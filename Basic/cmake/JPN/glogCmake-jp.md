# glog.cmake リファレンス

## 概要

`glog.cmake` は glog ライブラリの自動ダウンロード、ビルド、リンクを行う CMake 設定ファイルです。
CMake の `file(DOWNLOAD)` と `execute_process` を使用して依存関係を管理し、`download/` ディレクトリにキャッシュすることで冗長なダウンロードとリビルドを回避します。

glog（Google Logging Library）は C++ ロギングライブラリで、C++ スタイルのストリームに基づくロギング API と各種ヘルパーマクロを提供します。
重大度レベル（INFO, WARNING, ERROR, FATAL）、条件付き・周期的ロギング、詳細ロギング（VLOG）、アサーションスタイルの CHECK マクロ、クラッシュ時の自動スタックトレースダンプをサポートしています。

## ファイル情報

| 項目 | 詳細 |
|------|------|
| ソースディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/glog` |
| インストールディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/glog-install` |
| ダウンロード URL | https://github.com/google/glog/archive/refs/tags/v0.7.1.tar.gz |
| バージョン | 0.7.1 |
| ライセンス | BSD 3-Clause License |

---

## インクルードガード

```cmake
include_guard(GLOBAL)
```

このファイルは `include_guard(GLOBAL)` を使用して、複数回インクルードされても一度だけ実行されるようにしています。

**必要な理由：**

- configure 時の `execute_process` の重複呼び出しを防止
- `target_link_libraries` での重複リンクを防止

---

## ディレクトリ構造

```
glog/
├── cmake/
│   ├── glog.cmake          # この設定ファイル
│   └── glogCmake.md        # このドキュメント
├── download/
│   ├── glog/               # glog ソース（キャッシュ、GitHub からダウンロード）
│   │   └── _build/         # CMake ビルドディレクトリ（ソース内）
│   └── glog-install/       # glog ビルド成果物（lib/, include/）
│       ├── include/
│       │   └── glog/
│       │       ├── logging.h
│       │       ├── log_severity.h
│       │       ├── flags.h
│       │       ├── vlog_is_on.h
│       │       └── ...
│       └── lib/
│           └── libglog.a
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## 使い方

### CMakeLists.txt への追加

```cmake
# glog.cmake が存在する場合に自動インクルード
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/glog.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/glog.cmake)
endif()
```

### ビルド

```bash
mkdir build && cd build
cmake ..
make
```

---

## 処理の流れ

### 1. ディレクトリパスの設定

```cmake
set(GLOG_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(GLOG_SOURCE_DIR ${GLOG_DOWNLOAD_DIR}/glog)
set(GLOG_INSTALL_DIR ${GLOG_DOWNLOAD_DIR}/glog-install)
set(GLOG_BUILD_DIR ${GLOG_SOURCE_DIR}/_build)
set(GLOG_VERSION "0.7.1")
set(GLOG_URL "https://github.com/google/glog/archive/refs/tags/v${GLOG_VERSION}.tar.gz")
```

### 2. キャッシュチェックと条件付きビルド

```cmake
if(EXISTS ${GLOG_INSTALL_DIR}/lib/libglog.a)
    message(STATUS "glog already built: ${GLOG_INSTALL_DIR}/lib/libglog.a")
else()
    # ダウンロード、設定、ビルド、インストール ...
endif()
```

キャッシュのロジックは以下の通りです：

| 条件 | アクション |
|------|----------|
| `glog-install/lib/libglog.a` が存在 | すべてスキップ（キャッシュされたビルドを使用） |
| `glog/CMakeLists.txt` が存在（インストールなし） | ダウンロードをスキップ、CMake configure/build/install を実行 |
| 何も存在しない | ダウンロード、展開、CMake configure、ビルド、インストール |

### 3. ダウンロード（必要な場合）

```cmake
file(DOWNLOAD
    ${GLOG_URL}
    ${GLOG_DOWNLOAD_DIR}/glog-${GLOG_VERSION}.tar.gz
    SHOW_PROGRESS
    STATUS DOWNLOAD_STATUS
)
file(ARCHIVE_EXTRACT
    INPUT ${GLOG_DOWNLOAD_DIR}/glog-${GLOG_VERSION}.tar.gz
    DESTINATION ${GLOG_DOWNLOAD_DIR}
)
file(RENAME ${GLOG_DOWNLOAD_DIR}/glog-${GLOG_VERSION} ${GLOG_SOURCE_DIR})
```

- GitHub Releases からダウンロード
- `glog-0.7.1/` を `glog/` にリネーム（クリーンなパスのため）

### 4. 設定、ビルド、インストール（CMake）

```cmake
execute_process(
    COMMAND ${CMAKE_COMMAND}
            -DCMAKE_INSTALL_PREFIX=${GLOG_INSTALL_DIR}
            -DBUILD_SHARED_LIBS=OFF
            -DWITH_GFLAGS=OFF
            -DWITH_GTEST=OFF
            -DWITH_UNWIND=OFF
            -DBUILD_TESTING=OFF
            -DCMAKE_BUILD_TYPE=Release
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON
            ${GLOG_SOURCE_DIR}
    WORKING_DIRECTORY ${GLOG_BUILD_DIR}
)
execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release -j4
    WORKING_DIRECTORY ${GLOG_BUILD_DIR})
execute_process(COMMAND ${CMAKE_COMMAND} --install . --config Release
    WORKING_DIRECTORY ${GLOG_BUILD_DIR})
```

- `-DBUILD_SHARED_LIBS=OFF`：静的ライブラリのみビルド
- `-DWITH_GFLAGS=OFF`：gflags 依存を無効化（ビルドを簡素化）
- `-DWITH_GTEST=OFF`：Google Test 依存を無効化
- `-DWITH_UNWIND=OFF`：libunwind 依存を無効化
- `-DBUILD_TESTING=OFF`：テストバイナリのビルドを無効化
- `-DCMAKE_POSITION_INDEPENDENT_CODE=ON`：位置独立コードを生成
- すべてのステップは CMake configure 時（ビルド時ではなく）に実行

### 5. ライブラリのリンク

```cmake
add_library(glog_lib STATIC IMPORTED)
set_target_properties(glog_lib PROPERTIES
    IMPORTED_LOCATION ${GLOG_INSTALL_DIR}/lib/libglog.a
)

target_include_directories(${PROJECT_NAME} PRIVATE ${GLOG_INSTALL_DIR}/include)
target_link_libraries(${PROJECT_NAME} PRIVATE glog_lib)
```

---

## glog の主な機能

| 機能 | 説明 |
|------|------|
| 重大度レベル | `LOG(INFO)`, `LOG(WARNING)`, `LOG(ERROR)`, `LOG(FATAL)` |
| 条件付きロギング | `LOG_IF`, `LOG_EVERY_N`, `LOG_FIRST_N`, `LOG_EVERY_T` |
| 詳細ロギング | `VLOG(n)`、`--v=N` フラグで制御 |
| CHECK マクロ | `CHECK`, `CHECK_EQ`, `CHECK_NE`, `CHECK_LT`, `CHECK_LE`, `CHECK_GT`, `CHECK_GE`, `CHECK_NOTNULL` |
| 失敗シグナルハンドラー | SIGSEGV, SIGABRT などでスタックトレースを出力 |
| ログ出力先 | stderr、ファイル、カスタムシンク |
| スレッドセーフ | すべてのロギング操作はスレッドセーフ |
| ストリームベース API | C++ の `<<` 演算子による柔軟なフォーマット |

---

## C++ での使用例

### 基本的なロギング

```cpp
#include <glog/logging.h>

int main(int argc, char* argv[]) {
    google::InitGoogleLogging(argv[0]);
    FLAGS_alsologtostderr = true;

    LOG(INFO) << "情報メッセージです";
    LOG(WARNING) << "警告メッセージです";
    LOG(ERROR) << "エラーメッセージです";
    // LOG(FATAL) << "プログラムを終了します";

    google::ShutdownGoogleLogging();
    return 0;
}
```

### 条件付きロギング

```cpp
#include <glog/logging.h>

int main(int argc, char* argv[]) {
    google::InitGoogleLogging(argv[0]);
    FLAGS_alsologtostderr = true;

    int value = 42;

    // 条件が true の場合のみログ出力
    LOG_IF(INFO, value > 10) << "value は 10 より大きい";

    // N 回ごとにログ出力
    for (int i = 0; i < 100; ++i) {
        LOG_EVERY_N(INFO, 10) << "10 回ごと: i=" << i;
    }

    // 最初の N 回のみログ出力
    for (int i = 0; i < 100; ++i) {
        LOG_FIRST_N(INFO, 3) << "最初の 3 回のみ: i=" << i;
    }

    // T 秒に最大 1 回ログ出力
    for (int i = 0; i < 100; ++i) {
        LOG_EVERY_T(INFO, 1.0) << "1 秒に最大 1 回: i=" << i;
    }

    google::ShutdownGoogleLogging();
    return 0;
}
```

### 詳細ロギング (VLOG)

```cpp
#include <glog/logging.h>

int main(int argc, char* argv[]) {
    google::InitGoogleLogging(argv[0]);
    FLAGS_alsologtostderr = true;

    // --v=2 で実行すると VLOG(1) と VLOG(2) のメッセージが表示される
    VLOG(1) << "詳細レベル 1: 一般的なデバッグ情報";
    VLOG(2) << "詳細レベル 2: 詳細なトレース情報";
    VLOG(3) << "詳細レベル 3: 非常に詳細な情報";

    if (VLOG_IS_ON(2)) {
        // 詳細レベル >= 2 の場合のみ高コストな計算を実行
        LOG(INFO) << "詳細診断が有効です";
    }

    google::ShutdownGoogleLogging();
    return 0;
}
```

### CHECK マクロ（アサーション）

```cpp
#include <glog/logging.h>
#include <vector>

int main(int argc, char* argv[]) {
    google::InitGoogleLogging(argv[0]);

    int a = 10, b = 20;

    CHECK(a < b) << "a は b より小さくなければならない";
    CHECK_EQ(a, 10) << "a は 10 であるべき";
    CHECK_NE(a, b) << "a と b は異なるべき";
    CHECK_LT(a, b) << "a は b より小さいべき";
    CHECK_GT(b, a) << "b は a より大きいべき";

    // CHECK_NOTNULL は非 null ならポインタを返す
    std::vector<int> v = {1, 2, 3};
    auto* ptr = CHECK_NOTNULL(&v);
    LOG(INFO) << "ベクタサイズ: " << ptr->size();

    google::ShutdownGoogleLogging();
    return 0;
}
```

### 失敗シグナルハンドラー（クラッシュ時のスタックトレース）

```cpp
#include <glog/logging.h>

void cause_segfault() {
    int* p = nullptr;
    *p = 42;  // SIGSEGV
}

int main(int argc, char* argv[]) {
    google::InitGoogleLogging(argv[0]);
    FLAGS_alsologtostderr = true;

    // SIGSEGV, SIGABRT, SIGBUS などのシグナルハンドラーをインストール
    google::InstallFailureSignalHandler();

    LOG(INFO) << "クラッシュします...";
    cause_segfault();  // 終了前にスタックトレースを出力

    google::ShutdownGoogleLogging();
    return 0;
}
```

### ファイルへのログ出力

```cpp
#include <glog/logging.h>

int main(int argc, char* argv[]) {
    google::InitGoogleLogging(argv[0]);

    // INFO 以上を /tmp/myapp.INFO 等に出力
    google::SetLogDestination(google::INFO, "/tmp/myapp.INFO.");
    google::SetLogDestination(google::WARNING, "/tmp/myapp.WARNING.");
    google::SetLogDestination(google::ERROR, "/tmp/myapp.ERROR.");

    // stderr にも出力
    FLAGS_alsologtostderr = true;

    LOG(INFO) << "ファイルと stderr の両方に出力";
    LOG(WARNING) << "警告がファイルに記録される";

    google::ShutdownGoogleLogging();
    return 0;
}
```

---

## 重大度レベル

| レベル | マクロ | 説明 |
|-------|--------|------|
| 0 | `LOG(INFO)` | 情報メッセージ |
| 1 | `LOG(WARNING)` | 警告状態 |
| 2 | `LOG(ERROR)` | エラー状態 |
| 3 | `LOG(FATAL)` | 致命的エラー；メッセージをログ出力後、`abort()` でプログラムを終了 |

上位の重大度レベルは、ログ出力にすべての下位レベルを含みます。例えば、`FLAGS_minloglevel = 1` は INFO を抑制しますが、WARNING、ERROR、FATAL は表示します。

---

## よく使用されるフラグ

| フラグ | デフォルト | 説明 |
|-------|---------|------|
| `FLAGS_logtostderr` | `false` | ファイルの代わりに stderr にログ出力 |
| `FLAGS_alsologtostderr` | `false` | ファイルに加えて stderr にもログ出力 |
| `FLAGS_colorlogtostderr` | `false` | stderr のログ出力をカラー化 |
| `FLAGS_minloglevel` | `0`（INFO） | ログ出力する最小重大度レベル |
| `FLAGS_v` | `0` | VLOG の詳細レベル |
| `FLAGS_log_dir` | `""` | ログファイルのディレクトリ |
| `FLAGS_max_log_size` | `1800` | 最大ログファイルサイズ（MB） |
| `FLAGS_stop_logging_if_full_disk` | `false` | ディスクが満杯の場合にロギングを停止 |

---

## 他のロギングライブラリとの比較

| 機能 | glog | spdlog | Abseil Logging |
|------|------|--------|----------------|
| API スタイル | ストリーム（`<<`） | fmt/printf | ストリーム（`<<`） |
| 重大度レベル | 4（INFO-FATAL） | 7（trace-critical） | 4（INFO-FATAL） |
| CHECK マクロ | あり | なし | あり |
| VLOG | あり | なし | あり |
| シグナルハンドラー | あり | なし | あり |
| ヘッダーオンリー | なし | 選択可 | なし |
| スレッドセーフ | あり | あり | あり |
| メンテナンス状況 | アーカイブ（2025-06） | アクティブ | アクティブ |

---

## トラブルシューティング

### ダウンロードが失敗する

GitHub に接続できない場合、手動でダウンロードして配置できます：

```bash
curl -L -o download/glog-0.7.1.tar.gz https://github.com/google/glog/archive/refs/tags/v0.7.1.tar.gz
```

その後 `cmake ..` を再実行すると、キャッシュされた tarball から展開されます。

### 設定が失敗する

CMake 3.20 以上が利用可能であることを確認してください：

```bash
cmake --version
```

macOS では、Xcode Command Line Tools がインストールされていることを確認してください：

```bash
xcode-select --install
```

### glog を最初からリビルド

完全なリビルドを強制するには、インストールディレクトリとソースディレクトリを削除します：

```bash
rm -rf download/glog-install download/glog
cd build && cmake ..
```

### リンクエラー：glog シンボルへの未定義参照

`download/glog-install/lib/` に `libglog.a` が存在することを確認してください。存在しない場合は、インストールディレクトリを削除して cmake を再実行してください。

### `<glog/logging.h> was not included correctly`

glog 0.7.x はライブラリを CMake の `find_package` 経由か、インクルードパスを正しく設定して利用する必要があります。`target_include_directories` が glog インストールの include ディレクトリを指していることを確認してください。

---

## 参考資料

- [glog GitHub リポジトリ](https://github.com/google/glog)
- [glog ドキュメント（0.7.1）](https://google.github.io/glog/0.7.1/)
- [glog README](https://github.com/google/glog/blob/master/README.rst)
- [CMake execute_process ドキュメント](https://cmake.org/cmake/help/latest/command/execute_process.html)
- [CMake file(DOWNLOAD) ドキュメント](https://cmake.org/cmake/help/latest/command/file.html#download)
