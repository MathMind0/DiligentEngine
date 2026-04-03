/*
 *  Copyright 2019-2026 Diligent Graphics LLC
 *  Copyright 2015-2019 Egor Yusov
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
/// Metal debug utilities

#import <Metal/Metal.h>

namespace Diligent
{

/// Sets a debug label for a Metal resource
/// \param [in] Resource - The Metal resource to label
/// \param [in] Name - The debug label to set
void SetMtlObjectLabel(id<MTLResource> Resource, const char* Name) noexcept;

/// Logs a Metal error with context information
/// \param [in] Error - The NSError object from Metal
/// \param [in] Context - A string describing the context where the error occurred
void LogMtlError(NSError* Error, const char* Context) noexcept;

/// Validates that a Metal device supports the minimum required feature set
/// \param [in] Device - The Metal device to validate
/// \return True if the device meets minimum requirements, false otherwise
bool ValidateMtlFeatureSet(id<MTLDevice> Device) noexcept;

/// Checks if Metal validation is enabled
/// \return True if validation is enabled, false otherwise
bool IsMtlValidationEnabled() noexcept;

} // namespace Diligent