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
    // Comprehensive format conversion - maps Diligent formats to Metal equivalents
    // Note: Metal doesn't have "typeless" formats, so we map them to the most common interpretation
    switch (TexFmt)
    {
        // RGBA 32-bit formats
        case TEX_FORMAT_RGBA8_TYPELESS:   return MTLPixelFormatRGBA8Unorm;
        case TEX_FORMAT_RGBA8_UNORM:     return MTLPixelFormatRGBA8Unorm;
        case TEX_FORMAT_RGBA8_UNORM_SRGB: return MTLPixelFormatRGBA8Unorm_sRGB;
        case TEX_FORMAT_RGBA8_UINT:      return MTLPixelFormatRGBA8Uint;
        case TEX_FORMAT_RGBA8_SNORM:     return MTLPixelFormatRGBA8Snorm;
        case TEX_FORMAT_RGBA8_SINT:      return MTLPixelFormatRGBA8Sint;
        
        // BGRA 32-bit formats
        case TEX_FORMAT_BGRA8_TYPELESS:   return MTLPixelFormatBGRA8Unorm;
        case TEX_FORMAT_BGRA8_UNORM:     return MTLPixelFormatBGRA8Unorm;
        case TEX_FORMAT_BGRA8_UNORM_SRGB: return MTLPixelFormatBGRA8Unorm_sRGB;
        
        // RGBA 64-bit formats
        case TEX_FORMAT_RGBA16_TYPELESS:  return MTLPixelFormatRGBA16Float;
        case TEX_FORMAT_RGBA16_FLOAT:    return MTLPixelFormatRGBA16Float;
        case TEX_FORMAT_RGBA16_UNORM:    return MTLPixelFormatRGBA16Unorm;
        case TEX_FORMAT_RGBA16_UINT:     return MTLPixelFormatRGBA16Uint;
        case TEX_FORMAT_RGBA16_SNORM:    return MTLPixelFormatRGBA16Snorm;
        case TEX_FORMAT_RGBA16_SINT:     return MTLPixelFormatRGBA16Sint;
        
        // RGBA 128-bit formats
        case TEX_FORMAT_RGBA32_TYPELESS:  return MTLPixelFormatRGBA32Float;
        case TEX_FORMAT_RGBA32_FLOAT:    return MTLPixelFormatRGBA32Float;
        case TEX_FORMAT_RGBA32_UINT:     return MTLPixelFormatRGBA32Uint;
        case TEX_FORMAT_RGBA32_SINT:     return MTLPixelFormatRGBA32Sint;
        
        // RG 32-bit formats
        case TEX_FORMAT_RG8_TYPELESS:     return MTLPixelFormatRG8Unorm;
        case TEX_FORMAT_RG8_UNORM:       return MTLPixelFormatRG8Unorm;
        case TEX_FORMAT_RG8_UINT:        return MTLPixelFormatRG8Uint;
        case TEX_FORMAT_RG8_SNORM:       return MTLPixelFormatRG8Snorm;
        case TEX_FORMAT_RG8_SINT:        return MTLPixelFormatRG8Sint;
        
        // RG 64-bit formats
        case TEX_FORMAT_RG16_TYPELESS:    return MTLPixelFormatRG16Float;
        case TEX_FORMAT_RG16_FLOAT:      return MTLPixelFormatRG16Float;
        case TEX_FORMAT_RG16_UNORM:      return MTLPixelFormatRG16Unorm;
        case TEX_FORMAT_RG16_UINT:       return MTLPixelFormatRG16Uint;
        case TEX_FORMAT_RG16_SNORM:      return MTLPixelFormatRG16Snorm;
        case TEX_FORMAT_RG16_SINT:       return MTLPixelFormatRG16Sint;
        
        // RG 128-bit formats
        case TEX_FORMAT_RG32_TYPELESS:    return MTLPixelFormatRG32Float;
        case TEX_FORMAT_RG32_FLOAT:      return MTLPixelFormatRG32Float;
        case TEX_FORMAT_RG32_UINT:       return MTLPixelFormatRG32Uint;
        case TEX_FORMAT_RG32_SINT:       return MTLPixelFormatRG32Sint;
        
        // R 16-bit formats
        case TEX_FORMAT_R16_TYPELESS:     return MTLPixelFormatR16Float;
        case TEX_FORMAT_R16_FLOAT:       return MTLPixelFormatR16Float;
        case TEX_FORMAT_R16_UNORM:       return MTLPixelFormatR16Unorm;
        case TEX_FORMAT_R16_UINT:        return MTLPixelFormatR16Uint;
        case TEX_FORMAT_R16_SNORM:       return MTLPixelFormatR16Snorm;
        case TEX_FORMAT_R16_SINT:        return MTLPixelFormatR16Sint;
        
        // R 32-bit formats
        case TEX_FORMAT_R32_TYPELESS:     return MTLPixelFormatR32Float;
        case TEX_FORMAT_R32_FLOAT:       return MTLPixelFormatR32Float;
        case TEX_FORMAT_R32_UINT:        return MTLPixelFormatR32Uint;
        case TEX_FORMAT_R32_SINT:        return MTLPixelFormatR32Sint;
        
        // Depth formats
        case TEX_FORMAT_D16_UNORM:       return MTLPixelFormatDepth16Unorm;
        case TEX_FORMAT_D24_UNORM_S8_UINT: return MTLPixelFormatDepth24Unorm_Stencil8;
        case TEX_FORMAT_D32_FLOAT:       return MTLPixelFormatDepth32Float;
        case TEX_FORMAT_D32_FLOAT_S8X24_UINT: return MTLPixelFormatDepth32Float_Stencil8;
        
        // Packed formats
        case TEX_FORMAT_R11G11B10_FLOAT: return MTLPixelFormatRG11B10Float;
        case TEX_FORMAT_RGB10A2_TYPELESS: return MTLPixelFormatRGB10A2Unorm;
        case TEX_FORMAT_RGB10A2_UNORM:   return MTLPixelFormatRGB10A2Unorm;
        case TEX_FORMAT_RGB10A2_UINT:    return MTLPixelFormatRGB10A2Uint;
        
        // BC compressed formats
        case TEX_FORMAT_BC1_TYPELESS:     return MTLPixelFormatBC1_RGBA;
        case TEX_FORMAT_BC1_UNORM:       return MTLPixelFormatBC1_RGBA;
        case TEX_FORMAT_BC1_UNORM_SRGB:  return MTLPixelFormatBC1_RGBA_sRGB;
        case TEX_FORMAT_BC2_TYPELESS:     return MTLPixelFormatBC2_RGBA;
        case TEX_FORMAT_BC2_UNORM:       return MTLPixelFormatBC2_RGBA;
        case TEX_FORMAT_BC2_UNORM_SRGB:  return MTLPixelFormatBC2_RGBA_sRGB;
        case TEX_FORMAT_BC3_TYPELESS:     return MTLPixelFormatBC3_RGBA;
        case TEX_FORMAT_BC3_UNORM:       return MTLPixelFormatBC3_RGBA;
        case TEX_FORMAT_BC3_UNORM_SRGB:  return MTLPixelFormatBC3_RGBA_sRGB;
        case TEX_FORMAT_BC4_TYPELESS:     return MTLPixelFormatBC4_RUnorm;
        case TEX_FORMAT_BC4_UNORM:       return MTLPixelFormatBC4_RUnorm;
        case TEX_FORMAT_BC4_SNORM:       return MTLPixelFormatBC4_RSnorm;
        case TEX_FORMAT_BC5_TYPELESS:     return MTLPixelFormatBC5_RGUnorm;
        case TEX_FORMAT_BC5_UNORM:       return MTLPixelFormatBC5_RGUnorm;
        case TEX_FORMAT_BC5_SNORM:       return MTLPixelFormatBC5_RGSnorm;
        case TEX_FORMAT_BC6H_TYPELESS:    return MTLPixelFormatBC6H_RGBFloat;
        case TEX_FORMAT_BC6H_UF16:       return MTLPixelFormatBC6H_RGBUfloat;
        case TEX_FORMAT_BC6H_SF16:       return MTLPixelFormatBC6H_RGBFloat;
        case TEX_FORMAT_BC7_TYPELESS:     return MTLPixelFormatBC7_RGBAUnorm;
        case TEX_FORMAT_BC7_UNORM:       return MTLPixelFormatBC7_RGBAUnorm;
        case TEX_FORMAT_BC7_UNORM_SRGB:  return MTLPixelFormatBC7_RGBAUnorm_sRGB;
        
        // ASTC compressed formats (for iOS/tvOS compatibility)
        #if !TARGET_OS_OSX
        case TEX_FORMAT_ASTC_4x4_UNORM:  return MTLPixelFormatASTC_4x4_LDR;
        case TEX_FORMAT_ASTC_4x4_UNORM_SRGB: return MTLPixelFormatASTC_4x4_sRGB;
        #endif
        
        default:                         return MTLPixelFormatInvalid;
    }
}

TEXTURE_FORMAT MtlPixelFormatToTexFormat(MTLPixelFormat MtlFmt) noexcept
{
    // Comprehensive reverse mapping
    switch (MtlFmt)
    {
        // RGBA 32-bit formats
        case MTLPixelFormatRGBA8Unorm:     return TEX_FORMAT_RGBA8_UNORM;
        case MTLPixelFormatRGBA8Unorm_sRGB: return TEX_FORMAT_RGBA8_UNORM_SRGB;
        case MTLPixelFormatRGBA8Uint:      return TEX_FORMAT_RGBA8_UINT;
        case MTLPixelFormatRGBA8Snorm:     return TEX_FORMAT_RGBA8_SNORM;
        case MTLPixelFormatRGBA8Sint:      return TEX_FORMAT_RGBA8_SINT;
        
        // BGRA 32-bit formats
        case MTLPixelFormatBGRA8Unorm:     return TEX_FORMAT_BGRA8_UNORM;
        case MTLPixelFormatBGRA8Unorm_sRGB: return TEX_FORMAT_BGRA8_UNORM_SRGB;
        
        // RGBA 64-bit formats
        case MTLPixelFormatRGBA16Float:    return TEX_FORMAT_RGBA16_FLOAT;
        case MTLPixelFormatRGBA16Unorm:    return TEX_FORMAT_RGBA16_UNORM;
        case MTLPixelFormatRGBA16Uint:     return TEX_FORMAT_RGBA16_UINT;
        case MTLPixelFormatRGBA16Snorm:    return TEX_FORMAT_RGBA16_SNORM;
        case MTLPixelFormatRGBA16Sint:     return TEX_FORMAT_RGBA16_SINT;
        
        // RGBA 128-bit formats
        case MTLPixelFormatRGBA32Float:    return TEX_FORMAT_RGBA32_FLOAT;
        case MTLPixelFormatRGBA32Uint:     return TEX_FORMAT_RGBA32_UINT;
        case MTLPixelFormatRGBA32Sint:     return TEX_FORMAT_RGBA32_SINT;
        
        // RG 32-bit formats
        case MTLPixelFormatRG8Unorm:       return TEX_FORMAT_RG8_UNORM;
        case MTLPixelFormatRG8Uint:        return TEX_FORMAT_RG8_UINT;
        case MTLPixelFormatRG8Snorm:       return TEX_FORMAT_RG8_SNORM;
        case MTLPixelFormatRG8Sint:        return TEX_FORMAT_RG8_SINT;
        
        // RG 64-bit formats
        case MTLPixelFormatRG16Float:      return TEX_FORMAT_RG16_FLOAT;
        case MTLPixelFormatRG16Unorm:      return TEX_FORMAT_RG16_UNORM;
        case MTLPixelFormatRG16Uint:       return TEX_FORMAT_RG16_UINT;
        case MTLPixelFormatRG16Snorm:      return TEX_FORMAT_RG16_SNORM;
        case MTLPixelFormatRG16Sint:       return TEX_FORMAT_RG16_SINT;
        
        // RG 128-bit formats
        case MTLPixelFormatRG32Float:      return TEX_FORMAT_RG32_FLOAT;
        case MTLPixelFormatRG32Uint:       return TEX_FORMAT_RG32_UINT;
        case MTLPixelFormatRG32Sint:       return TEX_FORMAT_RG32_SINT;
        
        // R 16-bit formats
        case MTLPixelFormatR16Float:       return TEX_FORMAT_R16_FLOAT;
        case MTLPixelFormatR16Unorm:       return TEX_FORMAT_R16_UNORM;
        case MTLPixelFormatR16Uint:        return TEX_FORMAT_R16_UINT;
        case MTLPixelFormatR16Snorm:       return TEX_FORMAT_R16_SNORM;
        case MTLPixelFormatR16Sint:        return TEX_FORMAT_R16_SINT;
        
        // R 32-bit formats
        case MTLPixelFormatR32Float:       return TEX_FORMAT_R32_FLOAT;
        case MTLPixelFormatR32Uint:        return TEX_FORMAT_R32_UINT;
        case MTLPixelFormatR32Sint:        return TEX_FORMAT_R32_SINT;
        
        // Depth formats
        case MTLPixelFormatDepth16Unorm:   return TEX_FORMAT_D16_UNORM;
        case MTLPixelFormatDepth24Unorm_Stencil8: return TEX_FORMAT_D24_UNORM_S8_UINT;
        case MTLPixelFormatDepth32Float:   return TEX_FORMAT_D32_FLOAT;
        case MTLPixelFormatDepth32Float_Stencil8: return TEX_FORMAT_D32_FLOAT_S8X24_UINT;
        
        // Packed formats
        case MTLPixelFormatRG11B10Float:   return TEX_FORMAT_R11G11B10_FLOAT;
        case MTLPixelFormatRGB10A2Unorm:   return TEX_FORMAT_RGB10A2_UNORM;
        case MTLPixelFormatRGB10A2Uint:    return TEX_FORMAT_RGB10A2_UINT;
        
        // BC compressed formats
        case MTLPixelFormatBC1_RGBA:       return TEX_FORMAT_BC1_UNORM;
        case MTLPixelFormatBC1_RGBA_sRGB:  return TEX_FORMAT_BC1_UNORM_SRGB;
        case MTLPixelFormatBC2_RGBA:       return TEX_FORMAT_BC2_UNORM;
        case MTLPixelFormatBC2_RGBA_sRGB:  return TEX_FORMAT_BC2_UNORM_SRGB;
        case MTLPixelFormatBC3_RGBA:       return TEX_FORMAT_BC3_UNORM;
        case MTLPixelFormatBC3_RGBA_sRGB:  return TEX_FORMAT_BC3_UNORM_SRGB;
        case MTLPixelFormatBC4_RUnorm:     return TEX_FORMAT_BC4_UNORM;
        case MTLPixelFormatBC4_RSnorm:     return TEX_FORMAT_BC4_SNORM;
        case MTLPixelFormatBC5_RGUnorm:    return TEX_FORMAT_BC5_UNORM;
        case MTLPixelFormatBC5_RGSnorm:    return TEX_FORMAT_BC5_SNORM;
        case MTLPixelFormatBC6H_RGBFloat:  return TEX_FORMAT_BC6H_SF16;
        case MTLPixelFormatBC6H_RGBUfloat: return TEX_FORMAT_BC6H_UF16;
        case MTLPixelFormatBC7_RGBAUnorm:  return TEX_FORMAT_BC7_UNORM;
        case MTLPixelFormatBC7_RGBAUnorm_sRGB: return TEX_FORMAT_BC7_UNORM_SRGB;
        
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