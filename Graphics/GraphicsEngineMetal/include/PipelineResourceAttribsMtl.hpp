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

#pragma once

/// \file
/// Declaration of Diligent::PipelineResourceAttribsMtl struct

#include "BasicTypes.h"
#include "ShaderResourceCacheCommon.hpp"
#include "PrivateConstants.h"
#include "DebugUtilities.hpp"
#include "HashUtils.hpp"

namespace Diligent
{

/// Resource binding type for Metal
enum class MtlResourceType : Uint8
{
    ConstantBuffer,       // Uniform buffer (MTLBuffer)
    StructuredBuffer,     // Shader storage buffer (MTLBuffer)
    FormattedBuffer,      // Texel buffer (MTLBuffer with texture view)
    TextureSRV,           // Texture read (MTLTexture)
    TextureUAV,           // Texture read/write (MTLTexture)
    BufferUAV,            // Buffer read/write (MTLBuffer)
    Sampler,              // Sampler state (MTLSamplerState)
    AccelerationStructure,// Ray tracing acceleration structure
    InputAttachment,      // Input attachment (subpass input)
    Count,
    Unknown = 255,
};

// sizeof(PipelineResourceAttribsMtl) == 16, x64
struct PipelineResourceAttribsMtl
{
private:
    static constexpr Uint32 _BindingIndexBits    = 16;
    static constexpr Uint32 _SamplerIndBits      = 16;
    static constexpr Uint32 _ArraySizeBits       = 24;
    static constexpr Uint32 _ResourceTypeBits    = 8;

    static_assert((_BindingIndexBits + _SamplerIndBits + _ArraySizeBits + _ResourceTypeBits) == 64, "Bits are not optimally packed");

public:
    static constexpr Uint32 InvalidSamplerInd = (1u << _SamplerIndBits) - 1;

    // clang-format off
    const Uint32  BindingIndex    : _BindingIndexBits;  // Binding index in the resource table
    const Uint32  SamplerInd      : _SamplerIndBits;    // Index of the assigned sampler
    const Uint32  ArraySize       : _ArraySizeBits;     // Array size
    const Uint32  ResourceType    : _ResourceTypeBits;  // MtlResourceType

    const Uint32  SRBCacheOffset;                       // Offset in the SRB resource cache
    const Uint32  StaticCacheOffset;                    // Offset in the static resource cache
    // clang-format on

    PipelineResourceAttribsMtl(Uint32          _BindingIndex,
                               Uint32          _ArraySize,
                               MtlResourceType _ResourceType,
                               Uint32          _SamplerInd,
                               Uint32          _SRBCacheOffset    = 0,
                               Uint32          _StaticCacheOffset = 0) noexcept :
        // clang-format off
        BindingIndex    {_BindingIndex                     },
        SamplerInd      {_SamplerInd                       },
        ArraySize       {_ArraySize                        },
        ResourceType    {static_cast<Uint32>(_ResourceType)},
        SRBCacheOffset  {_SRBCacheOffset                   },
        StaticCacheOffset {_StaticCacheOffset              }
    // clang-format on
    {
        // clang-format off
        VERIFY(BindingIndex    == _BindingIndex, "Binding index (", _BindingIndex, ") exceeds maximum representable value");
        VERIFY(ArraySize       == _ArraySize,    "Array size (", _ArraySize, ") exceeds maximum representable value");
        VERIFY(GetResourceType() == _ResourceType, "Resource type (", static_cast<Uint32>(_ResourceType), ") exceeds maximum representable value");
        VERIFY(SamplerInd      == _SamplerInd,   "Sampler index (", _SamplerInd, ") exceeds maximum representable value");
        // clang-format on
    }

    // Only for serialization
    PipelineResourceAttribsMtl() noexcept :
        PipelineResourceAttribsMtl{0, 0, MtlResourceType::Unknown, InvalidSamplerInd, 0, 0}
    {}

    Uint32 CacheOffset(ResourceCacheContentType CacheType) const
    {
        return CacheType == ResourceCacheContentType::SRB ? SRBCacheOffset : StaticCacheOffset;
    }

    MtlResourceType GetResourceType() const
    {
        return static_cast<MtlResourceType>(ResourceType);
    }

    bool IsCombinedWithSampler() const
    {
        return SamplerInd != InvalidSamplerInd;
    }

    bool IsCompatibleWith(const PipelineResourceAttribsMtl& rhs) const
    {
        // Ignore sampler index and cache offsets.
        // clang-format off
        return BindingIndex == rhs.BindingIndex &&
               ArraySize    == rhs.ArraySize    &&
               ResourceType == rhs.ResourceType;
        // clang-format on
    }

    size_t GetHash() const
    {
        return ComputeHash(BindingIndex, ArraySize, ResourceType);
    }
};
ASSERT_SIZEOF(PipelineResourceAttribsMtl, 16, "The struct is used in serialization and must be tightly packed");

/// Immutable sampler attributes for Metal
struct ImmutableSamplerAttribsMtl
{
    // Metal immutable samplers are stored directly in the shader
    // This struct is minimal for compatibility with the base class
    
    Uint32 SamplerIndex = 0;

    ImmutableSamplerAttribsMtl() noexcept = default;

    explicit ImmutableSamplerAttribsMtl(Uint32 _SamplerIndex) noexcept :
        SamplerIndex{_SamplerIndex}
    {}

    bool operator==(const ImmutableSamplerAttribsMtl& rhs) const
    {
        return SamplerIndex == rhs.SamplerIndex;
    }

    size_t GetHash() const
    {
        return ComputeHash(SamplerIndex);
    }
};

/// Inline constant buffer attributes for Metal
struct InlineConstantBufferAttribsMtl
{
    // Metal uses argument buffers for constant data
    // This struct provides minimal compatibility
    
    Uint32 BufferIndex = 0;
    Uint32 Size        = 0;

    InlineConstantBufferAttribsMtl() noexcept = default;

    InlineConstantBufferAttribsMtl(Uint32 _BufferIndex, Uint32 _Size) noexcept :
        BufferIndex{_BufferIndex},
        Size{_Size}
    {}

    bool operator==(const InlineConstantBufferAttribsMtl& rhs) const
    {
        return BufferIndex == rhs.BufferIndex && Size == rhs.Size;
    }

    size_t GetHash() const
    {
        return ComputeHash(BufferIndex, Size);
    }
};

/// Pipeline resource signature internal data for Metal
struct PipelineResourceSignatureInternalDataMtl
{
    // Metal-specific internal data
    // Currently minimal for compatibility
    
    Uint32 ArgumentBufferIndex = 0;
    
    PipelineResourceSignatureInternalDataMtl() noexcept = default;
    
    explicit PipelineResourceSignatureInternalDataMtl(Uint32 _ArgumentBufferIndex) noexcept :
        ArgumentBufferIndex{_ArgumentBufferIndex}
    {}
};

} // namespace Diligent
