# CMakeTemplate

A collection of reusable CMake project templates for C++ development on macOS and Linux.

This repository is designed as a multi-project workspace: a top-level `CMakeLists.txt` automatically discovers and builds all subdirectory projects that contain their own `CMakeLists.txt`.

## Project Structure

```text
CMakeTemplate/
├── CMakeLists.txt          # Top-level build configuration (auto-discovers subdirectories)
├── README.md               # This file
├── .gitignore              # Shared git exclusion settings
│
├── Basic/                  # Full-featured template with extensive CMake modules
│   ├── CMakeLists.txt
│   ├── CMAKE.md
│   ├── README.md
│   ├── LICENSE.md
│   ├── Doxyfile
│   ├── .gitignore
│   ├── src/
│   ├── test/
│   └── cmake/
│
└── @small/                 # Minimal template for quick prototyping
    ├── CMakeLists.txt
    ├── .gitignore
    └── src/
```

---

## Templates

### Basic

A full-featured CMake template with extensive library integration modules and documentation. Suitable as a starting point for projects that may need external libraries, testing, or code generation tools.

**Key Features:**

- C17 / C++17 language standards
- Debug / Release / Sanitizer build configurations
- GoogleTest integration (`-DGTEST=true`)
- Automatic source file discovery (`src/` or project root)
- Post-build diagnostics (architecture, linked libraries)
- `compile_commands.json` generation for clangd
- Doxygen configuration included

**Extension Modules (`cmake/` directory):**

Each module is included by uncommenting the corresponding line in `CMakeLists.txt`. Every `.cmake` file has a companion `*Cmake.md` documentation file.

| Module | Description |
| --- | --- |
| `alglib.cmake` | ALGLIB numerical analysis library manual download and static build |
| `apple.cmake` | macOS/Homebrew path settings, Metal C++ support |
| `boost.cmake` | Boost library search and linking |
| `botan.cmake` | Botan cryptography library manual download and Python-based configure build |
| `CodeGenerators.cmake` | Flex/Bison, gRPC/Protobuf, ANTLR integration |
| `dlib.cmake` | dlib library auto-download and build |
| `Exiv2.cmake` | Exiv2 image metadata (Exif/IPTC/XMP) library via FetchContent |
| `framework.cmake` | Apple system framework linking (200+ frameworks listed) |
| `gflags.cmake` | Google commandline flags library manual download and CMake build |
| `glog.cmake` | Google logging library manual download and CMake build |
| `gmp.cmake` | GNU arbitrary precision arithmetic library manual download and autotools build |
| `gsl.cmake` | GNU Scientific Library manual download and autotools build |
| `install.cmake` | Installation rules for `cmake --install` |
| `isocline.cmake` | isocline (portable readline alternative) manual download and CMake build |
| `LibSodium.cmake` | libsodium modern cryptography library manual download and autotools build |
| `LinqForCpp.cmake` | LINQ for C++ header-only library direct download from GitHub |
| `llama.cmake` | llama.cpp auto-download and build via FetchContent |
| `mpdecimal.cmake` | mpdecimal arbitrary precision decimal arithmetic library manual download and autotools build |
| `nlohmann-json.cmake` | nlohmann/json header-only JSON library single header download |
| `openblas.cmake` | OpenBLAS optimized BLAS/LAPACK library manual download and make build |
| `packageInstall.cmake` | CMake package export for `find_package()` |
| `replxx.cmake` | replxx (readline alternative) auto-download via FetchContent |
| `sqlite3.cmake` | SQLite3 amalgamation auto-download and static build |

**Utility Functions (defined in `CMakeLists.txt`):**

| Function | Description |
|----------|-------------|
| `copy_files()` | Copy files by extension to the build directory |
| `find_pkg_config()` | pkg-config based package search and linking |
| `link_latest_package()` | Link the latest Homebrew Cellar package (macOS only) |

**Directory Layout:**

```
Basic/
├── CMakeLists.txt                  # Main build configuration
├── CMAKE.md                        # Detailed CMakeLists.txt usage guide
├── README.md                       # Template overview and quick start
├── LICENSE.md                      # MIT License
├── Doxyfile                        # Doxygen configuration
├── .gitignore                      # Git exclusion settings
├── src/
│   ├── include/                    # Header files
│   └── main.cpp                    # Sample source (compiler info, CMake definitions demo)
├── test/
│   ├── test_main.cpp               # GoogleTest sample tests
│   ├── googleTest.md               # GoogleTest usage guide
│   └── README.md                   # Test build/run instructions
├── download/                       # Downloaded library sources (auto-created)
└── cmake/
    ├── alglib.cmake                # ALGLIB numerical analysis
    ├── alglibCmake.md
    ├── apple.cmake                 # macOS/Homebrew settings
    ├── appleCmake.md
    ├── boost.cmake                 # Boost integration
    ├── boostCmake.md
    ├── botan.cmake                 # Botan cryptography
    ├── botanCmake.md
    ├── CodeGenerators.cmake        # Flex/Bison/gRPC/ANTLR
    ├── CodeGeneratorsCmake.md
    ├── dlib.cmake                  # dlib integration
    ├── dlibCmake.md
    ├── Exiv2.cmake                 # Exiv2 image metadata
    ├── Exiv2Cmake.md
    ├── framework.cmake             # Apple framework linking
    ├── frameworkCmake.md
    ├── gflags.cmake                # Google commandline flags
    ├── gflagsCmake.md
    ├── glog.cmake                  # Google logging
    ├── glogCmake.md
    ├── gmp.cmake                   # GNU arbitrary precision arithmetic
    ├── gmpCmake.md
    ├── gsl.cmake                   # GNU Scientific Library
    ├── gslCmake.md
    ├── install.cmake               # Installation rules
    ├── installCmake.md
    ├── isocline.cmake              # isocline readline alternative
    ├── isoclineCmake.md
    ├── LibSodium.cmake             # libsodium cryptography
    ├── LibSodiumCmake.md
    ├── LinqForCpp.cmake            # LINQ for C++ header-only
    ├── LinqForCppCmake.md
    ├── llama.cmake                 # llama.cpp integration
    ├── llamaCmake.md
    ├── mpdecimal.cmake             # mpdecimal decimal arithmetic
    ├── mpdecimalCmake.md
    ├── nlohmann-json.cmake         # nlohmann/json header-only
    ├── nlohmann-jsonCmake.md
    ├── openblas.cmake              # OpenBLAS BLAS/LAPACK
    ├── openblasCmake.md
    ├── packageInstall.cmake        # CMake package export
    ├── packageInstallCmake.md
    ├── replxx.cmake                # replxx integration
    ├── replxxCmake.md
    ├── sqlite3.cmake               # SQLite3 integration
    ├── sqlite3Cmake.md
    ├── JPN/                        # Japanese documentation
    ├── check_all_linkable_frameworks.sh  # Framework listing utility
    └── debug.txt                   # CMake variable debug script
```

---

### @small

A minimal template that provides only the core build configuration. Ideal for quick experiments, small utilities, or as a clean starting point without extra modules.

**Included Features:**

- Same core `CMakeLists.txt` as Basic (compiler settings, build types, diagnostics)
- GoogleTest support (`-DGTEST=true`)
- Utility functions (`copy_files()`, `find_pkg_config()`, `link_latest_package()`)
- No `cmake/` extension modules included

**What is NOT included (compared to Basic):**

- No `cmake/` directory (no extension modules)
- No `test/` directory (add as needed)
- No `LICENSE.md`, `CMAKE.md`, `Doxyfile`

**Directory Layout:**

```
@small/
├── CMakeLists.txt          # Build configuration (same core as Basic)
├── .gitignore              # Git exclusion settings
└── src/
    └── main.cpp            # Minimal sample source
```

---

## Top-Level CMakeLists.txt

The top-level `CMakeLists.txt` automatically discovers all subdirectories containing a `CMakeLists.txt` and adds them via `add_subdirectory()`. This allows multiple independent projects to coexist and build together.

```cmake
# Automatically finds and adds all subdirectories with CMakeLists.txt
function(add_subdirectories)
    file(GLOB SUBDIRS RELATIVE ${CURRENT_DIR} ${CURRENT_DIR}/*)
    foreach(SUBDIR ${SUBDIRS})
        if(IS_DIRECTORY ${CURRENT_DIR}/${SUBDIR})
            if(EXISTS ${CURRENT_DIR}/${SUBDIR}/CMakeLists.txt)
                add_subdirectory(${SUBDIR})
            endif()
        endif()
    endforeach()
endfunction()
```

When built from the top level, each subdirectory project is named `<directory_name>.out` (e.g., `Basic.out`, `@small.out`). When built individually, the project is named `a.out`.

---

## Quick Start

### Build all projects from the top level

```bash
mkdir build && cd build
cmake ..
cmake --build .
```

Executables are output to `build/bin/`.

### Build a single template individually

```bash
cd Basic
mkdir build && cd build
cmake ..
cmake --build .
./a.out
```

### Build options

| Option | Description | Example |
|--------|-------------|---------|
| `-DDEBUG=true` | Debug build (`-g -O0`) | `cmake -DDEBUG=true ..` |
| `-DSANI=true` | Enable AddressSanitizer + UBSan | `cmake -DSANI=true ..` |
| `-DGTEST=true` | Build with GoogleTest | `cmake -DGTEST=true ..` |

---

## How to Add a New Project

1. Create a new directory under `CMakeTemplate/`
2. Copy a `CMakeLists.txt` from `Basic/` or `@small/`
3. Add source files to `src/`
4. The top-level build will automatically discover and include it

---

## Requirements

- CMake 3.20 or later
- C++17 compatible compiler (AppleClang, GCC, Clang)
- Homebrew (optional, macOS only, required for some library modules)

---

## Platform Support

| Platform | Compiler | Status |
|----------|----------|--------|
| macOS | AppleClang | Primary target |
| Linux (Ubuntu) | GCC / Clang | Supported |

---

## License

- **Basic/** - MIT License (see [Basic/LICENSE.md](Basic/LICENSE.md))
- **@small/** - MIT License (see [Basic/LICENSE.md](Basic/LICENSE.md))
- **sqlite3.cmake** - Public Domain (same as SQLite)
