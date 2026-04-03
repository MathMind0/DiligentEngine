/*
 *  Copyright 2019-2026 Diligent Graphics LLC
 *  Copyright 2026 ViBEN Contributors
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

// Stub implementation for SparseTextureManagerMtlImpl
// This file provides minimal implementations to allow compilation when the full
// implementation is disabled due to Metal API compatibility issues.

#include "pch.h"
#include "SparseTextureManagerMtlImpl.hpp"
#include "MetalDebug.h"

namespace Diligent
{

SparseTextureManagerMtlImpl::SparseTextureManagerMtlImpl()
{
}

SparseTextureManagerMtlImpl::~SparseTextureManagerMtlImpl()
{
}

MTLSize SparseTextureManagerMtlImpl::CalculateTileSize(id<MTLDevice> mtlDevice,
                                                        MTLTextureType textureType,
                                                        MTLPixelFormat pixelFormat,
                                                        NSUInteger sampleCount)
{
    // Return default tile size - sparse textures not available
    return MTLSizeMake(128, 128, 1);
}

Uint32 SparseTextureManagerMtlImpl::CalculateTileCount(const MTLSize& tileSize,
                                                        Uint32 regionWidth,
                                                        Uint32 regionHeight,
                                                        Uint32 regionDepth)
{
    if (tileSize.width == 0 || tileSize.height == 0 || tileSize.depth == 0)
        return 0;
    
    Uint32 tilesX = (regionWidth + tileSize.width - 1) / tileSize.width;
    Uint32 tilesY = (regionHeight + tileSize.height - 1) / tileSize.height;
    Uint32 tilesZ = (regionDepth + tileSize.depth - 1) / tileSize.depth;
    
    return tilesX * tilesY * tilesZ;
}

void SparseTextureManagerMtlImpl::UpdateTextureMappings(
    id<MTLCommandBuffer>              commandBuffer,
    id<MTLTexture>                    texture,
    const MTLRegion*                  regions,
    const NSUInteger*                 mipLevels,
    const NSUInteger*                 slices,
    NSUInteger                        numRegions,
    MTLSparseTextureMappingMode       mode)
{
    LOG_WARNING_MESSAGE("SparseTextureManagerMtlImpl::UpdateTextureMappings: Sparse textures are not available in this build");
}

void SparseTextureManagerMtlImpl::UpdateSingleTileMapping(
    id<MTLCommandBuffer>              commandBuffer,
    id<MTLTexture>                    texture,
    NSUInteger                        mipLevel,
    NSUInteger                        slice,
    MTLRegion                         region,
    MTLSparseTextureMappingMode       mode)
{
    LOG_WARNING_MESSAGE("SparseTextureManagerMtlImpl::UpdateSingleTileMapping: Sparse textures are not available in this build");
}

NSUInteger SparseTextureManagerMtlImpl::GetTileAlignment(id<MTLDevice> mtlDevice,
                                                          MTLTextureType textureType)
{
    // Return default alignment - sparse textures not available
    return 256;
}

void SparseTextureManagerMtlImpl::ConvertBindRangeToRegion(const SparseTextureMemoryBindRange& bindRange,
                                                            Uint32 tileWidth,
                                                            Uint32 tileHeight,
                                                            Uint32 tileDepth,
                                                            MTLRegion& outRegion)
{
    // Convert Box to MTLRegion
    // Box uses MinX/MaxX/MinY/MaxY/MinZ/MaxZ
    outRegion = MTLRegionMake3D(
        bindRange.Region.MinX / tileWidth * tileWidth,
        bindRange.Region.MinY / tileHeight * tileHeight,
        bindRange.Region.MinZ / tileDepth * tileDepth,
        ((bindRange.Region.Width() + tileWidth - 1) / tileWidth) * tileWidth,
        ((bindRange.Region.Height() + tileHeight - 1) / tileHeight) * tileHeight,
        ((bindRange.Region.Depth() + tileDepth - 1) / tileDepth) * tileDepth
    );
}

} // namespace Diligent
