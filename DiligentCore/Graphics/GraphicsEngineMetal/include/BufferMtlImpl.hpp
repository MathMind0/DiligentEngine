/*
 *  Copyright 2019-2023 Diligent Graphics LLC
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *      http://www.apache.org/licenses/LICENSE-2.0
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
/// Implementation of the Diligent::BufferMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "BufferBase.hpp"
#include "BufferMtl.h"

namespace Diligent
{

/// Implementation of IBufferMtl interface
class BufferMtlImpl final : public BufferBase<EngineMtlImplTraits>
{
public:
    using TBufferBase = BufferBase<EngineMtlImplTraits>;

    BufferMtlImpl(IReferenceCounters*        pRefCounters,
                  FixedBlockMemoryAllocator& BuffViewObjMemAllocator,
                  RenderDeviceMtlImpl*       pDevice,
                  const BufferDesc&          BuffDesc,
                  const BufferData*          pBufferData = nullptr);

    ~BufferMtlImpl();

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_BufferMtl, TBufferBase)

    /// Implementation of IBufferMtl::GetMtlResource()
    virtual id<MTLBuffer> DILIGENT_CALL_TYPE GetMtlResource() const override
    {
        return m_mtlBuffer;
    }

    /// Implementation of IBuffer::GetNativeHandle()
    virtual Uint64 DILIGENT_CALL_TYPE GetNativeHandle() override
    {
        return reinterpret_cast<Uint64>(m_mtlBuffer);
    }

protected:
    /// Implementation of BufferBase::CreateViewInternal
    virtual void CreateViewInternal(const BufferViewDesc& ViewDesc,
                                    IBufferView**         ppView,
                                    bool                  bIsDefaultView) override;

private:
    id<MTLBuffer> m_mtlBuffer = nil;
};

} // namespace Diligent
