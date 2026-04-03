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

#pragma once

/// \file
/// Declaration of Diligent::RasterizationRateMapMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "RasterizationRateMapMtl.h"
#include "DeviceObjectBase.hpp"
#include "RenderDeviceMtlImpl.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

/// Implementation of IRasterizationRateMapMtl for Metal rasterization rate maps.
class RasterizationRateMapMtlImpl final : public DeviceObjectBase<IRasterizationRateMapMtl, RenderDeviceMtlImpl, RasterizationRateMapDesc>
{
public:
    using TRasterizationRateMapBase = DeviceObjectBase<IRasterizationRateMapMtl, RenderDeviceMtlImpl, RasterizationRateMapDesc>;

    RasterizationRateMapMtlImpl(IReferenceCounters*                  pRefCounters,
                                RenderDeviceMtlImpl*                 pDevice,
                                const RasterizationRateMapCreateInfo& CreateInfo);

    RasterizationRateMapMtlImpl(IReferenceCounters*       pRefCounters,
                                RenderDeviceMtlImpl*      pDevice,
                                const RasterizationRateMapDesc& Desc,
                                id<MTLRasterizationRateMap> mtlRRM);

    ~RasterizationRateMapMtlImpl();

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_RasterizationRateMapMtl, TRasterizationRateMapBase)

    /// Implementation of IRasterizationRateMapMtl::GetMtlResource()
    virtual id<MTLRasterizationRateMap> DILIGENT_CALL_TYPE GetMtlResource() const override final
    {
        return m_mtlRRM;
    }

    /// Implementation of IRasterizationRateMapMtl::GetPhysicalSizeForLayer()
    virtual void DILIGENT_CALL_TYPE GetPhysicalSizeForLayer(Uint32    LayerIndex,
                                                            Uint32&   PhysicalWidth,
                                                            Uint32&   PhysicalHeight) const override final;

    /// Implementation of IRasterizationRateMapMtl::GetPhysicalGranularity()
    virtual void DILIGENT_CALL_TYPE GetPhysicalGranularity(Uint32& XGranularity,
                                                           Uint32& YGranularity) const override final;

    /// Implementation of IRasterizationRateMapMtl::MapScreenToPhysicalCoordinates()
    virtual void DILIGENT_CALL_TYPE MapScreenToPhysicalCoordinates(Uint32  LayerIndex,
                                                                   float   ScreenCoordX,
                                                                   float   ScreenCoordY,
                                                                   float&  PhysicalCoordX,
                                                                   float&  PhysicalCoordY) const override final;

    /// Implementation of IRasterizationRateMapMtl::MapPhysicalToScreenCoordinates()
    virtual void DILIGENT_CALL_TYPE MapPhysicalToScreenCoordinates(Uint32  LayerIndex,
                                                                   float   PhysicalCoordX,
                                                                   float   PhysicalCoordY,
                                                                   float&  ScreenCoordX,
                                                                   float&  ScreenCoordY) const override final;

    /// Implementation of IRasterizationRateMapMtl::GetParameterBufferSizeAndAlign()
    virtual void DILIGENT_CALL_TYPE GetParameterBufferSizeAndAlign(Uint64& Size,
                                                                   Uint32& Align) const override final;

    /// Implementation of IRasterizationRateMapMtl::CopyParameterDataToBuffer()
    virtual void DILIGENT_CALL_TYPE CopyParameterDataToBuffer(IBuffer* pDstBuffer,
                                                              Uint64   Offset) const override final;

    /// Implementation of IRasterizationRateMapMtl::GetView()
    virtual ITextureView* DILIGENT_CALL_TYPE GetView() override final;

private:
    /// The Metal rasterization rate map object
    id<MTLRasterizationRateMap> m_mtlRRM API_AVAILABLE(ios(13), macosx(10.15.4)) API_UNAVAILABLE(tvos);
    
    /// Texture view for framebuffer attachment
    RefCntAutoPtr<ITextureView> m_pView;
};

} // namespace Diligent
