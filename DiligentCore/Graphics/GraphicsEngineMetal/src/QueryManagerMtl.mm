/*
 *  Copyright 2019-2026 Diligent Graphics LLC
 *  Copyright 2015-2019 Egor Yusov
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#include "pch.h"
#include "QueryManagerMtl.hpp"
#include "RenderDeviceMtlImpl.hpp"

#import <Foundation/Foundation.h>
#include <mach/mach_time.h>

namespace Diligent
{

// QueryPoolInfo methods
Uint32 QueryManagerMtl::QueryPoolInfo::Allocate()
{
    std::lock_guard<std::mutex> Lock(Mutex);

    if (AvailableQueries.empty())
        return InvalidIndex;

    Uint32 Index = AvailableQueries.back();
    AvailableQueries.pop_back();

    MaxAllocatedQueries = std::max(MaxAllocatedQueries, QueryCount - static_cast<Uint32>(AvailableQueries.size()));

    return Index;
}

void QueryManagerMtl::QueryPoolInfo::Discard(Uint32 Index)
{
    std::lock_guard<std::mutex> Lock(Mutex);

    VERIFY(Index < QueryCount, "Query index ", Index, " is out of range");
    StaleQueries.push_back(Index);
}

void QueryManagerMtl::QueryPoolInfo::ResetStaleQueries()
{
    std::lock_guard<std::mutex> Lock(Mutex);

    // Move stale queries back to available pool
    for (Uint32 Index : StaleQueries)
    {
        AvailableQueries.push_back(Index);
    }
    StaleQueries.clear();
}

// QueryManagerMtl methods
QueryManagerMtl::QueryManagerMtl(RenderDeviceMtlImpl* pRenderDeviceMtl,
                                 const Uint32         QueryHeapSizes[],
                                 Uint32               CmdQueueIndex) :
    m_MtlDevice{pRenderDeviceMtl->GetMtlDevice()},
    m_CommandQueueIndex{CmdQueueIndex}
{
    @autoreleasepool
    {
        // Initialize pools for each query type
        for (Uint32 query_type = QUERY_TYPE_UNDEFINED + 1; query_type < QUERY_TYPE_NUM_TYPES; ++query_type)
        {
            const QUERY_TYPE QueryType = static_cast<QUERY_TYPE>(query_type);
            const Uint32     QueryCount = QueryHeapSizes[QueryType];

            if (QueryCount == 0)
                continue;

            // Skip query types that are not supported on this platform
            if (!IsQueryTypeSupported(QueryType))
                continue;

            QueryPoolInfo& PoolInfo = m_Pools[QueryType];
            PoolInfo.Type = QueryType;
            PoolInfo.QueryCount = QueryCount;

            // Initialize available queries
            PoolInfo.AvailableQueries.resize(QueryCount);
            for (Uint32 i = 0; i < QueryCount; ++i)
            {
                PoolInfo.AvailableQueries[i] = i;
            }

            // Initialize Metal resources for each query type
            switch (QueryType)
            {
                case QUERY_TYPE_OCCLUSION:
                case QUERY_TYPE_BINARY_OCCLUSION:
                    InitVisibilityResultBuffer(m_MtlDevice, QueryCount);
                    break;

                case QUERY_TYPE_TIMESTAMP:
                case QUERY_TYPE_DURATION:
                    if (@available(macOS 10.15, iOS 14.0, *))
                    {
                        InitCounterSampleBuffer(m_MtlDevice, QueryType == QUERY_TYPE_DURATION ? QueryCount * 2 : QueryCount);
                    }
                    break;

                case QUERY_TYPE_PIPELINE_STATISTICS:
                    // Pipeline statistics are not directly supported in Metal
                    // We'll use MTLCounterSet where available, but this is device-dependent
                    LOG_WARNING_MESSAGE("Pipeline statistics queries have limited support in Metal. "
                                       "Not all statistics may be available.");
                    break;

                default:
                    break;
            }
        }

        // Set counter frequency
        if (@available(macOS 10.15, iOS 14.0, *))
        {
            if (m_CounterSampleBuffer != nil)
            {
                // Get the timestamp frequency from the device
                // Metal timestamps are in nanoseconds, so frequency is 1 GHz
                m_CounterFrequency = 1000000000ULL;
            }
        }
        else
        {
            // Fallback for older platforms - use mach_absolute_time frequency
            mach_timebase_info_data_t timebase;
            mach_timebase_info(&timebase);
            m_CounterFrequency = 1000000000ULL * timebase.denom / timebase.numer;
        }
    }
}

QueryManagerMtl::~QueryManagerMtl()
{
    // Log peak query usage statistics
    std::stringstream QueryUsageSS;
    QueryUsageSS << "Metal query manager peak usage:";
    bool AnyPoolUsed = false;

    for (Uint32 QueryType = QUERY_TYPE_UNDEFINED + 1; QueryType < QUERY_TYPE_NUM_TYPES; ++QueryType)
    {
        QueryPoolInfo& PoolInfo = m_Pools[QueryType];
        if (PoolInfo.QueryCount == 0)
            continue;

        QueryUsageSS << std::endl
                     << std::setw(30) << std::left << GetQueryTypeString(static_cast<QUERY_TYPE>(QueryType)) << ": "
                     << std::setw(4) << std::right << PoolInfo.MaxAllocatedQueries
                     << '/' << std::setw(4) << PoolInfo.QueryCount;
        AnyPoolUsed = true;
    }

    if (AnyPoolUsed)
    {
        LOG_INFO_MESSAGE(QueryUsageSS.str());
    }
}

void QueryManagerMtl::InitVisibilityResultBuffer(id<MTLDevice> mtlDevice, Uint32 QueryCount)
{
    @autoreleasepool
    {
        // Create a buffer to hold visibility results
        // Each result is a 64-bit counter
        const NSUInteger BufferSize = QueryCount * VisibilityResultSize;

        // Check if device supports occlusion queries
        if (![mtlDevice isDepth24Stencil8PixelFormatSupported])
        {
            // Some older devices may not support certain query features
            LOG_WARNING_MESSAGE("Device may have limited occlusion query support");
        }

        m_VisibilityResultBuffer = [mtlDevice newBufferWithLength:BufferSize
                                                          options:MTLResourceStorageModeShared];
        if (m_VisibilityResultBuffer == nil)
        {
            LOG_ERROR_AND_THROW("Failed to create visibility result buffer for occlusion queries");
        }

        // Initialize buffer to zero
        memset(m_VisibilityResultBuffer.contents, 0, BufferSize);
    }
}

void QueryManagerMtl::InitCounterSampleBuffer(id<MTLDevice> mtlDevice, Uint32 QueryCount) API_AVAILABLE(ios(14), macosx(10.15))
{
    @autoreleasepool
    {
        // Check if the device supports counter sampling
        if (![mtlDevice supportsCounterSampling:MTLCounterSamplingPointAtStageBoundary])
        {
            LOG_WARNING_MESSAGE("Device does not support timestamp queries at stage boundaries. "
                               "Timestamp queries will have limited functionality.");
        }

        // Create counter sample buffer descriptor
        MTLCounterSampleBufferDescriptor* descriptor = [[MTLCounterSampleBufferDescriptor alloc] init];
        descriptor.counterSet = nil; // Will use timestamp counter set
        descriptor.sampleCount = QueryCount;
        descriptor.storageMode = MTLStorageModeShared;

        // Try to find the timestamp counter set
        NSArray<id<MTLCounterSet>>* counterSets = mtlDevice.counterSets;
        for (id<MTLCounterSet> counterSet in counterSets)
        {
            if ([counterSet.name isEqualToString:@"Timestamp"])
            {
                descriptor.counterSet = counterSet;
                break;
            }
        }

        if (descriptor.counterSet == nil && counterSets.count > 0)
        {
            // Use the first available counter set as fallback
            descriptor.counterSet = counterSets[0];
            LOG_WARNING_MESSAGE("Timestamp counter set not found, using: ", [[descriptor.counterSet name] UTF8String]);
        }

        if (descriptor.counterSet != nil)
        {
            NSError* error = nil;
            m_CounterSampleBuffer = [mtlDevice newCounterSampleBufferWithDescriptor:descriptor
                                                                              error:&error];
            if (error != nil)
            {
                LOG_ERROR_MESSAGE("Failed to create counter sample buffer: ", [[error localizedDescription] UTF8String]);
            }
        }
        else
        {
            LOG_WARNING_MESSAGE("No counter sets available on this device. Timestamp queries will not work.");
        }
    }
}

Uint32 QueryManagerMtl::AllocateQuery(QUERY_TYPE Type)
{
    if (Type <= QUERY_TYPE_UNDEFINED || Type >= QUERY_TYPE_NUM_TYPES)
    {
        UNEXPECTED("Invalid query type");
        return InvalidIndex;
    }

    QueryPoolInfo& PoolInfo = m_Pools[Type];
    if (PoolInfo.QueryCount == 0)
    {
        LOG_ERROR_MESSAGE("Query pool for type ", GetQueryTypeString(Type), " is not initialized");
        return InvalidIndex;
    }

    return PoolInfo.Allocate();
}

void QueryManagerMtl::DiscardQuery(QUERY_TYPE Type, Uint32 Index)
{
    if (Type <= QUERY_TYPE_UNDEFINED || Type >= QUERY_TYPE_NUM_TYPES)
    {
        UNEXPECTED("Invalid query type");
        return;
    }

    QueryPoolInfo& PoolInfo = m_Pools[Type];
    if (PoolInfo.QueryCount == 0)
    {
        UNEXPECTED("Query pool for type ", GetQueryTypeString(Type), " is not initialized");
        return;
    }

    PoolInfo.Discard(Index);
}

bool QueryManagerMtl::IsQueryTypeSupported(QUERY_TYPE Type) const
{
    switch (Type)
    {
        case QUERY_TYPE_OCCLUSION:
        case QUERY_TYPE_BINARY_OCCLUSION:
            // Occlusion queries are supported on all Metal-capable devices
            return true;

        case QUERY_TYPE_TIMESTAMP:
        case QUERY_TYPE_DURATION:
            // Timestamp queries require MTLCounterSampleBuffer (macOS 10.15+, iOS 14+)
            if (@available(macOS 10.15, iOS 14.0, *))
            {
                return true;
            }
            return false;

        case QUERY_TYPE_PIPELINE_STATISTICS:
            // Pipeline statistics have limited support in Metal
            // Some statistics may be available via MTLCounterSet
            return true;

        default:
            return false;
    }
}

bool QueryManagerMtl::ReadVisibilityResult(Uint32 Index, Uint64& Result) const
{
    if (m_VisibilityResultBuffer == nil)
    {
        LOG_ERROR_MESSAGE("Visibility result buffer is not initialized");
        return false;
    }

    const Uint64* pData = static_cast<const Uint64*>(m_VisibilityResultBuffer.contents);
    Result = pData[Index];
    return true;
}

bool QueryManagerMtl::ReadTimestamp(Uint32 Index, Uint64& Timestamp) const
{
    if (@available(macOS 10.15, iOS 14.0, *))
    {
        if (m_CounterSampleBuffer == nil)
        {
            LOG_ERROR_MESSAGE("Counter sample buffer is not initialized");
            return false;
        }

        @autoreleasepool
        {
            NSData* data = [m_CounterSampleBuffer resolveCounterRange:NSMakeRange(Index, 1)];

            if (data == nil || data.length < sizeof(Uint64))
            {
                LOG_ERROR_MESSAGE("Failed to resolve timestamp or insufficient data returned from counter sample buffer");
                return false;
            }

            Timestamp = *static_cast<const Uint64*>(data.bytes);
            return true;
        }
    }
    else
    {
        LOG_ERROR_MESSAGE("Timestamp queries require macOS 10.15+ or iOS 14.0+");
        return false;
    }
}

} // namespace Diligent
