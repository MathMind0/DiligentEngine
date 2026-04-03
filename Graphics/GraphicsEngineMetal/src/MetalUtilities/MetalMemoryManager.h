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

#pragma once

/// \file
/// Metal memory management utilities

#import <Metal/Metal.h>

#include <vector>
#include <mutex>
#include <array>

#include "GraphicsTypes.h"

namespace Diligent
{

/// Pool for managing staging buffers for CPU-to-GPU data transfers
class MetalStagingBufferPool
{
public:
    explicit MetalStagingBufferPool(id<MTLDevice> Device, Uint64 BufferSize) noexcept;
    ~MetalStagingBufferPool() noexcept;

    MetalStagingBufferPool(const MetalStagingBufferPool&) = delete;
    MetalStagingBufferPool& operator=(const MetalStagingBufferPool&) = delete;

    /// Allocates memory from the staging buffer pool
    /// \param [in] Size - The size to allocate
    /// \param [out] pOffset - Pointer to receive the offset within the buffer
    /// \return The Metal buffer containing the allocated memory
    id<MTLBuffer> Allocate(Uint64 Size, Uint64* pOffset) noexcept;

    /// Resets the pool, allowing memory to be reused
    void Reset() noexcept;

private:
    id<MTLDevice> m_Device = nil;
    Uint64 m_BufferSize = 0;
    Uint64 m_CurrentOffset = 0;
    std::vector<id<MTLBuffer>> m_Buffers;
    size_t m_CurrentBufferIndex = 0;
};

/// Ring buffer for managing GPU-visible memory with frame-based allocation
class MetalRingBuffer
{
public:
    explicit MetalRingBuffer(id<MTLDevice> Device, Uint64 Size) noexcept;
    ~MetalRingBuffer() noexcept;

    MetalRingBuffer(const MetalRingBuffer&) = delete;
    MetalRingBuffer& operator=(const MetalRingBuffer&) = delete;

    /// Allocates memory from the ring buffer
    /// \param [in] Size - The size to allocate
    /// \param [out] pOffset - Pointer to receive the offset within the buffer
    /// \return The Metal buffer containing the allocated memory, or nil if out of memory
    id<MTLBuffer> Allocate(Uint64 Size, Uint64* pOffset) noexcept;

    /// Advances to the next frame, freeing memory from completed frames
    void AdvanceFrame() noexcept;

    /// Gets the total size of the ring buffer
    Uint64 GetSize() const noexcept { return m_TotalSize; }

    /// Gets the Metal buffer
    id<MTLBuffer> GetBuffer() const noexcept { return m_Buffer; }

private:
    id<MTLDevice> m_Device = nil;
    id<MTLBuffer> m_Buffer = nil;
    Uint64 m_TotalSize = 0;
    Uint64 m_CurrentOffset = 0;
    
    // Frame-based management
    static constexpr Uint32 m_FrameLag = 3;
    Uint32 m_CurrentFrame = 0;
    std::array<Uint64, m_FrameLag> m_FrameStartOffsets = {};
    
    std::mutex m_Mutex;
};

} // namespace Diligent