# packageInstall.cmake リファレンス

## 概要

`packageInstall.cmake` は、プロジェクトを CMake パッケージとしてインストールするための設定ファイルです。他の CMake プロジェクトから `find_package()` を使用してインポートできる形式でライブラリをエクスポートします。

## ファイル情報

| 項目 | 詳細 |
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

- `install(TARGETS ...)` の重複によるエラーを防止
- `install(EXPORT ...)` の重複登録を防止
- パッケージ設定ファイルの重複生成を回避
- ターゲット検出ロジックの重複実行を防止

---

## 処理の流れ

```
1. パッケージ名とバージョンの設定
2. バリデーション
3. インクルードディレクトリの設定
4. バージョンファイルの生成
5. 設定ファイルの生成
6. ターゲットの検出とインストール
7. エクスポートファイルの生成
8. 設定ファイルのインストール
```

---

## 機能の詳細

### 1. パッケージ名とバージョンの設定

```cmake
set(PACKAGE_NAME ${PROJECT_NAME})
set(PACKAGE_VERSION 0.0.1)
```

| 変数 | 説明 |
|------|------|
| `PACKAGE_NAME` | パッケージの識別名（デフォルト：プロジェクト名） |
| `PACKAGE_VERSION` | セマンティックバージョニング形式 |

---

### 2. 必須変数のバリデーション

```cmake
if(NOT DEFINED PACKAGE_NAME OR PACKAGE_NAME STREQUAL "")
    message(FATAL_ERROR "PACKAGE_NAME is not set...")
endif()
```

`PACKAGE_NAME` または `PACKAGE_VERSION` が設定されていない場合、エラーでビルドを停止します。

---

### 3. インクルードディレクトリの設定

```cmake
if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src/include)
    target_include_directories(${PROJECT_NAME} PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/include>
        $<INSTALL_INTERFACE:include>
    )
endif()
```

| ジェネレータ式 | 説明 |
|--------------|------|
| `$<BUILD_INTERFACE:...>` | ビルド時に使用されるパス |
| `$<INSTALL_INTERFACE:...>` | インストール後に使用されるパス |

ビルド時とインストール後に適切なインクルードパスが使用されるようにします。

---

### 4. バージョンファイルの生成

```cmake
include(CMakePackageConfigHelpers)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}ConfigVersion.cmake
    VERSION ${PACKAGE_VERSION}
    COMPATIBILITY AnyNewerVersion
)
```

| パラメータ | 説明 |
|----------|------|
| `VERSION` | パッケージバージョン |
| `COMPATIBILITY` | バージョン互換性ポリシー |

**互換性オプション：**

| オプション | 説明 |
|----------|------|
| `AnyNewerVersion` | 同一またはより新しいバージョンと互換 |
| `SameMajorVersion` | メジャーバージョンが一致すれば互換 |
| `SameMinorVersion` | マイナーバージョンが一致すれば互換 |
| `ExactVersion` | 完全一致のみ |

---

### 5. 設定ファイルの生成

```cmake
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/cmake)
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/cmake/${PACKAGE_NAME}Config.cmake.in
    "include(\"\${CMAKE_CURRENT_LIST_DIR}/${PACKAGE_NAME}Targets.cmake\")"
)

configure_file(
    ${CMAKE_CURRENT_BINARY_DIR}/cmake/${PACKAGE_NAME}Config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}Config.cmake
    @ONLY
)
```

`@ONLY` オプションは `@VAR@` 形式の置換のみを行い、`${VAR}` 形式の式は保持します。

---

### 6. インストール可能なターゲットの自動検出

```cmake
get_property(ALL_TARGETS DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    PROPERTY BUILDSYSTEM_TARGETS)

foreach(target ${ALL_TARGETS})
    get_target_property(target_type ${target} TYPE)
    if(target_type MATCHES "EXECUTABLE|STATIC_LIBRARY|SHARED_LIBRARY")
        list(APPEND INSTALL_TARGETS ${target})
    endif()
endforeach()
```

以下のターゲットタイプが自動検出されます：

| ターゲットタイプ | 説明 |
|----------------|------|
| `EXECUTABLE` | 実行ファイル |
| `STATIC_LIBRARY` | 静的ライブラリ |
| `SHARED_LIBRARY` | 共有ライブラリ |

---

### 7. ターゲットのインストール

```cmake
install(TARGETS ${INSTALL_TARGETS} EXPORT ${PACKAGE_NAME}Targets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    INCLUDES DESTINATION include
)
```

| コンポーネント | インストール先 | 説明 |
|--------------|--------------|------|
| `LIBRARY` | `lib/` | 共有ライブラリ（.so/.dylib） |
| `ARCHIVE` | `lib/` | 静的ライブラリ（.a） |
| `RUNTIME` | `bin/` | 実行ファイル |
| `INCLUDES` | `include/` | インクルードディレクトリ |

---

### 8. インクルードディレクトリのインストール

```cmake
if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src/include)
    install(DIRECTORY src/include/ DESTINATION include)
endif()
```

`src/include/` ディレクトリの内容を `include/` にインストールします。

---

### 9. エクスポート設定のインストール

```cmake
install(EXPORT ${PACKAGE_NAME}Targets
    FILE ${PACKAGE_NAME}Targets.cmake
    NAMESPACE ${PACKAGE_NAME}::
    DESTINATION lib/cmake/${PACKAGE_NAME}
)
```

| パラメータ | 説明 |
|----------|------|
| `FILE` | エクスポートファイル名 |
| `NAMESPACE` | ターゲットに付与されるプレフィックス |
| `DESTINATION` | インストール先 |

これにより他のプロジェクトから `${PACKAGE_NAME}::${TARGET_NAME}` でリンクできます。

---

### 10. 設定ファイルのインストール

```cmake
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}Config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}ConfigVersion.cmake"
    DESTINATION lib/cmake/${PACKAGE_NAME}
)
```

---

## インストール後のディレクトリ構造

```
${CMAKE_INSTALL_PREFIX}/
├── bin/
│   └── ${PROJECT_NAME}           # 実行ファイル
├── lib/
│   ├── lib${PROJECT_NAME}.a      # 静的ライブラリ
│   └── cmake/${PACKAGE_NAME}/
│       ├── ${PACKAGE_NAME}Config.cmake
│       ├── ${PACKAGE_NAME}ConfigVersion.cmake
│       └── ${PACKAGE_NAME}Targets.cmake
└── include/
    └── （ヘッダーファイル）
```

---

## 他のプロジェクトからの使用

```cmake
find_package(${PACKAGE_NAME} REQUIRED)
target_link_libraries(my_app PRIVATE ${PACKAGE_NAME}::${TARGET_NAME})
```

---

## アンインストール

インストール後、ビルドディレクトリに `install_manifest.txt` が生成されます：

```bash
sudo xargs rm < install_manifest.txt
```

---

## 使い方

メインの `CMakeLists.txt` からインクルード：

```cmake
include(cmake/packageInstall.cmake)
```

---

## 依存関係

| 依存先 | 必須/任意 | 説明 |
|--------|-----------|------|
| `${PROJECT_NAME}` | 必須 | メインプロジェクトのターゲット名 |
| `CMakePackageConfigHelpers` | 必須 | CMake 標準モジュール |

---

## 注意事項

1. **ターゲット定義の順序**：このファイルをインクルードする前にすべてのターゲットを定義する必要があります。

2. **ターゲットなしエラー**：インストール可能なターゲットが見つからない場合、`FATAL_ERROR` でビルドが停止します。

3. **名前空間**：エクスポートされたターゲットには `${PACKAGE_NAME}::` プレフィックスが付与されます。

4. **INTERFACE/OBJECT ライブラリ**：これらのタイプはインストールターゲットから除外されます。

5. **バージョン変更**：`PACKAGE_VERSION` を変更する際は、互換性ポリシーに注意してください。
