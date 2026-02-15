# gmp.cmake Reference

## Overview

`gmp.cmake` is a CMake configuration file that automatically downloads, builds, and links the GMP library.
It uses CMake's `file(DOWNLOAD)` and `execute_process` to manage the dependency, with caching in the `download/` directory to avoid redundant downloads and rebuilds.

GMP (GNU Multiple Precision Arithmetic Library) is a free library for arbitrary precision arithmetic, operating on signed integers (`mpz`), rational numbers (`mpq`), and floating-point numbers (`mpf`).
The C++ wrapper (`gmpxx.h`) provides operator overloading and convenient classes such as `mpz_class`, `mpq_class`, and `mpf_class`.

## File Information

| Item | Details |
|------|---------|
| Source Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/gmp` |
| Install Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/gmp-install` |
| Download URL | https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz |
| Version | 6.3.0 |
| License | GNU LGPL v3 / GNU GPL v2 (dual-licensed) |

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
GMP/
├── cmake/
│   ├── gmp.cmake          # This configuration file
│   └── gmpCmake.md        # This document
├── download/
│   ├── gmp/               # GMP source (cached, downloaded from ftp.gnu.org)
│   └── gmp-install/       # GMP built artifacts (lib/, include/)
│       ├── include/
│       │   ├── gmp.h
│       │   └── gmpxx.h
│       └── lib/
│           ├── libgmp.a
│           └── libgmpxx.a
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## Usage

### Adding to CMakeLists.txt

```cmake
# Automatically include gmp.cmake if it exists
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/gmp.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/gmp.cmake)
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
set(GMP_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(GMP_SOURCE_DIR ${GMP_DOWNLOAD_DIR}/gmp)
set(GMP_INSTALL_DIR ${GMP_DOWNLOAD_DIR}/gmp-install)
set(GMP_VERSION "6.3.0")
set(GMP_URL "https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.xz")
```

### 2. Cache Check and Conditional Build

```cmake
if(EXISTS ${GMP_INSTALL_DIR}/lib/libgmp.a AND EXISTS ${GMP_INSTALL_DIR}/lib/libgmpxx.a)
    message(STATUS "GMP already built: ${GMP_INSTALL_DIR}/lib/libgmp.a")
else()
    # Download, configure, build, and install ...
endif()
```

The cache logic works as follows:

| Condition | Action |
|-----------|--------|
| `gmp-install/lib/libgmp.a` exists | Skip everything (use cached build) |
| `gmp/configure` exists (install missing) | Skip download, run configure/make/install |
| Nothing exists | Download, extract, configure, make, install |

### 3. Download (if needed)

```cmake
file(DOWNLOAD
    ${GMP_URL}
    ${GMP_DOWNLOAD_DIR}/gmp-${GMP_VERSION}.tar.xz
    SHOW_PROGRESS
    STATUS DOWNLOAD_STATUS
)
file(ARCHIVE_EXTRACT
    INPUT ${GMP_DOWNLOAD_DIR}/gmp-${GMP_VERSION}.tar.xz
    DESTINATION ${GMP_DOWNLOAD_DIR}
)
file(RENAME ${GMP_DOWNLOAD_DIR}/gmp-${GMP_VERSION} ${GMP_SOURCE_DIR})
```

- Downloads from `ftp.gnu.org` (GNU official mirror)
- Extracts and renames `gmp-6.3.0/` to `gmp/` for a clean path

### 4. Configure, Build, and Install

```cmake
execute_process(
    COMMAND ${GMP_SOURCE_DIR}/configure
            --prefix=${GMP_INSTALL_DIR}
            --enable-cxx
            --disable-shared
            --enable-static
            --with-pic
    WORKING_DIRECTORY ${GMP_SOURCE_DIR}
)
execute_process(COMMAND make -j4 WORKING_DIRECTORY ${GMP_SOURCE_DIR})
execute_process(COMMAND make install WORKING_DIRECTORY ${GMP_SOURCE_DIR})
```

- `--enable-cxx`: Builds the C++ interface (`libgmpxx`)
- `--disable-shared --enable-static`: Builds static libraries only
- `--with-pic`: Generates position-independent code
- All steps run at CMake configure time, not at build time

### 5. Linking the Library

```cmake
add_library(gmp_lib STATIC IMPORTED)
set_target_properties(gmp_lib PROPERTIES
    IMPORTED_LOCATION ${GMP_INSTALL_DIR}/lib/libgmp.a
)

add_library(gmpxx_lib STATIC IMPORTED)
set_target_properties(gmpxx_lib PROPERTIES
    IMPORTED_LOCATION ${GMP_INSTALL_DIR}/lib/libgmpxx.a
)

target_include_directories(${PROJECT_NAME} PRIVATE ${GMP_INSTALL_DIR}/include)
target_link_libraries(${PROJECT_NAME} PRIVATE gmpxx_lib gmp_lib)
```

Note: `gmpxx_lib` must be listed before `gmp_lib` to satisfy linker dependency order.

---

## Key Features of GMP

| Feature | Description |
|---------|-------------|
| Integer arithmetic (`mpz`) | Arbitrary precision signed integers |
| Rational arithmetic (`mpq`) | Exact fractions (numerator/denominator) |
| Floating-point arithmetic (`mpf`) | Arbitrary precision floating-point numbers |
| C++ wrapper (`gmpxx.h`) | Operator overloading via `mpz_class`, `mpq_class`, `mpf_class` |
| Number theoretic functions | GCD, LCM, primality testing, Jacobi symbol, etc. |
| I/O support | Stream operators (`<<`, `>>`) for C++ classes |
| High performance | Assembly-optimized for many platforms (x86, ARM, etc.) |

---

## Usage Examples in C++

### Basic Arithmetic

```cpp
#include <gmpxx.h>
#include <iostream>

int main() {
    mpz_class a, b, c;

    a = 1234;
    b = "-5678";
    c = a + b;

    std::cout << "sum of " << a << " and " << b << " is " << c << "\n";
    std::cout << "absolute value is " << abs(c) << "\n";

    return 0;
}
```

### Fibonacci (Iterative)

```cpp
#include <gmpxx.h>
#include <iostream>

mpz_class fib(int n) {
    mpz_class a = 1, b = 0;
    for (int i = 0; i < n; ++i) {
        swap(a, b);
        b += a;
    }
    return b;
}

int main() {
    // Computes extremely large Fibonacci numbers with ease
    std::cout << "fib(100) = " << fib(100) << std::endl;
    std::cout << "fib(1000) = " << fib(1000) << std::endl;
    return 0;
}
```

### Factorial

```cpp
#include <gmpxx.h>
#include <iostream>

mpz_class factorial(int n) {
    mpz_class result = 1;
    for (int i = 2; i <= n; ++i) {
        result *= i;
    }
    return result;
}

int main() {
    std::cout << "100! = " << factorial(100) << std::endl;
    return 0;
}
```

### Rational Numbers

```cpp
#include <gmpxx.h>
#include <iostream>

int main() {
    mpq_class a(1, 3);  // 1/3
    mpq_class b(1, 6);  // 1/6

    std::cout << a << " + " << b << " = " << a + b << std::endl;  // 1/2
    std::cout << a << " * " << b << " = " << a * b << std::endl;  // 1/18

    return 0;
}
```

### Floating-Point with Arbitrary Precision

```cpp
#include <gmpxx.h>
#include <iostream>

int main() {
    // Set precision to 256 bits
    mpf_class pi("3.14159265358979323846264338327950288", 256);
    mpf_class r("2.5", 256);

    mpf_class area = pi * r * r;
    std::cout << "Area of circle with r=2.5: " << area << std::endl;

    return 0;
}
```

### Primality Testing (C API)

```cpp
#include <gmpxx.h>
#include <iostream>

int main() {
    mpz_class n("170141183460469231731687303715884105727");  // 2^127 - 1 (Mersenne prime)

    // mpz_probab_prime_p returns: 2 = definitely prime, 1 = probably prime, 0 = composite
    int result = mpz_probab_prime_p(n.get_mpz_t(), 25);

    if (result >= 1) {
        std::cout << n << " is prime" << std::endl;
    } else {
        std::cout << n << " is composite" << std::endl;
    }

    return 0;
}
```

---

## C++ Classes Overview

### mpz_class (Integer)

| Operation | Example |
|-----------|---------|
| Assignment | `mpz_class a = 42;` or `a = "123456789";` |
| Arithmetic | `a + b`, `a - b`, `a * b`, `a / b`, `a % b` |
| Comparison | `a == b`, `a != b`, `a < b`, `a > b` |
| Absolute value | `abs(a)` |
| Power | `mpz_class r; mpz_pow_ui(r.get_mpz_t(), a.get_mpz_t(), exp);` |
| GCD | `mpz_class g; mpz_gcd(g.get_mpz_t(), a.get_mpz_t(), b.get_mpz_t());` |
| String conversion | `a.get_str()` |
| Swap | `swap(a, b)` |

### mpq_class (Rational)

| Operation | Example |
|-----------|---------|
| Assignment | `mpq_class a(1, 3);` (1/3) |
| Arithmetic | `a + b`, `a - b`, `a * b`, `a / b` |
| Canonicalize | `a.canonicalize();` |
| Get numerator | `a.get_num()` |
| Get denominator | `a.get_den()` |

### mpf_class (Floating-point)

| Operation | Example |
|-----------|---------|
| Assignment | `mpf_class a("3.14", 256);` (256-bit precision) |
| Arithmetic | `a + b`, `a - b`, `a * b`, `a / b` |
| Square root | `mpf_class r; mpf_sqrt(r.get_mpf_t(), a.get_mpf_t());` |
| Set precision | `mpf_set_default_prec(1024);` |

---

## Comparison with Built-in Types

| Feature | `long long` | `__int128` | `mpz_class` (GMP) |
|---------|------------|-----------|-------------------|
| Max digits | ~19 | ~38 | Unlimited |
| Speed | Fastest | Fast | Slower (but optimized) |
| Operator overloading | Built-in | Partial | Full (C++) |
| Exact arithmetic | Yes | Yes | Yes |
| Platform support | All | GCC/Clang | All |

---

## Troubleshooting

### Download Fails

If `ftp.gnu.org` is unreachable, you can manually download and place the tarball:

```bash
curl -L -o download/gmp-6.3.0.tar.xz https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz
```

Then re-run `cmake ..` and the extraction will proceed from the cached tarball.

### Configure Fails

Ensure that autotools prerequisites are available:

```bash
# macOS (Xcode Command Line Tools)
xcode-select --install

# Check m4 is available (required by GMP configure)
m4 --version
```

### Rebuild GMP from Scratch

To force a full rebuild, remove the install and source directories:

```bash
rm -rf download/gmp-install download/gmp
cd build && cmake ..
```

### Link Error: gmpxx Not Found

Verify that `--enable-cxx` was passed during configure. The C++ wrapper `libgmpxx.a` is only built when this option is enabled.

### Undefined Reference to `__gmpz_init` etc.

Ensure that `gmpxx_lib` is linked before `gmp_lib`. The linker processes libraries left to right, and `libgmpxx.a` depends on `libgmp.a`.

---

## References

- [GMP Official Website](https://gmplib.org/)
- [GMP Manual](https://gmplib.org/manual/)
- [GMP C++ Class Interface](https://gmplib.org/manual/C_002b_002b-Class-Interface)
- [GNU FTP Mirror](https://ftp.gnu.org/gnu/gmp/)
- [CMake execute_process Documentation](https://cmake.org/cmake/help/latest/command/execute_process.html)
- [CMake file(DOWNLOAD) Documentation](https://cmake.org/cmake/help/latest/command/file.html#download)
