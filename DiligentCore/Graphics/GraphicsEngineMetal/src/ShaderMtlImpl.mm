/*
 *  Copyright 2019-2026 Diligent Graphics LLC
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

#include "pch.h"

#include "ShaderMtlImpl.hpp"

#include <array>
#include <cctype>

#include "RenderDeviceMtlImpl.hpp"
#include "DataBlobImpl.hpp"
#include "GLSLUtils.hpp"
#include "ShaderToolsCommon.hpp"

// SPIRV-Cross headers
#include "spirv_parser.hpp"
#include "spirv_msl.hpp"
#include "GLSLangUtils.hpp"
#include "SPIRVShaderResources.hpp"

namespace Diligent
{

constexpr INTERFACE_ID ShaderMtlImpl::IID_InternalImpl;

ShaderMtlImpl::ShaderMtlImpl(IReferenceCounters*     pRefCounters,
                             RenderDeviceMtlImpl*    pRenderDeviceMtl,
                             const ShaderCreateInfo& ShaderCI,
                             const CreateInfo&       MtlShaderCI,
                             bool                    IsDeviceInternal) :
    // clang-format off
    TShaderBase
    {
        pRefCounters,
        pRenderDeviceMtl,
        ShaderCI.Desc,
        MtlShaderCI.DeviceInfo,
        MtlShaderCI.AdapterInfo,
        IsDeviceInternal
    },
    m_mtlDevice{pRenderDeviceMtl->GetMtlDevice()}
// clang-format on
{
    m_Status.store(SHADER_STATUS_COMPILING);
    if (MtlShaderCI.pCompilationThreadPool == nullptr || (ShaderCI.CompileFlags & SHADER_COMPILE_FLAG_ASYNCHRONOUS) == 0 || ShaderCI.ByteCode != nullptr)
    {
        Initialize(ShaderCI, MtlShaderCI);
    }
    else
    {
        this->m_AsyncInitializer = AsyncInitializer::Start(
            MtlShaderCI.pCompilationThreadPool,
            [this,
             ShaderCI         = ShaderCreateInfoWrapper{ShaderCI, GetRawAllocator()},
             DeviceInfo       = MtlShaderCI.DeviceInfo,
             AdapterInfo      = MtlShaderCI.AdapterInfo,
             ppCompilerOutput = MtlShaderCI.ppCompilerOutput](Uint32 ThreadId) mutable //
            {
                try
                {
                    const CreateInfo MtlShaderCI{
                        DeviceInfo,
                        AdapterInfo,
                        ppCompilerOutput,
                        nullptr,
                    };
                    Initialize(ShaderCI, MtlShaderCI);
                }
                catch (...)
                {
                    m_Status.store(SHADER_STATUS_FAILED);
                }
                ShaderCI = ShaderCreateInfoWrapper{};
            });
    }
}

ShaderMtlImpl::~ShaderMtlImpl()
{
    // Make sure that asynchronous task is complete as it references the shader object.
    GetStatus(/*WaitForCompletion = */ true);

    // Metal objects are automatically released by ARC - no explicit release needed
    m_mtlFunction = nil;
    m_mtlLibrary = nil;
}

void ShaderMtlImpl::Initialize(const ShaderCreateInfo& ShaderCI,
                               const CreateInfo&       MtlShaderCI) noexcept(false)
{
    std::vector<uint32_t> SPIRV;

    // Step 1: Get SPIR-V bytecode
    if (ShaderCI.ByteCode != nullptr && ShaderCI.ByteCodeSize > 0)
    {
        // Use pre-compiled SPIR-V bytecode
        const uint32_t* pByteCode = reinterpret_cast<const uint32_t*>(ShaderCI.ByteCode);
        const size_t    NumWords  = ShaderCI.ByteCodeSize / sizeof(uint32_t);
        SPIRV.assign(pByteCode, pByteCode + NumWords);
    }
    else
    {
        // Compile from source to SPIR-V
        if (ShaderCI.Source == nullptr && ShaderCI.FilePath == nullptr)
        {
            LOG_ERROR_AND_THROW("Shader source or file path must be provided");
        }

        // Determine the shader source language
        SHADER_SOURCE_LANGUAGE SourceLang = ShaderCI.SourceLanguage;
        if (SourceLang == SHADER_SOURCE_LANGUAGE_DEFAULT)
        {
            SourceLang = SHADER_SOURCE_LANGUAGE_HLSL;
        }

        std::string          Source;
        ShaderSourceFileData SourceData;

        if (ShaderCI.Source != nullptr)
        {
            Source = ShaderCI.Source;
        }
        else
        {
            // Load shader from file - use the convenient overload that takes ShaderCreateInfo
            SourceData = ReadShaderSourceFile(ShaderCI);
            Source     = std::string{SourceData.Source, SourceData.SourceLength};
        }

        // Compile HLSL to SPIR-V using glslang
        if (SourceLang == SHADER_SOURCE_LANGUAGE_HLSL)
        {
#if DILIGENT_NO_GLSLANG
            LOG_ERROR_AND_THROW("Diligent engine was not linked with glslang, use precompiled SPIRV bytecode.");
#else
            // Use HLSLtoSPIRV which takes ShaderCreateInfo directly
            SPIRV = GLSLangUtils::HLSLtoSPIRV(ShaderCI, GLSLangUtils::SpirvVersion::Vk100, nullptr, MtlShaderCI.ppCompilerOutput);

            if (SPIRV.empty())
            {
                LOG_ERROR_AND_THROW("Failed to compile shader '", (ShaderCI.Desc.Name ? ShaderCI.Desc.Name : ""),
                                    "' to SPIR-V via glslang");
            }
#endif
        }
        else if (SourceLang == SHADER_SOURCE_LANGUAGE_GLSL)
        {
#if DILIGENT_NO_GLSLANG
            LOG_ERROR_AND_THROW("Diligent engine was not linked with glslang, use precompiled SPIRV bytecode.");
#else
            GLSLangUtils::GLSLtoSPIRVAttribs Attribs;
            Attribs.ShaderSource  = Source.c_str();
            Attribs.SourceCodeLen = static_cast<int>(Source.length());
            Attribs.ShaderType    = m_Desc.ShaderType;
            Attribs.Macros        = ShaderCI.Macros;
            Attribs.ppCompilerOutput = MtlShaderCI.ppCompilerOutput;

            SPIRV = GLSLangUtils::GLSLtoSPIRV(Attribs);

            if (SPIRV.empty())
            {
                LOG_ERROR_AND_THROW("Failed to compile GLSL shader '", (ShaderCI.Desc.Name ? ShaderCI.Desc.Name : ""),
                                    "' to SPIR-V");
            }
#endif
        }
        else
        {
            LOG_ERROR_AND_THROW("Unsupported shader source language for Metal backend");
        }
    }

    if (SPIRV.empty())
    {
        LOG_ERROR_AND_THROW("SPIR-V bytecode is empty after compilation");
    }

    // Store SPIR-V
    m_SPIRV = std::move(SPIRV);

    // Step 2: Perform shader reflection using SPIRVShaderResources
    SPIRVShaderResources::CreateInfo ResCI;
    ResCI.ShaderType                  = m_Desc.ShaderType;
    ResCI.Name                        = m_Desc.Name;
    ResCI.CombinedSamplerSuffix       = nullptr; // TODO: Get from device
    ResCI.LoadShaderStageInputs       = (m_Desc.ShaderType == SHADER_TYPE_VERTEX);
    ResCI.LoadUniformBufferReflection = true;

    std::string EntryPoint;
    if (ShaderCI.EntryPoint != nullptr)
    {
        EntryPoint = ShaderCI.EntryPoint;
    }
    else
    {
        EntryPoint = "main";
    }
    m_EntryPoint = EntryPoint;

    m_pShaderResources = SPIRVShaderResources::Create(
        GetRawAllocator(),
        m_SPIRV,
        ResCI,
        &EntryPoint);

    // Step 3: Compile SPIR-V to MSL using SPIRV-Cross
    std::string MSLSource = CompileSPIRVtoMSL(m_SPIRV, EntryPoint);
    m_MSLSource           = MSLSource;

    // Step 4: Compile MSL to MTLLibrary and extract MTLFunction
    CompileMSL(MSLSource, EntryPoint);

    // Mark shader as ready
    m_Status.store(SHADER_STATUS_READY);
}

std::string ShaderMtlImpl::CompileSPIRVtoMSL(const std::vector<uint32_t>& SPIRV,
                                              std::string&                 EntryPoint)
{
    try
    {
        // Parse SPIR-V using Diligent's SPIRV-Cross wrapper
        diligent_spirv_cross::Parser parser(SPIRV);
        parser.parse();

        // Create MSL compiler
        diligent_spirv_cross::CompilerMSL compiler(parser.get_parsed_ir());

        // Configure MSL compiler options
        diligent_spirv_cross::CompilerMSL::Options msl_options;
        msl_options.set_msl_version(2, 0); // MSL 2.0 for basic features

        // Configure platform-specific options
#if TARGET_OS_IOS
        msl_options.platform = diligent_spirv_cross::CompilerMSL::Options::iOS;
#else
        msl_options.platform = diligent_spirv_cross::CompilerMSL::Options::macOS;
#endif

        // Enable argument buffers for better descriptor set mapping
        msl_options.argument_buffers = true;

        // Set the options
        compiler.set_msl_options(msl_options);

        // Rename entry point if needed
        // Metal requires specific function names
        std::string msl_entry_point = EntryPoint;

        // Compile to MSL
        std::string msl_source = compiler.compile();

        // Post-process MSL source to ensure entry point is correct
        // SPIRV-Cross may rename the entry point
        auto entry_points = compiler.get_entry_points_and_stages();
        if (!entry_points.empty())
        {
            // Use the first entry point that matches our shader stage
            for (const auto& ep : entry_points)
            {
                if (ep.execution_model == diligent_spirv_cross::ExecutionModelVertex ||
                    ep.execution_model == diligent_spirv_cross::ExecutionModelFragment ||
                    ep.execution_model == diligent_spirv_cross::ExecutionModelGLCompute ||
                    ep.execution_model == diligent_spirv_cross::ExecutionModelMeshNV ||
                    ep.execution_model == diligent_spirv_cross::ExecutionModelTaskNV)
                {
                    msl_entry_point = ep.name;
                    break;
                }
            }
        }

        EntryPoint = msl_entry_point;

        return msl_source;
    }
    catch (const std::exception& e)
    {
        LOG_ERROR_AND_THROW("Failed to compile SPIR-V to MSL: ", e.what());
        return "";
    }
}

void ShaderMtlImpl::CompileMSL(const std::string& MSLSource,
                                const std::string& EntryPoint)
{
    @autoreleasepool
    {
        NSError* error = nil;

        // Create MTLLibrary from MSL source
        MTLCompileOptions* compile_options = [[MTLCompileOptions alloc] init];

        // Set Metal language version based on platform
#if TARGET_OS_IOS
        compile_options.languageVersion = MTLLanguageVersion2_0;
#else
        compile_options.languageVersion = MTLLanguageVersion2_0;
#endif

        // Compile MSL to MTLLibrary
        NSString* msl_ns_string = [NSString stringWithUTF8String:MSLSource.c_str()];
        m_mtlLibrary            = [m_mtlDevice newLibraryWithSource:msl_ns_string
                                                            options:compile_options
                                                              error:&error];

        if (error != nil || m_mtlLibrary == nil)
        {
            LogMetalError(error, "MTLLibrary compilation");
            LOG_ERROR_AND_THROW("Failed to compile MSL shader library for shader '", m_Desc.Name, "'");
        }

        // Extract MTLFunction by entry point name
        NSString* entry_point_ns = [NSString stringWithUTF8String:EntryPoint.c_str()];
        m_mtlFunction            = [m_mtlLibrary newFunctionWithName:entry_point_ns];

        if (m_mtlFunction == nil)
        {
            LOG_ERROR_AND_THROW("Failed to find entry point '", EntryPoint, "' in compiled Metal shader library for shader '",
                                m_Desc.Name, "'");
        }
    }
}

void ShaderMtlImpl::LogMetalError(NSError* error, const char* context)
{
    if (error == nil)
        return;

    NSString* error_desc = [error localizedDescription];
    NSString* error_reason = [error localizedFailureReason];
    NSString* error_suggestion = [error localizedRecoverySuggestion];

    std::string error_message;
    if (error_desc != nil)
    {
        error_message += [error_desc UTF8String];
    }
    if (error_reason != nil)
    {
        if (!error_message.empty())
            error_message += " - ";
        error_message += [error_reason UTF8String];
    }
    if (error_suggestion != nil)
    {
        if (!error_message.empty())
            error_message += " - ";
        error_message += "Suggestion: ";
        error_message += [error_suggestion UTF8String];
    }

    LOG_ERROR_MESSAGE("Metal error during ", context, ": ", error_message);
}

void ShaderMtlImpl::GetResourceDesc(Uint32 Index, ShaderResourceDesc& ResourceDesc) const
{
    DEV_CHECK_ERR(!IsCompiling(), "Shader resources are not available until the shader is compiled. Use GetStatus() to check the shader status.");

    const Uint32 ResCount = GetResourceCount();
    DEV_CHECK_ERR(Index < ResCount, "Resource index (", Index, ") is out of range");
    if (Index < ResCount)
    {
        const SPIRVShaderResourceAttribs& SPIRVResource = m_pShaderResources->GetResource(Index);
        ResourceDesc                                    = SPIRVResource.GetResourceDesc();
    }
}

const ShaderCodeBufferDesc* ShaderMtlImpl::GetConstantBufferDesc(Uint32 Index) const
{
    DEV_CHECK_ERR(!IsCompiling(), "Shader resources are not available until the shader is compiled. Use GetStatus() to check the shader status.");

    const Uint32 ResCount = GetResourceCount();
    if (Index >= ResCount)
    {
        UNEXPECTED("Resource index (", Index, ") is out of range");
        return nullptr;
    }

    // Uniform buffers always go first in the list of resources
    return m_pShaderResources->GetUniformBufferDesc(Index);
}

} // namespace Diligent
