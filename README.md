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
| `apple.cmake` | macOS/Homebrew path settings, Metal C++ support |
| `framework.cmake` | Apple system framework linking (200+ frameworks listed) |
| `boost.cmake` | Boost library search and linking |
| `sqlite3.cmake` | SQLite3 amalgamation auto-download and static build |
| `replxx.cmake` | replxx (readline alternative) auto-download via FetchContent |
| `llama.cmake` | llama.cpp auto-download and build via FetchContent |
| `dlib.cmake` | dlib library auto-download and build |
| `CodeGenerators.cmake` | Flex/Bison, gRPC/Protobuf, ANTLR integration |
| `install.cmake` | Installation rules for `cmake --install` |
| `packageInstall.cmake` | CMake package export for `find_package()` |

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
│   └── main.cpp                    # Sample source (compiler info, CMake definitions demo)
├── test/
│   ├── test_main.cpp               # GoogleTest sample tests
│   ├── googleTest.md               # GoogleTest usage guide
│   └── README.md                   # Test build/run instructions
└── cmake/
    ├── apple.cmake                 # macOS/Homebrew settings
    ├── appleCmake.md
    ├── boost.cmake                 # Boost integration
    ├── boostCmake.md
    ├── dlib.cmake                  # dlib integration
    ├── dlibCmake.md
    ├── framework.cmake             # Apple framework linking
    ├── frameworkCmake.md
    ├── install.cmake               # Installation rules
    ├── installCmake.md
    ├── llama.cmake                 # llama.cpp integration
    ├── llamaCmake.md
    ├── packageInstall.cmake        # CMake package export
    ├── packageInstallCmake.md
    ├── replxx.cmake                # replxx integration
    ├── replxxCmake.md
    ├── sqlite3.cmake               # SQLite3 integration
    ├── sqlite3Cmake.md
    ├── CodeGenerators.cmake        # Flex/Bison/gRPC/ANTLR
    ├── CodeGeneratorsCmake.md
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
