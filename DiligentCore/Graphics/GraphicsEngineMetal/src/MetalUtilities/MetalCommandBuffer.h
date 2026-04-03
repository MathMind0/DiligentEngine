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
/// Metal command buffer utilities

#import <Metal/Metal.h>

#include <mutex>
#include <vector>
#include <functional>

namespace Diligent
{

/// Pool for managing Metal command buffers
class MetalCommandBufferPool
{
public:
    explicit MetalCommandBufferPool(id<MTLCommandQueue> Queue) noexcept;
    ~MetalCommandBufferPool() noexcept;

    MetalCommandBufferPool(const MetalCommandBufferPool&) = delete;
    MetalCommandBufferPool& operator=(const MetalCommandBufferPool&) = delete;

    id<MTLCommandBuffer> GetCommandBuffer() noexcept;
    void ReturnCommandBuffer(id<MTLCommandBuffer> CommandBuffer) noexcept;

private:
    id<MTLCommandQueue> m_Queue = nil;
};

/// Manages Metal encoder state (render, compute, blit)
class MetalEncoderState
{
public:
    enum class EncoderType
    {
        None,
        Render,
        Compute,
        Blit
    };

    MetalEncoderState() noexcept = default;
    ~MetalEncoderState() noexcept = default;

    MetalEncoderState(const MetalEncoderState&) = delete;
    MetalEncoderState& operator=(const MetalEncoderState&) = delete;

    void BeginRenderEncoder(id<MTLCommandBuffer> CommandBuffer, id<MTLRenderCommandEncoder> RenderEncoder) noexcept;
    void BeginComputeEncoder(id<MTLCommandBuffer> CommandBuffer, id<MTLComputeCommandEncoder> ComputeEncoder) noexcept;
    void BeginBlitEncoder(id<MTLCommandBuffer> CommandBuffer, id<MTLBlitCommandEncoder> BlitEncoder) noexcept;
    void EndCurrentEncoder() noexcept;

    id<MTLRenderCommandEncoder> GetRenderEncoder() const noexcept { return m_RenderEncoder; }
    id<MTLComputeCommandEncoder> GetComputeEncoder() const noexcept { return m_ComputeEncoder; }
    id<MTLBlitCommandEncoder> GetBlitEncoder() const noexcept { return m_BlitEncoder; }

private:
    id<MTLCommandBuffer> m_ActiveCommandBuffer = nil;
    EncoderType m_ActiveEncoderType = EncoderType::None;
    id<MTLRenderCommandEncoder> m_ActiveRenderEncoder = nil;
    id<MTLComputeCommandEncoder> m_ActiveComputeEncoder = nil;
    id<MTLBlitCommandEncoder> m_ActiveBlitEncoder = nil;
    
    // Legacy members for compatibility
    id<MTLRenderCommandEncoder> m_RenderEncoder = nil;
    id<MTLComputeCommandEncoder> m_ComputeEncoder = nil;
    id<MTLBlitCommandEncoder> m_BlitEncoder = nil;
};

/// Manages completion handlers for Metal command buffers
class MetalCompletionHandlerManager
{
public:
    using CompletionHandler = void (^)(id<MTLCommandBuffer>);

    MetalCompletionHandlerManager() noexcept = default;
    ~MetalCompletionHandlerManager() noexcept = default;

    MetalCompletionHandlerManager(const MetalCompletionHandlerManager&) = delete;
    MetalCompletionHandlerManager& operator=(const MetalCompletionHandlerManager&) = delete;

    void AddCompletionHandler(id<MTLCommandBuffer> CommandBuffer,
                              void (^Handler)(id<MTLCommandBuffer>)) noexcept;
    void WaitForCompletions() noexcept;

private:
    std::mutex m_Mutex;
    std::vector<id<MTLCommandBuffer>> m_PendingCompletions;
};

} // namespace Diligent