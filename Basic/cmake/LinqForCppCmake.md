# LinqForCpp.cmake Reference

## Overview

`LinqForCpp.cmake` is a CMake configuration file that automatically downloads and configures the LinqForCpp library.
It uses CMake's `file(DOWNLOAD)` and `execute_process()` to manage the dependency, with caching in the `download/` directory to avoid redundant downloads.

LinqForCpp is a C++ implementation of LINQ (Language Integrated Query), bringing C#-style query capabilities to C++. It provides a fluent API using the `<<` operator for chaining operations like filtering, transformation, sorting, and aggregation on any iterable collection.

Since LinqForCpp is header-only, no compilation or linking is required. Only the include path needs to be configured.

## File Information

| Item | Details |
|------|---------|
| Install Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/LinqForCpp/LinqForCpp-install` |
| Download URL | https://github.com/harayuu9/LinqForCpp/releases/download/v1.0.1/LinqForCpp.zip |
| Version | 1.0.1 |
| License | MIT License |

---

## Include Guard

```cmake
include_guard(GLOBAL)
```

This file uses `include_guard(GLOBAL)` to ensure it is only executed once, even if included multiple times.

**Why it's needed:**

- Prevents duplicate `file(DOWNLOAD)` invocations during configure
- Prevents duplicate `target_include_directories` calls

---

## Directory Structure

```
LinqForCpp/
├── cmake/
│   ├── LinqForCpp.cmake          # This configuration file
│   ├── LinqForCppCmake.md        # This document (English)
│   └── LinqForCppCmake-jp.md     # This document (Japanese)
├── download/LinqForCpp/
│   ├── LinqForCpp.zip            # Cached download (zip archive)
│   └── LinqForCpp-install/       # Installed headers
│       └── include/
│           ├── SingleHeader/
│           │   └── Linq.hpp      # Single-header version (~73KB)
│           └── Linq/
│               ├── Linq.h        # Split-header entry point
│               ├── Where.h
│               ├── Select.h
│               ├── OrderBy.h
│               └── ...           # Other operation headers
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## Usage

### Adding to CMakeLists.txt

```cmake
include("./cmake/LinqForCpp.cmake")
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
set(LINQFORCPP_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/LinqForCpp)
set(LINQFORCPP_INSTALL_DIR ${LINQFORCPP_DOWNLOAD_DIR}/LinqForCpp-install)
set(LINQFORCPP_VERSION "1.0.1")
set(LINQFORCPP_URL "https://github.com/harayuu9/LinqForCpp/releases/download/v${LINQFORCPP_VERSION}/LinqForCpp.zip")
```

### 2. Cache Check and Conditional Download

```cmake
if(EXISTS ${LINQFORCPP_INSTALL_DIR}/include/SingleHeader/Linq.hpp)
    message(STATUS "LinqForCpp already installed")
else()
    # Download and install ...
endif()
```

The cache logic works as follows:

| Condition | Action |
|-----------|--------|
| `LinqForCpp-install/include/SingleHeader/Linq.hpp` exists | Skip everything (use cached) |
| `download/LinqForCpp/LinqForCpp.zip` exists (install missing) | Skip download, extract to install |
| Nothing exists | Download from GitHub, extract to install |

### 3. Download (if needed)

```cmake
file(DOWNLOAD
    ${LINQFORCPP_URL}
    ${LINQFORCPP_CACHED}
    SHOW_PROGRESS
    STATUS DOWNLOAD_STATUS
)
```

- Downloads `LinqForCpp.zip` from GitHub Releases (~160KB)
- Contains both single-header and split-header versions

### 4. Extract and Install

```cmake
execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar xzf ${LINQFORCPP_CACHED}
    WORKING_DIRECTORY ${LINQFORCPP_INSTALL_DIR}/include
)
```

- Extracts the zip archive into the install directory
- Creates `SingleHeader/Linq.hpp` and `Linq/*.h` directory structures
- No compilation step is needed (header-only library)

### 5. Configuring Include Path

```cmake
target_include_directories(${PROJECT_NAME} PRIVATE
    ${LINQFORCPP_INSTALL_DIR}/include
)
```

Unlike compiled libraries, LinqForCpp is header-only. No `add_library`, `target_link_libraries`, or static library creation is needed.

---

## LinqForCpp Library

LinqForCpp provides two include options:

| File | Size | Description |
|------|------|-------------|
| `SingleHeader/Linq.hpp` | ~73KB | Single-header version (all-in-one) |
| `Linq/Linq.h` | ~1.5KB | Split-header entry point (includes all operation headers) |

---

## Key Features of LinqForCpp

| Feature | Description |
|---------|-------------|
| Fluent API | Chain operations using `<<` operator |
| Lazy Evaluation | Most operations use deferred execution |
| C++17/C++20 | Requires C++17 or later |
| STL Compatible | Works with any collection supporting `std::begin()`/`std::end()` |
| Macro Syntax | Convenience macros like `WHERE(v, cond)`, `SELECT(v, expr)` |
| Custom Allocator | Internal memory management with configurable allocator |

---

## Available Operations

### Filtering

| Operation | Description |
|-----------|-------------|
| `Where(func)` | Filter elements matching a predicate |
| `Distinct()` | Remove duplicate elements |

### Transformation

| Operation | Description |
|-----------|-------------|
| `Select(func)` | Transform each element |
| `SelectMany(func)` | Transform and flatten nested collections |
| `Reverse()` | Reverse element order |
| `ZipWith(other)` | Combine two sequences into pairs |
| `PairWise()` | Create pairs of consecutive elements |

### Sorting

| Operation | Description |
|-----------|-------------|
| `OrderBy(func, isAscending)` | Sort by key with direction flag |
| `OrderByAscending(func)` | Sort by key ascending |
| `OrderByDescending(func)` | Sort by key descending |
| `ThenBy(func, isAscending)` | Secondary sort (after OrderBy) |

### Aggregation

| Operation | Description |
|-----------|-------------|
| `Sum()` | Sum of all elements |
| `Min()` | Minimum element |
| `Max()` | Maximum element |
| `MinMax()` | Both min and max as `std::pair` |
| `Avg<Result>()` | Average (specify result type) |
| `Count()` | Count all elements |
| `Count(func)` | Count elements matching predicate |
| `Aggregate(init, func)` | Fold/reduce with accumulator |

### Element Access

| Operation | Description |
|-----------|-------------|
| `First(func)` | First element matching predicate (throws if none) |
| `Last(func)` | Last element matching predicate (throws if none) |
| `FirstOrDefault(func)` | First matching element or default value |
| `LastOrDefault(func)` | Last matching element or default value |
| `Contains(value)` | Check if sequence contains a value |

### Quantifiers

| Operation | Description |
|-----------|-------------|
| `Any(func)` | True if any element matches |
| `All(func)` | True if all elements match |
| `SequenceEqual(other)` | True if two sequences are equal |

### Partitioning

| Operation | Description |
|-----------|-------------|
| `Take(n)` | Take first n elements |
| `TakeWhile(func)` | Take while predicate is true |
| `Skip(n)` | Skip first n elements |
| `SkipWhile(func)` | Skip while predicate is true |

### Generators

| Operation | Description |
|-----------|-------------|
| `Range(start, count)` | Generate arithmetic sequence |
| `Repeat(value, count)` | Generate repeated value |
| `Singleton(value)` | Single-element sequence |
| `Empty<T>()` | Empty sequence of type T |

### Materialization

| Operation | Description |
|-----------|-------------|
| `ToVector()` | Convert to `std::vector` |
| `ToList()` | Convert to `std::list` |

---

## Usage Examples in C/C++

### Where and Select

```cpp
#include <SingleHeader/Linq.hpp>
#include <iostream>
#include <vector>

int main() {
    std::vector<int> numbers = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

    auto evens = numbers
        << linq::Where([](const int v) { return v % 2 == 0; })
        << linq::Select([](const int v) { return v * v; })
        << linq::ToVector();

    for (const auto& v : evens) {
        std::cout << v << " ";  // 4 16 36 64 100
    }
    return 0;
}
```

### OrderBy

```cpp
#include <SingleHeader/Linq.hpp>
#include <iostream>
#include <vector>
#include <string>

int main() {
    std::vector<std::string> words = {"banana", "apple", "cherry"};

    auto sorted = words
        << linq::OrderByAscending([](const std::string& s) { return s; })
        << linq::ToVector();

    for (const auto& w : sorted) {
        std::cout << w << " ";  // apple banana cherry
    }
    return 0;
}
```

### Aggregation

```cpp
#include <SingleHeader/Linq.hpp>
#include <iostream>
#include <vector>

int main() {
    std::vector<int> numbers = {3, 7, 1, 9, 4};

    auto sum = numbers << linq::Sum();
    auto avg = numbers << linq::Avg<double>();
    auto [min, max] = numbers << linq::MinMax();

    std::cout << "Sum: " << sum << "\n";  // 24
    std::cout << "Avg: " << avg << "\n";  // 4.8
    std::cout << "Min: " << min << ", Max: " << max << "\n";  // 1, 9

    return 0;
}
```

### Take, Skip, and Pagination

```cpp
#include <SingleHeader/Linq.hpp>
#include <iostream>
#include <vector>

int main() {
    std::vector<int> numbers = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

    // Page 2 (items 4-6)
    auto page = numbers
        << linq::Skip(3)
        << linq::Take(3)
        << linq::ToVector();

    for (const auto& v : page) {
        std::cout << v << " ";  // 4 5 6
    }
    return 0;
}
```

### Range and FizzBuzz

```cpp
#include <SingleHeader/Linq.hpp>
#include <iostream>
#include <string>

int main() {
    auto fizzbuzz = linq::Range(1, 15)
        << linq::Select([](const int v) -> std::string {
            if (v % 15 == 0) return "FizzBuzz";
            if (v % 3 == 0)  return "Fizz";
            if (v % 5 == 0)  return "Buzz";
            return std::to_string(v);
        })
        << linq::ToVector();

    for (const auto& s : fizzbuzz) {
        std::cout << s << " ";
    }
    return 0;
}
```

### Using Macros

```cpp
#include <SingleHeader/Linq.hpp>
#include <iostream>
#include <vector>
#include <string>

int main() {
    std::vector<int> numbers = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

    // Macro syntax (alternative to lambda)
    auto result = numbers
        << WHERE(v, v > 5)
        << SELECT(v, std::to_string(v))
        << linq::ToVector();

    for (const auto& s : result) {
        std::cout << s << " ";  // 6 7 8 9 10
    }
    return 0;
}
```

### ZipWith

```cpp
#include <SingleHeader/Linq.hpp>
#include <iostream>
#include <vector>
#include <string>

int main() {
    std::vector<std::string> names = {"Alice", "Bob", "Charlie"};
    std::vector<int> scores = {95, 87, 92};

    auto zipped = names
        << linq::ZipWith(scores)
        << linq::ToVector();

    for (const auto& [name, score] : zipped) {
        std::cout << name << ": " << score << "\n";
    }
    return 0;
}
```

---

## LinqForCpp API Conventions

### Namespace

All functionality is in the `linq` namespace:

```cpp
#include <SingleHeader/Linq.hpp>

// Use operations via linq:: prefix
auto result = arr << linq::Where([](auto v) { return v > 0; });
```

### Operator `<<`

The `<<` operator is the core of LinqForCpp. It passes a collection to a builder object:

```cpp
auto result = collection << linq::Operation(args);
```

Operations can be chained:

```cpp
auto result = collection
    << linq::Where(predicate)
    << linq::Select(transform)
    << linq::OrderByAscending(keySelector)
    << linq::ToVector();
```

### Execution Model

| Type | Execution | Examples |
|------|-----------|---------|
| Lazy | Deferred until iteration | Where, Select, Take, Skip, Reverse, ZipWith, PairWise |
| Immediate | Executes immediately | Sum, Min, Max, Count, Avg, Aggregate, Contains, Any, All, OrderBy, Distinct, First, Last, ToVector, ToList |

### Macro Alternatives

| Macro | Equivalent |
|-------|------------|
| `WHERE(v, cond)` | `linq::Where([&](const auto& v) { return cond; })` |
| `SELECT(v, expr)` | `linq::Select([&](const auto& v) { return expr; })` |
| `SELECT_MANY(v, expr)` | `linq::SelectMany([&](const auto& v) { return expr; })` |
| `ORDER_BY(v, key, asc)` | `linq::OrderBy([&](const auto& v) { return key; }, asc)` |
| `ORDER_BY_ASCENDING(v, key)` | `linq::OrderByAscending([&](const auto& v) { return key; })` |
| `ORDER_BY_DESCENDING(v, key)` | `linq::OrderByDescending([&](const auto& v) { return key; })` |
| `COUNT(v, cond)` | `linq::Count([&](const auto& v) { return cond; })` |
| `ANY(v, cond)` | `linq::Any([&](const auto& v) { return cond; })` |
| `ALL(v, cond)` | `linq::All([&](const auto& v) { return cond; })` |
| `FIRST(v, cond)` | `linq::First([&](const auto& v) { return cond; })` |
| `LAST(v, cond)` | `linq::Last([&](const auto& v) { return cond; })` |
| `FIRST_OR_DEFAULT(v, cond)` | `linq::FirstOrDefault([&](const auto& v) { return cond; })` |
| `LAST_OR_DEFAULT(v, cond)` | `linq::LastOrDefault([&](const auto& v) { return cond; })` |
| `AGGREGATE(init, a, b, expr)` | `linq::Aggregate(init, [&](const auto& a, const auto& b) { return expr; })` |

---

## Comparison: LinqForCpp vs Other C++ Query Libraries

| Feature | LinqForCpp | ranges (C++20) | Boost.Range | cpplinq |
|---------|-----------|----------------|-------------|---------|
| License | MIT | Standard Library | BSL 1.0 | MIT |
| C++ Standard | C++17+ | C++20+ | C++11+ | C++11+ |
| Header-only | Yes | Yes (stdlib) | No | Yes |
| Operator Style | `<<` | `\|` | `\|` | `>>` |
| Lazy Evaluation | Most ops | All views | All adaptors | Most ops |
| C# LINQ Similarity | High | Low | Low | High |
| STL Compatible | Yes | Yes | Yes | Limited |
| Aggregation | Yes | Limited | Limited | Yes |
| Custom Allocator | Yes | No | No | No |

---

## Troubleshooting

### Download Fails

If GitHub is unreachable, you can manually download and place the archive:

```bash
curl -L -o download/LinqForCpp/LinqForCpp.zip \
    https://github.com/harayuu9/LinqForCpp/releases/download/v1.0.1/LinqForCpp.zip
```

Then re-run `cmake ..` and the installation will proceed from the cached file.

### Rebuild from Scratch

To force a fresh download and install:

```bash
rm -rf download/LinqForCpp/LinqForCpp-install download/LinqForCpp/LinqForCpp.zip
cd build && cmake ..
```

### Header Not Found

Ensure the include directory is correctly configured:

```cmake
target_include_directories(${PROJECT_NAME} PRIVATE ${LINQFORCPP_INSTALL_DIR}/include)
```

The header should be included as:

```cpp
#include <SingleHeader/Linq.hpp>   // Single-header version
// or
#include <Linq/Linq.h>            // Split-header version
```

### Compilation Errors with C++14 or Earlier

LinqForCpp requires C++17 or later. Ensure your CMakeLists.txt specifies at least C++17:

```cmake
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_17)
```

---

## References

- [LinqForCpp GitHub Repository](https://github.com/harayuu9/LinqForCpp)
- [LinqForCpp Releases](https://github.com/harayuu9/LinqForCpp/releases)
- [LINQ Documentation (C#)](https://learn.microsoft.com/en-us/dotnet/csharp/linq/)
- [CMake file(DOWNLOAD) Documentation](https://cmake.org/cmake/help/latest/command/file.html#download)
- [CMake execute_process Documentation](https://cmake.org/cmake/help/latest/command/execute_process.html)
