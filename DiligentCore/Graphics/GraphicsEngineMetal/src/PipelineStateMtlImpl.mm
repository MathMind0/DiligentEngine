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
#include "PipelineStateMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "ShaderMtlImpl.hpp"
#include "MetalTypeConversions.h"
#include "GraphicsAccessories.hpp"

namespace Diligent
{

constexpr INTERFACE_ID PipelineStateMtlImpl::IID_InternalImpl;

PipelineStateMtlImpl::PipelineStateMtlImpl(IReferenceCounters*                   pRefCounters,
                                           RenderDeviceMtlImpl*                  pDeviceMtl,
                                           const GraphicsPipelineStateCreateInfo& CreateInfo,
                                           bool                                   bIsDeviceInternal) :
    TPipelineStateBase{pRefCounters, pDeviceMtl, CreateInfo, bIsDeviceInternal}
{
    InitializePipeline(CreateInfo);
}

PipelineStateMtlImpl::PipelineStateMtlImpl(IReferenceCounters*                  pRefCounters,
                                           RenderDeviceMtlImpl*                 pDeviceMtl,
                                           const ComputePipelineStateCreateInfo& CreateInfo,
                                           bool                                  bIsDeviceInternal) :
    TPipelineStateBase{pRefCounters, pDeviceMtl, CreateInfo, bIsDeviceInternal}
{
    InitializePipeline(CreateInfo);
}

PipelineStateMtlImpl::~PipelineStateMtlImpl()
{
    Destruct();
}

void PipelineStateMtlImpl::Destruct()
{
    // Metal objects are reference-counted and will be released automatically
    TPipelineStateBase::Destruct();
}

void PipelineStateMtlImpl::InitializePipeline(const GraphicsPipelineStateCreateInfo& CreateInfo)
{
    const auto& GraphicsDesc = CreateInfo.GraphicsPipeline;

    // Store pipeline state descriptions for encoder-level state
    m_RasterizerState = GraphicsDesc.RasterizerDesc;
    m_BlendState = GraphicsDesc.BlendDesc;
    m_DepthStencilStateDesc = GraphicsDesc.DepthStencilDesc;

    // Store render pass reference
    if (GraphicsDesc.pRenderPass != nullptr)
    {
        m_pRenderPass = GraphicsDesc.pRenderPass;
    }

    CreateRenderPipeline(CreateInfo);
    CreateDepthStencilState(GraphicsDesc.DepthStencilDesc);
}

void PipelineStateMtlImpl::InitializePipeline(const ComputePipelineStateCreateInfo& CreateInfo)
{
    CreateComputePipeline(CreateInfo);
}

void PipelineStateMtlImpl::CreateRenderPipeline(const GraphicsPipelineStateCreateInfo& CreateInfo)
{
    auto* pDevice = GetDevice();
    id<MTLDevice> mtlDevice = pDevice->GetMtlDevice();

    @autoreleasepool
    {
        MTLRenderPipelineDescriptor* pDesc = [[MTLRenderPipelineDescriptor alloc] init];

        // Set pipeline label
        pDesc.label = [NSString stringWithUTF8String:CreateInfo.PSODesc.Name];

        // Configure vertex shader
        ShaderMtlImpl* pVS = nullptr;
        if (CreateInfo.pVS != nullptr)
        {
            pVS = ClassPtrCast<ShaderMtlImpl>(CreateInfo.pVS);
            ConfigureVertexFunction(pDesc, pVS);
        }

        // Configure fragment shader
        ShaderMtlImpl* pFS = nullptr;
        if (CreateInfo.pPS != nullptr)
        {
            pFS = ClassPtrCast<ShaderMtlImpl>(CreateInfo.pPS);
            ConfigureFragmentFunction(pDesc, pFS);
        }

        // Configure vertex input layout
        const auto& InputLayout = CreateInfo.GraphicsPipeline.InputLayout;
        if (InputLayout.NumElements > 0)
        {
            pDesc.vertexDescriptor = CreateVertexDescriptor(InputLayout);
        }

        // Configure color attachments
        ConfigureColorAttachments(pDesc, CreateInfo.GraphicsPipeline);

        // Configure sample count (use rasterSampleCount instead of deprecated sampleCount)
        pDesc.rasterSampleCount = CreateInfo.GraphicsPipeline.SmplDesc.Count;

        // Create the render pipeline state
        NSError* pError = nil;
        m_RenderPipelineState = [mtlDevice newRenderPipelineStateWithDescriptor:pDesc error:&pError];

        if (m_RenderPipelineState == nil || pError != nil)
        {
            LOG_ERROR_MESSAGE("Failed to create Metal render pipeline state: ",
                             pError != nil ? [[pError localizedDescription] UTF8String] : "Unknown error");
        }
    }
}

void PipelineStateMtlImpl::CreateComputePipeline(const ComputePipelineStateCreateInfo& CreateInfo)
{
    auto* pDevice = GetDevice();
    id<MTLDevice> mtlDevice = pDevice->GetMtlDevice();

    @autoreleasepool
    {
        MTLComputePipelineDescriptor* pDesc = [[MTLComputePipelineDescriptor alloc] init];

        // Set pipeline label
        pDesc.label = [NSString stringWithUTF8String:CreateInfo.PSODesc.Name];

        // Configure compute shader
        if (CreateInfo.pCS != nullptr)
        {
            ShaderMtlImpl* pCS = ClassPtrCast<ShaderMtlImpl>(CreateInfo.pCS);
            id<MTLFunction> mtlFunction = pCS->GetMtlShaderFunction();
            if (mtlFunction != nil)
            {
                pDesc.computeFunction = mtlFunction;
            }
        }

        // Create the compute pipeline state
        NSError* pError = nil;
        m_ComputePipelineState = [mtlDevice newComputePipelineStateWithDescriptor:pDesc
                                                                           options:MTLPipelineOptionNone
                                                                        reflection:nil
                                                                             error:&pError];

        if (m_ComputePipelineState == nil || pError != nil)
        {
            LOG_ERROR_MESSAGE("Failed to create Metal compute pipeline state: ",
                             pError != nil ? [[pError localizedDescription] UTF8String] : "Unknown error");
        }
    }
}

void PipelineStateMtlImpl::CreateDepthStencilState(const DepthStencilStateDesc& Desc)
{
    auto* pDevice = GetDevice();
    id<MTLDevice> mtlDevice = pDevice->GetMtlDevice();

    @autoreleasepool
    {
        MTLDepthStencilDescriptor* pDesc = [[MTLDepthStencilDescriptor alloc] init];

        // Configure depth state
        pDesc.depthCompareFunction = ComparisonFuncToMtlCompareFunction(Desc.DepthFunc);
        pDesc.depthWriteEnabled = Desc.DepthEnable ? YES : NO;

        // Configure stencil state (front face)
        MTLStencilDescriptor* pFrontStencil = [[MTLStencilDescriptor alloc] init];
        pFrontStencil.stencilCompareFunction = ComparisonFuncToMtlCompareFunction(Desc.FrontFace.StencilFunc);
        pFrontStencil.stencilFailureOperation = StencilOpToMtlStencilOperation(Desc.FrontFace.StencilFailOp);
        pFrontStencil.depthFailureOperation = StencilOpToMtlStencilOperation(Desc.FrontFace.StencilDepthFailOp);
        pFrontStencil.depthStencilPassOperation = StencilOpToMtlStencilOperation(Desc.FrontFace.StencilPassOp);
        pFrontStencil.readMask = Desc.StencilReadMask;
        pFrontStencil.writeMask = Desc.StencilWriteMask;
        pDesc.frontFaceStencil = pFrontStencil;

        // Configure stencil state (back face)
        MTLStencilDescriptor* pBackStencil = [[MTLStencilDescriptor alloc] init];
        pBackStencil.stencilCompareFunction = ComparisonFuncToMtlCompareFunction(Desc.BackFace.StencilFunc);
        pBackStencil.stencilFailureOperation = StencilOpToMtlStencilOperation(Desc.BackFace.StencilFailOp);
        pBackStencil.depthFailureOperation = StencilOpToMtlStencilOperation(Desc.BackFace.StencilDepthFailOp);
        pBackStencil.depthStencilPassOperation = StencilOpToMtlStencilOperation(Desc.BackFace.StencilPassOp);
        pBackStencil.readMask = Desc.StencilReadMask;
        pBackStencil.writeMask = Desc.StencilWriteMask;
        pDesc.backFaceStencil = pBackStencil;

        // Create depth-stencil state
        m_DepthStencilState = [mtlDevice newDepthStencilStateWithDescriptor:pDesc];
    }
}

MTLVertexDescriptor* PipelineStateMtlImpl::CreateVertexDescriptor(const InputLayoutDesc& InputLayout) const
{
    MTLVertexDescriptor* pVertexDesc = [[MTLVertexDescriptor alloc] init];

    // Group attributes by buffer slot
    std::unordered_map<Uint32, std::vector<LayoutElement>> BufferElements;
    for (Uint32 i = 0; i < InputLayout.NumElements; ++i)
    {
        const auto& Elem = InputLayout.LayoutElements[i];
        BufferElements[Elem.BufferSlot].push_back(Elem);
    }

    // Configure each buffer
    for (const auto& [BufferSlot, Elements] : BufferElements)
    {
        // Configure buffer layout
        MTLVertexBufferLayoutDescriptor* pLayout = pVertexDesc.layouts[BufferSlot];
        if (!Elements.empty())
        {
            const auto& FirstElem = Elements[0];
            pLayout.stride = FirstElem.Stride;
            pLayout.stepFunction = FirstElem.Frequency == INPUT_ELEMENT_FREQUENCY_PER_VERTEX
                                     ? MTLVertexStepFunctionPerVertex
                                     : MTLVertexStepFunctionPerInstance;
            pLayout.stepRate = static_cast<NSUInteger>(FirstElem.InstanceDataStepRate);
        }

        // Configure attributes
        for (const auto& Elem : Elements)
        {
            MTLVertexAttributeDescriptor* pAttr = pVertexDesc.attributes[Elem.InputIndex];
            pAttr.format = ValueTypeToMtlVertexFormat(Elem.ValueType, Elem.NumComponents, Elem.IsNormalized);
            pAttr.offset = static_cast<NSUInteger>(Elem.RelativeOffset);
            pAttr.bufferIndex = static_cast<NSUInteger>(Elem.BufferSlot);
        }
    }

    return pVertexDesc;
}

void PipelineStateMtlImpl::ConfigureColorAttachments(MTLRenderPipelineDescriptor* pDesc,
                                                      const GraphicsPipelineDesc& GraphicsDesc) const
{
    const auto& BlendDesc = GraphicsDesc.BlendDesc;

    for (Uint32 i = 0; i < GraphicsDesc.NumRenderTargets; ++i)
    {
        MTLPixelFormat pixelFormat = TexFormatToMtlPixelFormat(GraphicsDesc.RTVFormats[i]);
        if (pixelFormat != MTLPixelFormatInvalid)
        {
            pDesc.colorAttachments[i].pixelFormat = pixelFormat;

            // Configure blend state for this attachment
            if (BlendDesc.RenderTargets[i].BlendEnable)
            {
                const auto& RTBlend = BlendDesc.RenderTargets[i];
                pDesc.colorAttachments[i].blendingEnabled = YES;
                pDesc.colorAttachments[i].sourceRGBBlendFactor = BlendFactorToMtlBlendFactor(RTBlend.SrcBlend);
                pDesc.colorAttachments[i].destinationRGBBlendFactor = BlendFactorToMtlBlendFactor(RTBlend.DestBlend);
                pDesc.colorAttachments[i].rgbBlendOperation = BlendOperationToMtlBlendOperation(RTBlend.BlendOp);
                pDesc.colorAttachments[i].sourceAlphaBlendFactor = BlendFactorToMtlBlendFactor(RTBlend.SrcBlendAlpha);
                pDesc.colorAttachments[i].destinationAlphaBlendFactor = BlendFactorToMtlBlendFactor(RTBlend.DestBlendAlpha);
                pDesc.colorAttachments[i].alphaBlendOperation = BlendOperationToMtlBlendOperation(RTBlend.BlendOpAlpha);
                pDesc.colorAttachments[i].writeMask = static_cast<MTLColorWriteMask>(RTBlend.RenderTargetWriteMask);
            }
        }
    }

    // Configure depth attachment format
    if (GraphicsDesc.DSVFormat != TEX_FORMAT_UNKNOWN)
    {
        pDesc.depthAttachmentPixelFormat = TexFormatToMtlPixelFormat(GraphicsDesc.DSVFormat);
    }
}

void PipelineStateMtlImpl::ConfigureVertexFunction(MTLRenderPipelineDescriptor* pDesc, ShaderMtlImpl* pVS) const
{
    if (pVS != nullptr)
    {
        id<MTLFunction> mtlFunction = pVS->GetMtlShaderFunction();
        if (mtlFunction != nil)
        {
            pDesc.vertexFunction = mtlFunction;
        }
    }
}

void PipelineStateMtlImpl::ConfigureFragmentFunction(MTLRenderPipelineDescriptor* pDesc, ShaderMtlImpl* pFS) const
{
    if (pFS != nullptr)
    {
        id<MTLFunction> mtlFunction = pFS->GetMtlShaderFunction();
        if (mtlFunction != nil)
        {
            pDesc.fragmentFunction = mtlFunction;
        }
    }
}

} // namespace Diligent
