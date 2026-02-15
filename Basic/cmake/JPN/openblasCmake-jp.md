# openblas.cmake リファレンス

## 概要

`openblas.cmake` は、OpenBLASライブラリの自動ダウンロード・ビルド・リンクを行うCMake設定ファイルです。
CMakeの `file(DOWNLOAD)` と `execute_process` を使用して依存関係を管理し、`download/` ディレクトリにキャッシュすることで、不要なダウンロードや再ビルドを避けます。

OpenBLASは、GotoBLAS2をベースとした最適化BLASライブラリです。CPU固有のSIMD命令（SSE, AVX, AVX2, AVX-512, NEON等）とマルチスレッドを活用し、BLAS Level 1/2/3ルーチンの高性能な実装を提供します。

OpenBLASはC/Fortranライブラリです。C++から使用する場合は、CBLASヘッダ（`<cblas.h>`）を直接インクルードします。

## ファイル情報

| 項目 | 詳細 |
|------|------|
| ソースディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/openblas` |
| インストールディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/openblas-install` |
| ダウンロードURL | https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.28/OpenBLAS-0.3.28.tar.gz |
| バージョン | 0.3.28 |
| ライセンス | BSD 3-Clause |

---

## インクルードガード

```cmake
include_guard(GLOBAL)
```

このファイルは `include_guard(GLOBAL)` を使用して、複数回インクルードされても一度だけ実行されるようにしています。

**必要な理由:**

- configure時の `execute_process` の重複実行を防止
- `target_link_libraries` の重複リンクを防止

---

## ディレクトリ構造

```
OpenBLAS/
├── cmake/
│   ├── openblas.cmake         # この設定ファイル
│   ├── openblasCmake.md       # ドキュメント（英語）
│   └── openblasCmake-jp.md   # このドキュメント（日本語）
├── download/openblas
│   ├── openblas/              # OpenBLASソース（キャッシュ、GitHubからダウンロード）
│   └── openblas-install/      # OpenBLASビルド成果物（lib/, include/）
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

## 使い方

### CMakeLists.txtへの追加

```cmake
# openblas.cmakeが存在する場合に自動インクルード
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/openblas.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/openblas.cmake)
endif()
```

### ビルド

```bash
mkdir build && cd build
cmake ..
make
```

---

## 処理フロー

### 1. ディレクトリパスの設定

```cmake
set(OPENBLAS_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/openblas)
set(OPENBLAS_SOURCE_DIR ${OPENBLAS_DOWNLOAD_DIR}/openblas)
set(OPENBLAS_INSTALL_DIR ${OPENBLAS_DOWNLOAD_DIR}/openblas-install)
set(OPENBLAS_VERSION "0.3.28")
set(OPENBLAS_URL "https://github.com/OpenMathLib/OpenBLAS/releases/download/v${OPENBLAS_VERSION}/OpenBLAS-${OPENBLAS_VERSION}.tar.gz")
```

### 2. キャッシュチェックと条件付きビルド

```cmake
if(EXISTS ${OPENBLAS_INSTALL_DIR}/lib/libopenblas.a)
    message(STATUS "OpenBLAS already built: ${OPENBLAS_INSTALL_DIR}/lib/libopenblas.a")
else()
    # ダウンロード、ビルド、インストール ...
endif()
```

キャッシュロジックは以下の通りです:

| 条件 | アクション |
|------|------------|
| `openblas-install/lib/libopenblas.a` が存在 | すべてスキップ（キャッシュされたビルドを使用） |
| `openblas/Makefile` が存在（インストールが未完了） | ダウンロードをスキップ、make/installを実行 |
| 何も存在しない | ダウンロード、展開、make、install |

### 3. ダウンロード（必要な場合）

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

- GitHub（OpenMathLib公式リポジトリ）からダウンロード
- プライマリミラーが失敗した場合、レガシーのxianyi/OpenBLASリポジトリにフォールバック
- `OpenBLAS-0.3.28/` を `openblas/` にリネームしてパスを整理

### 4. ビルドとインストール

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

- OpenBLASは `make` を直接使用します（`./configure` ステップは不要）
- `libs netlib`: ライブラリターゲットのみビルド（macOSでLTOリンカーエラーを起こすテストバイナリをスキップ）
- `NO_FORTRAN=1`: Fortranコンパイラを必要としない
- `NO_LAPACK=1`: LAPACKルーチンを除外（BLASのみ）
- `USE_OPENMP=0`: スレッドにpthreadsを使用（OpenMPではなく）
- `DYNAMIC_ARCH=0`: ホストCPUアーキテクチャ専用にビルド
- `NO_SHARED=1`: 静的ライブラリのみビルド（共有ライブラリは作成しない）
- すべてのステップはCMake configure時に実行（ビルド時ではない）

### 5. ライブラリのリンク

```cmake
add_library(openblas_lib STATIC IMPORTED)
set_target_properties(openblas_lib PROPERTIES
    IMPORTED_LOCATION ${OPENBLAS_INSTALL_DIR}/lib/libopenblas.a
)

target_include_directories(${PROJECT_NAME} PRIVATE ${OPENBLAS_INSTALL_DIR}/include)
target_link_libraries(${PROJECT_NAME} PRIVATE openblas_lib m pthread)
```

注: `pthread` はOpenBLASの内部スレッドに必要です。`m`（libm）は数学関数に必要です。

---

## OpenBLASライブラリ

OpenBLASは単一の統合ライブラリを生成します:

| ライブラリ | ファイル | 説明 |
|-----------|----------|------|
| `libopenblas` | `libopenblas.a` | 全BLASルーチン（およびオプションでLAPACK）を含む統合ライブラリ |

GSL（`libgsl` + `libgslcblas` に分割）とは異なり、OpenBLASはすべてを1つのライブラリにまとめます。これによりリンクが簡素化されます。

---

## ビルドオプション

OpenBLASは多数のビルド時オプションをサポートしています。主要なオプション:

| オプション | デフォルト | 説明 |
|-----------|-----------|------|
| `NO_FORTRAN=1` | 0 | Fortranコンパイラを必要としない |
| `NO_LAPACK=1` | 0 | LAPACKルーチンを除外（BLASのみ） |
| `USE_OPENMP=1` | 0 | pthreadsの代わりにOpenMPを使用 |
| `DYNAMIC_ARCH=1` | 0 | 複数アーキテクチャ向けにビルド（実行時ディスパッチ） |
| `TARGET=xxx` | 自動 | CPUターゲットを指定（例: `HASWELL`, `SKYLAKEX`, `ARMV8`） |
| `NUM_THREADS=n` | 自動 | 最大スレッド数 |
| `NO_CBLAS=1` | 0 | CBLASインターフェースをビルドしない |
| `ONLY_CBLAS=1` | 0 | CBLASインターフェースのみビルド |
| `NO_SHARED=1` | 0 | 共有ライブラリをビルドしない（静的のみ） |
| `USE_THREAD=0` | 1 | スレッドを完全に無効化 |
| `PREFIX=/path` | `/opt/OpenBLAS` | インストール先プレフィックス |

---

## OpenBLASの主要機能（CBLASインターフェース）

### BLAS Level 1 - ベクトル演算

| 関数 | 説明 |
|------|------|
| `cblas_ddot` | 2つのベクトルのドット積 |
| `cblas_dnrm2` | ユークリッドノルム（L2ノルム） |
| `cblas_dasum` | 絶対値の和 |
| `cblas_daxpy` | y = alpha * x + y |
| `cblas_dscal` | x = alpha * x |
| `cblas_dcopy` | ベクトルxをyにコピー |
| `cblas_dswap` | ベクトルxとyを交換 |
| `cblas_idamax` | 絶対値が最大の要素のインデックス |
| `cblas_drotg` | ギブンス回転の生成 |
| `cblas_drot` | ギブンス回転の適用 |

### BLAS Level 2 - 行列-ベクトル演算

| 関数 | 説明 |
|------|------|
| `cblas_dgemv` | y = alpha * A * x + beta * y（一般行列-ベクトル積） |
| `cblas_dsymv` | y = alpha * A * x + beta * y（対称行列-ベクトル積） |
| `cblas_dtrmv` | x = A * x（三角行列-ベクトル積） |
| `cblas_dtrsv` | A * x = b を解く（三角求解） |
| `cblas_dger` | A = alpha * x * y^T + A（ランク1更新） |
| `cblas_dsyr` | A = alpha * x * x^T + A（対称ランク1更新） |
| `cblas_dsyr2` | A = alpha * x * y^T + alpha * y * x^T + A |

### BLAS Level 3 - 行列-行列演算

| 関数 | 説明 |
|------|------|
| `cblas_dgemm` | C = alpha * A * B + beta * C（一般行列積） |
| `cblas_dsymm` | C = alpha * A * B + beta * C（対称行列積） |
| `cblas_dtrmm` | B = alpha * A * B（三角行列積） |
| `cblas_dtrsm` | A * X = alpha * B を解く（三角求解、複数右辺） |
| `cblas_dsyrk` | C = alpha * A * A^T + beta * C（対称ランクk更新） |
| `cblas_dsyr2k` | C = alpha * A * B^T + alpha * B * A^T + beta * C |

---

## C/C++での使用例

### BLAS Level 1: ドット積とベクトル演算

```cpp
#include <cblas.h>
#include <cstdio>

int main() {
    double x[] = {1.0, 2.0, 3.0, 4.0, 5.0};
    double y[] = {2.0, 3.0, 4.0, 5.0, 6.0};
    int n = 5;

    // ドット積
    double dot = cblas_ddot(n, x, 1, y, 1);
    printf("x . y = %.4f\n", dot);  // 70.0

    // ユークリッドノルム
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

### BLAS Level 2: 行列-ベクトル乗算

```cpp
#include <cblas.h>
#include <cstdio>

int main() {
    // A: 3x3 行優先行列
    double A[] = {
        1.0, 2.0, 3.0,
        4.0, 5.0, 6.0,
        7.0, 8.0, 9.0
    };
    double x[] = {1.0, 1.0, 1.0};
    double y[] = {0.0, 0.0, 0.0};

    // y = 1.0 * A * x + 0.0 * y
    cblas_dgemv(CblasRowMajor, CblasNoTrans,
                3, 3,      // 行数, 列数
                1.0,       // alpha
                A, 3,      // A, lda
                x, 1,      // x, incx
                0.0,       // beta
                y, 1);     // y, incy

    printf("y = A*x = [%.1f, %.1f, %.1f]\n", y[0], y[1], y[2]);
    // 出力: [6.0, 15.0, 24.0]

    return 0;
}
```

### BLAS Level 3: 行列乗算

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

### パフォーマンスベンチマーク

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

### OpenBLASの設定とスレッド制御

```cpp
#include <cblas.h>
#include <cstdio>

int main() {
    // OpenBLASの設定情報を取得
    printf("Config:     %s\n", openblas_get_config());
    printf("Corename:   %s\n", openblas_get_corename());
    printf("Threads:    %d\n", openblas_get_num_threads());
    printf("Parallel:   %d\n", openblas_get_parallel());

    // スレッド数の制御
    openblas_set_num_threads(4);  // 4スレッドに設定
    printf("Threads (設定後): %d\n", openblas_get_num_threads());

    // シングルスレッドモード
    openblas_set_num_threads(1);

    return 0;
}
```

---

## CBLAS APIの規約

### データレイアウト

OpenBLASのCBLAS関数は、行優先と列優先の両方のレイアウトをサポートします:

```cpp
cblas_dgemm(CblasRowMajor, ...);  // C/C++の自然な順序
cblas_dgemm(CblasColMajor, ...);  // Fortranの自然な順序
```

### 転置演算

```cpp
CblasNoTrans   // Aをそのまま使用
CblasTrans     // A^T（転置）を使用
CblasConjTrans // A^H（共役転置、複素数用）を使用
```

### 命名規約

CBLAS関数名は `cblas_<接頭辞><演算>` のパターンに従います:

| 接頭辞 | データ型 |
|--------|----------|
| `s` | 単精度（`float`） |
| `d` | 倍精度（`double`） |
| `c` | 単精度複素数 |
| `z` | 倍精度複素数 |

| 演算 | レベル | 説明 |
|------|--------|------|
| `dot` | 1 | ドット積 |
| `nrm2` | 1 | ユークリッドノルム |
| `axpy` | 1 | y = alpha*x + y |
| `scal` | 1 | x = alpha*x |
| `gemv` | 2 | 一般行列-ベクトル積 |
| `gemm` | 3 | 一般行列-行列積 |
| `trsm` | 3 | 三角求解（複数右辺） |

### パラメータ

| パラメータ | 説明 |
|-----------|------|
| `order` | `CblasRowMajor` または `CblasColMajor` |
| `trans` | `CblasNoTrans`, `CblasTrans`, `CblasConjTrans` |
| `M, N, K` | 行列の次元 |
| `alpha, beta` | スカラー倍数 |
| `lda, ldb, ldc` | A, B, Cのリーディングディメンション |
| `incx, incy` | ベクトルx, yのストライド（増分） |

---

## 比較: OpenBLAS vs 他のBLAS実装

| 機能 | OpenBLAS | Apple Accelerate | Intel MKL | Reference BLAS |
|------|----------|-----------------|-----------|----------------|
| ライセンス | BSD 3-Clause | プロプライエタリ（無料） | プロプライエタリ（無料） | パブリックドメイン |
| プラットフォーム | クロスプラットフォーム | macOS/iOSのみ | x86/x86_64 | 任意 |
| CPU最適化 | あり（自動検出） | あり（Apple Silicon） | あり（Intel CPU） | なし |
| マルチスレッド | pthreads/OpenMP | GCD | OpenMP/TBB | なし |
| LAPACK含む | オプション | あり | あり | なし |
| 動的ディスパッチ | オプション | あり | あり | なし |
| パフォーマンス | 高い | 非常に高い（Apple上） | 非常に高い（Intel上） | 低い |
| ヘッダオンリー | いいえ | いいえ | いいえ | いいえ |

OpenBLASは最もポータブルな高性能BLAS実装です。x86、ARM、POWERなど多様なアーキテクチャにおいて、ベンダーロックインなしで最適に近いパフォーマンスを提供します。

---

## トラブルシューティング

### ダウンロードが失敗する

GitHubに接続できない場合は、手動でtarballをダウンロードして配置できます:

```bash
curl -L -o download/openblas/OpenBLAS-0.3.28.tar.gz \
    https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.28/OpenBLAS-0.3.28.tar.gz
```

その後、`cmake ..` を再実行すると、キャッシュされたtarballから展開が行われます。

### macOSでビルドが失敗する

Xcode Command Line Toolsがインストールされていることを確認してください:

```bash
xcode-select --install
```

Apple Silicon（M1/M2/M3/M4）では、OpenBLASは自動的にARMアーキテクチャを検出し、最適化されたカーネルをビルドします。

### macOSでLTOリンカーエラーが発生する

以下のようなエラーが表示される場合:

```text
ld: -lto_library library filename must be 'libLTO.dylib'
make[1]: *** [xscblat1] Error 1
```

これはmacOS ClangのLTO（Link Time Optimization）がOpenBLASのテストバイナリと互換性がないために発生します。解決策は、デフォルトの `make` ターゲットの代わりに `make libs netlib` を使用してライブラリターゲットのみをビルドすることです。これによりテストバイナリのリンクを完全にスキップします。現在の `openblas.cmake` にはこの修正が既に適用されています。

### Fortranコンパイラが原因でビルドが失敗する

この設定では `NO_FORTRAN=1` を使用しているため、Fortranコンパイラは不要です。LAPACKサポートが必要な場合（Fortranが必要）は、gfortranをインストールしてください:

```bash
# macOS
brew install gfortran

# openblas.cmakeの NO_FORTRAN=1 を NO_FORTRAN=0 に、
# NO_LAPACK=1 を NO_LAPACK=0 に変更してください
```

### OpenBLASをゼロから再ビルドする

完全な再ビルドを強制するには、インストールディレクトリとソースディレクトリを削除します:

```bash
rm -rf download/openblas
cd build && cmake ..
```

### リンクエラー: `pthread_*` への未定義参照

OpenBLASはマルチスレッドにpthreadsを使用します。`pthread` がリンクされていることを確認してください:

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE openblas_lib m pthread)
```

### スレッド数の制御

OpenBLASはデフォルトでマルチスレッドを使用します。制御するには:

```bash
# 環境変数
export OPENBLAS_NUM_THREADS=1  # シングルスレッド
export OPENBLAS_NUM_THREADS=4  # 4スレッド
```

またはプログラム内で:

```cpp
openblas_set_num_threads(1);  // シングルスレッド
```

### OpenBLASをGSLと組み合わせて使用する

OpenBLASはGSLのバンドルCBLASを置き換えて、パフォーマンスを向上させることができます:

```cmake
# libgslcblasの代わりにOpenBLASをリンク
target_link_libraries(${PROJECT_NAME} PRIVATE gsl_lib openblas_lib m pthread)
```

---

## 参考文献

- [OpenBLAS公式サイト](https://www.openblas.net/)
- [OpenBLAS GitHubリポジトリ](https://github.com/OpenMathLib/OpenBLAS)
- [OpenBLAS Wiki](https://github.com/OpenMathLib/OpenBLAS/wiki)
- [CBLASリファレンス（Netlib）](https://www.netlib.org/blas/#_cblas)
- [BLASクイックリファレンス](https://www.netlib.org/blas/blasqr.pdf)
- [CMake execute_process ドキュメント](https://cmake.org/cmake/help/latest/command/execute_process.html)
- [CMake file(DOWNLOAD) ドキュメント](https://cmake.org/cmake/help/latest/command/file.html#download)
