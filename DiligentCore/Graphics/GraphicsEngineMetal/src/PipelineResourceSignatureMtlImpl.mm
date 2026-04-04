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
#include "PipelineResourceSignatureMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "ShaderResourceBindingMtlImpl.hpp"
#include "SamplerMtlImpl.hpp"
#include "FixedLinearAllocator.hpp"

namespace Diligent
{

PipelineResourceSignatureMtlImpl::PipelineResourceSignatureMtlImpl(IReferenceCounters*                  pRefCounters,
                                                                     RenderDeviceMtlImpl*                 pDevice,
                                                                     const PipelineResourceSignatureDesc& Desc) :
    TBase{pRefCounters, pDevice, Desc},
    m_StaticResourceCache{ResourceCacheContentType::Signature}
{
    try
    {
        Initialize(
            GetRawAllocator(), Desc, /*CreateImmutableSamplers = */ false,
            [this]() //
            {
                CreateResourceLayouts(/*IsSerialized*/ false);
            },
            [this]() //
            {
                return ShaderResourceCacheMtl::GetRequiredMemorySize(m_TotalResources);
            });
    }
    catch (...)
    {
        Destruct();
        throw;
    }
}

PipelineResourceSignatureMtlImpl::~PipelineResourceSignatureMtlImpl()
{
}

void PipelineResourceSignatureMtlImpl::CreateResourceLayouts(const bool IsSerialized)
{
    const auto& Desc = GetDesc();
    const Uint32 NumResources = Desc.NumResources;
    
    m_TotalResources = 0;

    if (NumResources == 0 || Desc.Resources == nullptr)
        return;

    // Reserve space for resource attribs
    m_ResourceAttribs.reserve(NumResources);

    // Calculate cache offsets for each resource
    Uint32 CacheOffset = 0;
    for (Uint32 i = 0; i < NumResources; ++i)
    {
        const auto& ResDesc = Desc.Resources[i];
        // Use emplace_back to construct in place (const members prevent assignment)
        m_ResourceAttribs.emplace_back(
            CacheOffset,                           // BindingIndex
            ResDesc.ArraySize,                     // ArraySize
            MtlResourceType::Unknown,              // ResourceType (will be set properly later)
            ResourceAttribs::InvalidSamplerInd,    // SamplerInd
            0,                                     // SRBCacheOffset
            0                                      // StaticCacheOffset
        );
        CacheOffset += ResDesc.ArraySize;
        m_TotalResources += ResDesc.ArraySize;
    }

    // Initialize static resource cache
    // Note: For static resources, we would initialize the cache here
}

const PipelineResourceSignatureMtlImpl::ResourceAttribs& PipelineResourceSignatureMtlImpl::GetResourceAttribs(Uint32 ResIndex) const
{
    VERIFY_EXPR(ResIndex < m_ResourceAttribs.size());
    return m_ResourceAttribs[ResIndex];
}

const PipelineResourceDesc& PipelineResourceSignatureMtlImpl::GetResourceDesc(Uint32 ResIndex) const
{
    return TBase::GetDesc().Resources[ResIndex];
}

Uint32 PipelineResourceSignatureMtlImpl::GetResourceCount() const
{
    return static_cast<Uint32>(m_ResourceAttribs.size());
}

void PipelineResourceSignatureMtlImpl::InitSRBResourceCache(ShaderResourceCacheMtl& ResourceCache)
{
    // TODO: Initialize the resource cache for SRB usage
}

void PipelineResourceSignatureMtlImpl::CopyStaticResources(ShaderResourceCacheMtl& DstResourceCache) const
{
    // TODO: Copy static resources from m_StaticResourceCache to DstResourceCache
}

} // namespace Diligent
