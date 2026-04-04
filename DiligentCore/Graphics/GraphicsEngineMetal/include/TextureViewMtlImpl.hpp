/*
 *  Copyright 2019-2026 Diligent Graphics LLC
 *  Copyright 2025 ViBEN Authors
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
/// Implementation of TextureViewMtlImpl

#include "EngineMtlImplTraits.hpp"
#include "../../GraphicsEngine/include/TextureViewBase.hpp"
#include "../interface/TextureViewMtl.h"

namespace Diligent
{

class TextureViewMtlImpl final : public TextureViewBase<EngineMtlImplTraits>
{
public:
    using TTextureViewBase = TextureViewBase<EngineMtlImplTraits>;

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_TextureViewMtl, TTextureViewBase)

    TextureViewMtlImpl(IReferenceCounters*                 pRefCounters,
                       RenderDeviceMtlImpl*                pDevice,
                       const TextureViewDesc&              ViewDesc,
                       ITexture*                           pTexture,
                       bool                                bIsDefaultView);

    ~TextureViewMtlImpl() override;

    /// Implementation of ITextureViewMtl::GetMtlTexture()
    virtual id<MTLTexture> DILIGENT_CALL_TYPE GetMtlTexture() const override;
};

} // namespace Diligent
