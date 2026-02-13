# =============================================================================
# llama.cpp integration for CMake
#
# This file sets up llama.cpp as a subdirectory build and links it to the target.
# llama.cpp will be automatically downloaded to ${CMAKE_CURRENT_SOURCE_DIR}/download/llama/
#
# License: MIT License
# See LICENSE.md for details.
# =============================================================================

include_guard(GLOBAL)

include(FetchContent)

set(LLAMA_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(LLAMA_SOURCE_DIR ${LLAMA_DOWNLOAD_DIR}/llama)

message(STATUS "===============================================================")
message(STATUS "llama.cmake: Setting up llama.cpp integration")
message(STATUS "LLAMA_SOURCE_DIR = ${LLAMA_SOURCE_DIR}")

set(FETCHCONTENT_BASE_DIR ${LLAMA_DOWNLOAD_DIR})

FetchContent_Declare(
    llama
    GIT_REPOSITORY https://github.com/ggerganov/llama.cpp.git
    GIT_SHALLOW TRUE
    SOURCE_DIR ${LLAMA_SOURCE_DIR}
)

# Build options for llama.cpp
set(LLAMA_BUILD_COMMON ON CACHE BOOL "Build llama.cpp common library" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "Build llama.cpp examples" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "Build llama.cpp tests" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "Build llama.cpp server" FORCE)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build shared libraries" FORCE)

# Enable GPU acceleration
if(APPLE)
    set(GGML_METAL ON CACHE BOOL "Enable Metal" FORCE)
    set(GGML_METAL_EMBED_LIBRARY ON CACHE BOOL "Embed Metal library" FORCE)
    message(STATUS "llama.cmake: Metal support enabled for macOS")
else()
    find_package(CUDAToolkit QUIET)
    if(CUDAToolkit_FOUND)
        set(GGML_CUDA ON CACHE BOOL "Enable CUDA" FORCE)
        message(STATUS "llama.cmake: CUDA support enabled")
    else()
        message(STATUS "llama.cmake: No GPU backend found, using CPU only")
    endif()
endif()

# Download and add llama.cpp as a subdirectory
FetchContent_MakeAvailable(llama)

# Include directories for llama.cpp
target_include_directories(${PROJECT_NAME} PRIVATE
    ${LLAMA_SOURCE_DIR}/include
    ${LLAMA_SOURCE_DIR}/ggml/include
    ${LLAMA_SOURCE_DIR}/common
)

# Link llama library to the target
target_link_libraries(${PROJECT_NAME} PRIVATE
    llama
    ggml
    common
)

message(STATUS "llama.cmake: llama.cpp integration complete")
message(STATUS "===============================================================")
