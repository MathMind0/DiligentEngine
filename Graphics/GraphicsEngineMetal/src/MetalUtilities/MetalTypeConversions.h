/*
 *  Copyright 2019-2025 Diligent Graphics LLC
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
/// Metal type conversion routines

#import <Metal/Metal.h>

#include "GraphicsTypes.h"

namespace Diligent
{

MTLPixelFormat   TexFormatToMtlPixelFormat(TEXTURE_FORMAT TexFmt) noexcept;
TEXTURE_FORMAT   MtlPixelFormatToTexFormat(MTLPixelFormat MtlFmt) noexcept;

MTLVertexFormat  InputLayoutFormatToMtlVertexFormat(VALUE_TYPE ValType, Uint32 NumComponents, Bool bIsNormalized);
MTLIndexType     TypeToMtlIndexType(VALUE_TYPE IndexType);
MTLPrimitiveType PrimitiveTopologyToMtlPrimitiveType(PRIMITIVE_TOPOLOGY Topology) noexcept;
MTLCompareFunction ComparisonFuncToMtlCompareFunction(COMPARISON_FUNCTION CmpFunc) noexcept;
MTLStencilOperation StencilOpToMtlStencilOperation(STENCIL_OP StencilOp) noexcept;
MTLBlendOperation BlendOpToMtlBlendOperation(BLEND_OPERATION BlendOp);
MTLBlendFactor BlendFactorToMtlBlendFactor(BLEND_FACTOR BlendFactor) noexcept;
MTLSamplerAddressMode AddressModeToMtlAddressMode(TEXTURE_ADDRESS_MODE AddressMode) noexcept;
MTLSamplerMinMagFilter FilterTypeToMtlMinMagFilter(FILTER_TYPE FilterType);
MTLSamplerMipFilter FilterTypeToMtlMipFilter(FILTER_TYPE FilterType) noexcept;

} // namespace Diligent