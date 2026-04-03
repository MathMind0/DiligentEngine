/*
 *  Copyright 2019-2026 Diligent Graphics LLC
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
/// Implementation of TextureMtlImpl for Metal backend

#include "EngineMtlImplTraits.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "TextureViewMtlImpl.hpp"
#include "../../GraphicsEngine/include/TextureBase.hpp"
#include "../interface/TextureMtl.h"

#import <Metal/Metal.h>

namespace Diligent
{

class FixedBlockMemoryAllocator;

class TextureMtlImpl final : public TextureBase<EngineMtlImplTraits>
{
public:
    using TTextureBase = TextureBase<EngineMtlImplTraits>;

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_TextureMtl, TTextureBase)

    // Creates a new Metal texture
    TextureMtlImpl(IReferenceCounters*        pRefCounters,
                   FixedBlockMemoryAllocator& TexViewObjAllocator,
                   RenderDeviceMtlImpl*       pDevice,
                   const TextureDesc&         TexDesc,
                   const TextureData*         pInitData = nullptr);

    /// Creates a sparse texture backed by a Metal heap.
    TextureMtlImpl(IReferenceCounters*        pRefCounters,
                   FixedBlockMemoryAllocator& TexViewObjAllocator,
                   RenderDeviceMtlImpl*       pDevice,
                   const TextureDesc&         TexDesc,
                   DeviceMemoryMtlImpl*       pMemory) API_AVAILABLE(ios(16), macosx(11.0));

    ~TextureMtlImpl() override;

    /// Implementation of ITextureMtl::GetMtlResource()
    virtual id<MTLResource> DILIGENT_CALL_TYPE GetMtlResource() const override;

    /// Implementation of ITextureMtl::GetMtlHeap()
    virtual id<MTLHeap> DILIGENT_CALL_TYPE GetMtlHeap() const override;

    /// Implementation of ITexture::GetNativeHandle()
    virtual Uint64 DILIGENT_CALL_TYPE GetNativeHandle() override;
    
    /// Returns the Metal texture object.
    id<MTLTexture> GetMtlTexture() const { return m_mtlTexture; }
    
    /// Returns true if this is a sparse texture.
    bool IsSparse() const { return m_IsSparse; }
    
    /// Returns the sparse tile size for this texture.
    MTLSize GetSparseTileSize() const { return m_SparseTileSize; }

protected:
    /// Implementation of TextureBase::CreateViewInternal
    virtual void CreateViewInternal(const TextureViewDesc& ViewDesc,
                                    ITextureView**         ppView,
                                    bool                   bIsDefaultView) override;

private:
    /// Creates the Metal texture from a heap (for sparse textures)
    void CreateSparseTextureFromHeap(DeviceMemoryMtlImpl* pMemory) API_AVAILABLE(ios(16), macosx(11.0));

    /// The Metal texture object
    id<MTLTexture> m_mtlTexture = nil;
    
    /// The Metal heap for sparse textures (nil for non-sparse textures)
    id<MTLHeap> m_mtlHeap = nil;
    
    /// True if this is a sparse texture
    bool m_IsSparse = false;
    
    /// Sparse tile size (valid only for sparse textures)
    MTLSize m_SparseTileSize = {0, 0, 0};
};

} // namespace Diligent
