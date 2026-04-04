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

#include "DeviceContextMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"

// Include implementation headers for complete type definitions needed by base classes
#include "BufferMtlImpl.hpp"
#include "TextureMtlImpl.hpp"
#include "TextureViewMtlImpl.hpp"
#include "FramebufferMtlImpl.hpp"
#include "RenderPassMtlImpl.hpp"
#include "PipelineStateMtlImpl.hpp"
#include "SparseTextureManagerMtlImpl.hpp"
#include "DeviceMemoryMtlImpl.hpp"

#include "DebugUtilities.hpp"
#include "GraphicsAccessories.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

DeviceContextMtlImpl::DeviceContextMtlImpl(IReferenceCounters*      pRefCounters,
                                           RenderDeviceMtlImpl*     pDevice,
                                           const DeviceContextDesc& Desc) :
    TDeviceContextBase{pRefCounters, pDevice, Desc}
{
}

DeviceContextMtlImpl::~DeviceContextMtlImpl()
{
}

id<MTLCommandBuffer> DILIGENT_CALL_TYPE DeviceContextMtlImpl::GetMtlCommandBuffer()
{
    return m_mtlCommandBuffer;
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::SetComputeThreadgroupMemoryLength(Uint32 Length, Uint32 Index)
{
    LOG_ERROR_MESSAGE("SetComputeThreadgroupMemoryLength is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::SetTileThreadgroupMemoryLength(Uint32 Length, Uint32 Offset, Uint32 Index)
{
    LOG_ERROR_MESSAGE("SetTileThreadgroupMemoryLength is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::Begin(Uint32 ImmediateContextId)
{
    LOG_ERROR_MESSAGE("Begin is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::SetPipelineState(IPipelineState* pPipelineState)
{
    if (pPipelineState == nullptr)
    {
        m_pPipelineState.Release();
        return;
    }
    
    m_pPipelineState = ClassPtrCast<PipelineStateMtlImpl>(pPipelineState);
    
    // Apply pipeline state to the current render encoder if we're in a render pass
    if (m_RenderEncoder != nil && m_pPipelineState != nullptr)
    {
        id<MTLRenderPipelineState> renderPipeline = m_pPipelineState->GetMtlRenderPipeline();
        if (renderPipeline != nil)
        {
            [m_RenderEncoder setRenderPipelineState:renderPipeline];
        }
        
        id<MTLDepthStencilState> depthStencilState = m_pPipelineState->GetMtlDepthStencilState();
        if (depthStencilState != nil)
        {
            [m_RenderEncoder setDepthStencilState:depthStencilState];
        }
    }
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::TransitionShaderResources(IShaderResourceBinding* pShaderResourceBinding)
{
    LOG_ERROR_MESSAGE("TransitionShaderResources is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::CommitShaderResources(IShaderResourceBinding* pShaderResourceBinding, RESOURCE_STATE_TRANSITION_MODE StateTransitionMode)
{
    LOG_ERROR_MESSAGE("CommitShaderResources is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::SetStencilRef(Uint32 StencilRef)
{
    LOG_ERROR_MESSAGE("SetStencilRef is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::SetBlendFactors(const float* pBlendFactors)
{
    LOG_ERROR_MESSAGE("SetBlendFactors is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::SetVertexBuffers(Uint32                         StartSlot,
                                                               Uint32                         NumBuffersSet,
                                                               IBuffer* const*                ppBuffers,
                                                               const Uint64*                  pOffsets,
                                                               RESOURCE_STATE_TRANSITION_MODE StateTransitionMode,
                                                               SET_VERTEX_BUFFERS_FLAGS       Flags)
{
    for (Uint32 i = 0; i < NumBuffersSet; ++i)
    {
        Uint32 slot = StartSlot + i;
        if (slot >= MAX_VERTEX_BUFFERS)
        {
            LOG_WARNING_MESSAGE("Vertex buffer slot ", slot, " exceeds maximum (", MAX_VERTEX_BUFFERS, ")");
            continue;
        }
        
        if (ppBuffers[i] != nullptr)
        {
            BufferMtlImpl* pBuffer = ClassPtrCast<BufferMtlImpl>(ppBuffers[i]);
            m_VertexBuffers[slot] = pBuffer->GetMtlResource();
            m_VertexBufferOffsets[slot] = pOffsets != nullptr ? static_cast<NSUInteger>(pOffsets[i]) : 0;
            
            // Apply to render encoder if active
            if (m_RenderEncoder != nil)
            {
                [m_RenderEncoder setVertexBuffer:m_VertexBuffers[slot] offset:m_VertexBufferOffsets[slot] atIndex:slot];
            }
        }
        else
        {
            m_VertexBuffers[slot] = nil;
            m_VertexBufferOffsets[slot] = 0;
        }
    }
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::InvalidateState()
{
    LOG_ERROR_MESSAGE("InvalidateState is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::SetIndexBuffer(IBuffer* pIndexBuffer, Uint64 ByteOffset, RESOURCE_STATE_TRANSITION_MODE StateTransitionMode)
{
    if (pIndexBuffer != nullptr)
    {
        BufferMtlImpl* pBuffer = ClassPtrCast<BufferMtlImpl>(pIndexBuffer);
        m_IndexBuffer = pBuffer->GetMtlResource();
        m_IndexBufferOffset = static_cast<NSUInteger>(ByteOffset);
        
        // Determine index type based on buffer format
        const auto& desc = pBuffer->GetDesc();
        m_IndexType = desc.ElementByteStride == 4 ? MTLIndexTypeUInt32 : MTLIndexTypeUInt16;
    }
    else
    {
        m_IndexBuffer = nil;
        m_IndexBufferOffset = 0;
    }
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::SetViewports(Uint32 NumViewports, const Viewport* pViewports, Uint32 RTWidth, Uint32 RTHeight)
{
    LOG_ERROR_MESSAGE("SetViewports is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::SetScissorRects(Uint32 NumRects, const Rect* pRects, Uint32 RTWidth, Uint32 RTHeight)
{
    LOG_ERROR_MESSAGE("SetScissorRects is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::SetRenderTargetsExt(const SetRenderTargetsAttribs& Attribs)
{
    // End current render pass if any
    if (m_InRenderPass && m_RenderEncoder != nil)
    {
        [m_RenderEncoder endEncoding];
        m_RenderEncoder = nil;
        m_InRenderPass = false;
    }
    
    // Store render targets
    m_RenderTargets.clear();
    for (Uint32 i = 0; i < Attribs.NumRenderTargets; ++i)
    {
        if (Attribs.ppRenderTargets[i] != nullptr)
        {
            m_RenderTargets.push_back(RefCntAutoPtr<ITextureView>(Attribs.ppRenderTargets[i]));
        }
    }
    m_pDepthStencilTarget = Attribs.pDepthStencil;
    
    // Create render pass descriptor
    m_RenderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
    
    // Configure color attachments
    for (Uint32 i = 0; i < m_RenderTargets.size(); ++i)
    {
        if (m_RenderTargets[i] != nullptr)
        {
            TextureViewMtlImpl* pRTV = static_cast<TextureViewMtlImpl*>(m_RenderTargets[i].RawPtr());
            id<MTLTexture> texture = pRTV->GetMtlTexture();
            if (texture != nil)
            {
                m_RenderPassDescriptor.colorAttachments[i].texture = texture;
                m_RenderPassDescriptor.colorAttachments[i].loadAction = MTLLoadActionLoad;
                m_RenderPassDescriptor.colorAttachments[i].storeAction = MTLStoreActionStore;
            }
        }
    }
    
    // Configure depth stencil attachment
    if (m_pDepthStencilTarget != nullptr)
    {
        TextureViewMtlImpl* pDSV = static_cast<TextureViewMtlImpl*>(m_pDepthStencilTarget.RawPtr());
        id<MTLTexture> texture = pDSV->GetMtlTexture();
        if (texture != nil)
        {
            m_RenderPassDescriptor.depthAttachment.texture = texture;
            m_RenderPassDescriptor.depthAttachment.loadAction = MTLLoadActionLoad;
            m_RenderPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
            
            // Also set stencil attachment if the texture has stencil
            m_RenderPassDescriptor.stencilAttachment.texture = texture;
            m_RenderPassDescriptor.stencilAttachment.loadAction = MTLLoadActionLoad;
            m_RenderPassDescriptor.stencilAttachment.storeAction = MTLStoreActionStore;
        }
    }
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::BeginRenderPass(const BeginRenderPassAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("BeginRenderPass is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::NextSubpass()
{
    LOG_ERROR_MESSAGE("NextSubpass is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::EndRenderPass()
{
    if (m_RenderEncoder != nil)
    {
        [m_RenderEncoder endEncoding];
        m_RenderEncoder = nil;
    }
    m_InRenderPass = false;
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::Draw(const DrawAttribs& Attribs)
{
    // Ensure we have a command buffer
    if (m_mtlCommandBuffer == nil)
    {
        RenderDeviceMtlImpl* pDeviceMtl = static_cast<RenderDeviceMtlImpl*>(GetDevice());
        const auto& cmdQueue = pDeviceMtl->GetCommandQueue(SoftwareQueueIndex{0});
        id<MTLCommandQueue> mtlCommandQueue = cmdQueue.GetMtlCommandQueue();
        m_mtlCommandBuffer = [mtlCommandQueue commandBuffer];
    }
    
    // Begin render pass if not already in one
    if (!m_InRenderPass && m_RenderPassDescriptor != nil)
    {
        m_RenderEncoder = [m_mtlCommandBuffer renderCommandEncoderWithDescriptor:m_RenderPassDescriptor];
        m_InRenderPass = true;
        
        // Re-apply pipeline state
        if (m_pPipelineState != nullptr)
        {
            id<MTLRenderPipelineState> renderPipeline = m_pPipelineState->GetMtlRenderPipeline();
            if (renderPipeline != nil)
            {
                [m_RenderEncoder setRenderPipelineState:renderPipeline];
            }
            
            id<MTLDepthStencilState> depthStencilState = m_pPipelineState->GetMtlDepthStencilState();
            if (depthStencilState != nil)
            {
                [m_RenderEncoder setDepthStencilState:depthStencilState];
            }
        }
        
        // Re-apply vertex buffers
        for (Uint32 i = 0; i < MAX_VERTEX_BUFFERS; ++i)
        {
            if (m_VertexBuffers[i] != nil)
            {
                [m_RenderEncoder setVertexBuffer:m_VertexBuffers[i] offset:m_VertexBufferOffsets[i] atIndex:i];
            }
        }
    }
    
    if (m_RenderEncoder == nil)
    {
        LOG_ERROR_MESSAGE("No render encoder available. Call SetRenderTargetsExt first.");
        return;
    }
    
    // Apply rasterizer state
    if (m_pPipelineState != nullptr)
    {
        const auto& rasterizerDesc = m_pPipelineState->GetRasterizerStateDesc();
        [m_RenderEncoder setFrontFacingWinding:rasterizerDesc.FrontCounterClockwise ? MTLWindingCounterClockwise : MTLWindingClockwise];
        [m_RenderEncoder setCullMode:rasterizerDesc.CullMode == CULL_MODE_NONE ? MTLCullModeNone :
                               rasterizerDesc.CullMode == CULL_MODE_FRONT ? MTLCullModeFront : MTLCullModeBack];
        [m_RenderEncoder setTriangleFillMode:rasterizerDesc.FillMode == FILL_MODE_WIREFRAME ? MTLTriangleFillModeLines : MTLTriangleFillModeFill];
    }
    
    // Draw
    [m_RenderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                        vertexStart:Attribs.StartVertexLocation
                        vertexCount:Attribs.NumVertices];
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::DrawIndexed(const DrawIndexedAttribs& Attribs)
{
    // Ensure we have a command buffer
    if (m_mtlCommandBuffer == nil)
    {
        RenderDeviceMtlImpl* pDeviceMtl = static_cast<RenderDeviceMtlImpl*>(GetDevice());
        const auto& cmdQueue = pDeviceMtl->GetCommandQueue(SoftwareQueueIndex{0});
        id<MTLCommandQueue> mtlCommandQueue = cmdQueue.GetMtlCommandQueue();
        m_mtlCommandBuffer = [mtlCommandQueue commandBuffer];
    }
    
    // Begin render pass if not already in one
    if (!m_InRenderPass && m_RenderPassDescriptor != nil)
    {
        m_RenderEncoder = [m_mtlCommandBuffer renderCommandEncoderWithDescriptor:m_RenderPassDescriptor];
        m_InRenderPass = true;
        
        // Re-apply pipeline state
        if (m_pPipelineState != nullptr)
        {
            id<MTLRenderPipelineState> renderPipeline = m_pPipelineState->GetMtlRenderPipeline();
            if (renderPipeline != nil)
            {
                [m_RenderEncoder setRenderPipelineState:renderPipeline];
            }
            
            id<MTLDepthStencilState> depthStencilState = m_pPipelineState->GetMtlDepthStencilState();
            if (depthStencilState != nil)
            {
                [m_RenderEncoder setDepthStencilState:depthStencilState];
            }
        }
        
        // Re-apply vertex buffers
        for (Uint32 i = 0; i < MAX_VERTEX_BUFFERS; ++i)
        {
            if (m_VertexBuffers[i] != nil)
            {
                [m_RenderEncoder setVertexBuffer:m_VertexBuffers[i] offset:m_VertexBufferOffsets[i] atIndex:i];
            }
        }
    }
    
    if (m_RenderEncoder == nil)
    {
        LOG_ERROR_MESSAGE("No render encoder available. Call SetRenderTargetsExt first.");
        return;
    }
    
    // Apply rasterizer state
    if (m_pPipelineState != nullptr)
    {
        const auto& rasterizerDesc = m_pPipelineState->GetRasterizerStateDesc();
        [m_RenderEncoder setFrontFacingWinding:rasterizerDesc.FrontCounterClockwise ? MTLWindingCounterClockwise : MTLWindingClockwise];
        [m_RenderEncoder setCullMode:rasterizerDesc.CullMode == CULL_MODE_NONE ? MTLCullModeNone :
                               rasterizerDesc.CullMode == CULL_MODE_FRONT ? MTLCullModeFront : MTLCullModeBack];
        [m_RenderEncoder setTriangleFillMode:rasterizerDesc.FillMode == FILL_MODE_WIREFRAME ? MTLTriangleFillModeLines : MTLTriangleFillModeFill];
    }
    
    // Draw indexed
    if (m_IndexBuffer != nil)
    {
        NSUInteger indexBufferOffset = m_IndexBufferOffset + Attribs.FirstIndexLocation * (m_IndexType == MTLIndexTypeUInt32 ? 4 : 2);
        [m_RenderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                    indexCount:Attribs.NumIndices
                                     indexType:m_IndexType
                                   indexBuffer:m_IndexBuffer
                             indexBufferOffset:indexBufferOffset
                                 instanceCount:Attribs.NumInstances
                                    baseVertex:Attribs.BaseVertex
                                  baseInstance:Attribs.FirstInstanceLocation];
    }
    else
    {
        LOG_ERROR_MESSAGE("No index buffer set. Call SetIndexBuffer first.");
    }
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::DrawIndirect(const DrawIndirectAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("DrawIndirect is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::DrawIndexedIndirect(const DrawIndexedIndirectAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("DrawIndexedIndirect is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::DrawMesh(const DrawMeshAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("DrawMesh is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::DrawMeshIndirect(const DrawMeshIndirectAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("DrawMeshIndirect is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::MultiDraw(const MultiDrawAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("MultiDraw is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::MultiDrawIndexed(const MultiDrawIndexedAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("MultiDrawIndexed is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::DispatchCompute(const DispatchComputeAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("DispatchCompute is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::DispatchComputeIndirect(const DispatchComputeIndirectAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("DispatchComputeIndirect is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::GetTileSize(Uint32& TileSizeX, Uint32& TileSizeY)
{
    TileSizeX = 32;
    TileSizeY = 32;
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::DispatchTile(const DispatchTileAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("DispatchTile is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::ClearRenderTarget(ITextureView* pView, const void* pClearColor, RESOURCE_STATE_TRANSITION_MODE StateTransitionMode)
{
    if (pView == nullptr)
    {
        LOG_ERROR_MESSAGE("ClearRenderTarget: pView is null");
        return;
    }
    
    TextureViewMtlImpl* pViewMtl = static_cast<TextureViewMtlImpl*>(pView);
    id<MTLTexture> mtlTexture = pViewMtl->GetMtlTexture();
    if (mtlTexture == nil)
    {
        LOG_ERROR_MESSAGE("ClearRenderTarget: Metal texture is null");
        return;
    }
    
    // Parse clear color (RGBA float)
    const float* pColor = static_cast<const float*>(pClearColor);
    MTLClearColor clearColor = MTLClearColorMake(
        pColor ? pColor[0] : 0.0,
        pColor ? pColor[1] : 0.0,
        pColor ? pColor[2] : 0.0,
        pColor ? pColor[3] : 1.0
    );
    
    // End current render pass if active
    if (m_RenderEncoder != nil)
    {
        [m_RenderEncoder endEncoding];
        m_RenderEncoder = nil;
        m_InRenderPass = false;
    }
    
    // Create render pass descriptor with clear load action
    MTLRenderPassDescriptor* renderPassDesc = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDesc.colorAttachments[0].texture = mtlTexture;
    renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPassDesc.colorAttachments[0].clearColor = clearColor;
    
    // Ensure we have a command buffer
    if (m_mtlCommandBuffer == nil)
    {
        RenderDeviceMtlImpl* pDeviceMtl = static_cast<RenderDeviceMtlImpl*>(GetDevice());
        const auto& cmdQueue = pDeviceMtl->GetCommandQueue(SoftwareQueueIndex{0});
        id<MTLCommandQueue> mtlCommandQueue = cmdQueue.GetMtlCommandQueue();
        m_mtlCommandBuffer = [mtlCommandQueue commandBuffer];
    }
    
    // Create render encoder and immediately end it (just for the clear)
    id<MTLRenderCommandEncoder> clearEncoder = [m_mtlCommandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
    [clearEncoder endEncoding];
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::ClearDepthStencil(ITextureView* pView, CLEAR_DEPTH_STENCIL_FLAGS ClearFlags, float fDepth, Uint8 Stencil, RESOURCE_STATE_TRANSITION_MODE StateTransitionMode)
{
    LOG_ERROR_MESSAGE("ClearDepthStencil is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::UpdateBuffer(IBuffer* pBuffer, Uint64 Offset, Uint64 Size, const void* pData, RESOURCE_STATE_TRANSITION_MODE StateTransitionMode)
{
    LOG_ERROR_MESSAGE("UpdateBuffer is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::CopyBuffer(IBuffer* pSrcBuffer, Uint64 SrcOffset, RESOURCE_STATE_TRANSITION_MODE SrcBufferTransitionMode,
                                                          IBuffer* pDstBuffer, Uint64 DstOffset, Uint64 Size, RESOURCE_STATE_TRANSITION_MODE DstBufferTransitionMode)
{
    LOG_ERROR_MESSAGE("CopyBuffer is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::MapBuffer(IBuffer* pBuffer, MAP_TYPE MapType, MAP_FLAGS MapFlags, PVoid& pMappedData)
{
    pMappedData = nullptr;
    
    if (pBuffer == nullptr)
    {
        LOG_ERROR_MESSAGE("MapBuffer: pBuffer is null");
        return;
    }
    
    auto* pBufferMtl = ClassPtrCast<BufferMtlImpl>(pBuffer);
    if (pBufferMtl == nullptr)
    {
        LOG_ERROR_MESSAGE("MapBuffer: Invalid buffer");
        return;
    }
    
    id<MTLBuffer> mtlBuffer = pBufferMtl->GetMtlResource();
    if (mtlBuffer == nil)
    {
        LOG_ERROR_MESSAGE("MapBuffer: Metal buffer is null");
        return;
    }
    
    // For shared storage mode, we can get a direct pointer
    if (mtlBuffer.storageMode == MTLStorageModeShared)
    {
        pMappedData = [mtlBuffer contents];
    }
    else
    {
        // For private storage mode, we need to use a staging buffer
        // This is a simplified implementation
        LOG_WARNING_MESSAGE("MapBuffer: Buffer uses private storage, mapping not fully supported");
        pMappedData = nullptr;
    }
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::UnmapBuffer(IBuffer* pBuffer, MAP_TYPE MapType)
{
    // For shared storage mode, there's no need to unmap
    // The memory is always accessible
    // For private storage, we would need to sync back
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::UpdateTexture(ITexture*                      pTexture,
                                                            Uint32                         MipLevel,
                                                            Uint32                         Slice,
                                                            const Box&                     DstBox,
                                                            const TextureSubResData&       SubresData,
                                                            RESOURCE_STATE_TRANSITION_MODE SrcBufferTransitionMode,
                                                            RESOURCE_STATE_TRANSITION_MODE DstTextureTransitionMode)
{
    if (pTexture == nullptr)
    {
        LOG_ERROR_MESSAGE("UpdateTexture: pTexture is null");
        return;
    }
    
    auto* pTextureMtl = ClassPtrCast<TextureMtlImpl>(pTexture);
    if (pTextureMtl == nullptr)
    {
        LOG_ERROR_MESSAGE("UpdateTexture: Invalid texture");
        return;
    }
    
    id<MTLTexture> mtlTexture = pTextureMtl->GetMtlTexture();
    if (mtlTexture == nil)
    {
        LOG_ERROR_MESSAGE("UpdateTexture: Metal texture is null");
        return;
    }
    
    const TextureDesc& TexDesc = pTextureMtl->GetDesc();
    
    // Calculate region dimensions
    MTLRegion region;
    region.origin.x = DstBox.MinX;
    region.origin.y = DstBox.MinY;
    region.origin.z = DstBox.MinZ;
    region.size.width = DstBox.MaxX - DstBox.MinX;
    region.size.height = DstBox.MaxY - DstBox.MinY;
    region.size.depth = DstBox.MaxZ - DstBox.MinZ;
    
    // For 1D textures, height and depth should be 1
    if (TexDesc.Type == RESOURCE_DIM_TEX_1D || TexDesc.Type == RESOURCE_DIM_TEX_1D_ARRAY)
    {
        region.origin.y = 0;
        region.size.height = 1;
    }
    
    // For 2D textures, depth should be 1
    if (TexDesc.Type != RESOURCE_DIM_TEX_3D)
    {
        region.origin.z = 0;
        region.size.depth = 1;
    }
    
    // Upload the texture data
    if (SubresData.pData != nullptr)
    {
        // For private storage mode, we need to use a staging buffer
        if (mtlTexture.storageMode == MTLStorageModePrivate)
        {
            // Get the Metal device and command queue
            auto* pDeviceMtl = ClassPtrCast<RenderDeviceMtlImpl>(GetDevice());
            if (pDeviceMtl == nullptr)
            {
                LOG_ERROR_MESSAGE("UpdateTexture: Invalid device");
                return;
            }
            
            id<MTLDevice> mtlDevice = pDeviceMtl->GetMtlDevice();
            const auto& cmdQueue = pDeviceMtl->GetCommandQueue(SoftwareQueueIndex{0});
            id<MTLCommandQueue> mtlCommandQueue = cmdQueue.GetMtlCommandQueue();
            
            if (mtlCommandQueue == nil)
            {
                LOG_ERROR_MESSAGE("UpdateTexture: Metal command queue is null");
                return;
            }
            
            // Calculate bytes per row and image
            NSUInteger bytesPerRow = SubresData.Stride;
            NSUInteger bytesPerImage = SubresData.DepthStride;
            
            // Calculate total data size
            NSUInteger dataSize = bytesPerImage > 0 ? bytesPerImage : bytesPerRow * region.size.height;
            if (dataSize == 0)
            {
                dataSize = bytesPerRow * region.size.height;
            }
            
            // Create a staging buffer
            id<MTLBuffer> stagingBuffer = [mtlDevice newBufferWithLength:dataSize options:MTLStorageModeShared];
            if (stagingBuffer == nil)
            {
                LOG_ERROR_MESSAGE("UpdateTexture: Failed to create staging buffer");
                return;
            }
            
            // Copy data to staging buffer
            void* pStagingData = [stagingBuffer contents];
            if (pStagingData == nullptr)
            {
                LOG_ERROR_MESSAGE("UpdateTexture: Failed to get staging buffer contents");
                return;
            }
            std::memcpy(pStagingData, SubresData.pData, dataSize);
            
            // Create a command buffer
            id<MTLCommandBuffer> commandBuffer = [mtlCommandQueue commandBuffer];
            if (commandBuffer == nil)
            {
                LOG_ERROR_MESSAGE("UpdateTexture: Failed to create command buffer");
                return;
            }
            
            // Create a blit command encoder
            id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
            if (blitEncoder == nil)
            {
                LOG_ERROR_MESSAGE("UpdateTexture: Failed to create blit command encoder");
                return;
            }
            
            // Copy from buffer to texture
            NSUInteger sourceOffset = 0;
            [blitEncoder copyFromBuffer:stagingBuffer
                           sourceOffset:sourceOffset
                      sourceBytesPerRow:bytesPerRow
                    sourceBytesPerImage:bytesPerImage
                             sourceSize:MTLSizeMake(region.size.width, region.size.height, region.size.depth)
                              toTexture:mtlTexture
                       destinationSlice:Slice
                       destinationLevel:MipLevel
                      destinationOrigin:MTLOriginMake(region.origin.x, region.origin.y, region.origin.z)];
            
            [blitEncoder endEncoding];
            
            // Commit and wait for completion
            [commandBuffer commit];
            [commandBuffer waitUntilCompleted];
            
            LOG_INFO_MESSAGE("Updated Metal texture '", TexDesc.Name, "' mip level ", MipLevel, 
                             " slice ", Slice, " via staging buffer");
        }
        else
        {
            // For shared/managed storage mode, use replaceRegion directly
            [mtlTexture replaceRegion:region
                          mipmapLevel:MipLevel
                                slice:Slice
                            withBytes:SubresData.pData
                          bytesPerRow:SubresData.Stride
                        bytesPerImage:SubresData.DepthStride];
            
            LOG_INFO_MESSAGE("Updated Metal texture '", TexDesc.Name, "' mip level ", MipLevel, 
                             " slice ", Slice, " (", region.size.width, "x", region.size.height, ")");
        }
    }
    else
    {
        LOG_ERROR_MESSAGE("UpdateTexture: SubresData.pData is null");
    }
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::CopyTexture(const CopyTextureAttribs& CopyAttribs)
{
    LOG_ERROR_MESSAGE("CopyTexture is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::MapTextureSubresource(ITexture*                 pTexture,
                                                                    Uint32                    MipLevel,
                                                                    Uint32                    ArraySlice,
                                                                    MAP_TYPE                  MapType,
                                                                    MAP_FLAGS                 MapFlags,
                                                                    const Box*                pMapRegion,
                                                                    MappedTextureSubresource& MappedData)
{
    LOG_ERROR_MESSAGE("MapTextureSubresource is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::UnmapTextureSubresource(ITexture* pTexture, Uint32 MipLevel, Uint32 ArraySlice)
{
    LOG_ERROR_MESSAGE("UnmapTextureSubresource is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::FinishCommandList(ICommandList** ppCommandList)
{
    LOG_ERROR_MESSAGE("FinishCommandList is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::ExecuteCommandLists(Uint32 NumCommandLists, ICommandList* const* ppCommandLists)
{
    LOG_ERROR_MESSAGE("ExecuteCommandLists is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::EnqueueSignal(IFence* pFence, Uint64 Value)
{
    LOG_ERROR_MESSAGE("EnqueueSignal is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::DeviceWaitForFence(IFence* pFence, Uint64 Value)
{
    LOG_ERROR_MESSAGE("DeviceWaitForFence is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::WaitForIdle()
{
    LOG_ERROR_MESSAGE("WaitForIdle is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::BeginQuery(IQuery* pQuery)
{
    LOG_ERROR_MESSAGE("BeginQuery is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::EndQuery(IQuery* pQuery)
{
    LOG_ERROR_MESSAGE("EndQuery is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::Flush()
{
    // For Metal, we need to commit any pending command buffers
    // Since we're using immediate mode, we commit the command buffer
    // and wait for it to complete
    
    auto* pDeviceMtl = ClassPtrCast<RenderDeviceMtlImpl>(GetDevice());
    if (pDeviceMtl == nullptr)
    {
        LOG_ERROR_MESSAGE("Flush: Invalid device");
        return;
    }
    
    // Get the command queue (index 0 for the main queue)
    const auto& cmdQueue = pDeviceMtl->GetCommandQueue(SoftwareQueueIndex{0});
    id<MTLCommandQueue> mtlCommandQueue = cmdQueue.GetMtlCommandQueue();
    
    if (mtlCommandQueue == nil)
    {
        LOG_ERROR_MESSAGE("Flush: Command queue is null");
        return;
    }
    
    // Create a command buffer for flush
    id<MTLCommandBuffer> commandBuffer = [mtlCommandQueue commandBuffer];
    if (commandBuffer == nil)
    {
        LOG_ERROR_MESSAGE("Flush: Failed to create command buffer");
        return;
    }
    
    commandBuffer.label = @"Flush";
    
    // Commit and wait
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
    LOG_INFO_MESSAGE("Metal context flushed");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::BuildBLAS(const BuildBLASAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("BuildBLAS is not implemented. Ray tracing will be implemented in Phase 5.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::BuildTLAS(const BuildTLASAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("BuildTLAS is not implemented. Ray tracing will be implemented in Phase 5.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::CopyBLAS(const CopyBLASAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("CopyBLAS is not implemented. Ray tracing will be implemented in Phase 5.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::CopyTLAS(const CopyTLASAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("CopyTLAS is not implemented. Ray tracing will be implemented in Phase 5.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::WriteBLASCompactedSize(const WriteBLASCompactedSizeAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("WriteBLASCompactedSize is not implemented. Ray tracing will be implemented in Phase 5.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::WriteTLASCompactedSize(const WriteTLASCompactedSizeAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("WriteTLASCompactedSize is not implemented. Ray tracing will be implemented in Phase 5.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::TraceRays(const TraceRaysAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("TraceRays is not implemented. Ray tracing will be implemented in Phase 5.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::TraceRaysIndirect(const TraceRaysIndirectAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("TraceRaysIndirect is not implemented. Ray tracing will be implemented in Phase 5.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::UpdateSBT(IShaderBindingTable* pSBT, const UpdateIndirectRTBufferAttribs* pUpdateIndirectBufferAttribs)
{
    LOG_ERROR_MESSAGE("UpdateSBT is not implemented. Ray tracing will be implemented in Phase 5.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::FinishFrame()
{
    // For Metal, we commit any pending work and ensure all frames are complete
    // This is typically called at the end of a frame
    Flush();
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::SetShadingRate(SHADING_RATE BaseRate, SHADING_RATE_COMBINER PrimitiveCombiner, SHADING_RATE_COMBINER TextureCombiner)
{
    LOG_ERROR_MESSAGE("SetShadingRate is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::BindSparseResourceMemory(const BindSparseResourceMemoryAttribs& Attribs)
{
    if (@available(iOS 16, macOS 11.0, *))
    {
        // Validate input
        if (Attribs.NumTextureBinds == 0 && Attribs.NumBufferBinds == 0)
        {
            LOG_WARNING_MESSAGE("BindSparseResourceMemory called with no bindings");
            return;
        }
        
        // Buffer sparse binding is not supported in Metal
        if (Attribs.NumBufferBinds > 0)
        {
            LOG_ERROR_MESSAGE("Sparse buffer binding is not supported in Metal. Only texture sparse binding is supported.");
            return;
        }
        
        // Process texture binds
        for (Uint32 i = 0; i < Attribs.NumTextureBinds; ++i)
        {
            const SparseTextureMemoryBindInfo& bindInfo = Attribs.pTextureBinds[i];
            if (bindInfo.pTexture == nullptr)
            {
                LOG_ERROR_MESSAGE("pTexture is null in SparseTextureMemoryBindInfo at index ", i);
                continue;
            }
            
            auto* pTextureMtl = ClassPtrCast<TextureMtlImpl>(bindInfo.pTexture);
            if (pTextureMtl == nullptr || !pTextureMtl->IsSparse())
            {
                LOG_ERROR_MESSAGE("Texture at index ", i, " is not a sparse texture");
                continue;
            }
            
            id<MTLTexture> mtlTexture = pTextureMtl->GetMtlTexture();
            if (mtlTexture == nil)
            {
                LOG_ERROR_MESSAGE("Metal texture is null");
                continue;
            }
            
            // Get tile size for this texture
            MTLSize tileSize = pTextureMtl->GetSparseTileSize();
            
            // Process each bind range
            for (Uint32 j = 0; j < bindInfo.NumRanges; ++j)
            {
                const SparseTextureMemoryBindRange& bindRange = bindInfo.pRanges[j];
                
                // Convert to Metal region
                MTLRegion region;
                SparseTextureManagerMtlImpl::ConvertBindRangeToRegion(
                    bindRange,
                    static_cast<Uint32>(tileSize.width),
                    static_cast<Uint32>(tileSize.height),
                    static_cast<Uint32>(tileSize.depth),
                    region);
                
                // Determine map mode
                MTLSparseTextureMappingMode mode = (bindRange.pMemory != nullptr) 
                    ? MTLSparseTextureMappingModeMap 
                    : MTLSparseTextureMappingModeUnmap;
                
                // Create command buffer if needed
                // Note: In a production implementation, we would use a proper command buffer
                // from the command queue
                id<MTLCommandBuffer> commandBuffer = nil; // TODO: Get from command queue
                
                if (commandBuffer == nil)
                {
                    LOG_ERROR_MESSAGE("Cannot bind sparse texture memory: no command buffer available");
                    continue;
                }
                
                // Update texture mapping
                SparseTextureManagerMtlImpl::UpdateSingleTileMapping(
                    commandBuffer,
                    mtlTexture,
                    bindRange.MipLevel,
                    bindRange.ArraySlice,
                    region,
                    mode);
            }
        }
        
        // Wait for fences
        for (Uint32 i = 0; i < Attribs.NumWaitFences; ++i)
        {
            // TODO: Implement fence waiting
            LOG_WARNING_MESSAGE("Fence waiting in BindSparseResourceMemory is not yet implemented");
        }
        
        // Signal fences
        for (Uint32 i = 0; i < Attribs.NumSignalFences; ++i)
        {
            // TODO: Implement fence signaling
            LOG_WARNING_MESSAGE("Fence signaling in BindSparseResourceMemory is not yet implemented");
        }
    }
    else
    {
        LOG_ERROR_MESSAGE("Sparse resources require iOS 16+ or macOS 11.0+");
    }
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::TransitionResourceStates(Uint32 BarrierCount, const StateTransitionDesc* pResourceBarriers)
{
    // Metal does not have explicit resource state transitions like D3D12/Vulkan.
    // Resource states are managed implicitly by the driver.
    // This method is a no-op for the Metal backend, but we validate the input.
    
    if (pResourceBarriers == nullptr && BarrierCount > 0)
    {
        LOG_ERROR_MESSAGE("TransitionResourceStates: pResourceBarriers is null but BarrierCount > 0");
        return;
    }
    
    // No-op: Metal handles resource synchronization automatically
#ifdef DILIGENT_DEVELOPMENT
    for (Uint32 i = 0; i < BarrierCount; ++i)
    {
        if (pResourceBarriers[i].pResource == nullptr)
        {
            LOG_WARNING_MESSAGE("TransitionResourceStates: Resource at index ", i, " is null");
        }
    }
#endif
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::GenerateMips(ITextureView* pTexView)
{
    if (pTexView == nullptr)
    {
        LOG_ERROR_MESSAGE("GenerateMips: pTexView is null");
        return;
    }
    
    auto* pTexViewMtl = ClassPtrCast<TextureViewMtlImpl>(pTexView);
    if (pTexViewMtl == nullptr)
    {
        LOG_ERROR_MESSAGE("GenerateMips: Invalid texture view");
        return;
    }
    
    id<MTLTexture> mtlTexture = pTexViewMtl->GetMtlTexture();
    if (mtlTexture == nil)
    {
        LOG_ERROR_MESSAGE("GenerateMips: Metal texture is null");
        return;
    }
    
    // Get the Metal device and command queue
    auto* pDeviceMtl = ClassPtrCast<RenderDeviceMtlImpl>(GetDevice());
    if (pDeviceMtl == nullptr)
    {
        LOG_ERROR_MESSAGE("GenerateMips: Invalid device");
        return;
    }
    
    id<MTLDevice> mtlDevice = pDeviceMtl->GetMtlDevice();
    
    // Get the command queue (index 0 for the main queue)
    const auto& cmdQueue = pDeviceMtl->GetCommandQueue(SoftwareQueueIndex{0});
    id<MTLCommandQueue> mtlCommandQueue = cmdQueue.GetMtlCommandQueue();
    
    if (mtlCommandQueue == nil)
    {
        LOG_ERROR_MESSAGE("GenerateMips: Metal command queue is null");
        return;
    }
    
    // Create a command buffer
    id<MTLCommandBuffer> commandBuffer = [mtlCommandQueue commandBuffer];
    if (commandBuffer == nil)
    {
        LOG_ERROR_MESSAGE("GenerateMips: Failed to create command buffer");
        return;
    }
    
    // Create a blit command encoder
    id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
    if (blitEncoder == nil)
    {
        LOG_ERROR_MESSAGE("GenerateMips: Failed to create blit command encoder");
        return;
    }
    
    // Generate mipmaps
    [blitEncoder generateMipmapsForTexture:mtlTexture];
    [blitEncoder endEncoding];
    
    // Commit the command buffer without waiting
    // The mipmap generation will complete asynchronously
    [commandBuffer commit];
    
    LOG_INFO_MESSAGE("Generated mipmaps for Metal texture");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::ResolveTextureSubresource(ITexture*                               pSrcTexture,
                                                                         ITexture*                               pDstTexture,
                                                                         const ResolveTextureSubresourceAttribs& ResolveAttribs)
{
    LOG_ERROR_MESSAGE("ResolveTextureSubresource is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::BeginDebugGroup(const char* pName, const float* pColor)
{
    LOG_ERROR_MESSAGE("BeginDebugGroup is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::EndDebugGroup()
{
    LOG_ERROR_MESSAGE("EndDebugGroup is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::InsertDebugLabel(const char* pLabel, const float* pColor)
{
    LOG_ERROR_MESSAGE("InsertDebugLabel is not implemented yet. Metal backend is under development.");
}

} // namespace Diligent
