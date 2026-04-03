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
/// Declaration of Diligent::CommandQueueMtlImpl class

#include <mutex>
#include <atomic>

#include "EngineMtlImplTraits.hpp"
#include "ObjectBase.hpp"
#include "CommandQueueMtl.h"

#import <Metal/Metal.h>

namespace Diligent
{

/// Implementation of the Diligent::ICommandQueueMtl interface
class CommandQueueMtlImpl final : public ObjectBase<ICommandQueueMtl>
{
public:
    using TBase = ObjectBase<ICommandQueueMtl>;

    CommandQueueMtlImpl(IReferenceCounters*      pRefCounters,
                        id<MTLDevice>            MtlDevice,
                        const char*              Name);
    
    ~CommandQueueMtlImpl();

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_CommandQueueMtl, TBase)

    /// Implementation of ICommandQueue::GetNextFenceValue().
    virtual Uint64 DILIGENT_CALL_TYPE GetNextFenceValue() const override final
    {
        return m_NextFenceValue.load();
    }

    /// Implementation of ICommandQueue::GetCompletedFenceValue().
    virtual Uint64 DILIGENT_CALL_TYPE GetCompletedFenceValue() override final
    {
        return m_CompletedFenceValue.load();
    }

    /// Implementation of ICommandQueue::WaitForIdle().
    virtual Uint64 DILIGENT_CALL_TYPE WaitForIdle() override final;

    /// Implementation of ICommandQueueMtl::GetMtlCommandQueue().
    virtual id<MTLCommandQueue> DILIGENT_CALL_TYPE GetMtlCommandQueue() const override final
    {
        return m_CommandQueue;
    }

    /// Implementation of ICommandQueueMtl::Submit().
    virtual Uint64 DILIGENT_CALL_TYPE Submit(id<MTLCommandBuffer> mtlCommandBuffer) override final;

    /// Helper method to create a command buffer (not part of interface)
    id<MTLCommandBuffer> CreateCommandBuffer();

private:
    // The Metal command queue
    id<MTLCommandQueue> m_CommandQueue = nil;

    // A value that will be signaled by the command queue next
    std::atomic<Uint64> m_NextFenceValue{1};

    // The last completed fence value
    std::atomic<Uint64> m_CompletedFenceValue{0};

    // Protects access to the command queue
    std::mutex m_QueueMutex;
};

} // namespace Diligent
