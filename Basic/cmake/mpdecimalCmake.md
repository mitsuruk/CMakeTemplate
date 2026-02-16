# mpdecimal.cmake Reference

## Overview

`mpdecimal.cmake` is a CMake configuration file that automatically downloads, builds, and links the mpdecimal library.
It uses CMake's `file(DOWNLOAD)` and `execute_process` to manage the dependency, with caching in the `download/` directory to avoid redundant downloads and rebuilds.

mpdecimal is a package for correctly-rounded arbitrary precision decimal floating-point arithmetic. It implements the General Decimal Arithmetic Specification (IEEE 754-2008) and is the library that powers Python's `decimal` module.

mpdecimal provides two libraries:
- **libmpdec** (C API): Low-level decimal arithmetic via `mpdecimal.h`
- **libmpdec++** (C++ API): High-level C++ wrapper via `decimal.hh`

## File Information

| Item | Details |
|------|---------|
| Source Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/mpdecimal` |
| Install Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/mpdecimal/mpdecimal-install` |
| Download URL | https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-4.0.1.tar.gz |
| Version | 4.0.1 |
| License | Simplified BSD License |

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
mpdecimal/
├── cmake/
│   ├── mpdecimal.cmake        # This configuration file
│   ├── mpdecimalCmake.md      # This document (English)
│   └── mpdecimalCmake-jp.md   # Japanese documentation
├── download/mpdecimal
│   ├── mpdecimal/             # mpdecimal source (cached, downloaded from bytereef.org)
│   └── mpdecimal-install/     # mpdecimal built artifacts (lib/, include/)
│       ├── include/
│       │   ├── mpdecimal.h    # C API header
│       │   └── decimal.hh     # C++ API header
│       └── lib/
│           ├── libmpdec.a     # C library (static)
│           └── libmpdec++.a   # C++ library (static)
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## Usage

### Adding to CMakeLists.txt

```cmake
# Automatically include mpdecimal.cmake if it exists
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/mpdecimal.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/mpdecimal.cmake)
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
set(MPDECIMAL_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/mpdecimal)
set(MPDECIMAL_SOURCE_DIR ${MPDECIMAL_DOWNLOAD_DIR}/mpdecimal)
set(MPDECIMAL_INSTALL_DIR ${MPDECIMAL_DOWNLOAD_DIR}/mpdecimal-install)
set(MPDECIMAL_VERSION "4.0.1")
set(MPDECIMAL_URL "https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-${MPDECIMAL_VERSION}.tar.gz")
```

### 2. Cache Check and Conditional Build

```cmake
if(EXISTS ${MPDECIMAL_INSTALL_DIR}/lib/libmpdec.a AND EXISTS ${MPDECIMAL_INSTALL_DIR}/lib/libmpdec++.a)
    message(STATUS "mpdecimal already built: ${MPDECIMAL_INSTALL_DIR}/lib/libmpdec.a")
else()
    # Download, configure, build, and install ...
endif()
```

The cache logic works as follows:

| Condition | Action |
|-----------|--------|
| `mpdecimal-install/lib/libmpdec.a` exists | Skip everything (use cached build) |
| `mpdecimal/configure` exists (install missing) | Skip download, run configure/make/install |
| Nothing exists | Download, extract, configure, make, install |

### 3. Download (if needed)

```cmake
file(DOWNLOAD
    ${MPDECIMAL_URL}
    ${MPDECIMAL_DOWNLOAD_DIR}/mpdecimal-${MPDECIMAL_VERSION}.tar.gz
    SHOW_PROGRESS
    STATUS DOWNLOAD_STATUS
)
file(ARCHIVE_EXTRACT
    INPUT ${MPDECIMAL_DOWNLOAD_DIR}/mpdecimal-${MPDECIMAL_VERSION}.tar.gz
    DESTINATION ${MPDECIMAL_DOWNLOAD_DIR}
)
file(RENAME ${MPDECIMAL_DOWNLOAD_DIR}/mpdecimal-${MPDECIMAL_VERSION} ${MPDECIMAL_SOURCE_DIR})
```

- Downloads from `bytereef.org` (official site)
- Extracts and renames `mpdecimal-4.0.1/` to `mpdecimal/` for a clean path

### 4. Configure, Build, and Install

```cmake
execute_process(
    COMMAND ${MPDECIMAL_SOURCE_DIR}/configure
            --prefix=${MPDECIMAL_INSTALL_DIR}
            --disable-shared
            --enable-static
            --enable-pc
    WORKING_DIRECTORY ${MPDECIMAL_SOURCE_DIR}
)
execute_process(COMMAND make -j4 WORKING_DIRECTORY ${MPDECIMAL_SOURCE_DIR})
execute_process(COMMAND make install WORKING_DIRECTORY ${MPDECIMAL_SOURCE_DIR})
```

- `--disable-shared --enable-static`: Builds static libraries only
- `--enable-pc`: Installs pkg-config files
- All steps run at CMake configure time, not at build time
- Both libmpdec (C) and libmpdec++ (C++) are built by default

### 5. Linking the Library

```cmake
add_library(mpdec_lib STATIC IMPORTED)
set_target_properties(mpdec_lib PROPERTIES
    IMPORTED_LOCATION ${MPDECIMAL_INSTALL_DIR}/lib/libmpdec.a
)

add_library(mpdecpp_lib STATIC IMPORTED)
set_target_properties(mpdecpp_lib PROPERTIES
    IMPORTED_LOCATION ${MPDECIMAL_INSTALL_DIR}/lib/libmpdec++.a
)

target_include_directories(${PROJECT_NAME} PRIVATE ${MPDECIMAL_INSTALL_DIR}/include)
target_link_libraries(${PROJECT_NAME} PRIVATE mpdecpp_lib mpdec_lib m)
```

Note: `mpdecpp_lib` (libmpdec++) must be listed before `mpdec_lib` (libmpdec) to satisfy linker dependency order. `m` (libm) is required for math functions.

---

## mpdecimal Libraries

mpdecimal consists of two libraries:

| Library | File | Header | Description |
|---------|------|--------|-------------|
| `libmpdec` | `libmpdec.a` | `mpdecimal.h` | C library implementing the General Decimal Arithmetic Specification |
| `libmpdec++` | `libmpdec++.a` | `decimal.hh` | C++ wrapper providing `decimal::Decimal` class with operator overloading |

`libmpdec++` depends on `libmpdec`. When using the C++ API, both libraries must be linked.

---

## Key Features of mpdecimal

| Feature | C API | C++ API | Description |
|---------|-------|---------|-------------|
| Arbitrary Precision | `mpd_qsetprec()` | `decimal::context.prec()` | Set precision from 1 to billions of digits |
| Basic Arithmetic | `mpd_qadd/sub/mul/div` | `+`, `-`, `*`, `/` operators | Add, subtract, multiply, divide |
| Comparison | `mpd_qcompare()` | `==`, `<`, `>` operators | Numeric comparison of decimal values |
| Square Root | `mpd_qsqrt()` | `.sqrt()` | Correctly rounded square root |
| Exponential | `mpd_qexp()` | `.exp()` | Correctly rounded exponential (e^x) |
| Natural Log | `mpd_qln()` | `.ln()` | Correctly rounded natural logarithm |
| Log Base 10 | `mpd_qlog10()` | `.log10()` | Correctly rounded common logarithm |
| Power | `mpd_qpow()` | `.pow()` | Correctly rounded exponentiation |
| Rounding Modes | `mpd_qsetround()` | `decimal::context.round()` | 9 IEEE 754 rounding modes |
| Quantize | `mpd_qquantize()` | `.quantize()` | Set number of decimal places |
| Integer Division | `mpd_qdivint()` | `.divint()` | Integer part of division |
| Remainder | `mpd_qrem()` | `.rem()` | Remainder of division |
| Modular Power | `mpd_qpowmod()` | N/A | (base^exp) mod m |
| Absolute Value | `mpd_qabs()` | `.abs()` | Absolute value |
| Reduce | `mpd_qreduce()` | `.reduce()` | Remove trailing zeros |
| String Conversion | `mpd_to_sci/eng()` | `.format()` | Scientific, engineering, and custom formatting |
| Integer Conversion | `mpd_qset_i64/u64()` | Constructor | Convert to/from 64-bit integers |
| Special Values | `mpd_setspecial()` | `Decimal("NaN")` | Infinity, -Infinity, NaN, sNaN |
| FMA | `mpd_qfma()` | `.fma()` | Fused multiply-add |
| IEEE 754-2008 | Full | Full | Complete implementation of the standard |

### Note: Remainder with Negative Numbers

mpdecimal's `rem` operation truncates the quotient toward zero (like C/C++ `%`), **not** toward negative infinity (like Python `%`).

| Expression | divint | rem | Explanation |
| --- | --- | --- | --- |
| `-5 % 3` | `-1` | `-2` | `-5 = 3 * (-1) + (-2)` |
| `5 % -3` | `-1` | `2` | `5 = (-3) * (-1) + 2` |
| `-5 % -3` | `1` | `-2` | `-5 = (-3) * 1 + (-2)` |
| `17 % 5` | `3` | `2` | `17 = 5 * 3 + 2` |

The sign of the remainder always matches the sign of the dividend (left operand). This follows the IEEE 754 remainder definition and differs from Python's modulo operator, which always returns a non-negative result when the divisor is positive.

```cpp
decimal::Decimal a("-5");
decimal::Decimal b("3");
std::cout << a.divint(b).format("f") << "\n";  // -1
std::cout << a.rem(b).format("f") << "\n";     // -2
```

---

## Rounding Modes

mpdecimal supports 9 rounding modes defined by IEEE 754:

| Constant | Description | Example (2.25 -> 1dp) |
|----------|-------------|----------------------|
| `MPD_ROUND_HALF_UP` | Round 0.5 up (away from zero) | 2.3 |
| `MPD_ROUND_HALF_DOWN` | Round 0.5 down (toward zero) | 2.2 |
| `MPD_ROUND_HALF_EVEN` | Round 0.5 to nearest even (banker's rounding) | 2.2 |
| `MPD_ROUND_UP` | Round away from zero | 2.3 |
| `MPD_ROUND_DOWN` | Round toward zero (truncate) | 2.2 |
| `MPD_ROUND_CEILING` | Round toward +infinity | 2.3 |
| `MPD_ROUND_FLOOR` | Round toward -infinity | 2.2 |
| `MPD_ROUND_05UP` | Round zero or five away from zero | 2.2 |
| `MPD_ROUND_TRUNC` | Truncate, but set infinities | 2.2 |

---

## Usage Examples in C++

### Basic Arithmetic (C++ API)

```cpp
#include <decimal.hh>
#include <iostream>

int main() {
    decimal::Decimal a("0.1");
    decimal::Decimal b("0.2");
    decimal::Decimal c = a + b;

    // Prints exactly 0.3 (unlike IEEE 754 binary float)
    std::cout << "0.1 + 0.2 = " << c.format("f") << "\n";

    decimal::Decimal x("123.456");
    decimal::Decimal y("78.9");

    std::cout << "x + y = " << (x + y).format("f") << "\n";
    std::cout << "x - y = " << (x - y).format("f") << "\n";
    std::cout << "x * y = " << (x * y).format("f") << "\n";
    std::cout << "x / y = " << (x / y).format("f") << "\n";

    return 0;
}
```

### Precision Control

```cpp
#include <decimal.hh>
#include <iostream>

int main() {
    decimal::context.prec(50);
    decimal::Decimal result = decimal::Decimal("1").div(decimal::Decimal("3"));
    std::cout << "1/3 (50 digits): " << result.format("f") << "\n";

    decimal::context.prec(10);
    result = decimal::Decimal("1").div(decimal::Decimal("3"));
    std::cout << "1/3 (10 digits): " << result.format("f") << "\n";

    return 0;
}
```

### Rounding and Quantize

```cpp
#include <decimal.hh>
#include <iostream>

int main() {
    decimal::Decimal price("19.99");
    decimal::Decimal tax("0.08");
    decimal::Decimal total = price * (decimal::Decimal("1") + tax);
    decimal::Decimal cent("0.01");

    decimal::context.round(MPD_ROUND_HALF_UP);
    std::cout << "Total: " << total.quantize(cent).format("f") << "\n";

    return 0;
}
```

### Mathematical Functions

```cpp
#include <decimal.hh>
#include <iostream>

int main() {
    decimal::context.prec(28);

    decimal::Decimal two("2");
    std::cout << "sqrt(2) = " << two.sqrt().format("f") << "\n";

    decimal::Decimal one("1");
    std::cout << "e       = " << one.exp().format("f") << "\n";
    std::cout << "ln(e)   = " << one.exp().ln().format("f") << "\n";

    decimal::Decimal base("2");
    decimal::Decimal exp("10");
    std::cout << "2^10    = " << base.pow(exp).format("f") << "\n";

    return 0;
}
```

### C API: Low-Level Usage

```c
#include <mpdecimal.h>
#include <stdio.h>

int main() {
    mpd_context_t ctx;
    mpd_defaultcontext(&ctx);

    mpd_t *a = mpd_new(&ctx);
    mpd_t *b = mpd_new(&ctx);
    mpd_t *result = mpd_new(&ctx);

    uint32_t status = 0;
    mpd_qset_string(a, "0.1", &ctx, &status);
    mpd_qset_string(b, "0.2", &ctx, &status);
    mpd_qadd(result, a, b, &ctx, &status);

    char *s = mpd_to_sci(result, 1);
    printf("0.1 + 0.2 = %s\n", s);

    mpd_free(s);
    mpd_del(a);
    mpd_del(b);
    mpd_del(result);
    return 0;
}
```

### String Formatting

```cpp
#include <decimal.hh>
#include <mpdecimal.h>
#include <iostream>

int main() {
    decimal::Decimal pi("3.14159265358979323846");

    std::cout << "default : " << pi.format("f") << "\n";
    std::cout << ".6f     : " << pi.format(".6f") << "\n";
    std::cout << ".2f     : " << pi.format(".2f") << "\n";
    std::cout << "E       : " << pi.format("E") << "\n";

    // C API: scientific and engineering notation
    mpd_context_t ctx;
    mpd_defaultcontext(&ctx);
    mpd_t *val = mpd_new(&ctx);
    uint32_t status = 0;
    mpd_qset_string(val, "12345.6789", &ctx, &status);

    char *sci = mpd_to_sci(val, 1);
    char *eng = mpd_to_eng(val, 1);
    printf("scientific  : %s\n", sci);
    printf("engineering : %s\n", eng);

    mpd_free(sci);
    mpd_free(eng);
    mpd_del(val);
    return 0;
}
```

---

## C API Conventions

### Context Management

All C API operations require a `mpd_context_t` that controls precision, rounding, and error handling:

```c
mpd_context_t ctx;
mpd_defaultcontext(&ctx);      // precision = 2*MPD_RDIGITS, ROUND_HALF_EVEN
mpd_maxcontext(&ctx);          // maximum precision
mpd_basiccontext(&ctx);        // precision = 9
mpd_init(&ctx, 50);            // custom precision of 50
```

### Memory Management

mpdecimal manages memory using the `mpd_new` / `mpd_del` pattern:

```c
mpd_t *dec = mpd_new(&ctx);
// ... use ...
mpd_del(dec);
```

For strings returned by `mpd_to_sci()`, `mpd_to_eng()`, etc., use `mpd_free()`:

```c
char *s = mpd_to_sci(dec, 1);
// ... use ...
mpd_free(s);
```

### Error Handling

The "quiet" API functions (`mpd_q*`) use an explicit `uint32_t *status` parameter:

```c
uint32_t status = 0;
mpd_qadd(result, a, b, &ctx, &status);
if (status & MPD_Errors) {
    // handle error
}
```

The non-quiet variants (`mpd_add`, etc.) raise signals through the context trap mechanism.

---

## Comparison: mpdecimal vs Other Libraries

| Feature | mpdecimal | GMP | Boost.Multiprecision | double |
|---------|-----------|-----|----------------------|--------|
| Base | Decimal | Binary | Configurable | Binary |
| IEEE 754-2008 | Full | No | Partial | Partial |
| Exact 0.1+0.2 | Yes | No | Depends on backend | No |
| Rounding Modes | 9 modes | Limited | Limited | 4 modes |
| Financial Math | Excellent | Poor | Good | Poor |
| Performance | Very Fast | Fastest | Fast | Fastest |
| Precision | Arbitrary | Arbitrary | Arbitrary | 15-17 digits |
| License | BSD | LGPL | Boost | N/A |

mpdecimal excels at financial and monetary calculations where exact decimal representation is critical. For pure mathematical computation where binary representation is acceptable, GMP or hardware floats may be faster.

---

## Troubleshooting

### Download Fails

If `bytereef.org` is unreachable, you can manually download and place the tarball:

```bash
curl -L -o download/mpdecimal/mpdecimal-4.0.1.tar.gz \
    https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-4.0.1.tar.gz
```

Then re-run `cmake ..` and the extraction will proceed from the cached tarball.

### Configure Fails

Ensure that build prerequisites are available:

```bash
# macOS (Xcode Command Line Tools)
xcode-select --install

# Check make is available
make --version
```

### Rebuild mpdecimal from Scratch

To force a full rebuild, remove the install and source directories:

```bash
rm -rf download/mpdecimal/mpdecimal-install download/mpdecimal/mpdecimal
cd build && cmake ..
```

### Link Error: Undefined Reference to `mpd_*`

Ensure that both `mpdecpp_lib` and `mpdec_lib` are linked in the correct order (C++ before C):

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE mpdecpp_lib mpdec_lib m)
```

### Link Error: Undefined Reference to C++ Symbols

If using the C++ API (`decimal.hh`), ensure you are compiling with a C++ compiler (not a C compiler) and linking `libmpdec++.a` before `libmpdec.a`.

### Disable C++ Library

If you only need the C API, add `--disable-cxx` to the configure options:

```cmake
execute_process(
    COMMAND ${MPDECIMAL_SOURCE_DIR}/configure
            --prefix=${MPDECIMAL_INSTALL_DIR}
            --disable-shared
            --enable-static
            --disable-cxx
    WORKING_DIRECTORY ${MPDECIMAL_SOURCE_DIR}
)
```

Then link only `libmpdec.a`:

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE mpdec_lib m)
```

---

## References

- [mpdecimal Official Website](https://www.bytereef.org/mpdecimal/)
- [mpdecimal Download Page](https://www.bytereef.org/mpdecimal/download.html)
- [mpdecimal Quickstart Guide](https://www.bytereef.org/mpdecimal/quickstart.html)
- [libmpdec API Documentation](https://www.bytereef.org/mpdecimal/doc/libmpdec/index.html)
- [libmpdec++ API Documentation](https://www.bytereef.org/mpdecimal/doc/libmpdec++/index.html)
- [General Decimal Arithmetic Specification](https://speleotrove.com/decimal/decarith.html)
- [IEEE 754-2008 Standard](https://en.wikipedia.org/wiki/IEEE_754)
- [CMake execute_process Documentation](https://cmake.org/cmake/help/latest/command/execute_process.html)
- [CMake file(DOWNLOAD) Documentation](https://cmake.org/cmake/help/latest/command/file.html#download)
