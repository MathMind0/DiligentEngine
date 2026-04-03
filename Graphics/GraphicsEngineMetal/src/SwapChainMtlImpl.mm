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
/// Implementation of Diligent::SwapChainMtlImpl class

#include "pch.h"

#include "SwapChainMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "DeviceContextMtlImpl.hpp"
#include "TextureMtlImpl.hpp"
#include "TextureViewMtlImpl.hpp"
#include "MetalTypeConversions.h"

#import <QuartzCore/QuartzCore.h>

#if PLATFORM_MACOS
#import <AppKit/AppKit.h>
#elif PLATFORM_IOS || PLATFORM_TVOS
#import <UIKit/UIKit.h>
#endif

namespace Diligent
{

namespace
{

CAMetalLayer* GetOrCreateMetalLayer(const NativeWindow& Window)
{
#if PLATFORM_MACOS
    NSView* view = (__bridge NSView*)(Window.pNSView);
    if (view == nil)
    {
        LOG_ERROR_MESSAGE("Failed to get NSView from native window");
        return nil;
    }
    
    if ([view.layer isKindOfClass:[CAMetalLayer class]])
    {
        return static_cast<CAMetalLayer*>(view.layer);
    }
    
    CAMetalLayer* metalLayer = [CAMetalLayer layer];
    if (metalLayer == nil)
    {
        LOG_ERROR_MESSAGE("Failed to create CAMetalLayer");
        return nil;
    }
    
    view.wantsLayer = YES;
    view.layer = metalLayer;
    
    return metalLayer;
    
#elif PLATFORM_IOS || PLATFORM_TVOS
    UIView* view = static_cast<UIView*>(Window.pUIView);
    if (view == nil)
    {
        LOG_ERROR_MESSAGE("Failed to get UIView from native window");
        return nil;
    }
    
    if ([view.layer isKindOfClass:[CAMetalLayer class]])
    {
        return static_cast<CAMetalLayer*>(view.layer);
    }
    
    CAMetalLayer* metalLayer = [CAMetalLayer layer];
    if (metalLayer == nil)
    {
        LOG_ERROR_MESSAGE("Failed to create CAMetalLayer");
        return nil;
    }
    
    view.layer = metalLayer;
    
    return metalLayer;
#else
    LOG_ERROR_MESSAGE("Platform not supported for Metal swap chain");
    return nil;
#endif
}

} // namespace

SwapChainMtlImpl::SwapChainMtlImpl(IReferenceCounters*         pRefCounters,
                                   const SwapChainDesc&        SwapChainDesc,
                                   RenderDeviceMtlImpl*        pRenderDevice,
                                   DeviceContextMtlImpl*       pDeviceContext,
                                   const NativeWindow&         Window) :
    TSwapChainBase{pRefCounters, pRenderDevice, pDeviceContext, SwapChainDesc},
    m_Window{Window}
{
    LOG_INFO_MESSAGE("Creating Metal swap chain: ", SwapChainDesc.Width, "x", SwapChainDesc.Height, 
                     ", ", SwapChainDesc.BufferCount, " buffers");
    
    m_MetalLayer = GetOrCreateMetalLayer(Window);
    if (m_MetalLayer == nil)
    {
        LOG_ERROR_AND_THROW("Failed to get or create CAMetalLayer");
    }
    
    ConfigureMetalLayer();
    CreateDepthBuffer();
    
    if (!AcquireNextDrawable())
    {
        LOG_ERROR_AND_THROW("Failed to acquire first drawable");
    }
    
    LOG_INFO_MESSAGE("Metal swap chain created successfully");
}

SwapChainMtlImpl::~SwapChainMtlImpl()
{
    LOG_INFO_MESSAGE("Destroying Metal swap chain");
    ReleaseCurrentDrawable();
}

void SwapChainMtlImpl::ConfigureMetalLayer()
{
    if (m_MetalLayer == nil)
    {
        LOG_ERROR_MESSAGE("Metal layer is nil");
        return;
    }
    
    RenderDeviceMtlImpl* pDeviceMtl = m_pRenderDevice.RawPtr<RenderDeviceMtlImpl>();
    id<MTLDevice> mtlDevice = pDeviceMtl->GetMtlDevice();
    
    m_MetalLayer.device = mtlDevice;
    
    MTLPixelFormat pixelFormat = TexFormatToMtlPixelFormat(m_SwapChainDesc.ColorBufferFormat);
    if (pixelFormat == MTLPixelFormatInvalid)
    {
        LOG_WARNING_MESSAGE("Unsupported color buffer format, using BGRA8Unorm");
        pixelFormat = MTLPixelFormatBGRA8Unorm;
        m_SwapChainDesc.ColorBufferFormat = TEX_FORMAT_BGRA8_UNORM;
    }
    m_MetalLayer.pixelFormat = pixelFormat;
    m_MetalLayer.drawableSize = CGSizeMake(m_SwapChainDesc.Width, m_SwapChainDesc.Height);
    m_MetalLayer.framebufferOnly = YES;
    
#if PLATFORM_MACOS
    if (@available(macOS 10.13.2, *))
    {
        m_MetalLayer.displaySyncEnabled = m_VSyncEnabled;
    }
    
    NSView* view = (__bridge NSView*)(m_Window.pNSView);
    if (view != nil && view.window != nil)
    {
        m_ContentScale = view.window.backingScaleFactor;
        if (m_ContentScale <= 0)
            m_ContentScale = 1.0;
    }
#elif PLATFORM_IOS || PLATFORM_TVOS
    UIView* view = (__bridge UIView*)(m_Window.pUIView);
    if (view != nil)
    {
        m_ContentScale = view.contentScaleFactor;
        if (m_ContentScale <= 0)
            m_ContentScale = 1.0;
    }
#endif
    
    LOG_INFO_MESSAGE("Metal layer configured: format=", static_cast<int>(pixelFormat), 
                     ", size=", m_SwapChainDesc.Width, "x", m_SwapChainDesc.Height,
                     ", scale=", m_ContentScale);
}

void SwapChainMtlImpl::CreateDepthBuffer()
{
    if (m_SwapChainDesc.DepthBufferFormat == TEX_FORMAT_UNKNOWN)
    {
        LOG_INFO_MESSAGE("No depth buffer format specified, skipping depth buffer creation");
        return;
    }
    
    TextureDesc DepthBufferDesc;
    DepthBufferDesc.Name        = "Depth buffer";
    DepthBufferDesc.Type        = RESOURCE_DIM_TEX_2D;
    DepthBufferDesc.Width       = m_SwapChainDesc.Width;
    DepthBufferDesc.Height      = m_SwapChainDesc.Height;
    DepthBufferDesc.Format      = m_SwapChainDesc.DepthBufferFormat;
    DepthBufferDesc.BindFlags   = BIND_DEPTH_STENCIL;
    DepthBufferDesc.Usage       = USAGE_DEFAULT;
    
    RefCntAutoPtr<ITexture> pDepthBuffer;
    m_pRenderDevice->CreateTexture(DepthBufferDesc, nullptr, &pDepthBuffer);
    
    m_pDepthBufferTexture = RefCntAutoPtr<ITextureMtl>(pDepthBuffer, IID_TextureMtl);
    if (m_pDepthBufferTexture == nullptr)
    {
        LOG_ERROR_MESSAGE("Failed to create depth buffer texture");
        return;
    }
    
    TextureViewDesc DSVDesc;
    DSVDesc.ViewType = TEXTURE_VIEW_DEPTH_STENCIL;
    RefCntAutoPtr<ITextureView> pDSV;
    m_pDepthBufferTexture->CreateView(DSVDesc, &pDSV);
    m_pDepthBufferDSV = RefCntAutoPtr<ITextureViewMtl>(pDSV, IID_TextureViewMtl);
    
    LOG_INFO_MESSAGE("Depth buffer created: ", m_SwapChainDesc.Width, "x", m_SwapChainDesc.Height,
                     ", format=", static_cast<int>(m_SwapChainDesc.DepthBufferFormat));
}

bool SwapChainMtlImpl::AcquireNextDrawable()
{
    ReleaseCurrentDrawable();
    
    @autoreleasepool
    {
        m_CurrentDrawable = [m_MetalLayer nextDrawable];
        if (m_CurrentDrawable == nil)
        {
            LOG_ERROR_MESSAGE("Failed to acquire next drawable");
            return false;
        }
        
        // Create back buffer texture view
        TextureDesc BackBufferDesc;
        BackBufferDesc.Name      = "Back buffer";
        BackBufferDesc.Type      = RESOURCE_DIM_TEX_2D;
        BackBufferDesc.Width     = m_SwapChainDesc.Width;
        BackBufferDesc.Height    = m_SwapChainDesc.Height;
        BackBufferDesc.Format    = m_SwapChainDesc.ColorBufferFormat;
        BackBufferDesc.BindFlags = BIND_RENDER_TARGET;
        BackBufferDesc.Usage     = USAGE_DEFAULT;
        
        // For now, we'll skip wrapping the drawable texture
        // This is a simplified implementation
        LOG_INFO_MESSAGE("Acquired next drawable");
    }
    
    return true;
}

void SwapChainMtlImpl::ReleaseCurrentDrawable()
{
    m_CurrentDrawable = nil;
    m_pBackBufferRTV.Release();
    m_pBackBufferTexture.Release();
}

void SwapChainMtlImpl::UpdateDrawableSize()
{
    if (m_MetalLayer == nil)
        return;
    
    CGSize drawableSize = m_MetalLayer.drawableSize;
    if (drawableSize.width != m_SwapChainDesc.Width || drawableSize.height != m_SwapChainDesc.Height)
    {
        m_SwapChainDesc.Width  = static_cast<Uint32>(drawableSize.width);
        m_SwapChainDesc.Height = static_cast<Uint32>(drawableSize.height);
        
        CreateDepthBuffer();
        AcquireNextDrawable();
        
        LOG_INFO_MESSAGE("Drawable size updated to ", m_SwapChainDesc.Width, "x", m_SwapChainDesc.Height);
    }
}

void SwapChainMtlImpl::Present(Uint32 SyncInterval)
{
    if (m_CurrentDrawable == nil)
    {
        LOG_ERROR_MESSAGE("No current drawable to present");
        return;
    }
    
    // TODO: Get command buffer from device context for proper synchronization
    // id<MTLCommandBuffer> commandBuffer = ...;
    
    // Present the drawable
    if (SyncInterval == 0)
    {
        // No VSync - present immediately
        [m_CurrentDrawable present];
    }
    else
    {
        // VSync enabled - present at next frame
        [m_CurrentDrawable present];
    }
    
    // Acquire next drawable for next frame
    AcquireNextDrawable();
}

void SwapChainMtlImpl::Resize(Uint32 NewWidth, Uint32 NewHeight, SURFACE_TRANSFORM NewPreTransform)
{
    if (m_IsResizing)
        return;
    
    m_IsResizing = true;
    
    LOG_INFO_MESSAGE("Resizing swap chain to ", NewWidth, "x", NewHeight);
    
    ReleaseCurrentDrawable();
    
    m_SwapChainDesc.Width  = NewWidth;
    m_SwapChainDesc.Height = NewHeight;
    
    if (m_MetalLayer != nil)
    {
        m_MetalLayer.drawableSize = CGSizeMake(NewWidth, NewHeight);
    }
    
    CreateDepthBuffer();
    AcquireNextDrawable();
    
    m_IsResizing = false;
    
    LOG_INFO_MESSAGE("Swap chain resize completed");
}

void SwapChainMtlImpl::SetFullscreenMode(const DisplayModeAttribs& DisplayMode)
{
    LOG_WARNING_MESSAGE("SetFullscreenMode is not supported on Metal");
}

void SwapChainMtlImpl::SetWindowedMode()
{
    LOG_WARNING_MESSAGE("SetWindowedMode is not supported on Metal");
}

} // namespace Diligent
