# nlohmann-json.cmake リファレンス

## 概要

`nlohmann-json.cmake` は nlohmann/json ライブラリの自動ダウンロードと設定を行う CMake 設定ファイルです。
CMake の `file(DOWNLOAD)` を使用して依存関係を管理し、`download/` ディレクトリにキャッシュすることで冗長なダウンロードを回避します。

nlohmann/json はモダンなヘッダーオンリー C++ JSON ライブラリです。Python 辞書に似た直感的な構文、完全な STL 統合、シリアライズ/デシリアライズ、包括的な型安全性を提供します。

nlohmann/json はヘッダーオンリーであるため、コンパイルやリンクは不要です。インクルードパスの設定のみが必要です。

## ファイル情報

| 項目 | 詳細 |
|------|------|
| インストールディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/nlohmann-json-install` |
| ダウンロード URL | https://github.com/nlohmann/json/releases/download/v3.12.0/json.hpp |
| バージョン | 3.12.0 |
| ライセンス | MIT License |

---

## インクルードガード

```cmake
include_guard(GLOBAL)
```

このファイルは `include_guard(GLOBAL)` を使用して、複数回インクルードされても一度だけ実行されるようにしています。

**必要な理由：**

- configure 時の `file(DOWNLOAD)` の重複呼び出しを防止
- `target_include_directories` の重複呼び出しを防止

---

## ディレクトリ構造

```
nlohmann-json/
├── cmake/
│   ├── nlohmann-json.cmake    # この設定ファイル
│   └── nlohmann-jsonCmake.md  # このドキュメント
├── download/nlohmann-json
│   ├── json.hpp               # キャッシュされたダウンロード（単一ヘッダーファイル）
│   └── nlohmann-json-install/ # インストールされたヘッダー
│       └── include/
│           └── nlohmann/
│               └── json.hpp   # プロジェクトが使用するヘッダー
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## 使い方

### CMakeLists.txt への追加

```cmake
include("./cmake/nlohmann-json.cmake")
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
set(NLOHMANN_JSON_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(NLOHMANN_JSON_INSTALL_DIR ${NLOHMANN_JSON_DOWNLOAD_DIR}/nlohmann-json-install)
set(NLOHMANN_JSON_VERSION "3.12.0")
set(NLOHMANN_JSON_URL "https://github.com/nlohmann/json/releases/download/v${NLOHMANN_JSON_VERSION}/json.hpp")
```

### 2. キャッシュチェックと条件付きダウンロード

```cmake
if(EXISTS ${NLOHMANN_JSON_INSTALL_DIR}/include/nlohmann/json.hpp)
    message(STATUS "nlohmann-json already installed")
else()
    # ダウンロードとインストール ...
endif()
```

キャッシュのロジックは以下の通りです：

| 条件 | アクション |
|------|----------|
| `nlohmann-json-install/include/nlohmann/json.hpp` が存在 | すべてスキップ（キャッシュを使用） |
| `download/json.hpp` が存在（インストールなし） | ダウンロードをスキップ、インストールにコピー |
| 何も存在しない | GitHub からダウンロード、インストールにコピー |

### 3. ダウンロード（必要な場合）

```cmake
file(DOWNLOAD
    ${NLOHMANN_JSON_URL}
    ${NLOHMANN_JSON_CACHED}
    SHOW_PROGRESS
    STATUS DOWNLOAD_STATUS
)
```

- GitHub Releases から単一ヘッダー `json.hpp` をダウンロード
- 1 ファイル（約 900KB）のみダウンロード

### 4. インストール

```cmake
file(COPY ${NLOHMANN_JSON_CACHED}
    DESTINATION ${NLOHMANN_JSON_INSTALL_DIR}/include/nlohmann
)
```

- 標準的な `#include <nlohmann/json.hpp>` パスに合わせて `json.hpp` を `include/nlohmann/` にコピー
- コンパイル手順は不要（ヘッダーオンリーライブラリ）

### 5. インクルードパスの設定

```cmake
target_include_directories(${PROJECT_NAME} PRIVATE
    ${NLOHMANN_JSON_INSTALL_DIR}/include
)
```

GSL や ALGLIB とは異なり、nlohmann/json はヘッダーオンリーです。`add_library`、`target_link_libraries`、静的ライブラリの作成は不要です。

---

## nlohmann/json ライブラリ

nlohmann/json は単一のヘッダーファイルで構成されます：

| ファイル | サイズ | 説明 |
|--------|------|------|
| `json.hpp` | 約 900KB | すべての機能を含む単一ヘッダーライブラリ |

---

## nlohmann/json の主な機能

| 機能 | 説明 |
|------|------|
| 直感的な構文 | `j["key"]` アクセス、初期化子リスト構築 |
| STL 統合 | `std::vector`、`std::map`、`std::string` などと連携 |
| 型安全性 | `get<T>()` による明示的な型変換、`is_*()` による型チェック |
| シリアライズ | `dump()` で JSON を文字列に（オプションで整形出力） |
| デシリアライズ | `parse()` で文字列を JSON に変換 |
| JSON Pointer | RFC 6901 JSON Pointer サポート（`j["/path/to/key"_json_pointer]`） |
| JSON Patch | RFC 6902 JSON Patch による差分とマージのサポート |
| イテレータサポート | 範囲 for ループ、`items()` によるキー・値イテレーション |
| エラー処理 | `parse_error`、`type_error`、`out_of_range` による例外ベース |
| カスタム型 | `to_json`/`from_json` によるユーザー定義型のシリアライズ |
| CBOR/MessagePack | バイナリシリアライズ形式サポート |

---

## C/C++ での使用例

### パースとアクセス

```cpp
#include <nlohmann/json.hpp>
#include <iostream>

int main() {
    std::string s = R"({"name":"John","age":30})";
    nlohmann::json j = nlohmann::json::parse(s);

    std::cout << "名前: " << j["name"].get<std::string>() << "\n";
    std::cout << "年齢: " << j["age"].get<int>() << "\n";

    return 0;
}
```

### プログラムで JSON を構築

```cpp
#include <nlohmann/json.hpp>
#include <iostream>

int main() {
    nlohmann::json j = {
        {"name", "Alice"},
        {"age", 25},
        {"skills", {"C++", "Python", "Rust"}}
    };

    std::cout << j.dump(4) << "\n";
    return 0;
}
```

### 変更とシリアライズ

```cpp
#include <nlohmann/json.hpp>
#include <iostream>

int main() {
    nlohmann::json j = {{"name", "John"}, {"age", 30}};

    j["age"] = 31;
    j["email"] = "john@example.com";
    j.erase("name");

    // 整形出力（4 スペースインデント）
    std::cout << j.dump(4) << "\n";

    // コンパクト
    std::cout << j.dump() << "\n";

    return 0;
}
```

### デフォルト値による安全なアクセス

```cpp
#include <nlohmann/json.hpp>
#include <iostream>

int main() {
    nlohmann::json j = {{"name", "John"}};

    // value() はキーが存在しない場合デフォルトを返す
    std::string email = j.value("email", "N/A");
    int age = j.value("age", -1);

    std::cout << "メール: " << email << "\n";  // "N/A"
    std::cout << "年齢: " << age << "\n";       // -1

    // contains() でキーの存在を確認
    if (j.contains("name")) {
        std::cout << "名前: " << j["name"].get<std::string>() << "\n";
    }

    return 0;
}
```

### イテレーション

```cpp
#include <nlohmann/json.hpp>
#include <iostream>

int main() {
    nlohmann::json j = {
        {"name", "Alice"},
        {"scores", {95, 87, 92}}
    };

    // キー・値ペアのイテレーション
    for (auto& [key, val] : j.items()) {
        std::cout << key << " -> " << val.dump() << "\n";
    }

    // 配列のイテレーション
    for (const auto& score : j["scores"]) {
        std::cout << score.get<int>() << " ";
    }
    std::cout << "\n";

    return 0;
}
```

### 型チェック

```cpp
#include <nlohmann/json.hpp>
#include <iostream>

int main() {
    nlohmann::json j = {
        {"str", "hello"},
        {"num", 42},
        {"arr", {1, 2, 3}},
        {"nil", nullptr}
    };

    for (auto& [key, val] : j.items()) {
        std::cout << key << " は ";
        if (val.is_string())        std::cout << "文字列";
        else if (val.is_number())   std::cout << "数値";
        else if (val.is_array())    std::cout << "配列";
        else if (val.is_null())     std::cout << "null";
        std::cout << "\n";
    }

    return 0;
}
```

### エラー処理

```cpp
#include <nlohmann/json.hpp>
#include <iostream>

int main() {
    // パースエラー
    try {
        nlohmann::json j = nlohmann::json::parse("{invalid}");
    } catch (const nlohmann::json::parse_error& e) {
        std::cout << "パースエラー: " << e.what() << "\n";
    }

    // 型エラー
    nlohmann::json j = {{"name", "John"}};
    try {
        int val = j["name"].get<int>();  // string -> int は失敗
        (void)val;
    } catch (const nlohmann::json::type_error& e) {
        std::cout << "型エラー: " << e.what() << "\n";
    }

    // 範囲外
    try {
        auto val = j.at("nonexistent");
        (void)val;
    } catch (const nlohmann::json::out_of_range& e) {
        std::cout << "範囲外: " << e.what() << "\n";
    }

    return 0;
}
```

### カスタム型のシリアライズ

```cpp
#include <nlohmann/json.hpp>
#include <iostream>

struct Person {
    std::string name;
    int age;
};

void to_json(nlohmann::json& j, const Person& p) {
    j = nlohmann::json{{"name", p.name}, {"age", p.age}};
}

void from_json(const nlohmann::json& j, Person& p) {
    j.at("name").get_to(p.name);
    j.at("age").get_to(p.age);
}

int main() {
    Person p = {"Alice", 30};
    nlohmann::json j = p;
    std::cout << j.dump(4) << "\n";

    Person p2 = j.get<Person>();
    std::cout << p2.name << ", " << p2.age << "\n";

    return 0;
}
```

---

## nlohmann/json API の規約

### 名前空間

すべての機能は `nlohmann` 名前空間にあります：

```cpp
nlohmann::json j;

// よく使われるエイリアス
using json = nlohmann::json;
json j2;
```

### 値のアクセス

| メソッド | 説明 |
|--------|------|
| `j["key"]` | キーでアクセス（存在しない場合は作成） |
| `j.at("key")` | キーでアクセス（存在しない場合は例外） |
| `j.value("key", default)` | デフォルトフォールバック付きアクセス |
| `j.get<T>()` | 明示的な型変換 |
| `j.contains("key")` | キーの存在を確認 |

### シリアライズ

| メソッド | 説明 |
|--------|------|
| `j.dump()` | コンパクトな JSON 文字列 |
| `j.dump(4)` | 4 スペースインデントで整形出力 |
| `nlohmann::json::parse(str)` | 文字列からパース |

### 型チェック

| メソッド | 説明 |
|--------|------|
| `j.is_string()` | 文字列かチェック |
| `j.is_number()` | 数値（整数または浮動小数点）かチェック |
| `j.is_number_integer()` | 整数かチェック |
| `j.is_number_float()` | 浮動小数点かチェック |
| `j.is_boolean()` | 真偽値かチェック |
| `j.is_null()` | null かチェック |
| `j.is_array()` | 配列かチェック |
| `j.is_object()` | オブジェクトかチェック |

### 変更

| メソッド | 説明 |
|--------|------|
| `j["key"] = value` | 値の設定/更新 |
| `j.push_back(val)` | 配列に追加 |
| `j.erase("key")` | オブジェクトからキーを削除 |
| `j.clear()` | すべての要素を削除 |
| `j.merge_patch(other)` | 別の JSON オブジェクトをマージ |

### エラー型

| 例外 | 発生条件 |
|------|---------|
| `nlohmann::json::parse_error` | 無効な JSON 構文 |
| `nlohmann::json::type_error` | 間違った型のアクセス（例：文字列を int として取得） |
| `nlohmann::json::out_of_range` | キー/インデックスが存在しない（`at()` 使用時） |
| `nlohmann::json::invalid_iterator` | 無効なイテレータ操作 |
| `nlohmann::json::other_error` | その他のエラー |

---

## 比較：nlohmann/json vs 他の JSON ライブラリ

| 機能 | nlohmann/json | RapidJSON | simdjson | Boost.JSON |
|------|--------------|-----------|----------|------------|
| ライセンス | MIT | MIT | Apache 2 | BSL 1.0 |
| ヘッダーオンリー | はい | はい | いいえ | いいえ |
| C++ 標準 | C++11+ | C++11+ | C++17+ | C++11+ |
| 使いやすさ | 優秀 | 普通 | 普通 | 良好 |
| パース速度 | 良好 | 高速 | 最速 | 良好 |
| メモリ使用量 | やや多い | 少ない | 少ない | 普通 |
| STL 統合 | 完全 | 最小限 | 最小限 | 良好 |
| カスタム型 | あり（to/from_json） | 手動 | 読み取り専用 | あり |
| バイナリ形式 | CBOR, MessagePack, UBJSON, BSON | なし | なし | なし |

nlohmann/json は生のパフォーマンスよりも使いやすさと開発体験を優先しています。
ほとんどのアプリケーションでは、そのパフォーマンスは十分です。高スループットのパース用途には RapidJSON や simdjson を検討してください。

---

## トラブルシューティング

### ダウンロードが失敗する

GitHub に接続できない場合、手動でダウンロードして配置できます：

```bash
curl -L -o download/json.hpp \
    https://github.com/nlohmann/json/releases/download/v3.12.0/json.hpp
```

その後 `cmake ..` を再実行すると、キャッシュされたファイルからインストールされます。

### 最初からリビルド

新規のダウンロードとインストールを強制する場合：

```bash
rm -rf download/nlohmann-json-install download/json.hpp
cd build && cmake ..
```

### ヘッダーが見つからない

インクルードディレクトリが正しく設定されていることを確認してください：

```cmake
target_include_directories(${PROJECT_NAME} PRIVATE ${NLOHMANN_JSON_INSTALL_DIR}/include)
```

ヘッダーは以下のようにインクルードします：

```cpp
#include <nlohmann/json.hpp>   // OK
// #include "json.hpp"         // NG（パスが間違い）
```

### コンパイルが遅い

`json.hpp` は大きな単一ヘッダーファイル（約 900KB）です。コンパイル時間が増加する可能性があります。これが問題な場合：

- プリコンパイルヘッダー（PCH）を使用してパース済みヘッダーをキャッシュ
- GitHub リポジトリのマルチヘッダー版の使用を検討

---

## 参考資料

- [nlohmann/json GitHub リポジトリ](https://github.com/nlohmann/json)
- [nlohmann/json ドキュメント](https://json.nlohmann.me/)
- [nlohmann/json API リファレンス](https://json.nlohmann.me/api/basic_json/)
- [JSON 仕様（RFC 8259）](https://tools.ietf.org/html/rfc8259)
- [JSON Pointer（RFC 6901）](https://tools.ietf.org/html/rfc6901)
- [CMake file(DOWNLOAD) ドキュメント](https://cmake.org/cmake/help/latest/command/file.html#download)
