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
#include "BottomLevelASMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "MetalDebug.h"
#include "GraphicsAccessories.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

BottomLevelASMtlImpl::BottomLevelASMtlImpl(IReferenceCounters*      pRefCounters,
                                           RenderDeviceMtlImpl*     pDevice,
                                           const BottomLevelASDesc& Desc) :
    TBottomLevelASBase{pRefCounters, pDevice, Desc}
{
    // Check if ray tracing is supported on this device
    id<MTLDevice> mtlDevice = pDevice->GetMtlDevice();
    
    if (@available(iOS 14, macOS 11.0, *))
    {
        if (![mtlDevice supportsRaytracing])
        {
            LOG_ERROR_AND_THROW("Ray tracing is not supported on this device. BLAS '", 
                               (Desc.Name ? Desc.Name : "<unnamed>"), 
                               "' cannot be created.");
            return;
        }
        
        MTLAccelerationStructureSizes accelStructSizes = {0, 0, 0};
        
        if (Desc.CompactedSize > 0)
        {
            // Use precomputed size
            accelStructSizes.accelerationStructureSize = Desc.CompactedSize;
            accelStructSizes.buildScratchBufferSize = 0;
            accelStructSizes.refitScratchBufferSize = 0;
        }
        else
        {
            // Create geometry descriptors based on Desc
            NSMutableArray* geometryDescriptors = 
                [NSMutableArray arrayWithCapacity:Desc.TriangleCount + Desc.BoxCount];
            
            if (Desc.pTriangles != nullptr && Desc.TriangleCount > 0)
            {
                for (Uint32 i = 0; i < Desc.TriangleCount; ++i)
                {
                    const BLASTriangleDesc& triDesc = Desc.pTriangles[i];
                    
                    // Create triangle geometry descriptor
                    MTLAccelerationStructureTriangleGeometryDescriptor* triGeomDesc = 
                        [MTLAccelerationStructureTriangleGeometryDescriptor descriptor];
                    
                    // Vertex buffer will be set during build
                    triGeomDesc.vertexBuffer = nil;
                    triGeomDesc.vertexBufferOffset = 0;
                    triGeomDesc.vertexStride = triDesc.VertexComponentCount * sizeof(float);
                    
                    // Set vertex format - Metal uses MTLAttributeFormat for ray tracing
                    triGeomDesc.vertexFormat = MTLAttributeFormatFloat3;
                    
                    // Index buffer will be set during build
                    triGeomDesc.indexBuffer = nil;
                    triGeomDesc.indexBufferOffset = 0;
                    
                    // Set index type based on IndexType
                    switch (triDesc.IndexType)
                    {
                        case VT_UINT16:
                            triGeomDesc.indexType = MTLIndexTypeUInt16;
                            break;
                        case VT_UINT32:
                            triGeomDesc.indexType = MTLIndexTypeUInt32;
                            break;
                        default:
                            triGeomDesc.indexType = MTLIndexTypeUInt32;
                            break;
                    }
                    
                    triGeomDesc.triangleCount = triDesc.MaxPrimitiveCount;
                    
                    // Transform buffer (optional, for transform data)
                    if (triDesc.AllowsTransforms)
                    {
                        triGeomDesc.transformationMatrixBuffer = nil;
                        triGeomDesc.transformationMatrixBufferOffset = 0;
                    }
                    
                    [geometryDescriptors addObject:triGeomDesc];
                }
            }
            
            if (Desc.pBoxes != nullptr && Desc.BoxCount > 0)
            {
                for (Uint32 i = 0; i < Desc.BoxCount; ++i)
                {
                    const BLASBoundingBoxDesc& boxDesc = Desc.pBoxes[i];
                    
                    // Create bounding box geometry descriptor
                    MTLAccelerationStructureBoundingBoxGeometryDescriptor* boxGeomDesc = 
                        [MTLAccelerationStructureBoundingBoxGeometryDescriptor descriptor];
                    
                    // Bounding box buffer will be set during build
                    boxGeomDesc.boundingBoxBuffer = nil;
                    boxGeomDesc.boundingBoxBufferOffset = 0;
                    boxGeomDesc.boundingBoxStride = sizeof(float) * 6; // min.xyz, max.xyz
                    boxGeomDesc.boundingBoxCount = boxDesc.MaxBoxCount;
                    
                    [geometryDescriptors addObject:boxGeomDesc];
                }
            }
            
            if (geometryDescriptors.count == 0)
            {
                LOG_ERROR_AND_THROW("BLAS must have at least one geometry descriptor");
            }
            
            // Create primitive acceleration structure descriptor
            MTLPrimitiveAccelerationStructureDescriptor* accelStructDesc = 
                [MTLPrimitiveAccelerationStructureDescriptor descriptor];
            accelStructDesc.geometryDescriptors = geometryDescriptors;
            
            // Set build flags
            MTLAccelerationStructureUsage usage = 0;
            if (Desc.Flags & RAYTRACING_BUILD_AS_PREFER_FAST_TRACE)
                usage |= MTLAccelerationStructureUsageRefit;
            if (Desc.Flags & RAYTRACING_BUILD_AS_ALLOW_UPDATE)
                usage |= MTLAccelerationStructureUsageRefit;
            accelStructDesc.usage = usage;
            
            // Query sizes
            accelStructSizes = [mtlDevice accelerationStructureSizesWithDescriptor:accelStructDesc];
        }
        
        // Allocate Metal buffer for acceleration structure storage
        m_mtlBuffer = [mtlDevice newBufferWithLength:accelStructSizes.accelerationStructureSize
                                             options:MTLResourceStorageModePrivate];
        if (m_mtlBuffer == nil)
        {
            LOG_ERROR_AND_THROW("Failed to allocate Metal buffer for BLAS '",
                               (Desc.Name ? Desc.Name : "<unnamed>"), "'");
        }
        
        // Set debug label
        if (Desc.Name != nullptr)
        {
            m_mtlBuffer.label = [NSString stringWithUTF8String:Desc.Name];
        }
        
        // Create the acceleration structure with size
        m_mtlAccelerationStructure = [mtlDevice newAccelerationStructureWithSize:accelStructSizes.accelerationStructureSize];
        if (m_mtlAccelerationStructure == nil)
        {
            LOG_ERROR_AND_THROW("Failed to create Metal acceleration structure for BLAS '",
                               (Desc.Name ? Desc.Name : "<unnamed>"), "'");
        }
        
        // Store scratch buffer sizes
        m_ScratchSize.Build = accelStructSizes.buildScratchBufferSize;
        m_ScratchSize.Update = accelStructSizes.refitScratchBufferSize;
        
        // Set initial resource state
        SetState(RESOURCE_STATE_BUILD_AS_READ);
        
        LOG_INFO_MESSAGE("Created Metal BLAS '", (Desc.Name ? Desc.Name : "<unnamed>"),
                        "' with size ", accelStructSizes.accelerationStructureSize,
                        " bytes, scratch size ", m_ScratchSize.Build, " bytes");
    }
    else
    {
        LOG_ERROR_AND_THROW("Ray tracing requires iOS 14+ or macOS 11.0+. BLAS '",
                           (Desc.Name ? Desc.Name : "<unnamed>"), "' cannot be created.");
    }
}

BottomLevelASMtlImpl::BottomLevelASMtlImpl(IReferenceCounters*          pRefCounters,
                                           RenderDeviceMtlImpl*         pDevice,
                                           const BottomLevelASDesc&     Desc,
                                           RESOURCE_STATE               InitialState,
                                           id<MTLAccelerationStructure> mtlBLAS) API_AVAILABLE(ios(14), macosx(11.0)) :
    TBottomLevelASBase{pRefCounters, pDevice, Desc}
{
    if (mtlBLAS == nil)
    {
        LOG_ERROR_AND_THROW("Cannot create BLAS from null Metal acceleration structure");
    }
    
    m_mtlAccelerationStructure = mtlBLAS;
    
    // Note: When wrapping an existing acceleration structure, we don't own the backing buffer
    // The scratch sizes are unknown in this case and should be queried separately if needed
    m_ScratchSize.Build = 0;
    m_ScratchSize.Update = 0;
    
    SetState(InitialState);
    
    LOG_INFO_MESSAGE("Created Metal BLAS '", (Desc.Name ? Desc.Name : "<unnamed>"),
                    "' from existing Metal acceleration structure");
}

BottomLevelASMtlImpl::~BottomLevelASMtlImpl()
{
    // Metal acceleration structures are reference-counted by ARC
    // The backing buffer is released when the acceleration structure is released
    
    // Destructors of base classes will handle cleanup
    LOG_INFO_MESSAGE("Destroyed Metal BLAS '", 
                    (m_Desc.Name ? m_Desc.Name : "<unnamed>"), "'");
}

} // namespace Diligent