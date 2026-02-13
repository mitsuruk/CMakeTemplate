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

4. Post-Build Processing (lines 224-246)
   └─ macOS-specific diagnostic commands

5. Include Path Configuration (lines 248-267)
   └─ Header directories inside and outside the project

6. Extension Module Loading (lines 269-441)
   └─ Conditional inclusion of .cmake files

7. Utility Function Definitions (lines 289-482)
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

### 17. Post-Build Processing (lines 224-246)

```cmake
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

    add_custom_command(
        TARGET ${PROJECT_NAME}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/compile_commands.json ${CMAKE_CURRENT_SOURCE_DIR}/compile_commands.json
        COMMENT "Copying compile_commands.json to source directory"
    )
endif()
```

**Expected Behavior:**

Automatically executed after a successful build:

1. Displays the current date and time
2. Displays the working directory
3. `lipo -archs`: Displays the executable's architecture (e.g., `x86_64`, `arm64`)
4. `otool -L`: Lists the linked dynamic libraries
5. Copies `compile_commands.json` to the source directory

**Output example:**

```text
Mon, 15 Jan 2026 14:30:00 +0900
/Users/user/project/build
arm64
/Users/user/project/build/a.out:
    /usr/lib/libc++.1.dylib (compatibility version 1.0.0)
    /usr/lib/libSystem.B.dylib (compatibility version 1.0.0)
```

---

### 18. Include Path Configuration (lines 248-267)

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

### 19. Extension Module Loading (lines 269-441)

```cmake
# macOS only
if(APPLE)
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/apple.cmake)
        include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/apple.cmake)
    endif()
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/framework.cmake)
        include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/framework.cmake)
    endif()
endif()

# Common
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/install.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/install.cmake)
endif()
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/boost.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/boost.cmake)
endif()
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/CodeGenerators.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/CodeGenerators.cmake)
endif()
```

**Expected Behavior:**

| File | Condition | Functionality |
|------|-----------|---------------|
| `cmake/apple.cmake` | macOS + file exists | Homebrew configuration, Metal C++ support |
| `cmake/framework.cmake` | macOS + file exists | Apple framework linking |
| `cmake/install.cmake` | File exists | Install rules |
| `cmake/boost.cmake` | File exists | Boost library integration |
| `cmake/CodeGenerators.cmake` | File exists | Flex/Bison/gRPC/ANTLR integration |

---

### 20. GoogleTest Integration (lines 392-420)

```cmake
if(GTEST)
    find_package(GTest REQUIRED)
    target_link_libraries(
        ${PROJECT_NAME}
        PRIVATE
        GTest::gmock
        GTest::gmock_main
    )
    set_target_properties(${PROJECT_NAME} PROPERTIES COMPILE_DEFINITIONS "GTEST")
endif()
```

**Expected Behavior:**

Enabled with `cmake -DGTEST=true ..`:

1. Searches for the GoogleTest package
2. Links GoogleMock + GoogleTest
3. Defines the `GTEST` macro

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

### copy_files() (lines 303-330)

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

### find_pkg_config() (lines 338-376)

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

### link_latest_package() (lines 454-481) - macOS only

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

### apple.cmake

- Automatic detection of the Homebrew installation directory
- Addition to `CMAKE_PREFIX_PATH`
- Metal C++ header support (`/usr/local/include/metal-cpp`)

### boost.cmake

- Boost library search and linking
- Select components to use via the `BOOST_COMPONENTS` list
- Key components: `headers`, `filesystem`, `regex`, `json`, `program_options`

### framework.cmake

- Link configuration for macOS system frameworks
- Over 200 frameworks listed with comments
- Uncomment the desired frameworks to enable them

### install.cmake

- Install rules for `cmake --install`
- Configuration of install destinations for executables, headers, and documentation

### packageInstall.cmake

- Export as a CMake package
- Makes the project available to other projects via `find_package()`

### sqlite3.cmake

- Automatic download of the SQLite3 amalgamation
- Built as a static library
- Cached in `download/sqlite3/`

### CodeGenerators.cmake

- Flex/Bison: Processes `.y`/`.l` files in the `grammar/` directory
- gRPC/Protobuf: Processes `.proto` files in the `protos/` directory
- ANTLR: Processes `.g4` files in the `antlr/` directory

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
