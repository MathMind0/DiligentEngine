/*
 *  Copyright 2019-2023 Diligent Graphics LLC
 *  Copyright 2025 ViBEN Authors
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF ANY PROPRIETARY RIGHTS.
 *
 *  In no event and under no legal theory, whether in tort (including negligence),
 *  contract, or otherwise, unless required by applicable law (such as deliberate
 *  and grossly negligent acts) or agreed to in writing, shall any Contributor be
 *  liable for any damages, including any direct, indirect, special, incidental,
 *  or consequential damages of any character arising as a result of this License or
 *  out of the use or inability to use the software (including but not limited to damages
 *  for loss of goodwill, work stoppage, computer failure or malfunction, or any and
 *  all other commercial damages or losses), even if such Contributor has been advised
 *  of the possibility of such damages.
 */

#pragma once

/// \file
/// Precompiled header for Metal backend

#include <vector>
#include <memory>
#include <unordered_map>
#include <mutex>
#include <atomic>
#include <cstring>
#include <exception>
#include <algorithm>

// Metal frameworks
#include <Metal/Metal.h>
#include <QuartzCore/QuartzCore.h>
#include <Foundation/Foundation.h>

// DiligentEngine headers
#include "GraphicsTypes.h"
#include "PlatformDefinitions.h"
#include "Errors.hpp"
#include "RefCntAutoPtr.hpp"
#include "RenderDeviceBase.hpp"
#include "Cast.hpp"
#include "ShaderBase.hpp"
#include "SPIRVShaderResources.hpp"
#include "ShaderResourceBindingBase.hpp"
#include "PipelineResourceSignatureBase.hpp"
#include "ShaderResourceCacheCommon.hpp"
#include "FixedLinearAllocator.hpp"
