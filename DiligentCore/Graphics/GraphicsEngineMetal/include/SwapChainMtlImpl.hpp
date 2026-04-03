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

#pragma once

/// \file
/// Declaration of Diligent::SwapChainMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "SwapChainMtl.h"
#include "SwapChainBase.hpp"

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

namespace Diligent
{

/// Swap chain implementation in Metal backend.
class SwapChainMtlImpl final : public SwapChainBase<ISwapChainMtl>
{
public:
    using TSwapChainBase = SwapChainBase<ISwapChainMtl>;

    /**
     * @brief Constructs a Metal swap chain.
     * 
     * @param pRefCounters    Reference counters object.
     * @param SwapChainDesc   Swap chain description.
     * @param pRenderDevice   Pointer to the render device.
     * @param pDeviceContext  Pointer to the immediate device context.
     * @param Window          Native window containing the CAMetalLayer.
     */
    SwapChainMtlImpl(IReferenceCounters*        pRefCounters,
                     const SwapChainDesc&       SwapChainDesc,
                     class RenderDeviceMtlImpl* pRenderDevice,
                     class DeviceContextMtlImpl* pDeviceContext,
                     const NativeWindow&        Window);

    ~SwapChainMtlImpl() override;

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_SwapChainMtl, TSwapChainBase)

    /// Implementation of ISwapChain::Present() in Metal backend.
    virtual void DILIGENT_CALL_TYPE Present(Uint32 SyncInterval) override final;

    /// Implementation of ISwapChain::Resize() in Metal backend.
    virtual void DILIGENT_CALL_TYPE Resize(Uint32 NewWidth, Uint32 NewHeight, SURFACE_TRANSFORM NewPreTransform) override final;

    /// Implementation of ISwapChain::SetFullscreenMode() in Metal backend.
    virtual void DILIGENT_CALL_TYPE SetFullscreenMode(const DisplayModeAttribs& DisplayMode) override final;

    /// Implementation of ISwapChain::SetWindowedMode() in Metal backend.
    virtual void DILIGENT_CALL_TYPE SetWindowedMode() override final;

    /// Implementation of ISwapChain::GetCurrentBackBufferRTV() in Metal backend.
    virtual ITextureViewMtl* DILIGENT_CALL_TYPE GetCurrentBackBufferRTV() override final
    {
        return m_pBackBufferRTV;
    }

    /// Implementation of ISwapChain::GetDepthBufferDSV() in Metal backend.
    virtual ITextureViewMtl* DILIGENT_CALL_TYPE GetDepthBufferDSV() override final
    {
        return m_pDepthBufferDSV;
    }

    /**
     * @brief Gets the CAMetalLayer used by this swap chain.
     * @return The CAMetalLayer, or nil if not available.
     */
    CAMetalLayer* GetMetalLayer() const { return m_MetalLayer; }

private:
    /**
     * @brief Configures the Metal layer with the swap chain description.
     */
    void ConfigureMetalLayer();

    /**
     * @brief Acquires the next drawable from the Metal layer.
     * @return true if a drawable was successfully acquired, false otherwise.
     */
    bool AcquireNextDrawable();

    /**
     * @brief Creates the depth-stencil buffer.
     */
    void CreateDepthBuffer();

    /**
     * @brief Updates the drawable size based on the Metal layer.
     */
    void UpdateDrawableSize();

    /**
     * @brief Releases the current drawable and back buffer.
     */
    void ReleaseCurrentDrawable();

    /// The native window
    const NativeWindow m_Window;

    /// The CAMetalLayer used for presentation
    CAMetalLayer* m_MetalLayer = nil;

    /// The current drawable from the Metal layer
    id<CAMetalDrawable> m_CurrentDrawable = nil;

    /// The back buffer render target view
    RefCntAutoPtr<ITextureViewMtl> m_pBackBufferRTV;

    /// The back buffer texture (wraps the drawable texture)
    RefCntAutoPtr<ITextureMtl> m_pBackBufferTexture;

    /// The depth-stencil buffer texture
    RefCntAutoPtr<ITextureMtl> m_pDepthBufferTexture;

    /// The depth-stencil buffer depth-stencil view
    RefCntAutoPtr<ITextureViewMtl> m_pDepthBufferDSV;

    /// VSync enabled flag
    bool m_VSyncEnabled = true;

    /// Content scale for HiDPI support
    CGFloat m_ContentScale = 1.0;

    /// Flag indicating if the swap chain has been resized
    bool m_IsResizing = false;
};

} // namespace Diligent
