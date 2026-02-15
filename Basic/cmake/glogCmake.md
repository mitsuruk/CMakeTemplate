# glog.cmake Reference

## Overview

`glog.cmake` is a CMake configuration file that automatically downloads, builds, and links the glog library.
It uses CMake's `file(DOWNLOAD)` and `execute_process` to manage the dependency, with caching in the `download/` directory to avoid redundant downloads and rebuilds.

glog (Google Logging Library) is a C++ logging library that provides logging APIs based on C++-style streams and various helper macros.
It supports severity levels (INFO, WARNING, ERROR, FATAL), conditional and periodic logging, verbose logging (VLOG), assertion-style CHECK macros, and automatic stack trace dumping on crash.

## File Information

| Item | Details |
|------|---------|
| Source Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/glog` |
| Install Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/glog-install` |
| Download URL | https://github.com/google/glog/archive/refs/tags/v0.7.1.tar.gz |
| Version | 0.7.1 |
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
glog/
├── cmake/
│   ├── glog.cmake          # This configuration file
│   └── glogCmake.md        # This document
├── download/
│   ├── glog/               # glog source (cached, downloaded from GitHub)
│   │   └── _build/         # CMake build directory (inside source)
│   └── glog-install/       # glog built artifacts (lib/, include/)
│       ├── include/
│       │   └── glog/
│       │       ├── logging.h
│       │       ├── log_severity.h
│       │       ├── flags.h
│       │       ├── vlog_is_on.h
│       │       └── ...
│       └── lib/
│           └── libglog.a
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## Usage

### Adding to CMakeLists.txt

```cmake
# Automatically include glog.cmake if it exists
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/glog.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/glog.cmake)
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
set(GLOG_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(GLOG_SOURCE_DIR ${GLOG_DOWNLOAD_DIR}/glog)
set(GLOG_INSTALL_DIR ${GLOG_DOWNLOAD_DIR}/glog-install)
set(GLOG_BUILD_DIR ${GLOG_SOURCE_DIR}/_build)
set(GLOG_VERSION "0.7.1")
set(GLOG_URL "https://github.com/google/glog/archive/refs/tags/v${GLOG_VERSION}.tar.gz")
```

### 2. Cache Check and Conditional Build

```cmake
if(EXISTS ${GLOG_INSTALL_DIR}/lib/libglog.a)
    message(STATUS "glog already built: ${GLOG_INSTALL_DIR}/lib/libglog.a")
else()
    # Download, configure, build, and install ...
endif()
```

The cache logic works as follows:

| Condition | Action |
|-----------|--------|
| `glog-install/lib/libglog.a` exists | Skip everything (use cached build) |
| `glog/CMakeLists.txt` exists (install missing) | Skip download, run CMake configure/build/install |
| Nothing exists | Download, extract, CMake configure, build, install |

### 3. Download (if needed)

```cmake
file(DOWNLOAD
    ${GLOG_URL}
    ${GLOG_DOWNLOAD_DIR}/glog-${GLOG_VERSION}.tar.gz
    SHOW_PROGRESS
    STATUS DOWNLOAD_STATUS
)
file(ARCHIVE_EXTRACT
    INPUT ${GLOG_DOWNLOAD_DIR}/glog-${GLOG_VERSION}.tar.gz
    DESTINATION ${GLOG_DOWNLOAD_DIR}
)
file(RENAME ${GLOG_DOWNLOAD_DIR}/glog-${GLOG_VERSION} ${GLOG_SOURCE_DIR})
```

- Downloads from GitHub Releases
- Extracts and renames `glog-0.7.1/` to `glog/` for a clean path

### 4. Configure, Build, and Install (CMake)

```cmake
execute_process(
    COMMAND ${CMAKE_COMMAND}
            -DCMAKE_INSTALL_PREFIX=${GLOG_INSTALL_DIR}
            -DBUILD_SHARED_LIBS=OFF
            -DWITH_GFLAGS=OFF
            -DWITH_GTEST=OFF
            -DWITH_UNWIND=OFF
            -DBUILD_TESTING=OFF
            -DCMAKE_BUILD_TYPE=Release
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON
            ${GLOG_SOURCE_DIR}
    WORKING_DIRECTORY ${GLOG_BUILD_DIR}
)
execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release -j4
    WORKING_DIRECTORY ${GLOG_BUILD_DIR})
execute_process(COMMAND ${CMAKE_COMMAND} --install . --config Release
    WORKING_DIRECTORY ${GLOG_BUILD_DIR})
```

- `-DBUILD_SHARED_LIBS=OFF`: Builds static library only
- `-DWITH_GFLAGS=OFF`: Disables gflags dependency (simplifies build)
- `-DWITH_GTEST=OFF`: Disables Google Test dependency
- `-DWITH_UNWIND=OFF`: Disables libunwind dependency
- `-DBUILD_TESTING=OFF`: Disables building test binaries
- `-DCMAKE_POSITION_INDEPENDENT_CODE=ON`: Generates position-independent code
- All steps run at CMake configure time, not at build time

### 5. Linking the Library

```cmake
add_library(glog_lib STATIC IMPORTED)
set_target_properties(glog_lib PROPERTIES
    IMPORTED_LOCATION ${GLOG_INSTALL_DIR}/lib/libglog.a
)

target_include_directories(${PROJECT_NAME} PRIVATE ${GLOG_INSTALL_DIR}/include)
target_link_libraries(${PROJECT_NAME} PRIVATE glog_lib)
```

---

## Key Features of glog

| Feature | Description |
|---------|-------------|
| Severity levels | `LOG(INFO)`, `LOG(WARNING)`, `LOG(ERROR)`, `LOG(FATAL)` |
| Conditional logging | `LOG_IF`, `LOG_EVERY_N`, `LOG_FIRST_N`, `LOG_EVERY_T` |
| Verbose logging | `VLOG(n)`, controlled by `--v=N` flag |
| CHECK macros | `CHECK`, `CHECK_EQ`, `CHECK_NE`, `CHECK_LT`, `CHECK_LE`, `CHECK_GT`, `CHECK_GE`, `CHECK_NOTNULL` |
| Failure signal handler | Stack trace on SIGSEGV, SIGABRT, etc. |
| Log destinations | stderr, files, custom sinks |
| Thread safety | All logging operations are thread-safe |
| Stream-based API | C++ `<<` operator for flexible formatting |

---

## Usage Examples in C++

### Basic Logging

```cpp
#include <glog/logging.h>

int main(int argc, char* argv[]) {
    google::InitGoogleLogging(argv[0]);
    FLAGS_alsologtostderr = true;

    LOG(INFO) << "This is an info message";
    LOG(WARNING) << "This is a warning";
    LOG(ERROR) << "This is an error";
    // LOG(FATAL) << "This terminates the program";

    google::ShutdownGoogleLogging();
    return 0;
}
```

### Conditional Logging

```cpp
#include <glog/logging.h>

int main(int argc, char* argv[]) {
    google::InitGoogleLogging(argv[0]);
    FLAGS_alsologtostderr = true;

    int value = 42;

    // Log only when condition is true
    LOG_IF(INFO, value > 10) << "value is greater than 10";

    // Log every N-th occurrence
    for (int i = 0; i < 100; ++i) {
        LOG_EVERY_N(INFO, 10) << "Every 10th: i=" << i;
    }

    // Log only the first N occurrences
    for (int i = 0; i < 100; ++i) {
        LOG_FIRST_N(INFO, 3) << "First 3 only: i=" << i;
    }

    // Log at most once every T seconds
    for (int i = 0; i < 100; ++i) {
        LOG_EVERY_T(INFO, 1.0) << "At most once per second: i=" << i;
    }

    google::ShutdownGoogleLogging();
    return 0;
}
```

### Verbose Logging (VLOG)

```cpp
#include <glog/logging.h>

int main(int argc, char* argv[]) {
    google::InitGoogleLogging(argv[0]);
    FLAGS_alsologtostderr = true;

    // Run with --v=2 to see VLOG(1) and VLOG(2) messages
    VLOG(1) << "Verbose level 1: general debug info";
    VLOG(2) << "Verbose level 2: detailed trace info";
    VLOG(3) << "Verbose level 3: very detailed info";

    if (VLOG_IS_ON(2)) {
        // Expensive computation only when verbose level >= 2
        LOG(INFO) << "Detailed diagnostics enabled";
    }

    google::ShutdownGoogleLogging();
    return 0;
}
```

### CHECK Macros (Assertions)

```cpp
#include <glog/logging.h>
#include <vector>

int main(int argc, char* argv[]) {
    google::InitGoogleLogging(argv[0]);

    int a = 10, b = 20;

    CHECK(a < b) << "a must be less than b";
    CHECK_EQ(a, 10) << "a should be 10";
    CHECK_NE(a, b) << "a and b should differ";
    CHECK_LT(a, b) << "a should be less than b";
    CHECK_GT(b, a) << "b should be greater than a";

    // CHECK_NOTNULL returns the pointer if non-null
    std::vector<int> v = {1, 2, 3};
    auto* ptr = CHECK_NOTNULL(&v);
    LOG(INFO) << "Vector size: " << ptr->size();

    google::ShutdownGoogleLogging();
    return 0;
}
```

### Failure Signal Handler (Stack Trace on Crash)

```cpp
#include <glog/logging.h>

void cause_segfault() {
    int* p = nullptr;
    *p = 42;  // SIGSEGV
}

int main(int argc, char* argv[]) {
    google::InitGoogleLogging(argv[0]);
    FLAGS_alsologtostderr = true;

    // Install signal handler for SIGSEGV, SIGABRT, SIGBUS, etc.
    google::InstallFailureSignalHandler();

    LOG(INFO) << "About to crash...";
    cause_segfault();  // Will print stack trace before dying

    google::ShutdownGoogleLogging();
    return 0;
}
```

### Log to File

```cpp
#include <glog/logging.h>

int main(int argc, char* argv[]) {
    google::InitGoogleLogging(argv[0]);

    // Log INFO and above to /tmp/myapp.INFO, etc.
    google::SetLogDestination(google::INFO, "/tmp/myapp.INFO.");
    google::SetLogDestination(google::WARNING, "/tmp/myapp.WARNING.");
    google::SetLogDestination(google::ERROR, "/tmp/myapp.ERROR.");

    // Also log to stderr
    FLAGS_alsologtostderr = true;

    LOG(INFO) << "This goes to both file and stderr";
    LOG(WARNING) << "Warning logged to file";

    google::ShutdownGoogleLogging();
    return 0;
}
```

---

## Severity Levels

| Level | Macro | Description |
|-------|-------|-------------|
| 0 | `LOG(INFO)` | Informational messages |
| 1 | `LOG(WARNING)` | Warning conditions |
| 2 | `LOG(ERROR)` | Error conditions |
| 3 | `LOG(FATAL)` | Fatal error; logs message then terminates program via `abort()` |

Higher severity levels include all lower levels in log output. For example, `FLAGS_minloglevel = 1` suppresses INFO but shows WARNING, ERROR, and FATAL.

---

## Commonly Used Flags

| Flag | Default | Description |
|------|---------|-------------|
| `FLAGS_logtostderr` | `false` | Log to stderr instead of files |
| `FLAGS_alsologtostderr` | `false` | Log to stderr in addition to files |
| `FLAGS_colorlogtostderr` | `false` | Colorize log output on stderr |
| `FLAGS_minloglevel` | `0` (INFO) | Minimum severity level to log |
| `FLAGS_v` | `0` | Verbose level for VLOG |
| `FLAGS_log_dir` | `""` | Directory for log files |
| `FLAGS_max_log_size` | `1800` | Max log file size in MB |
| `FLAGS_stop_logging_if_full_disk` | `false` | Stop logging when disk is full |

---

## Comparison with Other Logging Libraries

| Feature | glog | spdlog | Abseil Logging |
|---------|------|--------|----------------|
| API style | Stream (`<<`) | fmt/printf | Stream (`<<`) |
| Severity levels | 4 (INFO-FATAL) | 7 (trace-critical) | 4 (INFO-FATAL) |
| CHECK macros | Yes | No | Yes |
| VLOG | Yes | No | Yes |
| Signal handler | Yes | No | Yes |
| Header-only | No | Optional | No |
| Thread safety | Yes | Yes | Yes |
| Active maintenance | Archived (2025-06) | Active | Active |

---

## Troubleshooting

### Download Fails

If GitHub is unreachable, you can manually download and place the tarball:

```bash
curl -L -o download/glog-0.7.1.tar.gz https://github.com/google/glog/archive/refs/tags/v0.7.1.tar.gz
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

### Rebuild glog from Scratch

To force a full rebuild, remove the install and source directories:

```bash
rm -rf download/glog-install download/glog
cd build && cmake ..
```

### Link Error: Undefined Reference to glog Symbols

Verify that `libglog.a` exists in `download/glog-install/lib/`. If missing, delete the install directory and re-run cmake.

### `<glog/logging.h> was not included correctly`

glog 0.7.x requires consuming the library through CMake's `find_package` or by setting include paths correctly. Ensure `target_include_directories` points to the glog install's include directory.

---

## References

- [glog GitHub Repository](https://github.com/google/glog)
- [glog Documentation (0.7.1)](https://google.github.io/glog/0.7.1/)
- [glog README](https://github.com/google/glog/blob/master/README.rst)
- [CMake execute_process Documentation](https://cmake.org/cmake/help/latest/command/execute_process.html)
- [CMake file(DOWNLOAD) Documentation](https://cmake.org/cmake/help/latest/command/file.html#download)
