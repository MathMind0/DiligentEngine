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
    LOG_ERROR_MESSAGE("SetPipelineState is not implemented yet. Metal backend is under development.");
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
    LOG_ERROR_MESSAGE("SetVertexBuffers is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::InvalidateState()
{
    LOG_ERROR_MESSAGE("InvalidateState is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::SetIndexBuffer(IBuffer* pBuffer, Uint64 ByteOffset, RESOURCE_STATE_TRANSITION_MODE StateTransitionMode)
{
    LOG_ERROR_MESSAGE("SetIndexBuffer is not implemented yet. Metal backend is under development.");
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
    LOG_ERROR_MESSAGE("SetRenderTargetsExt is not implemented yet. Metal backend is under development.");
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
    LOG_ERROR_MESSAGE("EndRenderPass is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::Draw(const DrawAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("Draw is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::DrawIndexed(const DrawIndexedAttribs& Attribs)
{
    LOG_ERROR_MESSAGE("DrawIndexed is not implemented yet. Metal backend is under development.");
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
    LOG_ERROR_MESSAGE("ClearRenderTarget is not implemented yet. Metal backend is under development.");
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
    LOG_ERROR_MESSAGE("MapBuffer is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::UnmapBuffer(IBuffer* pBuffer, MAP_TYPE MapType)
{
    LOG_ERROR_MESSAGE("UnmapBuffer is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::UpdateTexture(ITexture*                      pTexture,
                                                            Uint32                         MipLevel,
                                                            Uint32                         Slice,
                                                            const Box&                     DstBox,
                                                            const TextureSubResData&       SubresData,
                                                            RESOURCE_STATE_TRANSITION_MODE SrcBufferTransitionMode,
                                                            RESOURCE_STATE_TRANSITION_MODE DstTextureTransitionMode)
{
    LOG_ERROR_MESSAGE("UpdateTexture is not implemented yet. Metal backend is under development.");
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
    LOG_ERROR_MESSAGE("Flush is not implemented yet. Metal backend is under development.");
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
    LOG_ERROR_MESSAGE("FinishFrame is not implemented yet. Metal backend is under development.");
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
    LOG_ERROR_MESSAGE("TransitionResourceStates is not implemented yet. Metal backend is under development.");
}

void DILIGENT_CALL_TYPE DeviceContextMtlImpl::GenerateMips(ITextureView* pTexView)
{
    LOG_ERROR_MESSAGE("GenerateMips is not implemented yet. Metal backend is under development.");
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
