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
#include "BufferViewMtlImpl.hpp"
#include "BufferMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"

namespace Diligent
{

BufferViewMtlImpl::BufferViewMtlImpl(IReferenceCounters*   pRefCounters,
                                     RenderDeviceMtlImpl*  pDevice,
                                     const BufferViewDesc& ViewDesc,
                                     IBuffer*              pBuffer,
                                     bool                  bIsDefaultView) :
    TBufferViewBase{pRefCounters, pDevice, ViewDesc, pBuffer, bIsDefaultView}
{
}

BufferViewMtlImpl::~BufferViewMtlImpl()
{
}

} // namespace Diligent