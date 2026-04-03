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

#include "RasterizationRateMapMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "GraphicsAccessories.hpp"
#include "EngineMtlImplTraits.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

RasterizationRateMapMtlImpl::RasterizationRateMapMtlImpl(IReferenceCounters*                   pRefCounters,
                                                         RenderDeviceMtlImpl*                  pDevice,
                                                         const RasterizationRateMapCreateInfo& CreateInfo)
    : TRasterizationRateMapBase{pRefCounters, pDevice, CreateInfo.Desc}
{
    if (@available(iOS 13.0, macOS 10.15.4, *))
    {
        id<MTLDevice> mtlDevice = pDevice->GetMtlDevice();
        
        MTLRasterizationRateMapDescriptor* descriptor = [MTLRasterizationRateMapDescriptor rasterizationRateMapDescriptorWithScreenWidth:CreateInfo.Desc.ScreenWidth
                                                                                                                               screenHeight:CreateInfo.Desc.ScreenHeight
                                                                                                                                  layerCount:CreateInfo.Desc.LayerCount];
        
        if (descriptor == nil)
        {
            LOG_ERROR_MESSAGE("Failed to create Metal rasterization rate map descriptor");
            return;
        }
        
        // Configure each layer
        for (Uint32 layer = 0; layer < CreateInfo.Desc.LayerCount && CreateInfo.pLayers != nullptr; ++layer)
        {
            const RasterizationRateLayerDesc& layerDesc = CreateInfo.pLayers[layer];
            MTLRasterizationRateLayerDescriptor* mtlLayer = descriptor.layers[layer];
            
            if (layerDesc.pHorizontal != nullptr && layerDesc.HorizontalCount > 0)
            {
                NSMutableArray<NSNumber*>* horizontalRates = [NSMutableArray arrayWithCapacity:layerDesc.HorizontalCount];
                for (Uint32 i = 0; i < layerDesc.HorizontalCount; ++i)
                {
                    [horizontalRates addObject:@(layerDesc.pHorizontal[i])];
                }
                mtlLayer.horizontalSampleStorage = horizontalRates;
            }
            
            if (layerDesc.pVertical != nullptr && layerDesc.VerticalCount > 0)
            {
                NSMutableArray<NSNumber*>* verticalRates = [NSMutableArray arrayWithCapacity:layerDesc.VerticalCount];
                for (Uint32 i = 0; i < layerDesc.VerticalCount; ++i)
                {
                    [verticalRates addObject:@(layerDesc.pVertical[i])];
                }
                mtlLayer.verticalSampleStorage = verticalRates;
            }
        }
        
        m_mtlRRM = [mtlDevice newRasterizationRateMapWithDescriptor:descriptor];
        
        if (m_mtlRRM == nil)
        {
            LOG_ERROR_MESSAGE("Failed to create Metal rasterization rate map");
            return;
        }
    }
    else
    {
        LOG_ERROR_MESSAGE("Rasterization rate maps require iOS 13.0+ or macOS 10.15.4+");
    }
}

RasterizationRateMapMtlImpl::RasterizationRateMapMtlImpl(IReferenceCounters*        pRefCounters,
                                                         RenderDeviceMtlImpl*       pDevice,
                                                         const RasterizationRateMapDesc& Desc,
                                                         id<MTLRasterizationRateMap>     mtlRRM)
    : TRasterizationRateMapBase{pRefCounters, pDevice, Desc}
{
    if (@available(iOS 13.0, macOS 10.15.4, *))
    {
        if (mtlRRM != nil)
        {
            m_mtlRRM = mtlRRM;
        }
        else
        {
            LOG_ERROR_MESSAGE("Cannot create rasterization rate map from null Metal resource");
        }
    }
    else
    {
        LOG_ERROR_MESSAGE("Rasterization rate maps require iOS 13.0+ or macOS 10.15.4+");
    }
}

RasterizationRateMapMtlImpl::~RasterizationRateMapMtlImpl()
{
    // m_mtlRRM is automatically released by ARC
}

void RasterizationRateMapMtlImpl::GetPhysicalSizeForLayer(Uint32  LayerIndex,
                                                          Uint32& PhysicalWidth,
                                                          Uint32& PhysicalHeight) const
{
    if (@available(iOS 13.0, macOS 10.15.4, *))
    {
        if (m_mtlRRM != nil && LayerIndex < m_Desc.LayerCount)
        {
            CGSize physicalSize = [m_mtlRRM physicalSizeForLayer:LayerIndex];
            PhysicalWidth  = static_cast<Uint32>(physicalSize.width);
            PhysicalHeight = static_cast<Uint32>(physicalSize.height);
        }
        else
        {
            PhysicalWidth  = 0;
            PhysicalHeight = 0;
        }
    }
    else
    {
        PhysicalWidth  = 0;
        PhysicalHeight = 0;
    }
}

void RasterizationRateMapMtlImpl::GetPhysicalGranularity(Uint32& XGranularity,
                                                         Uint32& YGranularity) const
{
    if (@available(iOS 13.0, macOS 10.15.4, *))
    {
        if (m_mtlRRM != nil)
        {
            CGSize granularity = m_mtlRRM.physicalGranularity;
            XGranularity = static_cast<Uint32>(granularity.width);
            YGranularity = static_cast<Uint32>(granularity.height);
        }
        else
        {
            XGranularity = 0;
            YGranularity = 0;
        }
    }
    else
    {
        XGranularity = 0;
        YGranularity = 0;
    }
}

void RasterizationRateMapMtlImpl::MapScreenToPhysicalCoordinates(Uint32 LayerIndex,
                                                                 float  ScreenCoordX,
                                                                 float  ScreenCoordY,
                                                                 float& PhysicalCoordX,
                                                                 float& PhysicalCoordY) const
{
    if (@available(iOS 13.0, macOS 10.15.4, *))
    {
        if (m_mtlRRM != nil && LayerIndex < m_Desc.LayerCount)
        {
            CGPoint screenPoint  = CGPointMake(ScreenCoordX, ScreenCoordY);
            CGPoint physicalPoint = [m_mtlRRM mapScreenToPhysicalCoordinates:screenPoint forLayer:LayerIndex];
            PhysicalCoordX = static_cast<float>(physicalPoint.x);
            PhysicalCoordY = static_cast<float>(physicalPoint.y);
        }
        else
        {
            PhysicalCoordX = 0.0f;
            PhysicalCoordY = 0.0f;
        }
    }
    else
    {
        PhysicalCoordX = 0.0f;
        PhysicalCoordY = 0.0f;
    }
}

void RasterizationRateMapMtlImpl::MapPhysicalToScreenCoordinates(Uint32 LayerIndex,
                                                                 float  PhysicalCoordX,
                                                                 float  PhysicalCoordY,
                                                                 float& ScreenCoordX,
                                                                 float& ScreenCoordY) const
{
    if (@available(iOS 13.0, macOS 10.15.4, *))
    {
        if (m_mtlRRM != nil && LayerIndex < m_Desc.LayerCount)
        {
            CGPoint physicalPoint = CGPointMake(PhysicalCoordX, PhysicalCoordY);
            CGPoint screenPoint   = [m_mtlRRM mapPhysicalToScreenCoordinates:physicalPoint forLayer:LayerIndex];
            ScreenCoordX = static_cast<float>(screenPoint.x);
            ScreenCoordY = static_cast<float>(screenPoint.y);
        }
        else
        {
            ScreenCoordX = 0.0f;
            ScreenCoordY = 0.0f;
        }
    }
    else
    {
        ScreenCoordX = 0.0f;
        ScreenCoordY = 0.0f;
    }
}

void RasterizationRateMapMtlImpl::GetParameterBufferSizeAndAlign(Uint64& Size,
                                                                 Uint32& Align) const
{
    if (@available(iOS 13.0, macOS 10.15.4, *))
    {
        if (m_mtlRRM != nil)
        {
            Size  = m_mtlRRM.parameterBufferSize;
            Align = m_mtlRRM.parameterBufferAlignment;
        }
        else
        {
            Size  = 0;
            Align = 0;
        }
    }
    else
    {
        Size  = 0;
        Align = 0;
    }
}

void RasterizationRateMapMtlImpl::CopyParameterDataToBuffer(IBuffer* pDstBuffer,
                                                            Uint64   Offset) const
{
    if (@available(iOS 13.0, macOS 10.15.4, *))
    {
        if (m_mtlRRM == nil)
        {
            LOG_ERROR_MESSAGE("Cannot copy parameter data from null rasterization rate map");
            return;
        }
        
        if (pDstBuffer == nullptr)
        {
            LOG_ERROR_MESSAGE("Destination buffer is null");
            return;
        }
        
        // Get the Metal buffer
        id<MTLBuffer> mtlBuffer = nullptr;
        BufferDesc    buffDesc  = pDstBuffer->GetDesc();
        
        // We need to cast to get the Metal buffer
        if (buffDesc.Usage == USAGE_UNIFIED)
        {
            // Get the native buffer handle
            IBuffer* pBuffer = pDstBuffer;
            // For unified memory buffers, we need to get the underlying Metal buffer
            // This requires the buffer implementation to expose the Metal resource
            // For now, we'll use a different approach - copy to a staging buffer
            
            // Note: The actual implementation depends on how the Metal buffer exposes its native resource
            // This is a placeholder that uses copyParameterDataToBuffer: with NSData
            
            // Get the CPU-accessible pointer for unified memory
            void* pData = pDstBuffer->GetNativeHandle();
            if (pData != nullptr)
            {
                NSData* data = [m_mtlRRM copyParameterDataToBuffer:nil];
                if (data != nil)
                {
                    size_t dataSize = [data length];
                    memcpy(static_cast<char*>(pData) + Offset, [data bytes], dataSize);
                }
            }
            else
            {
                LOG_ERROR_MESSAGE("Failed to get CPU pointer from unified memory buffer");
            }
        }
        else
        {
            LOG_ERROR_MESSAGE("Rasterization rate map parameter buffer must be USAGE_UNIFIED");
        }
    }
    else
    {
        LOG_ERROR_MESSAGE("Rasterization rate maps require iOS 13.0+ or macOS 10.15.4+");
    }
}

ITextureView* RasterizationRateMapMtlImpl::GetView()
{
    // Note: The actual implementation of GetView() depends on the Metal rasterization rate map API
    // which provides a texture view for framebuffer attachment
    // This is a placeholder that returns null until we have more context on how the view should be created
    LOG_WARNING_MESSAGE("RasterizationRateMapMtlImpl::GetView() is not fully implemented yet");
    return m_pView;
}

} // namespace Diligent
