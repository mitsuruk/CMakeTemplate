# gflags.cmake リファレンス

## 概要

`gflags.cmake` は、gflags ライブラリを自動的にダウンロード・ビルド・リンクする CMake 設定ファイルです。
CMake の `file(DOWNLOAD)` と `execute_process` を使用して依存関係を管理し、`download/` ディレクトリにキャッシュすることで、不要なダウンロードや再ビルドを回避します。

gflags（Google Commandline Flags）は、C++ のコマンドラインフラグ処理ライブラリです。
各種型（string, int32, int64, uint64, double, bool）のフラグ定義、フラグのバリデーション、プログラムからのフラグのアクセスと変更、`--help` / `--version` の自動生成をサポートしています。

## ファイル情報

| 項目 | 詳細 |
|------|------|
| ソースディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/gflags` |
| インストールディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/gflags-install` |
| ダウンロード URL | https://github.com/gflags/gflags/archive/refs/tags/v2.2.2.tar.gz |
| バージョン | 2.2.2 |
| ライセンス | BSD 3-Clause License |

---

## インクルードガード

```cmake
include_guard(GLOBAL)
```

このファイルは `include_guard(GLOBAL)` を使用して、複数回インクルードされても1回だけ実行されることを保証します。

**なぜ必要か：**

- configure 時の `execute_process` の重複呼び出しを防止
- `target_link_libraries` での重複リンクを防止

---

## ディレクトリ構成

```
gflags/
├── cmake/
│   ├── gflags.cmake          # この設定ファイル
│   ├── gflagsCmake.md        # このドキュメント（英語版）
│   └── gflagsCmake-jp.md     # このドキュメント（日本語版）
├── download/
│   ├── gflags/               # gflags ソース（キャッシュ、GitHub からダウンロード）
│   │   └── _build/           # CMake ビルドディレクトリ（ソース内）
│   └── gflags-install/       # gflags ビルド成果物（lib/, include/）
│       ├── include/
│       │   └── gflags/
│       │       ├── gflags.h
│       │       ├── gflags_declare.h
│       │       ├── gflags_completions.h
│       │       └── ...
│       └── lib/
│           └── libgflags.a
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## 使い方

### CMakeLists.txt への追加

```cmake
# gflags.cmake が存在する場合に自動的にインクルード
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/gflags.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/gflags.cmake)
endif()
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
set(GFLAGS_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(GFLAGS_SOURCE_DIR ${GFLAGS_DOWNLOAD_DIR}/gflags)
set(GFLAGS_INSTALL_DIR ${GFLAGS_DOWNLOAD_DIR}/gflags-install)
set(GFLAGS_BUILD_DIR ${GFLAGS_SOURCE_DIR}/_build)
set(GFLAGS_VERSION "2.2.2")
set(GFLAGS_URL "https://github.com/gflags/gflags/archive/refs/tags/v${GFLAGS_VERSION}.tar.gz")
```

### 2. キャッシュチェックと条件付きビルド

```cmake
if(EXISTS ${GFLAGS_INSTALL_DIR}/lib/libgflags.a)
    message(STATUS "gflags already built: ${GFLAGS_INSTALL_DIR}/lib/libgflags.a")
else()
    # ダウンロード、設定、ビルド、インストール ...
endif()
```

キャッシュロジックは以下の通りです：

| 条件 | アクション |
|------|-----------|
| `gflags-install/lib/libgflags.a` が存在する | すべてスキップ（キャッシュされたビルドを使用） |
| `gflags/CMakeLists.txt` が存在する（インストールなし） | ダウンロードをスキップ、CMake configure/build/install を実行 |
| 何も存在しない | ダウンロード、展開、CMake configure、ビルド、インストール |

### 3. ダウンロード（必要な場合）

```cmake
file(DOWNLOAD
    ${GFLAGS_URL}
    ${GFLAGS_DOWNLOAD_DIR}/gflags-${GFLAGS_VERSION}.tar.gz
    SHOW_PROGRESS
    STATUS DOWNLOAD_STATUS
)
file(ARCHIVE_EXTRACT
    INPUT ${GFLAGS_DOWNLOAD_DIR}/gflags-${GFLAGS_VERSION}.tar.gz
    DESTINATION ${GFLAGS_DOWNLOAD_DIR}
)
file(RENAME ${GFLAGS_DOWNLOAD_DIR}/gflags-${GFLAGS_VERSION} ${GFLAGS_SOURCE_DIR})
```

- GitHub Releases からダウンロード
- 展開後、`gflags-2.2.2/` を `gflags/` にリネームしてパスを統一

### 4. Configure、ビルド、インストール（CMake）

```cmake
execute_process(
    COMMAND ${CMAKE_COMMAND}
            -DCMAKE_INSTALL_PREFIX=${GFLAGS_INSTALL_DIR}
            -DBUILD_SHARED_LIBS=OFF
            -DBUILD_STATIC_LIBS=ON
            -DBUILD_TESTING=OFF
            -DBUILD_PACKAGING=OFF
            -DBUILD_gflags_nothreads_LIB=OFF
            -DCMAKE_BUILD_TYPE=Release
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON
            ${GFLAGS_SOURCE_DIR}
    WORKING_DIRECTORY ${GFLAGS_BUILD_DIR}
)
execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release -j4
    WORKING_DIRECTORY ${GFLAGS_BUILD_DIR})
execute_process(COMMAND ${CMAKE_COMMAND} --install . --config Release
    WORKING_DIRECTORY ${GFLAGS_BUILD_DIR})
```

- `-DBUILD_SHARED_LIBS=OFF`: 共有ライブラリのビルドを無効化
- `-DBUILD_STATIC_LIBS=ON`: 静的ライブラリのみビルド
- `-DBUILD_TESTING=OFF`: テストバイナリのビルドを無効化
- `-DBUILD_PACKAGING=OFF`: CPack パッケージングを無効化
- `-DBUILD_gflags_nothreads_LIB=OFF`: マルチスレッド版のみビルド
- `-DCMAKE_POSITION_INDEPENDENT_CODE=ON`: 位置独立コードを生成
- すべてのステップは CMake configure 時に実行（ビルド時ではない）

### 5. ライブラリのリンク

```cmake
set(gflags_DIR ${GFLAGS_INSTALL_DIR}/lib/cmake/gflags)
find_package(gflags REQUIRED CONFIG)

target_link_libraries(${PROJECT_NAME} PRIVATE gflags::gflags)
```

---

## gflags の主な機能

| 機能 | 説明 |
|------|------|
| フラグ型 | `DEFINE_string`, `DEFINE_int32`, `DEFINE_int64`, `DEFINE_uint64`, `DEFINE_double`, `DEFINE_bool` |
| フラグアクセス | `FLAGS_<name>` グローバル変数 |
| フラグバリデーション | `DEFINE_validator` / `RegisterFlagValidator` コールバック |
| フラグ情報取得 | `GetCommandLineFlagInfo`, `GetAllFlags` |
| プログラムからの設定 | `SetCommandLineOption` |
| 使用方法/バージョン | `SetUsageMessage`, `SetVersionString`, `--help`, `--version` |
| argv 処理 | `ParseCommandLineFlags`（オプションでフラグを argv から削除） |
| スレッドセーフ | すべてのフラグ操作はスレッドセーフ |

---

## C++ 使用例

### 基本的なフラグ定義と使用

```cpp
#include <gflags/gflags.h>
#include <iostream>

DEFINE_string(name, "World", "Name to greet");
DEFINE_int32(count, 1, "Number of greetings");
DEFINE_bool(verbose, false, "Enable verbose output");

int main(int argc, char* argv[]) {
    gflags::ParseCommandLineFlags(&argc, &argv, true);

    for (int i = 0; i < FLAGS_count; ++i) {
        std::cout << "Hello, " << FLAGS_name << "!" << std::endl;
    }

    if (FLAGS_verbose) {
        std::cout << "Verbose mode enabled" << std::endl;
    }

    gflags::ShutDownCommandLineFlags();
    return 0;
}
```

### フラグバリデーション

```cpp
#include <gflags/gflags.h>
#include <iostream>

DEFINE_int32(port, 8080, "Server port number");

static bool ValidatePort(const char* flagname, gflags::int32 value) {
    if (value > 0 && value < 65536) return true;
    std::cerr << "Invalid value for --" << flagname << ": " << value << std::endl;
    return false;
}
DEFINE_validator(port, &ValidatePort);

int main(int argc, char* argv[]) {
    gflags::ParseCommandLineFlags(&argc, &argv, true);

    std::cout << "Server running on port " << FLAGS_port << std::endl;

    gflags::ShutDownCommandLineFlags();
    return 0;
}
```

### フラグ情報の取得

```cpp
#include <gflags/gflags.h>
#include <iostream>
#include <vector>

DEFINE_string(config, "/etc/app.conf", "Configuration file path");

int main(int argc, char* argv[]) {
    gflags::ParseCommandLineFlags(&argc, &argv, true);

    // 特定のフラグの詳細情報を取得
    gflags::CommandLineFlagInfo info;
    if (gflags::GetCommandLineFlagInfo("config", &info)) {
        std::cout << "Flag: --" << info.name << std::endl;
        std::cout << "  Type:    " << info.type << std::endl;
        std::cout << "  Value:   " << info.current_value << std::endl;
        std::cout << "  Default: " << info.default_value << std::endl;
        std::cout << "  Changed: " << std::boolalpha << !info.is_default << std::endl;
    }

    // すべてのフラグを列挙
    std::vector<gflags::CommandLineFlagInfo> all_flags;
    gflags::GetAllFlags(&all_flags);
    std::cout << "Total registered flags: " << all_flags.size() << std::endl;

    gflags::ShutDownCommandLineFlags();
    return 0;
}
```

### プログラムからのフラグ設定

```cpp
#include <gflags/gflags.h>
#include <iostream>

DEFINE_string(mode, "normal", "Operation mode");
DEFINE_int32(timeout, 30, "Timeout in seconds");

int main(int argc, char* argv[]) {
    gflags::ParseCommandLineFlags(&argc, &argv, true);

    std::cout << "mode = " << FLAGS_mode << std::endl;

    // プログラムからフラグの値を変更
    gflags::SetCommandLineOption("mode", "debug");
    std::cout << "mode = " << FLAGS_mode << std::endl;  // "debug"

    // FLAGS_ 変数を直接変更することも可能
    FLAGS_timeout = 60;
    std::cout << "timeout = " << FLAGS_timeout << std::endl;  // 60

    gflags::ShutDownCommandLineFlags();
    return 0;
}
```

### 使用方法メッセージとバージョン

```cpp
#include <gflags/gflags.h>

DEFINE_string(input, "", "Input file path (required)");
DEFINE_string(output, "out.txt", "Output file path");

int main(int argc, char* argv[]) {
    gflags::SetVersionString("2.0.0");
    gflags::SetUsageMessage("Process input files\nUsage: myapp --input=<file>");

    gflags::ParseCommandLineFlags(&argc, &argv, true);

    // --help は使用方法メッセージとすべてのフラグを表示
    // --version はバージョン文字列を表示
    // --helpshort はメインファイルで定義されたフラグのみ表示

    if (FLAGS_input.empty()) {
        gflags::ShowUsageWithFlagsRestrict(argv[0], "main");
        return 1;
    }

    gflags::ShutDownCommandLineFlags();
    return 0;
}
```

### 複数のフラグ型

```cpp
#include <gflags/gflags.h>
#include <iostream>

DEFINE_bool(debug, false, "Enable debug mode");
DEFINE_int32(threads, 4, "Number of threads");
DEFINE_int64(max_memory, 1073741824, "Max memory in bytes (default: 1GB)");
DEFINE_uint64(seed, 0, "Random seed (0 = auto)");
DEFINE_double(learning_rate, 0.001, "Learning rate");
DEFINE_string(model, "default", "Model name");

int main(int argc, char* argv[]) {
    gflags::ParseCommandLineFlags(&argc, &argv, true);

    std::cout << "debug:         " << std::boolalpha << FLAGS_debug << std::endl;
    std::cout << "threads:       " << FLAGS_threads << std::endl;
    std::cout << "max_memory:    " << FLAGS_max_memory << std::endl;
    std::cout << "seed:          " << FLAGS_seed << std::endl;
    std::cout << "learning_rate: " << FLAGS_learning_rate << std::endl;
    std::cout << "model:         " << FLAGS_model << std::endl;

    gflags::ShutDownCommandLineFlags();
    return 0;
}
```

---

## フラグの型

| マクロ | C++ 型 | 例 |
|--------|--------|-----|
| `DEFINE_bool` | `bool` | `DEFINE_bool(verbose, false, "...")` |
| `DEFINE_int32` | `int32_t` | `DEFINE_int32(port, 8080, "...")` |
| `DEFINE_int64` | `int64_t` | `DEFINE_int64(max_size, 1000000, "...")` |
| `DEFINE_uint64` | `uint64_t` | `DEFINE_uint64(seed, 0, "...")` |
| `DEFINE_double` | `double` | `DEFINE_double(rate, 0.01, "...")` |
| `DEFINE_string` | `std::string` | `DEFINE_string(name, "default", "...")` |

---

## よく使う関数

| 関数 | 説明 |
|------|------|
| `ParseCommandLineFlags(&argc, &argv, remove)` | コマンドラインフラグを解析。`remove` が true の場合、解析済みフラグは argv から削除される |
| `SetUsageMessage(message)` | `--help` で表示される使用方法メッセージを設定 |
| `SetVersionString(version)` | `--version` で表示されるバージョン文字列を設定 |
| `SetCommandLineOption(name, value)` | プログラムからフラグの値を設定（文字列形式） |
| `GetCommandLineFlagInfo(name, &info)` | フラグの詳細情報を取得 |
| `GetAllFlags(&flags)` | 登録されているすべてのフラグのリストを取得 |
| `ShowUsageWithFlagsRestrict(argv0, filter)` | フィルタに一致するフラグの使用方法を表示 |
| `ProgramInvocationShortName()` | プログラムの短縮名（ベース名）を取得 |
| `ShutDownCommandLineFlags()` | gflags のリソースをクリーンアップ |

---

## 他のフラグライブラリとの比較

| 機能 | gflags | Abseil Flags | Boost.Program_options |
|------|--------|-------------|----------------------|
| フラグ定義 | `DEFINE_*` マクロ | `ABSL_FLAG` マクロ | `options_description` |
| フラグアクセス | `FLAGS_<name>` | `absl::GetFlag()` | `vm["name"]` |
| バリデーション | `DEFINE_validator` | カスタムパーサー | `notifier` |
| イントロスペクション | `GetAllFlags` | 限定的 | 限定的 |
| `--help` | 組み込み | 組み込み | 組み込み |
| スレッドセーフ | はい | はい | いいえ |
| ヘッダーオンリー | いいえ | いいえ | いいえ |
| メンテナンス状況 | 中程度 | 活発 | 活発 |

---

## トラブルシューティング

### ダウンロードに失敗する

GitHub に接続できない場合、手動で tarball をダウンロードして配置できます：

```bash
curl -L -o download/gflags-2.2.2.tar.gz https://github.com/gflags/gflags/archive/refs/tags/v2.2.2.tar.gz
```

その後、`cmake ..` を再実行すれば、キャッシュされた tarball から展開が行われます。

### Configure に失敗する

CMake 3.20 以上が利用可能か確認してください：

```bash
cmake --version
```

macOS の場合、Xcode Command Line Tools がインストールされていることを確認してください：

```bash
xcode-select --install
```

### gflags をゼロから再ビルドする

完全な再ビルドを行うには、インストールディレクトリとソースディレクトリを削除します：

```bash
rm -rf download/gflags-install download/gflags
cd build && cmake ..
```

### リンクエラー: gflags シンボルへの未定義参照

`download/gflags-install/lib/` に `libgflags.a` が存在することを確認してください。存在しない場合は、インストールディレクトリを削除して cmake を再実行してください。

### `<gflags/gflags.h> が正しくインクルードされない`

`find_package(gflags)` が `CONFIG` モードで呼び出され、`gflags_DIR` が正しい cmake 設定ディレクトリを指していることを確認してください。インストールされた cmake 設定は `download/gflags-install/lib/cmake/gflags/` にあります。

---

## 参考資料

- [gflags GitHub リポジトリ](https://github.com/gflags/gflags)
- [gflags ドキュメント](https://gflags.github.io/gflags/)
- [gflags README](https://github.com/gflags/gflags/blob/master/README.md)
- [CMake execute_process ドキュメント](https://cmake.org/cmake/help/latest/command/execute_process.html)
- [CMake file(DOWNLOAD) ドキュメント](https://cmake.org/cmake/help/latest/command/file.html#download)
