# gsl.cmake リファレンス

## 概要

`gsl.cmake` は GSL ライブラリの自動ダウンロード、ビルド、リンクを行う CMake 設定ファイルです。
CMake の `file(DOWNLOAD)` と `execute_process` を使用して依存関係を管理し、`download/` ディレクトリにキャッシュすることで冗長なダウンロードとリビルドを回避します。

GSL（GNU Scientific Library）は C および C++ プログラマ向けのフリーな数値計算ライブラリです。乱数生成器、特殊関数、最小二乗フィッティング、FFT、線形代数、統計、補間、数値微分/積分など、1,000 以上の数学計算ルーチンを提供します。

GSL は純粋な C ライブラリです。C++ から使用する場合は、C ヘッダー（`<gsl/gsl_*.h>`）を直接 `#include` します。

## ファイル情報

| 項目 | 詳細 |
|------|------|
| ソースディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/gsl` |
| インストールディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/gsl-install` |
| ダウンロード URL | https://ftp.gnu.org/gnu/gsl/gsl-2.8.tar.gz |
| バージョン | 2.8 |
| ライセンス | GNU GPL v3 |

---

## インクルードガード

```cmake
include_guard(GLOBAL)
```

このファイルは `include_guard(GLOBAL)` を使用して、複数回インクルードされても一度だけ実行されるようにしています。

**必要な理由：**

- configure 時の `execute_process` の重複呼び出しを防止
- `target_link_libraries` での重複リンクを防止

---

## ディレクトリ構造

```
GSL/
├── cmake/
│   ├── gsl.cmake          # この設定ファイル
│   └── gslCmake.md        # このドキュメント
├── download/gsl
│   ├── gsl/               # GSL ソース（キャッシュ、ftp.gnu.org からダウンロード）
│   └── gsl-install/       # GSL ビルド成果物（lib/, include/）
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
│       │       └── ...（300 以上のヘッダー）
│       └── lib/
│           ├── libgsl.a
│           └── libgslcblas.a
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## 使い方

### CMakeLists.txt への追加

```cmake
# gsl.cmake が存在する場合に自動インクルード
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/gsl.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/gsl.cmake)
endif()
```

### ビルド

```bash
mkdir build && cd build
cmake ..
make
```

---

## 処理の流れ

### 1. ディレクトリパスの設定

```cmake
set(GSL_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(GSL_SOURCE_DIR ${GSL_DOWNLOAD_DIR}/gsl)
set(GSL_INSTALL_DIR ${GSL_DOWNLOAD_DIR}/gsl-install)
set(GSL_VERSION "2.8")
set(GSL_URL "https://ftp.gnu.org/gnu/gsl/gsl-${GSL_VERSION}.tar.gz")
```

### 2. キャッシュチェックと条件付きビルド

```cmake
if(EXISTS ${GSL_INSTALL_DIR}/lib/libgsl.a AND EXISTS ${GSL_INSTALL_DIR}/lib/libgslcblas.a)
    message(STATUS "GSL already built: ${GSL_INSTALL_DIR}/lib/libgsl.a")
else()
    # ダウンロード、設定、ビルド、インストール ...
endif()
```

キャッシュのロジックは以下の通りです：

| 条件 | アクション |
|------|----------|
| `gsl-install/lib/libgsl.a` が存在 | すべてスキップ（キャッシュされたビルドを使用） |
| `gsl/configure` が存在（インストールなし） | ダウンロードをスキップ、configure/make/install を実行 |
| 何も存在しない | ダウンロード、展開、configure、make、install |

### 3. ダウンロード（必要な場合）

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

- `ftp.gnu.org`（GNU 公式ミラー）からダウンロード
- `gsl-2.8/` を `gsl/` にリネーム（クリーンなパスのため）

### 4. 設定、ビルド、インストール

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

- `--disable-shared --enable-static`：静的ライブラリのみビルド
- `--with-pic`：位置独立コードを生成
- すべてのステップは CMake configure 時（ビルド時ではなく）に実行
- GMP とは異なり、`--enable-cxx` オプションはありません（GSL は C ライブラリ）

### 5. ライブラリのリンク

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

注意：リンカーの依存関係の順序を満たすため、`gsl_lib` を `gslcblas_lib` の前に記述する必要があります。`m`（libm）は数学関数に必要です。

---

## GSL ライブラリ

GSL は 2 つのライブラリで構成されます：

| ライブラリ | ファイル | 説明 |
|----------|--------|------|
| `libgsl` | `libgsl.a` | すべての科学計算ルーチンを含む GSL メインライブラリ |
| `libgslcblas` | `libgslcblas.a` | GSL 付属の CBLAS 実装、線形代数ルーチンが使用 |

`libgslcblas` は CBLAS（基本線形代数副プログラムの C インターフェース）のリファレンス実装です。
より高速な BLAS 実装（Apple Accelerate、OpenBLAS、Intel MKL など）が利用可能な場合、`libgslcblas` の代わりにリンクすることでパフォーマンスが向上します。

---

## GSL の主な機能

| 機能 | ヘッダー | 説明 |
|------|--------|------|
| ベクトルと行列 | `gsl_vector.h`, `gsl_matrix.h` | 動的に割り当てられるベクトルと行列 |
| BLAS | `gsl_blas.h` | レベル 1/2/3 BLAS（内積、行列乗算など） |
| 線形代数 | `gsl_linalg.h` | LU, QR, コレスキー, SVD 分解、連立方程式の求解 |
| 固有値 | `gsl_eigen.h` | 実対称/非対称行列の固有値と固有ベクトル |
| FFT | `gsl_fft_real.h`, `gsl_fft_complex.h` | 実数・複素数列の高速フーリエ変換 |
| 乱数生成 | `gsl_rng.h` | メルセンヌ・ツイスターなど多数の乱数生成器 |
| 確率分布 | `gsl_randist.h` | ガウス分布、ポアソン分布、二項分布などの乱数変量と PDF |
| 統計 | `gsl_statistics.h` | 平均、分散、標準偏差、中央値、共分散、相関 |
| 補間 | `gsl_spline.h`, `gsl_interp.h` | 線形、多項式、三次スプライン補間 |
| 数値微分 | `gsl_deriv.h` | 誤差推定付き中心差分による数値微分 |
| 数値積分 | `gsl_integration.h` | 適応型数値積分（QAG, QAGS, QAGI など） |
| 最小化 | `gsl_min.h`, `gsl_multimin.h` | 1 次元および多次元関数の最小化 |
| 非線形最小二乗 | `gsl_multifit_nlinear.h` | Levenberg-Marquardt などによる曲線フィッティング |
| 常微分方程式 | `gsl_odeiv2.h` | ルンゲ-クッタ、Adams などによる ODE 求解 |
| 特殊関数 | `gsl_sf.h` | ベッセル関数、ルジャンドル関数、ガンマ関数、ベータ関数など |
| 多項式 | `gsl_poly.h` | 多項式の評価と根の求解 |
| ソート | `gsl_sort.h` | 配列のソートとインデックス付きソート |
| ヒストグラム | `gsl_histogram.h` | 1D および 2D ヒストグラム |
| モンテカルロ積分 | `gsl_monte.h` | PLAIN, MISER, VEGAS 法 |
| 焼きなまし法 | `gsl_siman.h` | 組み合わせ最適化 |
| ウェーブレット変換 | `gsl_wavelet.h` | ドベシー、ハールなどのウェーブレット |

---

## C/C++ での使用例

### ベクトル、行列、LU 分解

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

    printf("平均     = %f\n", gsl_stats_mean(data, 1, n));
    printf("分散     = %f\n", gsl_stats_variance(data, 1, n));
    printf("標準偏差 = %f\n", gsl_stats_sd(data, 1, n));
    printf("最大値   = %f\n", gsl_stats_max(data, 1, n));
    printf("最小値   = %f\n", gsl_stats_min(data, 1, n));

    // データをソートしてから中央値を計算
    gsl_sort(data, 1, n);
    printf("中央値   = %f\n", gsl_stats_median_from_sorted_data(data, 1, n));

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
        printf("spline(%f) = %f  (正確値: %f)\n", xi, yi, sin(xi));
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

    // sin(x) の x = pi/4 での微分 -> cos(pi/4) ≈ 0.7071
    gsl_deriv_central(&F, M_PI / 4.0, 1e-8, &result, &abserr);
    printf("f'(pi/4)  = %.10f (正確値: %.10f)\n", result, cos(M_PI / 4.0));
    printf("絶対誤差  = %.2e\n", abserr);

    return 0;
}
```

### FFT（実数列）

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

    printf("FFT 係数:\n");
    for (int i = 0; i < N; i++)
        printf("  [%2d] = %+.6e\n", i, data[i]);

    // 逆変換
    gsl_fft_halfcomplex_wavetable *hc = gsl_fft_halfcomplex_wavetable_alloc(N);
    gsl_fft_halfcomplex_inverse(data, 1, N, hc, w);
    gsl_fft_halfcomplex_wavetable_free(hc);
    gsl_fft_real_workspace_free(w);

    printf("\n復元されたデータ:\n");
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
    // メルセンヌ・ツイスターで乱数生成器を初期化
    gsl_rng *rng = gsl_rng_alloc(gsl_rng_mt19937);
    gsl_rng_set(rng, 12345);

    // 一様乱数 [0, 1)
    printf("一様分布:\n");
    for (int i = 0; i < 5; i++)
        printf("  %f\n", gsl_rng_uniform(rng));

    // ガウス分布（sigma=1.0）
    printf("ガウス分布（sigma=1）:\n");
    for (int i = 0; i < 5; i++)
        printf("  %f\n", gsl_ran_gaussian(rng, 1.0));

    // ポアソン分布（lambda=4.0）
    printf("ポアソン分布（lambda=4）:\n");
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
    printf("積分値   = %.15f\n", result);
    printf("誤差     = %.2e\n", abserr);
    printf("評価回数 = %zu\n", neval);

    return 0;
}
```

### 常微分方程式（ODE）

```c
#include <gsl/gsl_errno.h>
#include <gsl/gsl_odeiv2.h>
#include <stdio.h>

// dy/dt = -y（解析解: y = exp(-t)）
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
        printf("t = %.1f, y = %.8f (正確値: %.8f)\n", t, y[0], exp(-t));
    }

    gsl_odeiv2_driver_free(d);
    return 0;
}
```

---

## GSL API の規約

### 関数命名規則

GSL の関数名は一貫した命名規則に従います：

| パターン | 例 | 説明 |
|--------|-----|------|
| `gsl_<module>_alloc` | `gsl_vector_alloc(n)` | メモリ確保 |
| `gsl_<module>_free` | `gsl_vector_free(v)` | メモリ解放 |
| `gsl_<module>_set` | `gsl_vector_set(v, i, x)` | 値の設定 |
| `gsl_<module>_get` | `gsl_vector_get(v, i)` | 値の取得 |

### エラー処理

GSL の関数は通常、整数のエラーコードを返します：

```c
#include <gsl/gsl_errno.h>

int status = gsl_some_function(...);
if (status != GSL_SUCCESS) {
    fprintf(stderr, "GSL エラー: %s\n", gsl_strerror(status));
}
```

一般的なエラーコード：

| コード | 定数 | 説明 |
|-------|------|------|
| 0 | `GSL_SUCCESS` | 成功 |
| 1 | `GSL_EDOM` | 定義域エラー |
| 2 | `GSL_ERANGE` | 値域エラー（オーバーフローなど） |
| 4 | `GSL_EINVAL` | 無効な引数 |
| 8 | `GSL_ENOMEM` | メモリ確保失敗 |

### メモリ管理

GSL は `_alloc` / `_free` パターンでメモリを管理します。確保したオブジェクトは必ず対応する `_free` 関数で解放してください：

```c
gsl_vector *v = gsl_vector_alloc(10);
// ... 使用 ...
gsl_vector_free(v);

gsl_matrix *m = gsl_matrix_alloc(3, 3);
// ... 使用 ...
gsl_matrix_free(m);
```

---

## 比較：GSL vs 他のライブラリ

| 機能 | GSL | Eigen | Armadillo | LAPACK |
|------|-----|-------|-----------|--------|
| 言語 | C | C++ | C++ | Fortran/C |
| ライセンス | GPL v3 | MPL 2 | Apache 2 | BSD |
| ヘッダーオンリー | いいえ | はい | 部分的 | いいえ |
| 線形代数 | あり | あり | あり | あり |
| FFT | あり | あり | あり | なし |
| 統計 | あり | なし | なし | なし |
| 乱数 | あり | なし | なし | なし |
| 特殊関数 | あり | なし | なし | なし |
| ODE ソルバー | あり | なし | なし | なし |
| 補間 | あり | なし | なし | なし |
| 数値積分 | あり | なし | なし | なし |

GSL は「科学計算のスイスアーミーナイフ」として、単一のライブラリで幅広い数値計算機能を提供します。
Eigen と Armadillo は線形代数に特化し、C++ テンプレートによる最適化に優れますが、統計、FFT、ODE ソルバーなどの機能は含まれていません。

---

## トラブルシューティング

### ダウンロードが失敗する

`ftp.gnu.org` に接続できない場合、手動でダウンロードして配置できます：

```bash
curl -L -o download/gsl-2.8.tar.gz https://ftp.gnu.org/gnu/gsl/gsl-2.8.tar.gz
```

その後 `cmake ..` を再実行すると、キャッシュされた tarball から展開されます。

### 設定が失敗する

ビルドの前提条件が利用可能であることを確認してください：

```bash
# macOS（Xcode Command Line Tools）
xcode-select --install

# make が利用可能であることを確認
make --version
```

### GSL を最初からリビルド

完全なリビルドを強制するには、インストールディレクトリとソースディレクトリを削除します：

```bash
rm -rf download/gsl-install download/gsl
cd build && cmake ..
```

### リンクエラー：`cblas_*` への未定義参照

`libgsl.a` は `libgslcblas.a`（または別の CBLAS 実装）に依存します。`gslcblas_lib` が `gsl_lib` の後にリンクされていることを確認してください：

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE gsl_lib gslcblas_lib m)
```

### リンクエラー：`sin`、`cos`、`exp` 等への未定義参照

数学関数には `-lm`（libm）とのリンクが必要です。`target_link_libraries` の `m` がこれを処理します：

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE gsl_lib gslcblas_lib m)
```

### より高速な BLAS 実装の使用

Apple Accelerate や OpenBLAS をバンドル CBLAS の代わりに使用する場合：

```cmake
# Apple Accelerate（macOS）
target_link_libraries(${PROJECT_NAME} PRIVATE gsl_lib "-framework Accelerate")

# OpenBLAS
target_link_libraries(${PROJECT_NAME} PRIVATE gsl_lib openblas m)
```

これらの場合、`gslcblas_lib` は不要です。

---

## 参考資料

- [GSL 公式サイト](https://www.gnu.org/software/gsl/)
- [GSL リファレンスマニュアル](https://www.gnu.org/software/gsl/doc/html/)
- [GSL ソース（FTP）](https://ftp.gnu.org/gnu/gsl/)
- [CMake execute_process ドキュメント](https://cmake.org/cmake/help/latest/command/execute_process.html)
- [CMake file(DOWNLOAD) ドキュメント](https://cmake.org/cmake/help/latest/command/file.html#download)
