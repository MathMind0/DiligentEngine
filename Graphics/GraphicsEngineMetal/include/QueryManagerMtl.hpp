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

#pragma once

/// \file
/// Declaration of Diligent::QueryManagerMtl class

#include <mutex>
#include <array>
#include <vector>

#include "Query.h"

#import <Metal/Metal.h>

namespace Diligent
{

class RenderDeviceMtlImpl;

/// Manages Metal query pools for occlusion, timestamp, and pipeline statistics queries.
///
/// Metal uses different mechanisms for different query types:
/// - Occlusion queries: MTLBuffer used as visibility result buffer
/// - Timestamp queries: MTLCounterSampleBuffer (macOS 10.15+, iOS 14+)
/// - Pipeline statistics: Limited support via MTLCounterSet (device-dependent)
class QueryManagerMtl
{
public:
    /// Invalid index constant for query pool allocation
    static constexpr Uint32 InvalidIndex = static_cast<Uint32>(-1);

    QueryManagerMtl(RenderDeviceMtlImpl* pRenderDeviceMtl,
                    const Uint32         QueryHeapSizes[],
                    Uint32               CmdQueueIndex);
    ~QueryManagerMtl();

    // Non-copyable, non-movable
    QueryManagerMtl(const QueryManagerMtl&) = delete;
    QueryManagerMtl(QueryManagerMtl&&) = delete;
    QueryManagerMtl& operator=(const QueryManagerMtl&) = delete;
    QueryManagerMtl& operator=(QueryManagerMtl&&) = delete;

    /// Allocates a query of the specified type.
    /// Returns InvalidIndex if no queries are available.
    Uint32 AllocateQuery(QUERY_TYPE Type);

    /// Discards a query back to the pool for reuse.
    void DiscardQuery(QUERY_TYPE Type, Uint32 Index);

    /// Returns the visibility result buffer for occlusion queries.
    id<MTLBuffer> GetVisibilityResultBuffer() const
    {
        return m_VisibilityResultBuffer;
    }

    /// Returns the counter sample buffer for timestamp queries.
    id<MTLCounterSampleBuffer> GetCounterSampleBuffer() const API_AVAILABLE(ios(14), macosx(10.15))
    {
        return m_CounterSampleBuffer;
    }

    /// Returns the counter frequency for timestamp queries (in Hz).
    Uint64 GetCounterFrequency() const
    {
        return m_CounterFrequency;
    }

    /// Returns the command queue index this manager is associated with.
    Uint32 GetCommandQueueIndex() const
    {
        return m_CommandQueueIndex;
    }

    /// Checks if the specified query type is supported.
    bool IsQueryTypeSupported(QUERY_TYPE Type) const;

    /// Reads the visibility result at the specified index.
    /// Returns true if the result was read successfully.
    bool ReadVisibilityResult(Uint32 Index, Uint64& Result) const;

    /// Reads the timestamp at the specified index.
    /// Returns true if the result was read successfully.
    bool ReadTimestamp(Uint32 Index, Uint64& Timestamp) const API_AVAILABLE(ios(14), macosx(10.15));

private:
    /// Per-query type pool info
    struct QueryPoolInfo
    {
        /// Query type for this pool
        QUERY_TYPE Type = QUERY_TYPE_UNDEFINED;

        /// Total number of queries in the pool
        Uint32 QueryCount = 0;

        /// Available query indices (for reuse)
        std::vector<Uint32> AvailableQueries;

        /// Queries that are stale and need to be reset
        std::vector<Uint32> StaleQueries;

        /// Mutex for thread-safe allocation/deallocation
        std::mutex Mutex;

        /// Maximum number of queries ever allocated (for statistics)
        Uint32 MaxAllocatedQueries = 0;

        /// Allocates a query from this pool.
        Uint32 Allocate();

        /// Discards a query back to this pool.
        void Discard(Uint32 Index);

        /// Resets stale queries (moves them to available).
        void ResetStaleQueries();
    };

    /// Initializes the visibility result buffer for occlusion queries.
    void InitVisibilityResultBuffer(id<MTLDevice> mtlDevice, Uint32 QueryCount);

    /// Initializes the counter sample buffer for timestamp queries.
    void InitCounterSampleBuffer(id<MTLDevice> mtlDevice, Uint32 QueryCount) API_AVAILABLE(ios(14), macosx(10.15));

    /// Pool info for each query type
    std::array<QueryPoolInfo, QUERY_TYPE_NUM_TYPES> m_Pools;

    /// Metal device reference
    id<MTLDevice> m_MtlDevice = nil;

    /// Visibility result buffer for occlusion queries
    id<MTLBuffer> m_VisibilityResultBuffer = nil;

    /// Counter sample buffer for timestamp queries
    id<MTLCounterSampleBuffer> m_CounterSampleBuffer API_AVAILABLE(ios(14), macosx(10.15)) = nil;

    /// Counter frequency (GPU timestamps per second)
    Uint64 m_CounterFrequency = 0;

    /// Command queue index this manager is associated with
    Uint32 m_CommandQueueIndex = 0;

    /// Size of each visibility result (Uint64 per query)
    static constexpr size_t VisibilityResultSize = sizeof(Uint64);
};

} // namespace Diligent
