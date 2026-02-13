# dlib.cmake Documentation

## Overview

`dlib.cmake` is a CMake configuration file that handles automatic downloading, building, and linking of the dlib library and pre-trained models.
It uses CMake's `FetchContent` module to manage dependencies.

## File Information

| Item | Content |
|------|---------|
| Project | CMake Template Project |
| Author | mitsuruk |
| Created | 2025/11/26 |
| License | MIT License |

---

## Include Guard

```cmake
include_guard(GLOBAL)
```

This file uses `include_guard(GLOBAL)` to ensure it is only executed once even if included multiple times.

**Why it's needed:**

- Prevents duplicate call errors from `add_subdirectory(dlib)`
- Avoids duplicate execution of FetchContent processing
- Prevents duplicate linking via `target_link_libraries`
- Avoids duplicate extraction of model files

---

## Directory Structure

```text
Basic/
├── cmake/
│   └── dlib.cmake      # This configuration file
├── download/
│   ├── dlib/           # dlib library itself (GitHub: davisking/dlib)
│   └── dlib-models/    # Pre-trained models (GitHub: davisking/dlib-models)
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## Usage

### Basic Build (without models)

```bash
cd build
cmake ..
make
```

### Build with Pre-trained Models

```bash
cd build
cmake -DDLIB_DOWNLOAD_MODELS=ON ..
make
```

## CMake Options

| Option | Default | Description |
|--------|---------|-------------|
| `DLIB_DOWNLOAD_MODELS` | OFF | Download and extract pre-trained models |

## Processing Flow

### 1. Downloading the dlib Library (FetchContent)

```cmake
include(FetchContent)

FetchContent_Declare(
    dlib
    GIT_REPOSITORY https://github.com/davisking/dlib.git
    GIT_TAG        master
    GIT_SHALLOW    TRUE
    SOURCE_DIR     ${DLIB_DIR}
)

FetchContent_GetProperties(dlib)
if(NOT dlib_POPULATED)
    FetchContent_Populate(dlib)
endif()
```

- Uses the `FetchContent` module to automatically download from GitHub
- `GIT_SHALLOW TRUE` fetches only the latest commit (for faster downloads)
- `SOURCE_DIR` specifies the download destination as `download/dlib/`
- Skipped if already downloaded

### 2. Downloading Pre-trained Models

Executed only when `-DDLIB_DOWNLOAD_MODELS=ON` is specified:

```cmake
FetchContent_Declare(
    dlib-models
    GIT_REPOSITORY https://github.com/davisking/dlib-models.git
    GIT_TAG        master
    GIT_SHALLOW    TRUE
    SOURCE_DIR     ${DLIB_MODELS_DIR}
)

FetchContent_GetProperties(dlib-models)
if(NOT dlib-models_POPULATED)
    FetchContent_Populate(dlib-models)
endif()
```

### 3. Extracting Model Files

Downloaded `.bz2` files are extracted using `bunzip2`:

```cmake
foreach(MODEL_FILE ${DLIB_MODEL_FILES})
    if(EXISTS ${MODEL_PATH} AND NOT EXISTS ${EXTRACTED_PATH})
        execute_process(
            COMMAND ${BUNZIP2_EXECUTABLE} -k ${MODEL_PATH}
            ...
        )
    endif()
endforeach()
```

- The `-k` option preserves the original `.bz2` files
- Already extracted files are skipped

### 4. dlib Library Build Configuration

```cmake
# Disable X11/GUI support
set(DLIB_NO_GUI_SUPPORT ON CACHE BOOL "Disable dlib GUI support" FORCE)

# Add dlib as a subdirectory
add_subdirectory(${dlib_SOURCE_DIR}/dlib dlib_build)

# Link to the project
target_link_libraries(${PROJECT_NAME} PRIVATE dlib::dlib)
```

### 5. Model Path Compile Definition

```cmake
if(DLIB_DOWNLOAD_MODELS AND EXISTS ${DLIB_MODELS_DIR})
    target_compile_definitions(${PROJECT_NAME} PRIVATE
        DLIB_MODELS_PATH="${DLIB_MODELS_DIR}"
    )
endif()
```

The model directory can be referenced from C++ code via the `DLIB_MODELS_PATH` macro.

## About FetchContent

### Advantages

- **CMake-native**: Minimal dependency on external tools
- **Caching**: Efficient during rebuilds
- **Dependency management**: Manages dependencies using CMake's standard approach
- **Portability**: Expected to behave consistently across different environments

### Key Functions

| Function | Description |
|----------|-------------|
| `FetchContent_Declare()` | Declares the download source |
| `FetchContent_GetProperties()` | Retrieves download status |
| `FetchContent_Populate()` | Performs the actual download |
| `FetchContent_MakeAvailable()` | Populate + add_subdirectory (not used here) |

### Important Notes

- When using `GIT_REPOSITORY`, Git must be installed on the system
- If `SOURCE_DIR` is not specified, files are downloaded to `_deps/<name>-src`

## Available Pre-trained Models

### Face Recognition

| File Name | Description |
|-----------|-------------|
| `dlib_face_recognition_resnet_model_v1.dat` | ResNet-based face recognition (128-dimensional feature vectors) |
| `face_recognition_densenet_model_v1.dat` | DenseNet-based face recognition (lightweight version) |
| `taguchi_face_recognition_resnet_model_v1.dat` | Face recognition optimized for Asian faces |

### Face Detection and Landmarks

| File Name | Description |
|-----------|-------------|
| `mmod_human_face_detector.dat` | CNN face detector |
| `shape_predictor_5_face_landmarks.dat` | 5-point landmarks (lightweight version) |
| `shape_predictor_68_face_landmarks.dat` | 68-point landmarks (standard) |
| `shape_predictor_68_face_landmarks_GTX.dat` | 68-point landmarks (high-accuracy version) |

### Vehicle Detection

| File Name | Description |
|-----------|-------------|
| `mmod_rear_end_vehicle_detector.dat` | Vehicle rear-end detection |
| `mmod_front_and_rear_end_vehicle_detector.dat` | Vehicle front and rear-end detection |

### Image Classification

| File Name | Description |
|-----------|-------------|
| `resnet34_1000_imagenet_classifier.dnn` | ResNet34 ImageNet classifier |
| `resnet50_1000_imagenet_classifier.dnn` | ResNet50 ImageNet classifier |
| `resnet34_stable_imagenet_1k.dat` | ResNet34 stable version |
| `vit-s-16_stable_imagenet_1k.dat` | Vision Transformer (ViT-S-16) |

### Others

| File Name | Description |
|-----------|-------------|
| `mmod_dog_hipsterizer.dat` | Dog detection |
| `dnn_gender_classifier_v1.dat` | Gender estimation |
| `dnn_age_predictor_v1.dat` | Age estimation |
| `dcgan_162x162_synth_faces.dnn` | Face image generation (DCGAN) |
| `res50_self_supervised_cifar_10.dat` | Self-supervised learning |
| `highres_colorify.dnn` | Image colorization |

## Example Model Usage in C++ Code

```cpp
#include <dlib/dnn.h>
#include <dlib/image_processing/frontal_face_detector.h>
#include <dlib/image_processing.h>

int main() {
#ifdef DLIB_MODELS_PATH
    // Build model path
    std::string models_dir = DLIB_MODELS_PATH;

    // Load face landmark detector
    dlib::shape_predictor sp;
    dlib::deserialize(models_dir + "/shape_predictor_68_face_landmarks.dat") >> sp;

    // Load face recognition model
    // ...
#else
    #error "DLIB_MODELS_PATH is not defined. Build with -DDLIB_DOWNLOAD_MODELS=ON"
#endif
    return 0;
}
```

## Build Option Details

### DLIB_NO_GUI_SUPPORT

```cmake
set(DLIB_NO_GUI_SUPPORT ON CACHE BOOL "Disable dlib GUI support" FORCE)
```

- Disables X11/X Window System support
- Intended for server environments and headless environments without a GUI
- Reduces the number of libraries to link

## Troubleshooting

### bunzip2 not found

```text
-- WARNING: bunzip2 not found. Cannot extract model files.
```

On macOS:
```bash
brew install bzip2
```

### Git not found

```text
-- Could not find Git
```

Git is required when using `GIT_REPOSITORY` with FetchContent.
Please install Git.

### Model download is slow

The `dlib-models` repository is large (several GB), so downloading takes time.
Please run on a stable network connection.

### FetchContent fails

Your CMake version may be outdated. CMake 3.11 or higher is required.

```bash
cmake --version
```

## Reference Links

- [dlib Official Site](http://dlib.net/)
- [dlib GitHub](https://github.com/davisking/dlib)
- [dlib-models GitHub](https://github.com/davisking/dlib-models)
- [dlib Official Model Files](http://dlib.net/files/)
- [CMake FetchContent Documentation](https://cmake.org/cmake/help/latest/module/FetchContent.html)
