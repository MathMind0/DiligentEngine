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
/// Declaration of Diligent::RenderDeviceMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "RenderDeviceBase.hpp"
#include "RenderDeviceNextGenBase.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

/// Render device implementation in Metal backend.
class RenderDeviceMtlImpl final : public RenderDeviceNextGenBase<RenderDeviceBase<EngineMtlImplTraits>, ICommandQueueMtl>
{
public:
    using TRenderDeviceBase = RenderDeviceNextGenBase<RenderDeviceBase<EngineMtlImplTraits>, ICommandQueueMtl>;

    RenderDeviceMtlImpl(IReferenceCounters*        pRefCounters,
                        IMemoryAllocator&          RawMemAllocator,
                        IEngineFactory*            pEngineFactory,
                        const EngineMtlCreateInfo& EngineCI,
                        const GraphicsAdapterInfo& AdapterInfo,
                        size_t                     CommandQueueCount,
                        ICommandQueueMtl**         ppCmdQueues,
                        id<MTLDevice>              mtlDevice);

    ~RenderDeviceMtlImpl();

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_RenderDeviceMtl, TRenderDeviceBase)

    /// Implementation of IRenderDeviceMtl::GetMtlDevice()
    virtual id<MTLDevice> DILIGENT_CALL_TYPE GetMtlDevice() const override final
    {
        return m_mtlDevice;
    }

    /// Implementation of IRenderDevice::CreateGraphicsPipelineState()
    virtual void DILIGENT_CALL_TYPE CreateGraphicsPipelineState(const GraphicsPipelineStateCreateInfo& PSOCreateInfo,
                                                                IPipelineState**                       ppPipelineState) override final;

    /// Implementation of IRenderDevice::CreateComputePipelineState()
    virtual void DILIGENT_CALL_TYPE CreateComputePipelineState(const ComputePipelineStateCreateInfo& PSOCreateInfo,
                                                               IPipelineState**                      ppPipelineState) override final;

    /// Implementation of IRenderDevice::CreateRayTracingPipelineState()
    virtual void DILIGENT_CALL_TYPE CreateRayTracingPipelineState(const RayTracingPipelineStateCreateInfo& PSOCreateInfo,
                                                                  IPipelineState**                         ppPipelineState) override final;

    /// Implementation of IRenderDevice::CreateBuffer()
    virtual void DILIGENT_CALL_TYPE CreateBuffer(const BufferDesc& BuffDesc,
                                                 const BufferData* pBuffData,
                                                 IBuffer**         ppBuffer) override final;

    /// Implementation of IRenderDevice::CreateTexture()
    virtual void DILIGENT_CALL_TYPE CreateTexture(const TextureDesc& TexDesc,
                                                  const TextureData* pTexData,
                                                  ITexture**         ppTexture) override final;

    /// Implementation of IRenderDevice::CreateSampler()
    virtual void DILIGENT_CALL_TYPE CreateSampler(const SamplerDesc& SamplerDesc,
                                                  ISampler**         ppSampler) override final;

    /// Implementation of IRenderDevice::CreateShader()
    virtual void DILIGENT_CALL_TYPE CreateShader(const ShaderCreateInfo& ShaderCI,
                                                 IShader**               ppShader,
                                                 IDataBlob**             ppCompilerOutput) override final;

    /// Implementation of IRenderDevice::CreateFence()
    virtual void DILIGENT_CALL_TYPE CreateFence(const FenceDesc& Desc,
                                                IFence**         ppFence) override final;

    /// Implementation of IRenderDevice::CreateQuery()
    virtual void DILIGENT_CALL_TYPE CreateQuery(const QueryDesc& Desc,
                                                IQuery**         ppQuery) override final;

    /// Implementation of IRenderDevice::CreateRenderPass()
    virtual void DILIGENT_CALL_TYPE CreateRenderPass(const RenderPassDesc& Desc,
                                                     IRenderPass**         ppRenderPass) override final;

    /// Implementation of IRenderDevice::CreateFramebuffer()
    virtual void DILIGENT_CALL_TYPE CreateFramebuffer(const FramebufferDesc& Desc,
                                                      IFramebuffer**         ppFramebuffer) override final;

    /// Implementation of IRenderDevice::CreatePipelineResourceSignature()
    virtual void DILIGENT_CALL_TYPE CreatePipelineResourceSignature(const PipelineResourceSignatureDesc& Desc,
                                                                    IPipelineResourceSignature**         ppSignature) override final;

    /// Implementation of IRenderDevice::CreatePipelineStateCache()
    virtual void DILIGENT_CALL_TYPE CreatePipelineStateCache(const PipelineStateCacheCreateInfo& CreateInfo,
                                                             IPipelineStateCache**               ppPSOCache) override final;

    /// Implementation of IRenderDevice::CreateDeviceMemory()
    virtual void DILIGENT_CALL_TYPE CreateDeviceMemory(const DeviceMemoryCreateInfo& CreateInfo,
                                                       IDeviceMemory**               ppMemory) override final;

    /// Implementation of IRenderDeviceMtl::CreateTextureFromMtlResource()
    virtual void DILIGENT_CALL_TYPE CreateTextureFromMtlResource(id<MTLTexture>  mtlTexture,
                                                                 RESOURCE_STATE  InitialState,
                                                                 ITexture**      ppTexture) override final;

    /// Implementation of IRenderDeviceMtl::CreateBufferFromMtlResource()
    virtual void DILIGENT_CALL_TYPE CreateBufferFromMtlResource(id<MTLBuffer>       mtlBuffer,
                                                                const BufferDesc&   BuffDesc,
                                                                RESOURCE_STATE      InitialState,
                                                                IBuffer**           ppBuffer) override final;

    /// Implementation of IRenderDeviceMtl::CreateBLASFromMtlResource()
    virtual void DILIGENT_CALL_TYPE CreateBLASFromMtlResource(id<MTLAccelerationStructure> mtlBLAS,
                                                              const BottomLevelASDesc&     Desc,
                                                              RESOURCE_STATE               InitialState,
                                                              IBottomLevelAS**             ppBLAS)
        API_AVAILABLE(ios(14), macosx(11.0)) API_UNAVAILABLE(tvos) override final;

    /// Implementation of IRenderDeviceMtl::CreateTLASFromMtlResource()
    virtual void DILIGENT_CALL_TYPE CreateTLASFromMtlResource(id<MTLAccelerationStructure> mtlTLAS,
                                                              const TopLevelASDesc&        Desc,
                                                              RESOURCE_STATE               InitialState,
                                                              ITopLevelAS**                ppTLAS)
        API_AVAILABLE(ios(14), macosx(11.0)) API_UNAVAILABLE(tvos) override final;

    /// Implementation of IRenderDeviceMtl::CreateRasterizationRateMapFromMtlResource()
    virtual void DILIGENT_CALL_TYPE CreateRasterizationRateMapFromMtlResource(id<MTLRasterizationRateMap> mtlRRM,
                                                                              IRasterizationRateMapMtl**  ppRRM)
        API_AVAILABLE(ios(13), macosx(10.15.4)) API_UNAVAILABLE(tvos) override final;

    /// Implementation of IRenderDeviceMtl::CreateRasterizationRateMap()
    virtual void DILIGENT_CALL_TYPE CreateRasterizationRateMap(const RasterizationRateMapCreateInfo& CreateInfo,
                                                               IRasterizationRateMapMtl**            ppRRM) override final;

    /// Implementation of IRenderDeviceMtl::CreateSparseTexture()
    virtual void DILIGENT_CALL_TYPE CreateSparseTexture(const TextureDesc& TexDesc,
                                                        IDeviceMemory*     pMemory,
                                                        ITexture**         ppTexture) override final;

    /// Implementation of IRenderDevice::ReleaseStaleResources()
    virtual void DILIGENT_CALL_TYPE ReleaseStaleResources(bool ForceRelease = false) override final;

    /// Implementation of IRenderDevice::IdleGPU()
    virtual void DILIGENT_CALL_TYPE IdleGPU() override final;

    /// Implementation of IRenderDevice::CreateBLAS()
    virtual void DILIGENT_CALL_TYPE CreateBLAS(const BottomLevelASDesc& Desc,
                                                IBottomLevelAS**         ppBLAS) override final;

    /// Implementation of IRenderDevice::CreateTLAS()
    virtual void DILIGENT_CALL_TYPE CreateTLAS(const TopLevelASDesc& Desc,
                                               ITopLevelAS**         ppTLAS) override final;

    /// Implementation of IRenderDevice::CreateSBT()
    virtual void DILIGENT_CALL_TYPE CreateSBT(const ShaderBindingTableDesc& Desc,
                                              IShaderBindingTable**         ppSBT) override final;

    /// Implementation of IRenderDevice::CreateDeferredContext()
    virtual void DILIGENT_CALL_TYPE CreateDeferredContext(IDeviceContext** ppContext) override final;

    /// Implementation of IRenderDevice::GetSparseTextureFormatInfo()
    virtual Bool DILIGENT_CALL_TYPE GetSparseTextureFormatInfo(TEXTURE_FORMAT     TexFormat,
                                                               RESOURCE_DIMENSION Dimension,
                                                               Uint32             SampleCount,
                                                               SparseTextureFormatInfo& FormatInfo) const override final;

    /// Implementation of RenderDeviceBase::TestTextureFormat()
    virtual void TestTextureFormat(TEXTURE_FORMAT TexFormat) override final;

private:
    // The Metal device
    id<MTLDevice> m_mtlDevice;
};

} // namespace Diligent
