# isocline.cmake リファレンス

## 概要

`isocline.cmake` は、isocline ライブラリのダウンロード・ビルド・リンクを自動化する CMake 設定ファイルです。
CMake の `file(DOWNLOAD)` と `execute_process` を使用して依存関係を管理し、`download/` ディレクトリにキャッシュすることで、不要なダウンロードや再ビルドを回避します。

isocline は、純粋な C で書かれたポータブルな GNU readline 代替ライブラリです。マルチライン編集、シンタックスハイライト、プレビュー付きタブ補完、Unicode サポート、24ビットカラー、永続的なヒストリ、括弧マッチング、BBCode スタイルのフォーマット出力などの機能を備えています。

isocline は外部依存ライブラリを持たず、単一の C ファイルとしてコンパイル可能です。

## ファイル情報

| 項目 | 詳細 |
|------|------|
| ソースディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/isocline/isocline` |
| インストールディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/isocline/isocline-install` |
| ダウンロード URL | https://github.com/daanx/isocline/archive/refs/tags/v1.0.9.tar.gz |
| バージョン | 1.0.9 |
| ライセンス | MIT |

---

## インクルードガード

```cmake
include_guard(GLOBAL)
```

このファイルは `include_guard(GLOBAL)` を使用して、複数回インクルードされても一度だけ実行されることを保証します。

**必要な理由:**

- configure 中の `execute_process` の重複実行を防止
- `target_link_libraries` での重複リンクを防止

---

## ディレクトリ構成

```
isocline/
├── cmake/
│   ├── isocline.cmake       # この設定ファイル
│   ├── isoclineCmake.md     # 英語版ドキュメント
│   └── isoclineCmake-jp.md  # このドキュメント
├── download/isocline/
│   ├── isocline/            # isocline ソース（GitHub からダウンロード・キャッシュ）
│   └── isocline-install/    # isocline ビルド成果物（lib/, include/）
│       ├── include/
│       │   └── isocline.h
│       └── lib/
│           └── libisocline.a
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## 使い方

### CMakeLists.txt への追加

```cmake
# CMakeLists.txt の末尾に isocline.cmake をインクルード
include("./cmake/isocline.cmake")
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
set(ISOCLINE_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/isocline)
set(ISOCLINE_SOURCE_DIR ${ISOCLINE_DOWNLOAD_DIR}/isocline)
set(ISOCLINE_INSTALL_DIR ${ISOCLINE_DOWNLOAD_DIR}/isocline-install)
set(ISOCLINE_VERSION "1.0.9")
set(ISOCLINE_URL "https://github.com/daanx/isocline/archive/refs/tags/v${ISOCLINE_VERSION}.tar.gz")
```

### 2. キャッシュチェックと条件付きビルド

```cmake
if(EXISTS ${ISOCLINE_INSTALL_DIR}/lib/libisocline.a)
    message(STATUS "isocline already built: ${ISOCLINE_INSTALL_DIR}/lib/libisocline.a")
else()
    # ダウンロード、設定、ビルド、インストール ...
endif()
```

キャッシュロジックは以下の通りです:

| 条件 | アクション |
|------|-----------|
| `isocline-install/lib/libisocline.a` が存在 | すべてスキップ（キャッシュ済みビルドを使用） |
| `isocline/CMakeLists.txt` が存在（インストールなし） | ダウンロードをスキップし、cmake configure/build/install を実行 |
| 何も存在しない | ダウンロード、展開、設定、ビルド、インストール |

### 3. ダウンロード（必要な場合）

```cmake
file(DOWNLOAD
    ${ISOCLINE_URL}
    ${ISOCLINE_DOWNLOAD_DIR}/isocline-${ISOCLINE_VERSION}.tar.gz
    SHOW_PROGRESS
    STATUS DOWNLOAD_STATUS
)
file(ARCHIVE_EXTRACT
    INPUT ${ISOCLINE_DOWNLOAD_DIR}/isocline-${ISOCLINE_VERSION}.tar.gz
    DESTINATION ${ISOCLINE_DOWNLOAD_DIR}
)
file(RENAME ${ISOCLINE_DOWNLOAD_DIR}/isocline-${ISOCLINE_VERSION} ${ISOCLINE_SOURCE_DIR})
```

- GitHub（daanx/isocline リリース）からダウンロード
- `isocline-1.0.9/` を `isocline/` にリネームしてパスを整理

### 4. 設定とビルド（CMake ベース）

```cmake
execute_process(
    COMMAND ${CMAKE_COMMAND}
            -DCMAKE_INSTALL_PREFIX=${ISOCLINE_INSTALL_DIR}
            -DCMAKE_BUILD_TYPE=Release
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON
            ${ISOCLINE_SOURCE_DIR}
    WORKING_DIRECTORY ${ISOCLINE_BUILD_DIR}
)
execute_process(
    COMMAND ${CMAKE_COMMAND} --build . --target isocline -j4
    WORKING_DIRECTORY ${ISOCLINE_BUILD_DIR}
)
```

- CMake を使用して設定・ビルド（autoconf ベースのライブラリとは異なる）
- `-DCMAKE_POSITION_INDEPENDENT_CODE=ON`: 位置独立コードを生成
- `isocline` ライブラリターゲットのみビルド（サンプルやテストは除外）
- すべてのステップは CMake configure 時に実行され、ビルド時ではない

### 5. インストール（手動）

isocline の CMakeLists.txt にはインストールルールが含まれていないため、手動でインストールします:

```cmake
file(COPY ${ISOCLINE_LIB_FILE} DESTINATION ${ISOCLINE_INSTALL_DIR}/lib)
file(COPY ${ISOCLINE_SOURCE_DIR}/include/isocline.h DESTINATION ${ISOCLINE_INSTALL_DIR}/include)
```

### 6. ライブラリのリンク

```cmake
add_library(isocline_lib STATIC IMPORTED)
set_target_properties(isocline_lib PROPERTIES
    IMPORTED_LOCATION ${ISOCLINE_INSTALL_DIR}/lib/libisocline.a
)

target_include_directories(${PROJECT_NAME} PRIVATE ${ISOCLINE_INSTALL_DIR}/include)
target_link_libraries(${PROJECT_NAME} PRIVATE isocline_lib)
```

GSL とは異なり、isocline は単一のライブラリで、追加の依存関係（`-lm` や CBLAS など）は不要です。

---

## isocline ライブラリ

isocline は単一のライブラリで構成されます:

| ライブラリ | ファイル | 説明 |
|-----------|---------|------|
| `libisocline` | `libisocline.a` | readline 機能のすべてを含む isocline ライブラリ |

ライブラリは純粋な C で書かれており、外部依存ライブラリはありません。標準の POSIX API と ANSI エスケープシーケンスのみを使用してターミナル操作を行います。

---

## isocline の主要機能

| 機能 | API 関数 | 説明 |
|------|---------|------|
| 行入力 | `ic_readline`, `ic_readline_ex` | リッチ編集機能付きのインタラクティブ入力 |
| ヒストリ | `ic_set_history`, `ic_history_add`, `ic_history_remove_last`, `ic_history_clear` | ファイル保存による永続的なコマンドヒストリ |
| タブ補完 | `ic_set_default_completer`, `ic_add_completion`, `ic_add_completions` | プレビュー付きカスタマイズ可能なタブ補完 |
| ファイル名補完 | `ic_complete_filename` | 組み込みのファイル名/パス補完 |
| 単語補完 | `ic_complete_word`, `ic_complete_qword` | 単語境界およびクォートされた単語の補完 |
| シンタックスハイライト | `ic_set_default_highlighter`, `ic_highlight` | カスタムシンタックスハイライトコールバック |
| BBCode 出力 | `ic_print`, `ic_println`, `ic_printf` | BBCode マークアップによるスタイル付きターミナル出力 |
| スタイル定義 | `ic_style_def`, `ic_style_open`, `ic_style_close` | カスタム名前付きスタイルの定義・適用 |
| プロンプト設定 | `ic_set_prompt_marker`, `ic_get_prompt_marker` | プロンプトと継続行マーカーの設定 |
| マルチライン編集 | `ic_enable_multiline` | Shift+Tab でのマルチライン入力 |
| 括弧マッチング | `ic_enable_brace_matching`, `ic_enable_brace_insertion` | 対応する括弧のハイライト、閉じ括弧の自動挿入 |
| ヒント | `ic_enable_hint`, `ic_set_hint_delay` | インライン補完ヒント |
| カラー制御 | `ic_enable_color` | カラー出力の有効/無効 |
| ターミナル API | `ic_term_init`, `ic_term_write`, `ic_term_color_rgb` | 低レベルターミナル制御 |
| 非同期停止 | `ic_async_stop` | スレッドセーフな readline 中断 |
| カスタムアロケータ | `ic_init_custom_alloc`, `ic_malloc`, `ic_free` | カスタムメモリアロケーション |

---

## C/C++ での使用例

### 基本的な Readline ループ

```c
#include <isocline.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    ic_set_history("history.txt", -1);

    char *input;
    while ((input = ic_readline("prompt> ")) != NULL) {
        printf("入力: %s\n", input);
        free(input);
    }
    return 0;
}
```

### タブ補完

```c
#include <isocline.h>
#include <stdio.h>
#include <stdlib.h>

static const char *commands[] = {
    "help", "exit", "list", "add", "remove", NULL
};

static void completer(ic_completion_env_t *cenv, const char *prefix) {
    ic_add_completions(cenv, prefix, commands);
}

int main() {
    ic_set_default_completer(&completer, NULL);
    ic_enable_completion_preview(true);

    char *input;
    while ((input = ic_readline("$ ")) != NULL) {
        printf("コマンド: %s\n", input);
        free(input);
    }
    return 0;
}
```

### シンタックスハイライト

```c
#include <isocline.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char *keywords[] = {
    "if", "else", "while", "for", "return", NULL
};

static void highlighter(ic_highlight_env_t *henv, const char *input, void *arg) {
    (void)arg;
    for (int i = 0; keywords[i] != NULL; i++) {
        size_t len = strlen(keywords[i]);
        if (strncmp(input, keywords[i], len) == 0 &&
            (input[len] == '\0' || input[len] == ' ')) {
            ic_highlight(henv, 0, (long)len, "keyword");
            break;
        }
    }
}

int main() {
    ic_style_def("keyword", "[blue]");
    ic_set_default_highlighter(&highlighter, NULL);

    char *input;
    while ((input = ic_readline("> ")) != NULL) {
        printf("%s\n", input);
        free(input);
    }
    return 0;
}
```

### BBCode スタイル出力

```c
#include <isocline.h>

int main() {
    ic_println("[b]太字[/b] と [i]斜体[/i] テキスト");
    ic_println("[red]エラー:[/red] 何かが失敗しました");
    ic_println("[green]成功:[/green] 操作が完了しました");

    // カスタムスタイルの定義
    ic_style_def("header", "[bold][underline]");
    ic_println("[header]マイアプリケーション[/header]");

    // BBCode 付き printf スタイル
    ic_printf("[blue]結果:[/blue] %d\n", 42);

    return 0;
}
```

### ファイル名補完

```c
#include <isocline.h>
#include <stdio.h>
#include <stdlib.h>

static void completer(ic_completion_env_t *cenv, const char *prefix) {
    // すべての拡張子のファイル名を補完（デフォルトのディレクトリセパレータを使用）
    ic_complete_filename(cenv, prefix, 0, NULL, NULL);
}

int main() {
    ic_set_default_completer(&completer, NULL);
    ic_enable_completion_preview(true);

    char *input;
    while ((input = ic_readline("file> ")) != NULL) {
        printf("選択: %s\n", input);
        free(input);
    }
    return 0;
}
```

### ヘルプテキスト付き補完

```c
#include <isocline.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void completer(ic_completion_env_t *cenv, const char *prefix) {
    // 表示テキストとヘルプ説明付きの補完を追加
    if (strncmp("help", prefix, strlen(prefix)) == 0) {
        ic_add_completion_ex(cenv, "help", "help", "ヘルプ情報を表示");
    }
    if (strncmp("exit", prefix, strlen(prefix)) == 0) {
        ic_add_completion_ex(cenv, "exit", "exit", "プログラムを終了");
    }
    if (strncmp("list", prefix, strlen(prefix)) == 0) {
        ic_add_completion_ex(cenv, "list", "list", "すべてのアイテムを一覧表示");
    }
}

int main() {
    ic_set_default_completer(&completer, NULL);
    ic_enable_completion_preview(true);
    ic_enable_inline_help(true);

    char *input;
    while ((input = ic_readline("$ ")) != NULL) {
        printf("コマンド: %s\n", input);
        free(input);
    }
    return 0;
}
```

### カスタムプロンプトによるマルチライン入力

```c
#include <isocline.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    ic_enable_multiline(true);
    ic_enable_brace_matching(true);
    ic_enable_brace_insertion(true);
    ic_set_prompt_marker("> ", "  ");

    char *input;
    while ((input = ic_readline("")) != NULL) {
        printf("入力:\n%s\n", input);
        free(input);
    }
    return 0;
}
```

---

## isocline API の規約

### 関数命名規則

isocline の関数名は一貫した `ic_` プレフィックス規則に従います:

| パターン | 例 | 説明 |
|---------|-----|------|
| `ic_readline*` | `ic_readline("prompt")` | インタラクティブ入力の読み取り |
| `ic_set_*` | `ic_set_history(...)` | 設定の構成 |
| `ic_enable_*` | `ic_enable_multiline(true)` | 機能の有効/無効 |
| `ic_add_completion*` | `ic_add_completion(cenv, str)` | 補完候補の追加 |
| `ic_complete_*` | `ic_complete_filename(...)` | 組み込み補完ヘルパー |
| `ic_print*` | `ic_println("text")` | BBCode スタイル付きターミナル出力 |
| `ic_style_*` | `ic_style_def("name", "[blue]")` | 名前付きスタイルの定義・管理 |
| `ic_highlight*` | `ic_highlight(henv, pos, len, style)` | シンタックスハイライトの適用 |
| `ic_history_*` | `ic_history_add("entry")` | ヒストリの操作 |
| `ic_term_*` | `ic_term_write("text")` | 低レベルターミナル操作 |

### メモリ管理

`ic_readline()` はヒープに確保された `char*` を返し、呼び出し側が `free()` する必要があります:

```c
char *input = ic_readline("prompt> ");
if (input != NULL) {
    // ... input を使用 ...
    free(input);  // 呼び出し側が解放
}
```

`ic_init_custom_alloc()` でカスタムアロケータを設定した場合は、`free()` の代わりに `ic_free()` を使用してください。

### 戻り値

- `ic_readline()` は EOF（Ctrl+D）、Ctrl+C、またはエラー時に `NULL` を返す
- `ic_add_completion()` は補完が追加された場合に `true` を返す
- ほとんどの設定関数（`ic_set_*`, `ic_enable_*`）は `void` を返す

### BBCode マークアップリファレンス

| タグ | 効果 |
|------|------|
| `[b]...[/b]` | 太字 |
| `[i]...[/i]` | 斜体 |
| `[u]...[/u]` | 下線 |
| `[red]...[/red]` | 赤色テキスト（他: green, blue, yellow, cyan, magenta, white, black） |
| `[#RRGGBB]...[/#]` | 24ビット RGB カラー |
| `[bold]` | `[b]` と同じ |
| `[underline]` | `[u]` と同じ |
| `[italic]` | `[i]` と同じ |
| `[reverse]` | 反転表示 |

---

## 比較: isocline vs 他の Readline ライブラリ

| 機能 | isocline | GNU readline | libedit | linenoise |
|------|----------|-------------|---------|-----------|
| 言語 | C | C | C | C |
| ライセンス | MIT | GPL v3 | BSD | BSD |
| 依存ライブラリ | なし | ncurses/termcap | ncurses | なし |
| Unicode | 完全対応 | 部分対応 | 部分対応 | 非対応 |
| マルチライン | 対応 | 非対応 | 非対応 | 非対応 |
| 24ビットカラー | 対応 | 非対応 | 非対応 | 非対応 |
| シンタックスハイライト | 対応 | 非対応 | 非対応 | 非対応 |
| 補完プレビュー | 対応 | 非対応 | 非対応 | 非対応 |
| 括弧マッチング | 対応 | 非対応 | 非対応 | 非対応 |
| BBCode 出力 | 対応 | 非対応 | 非対応 | 非対応 |
| ヒストリ検索 | 対応（Ctrl+R） | 対応（Ctrl+R） | 対応 | 非対応 |
| Windows 対応 | 対応 | 非対応（Cygwin） | 非対応 | 部分対応 |
| コードサイズ | 約8000行 | 約40000行 | 約30000行 | 約1000行 |

isocline は readline 代替ライブラリの中で最も豊富な機能セットを提供しながら、軽量で依存ライブラリがありません。シンタックスハイライト、補完プレビュー、マルチライン編集を必要とするインタラクティブ CLI ツールに特に適しています。

---

## 環境変数

| 変数 | 効果 |
|------|------|
| `NO_COLOR` | 設定されている場合、すべてのカラー出力を無効化 |
| `CLICOLOR=1` | ファイル名補完のカラー表示に `LS_COLORS` を有効化 |
| `COLORTERM` | カラーパレットを強制: `truecolor`, `256color`, `16color`, `8color`, `monochrome` |
| `TERM` | ターミナル機能検出に使用 |

---

## トラブルシューティング

### ダウンロードに失敗する場合

GitHub にアクセスできない場合、手動でダウンロードしてファイルを配置できます:

```bash
curl -L -o download/isocline/isocline-1.0.9.tar.gz \
    https://github.com/daanx/isocline/archive/refs/tags/v1.0.9.tar.gz
```

その後 `cmake ..` を再実行すると、キャッシュされたアーカイブからの展開が進みます。

### ビルドに失敗する場合

CMake 3.10 以上と C99 対応のコンパイラが利用可能であることを確認してください:

```bash
cmake --version
cc --version
```

### isocline を最初からリビルドする場合

完全なリビルドを強制するには、インストールディレクトリとソースディレクトリを削除します:

```bash
rm -rf download/isocline/isocline-install download/isocline/isocline
cd build && cmake ..
```

### ヘッダが見つからない: `isocline.h`

`'isocline.h' file not found` が表示される場合は、ビルドが少なくとも一度完了していることを確認してください。ヘッダは CMake configure ステップ中にインストールディレクトリにコピーされます:

```bash
cd build && cmake .. && make
```

ビルドが成功すると、`compile_commands.json` が更新され、IDE の診断エラーは解消されます。

---

## 参考資料

- [isocline GitHub リポジトリ](https://github.com/daanx/isocline)
- [isocline API ドキュメント](https://daanx.github.io/isocline/)
- [isocline README](https://github.com/daanx/isocline/blob/main/readme.md)
- [Readline API リファレンス](https://daanx.github.io/isocline/group__readline.html)
- [History API リファレンス](https://daanx.github.io/isocline/group__history.html)
- [Completion API リファレンス](https://daanx.github.io/isocline/group__completion.html)
- [Highlighting API リファレンス](https://daanx.github.io/isocline/group__highlight.html)
- [BBCode API リファレンス](https://daanx.github.io/isocline/group__bbcode.html)
