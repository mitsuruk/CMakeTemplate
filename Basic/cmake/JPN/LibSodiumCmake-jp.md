# LibSodium.cmake リファレンス

## 概要

`LibSodium.cmake` は、libsodium ライブラリのダウンロード・ビルド・リンクを自動化する CMake 設定ファイルです。
CMake の `file(DOWNLOAD)` と `execute_process` を使用して依存関係を管理し、`download/` ディレクトリにキャッシュすることで、不要なダウンロードや再ビルドを回避します。

libsodium は、モダンでポータブルな使いやすい暗号化ライブラリです。認証付き暗号化、鍵交換、デジタル署名、パスワードハッシュ、秘密鍵暗号化、公開鍵暗号化、セキュアメモリ管理、乱数生成などの機能を提供します。

libsodium は autoconf ビルドシステム（`./configure && make && make install`）を使用します。

## ファイル情報

| 項目 | 詳細 |
|------|------|
| ソースディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/LibSodium/libsodium` |
| インストールディレクトリ | `${CMAKE_CURRENT_SOURCE_DIR}/download/LibSodium/libsodium-install` |
| ダウンロード URL | https://github.com/jedisct1/libsodium/archive/refs/tags/1.0.21-RELEASE.tar.gz |
| フォールバック URL | https://download.libsodium.org/libsodium/releases/libsodium-1.0.21.tar.gz |
| バージョン | 1.0.21 |
| ライセンス | ISC |

---

## インクルードガード

```cmake
include_guard(GLOBAL)
```

このファイルは `include_guard(GLOBAL)` を使用して、複数回インクルードされても一度だけ実行されることを保証します。

**必要な理由:**

- configure 中の `execute_process` の重複実行を防止
- `target_link_libraries` での重複リンクを防止

---

## ディレクトリ構成

```
LibSodium/
├── cmake/
│   ├── LibSodium.cmake       # この設定ファイル
│   ├── LibSodiumCmake.md     # 英語版ドキュメント
│   └── LibSodiumCmake-jp.md  # このドキュメント
├── download/LibSodium/libsodium
│   ├── libsodium/            # libsodium ソース（GitHub からダウンロード・キャッシュ）
│   └── libsodium-install/    # libsodium ビルド成果物（lib/, include/）
│       ├── include/
│       │   ├── sodium.h
│       │   └── sodium/
│       │       ├── core.h
│       │       ├── crypto_secretbox.h
│       │       ├── crypto_box.h
│       │       ├── crypto_sign.h
│       │       ├── crypto_generichash.h
│       │       ├── crypto_pwhash.h
│       │       ├── crypto_kx.h
│       │       ├── randombytes.h
│       │       └── ...（他多数）
│       └── lib/
│           └── libsodium.a
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## 使い方

### CMakeLists.txt への追加

```cmake
# CMakeLists.txt の末尾に LibSodium.cmake をインクルード
include("./cmake/LibSodium.cmake")
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
set(LIBSODIUM_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/LibSodium)
set(LIBSODIUM_SOURCE_DIR ${LIBSODIUM_DOWNLOAD_DIR}/libsodium)
set(LIBSODIUM_INSTALL_DIR ${LIBSODIUM_DOWNLOAD_DIR}/libsodium-install)
set(LIBSODIUM_VERSION "1.0.21")
set(LIBSODIUM_URL "https://github.com/jedisct1/libsodium/archive/refs/tags/${LIBSODIUM_VERSION}-RELEASE.tar.gz")
```

### 2. キャッシュチェックと条件付きビルド

```cmake
if(EXISTS ${LIBSODIUM_INSTALL_DIR}/lib/libsodium.a)
    message(STATUS "libsodium already built: ${LIBSODIUM_INSTALL_DIR}/lib/libsodium.a")
else()
    # ダウンロード、設定、ビルド、インストール ...
endif()
```

キャッシュロジックは以下の通りです:

| 条件 | アクション |
|------|-----------|
| `libsodium-install/lib/libsodium.a` が存在 | すべてスキップ（キャッシュ済みビルドを使用） |
| `libsodium/configure` が存在（インストールなし） | ダウンロードをスキップし、configure/make/make install を実行 |
| 何も存在しない | ダウンロード、展開、設定、ビルド、インストール |

### 3. ダウンロード（必要な場合）

```cmake
file(DOWNLOAD
    ${LIBSODIUM_URL}
    ${LIBSODIUM_DOWNLOAD_DIR}/libsodium-${LIBSODIUM_VERSION}.tar.gz
    SHOW_PROGRESS
    STATUS DOWNLOAD_STATUS
)
file(ARCHIVE_EXTRACT
    INPUT ${LIBSODIUM_DOWNLOAD_DIR}/libsodium-${LIBSODIUM_VERSION}.tar.gz
    DESTINATION ${LIBSODIUM_DOWNLOAD_DIR}
)
file(RENAME ${LIBSODIUM_DOWNLOAD_DIR}/libsodium-${LIBSODIUM_VERSION}-RELEASE ${LIBSODIUM_SOURCE_DIR})
```

- GitHub（jedisct1/libsodium リリース）からダウンロード、download.libsodium.org をフォールバック先として使用
- `libsodium-1.0.21-RELEASE/` を `libsodium/` にリネームしてパスを整理

### 4. 設定とビルド（autoconf ベース）

```cmake
# GitHub アーカイブに ./configure がない場合、autogen.sh を先に実行
execute_process(
    COMMAND sh autogen.sh
    WORKING_DIRECTORY ${LIBSODIUM_SOURCE_DIR}
)

execute_process(
    COMMAND ${LIBSODIUM_SOURCE_DIR}/configure
            --prefix=${LIBSODIUM_INSTALL_DIR}
            --disable-shared
            --enable-static
            --with-pic
    WORKING_DIRECTORY ${LIBSODIUM_SOURCE_DIR}
)
execute_process(
    COMMAND make -j4
    WORKING_DIRECTORY ${LIBSODIUM_SOURCE_DIR}
)
```

- autoconf（`./configure && make`）を使用、CMake ではない
- `--disable-shared --enable-static`: スタティックライブラリのみビルド
- `--with-pic`: 位置独立コードを生成
- すべてのステップは CMake configure 時に実行され、ビルド時ではない

### 5. インストール

libsodium の configure スクリプトには適切なインストールルールが含まれているため、`make install` が直接動作します:

```cmake
execute_process(
    COMMAND make install
    WORKING_DIRECTORY ${LIBSODIUM_SOURCE_DIR}
)
```

ヘッダは `libsodium-install/include/` に、スタティックライブラリは `libsodium-install/lib/` にインストールされます。

### 6. ライブラリのリンク

```cmake
add_library(sodium_lib STATIC IMPORTED)
set_target_properties(sodium_lib PROPERTIES
    IMPORTED_LOCATION ${LIBSODIUM_INSTALL_DIR}/lib/libsodium.a
)

target_include_directories(${PROJECT_NAME} PRIVATE ${LIBSODIUM_INSTALL_DIR}/include)
target_link_libraries(${PROJECT_NAME} PRIVATE sodium_lib)
```

libsodium はほとんどのプラットフォームで追加の依存ライブラリを必要としない自己完結型ライブラリです。

---

## libsodium ライブラリ

libsodium は単一のライブラリで構成されます:

| ライブラリ | ファイル | 説明 |
|-----------|---------|------|
| `libsodium` | `libsodium.a` | libsodium 暗号化ライブラリの全機能 |

ライブラリは C で書かれており、各種 CPU アーキテクチャ（x86_64 SSE/AVX、ARM NEON 等）に最適化された実装を使用します。

---

## libsodium の主要機能

| 機能 | API 関数 | 説明 |
|------|---------|------|
| 初期化 | `sodium_init` | ライブラリの初期化（最初に呼び出す必要あり） |
| 乱数生成 | `randombytes_buf`, `randombytes_random`, `randombytes_uniform` | 暗号学的に安全な乱数生成 |
| 決定性乱数 | `randombytes_buf_deterministic` | シードからの決定性乱数 |
| 秘密鍵暗号化 | `crypto_secretbox_easy`, `crypto_secretbox_open_easy` | XSalsa20-Poly1305 認証付き暗号化 |
| 秘密鍵生成 | `crypto_secretbox_keygen` | ランダムな秘密鍵の生成 |
| 公開鍵暗号化 | `crypto_box_easy`, `crypto_box_open_easy` | X25519-XSalsa20-Poly1305 認証付き暗号化 |
| シールドボックス | `crypto_box_seal`, `crypto_box_seal_open` | 匿名公開鍵暗号化 |
| 鍵ペア生成 | `crypto_box_keypair`, `crypto_sign_keypair` | 公開鍵/秘密鍵ペアの生成 |
| 汎用ハッシュ | `crypto_generichash`, `crypto_generichash_init/update/final` | BLAKE2b ハッシュ（シングルパスとストリーミング） |
| 鍵付きハッシュ | `crypto_generichash`（鍵付き）, `crypto_generichash_keygen` | BLAKE2b 鍵付きハッシュ（MAC） |
| パスワードハッシュ | `crypto_pwhash_str`, `crypto_pwhash_str_verify` | Argon2id パスワードハッシュと検証 |
| 鍵導出 | `crypto_pwhash` | パスワードからの鍵導出 |
| 鍵交換 | `crypto_kx_keypair`, `crypto_kx_client_session_keys`, `crypto_kx_server_session_keys` | X25519 鍵交換 |
| デジタル署名 | `crypto_sign_detached`, `crypto_sign_verify_detached` | Ed25519 デジタル署名 |
| セキュアメモリ | `sodium_malloc`, `sodium_free`, `sodium_mprotect_readonly` | ガード付きメモリ確保 |
| メモリゼロ化 | `sodium_memzero` | セキュアなメモリ消去（コンパイラ最適化を防止） |
| 定数時間比較 | `sodium_memcmp` | タイミングセーフなメモリ比較 |
| 16進エンコード | `sodium_bin2hex`, `sodium_hex2bin` | バイナリと16進数の相互変換 |
| Base64 エンコード | `sodium_bin2base64`, `sodium_base642bin` | バイナリと Base64 の相互変換 |
| バージョン情報 | `sodium_version_string` | ライブラリバージョン文字列の取得 |

---

## C/C++ での使用例

### 初期化と乱数生成

```cpp
#include <sodium.h>
#include <cstdio>

int main() {
    if (sodium_init() < 0) {
        return 1;  // ライブラリの初期化に失敗
    }

    // ランダムな32ビット整数
    uint32_t r = randombytes_random();
    printf("乱数: %u\n", r);

    // ランダムバイト列
    unsigned char buf[32];
    randombytes_buf(buf, sizeof(buf));

    return 0;
}
```

### 秘密鍵認証付き暗号化

```cpp
#include <sodium.h>
#include <cstdio>
#include <cstring>
#include <vector>

int main() {
    if (sodium_init() < 0) return 1;

    const char *message = "秘密のメッセージ";
    size_t message_len = strlen(message);

    unsigned char key[crypto_secretbox_KEYBYTES];
    unsigned char nonce[crypto_secretbox_NONCEBYTES];
    crypto_secretbox_keygen(key);
    randombytes_buf(nonce, sizeof(nonce));

    // 暗号化
    size_t ciphertext_len = crypto_secretbox_MACBYTES + message_len;
    std::vector<unsigned char> ciphertext(ciphertext_len);
    crypto_secretbox_easy(ciphertext.data(),
        (const unsigned char *)message, message_len, nonce, key);

    // 復号
    std::vector<unsigned char> decrypted(message_len);
    if (crypto_secretbox_open_easy(decrypted.data(),
            ciphertext.data(), ciphertext_len, nonce, key) == 0) {
        printf("復号結果: %.*s\n", (int)message_len, decrypted.data());
    }

    return 0;
}
```

### 汎用ハッシュ（BLAKE2b）

```cpp
#include <sodium.h>
#include <cstdio>
#include <cstring>

int main() {
    if (sodium_init() < 0) return 1;

    const char *message = "ハッシュ対象";
    unsigned char hash[crypto_generichash_BYTES];

    crypto_generichash(hash, sizeof(hash),
        (const unsigned char *)message, strlen(message), NULL, 0);

    char hex[crypto_generichash_BYTES * 2 + 1];
    sodium_bin2hex(hex, sizeof(hex), hash, sizeof(hash));
    printf("BLAKE2b: %s\n", hex);

    return 0;
}
```

### パスワードハッシュ（Argon2id）

```cpp
#include <sodium.h>
#include <cstdio>
#include <cstring>

int main() {
    if (sodium_init() < 0) return 1;

    const char *password = "私の秘密のパスワード";
    char hashed[crypto_pwhash_STRBYTES];

    // パスワードをハッシュ化
    crypto_pwhash_str(hashed, password, strlen(password),
        crypto_pwhash_OPSLIMIT_INTERACTIVE,
        crypto_pwhash_MEMLIMIT_INTERACTIVE);

    // 検証
    if (crypto_pwhash_str_verify(hashed, password, strlen(password)) == 0) {
        printf("パスワード OK\n");
    }

    return 0;
}
```

### デジタル署名（Ed25519）

```cpp
#include <sodium.h>
#include <cstdio>
#include <cstring>

int main() {
    if (sodium_init() < 0) return 1;

    unsigned char pk[crypto_sign_PUBLICKEYBYTES];
    unsigned char sk[crypto_sign_SECRETKEYBYTES];
    crypto_sign_keypair(pk, sk);

    const char *message = "署名対象のメッセージ";
    unsigned char sig[crypto_sign_BYTES];
    crypto_sign_detached(sig, NULL,
        (const unsigned char *)message, strlen(message), sk);

    if (crypto_sign_verify_detached(sig,
            (const unsigned char *)message, strlen(message), pk) == 0) {
        printf("署名検証成功\n");
    }

    return 0;
}
```

### 鍵交換（X25519）

```cpp
#include <sodium.h>
#include <cstdio>

int main() {
    if (sodium_init() < 0) return 1;

    // クライアントとサーバーが鍵ペアを生成
    unsigned char client_pk[crypto_kx_PUBLICKEYBYTES], client_sk[crypto_kx_SECRETKEYBYTES];
    unsigned char server_pk[crypto_kx_PUBLICKEYBYTES], server_sk[crypto_kx_SECRETKEYBYTES];
    crypto_kx_keypair(client_pk, client_sk);
    crypto_kx_keypair(server_pk, server_sk);

    // セッション鍵を導出
    unsigned char client_rx[crypto_kx_SESSIONKEYBYTES], client_tx[crypto_kx_SESSIONKEYBYTES];
    unsigned char server_rx[crypto_kx_SESSIONKEYBYTES], server_tx[crypto_kx_SESSIONKEYBYTES];

    crypto_kx_client_session_keys(client_rx, client_tx, client_pk, client_sk, server_pk);
    crypto_kx_server_session_keys(server_rx, server_tx, server_pk, server_sk, client_pk);

    // client_tx == server_rx, client_rx == server_tx
    if (sodium_memcmp(client_tx, server_rx, crypto_kx_SESSIONKEYBYTES) == 0) {
        printf("鍵交換成功\n");
    }

    return 0;
}
```

### セキュアメモリ

```cpp
#include <sodium.h>
#include <cstdio>

int main() {
    if (sodium_init() < 0) return 1;

    // ガード付きメモリを確保（カナリアとガードページ付き）
    unsigned char *secret = (unsigned char *)sodium_malloc(32);
    randombytes_buf(secret, 32);

    // 読み取り専用に設定（書き込みはクラッシュ）
    sodium_mprotect_readonly(secret);

    // 読み書き可能に戻す
    sodium_mprotect_readwrite(secret);

    // セキュアに消去して解放
    sodium_memzero(secret, 32);
    sodium_free(secret);

    return 0;
}
```

---

## libsodium API の規約

### 関数命名規則

libsodium の関数名は一貫したプレフィックス規則に従います:

| パターン | 例 | 説明 |
|---------|-----|------|
| `sodium_*` | `sodium_init()` | コアライブラリ関数 |
| `crypto_secretbox_*` | `crypto_secretbox_easy(...)` | 秘密鍵認証付き暗号化 |
| `crypto_box_*` | `crypto_box_easy(...)` | 公開鍵認証付き暗号化 |
| `crypto_sign_*` | `crypto_sign_detached(...)` | デジタル署名 |
| `crypto_generichash_*` | `crypto_generichash(...)` | 汎用ハッシュ（BLAKE2b） |
| `crypto_pwhash_*` | `crypto_pwhash_str(...)` | パスワードハッシュ（Argon2id） |
| `crypto_kx_*` | `crypto_kx_keypair(...)` | 鍵交換 |
| `crypto_aead_*` | `crypto_aead_xchacha20poly1305_ietf_encrypt(...)` | AEAD 暗号化 |
| `randombytes_*` | `randombytes_buf(...)` | 乱数生成 |

### メモリ管理

ほとんどの libsodium 関数は、呼び出し側が提供するバッファに書き込みます。呼び出し側がこれらのバッファの確保と解放を行う責任があります。`crypto_secretbox_KEYBYTES` などの定数が必要なバッファサイズを定義します。

機密データには、標準の `malloc()`/`free()` の代わりに `sodium_malloc()` と `sodium_free()` を使用してください:

```cpp
unsigned char *key = (unsigned char *)sodium_malloc(crypto_secretbox_KEYBYTES);
// ... key を使用 ...
sodium_free(key);  // 解放前に自動的にメモリをゼロ化
```

### 戻り値

- ほとんどの関数は成功時に `0`、失敗時に `-1` を返す
- `sodium_init()` は成功時に `0`、初期化済みの場合は `1`、失敗時に `-1` を返す
- `crypto_pwhash_str_verify()` はパスワードが一致した場合に `0`、それ以外は `-1` を返す
- `sodium_memcmp()` はバッファが等しい場合に `0` を返す（定数時間）

### 定数

バッファサイズはコンパイル時定数として定義されています:

| 定数 | 値 | 説明 |
|------|-----|------|
| `crypto_secretbox_KEYBYTES` | 32 | 秘密鍵サイズ |
| `crypto_secretbox_NONCEBYTES` | 24 | ノンスサイズ |
| `crypto_secretbox_MACBYTES` | 16 | 認証タグサイズ |
| `crypto_box_PUBLICKEYBYTES` | 32 | 公開鍵サイズ |
| `crypto_box_SECRETKEYBYTES` | 32 | 秘密鍵サイズ |
| `crypto_sign_PUBLICKEYBYTES` | 32 | 署名用公開鍵サイズ |
| `crypto_sign_SECRETKEYBYTES` | 64 | 署名用秘密鍵サイズ |
| `crypto_sign_BYTES` | 64 | 署名サイズ |
| `crypto_generichash_BYTES` | 32 | デフォルトハッシュ出力サイズ |
| `crypto_pwhash_STRBYTES` | 128 | パスワードハッシュ文字列サイズ |

---

## 比較: libsodium vs 他の暗号化ライブラリ

| 機能 | libsodium | OpenSSL | Botan | libgcrypt |
|------|-----------|---------|-------|-----------|
| 言語 | C | C | C++ | C |
| ライセンス | ISC | Apache 2.0 | BSD | LGPL |
| API の複雑さ | シンプル | 複雑 | 中程度 | 複雑 |
| 誤用耐性 | 高い | 低い | 中程度 | 低い |
| 鍵交換 | X25519 | ECDH/X25519 | ECDH/X25519 | ECDH |
| AEAD | XChaCha20-Poly1305 | AES-GCM, ChaCha20 | AES-GCM, ChaCha20 | AES-GCM |
| パスワードハッシュ | Argon2id | scrypt, PBKDF2 | Argon2, bcrypt | scrypt |
| デジタル署名 | Ed25519 | ECDSA, Ed25519 | ECDSA, Ed25519 | ECDSA |
| ハッシュ | BLAKE2b, SHA-256/512 | SHA 系, BLAKE2 | SHA, BLAKE2 | SHA 系 |
| セキュアメモリ | 対応 | 非対応 | 非対応 | 対応 |
| コードサイズ | 約30000行 | 約500000行 | 約200000行 | 約100000行 |
| 依存ライブラリ | なし | なし | なし | libgpg-error |

libsodium は、厳選された高品質な暗号プリミティブを、誤用しにくい API で提供することに重点を置いています。フル機能の TLS ライブラリの複雑さを必要とせず、モダンでセキュアバイデフォルトな暗号化が必要なアプリケーションに特に適しています。

---

## 環境変数

| 変数 | 効果 |
|------|------|
| `SODIUM_DISABLE_AES256GCM` | 設定されている場合、ハードウェアサポートがあっても AES-256-GCM を無効化 |

---

## トラブルシューティング

### ダウンロードに失敗する場合

GitHub にアクセスできない場合、手動でダウンロードしてファイルを配置できます:

```bash
curl -L -o download/LibSodium/libsodium-1.0.21.tar.gz \
    https://github.com/jedisct1/libsodium/archive/refs/tags/1.0.21-RELEASE.tar.gz
```

その後 `cmake ..` を再実行すると、キャッシュされたアーカイブからの展開が進みます。

### ビルドに失敗する場合

CMake 3.20 以上、C99 対応のコンパイラ、および autotools が利用可能であることを確認してください:

```bash
cmake --version
cc --version
autoconf --version  # autogen.sh の実行が必要な場合のみ
```

### autogen.sh に失敗する場合

`autogen.sh` が失敗する場合、autotools のインストールが必要な場合があります:

```bash
# macOS
brew install autoconf automake libtool

# Ubuntu/Debian
sudo apt-get install autoconf automake libtool
```

または、事前生成された `configure` スクリプトを含む公式リリースページからダウンロードしてください:

```bash
curl -L -o download/LibSodium/libsodium-1.0.21.tar.gz \
    https://download.libsodium.org/libsodium/releases/libsodium-1.0.21.tar.gz
```

### libsodium を最初からリビルドする場合

完全なリビルドを強制するには、インストールディレクトリとソースディレクトリを削除します:

```bash
rm -rf download/LibSodium/libsodium-install download/LibSodium/libsodium
cd build && cmake ..
```

### ヘッダが見つからない: `sodium.h`

`'sodium.h' file not found` が表示される場合は、ビルドが少なくとも一度完了していることを確認してください。ヘッダは CMake configure ステップ中にインストールディレクトリにコピーされます:

```bash
cd build && cmake .. && make
```

ビルドが成功すると、`compile_commands.json` が更新され、IDE の診断エラーは解消されます。

---

## 参考資料

- [libsodium GitHub リポジトリ](https://github.com/jedisct1/libsodium)
- [libsodium ドキュメント](https://doc.libsodium.org/)
- [libsodium インストールガイド](https://doc.libsodium.org/installation)
- [秘密鍵暗号化](https://doc.libsodium.org/secret-key_cryptography/secretbox)
- [公開鍵暗号化](https://doc.libsodium.org/public-key_cryptography/authenticated_encryption)
- [シールドボックス](https://doc.libsodium.org/public-key_cryptography/sealed_boxes)
- [汎用ハッシュ](https://doc.libsodium.org/hashing/generic_hashing)
- [パスワードハッシュ](https://doc.libsodium.org/password_hashing)
- [鍵交換](https://doc.libsodium.org/key_exchange)
- [デジタル署名](https://doc.libsodium.org/public-key_cryptography/public-key_signatures)
- [セキュアメモリ](https://doc.libsodium.org/memory_management)
