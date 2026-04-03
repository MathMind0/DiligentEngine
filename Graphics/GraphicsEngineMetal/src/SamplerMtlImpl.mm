/*
 *  Copyright 2019-2026 Diligent Graphics LLC
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
#include "SamplerMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "MetalTypeConversions.h"

namespace Diligent
{

SamplerMtlImpl::SamplerMtlImpl(IReferenceCounters*  pRefCounters,
                               RenderDeviceMtlImpl* pDevice,
                               const SamplerDesc&   Desc) :
    TSamplerBase{pRefCounters, pDevice, Desc}
{
    @autoreleasepool
    {
        MTLSamplerDescriptor* mtlSamplerDesc = [[MTLSamplerDescriptor alloc] init];
        
        // Set filter modes
        mtlSamplerDesc.minFilter = FilterTypeToMtlMinMagFilter(Desc.MinFilter);
        mtlSamplerDesc.magFilter = FilterTypeToMtlMinMagFilter(Desc.MagFilter);
        mtlSamplerDesc.mipFilter = FilterTypeToMtlMipFilter(Desc.MipFilter);
        
        // Set address modes
        mtlSamplerDesc.sAddressMode = AddressModeToMtlAddressMode(Desc.AddressU);
        mtlSamplerDesc.tAddressMode = AddressModeToMtlAddressMode(Desc.AddressV);
        mtlSamplerDesc.rAddressMode = AddressModeToMtlAddressMode(Desc.AddressW);
        
        // Set mip LOD parameters
        mtlSamplerDesc.lodMinClamp = Desc.MinLOD;
        mtlSamplerDesc.lodMaxClamp = Desc.MaxLOD;
        
        // Set max anisotropy
        if (Desc.MaxAnisotropy > 1)
        {
            mtlSamplerDesc.maxAnisotropy = Desc.MaxAnisotropy;
        }
        
        // Set compare function
        if (Desc.ComparisonFunc != COMPARISON_FUNC_UNKNOWN)
        {
            mtlSamplerDesc.compareFunction = ComparisonFuncToMtlCompareFunction(Desc.ComparisonFunc);
        }
        
        // Set border color (Metal has limited border color support)
        // Note: Metal doesn't support all border colors that D3D12/Vulkan support
        
        // Create the sampler state
        m_mtlSamplerState = [pDevice->GetMtlDevice() newSamplerStateWithDescriptor:mtlSamplerDesc];
        
        if (m_mtlSamplerState == nil)
        {
            LOG_ERROR_AND_THROW("Failed to create Metal sampler state");
        }
    }
}

SamplerMtlImpl::~SamplerMtlImpl()
{
    m_mtlSamplerState = nil;
}

} // namespace Diligent