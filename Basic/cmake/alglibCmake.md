# alglib.cmake Reference

## Overview

`alglib.cmake` is a CMake configuration file that automatically downloads, builds, and links the ALGLIB library.
It uses CMake's `file(DOWNLOAD)` and `execute_process` to manage the dependency, with caching in the `download/` directory to avoid redundant downloads and rebuilds.

ALGLIB is a cross-platform numerical analysis and data processing library. It provides routines for linear algebra, eigenvalue problems, interpolation, curve fitting, optimization, FFT, statistics, special functions, and more.

ALGLIB is a C++ library used through the `alglib::` namespace. Arrays use custom types such as `alglib::real_1d_array` and `alglib::real_2d_array`.

## File Information

| Item | Details |
|------|---------|
| Source Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/alglib` |
| Install Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/alglib-install` |
| Download URL | https://www.alglib.net/translator/re/alglib-4.07.0.cpp.gpl.zip |
| Version | 4.07.0 |
| License | GNU GPL v2+ |

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
Alglib/
├── cmake/
│   ├── alglib.cmake        # This configuration file
│   └── alglibCmake.md      # This document
├── download/
│   ├── alglib/              # ALGLIB source (cached, downloaded from alglib.net)
│   │   └── cpp/
│   │       └── src/         # All .h and .cpp files
│   │           ├── ap.h / ap.cpp           # Core types
│   │           ├── linalg.h / linalg.cpp   # Linear algebra
│   │           ├── solvers.h / solvers.cpp  # Equation solvers
│   │           ├── interpolation.h / .cpp   # Interpolation
│   │           ├── optimization.h / .cpp    # Optimization
│   │           ├── fasttransforms.h / .cpp  # FFT
│   │           ├── statistics.h / .cpp      # Statistics
│   │           ├── specialfunctions.h / .cpp# Special functions
│   │           ├── dataanalysis.h / .cpp    # Data analysis (PCA, k-means, etc.)
│   │           ├── diffequations.h / .cpp   # ODE solvers
│   │           ├── integration.h / .cpp     # Numerical integration
│   │           ├── alglibmisc.h / .cpp      # Misc (kd-trees, etc.)
│   │           └── alglibinternal.h / .cpp  # Internal helpers
│   └── alglib-install/      # Built artifacts
│       ├── include/         # Header files (.h)
│       └── lib/
│           └── libalglib.a  # Static library
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## Usage

### Adding to CMakeLists.txt

```cmake
include("./cmake/alglib.cmake")
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
set(ALGLIB_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(ALGLIB_SOURCE_DIR ${ALGLIB_DOWNLOAD_DIR}/alglib)
set(ALGLIB_INSTALL_DIR ${ALGLIB_DOWNLOAD_DIR}/alglib-install)
set(ALGLIB_VERSION "4.07.0")
set(ALGLIB_URL "https://www.alglib.net/translator/re/alglib-${ALGLIB_VERSION}.cpp.gpl.zip")
```

### 2. Cache Check and Conditional Build

```cmake
if(EXISTS ${ALGLIB_INSTALL_DIR}/lib/libalglib.a)
    message(STATUS "ALGLIB already built: ${ALGLIB_INSTALL_DIR}/lib/libalglib.a")
else()
    # Download, compile, and install ...
endif()
```

The cache logic works as follows:

| Condition | Action |
|-----------|--------|
| `alglib-install/lib/libalglib.a` exists | Skip everything (use cached build) |
| `alglib/cpp/src/ap.h` exists (install missing) | Skip download, compile and install |
| Nothing exists | Download, extract, compile, install |

### 3. Download (if needed)

```cmake
file(DOWNLOAD
    ${ALGLIB_URL}
    ${ALGLIB_ARCHIVE}
    SHOW_PROGRESS
    STATUS DOWNLOAD_STATUS
)
file(ARCHIVE_EXTRACT
    INPUT ${ALGLIB_ARCHIVE}
    DESTINATION ${ALGLIB_DOWNLOAD_DIR}/alglib-tmp
)
file(RENAME ... ${ALGLIB_SOURCE_DIR})
```

- Downloads zip archive from `alglib.net`
- Extracts and renames to `alglib/` for a clean path

### 4. Compile and Install

```cmake
# Compile each .cpp file
execute_process(
    COMMAND ${ALGLIB_CXX} -O2 -fPIC -std=c++17
            -I${ALGLIB_SOURCE_DIR}/cpp/src
            -c ${SRC_FILE}
            -o ${OBJ_FILE}
    ...
)

# Archive into static library
execute_process(
    COMMAND ${CMAKE_AR} rcs ${ALGLIB_INSTALL_DIR}/lib/libalglib.a ${ALGLIB_OBJECTS}
    ...
)

# Copy headers
file(COPY ${HDR} DESTINATION ${ALGLIB_INSTALL_DIR}/include)
```

- ALGLIB does not ship with a build system (no Makefile, no CMakeLists.txt), so source files are compiled directly
- All `.cpp` files are compiled with `-O2 -fPIC -std=c++17`
- `ar rcs` creates the static library `libalglib.a`
- Header files are copied to the install directory
- All steps run at CMake configure time, not at build time

### 5. Linking the Library

```cmake
add_library(alglib_lib STATIC IMPORTED)
set_target_properties(alglib_lib PROPERTIES
    IMPORTED_LOCATION ${ALGLIB_INSTALL_DIR}/lib/libalglib.a
)

target_include_directories(${PROJECT_NAME} PRIVATE ${ALGLIB_INSTALL_DIR}/include)
target_link_libraries(${PROJECT_NAME} PRIVATE alglib_lib)
```

Unlike GSL, ALGLIB consists of a single library (`libalglib.a`). No additional linking to CBLAS or libm is required.

---

## ALGLIB Library

ALGLIB consists of a single static library:

| Library | File | Description |
|---------|------|-------------|
| `libalglib` | `libalglib.a` | Main ALGLIB library containing all numerical routines |

---

## Key Features of ALGLIB

| Feature | Header | Description |
|---------|--------|-------------|
| Core Types | `ap.h` | `real_1d_array`, `real_2d_array`, `complex_1d_array`, `ae_int_t`, etc. |
| Linear Algebra | `linalg.h` | LU, QR, Cholesky, SVD decomposition, matrix operations |
| Eigenvalues | `linalg.h` | Eigenvalues/eigenvectors of symmetric and non-symmetric matrices |
| Equation Solvers | `solvers.h` | Dense/sparse linear and nonlinear equation solvers |
| Interpolation | `interpolation.h` | 1D/2D splines, polynomial interpolation, RBF, curve/surface fitting |
| Optimization | `optimization.h` | Levenberg-Marquardt, L-BFGS, CG, LP, QP, NLP, MINLP |
| FFT | `fasttransforms.h` | Real/complex FFT, convolution, correlation |
| Statistics | `statistics.h` | Descriptive statistics, Pearson/Spearman correlation, statistical tests |
| Special Functions | `specialfunctions.h` | Bessel, Gamma, Beta, error function, etc. |
| Data Analysis | `dataanalysis.h` | PCA, LDA, k-means++, decision forests, neural networks |
| Numerical Integration | `integration.h` | Adaptive numerical integration (Gauss-Kronrod, etc.) |
| ODE | `diffequations.h` | ODE solvers |
| Miscellaneous | `alglibmisc.h` | kd-tree, nearest neighbor search |

---

## Usage Examples in C/C++

### Solving Linear Systems (Ax = b)

```cpp
#include "ap.h"
#include "solvers.h"

int main() {
    alglib::real_2d_array a("[[1,2,3],[4,5,6],[7,8,10]]");
    alglib::real_1d_array b("[14,32,51]");

    alglib::ae_int_t info;
    alglib::densesolverreport rep;
    alglib::real_1d_array x;
    alglib::rmatrixsolve(a, 3, b, info, rep, x);

    if (info > 0) {
        printf("x = [%.6f, %.6f, %.6f]\n", x(0), x(1), x(2));
    }
    return 0;
}
```

### Eigenvalue Decomposition (Symmetric Matrix)

```cpp
#include "ap.h"
#include "linalg.h"

int main() {
    alglib::real_2d_array a("[[4,1,2],[1,3,1],[2,1,5]]");

    alglib::real_1d_array d;
    alglib::real_2d_array z;
    alglib::smatrixevd(a, 3, 1, true, d, z);

    for (int i = 0; i < 3; i++)
        printf("lambda[%d] = %.6f\n", i, d(i));

    return 0;
}
```

### Cubic Spline Interpolation

```cpp
#include "ap.h"
#include "interpolation.h"
#include <cmath>

int main() {
    const int N = 8;
    alglib::real_1d_array x, y;
    x.setlength(N);
    y.setlength(N);

    for (int i = 0; i < N; i++) {
        x(i) = (double)i / N * M_PI;
        y(i) = sin(x(i));
    }

    alglib::spline1dinterpolant spline;
    alglib::spline1dbuildcubic(x, y, N, 2, 0.0, 2, 0.0, spline);

    for (double xi = 0.1; xi < x(N - 1); xi += 0.3) {
        double yi = alglib::spline1dcalc(spline, xi);
        printf("spline(%.4f) = %.6f  (exact: %.6f)\n", xi, yi, sin(xi));
    }

    return 0;
}
```

### FFT (Real-to-Complex)

```cpp
#include "ap.h"
#include "fasttransforms.h"

int main() {
    alglib::real_1d_array signal("[1,0,1,0,1,0,1,0]");

    alglib::complex_1d_array spectrum;
    alglib::fftr1d(signal, spectrum);

    for (int i = 0; i < spectrum.length(); i++)
        printf("F[%d] = %+.6f %+.6fi\n", i, spectrum(i).x, spectrum(i).y);

    // Inverse FFT
    alglib::real_1d_array recovered;
    alglib::fftr1dinv(spectrum, 8, recovered);

    for (int i = 0; i < 8; i++)
        printf("recovered[%d] = %.6f\n", i, recovered(i));

    return 0;
}
```

### Nonlinear Least Squares Fitting (Levenberg-Marquardt)

```cpp
#include "ap.h"
#include "optimization.h"
#include <cmath>

// Model: y = a * exp(-b * x)
void residual(const alglib::real_1d_array &c,
              const alglib::real_1d_array &x,
              double &func, void *ptr) {
    func = c(0) * exp(-c(1) * x(0));
}

int main() {
    // Data: x values and y values
    alglib::real_2d_array xmat("[[0],[1],[2],[3],[4]]");
    alglib::real_1d_array yobs("[3.0, 1.819, 1.104, 0.670, 0.406]");

    alglib::real_1d_array c("[1.0, 1.0]");  // Initial guess

    alglib::lsfitstate state;
    alglib::lsfitreport rep;
    alglib::ae_int_t info;

    alglib::lsfitcreatef(xmat, yobs, c, 1.0e-6, state);
    alglib::lsfitsetcond(state, 1.0e-8, 0);
    alglib::lsfitfit(state, residual, NULL, NULL);
    alglib::lsfitresults(state, info, c, rep);

    printf("a = %.6f, b = %.6f\n", c(0), c(1));
    return 0;
}
```

### Descriptive Statistics

```cpp
#include "ap.h"
#include "statistics.h"
#include <cmath>

int main() {
    alglib::real_1d_array data("[10.5, 18.2, 10.3, 15.4, 16.2, 18.3]");

    double mean, variance, skewness, kurtosis;
    alglib::samplemoments(data, 6, mean, variance, skewness, kurtosis);

    printf("mean     = %f\n", mean);
    printf("variance = %f\n", variance);
    printf("sd       = %f\n", sqrt(variance));

    return 0;
}
```

### Pearson Correlation

```cpp
#include "ap.h"
#include "statistics.h"

int main() {
    alglib::real_1d_array x("[1, 2, 3, 4, 5]");
    alglib::real_1d_array y("[2.1, 3.9, 6.2, 7.8, 10.1]");

    double corr = alglib::pearsoncorr2(x, y);
    printf("Pearson correlation = %.6f\n", corr);

    return 0;
}
```

### Special Functions

```cpp
#include "ap.h"
#include "specialfunctions.h"

int main() {
    printf("Gamma(5) = %.1f\n", alglib::gammafunction(5.0));     // 24.0
    printf("erf(1.0) = %.6f\n", alglib::errorfunction(1.0));     // 0.842701

    double sgn;
    printf("ln(Gamma(10)) = %.6f\n", alglib::lngamma(10.0, &sgn));

    return 0;
}
```

---

## ALGLIB API Conventions

### Data Types

ALGLIB uses its own array types:

| Type | Description |
|------|-------------|
| `alglib::real_1d_array` | 1D array of doubles |
| `alglib::real_2d_array` | 2D matrix of doubles |
| `alglib::complex_1d_array` | 1D array of complex numbers |
| `alglib::complex_2d_array` | 2D matrix of complex numbers |
| `alglib::ae_int_t` | ALGLIB standard integer type |

### Array Initialization

```cpp
// Initialize from string
alglib::real_1d_array x("[1, 2, 3, 4, 5]");
alglib::real_2d_array m("[[1,2],[3,4]]");

// Initialize with specified size
alglib::real_1d_array x;
x.setlength(5);
x(0) = 1.0; x(1) = 2.0;

// Initialize from existing C array
double raw[] = {1.0, 2.0, 3.0};
alglib::real_1d_array x;
x.setcontent(3, raw);
```

### Element Access

Unlike GSL (`gsl_vector_get/set`), ALGLIB uses `operator()` for element access:

```cpp
alglib::real_1d_array v("[1, 2, 3]");
double val = v(0);     // read
v(1) = 5.0;           // write

alglib::real_2d_array m("[[1,2],[3,4]]");
double val = m(0, 1);  // row 0, column 1
m(1, 0) = 9.0;
```

### Error Handling

ALGLIB reports errors in two ways:

1. **info parameter**: Many functions have an `ae_int_t& info` output parameter
   - `info > 0`: Success
   - `info <= 0`: Failure (the value indicates the error type)

2. **Exceptions**: Serious problems throw an `alglib::ap_error` exception

```cpp
alglib::ae_int_t info;
alglib::densesolverreport rep;
alglib::real_1d_array x;
alglib::rmatrixsolve(a, n, b, info, rep, x);

if (info > 0) {
    // Success
} else {
    // Failure
}
```

### Memory Management

ALGLIB's C++ interface follows the RAII pattern. No manual `alloc/free` like GSL is needed:

```cpp
// GSL (manual management required)
gsl_vector *v = gsl_vector_alloc(10);
// ... use ...
gsl_vector_free(v);

// ALGLIB (automatic management)
alglib::real_1d_array v;
v.setlength(10);
// ... use ...
// Automatically freed when going out of scope
```

---

## Comparison: ALGLIB vs GSL vs Other Libraries

| Feature | ALGLIB | GSL | Eigen | Armadillo |
|---------|--------|-----|-------|-----------|
| Language | C++ | C | C++ | C++ |
| License | GPL v2+ | GPL v3 | MPL 2 | Apache 2 |
| Build System | None (source compile) | autotools | Header-only | Partial |
| Memory Management | RAII (automatic) | Manual (alloc/free) | RAII | RAII |
| Linear Algebra | Yes | Yes | Yes | Yes |
| FFT | Yes | Yes | Yes | Yes |
| Statistics | Yes | Yes | No | No |
| Optimization | Yes (LP/QP/NLP) | Limited | No | No |
| Interpolation | Yes | Yes | No | No |
| Data Analysis | Yes (PCA/k-means/NN) | No | No | No |
| Special Functions | Yes | Yes | No | No |
| ODE Solver | Yes | Yes | No | No |

ALGLIB provides a wide range of numerical computing features similar to GSL, but its native C++ RAII design eliminates the need for manual memory management.
It also includes features not found in GSL, such as data analysis (PCA, decision forests, neural networks) and advanced optimization (LP, QP, MINLP).

---

## Troubleshooting

### Download Fails

If `alglib.net` is unreachable, you can manually download and place the zip:

```bash
curl -L -o download/alglib-4.07.0.cpp.gpl.zip \
    https://www.alglib.net/translator/re/alglib-4.07.0.cpp.gpl.zip
```

Then re-run `cmake ..` and the extraction will proceed from the cached archive.

### Compile Fails

Ensure a C++17 compatible compiler is available:

```bash
# macOS
xcode-select --install
c++ --version

# Check C++17 support
c++ -std=c++17 -x c++ -E /dev/null
```

### Rebuild ALGLIB from Scratch

To force a full rebuild, remove the install and source directories:

```bash
rm -rf download/alglib-install download/alglib
cd build && cmake ..
```

### Link Error: Undefined Reference to ALGLIB Functions

Ensure that `alglib_lib` is linked properly:

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE alglib_lib)
```

### Header Not Found

Ensure the include directory points to the install location:

```cmake
target_include_directories(${PROJECT_NAME} PRIVATE ${ALGLIB_INSTALL_DIR}/include)
```

ALGLIB headers are included without a namespace directory:

```cpp
#include "ap.h"           // OK
#include "linalg.h"       // OK
// #include <alglib/ap.h> // NG (this path does not exist)
```

---

## References

- [ALGLIB Official Website](https://www.alglib.net/)
- [ALGLIB Download Page](https://www.alglib.net/download.php)
- [ALGLIB Documentation](https://www.alglib.net/docs.php)
- [ALGLIB Interpolation](https://www.alglib.net/interpolation/)
- [ALGLIB Optimization](https://www.alglib.net/optimization/)
- [ALGLIB Linear Algebra](https://www.alglib.net/linearalgebra/)
- [CMake execute_process Documentation](https://cmake.org/cmake/help/latest/command/execute_process.html)
- [CMake file(DOWNLOAD) Documentation](https://cmake.org/cmake/help/latest/command/file.html#download)
