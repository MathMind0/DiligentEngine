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
/// Declaration of Diligent::EngineMtlImplTraits struct

#include "RenderDeviceMtl.h"
#include "CommandQueueMtl.h"
#include "DeviceContextMtl.h"
#include "PipelineStateMtl.h"
#include "ShaderResourceBindingMtl.h"
#include "BufferMtl.h"
#include "BufferViewMtl.h"
#include "TextureMtl.h"
#include "TextureViewMtl.h"
#include "ShaderMtl.h"
#include "SamplerMtl.h"
#include "FenceMtl.h"
#include "QueryMtl.h"
#include "BottomLevelASMtl.h"
#include "TopLevelASMtl.h"
#include "DeviceMemoryMtl.h"
#include "PipelineStateCacheMtl.h"
#include "PipelineResourceAttribsMtl.hpp"

// Use base interfaces for types without Metal-specific interfaces yet
#include "RenderPassMtl.h"
#include "FramebufferMtl.h"
#include "ShaderBindingTable.h"
#include "PipelineResourceSignature.h"
#include "CommandList.h"

namespace Diligent
{

// Forward declarations (implementations will be defined later)
class RenderDeviceMtlImpl;
class DeviceContextMtlImpl;
class CommandQueueMtlImpl;
class PipelineStateMtlImpl;
class ShaderResourceBindingMtlImpl;
class BufferMtlImpl;
class BufferViewMtlImpl;
class TextureMtlImpl;
class TextureViewMtlImpl;
class ShaderMtlImpl;
class SamplerMtlImpl;
class FenceMtlImpl;
class QueryMtlImpl;
class RenderPassMtlImpl;
class FramebufferMtlImpl;
class BottomLevelASMtlImpl;
class TopLevelASMtlImpl;
class ShaderBindingTableMtlImpl;
class PipelineResourceSignatureMtlImpl;
class DeviceMemoryMtlImpl;
class PipelineStateCacheMtlImpl;

class FixedBlockMemoryAllocator;

// Forward declarations for resource cache and variable manager
class ShaderResourceCacheMtl;
class ShaderVariableManagerMtl;

/// Metal engine implementation traits
struct EngineMtlImplTraits
{
    static constexpr RENDER_DEVICE_TYPE DeviceType = RENDER_DEVICE_TYPE_METAL;

    using RenderDeviceInterface              = IRenderDeviceMtl;
    using DeviceContextInterface             = IDeviceContextMtl;
    using PipelineStateInterface             = IPipelineStateMtl;
    using ShaderResourceBindingInterface     = IShaderResourceBindingMtl;
    using BufferInterface                    = IBufferMtl;
    using BufferViewInterface                = IBufferViewMtl;
    using TextureInterface                   = ITextureMtl;
    using TextureViewInterface               = ITextureViewMtl;
    using ShaderInterface                    = IShaderMtl;
    using SamplerInterface                   = ISamplerMtl;
    using FenceInterface                     = IFenceMtl;
    using QueryInterface                     = IQueryMtl;
    using RenderPassInterface                = IRenderPassMtl;
    using FramebufferInterface               = IFramebufferMtl;
    using CommandListInterface               = ICommandList;
    using BottomLevelASInterface             = IBottomLevelASMtl;
    using TopLevelASInterface                = ITopLevelASMtl;
    using ShaderBindingTableInterface        = IShaderBindingTable;
    using PipelineResourceSignatureInterface = IPipelineResourceSignature;
    using CommandQueueInterface              = ICommandQueueMtl;
    using DeviceMemoryInterface              = IDeviceMemoryMtl;
    using PipelineStateCacheInterface        = IPipelineStateCacheMtl;
    using RenderDeviceImplType              = RenderDeviceMtlImpl;
    using DeviceContextImplType             = DeviceContextMtlImpl;
    using PipelineStateImplType             = PipelineStateMtlImpl;
    using ShaderResourceBindingImplType     = ShaderResourceBindingMtlImpl;
    using BufferImplType                    = BufferMtlImpl;
    using BufferViewImplType                = BufferViewMtlImpl;
    using TextureImplType                   = TextureMtlImpl;
    using TextureViewImplType               = TextureViewMtlImpl;
    using ShaderImplType                    = ShaderMtlImpl;
    using SamplerImplType                   = SamplerMtlImpl;
    using FenceImplType                     = FenceMtlImpl;
    using QueryImplType                     = QueryMtlImpl;
    using RenderPassImplType                = RenderPassMtlImpl;
    using FramebufferImplType               = FramebufferMtlImpl;
    using CommandQueueImplType              = CommandQueueMtlImpl;
    using BottomLevelASImplType             = BottomLevelASMtlImpl;
    using TopLevelASImplType                = TopLevelASMtlImpl;
    using ShaderBindingTableImplType        = ShaderBindingTableMtlImpl;
    using PipelineResourceSignatureImplType = PipelineResourceSignatureMtlImpl;
    using DeviceMemoryImplType              = DeviceMemoryMtlImpl;
    using PipelineStateCacheImplType        = PipelineStateCacheMtlImpl;

    using BuffViewObjAllocatorType = FixedBlockMemoryAllocator;
    using TexViewObjAllocatorType  = FixedBlockMemoryAllocator;
    
    // Resource cache and variable manager types
    using ShaderResourceCacheImplType   = ShaderResourceCacheMtl;
    using ShaderVariableManagerImplType = ShaderVariableManagerMtl;

    using PipelineResourceAttribsType               = PipelineResourceAttribsMtl;
    using ImmutableSamplerAttribsType               = ImmutableSamplerAttribsMtl;
    using InlineConstantBufferAttribsType           = InlineConstantBufferAttribsMtl;
    using PipelineResourceSignatureInternalDataType = PipelineResourceSignatureInternalDataMtl;
};

} // namespace Diligent
