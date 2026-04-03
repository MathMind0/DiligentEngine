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
/// Declaration of Diligent::DeviceContextMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "DeviceContextNextGenBase.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

class RenderDeviceMtlImpl;

/// Device context implementation in Metal backend.
class DeviceContextMtlImpl final : public DeviceContextNextGenBase<EngineMtlImplTraits>
{
public:
    using TDeviceContextBase = DeviceContextNextGenBase<EngineMtlImplTraits>;

    DeviceContextMtlImpl(IReferenceCounters*      pRefCounters,
                         RenderDeviceMtlImpl*     pDevice,
                         const DeviceContextDesc& Desc);

    ~DeviceContextMtlImpl();

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_DeviceContextMtl, TDeviceContextBase)

    /// Implementation of IDeviceContextMtl::GetMtlCommandBuffer()
    virtual id<MTLCommandBuffer> DILIGENT_CALL_TYPE GetMtlCommandBuffer() override final;

    /// Implementation of IDeviceContextMtl::SetComputeThreadgroupMemoryLength()
    virtual void DILIGENT_CALL_TYPE SetComputeThreadgroupMemoryLength(Uint32 Length, Uint32 Index) override final;

    /// Implementation of IDeviceContextMtl::SetTileThreadgroupMemoryLength()
    virtual void DILIGENT_CALL_TYPE SetTileThreadgroupMemoryLength(Uint32 Length, Uint32 Offset, Uint32 Index)
        API_AVAILABLE(ios(11), macosx(11.0), tvos(14.5)) override final;

    //=== DeviceContext methods ===//

    virtual void DILIGENT_CALL_TYPE Begin(Uint32 ImmediateContextId) override final;

    virtual void DILIGENT_CALL_TYPE SetPipelineState(IPipelineState* pPipelineState) override final;

    virtual void DILIGENT_CALL_TYPE TransitionShaderResources(IShaderResourceBinding* pShaderResourceBinding) override final;

    virtual void DILIGENT_CALL_TYPE CommitShaderResources(IShaderResourceBinding* pShaderResourceBinding,
                                                          RESOURCE_STATE_TRANSITION_MODE StateTransitionMode) override final;

    virtual void DILIGENT_CALL_TYPE SetStencilRef(Uint32 StencilRef) override final;

    virtual void DILIGENT_CALL_TYPE SetBlendFactors(const float* pBlendFactors) override final;

    virtual void DILIGENT_CALL_TYPE SetVertexBuffers(Uint32                         StartSlot,
                                                     Uint32                         NumBuffersSet,
                                                     IBuffer* const*                ppBuffers,
                                                     const Uint64*                  pOffsets,
                                                     RESOURCE_STATE_TRANSITION_MODE StateTransitionMode,
                                                     SET_VERTEX_BUFFERS_FLAGS       Flags) override final;

    virtual void DILIGENT_CALL_TYPE InvalidateState() override final;

    virtual void DILIGENT_CALL_TYPE SetIndexBuffer(IBuffer* pIndexBuffer, Uint64 ByteOffset, RESOURCE_STATE_TRANSITION_MODE StateTransitionMode) override final;

    virtual void DILIGENT_CALL_TYPE SetViewports(Uint32 NumViewports, const Viewport* pViewports, Uint32 RTWidth, Uint32 RTHeight) override final;

    virtual void DILIGENT_CALL_TYPE SetScissorRects(Uint32 NumRects, const Rect* pRects, Uint32 RTWidth, Uint32 RTHeight) override final;

    virtual void DILIGENT_CALL_TYPE SetRenderTargetsExt(const SetRenderTargetsAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE BeginRenderPass(const BeginRenderPassAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE NextSubpass() override final;

    virtual void DILIGENT_CALL_TYPE EndRenderPass() override final;

    virtual void DILIGENT_CALL_TYPE Draw(const DrawAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE DrawIndexed(const DrawIndexedAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE DrawIndirect(const DrawIndirectAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE DrawIndexedIndirect(const DrawIndexedIndirectAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE DrawMesh(const DrawMeshAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE DrawMeshIndirect(const DrawMeshIndirectAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE MultiDraw(const MultiDrawAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE MultiDrawIndexed(const MultiDrawIndexedAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE DispatchCompute(const DispatchComputeAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE DispatchComputeIndirect(const DispatchComputeIndirectAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE GetTileSize(Uint32& TileSizeX, Uint32& TileSizeY) override final;

    virtual void DILIGENT_CALL_TYPE DispatchTile(const DispatchTileAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE ClearRenderTarget(ITextureView* pView, const void* pClearColor, RESOURCE_STATE_TRANSITION_MODE StateTransitionMode) override final;

    virtual void DILIGENT_CALL_TYPE ClearDepthStencil(ITextureView* pView, CLEAR_DEPTH_STENCIL_FLAGS ClearFlags, float fDepth, Uint8 Stencil, RESOURCE_STATE_TRANSITION_MODE StateTransitionMode) override final;

    virtual void DILIGENT_CALL_TYPE UpdateBuffer(IBuffer* pBuffer, Uint64 Offset, Uint64 Size, const void* pData, RESOURCE_STATE_TRANSITION_MODE StateTransitionMode) override final;

    virtual void DILIGENT_CALL_TYPE CopyBuffer(IBuffer* pSrcBuffer, Uint64 SrcOffset, RESOURCE_STATE_TRANSITION_MODE SrcBufferTransitionMode,
                                               IBuffer* pDstBuffer, Uint64 DstOffset, Uint64 Size, RESOURCE_STATE_TRANSITION_MODE DstBufferTransitionMode) override final;

    virtual void DILIGENT_CALL_TYPE MapBuffer(IBuffer* pBuffer, MAP_TYPE MapType, MAP_FLAGS MapFlags, PVoid& pMappedData) override final;

    virtual void DILIGENT_CALL_TYPE UnmapBuffer(IBuffer* pBuffer, MAP_TYPE MapType) override final;

    virtual void DILIGENT_CALL_TYPE UpdateTexture(ITexture*                      pTexture,
                                                  Uint32                         MipLevel,
                                                  Uint32                         Slice,
                                                  const Box&                     DstBox,
                                                  const TextureSubResData&       SubresData,
                                                  RESOURCE_STATE_TRANSITION_MODE SrcBufferTransitionMode,
                                                  RESOURCE_STATE_TRANSITION_MODE DstTextureTransitionMode) override final;

    virtual void DILIGENT_CALL_TYPE CopyTexture(const CopyTextureAttribs& CopyAttribs) override final;

    virtual void DILIGENT_CALL_TYPE MapTextureSubresource(ITexture*                 pTexture,
                                                          Uint32                    MipLevel,
                                                          Uint32                    ArraySlice,
                                                          MAP_TYPE                  MapType,
                                                          MAP_FLAGS                 MapFlags,
                                                          const Box*                pMapRegion,
                                                          MappedTextureSubresource& MappedData) override final;

    virtual void DILIGENT_CALL_TYPE UnmapTextureSubresource(ITexture* pTexture, Uint32 MipLevel, Uint32 ArraySlice) override final;

    virtual void DILIGENT_CALL_TYPE FinishCommandList(ICommandList** ppCommandList) override final;

    virtual void DILIGENT_CALL_TYPE ExecuteCommandLists(Uint32 NumCommandLists, ICommandList* const* ppCommandLists) override final;

    virtual void DILIGENT_CALL_TYPE EnqueueSignal(IFence* pFence, Uint64 Value) override final;

    virtual void DILIGENT_CALL_TYPE DeviceWaitForFence(IFence* pFence, Uint64 Value) override final;

    virtual void DILIGENT_CALL_TYPE WaitForIdle() override final;

    virtual void DILIGENT_CALL_TYPE BeginQuery(IQuery* pQuery) override final;

    virtual void DILIGENT_CALL_TYPE EndQuery(IQuery* pQuery) override final;

    virtual void DILIGENT_CALL_TYPE Flush() override final;

    virtual void DILIGENT_CALL_TYPE BuildBLAS(const BuildBLASAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE BuildTLAS(const BuildTLASAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE CopyBLAS(const CopyBLASAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE CopyTLAS(const CopyTLASAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE WriteBLASCompactedSize(const WriteBLASCompactedSizeAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE WriteTLASCompactedSize(const WriteTLASCompactedSizeAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE TraceRays(const TraceRaysAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE TraceRaysIndirect(const TraceRaysIndirectAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE UpdateSBT(IShaderBindingTable* pSBT, const UpdateIndirectRTBufferAttribs* pUpdateIndirectBufferAttribs) override final;

    virtual void DILIGENT_CALL_TYPE FinishFrame() override final;

    virtual void DILIGENT_CALL_TYPE SetShadingRate(SHADING_RATE BaseRate, SHADING_RATE_COMBINER PrimitiveCombiner, SHADING_RATE_COMBINER TextureCombiner) override final;

    virtual void DILIGENT_CALL_TYPE BindSparseResourceMemory(const BindSparseResourceMemoryAttribs& Attribs) override final;

    virtual void DILIGENT_CALL_TYPE TransitionResourceStates(Uint32 BarrierCount, const StateTransitionDesc* pResourceBarriers) override final;

    virtual void DILIGENT_CALL_TYPE GenerateMips(ITextureView* pTexView) override final;

    virtual void DILIGENT_CALL_TYPE ResolveTextureSubresource(ITexture*                               pSrcTexture,
                                                              ITexture*                               pDstTexture,
                                                              const ResolveTextureSubresourceAttribs& ResolveAttribs) override final;

    virtual void DILIGENT_CALL_TYPE BeginDebugGroup(const char* pName, const float* pColor) override final;

    virtual void DILIGENT_CALL_TYPE EndDebugGroup() override final;

    virtual void DILIGENT_CALL_TYPE InsertDebugLabel(const char* pLabel, const float* pColor) override final;

private:
    // Metal command buffer
    id<MTLCommandBuffer> m_mtlCommandBuffer;
};

} // namespace Diligent
