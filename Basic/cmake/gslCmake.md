# gsl.cmake Reference

## Overview

`gsl.cmake` is a CMake configuration file that automatically downloads, builds, and links the GSL library.
It uses CMake's `file(DOWNLOAD)` and `execute_process` to manage the dependency, with caching in the `download/` directory to avoid redundant downloads and rebuilds.

GSL (GNU Scientific Library) is a free numerical library for C and C++ programmers. It provides over 1,000 routines for mathematical computation including random number generators, special functions, least-squares fitting, FFT, linear algebra, statistics, interpolation, numerical differentiation/integration, and more.

GSL is a pure C library. C++ from利用する場合は、C のヘッダ (`<gsl/gsl_*.h>`) をそのまま `#include` して使用します。

## File Information

| Item | Details |
|------|---------|
| Source Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/gsl` |
| Install Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/gsl-install` |
| Download URL | https://ftp.gnu.org/gnu/gsl/gsl-2.8.tar.gz |
| Version | 2.8 |
| License | GNU GPL v3 |

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
GSL/
├── cmake/
│   ├── gsl.cmake          # This configuration file
│   └── gslCmake.md        # This document
├── download/gsl
│   ├── gsl/               # GSL source (cached, downloaded from ftp.gnu.org)
│   └── gsl-install/       # GSL built artifacts (lib/, include/)
│       ├── include/
│       │   └── gsl/
│       │       ├── gsl_blas.h
│       │       ├── gsl_deriv.h
│       │       ├── gsl_fft_real.h
│       │       ├── gsl_linalg.h
│       │       ├── gsl_matrix.h
│       │       ├── gsl_randist.h
│       │       ├── gsl_rng.h
│       │       ├── gsl_sort.h
│       │       ├── gsl_spline.h
│       │       ├── gsl_statistics.h
│       │       ├── gsl_vector.h
│       │       ├── gsl_version.h
│       │       └── ... (300+ headers)
│       └── lib/
│           ├── libgsl.a
│           └── libgslcblas.a
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## Usage

### Adding to CMakeLists.txt

```cmake
# Automatically include gsl.cmake if it exists
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/gsl.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/gsl.cmake)
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
set(GSL_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(GSL_SOURCE_DIR ${GSL_DOWNLOAD_DIR}/gsl)
set(GSL_INSTALL_DIR ${GSL_DOWNLOAD_DIR}/gsl-install)
set(GSL_VERSION "2.8")
set(GSL_URL "https://ftp.gnu.org/gnu/gsl/gsl-${GSL_VERSION}.tar.gz")
```

### 2. Cache Check and Conditional Build

```cmake
if(EXISTS ${GSL_INSTALL_DIR}/lib/libgsl.a AND EXISTS ${GSL_INSTALL_DIR}/lib/libgslcblas.a)
    message(STATUS "GSL already built: ${GSL_INSTALL_DIR}/lib/libgsl.a")
else()
    # Download, configure, build, and install ...
endif()
```

The cache logic works as follows:

| Condition | Action |
|-----------|--------|
| `gsl-install/lib/libgsl.a` exists | Skip everything (use cached build) |
| `gsl/configure` exists (install missing) | Skip download, run configure/make/install |
| Nothing exists | Download, extract, configure, make, install |

### 3. Download (if needed)

```cmake
file(DOWNLOAD
    ${GSL_URL}
    ${GSL_DOWNLOAD_DIR}/gsl-${GSL_VERSION}.tar.gz
    SHOW_PROGRESS
    STATUS DOWNLOAD_STATUS
)
file(ARCHIVE_EXTRACT
    INPUT ${GSL_DOWNLOAD_DIR}/gsl-${GSL_VERSION}.tar.gz
    DESTINATION ${GSL_DOWNLOAD_DIR}
)
file(RENAME ${GSL_DOWNLOAD_DIR}/gsl-${GSL_VERSION} ${GSL_SOURCE_DIR})
```

- Downloads from `ftp.gnu.org` (GNU official mirror)
- Extracts and renames `gsl-2.8/` to `gsl/` for a clean path

### 4. Configure, Build, and Install

```cmake
execute_process(
    COMMAND ${GSL_SOURCE_DIR}/configure
            --prefix=${GSL_INSTALL_DIR}
            --disable-shared
            --enable-static
            --with-pic
    WORKING_DIRECTORY ${GSL_SOURCE_DIR}
)
execute_process(COMMAND make -j4 WORKING_DIRECTORY ${GSL_SOURCE_DIR})
execute_process(COMMAND make install WORKING_DIRECTORY ${GSL_SOURCE_DIR})
```

- `--disable-shared --enable-static`: Builds static libraries only
- `--with-pic`: Generates position-independent code
- All steps run at CMake configure time, not at build time
- GMP と異なり `--enable-cxx` オプションはありません（GSL は C ライブラリです）

### 5. Linking the Library

```cmake
add_library(gsl_lib STATIC IMPORTED)
set_target_properties(gsl_lib PROPERTIES
    IMPORTED_LOCATION ${GSL_INSTALL_DIR}/lib/libgsl.a
)

add_library(gslcblas_lib STATIC IMPORTED)
set_target_properties(gslcblas_lib PROPERTIES
    IMPORTED_LOCATION ${GSL_INSTALL_DIR}/lib/libgslcblas.a
)

target_include_directories(${PROJECT_NAME} PRIVATE ${GSL_INSTALL_DIR}/include)
target_link_libraries(${PROJECT_NAME} PRIVATE gsl_lib gslcblas_lib m)
```

Note: `gsl_lib` must be listed before `gslcblas_lib` to satisfy linker dependency order. `m` (libm) is required for math functions.

---

## GSL Libraries

GSL は2つのライブラリで構成されています:

| Library | File | Description |
|---------|------|-------------|
| `libgsl` | `libgsl.a` | GSL 本体。すべての科学計算ルーチンを含む |
| `libgslcblas` | `libgslcblas.a` | GSL 付属の CBLAS 実装。線形代数ルーチンが使用する |

`libgslcblas` は CBLAS (C interface to Basic Linear Algebra Subprograms) のリファレンス実装です。
より高速な BLAS 実装（Apple Accelerate, OpenBLAS, Intel MKL など）がある場合は、`libgslcblas` の代わりにそれらをリンクすることで性能が向上します。

---

## Key Features of GSL

| Feature | Header | Description |
|---------|--------|-------------|
| ベクトル・行列 | `gsl_vector.h`, `gsl_matrix.h` | 動的に確保されるベクトルと行列 |
| BLAS | `gsl_blas.h` | Level 1/2/3 BLAS (内積, 行列積 等) |
| 線形代数 | `gsl_linalg.h` | LU, QR, Cholesky, SVD 分解, 連立方程式の求解 |
| 固有値 | `gsl_eigen.h` | 実対称・非対称行列の固有値・固有ベクトル |
| FFT | `gsl_fft_real.h`, `gsl_fft_complex.h` | 実数列・複素数列の高速フーリエ変換 |
| 乱数生成 | `gsl_rng.h` | Mersenne Twister 他、多数の乱数生成器 |
| 確率分布 | `gsl_randist.h` | ガウス, ポアソン, 二項分布 等の乱数とPDF |
| 統計 | `gsl_statistics.h` | 平均, 分散, 標準偏差, 中央値, 共分散, 相関 |
| 補間 | `gsl_spline.h`, `gsl_interp.h` | 線形補間, 多項式補間, 三次スプライン補間 |
| 数値微分 | `gsl_deriv.h` | 中心差分による数値微分と誤差推定 |
| 数値積分 | `gsl_integration.h` | 適応型数値積分 (QAG, QAGS, QAGI 等) |
| 最小化 | `gsl_min.h`, `gsl_multimin.h` | 1次元・多次元の関数最小化 |
| 非線形最小二乗 | `gsl_multifit_nlinear.h` | Levenberg-Marquardt 等のフィッティング |
| 常微分方程式 | `gsl_odeiv2.h` | Runge-Kutta, Adams 法等による ODE 求解 |
| 特殊関数 | `gsl_sf.h` | Bessel, Legendre, Gamma, Beta 等 |
| 多項式 | `gsl_poly.h` | 多項式の評価と求根 |
| ソート | `gsl_sort.h` | 配列のソートとインデックス付きソート |
| ヒストグラム | `gsl_histogram.h` | 1次元・2次元ヒストグラム |
| モンテカルロ積分 | `gsl_monte.h` | PLAIN, MISER, VEGAS 法 |
| シミュレーテッドアニーリング | `gsl_siman.h` | 組合せ最適化 |
| ウェーブレット変換 | `gsl_wavelet.h` | Daubechies, Haar 等のウェーブレット |

---

## Usage Examples in C/C++

### ベクトル・行列と LU 分解

```c
#include <gsl/gsl_linalg.h>
#include <gsl/gsl_matrix.h>
#include <gsl/gsl_vector.h>
#include <stdio.h>

int main() {
    // 3x3 行列 A
    double a_data[] = {1, 2, 3, 4, 5, 6, 7, 8, 10};
    gsl_matrix_view A = gsl_matrix_view_array(a_data, 3, 3);

    // 右辺ベクトル b
    double b_data[] = {1, 2, 3};
    gsl_vector_view b = gsl_vector_view_array(b_data, 3);

    // 解ベクトル x
    gsl_vector *x = gsl_vector_alloc(3);

    // LU 分解と求解
    gsl_permutation *p = gsl_permutation_alloc(3);
    int signum;
    gsl_linalg_LU_decomp(&A.matrix, p, &signum);
    gsl_linalg_LU_solve(&A.matrix, p, &b.vector, x);

    printf("x = [%.6f, %.6f, %.6f]\n",
           gsl_vector_get(x, 0),
           gsl_vector_get(x, 1),
           gsl_vector_get(x, 2));

    gsl_permutation_free(p);
    gsl_vector_free(x);
    return 0;
}
```

### 統計計算

```c
#include <gsl/gsl_sort.h>
#include <gsl/gsl_statistics.h>
#include <stdio.h>

int main() {
    double data[] = {10.5, 18.2, 10.3, 15.4, 16.2, 18.3};
    size_t n = 6;

    printf("mean     = %f\n", gsl_stats_mean(data, 1, n));
    printf("variance = %f\n", gsl_stats_variance(data, 1, n));
    printf("sd       = %f\n", gsl_stats_sd(data, 1, n));
    printf("max      = %f\n", gsl_stats_max(data, 1, n));
    printf("min      = %f\n", gsl_stats_min(data, 1, n));

    // ソートしてから中央値を求める
    gsl_sort(data, 1, n);
    printf("median   = %f\n", gsl_stats_median_from_sorted_data(data, 1, n));

    return 0;
}
```

### 三次スプライン補間

```c
#include <gsl/gsl_spline.h>
#include <math.h>
#include <stdio.h>

int main() {
    const int N = 8;
    double x[8], y[8];

    for (int i = 0; i < N; i++) {
        x[i] = (double)i / N * M_PI;
        y[i] = sin(x[i]);
    }

    gsl_interp_accel *acc = gsl_interp_accel_alloc();
    gsl_spline *spline = gsl_spline_alloc(gsl_interp_cspline, N);
    gsl_spline_init(spline, x, y, N);

    for (double xi = 0.1; xi < x[N - 1]; xi += 0.2) {
        double yi = gsl_spline_eval(spline, xi, acc);
        printf("spline(%f) = %f  (exact: %f)\n", xi, yi, sin(xi));
    }

    gsl_spline_free(spline);
    gsl_interp_accel_free(acc);
    return 0;
}
```

### 数値微分

```c
#include <gsl/gsl_deriv.h>
#include <math.h>
#include <stdio.h>

double f(double x, void *params) {
    return sin(x);
}

int main() {
    gsl_function F;
    F.function = &f;
    F.params = NULL;

    double result, abserr;

    // x = pi/4 における sin(x) の微分 → cos(pi/4) ≈ 0.7071
    gsl_deriv_central(&F, M_PI / 4.0, 1e-8, &result, &abserr);
    printf("f'(pi/4)  = %.10f (exact: %.10f)\n", result, cos(M_PI / 4.0));
    printf("abs error = %.2e\n", abserr);

    return 0;
}
```

### FFT (実数列)

```c
#include <gsl/gsl_fft_halfcomplex.h>
#include <gsl/gsl_fft_real.h>
#include <stdio.h>

int main() {
    const int N = 16;
    double data[16];

    // 矩形パルスを作成
    for (int i = 0; i < N; i++)
        data[i] = (i >= 4 && i < 12) ? 1.0 : 0.0;

    // 順変換
    gsl_fft_real_wavetable *real = gsl_fft_real_wavetable_alloc(N);
    gsl_fft_real_workspace *w = gsl_fft_real_workspace_alloc(N);
    gsl_fft_real_transform(data, 1, N, real, w);
    gsl_fft_real_wavetable_free(real);

    printf("FFT coefficients:\n");
    for (int i = 0; i < N; i++)
        printf("  [%2d] = %+.6e\n", i, data[i]);

    // 逆変換
    gsl_fft_halfcomplex_wavetable *hc = gsl_fft_halfcomplex_wavetable_alloc(N);
    gsl_fft_halfcomplex_inverse(data, 1, N, hc, w);
    gsl_fft_halfcomplex_wavetable_free(hc);
    gsl_fft_real_workspace_free(w);

    printf("\nRecovered data:\n");
    for (int i = 0; i < N; i++)
        printf("  [%2d] = %.6f\n", i, data[i]);

    return 0;
}
```

### 乱数生成と確率分布

```c
#include <gsl/gsl_randist.h>
#include <gsl/gsl_rng.h>
#include <stdio.h>

int main() {
    // Mersenne Twister で乱数生成器を初期化
    gsl_rng *rng = gsl_rng_alloc(gsl_rng_mt19937);
    gsl_rng_set(rng, 12345);

    // 一様乱数 [0, 1)
    printf("Uniform:\n");
    for (int i = 0; i < 5; i++)
        printf("  %f\n", gsl_rng_uniform(rng));

    // ガウス分布 (sigma=1.0)
    printf("Gaussian (sigma=1):\n");
    for (int i = 0; i < 5; i++)
        printf("  %f\n", gsl_ran_gaussian(rng, 1.0));

    // ポアソン分布 (lambda=4.0)
    printf("Poisson (lambda=4):\n");
    for (int i = 0; i < 10; i++)
        printf("  %u\n", gsl_ran_poisson(rng, 4.0));

    gsl_rng_free(rng);
    return 0;
}
```

### 数値積分

```c
#include <gsl/gsl_integration.h>
#include <math.h>
#include <stdio.h>

double f(double x, void *params) {
    return exp(-x * x);  // ガウス関数
}

int main() {
    gsl_function F;
    F.function = &f;
    F.params = NULL;

    double result, abserr;
    size_t neval;

    // ∫₀¹ exp(-x²) dx
    gsl_integration_qng(&F, 0.0, 1.0, 1e-10, 1e-10, &result, &abserr, &neval);
    printf("integral = %.15f\n", result);
    printf("error    = %.2e\n", abserr);
    printf("neval    = %zu\n", neval);

    return 0;
}
```

### 常微分方程式 (ODE)

```c
#include <gsl/gsl_errno.h>
#include <gsl/gsl_odeiv2.h>
#include <stdio.h>

// dy/dt = -y (解析解: y = exp(-t))
int func(double t, const double y[], double dydt[], void *params) {
    (void)t;
    (void)params;
    dydt[0] = -y[0];
    return GSL_SUCCESS;
}

int main() {
    gsl_odeiv2_system sys = {func, NULL, 1, NULL};

    gsl_odeiv2_driver *d =
        gsl_odeiv2_driver_alloc_y_new(&sys, gsl_odeiv2_step_rk4, 1e-3, 1e-8, 1e-8);

    double t = 0.0;
    double y[1] = {1.0};  // y(0) = 1

    for (int i = 1; i <= 10; i++) {
        double ti = (double)i * 0.5;
        int status = gsl_odeiv2_driver_apply(d, &t, ti, y);
        if (status != GSL_SUCCESS) break;
        printf("t = %.1f, y = %.8f (exact: %.8f)\n", t, y[0], exp(-t));
    }

    gsl_odeiv2_driver_free(d);
    return 0;
}
```

---

## GSL API Conventions

### 関数の命名規則

GSL の関数名は一貫した命名規則に従っています:

| Pattern | Example | Description |
|---------|---------|-------------|
| `gsl_<module>_alloc` | `gsl_vector_alloc(n)` | メモリの確保 |
| `gsl_<module>_free` | `gsl_vector_free(v)` | メモリの解放 |
| `gsl_<module>_set` | `gsl_vector_set(v, i, x)` | 値の設定 |
| `gsl_<module>_get` | `gsl_vector_get(v, i)` | 値の取得 |

### エラーハンドリング

GSL の関数は通常、整数のエラーコードを返します:

```c
#include <gsl/gsl_errno.h>

int status = gsl_some_function(...);
if (status != GSL_SUCCESS) {
    fprintf(stderr, "GSL error: %s\n", gsl_strerror(status));
}
```

主なエラーコード:

| Code | Constant | Description |
|------|----------|-------------|
| 0 | `GSL_SUCCESS` | 正常終了 |
| 1 | `GSL_EDOM` | 定義域エラー |
| 2 | `GSL_ERANGE` | 値域エラー (オーバーフロー等) |
| 4 | `GSL_EINVAL` | 不正な引数 |
| 8 | `GSL_ENOMEM` | メモリ確保失敗 |

### メモリ管理

GSL は `_alloc` / `_free` パターンでメモリを管理します。確保したオブジェクトは必ず対応する `_free` で解放してください:

```c
gsl_vector *v = gsl_vector_alloc(10);
// ... 使用 ...
gsl_vector_free(v);

gsl_matrix *m = gsl_matrix_alloc(3, 3);
// ... 使用 ...
gsl_matrix_free(m);
```

---

## Comparison: GSL vs Other Libraries

| Feature | GSL | Eigen | Armadillo | LAPACK |
|---------|-----|-------|-----------|--------|
| Language | C | C++ | C++ | Fortran/C |
| License | GPL v3 | MPL 2 | Apache 2 | BSD |
| Header-only | No | Yes | Partial | No |
| Linear Algebra | Yes | Yes | Yes | Yes |
| FFT | Yes | Yes | Yes | No |
| Statistics | Yes | No | No | No |
| Random Numbers | Yes | No | No | No |
| Special Functions | Yes | No | No | No |
| ODE Solver | Yes | No | No | No |
| Interpolation | Yes | No | No | No |
| Numerical Integration | Yes | No | No | No |

GSL は「科学計算のスイスアーミーナイフ」として、幅広い数値計算機能を単一のライブラリで提供します。
Eigen や Armadillo は線形代数に特化しており、C++ テンプレートによる高速化に優れますが、統計・FFT・ODE 等の機能は含みません。

---

## Troubleshooting

### Download Fails

If `ftp.gnu.org` is unreachable, you can manually download and place the tarball:

```bash
curl -L -o download/gsl-2.8.tar.gz https://ftp.gnu.org/gnu/gsl/gsl-2.8.tar.gz
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

### Rebuild GSL from Scratch

To force a full rebuild, remove the install and source directories:

```bash
rm -rf download/gsl-install download/gsl
cd build && cmake ..
```

### Link Error: Undefined Reference to `cblas_*`

`libgsl.a` depends on `libgslcblas.a` (or another CBLAS implementation). Ensure that `gslcblas_lib` is linked after `gsl_lib`:

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE gsl_lib gslcblas_lib m)
```

### Link Error: Undefined Reference to `sin`, `cos`, `exp` etc.

Math functions require linking with `-lm` (libm). The `m` in `target_link_libraries` handles this:

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE gsl_lib gslcblas_lib m)
```

### Using a Faster BLAS Implementation

To use Apple Accelerate or OpenBLAS instead of the bundled CBLAS:

```cmake
# Apple Accelerate (macOS)
target_link_libraries(${PROJECT_NAME} PRIVATE gsl_lib "-framework Accelerate")

# OpenBLAS
target_link_libraries(${PROJECT_NAME} PRIVATE gsl_lib openblas m)
```

In these cases, `gslcblas_lib` is not needed.

---

## References

- [GSL Official Website](https://www.gnu.org/software/gsl/)
- [GSL Reference Manual](https://www.gnu.org/software/gsl/doc/html/)
- [GSL Source (FTP)](https://ftp.gnu.org/gnu/gsl/)
- [C++ Introduction to GSL (日本語)](https://modeling-res-lab.com/programming/gsl.html)
- [CMake execute_process Documentation](https://cmake.org/cmake/help/latest/command/execute_process.html)
- [CMake file(DOWNLOAD) Documentation](https://cmake.org/cmake/help/latest/command/file.html#download)
