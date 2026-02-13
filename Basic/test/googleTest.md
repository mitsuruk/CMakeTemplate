# GoogleTest Usage Guide

This document explains how to use GoogleTest in this CMake project template.

## Table of Contents

1. [Quick Start](#quick-start)
2. [GTest Targets Overview](#gtest-targets-overview)
3. [CTest Integration](#ctest-integration)
4. [Testing Workflow](#testing-workflow)
5. [Advanced Configuration](#advanced-configuration)

---

## Quick Start

### 1. Build with GoogleTest enabled

```bash
cd /path/to/project
cmake -DGTEST=true -B build
cmake --build build
```

### 2. Run tests

**Option 1: Using CTest (Recommended)**
```bash
cd build
ctest                      # Simple output
ctest --verbose            # Detailed output
ctest --output-on-failure  # Show details only on failure
```

**Option 2: Direct execution**
```bash
./build/a.out.out
```

---

## GTest Targets Overview

The `GTest::` targets made available by CMake's `find_package(GTest REQUIRED)` are organized by the functionality provided by the GoogleTest libraries, allowing you to select the appropriate target based on your use case.

Here's a summary of the main `GTest::` targets:

---

### 🔹 `GTest::gtest`

- **Content**: GoogleTest core library.
- **Purpose**: Provides assertions (`EXPECT_*`, `ASSERT_*`) and core unit testing framework functionality.
- **Note**: Use this when you want to define your own `main()` function.

---

### 🔹 `GTest::gtest_main`

- **Content**: Includes `GTest::gtest` plus GoogleTest's provided `main()` function.
- **Purpose**: Convenient when you want to run tests without writing your own `main()`.
- **Note**: Automatically includes a `main()` function that calls `RUN_ALL_TESTS()`.

---

### 🔹 `GTest::gmock`

- **Content**: GoogleMock core library.
- **Purpose**: Use when writing tests with mock objects.
- **Note**: Depends on GoogleTest (`gmock` internally links `gtest`).

---

### 🔹 `GTest::gmock_main`

- **Content**: Includes `GTest::gmock` plus provides `main()`.
- **Purpose**: Use GoogleMock with a pre-defined `main()` function.

---

### 💡 Usage Examples by Difference

| Purpose                              | Link Target                          |
|--------------------------------------|--------------------------------------|
| Define your own `main()`             | `GTest::gtest` or `GTest::gmock`     |
| Want `main()` provided automatically | `GTest::gtest_main` or `GTest::gmock_main` |

---

### 🎯 Recommended Usage

- **For lightweight unit tests only** → `GTest::gtest_main`
- **For tests using mocks** → `GTest::gmock_main`
- **For customizing main function** → `GTest::gtest` or `GTest::gmock`

---

You can link multiple targets using `target_link_libraries()` if necessary, but when using `gmock_main` or `gtest_main`, ensure that `main()` is not defined elsewhere to avoid duplication errors.

--- 


`gtest` / `gmock` each have **variations depending on whether they include `main()`**:

---

## ✅ Summary:

| Target Name              | Included Functionality                   | Includes `main()`? |
|--------------------------|------------------------------------------|--------------------|
| `GTest::gtest`           | GoogleTest core library                  | ❌ No              |
| `GTest::gtest_main`      | `gtest` + Google-provided `main()`       | ✅ Yes             |
| `GTest::gmock`           | GoogleMock + GoogleTest                  | ❌ No              |
| `GTest::gmock_main`      | `gmock` + `gtest` + Google's `main()`    | ✅ Yes             |

---

## 💡 Key Points

- Targets with `*_main` suffix include `main()`.
- Targets without `*_main` suffix require **you to write your own `int main()`**.
- `gmock_main` includes `gmock`, `gtest`, and `main()`, so it's self-contained.

---

## Example: Choosing Based on Whether to Write main

### 🎯 Want to write your own main (e.g., to launch multiple tests together)
```cmake
target_link_libraries(
  ${PROJECT_NAME}
  PRIVATE
  GTest::gmock
)
```

### 🎯 Use standard main for quick testing
```cmake
target_link_libraries(
  ${PROJECT_NAME}
  PRIVATE
  GTest::gmock_main
)
```

---

Whether or not you need to customize the `main()` function is the key factor in deciding which target to use.
If desired, I can also provide templates for custom `main()` or examples of test grouping.

---

## CTest Integration

This project uses CMake's built-in testing functionality through `enable_testing()` and `add_test()`.

### How CTest Works

When you build with `-DGTEST=true`, the CMake configuration:

1. **Enables testing** with `enable_testing()`
2. **Registers test executable** with `add_test()`
3. **Generates** `CTestTestfile.cmake` in the build directory

### CTest vs Direct Execution

| Method | Command | Features |
|--------|---------|----------|
| **Direct** | `./a.out.out` | Simple execution, GoogleTest output |
| **CTest** | `ctest` | Test management, timeout control, parallel execution, CI/CD integration |

### What CTest Does Internally

When you run `ctest`, it:

1. Reads `CTestTestfile.cmake`
2. Executes registered test executable (`./a.out.out`)
3. Monitors execution time and timeout (60 seconds default)
4. Collects results and formats output
5. Returns appropriate exit codes for CI/CD

### CTest Commands

```bash
# Basic execution
ctest                      # Run all tests
ctest --verbose            # Show detailed output
ctest --output-on-failure  # Show output only when tests fail

# Advanced usage
ctest -j4                  # Run tests in parallel (4 jobs)
ctest -R pattern           # Run tests matching regex pattern
ctest --rerun-failed       # Re-run only failed tests
ctest -T Test              # Generate XML output for CI/CD
```

### Test Configuration in CMakeLists.txt

```cmake
# Enable testing
enable_testing()

# Register test
add_test(
    NAME ${PROJECT_NAME}_tests
    COMMAND ${PROJECT_NAME}
    WORKING_DIRECTORY ${BINARY_OUTPUT_DIR}
)

# Set test properties
set_tests_properties(${PROJECT_NAME}_tests PROPERTIES
    TIMEOUT 60                   # Test timeout (seconds)
    ENVIRONMENT "GTEST_COLOR=1"  # Enable colored output
)
```

---

## Testing Workflow

### Project Structure

```
Basic/
├── CMakeLists.txt       # Main build configuration
├── src/
│   └── main.cpp         # Production code
└── test/
    ├── README.md        # Test documentation
    └── test_main.cpp    # GoogleTest test cases
```

### Writing Tests

Create test files in the `test/` directory:

```cpp
#include <gtest/gtest.h>
#include <gmock/gmock.h>

// Test case example
TEST(TestSuiteName, TestCaseName) {
    EXPECT_EQ(1 + 1, 2);
    ASSERT_TRUE(true);
}

// Main function
int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
```

### Build and Test Cycle

```bash
# 1. Configure with GoogleTest
cmake -DGTEST=true -B build

# 2. Build
cmake --build build

# 3. Run tests
cd build
ctest --verbose

# 4. Or run directly
./a.out.out
```

### Expected Output

#### CTest Output

```
Test project /path/to/build
    Start 1: a.out.out_tests
1/1 Test #1: a.out.out_tests ..................   Passed    0.01 sec

100% tests passed, 0 tests failed out of 1

Total Test time (real) =   0.01 sec
```

#### Direct Execution Output

```
[==========] Running 3 tests from 2 test suites.
[----------] Global test environment set-up.
[----------] 2 tests from BasicTest
[ RUN      ] BasicTest.Addition
[       OK ] BasicTest.Addition (0 ms)
[ RUN      ] BasicTest.Multiplication
[       OK ] BasicTest.Multiplication (0 ms)
[----------] 2 tests from BasicTest (0 ms total)

[----------] 1 test from StringTest
[ RUN      ] StringTest.BasicStringOperations
[       OK ] StringTest.BasicStringOperations (0 ms)
[----------] 1 test from StringTest (0 ms total)

[----------] Global test environment tear-down
[==========] 3 tests from 2 test suites ran. (0 ms total)
[  PASSED  ] 3 tests.
```

---

## Advanced Configuration

### Current CMakeLists.txt Configuration

The current implementation in CMakeLists.txt (lines 408-460):

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

### Alternative Approach: Using gtest_discover_tests()

The code block below shows an alternative approach using `gtest_discover_tests()`:

---
### Example: googleTest.cmake with FetchContent

This example shows how to automatically fetch GoogleTest from GitHub if it's not installed via Homebrew.

```cmake
# ------------------------------------------------------------------------------
# googleTest.cmake - googleTest Configuration File
#
# Project: [CMake Template Project]
# Author: [mitsuruK]
# Date: [2025/07/23]
# License: MIT License
# See LICENSE.md for details.
# ------------------------------------------------------------------------------

if(GTEST)
    # Locate the Homebrew installation directory with proper error handling
    find_program(BREW_COMMAND brew)
    if(BREW_COMMAND)
        execute_process(COMMAND brew --prefix OUTPUT_VARIABLE BREW_DIR ERROR_QUIET)
        string(STRIP "${BREW_DIR}" BREW_DIR)
        if(BREW_DIR)
            message(STATUS "Using Homebrew installation at: ${BREW_DIR}")
            set(CMAKE_PREFIX_PATH "${BREW_DIR};${CMAKE_PREFIX_PATH}")
        else()
            message(WARNING "Homebrew found but brew --prefix failed")
        endif()
    else()
        message(STATUS "Homebrew not found, using system defaults")
    endif()

    # Verify if GoogleTest is installed via Homebrew
    if(BREW_COMMAND)
        execute_process(COMMAND bash -c "brew list | grep -y googletest"
            RESULT_VARIABLE result
            OUTPUT_VARIABLE output
            ERROR_QUIET)
    endif()

    if(NOT BREW_COMMAND OR output STREQUAL "")
        # If GoogleTest is not installed via Homebrew, fetch it from GitHub
        message(STATUS "Fetching GoogleTest from GitHub")
        include(FetchContent)
        FetchContent_Declare(
            googletest
            URL https://github.com/google/googletest/archive/refs/heads/master.zip
        )
        set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
        FetchContent_MakeAvailable(googletest)
    else()
        # If GoogleTest is installed via Homebrew, locate it
        message(STATUS "Using GoogleTest from Homebrew")
        find_package(GTest REQUIRED)
    endif()

    # Enable testing and link GoogleTest
    # Reference: https://google.github.io/googletest/quickstart-cmake.html
    enable_testing()

    target_link_libraries(
        ${PROJECT_NAME}
        PRIVATE
        GTest::gtest
        # GTest::gtest_main
    )

    # Auto-discover tests using GoogleTest
    include(GoogleTest)
    gtest_discover_tests(${PROJECT_NAME})

    # Compiler flags for GoogleTest
    target_compile_definitions(${PROJECT_NAME} PRIVATE GTEST)
endif() # GTEST
```

### Comparison: add_test() vs gtest_discover_tests()

| Feature | `add_test()` | `gtest_discover_tests()` |
|---------|--------------|--------------------------|
| **Registration** | Manual, one test executable | Automatic, per TEST() case |
| **CTest output** | Single test entry | Multiple test entries (one per TEST) |
| **Setup** | Simple, explicit | Requires `include(GoogleTest)` |
| **Flexibility** | Good for simple cases | Better for many test cases |
| **This project uses** | `add_test()` | Not used (but available) |

### Using gtest_discover_tests() Example

If you want CTest to show each `TEST()` individually:

```cmake
if(GTEST)
    find_package(GTest REQUIRED)
    enable_testing()

    target_link_libraries(${PROJECT_NAME} PRIVATE GTest::gmock GTest::gmock_main)

    # This will discover each TEST() as a separate CTest entry
    include(GoogleTest)
    gtest_discover_tests(${PROJECT_NAME})
endif()
```

**Output with gtest_discover_tests():**

```
Test project /path/to/build
    Start 1: BasicTest.Addition
1/3 Test #1: BasicTest.Addition ...................   Passed    0.00 sec
    Start 2: BasicTest.Multiplication
2/3 Test #2: BasicTest.Multiplication .............   Passed    0.00 sec
    Start 3: StringTest.BasicStringOperations
3/3 Test #3: StringTest.BasicStringOperations .....   Passed    0.00 sec

100% tests passed, 0 tests failed out of 3
```

**Output with add_test() (current implementation):**

```
Test project /path/to/build
    Start 1: a.out.out_tests
1/1 Test #1: a.out.out_tests ......................   Passed    0.01 sec

100% tests passed, 0 tests failed out of 1
```

---

## Summary

### Key Points

1. **Two ways to run tests**: Direct execution or via CTest
2. **CTest provides**: Test management, timeout control, parallel execution, CI/CD integration
3. **Current implementation**: Uses `enable_testing()` + `add_test()` for simplicity
4. **Alternative approach**: `gtest_discover_tests()` for granular test discovery

### Recommended Workflow

```bash
# Build with GoogleTest
cmake -DGTEST=true -B build
cmake --build build

# Run tests
cd build
ctest --output-on-failure

# For detailed GoogleTest output, run directly
./a.out.out
```

### References

- [GoogleTest Official Documentation](https://google.github.io/googletest/)
- [GoogleTest CMake Quickstart](https://google.github.io/googletest/quickstart-cmake.html)
- [CMake enable_testing()](https://cmake.org/cmake/help/latest/command/enable_testing.html)
- [CMake add_test()](https://cmake.org/cmake/help/latest/command/add_test.html)
- [GoogleTest Module](https://cmake.org/cmake/help/latest/module/GoogleTest.html)

---

That's all, folks! Happy testing!
