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
/// Declaration of Diligent::FenceMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "FenceBase.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

/// Fence implementation in Metal backend.
class FenceMtlImpl final : public FenceBase<EngineMtlImplTraits>
{
public:
    using TFenceBase = FenceBase<EngineMtlImplTraits>;

    FenceMtlImpl(IReferenceCounters* pRefCounters,
                 RenderDeviceMtlImpl* pDeviceMtl,
                 const FenceDesc&     Desc,
                 bool                 IsDeviceInternal = false);

    ~FenceMtlImpl();

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_FenceMtl, TFenceBase)

    /// Implementation of IFence::GetCompletedValue().
    virtual Uint64 DILIGENT_CALL_TYPE GetCompletedValue() override final;

    /// Implementation of IFence::Signal().
    virtual void DILIGENT_CALL_TYPE Signal(Uint64 Value) override final;

    /// Implementation of IFence::Wait().
    virtual void DILIGENT_CALL_TYPE Wait(Uint64 Value) override final;

    /// Implementation of IFenceMtl::GetMtlSharedEvent().
    virtual id<MTLSharedEvent> DILIGENT_CALL_TYPE GetMtlSharedEvent() const API_AVAILABLE(ios(12), macosx(10.14), tvos(12.0)) override final
    {
        return m_SharedEvent;
    }

private:
    // MTLSharedEvent for GPU-CPU synchronization (requires macOS 10.14+ / iOS 12+)
    id<MTLSharedEvent> m_SharedEvent API_AVAILABLE(ios(12), macosx(10.14), tvos(12.0)) = nil;
};

} // namespace Diligent
