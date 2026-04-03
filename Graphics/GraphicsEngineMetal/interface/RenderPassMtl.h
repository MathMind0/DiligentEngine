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
/// Definition of the Diligent::IRenderPassMtl interface

#include "../../GraphicsEngine/interface/RenderPass.h"

DILIGENT_BEGIN_NAMESPACE(Diligent)

// {B2C3D4E5-F6A7-8901-BCDE-F12345678901}
static DILIGENT_CONSTEXPR INTERFACE_ID IID_RenderPassMtl =
    {0xb2c3d4e5, 0xf6a7, 0x8901, {0xbc, 0xde, 0xf1, 0x23, 0x45, 0x67, 0x89, 0x01}};

#define DILIGENT_INTERFACE_NAME IRenderPassMtl
#include "../../../Primitives/interface/DefineInterfaceHelperMacros.h"

#define IRenderPassMtlInclusiveMethods \
    IRenderPassInclusiveMethods

// {IRenderPassMtl}
DILIGENT_BEGIN_INTERFACE(IRenderPassMtl, IRenderPass)
{
    // No Metal-specific methods
};
DILIGENT_END_INTERFACE

#include "../../../Primitives/interface/UndefInterfaceHelperMacros.h"

DILIGENT_END_NAMESPACE // namespace Diligent
