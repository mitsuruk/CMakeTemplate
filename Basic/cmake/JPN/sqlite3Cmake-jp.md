# sqlite3.cmake リファレンス

## 概要

`sqlite3.cmake` は SQLite3 データベースライブラリを公式サイトから自動ダウンロードし、静的ライブラリとしてビルドする CMake 設定ファイルです。キャッシュ機構により、以降のビルドでは再ダウンロードをスキップします。

## ファイル情報

| 項目 | 詳細 |
|------|------|
| プロジェクト | SQLite3 アマルガメーションのダウンロードとビルド |
| 作者 | mitsuruk |
| 作成日 | 2025/11/26 |
| ライセンス | パブリックドメイン（SQLite と同様） |

---

## インクルードガード

```cmake
include_guard(GLOBAL)
```

このファイルは `include_guard(GLOBAL)` を使用して、複数回インクルードされても一度だけ実行されるようにしています。

**必要な理由：**

- `add_library(sqlite3 ...)` の重複定義エラーを防止
- ダウンロード処理の重複実行を回避
- `target_link_libraries` での重複リンクを防止

---

## 処理の流れ

```
1. キャッシュの確認
   ├─ 存在する → キャッシュを使用
   └─ 存在しない → ステップ 2 へ
2. 公式サイトから最新バージョンを検出
3. SQLite アマルガメーションをダウンロード
4. キャッシュディレクトリに保存
5. ヘッダーファイルを別ディレクトリにコピー（競合回避）
6. 静的ライブラリのビルド
7. メインプロジェクトへのリンク
```

---

## 機能の詳細

### 1. キャッシュ機構

```cmake
set(SQLITE3_CACHE_DIR "${CMAKE_SOURCE_DIR}/download/sqlite3")

if(EXISTS "${SQLITE3_CACHE_DIR}/sqlite3.c" AND
   EXISTS "${SQLITE3_CACHE_DIR}/sqlite3.h" AND
   EXISTS "${SQLITE3_CACHE_DIR}/sqlite3ext.h")
  message(STATUS "Using cached SQLite3 from: ${SQLITE3_CACHE_DIR}")
  set(SQLITE3_SOURCE_DIR "${SQLITE3_CACHE_DIR}")
else()
  # ダウンロード処理
endif()
```

キャッシュディレクトリに必要なファイルが存在する場合、ダウンロードをスキップします。

**キャッシュされるファイル：**

| ファイル | 説明 |
|--------|------|
| `sqlite3.c` | SQLite メインソース（アマルガメーション） |
| `sqlite3.h` | 公開ヘッダー |
| `sqlite3ext.h` | 拡張ヘッダー |
| `VERSION.txt` | バージョン情報（自動生成） |

---

### 2. 最新バージョンの自動検出

```cmake
set(SQLITE_DOWNLOAD_PAGE "https://sqlite.org/download.html")

file(DOWNLOAD
    ${SQLITE_DOWNLOAD_PAGE}
    ${CMAKE_BINARY_DIR}/sqlite_download.html
    STATUS DOWNLOAD_STATUS
)

# HTML からダウンロード URL を抽出
string(REGEX MATCH "([0-9]+)/sqlite-autoconf-([0-9]+)\\.tar\\.gz"
    _match "${_sqlite_html}")
```

SQLite の公式ダウンロードページを取得し、正規表現で最新の autoconf パッケージの URL を抽出します。

---

### 3. ダウンロードとキャッシュ

```cmake
set(SQLITE_URL "https://sqlite.org/${SQLITE_YEAR}/sqlite-autoconf-${SQLITE_VERSION_NUMBER}.tar.gz")

FetchContent_Declare(
    sqlite3_download
    URL ${SQLITE_URL}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)

FetchContent_MakeAvailable(sqlite3_download)
```

`FetchContent` モジュールを使用してアーカイブをダウンロード・展開します。

---

### 4. ヘッダーファイルの分離（競合回避）

```cmake
set(SQLITE3_INCLUDE_DIR "${CMAKE_BINARY_DIR}/sqlite3_include")
file(MAKE_DIRECTORY "${SQLITE3_INCLUDE_DIR}")
file(COPY "${SQLITE3_SOURCE_DIR}/sqlite3.h" DESTINATION "${SQLITE3_INCLUDE_DIR}")
file(COPY "${SQLITE3_SOURCE_DIR}/sqlite3ext.h" DESTINATION "${SQLITE3_INCLUDE_DIR}")
```

**重要**：SQLite の配布物には `VERSION` ファイルが含まれており、C++ 標準ライブラリの `<version>` ヘッダーと競合する可能性があります。これを回避するため、ヘッダーファイルを別のディレクトリにコピーします。

---

### 5. 静的ライブラリのビルド

```cmake
add_library(sqlite3 STATIC
    "${SQLITE3_SOURCE_DIR}/sqlite3.c"
)
```

SQLite アマルガメーション（単一ソースファイル）から静的ライブラリを作成します。

---

### 6. インクルードディレクトリの設定

```cmake
# sqlite3 ライブラリ自体はソースディレクトリを使用（PRIVATE）
target_include_directories(sqlite3 PRIVATE
    ${SQLITE3_SOURCE_DIR}
)

# 外部ユーザーはコピーされたヘッダーを使用（PUBLIC）
target_include_directories(sqlite3 PUBLIC
    ${SQLITE3_INCLUDE_DIR}
)
```

---

### 7. コンパイル設定

```cmake
target_compile_definitions(sqlite3 PUBLIC
    SQLITE_ENABLE_FTS5
    SQLITE_THREADSAFE=1
)

target_compile_options(sqlite3 PRIVATE
    -O2
)
```

| 定義 | 説明 |
|------|------|
| `SQLITE_ENABLE_FTS5` | 全文検索エンジン（FTS5）を有効化 |
| `SQLITE_THREADSAFE=1` | スレッドセーフモード（シリアライズド） |

| オプション | 説明 |
|----------|------|
| `-O2` | 最適化レベル 2 |

---

### 8. メインプロジェクトへのリンク

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE sqlite3)
```

---

## ディレクトリ構造

### 初回ビルド後

```
project/
├── download/
│   └── sqlite3/                    # キャッシュディレクトリ
│       ├── sqlite3.c
│       ├── sqlite3.h
│       ├── sqlite3ext.h
│       └── VERSION.txt
├── build/
│   ├── sqlite3_include/            # 競合回避用ヘッダー
│   │   ├── sqlite3.h
│   │   └── sqlite3ext.h
│   └── libsqlite3.a                # ビルドされた静的ライブラリ
└── CMakeLists.txt
```

---

## 強制再ダウンロード

キャッシュをクリアして強制的に再ダウンロードする場合：

```bash
rm -rf download/sqlite3
```

次回 CMake を構成する際に最新バージョンがダウンロードされます。

---

## スレッドセーフモード

`SQLITE_THREADSAFE` の値による動作の違い：

| 値 | モード | 説明 |
|-----|------|------|
| `0` | シングルスレッド | ミューテックスなし（最速） |
| `1` | シリアライズド | すべての操作がシリアライズされる（最も安全） |
| `2` | マルチスレッド | 各接続を別々のスレッドで使用可能 |

---

## 使い方

メインの `CMakeLists.txt` からインクルード：

```cmake
include(cmake/sqlite3.cmake)
```

コード内での使用：

```cpp
#include <sqlite3.h>

sqlite3* db;
sqlite3_open(":memory:", &db);
// ...
sqlite3_close(db);
```

---

## 依存関係

| 依存先 | 必須/任意 | 説明 |
|--------|-----------|------|
| `${PROJECT_NAME}` | 必須 | メインプロジェクトのターゲット名 |
| `FetchContent` | 必須 | CMake 3.11 以上に含まれる標準モジュール |
| インターネット接続 | 必須（初回のみ） | ダウンロードに必要 |

---

## 注意事項

1. **ネットワーク依存**：初回ビルドにはインターネット接続が必要です。

2. **バージョン固定**：特定のバージョンを使用したい場合は、スクリプトを修正して `SQLITE_URL` を直接指定してください。

3. **VERSION ファイルの競合**：このスクリプトは `<version>` ヘッダーとの競合を回避するために、ヘッダーファイルを別のディレクトリにコピーします。

4. **コンパイルオプション**：`-O2` は GCC/Clang 用です。他のコンパイラでは調整が必要な場合があります。

5. **FTS5**：全文検索が不要な場合は、`SQLITE_ENABLE_FTS5` を削除できます。

6. **プロキシ環境**：プロキシが必要な企業ネットワークでは、CMake の環境変数（`HTTP_PROXY`/`HTTPS_PROXY`）を設定してください。
