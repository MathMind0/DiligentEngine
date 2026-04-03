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
/// Implementation of TopLevelASMtlImpl for Metal ray tracing

#include "EngineMtlImplTraits.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "BottomLevelASMtlImpl.hpp"
#include "../../GraphicsEngine/include/TopLevelASBase.hpp"
#include "../interface/TopLevelASMtl.h"

#import <Metal/Metal.h>

namespace Diligent
{

/// Implementation of ITopLevelAS for Metal backend.
///
/// Metal ray tracing uses MTLAccelerationStructure for top-level acceleration structures.
/// This class wraps Metal's acceleration structure API to provide Diligent-compatible
/// ray tracing functionality.
class TopLevelASMtlImpl final : public TopLevelASBase<EngineMtlImplTraits>
{
public:
    using TTopLevelASBase = TopLevelASBase<EngineMtlImplTraits>;

    TopLevelASMtlImpl(IReferenceCounters*     pRefCounters,
                      RenderDeviceMtlImpl*    pDevice,
                      const TopLevelASDesc&   Desc);

    /// Creates a TLAS from an existing Metal acceleration structure resource.
    TopLevelASMtlImpl(IReferenceCounters*         pRefCounters,
                      RenderDeviceMtlImpl*        pDevice,
                      const TopLevelASDesc&       Desc,
                      RESOURCE_STATE              InitialState,
                      id<MTLAccelerationStructure> mtlTLAS) API_AVAILABLE(ios(14), macosx(11.0));

    ~TopLevelASMtlImpl() override;

    /// Implementation of ITopLevelASMtl::GetMtlAccelerationStructure()
    virtual id<MTLAccelerationStructure> DILIGENT_CALL_TYPE GetMtlAccelerationStructure() const override
    {
        return m_mtlAccelerationStructure;
    }

    /// Implementation of ITopLevelAS::GetNativeHandle()
    virtual Uint64 DILIGENT_CALL_TYPE GetNativeHandle() override
    {
        return reinterpret_cast<Uint64>(m_mtlAccelerationStructure);
    }

    /// Returns the Metal buffer used for acceleration structure storage.
    id<MTLBuffer> GetMtlBuffer() const { return m_mtlBuffer; }

    /// Returns the scratch buffer size required for building.
    Uint64 GetScratchBufferSize() const { return m_ScratchSize.Build; }

    /// Returns the scratch buffer size required for refitting (updating).
    Uint64 GetRefitScratchBufferSize() const { return m_ScratchSize.Update; }

private:
    /// Scratch buffer sizes
    struct
    {
        Uint64 Build  = 0;
        Uint64 Update = 0;
    } m_ScratchSize;

    /// The Metal acceleration structure object
    id<MTLAccelerationStructure> m_mtlAccelerationStructure API_AVAILABLE(ios(14), macosx(11.0)) = nil;

    /// The Metal buffer that backs the acceleration structure storage
    id<MTLBuffer> m_mtlBuffer = nil;
};

} // namespace Diligent
