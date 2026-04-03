cmake_minimum_required (VERSION 3.10)

include(../../BuildTools/CMake/BuildUtils.cmake)

project(Diligent-GraphicsEngineMetal CXX)

set(INCLUDE
    include/pch.h
    include/ShaderMtlImpl.hpp
    include/ShaderResourceCacheMtl.hpp
    include/ShaderVariableManagerMtl.hpp
    include/PipelineResourceSignatureMtlImpl.hpp
    include/PipelineResourceAttribsMtl.hpp
    include/ShaderResourceBindingMtlImpl.hpp
    include/PipelineStateMtlImpl.hpp
    include/PipelineStateCacheMtlImpl.hpp
    include/FenceMtlImpl.hpp
    include/QueryMtlImpl.hpp
    include/QueryManagerMtl.hpp
    include/EngineMtlImplTraits.hpp
    include/BottomLevelASMtlImpl.hpp
    include/TopLevelASMtlImpl.hpp
    include/RasterizationRateMapMtlImpl.hpp
    include/DeviceMemoryMtlImpl.hpp
    include/TextureMtlImpl.hpp
    include/SparseTextureManagerMtlImpl.hpp
    include/ShaderBindingTableMtlImpl.hpp
)

set(INTERFACE
    interface/BottomLevelASMtl.h
    interface/BufferMtl.h
    interface/BufferViewMtl.h
    interface/CommandQueueMtl.h
    interface/DeviceContextMtl.h
    interface/DeviceMemoryMtl.h
    interface/EngineFactoryMtl.h
    interface/FenceMtl.h
    interface/PipelineStateCacheMtl.h
    interface/PipelineStateMtl.h
    interface/QueryMtl.h
    interface/RasterizationRateMapMtl.h
    interface/RenderDeviceMtl.h
    interface/SamplerMtl.h
    interface/ShaderMtl.h
    interface/ShaderResourceBindingMtl.h
    interface/SwapChainMtl.h
    interface/TextureMtl.h
    interface/TextureViewMtl.h
    interface/TopLevelASMtl.h
)

set(SRC
    src/EngineFactoryMtl.mm
    src/CommandQueueMtlImpl.mm
    src/RenderDeviceMtlImpl.mm
    src/DeviceContextMtlImpl.mm
    src/ShaderMtlImpl.mm
    src/ShaderResourceCacheMtl.mm
    src/ShaderVariableManagerMtl.mm
    src/PipelineResourceSignatureMtlImpl.mm
    src/ShaderResourceBindingMtlImpl.mm
    src/PipelineStateMtlImpl.mm
    src/PipelineStateCacheMtlImpl.mm
    src/FenceMtlImpl.mm
    src/QueryMtlImpl.mm
    src/QueryManagerMtl.mm
    src/BufferMtlImpl.mm
    src/BufferViewMtlImpl.mm
    src/SamplerMtlImpl.mm
    src/BottomLevelASMtlImpl.mm
    src/TopLevelASMtlImpl.mm
    src/RasterizationRateMapMtlImpl_Stub.mm
    src/DeviceMemoryMtlImpl.mm
    src/TextureMtlImpl.mm
    src/TextureViewMtlImpl.mm
    src/SwapChainMtlImpl.mm
    src/SparseTextureManagerMtlImpl_Stub.mm
    src/ShaderBindingTableMtlImpl.mm
    src/MetalUtilities/MetalTypeConversions.mm
    src/MetalUtilities/MetalDebug.mm
    src/MetalUtilities/MetalMemoryManager.mm
    src/MetalUtilities/MetalCommandBuffer.mm
)

set(DLL_SOURCE
    src/DLLMain.cpp
    src/GraphicsEngineMtl.def
)

add_library(Diligent-GraphicsEngineMetalInterface INTERFACE)
target_link_libraries     (Diligent-GraphicsEngineMetalInterface INTERFACE Diligent-GraphicsEngineInterface)
target_include_directories(Diligent-GraphicsEngineMetalInterface INTERFACE interface)


add_library(Diligent-GraphicsEngineMetal-static STATIC
    ${SRC} ${INTERFACE} ${INCLUDE}
    readme.md
)

target_include_directories(Diligent-GraphicsEngineMetal-static
PRIVATE
    include
    ${CMAKE_CURRENT_SOURCE_DIR}/../../ThirdParty/SPIRV-Cross
)

set(PRIVATE_DEPENDENCIES
    Diligent-BuildSettings
    Diligent-Common
    Diligent-TargetPlatform
    Diligent-GraphicsEngineNextGenBase
    Diligent-ShaderTools
    spirv-cross-core
    spirv-cross-msl
)

set(PUBLIC_DEPENDENCIES
    Diligent-GraphicsEngineMetalInterface
)

# Link Apple frameworks
if(PLATFORM_MACOS)
    find_library(METAL_LIBRARY Metal REQUIRED)
    find_library(QUARTZ_CORE QuartzCore REQUIRED)
    find_library(APP_KIT AppKit REQUIRED)
    list(APPEND PRIVATE_DEPENDENCIES ${METAL_LIBRARY} ${QUARTZ_CORE} ${APP_KIT})
elseif(PLATFORM_IOS)
    find_library(METAL_LIBRARY Metal REQUIRED)
    find_library(QUARTZ_CORE QuartzCore REQUIRED)
    find_library(UI_KIT UIKit REQUIRED)
    list(APPEND PRIVATE_DEPENDENCIES ${METAL_LIBRARY} ${QUARTZ_CORE} ${UI_KIT})
endif()

target_link_libraries(Diligent-GraphicsEngineMetal-static
PRIVATE
    ${PRIVATE_DEPENDENCIES}
PUBLIC
    ${PUBLIC_DEPENDENCIES}
)

# Objective-C++ compilation flags - CMake auto-detects .mm files as Objective-C++
target_compile_options(Diligent-GraphicsEngineMetal-static PRIVATE
    -x objective-c++
    -fobjc-arc
    -Wno-unguarded-availability-new
)

target_compile_definitions(Diligent-GraphicsEngineMetal-static
PRIVATE
    METAL_SUPPORTED=1
)

set_common_target_properties(Diligent-GraphicsEngineMetal-static)

source_group("src" FILES ${SRC})
source_group("include" FILES ${INCLUDE})
source_group("interface" FILES ${INTERFACE})

set_target_properties(Diligent-GraphicsEngineMetal-static PROPERTIES
    FOLDER DiligentCore/Graphics
)

set_source_files_properties(
    readme.md PROPERTIES HEADER_FILE_ONLY TRUE
)

if(DILIGENT_INSTALL_CORE)
    install_core_lib(Diligent-GraphicsEngineMetal-static)
endif()
