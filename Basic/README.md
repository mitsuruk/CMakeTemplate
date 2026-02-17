# CMake Template Project (macOS + Clang + C++)

A CMake template project for C++ development on macOS using the Clang compiler.
Supports modern C++ standards from C++17 onwards.

## Features

- CMake configuration optimized for macOS
- Compatible with AppleClang toolchain and Homebrew environment
- Flexible integration of libraries such as Boost, GoogleTest, and SQLite3
- Support for code generation tools including Flex/Bison, gRPC, and ANTLR

## License

MIT License - See [LICENSE.md](LICENSE.md) for details

---

## Directory Layout

See the **Directory Layout** section in the [top-level README](../README.md) for the full directory tree.

---

## File Descriptions

### Build Configuration Files

| File | Description |
|------|-------------|
| **CMakeLists.txt** | Main build configuration |
| **CMAKE.md** | Detailed CMakeLists.txt usage guide |

### Source Code

| File | Description |
|------|-------------|
| **src/main.cpp** | Sample source (compiler info, CMake definitions demo) |
| **src/include/** | Header files |

### Tests (test/ directory)

| File | Description |
|------|-------------|
| **test/test_main.cpp** | GoogleTest sample tests |
| **test/googleTest.md** | GoogleTest usage guide |
| **test/README.md** | Test build/run instructions |

### Extension Modules (`cmake/` directory)

See the **Extension Modules (`cmake/` directory)** section in the [top-level README](../README.md) for the full module list and descriptions. Each `.cmake` file has a companion `*Cmake.md` documentation file.

### Documentation

| File | Description |
|------|-------------|
| **README.md** | Template overview and quick start |
| **CMAKE.md** | Detailed CMakeLists.txt usage guide |
| **LICENSE.md** | MIT License |

### Other

| File | Description |
|------|-------------|
| **.gitignore** | Git exclusion settings |
| **Doxyfile** | Doxygen configuration |

---

## Quick Start

### Basic Build

```bash
# Create build directory
mkdir build && cd build

# CMake configuration (Release build)
cmake ..

# Build
cmake --build .

# Run
./a.out
```

### Debug Build

```bash
cmake -DDEBUG=true ..
cmake --build .
```

### Enable Sanitizers (Memory Error Detection)

```bash
cmake -DSANI=true ..
cmake --build .
```

### Enable GoogleTest

```bash
cmake -DGTEST=true ..
cmake --build .
```

---

## Detailed Information

For detailed usage of each feature, see [CMAKE.md](CMAKE.md).

---

## Requirements

- CMake 3.20 or later
- AppleClang (Xcode Command Line Tools)
- Homebrew (optional, required when using various libraries)
