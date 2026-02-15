# dlib.cmake ドキュメント

## 概要

`dlib.cmake` は dlib ライブラリと事前学習モデルの自動ダウンロード、ビルド、リンクを行う CMake 設定ファイルです。
CMake の `FetchContent` モジュールを使用して依存関係を管理します。

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

- `add_subdirectory(dlib)` の重複呼び出しエラーを防止
- FetchContent 処理の重複実行を回避
- `target_link_libraries` による重複リンクを防止
- モデルファイルの重複展開を回避

---

## ディレクトリ構造

```text
Basic/
├── cmake/
│   └── dlib.cmake      # この設定ファイル
├── download/
│   ├── dlib/           # dlib ライブラリ本体（GitHub: davisking/dlib）
│   └── dlib-models/    # 事前学習モデル（GitHub: davisking/dlib-models）
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## 使い方

### 基本的なビルド（モデルなし）

```bash
cd build
cmake ..
make
```

### 事前学習モデル付きビルド

```bash
cd build
cmake -DDLIB_DOWNLOAD_MODELS=ON ..
make
```

## CMake オプション

| オプション | デフォルト | 説明 |
|----------|---------|------|
| `DLIB_DOWNLOAD_MODELS` | OFF | 事前学習モデルのダウンロードと展開 |

## 処理の流れ

### 1. dlib ライブラリのダウンロード（FetchContent）

```cmake
include(FetchContent)

FetchContent_Declare(
    dlib
    GIT_REPOSITORY https://github.com/davisking/dlib.git
    GIT_TAG        master
    GIT_SHALLOW    TRUE
    SOURCE_DIR     ${DLIB_DIR}
)

FetchContent_GetProperties(dlib)
if(NOT dlib_POPULATED)
    FetchContent_Populate(dlib)
endif()
```

- `FetchContent` モジュールを使用して GitHub から自動ダウンロード
- `GIT_SHALLOW TRUE`：最新のコミットのみを取得（高速ダウンロード）
- `SOURCE_DIR`：ダウンロード先を `download/dlib/` に指定
- ダウンロード済みの場合はスキップ

### 2. 事前学習モデルのダウンロード

`-DDLIB_DOWNLOAD_MODELS=ON` を指定した場合のみ実行されます：

```cmake
FetchContent_Declare(
    dlib-models
    GIT_REPOSITORY https://github.com/davisking/dlib-models.git
    GIT_TAG        master
    GIT_SHALLOW    TRUE
    SOURCE_DIR     ${DLIB_MODELS_DIR}
)

FetchContent_GetProperties(dlib-models)
if(NOT dlib-models_POPULATED)
    FetchContent_Populate(dlib-models)
endif()
```

### 3. モデルファイルの展開

ダウンロードされた `.bz2` ファイルは `bunzip2` で展開されます：

```cmake
foreach(MODEL_FILE ${DLIB_MODEL_FILES})
    if(EXISTS ${MODEL_PATH} AND NOT EXISTS ${EXTRACTED_PATH})
        execute_process(
            COMMAND ${BUNZIP2_EXECUTABLE} -k ${MODEL_PATH}
            ...
        )
    endif()
endforeach()
```

- `-k` オプションで元の `.bz2` ファイルを保持
- 展開済みのファイルはスキップ

### 4. dlib ライブラリのビルド設定

```cmake
# X11/GUI サポートを無効化
set(DLIB_NO_GUI_SUPPORT ON CACHE BOOL "Disable dlib GUI support" FORCE)

# dlib をサブディレクトリとして追加
add_subdirectory(${dlib_SOURCE_DIR}/dlib dlib_build)

# プロジェクトにリンク
target_link_libraries(${PROJECT_NAME} PRIVATE dlib::dlib)
```

### 5. モデルパスのコンパイル定義

```cmake
if(DLIB_DOWNLOAD_MODELS AND EXISTS ${DLIB_MODELS_DIR})
    target_compile_definitions(${PROJECT_NAME} PRIVATE
        DLIB_MODELS_PATH="${DLIB_MODELS_DIR}"
    )
endif()
```

モデルディレクトリは `DLIB_MODELS_PATH` マクロを通じて C++ コードから参照できます。

## FetchContent について

### 利点

- **CMake ネイティブ**：外部ツールへの依存が最小限
- **キャッシュ**：再ビルド時に効率的
- **依存関係管理**：CMake の標準的な方法で依存関係を管理
- **可搬性**：異なる環境間で一貫した動作が期待される

### 主要な関数

| 関数 | 説明 |
|------|------|
| `FetchContent_Declare()` | ダウンロードソースを宣言 |
| `FetchContent_GetProperties()` | ダウンロード状態を取得 |
| `FetchContent_Populate()` | 実際のダウンロードを実行 |
| `FetchContent_MakeAvailable()` | Populate + add_subdirectory（ここでは未使用） |

### 重要な注意

- `GIT_REPOSITORY` を使用する場合、システムに Git がインストールされている必要があります
- `SOURCE_DIR` を指定しない場合、ファイルは `_deps/<name>-src` にダウンロードされます

## 利用可能な事前学習モデル

### 顔認識

| ファイル名 | 説明 |
|----------|------|
| `dlib_face_recognition_resnet_model_v1.dat` | ResNet ベースの顔認識（128 次元特徴ベクトル） |
| `face_recognition_densenet_model_v1.dat` | DenseNet ベースの顔認識（軽量版） |
| `taguchi_face_recognition_resnet_model_v1.dat` | アジア人の顔に最適化された顔認識 |

### 顔検出とランドマーク

| ファイル名 | 説明 |
|----------|------|
| `mmod_human_face_detector.dat` | CNN 顔検出器 |
| `shape_predictor_5_face_landmarks.dat` | 5 点ランドマーク（軽量版） |
| `shape_predictor_68_face_landmarks.dat` | 68 点ランドマーク（標準） |
| `shape_predictor_68_face_landmarks_GTX.dat` | 68 点ランドマーク（高精度版） |

### 車両検出

| ファイル名 | 説明 |
|----------|------|
| `mmod_rear_end_vehicle_detector.dat` | 車両後部検出 |
| `mmod_front_and_rear_end_vehicle_detector.dat` | 車両前後部検出 |

### 画像分類

| ファイル名 | 説明 |
|----------|------|
| `resnet34_1000_imagenet_classifier.dnn` | ResNet34 ImageNet 分類器 |
| `resnet50_1000_imagenet_classifier.dnn` | ResNet50 ImageNet 分類器 |
| `resnet34_stable_imagenet_1k.dat` | ResNet34 安定版 |
| `vit-s-16_stable_imagenet_1k.dat` | Vision Transformer（ViT-S-16） |

### その他

| ファイル名 | 説明 |
|----------|------|
| `mmod_dog_hipsterizer.dat` | 犬検出 |
| `dnn_gender_classifier_v1.dat` | 性別推定 |
| `dnn_age_predictor_v1.dat` | 年齢推定 |
| `dcgan_162x162_synth_faces.dnn` | 顔画像生成（DCGAN） |
| `res50_self_supervised_cifar_10.dat` | 自己教師あり学習 |
| `highres_colorify.dnn` | 画像カラー化 |

## C++ コードでのモデル使用例

```cpp
#include <dlib/dnn.h>
#include <dlib/image_processing/frontal_face_detector.h>
#include <dlib/image_processing.h>

int main() {
#ifdef DLIB_MODELS_PATH
    // モデルパスの構築
    std::string models_dir = DLIB_MODELS_PATH;

    // 顔ランドマーク検出器のロード
    dlib::shape_predictor sp;
    dlib::deserialize(models_dir + "/shape_predictor_68_face_landmarks.dat") >> sp;

    // 顔認識モデルのロード
    // ...
#else
    #error "DLIB_MODELS_PATH is not defined. Build with -DDLIB_DOWNLOAD_MODELS=ON"
#endif
    return 0;
}
```

## ビルドオプションの詳細

### DLIB_NO_GUI_SUPPORT

```cmake
set(DLIB_NO_GUI_SUPPORT ON CACHE BOOL "Disable dlib GUI support" FORCE)
```

- X11/X Window System サポートを無効化
- サーバー環境や GUI のないヘッドレス環境向け
- リンクするライブラリ数を削減

## トラブルシューティング

### bunzip2 が見つからない

```text
-- WARNING: bunzip2 not found. Cannot extract model files.
```

macOS の場合：
```bash
brew install bzip2
```

### Git が見つからない

```text
-- Could not find Git
```

FetchContent で `GIT_REPOSITORY` を使用する場合、Git が必要です。
Git をインストールしてください。

### モデルのダウンロードが遅い

`dlib-models` リポジトリは大きい（数 GB）ため、ダウンロードに時間がかかります。
安定したネットワーク接続で実行してください。

### FetchContent が失敗する

CMake のバージョンが古い可能性があります。CMake 3.11 以上が必要です。

```bash
cmake --version
```

## 参考リンク

- [dlib 公式サイト](http://dlib.net/)
- [dlib GitHub](https://github.com/davisking/dlib)
- [dlib-models GitHub](https://github.com/davisking/dlib-models)
- [dlib 公式モデルファイル](http://dlib.net/files/)
- [CMake FetchContent ドキュメント](https://cmake.org/cmake/help/latest/module/FetchContent.html)
