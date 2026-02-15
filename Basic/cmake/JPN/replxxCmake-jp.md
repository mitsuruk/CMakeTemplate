# replxx.cmake リファレンス

## 概要

`replxx.cmake` は replxx ライブラリの自動ダウンロード、ビルド、リンクを行う CMake 設定ファイルです。
CMake の `FetchContent` モジュールを使用して依存関係を管理します。

replxx は GNU readline / libedit の代替ライブラリで、UTF-8 サポート、シンタックスハイライト、ヒント機能、クロスプラットフォーム互換性を備えています。
名前は「REPL (Read-Eval-Print Loop) + xx (C++)」に由来します。

## ファイル情報

| 項目 | 詳細 |
|------|------|
| ダウンロードディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/replxx` |
| リポジトリ | https://github.com/AmokHuginnsson/replxx |
| バージョン | release-0.0.4 |
| ライセンス | BSD-3-Clause |

---

## インクルードガード

```cmake
include_guard(GLOBAL)
```

このファイルは `include_guard(GLOBAL)` を使用して、複数回インクルードされても一度だけ実行されるようにしています。

**必要な理由：**

- `FetchContent_MakeAvailable(replxx)` の重複呼び出しエラーを防止
- `target_link_libraries` での重複リンクを防止

---

## ディレクトリ構造

```
Basic/
├── cmake/
│   └── replxx.cmake    # この設定ファイル
├── download/
│   └── replxx/         # replxx ライブラリ（GitHub: AmokHuginnsson/replxx）
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## 使い方

### CMakeLists.txt への追加

```cmake
# replxx.cmake が存在する場合に自動インクルード
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/replxx.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/replxx.cmake)
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

### 1. ダウンロードディレクトリの設定

```cmake
set(REPLXX_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(REPLXX_SOURCE_DIR ${REPLXX_DOWNLOAD_DIR}/replxx)
```

### 2. FetchContent による replxx の宣言

```cmake
FetchContent_Declare(
    replxx
    GIT_REPOSITORY https://github.com/AmokHuginnsson/replxx.git
    GIT_TAG        release-0.0.4
    GIT_SHALLOW    TRUE
    SOURCE_DIR     ${REPLXX_SOURCE_DIR}
)
```

- `GIT_TAG release-0.0.4`：安定リリースバージョンを使用
- `GIT_SHALLOW TRUE`：最新のコミットのみを取得（高速化）
- `SOURCE_DIR`：ダウンロード先を明示的に指定

### 3. ビルドオプションの設定

```cmake
set(REPLXX_BUILD_EXAMPLES OFF CACHE BOOL "Build replxx examples" FORCE)
```

ビルド時間を短縮するためにサンプルプログラムのビルドを無効化します。

### 4. ダウンロードとビルド

```cmake
FetchContent_MakeAvailable(replxx)
```

### 5. ライブラリのリンク

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE replxx)
target_include_directories(${PROJECT_NAME} PRIVATE ${REPLXX_SOURCE_DIR}/include)
```

---

## replxx の主な機能

| 機能 | 説明 |
|------|------|
| 行編集 | カーソル移動、文字削除、行編集 |
| 履歴 | 上下矢印キーで以前の入力を呼び出し |
| 補完 | Tab キーによるカスタム補完 |
| シンタックスハイライト | 入力中のテキストを色付け |
| ヒント表示 | 入力中にグレーで候補を表示 |
| UTF-8 サポート | 日本語などのマルチバイト文字を正しく処理 |
| 複数行編集 | 複数行にまたがる入力の編集 |

---

## C++ での使用例

### 基本的な使い方

```cpp
#include <replxx.hxx>
#include <string>
#include <iostream>

int main() {
    replxx::Replxx rx;

    // 履歴ファイルのロード
    rx.history_load("history.txt");

    // メインループ
    while (true) {
        // プロンプトを表示して入力を取得
        const char* input = rx.input("> ");

        if (input == nullptr) {
            // Ctrl+D (EOF)
            std::cout << std::endl;
            break;
        }

        std::string line(input);

        // 終了コマンド
        if (line == ".quit" || line == ".") {
            break;
        }

        // 空行をスキップ
        if (line.empty()) {
            continue;
        }

        // 履歴に追加
        rx.history_add(line);

        // 入力を処理
        std::cout << "入力: " << line << std::endl;
    }

    // 履歴を保存
    rx.history_save("history.txt");

    return 0;
}
```

### 補完の実装

```cpp
#include <replxx.hxx>
#include <vector>
#include <string>

// 補完候補を返すコールバック
replxx::Replxx::completions_t completionCallback(
    const std::string& context,
    int& contextLen
) {
    replxx::Replxx::completions_t completions;

    // コマンドのリスト
    std::vector<std::string> commands = {
        ".help", ".quit", ".reset", ".save", ".load", ".log"
    };

    // 一致する補完候補を追加
    for (const auto& cmd : commands) {
        if (cmd.find(context) == 0) {
            completions.emplace_back(cmd);
        }
    }

    return completions;
}

int main() {
    replxx::Replxx rx;

    // 補完コールバックを設定
    rx.set_completion_callback(completionCallback);

    // ...
}
```

### シンタックスハイライトの実装

```cpp
#include <replxx.hxx>

// ハイライトコールバック
void highlightCallback(
    const std::string& context,
    replxx::Replxx::colors_t& colors
) {
    // ドットで始まるコマンドを緑色に
    if (!context.empty() && context[0] == '.') {
        for (size_t i = 0; i < context.size(); ++i) {
            colors[i] = replxx::Replxx::Color::GREEN;
        }
    }
}

int main() {
    replxx::Replxx rx;

    // ハイライトコールバックを設定
    rx.set_highlighter_callback(highlightCallback);

    // ...
}
```

### ヒント機能の実装

```cpp
#include <replxx.hxx>

// ヒントコールバック
replxx::Replxx::hints_t hintCallback(
    const std::string& context,
    int& contextLen,
    replxx::Replxx::Color& color
) {
    replxx::Replxx::hints_t hints;
    color = replxx::Replxx::Color::GRAY;

    // ".h" が入力されたら ".help" をヒントとして表示
    if (context == ".h") {
        hints.emplace_back("elp");
    }

    return hints;
}

int main() {
    replxx::Replxx rx;

    // ヒントコールバックを設定
    rx.set_hint_callback(hintCallback);

    // ...
}
```

---

## キーバインド

replxx は Emacs スタイルのキーバインドをサポートしています。
以下のキーバインドがこのプロジェクトの REPL で利用可能です。

### カーソル移動

| キー | アクション |
|------|----------|
| `Ctrl+A` | 行頭に移動 |
| `Ctrl+E` | 行末に移動 |
| `Ctrl+B` / `←` | 1 文字左に移動 |
| `Ctrl+F` / `→` | 1 文字右に移動 |
| `Alt+B` | 1 単語左に移動 |
| `Alt+F` | 1 単語右に移動 |

### 編集

| キー | アクション |
|------|----------|
| `Ctrl+D` | カーソル位置の文字を削除 / 入力が空なら EOF |
| `Ctrl+H` / `Backspace` | カーソル左の文字を削除 |
| `Ctrl+K` | カーソルから行末まで削除 |
| `Ctrl+U` | 行頭からカーソルまで削除 |
| `Ctrl+W` | カーソル左の単語を削除 |
| `Ctrl+T` | カーソル位置とその左の文字を入れ替え |
| `Ctrl+Y` | ヤンク（削除したテキストを貼り付け） |

### 履歴

| キー | アクション |
|------|----------|
| `Ctrl+P` / `↑` | 履歴を後方にナビゲート |
| `Ctrl+N` / `↓` | 履歴を前方にナビゲート |
| `Ctrl+R` | 履歴をインクリメンタルに後方検索 |
| `Ctrl+S` | 履歴をインクリメンタルに前方検索 |
| `Alt+<` | 履歴の先頭に移動 |
| `Alt+>` | 履歴の末尾に移動 |

### 補完とその他

| キー | アクション |
|------|----------|
| `Tab` | 補完（このプロジェクトではコマンド補完） |
| `Ctrl+L` | 画面クリア |
| `Ctrl+C` | 現在の入力をキャンセル |
| `Ctrl+D` | EOF（入力が空なら REPL を終了） |

### このプロジェクトで有効な機能

このプロジェクトの `run_repl()` では以下の機能が設定されています：

| 機能 | 設定 | 説明 |
|------|------|------|
| 履歴サイズ | `rx.set_max_history_size(1000)` | 最大 1000 件の履歴を保持 |
| 履歴永続化 | `.llama_history` | ファイルに履歴を保存・復元 |
| Tab 補完 | `set_completion_callback` | `.` で始まるコマンドを補完 |
| シンタックスハイライト | `set_highlighter_callback` | コマンドを緑色で表示 |

---

## 履歴管理

```cpp
replxx::Replxx rx;

// 最大履歴サイズを設定
rx.set_max_history_size(1000);

// 履歴ファイルをロード
rx.history_load("~/.myapp_history");

// 履歴に追加
rx.history_add("command");

// 履歴を保存
rx.history_save("~/.myapp_history");

// 履歴をクリア
rx.history_clear();
```

---

## std::getline との比較

| 機能 | std::getline | replxx |
|------|-------------|--------|
| 行編集 | x | o |
| 履歴 | x | o |
| 補完 | x | o |
| シンタックスハイライト | x | o |
| ヒント表示 | x | o |
| UTF-8 | 部分的 | o |
| Windows | o | o |

---

## トラブルシューティング

### FetchContent が失敗する

CMake のバージョンが古い可能性があります。CMake 3.11 以上が必要です。

```bash
cmake --version
```

### リンクエラー：replxx が見つからない

`FetchContent_MakeAvailable(replxx)` が実行されていることを確認してください。

### 日本語が正しく表示されない

ターミナルの文字エンコーディングが UTF-8 に設定されていることを確認してください。

```bash
echo $LANG
# ja_JP.UTF-8 のように表示されるべき
```

---

## 参考資料

- [replxx GitHub](https://github.com/AmokHuginnsson/replxx)
- [replxx README](https://github.com/AmokHuginnsson/replxx/blob/master/README.md)
- [CMake FetchContent ドキュメント](https://cmake.org/cmake/help/latest/module/FetchContent.html)
