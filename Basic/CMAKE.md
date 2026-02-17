# CMakeLists.txt Detailed Guide

## Overview

This CMakeLists.txt is a general-purpose template for building C/C++ projects on macOS.
It requires CMake 3.20 or later and is optimized for the AppleClang compiler.

---

## File Structure and Processing Flow

```text
CMakeLists.txt processing order:

1. Initial Setup (lines 1-29)
   └─ CMake minimum version, diagnostic output, compile_commands.json generation

2. Project Definition (lines 31-84)
   └─ Project name determination, source file discovery, target creation

3. Compiler Settings (lines 86-194)
   └─ Output directories, language standards, build type, sanitizers

4. Post-Build Processing (lines 224-258)
   └─ macOS-specific diagnostics, compile_commands.json copy, clangd cache cleanup

5. Include Path Configuration (lines 260-279)
   └─ Header directories inside and outside the project

6. Extension Module Loading (lines 281-495)
   └─ Conditional inclusion of .cmake files (apple, framework active; others commented)

7. Utility Function Definitions (lines 301-537)
   └─ copy_files(), find_pkg_config(), link_latest_package()
```

---

## Detailed Section-by-Section Guide

### 1. Header and CMake Minimum Version (lines 1-11)

```cmake
cmake_minimum_required(VERSION 3.20)
```

**Expected Behavior:**

- Configuration will fail and stop if the CMake version is below 3.20
- Reason 3.20 is required: C17/C++17 support for `target_compile_features()`, extended generator expression features

---

### 2. Diagnostic Information Output (lines 13-25)

```cmake
message(STATUS "CMake version: ${CMAKE_VERSION}")

if(APPLE OR UNIX)
    execute_process(
        COMMAND date "+%Y-%m-%d %H:%M:%S"
        OUTPUT_VARIABLE LOCAL_TIME
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
endif()
message(STATUS "Local time: ${LOCAL_TIME}")
```

**Expected Behavior:**

- Displays the CMake version
- On macOS/Linux, retrieves and displays the current local time
- Embeds a timestamp in the build log to facilitate debugging

**Output example:**

```text
-- CMake version: 3.28.1
-- Local time: 2026-01-15 14:30:00
```

---

### 3. compile_commands.json Generation (lines 28-29)

```cmake
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
```

**Expected Behavior:**

- Automatically generates `compile_commands.json` in the build directory
- Used by Language Servers such as clangd and ccls for code completion and diagnostics
- Later copied to the source directory via a POST_BUILD step

---

### 4. Project Name Determination (lines 31-40)

```cmake
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    project(a.out VERSION 0.0.1)
else()
    get_filename_component(DIR_NAME ${CMAKE_CURRENT_SOURCE_DIR} NAME)
    project(${DIR_NAME}.out VERSION 0.0.1)
endif()
```

**Expected Behavior:**

| Situation | Project Name | Example |
|-----------|--------------|---------|
| Top-level project | `a.out` | Running `cmake ..` directly |
| Subdirectory | `<directory_name>.out` | When called via `add_subdirectory()`, e.g., `Basic.out` |

**Design Intent:**

- Prevents name collisions when integrating multiple projects via `add_subdirectory()`
- Automatically determines the executable name from the directory name

---

### 5. Directory Information Diagnostic Output (lines 42-50)

```cmake
message(STATUS "CMAKE_SOURCE_DIR         = ${CMAKE_SOURCE_DIR}")
message(STATUS "CMAKE_BINARY_DIR         = ${CMAKE_BINARY_DIR}")
message(STATUS "CMAKE_CURRENT_SOURCE_DIR = ${CMAKE_CURRENT_SOURCE_DIR}")
message(STATUS "CMAKE_CURRENT_BINARY_DIR = ${CMAKE_CURRENT_BINARY_DIR}")
```

**Variable Meanings:**

| Variable | Description |
|----------|-------------|
| `CMAKE_SOURCE_DIR` | Directory containing the top-level CMakeLists.txt |
| `CMAKE_BINARY_DIR` | Top-level build directory |
| `CMAKE_CURRENT_SOURCE_DIR` | Directory containing the currently processed CMakeLists.txt |
| `CMAKE_CURRENT_BINARY_DIR` | Build directory for the currently processed CMakeLists.txt |

---

### 6. Source Directory Determination (lines 53-64)

```cmake
if(NOT GTEST)
    if(EXISTS ${PROJECT_SOURCE_DIR}/src)
        set(LOCAL_SOURCE_DIR ${PROJECT_SOURCE_DIR}/src)
    else()
        set(LOCAL_SOURCE_DIR ${PROJECT_SOURCE_DIR})
    endif()
else()
    set(LOCAL_SOURCE_DIR ${PROJECT_SOURCE_DIR}/test)
endif()
```

**Expected Behavior:**

| Condition | LOCAL_SOURCE_DIR |
|-----------|------------------|
| Normal build + `src/` exists | `${PROJECT_SOURCE_DIR}/src` |
| Normal build + no `src/` | `${PROJECT_SOURCE_DIR}` (root) |
| `-DGTEST=true` | `${PROJECT_SOURCE_DIR}/test` |

**Design Intent:**

- If a `src/` directory exists, search for sources there (recommended layout)
- Otherwise, search from the project root (for simple projects)
- When GoogleTest is enabled, use the `test/` directory

---

### 7. Source File Collection (lines 66-81)

```cmake
file(GLOB SRC
    CONFIGURE_DEPENDS
    "${LOCAL_SOURCE_DIR}/*.cpp"
    "${LOCAL_SOURCE_DIR}/*.cc"
    "${LOCAL_SOURCE_DIR}/*.cxx"
    "${LOCAL_SOURCE_DIR}/*.c"
    "${LOCAL_SOURCE_DIR}/*.m"
    "${LOCAL_SOURCE_DIR}/*.mm"
)

if(NOT SRC)
    message(WARNING "No source files found in ${LOCAL_SOURCE_DIR}")
endif()
```

**Expected Behavior:**

- Automatically collects all source files in the specified directory
- `CONFIGURE_DEPENDS`: Automatically re-runs CMake when files are added or removed
- Displays a warning if no sources are found (the build continues)

**Supported File Types:**

| Extension | Language |
|-----------|----------|
| `.cpp`, `.cc`, `.cxx` | C++ |
| `.c` | C |
| `.m` | Objective-C |
| `.mm` | Objective-C++ |

---

### 8. Executable Target Creation (lines 83-84)

```cmake
add_executable(${PROJECT_NAME} ${SRC})
```

**Expected Behavior:**

- Creates an executable target named `${PROJECT_NAME}` (e.g., `a.out`)
- Registers all collected source files as compilation targets

---

### 9. Compiler Information Diagnostic Output (lines 86-94)

```cmake
message(STATUS "CMAKE_CXX_COMPILER_ID      = ${CMAKE_CXX_COMPILER_ID}")
message(STATUS "CMAKE_CXX_COMPILER_VERSION = ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "CMAKE_CXX_COMPILER         = ${CMAKE_CXX_COMPILER}")
message(STATUS "CMAKE_C_COMPILER           = ${CMAKE_C_COMPILER}")
```

**Output example (macOS):**

```text
-- CMAKE_CXX_COMPILER_ID      = AppleClang
-- CMAKE_CXX_COMPILER_VERSION = 16.0.0.16000026
-- CMAKE_CXX_COMPILER         = /usr/bin/clang++
-- CMAKE_C_COMPILER           = /usr/bin/clang
```

---

### 10. Output Directory Configuration (lines 97-127)

```cmake
if(NOT DEFINED CMAKE_RUNTIME_OUTPUT_DIRECTORY)
    set_target_properties(${PROJECT_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
endif()
```

**Expected Behavior:**

| Property | Default Value | Purpose |
|----------|---------------|---------|
| `RUNTIME_OUTPUT_DIRECTORY` | `${CMAKE_BINARY_DIR}` | Executable output location |
| `ARCHIVE_OUTPUT_DIRECTORY` | `${CMAKE_BINARY_DIR}` | Static library output location |
| `LIBRARY_OUTPUT_DIRECTORY` | `${CMAKE_BINARY_DIR}` | Shared library output location |

**Design Intent:**

- Respects the output directory if already specified by a parent project
- Otherwise, outputs directly under the build directory

---

### 11. Language Standard Configuration (lines 129-133)

```cmake
target_compile_features(${PROJECT_NAME} PRIVATE c_std_17 cxx_std_17)
```

**Expected Behavior:**

- Requires the C17 standard (equivalent to `-std=c17`)
- Requires the C++17 standard (equivalent to `-std=c++17`)
- Raises an error if the compiler does not support them

**Key features available with C++17:**

- Structured bindings (`auto [a, b] = pair;`)
- `if constexpr`
- `std::optional`, `std::variant`, `std::string_view`
- Inline variables
- Fold expressions

---

### 12. Project-Wide Compile Definitions (lines 135-144)

```cmake
target_compile_definitions(${PROJECT_NAME} PRIVATE
    PROJECT_NAME="${PROJECT_NAME}"
    PROJECT_VERSION="${PROJECT_VERSION}"
    ONE_=1
    TWO_=2
    THREE_=3
)
```

**Expected Behavior:**

The following macros are available in all source files:

```cpp
// Usage example in C++ code
std::cout << PROJECT_NAME << std::endl;    // "a.out"
std::cout << PROJECT_VERSION << std::endl; // "0.0.1"
std::cout << ONE_ + TWO_ + THREE_ << std::endl; // 6
```

---

### 13. File-Specific Compile Definitions (lines 146-163)

```cmake
set_source_files_properties(
    ${LOCAL_SOURCE_DIR}/main.cpp
    PROPERTIES COMPILE_DEFINITIONS
    "MAIN_FILE_=1;MSG1=\"MSG1\";MSG2=\"Hello\""
)
```

**Expected Behavior:**

- Defines macros that are only effective in `main.cpp`
- Not accessible from other source files

```cpp
// Available only in main.cpp
#ifdef MAIN_FILE_
    std::cout << MSG1 << std::endl;  // "MSG1"
    std::cout << MSG2 << std::endl;  // "Hello"
#endif
```

**Use Cases:**

- When different settings need to be applied per file
- Identifying the main file

---

### 14. Build Type Configuration (lines 165-191)

```cmake
if(DEBUG)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

target_compile_options(${PROJECT_NAME} PRIVATE
    $<$<CONFIG:Release>:-O2 -Wall -funroll-loops>
    $<$<CONFIG:Debug>:-g -O0 -Wall>
)

target_compile_definitions(${PROJECT_NAME}
    PRIVATE
    $<$<CONFIG:Debug>:DEBUG_BUILD>
    $<$<CONFIG:Release>:NDEBUG>
)
```

**Expected Behavior:**

| Build Type | Command | Compile Options | Defined Macros |
|------------|---------|-----------------|----------------|
| Release (default) | `cmake ..` | `-O2 -Wall -funroll-loops` | `NDEBUG` |
| Debug | `cmake -DDEBUG=true ..` | `-g -O0 -Wall` | `DEBUG_BUILD` |

**Option Descriptions:**

| Option | Description |
|--------|-------------|
| `-O2` | Optimization level 2 (speed-oriented) |
| `-O0` | No optimization (for debugging) |
| `-g` | Include debug information |
| `-Wall` | Enable common warnings |
| `-funroll-loops` | Optimization via loop unrolling |

---

### 15. Character Encoding Configuration (lines 193-194)

```cmake
target_compile_options(${PROJECT_NAME} PRIVATE -finput-charset=UTF-8 -fexec-charset=UTF-8)
```

**Expected Behavior:**

- Reads source files as UTF-8
- Treats runtime strings as UTF-8
- Correctly handles multibyte characters such as Japanese

---

### 16. Sanitizer Configuration (lines 196-222)

```cmake
if(SANI)
    target_compile_options(${PROJECT_NAME} PRIVATE
        -fsanitize=address
        -fsanitize=undefined
        -fno-omit-frame-pointer
        -fno-optimize-sibling-calls
        -g
        -O1
    )
    target_link_options(${PROJECT_NAME} PRIVATE
        -fsanitize=address
        -fsanitize=undefined
    )
endif()
```

**Expected Behavior:**

Enabled with `cmake -DSANI=true ..`:

| Sanitizer | Detection Targets |
|-----------|-------------------|
| AddressSanitizer (ASan) | Buffer overflow, use-after-free, memory leaks |
| UndefinedBehaviorSanitizer (UBSan) | Undefined behavior (integer overflow, null dereference, etc.) |

**Additional Option Descriptions:**

| Option | Description |
|--------|-------------|
| `-fno-omit-frame-pointer` | Ensures accurate stack traces |
| `-fno-optimize-sibling-calls` | Disables tail call optimization (improves trace accuracy) |
| `-O1` | Minimal optimization (for ASan compatibility) |

---

### 17. Post-Build Processing (lines 224-258)

```cmake
# macOS-specific diagnostics
if(APPLE)
    add_custom_command(
        TARGET ${PROJECT_NAME}
        POST_BUILD
        COMMAND "date" "-R"
        COMMAND "pwd"
        COMMAND "lipo" "-archs" "${BINARY_OUTPUT_DIR}/${PROJECT_NAME}"
        COMMAND "otool" "-L" "${BINARY_OUTPUT_DIR}/${PROJECT_NAME}"
        COMMENT "${PROJECT_NAME} information"
    )
endif()

# Copy compile_commands.json to source directory (all platforms)
add_custom_command(
    TARGET ${PROJECT_NAME}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/compile_commands.json ${CMAKE_CURRENT_SOURCE_DIR}/compile_commands.json
    COMMENT "Copying compile_commands.json to source directory"
)

# Remove clangd cache files (all platforms)
add_custom_command(
    TARGET ${PROJECT_NAME}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${PROJECT_SOURCE_DIR}/.cache"
)
```

**Expected Behavior:**

Automatically executed after a successful build:

1. **(macOS only)** Displays the current date and time
2. **(macOS only)** Displays the working directory
3. **(macOS only)** `lipo -archs`: Displays the executable's architecture (e.g., `x86_64`, `arm64`)
4. **(macOS only)** `otool -L`: Lists the linked dynamic libraries
5. **(All platforms)** Copies `compile_commands.json` to the source directory
6. **(All platforms)** Removes the `.cache` directory (clangd index cache) to force re-indexing

**Output example (macOS):**

```text
Mon, 15 Jan 2026 14:30:00 +0900
/Users/user/project/build
arm64
/Users/user/project/build/a.out:
    /usr/lib/libc++.1.dylib (compatibility version 1.0.0)
    /usr/lib/libSystem.B.dylib (compatibility version 1.0.0)
```

---

### 18. Include Path Configuration (lines 260-279)

```cmake
if(IS_DIRECTORY ${PROJECT_SOURCE_DIR}/src/include)
    target_include_directories(${PROJECT_NAME} PRIVATE ${PROJECT_SOURCE_DIR}/src/include)
endif()
if(IS_DIRECTORY ${PROJECT_SOURCE_DIR}/include)
    target_include_directories(${PROJECT_NAME} PRIVATE ${PROJECT_SOURCE_DIR}/include)
endif()

if(IS_DIRECTORY /usr/local/include)
    target_include_directories(${PROJECT_NAME} PRIVATE /usr/local/include)
endif()
if(IS_DIRECTORY $ENV{HOME}/include)
    target_include_directories(${PROJECT_NAME} PRIVATE $ENV{HOME}/include)
endif()
if(IS_DIRECTORY ../include)
    target_include_directories(${PROJECT_NAME} PRIVATE ../include)
endif()
```

**Expected Behavior:**

The following directories are added to the include path if they exist:

| Priority | Path | Purpose |
|----------|------|---------|
| 1 | `${PROJECT_SOURCE_DIR}/src/include` | Project-specific headers |
| 2 | `${PROJECT_SOURCE_DIR}/include` | Project-specific headers (alternative) |
| 3 | `/usr/local/include` | System-wide headers |
| 4 | `$HOME/include` | User-specific headers |
| 5 | `../include` | Shared headers in the parent directory |

---

### 19. Extension Module Loading (lines 281-495)

```cmake
# macOS only (active by default)
if(APPLE)
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/apple.cmake)
        include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/apple.cmake)
    endif()
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/framework.cmake)
        include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/framework.cmake)
    endif()
endif()

# Common (commented out by default — uncomment to enable)
# include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/install.cmake)
# include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/boost.cmake)
# include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/CodeGenerators.cmake)
# include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/sqlite3.cmake)
# include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/dlib.cmake)
```

**Expected Behavior:**

| File | Status | Condition | Functionality |
| --- | --- | --- | --- |
| `cmake/apple.cmake` | **Active** | macOS + file exists | Homebrew configuration, Metal C++ support |
| `cmake/framework.cmake` | **Active** | macOS + file exists | Apple framework linking |
| `cmake/install.cmake` | Commented | Uncomment to enable | Install rules |
| `cmake/boost.cmake` | Commented | Uncomment to enable | Boost library integration |
| `cmake/CodeGenerators.cmake` | Commented | Uncomment to enable | Flex/Bison/gRPC/ANTLR integration |
| `cmake/sqlite3.cmake` | Commented | Uncomment to enable | SQLite3 integration |
| `cmake/dlib.cmake` | Commented | Uncomment to enable | dlib integration |

**Note:** All other extension modules in the `cmake/` directory (alglib, botan, Exiv2, gflags, glog, gmp, gsl, isocline, LibSodium, LinqForCpp, llama, mpdecimal, nlohmann-json, openblas, packageInstall, replxx) can be enabled by adding an `include()` block following the same pattern.

---

### 20. GoogleTest Integration (lines 408-460)

```cmake
if(GTEST)
    find_package(GTest REQUIRED)
    enable_testing()

    target_link_libraries(
        ${PROJECT_NAME}
        PRIVATE
        GTest::gmock
        GTest::gmock_main
    )

    set_target_properties(${PROJECT_NAME} PROPERTIES COMPILE_DEFINITIONS "GTEST")

    # Register with CTest
    add_test(
        NAME ${PROJECT_NAME}_tests
        COMMAND ${PROJECT_NAME}
        WORKING_DIRECTORY ${BINARY_OUTPUT_DIR}
    )

    set_tests_properties(${PROJECT_NAME}_tests PROPERTIES
        TIMEOUT 60
        ENVIRONMENT "GTEST_COLOR=1"
    )
endif()
```

**Expected Behavior:**

Enabled with `cmake -DGTEST=true ..`:

1. Searches for the GoogleTest package
2. Enables CTest for the project
3. Links GoogleMock + GoogleTest
4. Defines the `GTEST` macro
5. Registers the executable as a CTest test with a 60-second timeout and colored output

**Running tests:**

```bash
cmake -DGTEST=true ..
cmake --build .
ctest              # or ctest --verbose
./${PROJECT_NAME}  # run directly
```

**Usage example:**

```cpp
#ifdef GTEST
#include <gtest/gtest.h>
#include <gmock/gmock.h>

TEST(MyTest, BasicAssertion) {
    EXPECT_EQ(1 + 1, 2);
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
#endif
```

---

## Utility Functions

### copy_files() (lines 301-346)

Copies files with a specified extension to the build directory.

```cmake
function(copy_files TARGET_NAME S_DIR FILE_EXT TAG_DIR)
```

**Arguments:**

| Argument | Description | Example |
|----------|-------------|---------|
| `TARGET_NAME` | Custom target name | `copy_json_files` |
| `S_DIR` | Source directory | `${CMAKE_CURRENT_SOURCE_DIR}/json` |
| `FILE_EXT` | File extension | `json` |
| `TAG_DIR` | Destination directory | `${BINARY_OUTPUT_DIR}` |

**Usage example:**

```cmake
copy_files(copy_json_files "${CMAKE_CURRENT_SOURCE_DIR}/json" "json" "${BINARY_OUTPUT_DIR}")
add_dependencies(${PROJECT_NAME} copy_json_files)
```

---

### find_pkg_config() (lines 348-392)

Searches for and links a package using pkg-config.

```cmake
function(find_pkg_config target [scope] package)
```

**Arguments:**

| Argument | Description | Example |
|----------|-------------|---------|
| `target` | Target to link to | `${PROJECT_NAME}` |
| `scope` | Link scope (optional) | `PRIVATE`, `PUBLIC`, `INTERFACE` |
| `package` | Package name | `cairo`, `gtk+-3.0` |

**Usage example:**

```cmake
find_pkg_config(${PROJECT_NAME} PRIVATE cairo)
find_pkg_config(${PROJECT_NAME} PUBLIC gtk+-3.0)
```

---

### link_latest_package() (lines 498-537) - macOS only

Manually links the latest version of a package installed via Homebrew.

```cmake
function(link_latest_package PACKAGE_NAME LIB_FILES)
```

**Arguments:**

| Argument | Description | Example |
|----------|-------------|---------|
| `PACKAGE_NAME` | Cellar directory name | `libomp`, `boost` |
| `LIB_FILES` | Library file name(s) | `libomp.dylib` |

**Usage example:**

```cmake
link_latest_package(libomp "libomp.dylib")
link_latest_package(boost "libboost_system.dylib;libboost_filesystem.dylib")
```

**Expected Behavior:**

1. Retrieves the Homebrew installation path via `brew --prefix`
2. Searches for the latest version directory under `Cellar/<PACKAGE_NAME>/`
3. Adds `include/` and `lib/` to the paths
4. Links the specified libraries

---

## Build Options

| Option | Description | Usage Example |
|--------|-------------|---------------|
| `-DDEBUG=true` | Debug build | `cmake -DDEBUG=true ..` |
| `-DSANI=true` | Enable sanitizers | `cmake -DSANI=true ..` |
| `-DGTEST=true` | Enable GoogleTest | `cmake -DGTEST=true ..` |

---

## Extension Module Details

### alglib.cmake

- ALGLIB numerical analysis library
- Manual download and static build with source compilation
- Provides numerical analysis, data processing, and optimization functions

### apple.cmake

- Automatic detection of the Homebrew installation directory
- Addition to `CMAKE_PREFIX_PATH`
- Metal C++ header support (`/usr/local/include/metal-cpp`)

### boost.cmake

- Boost library search and linking
- Select components to use via the `BOOST_COMPONENTS` list
- Key components: `headers`, `filesystem`, `regex`, `json`, `program_options`

### botan.cmake

- Botan cryptography library
- Manual download and Python-based configure build
- Provides TLS, X.509, AEAD, hashing, and other cryptographic primitives

### CodeGenerators.cmake

- Flex/Bison: Processes `.y`/`.l` files in the `grammar/` directory
- gRPC/Protobuf: Processes `.proto` files in the `protos/` directory
- ANTLR: Processes `.g4` files in the `antlr/` directory

### dlib.cmake

- dlib machine learning / computer vision library
- Auto-download and build

### Exiv2.cmake

- Exiv2 image metadata library (Exif/IPTC/XMP)
- FetchContent with install cache

### framework.cmake

- Link configuration for macOS system frameworks
- Over 200 frameworks listed with comments
- Uncomment the desired frameworks to enable them

### gflags.cmake

- Google commandline flags library
- Manual download and CMake-based build

### glog.cmake

- Google logging library
- Manual download and CMake-based build

### gmp.cmake

- GNU Multiple Precision Arithmetic Library
- Manual download and autotools-based build
- Provides arbitrary precision integer, rational, and floating-point arithmetic

### gsl.cmake

- GNU Scientific Library
- Manual download and autotools-based build
- Provides numerical routines for scientific computing

### install.cmake

- Install rules for `cmake --install`
- Configuration of install destinations for executables, headers, and documentation

### isocline.cmake

- isocline portable readline alternative
- Manual download and CMake-based build
- Provides line editing with syntax highlighting and completion

### LibSodium.cmake

- libsodium modern cryptography library
- Manual download and autotools-based build
- Provides encryption, decryption, signatures, and password hashing

### LinqForCpp.cmake

- LINQ for C++ header-only library
- Direct download from GitHub (zip)
- Provides LINQ-style query operations for C++ containers

### llama.cmake

- llama.cpp LLM inference engine
- Auto-download and build via FetchContent

### mpdecimal.cmake

- mpdecimal arbitrary precision decimal arithmetic library
- Manual download and autotools-based build

### nlohmann-json.cmake

- nlohmann/json header-only JSON library
- Single header file direct download

### openblas.cmake

- OpenBLAS optimized BLAS/LAPACK library
- Manual download and make-based build
- Provides optimized linear algebra routines

### packageInstall.cmake

- Export as a CMake package
- Makes the project available to other projects via `find_package()`

### replxx.cmake

- replxx readline alternative
- Auto-download via FetchContent
- Provides line editing with history, completion, and syntax highlighting

### sqlite3.cmake

- Automatic download of the SQLite3 amalgamation
- Built as a static library
- Cached in `download/sqlite3/`

---

## Troubleshooting

### Source files not found

```text
CMake Warning: No source files found in /path/to/project/src
```

**Solution:** Place source files such as `.cpp` in `src/` or in the project root

### Homebrew package not found

```text
FATAL_ERROR: No valid version directory in /opt/homebrew/Cellar/package
```

**Solution:** Install the package with `brew install <package_name>`

### pkg-config error

```text
Could not find a package configuration file provided by "PkgConfig"
```

**Solution:** Install pkg-config with `brew install pkg-config`

### Sanitizer linker error

```text
ld: library not found for -lasan
```

**Solution:** Sanitizers may not be available with compilers other than AppleClang

---

## Reference

- **CMake version:** 3.20 or later required
- **C standard:** C17
- **C++ standard:** C++17
- **Supported OS:** macOS (some features also work on Linux)
- **Recommended compiler:** AppleClang
- **License:** MIT License

---

## Changelog

- 2025-11-26: Initial version created
- 2026-01-15: Added detailed guide with section-by-section explanations
- 2026-02-17: Synchronized with CMakeLists.txt — updated post-build processing (clangd cache cleanup, platform-independent compile_commands.json copy), corrected extension module loading section (apple/framework active, others commented), added GoogleTest CTest registration, added 13 new extension module descriptions (alglib, botan, dlib, Exiv2, gflags, glog, gmp, gsl, isocline, LibSodium, LinqForCpp, llama, mpdecimal, nlohmann-json, openblas, replxx), updated line references throughout
