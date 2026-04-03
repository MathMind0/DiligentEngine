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
#include "ShaderResourceBindingMtlImpl.hpp"
#include "PipelineResourceSignatureMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "FixedLinearAllocator.hpp"

namespace Diligent
{

ShaderResourceBindingMtlImpl::ShaderResourceBindingMtlImpl(IReferenceCounters*               pRefCounters,
                                                            PipelineResourceSignatureMtlImpl*  pPRS) :
    TBase{pRefCounters, pPRS},
    m_ResourceCache{ResourceCacheContentType::SRB}
{
    // Initialize the resource cache
    const Uint32 TotalResources = pPRS->GetResourceCount();
    if (TotalResources > 0)
    {
        // Use the raw allocator for resource cache memory
        auto& RawAllocator = GetRawAllocator();
        const size_t CacheMemorySize = ShaderResourceCacheMtl::GetRequiredMemorySize(TotalResources);
        if (CacheMemorySize > 0)
        {
            m_ResourceCache.InitializeResources(RawAllocator, TotalResources);
        }
    }
}

ShaderResourceBindingMtlImpl::~ShaderResourceBindingMtlImpl()
{
}

} // namespace Diligent
