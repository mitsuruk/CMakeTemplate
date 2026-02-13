# install.cmake Documentation

## Overview

`install.cmake` is a reference file for installation configuration using CMake's `install()` command. It provides templates for installing header files, documentation, executables, and more.

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

- Prevents duplicate execution of `install()` commands
- Ensures safety when uncommenting for actual use in the future
- Avoids duplicate registration of install rules

---

## Note

This file is a template/reference, and all commands are commented out. Uncomment the necessary parts when you want to use them.

---

## Installation Patterns

### 1. Installing Header Files (by Directory)

```cmake
install(DIRECTORY ${CMAKE_SOURCE_DIR}/src/include/mklib/
    DESTINATION /usr/local/include/mklib
    FILES_MATCHING
    PATTERN "*.h"
    PATTERN "*.hpp"
)
```

| Parameter | Description |
|-----------|-------------|
| `DIRECTORY` | Source directory (note the trailing `/`) |
| `DESTINATION` | Installation destination directory |
| `FILES_MATCHING` | Only files matching the pattern |
| `PATTERN "*.h"` | Target `.h` files |
| `PATTERN "*.hpp"` | Also target `.hpp` files |

**Meaning of the trailing `/`:**
- `src/include/mklib/` -- Copies the **contents** of `mklib`
- `src/include/mklib` -- Copies the `mklib` directory **itself**

---

### 2. Installing Specific Files

```cmake
# Collect files into a list
file(GLOB DOC_FILES ${CMAKE_SOURCE_DIR}/src/*.md)

# Install to the specified directory
install(FILES ${DOC_FILES} DESTINATION /usr/local/include/mklib)
```

| Parameter | Description |
|-----------|-------------|
| `FILES` | List of files to install |
| `DESTINATION` | Installation destination directory |

---

### 3. Installing Executables

#### 3.1 Default (/usr/local/bin)

```cmake
install(TARGETS ${PROJECT_NAME})
```

Installs to the `bin` directory under `CMAKE_INSTALL_PREFIX` (default: `/usr/local`).

#### 3.2 Custom Directory

```cmake
install(TARGETS ${PROJECT_NAME} DESTINATION ${PROJECT_SOURCE_DIR}/install)
```

Installs to the `install` directory within the project source directory.

#### 3.3 Specifying a Prefix

```cmake
set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/install)
install(TARGETS ${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_PREFIX})
```

Changes the entire install prefix.

---

### 4. Installing Include Directories

```cmake
install(DIRECTORY ${CMAKE_SOURCE_DIR}/src/include/
    DESTINATION include
    FILES_MATCHING PATTERN "*.h*"
)
```

Installs all `.h` and `.hpp` files (matched by the `.h*` pattern) to the `include` directory.

---

## How to Run Installation

### Build and Install

```bash
# In the build directory
cmake --build . --target install

# Or
make install

# If elevated permissions are needed
sudo make install
```

### Specifying the Install Prefix

```bash
# Specify at configuration time
cmake -DCMAKE_INSTALL_PREFIX=/custom/path ..

# Or at install time
cmake --install . --prefix /custom/path
```

---

## CMake Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `CMAKE_INSTALL_PREFIX` | Root installation destination | `/usr/local` (Unix) |
| `CMAKE_SOURCE_DIR` | Top-level source directory | - |
| `CMAKE_CURRENT_SOURCE_DIR` | Directory of the current CMakeLists.txt | - |
| `PROJECT_SOURCE_DIR` | Source directory of the nearest `project()` | - |

---

## Default Installation Destinations

| Target Type | Default Path |
|-------------|--------------|
| Executables | `${CMAKE_INSTALL_PREFIX}/bin` |
| Libraries | `${CMAKE_INSTALL_PREFIX}/lib` |
| Headers | `${CMAKE_INSTALL_PREFIX}/include` |

---

## Usage

1. Uncomment the necessary install commands
2. Adjust paths to match your actual project structure
3. Include from the main `CMakeLists.txt`:

```cmake
include(cmake/install.cmake)
```

---

## Notes

1. **Permissions**: Installing to `/usr/local` typically requires `sudo`.

2. **Relative DESTINATION paths**: When a relative path is specified for `DESTINATION`, it is relative to `CMAKE_INSTALL_PREFIX`.

3. **Trailing slash**: The trailing `/` in `DIRECTORY` affects the copy behavior (see above).

4. **install_manifest.txt**: After running `make install`, an `install_manifest.txt` is generated in the build directory. This can be used for uninstallation.

5. **Duplicate code**: This file intentionally contains duplicate commented-out code. When using it, enable only the parts you need.
