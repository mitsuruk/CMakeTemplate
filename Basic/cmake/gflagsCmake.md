# gflags.cmake Reference

## Overview

`gflags.cmake` is a CMake configuration file that automatically downloads, builds, and links the gflags library.
It uses CMake's `file(DOWNLOAD)` and `execute_process` to manage the dependency, with caching in the `download/` directory to avoid redundant downloads and rebuilds.

gflags (Google Commandline Flags) is a C++ library that implements commandline flags processing.
It includes support for defining flags of various types (string, int32, int64, uint64, double, bool), flag validation, programmatic flag access and modification, and automatic `--help` / `--version` generation.

## File Information

| Item | Details |
|------|---------|
| Source Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/gflags` |
| Install Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/gflags-install` |
| Download URL | https://github.com/gflags/gflags/archive/refs/tags/v2.2.2.tar.gz |
| Version | 2.2.2 |
| License | BSD 3-Clause License |

---

## Include Guard

```cmake
include_guard(GLOBAL)
```

This file uses `include_guard(GLOBAL)` to ensure it is only executed once, even if included multiple times.

**Why it's needed:**

- Prevents duplicate `execute_process` invocations during configure
- Prevents duplicate linking in `target_link_libraries`

---

## Directory Structure

```
gflags/
├── cmake/
│   ├── gflags.cmake          # This configuration file
│   ├── gflagsCmake.md        # This document (English)
│   └── gflagsCmake-jp.md     # This document (Japanese)
├── download/
│   ├── gflags/               # gflags source (cached, downloaded from GitHub)
│   │   └── _build/           # CMake build directory (inside source)
│   └── gflags-install/       # gflags built artifacts (lib/, include/)
│       ├── include/
│       │   └── gflags/
│       │       ├── gflags.h
│       │       ├── gflags_declare.h
│       │       ├── gflags_completions.h
│       │       └── ...
│       └── lib/
│           └── libgflags.a
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## Usage

### Adding to CMakeLists.txt

```cmake
# Automatically include gflags.cmake if it exists
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/gflags.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/gflags.cmake)
endif()
```

### Build

```bash
mkdir build && cd build
cmake ..
make
```

---

## Processing Flow

### 1. Setting the Directory Paths

```cmake
set(GFLAGS_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(GFLAGS_SOURCE_DIR ${GFLAGS_DOWNLOAD_DIR}/gflags)
set(GFLAGS_INSTALL_DIR ${GFLAGS_DOWNLOAD_DIR}/gflags-install)
set(GFLAGS_BUILD_DIR ${GFLAGS_SOURCE_DIR}/_build)
set(GFLAGS_VERSION "2.2.2")
set(GFLAGS_URL "https://github.com/gflags/gflags/archive/refs/tags/v${GFLAGS_VERSION}.tar.gz")
```

### 2. Cache Check and Conditional Build

```cmake
if(EXISTS ${GFLAGS_INSTALL_DIR}/lib/libgflags.a)
    message(STATUS "gflags already built: ${GFLAGS_INSTALL_DIR}/lib/libgflags.a")
else()
    # Download, configure, build, and install ...
endif()
```

The cache logic works as follows:

| Condition | Action |
|-----------|--------|
| `gflags-install/lib/libgflags.a` exists | Skip everything (use cached build) |
| `gflags/CMakeLists.txt` exists (install missing) | Skip download, run CMake configure/build/install |
| Nothing exists | Download, extract, CMake configure, build, install |

### 3. Download (if needed)

```cmake
file(DOWNLOAD
    ${GFLAGS_URL}
    ${GFLAGS_DOWNLOAD_DIR}/gflags-${GFLAGS_VERSION}.tar.gz
    SHOW_PROGRESS
    STATUS DOWNLOAD_STATUS
)
file(ARCHIVE_EXTRACT
    INPUT ${GFLAGS_DOWNLOAD_DIR}/gflags-${GFLAGS_VERSION}.tar.gz
    DESTINATION ${GFLAGS_DOWNLOAD_DIR}
)
file(RENAME ${GFLAGS_DOWNLOAD_DIR}/gflags-${GFLAGS_VERSION} ${GFLAGS_SOURCE_DIR})
```

- Downloads from GitHub Releases
- Extracts and renames `gflags-2.2.2/` to `gflags/` for a clean path

### 4. Configure, Build, and Install (CMake)

```cmake
execute_process(
    COMMAND ${CMAKE_COMMAND}
            -DCMAKE_INSTALL_PREFIX=${GFLAGS_INSTALL_DIR}
            -DBUILD_SHARED_LIBS=OFF
            -DBUILD_STATIC_LIBS=ON
            -DBUILD_TESTING=OFF
            -DBUILD_PACKAGING=OFF
            -DBUILD_gflags_nothreads_LIB=OFF
            -DCMAKE_BUILD_TYPE=Release
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON
            ${GFLAGS_SOURCE_DIR}
    WORKING_DIRECTORY ${GFLAGS_BUILD_DIR}
)
execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release -j4
    WORKING_DIRECTORY ${GFLAGS_BUILD_DIR})
execute_process(COMMAND ${CMAKE_COMMAND} --install . --config Release
    WORKING_DIRECTORY ${GFLAGS_BUILD_DIR})
```

- `-DBUILD_SHARED_LIBS=OFF`: Disables shared library build
- `-DBUILD_STATIC_LIBS=ON`: Builds static library only
- `-DBUILD_TESTING=OFF`: Disables building test binaries
- `-DBUILD_PACKAGING=OFF`: Disables CPack packaging
- `-DBUILD_gflags_nothreads_LIB=OFF`: Only builds the multi-threaded variant
- `-DCMAKE_POSITION_INDEPENDENT_CODE=ON`: Generates position-independent code
- All steps run at CMake configure time, not at build time

### 5. Linking the Library

```cmake
set(gflags_DIR ${GFLAGS_INSTALL_DIR}/lib/cmake/gflags)
find_package(gflags REQUIRED CONFIG)

target_link_libraries(${PROJECT_NAME} PRIVATE gflags::gflags)
```

---

## Key Features of gflags

| Feature | Description |
|---------|-------------|
| Flag types | `DEFINE_string`, `DEFINE_int32`, `DEFINE_int64`, `DEFINE_uint64`, `DEFINE_double`, `DEFINE_bool` |
| Flag access | `FLAGS_<name>` global variables |
| Flag validation | `DEFINE_validator` / `RegisterFlagValidator` callbacks |
| Flag introspection | `GetCommandLineFlagInfo`, `GetAllFlags` |
| Programmatic setting | `SetCommandLineOption` |
| Usage/version | `SetUsageMessage`, `SetVersionString`, `--help`, `--version` |
| Argv processing | `ParseCommandLineFlags` with optional flag removal |
| Thread safety | All flag operations are thread-safe |

---

## Usage Examples in C++

### Basic Flag Definition and Usage

```cpp
#include <gflags/gflags.h>
#include <iostream>

DEFINE_string(name, "World", "Name to greet");
DEFINE_int32(count, 1, "Number of greetings");
DEFINE_bool(verbose, false, "Enable verbose output");

int main(int argc, char* argv[]) {
    gflags::ParseCommandLineFlags(&argc, &argv, true);

    for (int i = 0; i < FLAGS_count; ++i) {
        std::cout << "Hello, " << FLAGS_name << "!" << std::endl;
    }

    if (FLAGS_verbose) {
        std::cout << "Verbose mode enabled" << std::endl;
    }

    gflags::ShutDownCommandLineFlags();
    return 0;
}
```

### Flag Validation

```cpp
#include <gflags/gflags.h>
#include <iostream>

DEFINE_int32(port, 8080, "Server port number");

static bool ValidatePort(const char* flagname, gflags::int32 value) {
    if (value > 0 && value < 65536) return true;
    std::cerr << "Invalid value for --" << flagname << ": " << value << std::endl;
    return false;
}
DEFINE_validator(port, &ValidatePort);

int main(int argc, char* argv[]) {
    gflags::ParseCommandLineFlags(&argc, &argv, true);

    std::cout << "Server running on port " << FLAGS_port << std::endl;

    gflags::ShutDownCommandLineFlags();
    return 0;
}
```

### Flag Introspection

```cpp
#include <gflags/gflags.h>
#include <iostream>
#include <vector>

DEFINE_string(config, "/etc/app.conf", "Configuration file path");

int main(int argc, char* argv[]) {
    gflags::ParseCommandLineFlags(&argc, &argv, true);

    // Get information about a specific flag
    gflags::CommandLineFlagInfo info;
    if (gflags::GetCommandLineFlagInfo("config", &info)) {
        std::cout << "Flag: --" << info.name << std::endl;
        std::cout << "  Type:    " << info.type << std::endl;
        std::cout << "  Value:   " << info.current_value << std::endl;
        std::cout << "  Default: " << info.default_value << std::endl;
        std::cout << "  Changed: " << std::boolalpha << !info.is_default << std::endl;
    }

    // Enumerate all flags
    std::vector<gflags::CommandLineFlagInfo> all_flags;
    gflags::GetAllFlags(&all_flags);
    std::cout << "Total registered flags: " << all_flags.size() << std::endl;

    gflags::ShutDownCommandLineFlags();
    return 0;
}
```

### Programmatic Flag Setting

```cpp
#include <gflags/gflags.h>
#include <iostream>

DEFINE_string(mode, "normal", "Operation mode");
DEFINE_int32(timeout, 30, "Timeout in seconds");

int main(int argc, char* argv[]) {
    gflags::ParseCommandLineFlags(&argc, &argv, true);

    std::cout << "mode = " << FLAGS_mode << std::endl;

    // Change flag value programmatically
    gflags::SetCommandLineOption("mode", "debug");
    std::cout << "mode = " << FLAGS_mode << std::endl;  // "debug"

    // Can also set via FLAGS_ variable directly
    FLAGS_timeout = 60;
    std::cout << "timeout = " << FLAGS_timeout << std::endl;  // 60

    gflags::ShutDownCommandLineFlags();
    return 0;
}
```

### Usage Message and Version

```cpp
#include <gflags/gflags.h>

DEFINE_string(input, "", "Input file path (required)");
DEFINE_string(output, "out.txt", "Output file path");

int main(int argc, char* argv[]) {
    gflags::SetVersionString("2.0.0");
    gflags::SetUsageMessage("Process input files\nUsage: myapp --input=<file>");

    gflags::ParseCommandLineFlags(&argc, &argv, true);

    // --help prints usage message and all flags
    // --version prints version string
    // --helpshort prints only flags defined in main file

    if (FLAGS_input.empty()) {
        gflags::ShowUsageWithFlagsRestrict(argv[0], "main");
        return 1;
    }

    gflags::ShutDownCommandLineFlags();
    return 0;
}
```

### Multiple Flag Types

```cpp
#include <gflags/gflags.h>
#include <iostream>

DEFINE_bool(debug, false, "Enable debug mode");
DEFINE_int32(threads, 4, "Number of threads");
DEFINE_int64(max_memory, 1073741824, "Max memory in bytes (default: 1GB)");
DEFINE_uint64(seed, 0, "Random seed (0 = auto)");
DEFINE_double(learning_rate, 0.001, "Learning rate");
DEFINE_string(model, "default", "Model name");

int main(int argc, char* argv[]) {
    gflags::ParseCommandLineFlags(&argc, &argv, true);

    std::cout << "debug:         " << std::boolalpha << FLAGS_debug << std::endl;
    std::cout << "threads:       " << FLAGS_threads << std::endl;
    std::cout << "max_memory:    " << FLAGS_max_memory << std::endl;
    std::cout << "seed:          " << FLAGS_seed << std::endl;
    std::cout << "learning_rate: " << FLAGS_learning_rate << std::endl;
    std::cout << "model:         " << FLAGS_model << std::endl;

    gflags::ShutDownCommandLineFlags();
    return 0;
}
```

---

## Flag Types

| Macro | C++ Type | Example |
|-------|----------|---------|
| `DEFINE_bool` | `bool` | `DEFINE_bool(verbose, false, "...")` |
| `DEFINE_int32` | `int32_t` | `DEFINE_int32(port, 8080, "...")` |
| `DEFINE_int64` | `int64_t` | `DEFINE_int64(max_size, 1000000, "...")` |
| `DEFINE_uint64` | `uint64_t` | `DEFINE_uint64(seed, 0, "...")` |
| `DEFINE_double` | `double` | `DEFINE_double(rate, 0.01, "...")` |
| `DEFINE_string` | `std::string` | `DEFINE_string(name, "default", "...")` |

---

## Commonly Used Functions

| Function | Description |
|----------|-------------|
| `ParseCommandLineFlags(&argc, &argv, remove)` | Parse command-line flags; if `remove` is true, parsed flags are removed from argv |
| `SetUsageMessage(message)` | Set the usage message shown by `--help` |
| `SetVersionString(version)` | Set the version string shown by `--version` |
| `SetCommandLineOption(name, value)` | Set a flag value programmatically (string form) |
| `GetCommandLineFlagInfo(name, &info)` | Get detailed information about a flag |
| `GetAllFlags(&flags)` | Get a list of all registered flags |
| `ShowUsageWithFlagsRestrict(argv0, filter)` | Show usage for flags matching filter |
| `ProgramInvocationShortName()` | Get the program's short name (basename) |
| `ShutDownCommandLineFlags()` | Clean up gflags resources |

---

## Comparison with Other Flag Libraries

| Feature | gflags | Abseil Flags | Boost.Program_options |
|---------|--------|-------------|----------------------|
| Flag definition | `DEFINE_*` macros | `ABSL_FLAG` macro | `options_description` |
| Flag access | `FLAGS_<name>` | `absl::GetFlag()` | `vm["name"]` |
| Validation | `DEFINE_validator` | Custom parsers | `notifier` |
| Introspection | `GetAllFlags` | Limited | Limited |
| `--help` | Built-in | Built-in | Built-in |
| Thread safety | Yes | Yes | No |
| Header-only | No | No | No |
| Active maintenance | Moderate | Active | Active |

---

## Troubleshooting

### Download Fails

If GitHub is unreachable, you can manually download and place the tarball:

```bash
curl -L -o download/gflags-2.2.2.tar.gz https://github.com/gflags/gflags/archive/refs/tags/v2.2.2.tar.gz
```

Then re-run `cmake ..` and the extraction will proceed from the cached tarball.

### Configure Fails

Ensure CMake 3.20+ is available:

```bash
cmake --version
```

On macOS, ensure Xcode Command Line Tools are installed:

```bash
xcode-select --install
```

### Rebuild gflags from Scratch

To force a full rebuild, remove the install and source directories:

```bash
rm -rf download/gflags-install download/gflags
cd build && cmake ..
```

### Link Error: Undefined Reference to gflags Symbols

Verify that `libgflags.a` exists in `download/gflags-install/lib/`. If missing, delete the install directory and re-run cmake.

### `<gflags/gflags.h> was not included correctly`

Ensure `find_package(gflags)` is called with `CONFIG` mode and `gflags_DIR` points to the correct cmake config directory. The installed cmake config is at `download/gflags-install/lib/cmake/gflags/`.

---

## References

- [gflags GitHub Repository](https://github.com/gflags/gflags)
- [gflags Documentation](https://gflags.github.io/gflags/)
- [gflags README](https://github.com/gflags/gflags/blob/master/README.md)
- [CMake execute_process Documentation](https://cmake.org/cmake/help/latest/command/execute_process.html)
- [CMake file(DOWNLOAD) Documentation](https://cmake.org/cmake/help/latest/command/file.html#download)
