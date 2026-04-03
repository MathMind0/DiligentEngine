/*
 *  Copyright 2019-2026 Diligent Graphics LLC
 *  Copyright 2026 ViBEN Contributors
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

// Stub implementation for RasterizationRateMapMtlImpl
// This file provides minimal implementations to allow compilation when the full
// implementation is disabled due to Metal API compatibility issues.

#include "RasterizationRateMapMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"

namespace Diligent
{

RasterizationRateMapMtlImpl::RasterizationRateMapMtlImpl(IReferenceCounters*                   pRefCounters,
                                                         RenderDeviceMtlImpl*                  pDevice,
                                                         const RasterizationRateMapCreateInfo& CreateInfo)
    : DeviceObjectBase<IRasterizationRateMapMtl, RenderDeviceMtlImpl, RasterizationRateMapDesc>{pRefCounters, pDevice, CreateInfo.Desc}
{
    LOG_WARNING_MESSAGE("RasterizationRateMapMtlImpl: Variable Rate Shading is not available in this build");
}

RasterizationRateMapMtlImpl::RasterizationRateMapMtlImpl(IReferenceCounters*       pRefCounters,
                                                         RenderDeviceMtlImpl*      pDevice,
                                                         const RasterizationRateMapDesc& Desc,
                                                         id<MTLRasterizationRateMap> mtlRRM)
    : DeviceObjectBase<IRasterizationRateMapMtl, RenderDeviceMtlImpl, RasterizationRateMapDesc>{pRefCounters, pDevice, Desc}
{
    LOG_WARNING_MESSAGE("RasterizationRateMapMtlImpl: Variable Rate Shading is not available in this build");
}

RasterizationRateMapMtlImpl::~RasterizationRateMapMtlImpl()
{
}

void RasterizationRateMapMtlImpl::GetPhysicalSizeForLayer(Uint32  LayerIndex,
                                                          Uint32& X,
                                                          Uint32& Y) const
{
    X = 0;
    Y = 0;
    LOG_WARNING_MESSAGE("RasterizationRateMapMtlImpl::GetPhysicalSizeForLayer: Not implemented");
}

void RasterizationRateMapMtlImpl::GetPhysicalGranularity(Uint32& XGranularity,
                                                         Uint32& YGranularity) const
{
    XGranularity = 0;
    YGranularity = 0;
    LOG_WARNING_MESSAGE("RasterizationRateMapMtlImpl::GetPhysicalGranularity: Not implemented");
}

void RasterizationRateMapMtlImpl::MapScreenToPhysicalCoordinates(Uint32  LayerIndex,
                                                                 float   ScreenX,
                                                                 float   ScreenY,
                                                                 float&  PhysicalX,
                                                                 float&  PhysicalY) const
{
    PhysicalX = ScreenX;
    PhysicalY = ScreenY;
    LOG_WARNING_MESSAGE("RasterizationRateMapMtlImpl::MapScreenToPhysicalCoordinates: Not implemented");
}

void RasterizationRateMapMtlImpl::MapPhysicalToScreenCoordinates(Uint32  LayerIndex,
                                                                 float   PhysicalX,
                                                                 float   PhysicalY,
                                                                 float&  ScreenX,
                                                                 float&  ScreenY) const
{
    ScreenX = PhysicalX;
    ScreenY = PhysicalY;
    LOG_WARNING_MESSAGE("RasterizationRateMapMtlImpl::MapPhysicalToScreenCoordinates: Not implemented");
}

void RasterizationRateMapMtlImpl::GetParameterBufferSizeAndAlign(Uint64& Size,
                                                                 Uint32& Align) const
{
    Size  = 0;
    Align = 1;
    LOG_WARNING_MESSAGE("RasterizationRateMapMtlImpl::GetParameterBufferSizeAndAlign: Not implemented");
}

void RasterizationRateMapMtlImpl::CopyParameterDataToBuffer(IBuffer* pDstBuffer,
                                                            Uint64   Offset) const
{
    LOG_WARNING_MESSAGE("RasterizationRateMapMtlImpl::CopyParameterDataToBuffer: Not implemented");
}

ITextureView* RasterizationRateMapMtlImpl::GetView()
{
    LOG_WARNING_MESSAGE("RasterizationRateMapMtlImpl::GetView() is not implemented");
    return nullptr;
}

} // namespace Diligent
