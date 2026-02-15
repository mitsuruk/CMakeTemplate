# nlohmann-json.cmake Reference

## Overview

`nlohmann-json.cmake` is a CMake configuration file that automatically downloads and configures the nlohmann/json library.
It uses CMake's `file(DOWNLOAD)` to manage the dependency, with caching in the `download/` directory to avoid redundant downloads.

nlohmann/json is a modern, header-only C++ JSON library. It provides intuitive syntax similar to Python dictionaries, full STL integration, serialization/deserialization, and comprehensive type safety.

Since nlohmann/json is header-only, no compilation or linking is required. Only the include path needs to be configured.

## File Information

| Item | Details |
|------|---------|
| Install Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/nlohmann-json-install` |
| Download URL | https://github.com/nlohmann/json/releases/download/v3.12.0/json.hpp |
| Version | 3.12.0 |
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
nlohmann-json/
├── cmake/
│   ├── nlohmann-json.cmake    # This configuration file
│   └── nlohmann-jsonCmake.md  # This document
├── download/nlohmann-json
│   ├── json.hpp               # Cached download (single header file)
│   └── nlohmann-json-install/ # Installed header
│       └── include/
│           └── nlohmann/
│               └── json.hpp   # The header used by the project
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## Usage

### Adding to CMakeLists.txt

```cmake
include("./cmake/nlohmann-json.cmake")
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
set(NLOHMANN_JSON_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(NLOHMANN_JSON_INSTALL_DIR ${NLOHMANN_JSON_DOWNLOAD_DIR}/nlohmann-json-install)
set(NLOHMANN_JSON_VERSION "3.12.0")
set(NLOHMANN_JSON_URL "https://github.com/nlohmann/json/releases/download/v${NLOHMANN_JSON_VERSION}/json.hpp")
```

### 2. Cache Check and Conditional Download

```cmake
if(EXISTS ${NLOHMANN_JSON_INSTALL_DIR}/include/nlohmann/json.hpp)
    message(STATUS "nlohmann-json already installed")
else()
    # Download and install ...
endif()
```

The cache logic works as follows:

| Condition | Action |
|-----------|--------|
| `nlohmann-json-install/include/nlohmann/json.hpp` exists | Skip everything (use cached) |
| `download/json.hpp` exists (install missing) | Skip download, copy to install |
| Nothing exists | Download from GitHub, copy to install |

### 3. Download (if needed)

```cmake
file(DOWNLOAD
    ${NLOHMANN_JSON_URL}
    ${NLOHMANN_JSON_CACHED}
    SHOW_PROGRESS
    STATUS DOWNLOAD_STATUS
)
```

- Downloads the single-header `json.hpp` from GitHub Releases
- Only one file (~900KB) needs to be downloaded

### 4. Install

```cmake
file(COPY ${NLOHMANN_JSON_CACHED}
    DESTINATION ${NLOHMANN_JSON_INSTALL_DIR}/include/nlohmann
)
```

- Copies `json.hpp` into `include/nlohmann/` to match the standard `#include <nlohmann/json.hpp>` path
- No compilation step is needed (header-only library)

### 5. Configuring Include Path

```cmake
target_include_directories(${PROJECT_NAME} PRIVATE
    ${NLOHMANN_JSON_INSTALL_DIR}/include
)
```

Unlike GSL or ALGLIB, nlohmann/json is header-only. No `add_library`, `target_link_libraries`, or static library creation is needed.

---

## nlohmann/json Library

nlohmann/json consists of a single header file:

| File | Size | Description |
|------|------|-------------|
| `json.hpp` | ~900KB | Single-header library containing all functionality |

---

## Key Features of nlohmann/json

| Feature | Description |
|---------|-------------|
| Intuitive Syntax | `j["key"]` access, initializer list construction |
| STL Integration | Works with `std::vector`, `std::map`, `std::string`, etc. |
| Type Safety | `get<T>()` for explicit type conversion, `is_*()` for type checking |
| Serialization | `dump()` for JSON-to-string with optional pretty-printing |
| Deserialization | `parse()` for string-to-JSON conversion |
| JSON Pointer | RFC 6901 JSON Pointer support (`j["/path/to/key"_json_pointer]`) |
| JSON Patch | RFC 6902 JSON Patch support for diff and merge |
| Iterator Support | Range-based for loops, `items()` for key-value iteration |
| Error Handling | Exception-based with `parse_error`, `type_error`, `out_of_range` |
| Custom Types | `to_json`/`from_json` for user-defined type serialization |
| CBOR/MessagePack | Binary serialization format support |

---

## Usage Examples in C/C++

### Parse and Access

```cpp
#include <nlohmann/json.hpp>
#include <iostream>

int main() {
    std::string s = R"({"name":"John","age":30})";
    nlohmann::json j = nlohmann::json::parse(s);

    std::cout << "Name: " << j["name"].get<std::string>() << "\n";
    std::cout << "Age: " << j["age"].get<int>() << "\n";

    return 0;
}
```

### Build JSON Programmatically

```cpp
#include <nlohmann/json.hpp>
#include <iostream>

int main() {
    nlohmann::json j = {
        {"name", "Alice"},
        {"age", 25},
        {"skills", {"C++", "Python", "Rust"}}
    };

    std::cout << j.dump(4) << "\n";
    return 0;
}
```

### Modify and Serialize

```cpp
#include <nlohmann/json.hpp>
#include <iostream>

int main() {
    nlohmann::json j = {{"name", "John"}, {"age", 30}};

    j["age"] = 31;
    j["email"] = "john@example.com";
    j.erase("name");

    // Pretty print (4-space indent)
    std::cout << j.dump(4) << "\n";

    // Compact
    std::cout << j.dump() << "\n";

    return 0;
}
```

### Safe Access with Default Values

```cpp
#include <nlohmann/json.hpp>
#include <iostream>

int main() {
    nlohmann::json j = {{"name", "John"}};

    // value() returns the default if key is missing
    std::string email = j.value("email", "N/A");
    int age = j.value("age", -1);

    std::cout << "Email: " << email << "\n";  // "N/A"
    std::cout << "Age: " << age << "\n";       // -1

    // contains() checks key existence
    if (j.contains("name")) {
        std::cout << "Name: " << j["name"].get<std::string>() << "\n";
    }

    return 0;
}
```

### Iteration

```cpp
#include <nlohmann/json.hpp>
#include <iostream>

int main() {
    nlohmann::json j = {
        {"name", "Alice"},
        {"scores", {95, 87, 92}}
    };

    // Iterate over key-value pairs
    for (auto& [key, val] : j.items()) {
        std::cout << key << " -> " << val.dump() << "\n";
    }

    // Iterate over array
    for (const auto& score : j["scores"]) {
        std::cout << score.get<int>() << " ";
    }
    std::cout << "\n";

    return 0;
}
```

### Type Checking

```cpp
#include <nlohmann/json.hpp>
#include <iostream>

int main() {
    nlohmann::json j = {
        {"str", "hello"},
        {"num", 42},
        {"arr", {1, 2, 3}},
        {"nil", nullptr}
    };

    for (auto& [key, val] : j.items()) {
        std::cout << key << " is ";
        if (val.is_string())        std::cout << "string";
        else if (val.is_number())   std::cout << "number";
        else if (val.is_array())    std::cout << "array";
        else if (val.is_null())     std::cout << "null";
        std::cout << "\n";
    }

    return 0;
}
```

### Error Handling

```cpp
#include <nlohmann/json.hpp>
#include <iostream>

int main() {
    // Parse error
    try {
        nlohmann::json j = nlohmann::json::parse("{invalid}");
    } catch (const nlohmann::json::parse_error& e) {
        std::cout << "Parse error: " << e.what() << "\n";
    }

    // Type error
    nlohmann::json j = {{"name", "John"}};
    try {
        int val = j["name"].get<int>();  // string -> int fails
        (void)val;
    } catch (const nlohmann::json::type_error& e) {
        std::cout << "Type error: " << e.what() << "\n";
    }

    // Out of range
    try {
        auto val = j.at("nonexistent");
        (void)val;
    } catch (const nlohmann::json::out_of_range& e) {
        std::cout << "Out of range: " << e.what() << "\n";
    }

    return 0;
}
```

### Custom Type Serialization

```cpp
#include <nlohmann/json.hpp>
#include <iostream>

struct Person {
    std::string name;
    int age;
};

void to_json(nlohmann::json& j, const Person& p) {
    j = nlohmann::json{{"name", p.name}, {"age", p.age}};
}

void from_json(const nlohmann::json& j, Person& p) {
    j.at("name").get_to(p.name);
    j.at("age").get_to(p.age);
}

int main() {
    Person p = {"Alice", 30};
    nlohmann::json j = p;
    std::cout << j.dump(4) << "\n";

    Person p2 = j.get<Person>();
    std::cout << p2.name << ", " << p2.age << "\n";

    return 0;
}
```

---

## nlohmann/json API Conventions

### Namespace

All functionality is in the `nlohmann` namespace:

```cpp
nlohmann::json j;

// Common alias
using json = nlohmann::json;
json j2;
```

### Value Access

| Method | Description |
|--------|-------------|
| `j["key"]` | Access by key (creates if missing) |
| `j.at("key")` | Access by key (throws if missing) |
| `j.value("key", default)` | Access with default fallback |
| `j.get<T>()` | Explicit type conversion |
| `j.contains("key")` | Check if key exists |

### Serialization

| Method | Description |
|--------|-------------|
| `j.dump()` | Compact JSON string |
| `j.dump(4)` | Pretty-printed with 4-space indent |
| `nlohmann::json::parse(str)` | Parse from string |

### Type Checking

| Method | Description |
|--------|-------------|
| `j.is_string()` | Check if string |
| `j.is_number()` | Check if number (int or float) |
| `j.is_number_integer()` | Check if integer |
| `j.is_number_float()` | Check if floating point |
| `j.is_boolean()` | Check if boolean |
| `j.is_null()` | Check if null |
| `j.is_array()` | Check if array |
| `j.is_object()` | Check if object |

### Modification

| Method | Description |
|--------|-------------|
| `j["key"] = value` | Set/update value |
| `j.push_back(val)` | Append to array |
| `j.erase("key")` | Remove key from object |
| `j.clear()` | Remove all elements |
| `j.merge_patch(other)` | Merge another JSON object |

### Error Types

| Exception | When |
|-----------|------|
| `nlohmann::json::parse_error` | Invalid JSON syntax |
| `nlohmann::json::type_error` | Wrong type access (e.g., string as int) |
| `nlohmann::json::out_of_range` | Key/index does not exist (with `at()`) |
| `nlohmann::json::invalid_iterator` | Invalid iterator operation |
| `nlohmann::json::other_error` | Other errors |

---

## Comparison: nlohmann/json vs Other JSON Libraries

| Feature | nlohmann/json | RapidJSON | simdjson | Boost.JSON |
|---------|--------------|-----------|----------|------------|
| License | MIT | MIT | Apache 2 | BSL 1.0 |
| Header-only | Yes | Yes | No | No |
| C++ Standard | C++11+ | C++11+ | C++17+ | C++11+ |
| Ease of Use | Excellent | Moderate | Moderate | Good |
| Parse Speed | Good | Fast | Fastest | Good |
| Memory Usage | Higher | Lower | Lower | Moderate |
| STL Integration | Full | Minimal | Minimal | Good |
| Custom Types | Yes (to/from_json) | Manual | Read-only | Yes |
| Binary Formats | CBOR, MessagePack, UBJSON, BSON | No | No | No |

nlohmann/json prioritizes ease of use and developer experience over raw performance.
For most applications, its performance is more than sufficient. For high-throughput parsing scenarios, consider RapidJSON or simdjson.

---

## Troubleshooting

### Download Fails

If GitHub is unreachable, you can manually download and place the header:

```bash
curl -L -o download/json.hpp \
    https://github.com/nlohmann/json/releases/download/v3.12.0/json.hpp
```

Then re-run `cmake ..` and the installation will proceed from the cached file.

### Rebuild from Scratch

To force a fresh download and install:

```bash
rm -rf download/nlohmann-json-install download/json.hpp
cd build && cmake ..
```

### Header Not Found

Ensure the include directory is correctly configured:

```cmake
target_include_directories(${PROJECT_NAME} PRIVATE ${NLOHMANN_JSON_INSTALL_DIR}/include)
```

The header should be included as:

```cpp
#include <nlohmann/json.hpp>   // OK
// #include "json.hpp"         // NG (wrong path)
```

### Compilation Slow

`json.hpp` is a large single-header file (~900KB). This can increase compile times. If this is a concern:

- Use precompiled headers (PCH) to cache the parsed header
- Consider using the multi-header version from the GitHub repository instead

---

## References

- [nlohmann/json GitHub Repository](https://github.com/nlohmann/json)
- [nlohmann/json Documentation](https://json.nlohmann.me/)
- [nlohmann/json API Reference](https://json.nlohmann.me/api/basic_json/)
- [JSON Specification (RFC 8259)](https://tools.ietf.org/html/rfc8259)
- [JSON Pointer (RFC 6901)](https://tools.ietf.org/html/rfc6901)
- [CMake file(DOWNLOAD) Documentation](https://cmake.org/cmake/help/latest/command/file.html#download)
