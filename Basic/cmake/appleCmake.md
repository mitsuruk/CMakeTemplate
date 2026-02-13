# apple.cmake Documentation

## Overview

`apple.cmake` is a CMake configuration file for macOS environments. It provides detection and configuration of the Homebrew package manager, as well as support for Apple Metal C++.

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

- Prevents duplicate calls to `target_include_directories`
- Prevents duplicate additions to `CMAKE_PREFIX_PATH`
- Avoids duplicate output of configuration messages

---

## Feature Details

### 1. Display Default macOS Framework Paths

```cmake
message(STATUS "Default macOS Framework Paths:")
message(STATUS "  /System/Library/Frameworks")
message(STATUS "  /Library/Frameworks")
```

Displays the default framework search paths on macOS. This is used for debugging and informational purposes.

---

### 2. Homebrew Detection and Configuration

#### 2.1 Searching for the brew Command

```cmake
find_program(BREW_COMMAND brew)
```

Checks whether the `brew` command exists on the system.

#### 2.2 Retrieving and Configuring the Homebrew Directory

```cmake
execute_process(COMMAND brew --prefix OUTPUT_VARIABLE BREW_DIR ERROR_QUIET)
string(STRIP "${BREW_DIR}" BREW_DIR)
```

Runs the `brew --prefix` command to retrieve the Homebrew installation directory.

#### 2.3 Path Configuration

If Homebrew is found, the following settings are applied:

| Setting | Description |
|---------|-------------|
| `CMAKE_PREFIX_PATH` | Adds the Homebrew directory |
| `target_include_directories` | Adds `${BREW_DIR}/include` (if it exists) |
| `CMAKE_PREFIX_PATH` | Adds `${BREW_DIR}/lib` to the path (if it exists) |

#### 2.4 Error Handling

- If Homebrew is found but `brew --prefix` fails: displays a warning
- If Homebrew is not found: notifies that system defaults will be used

---

### 3. Metal C++ Support

```cmake
if(IS_DIRECTORY /usr/local/include/metal-cpp)
    target_include_directories(${PROJECT_NAME} PRIVATE
        /usr/local/include/metal-cpp
        /usr/local/include/metal-cpp-extensions)
endif()
```

If Metal C++ headers exist at `/usr/local/include/metal-cpp`, they are added to the include directories. This enables direct use of Apple Metal from C++.

---

## Dependencies

| Dependency | Required/Optional | Description |
|------------|-------------------|-------------|
| `${PROJECT_NAME}` | Required | Main project target name (must be defined beforehand) |
| Homebrew | Optional | Settings are applied only if installed |
| Metal C++ | Optional | Enabled only if headers are present |

---

## Usage

Include from the main `CMakeLists.txt` as follows:

```cmake
if(APPLE)
    include(cmake/apple.cmake)
endif()
```

---

## Notes

1. **Target definition order**: The `${PROJECT_NAME}` target must be defined before including this file.

2. **Platform restriction**: This file is macOS-only. Do not use it on other platforms.

3. **Avoiding link_directories**: `CMAKE_PREFIX_PATH` is used instead of `link_directories`. This follows CMake modern best practices.
