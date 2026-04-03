/*
 *  Copyright 2019-2026 Diligent Graphics LLC
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

#pragma once

/// \file
/// Implementation of DeviceMemoryMtlImpl for Metal sparse memory

#include "EngineMtlImplTraits.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "../../GraphicsEngine/include/DeviceMemoryBase.hpp"
#include "../interface/DeviceMemoryMtl.h"

#import <Metal/Metal.h>

namespace Diligent
{

class DeviceMemoryMtlImpl final : public DeviceMemoryBase<EngineMtlImplTraits>
{
public:
    using TDeviceMemoryBase = DeviceMemoryBase<EngineMtlImplTraits>;

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_DeviceMemoryMtl, TDeviceMemoryBase)

    DeviceMemoryMtlImpl(IReferenceCounters*        pRefCounters,
                        FixedBlockMemoryAllocator& MemAllocator,
                        RenderDeviceMtlImpl*       pDevice,
                        const DeviceMemoryDesc&    Desc);

    ~DeviceMemoryMtlImpl() override;

    /// Implementation of IDeviceMemoryMtl::GetMtlResource()
    virtual id<MTLHeap> DILIGENT_CALL_TYPE GetMtlResource() const override;

    /// Implementation of IDeviceMemory::Resize()
    virtual Bool DILIGENT_CALL_TYPE Resize(Uint64 NewSize) override;

    /// Implementation of IDeviceMemory::GetCapacity()
    virtual Uint64 DILIGENT_CALL_TYPE GetCapacity() const override;

    /// Implementation of IDeviceMemory::IsCompatible()
    virtual Bool DILIGENT_CALL_TYPE IsCompatible(IDeviceObject* pResource) const override;

private:
    /// The Metal heap object backing sparse memory
    id<MTLHeap> m_mtlHeap = nil;
    
    /// Current capacity of the heap
    Uint64 m_Capacity = 0;
};

} // namespace Diligent
