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

#include "pch.h"
#include "SparseTextureManagerMtlImpl.hpp"
#include "MetalDebug.h"
#include "GraphicsAccessories.hpp"

#import <Metal/Metal.h>

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
                                                        NSUInteger sampleCount) API_AVAILABLE(ios(16), macosx(11.0))
{
    if ([mtlDevice supportsSparseTextures])
    {
        return [mtlDevice sparseTileSizeWithTextureType:textureType
                                            pixelFormat:pixelFormat
                                           sampleCount:sampleCount];
    }
    
    // Return default tile size if sparse textures are not supported
    return MTLSizeMake(128, 128, 1);
}

Uint32 SparseTextureManagerMtlImpl::CalculateTileCount(const MTLSize& tileSize,
                                                        Uint32 regionWidth,
                                                        Uint32 regionHeight,
                                                        Uint32 regionDepth)
{
    Uint32 tilesX = (regionWidth + static_cast<Uint32>(tileSize.width) - 1) / static_cast<Uint32>(tileSize.width);
    Uint32 tilesY = (regionHeight + static_cast<Uint32>(tileSize.height) - 1) / static_cast<Uint32>(tileSize.height);
    Uint32 tilesZ = (regionDepth + static_cast<Uint32>(tileSize.depth) - 1) / static_cast<Uint32>(tileSize.depth);
    
    return tilesX * tilesY * tilesZ;
}

void SparseTextureManagerMtlImpl::UpdateTextureMappings(
    id<MTLCommandBuffer>              commandBuffer,
    id<MTLTexture>                    texture,
    const MTLRegion*                  regions,
    const NSUInteger*                 mipLevels,
    const NSUInteger*                 slices,
    NSUInteger                        numRegions,
    MTLSparseTextureMappingMode       mode) API_AVAILABLE(ios(16), macosx(11.0))
{
    if (numRegions == 0 || regions == nullptr)
    {
        LOG_WARNING_MESSAGE("UpdateTextureMappings called with no regions");
        return;
    }
    
    // Create resource state command encoder for sparse texture mapping
    id<MTLResourceStateCommandEncoder> encoder = [commandBuffer resourceStateCommandEncoder];
    if (encoder == nil)
    {
        LOG_ERROR_MESSAGE("Failed to create resource state command encoder for sparse texture mapping");
        return;
    }
    
    // Update texture mappings
    [encoder updateTextureMappings:texture
                              mode:mode
                           regions:regions
                         mipLevels:mipLevels
                            slices:slices
                        numRegions:numRegions];
    
    [encoder endEncoding];
}

void SparseTextureManagerMtlImpl::UpdateSingleTileMapping(
    id<MTLCommandBuffer>              commandBuffer,
    id<MTLTexture>                    texture,
    NSUInteger                        mipLevel,
    NSUInteger                        slice,
    MTLRegion                         region,
    MTLSparseTextureMappingMode       mode) API_AVAILABLE(ios(16), macosx(11.0))
{
    UpdateTextureMappings(commandBuffer, texture, &region, &mipLevel, &slice, 1, mode);
}

NSUInteger SparseTextureManagerMtlImpl::GetTileAlignment(id<MTLDevice> mtlDevice,
                                                          MTLTextureType textureType) API_AVAILABLE(ios(16), macosx(11.0))
{
    // Metal sparse textures have alignment requirements based on tile size
    // The tile size is typically 128x128 for 2D textures
    if ([mtlDevice supportsSparseTextures])
    {
        // Return the sparse tile size in bytes
        // This varies by texture type and pixel format
        // For simplicity, we return a common alignment
        return 64 * 1024; // 64KB is common for many GPUs
    }
    return 64 * 1024; // Default 64KB alignment
}

void SparseTextureManagerMtlImpl::ConvertBindRangeToRegion(const SparseTextureMemoryBindRange& bindRange,
                                                            Uint32 tileWidth,
                                                            Uint32 tileHeight,
                                                            Uint32 tileDepth,
                                                            MTLRegion& outRegion)
{
    // Convert the Diligent Box region to MTLRegion
    // The Region must be aligned to tile boundaries
    outRegion.origin.x = (bindRange.Region.MinX / tileWidth) * tileWidth;
    outRegion.origin.y = (bindRange.Region.MinY / tileHeight) * tileHeight;
    outRegion.origin.z = (bindRange.Region.MinZ / tileDepth) * tileDepth;
    
    // Calculate region size (rounded up to tile boundaries)
    Uint32 width = bindRange.Region.MaxX - bindRange.Region.MinX;
    Uint32 height = bindRange.Region.MaxY - bindRange.Region.MinY;
    Uint32 depth = bindRange.Region.MaxZ - bindRange.Region.MinZ;
    
    outRegion.size.width = ((width + tileWidth - 1) / tileWidth) * tileWidth;
    outRegion.size.height = ((height + tileHeight - 1) / tileHeight) * tileHeight;
    outRegion.size.depth = ((depth + tileDepth - 1) / tileDepth) * tileDepth;
}

} // namespace Diligent
