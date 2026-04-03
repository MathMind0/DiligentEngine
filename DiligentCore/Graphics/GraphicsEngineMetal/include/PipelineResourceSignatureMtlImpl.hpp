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
/// Declaration of Diligent::PipelineResourceSignatureMtlImpl class

#include "PipelineResourceSignatureBase.hpp"
#include "EngineMtlImplTraits.hpp"
#include "ShaderResourceCacheMtl.hpp"
#include "ShaderVariableManagerMtl.hpp"
#include "PipelineResourceAttribsMtl.hpp"

namespace Diligent
{

class RenderDeviceMtlImpl;

/// Implementation of IPipelineResourceSignature for Metal backend.
/// This class manages the resource layout and binding for Metal shaders.
class PipelineResourceSignatureMtlImpl final : public PipelineResourceSignatureBase<EngineMtlImplTraits>
{
public:
    using TBase = PipelineResourceSignatureBase<EngineMtlImplTraits>;
    using ResourceAttribs = PipelineResourceAttribsMtl;

    PipelineResourceSignatureMtlImpl(IReferenceCounters*                  pRefCounters,
                                      RenderDeviceMtlImpl*                 pDevice,
                                      const PipelineResourceSignatureDesc& Desc);
    ~PipelineResourceSignatureMtlImpl();

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_PipelineResourceSignature, TBase)

    /// Gets the resource attributes for the given resource index
    const ResourceAttribs& GetResourceAttribs(Uint32 ResIndex) const;

    /// Gets the resource description for the given resource index
    const PipelineResourceDesc& GetResourceDesc(Uint32 ResIndex) const;

    /// Gets the number of resources
    Uint32 GetResourceCount() const;

    /// Initialize SRB resource cache
    void InitSRBResourceCache(ShaderResourceCacheMtl& ResourceCache);

    /// Copy static resources to the destination cache
    void CopyStaticResources(ShaderResourceCacheMtl& DstResourceCache) const;

    // Bring base class method into scope
    using TBase::CopyStaticResources;

private:
    /// Initializes resource attributes from the signature description
    void InitializeResourceAttribs();

private:
    std::vector<ResourceAttribs> m_ResourceAttribs;
    ShaderResourceCacheMtl       m_StaticResourceCache;
};

} // namespace Diligent
