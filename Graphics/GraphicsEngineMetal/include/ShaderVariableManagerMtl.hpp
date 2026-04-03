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
/// Declaration of Diligent::ShaderVariableManagerMtl and Diligent::ShaderVariableMtlImpl classes

#include "EngineMtlImplTraits.hpp"
#include "ShaderResourceVariableBase.hpp"
#include "ShaderResourceCacheMtl.hpp"
#include "PipelineResourceAttribsMtl.hpp"

namespace Diligent
{

class ShaderVariableMtlImpl;

/// Manages shader variables for Metal backend.
/// ShaderVariableManagerMtl is used by PipelineResourceSignatureMtlImpl to manage
/// static resources and by ShaderResourceBindingMtlImpl to manage mutable and dynamic resources.
class ShaderVariableManagerMtl : ShaderVariableManagerBase<EngineMtlImplTraits, ShaderVariableMtlImpl>
{
public:
    using TBase = ShaderVariableManagerBase<EngineMtlImplTraits, ShaderVariableMtlImpl>;

    /// Constructor that takes an owner object and resource cache
    ShaderVariableManagerMtl(IObject&               Owner,
                             ShaderResourceCacheMtl& ResourceCache) noexcept :
        TBase{Owner, ResourceCache}
    {}

    /// Initialize the manager with the given signature and allocator
    void Initialize(const PipelineResourceSignatureMtlImpl& Signature,
                    IMemoryAllocator&                        Allocator,
                    const SHADER_RESOURCE_VARIABLE_TYPE*     AllowedVarTypes,
                    Uint32                                   NumAllowedTypes,
                    SHADER_TYPE                              ShaderType);

    /// Destroy the manager and free resources
    void Destroy(IMemoryAllocator& Allocator);

    /// Get a variable by name
    ShaderVariableMtlImpl* GetVariable(const Char* Name) const;

    /// Get a variable by index
    ShaderVariableMtlImpl* GetVariable(Uint32 Index) const;

    /// Bind a resource at the given index
    void BindResource(Uint32 ResIndex, const BindResourceInfo& BindInfo);

    /// Get a resource
    IDeviceObject* Get(Uint32 ArrayIndex, Uint32 ResIndex) const;

    /// Bind resources from a resource mapping
    void BindResources(IResourceMapping* pResourceMapping, BIND_SHADER_RESOURCES_FLAGS Flags);

    /// Check if resources are bound
    void CheckResources(IResourceMapping*                    pResourceMapping,
                        BIND_SHADER_RESOURCES_FLAGS          Flags,
                        SHADER_RESOURCE_VARIABLE_TYPE_FLAGS& StaleVarTypes) const;

    /// Get the required memory size for the manager
    static size_t GetRequiredMemorySize(const PipelineResourceSignatureMtlImpl& Signature,
                                        const SHADER_RESOURCE_VARIABLE_TYPE*   AllowedVarTypes,
                                        Uint32                                 NumAllowedTypes,
                                        SHADER_TYPE                            ShaderStages,
                                        Uint32*                                pNumVariables = nullptr);

    /// Get the number of variables
    Uint32 GetVariableCount() const { return m_NumVariables; }

    /// Get the owner object
    IObject& GetOwner() const { return m_Owner; }

private:
    friend TBase;
    friend ShaderVariableMtlImpl;
    friend ShaderVariableBase<ShaderVariableMtlImpl, ShaderVariableManagerMtl, IShaderResourceVariable>;

    using ResourceAttribs = PipelineResourceAttribsMtl;

    Uint32 GetVariableIndex(const ShaderVariableMtlImpl& Variable);

    const PipelineResourceDesc& GetResourceDesc(Uint32 Index) const;
    const ResourceAttribs&      GetResourceAttribs(Uint32 Index) const;

private:
    Uint32 m_NumVariables = 0;
};

/// Metal shader variable implementation
class ShaderVariableMtlImpl final : public ShaderVariableBase<ShaderVariableMtlImpl, ShaderVariableManagerMtl, IShaderResourceVariable>
{
public:
    using TBase = ShaderVariableBase<ShaderVariableMtlImpl, ShaderVariableManagerMtl, IShaderResourceVariable>;

    ShaderVariableMtlImpl(ShaderVariableManagerMtl& ParentManager,
                          Uint32                     ResIndex) :
        TBase{ParentManager, ResIndex}
    {}

    // clang-format off
    ShaderVariableMtlImpl            (const ShaderVariableMtlImpl&) = delete;
    ShaderVariableMtlImpl            (ShaderVariableMtlImpl&&)      = delete;
    ShaderVariableMtlImpl& operator= (const ShaderVariableMtlImpl&) = delete;
    ShaderVariableMtlImpl& operator= (ShaderVariableMtlImpl&&)      = delete;
    // clang-format on

    virtual IDeviceObject* DILIGENT_CALL_TYPE Get(Uint32 ArrayIndex) const override final
    {
        return m_ParentManager.Get(ArrayIndex, m_ResIndex);
    }

    /// Get the resource index
    Uint32 GetResourceIndex() const { return m_ResIndex; }

    void BindResource(const BindResourceInfo& BindInfo) const
    {
        m_ParentManager.BindResource(m_ResIndex, BindInfo);
    }

    /// Set dynamic offset for dynamic uniform buffers
    void SetDynamicOffset(Uint32 ArrayIndex, Uint32 Offset)
    {
        // TODO: Implement dynamic offset setting
    }

    /// Set inline constants
    void SetConstants(const void* pConstants, Uint32 FirstConstant, Uint32 NumConstants)
    {
        // TODO: Implement constant setting
    }
};

} // namespace Diligent
