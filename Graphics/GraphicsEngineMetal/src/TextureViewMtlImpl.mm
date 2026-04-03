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

/// \file
/// Implementation of TextureViewMtlImpl

#include "pch.h"
#include "TextureViewMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "TextureMtlImpl.hpp"

namespace Diligent
{

TextureViewMtlImpl::TextureViewMtlImpl(IReferenceCounters*        pRefCounters,
                                       RenderDeviceMtlImpl*       pDevice,
                                       const TextureViewDesc&     ViewDesc,
                                       ITexture*                  pTexture,
                                       bool                       bIsDefaultView) :
    TTextureViewBase{pRefCounters, pDevice, ViewDesc, pTexture, bIsDefaultView}
{
    LOG_INFO_MESSAGE("Created Metal texture view '", (ViewDesc.Name ? ViewDesc.Name : "<unnamed>"), "'");
}

TextureViewMtlImpl::~TextureViewMtlImpl()
{
    LOG_INFO_MESSAGE("Destroyed Metal texture view '", (m_Desc.Name ? m_Desc.Name : "<unnamed>"), "'");
}

id<MTLTexture> TextureViewMtlImpl::GetMtlTexture() const
{
    if (m_pTexture)
    {
        TextureMtlImpl* pTexMtl = static_cast<TextureMtlImpl*>(m_pTexture);
        return pTexMtl->GetMtlTexture();
    }
    return nil;
}

} // namespace Diligent
