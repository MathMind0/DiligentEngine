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
/// Declaration of Diligent::ShaderResourceCacheMtl class

#include "ShaderResourceCacheCommon.hpp"
#include "EngineMtlImplTraits.hpp"

namespace Diligent
{

class DeviceContextMtlImpl;

/// Metal shader resource cache.
///
/// The cache stores Metal resources in a continuous chunk of memory:
///
///   |--------------|
///   |  Resources   |
///   |--------------|
///
/// Each resource can be a buffer, texture, or sampler.
/// For Metal, we use direct binding rather than descriptor sets.
/// Resources are bound to specific indices per shader stage.
class ShaderResourceCacheMtl : public ShaderResourceCacheBase
{
public:
    /// Resource stored in the cache
    struct Resource
    {
        enum class Type : Uint8
        {
            Unknown = 0,
            ConstantBuffer,
            StructuredBuffer,
            FormattedBuffer,
            TextureSRV,
            TextureUAV,
            BufferUAV,
            Sampler,
            AccelerationStructure,
            InputAttachment,
            NumTypes
        };

        Resource() noexcept {}

        explicit Resource(Type _Type, IDeviceObject* _pObject = nullptr) noexcept :
            m_Type{_Type},
            pObject{_pObject}
        {}

        Type            m_Type = Type::Unknown;
        IDeviceObject*  pObject = nullptr;
        
        Type GetType() const { return m_Type; }
    };

    explicit ShaderResourceCacheMtl(ResourceCacheContentType ContentType) noexcept :
        m_TotalResources{0},
        m_ContentType{static_cast<Uint32>(ContentType)}
    {
        VERIFY_EXPR(GetContentType() == ContentType);
    }

    // clang-format off
    ShaderResourceCacheMtl             (const ShaderResourceCacheMtl&) = delete;
    ShaderResourceCacheMtl             (ShaderResourceCacheMtl&&)      = delete;
    ShaderResourceCacheMtl& operator = (const ShaderResourceCacheMtl&) = delete;
    ShaderResourceCacheMtl& operator = (ShaderResourceCacheMtl&&)      = delete;
    // clang-format on

    ~ShaderResourceCacheMtl();

    /// Returns the content type of this cache (SRB or Static Shader Resources)
    ResourceCacheContentType GetContentType() const
    {
        return static_cast<ResourceCacheContentType>(m_ContentType);
    }

    /// Returns the number of resources in the cache
    Uint32 GetTotalResources() const { return m_TotalResources; }

    /// Gets required memory size for the given number of resources
    static size_t GetRequiredMemorySize(Uint32 NumResources);

    /// Allocates memory for resources
    void InitializeResources(IMemoryAllocator& MemAllocator,
                             Uint32            NumResources);

    /// Sets a resource at the given index
    void SetResource(Uint32             Index,
                     Resource::Type     ResourceType,
                     IDeviceObject*     pObject);

    /// Gets a resource at the given index
    Resource& GetResource(Uint32 Index);
    const Resource& GetResource(Uint32 Index) const;

    /// Clears all resources
    void ClearResources();

#ifdef DILIGENT_DEBUG
    void DbgVerifyResourceInitialization() const;
#endif

private:
    Resource* GetFirstResourcePtr();
    const Resource* GetFirstResourcePtr() const;

private:
    Uint32 m_TotalResources = 0;
    Uint32 m_ContentType = 0;
    void*  m_pMemory = nullptr;
    IMemoryAllocator* m_pAllocator = nullptr;
};

} // namespace Diligent
