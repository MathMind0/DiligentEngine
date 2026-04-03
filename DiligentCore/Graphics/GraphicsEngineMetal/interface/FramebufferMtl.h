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
/// Definition of the Diligent::IFramebufferMtl interface

#include "../../GraphicsEngine/interface/Framebuffer.h"

// Forward declarations for Metal protocols (for pure C/C++ compilation)
@protocol MTLTexture;

DILIGENT_BEGIN_NAMESPACE(Diligent)

// {A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
static DILIGENT_CONSTEXPR INTERFACE_ID IID_FramebufferMtl =
    {0xa1b2c3d4, 0xe5f6, 0x7890, {0xab, 0xcd, 0xef, 0x12, 0x34, 0x56, 0x78, 0x90}};

#define DILIGENT_INTERFACE_NAME IFramebufferMtl
#include "../../../Primitives/interface/DefineInterfaceHelperMacros.h"

#define IFramebufferMtlInclusiveMethods \
    IFramebufferInclusiveMethods

// {IFramebufferMtl}
DILIGENT_BEGIN_INTERFACE(IFramebufferMtl, IFramebuffer)
{
    /// Returns a pointer to the Metal texture.
    VIRTUAL id<MTLTexture> METHOD(GetMtlFramebuffer)(THIS) CONST PURE;
};
DILIGENT_END_INTERFACE

#include "../../../Primitives/interface/UndefInterfaceHelperMacros.h"

DILIGENT_END_NAMESPACE // namespace Diligent
