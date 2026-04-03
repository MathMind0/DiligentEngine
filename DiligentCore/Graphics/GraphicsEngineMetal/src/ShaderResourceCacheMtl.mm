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
#include "ShaderResourceCacheMtl.hpp"
#include "Align.hpp"

namespace Diligent
{

ShaderResourceCacheMtl::~ShaderResourceCacheMtl()
{
    if (m_pMemory != nullptr)
    {
        Resource* pResources = GetFirstResourcePtr();
        for (Uint32 i = 0; i < m_TotalResources; ++i)
        {
            pResources[i].~Resource();
        }
        m_pAllocator->Free(m_pMemory);
    }
}

size_t ShaderResourceCacheMtl::GetRequiredMemorySize(Uint32 NumResources)
{
    if (NumResources == 0)
        return 0;

    // Align each resource to cache line for better performance
    constexpr size_t ResourceAlignment = 16;
    return AlignUp(NumResources * sizeof(Resource), ResourceAlignment);
}

void ShaderResourceCacheMtl::InitializeResources(IMemoryAllocator& MemAllocator,
                                                  Uint32            NumResources)
{
    VERIFY_EXPR(m_pMemory == nullptr);
    if (NumResources == 0)
        return;

    const size_t MemorySize = GetRequiredMemorySize(NumResources);
    m_pMemory = MemAllocator.Allocate(MemorySize, "Shader resource cache memory", __FILE__, __LINE__);
    m_pAllocator = &MemAllocator;
    m_TotalResources = NumResources;

    // Construct resources
    Resource* pResources = GetFirstResourcePtr();
    for (Uint32 i = 0; i < NumResources; ++i)
    {
        new (pResources + i) Resource{};
    }
}

void ShaderResourceCacheMtl::SetResource(Uint32             Index,
                                          Resource::Type     ResourceType,
                                          IDeviceObject*     pObject)
{
    VERIFY_EXPR(Index < m_TotalResources);
    Resource* pResources = GetFirstResourcePtr();
    pResources[Index] = Resource{ResourceType, pObject};
}

ShaderResourceCacheMtl::Resource& ShaderResourceCacheMtl::GetResource(Uint32 Index)
{
    VERIFY_EXPR(Index < m_TotalResources);
    return GetFirstResourcePtr()[Index];
}

const ShaderResourceCacheMtl::Resource& ShaderResourceCacheMtl::GetResource(Uint32 Index) const
{
    VERIFY_EXPR(Index < m_TotalResources);
    return GetFirstResourcePtr()[Index];
}

void ShaderResourceCacheMtl::ClearResources()
{
    Resource* pResources = GetFirstResourcePtr();
    for (Uint32 i = 0; i < m_TotalResources; ++i)
    {
        pResources[i] = Resource{};
    }
}

ShaderResourceCacheMtl::Resource* ShaderResourceCacheMtl::GetFirstResourcePtr()
{
    return reinterpret_cast<Resource*>(m_pMemory);
}

const ShaderResourceCacheMtl::Resource* ShaderResourceCacheMtl::GetFirstResourcePtr() const
{
    return reinterpret_cast<const Resource*>(m_pMemory);
}

#ifdef DILIGENT_DEBUG
void ShaderResourceCacheMtl::DbgVerifyResourceInitialization() const
{
    const Resource* pResources = GetFirstResourcePtr();
    for (Uint32 i = 0; i < m_TotalResources; ++i)
    {
        VERIFY(pResources[i].m_Type != Resource::Type::Unknown,
               "Resource at index ", i, " has not been initialized. This is a bug.");
    }
}
#endif

} // namespace Diligent
