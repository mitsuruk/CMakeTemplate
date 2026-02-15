# alglib.cmake リファレンス

## 概要

`alglib.cmake` は ALGLIB ライブラリの自動ダウンロード、ビルド、リンクを行う CMake 設定ファイルです。
CMake の `file(DOWNLOAD)` と `execute_process` を使用して依存関係を管理し、`download/` ディレクトリにキャッシュすることで冗長なダウンロードとリビルドを回避します。

ALGLIB はクロスプラットフォームの数値解析・データ処理ライブラリです。線形代数、固有値問題、補間、曲線フィッティング、最適化、FFT、統計、特殊関数などのルーチンを提供します。

ALGLIB は `alglib::` 名前空間を通じて使用する C++ ライブラリです。配列には `alglib::real_1d_array` や `alglib::real_2d_array` などの独自型を使用します。

## ファイル情報

| 項目 | 詳細 |
|------|------|
| ソースディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/alglib` |
| インストールディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/alglib-install` |
| ダウンロード URL | https://www.alglib.net/translator/re/alglib-4.07.0.cpp.gpl.zip |
| バージョン | 4.07.0 |
| ライセンス | GNU GPL v2+ |

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
Alglib/
├── cmake/
│   ├── alglib.cmake        # この設定ファイル
│   └── alglibCmake.md      # このドキュメント
├── download/
│   ├── alglib/              # ALGLIB ソース（キャッシュ、alglib.net からダウンロード）
│   │   └── cpp/
│   │       └── src/         # すべての .h と .cpp ファイル
│   │           ├── ap.h / ap.cpp           # コア型
│   │           ├── linalg.h / linalg.cpp   # 線形代数
│   │           ├── solvers.h / solvers.cpp  # 方程式ソルバー
│   │           ├── interpolation.h / .cpp   # 補間
│   │           ├── optimization.h / .cpp    # 最適化
│   │           ├── fasttransforms.h / .cpp  # FFT
│   │           ├── statistics.h / .cpp      # 統計
│   │           ├── specialfunctions.h / .cpp# 特殊関数
│   │           ├── dataanalysis.h / .cpp    # データ分析（PCA、k-means など）
│   │           ├── diffequations.h / .cpp   # ODE ソルバー
│   │           ├── integration.h / .cpp     # 数値積分
│   │           ├── alglibmisc.h / .cpp      # その他（kd-tree など）
│   │           └── alglibinternal.h / .cpp  # 内部ヘルパー
│   └── alglib-install/      # ビルド成果物
│       ├── include/         # ヘッダーファイル（.h）
│       └── lib/
│           └── libalglib.a  # 静的ライブラリ
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## 使い方

### CMakeLists.txt への追加

```cmake
include("./cmake/alglib.cmake")
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
set(ALGLIB_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(ALGLIB_SOURCE_DIR ${ALGLIB_DOWNLOAD_DIR}/alglib)
set(ALGLIB_INSTALL_DIR ${ALGLIB_DOWNLOAD_DIR}/alglib-install)
set(ALGLIB_VERSION "4.07.0")
set(ALGLIB_URL "https://www.alglib.net/translator/re/alglib-${ALGLIB_VERSION}.cpp.gpl.zip")
```

### 2. キャッシュチェックと条件付きビルド

```cmake
if(EXISTS ${ALGLIB_INSTALL_DIR}/lib/libalglib.a)
    message(STATUS "ALGLIB already built: ${ALGLIB_INSTALL_DIR}/lib/libalglib.a")
else()
    # ダウンロード、コンパイル、インストール ...
endif()
```

キャッシュのロジックは以下の通りです：

| 条件 | アクション |
|------|----------|
| `alglib-install/lib/libalglib.a` が存在 | すべてスキップ（キャッシュされたビルドを使用） |
| `alglib/cpp/src/ap.h` が存在（インストールなし） | ダウンロードをスキップ、コンパイルしてインストール |
| 何も存在しない | ダウンロード、展開、コンパイル、インストール |

### 3. ダウンロード（必要な場合）

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

- `alglib.net` から zip アーカイブをダウンロード
- 展開して `alglib/` にリネーム（クリーンなパスのため）

### 4. コンパイルとインストール

```cmake
# 各 .cpp ファイルをコンパイル
execute_process(
    COMMAND ${ALGLIB_CXX} -O2 -fPIC -std=c++17
            -I${ALGLIB_SOURCE_DIR}/cpp/src
            -c ${SRC_FILE}
            -o ${OBJ_FILE}
    ...
)

# 静的ライブラリにアーカイブ
execute_process(
    COMMAND ${CMAKE_AR} rcs ${ALGLIB_INSTALL_DIR}/lib/libalglib.a ${ALGLIB_OBJECTS}
    ...
)

# ヘッダーをコピー
file(COPY ${HDR} DESTINATION ${ALGLIB_INSTALL_DIR}/include)
```

- ALGLIB にはビルドシステム（Makefile も CMakeLists.txt も）が付属しないため、ソースファイルを直接コンパイル
- すべての `.cpp` ファイルを `-O2 -fPIC -std=c++17` でコンパイル
- `ar rcs` で静的ライブラリ `libalglib.a` を作成
- ヘッダーファイルをインストールディレクトリにコピー
- すべてのステップは CMake configure 時（ビルド時ではなく）に実行

### 5. ライブラリのリンク

```cmake
add_library(alglib_lib STATIC IMPORTED)
set_target_properties(alglib_lib PROPERTIES
    IMPORTED_LOCATION ${ALGLIB_INSTALL_DIR}/lib/libalglib.a
)

target_include_directories(${PROJECT_NAME} PRIVATE ${ALGLIB_INSTALL_DIR}/include)
target_link_libraries(${PROJECT_NAME} PRIVATE alglib_lib)
```

GSL とは異なり、ALGLIB は単一のライブラリ（`libalglib.a`）で構成されます。CBLAS や libm への追加リンクは不要です。

---

## ALGLIB ライブラリ

ALGLIB は単一の静的ライブラリで構成されます：

| ライブラリ | ファイル | 説明 |
|----------|--------|------|
| `libalglib` | `libalglib.a` | すべての数値計算ルーチンを含む ALGLIB メインライブラリ |

---

## ALGLIB の主な機能

| 機能 | ヘッダー | 説明 |
|------|--------|------|
| コア型 | `ap.h` | `real_1d_array`, `real_2d_array`, `complex_1d_array`, `ae_int_t` など |
| 線形代数 | `linalg.h` | LU, QR, コレスキー, SVD 分解、行列演算 |
| 固有値 | `linalg.h` | 対称・非対称行列の固有値/固有ベクトル |
| 方程式ソルバー | `solvers.h` | 密/疎な線形・非線形方程式ソルバー |
| 補間 | `interpolation.h` | 1D/2D スプライン、多項式補間、RBF、曲線/曲面フィッティング |
| 最適化 | `optimization.h` | Levenberg-Marquardt, L-BFGS, CG, LP, QP, NLP, MINLP |
| FFT | `fasttransforms.h` | 実数/複素数 FFT、畳み込み、相関 |
| 統計 | `statistics.h` | 記述統計、ピアソン/スピアマン相関、統計検定 |
| 特殊関数 | `specialfunctions.h` | ベッセル関数、ガンマ関数、ベータ関数、誤差関数など |
| データ分析 | `dataanalysis.h` | PCA, LDA, k-means++, 決定木フォレスト、ニューラルネットワーク |
| 数値積分 | `integration.h` | 適応型数値積分（ガウス-クロンロッドなど） |
| ODE | `diffequations.h` | 常微分方程式ソルバー |
| その他 | `alglibmisc.h` | kd-tree、最近傍探索 |

---

## C/C++ での使用例

### 連立方程式の求解 (Ax = b)

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

### 固有値分解（対称行列）

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

### 三次スプライン補間

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

### FFT（実数→複素数）

```cpp
#include "ap.h"
#include "fasttransforms.h"

int main() {
    alglib::real_1d_array signal("[1,0,1,0,1,0,1,0]");

    alglib::complex_1d_array spectrum;
    alglib::fftr1d(signal, spectrum);

    for (int i = 0; i < spectrum.length(); i++)
        printf("F[%d] = %+.6f %+.6fi\n", i, spectrum(i).x, spectrum(i).y);

    // 逆 FFT
    alglib::real_1d_array recovered;
    alglib::fftr1dinv(spectrum, 8, recovered);

    for (int i = 0; i < 8; i++)
        printf("recovered[%d] = %.6f\n", i, recovered(i));

    return 0;
}
```

### 非線形最小二乗フィッティング（Levenberg-Marquardt）

```cpp
#include "ap.h"
#include "optimization.h"
#include <cmath>

// モデル: y = a * exp(-b * x)
void residual(const alglib::real_1d_array &c,
              const alglib::real_1d_array &x,
              double &func, void *ptr) {
    func = c(0) * exp(-c(1) * x(0));
}

int main() {
    // データ: x 値と y 値
    alglib::real_2d_array xmat("[[0],[1],[2],[3],[4]]");
    alglib::real_1d_array yobs("[3.0, 1.819, 1.104, 0.670, 0.406]");

    alglib::real_1d_array c("[1.0, 1.0]");  // 初期推定値

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

### 記述統計

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

### ピアソン相関

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

### 特殊関数

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

## ALGLIB API の規約

### データ型

ALGLIB は独自の配列型を使用します：

| 型 | 説明 |
|-----|------|
| `alglib::real_1d_array` | double の 1D 配列 |
| `alglib::real_2d_array` | double の 2D 行列 |
| `alglib::complex_1d_array` | 複素数の 1D 配列 |
| `alglib::complex_2d_array` | 複素数の 2D 行列 |
| `alglib::ae_int_t` | ALGLIB 標準整数型 |

### 配列の初期化

```cpp
// 文字列から初期化
alglib::real_1d_array x("[1, 2, 3, 4, 5]");
alglib::real_2d_array m("[[1,2],[3,4]]");

// サイズを指定して初期化
alglib::real_1d_array x;
x.setlength(5);
x(0) = 1.0; x(1) = 2.0;

// 既存の C 配列から初期化
double raw[] = {1.0, 2.0, 3.0};
alglib::real_1d_array x;
x.setcontent(3, raw);
```

### 要素アクセス

GSL（`gsl_vector_get/set`）とは異なり、ALGLIB は要素アクセスに `operator()` を使用します：

```cpp
alglib::real_1d_array v("[1, 2, 3]");
double val = v(0);     // 読み取り
v(1) = 5.0;           // 書き込み

alglib::real_2d_array m("[[1,2],[3,4]]");
double val = m(0, 1);  // 行 0、列 1
m(1, 0) = 9.0;
```

### エラー処理

ALGLIB は 2 つの方法でエラーを報告します：

1. **info パラメータ**：多くの関数には `ae_int_t& info` 出力パラメータがあります
   - `info > 0`：成功
   - `info <= 0`：失敗（値がエラーの種類を示す）

2. **例外**：深刻な問題は `alglib::ap_error` 例外をスローします

```cpp
alglib::ae_int_t info;
alglib::densesolverreport rep;
alglib::real_1d_array x;
alglib::rmatrixsolve(a, n, b, info, rep, x);

if (info > 0) {
    // 成功
} else {
    // 失敗
}
```

### メモリ管理

ALGLIB の C++ インターフェースは RAII パターンに従います。GSL のような手動の `alloc/free` は不要です：

```cpp
// GSL（手動管理が必要）
gsl_vector *v = gsl_vector_alloc(10);
// ... 使用 ...
gsl_vector_free(v);

// ALGLIB（自動管理）
alglib::real_1d_array v;
v.setlength(10);
// ... 使用 ...
// スコープを抜けると自動的に解放
```

---

## 比較：ALGLIB vs GSL vs 他のライブラリ

| 機能 | ALGLIB | GSL | Eigen | Armadillo |
|------|--------|-----|-------|-----------|
| 言語 | C++ | C | C++ | C++ |
| ライセンス | GPL v2+ | GPL v3 | MPL 2 | Apache 2 |
| ビルドシステム | なし（ソースコンパイル） | autotools | ヘッダーオンリー | 部分的 |
| メモリ管理 | RAII（自動） | 手動（alloc/free） | RAII | RAII |
| 線形代数 | あり | あり | あり | あり |
| FFT | あり | あり | あり | あり |
| 統計 | あり | あり | なし | なし |
| 最適化 | あり（LP/QP/NLP） | 限定的 | なし | なし |
| 補間 | あり | あり | なし | なし |
| データ分析 | あり（PCA/k-means/NN） | なし | なし | なし |
| 特殊関数 | あり | あり | なし | なし |
| ODE ソルバー | あり | あり | なし | なし |

ALGLIB は GSL と同様に幅広い数値計算機能を提供しますが、ネイティブ C++ RAII 設計により手動メモリ管理が不要です。
また、GSL にはないデータ分析（PCA、決定木フォレスト、ニューラルネットワーク）や高度な最適化（LP、QP、MINLP）などの機能も含まれています。

---

## トラブルシューティング

### ダウンロードが失敗する

`alglib.net` に接続できない場合、手動でダウンロードして配置できます：

```bash
curl -L -o download/alglib-4.07.0.cpp.gpl.zip \
    https://www.alglib.net/translator/re/alglib-4.07.0.cpp.gpl.zip
```

その後 `cmake ..` を再実行すると、キャッシュされたアーカイブから展開されます。

### コンパイルが失敗する

C++17 対応のコンパイラが利用可能であることを確認してください：

```bash
# macOS
xcode-select --install
c++ --version

# C++17 サポートの確認
c++ -std=c++17 -x c++ -E /dev/null
```

### ALGLIB を最初からリビルド

完全なリビルドを強制するには、インストールディレクトリとソースディレクトリを削除します：

```bash
rm -rf download/alglib-install download/alglib
cd build && cmake ..
```

### リンクエラー：ALGLIB 関数への未定義参照

`alglib_lib` が正しくリンクされていることを確認してください：

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE alglib_lib)
```

### ヘッダーが見つからない

インクルードディレクトリがインストール先を正しく指していることを確認してください：

```cmake
target_include_directories(${PROJECT_NAME} PRIVATE ${ALGLIB_INSTALL_DIR}/include)
```

ALGLIB ヘッダーは名前空間ディレクトリなしでインクルードします：

```cpp
#include "ap.h"           // OK
#include "linalg.h"       // OK
// #include <alglib/ap.h> // NG（このパスは存在しない）
```

---

## 参考資料

- [ALGLIB 公式サイト](https://www.alglib.net/)
- [ALGLIB ダウンロードページ](https://www.alglib.net/download.php)
- [ALGLIB ドキュメント](https://www.alglib.net/docs.php)
- [ALGLIB 補間](https://www.alglib.net/interpolation/)
- [ALGLIB 最適化](https://www.alglib.net/optimization/)
- [ALGLIB 線形代数](https://www.alglib.net/linearalgebra/)
- [CMake execute_process ドキュメント](https://cmake.org/cmake/help/latest/command/execute_process.html)
- [CMake file(DOWNLOAD) ドキュメント](https://cmake.org/cmake/help/latest/command/file.html#download)
