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
/// Declaration of Diligent::ShaderResourceBindingMtlImpl class

#include "ShaderResourceBindingBase.hpp"
#include "EngineMtlImplTraits.hpp"
#include "ShaderResourceCacheMtl.hpp"
#include "ShaderVariableManagerMtl.hpp"

namespace Diligent
{

class PipelineResourceSignatureMtlImpl;

/// Implementation of IShaderResourceBindingMtl interface.
/// This class manages resource bindings for Metal shaders.
class ShaderResourceBindingMtlImpl final : public ShaderResourceBindingBase<EngineMtlImplTraits>
{
public:
    using TBase = ShaderResourceBindingBase<EngineMtlImplTraits>;

    ShaderResourceBindingMtlImpl(IReferenceCounters*              pRefCounters,
                                  PipelineResourceSignatureMtlImpl* pPRS);
    ~ShaderResourceBindingMtlImpl();

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_ShaderResourceBindingMtl, TBase)

    /// Gets the resource cache
    ShaderResourceCacheMtl& GetResourceCache() { return m_ResourceCache; }
    const ShaderResourceCacheMtl& GetResourceCache() const { return m_ResourceCache; }

    /// Gets the pipeline resource signature
    PipelineResourceSignatureMtlImpl* GetSignature() { return m_pPRS; }
    const PipelineResourceSignatureMtlImpl* GetSignature() const { return m_pPRS; }

private:
    ShaderResourceCacheMtl m_ResourceCache;
};

} // namespace Diligent
