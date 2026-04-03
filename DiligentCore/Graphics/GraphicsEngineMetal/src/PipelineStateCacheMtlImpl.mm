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
#include "PipelineStateCacheMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "DataBlobImpl.hpp"
#include "FileSystem.hpp"

#import <Foundation/Foundation.h>

namespace Diligent
{

PipelineStateCacheMtlImpl::PipelineStateCacheMtlImpl(IReferenceCounters*                 pRefCounters,
                                                     RenderDeviceMtlImpl*                pDeviceMtl,
                                                     const PipelineStateCacheCreateInfo& CreateInfo,
                                                     bool                                IsDeviceInternal) :
    TPipelineStateCacheBase{pRefCounters, pDeviceMtl, CreateInfo, IsDeviceInternal}
{
    InitializeBinaryArchive(CreateInfo);
}

PipelineStateCacheMtlImpl::~PipelineStateCacheMtlImpl()
{
    // Metal objects are reference-counted and will be released automatically
}

bool PipelineStateCacheMtlImpl::IsBinaryArchiveSupported(id<MTLDevice> mtlDevice)
{
    // MTLBinaryArchive requires macOS 11.0+ or iOS 14.0+
    if (@available(macOS 11.0, iOS 14.0, *))
    {
        return true;
    }
    return false;
}

void PipelineStateCacheMtlImpl::InitializeBinaryArchive(const PipelineStateCacheCreateInfo& CreateInfo)
{
    auto* pDevice = GetDevice();
    id<MTLDevice> mtlDevice = pDevice->GetMtlDevice();

    if (!IsBinaryArchiveSupported(mtlDevice))
    {
        if (m_Desc.Flags & PSO_CACHE_FLAG_VERBOSE)
        {
            LOG_INFO_MESSAGE("PipelineStateCacheMtl: MTLBinaryArchive not supported on this platform. ",
                            "Pipeline caching will be limited.");
        }
        return;
    }

    @autoreleasepool
    {
        if (@available(macOS 11.0, iOS 14.0, *))
        {
            NSError* pError = nil;

            if (CreateInfo.pCacheData != nullptr && CreateInfo.CacheDataSize > 0)
            {
                // Load from provided cache data
                LoadFromData(CreateInfo.pCacheData, CreateInfo.CacheDataSize);
            }
            else
            {
                // Create new empty binary archive
                MTLBinaryArchiveDescriptor* pDesc = [[MTLBinaryArchiveDescriptor alloc] init];
                m_BinaryArchive = [mtlDevice newBinaryArchiveWithDescriptor:pDesc error:&pError];

                if (m_BinaryArchive == nil || pError != nil)
                {
                    LOG_ERROR_MESSAGE("Failed to create Metal binary archive: ",
                                     pError != nil ? [[pError localizedDescription] UTF8String] : "Unknown error");
                }
            }
        }
    }
}

void PipelineStateCacheMtlImpl::LoadFromData(const void* pCacheData, Uint32 CacheDataSize)
{
    if (CacheDataSize < sizeof(CacheHeader))
    {
        LOG_WARNING_MESSAGE("PipelineStateCacheMtl: Cache data too small");
        return;
    }

    const CacheHeader* pHeader = static_cast<const CacheHeader*>(pCacheData);

    // Validate header
    if (pHeader->magic != CacheHeader::Magic)
    {
        LOG_WARNING_MESSAGE("PipelineStateCacheMtl: Invalid cache magic number");
        return;
    }

    if (pHeader->version != CacheHeader::Version)
    {
        LOG_WARNING_MESSAGE("PipelineStateCacheMtl: Cache version mismatch. Expected: ",
                           CacheHeader::Version, ", Got: ", pHeader->version);
        return;
    }

    // Check device name (optional validation)
    auto* pDevice = GetDevice();
    id<MTLDevice> mtlDevice = pDevice->GetMtlDevice();
    NSString* deviceName = mtlDevice.name;
    const char* currentDeviceName = [deviceName UTF8String];

    if (strcmp(pHeader->deviceName, currentDeviceName) != 0)
    {
        LOG_WARNING_MESSAGE("PipelineStateCacheMtl: Device mismatch. Cache created on: ",
                           pHeader->deviceName, ", Current device: ", currentDeviceName);
        // Continue anyway as Metal binary archives are portable across devices
    }

    // Extract binary archive data
    const Uint8* pBinaryData = static_cast<const Uint8*>(pCacheData) + pHeader->headerSize;
    Uint32 binaryDataSize = CacheDataSize - pHeader->headerSize;

    if (binaryDataSize == 0)
    {
        LOG_WARNING_MESSAGE("PipelineStateCacheMtl: No binary archive data in cache");
        return;
    }

    @autoreleasepool
    {
        if (@available(macOS 11.0, iOS 14.0, *))
        {
            // Write binary data to temporary file for loading
            NSString* tempDir = NSTemporaryDirectory();
            NSString* tempFile = [tempDir stringByAppendingPathComponent:@"temp_mtl_cache.binaryarchive"];
            NSURL* tempURL = [NSURL fileURLWithPath:tempFile];

            NSData* nsData = [NSData dataWithBytes:pBinaryData length:binaryDataSize];
            if ([nsData writeToURL:tempURL atomically:YES])
            {
                NSError* pError = nil;
                MTLBinaryArchiveDescriptor* pDesc = [[MTLBinaryArchiveDescriptor alloc] init];
                pDesc.url = tempURL;

                m_BinaryArchive = [mtlDevice newBinaryArchiveWithDescriptor:pDesc error:&pError];

                if (m_BinaryArchive == nil && pError != nil)
                {
                    LOG_ERROR_MESSAGE("Failed to load Metal binary archive: ",
                                     [[pError localizedDescription] UTF8String]);
                }

                // Clean up temp file
                [[NSFileManager defaultManager] removeItemAtURL:tempURL error:nil];
            }
        }
    }
}

bool PipelineStateCacheMtlImpl::AddRenderPipeline(id<MTLRenderPipelineState> pPipeline, MTLRenderPipelineDescriptor* pDesc)
{
    if (m_BinaryArchive == nil)
        return false;

    @autoreleasepool
    {
        if (@available(macOS 11.0, iOS 14.0, *))
        {
            NSError* pError = nil;
            bool success = [m_BinaryArchive addRenderPipelineFunctionsWithDescriptor:pDesc error:&pError];

            if (!success && pError != nil)
            {
                if (m_Desc.Flags & PSO_CACHE_FLAG_VERBOSE)
                {
                    LOG_INFO_MESSAGE("PipelineStateCacheMtl: Failed to add render pipeline to cache: ",
                                    [[pError localizedDescription] UTF8String]);
                }
                return false;
            }
            return true;
        }
    }
    return false;
}

bool PipelineStateCacheMtlImpl::AddComputePipeline(id<MTLComputePipelineState> pPipeline, MTLComputePipelineDescriptor* pDesc)
{
    if (m_BinaryArchive == nil)
        return false;

    @autoreleasepool
    {
        if (@available(macOS 11.0, iOS 14.0, *))
        {
            NSError* pError = nil;
            bool success = [m_BinaryArchive addComputePipelineFunctionsWithDescriptor:pDesc error:&pError];

            if (!success && pError != nil)
            {
                if (m_Desc.Flags & PSO_CACHE_FLAG_VERBOSE)
                {
                    LOG_INFO_MESSAGE("PipelineStateCacheMtl: Failed to add compute pipeline to cache: ",
                                    [[pError localizedDescription] UTF8String]);
                }
                return false;
            }
            return true;
        }
    }
    return false;
}

void PipelineStateCacheMtlImpl::GetData(IDataBlob** ppBlob)
{
    DEV_CHECK_ERR(ppBlob != nullptr, "ppBlob must not be null");
    *ppBlob = nullptr;

    if (m_BinaryArchive == nil)
    {
        LOG_WARNING_MESSAGE("PipelineStateCacheMtl: No binary archive to serialize");
        return;
    }

    @autoreleasepool
    {
        if (@available(macOS 11.0, iOS 14.0, *))
        {
            // Serialize binary archive to temporary file
            NSString* tempDir = NSTemporaryDirectory();
            NSString* tempFile = [tempDir stringByAppendingPathComponent:@"temp_mtl_cache_out.binaryarchive"];
            NSURL* tempURL = [NSURL fileURLWithPath:tempFile];

            NSError* pError = nil;
            bool success = [m_BinaryArchive serializeToURL:tempURL error:&pError];

            if (!success)
            {
                LOG_ERROR_MESSAGE("PipelineStateCacheMtl: Failed to serialize binary archive: ",
                                 pError != nil ? [[pError localizedDescription] UTF8String] : "Unknown error");
                return;
            }

            // Read binary data from file
            NSData* nsData = [NSData dataWithContentsOfURL:tempURL];
            if (nsData == nil)
            {
                LOG_ERROR_MESSAGE("PipelineStateCacheMtl: Failed to read serialized data");
                [[NSFileManager defaultManager] removeItemAtURL:tempURL error:nil];
                return;
            }

            // Prepare header
            CacheHeader header = {};
            header.magic = CacheHeader::Magic;
            header.version = CacheHeader::Version;
            header.headerSize = sizeof(CacheHeader);

            auto* pDevice = GetDevice();
            id<MTLDevice> mtlDevice = pDevice->GetMtlDevice();
            NSString* deviceName = mtlDevice.name;
            strncpy(header.deviceName, [deviceName UTF8String], sizeof(header.deviceName) - 1);
            header.deviceName[sizeof(header.deviceName) - 1] = '\0';

            // Create data blob with header + binary data
            Uint32 binarySize = static_cast<Uint32>([nsData length]);
            Uint32 totalSize = sizeof(CacheHeader) + binarySize;

            RefCntAutoPtr<DataBlobImpl> pDataBlob = DataBlobImpl::Create(totalSize);

            // Write header
            Uint8* pBlobData = pDataBlob->GetDataPtr<Uint8>();
            memcpy(pBlobData, &header, sizeof(CacheHeader));

            // Write binary data
            memcpy(pBlobData + sizeof(CacheHeader), [nsData bytes], binarySize);

            // Clean up temp file
            [[NSFileManager defaultManager] removeItemAtURL:tempURL error:nil];

            *ppBlob = pDataBlob.Detach();
        }
    }
}

} // namespace Diligent
