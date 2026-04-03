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
#include "FenceMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"

#import <Foundation/Foundation.h>

namespace Diligent
{

FenceMtlImpl::FenceMtlImpl(IReferenceCounters* pRefCounters,
                           RenderDeviceMtlImpl* pDeviceMtl,
                           const FenceDesc&     Desc,
                           bool                 IsDeviceInternal) :
    TFenceBase{pRefCounters, pDeviceMtl, Desc, IsDeviceInternal}
{
    auto* pDevice = GetDevice();
    id<MTLDevice> mtlDevice = pDevice->GetMtlDevice();

    @autoreleasepool
    {
        if (@available(macOS 10.14, iOS 12.0, tvOS 12.0, *))
        {
            // Create MTLSharedEvent for GPU-CPU synchronization
            m_SharedEvent = [mtlDevice newSharedEvent];
            if (m_SharedEvent == nil)
            {
                LOG_ERROR_AND_THROW("Failed to create Metal shared event for fence '", Desc.Name, "'");
            }

            // Set initial signaled value
            m_SharedEvent.signaledValue = 0;
        }
        else
        {
            LOG_ERROR_AND_THROW("MTLSharedEvent is not supported on this platform. ",
                               "Metal fence requires macOS 10.14+ / iOS 12.0+ / tvOS 12.0+");
        }
    }
}

FenceMtlImpl::~FenceMtlImpl()
{
    // Metal objects are reference-counted and will be released automatically
}

Uint64 FenceMtlImpl::GetCompletedValue()
{
    if (@available(macOS 10.14, iOS 12.0, tvOS 12.0, *))
    {
        if (m_SharedEvent != nil)
        {
            return m_SharedEvent.signaledValue;
        }
    }
    return 0;
}

void FenceMtlImpl::Signal(Uint64 Value)
{
    if (@available(macOS 10.14, iOS 12.0, tvOS 12.0, *))
    {
        if (m_SharedEvent != nil)
        {
            // CPU signal - set the signaled value directly
            m_SharedEvent.signaledValue = Value;
        }
    }
}

void FenceMtlImpl::Wait(Uint64 Value)
{
    if (@available(macOS 10.14, iOS 12.0, tvOS 12.0, *))
    {
        if (m_SharedEvent == nil)
            return;

        // Use notification listener for efficient waiting
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

        [m_SharedEvent notifyListener:nil
                              atValue:Value
                                block:^(id<MTLSharedEvent> _Nonnull, Uint64 value) {
                                    dispatch_semaphore_signal(semaphore);
                                }];

        // Wait indefinitely for the fence to be signaled
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
}

} // namespace Diligent
