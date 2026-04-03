/*
 *  Copyright 2019-2026 Diligent Graphics LLC
 *  Copyright 2025 ViBEN Authors
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

/// \file
/// Implementation of the Diligent::CommandQueueMtlImpl class

#include "pch.h"
#include "CommandQueueMtlImpl.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

CommandQueueMtlImpl::CommandQueueMtlImpl(IReferenceCounters* pRefCounters,
                                         id<MTLDevice>       MtlDevice,
                                         const char*         Name) :
    TBase{pRefCounters}
{
    m_CommandQueue = [MtlDevice newCommandQueue];
    if (m_CommandQueue == nil)
    {
        LOG_ERROR_AND_THROW("Failed to create Metal command queue");
    }
    
    if (Name != nullptr)
    {
        m_CommandQueue.label = [NSString stringWithUTF8String:Name];
    }
    
    LOG_INFO_MESSAGE("Created Metal command queue '", (Name ? Name : "<unnamed>"), "'");
}

CommandQueueMtlImpl::~CommandQueueMtlImpl()
{
    LOG_INFO_MESSAGE("Destroying Metal command queue");
}

Uint64 CommandQueueMtlImpl::WaitForIdle()
{
    // Metal doesn't have a direct equivalent to Vulkan's waitIdle
    // We need to submit a dummy command buffer and wait for it to complete
    @autoreleasepool
    {
        id<MTLCommandBuffer> commandBuffer = [m_CommandQueue commandBuffer];
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
        
        Uint64 completedValue = m_NextFenceValue.fetch_add(1);
        m_CompletedFenceValue.store(completedValue);
        return completedValue;
    }
}

Uint64 CommandQueueMtlImpl::Submit(id<MTLCommandBuffer> mtlCommandBuffer)
{
    std::lock_guard<std::mutex> lock(m_QueueMutex);
    
    Uint64 fenceValue = m_NextFenceValue.fetch_add(1);
    
    // Add completion handler to update completed fence value
    [mtlCommandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        m_CompletedFenceValue.store(fenceValue);
    }];
    
    [mtlCommandBuffer commit];
    
    return fenceValue;
}

id<MTLCommandBuffer> CommandQueueMtlImpl::CreateCommandBuffer()
{
    std::lock_guard<std::mutex> lock(m_QueueMutex);
    return [m_CommandQueue commandBuffer];
}

} // namespace Diligent