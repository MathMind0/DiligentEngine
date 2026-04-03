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

/// \file
/// Routines that initialize Metal-based engine implementation

#include "pch.h"

#import <Metal/Metal.h>

#include "EngineFactoryMtl.h"
#include "EngineFactoryBase.hpp"
#include "DebugOutput.h"
#include "EngineMemory.h"
#include "CommandQueueMtlImpl.hpp"
#include "SwapChainMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "DeviceContextMtlImpl.hpp"
#include "RefCntAutoPtr.hpp"

namespace Diligent
{

namespace
{

/// Engine factory for Metal implementation
class EngineFactoryMtlImpl final : public EngineFactoryBase<IEngineFactoryMtl>
{
public:
    static EngineFactoryMtlImpl* GetInstance()
    {
        static EngineFactoryMtlImpl TheFactory;
        return &TheFactory;
    }

    using TBase = EngineFactoryBase<IEngineFactoryMtl>;
    EngineFactoryMtlImpl() :
        TBase{IID_EngineFactoryMtl}
    {
    }

    virtual void DILIGENT_CALL_TYPE CreateDeviceAndContextsMtl(const EngineMtlCreateInfo& EngineCI,
                                                               IRenderDevice**            ppDevice,
                                                               IDeviceContext**           ppContexts) override final
    {
        if (ppDevice == nullptr || ppContexts == nullptr)
        {
            LOG_ERROR_MESSAGE("CreateDeviceAndContextsMtl: ppDevice and ppContexts must not be null");
            return;
        }
        
        *ppDevice = nullptr;
        *ppContexts = nullptr;
        
        try
        {
            // Create Metal device
            id<MTLDevice> mtlDevice = nil;
            
            // Try to get the default Metal device
            mtlDevice = MTLCreateSystemDefaultDevice();
            
            if (mtlDevice == nil)
            {
                // If default device is not available, try to get any available device
                NSArray<id<MTLDevice>>* devices = MTLCopyAllDevices();
                if (devices.count > 0)
                {
                    mtlDevice = devices[0];
                }
            }
            
            if (mtlDevice == nil)
            {
                LOG_ERROR_AND_THROW("Failed to create Metal device: No Metal-capable GPU found");
            }
            
            LOG_INFO_MESSAGE("Created Metal device: ", [[mtlDevice name] UTF8String]);
            
            // Get adapter info
            GraphicsAdapterInfo AdapterInfo;
            memset(&AdapterInfo, 0, sizeof(AdapterInfo));
            AdapterInfo.Type = ADAPTER_TYPE_DISCRETE;
            const char* name = [[mtlDevice name] UTF8String];
            strncpy(AdapterInfo.Description, name, sizeof(AdapterInfo.Description) - 1);
            AdapterInfo.NumQueues = 1;
            
            // Create command queue using CommandQueueMtlImpl
            IMemoryAllocator& RawMemAllocator = GetRawAllocator();
            
            RefCntAutoPtr<CommandQueueMtlImpl> pCmdQueueMtl{
                NEW_RC_OBJ(RawMemAllocator, "CommandQueueMtlImpl instance", CommandQueueMtlImpl)
                (mtlDevice, "Main Command Queue")
            };
            
            // Create device with proper parameters
            ICommandQueueMtl* ppCmdQueues[] = {pCmdQueueMtl};
            
            RenderDeviceMtlImpl* pRenderDeviceMtl = NEW_RC_OBJ(RawMemAllocator, "RenderDeviceMtlImpl instance", RenderDeviceMtlImpl)
                (RawMemAllocator, this, EngineCI, AdapterInfo, static_cast<size_t>(1), ppCmdQueues, mtlDevice);
            
            pRenderDeviceMtl->QueryInterface(IID_RenderDevice, reinterpret_cast<IObject**>(ppDevice));
            
            // Create immediate context with proper descriptor
            DeviceContextDesc ContextDesc;
            ContextDesc.Name = "Immediate context";
            ContextDesc.IsDeferred = false;
            ContextDesc.ContextId = 0;
            
            DeviceContextMtlImpl* pImmediateContextMtl = NEW_RC_OBJ(RawMemAllocator, "DeviceContextMtlImpl instance", DeviceContextMtlImpl)
                (pRenderDeviceMtl, ContextDesc);
            
            pImmediateContextMtl->QueryInterface(IID_DeviceContext, reinterpret_cast<IObject**>(ppContexts));
            
            LOG_INFO_MESSAGE("Metal device and immediate context created successfully");
        }
        catch (const std::exception& e)
        {
            LOG_ERROR_MESSAGE("Failed to create Metal device and contexts: ", e.what());
            if (*ppDevice)
            {
                (*ppDevice)->Release();
                *ppDevice = nullptr;
            }
            if (*ppContexts)
            {
                (*ppContexts)->Release();
                *ppContexts = nullptr;
            }
        }
    }

    virtual void DILIGENT_CALL_TYPE CreateSwapChainMtl(IRenderDevice*       pDevice,
                                                       IDeviceContext*      pImmediateContext,
                                                       const SwapChainDesc& SwapChainDesc,
                                                       const NativeWindow&  Window,
                                                       ISwapChain**         ppSwapChain) override final
    {
        if (pDevice == nullptr || pImmediateContext == nullptr || ppSwapChain == nullptr)
        {
            LOG_ERROR_MESSAGE("Invalid arguments: pDevice, pImmediateContext, and ppSwapChain must not be null");
            if (ppSwapChain) *ppSwapChain = nullptr;
            return;
        }
        
        try
        {
            RenderDeviceMtlImpl* pDeviceMtl = ClassPtrCast<RenderDeviceMtlImpl>(pDevice);
            DeviceContextMtlImpl* pContextMtl = ClassPtrCast<DeviceContextMtlImpl>(pImmediateContext);
            
            SwapChainMtlImpl* pSwapChainMtl = NEW_RC_OBJ(GetRawAllocator(), "SwapChainMtlImpl instance", SwapChainMtlImpl)
                (SwapChainDesc, pDeviceMtl, pContextMtl, Window);
            
            *ppSwapChain = pSwapChainMtl;
        }
        catch (const std::exception& e)
        {
            LOG_ERROR_MESSAGE("Failed to create Metal swap chain: ", e.what());
            *ppSwapChain = nullptr;
        }
    }

    virtual void DILIGENT_CALL_TYPE CreateCommandQueueMtl(void*                pMtlNativeQueue,
                                                          IMemoryAllocator*    pRawAllocator,
                                                          ICommandQueueMtl**   ppCommandQueue) override final
    {
        LOG_ERROR_MESSAGE("CreateCommandQueueMtl is not implemented yet. Metal backend is under development.");
        if (ppCommandQueue) *ppCommandQueue = nullptr;
    }

    virtual void DILIGENT_CALL_TYPE AttachToMtlDevice(void*                     pMtlNativeDevice,
                                                      Uint32                    CommandQueueCount,
                                                      ICommandQueueMtl**        ppCommandQueues,
                                                      const EngineMtlCreateInfo& EngineCI,
                                                      IRenderDevice**           ppDevice,
                                                      IDeviceContext**          ppContexts) override final
    {
        LOG_ERROR_MESSAGE("AttachToMtlDevice is not implemented yet. Metal backend is under development.");
        if (ppDevice) *ppDevice = nullptr;
        if (ppContexts) *ppContexts = nullptr;
    }

    virtual void DILIGENT_CALL_TYPE EnumerateAdapters(Version              MinVersion,
                                                      Uint32&              NumAdapters,
                                                      GraphicsAdapterInfo* Adapters) const override final
    {
        // Enumerate Metal devices
        NSArray<id<MTLDevice>>* devices = MTLCopyAllDevices();
        
        if (Adapters == nullptr)
        {
            // Return the number of adapters
            NumAdapters = static_cast<Uint32>(devices.count);
            return;
        }
        
        // Fill adapter information
        const Uint32 maxAdapters = NumAdapters;
        NumAdapters = 0;
        
        for (id<MTLDevice> device in devices)
        {
            if (NumAdapters >= maxAdapters)
                break;
                
            GraphicsAdapterInfo& adapterInfo = Adapters[NumAdapters];
            
            // Set adapter type - use UNKNOWN for now, will be properly detected later
            adapterInfo.Type = ADAPTER_TYPE_UNKNOWN;
            
            // Set adapter name
            const char* name = [device.name UTF8String];
            strncpy(adapterInfo.Description, name, sizeof(adapterInfo.Description) - 1);
            adapterInfo.Description[sizeof(adapterInfo.Description) - 1] = '\0';
            
            // Set number of queues
            adapterInfo.NumQueues = 1; // Metal uses a single command queue
            
            NumAdapters++;
        }
    }

    virtual void DILIGENT_CALL_TYPE CreateDearchiver(const DearchiverCreateInfo& CreateInfo,
                                                     IDearchiver**               ppDearchiver) const override final
    {
        LOG_ERROR_MESSAGE("CreateDearchiver is not implemented yet. Metal backend is under development.");
        if (ppDearchiver) *ppDearchiver = nullptr;
    }

private:
    RefCntWeakPtr<IRenderDevice> m_wpDevice;
};

} // namespace

API_QUALIFIER IEngineFactoryMtl* GetEngineFactoryMtl()
{
    return EngineFactoryMtlImpl::GetInstance();
}

} // namespace Diligent
