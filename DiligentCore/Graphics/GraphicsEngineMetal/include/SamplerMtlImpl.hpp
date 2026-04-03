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
/// Implementation of the Diligent::SamplerMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "SamplerBase.hpp"
#include "SamplerMtl.h"

namespace Diligent
{

/// Implementation of ISamplerMtl interface
class SamplerMtlImpl final : public SamplerBase<EngineMtlImplTraits>
{
public:
    using TSamplerBase = SamplerBase<EngineMtlImplTraits>;

    SamplerMtlImpl(IReferenceCounters*  pRefCounters,
                   RenderDeviceMtlImpl* pDevice,
                   const SamplerDesc&   Desc);
    ~SamplerMtlImpl();

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_SamplerMtl, TSamplerBase)

    /// Implementation of ISamplerMtl::GetMtlSampler()
    virtual id<MTLSamplerState> DILIGENT_CALL_TYPE GetMtlSampler() override
    {
        return m_mtlSamplerState;
    }

private:
    id<MTLSamplerState> m_mtlSamplerState = nil;
};

} // namespace Diligent
