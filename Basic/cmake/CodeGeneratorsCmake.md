# CodeGenerators.cmake Reference

## Overview

`CodeGenerators.cmake` is a configuration file for integrating external code generation tools into a CMake project. It supports the following three code generation systems:

1. **Flex & Bison** - Lexical analysis and parsing
2. **gRPC & Protocol Buffers** - RPC interfaces
3. **ANTLR** - Grammar-based parsers

## File Information

| Item | Details |
|------|---------|
| Project | CMake Template Project |
| Author | mitsuruk |
| Created | 2025/11/26 |
| License | MIT License |

---

## Overall Structure

```cmake
include_guard(GLOBAL)  # Prevent duplicate inclusion

# 1. Flex & Bison integration (if the grammar directory exists)
# 2. gRPC & Protocol Buffers integration (if the protos directory exists)
# 3. ANTLR integration (if the antlr directory exists)
```

Each section is only executed if the corresponding directory exists.

---

## 1. Flex & Bison Integration

### Activation Condition

```cmake
if(EXISTS "${PROJECT_SOURCE_DIR}/grammar")
```

Activated when the `grammar` directory exists.

### Processing Flow

```
1. Search for Flex/Bison packages
2. Search and process *.y files (Bison grammars)
3. Search and process *.l files (Flex lexers)
4. Add generated sources to the project
```

### Processing Bison Files

```cmake
file(GLOB BISON_SOURCES "${PROJECT_SOURCE_DIR}/grammar/*.y")
foreach(bison_file ${BISON_SOURCES})
    get_filename_component(bison_name ${bison_file} NAME_WE)
    BISON_TARGET(${bison_name} ${bison_file}
        ${PROJECT_BINARY_DIR}/${bison_name}.tab.c
        DEFINES_FILE ${PROJECT_BINARY_DIR}/${bison_name}.tab.h)
    list(APPEND GENERATED_YACC_LEX ${BISON_${bison_name}_OUTPUTS})
endforeach()
```

| Input | Output |
|-------|--------|
| `grammar/parser.y` | `parser.tab.c`, `parser.tab.h` |

### Processing Flex Files

```cmake
file(GLOB FLEX_SOURCES "${PROJECT_SOURCE_DIR}/grammar/*.l")
foreach(flex_file ${FLEX_SOURCES})
    get_filename_component(flex_name ${flex_file} NAME_WE)
    FLEX_TARGET(${flex_name} ${flex_file}
        ${PROJECT_BINARY_DIR}/${flex_name}.yy.c)
    list(APPEND GENERATED_YACC_LEX ${FLEX_${flex_name}_OUTPUTS})
endforeach()
```

| Input | Output |
|-------|--------|
| `grammar/lexer.l` | `lexer.yy.c` |

### Directory Structure

```
project/
├── grammar/
│   ├── parser.y    # Bison grammar file
│   └── lexer.l     # Flex lexer file
└── CMakeLists.txt
```

---

## 2. gRPC & Protocol Buffers Integration

### Activation Condition

```cmake
if(EXISTS "${PROJECT_SOURCE_DIR}/protos")
```

Activated when the `protos` directory exists.

### Processing Flow

```
1. Search for Protobuf/gRPC packages
2. Search for *.proto files
3. Generate C++ code from each .proto file
4. Create a static library
5. Link to the main project
```

### Generated Files

The following are generated from each `.proto` file:

| Generated File | Description |
|-----------------|-------------|
| `{name}.pb.cc` | Protobuf message implementation |
| `{name}.pb.h` | Protobuf message header |
| `{name}.grpc.pb.cc` | gRPC service implementation |
| `{name}.grpc.pb.h` | gRPC service header |

### Custom Command

```cmake
add_custom_command(
    OUTPUT "${proto_src}" "${proto_hdr}" "${grpc_src}" "${grpc_hdr}"
    COMMAND ${_PROTOBUF_PROTOC}
    ARGS --proto_path="${PROJECT_SOURCE_DIR}/protos"
         --cpp_out="${CMAKE_CURRENT_BINARY_DIR}"
         --grpc_out="${CMAKE_CURRENT_BINARY_DIR}"
         --plugin=protoc-gen-grpc="${_GRPC_CPP_PLUGIN_EXECUTABLE}"
         "${proto_file}"
    DEPENDS "${proto_file}"
)
```

### Generated Library

```cmake
set(PRJ_PROTO "${DIR_NAME}_grpc_proto")
add_library(${PRJ_PROTO} ${GENERATED_GRPC_SRCS} ${GENERATED_GRPC_HDRS})
```

Library name: `{DIR_NAME}_grpc_proto`

### Directory Structure

```
project/
├── protos/
│   ├── service.proto
│   └── messages.proto
└── CMakeLists.txt
```

---

## 3. ANTLR Integration

### Activation Condition

```cmake
if(EXISTS "${PROJECT_SOURCE_DIR}/antlr")
```

Activated when the `antlr` directory exists.

### Processing Flow

```
1. Set C++17 standard
2. Search for ANTLR tool
3. Search for antlr4-runtime package
4. Search and process *.g4 grammar files
5. Create a static library
6. Link to the main project
```

### Generated Files

The following are generated from each `.g4` file:

| Generated File | Description |
|-----------------|-------------|
| `{name}Parser.cpp` | Parser implementation |
| `{name}Parser.h` | Parser header |
| `{name}Lexer.cpp` | Lexer implementation |
| `{name}Lexer.h` | Lexer header |
| `{name}Listener.h` | Listener interface |
| `{name}Visitor.h` | Visitor interface |

### Custom Command

```cmake
add_custom_command(
    OUTPUT "${parser_cpp}" "${parser_h}" "${lexer_cpp}" "${lexer_h}"
           "${listener_h}" "${visitor_h}"
    COMMAND ${ANTLR4_EXECUTABLE}
    ARGS -Dlanguage=Cpp
         -o "${CMAKE_CURRENT_BINARY_DIR}"
         "${grammar_file}"
    DEPENDS "${grammar_file}"
    COMMENT "Generating ANTLR4 C++ files from ${grammar_file}"
    VERBATIM
)
```

### Homebrew Support

```cmake
find_program(BREW_COMMAND brew)
if(BREW_COMMAND)
    # Add Homebrew ANTLR runtime path
    target_include_directories(${PRJ_ANTLR} PUBLIC
        ${BREW_DIR}/include/antlr4-runtime)
endif()
```

On macOS with Homebrew, the ANTLR runtime path is automatically added.

### Directory Structure

```
project/
├── antlr/
│   ├── MyGrammar.g4
│   └── AnotherGrammar.g4
└── CMakeLists.txt
```

---

## Dependencies

### Flex & Bison

| Dependency | Required/Optional |
|------------|-------------------|
| Flex | Required |
| Bison | Required |

### gRPC & Protocol Buffers

| Dependency | Required/Optional |
|------------|-------------------|
| Protobuf | Required |
| gRPC | Required |
| `${DIR_NAME}` | Required (used for library name) |

### ANTLR

| Dependency | Required/Optional |
|------------|-------------------|
| ANTLR4 tool (`antlr` command) | Required |
| antlr4-runtime | Required |

---

## Usage

1. Create the required directories:
   - Flex/Bison: `grammar/`
   - gRPC: `protos/`
   - ANTLR: `antlr/`

2. Place source files in the directories

3. Include from the main `CMakeLists.txt`:

```cmake
include(cmake/CodeGenerators.cmake)
```

---

## Notes

1. **include_guard**: `include_guard(GLOBAL)` ensures the file is only executed once, even if included multiple times.

2. **Conditional execution**: Each code generation tool is only activated if the corresponding directory exists. This avoids dependency errors for tools that are not needed.

3. **Generated file location**: All generated files are output to `${CMAKE_CURRENT_BINARY_DIR}` (the build directory).

4. **C++17 requirement**: The ANTLR section requires C++17. This may affect the entire project.

5. **Target definition order**: The `${PROJECT_NAME}` target must be defined before including this file.
