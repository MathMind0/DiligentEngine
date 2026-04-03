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

#include "MetalCommandBuffer.h"

#import <Metal/Metal.h>

namespace Diligent
{

// MetalCommandBufferPool implementation
MetalCommandBufferPool::MetalCommandBufferPool(id<MTLCommandQueue> Queue) noexcept
    : m_Queue(Queue)
{
    // ARC handles retention automatically
}

MetalCommandBufferPool::~MetalCommandBufferPool() noexcept
{
    // ARC handles release automatically
}

id<MTLCommandBuffer> MetalCommandBufferPool::GetCommandBuffer() noexcept
{
    @autoreleasepool
    {
        id<MTLCommandBuffer> CommandBuffer = [m_Queue commandBuffer];
        
        if (CommandBuffer == nil)
        {
            LOG_ERROR_MESSAGE("Failed to create Metal command buffer");
            return nil;
        }
        
        // Set debug label
        CommandBuffer.label = @"DiligentEngine Command Buffer";
        
        return CommandBuffer;
    }
}

void MetalCommandBufferPool::ReturnCommandBuffer(id<MTLCommandBuffer> CommandBuffer) noexcept
{
    // In Metal, command buffers are automatically released after completion
    // No need to manually return them to a pool
    // Just ensure they're committed
    if (CommandBuffer != nil && CommandBuffer.status != MTLCommandBufferStatusCommitted)
    {
        [CommandBuffer commit];
    }
}

// MetalEncoderState implementation
void MetalEncoderState::BeginRenderEncoder(id<MTLCommandBuffer> CommandBuffer,
                                          id<MTLRenderCommandEncoder> RenderEncoder) noexcept
{
    // End any currently active encoder
    EndCurrentEncoder();
    
    // Set the new encoder
    m_ActiveEncoderType = EncoderType::Render;
    m_ActiveCommandBuffer = CommandBuffer;
    m_ActiveRenderEncoder = RenderEncoder;
}

void MetalEncoderState::BeginComputeEncoder(id<MTLCommandBuffer> CommandBuffer,
                                           id<MTLComputeCommandEncoder> ComputeEncoder) noexcept
{
    // End any currently active encoder
    EndCurrentEncoder();
    
    // Set the new encoder
    m_ActiveEncoderType = EncoderType::Compute;
    m_ActiveCommandBuffer = CommandBuffer;
    m_ActiveComputeEncoder = ComputeEncoder;
}

void MetalEncoderState::BeginBlitEncoder(id<MTLCommandBuffer> CommandBuffer,
                                        id<MTLBlitCommandEncoder> BlitEncoder) noexcept
{
    // End any currently active encoder
    EndCurrentEncoder();
    
    // Set the new encoder
    m_ActiveEncoderType = EncoderType::Blit;
    m_ActiveCommandBuffer = CommandBuffer;
    m_ActiveBlitEncoder = BlitEncoder;
}

void MetalEncoderState::EndCurrentEncoder() noexcept
{
    switch (m_ActiveEncoderType)
    {
        case EncoderType::Render:
            if (m_ActiveRenderEncoder != nil)
            {
                [m_ActiveRenderEncoder endEncoding];
                m_ActiveRenderEncoder = nil;
            }
            break;
            
        case EncoderType::Compute:
            if (m_ActiveComputeEncoder != nil)
            {
                [m_ActiveComputeEncoder endEncoding];
                m_ActiveComputeEncoder = nil;
            }
            break;
            
        case EncoderType::Blit:
            if (m_ActiveBlitEncoder != nil)
            {
                [m_ActiveBlitEncoder endEncoding];
                m_ActiveBlitEncoder = nil;
            }
            break;
            
        case EncoderType::None:
        default:
            // No active encoder
            break;
    }
    
    m_ActiveEncoderType = EncoderType::None;
    m_ActiveCommandBuffer = nil;
}

// MetalCompletionHandlerManager implementation
void MetalCompletionHandlerManager::AddCompletionHandler(id<MTLCommandBuffer> CommandBuffer,
                                                        void (^Handler)(id<MTLCommandBuffer>)) noexcept
{
    if (CommandBuffer == nil || Handler == nil)
        return;
    
    @autoreleasepool
    {
        [CommandBuffer addCompletedHandler:Handler];
        m_PendingCompletions.push_back(CommandBuffer); // ARC handles retention
    }
}

void MetalCompletionHandlerManager::WaitForCompletions() noexcept
{
    @autoreleasepool
    {
        for (id<MTLCommandBuffer> CommandBuffer : m_PendingCompletions)
        {
            [CommandBuffer waitUntilCompleted];
            // ARC handles release automatically
        }
        m_PendingCompletions.clear();
    }
}

} // namespace Diligent
