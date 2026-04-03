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
#include "BufferMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "BufferViewMtlImpl.hpp"
#include "MetalTypeConversions.h"
#include "GraphicsAccessories.hpp"

namespace Diligent
{

BufferMtlImpl::BufferMtlImpl(IReferenceCounters*        pRefCounters,
                             FixedBlockMemoryAllocator& BuffViewObjMemAllocator,
                             RenderDeviceMtlImpl*       pRenderDeviceMtl,
                             const BufferDesc&          BuffDesc,
                             const BufferData*          pBuffData) :
    TBufferBase{
        pRefCounters,
        BuffViewObjMemAllocator,
        pRenderDeviceMtl,
        BuffDesc,
        false,
    }
{
    ValidateBufferInitData(m_Desc, pBuffData);

    @autoreleasepool
    {
        MTLResourceOptions options = MTLResourceStorageModePrivate;
        
        // Set CPU cache mode and storage mode based on usage
        switch (m_Desc.Usage)
        {
            case USAGE_IMMUTABLE:
            case USAGE_DEFAULT:
                options = MTLResourceStorageModePrivate;
                break;
                
            case USAGE_DYNAMIC:
            case USAGE_STAGING:
                options = MTLResourceStorageModeShared;
                break;
                
            case USAGE_UNIFIED:
                options = MTLResourceStorageModeShared;
                break;
                
            default:
                LOG_ERROR_AND_THROW("Unknown buffer usage type");
                break;
        }
        
        // Create Metal buffer
        m_mtlBuffer = [pRenderDeviceMtl->GetMtlDevice() newBufferWithLength:m_Desc.Size
                                                                    options:options];
        
        if (m_mtlBuffer == nil)
        {
            LOG_ERROR_AND_THROW("Failed to create Metal buffer '", m_Desc.Name, "'");
        }
        
        // Set debug label
        if (m_Desc.Name != nullptr)
        {
            m_mtlBuffer.label = [NSString stringWithUTF8String:m_Desc.Name];
        }
        
        // Copy initial data if provided
        if (pBuffData != nullptr && pBuffData->pData != nullptr)
        {
            if (options & MTLResourceStorageModeShared)
            {
                // Can copy directly for shared buffers
                memcpy([m_mtlBuffer contents], pBuffData->pData, std::min(m_Desc.Size, pBuffData->DataSize));
            }
            else
            {
                // TODO: For private storage, need to use a staging buffer and GPU copy
                LOG_WARNING_MESSAGE("Initial data for private storage buffer not yet supported. Use a staging buffer.");
            }
        }
    }
}

BufferMtlImpl::~BufferMtlImpl()
{
    m_mtlBuffer = nil;
}

void BufferMtlImpl::CreateViewInternal(const BufferViewDesc& ViewDesc,
                                       IBufferView**         ppView,
                                       bool                  bIsDefaultView)
{
    VERIFY(ppView != nullptr, "View pointer address is null");
    if (!ppView) return;
    VERIFY(*ppView == nullptr, "Overwriting reference to an existing object may result in memory leaks");
    
    *ppView = nullptr;
    
    try
    {
        BufferViewDesc UpdatedViewDesc = ViewDesc;
        ValidateAndCorrectBufferViewDesc(m_Desc, UpdatedViewDesc, GetDevice()->GetAdapterInfo().Buffer.StructuredBufferOffsetAlignment);
        
        *ppView = NEW_RC_OBJ(GetDevice()->GetBuffViewObjAllocator(), "BufferViewMtlImpl instance", BufferViewMtlImpl, bIsDefaultView ? this : nullptr)
            (GetDevice(), UpdatedViewDesc, this, bIsDefaultView);
    }
    catch (...)
    {
        LOG_ERROR("Failed to create buffer view");
    }
}

} // namespace Diligent