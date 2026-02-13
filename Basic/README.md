# CMake Template Project (macOS + Clang + C++)

A CMake template project for C++ development on macOS using the Clang compiler.
Supports modern C++ standards from C++17 onwards.

## Features

- CMake configuration optimized for macOS
- Compatible with AppleClang toolchain and Homebrew environment
- Flexible integration of libraries such as Boost, GoogleTest, and SQLite3
- Support for code generation tools including Flex/Bison, gRPC, and ANTLR

## License

MIT License - See [LICENSE.md](LICENSE.md) for details

---

## Directory Structure

```
Basic/
├── CMakeLists.txt           # Main build configuration file
├── CMAKE.md                 # Detailed usage guide for CMakeLists.txt
├── README.md                # This file
├── LICENSE.md               # License information (MIT License)
│
├── src/                     # Source code directory
│   ├── main.cpp             # Sample main file
│   └── include/             # Header files directory
│
├── test/                    # Test code directory
│   ├── test_main.cpp        # GoogleTest main file
│   ├── googleTest.md        # GoogleTest usage documentation
│   └── README.md            # Test directory description
│
├── cmake/                   # CMake extension modules & documentation
│   ├── apple.cmake              # macOS/Homebrew specific settings
│   ├── appleCmake.md            # Documentation for apple.cmake
│   ├── boost.cmake              # Boost library integration settings
│   ├── boostCmake.md            # Documentation for boost.cmake
│   ├── dlib.cmake               # dlib library integration settings
│   ├── dlibCmake.md             # Documentation for dlib.cmake
│   ├── framework.cmake          # Apple framework linking settings
│   ├── frameworkCmake.md        # Documentation for framework.cmake
│   ├── install.cmake            # Installation rule settings
│   ├── installCmake.md          # Documentation for install.cmake
│   ├── llama.cmake              # llama.cpp integration settings
│   ├── llamaCmake.md            # Documentation for llama.cmake
│   ├── packageInstall.cmake     # CMake package export settings
│   ├── packageInstallCmake.md   # Documentation for packageInstall.cmake
│   ├── replxx.cmake             # replxx library integration settings
│   ├── replxxCmake.md           # Documentation for replxx.cmake
│   ├── sqlite3.cmake            # SQLite3 integration settings
│   ├── sqlite3Cmake.md          # Documentation for sqlite3.cmake
│   ├── CodeGenerators.cmake     # Code generation tools (Flex/Bison/gRPC/ANTLR)
│   ├── CodeGeneratorsCmake.md   # Documentation for CodeGenerators.cmake
│   ├── check_all_linkable_frameworks.sh  # Framework verification script
│   └── debug.txt                # CMake variable debug output script
│
├── .gitignore               # Git exclusion settings
└── Doxyfile                 # Doxygen configuration file
```

---

## File Descriptions

### Build Configuration Files

| File | Description |
|------|-------------|
| **CMakeLists.txt** | Main CMake build configuration file. Defines build rules, compiler settings, and target definitions for the entire project |
| **CMAKE.md** | Detailed usage guide for CMakeLists.txt. Includes descriptions of build options, utility functions, and extensions |

### Source Code

| File | Description |
|------|-------------|
| **src/main.cpp** | Sample main file. Demonstrates usage of compile definitions passed from CMake, compiler info display, and C++ version detection |
| **src/include/** | Header files directory |

### Tests (test/ directory)

| File | Description |
|------|-------------|
| **test/test_main.cpp** | Main file for GoogleTest-based tests |
| **test/googleTest.md** | GoogleTest usage guide. Explains the differences between GTest::gtest, GTest::gmock targets and usage examples |
| **test/README.md** | Test directory description. Build and test execution instructions |

### Extension Modules (cmake/ directory)

Module files stored in the `cmake/` directory. They are automatically included from CMakeLists.txt. You can enable/disable features by uncommenting or deleting files as needed.

| File | Description | Include Condition |
|------|-------------|-------------------|
| **cmake/apple.cmake** | Homebrew path settings, Metal C++ support, and other macOS-specific settings | Automatic on macOS builds |
| **cmake/boost.cmake** | Boost library search and link settings. Uncomment desired components to enable | Automatic when file exists |
| **cmake/dlib.cmake** | Automatic download, build, and link settings for dlib library and pre-trained models | Automatic when file exists |
| **cmake/framework.cmake** | Link settings template for macOS system frameworks (Foundation, Metal, AppKit, etc.). Lists 200+ frameworks | Automatic on macOS builds |
| **cmake/install.cmake** | Installation rule settings template for `cmake --install` | Automatic when file exists |
| **cmake/llama.cmake** | Automatic download, build, and link settings for llama.cpp library (using FetchContent) | Automatic when file exists |
| **cmake/packageInstall.cmake** | Settings for exporting as a CMake package. Makes the project available via `find_package()` from other projects | Automatic when file exists |
| **cmake/replxx.cmake** | Automatic download, build, and link settings for replxx library (readline/libedit replacement with UTF-8 and syntax highlighting support) | Automatic when file exists |
| **cmake/sqlite3.cmake** | Downloads SQLite3 amalgamation from the official site and builds it as a static library | Automatic when file exists |
| **cmake/CodeGenerators.cmake** | Integration settings for Flex/Bison (lexical/syntactic analysis), gRPC/Protocol Buffers (RPC), and ANTLR (parser generation) | Automatic when file exists |
| **cmake/check_all_linkable_frameworks.sh** | Utility script to list linkable frameworks on macOS | — |
| **cmake/debug.txt** | CMake variable debug output script. Use `include(cmake/debug.txt)` to list CMake variables matching a specified keyword | Manual include |

### Extension Module Documentation (cmake/ directory)

Detailed documentation corresponding to each .cmake file.

| File | Description |
|------|-------------|
| **cmake/appleCmake.md** | Documentation for apple.cmake. Details on Homebrew detection and Metal C++ support |
| **cmake/boostCmake.md** | Documentation for boost.cmake. How to configure Boost components |
| **cmake/dlibCmake.md** | Documentation for dlib.cmake. Configuration for dlib library and pre-trained models |
| **cmake/frameworkCmake.md** | Documentation for framework.cmake. Apple framework link settings |
| **cmake/installCmake.md** | Documentation for install.cmake. How to configure installation rules |
| **cmake/llamaCmake.md** | Documentation for llama.cmake. How to integrate llama.cpp |
| **cmake/packageInstallCmake.md** | Documentation for packageInstall.cmake. CMake package export settings |
| **cmake/replxxCmake.md** | Documentation for replxx.cmake. How to integrate the replxx library |
| **cmake/sqlite3Cmake.md** | Documentation for sqlite3.cmake. SQLite3 amalgamation download and build method |
| **cmake/CodeGeneratorsCmake.md** | Documentation for CodeGenerators.cmake. Flex/Bison/gRPC/ANTLR integration methods |

### Documentation

| File | Description |
|------|-------------|
| **README.md** | This file. Project overview and file structure description |
| **CMAKE.md** | Detailed manual for CMakeLists.txt. Covers build options, utility functions, and usage of each .cmake file |
| **LICENSE.md** | MIT License full text |

### Other

| File | Description |
|------|-------------|
| **.gitignore** | Settings for files/directories excluded from Git management. Excludes VSCode, macOS, CMake, and Python temporary files |
| **Doxyfile** | Configuration file for Doxygen (documentation generation tool). Run `doxygen` to generate API documentation |

---

## Quick Start

### Basic Build

```bash
# Create build directory
mkdir build && cd build

# CMake configuration (Release build)
cmake ..

# Build
cmake --build .

# Run
./a.out
```

### Debug Build

```bash
cmake -DDEBUG=true ..
cmake --build .
```

### Enable Sanitizers (Memory Error Detection)

```bash
cmake -DSANI=true ..
cmake --build .
```

### Enable GoogleTest

```bash
cmake -DGTEST=true ..
cmake --build .
```

---

## Detailed Information

For detailed usage of each feature, see [CMAKE.md](CMAKE.md).

---

## Requirements

- CMake 3.20 or later
- AppleClang (Xcode Command Line Tools)
- Homebrew (optional, required when using various libraries)
