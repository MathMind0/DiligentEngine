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

#include "MetalMemoryManager.h"

#import <Metal/Metal.h>

namespace Diligent
{

// MetalStagingBufferPool implementation
MetalStagingBufferPool::MetalStagingBufferPool(id<MTLDevice> Device, Uint64 BufferSize) noexcept
    : m_Device(Device)
    , m_BufferSize(BufferSize)
{
    // ARC handles retention automatically
}

MetalStagingBufferPool::~MetalStagingBufferPool() noexcept
{
    // ARC handles release automatically
    for (id<MTLBuffer> Buffer : m_Buffers)
    {
        // Buffers are automatically released by ARC
    }
}

id<MTLBuffer> MetalStagingBufferPool::Allocate(Uint64 Size, Uint64* pOffset) noexcept
{
    if (Size > m_BufferSize)
    {
        LOG_ERROR_MESSAGE("Requested staging buffer size (", Size, 
                         ") exceeds buffer size (", m_BufferSize, ")");
        return nil;
    }
    
    // Check if we need a new buffer
    if (m_Buffers.empty() || m_CurrentOffset + Size > m_BufferSize)
    {
        // Create a new buffer
        @autoreleasepool
        {
            MTLResourceOptions Options = MTLResourceStorageModeShared | MTLResourceCPUCacheModeWriteCombined;
            id<MTLBuffer> NewBuffer = [m_Device newBufferWithLength:m_BufferSize options:Options];
            
            if (NewBuffer == nil)
            {
                LOG_ERROR_MESSAGE("Failed to create staging buffer of size ", m_BufferSize);
                return nil;
            }
            
            m_Buffers.push_back(NewBuffer); // ARC handles retention
            m_CurrentOffset = 0;
            m_CurrentBufferIndex = m_Buffers.size() - 1;
            
            LOG_INFO_MESSAGE("Created staging buffer #", m_CurrentBufferIndex, 
                           ", size: ", m_BufferSize / 1024, " KB");
        }
    }
    
    *pOffset = m_CurrentOffset;
    m_CurrentOffset += Size;
    
    // Align to 256 bytes for optimal performance
    m_CurrentOffset = (m_CurrentOffset + 255) & ~255ULL;
    
    return m_Buffers[m_CurrentBufferIndex];
}

void MetalStagingBufferPool::Reset() noexcept
{
    // Reset offset to beginning of first buffer
    m_CurrentOffset = 0;
    m_CurrentBufferIndex = 0;
    
    // Keep buffers allocated for reuse
}

// MetalRingBuffer implementation
MetalRingBuffer::MetalRingBuffer(id<MTLDevice> Device, Uint64 Size) noexcept
    : m_Device(Device)
    , m_TotalSize(Size)
{
    @autoreleasepool
    {
        // Create ring buffer with shared storage for CPU access
        MTLResourceOptions Options = MTLResourceStorageModeShared | MTLResourceCPUCacheModeWriteCombined;
        m_Buffer = [m_Device newBufferWithLength:Size options:Options];
        
        if (m_Buffer == nil)
        {
            LOG_ERROR_MESSAGE("Failed to create ring buffer of size ", Size);
        }
        else
        {
            LOG_INFO_MESSAGE("Created ring buffer, size: ", Size / 1024, " KB");
        }
    }
}

MetalRingBuffer::~MetalRingBuffer() noexcept
{
    // ARC handles release automatically
}

id<MTLBuffer> MetalRingBuffer::Allocate(Uint64 Size, Uint64* pOffset) noexcept
{
    if (m_Buffer == nil)
    {
        LOG_ERROR_MESSAGE("Ring buffer is not initialized");
        return nil;
    }
    
    // Align size to 256 bytes
    Uint64 AlignedSize = (Size + 255) & ~255ULL;
    
    // Check if we've reached the end
    if (m_CurrentOffset + AlignedSize > m_TotalSize)
    {
        // Wrap around to the beginning
        m_CurrentOffset = 0;
        
        // Check if we've caught up to the oldest frame
        Uint64 OldestFrameStart = m_FrameStartOffsets[(m_CurrentFrame + 1) % m_FrameLag];
        if (m_CurrentOffset + AlignedSize > OldestFrameStart)
        {
            LOG_ERROR_MESSAGE("Ring buffer overflow: requested ", Size, 
                            " bytes but only ", (OldestFrameStart - m_CurrentOffset), 
                            " bytes available");
            return nil;
        }
    }
    
    *pOffset = m_CurrentOffset;
    m_CurrentOffset += AlignedSize;
    
    return m_Buffer;
}

void MetalRingBuffer::AdvanceFrame() noexcept
{
    // Move to next frame
    m_CurrentFrame = (m_CurrentFrame + 1) % m_FrameLag;
    
    // Record the start offset for this frame
    m_FrameStartOffsets[m_CurrentFrame] = m_CurrentOffset;
}

} // namespace Diligent
