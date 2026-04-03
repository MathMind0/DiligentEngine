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

#include "pch.h"

#include "MetalDebug.h"

#import <Metal/Metal.h>

namespace Diligent
{

void SetMtlObjectLabel(id<MTLResource> Resource, const char* Name) noexcept
{
    if (Resource == nullptr || Name == nullptr)
        return;
    
    @autoreleasepool
    {
        NSString* Label = [NSString stringWithUTF8String:Name];
        Resource.label = Label;
    }
}

void LogMtlError(NSError* Error, const char* Context) noexcept
{
    if (Error == nullptr)
        return;
    
    @autoreleasepool
    {
        NSString* Description = [Error localizedDescription];
        NSString* Reason = [Error localizedFailureReason];
        NSString* Suggestion = [Error localizedRecoverySuggestion];
        
        const char* DescStr = [Description UTF8String];
        const char* ReasonStr = Reason ? [Reason UTF8String] : "";
        const char* SuggestionStr = Suggestion ? [Suggestion UTF8String] : "";
        
        LOG_ERROR_MESSAGE("Metal error in ", Context, ": ", DescStr);
        
        if (ReasonStr && strlen(ReasonStr) > 0)
            LOG_ERROR_MESSAGE("  Reason: ", ReasonStr);
        
        if (SuggestionStr && strlen(SuggestionStr) > 0)
            LOG_ERROR_MESSAGE("  Suggestion: ", SuggestionStr);
        
        LOG_ERROR_MESSAGE("  Error Code: ", static_cast<Int64>(Error.code));
        
        const char* DomainStr = [Error.domain UTF8String];
        LOG_ERROR_MESSAGE("  Error Domain: ", DomainStr ? DomainStr : "Unknown");
    }
}

bool ValidateMtlFeatureSet(id<MTLDevice> Device) noexcept
{
    if (Device == nullptr)
    {
        LOG_ERROR_MESSAGE("Metal device is null");
        return false;
    }
    
    @autoreleasepool
    {
        // Check for minimum Metal feature set
        // macOS: MTLFeatureSet_macOS_GPUFamily1_v1 (Metal 1.0)
        // iOS: MTLFeatureSet_iOS_GPUFamily1_v1 (Metal 1.0)
        
        bool IsValid = false;
        
        #if TARGET_OS_OSX
            // macOS minimum: GPU Family 1, Version 1 (Metal 1.0)
            // We recommend Metal 2.0+ for better performance
            if ([Device supportsFeatureSet:MTLFeatureSet_macOS_GPUFamily1_v1])
            {
                IsValid = true;
                LOG_INFO_MESSAGE("Metal device supports minimum feature set (macOS GPU Family 1 v1)");
            }
            else
            {
                LOG_ERROR_MESSAGE("Metal device does not support minimum feature set");
            }
        #elif TARGET_OS_IOS
            // iOS minimum: GPU Family 1, Version 1 (Metal 1.0)
            if ([Device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily1_v1])
            {
                IsValid = true;
                LOG_INFO_MESSAGE("Metal device supports minimum feature set (iOS GPU Family 1 v1)");
            }
            else
            {
                LOG_ERROR_MESSAGE("Metal device does not support minimum feature set");
            }
        #else
            // Unknown platform
            LOG_WARNING_MESSAGE("Unknown platform - skipping Metal feature set validation");
            IsValid = true;
        #endif
        
        // Log device information
        const char* DeviceName = [Device.name UTF8String];
        LOG_INFO_MESSAGE("Metal Device: ", DeviceName ? DeviceName : "Unknown");
        
        if (Device.hasUnifiedMemory)
        {
            LOG_INFO_MESSAGE("  Unified Memory: Yes");
        }
        else
        {
            LOG_INFO_MESSAGE("  Unified Memory: No");
        }
        
        // Log recommended max working set size (VRAM)
        // Note: This property is only available on macOS 10.12+
        #if TARGET_OS_OSX
            if (@available(macOS 10.12, *))
            {
                LOG_INFO_MESSAGE("  Recommended Max Working Set Size: ", 
                                static_cast<Uint64>(Device.recommendedMaxWorkingSetSize / (1024 * 1024)), " MB");
            }
        #endif
        
        return IsValid;
    }
}

bool IsMtlValidationEnabled() noexcept
{
    // Check if Metal validation is enabled via environment variable or debug settings
    // In debug builds, validation is typically enabled by default
    
    #ifdef DEBUG
        return true;
    #else
        return false;
    #endif
}

} // namespace Diligent
