# LinqForCpp.cmake リファレンス

## 概要

`LinqForCpp.cmake` は、LinqForCpp ライブラリを自動的にダウンロードして設定する CMake 設定ファイルです。
CMake の `file(DOWNLOAD)` と `execute_process()` を使用して依存関係を管理し、`download/` ディレクトリにキャッシュすることで冗長なダウンロードを回避します。

LinqForCpp は、LINQ (Language Integrated Query) の C++ 実装であり、C# スタイルのクエリ機能を C++ にもたらします。`<<` 演算子を使ったフルーエント API により、フィルタリング、変換、ソート、集約などの操作を、任意のイテラブルコレクションに対してチェーンできます。

LinqForCpp はヘッダオンリーであるため、コンパイルやリンクは不要です。インクルードパスの設定のみが必要です。

## ファイル情報

| 項目 | 詳細 |
|------|------|
| インストールディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/LinqForCpp/LinqForCpp-install` |
| ダウンロード URL | https://github.com/harayuu9/LinqForCpp/releases/download/v1.0.1/LinqForCpp.zip |
| バージョン | 1.0.1 |
| ライセンス | MIT License |

---

## インクルードガード

```cmake
include_guard(GLOBAL)
```

このファイルは `include_guard(GLOBAL)` を使用し、複数回インクルードされても一度だけ実行されることを保証します。

**必要な理由:**

- 設定時に `file(DOWNLOAD)` の重複呼び出しを防止
- `target_include_directories` の重複呼び出しを防止

---

## ディレクトリ構造

```
LinqForCpp/
├── cmake/
│   ├── LinqForCpp.cmake          # この設定ファイル
│   ├── LinqForCppCmake.md        # ドキュメント（英語版）
│   └── LinqForCppCmake-jp.md     # このドキュメント（日本語版）
├── download/LinqForCpp/
│   ├── LinqForCpp.zip            # キャッシュされたダウンロード（zip アーカイブ）
│   └── LinqForCpp-install/       # インストール済みヘッダ
│       └── include/
│           ├── SingleHeader/
│           │   └── Linq.hpp      # シングルヘッダ版（約73KB）
│           └── Linq/
│               ├── Linq.h        # スプリットヘッダのエントリポイント
│               ├── Where.h
│               ├── Select.h
│               ├── OrderBy.h
│               └── ...           # その他の操作ヘッダ
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## 使い方

### CMakeLists.txt への追加

```cmake
include("./cmake/LinqForCpp.cmake")
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
set(LINQFORCPP_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/LinqForCpp)
set(LINQFORCPP_INSTALL_DIR ${LINQFORCPP_DOWNLOAD_DIR}/LinqForCpp-install)
set(LINQFORCPP_VERSION "1.0.1")
set(LINQFORCPP_URL "https://github.com/harayuu9/LinqForCpp/releases/download/v${LINQFORCPP_VERSION}/LinqForCpp.zip")
```

### 2. キャッシュチェックと条件付きダウンロード

```cmake
if(EXISTS ${LINQFORCPP_INSTALL_DIR}/include/SingleHeader/Linq.hpp)
    message(STATUS "LinqForCpp already installed")
else()
    # ダウンロードとインストール ...
endif()
```

キャッシュロジックは以下の通りです：

| 条件 | アクション |
|------|------------|
| `LinqForCpp-install/include/SingleHeader/Linq.hpp` が存在 | すべてスキップ（キャッシュを使用） |
| `download/LinqForCpp/LinqForCpp.zip` が存在（インストール未完了） | ダウンロードをスキップし、展開してインストール |
| 何も存在しない | GitHub からダウンロードし、展開してインストール |

### 3. ダウンロード（必要な場合）

```cmake
file(DOWNLOAD
    ${LINQFORCPP_URL}
    ${LINQFORCPP_CACHED}
    SHOW_PROGRESS
    STATUS DOWNLOAD_STATUS
)
```

- GitHub Releases から `LinqForCpp.zip` をダウンロード（約160KB）
- シングルヘッダ版とスプリットヘッダ版の両方を含む

### 4. 展開とインストール

```cmake
execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar xzf ${LINQFORCPP_CACHED}
    WORKING_DIRECTORY ${LINQFORCPP_INSTALL_DIR}/include
)
```

- zip アーカイブをインストールディレクトリに展開
- `SingleHeader/Linq.hpp` と `Linq/*.h` のディレクトリ構造を作成
- コンパイルステップは不要（ヘッダオンリーライブラリ）

### 5. インクルードパスの設定

```cmake
target_include_directories(${PROJECT_NAME} PRIVATE
    ${LINQFORCPP_INSTALL_DIR}/include
)
```

コンパイルが必要なライブラリとは異なり、LinqForCpp はヘッダオンリーです。`add_library`、`target_link_libraries`、静的ライブラリの作成は不要です。

---

## LinqForCpp ライブラリ

LinqForCpp は2つのインクルードオプションを提供します：

| ファイル | サイズ | 説明 |
|----------|--------|------|
| `SingleHeader/Linq.hpp` | 約73KB | シングルヘッダ版（オールインワン） |
| `Linq/Linq.h` | 約1.5KB | スプリットヘッダのエントリポイント（すべての操作ヘッダをインクルード） |

---

## LinqForCpp の主な特徴

| 特徴 | 説明 |
|------|------|
| フルーエント API | `<<` 演算子を使って操作をチェーン |
| 遅延評価 | ほとんどの操作は遅延実行 |
| C++17/C++20 | C++17以降が必要 |
| STL 互換 | `std::begin()`/`std::end()` をサポートするすべてのコレクションで動作 |
| マクロ構文 | `WHERE(v, cond)`、`SELECT(v, expr)` などの便利マクロ |
| カスタムアロケータ | 設定可能なアロケータによる内部メモリ管理 |

---

## 利用可能な操作

### フィルタリング

| 操作 | 説明 |
|------|------|
| `Where(func)` | 述語に一致する要素をフィルタリング |
| `Distinct()` | 重複要素を除去 |

### 変換

| 操作 | 説明 |
|------|------|
| `Select(func)` | 各要素を変換 |
| `SelectMany(func)` | 変換してネストされたコレクションを平坦化 |
| `Reverse()` | 要素の順序を反転 |
| `ZipWith(other)` | 2つのシーケンスをペアに結合 |
| `PairWise()` | 連続する要素のペアを作成 |

### ソート

| 操作 | 説明 |
|------|------|
| `OrderBy(func, isAscending)` | キーでソート（方向フラグ付き） |
| `OrderByAscending(func)` | キーで昇順ソート |
| `OrderByDescending(func)` | キーで降順ソート |
| `ThenBy(func, isAscending)` | 二次ソート（OrderBy の後） |

### 集約

| 操作 | 説明 |
|------|------|
| `Sum()` | 全要素の合計 |
| `Min()` | 最小要素 |
| `Max()` | 最大要素 |
| `MinMax()` | 最小値と最大値を `std::pair` で返す |
| `Avg<Result>()` | 平均値（結果型を指定） |
| `Count()` | 全要素を数える |
| `Count(func)` | 述語に一致する要素を数える |
| `Aggregate(init, func)` | アキュムレータによるフォールド/リデュース |

### 要素アクセス

| 操作 | 説明 |
|------|------|
| `First(func)` | 述語に一致する最初の要素（なければ例外） |
| `Last(func)` | 述語に一致する最後の要素（なければ例外） |
| `FirstOrDefault(func)` | 最初の一致要素またはデフォルト値 |
| `LastOrDefault(func)` | 最後の一致要素またはデフォルト値 |
| `Contains(value)` | シーケンスに値が含まれるか確認 |

### 数量詞

| 操作 | 説明 |
|------|------|
| `Any(func)` | いずれかの要素が一致すれば true |
| `All(func)` | すべての要素が一致すれば true |
| `SequenceEqual(other)` | 2つのシーケンスが等しければ true |

### パーティショニング

| 操作 | 説明 |
|------|------|
| `Take(n)` | 先頭 n 個の要素を取得 |
| `TakeWhile(func)` | 述語が true の間、要素を取得 |
| `Skip(n)` | 先頭 n 個の要素をスキップ |
| `SkipWhile(func)` | 述語が true の間、要素をスキップ |

### ジェネレータ

| 操作 | 説明 |
|------|------|
| `Range(start, count)` | 等差数列を生成 |
| `Repeat(value, count)` | 繰り返し値を生成 |
| `Singleton(value)` | 単一要素のシーケンス |
| `Empty<T>()` | 型 T の空シーケンス |

### マテリアライゼーション

| 操作 | 説明 |
|------|------|
| `ToVector()` | `std::vector` に変換 |
| `ToList()` | `std::list` に変換 |

---

## C/C++ での使用例

### Where と Select

```cpp
#include <SingleHeader/Linq.hpp>
#include <iostream>
#include <vector>

int main() {
    std::vector<int> numbers = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

    auto evens = numbers
        << linq::Where([](const int v) { return v % 2 == 0; })
        << linq::Select([](const int v) { return v * v; })
        << linq::ToVector();

    for (const auto& v : evens) {
        std::cout << v << " ";  // 4 16 36 64 100
    }
    return 0;
}
```

### OrderBy

```cpp
#include <SingleHeader/Linq.hpp>
#include <iostream>
#include <vector>
#include <string>

int main() {
    std::vector<std::string> words = {"banana", "apple", "cherry"};

    auto sorted = words
        << linq::OrderByAscending([](const std::string& s) { return s; })
        << linq::ToVector();

    for (const auto& w : sorted) {
        std::cout << w << " ";  // apple banana cherry
    }
    return 0;
}
```

### 集約

```cpp
#include <SingleHeader/Linq.hpp>
#include <iostream>
#include <vector>

int main() {
    std::vector<int> numbers = {3, 7, 1, 9, 4};

    auto sum = numbers << linq::Sum();
    auto avg = numbers << linq::Avg<double>();
    auto [min, max] = numbers << linq::MinMax();

    std::cout << "Sum: " << sum << "\n";  // 24
    std::cout << "Avg: " << avg << "\n";  // 4.8
    std::cout << "Min: " << min << ", Max: " << max << "\n";  // 1, 9

    return 0;
}
```

### Take、Skip、ページネーション

```cpp
#include <SingleHeader/Linq.hpp>
#include <iostream>
#include <vector>

int main() {
    std::vector<int> numbers = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

    // ページ2（4~6番目の要素）
    auto page = numbers
        << linq::Skip(3)
        << linq::Take(3)
        << linq::ToVector();

    for (const auto& v : page) {
        std::cout << v << " ";  // 4 5 6
    }
    return 0;
}
```

### Range と FizzBuzz

```cpp
#include <SingleHeader/Linq.hpp>
#include <iostream>
#include <string>

int main() {
    auto fizzbuzz = linq::Range(1, 15)
        << linq::Select([](const int v) -> std::string {
            if (v % 15 == 0) return "FizzBuzz";
            if (v % 3 == 0)  return "Fizz";
            if (v % 5 == 0)  return "Buzz";
            return std::to_string(v);
        })
        << linq::ToVector();

    for (const auto& s : fizzbuzz) {
        std::cout << s << " ";
    }
    return 0;
}
```

### マクロの使用

```cpp
#include <SingleHeader/Linq.hpp>
#include <iostream>
#include <vector>
#include <string>

int main() {
    std::vector<int> numbers = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

    // マクロ構文（ラムダの代替）
    auto result = numbers
        << WHERE(v, v > 5)
        << SELECT(v, std::to_string(v))
        << linq::ToVector();

    for (const auto& s : result) {
        std::cout << s << " ";  // 6 7 8 9 10
    }
    return 0;
}
```

### ZipWith

```cpp
#include <SingleHeader/Linq.hpp>
#include <iostream>
#include <vector>
#include <string>

int main() {
    std::vector<std::string> names = {"Alice", "Bob", "Charlie"};
    std::vector<int> scores = {95, 87, 92};

    auto zipped = names
        << linq::ZipWith(scores)
        << linq::ToVector();

    for (const auto& [name, score] : zipped) {
        std::cout << name << ": " << score << "\n";
    }
    return 0;
}
```

---

## LinqForCpp API 規約

### 名前空間

すべての機能は `linq` 名前空間にあります：

```cpp
#include <SingleHeader/Linq.hpp>

// linq:: プレフィックスで操作を使用
auto result = arr << linq::Where([](auto v) { return v > 0; });
```

### `<<` 演算子

`<<` 演算子は LinqForCpp のコアです。コレクションをビルダーオブジェクトに渡します：

```cpp
auto result = collection << linq::Operation(args);
```

操作はチェーンできます：

```cpp
auto result = collection
    << linq::Where(predicate)
    << linq::Select(transform)
    << linq::OrderByAscending(keySelector)
    << linq::ToVector();
```

### 実行モデル

| タイプ | 実行 | 例 |
|--------|------|-----|
| 遅延 | イテレーション時まで遅延 | Where, Select, Take, Skip, Reverse, ZipWith, PairWise |
| 即時 | 即座に実行 | Sum, Min, Max, Count, Avg, Aggregate, Contains, Any, All, OrderBy, Distinct, First, Last, ToVector, ToList |

### マクロ代替

| マクロ | 等価 |
|--------|------|
| `WHERE(v, cond)` | `linq::Where([&](const auto& v) { return cond; })` |
| `SELECT(v, expr)` | `linq::Select([&](const auto& v) { return expr; })` |
| `SELECT_MANY(v, expr)` | `linq::SelectMany([&](const auto& v) { return expr; })` |
| `ORDER_BY(v, key, asc)` | `linq::OrderBy([&](const auto& v) { return key; }, asc)` |
| `ORDER_BY_ASCENDING(v, key)` | `linq::OrderByAscending([&](const auto& v) { return key; })` |
| `ORDER_BY_DESCENDING(v, key)` | `linq::OrderByDescending([&](const auto& v) { return key; })` |
| `COUNT(v, cond)` | `linq::Count([&](const auto& v) { return cond; })` |
| `ANY(v, cond)` | `linq::Any([&](const auto& v) { return cond; })` |
| `ALL(v, cond)` | `linq::All([&](const auto& v) { return cond; })` |
| `FIRST(v, cond)` | `linq::First([&](const auto& v) { return cond; })` |
| `LAST(v, cond)` | `linq::Last([&](const auto& v) { return cond; })` |
| `FIRST_OR_DEFAULT(v, cond)` | `linq::FirstOrDefault([&](const auto& v) { return cond; })` |
| `LAST_OR_DEFAULT(v, cond)` | `linq::LastOrDefault([&](const auto& v) { return cond; })` |
| `AGGREGATE(init, a, b, expr)` | `linq::Aggregate(init, [&](const auto& a, const auto& b) { return expr; })` |

---

## 比較: LinqForCpp vs 他の C++ クエリライブラリ

| 特徴 | LinqForCpp | ranges (C++20) | Boost.Range | cpplinq |
|------|-----------|----------------|-------------|---------|
| ライセンス | MIT | 標準ライブラリ | BSL 1.0 | MIT |
| C++ 標準 | C++17+ | C++20+ | C++11+ | C++11+ |
| ヘッダオンリー | はい | はい（stdlib） | いいえ | はい |
| 演算子スタイル | `<<` | `\|` | `\|` | `>>` |
| 遅延評価 | ほとんどの操作 | すべてのビュー | すべてのアダプタ | ほとんどの操作 |
| C# LINQ との類似性 | 高い | 低い | 低い | 高い |
| STL 互換 | はい | はい | はい | 限定的 |
| 集約 | はい | 限定的 | 限定的 | はい |
| カスタムアロケータ | はい | いいえ | いいえ | いいえ |

---

## トラブルシューティング

### ダウンロードに失敗する場合

GitHub にアクセスできない場合、手動でアーカイブをダウンロードして配置できます：

```bash
curl -L -o download/LinqForCpp/LinqForCpp.zip \
    https://github.com/harayuu9/LinqForCpp/releases/download/v1.0.1/LinqForCpp.zip
```

その後 `cmake ..` を再実行すると、キャッシュされたファイルからインストールが進行します。

### ゼロからリビルドする場合

ダウンロードとインストールを完全にやり直すには：

```bash
rm -rf download/LinqForCpp/LinqForCpp-install download/LinqForCpp/LinqForCpp.zip
cd build && cmake ..
```

### ヘッダが見つからない場合

インクルードディレクトリが正しく設定されていることを確認してください：

```cmake
target_include_directories(${PROJECT_NAME} PRIVATE ${LINQFORCPP_INSTALL_DIR}/include)
```

ヘッダは以下のようにインクルードしてください：

```cpp
#include <SingleHeader/Linq.hpp>   // シングルヘッダ版
// または
#include <Linq/Linq.h>            // スプリットヘッダ版
```

### C++14 以前でのコンパイルエラー

LinqForCpp は C++17 以降を必要とします。CMakeLists.txt で少なくとも C++17 を指定してください：

```cmake
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_17)
```

---

## 参考文献

- [LinqForCpp GitHub リポジトリ](https://github.com/harayuu9/LinqForCpp)
- [LinqForCpp リリース](https://github.com/harayuu9/LinqForCpp/releases)
- [LINQ ドキュメント (C#)](https://learn.microsoft.com/ja-jp/dotnet/csharp/linq/)
- [CMake file(DOWNLOAD) ドキュメント](https://cmake.org/cmake/help/latest/command/file.html#download)
- [CMake execute_process ドキュメント](https://cmake.org/cmake/help/latest/command/execute_process.html)
