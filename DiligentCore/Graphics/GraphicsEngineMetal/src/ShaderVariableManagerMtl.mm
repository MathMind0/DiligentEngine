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
#include "ShaderVariableManagerMtl.hpp"
#include "PipelineResourceSignatureMtlImpl.hpp"
#include "ShaderResourceCacheMtl.hpp"
#include "FixedLinearAllocator.hpp"

namespace Diligent
{

void ShaderVariableManagerMtl::Initialize(const PipelineResourceSignatureMtlImpl& Signature,
                                           IMemoryAllocator&                        Allocator,
                                           const SHADER_RESOURCE_VARIABLE_TYPE*     AllowedVarTypes,
                                           Uint32                                   NumAllowedTypes,
                                           SHADER_TYPE                              ShaderType)
{
    // Calculate required memory size
    Uint32       NumVariables = 0;
    const Uint32 NumResources = Signature.GetResourceCount();
    for (Uint32 r = 0; r < NumResources; ++r)
    {
        const auto& ResDesc = Signature.GetResourceDesc(r);
        if ((ResDesc.ShaderStages & ShaderType) != 0)
        {
            // Check if the variable type is allowed
            for (Uint32 t = 0; t < NumAllowedTypes; ++t)
            {
                if (ResDesc.VarType == AllowedVarTypes[t])
                {
                    ++NumVariables;
                    break;
                }
            }
        }
    }

    m_NumVariables = NumVariables;

    // Initialize base class
    const size_t MemorySize = sizeof(ShaderVariableMtlImpl) * NumVariables;
    TBase::Initialize(Signature, Allocator, MemorySize);

    // Construct variables
    if (NumVariables > 0 && m_pVariables != nullptr)
    {
        Uint32 VarIdx = 0;
        for (Uint32 r = 0; r < NumResources; ++r)
        {
            const auto& ResDesc = Signature.GetResourceDesc(r);
            if ((ResDesc.ShaderStages & ShaderType) != 0)
            {
                bool bIsAllowed = false;
                for (Uint32 t = 0; t < NumAllowedTypes; ++t)
                {
                    if (ResDesc.VarType == AllowedVarTypes[t])
                    {
                        bIsAllowed = true;
                        break;
                    }
                }
                if (bIsAllowed)
                {
                    new (&m_pVariables[VarIdx]) ShaderVariableMtlImpl(*this, r);
                    ++VarIdx;
                }
            }
        }
    }
}

void ShaderVariableManagerMtl::Destroy(IMemoryAllocator& Allocator)
{
    if (m_pVariables != nullptr && m_NumVariables > 0)
    {
        for (Uint32 v = 0; v < m_NumVariables; ++v)
        {
            m_pVariables[v].~ShaderVariableMtlImpl();
        }
    }
    TBase::Destroy(Allocator);
}

ShaderVariableMtlImpl* ShaderVariableManagerMtl::GetVariable(const Char* Name) const
{
    if (Name == nullptr || m_pVariables == nullptr)
        return nullptr;

    const PipelineResourceSignatureMtlImpl* pSignature = 
        static_cast<const PipelineResourceSignatureMtlImpl*>(m_pSignature);
    if (pSignature == nullptr)
        return nullptr;

    for (Uint32 v = 0; v < m_NumVariables; ++v)
    {
        const Uint32 ResIndex = m_pVariables[v].GetResourceIndex();
        const auto&  ResDesc  = pSignature->GetResourceDesc(ResIndex);
        if (strcmp(ResDesc.Name, Name) == 0)
            return &m_pVariables[v];
    }
    return nullptr;
}

ShaderVariableMtlImpl* ShaderVariableManagerMtl::GetVariable(Uint32 Index) const
{
    if (Index >= m_NumVariables || m_pVariables == nullptr)
        return nullptr;
    return &m_pVariables[Index];
}

void ShaderVariableManagerMtl::BindResource(Uint32 ResIndex, const BindResourceInfo& BindInfo)
{
    // TODO: Implement resource binding
    // This will need to interact with the resource cache
}

IDeviceObject* ShaderVariableManagerMtl::Get(Uint32 ArrayIndex, Uint32 ResIndex) const
{
    // TODO: Implement resource retrieval from cache
    return nullptr;
}

void ShaderVariableManagerMtl::BindResources(IResourceMapping* pResourceMapping, BIND_SHADER_RESOURCES_FLAGS Flags)
{
    TBase::BindResources(pResourceMapping, Flags);
}

void ShaderVariableManagerMtl::CheckResources(IResourceMapping*                    pResourceMapping,
                                               BIND_SHADER_RESOURCES_FLAGS          Flags,
                                               SHADER_RESOURCE_VARIABLE_TYPE_FLAGS& StaleVarTypes) const
{
    TBase::CheckResources(pResourceMapping, Flags, StaleVarTypes);
}

size_t ShaderVariableManagerMtl::GetRequiredMemorySize(const PipelineResourceSignatureMtlImpl& Signature,
                                                        const SHADER_RESOURCE_VARIABLE_TYPE*   AllowedVarTypes,
                                                        Uint32                                 NumAllowedTypes,
                                                        SHADER_TYPE                            ShaderStages,
                                                        Uint32*                                pNumVariables)
{
    const Uint32 NumResources = Signature.GetResourceCount();
    Uint32       NumVariables = 0;
    for (Uint32 r = 0; r < NumResources; ++r)
    {
        const auto& ResDesc = Signature.GetResourceDesc(r);
        if ((ResDesc.ShaderStages & ShaderStages) != 0)
        {
            for (Uint32 t = 0; t < NumAllowedTypes; ++t)
            {
                if (ResDesc.VarType == AllowedVarTypes[t])
                {
                    ++NumVariables;
                    break;
                }
            }
        }
    }

    if (pNumVariables != nullptr)
        *pNumVariables = NumVariables;

    return sizeof(ShaderVariableMtlImpl) * NumVariables;
}

Uint32 ShaderVariableManagerMtl::GetVariableIndex(const ShaderVariableMtlImpl& Variable)
{
    if (m_pVariables == nullptr)
        return 0;
    
    const ShaderVariableMtlImpl* pFirst = m_pVariables;
    const ShaderVariableMtlImpl* pVar   = &Variable;
    return static_cast<Uint32>(pVar - pFirst);
}

const PipelineResourceDesc& ShaderVariableManagerMtl::GetResourceDesc(Uint32 Index) const
{
    const auto& Signature = static_cast<const PipelineResourceSignatureMtlImpl&>(m_Owner);
    return Signature.GetResourceDesc(Index);
}

const PipelineResourceAttribsMtl& ShaderVariableManagerMtl::GetResourceAttribs(Uint32 Index) const
{
    const auto& Signature = static_cast<const PipelineResourceSignatureMtlImpl&>(m_Owner);
    return Signature.GetResourceAttribs(Index);
}

} // namespace Diligent
