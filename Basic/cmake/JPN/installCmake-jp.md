# install.cmake ドキュメント

## 概要

`install.cmake` は CMake の `install()` コマンドを使用したインストール設定のリファレンスファイルです。ヘッダーファイル、ドキュメント、実行ファイルなどのインストール用テンプレートを提供します。

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

- `install()` コマンドの重複実行を防止
- 将来、実際に使用するためにコメントアウトを外す際の安全性を確保
- インストールルールの重複登録を回避

---

## 備考

このファイルはテンプレート/リファレンスであり、すべてのコマンドがコメントアウトされています。使用する場合は必要な部分のコメントアウトを外してください。

---

## インストールパターン

### 1. ヘッダーファイルのインストール（ディレクトリ単位）

```cmake
install(DIRECTORY ${CMAKE_SOURCE_DIR}/src/include/mklib/
    DESTINATION /usr/local/include/mklib
    FILES_MATCHING
    PATTERN "*.h"
    PATTERN "*.hpp"
)
```

| パラメータ | 説明 |
|----------|------|
| `DIRECTORY` | ソースディレクトリ（末尾の `/` に注意） |
| `DESTINATION` | インストール先ディレクトリ |
| `FILES_MATCHING` | パターンに一致するファイルのみ |
| `PATTERN "*.h"` | `.h` ファイルが対象 |
| `PATTERN "*.hpp"` | `.hpp` ファイルも対象 |

**末尾の `/` の意味：**
- `src/include/mklib/` -- `mklib` の **中身** をコピー
- `src/include/mklib` -- `mklib` ディレクトリ **自体** をコピー

---

### 2. 特定ファイルのインストール

```cmake
# ファイルをリストに収集
file(GLOB DOC_FILES ${CMAKE_SOURCE_DIR}/src/*.md)

# 指定ディレクトリにインストール
install(FILES ${DOC_FILES} DESTINATION /usr/local/include/mklib)
```

| パラメータ | 説明 |
|----------|------|
| `FILES` | インストールするファイルのリスト |
| `DESTINATION` | インストール先ディレクトリ |

---

### 3. 実行ファイルのインストール

#### 3.1 デフォルト（/usr/local/bin）

```cmake
install(TARGETS ${PROJECT_NAME})
```

`CMAKE_INSTALL_PREFIX`（デフォルト：`/usr/local`）配下の `bin` ディレクトリにインストールします。

#### 3.2 カスタムディレクトリ

```cmake
install(TARGETS ${PROJECT_NAME} DESTINATION ${PROJECT_SOURCE_DIR}/install)
```

プロジェクトソースディレクトリ内の `install` ディレクトリにインストールします。

#### 3.3 プレフィックスの指定

```cmake
set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/install)
install(TARGETS ${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_PREFIX})
```

インストールプレフィックス全体を変更します。

---

### 4. インクルードディレクトリのインストール

```cmake
install(DIRECTORY ${CMAKE_SOURCE_DIR}/src/include/
    DESTINATION include
    FILES_MATCHING PATTERN "*.h*"
)
```

`.h` および `.hpp` ファイル（`.h*` パターンで一致）をすべて `include` ディレクトリにインストールします。

---

## インストールの実行方法

### ビルドとインストール

```bash
# ビルドディレクトリ内で
cmake --build . --target install

# または
make install

# 管理者権限が必要な場合
sudo make install
```

### インストールプレフィックスの指定

```bash
# 構成時に指定
cmake -DCMAKE_INSTALL_PREFIX=/custom/path ..

# またはインストール時に指定
cmake --install . --prefix /custom/path
```

---

## CMake 変数

| 変数 | 説明 | デフォルト値 |
|------|------|-----------|
| `CMAKE_INSTALL_PREFIX` | インストール先のルート | `/usr/local`（Unix） |
| `CMAKE_SOURCE_DIR` | トップレベルのソースディレクトリ | - |
| `CMAKE_CURRENT_SOURCE_DIR` | 現在の CMakeLists.txt のディレクトリ | - |
| `PROJECT_SOURCE_DIR` | 最も近い `project()` のソースディレクトリ | - |

---

## デフォルトのインストール先

| ターゲットタイプ | デフォルトパス |
|--------------|-------------|
| 実行ファイル | `${CMAKE_INSTALL_PREFIX}/bin` |
| ライブラリ | `${CMAKE_INSTALL_PREFIX}/lib` |
| ヘッダー | `${CMAKE_INSTALL_PREFIX}/include` |

---

## 使い方

1. 必要なインストールコマンドのコメントアウトを外す
2. 実際のプロジェクト構造に合わせてパスを調整
3. メインの `CMakeLists.txt` からインクルード：

```cmake
include(cmake/install.cmake)
```

---

## 注意事項

1. **権限**：`/usr/local` へのインストールには通常 `sudo` が必要です。

2. **相対 DESTINATION パス**：`DESTINATION` に相対パスを指定した場合、`CMAKE_INSTALL_PREFIX` からの相対パスになります。

3. **末尾のスラッシュ**：`DIRECTORY` の末尾の `/` はコピー動作に影響します（上記参照）。

4. **install_manifest.txt**：`make install` を実行すると、ビルドディレクトリに `install_manifest.txt` が生成されます。これはアンインストールに使用できます。

5. **重複コード**：このファイルには意図的に重複したコメントアウトコードが含まれています。使用する際は必要な部分のみ有効にしてください。
