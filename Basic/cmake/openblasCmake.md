# openblas.cmake Reference

## Overview

`openblas.cmake` is a CMake configuration file that automatically downloads, builds, and links the OpenBLAS library.
It uses CMake's `file(DOWNLOAD)` and `execute_process` to manage the dependency, with caching in the `download/` directory to avoid redundant downloads and rebuilds.

OpenBLAS is an optimized BLAS (Basic Linear Algebra Subprograms) library based on GotoBLAS2. It provides highly optimized implementations of BLAS Level 1/2/3 routines, leveraging CPU-specific SIMD instructions (SSE, AVX, AVX2, AVX-512, NEON, etc.) and multi-threading for maximum performance.

OpenBLAS is a C/Fortran library. When using it from C++, you include the CBLAS header (`<cblas.h>`) directly.

## File Information

| Item | Details |
|------|---------|
| Source Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/openblas` |
| Install Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/openblas-install` |
| Download URL | https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.28/OpenBLAS-0.3.28.tar.gz |
| Version | 0.3.28 |
| License | BSD 3-Clause |

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
OpenBLAS/
├── cmake/
│   ├── openblas.cmake         # This configuration file
│   ├── openblasCmake.md       # This document (English)
│   └── openblasCmake-jp.md   # Japanese documentation
├── download/openblas
│   ├── openblas/              # OpenBLAS source (cached, downloaded from GitHub)
│   └── openblas-install/      # OpenBLAS built artifacts (lib/, include/)
│       ├── include/
│       │   ├── cblas.h
│       │   ├── f77blas.h
│       │   ├── lapacke.h
│       │   ├── lapacke_config.h
│       │   ├── lapacke_mangling.h
│       │   ├── lapacke_utils.h
│       │   ├── openblas_config.h
│       │   └── openblas_config_template.h
│       └── lib/
│           └── libopenblas.a
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## Usage

### Adding to CMakeLists.txt

```cmake
# Automatically include openblas.cmake if it exists
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/openblas.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/openblas.cmake)
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
set(OPENBLAS_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/openblas)
set(OPENBLAS_SOURCE_DIR ${OPENBLAS_DOWNLOAD_DIR}/openblas)
set(OPENBLAS_INSTALL_DIR ${OPENBLAS_DOWNLOAD_DIR}/openblas-install)
set(OPENBLAS_VERSION "0.3.28")
set(OPENBLAS_URL "https://github.com/OpenMathLib/OpenBLAS/releases/download/v${OPENBLAS_VERSION}/OpenBLAS-${OPENBLAS_VERSION}.tar.gz")
```

### 2. Cache Check and Conditional Build

```cmake
if(EXISTS ${OPENBLAS_INSTALL_DIR}/lib/libopenblas.a)
    message(STATUS "OpenBLAS already built: ${OPENBLAS_INSTALL_DIR}/lib/libopenblas.a")
else()
    # Download, build, and install ...
endif()
```

The cache logic works as follows:

| Condition | Action |
|-----------|--------|
| `openblas-install/lib/libopenblas.a` exists | Skip everything (use cached build) |
| `openblas/Makefile` exists (install missing) | Skip download, run make/install |
| Nothing exists | Download, extract, make, install |

### 3. Download (if needed)

```cmake
file(DOWNLOAD
    ${OPENBLAS_URL}
    ${OPENBLAS_DOWNLOAD_DIR}/OpenBLAS-${OPENBLAS_VERSION}.tar.gz
    SHOW_PROGRESS
    STATUS DOWNLOAD_STATUS
)
file(ARCHIVE_EXTRACT
    INPUT ${OPENBLAS_DOWNLOAD_DIR}/OpenBLAS-${OPENBLAS_VERSION}.tar.gz
    DESTINATION ${OPENBLAS_DOWNLOAD_DIR}
)
file(RENAME ${OPENBLAS_DOWNLOAD_DIR}/OpenBLAS-${OPENBLAS_VERSION} ${OPENBLAS_SOURCE_DIR})
```

- Downloads from GitHub (OpenMathLib official repository)
- Falls back to the legacy xianyi/OpenBLAS repository if the primary mirror fails
- Extracts and renames `OpenBLAS-0.3.28/` to `openblas/` for a clean path

### 4. Build and Install

```cmake
execute_process(
    COMMAND make libs netlib -j4
            NO_FORTRAN=1
            NO_LAPACK=1
            USE_OPENMP=0
            DYNAMIC_ARCH=0
            NO_SHARED=1
            PREFIX=${OPENBLAS_INSTALL_DIR}
    WORKING_DIRECTORY ${OPENBLAS_SOURCE_DIR}
)
execute_process(
    COMMAND make install
            NO_FORTRAN=1
            NO_LAPACK=1
            USE_OPENMP=0
            DYNAMIC_ARCH=0
            NO_SHARED=1
            PREFIX=${OPENBLAS_INSTALL_DIR}
    WORKING_DIRECTORY ${OPENBLAS_SOURCE_DIR}
)
```

- OpenBLAS uses `make` directly (no `./configure` step)
- `libs netlib`: Builds only the library targets (skips test binaries that cause LTO linker errors on macOS)
- `NO_FORTRAN=1`: Does not require a Fortran compiler
- `NO_LAPACK=1`: Excludes LAPACK routines (BLAS only)
- `USE_OPENMP=0`: Uses pthreads for threading (not OpenMP)
- `DYNAMIC_ARCH=0`: Builds for the host CPU architecture only
- `NO_SHARED=1`: Builds static library only (no shared library)
- All steps run at CMake configure time, not at build time

### 5. Linking the Library

```cmake
add_library(openblas_lib STATIC IMPORTED)
set_target_properties(openblas_lib PROPERTIES
    IMPORTED_LOCATION ${OPENBLAS_INSTALL_DIR}/lib/libopenblas.a
)

target_include_directories(${PROJECT_NAME} PRIVATE ${OPENBLAS_INSTALL_DIR}/include)
target_link_libraries(${PROJECT_NAME} PRIVATE openblas_lib m pthread)
```

Note: `pthread` is required for OpenBLAS's internal threading. `m` (libm) is required for math functions.

---

## OpenBLAS Library

OpenBLAS produces a single unified library:

| Library | File | Description |
|---------|------|-------------|
| `libopenblas` | `libopenblas.a` | Unified library containing all BLAS (and optionally LAPACK) routines |

Unlike GSL (which splits into `libgsl` + `libgslcblas`), OpenBLAS bundles everything into one library. This simplifies linking.

---

## Build Options

OpenBLAS supports numerous build-time options. Key options are:

| Option | Default | Description |
|--------|---------|-------------|
| `NO_FORTRAN=1` | 0 | Do not require a Fortran compiler |
| `NO_LAPACK=1` | 0 | Exclude LAPACK routines (BLAS only) |
| `USE_OPENMP=1` | 0 | Use OpenMP instead of pthreads |
| `DYNAMIC_ARCH=1` | 0 | Build for multiple architectures (runtime dispatch) |
| `TARGET=xxx` | auto | Specify CPU target (e.g., `HASWELL`, `SKYLAKEX`, `ARMV8`) |
| `NUM_THREADS=n` | auto | Maximum number of threads |
| `NO_CBLAS=1` | 0 | Do not build CBLAS interface |
| `ONLY_CBLAS=1` | 0 | Build only the CBLAS interface |
| `NO_SHARED=1` | 0 | Do not build shared libraries (static only) |
| `USE_THREAD=0` | 1 | Disable threading entirely |
| `PREFIX=/path` | `/opt/OpenBLAS` | Installation prefix |

---

## Key Features of OpenBLAS (CBLAS Interface)

### BLAS Level 1 - Vector Operations

| Function | Description |
|----------|-------------|
| `cblas_ddot` | Dot product of two vectors |
| `cblas_dnrm2` | Euclidean norm (L2 norm) of a vector |
| `cblas_dasum` | Sum of absolute values |
| `cblas_daxpy` | y = alpha * x + y |
| `cblas_dscal` | x = alpha * x |
| `cblas_dcopy` | Copy vector x to y |
| `cblas_dswap` | Swap vectors x and y |
| `cblas_idamax` | Index of element with max absolute value |
| `cblas_drotg` | Generate Givens rotation |
| `cblas_drot` | Apply Givens rotation |

### BLAS Level 2 - Matrix-Vector Operations

| Function | Description |
|----------|-------------|
| `cblas_dgemv` | y = alpha * A * x + beta * y (general matrix-vector) |
| `cblas_dsymv` | y = alpha * A * x + beta * y (symmetric matrix-vector) |
| `cblas_dtrmv` | x = A * x (triangular matrix-vector) |
| `cblas_dtrsv` | Solve A * x = b (triangular solve) |
| `cblas_dger` | A = alpha * x * y^T + A (rank-1 update) |
| `cblas_dsyr` | A = alpha * x * x^T + A (symmetric rank-1 update) |
| `cblas_dsyr2` | A = alpha * x * y^T + alpha * y * x^T + A |

### BLAS Level 3 - Matrix-Matrix Operations

| Function | Description |
|----------|-------------|
| `cblas_dgemm` | C = alpha * A * B + beta * C (general matrix multiply) |
| `cblas_dsymm` | C = alpha * A * B + beta * C (symmetric matrix multiply) |
| `cblas_dtrmm` | B = alpha * A * B (triangular matrix multiply) |
| `cblas_dtrsm` | Solve A * X = alpha * B (triangular solve, multiple RHS) |
| `cblas_dsyrk` | C = alpha * A * A^T + beta * C (symmetric rank-k update) |
| `cblas_dsyr2k` | C = alpha * A * B^T + alpha * B * A^T + beta * C |

---

## Usage Examples in C/C++

### BLAS Level 1: Dot Product and Vector Operations

```cpp
#include <cblas.h>
#include <cstdio>

int main() {
    double x[] = {1.0, 2.0, 3.0, 4.0, 5.0};
    double y[] = {2.0, 3.0, 4.0, 5.0, 6.0};
    int n = 5;

    // Dot product
    double dot = cblas_ddot(n, x, 1, y, 1);
    printf("x . y = %.4f\n", dot);  // 70.0

    // Euclidean norm
    double nrm = cblas_dnrm2(n, x, 1);
    printf("||x||_2 = %.4f\n", nrm);

    // AXPY: y = 2.0 * x + y
    cblas_daxpy(n, 2.0, x, 1, y, 1);
    printf("y = 2*x + y_orig = [");
    for (int i = 0; i < n; i++)
        printf("%.1f%s", y[i], i < n - 1 ? ", " : "]\n");

    return 0;
}
```

### BLAS Level 2: Matrix-Vector Multiplication

```cpp
#include <cblas.h>
#include <cstdio>

int main() {
    // A: 3x3 row-major matrix
    double A[] = {
        1.0, 2.0, 3.0,
        4.0, 5.0, 6.0,
        7.0, 8.0, 9.0
    };
    double x[] = {1.0, 1.0, 1.0};
    double y[] = {0.0, 0.0, 0.0};

    // y = 1.0 * A * x + 0.0 * y
    cblas_dgemv(CblasRowMajor, CblasNoTrans,
                3, 3,      // rows, cols
                1.0,       // alpha
                A, 3,      // A, lda
                x, 1,      // x, incx
                0.0,       // beta
                y, 1);     // y, incy

    printf("y = A*x = [%.1f, %.1f, %.1f]\n", y[0], y[1], y[2]);
    // Output: [6.0, 15.0, 24.0]

    return 0;
}
```

### BLAS Level 3: Matrix Multiplication

```cpp
#include <cblas.h>
#include <cstdio>

int main() {
    // A: 2x3, B: 3x2 -> C: 2x2
    double A[] = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0};
    double B[] = {7.0, 8.0, 9.0, 10.0, 11.0, 12.0};
    double C[4] = {};

    // C = 1.0 * A * B + 0.0 * C
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                2, 2, 3,       // M, N, K
                1.0,           // alpha
                A, 3,          // A, lda
                B, 2,          // B, ldb
                0.0,           // beta
                C, 2);         // C, ldc

    printf("C = A*B =\n");
    printf("  [%.0f, %.0f]\n", C[0], C[1]);  // [58, 64]
    printf("  [%.0f, %.0f]\n", C[2], C[3]);  // [139, 154]

    return 0;
}
```

### Performance Benchmark

```cpp
#include <cblas.h>
#include <chrono>
#include <cstdio>
#include <vector>

int main() {
    const int N = 1024;
    std::vector<double> A(N * N, 1.0);
    std::vector<double> B(N * N, 1.0);
    std::vector<double> C(N * N, 0.0);

    auto start = std::chrono::high_resolution_clock::now();

    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                N, N, N, 1.0,
                A.data(), N, B.data(), N, 0.0, C.data(), N);

    auto end = std::chrono::high_resolution_clock::now();
    double ms = std::chrono::duration<double, std::milli>(end - start).count();
    double gflops = 2.0 * N * N * N / (ms * 1e6);

    printf("N=%d: %.3f ms, %.2f GFLOPS\n", N, ms, gflops);
    return 0;
}
```

### OpenBLAS Configuration and Threading

```cpp
#include <cblas.h>
#include <cstdio>

int main() {
    // Query OpenBLAS configuration
    printf("Config:     %s\n", openblas_get_config());
    printf("Corename:   %s\n", openblas_get_corename());
    printf("Threads:    %d\n", openblas_get_num_threads());
    printf("Parallel:   %d\n", openblas_get_parallel());

    // Control threading
    openblas_set_num_threads(4);  // Set to 4 threads
    printf("Threads (after set): %d\n", openblas_get_num_threads());

    // Single-threaded mode
    openblas_set_num_threads(1);

    return 0;
}
```

---

## CBLAS API Conventions

### Data Layout

OpenBLAS CBLAS functions support both row-major and column-major layouts:

```cpp
cblas_dgemm(CblasRowMajor, ...);  // C/C++ natural order
cblas_dgemm(CblasColMajor, ...);  // Fortran natural order
```

### Transpose Operations

```cpp
CblasNoTrans   // Use A as-is
CblasTrans     // Use A^T (transpose)
CblasConjTrans // Use A^H (conjugate transpose, for complex)
```

### Naming Conventions

CBLAS function names follow the pattern `cblas_<prefix><operation>`:

| Prefix | Data Type |
|--------|-----------|
| `s` | Single precision (`float`) |
| `d` | Double precision (`double`) |
| `c` | Single precision complex |
| `z` | Double precision complex |

| Operation | Level | Description |
|-----------|-------|-------------|
| `dot` | 1 | Dot product |
| `nrm2` | 1 | Euclidean norm |
| `axpy` | 1 | y = alpha*x + y |
| `scal` | 1 | x = alpha*x |
| `gemv` | 2 | General matrix-vector multiply |
| `gemm` | 3 | General matrix-matrix multiply |
| `trsm` | 3 | Triangular solve (multiple RHS) |

### Parameters

| Parameter | Description |
|-----------|-------------|
| `order` | `CblasRowMajor` or `CblasColMajor` |
| `trans` | `CblasNoTrans`, `CblasTrans`, `CblasConjTrans` |
| `M, N, K` | Matrix dimensions |
| `alpha, beta` | Scalar multipliers |
| `lda, ldb, ldc` | Leading dimensions of A, B, C |
| `incx, incy` | Stride (increment) for vectors x, y |

---

## Comparison: OpenBLAS vs Other BLAS Implementations

| Feature | OpenBLAS | Apple Accelerate | Intel MKL | Reference BLAS |
|---------|----------|-----------------|-----------|----------------|
| License | BSD 3-Clause | Proprietary (free) | Proprietary (free) | Public Domain |
| Platform | Cross-platform | macOS/iOS only | x86/x86_64 | Any |
| CPU Optimization | Yes (auto-detect) | Yes (Apple Silicon) | Yes (Intel CPUs) | No |
| Multi-threading | pthreads/OpenMP | GCD | OpenMP/TBB | No |
| LAPACK included | Optional | Yes | Yes | No |
| Dynamic dispatch | Optional | Yes | Yes | No |
| Performance | High | Very High (on Apple) | Very High (on Intel) | Low |
| Header-only | No | No | No | No |

OpenBLAS is the most portable high-performance BLAS implementation. It provides near-optimal performance across x86, ARM, POWER, and other architectures without vendor lock-in.

---

## Troubleshooting

### Download Fails

If GitHub is unreachable, you can manually download and place the tarball:

```bash
curl -L -o download/openblas/OpenBLAS-0.3.28.tar.gz \
    https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.28/OpenBLAS-0.3.28.tar.gz
```

Then re-run `cmake ..` and the extraction will proceed from the cached tarball.

### Build Fails on macOS

Ensure Xcode Command Line Tools are installed:

```bash
xcode-select --install
```

On Apple Silicon (M1/M2/M3/M4), OpenBLAS will automatically detect the ARM architecture and build optimized kernels.

### Build Fails with LTO Linker Error on macOS

If you see errors like:

```text
ld: -lto_library library filename must be 'libLTO.dylib'
make[1]: *** [xscblat1] Error 1
```

This is caused by macOS Clang's LTO (Link Time Optimization) incompatibility with OpenBLAS test binaries. The solution is to build only library targets using `make libs netlib` instead of the default `make` target. This skips test binary linking entirely. The current `openblas.cmake` already applies this fix.

### Build Fails Due to Fortran Compiler

This configuration uses `NO_FORTRAN=1`, so a Fortran compiler is not required. If you need LAPACK support (which requires Fortran), install gfortran:

```bash
# macOS
brew install gfortran

# Then change NO_FORTRAN=1 to NO_FORTRAN=0 and NO_LAPACK=1 to NO_LAPACK=0 in openblas.cmake
```

### Rebuild OpenBLAS from Scratch

To force a full rebuild, remove the install and source directories:

```bash
rm -rf download/openblas
cd build && cmake ..
```

### Link Error: Undefined Reference to `pthread_*`

OpenBLAS uses pthreads for multi-threading. Ensure `pthread` is linked:

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE openblas_lib m pthread)
```

### Controlling the Number of Threads

OpenBLAS uses multi-threading by default. To control:

```bash
# Environment variable
export OPENBLAS_NUM_THREADS=1  # Single-threaded
export OPENBLAS_NUM_THREADS=4  # 4 threads
```

Or programmatically:

```cpp
openblas_set_num_threads(1);  // Single-threaded
```

### Using OpenBLAS with GSL

OpenBLAS can replace GSL's bundled CBLAS for better performance:

```cmake
# Link GSL with OpenBLAS instead of libgslcblas
target_link_libraries(${PROJECT_NAME} PRIVATE gsl_lib openblas_lib m pthread)
```

---

## References

- [OpenBLAS Official Website](https://www.openblas.net/)
- [OpenBLAS GitHub Repository](https://github.com/OpenMathLib/OpenBLAS)
- [OpenBLAS Wiki](https://github.com/OpenMathLib/OpenBLAS/wiki)
- [CBLAS Reference (Netlib)](https://www.netlib.org/blas/#_cblas)
- [BLAS Quick Reference](https://www.netlib.org/blas/blasqr.pdf)
- [CMake execute_process Documentation](https://cmake.org/cmake/help/latest/command/execute_process.html)
- [CMake file(DOWNLOAD) Documentation](https://cmake.org/cmake/help/latest/command/file.html#download)
