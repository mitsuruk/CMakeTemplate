# llama.cmake リファレンス

## 概要

`llama.cmake` は llama.cpp ライブラリの自動ダウンロード、ビルド、リンクを行う CMake 設定ファイルです。
CMake の `FetchContent` モジュールを使用して依存関係を管理し、プラットフォームに応じた GPU アクセラレーション（Metal/CUDA）を自動的に設定します。

## ファイル情報

| 項目 | 詳細 |
|------|------|
| ダウンロードディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/llama` |
| リポジトリ | https://github.com/ggerganov/llama.cpp |

---

## インクルードガード

```cmake
include_guard(GLOBAL)
```

このファイルは `include_guard(GLOBAL)` を使用して、複数回インクルードされても一度だけ実行されるようにしています。

**必要な理由：**

- `FetchContent_MakeAvailable(llama)` の重複呼び出しエラーを防止
- `target_link_libraries` での重複リンクを防止
- ビルドオプション設定の重複を回避

---

## ディレクトリ構造

```
├── cmake/
│   └── llama.cmake     # この設定ファイル
├── download/
│   └── llama/          # llama.cpp ライブラリ（GitHub: ggerganov/llama.cpp）
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## 使い方

### 基本的なビルド

```bash
mkdir build && cd build
cmake ..
make
```

GPU アクセラレーションは自動検出されます：
- macOS：Metal が自動的に有効化
- Linux/Windows：CUDA が検出された場合に有効化

---

## 処理の流れ

### 1. ダウンロードディレクトリの設定

```cmake
set(LLAMA_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(LLAMA_SOURCE_DIR ${LLAMA_DOWNLOAD_DIR}/llama)
set(FETCHCONTENT_BASE_DIR ${LLAMA_DOWNLOAD_DIR})
```

- ソースコードを `download/llama/` にダウンロード
- `FETCHCONTENT_BASE_DIR` を設定してダウンロード場所を統一

### 2. FetchContent による llama.cpp の宣言

```cmake
FetchContent_Declare(
    llama
    GIT_REPOSITORY https://github.com/ggerganov/llama.cpp.git
    GIT_SHALLOW TRUE
    SOURCE_DIR ${LLAMA_SOURCE_DIR}
)
```

- `GIT_SHALLOW TRUE`：最新のコミットのみを取得（高速化）
- `SOURCE_DIR`：ダウンロード先を明示的に指定

### 3. ビルドオプションの設定

```cmake
set(LLAMA_BUILD_COMMON ON CACHE BOOL "Build llama.cpp common library" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "Build llama.cpp examples" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "Build llama.cpp tests" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "Build llama.cpp server" FORCE)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build shared libraries" FORCE)
```

| オプション | 値 | 説明 |
|-----------|-----|------|
| `LLAMA_BUILD_COMMON` | ON | common ライブラリ（ユーティリティ関数）をビルド |
| `LLAMA_BUILD_EXAMPLES` | OFF | サンプルプログラムをビルドしない |
| `LLAMA_BUILD_TESTS` | OFF | テストをビルドしない |
| `LLAMA_BUILD_SERVER` | OFF | サーバーをビルドしない |
| `BUILD_SHARED_LIBS` | OFF | 静的ライブラリとしてビルド |

### 4. GPU アクセラレーションの自動設定

```cmake
if(APPLE)
    set(GGML_METAL ON CACHE BOOL "Enable Metal" FORCE)
    set(GGML_METAL_EMBED_LIBRARY ON CACHE BOOL "Embed Metal library" FORCE)
else()
    find_package(CUDAToolkit QUIET)
    if(CUDAToolkit_FOUND)
        set(GGML_CUDA ON CACHE BOOL "Enable CUDA" FORCE)
    endif()
endif()
```

| プラットフォーム | バックエンド | 条件 |
|----------------|------------|------|
| macOS | Metal | 自動的に有効化 |
| Linux/Windows | CUDA | CUDAToolkit が検出された場合 |
| その他 | CPU | GPU バックエンドが見つからない場合 |

**Metal オプション：**
- `GGML_METAL`：Metal API を有効化
- `GGML_METAL_EMBED_LIBRARY`：Metal シェーダーを実行ファイルに埋め込み

### 5. ダウンロードとビルド

```cmake
FetchContent_MakeAvailable(llama)
```

- ソースコードをダウンロード
- 自動的に `add_subdirectory()` を実行
- ライブラリをビルド

### 6. インクルードディレクトリの設定

```cmake
target_include_directories(${PROJECT_NAME} PRIVATE
    ${LLAMA_SOURCE_DIR}/include
    ${LLAMA_SOURCE_DIR}/ggml/include
    ${LLAMA_SOURCE_DIR}/common
)
```

| ディレクトリ | 内容 |
|------------|------|
| `include/` | llama.cpp のメインヘッダー |
| `ggml/include/` | ggml（テンソル計算ライブラリ）のヘッダー |
| `common/` | ユーティリティ関数のヘッダー |

### 7. ライブラリのリンク

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE
    llama
    ggml
    common
)
```

| ライブラリ | 説明 |
|----------|------|
| `llama` | コア LLM 推論エンジン |
| `ggml` | テンソル計算と量子化ライブラリ |
| `common` | サンプリング、トークナイザーなどのユーティリティ |

---

## リンクされるライブラリ

### llama

コア LLM 推論機能を提供：
- モデルのロード/アンロード
- コンテキスト管理
- トークン生成（推論）
- KV キャッシュ管理

### ggml

低レベルのテンソル計算ライブラリ：
- 量子化（Q4_0, Q4_1, Q8_0 など）
- 最適化された行列演算
- Metal/CUDA バックエンド

### common

ユーティリティ関数：
- サンプリング戦略（temperature, top-p, top-k）
- ログ管理
- コマンドライン引数パーサー

---

## C++ での使用例

```cpp
#include "llama.h"
#include "common.h"

int main() {
    // バックエンドの初期化
    llama_backend_init();

    // モデルパラメータの設定
    llama_model_params model_params = llama_model_default_params();
    model_params.n_gpu_layers = 99; // 全レイヤーを GPU にオフロード

    // モデルのロード
    llama_model* model = llama_model_load_from_file("model.gguf", model_params);
    if (!model) {
        return 1;
    }

    // コンテキストの作成
    llama_context_params ctx_params = llama_context_default_params();
    ctx_params.n_ctx = 2048;
    llama_context* ctx = llama_init_from_model(model, ctx_params);

    // ... 推論処理 ...

    // クリーンアップ
    llama_free(ctx);
    llama_model_free(model);
    llama_backend_free();

    return 0;
}
```

---

## ビルドオプションのカスタマイズ

### GPU レイヤー数の指定

CMakeLists.txt で追加設定が可能です：

```cmake
# CUDA の場合、使用する GPU を指定
set(GGML_CUDA_DEVICE_ID 0 CACHE STRING "CUDA device ID" FORCE)

# Metal の場合、GPU メモリ制限
set(GGML_METAL_MAX_MEMORY_MB 4096 CACHE STRING "Metal max memory" FORCE)
```

### CPU 最適化

```cmake
# AVX2 を有効化（x86_64）
set(GGML_AVX2 ON CACHE BOOL "Enable AVX2" FORCE)

# ARM NEON を有効化（Apple Silicon/ARM）
set(GGML_NEON ON CACHE BOOL "Enable NEON" FORCE)
```

---

## トラブルシューティング

### Metal シェーダーが見つからない

```
Metal shader not found
```

`GGML_METAL_EMBED_LIBRARY` が有効になっていることを確認してください。
このオプションはデフォルトで有効です。

### CUDA が検出されない

```
-- llama.cmake: No GPU backend found, using CPU only
```

CUDAToolkit がインストールされていることを確認してください：
```bash
nvcc --version
```

CMake に CUDA パスを指定してください：
```bash
cmake -DCMAKE_CUDA_COMPILER=/usr/local/cuda/bin/nvcc ..
```

### ビルドエラー：common ライブラリが見つからない

`LLAMA_BUILD_COMMON` が `ON` に設定されていることを確認してください。

### メモリ不足エラー

大きなモデルをロードする場合は、`n_gpu_layers` を減らして CPU と GPU 間でレイヤーを分散してください。

---

## 参考資料

- [llama.cpp GitHub](https://github.com/ggerganov/llama.cpp)
- [llama.cpp Wiki](https://github.com/ggerganov/llama.cpp/wiki)
- [ggml GitHub](https://github.com/ggerganov/ggml)
- [CMake FetchContent ドキュメント](https://cmake.org/cmake/help/latest/module/FetchContent.html)
