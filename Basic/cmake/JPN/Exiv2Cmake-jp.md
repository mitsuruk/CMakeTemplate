# Exiv2.cmake リファレンス

## 概要

`Exiv2.cmake` は Exiv2 ライブラリの自動ダウンロード、ビルド、リンクを行う CMake 設定ファイルです。
初回ビルド時に FetchContent で Exiv2 をサブプロジェクトとしてダウンロード・ビルドし、ビルド済みライブラリを `exiv2-install/` にインストールします。
以降のビルドでは（`build/` ディレクトリを削除しても）、インストール済みライブラリを検出して再利用するため、再コンパイルは発生しません。

Exiv2 は画像メタデータ（Exif、IPTC、XMP、ICC プロファイル）の読み書き・削除・変更を行う C++ ライブラリおよびコマンドラインツールです。JPEG、PNG、TIFF、WebP、CR2、NEF など多数の画像フォーマットに対応しています。

Exiv2 は C++ ライブラリです。メインヘッダー `<exiv2/exiv2.hpp>` で完全な API が提供されます。

## ファイル情報

| 項目 | 詳細 |
|------|------|
| ダウンロードディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/Exiv2` |
| インストールディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/Exiv2/exiv2-install` |
| Git リポジトリ | https://github.com/Exiv2/exiv2.git |
| Git タグ | v0.28.7 |
| バージョン | 0.28.7 |
| ライセンス | GNU GPL v2+ |

---

## インクルードガード

```cmake
include_guard(GLOBAL)
```

このファイルは `include_guard(GLOBAL)` を使用して、複数回インクルードされても一度だけ実行されるようにしています。

**必要な理由：**

- `FetchContent_Declare` / `FetchContent_MakeAvailable` の重複呼び出しを防止
- `target_link_libraries` での重複リンクを防止

---

## ディレクトリ構造

```
Exiv2/
├── cmake/
│   ├── Exiv2.cmake        # この設定ファイル
│   ├── Exiv2Cmake.md      # 英語版ドキュメント
│   └── Exiv2Cmake-jp.md   # このドキュメント
├── download/Exiv2/
│   ├── exiv2-src/          # Exiv2 ソース（git clone、FetchContent によりキャッシュ）
│   ├── exiv2-build/        # Exiv2 CMake ビルドディレクトリ（FetchContent が管理）
│   ├── exiv2-subbuild/     # FetchContent サブビルドディレクトリ
│   └── exiv2-install/      # ビルド済みライブラリキャッシュ（lib/, include/）
│       ├── include/exiv2/  # Exiv2 ヘッダー
│       └── lib/            # libexiv2.dylib / libexiv2.so
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## 使い方

### CMakeLists.txt への追加

```cmake
include("./cmake/Exiv2.cmake")
```

### ビルド

```bash
mkdir build && cd build
cmake ..
make
```

---

## 処理の流れ

### ビルドキャッシュ戦略

`Exiv2.cmake` は不要な再コンパイルを回避するため、2段階のアプローチを採用しています：

| フェーズ | 条件 | アクション |
|---------|------|----------|
| 初回ビルド | `exiv2-install/` が存在しない | FetchContent でダウンロード、ビルド、リンク、インストール |
| 2回目以降 | `exiv2-install/lib/libexiv2.dylib` が存在する | キャッシュされたインストールを直接使用（FetchContent なし、再コンパイルなし） |

これにより、`build/` ディレクトリを削除しても、自分のソースファイルの再コンパイル（約2秒）のみで、Exiv2 ライブラリ全体の再コンパイル（約15秒）は不要になります。

### フェーズ 1：初回ビルド（FetchContent）

```cmake
include(FetchContent)
set(FETCHCONTENT_BASE_DIR ${EXIV2_DOWNLOAD_DIR})

FetchContent_Declare(
    exiv2
    GIT_REPOSITORY https://github.com/Exiv2/exiv2.git
    GIT_TAG        v${EXIV2_VERSION}
    GIT_SHALLOW    TRUE
)
FetchContent_MakeAvailable(exiv2)

target_link_libraries(${PROJECT_NAME} PRIVATE exiv2lib)
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_BINARY_DIR})
```

- `GIT_SHALLOW TRUE`：指定タグの最新コミットのみをクローンし、ダウンロードサイズと時間を大幅に削減
- `FetchContent_MakeAvailable`：ダウンロード（キャッシュがない場合）、設定を行い、`exiv2lib` ターゲットを利用可能にする
- すべての推移的依存関係（zlib、expat、brotli 等）は CMake により `exiv2lib` ターゲットを通じて自動的に解決される
- ビルド完了後、`POST_BUILD` コマンドで Exiv2 を `exiv2-install/` にインストールし、次回以降の使用に備える

### フェーズ 2：キャッシュビルド（IMPORTED ライブラリ）

```cmake
add_library(exiv2lib_cached SHARED IMPORTED)
set_target_properties(exiv2lib_cached PROPERTIES
    IMPORTED_LOCATION ${EXIV2_INSTALLED_LIB}
)
target_include_directories(${PROJECT_NAME} PRIVATE ${EXIV2_INSTALLED_INCLUDE_DIR})

target_link_libraries(${PROJECT_NAME} PRIVATE
    exiv2lib_cached ZLIB::ZLIB EXPAT::EXPAT Iconv::Iconv
)
```

- `exiv2-install/` にあるビルド済みライブラリを `IMPORTED` ターゲットとして直接使用
- システム依存関係（zlib、expat、iconv、brotli、CoreFoundation）を明示的にリンク
- FetchContent は呼び出されないため、`cmake ..` が高速に完了

### ビルドオプション

```cmake
set(EXIV2_ENABLE_XMP    ON  CACHE BOOL "" FORCE)
set(EXIV2_ENABLE_NLS    OFF CACHE BOOL "" FORCE)
set(EXIV2_ENABLE_INIH   OFF CACHE BOOL "" FORCE)
set(EXIV2_BUILD_SAMPLES OFF CACHE BOOL "" FORCE)
set(EXIV2_BUILD_EXIV2_COMMAND OFF CACHE BOOL "" FORCE)
```

- `EXIV2_ENABLE_XMP=ON`：XMP メタデータサポートを有効化
- `EXIV2_ENABLE_NLS=OFF`：国際化を無効化（不要）
- `EXIV2_ENABLE_INIH=OFF`：inih 設定パーサーを無効化（不要）
- `EXIV2_BUILD_SAMPLES=OFF`：サンプルアプリケーションをスキップ
- `EXIV2_BUILD_EXIV2_COMMAND=OFF`：コマンドラインツールをスキップ（ライブラリのみ必要）

---

## Exiv2 ビルドオプション

| オプション | デフォルト | 本プロジェクト | 説明 |
|----------|---------|--------------|------|
| `EXIV2_ENABLE_XMP` | ON | ON | XMP メタデータサポートを有効化 |
| `EXIV2_ENABLE_EXTERNAL_XMP` | OFF | （デフォルト） | バンドル版の代わりに外部 XMP SDK を使用 |
| `EXIV2_ENABLE_NLS` | OFF | OFF | ネイティブ言語サポート（国際化）を有効化 |
| `EXIV2_ENABLE_INIH` | ON | OFF | inih ライブラリ（.ini 設定ファイル）を有効化 |
| `EXIV2_ENABLE_BROTLI` | ON | （デフォルト） | JPEG XL 圧縮ボックス用の Brotli を有効化 |
| `EXIV2_ENABLE_BMFF` | ON | （デフォルト） | BMFF（HEIF、AVIF）サポートを有効化 |
| `EXIV2_BUILD_SAMPLES` | OFF | OFF | サンプルアプリケーションをビルド |
| `EXIV2_BUILD_EXIV2_COMMAND` | ON | OFF | exiv2 コマンドラインツールをビルド |
| `BUILD_SHARED_LIBS` | ON | （デフォルト） | 共有ライブラリをビルド |

---

## Exiv2 の主な機能

| 機能 | ヘッダー | 説明 |
|------|--------|------|
| Exif メタデータ | `exiv2/exif.hpp` | Exif タグの読み書き（カメラ情報、GPS、露出など） |
| IPTC メタデータ | `exiv2/iptc.hpp` | IPTC タグの読み書き（キャプション、キーワード、著作権） |
| XMP メタデータ | `exiv2/xmp_exiv2.hpp` | XMP プロパティの読み書き（Dublin Core など） |
| 画像 I/O | `exiv2/image.hpp` | 画像ファイルのオープン、読み取り、書き込み |
| 型システム | `exiv2/types.hpp` | 有理数、バイトオーダー、データ型 |
| タグ情報 | `exiv2/tags.hpp` | タグ名、説明、型情報 |
| 値の型 | `exiv2/value.hpp` | 型安全な値の表現 |
| エラー処理 | `exiv2/error.hpp` | 例外ベースのエラー処理 |
| バージョン | `exiv2/version.hpp` | ライブラリバージョン情報 |

### 対応画像フォーマット

| フォーマット | 読み取り | 書き込み | 拡張子 |
|------------|---------|---------|--------|
| JPEG | 対応 | 対応 | .jpg, .jpeg |
| TIFF | 対応 | 対応 | .tif, .tiff |
| PNG | 対応 | 対応 | .png |
| WebP | 対応 | 対応 | .webp |
| DNG | 対応 | 対応 | .dng |
| CR2（Canon） | 対応 | 対応 | .cr2 |
| NEF（Nikon） | 対応 | 対応 | .nef |
| ARW（Sony） | 対応 | 対応 | .arw |
| ORF（Olympus） | 対応 | 対応 | .orf |
| RAF（Fuji） | 対応 | 対応 | .raf |
| PEF（Pentax） | 対応 | 対応 | .pef |
| HEIF/HEIC | 対応 | 読み取りのみ | .heif, .heic |
| AVIF | 対応 | 読み取りのみ | .avif |

---

## C++ での使用例

### Exif メタデータの読み取り

```cpp
#include <exiv2/exiv2.hpp>
#include <iostream>

int main() {
    auto image = Exiv2::ImageFactory::open("photo.jpg");
    image->readMetadata();

    Exiv2::ExifData &exifData = image->exifData();
    for (const auto &entry : exifData) {
        std::cout << entry.key() << " = " << entry.value() << "\n";
    }
    return 0;
}
```

### 特定の Exif タグの読み取り

```cpp
#include <exiv2/exiv2.hpp>
#include <iostream>

int main() {
    auto image = Exiv2::ImageFactory::open("photo.jpg");
    image->readMetadata();

    Exiv2::ExifData &exifData = image->exifData();

    auto it = exifData.findKey(Exiv2::ExifKey("Exif.Image.Make"));
    if (it != exifData.end()) {
        std::cout << "カメラ: " << it->value() << "\n";
    }

    it = exifData.findKey(Exiv2::ExifKey("Exif.Photo.FNumber"));
    if (it != exifData.end()) {
        std::cout << "F値: " << it->value() << "\n";
    }

    return 0;
}
```

### Exif メタデータの書き込み

```cpp
#include <exiv2/exiv2.hpp>
#include <iostream>

int main() {
    auto image = Exiv2::ImageFactory::open("photo.jpg");
    image->readMetadata();

    Exiv2::ExifData &exifData = image->exifData();

    // 文字列値の設定
    exifData["Exif.Image.Make"] = "MyCamera";
    exifData["Exif.Image.Model"] = "Model X";
    exifData["Exif.Image.Software"] = "MyApp v1.0";

    // 有理数値の設定（例：露出時間 1/125秒）
    exifData["Exif.Photo.ExposureTime"] = Exiv2::URational(1, 125);
    exifData["Exif.Photo.FNumber"] = Exiv2::URational(28, 10);

    // 整数値の設定
    exifData["Exif.Photo.ISOSpeedRatings"] = uint16_t(800);
    exifData["Exif.Image.ImageWidth"] = uint32_t(4032);
    exifData["Exif.Image.ImageLength"] = uint32_t(3024);

    // 日時の設定
    exifData["Exif.Image.DateTime"] = "2026:01:15 14:30:00";

    image->writeMetadata();
    std::cout << "メタデータの書き込みが完了しました。\n";
    return 0;
}
```

### GPS 座標の書き込み

```cpp
#include <exiv2/exiv2.hpp>
#include <iostream>

int main() {
    auto image = Exiv2::ImageFactory::open("photo.jpg");
    image->readMetadata();

    Exiv2::ExifData &exifData = image->exifData();

    // 東京タワーの GPS 座標（北緯 35.6586度、東経 139.7454度）
    exifData["Exif.GPSInfo.GPSLatitudeRef"] = "N";
    exifData["Exif.GPSInfo.GPSLatitude"] = "35/1 39/1 3096/100";
    exifData["Exif.GPSInfo.GPSLongitudeRef"] = "E";
    exifData["Exif.GPSInfo.GPSLongitude"] = "139/1 44/1 4344/100";

    image->writeMetadata();
    std::cout << "GPS データを書き込みました。\n";
    return 0;
}
```

### IPTC メタデータの読み書き

```cpp
#include <exiv2/exiv2.hpp>
#include <iostream>

int main() {
    auto image = Exiv2::ImageFactory::open("photo.jpg");
    image->readMetadata();

    Exiv2::IptcData &iptcData = image->iptcData();

    // IPTC データの書き込み
    iptcData["Iptc.Application2.Headline"] = "美しい夕焼け";
    iptcData["Iptc.Application2.Caption"] = "海に沈む美しい夕日";
    iptcData["Iptc.Application2.Keywords"] = "sunset";
    iptcData["Iptc.Application2.City"] = "鎌倉";
    iptcData["Iptc.Application2.CountryName"] = "Japan";
    iptcData["Iptc.Application2.Copyright"] = "2026 Photographer";

    image->writeMetadata();

    // IPTC データの読み取り
    image->readMetadata();
    for (const auto &entry : image->iptcData()) {
        std::cout << entry.key() << " = " << entry.value() << "\n";
    }
    return 0;
}
```

### XMP メタデータの読み書き

```cpp
#include <exiv2/exiv2.hpp>
#include <iostream>

int main() {
    Exiv2::XmpParser::initialize();

    auto image = Exiv2::ImageFactory::open("photo.jpg");
    image->readMetadata();

    Exiv2::XmpData &xmpData = image->xmpData();

    // XMP Dublin Core プロパティの書き込み
    xmpData["Xmp.dc.title"] = "私の写真";
    xmpData["Xmp.dc.creator"] = "山田太郎";
    xmpData["Xmp.dc.description"] = "サンプル写真";
    xmpData["Xmp.dc.rights"] = "Creative Commons CC-BY";

    image->writeMetadata();

    // XMP データの読み取り
    image->readMetadata();
    for (const auto &entry : image->xmpData()) {
        std::cout << entry.key() << " [" << entry.typeName()
                  << "] = " << entry.value() << "\n";
    }

    Exiv2::XmpParser::terminate();
    return 0;
}
```

### メタデータの削除

```cpp
#include <exiv2/exiv2.hpp>
#include <iostream>

int main() {
    auto image = Exiv2::ImageFactory::open("photo.jpg");
    image->readMetadata();

    // 特定の Exif キーを削除
    Exiv2::ExifData &exifData = image->exifData();
    auto it = exifData.findKey(Exiv2::ExifKey("Exif.Image.Software"));
    if (it != exifData.end()) {
        exifData.erase(it);
    }

    // すべての IPTC データを削除
    image->iptcData().clear();

    image->writeMetadata();
    std::cout << "メタデータを削除しました。\n";
    return 0;
}
```

---

## Exiv2 API の規約

### 画像のオープン

すべてのメタデータ操作は画像ファイルのオープンから始まります：

```cpp
auto image = Exiv2::ImageFactory::open("photo.jpg");
image->readMetadata();
```

`ImageFactory::open()` は `std::unique_ptr<Exiv2::Image>` を返します。

### メタデータの種類

Exiv2 は 3 つのメタデータファミリーをサポートし、それぞれ専用のデータコンテナを持ちます：

| ファミリー | コンテナ | キー形式 | キーの例 |
|----------|---------|---------|---------|
| Exif | `Exiv2::ExifData` | `Exif.<グループ>.<タグ>` | `Exif.Image.Make` |
| IPTC | `Exiv2::IptcData` | `Iptc.<レコード>.<タグ>` | `Iptc.Application2.Headline` |
| XMP | `Exiv2::XmpData` | `Xmp.<スキーマ>.<プロパティ>` | `Xmp.dc.title` |

### 値の型

Exiv2 はメタデータエントリに型付きの値を使用します：

| Exif 型 | C++ 型 | 説明 |
|---------|--------|------|
| Ascii | `std::string` | ASCII 文字列（例：カメラメーカー） |
| Short | `uint16_t` | 16 ビット符号なし整数（例：ISO） |
| Long | `uint32_t` | 32 ビット符号なし整数（例：画像幅） |
| Rational | `Exiv2::URational` | 符号なし有理数（例：F 値、露出時間） |
| SRational | `Exiv2::Rational` | 符号付き有理数（例：露出補正） |
| Undefined | `Exiv2::DataBuf` | 生バイトデータ |

### エラー処理

Exiv2 はエラー処理に C++ 例外を使用します：

```cpp
try {
    auto image = Exiv2::ImageFactory::open("nonexistent.jpg");
    image->readMetadata();
} catch (const Exiv2::Error &e) {
    std::cerr << "エラー: " << e.what() << "\n";
}
```

---

## 比較：Exiv2 vs 他のライブラリ

| 機能 | Exiv2 | libexif | ExifTool | ImageMagick |
|------|-------|---------|----------|-------------|
| 言語 | C++ | C | Perl | C |
| ライセンス | GPL v2+ | LGPL | GPL/Artistic | Apache 2 |
| Exif | あり | あり | あり | あり |
| IPTC | あり | なし | あり | あり |
| XMP | あり | なし | あり | あり |
| ICC プロファイル | あり | なし | あり | あり |
| RAW フォーマット | あり | なし | あり | 部分的 |
| 書き込み対応 | あり | 限定的 | あり | あり |
| プログラム API | あり | あり | Perl/CLI | あり |
| 軽量 | はい | はい | いいえ（Perl） | いいえ（大規模） |

Exiv2 は画像メタデータのための包括的な C++ API を提供し、単一のライブラリで Exif、IPTC、XMP をサポートします。GIMP、darktable、digikam、gThumb など多くの写真アプリケーションで使用されている事実上の標準ライブラリです。

---

## トラブルシューティング

### Git クローンが失敗する

GitHub からのクローンが失敗する場合（ネットワークの問題、ファイアウォール等）、手動でリポジトリをクローンできます：

```bash
cd download/Exiv2
git clone --depth 1 --branch v0.28.7 https://github.com/Exiv2/exiv2.git exiv2-src
```

その後 `cmake ..` を再実行すると、FetchContent が既存のソースを検出します。

### CMake 設定が失敗する

macOS では Xcode Command Line Tools がインストールされていることを確認してください：

```bash
xcode-select --install
```

### Exiv2 を最初からリビルド

Exiv2 の完全なリビルド（再ダウンロード含む）を強制するには、download ディレクトリ全体を削除します：

```bash
rm -rf download/Exiv2
rm -rf build
mkdir build && cd build
cmake ..
```

ソースを保持したまま再ビルドのみ行うには、install ディレクトリだけを削除します：

```bash
rm -rf download/Exiv2/exiv2-install
rm -rf build
mkdir build && cd build
cmake ..
```

### ビルドに時間がかかる

初回ビルド時は Exiv2 のソースをダウンロードしてコンパイルします（約15秒）。以降のビルドはキャッシュされたインストールを再利用し、自分のソースファイルのみコンパイルします（約2秒）。初回ビルドを高速化するには：

```bash
cmake --build build -j$(nproc)   # Linux
cmake --build build -j$(sysctl -n hw.ncpu)  # macOS
```

---

## 参考資料

- [Exiv2 公式サイト](https://exiv2.org/)
- [Exiv2 GitHub リポジトリ](https://github.com/Exiv2/exiv2)
- [Exiv2 API ドキュメント](https://exiv2.org/doc/index.html)
- [Exiv2 リリース](https://github.com/Exiv2/exiv2/releases)
- [Exif タグリファレンス](https://exiv2.org/tags.html)
- [IPTC タグリファレンス](https://exiv2.org/iptc.html)
- [XMP 名前空間リファレンス](https://exiv2.org/tags-xmp-dc.html)
- [CMake FetchContent ドキュメント](https://cmake.org/cmake/help/latest/module/FetchContent.html)
