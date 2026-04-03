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
/// Declaration of Diligent::PipelineStateMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "PipelineStateBase.hpp"
#include "PipelineResourceSignatureMtlImpl.hpp"
#include "ShaderResourceBindingMtlImpl.hpp"
#include "FixedBlockMemoryAllocator.hpp"
#include "SRBMemoryAllocator.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

/// Pipeline state object implementation in Metal backend.
class PipelineStateMtlImpl final : public PipelineStateBase<EngineMtlImplTraits>
{
public:
    using TPipelineStateBase = PipelineStateBase<EngineMtlImplTraits>;

    static constexpr INTERFACE_ID IID_InternalImpl =
        {0xa1b2c3d4, 0xe5f6, 0x4789, {0xab, 0xcd, 0xef, 0x01, 0x23, 0x45, 0x67, 0x89}};

    PipelineStateMtlImpl(IReferenceCounters* pRefCounters, RenderDeviceMtlImpl* pDeviceMtl, const GraphicsPipelineStateCreateInfo& CreateInfo, bool bIsDeviceInternal = false);
    PipelineStateMtlImpl(IReferenceCounters* pRefCounters, RenderDeviceMtlImpl* pDeviceMtl, const ComputePipelineStateCreateInfo& CreateInfo, bool bIsDeviceInternal = false);
    ~PipelineStateMtlImpl();

    IMPLEMENT_QUERY_INTERFACE2_IN_PLACE(IID_PipelineStateMtl, IID_InternalImpl, TPipelineStateBase)

    /// Implementation of IPipelineStateMtl::GetMtlRenderPipeline().
    virtual id<MTLRenderPipelineState> DILIGENT_CALL_TYPE GetMtlRenderPipeline() const override final
    {
        return m_RenderPipelineState;
    }

    /// Implementation of IPipelineStateMtl::GetMtlComputePipeline().
    virtual id<MTLComputePipelineState> DILIGENT_CALL_TYPE GetMtlComputePipeline() const override final
    {
        return m_ComputePipelineState;
    }

    /// Implementation of IPipelineStateMtl::GetMtlDepthStencilState().
    virtual id<MTLDepthStencilState> DILIGENT_CALL_TYPE GetMtlDepthStencilState() const override final
    {
        return m_DepthStencilState;
    }

    /// Get the rasterizer state description
    const RasterizerStateDesc& GetRasterizerStateDesc() const { return m_RasterizerState; }

    /// Get the blend state description
    const BlendStateDesc& GetBlendStateDesc() const { return m_BlendState; }

    /// Get the depth stencil state description
    const DepthStencilStateDesc& GetDepthStencilStateDesc() const { return m_DepthStencilStateDesc; }

    /// Get the render pass
    IRenderPass* GetRenderPass() const { return m_pRenderPass; }

private:
    void InitializePipeline(const GraphicsPipelineStateCreateInfo& CreateInfo);
    void InitializePipeline(const ComputePipelineStateCreateInfo& CreateInfo);

    void CreateRenderPipeline(const GraphicsPipelineStateCreateInfo& CreateInfo);
    void CreateComputePipeline(const ComputePipelineStateCreateInfo& CreateInfo);
    void CreateDepthStencilState(const DepthStencilStateDesc& Desc);

    MTLVertexDescriptor* CreateVertexDescriptor(const InputLayoutDesc& InputLayout) const;
    void ConfigureColorAttachments(MTLRenderPipelineDescriptor* pDesc, const GraphicsPipelineDesc& GraphicsDesc) const;
    void ConfigureVertexFunction(MTLRenderPipelineDescriptor* pDesc, ShaderMtlImpl* pVS) const;
    void ConfigureFragmentFunction(MTLRenderPipelineDescriptor* pDesc, ShaderMtlImpl* pFS) const;

    // Metal pipeline objects
    id<MTLRenderPipelineState> m_RenderPipelineState = nil;
    id<MTLComputePipelineState> m_ComputePipelineState = nil;
    id<MTLDepthStencilState>    m_DepthStencilState = nil;

    // Pipeline state descriptions (needed for encoder-level state in Metal)
    RasterizerStateDesc    m_RasterizerState;
    BlendStateDesc         m_BlendState;
    DepthStencilStateDesc  m_DepthStencilStateDesc;

    // Render pass reference
    RefCntAutoPtr<IRenderPass> m_pRenderPass;
};

} // namespace Diligent
