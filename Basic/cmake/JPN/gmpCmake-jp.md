# gmp.cmake リファレンス

## 概要

`gmp.cmake` は GMP ライブラリの自動ダウンロード、ビルド、リンクを行う CMake 設定ファイルです。
CMake の `file(DOWNLOAD)` と `execute_process` を使用して依存関係を管理し、`download/` ディレクトリにキャッシュすることで冗長なダウンロードとリビルドを回避します。

GMP（GNU Multiple Precision Arithmetic Library）は任意精度演算のためのフリーライブラリで、符号付き整数（`mpz`）、有理数（`mpq`）、浮動小数点数（`mpf`）を扱います。
C++ ラッパー（`gmpxx.h`）は演算子オーバーロードと `mpz_class`、`mpq_class`、`mpf_class` などの便利なクラスを提供します。

## ファイル情報

| 項目 | 詳細 |
|------|------|
| ソースディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/gmp` |
| インストールディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/gmp-install` |
| ダウンロード URL | https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz |
| バージョン | 6.3.0 |
| ライセンス | GNU LGPL v3 / GNU GPL v2（デュアルライセンス） |

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
GMP/
├── cmake/
│   ├── gmp.cmake          # この設定ファイル
│   └── gmpCmake.md        # このドキュメント
├── download/
│   ├── gmp/               # GMP ソース（キャッシュ、ftp.gnu.org からダウンロード）
│   └── gmp-install/       # GMP ビルド成果物（lib/, include/）
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

## 使い方

### CMakeLists.txt への追加

```cmake
# gmp.cmake が存在する場合に自動インクルード
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/gmp.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/gmp.cmake)
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
set(GMP_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(GMP_SOURCE_DIR ${GMP_DOWNLOAD_DIR}/gmp)
set(GMP_INSTALL_DIR ${GMP_DOWNLOAD_DIR}/gmp-install)
set(GMP_VERSION "6.3.0")
set(GMP_URL "https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.xz")
```

### 2. キャッシュチェックと条件付きビルド

```cmake
if(EXISTS ${GMP_INSTALL_DIR}/lib/libgmp.a AND EXISTS ${GMP_INSTALL_DIR}/lib/libgmpxx.a)
    message(STATUS "GMP already built: ${GMP_INSTALL_DIR}/lib/libgmp.a")
else()
    # ダウンロード、設定、ビルド、インストール ...
endif()
```

キャッシュのロジックは以下の通りです：

| 条件 | アクション |
|------|----------|
| `gmp-install/lib/libgmp.a` が存在 | すべてスキップ（キャッシュされたビルドを使用） |
| `gmp/configure` が存在（インストールなし） | ダウンロードをスキップ、configure/make/install を実行 |
| 何も存在しない | ダウンロード、展開、configure、make、install |

### 3. ダウンロード（必要な場合）

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

- `ftp.gnu.org`（GNU 公式ミラー）からダウンロード
- `gmp-6.3.0/` を `gmp/` にリネーム（クリーンなパスのため）

### 4. 設定、ビルド、インストール

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

- `--enable-cxx`：C++ インターフェース（`libgmpxx`）をビルド
- `--disable-shared --enable-static`：静的ライブラリのみビルド
- `--with-pic`：位置独立コードを生成
- すべてのステップは CMake configure 時（ビルド時ではなく）に実行

### 5. ライブラリのリンク

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

注意：リンカーの依存関係の順序を満たすため、`gmpxx_lib` を `gmp_lib` の前に記述する必要があります。

---

## GMP の主な機能

| 機能 | 説明 |
|------|------|
| 整数演算（`mpz`） | 任意精度の符号付き整数 |
| 有理数演算（`mpq`） | 正確な分数（分子/分母） |
| 浮動小数点演算（`mpf`） | 任意精度の浮動小数点数 |
| C++ ラッパー（`gmpxx.h`） | `mpz_class`、`mpq_class`、`mpf_class` による演算子オーバーロード |
| 整数論関数 | GCD、LCM、素数判定、ヤコビ記号など |
| I/O サポート | C++ クラスのストリーム演算子（`<<`、`>>`） |
| 高性能 | 多くのプラットフォーム（x86、ARM など）向けにアセンブリ最適化 |

---

## C++ での使用例

### 基本的な演算

```cpp
#include <gmpxx.h>
#include <iostream>

int main() {
    mpz_class a, b, c;

    a = 1234;
    b = "-5678";
    c = a + b;

    std::cout << a << " と " << b << " の合計は " << c << "\n";
    std::cout << "絶対値は " << abs(c) << "\n";

    return 0;
}
```

### フィボナッチ数列（反復法）

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
    // 非常に大きなフィボナッチ数も簡単に計算可能
    std::cout << "fib(100) = " << fib(100) << std::endl;
    std::cout << "fib(1000) = " << fib(1000) << std::endl;
    return 0;
}
```

### 階乗

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

### 有理数

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

### 任意精度浮動小数点

```cpp
#include <gmpxx.h>
#include <iostream>

int main() {
    // 精度を 256 ビットに設定
    mpf_class pi("3.14159265358979323846264338327950288", 256);
    mpf_class r("2.5", 256);

    mpf_class area = pi * r * r;
    std::cout << "半径 2.5 の円の面積: " << area << std::endl;

    return 0;
}
```

### 素数判定（C API）

```cpp
#include <gmpxx.h>
#include <iostream>

int main() {
    mpz_class n("170141183460469231731687303715884105727");  // 2^127 - 1 (メルセンヌ素数)

    // mpz_probab_prime_p の戻り値: 2 = 確定的に素数、1 = おそらく素数、0 = 合成数
    int result = mpz_probab_prime_p(n.get_mpz_t(), 25);

    if (result >= 1) {
        std::cout << n << " は素数です" << std::endl;
    } else {
        std::cout << n << " は合成数です" << std::endl;
    }

    return 0;
}
```

---

## C++ クラスの概要

### mpz_class（整数）

| 操作 | 例 |
|------|-----|
| 代入 | `mpz_class a = 42;` または `a = "123456789";` |
| 演算 | `a + b`, `a - b`, `a * b`, `a / b`, `a % b` |
| 比較 | `a == b`, `a != b`, `a < b`, `a > b` |
| 絶対値 | `abs(a)` |
| 冪乗 | `mpz_class r; mpz_pow_ui(r.get_mpz_t(), a.get_mpz_t(), exp);` |
| GCD | `mpz_class g; mpz_gcd(g.get_mpz_t(), a.get_mpz_t(), b.get_mpz_t());` |
| 文字列変換 | `a.get_str()` |
| スワップ | `swap(a, b)` |

### mpq_class（有理数）

| 操作 | 例 |
|------|-----|
| 代入 | `mpq_class a(1, 3);`（1/3） |
| 演算 | `a + b`, `a - b`, `a * b`, `a / b` |
| 正規化 | `a.canonicalize();` |
| 分子の取得 | `a.get_num()` |
| 分母の取得 | `a.get_den()` |

### mpf_class（浮動小数点）

| 操作 | 例 |
|------|-----|
| 代入 | `mpf_class a("3.14", 256);`（256 ビット精度） |
| 演算 | `a + b`, `a - b`, `a * b`, `a / b` |
| 平方根 | `mpf_class r; mpf_sqrt(r.get_mpf_t(), a.get_mpf_t());` |
| 精度設定 | `mpf_set_default_prec(1024);` |

---

## 組み込み型との比較

| 機能 | `long long` | `__int128` | `mpz_class`（GMP） |
|------|------------|-----------|-------------------|
| 最大桁数 | 約 19 | 約 38 | 無制限 |
| 速度 | 最速 | 高速 | 低速（だが最適化済み） |
| 演算子オーバーロード | 組み込み | 部分的 | 完全（C++） |
| 正確な演算 | あり | あり | あり |
| プラットフォームサポート | 全て | GCC/Clang | 全て |

---

## トラブルシューティング

### ダウンロードが失敗する

`ftp.gnu.org` に接続できない場合、手動でダウンロードして配置できます：

```bash
curl -L -o download/gmp-6.3.0.tar.xz https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz
```

その後 `cmake ..` を再実行すると、キャッシュされた tarball から展開されます。

### 設定が失敗する

autotools の前提条件が利用可能であることを確認してください：

```bash
# macOS（Xcode Command Line Tools）
xcode-select --install

# m4 が利用可能であることを確認（GMP configure に必要）
m4 --version
```

### GMP を最初からリビルド

完全なリビルドを強制するには、インストールディレクトリとソースディレクトリを削除します：

```bash
rm -rf download/gmp-install download/gmp
cd build && cmake ..
```

### リンクエラー：gmpxx が見つからない

configure 時に `--enable-cxx` が渡されていることを確認してください。C++ ラッパー `libgmpxx.a` はこのオプションが有効な場合にのみビルドされます。

### `__gmpz_init` 等への未定義参照

`gmpxx_lib` が `gmp_lib` より前にリンクされていることを確認してください。リンカーはライブラリを左から右に処理し、`libgmpxx.a` は `libgmp.a` に依存します。

---

## 参考資料

- [GMP 公式サイト](https://gmplib.org/)
- [GMP マニュアル](https://gmplib.org/manual/)
- [GMP C++ クラスインターフェース](https://gmplib.org/manual/C_002b_002b-Class-Interface)
- [GNU FTP ミラー](https://ftp.gnu.org/gnu/gmp/)
- [CMake execute_process ドキュメント](https://cmake.org/cmake/help/latest/command/execute_process.html)
- [CMake file(DOWNLOAD) ドキュメント](https://cmake.org/cmake/help/latest/command/file.html#download)
