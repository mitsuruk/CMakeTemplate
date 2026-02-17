# botan.cmake リファレンス

## 概要

`botan.cmake` は、Botan ライブラリを自動的にダウンロード、ビルド、リンクする CMake 設定ファイルです。
CMake の `file(DOWNLOAD)` と `execute_process` を使用して依存関係を管理し、`download/` ディレクトリにキャッシュすることで、不要なダウンロードや再ビルドを回避します。

Botan は C++ 暗号ライブラリで、ハッシュ（SHA-2, SHA-3）、メッセージ認証（HMAC）、対称暗号（AES-GCM）、乱数生成、Base64/Hex エンコーディング、TLS、X.509 証明書など、多くの暗号アルゴリズムとプロトコルを提供します。

**注意:** Botan は CMake ではなく、Python の `configure.py` スクリプトをビルドシステムとして使用します。ビルドには Python 3 が必要です。

## ファイル情報

| 項目 | 詳細 |
|------|------|
| ソースディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/botan` |
| インストールディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/botan-install` |
| ダウンロード URL | https://github.com/randombit/botan/archive/refs/tags/3.10.0.tar.gz |
| バージョン | 3.10.0 |
| ライセンス | BSD 2-Clause License |
| ビルドシステム | Python `configure.py`（CMake ではない） |
| 言語標準 | C++20 |

---

## インクルードガード

```cmake
include_guard(GLOBAL)
```

このファイルは `include_guard(GLOBAL)` を使用して、複数回インクルードされても一度だけ実行されることを保証します。

**必要な理由:**

- configure 時の `execute_process` の重複実行を防止
- `target_link_libraries` の重複リンクを防止

---

## ディレクトリ構成

```
Botan/
├── cmake/
│   ├── botan.cmake          # この設定ファイル
│   ├── botanCmake.md        # ドキュメント（英語）
│   └── botanCmake-jp.md     # このドキュメント（日本語）
├── download/
│   ├── botan/               # Botan ソース（GitHub からダウンロード・キャッシュ）
│   └── botan-install/       # Botan ビルド成果物（lib/, include/）
│       ├── include/
│       │   └── botan-3/
│       │       └── botan/
│       │           ├── hash.h
│       │           ├── mac.h
│       │           ├── cipher_mode.h
│       │           ├── auto_rng.h
│       │           ├── base64.h
│       │           ├── hex.h
│       │           └── ...
│       └── lib/
│           └── libbotan-3.a
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## 使い方

### CMakeLists.txt への追加

```cmake
# CMakeLists.txt の末尾で botan.cmake をインクルード
include("./cmake/botan.cmake")
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
set(BOTAN_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(BOTAN_SOURCE_DIR ${BOTAN_DOWNLOAD_DIR}/botan)
set(BOTAN_INSTALL_DIR ${BOTAN_DOWNLOAD_DIR}/botan-install)
set(BOTAN_VERSION "3.10.0")
set(BOTAN_URL "https://github.com/randombit/botan/archive/refs/tags/${BOTAN_VERSION}.tar.gz")
```

### 2. キャッシュチェックと条件付きビルド

```cmake
if(EXISTS ${BOTAN_INSTALL_DIR}/lib/libbotan-3.a)
    message(STATUS "Botan already built: ${BOTAN_INSTALL_DIR}/lib/libbotan-3.a")
else()
    # ダウンロード、設定、ビルド、インストール ...
endif()
```

キャッシュロジックは以下の通りです:

| 条件 | アクション |
|------|----------|
| `botan-install/lib/libbotan-3.a` が存在 | すべてスキップ（キャッシュされたビルドを使用） |
| `botan/configure.py` が存在（インストール未済） | ダウンロードをスキップし、configure/build/install を実行 |
| 何も存在しない | ダウンロード、展開、configure、ビルド、インストール |

### 3. ダウンロード（必要な場合のみ）

```cmake
file(DOWNLOAD
    ${BOTAN_URL}
    ${BOTAN_DOWNLOAD_DIR}/botan-${BOTAN_VERSION}.tar.gz
    SHOW_PROGRESS
    STATUS DOWNLOAD_STATUS
)
file(ARCHIVE_EXTRACT
    INPUT ${BOTAN_DOWNLOAD_DIR}/botan-${BOTAN_VERSION}.tar.gz
    DESTINATION ${BOTAN_DOWNLOAD_DIR}
)
file(RENAME ${BOTAN_DOWNLOAD_DIR}/botan-${BOTAN_VERSION} ${BOTAN_SOURCE_DIR})
```

- GitHub のタグからダウンロード（Botan はタグを使用し、GitHub Releases は使用しない）
- `botan-3.10.0/` を `botan/` にリネームしてパスを簡潔に

### 4. Configure、ビルド、インストール（Python + Make）

```cmake
# Python 3 を検索
find_package(Python3 REQUIRED COMPONENTS Interpreter)

# Python configure.py で設定
execute_process(
    COMMAND ${Python3_EXECUTABLE} ${BOTAN_SOURCE_DIR}/configure.py
            --prefix=${BOTAN_INSTALL_DIR}
            --minimized-build
            --enable-modules=sha2_32,sha2_64,sha3,hmac,aes,gcm,ctr,auto_rng,system_rng,base64,hex
            --disable-shared-library
    WORKING_DIRECTORY ${BOTAN_SOURCE_DIR}
)

# make でビルド
execute_process(COMMAND make -j4
    WORKING_DIRECTORY ${BOTAN_SOURCE_DIR})

# インストール
execute_process(COMMAND make install
    WORKING_DIRECTORY ${BOTAN_SOURCE_DIR})
```

- `--minimized-build`: モジュールなしで開始し、明示的に有効化したもののみビルド
- `--enable-modules=...`: 必要な暗号モジュールを選択的に有効化
- `--disable-shared-library`: 静的ライブラリ（`libbotan-3.a`）のみビルド
- すべてのステップは CMake の configure 時に実行される（ビルド時ではない）

### 5. ライブラリのリンク

```cmake
add_library(botan_lib STATIC IMPORTED)
set_target_properties(botan_lib PROPERTIES
    IMPORTED_LOCATION ${BOTAN_INSTALL_DIR}/lib/libbotan-3.a
)

target_include_directories(${PROJECT_NAME} PRIVATE ${BOTAN_INSTALL_DIR}/include/botan-3)
target_link_libraries(${PROJECT_NAME} PRIVATE botan_lib Threads::Threads)

# macOS フレームワーク
if(APPLE)
    target_link_libraries(${PROJECT_NAME} PRIVATE "-framework Security" "-framework CoreFoundation")
endif()

# Botan 3.x は C++20 が必要
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_20)
```

---

## 有効化されたモジュール

最小ビルドでは以下のモジュールのみ有効化されます:

| モジュール | 説明 |
|-----------|------|
| `sha2_32` | SHA-224, SHA-256 |
| `sha2_64` | SHA-384, SHA-512 |
| `sha3` | SHA-3, SHAKE |
| `hmac` | HMAC メッセージ認証 |
| `aes` | AES ブロック暗号（128/192/256） |
| `gcm` | GCM 認証付き暗号モード |
| `ctr` | CTR ストリーム暗号モード |
| `auto_rng` | 自動シード乱数生成器 |
| `system_rng` | OS 提供の乱数生成器 |
| `base64` | Base64 エンコード/デコード |
| `hex` | 16進数 エンコード/デコード |

モジュールを追加するには、`botan.cmake` の `--enable-modules=` 行を編集してください。利用可能なすべてのモジュールは以下のコマンドで一覧表示できます:

```bash
python3 download/botan/configure.py --list-modules
```

---

## Botan の主な機能

| 機能 | 説明 |
|------|------|
| ハッシュ関数 | SHA-256, SHA-384, SHA-512, SHA-3, BLAKE2 など |
| MAC | HMAC, CMAC, GMAC, Poly1305 |
| 対称暗号 | AES-GCM, AES-CBC, ChaCha20-Poly1305 など |
| 公開鍵暗号 | RSA, ECDSA, Ed25519, X25519 など |
| 乱数生成 | `AutoSeeded_RNG`, `System_RNG` |
| エンコーディング | Base64, Hex |
| TLS | TLS 1.2 および TLS 1.3 |
| X.509 | 証明書の解析と生成 |
| 鍵導出 | HKDF, PBKDF2, Argon2 |
| スレッド安全性 | すべての操作はスレッドセーフ |

---

## C++ での使用例

### SHA-256 ハッシュ

```cpp
#include <botan/hash.h>
#include <botan/hex.h>
#include <iostream>

int main() {
    auto hash = Botan::HashFunction::create_or_throw("SHA-256");
    hash->update("Hello, Botan!");
    auto digest = hash->final();
    std::cout << "SHA-256: " << Botan::hex_encode(digest) << std::endl;
    return 0;
}
```

### HMAC-SHA-256

```cpp
#include <botan/mac.h>
#include <botan/auto_rng.h>
#include <botan/hex.h>
#include <iostream>

int main() {
    Botan::AutoSeeded_RNG rng;
    auto hmac = Botan::MessageAuthenticationCode::create_or_throw("HMAC(SHA-256)");

    auto key = rng.random_vec<std::vector<uint8_t>>(32);
    hmac->set_key(key);
    hmac->update("認証するメッセージ");
    auto tag = hmac->final();

    std::cout << "HMAC タグ: " << Botan::hex_encode(tag) << std::endl;

    // 検証
    hmac->set_key(key);
    hmac->update("認証するメッセージ");
    bool ok = hmac->verify_mac(tag);
    std::cout << "有効: " << (ok ? "はい" : "いいえ") << std::endl;

    return 0;
}
```

### AES-256/GCM 暗号化

```cpp
#include <botan/cipher_mode.h>
#include <botan/auto_rng.h>
#include <botan/hex.h>
#include <iostream>
#include <string>

int main() {
    Botan::AutoSeeded_RNG rng;
    auto key = rng.random_vec<Botan::secure_vector<uint8_t>>(32);

    // 暗号化
    auto enc = Botan::Cipher_Mode::create_or_throw("AES-256/GCM", Botan::Cipher_Dir::Encryption);
    enc->set_key(key);
    auto nonce = rng.random_vec<std::vector<uint8_t>>(enc->default_nonce_length());

    std::string plaintext = "秘密のデータ";
    Botan::secure_vector<uint8_t> ct(plaintext.begin(), plaintext.end());
    enc->start(nonce);
    enc->finish(ct);

    // 復号
    auto dec = Botan::Cipher_Mode::create_or_throw("AES-256/GCM", Botan::Cipher_Dir::Decryption);
    dec->set_key(key);
    dec->start(nonce);
    Botan::secure_vector<uint8_t> pt(ct);
    dec->finish(pt);

    std::cout << "復号結果: " << std::string(pt.begin(), pt.end()) << std::endl;
    return 0;
}
```

### 乱数生成

```cpp
#include <botan/auto_rng.h>
#include <botan/hex.h>
#include <iostream>

int main() {
    Botan::AutoSeeded_RNG rng;
    auto bytes = rng.random_vec<std::vector<uint8_t>>(32);
    std::cout << "乱数: " << Botan::hex_encode(bytes) << std::endl;
    return 0;
}
```

### Base64 エンコード / デコード

```cpp
#include <botan/base64.h>
#include <iostream>
#include <string>
#include <vector>

int main() {
    std::string input = "Hello, Botan!";
    std::vector<uint8_t> data(input.begin(), input.end());

    std::string encoded = Botan::base64_encode(data);
    auto decoded = Botan::base64_decode(encoded);

    std::cout << "エンコード: " << encoded << std::endl;
    std::cout << "デコード: " << std::string(decoded.begin(), decoded.end()) << std::endl;
    return 0;
}
```

### Hex エンコード / デコード

```cpp
#include <botan/hex.h>
#include <iostream>
#include <string>
#include <vector>

int main() {
    std::string input = "Hello";
    std::vector<uint8_t> data(input.begin(), input.end());

    std::string hex = Botan::hex_encode(data);
    auto decoded = Botan::hex_decode(hex);

    std::cout << "Hex: " << hex << std::endl;
    std::cout << "デコード: " << std::string(decoded.begin(), decoded.end()) << std::endl;
    return 0;
}
```

---

## configure オプション

`botan.cmake` で使用している `configure.py` の主なフラグ:

| フラグ | 説明 |
|--------|------|
| `--prefix=DIR` | インストール先ディレクトリ |
| `--minimized-build` | モジュールなしで開始 |
| `--enable-modules=LIST` | 有効化するモジュールのカンマ区切りリスト |
| `--disable-shared-library` | 共有ライブラリ（.so/.dylib）をビルドしない |

その他の便利なフラグ:

| フラグ | 説明 |
|--------|------|
| `--enable-static-library` | 静的ライブラリをビルド（共有無効時はデフォルト） |
| `--cc=COMPILER` | コンパイラを指定（gcc, clang） |
| `--list-modules` | 利用可能なすべてのモジュールを一覧表示 |
| `--with-debug-info` | デバッグシンボルを含める |
| `--with-sanitizers` | ASan/UBSan を有効化 |

---

## 他の暗号ライブラリとの比較

| 機能 | Botan | OpenSSL | libsodium | Crypto++ |
|------|-------|---------|-----------|----------|
| 言語 | C++20 | C | C | C++ |
| API スタイル | モダン C++ | C API | C API | C++（テンプレート） |
| モジュラービルド | 対応 | 部分対応 | 非対応 | 非対応 |
| ハッシュアルゴリズム | SHA-2/3, BLAKE2 等 | SHA-2/3 等 | BLAKE2b, SHA-256 | 多数 |
| AEAD | AES-GCM, ChaCha20-Poly1305 | AES-GCM, ChaCha20-Poly1305 | XChaCha20-Poly1305 | AES-GCM |
| TLS 対応 | TLS 1.2/1.3 | TLS 1.2/1.3 | 非対応 | 非対応 |
| X.509 対応 | 対応 | 対応 | 非対応 | 対応 |
| ライセンス | BSD 2-Clause | Apache 2.0 | ISC | Boost |
| メンテナンス状況 | アクティブ | アクティブ | アクティブ | アクティブ |

---

## トラブルシューティング

### ダウンロードに失敗する

GitHub に接続できない場合、手動でダウンロードして配置できます:

```bash
curl -L -o download/botan-3.10.0.tar.gz https://github.com/randombit/botan/archive/refs/tags/3.10.0.tar.gz
```

その後 `cmake ..` を再実行すると、キャッシュされた tarball から展開が行われます。

### configure に失敗する

Python 3 が利用可能であることを確認してください:

```bash
python3 --version
```

macOS では、Xcode Command Line Tools がインストールされていることを確認してください:

```bash
xcode-select --install
```

### Botan を最初からリビルドする

完全なリビルドを強制するには、インストールディレクトリとソースディレクトリを削除します:

```bash
rm -rf download/botan-install download/botan
cd build && cmake ..
```

### リンクエラー: Botan シンボルへの未定義参照

`download/botan-install/lib/` に `libbotan-3.a` が存在することを確認してください。存在しない場合は、インストールディレクトリを削除して cmake を再実行してください。

macOS では、Security と CoreFoundation フレームワークがリンクされていることを確認してください:

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE "-framework Security" "-framework CoreFoundation")
```

### `<botan/hash.h> が正しくインクルードされない`

Botan 3.x はヘッダを `include/botan-3/botan/` にインストールします。`target_include_directories` が `include/botan-3` ディレクトリを指していることを確認してください（`include/botan-3/botan/` ではありません）。

### 暗号モジュールを追加する

追加の機能（例: RSA, Ed25519, TLS）が必要な場合、`botan.cmake` の `--enable-modules=` 行にモジュール名を追加してください。その後、インストールディレクトリを削除してリビルドします:

```bash
rm -rf download/botan-install download/botan
cd build && cmake ..
```

---

## 参考リンク

- [Botan GitHub リポジトリ](https://github.com/randombit/botan)
- [Botan ドキュメント](https://botan.randombit.net/)
- [Botan API リファレンス](https://botan.randombit.net/doxygen/)
- [Botan ハンドブック](https://botan.randombit.net/handbook/)
- [CMake execute_process ドキュメント](https://cmake.org/cmake/help/latest/command/execute_process.html)
- [CMake file(DOWNLOAD) ドキュメント](https://cmake.org/cmake/help/latest/command/file.html#download)
