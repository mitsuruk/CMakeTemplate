# CodeGenerators.cmake リファレンス

## 概要

`CodeGenerators.cmake` は外部コード生成ツールを CMake プロジェクトに統合するための設定ファイルです。以下の 3 つのコード生成システムをサポートします：

1. **Flex & Bison** - 字句解析と構文解析
2. **gRPC & Protocol Buffers** - RPC インターフェース
3. **ANTLR** - 文法ベースのパーサー

## ファイル情報

| 項目 | 詳細 |
|------|------|
| プロジェクト | CMake テンプレートプロジェクト |
| 作者 | mitsuruk |
| 作成日 | 2025/11/26 |
| ライセンス | MIT License |

---

## 全体構造

```cmake
include_guard(GLOBAL)  # 重複インクルードの防止

# 1. Flex & Bison 統合（grammar ディレクトリが存在する場合）
# 2. gRPC & Protocol Buffers 統合（protos ディレクトリが存在する場合）
# 3. ANTLR 統合（antlr ディレクトリが存在する場合）
```

各セクションは対応するディレクトリが存在する場合にのみ実行されます。

---

## 1. Flex & Bison 統合

### 有効化条件

```cmake
if(EXISTS "${PROJECT_SOURCE_DIR}/grammar")
```

`grammar` ディレクトリが存在する場合に有効化されます。

### 処理の流れ

```
1. Flex/Bison パッケージの検索
2. *.y ファイル（Bison 文法）の検索と処理
3. *.l ファイル（Flex レキサー）の検索と処理
4. 生成されたソースをプロジェクトに追加
```

### Bison ファイルの処理

```cmake
file(GLOB BISON_SOURCES "${PROJECT_SOURCE_DIR}/grammar/*.y")
foreach(bison_file ${BISON_SOURCES})
    get_filename_component(bison_name ${bison_file} NAME_WE)
    BISON_TARGET(${bison_name} ${bison_file}
        ${PROJECT_BINARY_DIR}/${bison_name}.tab.c
        DEFINES_FILE ${PROJECT_BINARY_DIR}/${bison_name}.tab.h)
    list(APPEND GENERATED_YACC_LEX ${BISON_${bison_name}_OUTPUTS})
endforeach()
```

| 入力 | 出力 |
|------|------|
| `grammar/parser.y` | `parser.tab.c`, `parser.tab.h` |

### Flex ファイルの処理

```cmake
file(GLOB FLEX_SOURCES "${PROJECT_SOURCE_DIR}/grammar/*.l")
foreach(flex_file ${FLEX_SOURCES})
    get_filename_component(flex_name ${flex_file} NAME_WE)
    FLEX_TARGET(${flex_name} ${flex_file}
        ${PROJECT_BINARY_DIR}/${flex_name}.yy.c)
    list(APPEND GENERATED_YACC_LEX ${FLEX_${flex_name}_OUTPUTS})
endforeach()
```

| 入力 | 出力 |
|------|------|
| `grammar/lexer.l` | `lexer.yy.c` |

### ディレクトリ構造

```
project/
├── grammar/
│   ├── parser.y    # Bison 文法ファイル
│   └── lexer.l     # Flex レキサーファイル
└── CMakeLists.txt
```

---

## 2. gRPC & Protocol Buffers 統合

### 有効化条件

```cmake
if(EXISTS "${PROJECT_SOURCE_DIR}/protos")
```

`protos` ディレクトリが存在する場合に有効化されます。

### 処理の流れ

```
1. Protobuf/gRPC パッケージの検索
2. *.proto ファイルの検索
3. 各 .proto ファイルから C++ コードを生成
4. 静的ライブラリの作成
5. メインプロジェクトへのリンク
```

### 生成されるファイル

各 `.proto` ファイルから以下が生成されます：

| 生成ファイル | 説明 |
|------------|------|
| `{name}.pb.cc` | Protobuf メッセージ実装 |
| `{name}.pb.h` | Protobuf メッセージヘッダー |
| `{name}.grpc.pb.cc` | gRPC サービス実装 |
| `{name}.grpc.pb.h` | gRPC サービスヘッダー |

### カスタムコマンド

```cmake
add_custom_command(
    OUTPUT "${proto_src}" "${proto_hdr}" "${grpc_src}" "${grpc_hdr}"
    COMMAND ${_PROTOBUF_PROTOC}
    ARGS --proto_path="${PROJECT_SOURCE_DIR}/protos"
         --cpp_out="${CMAKE_CURRENT_BINARY_DIR}"
         --grpc_out="${CMAKE_CURRENT_BINARY_DIR}"
         --plugin=protoc-gen-grpc="${_GRPC_CPP_PLUGIN_EXECUTABLE}"
         "${proto_file}"
    DEPENDS "${proto_file}"
)
```

### 生成されるライブラリ

```cmake
set(PRJ_PROTO "${DIR_NAME}_grpc_proto")
add_library(${PRJ_PROTO} ${GENERATED_GRPC_SRCS} ${GENERATED_GRPC_HDRS})
```

ライブラリ名：`{DIR_NAME}_grpc_proto`

### ディレクトリ構造

```
project/
├── protos/
│   ├── service.proto
│   └── messages.proto
└── CMakeLists.txt
```

---

## 3. ANTLR 統合

### 有効化条件

```cmake
if(EXISTS "${PROJECT_SOURCE_DIR}/antlr")
```

`antlr` ディレクトリが存在する場合に有効化されます。

### 処理の流れ

```
1. C++17 標準の設定
2. ANTLR ツールの検索
3. antlr4-runtime パッケージの検索
4. *.g4 文法ファイルの検索と処理
5. 静的ライブラリの作成
6. メインプロジェクトへのリンク
```

### 生成されるファイル

各 `.g4` ファイルから以下が生成されます：

| 生成ファイル | 説明 |
|------------|------|
| `{name}Parser.cpp` | パーサー実装 |
| `{name}Parser.h` | パーサーヘッダー |
| `{name}Lexer.cpp` | レキサー実装 |
| `{name}Lexer.h` | レキサーヘッダー |
| `{name}Listener.h` | リスナーインターフェース |
| `{name}Visitor.h` | ビジターインターフェース |

### カスタムコマンド

```cmake
add_custom_command(
    OUTPUT "${parser_cpp}" "${parser_h}" "${lexer_cpp}" "${lexer_h}"
           "${listener_h}" "${visitor_h}"
    COMMAND ${ANTLR4_EXECUTABLE}
    ARGS -Dlanguage=Cpp
         -o "${CMAKE_CURRENT_BINARY_DIR}"
         "${grammar_file}"
    DEPENDS "${grammar_file}"
    COMMENT "Generating ANTLR4 C++ files from ${grammar_file}"
    VERBATIM
)
```

### Homebrew サポート

```cmake
find_program(BREW_COMMAND brew)
if(BREW_COMMAND)
    # Homebrew の ANTLR ランタイムパスを追加
    target_include_directories(${PRJ_ANTLR} PUBLIC
        ${BREW_DIR}/include/antlr4-runtime)
endif()
```

macOS で Homebrew を使用している場合、ANTLR ランタイムパスが自動的に追加されます。

### ディレクトリ構造

```
project/
├── antlr/
│   ├── MyGrammar.g4
│   └── AnotherGrammar.g4
└── CMakeLists.txt
```

---

## 依存関係

### Flex & Bison

| 依存先 | 必須/任意 |
|--------|-----------|
| Flex | 必須 |
| Bison | 必須 |

### gRPC & Protocol Buffers

| 依存先 | 必須/任意 |
|--------|-----------|
| Protobuf | 必須 |
| gRPC | 必須 |
| `${DIR_NAME}` | 必須（ライブラリ名に使用） |

### ANTLR

| 依存先 | 必須/任意 |
|--------|-----------|
| ANTLR4 ツール（`antlr` コマンド） | 必須 |
| antlr4-runtime | 必須 |

---

## 使い方

1. 必要なディレクトリを作成：
   - Flex/Bison：`grammar/`
   - gRPC：`protos/`
   - ANTLR：`antlr/`

2. ディレクトリにソースファイルを配置

3. メインの `CMakeLists.txt` からインクルード：

```cmake
include(cmake/CodeGenerators.cmake)
```

---

## 注意事項

1. **include_guard**：`include_guard(GLOBAL)` により、複数回インクルードされても一度だけ実行されます。

2. **条件付き実行**：各コード生成ツールは対応するディレクトリが存在する場合にのみ有効化されます。不要なツールの依存関係エラーを回避できます。

3. **生成ファイルの場所**：すべての生成ファイルは `${CMAKE_CURRENT_BINARY_DIR}`（ビルドディレクトリ）に出力されます。

4. **C++17 の要件**：ANTLR セクションは C++17 を必要とします。プロジェクト全体に影響する可能性があります。

5. **ターゲット定義の順序**：このファイルをインクルードする前に `${PROJECT_NAME}` ターゲットを定義する必要があります。
