# llama.cmake Reference

## Overview

`llama.cmake` is a CMake configuration file that automatically downloads, builds, and links the llama.cpp library.
It uses CMake's `FetchContent` module to manage dependencies and automatically configures GPU acceleration (Metal/CUDA) based on the platform.

## File Information

| Item | Details |
|------|---------|
| Download Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/llama` |
| Repository | https://github.com/ggerganov/llama.cpp |

---

## Include Guard

```cmake
include_guard(GLOBAL)
```

This file uses `include_guard(GLOBAL)` to ensure it is only executed once, even if included multiple times.

**Why it's needed:**

- Prevents duplicate invocation errors from `FetchContent_MakeAvailable(llama)`
- Prevents duplicate linking in `target_link_libraries`
- Avoids duplicate build option settings

---

## Directory Structure

```

├── cmake/
│   └── llama.cmake     # This configuration file
├── download/
│   └── llama/          # llama.cpp library (GitHub: ggerganov/llama.cpp)
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## Usage

### Basic Build

```bash
mkdir build && cd build
cmake ..
make
```

GPU acceleration is auto-detected:
- macOS: Metal is automatically enabled
- Linux/Windows: CUDA is enabled if detected

---

## Processing Flow

### 1. Setting the Download Directory

```cmake
set(LLAMA_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(LLAMA_SOURCE_DIR ${LLAMA_DOWNLOAD_DIR}/llama)
set(FETCHCONTENT_BASE_DIR ${LLAMA_DOWNLOAD_DIR})
```

- Downloads source code to `download/llama/`
- Sets `FETCHCONTENT_BASE_DIR` to unify the download location

### 2. Declaring llama.cpp with FetchContent

```cmake
FetchContent_Declare(
    llama
    GIT_REPOSITORY https://github.com/ggerganov/llama.cpp.git
    GIT_SHALLOW TRUE
    SOURCE_DIR ${LLAMA_SOURCE_DIR}
)
```

- `GIT_SHALLOW TRUE` fetches only the latest commit (faster)
- `SOURCE_DIR` explicitly specifies the download location

### 3. Setting Build Options

```cmake
set(LLAMA_BUILD_COMMON ON CACHE BOOL "Build llama.cpp common library" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "Build llama.cpp examples" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "Build llama.cpp tests" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "Build llama.cpp server" FORCE)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build shared libraries" FORCE)
```

| Option | Value | Description |
|--------|-------|-------------|
| `LLAMA_BUILD_COMMON` | ON | Build the common library (utility functions) |
| `LLAMA_BUILD_EXAMPLES` | OFF | Do not build sample programs |
| `LLAMA_BUILD_TESTS` | OFF | Do not build tests |
| `LLAMA_BUILD_SERVER` | OFF | Do not build the server |
| `BUILD_SHARED_LIBS` | OFF | Build as a static library |

### 4. Automatic GPU Acceleration Configuration

```cmake
if(APPLE)
    set(GGML_METAL ON CACHE BOOL "Enable Metal" FORCE)
    set(GGML_METAL_EMBED_LIBRARY ON CACHE BOOL "Embed Metal library" FORCE)
else()
    find_package(CUDAToolkit QUIET)
    if(CUDAToolkit_FOUND)
        set(GGML_CUDA ON CACHE BOOL "Enable CUDA" FORCE)
    endif()
endif()
```

| Platform | Backend | Condition |
|----------|---------|-----------|
| macOS | Metal | Automatically enabled |
| Linux/Windows | CUDA | When CUDAToolkit is detected |
| Other | CPU | When no GPU backend is found |

**Metal Options:**
- `GGML_METAL`: Enables the Metal API
- `GGML_METAL_EMBED_LIBRARY`: Embeds Metal shaders into the executable

### 5. Download and Build

```cmake
FetchContent_MakeAvailable(llama)
```

- Downloads the source code
- Automatically runs `add_subdirectory()`
- Builds the library

### 6. Setting Include Directories

```cmake
target_include_directories(${PROJECT_NAME} PRIVATE
    ${LLAMA_SOURCE_DIR}/include
    ${LLAMA_SOURCE_DIR}/ggml/include
    ${LLAMA_SOURCE_DIR}/common
)
```

| Directory | Contents |
|-----------|----------|
| `include/` | Main headers for llama.cpp |
| `ggml/include/` | Headers for ggml (tensor computation library) |
| `common/` | Headers for utility functions |

### 7. Linking Libraries

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE
    llama
    ggml
    common
)
```

| Library | Description |
|---------|-------------|
| `llama` | Core LLM inference engine |
| `ggml` | Tensor computation and quantization library |
| `common` | Utilities for sampling, tokenizer, etc. |

---

## Linked Libraries

### llama

Provides core LLM inference functionality:
- Model loading/unloading
- Context management
- Token generation (inference)
- KV cache management

### ggml

Low-level tensor computation library:
- Quantization (Q4_0, Q4_1, Q8_0, etc.)
- Optimized matrix operations
- Metal/CUDA backends

### common

Utility functions:
- Sampling strategies (temperature, top-p, top-k)
- Log management
- Command-line argument parser

---

## Usage Example in C++

```cpp
#include "llama.h"
#include "common.h"

int main() {
    // Initialize the backend
    llama_backend_init();

    // Configure model parameters
    llama_model_params model_params = llama_model_default_params();
    model_params.n_gpu_layers = 99; // Offload all layers to GPU

    // Load the model
    llama_model* model = llama_model_load_from_file("model.gguf", model_params);
    if (!model) {
        return 1;
    }

    // Create the context
    llama_context_params ctx_params = llama_context_default_params();
    ctx_params.n_ctx = 2048;
    llama_context* ctx = llama_init_from_model(model, ctx_params);

    // ... inference processing ...

    // Cleanup
    llama_free(ctx);
    llama_model_free(model);
    llama_backend_free();

    return 0;
}
```

---

## Customizing Build Options

### Specifying the Number of GPU Layers

Additional settings can be configured in CMakeLists.txt:

```cmake
# For CUDA, specify which GPU to use
set(GGML_CUDA_DEVICE_ID 0 CACHE STRING "CUDA device ID" FORCE)

# For Metal, GPU memory limit
set(GGML_METAL_MAX_MEMORY_MB 4096 CACHE STRING "Metal max memory" FORCE)
```

### CPU Optimization

```cmake
# Enable AVX2 (x86_64)
set(GGML_AVX2 ON CACHE BOOL "Enable AVX2" FORCE)

# Enable ARM NEON (Apple Silicon/ARM)
set(GGML_NEON ON CACHE BOOL "Enable NEON" FORCE)
```

---

## Troubleshooting

### Metal Shader Not Found

```
Metal shader not found
```

Ensure that `GGML_METAL_EMBED_LIBRARY` is enabled.
This option is enabled by default.

### CUDA Not Detected

```
-- llama.cmake: No GPU backend found, using CPU only
```

Verify that CUDAToolkit is installed:
```bash
nvcc --version
```

Specify the CUDA path for CMake:
```bash
cmake -DCMAKE_CUDA_COMPILER=/usr/local/cuda/bin/nvcc ..
```

### Build Error: common Library Not Found

Ensure that `LLAMA_BUILD_COMMON` is set to `ON`.

### Out of Memory Error

When loading large models, reduce `n_gpu_layers` to distribute layers between CPU and GPU.

---

## References

- [llama.cpp GitHub](https://github.com/ggerganov/llama.cpp)
- [llama.cpp Wiki](https://github.com/ggerganov/llama.cpp/wiki)
- [ggml GitHub](https://github.com/ggerganov/ggml)
- [CMake FetchContent Documentation](https://cmake.org/cmake/help/latest/module/FetchContent.html)
