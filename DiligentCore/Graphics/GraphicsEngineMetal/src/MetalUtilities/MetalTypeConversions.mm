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

#include "MetalTypeConversions.h"

#import <Metal/Metal.h>

namespace Diligent
{

// Forward declarations for helper functions
MTLStorageMode GetStorageMode(USAGE Usage, CPU_ACCESS_FLAGS CpuAccess) noexcept;
MTLCPUCacheMode GetCPUCacheMode(CPU_ACCESS_FLAGS CpuAccess) noexcept;
MTLBlendOperation BlendOperationToMtlBlendOperation(BLEND_OPERATION Op) noexcept;
MTLVertexFormat ValueTypeToMtlVertexFormat(VALUE_TYPE ValType, Uint32 NumComponents, Bool IsNormalized) noexcept;

// Texture format conversions
MTLPixelFormat TexFormatToMtlPixelFormat(TEXTURE_FORMAT TexFmt) noexcept
{
    // Stub implementation - returns common formats
    switch (TexFmt)
    {
        case TEX_FORMAT_RGBA8_UNORM:    return MTLPixelFormatRGBA8Unorm;
        case TEX_FORMAT_RGBA8_UNORM_SRGB: return MTLPixelFormatRGBA8Unorm_sRGB;
        case TEX_FORMAT_BGRA8_UNORM:    return MTLPixelFormatBGRA8Unorm;
        case TEX_FORMAT_BGRA8_UNORM_SRGB: return MTLPixelFormatBGRA8Unorm_sRGB;
        case TEX_FORMAT_RGBA32_FLOAT:   return MTLPixelFormatRGBA32Float;
        case TEX_FORMAT_RGBA16_FLOAT:   return MTLPixelFormatRGBA16Float;
        case TEX_FORMAT_R32_FLOAT:      return MTLPixelFormatR32Float;
        case TEX_FORMAT_R16_FLOAT:      return MTLPixelFormatR16Float;
        case TEX_FORMAT_D32_FLOAT:      return MTLPixelFormatDepth32Float;
        case TEX_FORMAT_D16_UNORM:      return MTLPixelFormatDepth16Unorm;
        default:                         return MTLPixelFormatInvalid;
    }
}

TEXTURE_FORMAT MtlPixelFormatToTexFormat(MTLPixelFormat MtlFmt) noexcept
{
    // Stub implementation
    switch (MtlFmt)
    {
        case MTLPixelFormatRGBA8Unorm:     return TEX_FORMAT_RGBA8_UNORM;
        case MTLPixelFormatRGBA8Unorm_sRGB: return TEX_FORMAT_RGBA8_UNORM_SRGB;
        case MTLPixelFormatBGRA8Unorm:     return TEX_FORMAT_BGRA8_UNORM;
        case MTLPixelFormatBGRA8Unorm_sRGB: return TEX_FORMAT_BGRA8_UNORM_SRGB;
        case MTLPixelFormatRGBA32Float:    return TEX_FORMAT_RGBA32_FLOAT;
        case MTLPixelFormatRGBA16Float:    return TEX_FORMAT_RGBA16_FLOAT;
        case MTLPixelFormatR32Float:       return TEX_FORMAT_R32_FLOAT;
        case MTLPixelFormatR16Float:       return TEX_FORMAT_R16_FLOAT;
        case MTLPixelFormatDepth32Float:   return TEX_FORMAT_D32_FLOAT;
        case MTLPixelFormatDepth16Unorm:   return TEX_FORMAT_D16_UNORM;
        default:                            return TEX_FORMAT_UNKNOWN;
    }
}

// Primitive topology conversions
MTLPrimitiveType PrimitiveTopologyToMtlPrimitiveType(PRIMITIVE_TOPOLOGY Topology) noexcept
{
    switch (Topology)
    {
        case PRIMITIVE_TOPOLOGY_TRIANGLE_LIST:  return MTLPrimitiveTypeTriangle;
        case PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP: return MTLPrimitiveTypeTriangleStrip;
        case PRIMITIVE_TOPOLOGY_LINE_LIST:      return MTLPrimitiveTypeLine;
        case PRIMITIVE_TOPOLOGY_LINE_STRIP:     return MTLPrimitiveTypeLineStrip;
        case PRIMITIVE_TOPOLOGY_POINT_LIST:     return MTLPrimitiveTypePoint;
        default:                                 return MTLPrimitiveTypeTriangle;
    }
}

MTLPrimitiveTopologyClass TopologyToMtlTopologyClass(PRIMITIVE_TOPOLOGY Topology) noexcept
{
    switch (Topology)
    {
        case PRIMITIVE_TOPOLOGY_TRIANGLE_LIST:
        case PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP:
            return MTLPrimitiveTopologyClassTriangle;
        
        case PRIMITIVE_TOPOLOGY_LINE_LIST:
        case PRIMITIVE_TOPOLOGY_LINE_STRIP:
            return MTLPrimitiveTopologyClassLine;
        
        case PRIMITIVE_TOPOLOGY_POINT_LIST:
            return MTLPrimitiveTopologyClassPoint;
        
        default:
            return MTLPrimitiveTopologyClassUnspecified;
    }
}

// Comparison function conversion
MTLCompareFunction ComparisonFuncToMtlCompareFunction(COMPARISON_FUNCTION Func) noexcept
{
    switch (Func)
    {
        case COMPARISON_FUNC_NEVER:         return MTLCompareFunctionNever;
        case COMPARISON_FUNC_LESS:          return MTLCompareFunctionLess;
        case COMPARISON_FUNC_EQUAL:         return MTLCompareFunctionEqual;
        case COMPARISON_FUNC_LESS_EQUAL:    return MTLCompareFunctionLessEqual;
        case COMPARISON_FUNC_GREATER:       return MTLCompareFunctionGreater;
        case COMPARISON_FUNC_NOT_EQUAL:     return MTLCompareFunctionNotEqual;
        case COMPARISON_FUNC_GREATER_EQUAL: return MTLCompareFunctionGreaterEqual;
        case COMPARISON_FUNC_ALWAYS:        return MTLCompareFunctionAlways;
        default:                             return MTLCompareFunctionNever;
    }
}

// Stencil operation conversion
MTLStencilOperation StencilOpToMtlStencilOperation(STENCIL_OP Op) noexcept
{
    switch (Op)
    {
        case STENCIL_OP_KEEP:           return MTLStencilOperationKeep;
        case STENCIL_OP_ZERO:           return MTLStencilOperationZero;
        case STENCIL_OP_REPLACE:        return MTLStencilOperationReplace;
        case STENCIL_OP_INCR_SAT:       return MTLStencilOperationIncrementClamp;
        case STENCIL_OP_DECR_SAT:       return MTLStencilOperationDecrementClamp;
        case STENCIL_OP_INVERT:         return MTLStencilOperationInvert;
        case STENCIL_OP_INCR_WRAP:      return MTLStencilOperationIncrementWrap;
        case STENCIL_OP_DECR_WRAP:      return MTLStencilOperationDecrementWrap;
        default:                         return MTLStencilOperationKeep;
    }
}

// Blend conversions
MTLBlendFactor BlendFactorToMtlBlendFactor(BLEND_FACTOR Factor) noexcept
{
    switch (Factor)
    {
        case BLEND_FACTOR_ZERO:             return MTLBlendFactorZero;
        case BLEND_FACTOR_ONE:              return MTLBlendFactorOne;
        case BLEND_FACTOR_SRC_COLOR:        return MTLBlendFactorSourceColor;
        case BLEND_FACTOR_INV_SRC_COLOR:    return MTLBlendFactorOneMinusSourceColor;
        case BLEND_FACTOR_SRC_ALPHA:        return MTLBlendFactorSourceAlpha;
        case BLEND_FACTOR_INV_SRC_ALPHA:    return MTLBlendFactorOneMinusSourceAlpha;
        case BLEND_FACTOR_DEST_ALPHA:       return MTLBlendFactorDestinationAlpha;
        case BLEND_FACTOR_INV_DEST_ALPHA:   return MTLBlendFactorOneMinusDestinationAlpha;
        case BLEND_FACTOR_DEST_COLOR:       return MTLBlendFactorDestinationColor;
        case BLEND_FACTOR_INV_DEST_COLOR:   return MTLBlendFactorOneMinusDestinationColor;
        default:                             return MTLBlendFactorZero;
    }
}

MTLBlendOperation BlendOpToMtlBlendOperation(BLEND_OPERATION Op)
{
    return BlendOperationToMtlBlendOperation(Op);
}

MTLBlendOperation BlendOperationToMtlBlendOperation(BLEND_OPERATION Op) noexcept
{
    switch (Op)
    {
        case BLEND_OPERATION_ADD:           return MTLBlendOperationAdd;
        case BLEND_OPERATION_SUBTRACT:      return MTLBlendOperationSubtract;
        case BLEND_OPERATION_REV_SUBTRACT:  return MTLBlendOperationReverseSubtract;
        case BLEND_OPERATION_MIN:           return MTLBlendOperationMin;
        case BLEND_OPERATION_MAX:           return MTLBlendOperationMax;
        default:                             return MTLBlendOperationAdd;
    }
}

// Filter and address mode conversions
MTLSamplerMinMagFilter FilterTypeToMtlMinMagFilter(FILTER_TYPE Filter)
{
    switch (Filter)
    {
        case FILTER_TYPE_POINT:  return MTLSamplerMinMagFilterNearest;
        case FILTER_TYPE_LINEAR: return MTLSamplerMinMagFilterLinear;
        default:                 return MTLSamplerMinMagFilterNearest;
    }
}

MTLSamplerMinMagFilter FilterTypeToMtlFilter(FILTER_TYPE Filter) noexcept
{
    switch (Filter)
    {
        case FILTER_TYPE_POINT:  return MTLSamplerMinMagFilterNearest;
        case FILTER_TYPE_LINEAR: return MTLSamplerMinMagFilterLinear;
        default:                 return MTLSamplerMinMagFilterNearest;
    }
}

MTLSamplerMipFilter FilterTypeToMtlMipFilter(FILTER_TYPE Filter) noexcept
{
    switch (Filter)
    {
        case FILTER_TYPE_POINT:  return MTLSamplerMipFilterNearest;
        case FILTER_TYPE_LINEAR: return MTLSamplerMipFilterLinear;
        default:                 return MTLSamplerMipFilterNotMipmapped;
    }
}

MTLSamplerAddressMode AddressModeToMtlAddressMode(TEXTURE_ADDRESS_MODE Mode) noexcept
{
    switch (Mode)
    {
        case TEXTURE_ADDRESS_WRAP:           return MTLSamplerAddressModeRepeat;
        case TEXTURE_ADDRESS_MIRROR:         return MTLSamplerAddressModeMirrorRepeat;
        case TEXTURE_ADDRESS_CLAMP:          return MTLSamplerAddressModeClampToEdge;
        case TEXTURE_ADDRESS_BORDER:         return MTLSamplerAddressModeClampToBorderColor;
        case TEXTURE_ADDRESS_MIRROR_ONCE:    return MTLSamplerAddressModeMirrorClampToEdge;
        default:                              return MTLSamplerAddressModeClampToEdge;
    }
}

// Vertex format conversion
MTLVertexFormat InputLayoutFormatToMtlVertexFormat(VALUE_TYPE ValType, Uint32 NumComponents, Bool bIsNormalized)
{
    return ValueTypeToMtlVertexFormat(ValType, NumComponents, bIsNormalized);
}

MTLVertexFormat ValueTypeToMtlVertexFormat(VALUE_TYPE ValType, Uint32 NumComponents, Bool IsNormalized) noexcept
{
    // Stub implementation
    switch (ValType)
    {
        case VT_FLOAT32:
            switch (NumComponents)
            {
                case 1: return MTLVertexFormatFloat;
                case 2: return MTLVertexFormatFloat2;
                case 3: return MTLVertexFormatFloat3;
                case 4: return MTLVertexFormatFloat4;
            }
            break;
        
        case VT_UINT8:
            if (IsNormalized)
            {
                switch (NumComponents)
                {
                    case 4: return MTLVertexFormatUCharNormalized;
                }
            }
            break;
    }
    
    return MTLVertexFormatInvalid;
}

MTLVertexStepFunction InputElementFrequencyToMtlStepFunction(INPUT_ELEMENT_FREQUENCY Freq) noexcept
{
    switch (Freq)
    {
        case INPUT_ELEMENT_FREQUENCY_PER_VERTEX:   return MTLVertexStepFunctionPerVertex;
        case INPUT_ELEMENT_FREQUENCY_PER_INSTANCE: return MTLVertexStepFunctionPerInstance;
        default:                                    return MTLVertexStepFunctionPerVertex;
    }
}

// Resource state conversions
MTLResourceUsage ResourceStatesToMtlResourceUsage(RESOURCE_STATE States) noexcept
{
    MTLResourceUsage Usage = MTLResourceUsageRead;
    
    if (States & RESOURCE_STATE_UNORDERED_ACCESS)
        Usage |= MTLResourceUsageWrite;
    
    return Usage;
}

MTLRenderStages ResourceStatesToMtlRenderStages(RESOURCE_STATE States) noexcept
{
    MTLRenderStages Stages = MTLRenderStageVertex;
    
    if (States & RESOURCE_STATE_SHADER_RESOURCE)
        Stages |= MTLRenderStageFragment;
    
    return Stages;
}

// Miscellaneous conversions
MTLCullMode CullModeToMtlCullMode(CULL_MODE Mode) noexcept
{
    switch (Mode)
    {
        case CULL_MODE_NONE:  return MTLCullModeNone;
        case CULL_MODE_FRONT: return MTLCullModeFront;
        case CULL_MODE_BACK:  return MTLCullModeBack;
        default:              return MTLCullModeNone;
    }
}

MTLWinding FillModeToMtlWinding(FILL_MODE Mode) noexcept
{
    // Fill mode maps to winding order in Metal (clockwise vs counter-clockwise)
    return MTLWindingCounterClockwise; // Default
}

MTLTriangleFillMode FillModeToMtlFillMode(FILL_MODE Mode) noexcept
{
    switch (Mode)
    {
        case FILL_MODE_WIREFRAME: return MTLTriangleFillModeLines;
        case FILL_MODE_SOLID:     return MTLTriangleFillModeFill;
        default:                   return MTLTriangleFillModeFill;
    }
}

MTLIndexType IndexTypeToMtlIndexType(VALUE_TYPE IndexType) noexcept
{
    switch (IndexType)
    {
        case VT_UINT16: return MTLIndexTypeUInt16;
        case VT_UINT32: return MTLIndexTypeUInt32;
        default:        return MTLIndexTypeUInt16;
    }
}

// Memory and storage mode conversions
MTLStorageMode GetOptimalStorageMode(USAGE Usage, CPU_ACCESS_FLAGS CpuAccess) noexcept
{
    #if TARGET_OS_OSX
        if (CpuAccess & (CPU_ACCESS_READ | CPU_ACCESS_WRITE))
            return MTLStorageModeManaged;
        return MTLStorageModePrivate;
    #else
        return MTLStorageModeShared;
    #endif
}

MTLTextureType ResourceDimensionToMtlTextureType(RESOURCE_DIMENSION Dim, bool IsArray, bool IsMS) noexcept
{
    switch (Dim)
    {
        case RESOURCE_DIM_TEX_1D:
            return IsArray ? MTLTextureType1DArray : MTLTextureType1D;
        
        case RESOURCE_DIM_TEX_2D:
            if (IsMS) return MTLTextureType2DMultisample;
            return IsArray ? MTLTextureType2DArray : MTLTextureType2D;
        
        case RESOURCE_DIM_TEX_3D:
            return MTLTextureType3D;
        
        case RESOURCE_DIM_TEX_CUBE:
            return IsArray ? MTLTextureTypeCubeArray : MTLTextureTypeCube;
        
        default:
            return MTLTextureType2D;
    }
}

// Resource options
MTLResourceOptions GetResourceOptions(USAGE Usage, CPU_ACCESS_FLAGS CpuAccess, BIND_FLAGS BindFlags) noexcept
{
    MTLResourceOptions Options = 0;
    
    // Storage mode
    Options |= GetStorageMode(Usage, CpuAccess);
    
    // CPU cache mode
    Options |= GetCPUCacheMode(CpuAccess);
    
    return Options;
}

MTLStorageMode GetStorageMode(USAGE Usage, CPU_ACCESS_FLAGS CpuAccess) noexcept
{
    #if TARGET_OS_OSX
        if (CpuAccess != CPU_ACCESS_NONE)
        {
            // CPU accessible - use managed on macOS
            return MTLStorageModeManaged;
        }
        return MTLStorageModePrivate;
    #else
        // iOS always uses shared storage
        return MTLStorageModeShared;
    #endif
}

MTLCPUCacheMode GetCPUCacheMode(CPU_ACCESS_FLAGS CpuAccess) noexcept
{
    if (CpuAccess & CPU_ACCESS_WRITE)
        return MTLCPUCacheModeWriteCombined;
    return MTLCPUCacheModeDefaultCache;
}

} // namespace Diligent