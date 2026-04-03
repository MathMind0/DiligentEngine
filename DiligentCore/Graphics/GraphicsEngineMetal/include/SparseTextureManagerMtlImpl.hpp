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
/// Sparse texture tile manager for Metal backend

#include "EngineMtlImplTraits.hpp"
#include "DeviceMemoryMtlImpl.hpp"
#include "../../GraphicsEngine/interface/Texture.h"
#include "../../GraphicsEngine/interface/DeviceContext.h"

#import <Metal/Metal.h>

namespace Diligent
{

/// Manages sparse texture tile mappings for Metal backend.
///
/// This class handles:
/// - Tracking which tiles are mapped/unmapped
/// - Mapping tiles to heap memory
/// - Unmapping tiles to free heap memory
/// - Tile alignment and size calculations
class SparseTextureManagerMtlImpl
{
public:
    SparseTextureManagerMtlImpl();
    ~SparseTextureManagerMtlImpl();

    /// Calculates the sparse tile size for a given texture format.
    ///
    /// \param mtlDevice     - The Metal device.
    /// \param textureType   - The texture type (2D, 3D, etc.).
    /// \param pixelFormat   - The pixel format.
    /// \param sampleCount   - The sample count.
    /// \return The tile size in bytes.
    static MTLSize CalculateTileSize(id<MTLDevice> mtlDevice,
                                      MTLTextureType textureType,
                                      MTLPixelFormat pixelFormat,
                                      NSUInteger sampleCount) API_AVAILABLE(ios(16), macosx(11.0));

    /// Calculates the number of tiles for a given texture region.
    ///
    /// \param tileSize    - The tile size.
    /// \param regionWidth - Region width in pixels.
    /// \param regionHeight - Region height in pixels.
    /// \param regionDepth - Region depth in pixels.
    /// \return The number of tiles.
    static Uint32 CalculateTileCount(const MTLSize& tileSize,
                                      Uint32 regionWidth,
                                      Uint32 regionHeight,
                                      Uint32 regionDepth);

    /// Maps texture tiles to heap memory.
    ///
    /// \param commandBuffer      - The Metal command buffer.
    /// \param texture            - The Metal texture to map.
    /// \param regions            - Array of regions to map.
    /// \param mipLevels          - Array of mip levels for each region.
    /// \param slices             - Array of array slices for each region.
    /// \param numRegions         - Number of regions.
    /// \param mode               - Map or unmap mode.
    static void UpdateTextureMappings(
        id<MTLCommandBuffer>              commandBuffer,
        id<MTLTexture>                    texture,
        const MTLRegion*                  regions,
        const NSUInteger*                 mipLevels,
        const NSUInteger*                 slices,
        NSUInteger                        numRegions,
        MTLSparseTextureMappingMode       mode) API_AVAILABLE(ios(16), macosx(11.0));

    /// Maps a single tile region.
    ///
    /// \param commandBuffer - The Metal command buffer.
    /// \param texture       - The Metal texture.
    /// \param mipLevel      - The mip level.
    /// \param slice         - The array slice.
    /// \param region        - The region in pixels.
    /// \param mode          - Map or unmap mode.
    static void UpdateSingleTileMapping(
        id<MTLCommandBuffer>              commandBuffer,
        id<MTLTexture>                    texture,
        NSUInteger                        mipLevel,
        NSUInteger                        slice,
        MTLRegion                         region,
        MTLSparseTextureMappingMode       mode) API_AVAILABLE(ios(16), macosx(11.0));

    /// Gets the tile alignment for a texture.
    ///
    /// \param mtlDevice   - The Metal device.
    /// \param textureType - The texture type.
    /// \return The tile alignment in bytes.
    static NSUInteger GetTileAlignment(id<MTLDevice> mtlDevice,
                                        MTLTextureType textureType) API_AVAILABLE(ios(16), macosx(11.0));

    /// Converts a Diligent sparse texture bind range to Metal regions.
    ///
    /// \param bindRange       - The Diligent bind range.
    /// \param tileWidth       - Tile width in pixels.
    /// \param tileHeight      - Tile height in pixels.
    /// \param tileDepth       - Tile depth in pixels.
    /// \param[out] outRegion  - The output Metal region.
    static void ConvertBindRangeToRegion(const SparseTextureMemoryBindRange& bindRange,
                                          Uint32 tileWidth,
                                          Uint32 tileHeight,
                                          Uint32 tileDepth,
                                          MTLRegion& outRegion);
};

} // namespace Diligent
