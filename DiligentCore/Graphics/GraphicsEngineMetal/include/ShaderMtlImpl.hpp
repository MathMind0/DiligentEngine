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
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. ANY PROPRIETARY RIGHTS.
 *
 *  In no event and under no legal theory, whether in tort (including negligence),
 *  contract, or otherwise, unless required by applicable law or agreed to in writing,
 *  shall any Contributor be liable for any damages, including any direct, indirect,
 *  special, incidental, or consequential damages of any character arising as a
 *  result of this License or out of the use or inability to use the software
 *  (including but not limited to damages for loss of goodwill, work stoppage,
 *  computer failure or malfunction, or any and all other commercial damages or
 *  losses), even if such Contributor has been advised of the possibility of such damages.
 */

#pragma once

/// \file
/// Declaration of Diligent::ShaderMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "ShaderBase.hpp"
#include "SPIRVShaderResources.hpp"
#include "ThreadPool.h"
#include "RefCntAutoPtr.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

/// Shader object implementation in Metal backend.
class ShaderMtlImpl final : public ShaderBase<EngineMtlImplTraits>
{
public:
    using TShaderBase = ShaderBase<EngineMtlImplTraits>;

    static constexpr INTERFACE_ID IID_InternalImpl =
        {0x2a5b7c8d, 0x9e1f, 0x4a3b, {0x8c, 0x2d, 0x5e, 0x6f, 0x7a, 0x8b, 0x9c, 0xad}};

    struct CreateInfo
    {
        const RenderDeviceInfo&    DeviceInfo;
        const GraphicsAdapterInfo& AdapterInfo;
        IDataBlob** const          ppCompilerOutput;
        IThreadPool* const         pCompilationThreadPool;
    };

    ShaderMtlImpl(IReferenceCounters*     pRefCounters,
                  RenderDeviceMtlImpl*    pRenderDeviceMtl,
                  const ShaderCreateInfo& ShaderCI,
                  const CreateInfo&       MtlShaderCI,
                  bool                    IsDeviceInternal = false);

    ~ShaderMtlImpl();

    IMPLEMENT_QUERY_INTERFACE2_IN_PLACE(IID_ShaderMtl, IID_InternalImpl, TShaderBase)

    /// Implementation of IShader::GetResourceCount() in Metal backend.
    virtual Uint32 DILIGENT_CALL_TYPE GetResourceCount() const override final
    {
        DEV_CHECK_ERR(!IsCompiling(), "Shader resources are not available until the shader is compiled. Use GetStatus() to check the shader status.");
        return m_pShaderResources ? m_pShaderResources->GetTotalResources() : 0;
    }

    /// Implementation of IShader::GetResource() in Metal backend.
    virtual void DILIGENT_CALL_TYPE GetResourceDesc(Uint32 Index, ShaderResourceDesc& ResourceDesc) const override final;

    /// Implementation of IShader::GetConstantBufferDesc() in Metal backend.
    virtual const ShaderCodeBufferDesc* DILIGENT_CALL_TYPE GetConstantBufferDesc(Uint32 Index) const override final;

    /// Implementation of IShaderMtl::GetMtlShaderFunction().
    virtual id<MTLFunction> DILIGENT_CALL_TYPE GetMtlShaderFunction() const override final
    {
        DEV_CHECK_ERR(!IsCompiling(), "Shader function is not available until the shader is compiled. Use GetStatus() to check the shader status.");
        return m_mtlFunction;
    }

    using ShaderResourcesSharedPtr = std::shared_ptr<const SPIRVShaderResources>;
    const ShaderResourcesSharedPtr& GetShaderResources() const
    {
        DEV_CHECK_ERR(!IsCompiling(), "Shader resources are not available until the shader is compiled. Use GetStatus() to check the shader status.");
        return m_pShaderResources;
    }

    const char* GetEntryPoint() const
    {
        DEV_CHECK_ERR(!IsCompiling(), "Shader entry point is not available until the shader is compiled. Use GetStatus() to check the shader status.");
        return m_EntryPoint.c_str();
    }

    /// Returns the MSL source code generated from SPIR-V
    const std::string& GetMSLSource() const
    {
        return m_MSLSource;
    }

    virtual void DILIGENT_CALL_TYPE GetBytecode(const void** ppBytecode,
                                                Uint64&      Size) const override final
    {
        DEV_CHECK_ERR(!IsCompiling(), "Shader byte code is not available until the shader is compiled. Use GetStatus() to check the shader status.");
        *ppBytecode = !m_SPIRV.empty() ? m_SPIRV.data() : nullptr;
        Size        = m_SPIRV.size() * sizeof(m_SPIRV[0]);
    }

private:
    void Initialize(const ShaderCreateInfo& ShaderCI,
                    const CreateInfo&       MtlShaderCI) noexcept(false);

    /// Compiles SPIR-V to MSL using SPIRV-Cross
    std::string CompileSPIRVtoMSL(const std::vector<uint32_t>& SPIRV,
                                  std::string&                 EntryPoint);

    /// Compiles MSL source to MTLLibrary and extracts MTLFunction
    void CompileMSL(const std::string& MSLSource,
                    const std::string& EntryPoint);

    /// Logs Metal compilation errors
    void LogMetalError(NSError* error, const char* context);

private:
    ShaderResourcesSharedPtr m_pShaderResources;

    std::string           m_EntryPoint;
    std::vector<uint32_t> m_SPIRV;
    std::string           m_MSLSource;

    // Metal objects
    id<MTLLibrary>  m_mtlLibrary  = nil;
    id<MTLFunction>  m_mtlFunction = nil;
    id<MTLDevice>    m_mtlDevice   = nil;
};

} // namespace Diligent
