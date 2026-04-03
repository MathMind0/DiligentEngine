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
#include "DeviceMemoryMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "MetalDebug.h"
#include "GraphicsAccessories.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

DeviceMemoryMtlImpl::DeviceMemoryMtlImpl(IReferenceCounters*        pRefCounters,
                                         FixedBlockMemoryAllocator& MemAllocator,
                                         RenderDeviceMtlImpl*       pDevice,
                                         const DeviceMemoryDesc&    Desc) :
    TDeviceMemoryBase{pRefCounters, pDevice, DeviceMemoryCreateInfo{Desc, Desc.PageSize}},
    m_Capacity{Desc.PageSize}
{
    id<MTLDevice> mtlDevice = pDevice->GetMtlDevice();
    
    if (Desc.Type == DEVICE_MEMORY_TYPE_SPARSE)
    {
        // Sparse memory requires heap support
        if (@available(iOS 16, macOS 11.0, *))
        {
            // Note: supportsSparseTextures API is not available on all macOS versions
            // We'll try to create the heap and check for failure
            
            // Create heap descriptor for sparse memory
            MTLHeapDescriptor* heapDesc = [[MTLHeapDescriptor alloc] init];
            heapDesc.size = Desc.PageSize > 0 ? Desc.PageSize : 256 * 1024 * 1024; // Default to 256MB
            heapDesc.storageMode = MTLStorageModePrivate;
            heapDesc.cpuCacheMode = MTLCPUCacheModeDefaultCache;
            
            // Enable sparse heap - use untracked hazard mode for sparse resources
            heapDesc.hazardTrackingMode = MTLHazardTrackingModeUntracked;
            heapDesc.resourceOptions = MTLResourceStorageModePrivate | MTLResourceHazardTrackingModeUntracked;
            
            // Create the heap
            m_mtlHeap = [mtlDevice newHeapWithDescriptor:heapDesc];
            if (m_mtlHeap == nil)
            {
                LOG_ERROR_AND_THROW("Failed to create Metal heap for sparse device memory '",
                                   (Desc.Name ? Desc.Name : "<unnamed>"), "'");
            }
            
            m_Capacity = heapDesc.size;
            
            // Set debug label
            if (Desc.Name != nullptr)
            {
                m_mtlHeap.label = [NSString stringWithUTF8String:Desc.Name];
            }
            
            LOG_INFO_MESSAGE("Created Metal sparse heap '", (Desc.Name ? Desc.Name : "<unnamed>"),
                            "' with size ", m_Capacity, " bytes");
        }
        else
        {
            LOG_ERROR_AND_THROW("Sparse memory requires iOS 16+ or macOS 11.0+. Device memory '",
                               (Desc.Name ? Desc.Name : "<unnamed>"), "' cannot be created.");
        }
    }
    else
    {
        LOG_ERROR_AND_THROW("Unknown device memory type: ", static_cast<int>(Desc.Type));
    }
}

DeviceMemoryMtlImpl::~DeviceMemoryMtlImpl()
{
    // Metal heaps are reference-counted by ARC
    LOG_INFO_MESSAGE("Destroyed Metal device memory '",
                    (m_Desc.Name ? m_Desc.Name : "<unnamed>"), "'");
}

id<MTLHeap> DeviceMemoryMtlImpl::GetMtlResource() const
{
    return m_mtlHeap;
}

Bool DeviceMemoryMtlImpl::Resize(Uint64 NewSize)
{
    if (NewSize == 0)
    {
        LOG_ERROR_MESSAGE("NewSize must not be zero");
        return false;
    }
    
    if ((NewSize % m_Desc.PageSize) != 0)
    {
        LOG_ERROR_MESSAGE("NewSize (", NewSize, ") must be a multiple of the page size (", m_Desc.PageSize, ")");
        return false;
    }
    
    // Metal heaps cannot be resized directly; we need to create a new heap
    // This is a limitation of the Metal API
    if (@available(iOS 16, macOS 11.0, *))
    {
        id<MTLDevice> mtlDevice = m_pDevice->GetMtlDevice();
        
        MTLHeapDescriptor* heapDesc = [[MTLHeapDescriptor alloc] init];
        heapDesc.size = NewSize;
        heapDesc.storageMode = MTLStorageModePrivate;
        heapDesc.cpuCacheMode = MTLCPUCacheModeDefaultCache;
        heapDesc.hazardTrackingMode = MTLHazardTrackingModeUntracked;
        heapDesc.resourceOptions = MTLResourceStorageModePrivate | MTLResourceHazardTrackingModeUntracked;
        
        id<MTLHeap> newHeap = [mtlDevice newHeapWithDescriptor:heapDesc];
        if (newHeap == nil)
        {
            LOG_ERROR_MESSAGE("Failed to resize Metal heap to ", NewSize, " bytes");
            return false;
        }
        
        if (m_Desc.Name != nullptr)
        {
            newHeap.label = [NSString stringWithUTF8String:m_Desc.Name];
        }
        
        // Replace the old heap
        m_mtlHeap = newHeap;
        m_Capacity = NewSize;
        
        LOG_INFO_MESSAGE("Resized Metal sparse heap '", (m_Desc.Name ? m_Desc.Name : "<unnamed>"),
                        "' to ", NewSize, " bytes");
        return true;
    }
    
    LOG_ERROR_MESSAGE("Heap resize requires iOS 16+ or macOS 11.0+");
    return false;
}

Uint64 DeviceMemoryMtlImpl::GetCapacity() const
{
    return m_Capacity;
}

Bool DeviceMemoryMtlImpl::IsCompatible(IDeviceObject* pResource) const
{
    if (pResource == nullptr)
    {
        return false;
    }
    
    // For Metal, sparse textures must be created from the same heap
    // We check if the resource is a texture created from this heap
    ITexture* pTexture = nullptr;
    pResource->QueryInterface(IID_Texture, reinterpret_cast<IObject**>(&pTexture));
    if (pTexture != nullptr)
    {
        ITextureMtl* pTextureMtl = nullptr;
        pTexture->QueryInterface(IID_TextureMtl, reinterpret_cast<IObject**>(&pTextureMtl));
        if (pTextureMtl != nullptr)
        {
            id<MTLHeap> resourceHeap = pTextureMtl->GetMtlHeap();
            return resourceHeap == m_mtlHeap;
        }
    }
    
    return false;
}

} // namespace Diligent
