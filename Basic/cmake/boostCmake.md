# boost.cmake Documentation

## Overview

`boost.cmake` is a CMake configuration file for integrating the Boost library into the project. It centrally manages the Boost components in use and automatically configures linking.

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

- Prevents duplicate calls to `find_package(Boost ...)`
- Prevents duplicate linking via `target_link_libraries`
- Avoids duplicate registration of Boost components

---

## Processing Flow

```
1. Component definition → 2. Boost search → 3. Target name generation → 4. Linking → 5. Debug info output
```

---

## Feature Details

### 1. Boost Component Definition

```cmake
set(BOOST_COMPONENTS
    headers            # Required: common headers
    # The following are optional (disable by commenting out)
)
```

Defines the Boost components to use as a list. Uncomment the needed components to enable them.

#### Available Components

| Component | Description |
|-----------|-------------|
| `headers` | Common Boost headers (required by most libraries) |
| `atomic` | Atomic operations (for lock-free concurrency) |
| `chrono` | Time representation and measurement (similar to `std::chrono`) |
| `container` | Fast standard container alternatives (small-size optimization, flat structures) |
| `context` | Low-level context switching (foundation for coroutines and fibers) |
| `coroutine` | Cooperative multitasking (built on `Boost::context`) |
| `date_time` | Date/time calculations (calendar time, special date support) |
| `fiber` | Userland threads (cooperative scheduling across threads) |
| `filesystem` | File/directory operations (`std::filesystem`-like API) |
| `graph` | Graph structures and algorithms (Dijkstra, DFS, etc.) |
| `iostreams` | Custom I/O streams (compression/encryption/memory buffer support) |
| `json` | High-performance JSON parser/generator (fully RFC-compliant) |
| `locale` | Localization (i18n/l10n, message translation) |
| `log` | Advanced logging (filters, formatting, async, etc.) |
| `log_setup` | Boost.Log initialization support (configuration file support) |
| `program_options` | Option parsing from command line/configuration files |
| `random` | Pseudo-random number generators (various distributions and engines) |
| `regex` | Regular expressions (Perl-compatible, Unicode support) |
| `serialization` | C++ object serialization/deserialization (XML/text/binary) |
| `thread` | Thread abstraction and synchronization primitives |
| `timer` | Elapsed time measurement |
| `unit_test_framework` | Integrated unit testing framework |
| `url` | URL parsing and generation (standards-compliant) |

---

### 2. Boost Package Search

```cmake
find_package(Boost 1.80.0 REQUIRED CONFIG COMPONENTS ${BOOST_COMPONENTS})
```

| Parameter | Description |
|-----------|-------------|
| `1.80.0` | Minimum required version |
| `REQUIRED` | Error if not found |
| `CONFIG` | Search using CMake config file mode |
| `COMPONENTS` | Search for the specified components |

---

### 3. Automatic Target Name Generation

```cmake
set(BOOST_DYNAMIC_LIBS "")
foreach(comp IN LISTS BOOST_COMPONENTS)
    list(APPEND BOOST_DYNAMIC_LIBS "Boost::${comp}")
endforeach()
```

Automatically generates CMake target names in the `Boost::xxx` format from component names.

**Examples:**
- `headers` → `Boost::headers`
- `filesystem` → `Boost::filesystem`

---

### 4. Linking to the Target

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE ${BOOST_DYNAMIC_LIBS})
```

Links all generated Boost targets to the project.

---

### 5. Debug Information Output

```cmake
message(STATUS "Boost version: ${Boost_VERSION}")
message(STATUS "Boost include dirs: ${Boost_INCLUDE_DIRS}")
message(STATUS "Boost libraries: ${BOOST_DYNAMIC_LIBS}")
```

Displays the following information at build time:
- Detected Boost version
- Include directories
- List of linked libraries

---

## Usage

### Basic Usage

1. Uncomment the components you want to use:

```cmake
set(BOOST_COMPONENTS
    headers
    filesystem    # Uncommented
    regex         # Uncommented
)
```

2. Include from the main `CMakeLists.txt`:

```cmake
include(cmake/boost.cmake)
```

---

## Dependencies

| Dependency | Required/Optional | Description |
|------------|-------------------|-------------|
| Boost 1.80.0 or higher | Required | Must be installed on the system |
| `${PROJECT_NAME}` | Required | Main project target name |

---

## Notes

1. **Boost installation**: Boost must be pre-installed on the system (via Homebrew, vcpkg, system packages, etc.).

2. **Inter-component dependencies**: Some components depend on others (e.g., `log` depends on `filesystem` and `thread`). CMake resolves these automatically.

3. **Python-related components**: Python binding components such as `python313` and `numpy313` require special configuration and are generally not used.

4. **Deprecated components**: Components marked as "not intended for use" in comments should be avoided unless there is a specific reason.
