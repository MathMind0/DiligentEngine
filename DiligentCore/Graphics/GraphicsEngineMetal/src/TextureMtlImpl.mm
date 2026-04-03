/*
 *  Copyright 2019-2026 Diligent Graphics LLC
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

#include "pch.h"
#include "TextureMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "DeviceMemoryMtlImpl.hpp"
#include "SparseTextureManagerMtlImpl.hpp"
#include "MetalDebug.h"
#include "GraphicsAccessories.hpp"
#include "MetalTypeConversions.h"

#import <Metal/Metal.h>

namespace Diligent
{

TextureMtlImpl::TextureMtlImpl(IReferenceCounters*        pRefCounters,
                               FixedBlockMemoryAllocator& TexViewObjAllocator,
                               RenderDeviceMtlImpl*       pDevice,
                               const TextureDesc&         TexDesc,
                               const TextureData*         pInitData) :
    TTextureBase{pRefCounters, TexViewObjAllocator, pDevice, TexDesc}
{
    id<MTLDevice> mtlDevice = pDevice->GetMtlDevice();
    
    // Create texture descriptor
    MTLTextureDescriptor* descriptor = [[MTLTextureDescriptor alloc] init];
    
    // Set texture type
    switch (TexDesc.Type)
    {
        case RESOURCE_DIM_TEX_1D:
            descriptor.textureType = MTLTextureType1D;
            break;
        case RESOURCE_DIM_TEX_1D_ARRAY:
            descriptor.textureType = MTLTextureType1DArray;
            break;
        case RESOURCE_DIM_TEX_2D:
            descriptor.textureType = MTLTextureType2D;
            break;
        case RESOURCE_DIM_TEX_2D_ARRAY:
            descriptor.textureType = MTLTextureType2DArray;
            break;
        case RESOURCE_DIM_TEX_3D:
            descriptor.textureType = MTLTextureType3D;
            break;
        case RESOURCE_DIM_TEX_CUBE:
            descriptor.textureType = MTLTextureTypeCube;
            break;
        case RESOURCE_DIM_TEX_CUBE_ARRAY:
            descriptor.textureType = MTLTextureTypeCubeArray;
            break;
        default:
            LOG_ERROR_AND_THROW("Unknown texture type");
    }
    
    // Set pixel format
    descriptor.pixelFormat = TexFormatToMtlPixelFormat(TexDesc.Format);
    
    // Set dimensions
    descriptor.width = TexDesc.Width;
    descriptor.height = TexDesc.Height > 0 ? TexDesc.Height : 1;
    descriptor.depth = TexDesc.Depth > 0 ? TexDesc.Depth : 1;
    descriptor.mipmapLevelCount = TexDesc.MipLevels > 0 ? TexDesc.MipLevels : 1;
    descriptor.sampleCount = TexDesc.SampleCount > 0 ? TexDesc.SampleCount : 1;
    descriptor.arrayLength = TexDesc.ArraySize > 0 ? TexDesc.ArraySize : 1;
    
    // Set usage flags
    MTLTextureUsage usage = MTLTextureUsageUnknown;
    if (TexDesc.BindFlags & BIND_SHADER_RESOURCE)
        usage |= MTLTextureUsageShaderRead;
    if (TexDesc.BindFlags & BIND_RENDER_TARGET)
        usage |= MTLTextureUsageRenderTarget;
    if (TexDesc.BindFlags & BIND_DEPTH_STENCIL)
        usage |= MTLTextureUsageRenderTarget;
    if (TexDesc.BindFlags & BIND_UNORDERED_ACCESS)
        usage |= MTLTextureUsageShaderWrite;
    descriptor.usage = usage;
    
    // Set storage mode based on usage
    if (TexDesc.Usage == USAGE_STAGING)
    {
        descriptor.storageMode = MTLStorageModeShared;
    }
    else if (TexDesc.Usage == USAGE_DYNAMIC)
    {
        descriptor.storageMode = MTLStorageModeManaged;
    }
    else
    {
        descriptor.storageMode = MTLStorageModePrivate;
    }
    
    // Create the texture
    m_mtlTexture = [mtlDevice newTextureWithDescriptor:descriptor];
    if (m_mtlTexture == nil)
    {
        LOG_ERROR_AND_THROW("Failed to create Metal texture '",
                           (TexDesc.Name ? TexDesc.Name : "<unnamed>"), "'");
    }
    
    // Set debug label
    if (TexDesc.Name != nullptr)
    {
        m_mtlTexture.label = [NSString stringWithUTF8String:TexDesc.Name];
    }
    
    m_IsSparse = false;
    
    LOG_INFO_MESSAGE("Created Metal texture '", (TexDesc.Name ? TexDesc.Name : "<unnamed>"),
                    "' (", TexDesc.Width, "x", TexDesc.Height, ", format: ",
                    GetTextureFormatAttribs(TexDesc.Format).Name, ")");
}

TextureMtlImpl::TextureMtlImpl(IReferenceCounters*        pRefCounters,
                               FixedBlockMemoryAllocator& TexViewObjAllocator,
                               RenderDeviceMtlImpl*       pDevice,
                               const TextureDesc&         TexDesc,
                               DeviceMemoryMtlImpl*       pMemory) API_AVAILABLE(ios(16), macosx(11.0)) :
    TTextureBase{pRefCounters, TexViewObjAllocator, pDevice, TexDesc}
{
    CreateSparseTextureFromHeap(pMemory);
}

void TextureMtlImpl::CreateSparseTextureFromHeap(DeviceMemoryMtlImpl* pMemory)
{
    // Sparse textures require macOS 11.0+ and specific hardware support
    // This feature is disabled due to Metal API compatibility issues
    LOG_ERROR_AND_THROW("Sparse textures are not supported in this build. Texture '",
                       (m_Desc.Name ? m_Desc.Name : "<unnamed>"), "' cannot be created.");
    
    /* Disabled due to Metal API compatibility
    id<MTLDevice> mtlDevice = m_pDevice->GetMtlDevice();
    
    // Check for sparse texture support
    if (![mtlDevice supportsSparseTextures])
    {
        LOG_ERROR_AND_THROW("Sparse textures are not supported on this device. Texture '",
                           (m_Desc.Name ? m_Desc.Name : "<unnamed>"), "' cannot be created.");
    }
    
    // Get the heap from device memory
    m_mtlHeap = pMemory->GetMtlResource();
    if (m_mtlHeap == nil)
    {
        LOG_ERROR_AND_THROW("Device memory does not have a valid Metal heap");
    }
    
    // Create texture descriptor
    MTLTextureDescriptor* descriptor = [[MTLTextureDescriptor alloc] init];
    
    // Set texture type
    switch (m_Desc.Type)
    {
        case RESOURCE_DIM_TEX_2D:
            descriptor.textureType = MTLTextureType2D;
            break;
        case RESOURCE_DIM_TEX_2D_ARRAY:
            descriptor.textureType = MTLTextureType2DArray;
            break;
        case RESOURCE_DIM_TEX_3D:
            descriptor.textureType = MTLTextureType3D;
            break;
        default:
            LOG_ERROR_AND_THROW("Unsupported sparse texture type. Only 2D, 2D array, and 3D textures are supported for sparse textures.");
    }
    
    // Set pixel format
    descriptor.pixelFormat = TexFormatToMtlPixelFormat(m_Desc.Format);
    
    // Set dimensions
    descriptor.width = m_Desc.Width;
    descriptor.height = m_Desc.Height > 0 ? m_Desc.Height : 1;
    descriptor.depth = m_Desc.Depth > 0 ? m_Desc.Depth : 1;
    descriptor.mipmapLevelCount = m_Desc.MipLevels > 0 ? m_Desc.MipLevels : 1;
    descriptor.sampleCount = m_Desc.SampleCount > 0 ? m_Desc.SampleCount : 1;
    descriptor.arrayLength = m_Desc.ArraySize > 0 ? m_Desc.ArraySize : 1;
    
    // Set usage flags
    MTLTextureUsage usage = MTLTextureUsageShaderRead;
    if (m_Desc.BindFlags & BIND_UNORDERED_ACCESS)
        usage |= MTLTextureUsageShaderWrite;
    if (m_Desc.BindFlags & BIND_RENDER_TARGET)
        usage |= MTLTextureUsageRenderTarget;
    descriptor.usage = usage;
    
    // Sparse textures must use private storage mode
    descriptor.storageMode = MTLStorageModePrivate;
    
    // Create the sparse texture from the heap
    m_mtlTexture = [mtlDevice newTextureWithDescriptor:descriptor
                                                heap:m_mtlHeap
                                              offset:0];
    if (m_mtlTexture == nil)
    {
        LOG_ERROR_AND_THROW("Failed to create Metal sparse texture '",
                           (m_Desc.Name ? m_Desc.Name : "<unnamed>"), "'");
    }
    
    // Set debug label
    if (m_Desc.Name != nullptr)
    {
        m_mtlTexture.label = [NSString stringWithUTF8String:m_Desc.Name];
    }
    
    // Query sparse tile size
    m_SparseTileSize = SparseTextureManagerMtlImpl::CalculateTileSize(
        mtlDevice,
        descriptor.textureType,
        descriptor.pixelFormat,
        descriptor.sampleCount);
    
    m_IsSparse = true;
    
    LOG_INFO_MESSAGE("Created Metal sparse texture '", (m_Desc.Name ? m_Desc.Name : "<unnamed>"),
                    "' (", m_Desc.Width, "x", m_Desc.Height, ", format: ",
                    GetTextureFormatAttribs(m_Desc.Format).Name,
                    ", tile size: ", m_SparseTileSize.width, "x", m_SparseTileSize.height, "x", m_SparseTileSize.depth, ")");
    */
}

TextureMtlImpl::~TextureMtlImpl()
{
    // Important: For sparse textures, we must unmap all tiles before destruction
    // Otherwise, the sparse heap continues to mark those tiles as mapped
    if (m_IsSparse && m_mtlTexture != nil)
    {
        // Note: In a production implementation, we would need to unmap all tiles here
        // This requires tracking all mapped tiles and creating a command buffer to unmap them
        // For now, we log a warning
        LOG_WARNING_MESSAGE("Sparse texture '", (m_Desc.Name ? m_Desc.Name : "<unnamed>"),
                           "' is being destroyed. Ensure all tiles are unmapped before releasing.");
    }
    
    LOG_INFO_MESSAGE("Destroyed Metal texture '", (m_Desc.Name ? m_Desc.Name : "<unnamed>"), "'");
}

id<MTLResource> TextureMtlImpl::GetMtlResource() const
{
    return m_mtlTexture;
}

id<MTLHeap> TextureMtlImpl::GetMtlHeap() const
{
    return m_mtlHeap;
}

Uint64 TextureMtlImpl::GetNativeHandle()
{
    return reinterpret_cast<Uint64>(m_mtlTexture);
}

void TextureMtlImpl::CreateViewInternal(const TextureViewDesc& ViewDesc,
                                         ITextureView**         ppView,
                                         bool                   bIsDefaultView)
{
    VERIFY(ppView != nullptr, "View pointer address is null");
    if (!ppView) return;
    VERIFY(*ppView == nullptr, "Overwriting reference to existing object may cause memory leaks");
    
    *ppView = nullptr;
    
    try
    {
        TextureViewDesc UpdatedViewDesc = ViewDesc;
        ValidatedAndCorrectTextureViewDesc(m_Desc, UpdatedViewDesc);
        
        TextureViewMtlImpl* pViewMtl = NEW_RC_OBJ(m_pDevice->GetTexViewObjAllocator(), 
                                                   "TextureViewMtlImpl instance", 
                                                   TextureViewMtlImpl,
                                                   bIsDefaultView ? this : nullptr)
            (m_pDevice, UpdatedViewDesc, this, bIsDefaultView);
        
        VERIFY(pViewMtl->GetDesc().ViewType == ViewDesc.ViewType, "Incorrect view type");
        
        if (bIsDefaultView)
            *ppView = pViewMtl;
        else
            pViewMtl->QueryInterface(IID_TextureView, ppView);
    }
    catch (const std::runtime_error&)
    {
        const char* ViewTypeName = GetTexViewTypeLiteralName(ViewDesc.ViewType);
        LOG_ERROR("Failed to create view '", ViewDesc.Name ? ViewDesc.Name : "", 
                  "' (", ViewTypeName, ") for texture '", m_Desc.Name ? m_Desc.Name : "", "'");
    }
}

} // namespace Diligent
