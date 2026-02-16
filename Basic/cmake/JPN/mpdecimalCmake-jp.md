# mpdecimal.cmake リファレンス

## 概要

`mpdecimal.cmake` は、mpdecimalライブラリのダウンロード、ビルド、リンクを自動的に行うCMake設定ファイルです。
CMakeの `file(DOWNLOAD)` と `execute_process` を使用して依存関係を管理し、`download/` ディレクトリにキャッシュすることで、不要なダウンロードやリビルドを回避します。

mpdecimalは、正確に丸められた任意精度の10進浮動小数点演算パッケージです。General Decimal Arithmetic Specification（IEEE 754-2008）を実装しており、Pythonの `decimal` モジュールの基盤となっているライブラリです。

mpdecimalは2つのライブラリを提供します:
- **libmpdec**（C API）: `mpdecimal.h` による低レベルの10進演算
- **libmpdec++**（C++ API）: `decimal.hh` による高レベルのC++ラッパー

## ファイル情報

| 項目 | 詳細 |
|------|------|
| ソースディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/mpdecimal` |
| インストールディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/mpdecimal/mpdecimal-install` |
| ダウンロードURL | https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-4.0.1.tar.gz |
| バージョン | 4.0.1 |
| ライセンス | Simplified BSD License |

---

## インクルードガード

```cmake
include_guard(GLOBAL)
```

このファイルは `include_guard(GLOBAL)` を使用して、複数回インクルードされた場合でも一度だけ実行されることを保証します。

**必要な理由:**

- configure時の `execute_process` の重複実行を防止
- `target_link_libraries` の重複リンクを防止

---

## ディレクトリ構成

```
mpdecimal/
├── cmake/
│   ├── mpdecimal.cmake        # この設定ファイル
│   ├── mpdecimalCmake.md      # 英語版ドキュメント
│   └── mpdecimalCmake-jp.md   # このドキュメント（日本語）
├── download/mpdecimal
│   ├── mpdecimal/             # mpdecimalソース（キャッシュ、bytereef.orgからダウンロード）
│   └── mpdecimal-install/     # mpdecimalビルド成果物（lib/、include/）
│       ├── include/
│       │   ├── mpdecimal.h    # C APIヘッダー
│       │   └── decimal.hh     # C++ APIヘッダー
│       └── lib/
│           ├── libmpdec.a     # Cライブラリ（静的）
│           └── libmpdec++.a   # C++ライブラリ（静的）
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## 使い方

### CMakeLists.txtへの追加

```cmake
# mpdecimal.cmakeが存在する場合に自動インクルード
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/mpdecimal.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/mpdecimal.cmake)
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
set(MPDECIMAL_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/mpdecimal)
set(MPDECIMAL_SOURCE_DIR ${MPDECIMAL_DOWNLOAD_DIR}/mpdecimal)
set(MPDECIMAL_INSTALL_DIR ${MPDECIMAL_DOWNLOAD_DIR}/mpdecimal-install)
set(MPDECIMAL_VERSION "4.0.1")
set(MPDECIMAL_URL "https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-${MPDECIMAL_VERSION}.tar.gz")
```

### 2. キャッシュチェックと条件付きビルド

```cmake
if(EXISTS ${MPDECIMAL_INSTALL_DIR}/lib/libmpdec.a AND EXISTS ${MPDECIMAL_INSTALL_DIR}/lib/libmpdec++.a)
    message(STATUS "mpdecimal already built: ${MPDECIMAL_INSTALL_DIR}/lib/libmpdec.a")
else()
    # ダウンロード、configure、ビルド、インストール ...
endif()
```

キャッシュロジックは以下の通りです:

| 条件 | アクション |
|------|-----------|
| `mpdecimal-install/lib/libmpdec.a` が存在する | すべてスキップ（キャッシュされたビルドを使用） |
| `mpdecimal/configure` が存在する（インストールなし） | ダウンロードをスキップし、configure/make/installを実行 |
| 何も存在しない | ダウンロード、展開、configure、make、install |

### 3. ダウンロード（必要な場合）

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

- `bytereef.org`（公式サイト）からダウンロード
- 展開後、`mpdecimal-4.0.1/` を `mpdecimal/` にリネームしてパスをクリーンに

### 4. Configure、ビルド、インストール

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

- `--disable-shared --enable-static`: 静的ライブラリのみビルド
- `--enable-pc`: pkg-configファイルをインストール
- すべてのステップはCMakeのconfigure時に実行（ビルド時ではない）
- デフォルトでlibmpdec（C）とlibmpdec++（C++）の両方がビルドされる

### 5. ライブラリのリンク

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

注意: リンカの依存関係順序を満たすため、`mpdecpp_lib`（libmpdec++）は `mpdec_lib`（libmpdec）の前にリストする必要があります。`m`（libm）は数学関数に必要です。

---

## mpdecimalライブラリ

mpdecimalは2つのライブラリで構成されています:

| ライブラリ | ファイル | ヘッダー | 説明 |
|-----------|---------|---------|------|
| `libmpdec` | `libmpdec.a` | `mpdecimal.h` | General Decimal Arithmetic Specificationを実装するCライブラリ |
| `libmpdec++` | `libmpdec++.a` | `decimal.hh` | 演算子オーバーロード付きの `decimal::Decimal` クラスを提供するC++ラッパー |

`libmpdec++` は `libmpdec` に依存しています。C++ APIを使用する場合、両方のライブラリをリンクする必要があります。

---

## mpdecimalの主要機能

| 機能 | C API | C++ API | 説明 |
|------|-------|---------|------|
| 任意精度 | `mpd_qsetprec()` | `decimal::context.prec()` | 1桁から数十億桁まで精度を設定可能 |
| 基本演算 | `mpd_qadd/sub/mul/div` | `+`, `-`, `*`, `/` 演算子 | 加算、減算、乗算、除算 |
| 比較 | `mpd_qcompare()` | `==`, `<`, `>` 演算子 | 10進値の数値比較 |
| 平方根 | `mpd_qsqrt()` | `.sqrt()` | 正確に丸められた平方根 |
| 指数関数 | `mpd_qexp()` | `.exp()` | 正確に丸められた指数関数（e^x） |
| 自然対数 | `mpd_qln()` | `.ln()` | 正確に丸められた自然対数 |
| 常用対数 | `mpd_qlog10()` | `.log10()` | 正確に丸められた常用対数 |
| 累乗 | `mpd_qpow()` | `.pow()` | 正確に丸められた累乗 |
| 丸めモード | `mpd_qsetround()` | `decimal::context.round()` | IEEE 754の9つの丸めモード |
| 量子化 | `mpd_qquantize()` | `.quantize()` | 小数点以下の桁数を設定 |
| 整数除算 | `mpd_qdivint()` | `.divint()` | 除算の整数部分 |
| 剰余 | `mpd_qrem()` | `.rem()` | 除算の剰余 |
| べき乗剰余 | `mpd_qpowmod()` | N/A | (base^exp) mod m |
| 絶対値 | `mpd_qabs()` | `.abs()` | 絶対値 |
| 正規化 | `mpd_qreduce()` | `.reduce()` | 末尾のゼロを除去 |
| 文字列変換 | `mpd_to_sci/eng()` | `.format()` | 科学表記、工学表記、カスタムフォーマット |
| 整数変換 | `mpd_qset_i64/u64()` | コンストラクタ | 64ビット整数との変換 |
| 特殊値 | `mpd_setspecial()` | `Decimal("NaN")` | Infinity、-Infinity、NaN、sNaN |
| FMA | `mpd_qfma()` | `.fma()` | 積和演算（Fused Multiply-Add） |
| IEEE 754-2008 | 完全準拠 | 完全準拠 | 規格の完全な実装 |

### 注意: 負の数の剰余演算

mpdecimalの `rem` 演算は、商をゼロ方向に切り捨てます（C/C++の `%` と同じ）。Pythonの `%`（負の無限大方向に切り捨て）とは**異なります**。

| 式 | divint | rem | 説明 |
| --- | --- | --- | --- |
| `-5 % 3` | `-1` | `-2` | `-5 = 3 * (-1) + (-2)` |
| `5 % -3` | `-1` | `2` | `5 = (-3) * (-1) + 2` |
| `-5 % -3` | `1` | `-2` | `-5 = (-3) * 1 + (-2)` |
| `17 % 5` | `3` | `2` | `17 = 5 * 3 + 2` |

剰余の符号は常に被除数（左オペランド）の符号と一致します。これはIEEE 754の剰余定義に従っており、除数が正の場合に常に非負の結果を返すPythonのモジュロ演算子とは異なります。

```cpp
decimal::Decimal a("-5");
decimal::Decimal b("3");
std::cout << a.divint(b).format("f") << "\n";  // -1
std::cout << a.rem(b).format("f") << "\n";     // -2
```

---

## 丸めモード

mpdecimalはIEEE 754で定義された9つの丸めモードをサポートしています:

| 定数 | 説明 | 例（2.25 -> 小数1桁） |
|------|------|----------------------|
| `MPD_ROUND_HALF_UP` | 0.5を切り上げ（ゼロから離れる方向） | 2.3 |
| `MPD_ROUND_HALF_DOWN` | 0.5を切り捨て（ゼロに近づく方向） | 2.2 |
| `MPD_ROUND_HALF_EVEN` | 0.5を最も近い偶数に丸め（銀行家の丸め） | 2.2 |
| `MPD_ROUND_UP` | ゼロから離れる方向に丸め | 2.3 |
| `MPD_ROUND_DOWN` | ゼロに近づく方向に丸め（切り捨て） | 2.2 |
| `MPD_ROUND_CEILING` | +無限大方向に丸め | 2.3 |
| `MPD_ROUND_FLOOR` | -無限大方向に丸め | 2.2 |
| `MPD_ROUND_05UP` | ゼロまたは5をゼロから離れる方向に丸め | 2.2 |
| `MPD_ROUND_TRUNC` | 切り捨て（無限大は設定） | 2.2 |

---

## C++での使用例

### 基本演算（C++ API）

```cpp
#include <decimal.hh>
#include <iostream>

int main() {
    decimal::Decimal a("0.1");
    decimal::Decimal b("0.2");
    decimal::Decimal c = a + b;

    // IEEE 754バイナリ浮動小数点とは異なり、正確に0.3を出力
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

### 精度制御

```cpp
#include <decimal.hh>
#include <iostream>

int main() {
    decimal::context.prec(50);
    decimal::Decimal result = decimal::Decimal("1").div(decimal::Decimal("3"));
    std::cout << "1/3 (50桁): " << result.format("f") << "\n";

    decimal::context.prec(10);
    result = decimal::Decimal("1").div(decimal::Decimal("3"));
    std::cout << "1/3 (10桁): " << result.format("f") << "\n";

    return 0;
}
```

### 丸めと量子化

```cpp
#include <decimal.hh>
#include <iostream>

int main() {
    decimal::Decimal price("19.99");
    decimal::Decimal tax("0.08");
    decimal::Decimal total = price * (decimal::Decimal("1") + tax);
    decimal::Decimal cent("0.01");

    decimal::context.round(MPD_ROUND_HALF_UP);
    std::cout << "合計: " << total.quantize(cent).format("f") << "\n";

    return 0;
}
```

### 数学関数

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

### C API: 低レベルの使用方法

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

### 文字列フォーマット

```cpp
#include <decimal.hh>
#include <mpdecimal.h>
#include <iostream>

int main() {
    decimal::Decimal pi("3.14159265358979323846");

    std::cout << "デフォルト : " << pi.format("f") << "\n";
    std::cout << ".6f       : " << pi.format(".6f") << "\n";
    std::cout << ".2f       : " << pi.format(".2f") << "\n";
    std::cout << "E         : " << pi.format("E") << "\n";

    // C API: 科学表記と工学表記
    mpd_context_t ctx;
    mpd_defaultcontext(&ctx);
    mpd_t *val = mpd_new(&ctx);
    uint32_t status = 0;
    mpd_qset_string(val, "12345.6789", &ctx, &status);

    char *sci = mpd_to_sci(val, 1);
    char *eng = mpd_to_eng(val, 1);
    printf("科学表記  : %s\n", sci);
    printf("工学表記  : %s\n", eng);

    mpd_free(sci);
    mpd_free(eng);
    mpd_del(val);
    return 0;
}
```

---

## C APIの規約

### コンテキスト管理

すべてのC API操作には、精度、丸め、エラー処理を制御する `mpd_context_t` が必要です:

```c
mpd_context_t ctx;
mpd_defaultcontext(&ctx);      // 精度 = 2*MPD_RDIGITS、ROUND_HALF_EVEN
mpd_maxcontext(&ctx);          // 最大精度
mpd_basiccontext(&ctx);        // 精度 = 9
mpd_init(&ctx, 50);            // カスタム精度50
```

### メモリ管理

mpdecimalは `mpd_new` / `mpd_del` パターンでメモリを管理します:

```c
mpd_t *dec = mpd_new(&ctx);
// ... 使用 ...
mpd_del(dec);
```

`mpd_to_sci()` や `mpd_to_eng()` などが返す文字列には `mpd_free()` を使用します:

```c
char *s = mpd_to_sci(dec, 1);
// ... 使用 ...
mpd_free(s);
```

### エラー処理

「quiet」APIの関数（`mpd_q*`）は、明示的な `uint32_t *status` パラメータを使用します:

```c
uint32_t status = 0;
mpd_qadd(result, a, b, &ctx, &status);
if (status & MPD_Errors) {
    // エラー処理
}
```

非quiet版（`mpd_add` など）は、コンテキストのトラップメカニズムを通じてシグナルを発生させます。

---

## 比較: mpdecimal vs 他のライブラリ

| 機能 | mpdecimal | GMP | Boost.Multiprecision | double |
|------|-----------|-----|----------------------|--------|
| 基数 | 10進数 | 2進数 | 設定可能 | 2進数 |
| IEEE 754-2008 | 完全準拠 | 非対応 | 部分的 | 部分的 |
| 正確な0.1+0.2 | はい | いいえ | バックエンドによる | いいえ |
| 丸めモード | 9モード | 限定的 | 限定的 | 4モード |
| 金融計算 | 優秀 | 不向き | 良好 | 不向き |
| パフォーマンス | 非常に高速 | 最速 | 高速 | 最速 |
| 精度 | 任意精度 | 任意精度 | 任意精度 | 15-17桁 |
| ライセンス | BSD | LGPL | Boost | N/A |

mpdecimalは、正確な10進表現が重要な金融・通貨計算に優れています。2進表現が許容される純粋な数学計算では、GMPやハードウェア浮動小数点の方が高速な場合があります。

---

## トラブルシューティング

### ダウンロード失敗

`bytereef.org` に到達できない場合、手動でtarballをダウンロードして配置できます:

```bash
curl -L -o download/mpdecimal/mpdecimal-4.0.1.tar.gz \
    https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-4.0.1.tar.gz
```

その後 `cmake ..` を再実行すると、キャッシュされたtarballから展開が進みます。

### Configure失敗

ビルドの前提条件が利用可能であることを確認してください:

```bash
# macOS（Xcode Command Line Tools）
xcode-select --install

# makeが利用可能か確認
make --version
```

### mpdecimalを最初からリビルド

完全なリビルドを強制するには、インストールディレクトリとソースディレクトリを削除します:

```bash
rm -rf download/mpdecimal/mpdecimal-install download/mpdecimal/mpdecimal
cd build && cmake ..
```

### リンクエラー: `mpd_*` への未定義参照

`mpdecpp_lib` と `mpdec_lib` の両方が正しい順序（C++がCの前）でリンクされていることを確認してください:

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE mpdecpp_lib mpdec_lib m)
```

### リンクエラー: C++シンボルへの未定義参照

C++ API（`decimal.hh`）を使用する場合、C++コンパイラ（Cコンパイラではない）でコンパイルし、`libmpdec++.a` を `libmpdec.a` の前にリンクしていることを確認してください。

### C++ライブラリを無効にする

C APIのみが必要な場合、configureオプションに `--disable-cxx` を追加します:

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

その後、`libmpdec.a` のみをリンクします:

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE mpdec_lib m)
```

---

## 参考文献

- [mpdecimal公式サイト](https://www.bytereef.org/mpdecimal/)
- [mpdecimalダウンロードページ](https://www.bytereef.org/mpdecimal/download.html)
- [mpdecimalクイックスタートガイド](https://www.bytereef.org/mpdecimal/quickstart.html)
- [libmpdec APIドキュメント](https://www.bytereef.org/mpdecimal/doc/libmpdec/index.html)
- [libmpdec++ APIドキュメント](https://www.bytereef.org/mpdecimal/doc/libmpdec++/index.html)
- [General Decimal Arithmetic Specification](https://speleotrove.com/decimal/decarith.html)
- [IEEE 754-2008規格](https://en.wikipedia.org/wiki/IEEE_754)
- [CMake execute_processドキュメント](https://cmake.org/cmake/help/latest/command/execute_process.html)
- [CMake file(DOWNLOAD)ドキュメント](https://cmake.org/cmake/help/latest/command/file.html#download)
