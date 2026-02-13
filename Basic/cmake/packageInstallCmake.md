# packageInstall.cmake Reference

## Overview

`packageInstall.cmake` is a configuration file for installing a project as a CMake package. It exports the library in a format that can be imported from other CMake projects using `find_package()`.

## File Information

| Item | Details |
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

This file uses `include_guard(GLOBAL)` to ensure it is only executed once, even if included multiple times.

**Why it's needed:**

- Prevents errors from duplicate `install(TARGETS ...)`
- Prevents duplicate registration of `install(EXPORT ...)`
- Avoids duplicate generation of package configuration files
- Prevents duplicate execution of target detection logic

---

## Processing Flow

```
1. Set package name and version
2. Validation
3. Set include directories
4. Generate version file
5. Generate configuration file
6. Detect and install targets
7. Generate export file
8. Install configuration files
```

---

## Feature Details

### 1. Setting Package Name and Version

```cmake
set(PACKAGE_NAME ${PROJECT_NAME})
set(PACKAGE_VERSION 0.0.1)
```

| Variable | Description |
|----------|-------------|
| `PACKAGE_NAME` | Package identifier name (default: project name) |
| `PACKAGE_VERSION` | Semantic versioning format |

---

### 2. Validation of Required Variables

```cmake
if(NOT DEFINED PACKAGE_NAME OR PACKAGE_NAME STREQUAL "")
    message(FATAL_ERROR "PACKAGE_NAME is not set...")
endif()
```

If `PACKAGE_NAME` or `PACKAGE_VERSION` is not set, the build stops with an error.

---

### 3. Setting Include Directories

```cmake
if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src/include)
    target_include_directories(${PROJECT_NAME} PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/include>
        $<INSTALL_INTERFACE:include>
    )
endif()
```

| Generator Expression | Description |
|----------------------|-------------|
| `$<BUILD_INTERFACE:...>` | Path used during build |
| `$<INSTALL_INTERFACE:...>` | Path used after installation |

This ensures the appropriate include paths are used during build and after installation.

---

### 4. Generating the Version File

```cmake
include(CMakePackageConfigHelpers)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}ConfigVersion.cmake
    VERSION ${PACKAGE_VERSION}
    COMPATIBILITY AnyNewerVersion
)
```

| Parameter | Description |
|-----------|-------------|
| `VERSION` | Package version |
| `COMPATIBILITY` | Version compatibility policy |

**Compatibility Options:**

| Option | Description |
|--------|-------------|
| `AnyNewerVersion` | Compatible with the same or newer version |
| `SameMajorVersion` | Compatible if the major version matches |
| `SameMinorVersion` | Compatible if the minor version matches |
| `ExactVersion` | Exact match only |

---

### 5. Generating the Configuration File

```cmake
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/cmake)
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/cmake/${PACKAGE_NAME}Config.cmake.in
    "include(\"\${CMAKE_CURRENT_LIST_DIR}/${PACKAGE_NAME}Targets.cmake\")"
)

configure_file(
    ${CMAKE_CURRENT_BINARY_DIR}/cmake/${PACKAGE_NAME}Config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}Config.cmake
    @ONLY
)
```

The `@ONLY` option causes only `@VAR@` style substitutions to be performed, preserving `${VAR}` style expressions.

---

### 6. Automatic Detection of Installable Targets

```cmake
get_property(ALL_TARGETS DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    PROPERTY BUILDSYSTEM_TARGETS)

foreach(target ${ALL_TARGETS})
    get_target_property(target_type ${target} TYPE)
    if(target_type MATCHES "EXECUTABLE|STATIC_LIBRARY|SHARED_LIBRARY")
        list(APPEND INSTALL_TARGETS ${target})
    endif()
endforeach()
```

The following target types are automatically detected:

| Target Type | Description |
|-------------|-------------|
| `EXECUTABLE` | Executable file |
| `STATIC_LIBRARY` | Static library |
| `SHARED_LIBRARY` | Shared library |

---

### 7. Installing Targets

```cmake
install(TARGETS ${INSTALL_TARGETS} EXPORT ${PACKAGE_NAME}Targets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    INCLUDES DESTINATION include
)
```

| Component | Install Location | Description |
|-----------|-----------------|-------------|
| `LIBRARY` | `lib/` | Shared libraries (.so/.dylib) |
| `ARCHIVE` | `lib/` | Static libraries (.a) |
| `RUNTIME` | `bin/` | Executables |
| `INCLUDES` | `include/` | Include directories |

---

### 8. Installing Include Directories

```cmake
if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src/include)
    install(DIRECTORY src/include/ DESTINATION include)
endif()
```

Installs the contents of the `src/include/` directory to `include/`.

---

### 9. Installing Export Configuration

```cmake
install(EXPORT ${PACKAGE_NAME}Targets
    FILE ${PACKAGE_NAME}Targets.cmake
    NAMESPACE ${PACKAGE_NAME}::
    DESTINATION lib/cmake/${PACKAGE_NAME}
)
```

| Parameter | Description |
|-----------|-------------|
| `FILE` | Export file name |
| `NAMESPACE` | Prefix added to targets |
| `DESTINATION` | Install location |

This allows other projects to link using `${PACKAGE_NAME}::${TARGET_NAME}`.

---

### 10. Installing Configuration Files

```cmake
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}Config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}ConfigVersion.cmake"
    DESTINATION lib/cmake/${PACKAGE_NAME}
)
```

---

## Directory Structure After Installation

```
${CMAKE_INSTALL_PREFIX}/
├── bin/
│   └── ${PROJECT_NAME}           # Executable
├── lib/
│   ├── lib${PROJECT_NAME}.a      # Static library
│   └── cmake/${PACKAGE_NAME}/
│       ├── ${PACKAGE_NAME}Config.cmake
│       ├── ${PACKAGE_NAME}ConfigVersion.cmake
│       └── ${PACKAGE_NAME}Targets.cmake
└── include/
    └── (header files)
```

---

## Using from Other Projects

```cmake
find_package(${PACKAGE_NAME} REQUIRED)
target_link_libraries(my_app PRIVATE ${PACKAGE_NAME}::${TARGET_NAME})
```

---

## Uninstallation

After installation, an `install_manifest.txt` is generated in the build directory:

```bash
sudo xargs rm < install_manifest.txt
```

---

## Usage

Include from the main `CMakeLists.txt`:

```cmake
include(cmake/packageInstall.cmake)
```

---

## Dependencies

| Dependency | Required/Optional | Description |
|------------|-------------------|-------------|
| `${PROJECT_NAME}` | Required | Main project target name |
| `CMakePackageConfigHelpers` | Required | CMake standard module |

---

## Notes

1. **Target definition order**: All targets must be defined before including this file.

2. **No targets error**: If no installable targets are found, the build stops with a `FATAL_ERROR`.

3. **Namespace**: Exported targets are prefixed with `${PACKAGE_NAME}::`.

4. **INTERFACE/OBJECT libraries**: These types are excluded from install targets.

5. **Version changes**: When changing `PACKAGE_VERSION`, be mindful of the compatibility policy.
