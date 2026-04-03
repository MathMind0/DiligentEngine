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

#include "pch.h"
#include "RenderDeviceMtlImpl.hpp"
#include "ShaderMtlImpl.hpp"
#include "PipelineResourceSignatureMtlImpl.hpp"
#include "PipelineStateMtlImpl.hpp"
#include "PipelineStateCacheMtlImpl.hpp"
#include "FenceMtlImpl.hpp"
#include "QueryMtlImpl.hpp"
#include "BufferMtlImpl.hpp"
#include "BufferViewMtlImpl.hpp"
#include "TextureMtlImpl.hpp"
#include "TextureViewMtlImpl.hpp"
#include "SamplerMtlImpl.hpp"
#include "RenderPassMtlImpl.hpp"
#include "FramebufferMtlImpl.hpp"
#include "BottomLevelASMtlImpl.hpp"
#include "TopLevelASMtlImpl.hpp"
#include "ShaderBindingTableMtlImpl.hpp"
#include "DeviceMemoryMtlImpl.hpp"
#include "RasterizationRateMapMtlImpl.hpp"
#include "SparseTextureManagerMtlImpl.hpp"
#include "DataBlobImpl.hpp"
#include "DebugOutput.h"
#include "MetalTypeConversions.h"

namespace Diligent
{

RenderDeviceMtlImpl::RenderDeviceMtlImpl(IReferenceCounters*        pRefCounters,
                                         IMemoryAllocator&          RawMemAllocator,
                                         IEngineFactory*            pEngineFactory,
                                         const EngineMtlCreateInfo& EngineCI,
                                         const GraphicsAdapterInfo& AdapterInfo,
                                         size_t                     CommandQueueCount,
                                         ICommandQueueMtl**         ppCmdQueues,
                                         id<MTLDevice>              mtlDevice) :
    TRenderDeviceBase{
        pRefCounters,
        RawMemAllocator,
        pEngineFactory,
        CommandQueueCount,
        ppCmdQueues,
        EngineCI,
        AdapterInfo},
    m_mtlDevice{mtlDevice}
{
}

RenderDeviceMtlImpl::~RenderDeviceMtlImpl()
{
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateGraphicsPipelineState(const GraphicsPipelineStateCreateInfo& PSOCreateInfo,
                                                                          IPipelineState**                       ppPipelineState)
{
    DEV_CHECK_ERR(ppPipelineState != nullptr, "ppPipelineState must not be null");
    if (ppPipelineState == nullptr)
        return;

    try
    {
        PipelineStateMtlImpl* pPipelineStateMtl = NEW_RC_OBJ(m_ShaderObjAllocator, "PipelineState object", PipelineStateMtlImpl)(this, PSOCreateInfo);
        pPipelineStateMtl->QueryInterface(IID_PipelineState, reinterpret_cast<IObject**>(ppPipelineState));
    }
    catch (const std::exception& e)
    {
        LOG_ERROR_MESSAGE("Failed to create graphics pipeline state: ", e.what());
        *ppPipelineState = nullptr;
    }
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateComputePipelineState(const ComputePipelineStateCreateInfo& PSOCreateInfo,
                                                                         IPipelineState**                      ppPipelineState)
{
    DEV_CHECK_ERR(ppPipelineState != nullptr, "ppPipelineState must not be null");
    if (ppPipelineState == nullptr)
        return;

    try
    {
        PipelineStateMtlImpl* pPipelineStateMtl = NEW_RC_OBJ(m_ShaderObjAllocator, "PipelineState object", PipelineStateMtlImpl)(this, PSOCreateInfo);
        pPipelineStateMtl->QueryInterface(IID_PipelineState, reinterpret_cast<IObject**>(ppPipelineState));
    }
    catch (const std::exception& e)
    {
        LOG_ERROR_MESSAGE("Failed to create compute pipeline state: ", e.what());
        *ppPipelineState = nullptr;
    }
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateRayTracingPipelineState(const RayTracingPipelineStateCreateInfo& PSOCreateInfo,
                                                                            IPipelineState**                         ppPipelineState)
{
    LOG_ERROR_MESSAGE("CreateRayTracingPipelineState is not implemented yet. Metal backend is under development.");
    if (ppPipelineState) *ppPipelineState = nullptr;
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateBuffer(const BufferDesc& BuffDesc,
                                                           const BufferData* pBuffData,
                                                           IBuffer**         ppBuffer)
{
    CreateBufferImpl(ppBuffer, BuffDesc, pBuffData);
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateTexture(const TextureDesc& TexDesc,
                                                           const TextureData* pTexData,
                                                           ITexture**         ppTexture)
{
    DEV_CHECK_ERR(ppTexture != nullptr, "ppTexture must not be null");
    if (ppTexture == nullptr)
        return;

    *ppTexture = nullptr;

    try
    {
        // Create Metal texture descriptor
        MTLTextureDescriptor* mtlDesc = [[MTLTextureDescriptor alloc] init];
        
        // Set texture type
        switch (TexDesc.Type)
        {
            case RESOURCE_DIM_TEX_1D:
                mtlDesc.textureType = MTLTextureType1D;
                break;
            case RESOURCE_DIM_TEX_1D_ARRAY:
                mtlDesc.textureType = MTLTextureType1DArray;
                break;
            case RESOURCE_DIM_TEX_2D:
                mtlDesc.textureType = MTLTextureType2D;
                break;
            case RESOURCE_DIM_TEX_2D_ARRAY:
                mtlDesc.textureType = MTLTextureType2DArray;
                break;
            case RESOURCE_DIM_TEX_3D:
                mtlDesc.textureType = MTLTextureType3D;
                break;
            case RESOURCE_DIM_TEX_CUBE:
                mtlDesc.textureType = MTLTextureTypeCube;
                break;
            case RESOURCE_DIM_TEX_CUBE_ARRAY:
                mtlDesc.textureType = MTLTextureTypeCubeArray;
                break;
            default:
                LOG_ERROR_AND_THROW("Unknown texture type");
        }
        
        // Set pixel format
        mtlDesc.pixelFormat = TexFormatToMtlPixelFormat(TexDesc.Format);
        if (mtlDesc.pixelFormat == MTLPixelFormatInvalid)
        {
            LOG_ERROR_AND_THROW("Unsupported texture format: ", TexDesc.Format);
        }
        
        // Set dimensions
        mtlDesc.width = TexDesc.Width;
        mtlDesc.height = (TexDesc.Type == RESOURCE_DIM_TEX_1D || TexDesc.Type == RESOURCE_DIM_TEX_1D_ARRAY) ? 1 : TexDesc.Height;
        mtlDesc.depth = (TexDesc.Type == RESOURCE_DIM_TEX_3D) ? TexDesc.Depth : 1;
        mtlDesc.mipmapLevelCount = TexDesc.MipLevels;
        mtlDesc.sampleCount = TexDesc.SampleCount;
        mtlDesc.arrayLength = (TexDesc.Type == RESOURCE_DIM_TEX_1D_ARRAY || 
                               TexDesc.Type == RESOURCE_DIM_TEX_2D_ARRAY || 
                               TexDesc.Type == RESOURCE_DIM_TEX_CUBE_ARRAY) ? TexDesc.ArraySize : 1;
        
        // Set usage
        mtlDesc.usage = MTLTextureUsageUnknown;
        if (TexDesc.BindFlags & BIND_RENDER_TARGET)
            mtlDesc.usage |= MTLTextureUsageRenderTarget;
        if (TexDesc.BindFlags & BIND_DEPTH_STENCIL)
            mtlDesc.usage |= MTLTextureUsageRenderTarget;
        if (TexDesc.BindFlags & BIND_SHADER_RESOURCE)
            mtlDesc.usage |= MTLTextureUsageShaderRead;
        if (TexDesc.BindFlags & BIND_UNORDERED_ACCESS)
            mtlDesc.usage |= MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;
        
        // Set storage mode
        if (TexDesc.Usage == USAGE_IMMUTABLE || TexDesc.Usage == USAGE_DEFAULT)
        {
            mtlDesc.storageMode = MTLStorageModePrivate;
        }
        else if (TexDesc.Usage == USAGE_DYNAMIC)
        {
            mtlDesc.storageMode = MTLStorageModeManaged;
        }
        else if (TexDesc.Usage == USAGE_STAGING)
        {
            mtlDesc.storageMode = MTLStorageModeShared;
        }
        else
        {
            mtlDesc.storageMode = MTLStorageModePrivate;
        }
        
        // Create Metal texture
        id<MTLTexture> mtlTexture = [m_mtlDevice newTextureWithDescriptor:mtlDesc];
        if (mtlTexture == nil)
        {
            LOG_ERROR_AND_THROW("Failed to create Metal texture");
        }
        
        // Set debug label
        if (TexDesc.Name != nullptr)
        {
            mtlTexture.label = [NSString stringWithUTF8String:TexDesc.Name];
        }
        
        // Upload initial data if provided
        if (pTexData != nullptr && pTexData->pSubResources != nullptr)
        {
            for (Uint32 slice = 0; slice < pTexData->NumSubresources; ++slice)
            {
                const TextureSubResData& subResData = pTexData->pSubResources[slice];
                
                MTLRegion region;
                if (TexDesc.Type == RESOURCE_DIM_TEX_3D)
                {
                    region = MTLRegionMake3D(0, 0, 0, TexDesc.Width, TexDesc.Height, TexDesc.Depth);
                }
                else if (TexDesc.Type == RESOURCE_DIM_TEX_1D || TexDesc.Type == RESOURCE_DIM_TEX_1D_ARRAY)
                {
                    region = MTLRegionMake1D(0, TexDesc.Width);
                }
                else
                {
                    region = MTLRegionMake2D(0, 0, TexDesc.Width, TexDesc.Height);
                }
                
                [mtlTexture replaceRegion:region
                          mipmapLevel:0
                                slice:0
                            withBytes:subResData.pData
                          bytesPerRow:subResData.Stride
                        bytesPerImage:subResData.DepthStride];
            }
        }
        
        // Create TextureMtlImpl wrapper
        TextureMtlImpl* pTextureMtl = NEW_RC_OBJ(m_TexObjAllocator, "TextureMtlImpl instance", TextureMtlImpl)
            (m_TexViewObjAllocator, this, TexDesc, pTexData);
        
        pTextureMtl->QueryInterface(IID_Texture, reinterpret_cast<IObject**>(ppTexture));
        
        LOG_INFO_MESSAGE("Created Metal texture '", (TexDesc.Name ? TexDesc.Name : "<unnamed>"),
                        "' (", TexDesc.Width, "x", TexDesc.Height, ", format=", TexDesc.Format, ")");
    }
    catch (const std::exception& e)
    {
        LOG_ERROR_MESSAGE("Failed to create texture: ", e.what());
        if (*ppTexture)
        {
            (*ppTexture)->Release();
            *ppTexture = nullptr;
        }
    }
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateSampler(const SamplerDesc& SamplerDesc,
                                                            ISampler**         ppSampler)
{
    CreateSamplerImpl(ppSampler, SamplerDesc);
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateShader(const ShaderCreateInfo& ShaderCI,
                                                          IShader**               ppShader,
                                                          IDataBlob**             ppCompilerOutput)
{
    DEV_CHECK_ERR(ppShader != nullptr, "ppShader must not be null");
    if (ppShader == nullptr)
        return;

    ShaderMtlImpl::CreateInfo ShaderMtlCI{
        GetDeviceInfo(),
        GetAdapterInfo(),
        ppCompilerOutput,
        nullptr, // TODO: Add thread pool support
    };

    try
    {
        ShaderMtlImpl* pShaderMtl = NEW_RC_OBJ(m_ShaderObjAllocator, "Shader object", ShaderMtlImpl)(this, ShaderCI, ShaderMtlCI);
        pShaderMtl->QueryInterface(IID_Shader, reinterpret_cast<IObject**>(ppShader));
    }
    catch (...)
    {
        if (ppCompilerOutput != nullptr && *ppCompilerOutput == nullptr)
        {
            // Create empty blob to indicate compilation failure
            RefCntAutoPtr<IDataBlob> pErrors;
            pErrors = DataBlobImpl::Create(size_t{0});
            pErrors->QueryInterface(IID_DataBlob, reinterpret_cast<IObject**>(ppCompilerOutput));
        }
        LOG_ERROR("Failed to create Metal shader");
        *ppShader = nullptr;
    }
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateFence(const FenceDesc& Desc,
                                                         IFence**         ppFence)
{
    DEV_CHECK_ERR(ppFence != nullptr, "ppFence must not be null");
    if (ppFence == nullptr)
        return;

    try
    {
        FenceMtlImpl* pFenceMtl = NEW_RC_OBJ(m_BufObjAllocator, "Fence object", FenceMtlImpl)(this, Desc);
        pFenceMtl->QueryInterface(IID_Fence, reinterpret_cast<IObject**>(ppFence));
    }
    catch (const std::exception& e)
    {
        LOG_ERROR_MESSAGE("Failed to create fence: ", e.what());
        *ppFence = nullptr;
    }
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateQuery(const QueryDesc& Desc,
                                                         IQuery**         ppQuery)
{
    DEV_CHECK_ERR(ppQuery != nullptr, "ppQuery must not be null");
    if (ppQuery == nullptr)
        return;

    try
    {
        QueryMtlImpl* pQueryMtl = NEW_RC_OBJ(m_BufObjAllocator, "Query object", QueryMtlImpl)(this, Desc);
        pQueryMtl->QueryInterface(IID_Query, reinterpret_cast<IObject**>(ppQuery));
    }
    catch (const std::exception& e)
    {
        LOG_ERROR_MESSAGE("Failed to create query: ", e.what());
        *ppQuery = nullptr;
    }
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateRenderPass(const RenderPassDesc& Desc,
                                                              IRenderPass**         ppRenderPass)
{
    LOG_ERROR_MESSAGE("CreateRenderPass is not implemented yet. Metal backend is under development.");
    if (ppRenderPass) *ppRenderPass = nullptr;
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateFramebuffer(const FramebufferDesc& Desc,
                                                               IFramebuffer**         ppFramebuffer)
{
    LOG_ERROR_MESSAGE("CreateFramebuffer is not implemented yet. Metal backend is under development.");
    if (ppFramebuffer) *ppFramebuffer = nullptr;
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreatePipelineResourceSignature(const PipelineResourceSignatureDesc& Desc,
                                                                              IPipelineResourceSignature**         ppSignature)
{
    VERIFY_EXPR(ppSignature != nullptr);
    *ppSignature = nullptr;

    try
    {
        auto pSignature = RefCntAutoPtr<PipelineResourceSignatureMtlImpl>{
            NEW_RC_OBJ(GetRawAllocator(), "PipelineResourceSignatureMtlImpl instance", PipelineResourceSignatureMtlImpl)(this, Desc)
        };
        pSignature->QueryInterface(IID_PipelineResourceSignature, reinterpret_cast<IObject**>(ppSignature));
    }
    catch (const std::exception& e)
    {
        LOG_ERROR_MESSAGE("Failed to create pipeline resource signature: ", e.what());
    }
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreatePipelineStateCache(const PipelineStateCacheCreateInfo& CreateInfo,
                                                                       IPipelineStateCache**               ppPSOCache)
{
    DEV_CHECK_ERR(ppPSOCache != nullptr, "ppPSOCache must not be null");
    if (ppPSOCache == nullptr)
        return;

    try
    {
        PipelineStateCacheMtlImpl* pCacheMtl = NEW_RC_OBJ(m_BufObjAllocator, "PipelineStateCache object", PipelineStateCacheMtlImpl)(this, CreateInfo);
        pCacheMtl->QueryInterface(IID_PipelineStateCache, reinterpret_cast<IObject**>(ppPSOCache));
    }
    catch (const std::exception& e)
    {
        LOG_ERROR_MESSAGE("Failed to create pipeline state cache: ", e.what());
        *ppPSOCache = nullptr;
    }
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateDeviceMemory(const DeviceMemoryCreateInfo& CreateInfo,
                                                                 IDeviceMemory**               ppMemory)
{
    LOG_ERROR_MESSAGE("CreateDeviceMemory is not implemented yet. Metal backend is under development.");
    if (ppMemory) *ppMemory = nullptr;
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateTextureFromMtlResource(id<MTLTexture>  mtlTexture,
                                                                           RESOURCE_STATE  InitialState,
                                                                           ITexture**      ppTexture)
{
    LOG_ERROR_MESSAGE("CreateTextureFromMtlResource is not implemented yet. Metal backend is under development.");
    if (ppTexture) *ppTexture = nullptr;
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateBufferFromMtlResource(id<MTLBuffer>       mtlBuffer,
                                                                          const BufferDesc&   BuffDesc,
                                                                          RESOURCE_STATE      InitialState,
                                                                          IBuffer**           ppBuffer)
{
    LOG_ERROR_MESSAGE("CreateBufferFromMtlResource is not implemented yet. Metal backend is under development.");
    if (ppBuffer) *ppBuffer = nullptr;
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateBLASFromMtlResource(id<MTLAccelerationStructure> mtlBLAS,
                                                                        const BottomLevelASDesc&     Desc,
                                                                        RESOURCE_STATE               InitialState,
                                                                        IBottomLevelAS**             ppBLAS)
{
    DEV_CHECK_ERR(ppBLAS != nullptr, "ppBLAS must not be null");
    if (ppBLAS == nullptr)
        return;

    if (@available(iOS 14, macOS 11.0, *))
    {
        try
        {
            BottomLevelASMtlImpl* pBLASMtl = NEW_RC_OBJ(m_BLASAllocator, "BottomLevelAS object", BottomLevelASMtlImpl)(
                this, Desc, InitialState, mtlBLAS);
            pBLASMtl->QueryInterface(IID_BottomLevelAS, reinterpret_cast<IObject**>(ppBLAS));
        }
        catch (const std::exception& e)
        {
            LOG_ERROR_MESSAGE("Failed to create BLAS from Metal resource: ", e.what());
            *ppBLAS = nullptr;
        }
    }
    else
    {
        LOG_ERROR_MESSAGE("CreateBLASFromMtlResource requires iOS 14+ or macOS 11.0+");
        *ppBLAS = nullptr;
    }
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateTLASFromMtlResource(id<MTLAccelerationStructure> mtlTLAS,
                                                                        const TopLevelASDesc&        Desc,
                                                                        RESOURCE_STATE               InitialState,
                                                                        ITopLevelAS**                ppTLAS)
{
    DEV_CHECK_ERR(ppTLAS != nullptr, "ppTLAS must not be null");
    if (ppTLAS == nullptr)
        return;

    if (@available(iOS 14, macOS 11.0, *))
    {
        try
        {
            TopLevelASMtlImpl* pTLASMtl = NEW_RC_OBJ(m_TLASAllocator, "TopLevelAS object", TopLevelASMtlImpl)(
                this, Desc, InitialState, mtlTLAS);
            pTLASMtl->QueryInterface(IID_TopLevelAS, reinterpret_cast<IObject**>(ppTLAS));
        }
        catch (const std::exception& e)
        {
            LOG_ERROR_MESSAGE("Failed to create TLAS from Metal resource: ", e.what());
            *ppTLAS = nullptr;
        }
    }
    else
    {
        LOG_ERROR_MESSAGE("CreateTLASFromMtlResource requires iOS 14+ or macOS 11.0+");
        *ppTLAS = nullptr;
    }
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateRasterizationRateMapFromMtlResource(id<MTLRasterizationRateMap> mtlRRM,
                                                                                        IRasterizationRateMapMtl**  ppRRM)
{
    if (@available(iOS 13.0, macOS 10.15.4, *))
    {
        if (ppRRM == nullptr)
        {
            LOG_ERROR_MESSAGE("ppRRM must not be null");
            return;
        }
        
        if (mtlRRM == nil)
        {
            LOG_ERROR_MESSAGE("mtlRRM must not be null");
            *ppRRM = nullptr;
            return;
        }
        
        RasterizationRateMapDesc Desc;
        Desc.Name        = "Rasterization rate map from Metal resource";
        Desc.ScreenWidth = static_cast<Uint32>(mtlRRM.screenSize.width);
        Desc.ScreenHeight = static_cast<Uint32>(mtlRRM.screenSize.height);
        Desc.LayerCount  = mtlRRM.layerCount;
        
        RasterizationRateMapMtlImpl* pRRM = NEW_RC_OBJ(GetRawAllocator(), "RasterizationRateMapMtlImpl", RasterizationRateMapMtlImpl)(this, Desc, mtlRRM);
        *ppRRM = pRRM;
    }
    else
    {
        LOG_ERROR_MESSAGE("Rasterization rate maps require iOS 13.0+ or macOS 10.15.4+");
        if (ppRRM) *ppRRM = nullptr;
    }
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateRasterizationRateMap(const RasterizationRateMapCreateInfo& CreateInfo,
                                                                         IRasterizationRateMapMtl**            ppRRM)
{
    if (@available(iOS 13.0, macOS 10.15.4, *))
    {
        if (ppRRM == nullptr)
        {
            LOG_ERROR_MESSAGE("ppRRM must not be null");
            return;
        }
        
        *ppRRM = nullptr;
        
        if (CreateInfo.Desc.ScreenWidth == 0 || CreateInfo.Desc.ScreenHeight == 0)
        {
            LOG_ERROR_MESSAGE("Screen width and height must be non-zero");
            return;
        }
        
        RasterizationRateMapMtlImpl* pRRM = NEW_RC_OBJ(GetRawAllocator(), "RasterizationRateMapMtlImpl", RasterizationRateMapMtlImpl)(this, CreateInfo);
        *ppRRM = pRRM;
    }
    else
    {
        LOG_ERROR_MESSAGE("Rasterization rate maps require iOS 13.0+ or macOS 10.15.4+");
        if (ppRRM) *ppRRM = nullptr;
    }
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateSparseTexture(const TextureDesc& TexDesc,
                                                                  IDeviceMemory*     pMemory,
                                                                  ITexture**         ppTexture)
{
    if (ppTexture == nullptr)
    {
        LOG_ERROR_MESSAGE("ppTexture must not be null");
        return;
    }
    
    *ppTexture = nullptr;
    
    // Check platform support
    if (@available(iOS 16, macOS 11.0, *))
    {
        // Check if sparse textures are supported by checking sparseTileSizeInBytes
        if (m_mtlDevice.sparseTileSizeInBytes == 0)
        {
            LOG_ERROR_MESSAGE("Sparse textures are not supported on this device");
            return;
        }
        
        // Validate device memory
        if (pMemory == nullptr)
        {
            LOG_ERROR_MESSAGE("pMemory must not be null for sparse textures");
            return;
        }
        
        auto* pMemoryMtl = ClassPtrCast<DeviceMemoryMtlImpl>(pMemory);
        if (pMemoryMtl == nullptr)
        {
            LOG_ERROR_MESSAGE("Invalid device memory object. Must be created with CreateDeviceMemory.");
            return;
        }
        
        // Validate texture usage
        if (TexDesc.Usage != USAGE_SPARSE)
        {
            LOG_ERROR_MESSAGE("Texture usage must be USAGE_SPARSE for sparse textures");
            return;
        }
        
        // Validate texture type (Metal only supports 2D, 2D array, and 3D sparse textures)
        if (TexDesc.Type != RESOURCE_DIM_TEX_2D &&
            TexDesc.Type != RESOURCE_DIM_TEX_2D_ARRAY &&
            TexDesc.Type != RESOURCE_DIM_TEX_3D)
        {
            LOG_ERROR_MESSAGE("Only 2D, 2D array, and 3D textures are supported for sparse textures");
            return;
        }
        
        try
        {
            // Create texture using NEW_RC_OBJ pattern
            TextureMtlImpl* pTextureMtl = NEW_RC_OBJ(m_TexObjAllocator, "TextureMtlImpl instance", TextureMtlImpl)(
                m_TexViewObjAllocator, this, TexDesc, pMemoryMtl);
            
            pTextureMtl->QueryInterface(IID_Texture, reinterpret_cast<IObject**>(ppTexture));
        }
        catch (const std::exception& e)
        {
            LOG_ERROR_MESSAGE("Failed to create sparse texture '", 
                             (TexDesc.Name ? TexDesc.Name : "<unnamed>"), "': ", e.what());
        }
    }
    else
    {
        LOG_ERROR_MESSAGE("Sparse textures require iOS 16+ or macOS 11.0+");
    }
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::ReleaseStaleResources(bool ForceRelease)
{
    // TODO: Implement resource release
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::IdleGPU()
{
    // Wait for all command queues to idle
    for (size_t i = 0; i < m_CmdQueueCount; ++i)
    {
        IdleCommandQueue(SoftwareQueueIndex{i}, false);
    }
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateBLAS(const BottomLevelASDesc& Desc,
                                                         IBottomLevelAS**         ppBLAS)
{
    DEV_CHECK_ERR(ppBLAS != nullptr, "ppBLAS must not be null");
    if (ppBLAS == nullptr)
        return;

    if (@available(iOS 14, macOS 11.0, *))
    {
        try
        {
            BottomLevelASMtlImpl* pBLASMtl = NEW_RC_OBJ(m_BLASAllocator, "BottomLevelAS object", BottomLevelASMtlImpl)(
                this, Desc);
            pBLASMtl->QueryInterface(IID_BottomLevelAS, reinterpret_cast<IObject**>(ppBLAS));
        }
        catch (const std::exception& e)
        {
            LOG_ERROR_MESSAGE("Failed to create BLAS: ", e.what());
            *ppBLAS = nullptr;
        }
    }
    else
    {
        LOG_ERROR_MESSAGE("CreateBLAS requires iOS 14+ or macOS 11.0+. Ray tracing is not available on this device.");
        *ppBLAS = nullptr;
    }
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateTLAS(const TopLevelASDesc& Desc,
                                                        ITopLevelAS**         ppTLAS)
{
    DEV_CHECK_ERR(ppTLAS != nullptr, "ppTLAS must not be null");
    if (ppTLAS == nullptr)
        return;

    if (@available(iOS 14, macOS 11.0, *))
    {
        try
        {
            TopLevelASMtlImpl* pTLASMtl = NEW_RC_OBJ(m_TLASAllocator, "TopLevelAS object", TopLevelASMtlImpl)(
                this, Desc);
            pTLASMtl->QueryInterface(IID_TopLevelAS, reinterpret_cast<IObject**>(ppTLAS));
        }
        catch (const std::exception& e)
        {
            LOG_ERROR_MESSAGE("Failed to create TLAS: ", e.what());
            *ppTLAS = nullptr;
        }
    }
    else
    {
        LOG_ERROR_MESSAGE("CreateTLAS requires iOS 14+ or macOS 11.0+. Ray tracing is not available on this device.");
        *ppTLAS = nullptr;
    }
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateSBT(const ShaderBindingTableDesc& Desc,
                                                       IShaderBindingTable**         ppSBT)
{
    LOG_ERROR_MESSAGE("CreateSBT is not implemented. Ray tracing will be implemented in Phase 5.");
    if (ppSBT) *ppSBT = nullptr;
}

void DILIGENT_CALL_TYPE RenderDeviceMtlImpl::CreateDeferredContext(IDeviceContext** ppContext)
{
    LOG_ERROR_MESSAGE("CreateDeferredContext is not implemented yet. Metal backend is under development.");
    if (ppContext) *ppContext = nullptr;
}

Bool DILIGENT_CALL_TYPE RenderDeviceMtlImpl::GetSparseTextureFormatInfo(TEXTURE_FORMAT     TexFormat,
                                                                         RESOURCE_DIMENSION Dimension,
                                                                         Uint32             SampleCount,
                                                                         SparseTextureFormatInfo& FormatInfo) const
{
    LOG_ERROR_MESSAGE("GetSparseTextureFormatInfo is not implemented. Sparse resources are not supported in Metal backend.");
    return False;
}

void RenderDeviceMtlImpl::TestTextureFormat(TEXTURE_FORMAT TexFormat)
{
    // TODO: Implement texture format testing
    // This is called to verify that a texture format is supported
}

} // namespace Diligent
