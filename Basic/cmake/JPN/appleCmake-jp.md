# apple.cmake ドキュメント

## 概要

`apple.cmake` は macOS 環境向けの CMake 設定ファイルです。Homebrew パッケージマネージャーの検出と設定、および Apple Metal C++ のサポートを提供します。

## ファイル情報

| 項目 | 内容 |
|------|------|
| プロジェクト | CMake テンプレートプロジェクト |
| 作者 | mitsuruk |
| 作成日 | 2025/11/26 |
| ライセンス | MIT License |

---

## インクルードガード

```cmake
include_guard(GLOBAL)
```

このファイルは `include_guard(GLOBAL)` を使用して、複数回インクルードされても一度だけ実行されるようにしています。

**必要な理由：**

- `target_include_directories` の重複呼び出しを防止
- `CMAKE_PREFIX_PATH` への重複追加を防止
- 設定メッセージの重複出力を回避

---

## 機能の詳細

### 1. デフォルトの macOS フレームワークパスの表示

```cmake
message(STATUS "Default macOS Framework Paths:")
message(STATUS "  /System/Library/Frameworks")
message(STATUS "  /Library/Frameworks")
```

macOS 上のデフォルトのフレームワーク検索パスを表示します。デバッグおよび情報提供の目的で使用されます。

---

### 2. Homebrew の検出と設定

#### 2.1 brew コマンドの検索

```cmake
find_program(BREW_COMMAND brew)
```

システム上に `brew` コマンドが存在するかどうかを確認します。

#### 2.2 Homebrew ディレクトリの取得と設定

```cmake
execute_process(COMMAND brew --prefix OUTPUT_VARIABLE BREW_DIR ERROR_QUIET)
string(STRIP "${BREW_DIR}" BREW_DIR)
```

`brew --prefix` コマンドを実行して Homebrew のインストールディレクトリを取得します。

#### 2.3 パスの設定

Homebrew が見つかった場合、以下の設定が適用されます：

| 設定 | 説明 |
|------|------|
| `CMAKE_PREFIX_PATH` | Homebrew ディレクトリを追加 |
| `target_include_directories` | `${BREW_DIR}/include` を追加（存在する場合） |
| `CMAKE_PREFIX_PATH` | `${BREW_DIR}/lib` をパスに追加（存在する場合） |

#### 2.4 エラー処理

- Homebrew は見つかったが `brew --prefix` が失敗した場合：警告を表示
- Homebrew が見つからない場合：システムデフォルトが使用されることを通知

---

### 3. Metal C++ サポート

```cmake
if(IS_DIRECTORY /usr/local/include/metal-cpp)
    target_include_directories(${PROJECT_NAME} PRIVATE
        /usr/local/include/metal-cpp
        /usr/local/include/metal-cpp-extensions)
endif()
```

`/usr/local/include/metal-cpp` に Metal C++ ヘッダーが存在する場合、インクルードディレクトリに追加します。これにより C++ から Apple Metal を直接使用できるようになります。

---

## 依存関係

| 依存先 | 必須/任意 | 説明 |
|--------|-----------|------|
| `${PROJECT_NAME}` | 必須 | メインプロジェクトのターゲット名（事前に定義が必要） |
| Homebrew | 任意 | インストールされている場合のみ設定が適用される |
| Metal C++ | 任意 | ヘッダーが存在する場合のみ有効 |

---

## 使い方

メインの `CMakeLists.txt` から以下のようにインクルードします：

```cmake
if(APPLE)
    include(cmake/apple.cmake)
endif()
```

---

## 注意事項

1. **ターゲット定義の順序**：このファイルをインクルードする前に `${PROJECT_NAME}` ターゲットを定義する必要があります。

2. **プラットフォームの制限**：このファイルは macOS 専用です。他のプラットフォームでは使用しないでください。

3. **link_directories の回避**：`link_directories` の代わりに `CMAKE_PREFIX_PATH` を使用しています。これは CMake のモダンなベストプラクティスに従っています。
