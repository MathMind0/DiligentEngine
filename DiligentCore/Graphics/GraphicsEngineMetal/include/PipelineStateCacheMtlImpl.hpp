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
/// Declaration of Diligent::PipelineStateCacheMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "PipelineStateCacheBase.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

/// Pipeline state cache object implementation in Metal backend.
class PipelineStateCacheMtlImpl final : public PipelineStateCacheBase<EngineMtlImplTraits>
{
public:
    using TPipelineStateCacheBase = PipelineStateCacheBase<EngineMtlImplTraits>;

    PipelineStateCacheMtlImpl(IReferenceCounters*                 pRefCounters,
                              RenderDeviceMtlImpl*                pDeviceMtl,
                              const PipelineStateCacheCreateInfo& CreateInfo,
                              bool                                IsDeviceInternal = false);
    ~PipelineStateCacheMtlImpl();

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_PipelineStateCacheMtl, TPipelineStateCacheBase)

    /// Implementation of IPipelineStateCache::GetData().
    virtual void DILIGENT_CALL_TYPE GetData(IDataBlob** ppBlob) override final;

    /// Get the Metal binary archive object
    id<MTLBinaryArchive> GetMtlBinaryArchive() const { return m_BinaryArchive; }

    /// Check if binary archive is supported on this device/OS
    static bool IsBinaryArchiveSupported(id<MTLDevice> mtlDevice);

    /// Add a render pipeline to the cache
    bool AddRenderPipeline(id<MTLRenderPipelineState> pPipeline, MTLRenderPipelineDescriptor* pDesc);

    /// Add a compute pipeline to the cache
    bool AddComputePipeline(id<MTLComputePipelineState> pPipeline, MTLComputePipelineDescriptor* pDesc);

private:
    void InitializeBinaryArchive(const PipelineStateCacheCreateInfo& CreateInfo);
    void LoadFromData(const void* pCacheData, Uint32 CacheDataSize);
    bool StoreToURL(NSURL* pURL);

    // Metal binary archive for pipeline caching (macOS 11+, iOS 14+)
    id<MTLBinaryArchive> m_BinaryArchive = nil;

    // File URL for persistent storage
    NSURL* m_CacheURL = nil;

    // Cache header for validation
    struct CacheHeader
    {
        static constexpr Uint32 Magic = 0x4D544C43; // "MTLC"
        static constexpr Uint32 Version = 1;

        Uint32 magic;
        Uint32 version;
        Uint32 headerSize;
        char deviceName[256];
    };
};

} // namespace Diligent
