# LibSodium.cmake Reference

## Overview

`LibSodium.cmake` is a CMake configuration file that automatically downloads, builds, and links the libsodium library.
It uses CMake's `file(DOWNLOAD)` and `execute_process` to manage the dependency, with caching in the `download/` directory to avoid redundant downloads and rebuilds.

libsodium is a modern, portable, easy-to-use cryptographic library. It provides authenticated encryption, key exchange, digital signatures, password hashing, secret-key encryption, public-key encryption, secure memory management, and random number generation.

libsodium uses the autoconf build system (`./configure && make && make install`).

## File Information

| Item | Details |
|------|---------|
| Source Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/LibSodium/libsodium` |
| Install Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/LibSodium/libsodium-install` |
| Download URL | https://github.com/jedisct1/libsodium/archive/refs/tags/1.0.21-RELEASE.tar.gz |
| Fallback URL | https://download.libsodium.org/libsodium/releases/libsodium-1.0.21.tar.gz |
| Version | 1.0.21 |
| License | ISC |

---

## Include Guard

```cmake
include_guard(GLOBAL)
```

This file uses `include_guard(GLOBAL)` to ensure it is only executed once, even if included multiple times.

**Why it's needed:**

- Prevents duplicate `execute_process` invocations during configure
- Prevents duplicate linking in `target_link_libraries`

---

## Directory Structure

```
LibSodium/
├── cmake/
│   ├── LibSodium.cmake       # This configuration file
│   ├── LibSodiumCmake.md     # This document
│   └── LibSodiumCmake-jp.md  # Japanese version of this document
├── download/LibSodium/libsodium
│   ├── libsodium/            # libsodium source (cached, downloaded from GitHub)
│   └── libsodium-install/    # libsodium built artifacts (lib/, include/)
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
│       │       └── ... (many more)
│       └── lib/
│           └── libsodium.a
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## Usage

### Adding to CMakeLists.txt

```cmake
# Include LibSodium.cmake at the end of CMakeLists.txt
include("./cmake/LibSodium.cmake")
```

### Build

```bash
mkdir build && cd build
cmake ..
make
```

---

## Processing Flow

### 1. Setting the Directory Paths

```cmake
set(LIBSODIUM_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/LibSodium)
set(LIBSODIUM_SOURCE_DIR ${LIBSODIUM_DOWNLOAD_DIR}/libsodium)
set(LIBSODIUM_INSTALL_DIR ${LIBSODIUM_DOWNLOAD_DIR}/libsodium-install)
set(LIBSODIUM_VERSION "1.0.21")
set(LIBSODIUM_URL "https://github.com/jedisct1/libsodium/archive/refs/tags/${LIBSODIUM_VERSION}-RELEASE.tar.gz")
```

### 2. Cache Check and Conditional Build

```cmake
if(EXISTS ${LIBSODIUM_INSTALL_DIR}/lib/libsodium.a)
    message(STATUS "libsodium already built: ${LIBSODIUM_INSTALL_DIR}/lib/libsodium.a")
else()
    # Download, configure, build, and install ...
endif()
```

The cache logic works as follows:

| Condition | Action |
|-----------|--------|
| `libsodium-install/lib/libsodium.a` exists | Skip everything (use cached build) |
| `libsodium/configure` exists (install missing) | Skip download, run configure/make/make install |
| Nothing exists | Download, extract, configure, build, install |

### 3. Download (if needed)

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

- Downloads from GitHub (jedisct1/libsodium releases) with fallback to download.libsodium.org
- Extracts and renames `libsodium-1.0.21-RELEASE/` to `libsodium/` for a clean path

### 4. Configure and Build (autoconf-based)

```cmake
# If GitHub archive lacks ./configure, run autogen.sh first
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

- Uses autoconf (`./configure && make`), not CMake
- `--disable-shared --enable-static`: Builds only the static library
- `--with-pic`: Generates position-independent code
- All steps run at CMake configure time, not at build time

### 5. Install

libsodium's configure script includes proper install rules, so `make install` works directly:

```cmake
execute_process(
    COMMAND make install
    WORKING_DIRECTORY ${LIBSODIUM_SOURCE_DIR}
)
```

This installs headers to `libsodium-install/include/` and the static library to `libsodium-install/lib/`.

### 6. Linking the Library

```cmake
add_library(sodium_lib STATIC IMPORTED)
set_target_properties(sodium_lib PROPERTIES
    IMPORTED_LOCATION ${LIBSODIUM_INSTALL_DIR}/lib/libsodium.a
)

target_include_directories(${PROJECT_NAME} PRIVATE ${LIBSODIUM_INSTALL_DIR}/include)
target_link_libraries(${PROJECT_NAME} PRIVATE sodium_lib)
```

libsodium is a self-contained library with no additional dependencies on most platforms.

---

## libsodium Library

libsodium consists of a single library:

| Library | File | Description |
|---------|------|-------------|
| `libsodium` | `libsodium.a` | The complete libsodium cryptographic library |

The library is written in C and uses optimized implementations for various CPU architectures (x86_64 SSE/AVX, ARM NEON, etc.).

---

## Key Features of libsodium

| Feature | API Functions | Description |
|---------|---------------|-------------|
| Initialization | `sodium_init` | Initialize the library (must be called first) |
| Random Numbers | `randombytes_buf`, `randombytes_random`, `randombytes_uniform` | Cryptographically secure random number generation |
| Deterministic Random | `randombytes_buf_deterministic` | Deterministic random from a seed |
| Secret-key Encryption | `crypto_secretbox_easy`, `crypto_secretbox_open_easy` | XSalsa20-Poly1305 authenticated encryption |
| Secret-key Keygen | `crypto_secretbox_keygen` | Generate a random secret key |
| Public-key Encryption | `crypto_box_easy`, `crypto_box_open_easy` | X25519-XSalsa20-Poly1305 authenticated encryption |
| Sealed Boxes | `crypto_box_seal`, `crypto_box_seal_open` | Anonymous public-key encryption |
| Key Pair Generation | `crypto_box_keypair`, `crypto_sign_keypair` | Generate public/secret key pairs |
| Generic Hashing | `crypto_generichash`, `crypto_generichash_init/update/final` | BLAKE2b hashing (single-pass and streaming) |
| Keyed Hashing | `crypto_generichash` (with key), `crypto_generichash_keygen` | BLAKE2b keyed hashing (MAC) |
| Password Hashing | `crypto_pwhash_str`, `crypto_pwhash_str_verify` | Argon2id password hashing and verification |
| Key Derivation | `crypto_pwhash` | Derive keys from passwords |
| Key Exchange | `crypto_kx_keypair`, `crypto_kx_client_session_keys`, `crypto_kx_server_session_keys` | X25519 key exchange |
| Digital Signatures | `crypto_sign_detached`, `crypto_sign_verify_detached` | Ed25519 digital signatures |
| Secure Memory | `sodium_malloc`, `sodium_free`, `sodium_mprotect_readonly` | Guarded memory allocations |
| Memory Zeroing | `sodium_memzero` | Secure memory erasure (prevents compiler optimization) |
| Constant-time Compare | `sodium_memcmp` | Timing-safe memory comparison |
| Hex Encoding | `sodium_bin2hex`, `sodium_hex2bin` | Binary to/from hexadecimal conversion |
| Base64 Encoding | `sodium_bin2base64`, `sodium_base642bin` | Binary to/from Base64 conversion |
| Version Info | `sodium_version_string` | Get library version string |

---

## Usage Examples in C/C++

### Initialization and Random Numbers

```cpp
#include <sodium.h>
#include <cstdio>

int main() {
    if (sodium_init() < 0) {
        return 1;  // library initialization failed
    }

    // Random 32-bit integer
    uint32_t r = randombytes_random();
    printf("Random: %u\n", r);

    // Random bytes
    unsigned char buf[32];
    randombytes_buf(buf, sizeof(buf));

    return 0;
}
```

### Secret-key Authenticated Encryption

```cpp
#include <sodium.h>
#include <cstdio>
#include <cstring>
#include <vector>

int main() {
    if (sodium_init() < 0) return 1;

    const char *message = "Secret message";
    size_t message_len = strlen(message);

    unsigned char key[crypto_secretbox_KEYBYTES];
    unsigned char nonce[crypto_secretbox_NONCEBYTES];
    crypto_secretbox_keygen(key);
    randombytes_buf(nonce, sizeof(nonce));

    // Encrypt
    size_t ciphertext_len = crypto_secretbox_MACBYTES + message_len;
    std::vector<unsigned char> ciphertext(ciphertext_len);
    crypto_secretbox_easy(ciphertext.data(),
        (const unsigned char *)message, message_len, nonce, key);

    // Decrypt
    std::vector<unsigned char> decrypted(message_len);
    if (crypto_secretbox_open_easy(decrypted.data(),
            ciphertext.data(), ciphertext_len, nonce, key) == 0) {
        printf("Decrypted: %.*s\n", (int)message_len, decrypted.data());
    }

    return 0;
}
```

### Generic Hashing (BLAKE2b)

```cpp
#include <sodium.h>
#include <cstdio>
#include <cstring>

int main() {
    if (sodium_init() < 0) return 1;

    const char *message = "Hash me";
    unsigned char hash[crypto_generichash_BYTES];

    crypto_generichash(hash, sizeof(hash),
        (const unsigned char *)message, strlen(message), NULL, 0);

    char hex[crypto_generichash_BYTES * 2 + 1];
    sodium_bin2hex(hex, sizeof(hex), hash, sizeof(hash));
    printf("BLAKE2b: %s\n", hex);

    return 0;
}
```

### Password Hashing (Argon2id)

```cpp
#include <sodium.h>
#include <cstdio>
#include <cstring>

int main() {
    if (sodium_init() < 0) return 1;

    const char *password = "my secret password";
    char hashed[crypto_pwhash_STRBYTES];

    // Hash the password
    crypto_pwhash_str(hashed, password, strlen(password),
        crypto_pwhash_OPSLIMIT_INTERACTIVE,
        crypto_pwhash_MEMLIMIT_INTERACTIVE);

    // Verify
    if (crypto_pwhash_str_verify(hashed, password, strlen(password)) == 0) {
        printf("Password OK\n");
    }

    return 0;
}
```

### Digital Signatures (Ed25519)

```cpp
#include <sodium.h>
#include <cstdio>
#include <cstring>

int main() {
    if (sodium_init() < 0) return 1;

    unsigned char pk[crypto_sign_PUBLICKEYBYTES];
    unsigned char sk[crypto_sign_SECRETKEYBYTES];
    crypto_sign_keypair(pk, sk);

    const char *message = "Sign this";
    unsigned char sig[crypto_sign_BYTES];
    crypto_sign_detached(sig, NULL,
        (const unsigned char *)message, strlen(message), sk);

    if (crypto_sign_verify_detached(sig,
            (const unsigned char *)message, strlen(message), pk) == 0) {
        printf("Signature valid\n");
    }

    return 0;
}
```

### Key Exchange (X25519)

```cpp
#include <sodium.h>
#include <cstdio>

int main() {
    if (sodium_init() < 0) return 1;

    // Client and server generate key pairs
    unsigned char client_pk[crypto_kx_PUBLICKEYBYTES], client_sk[crypto_kx_SECRETKEYBYTES];
    unsigned char server_pk[crypto_kx_PUBLICKEYBYTES], server_sk[crypto_kx_SECRETKEYBYTES];
    crypto_kx_keypair(client_pk, client_sk);
    crypto_kx_keypair(server_pk, server_sk);

    // Derive session keys
    unsigned char client_rx[crypto_kx_SESSIONKEYBYTES], client_tx[crypto_kx_SESSIONKEYBYTES];
    unsigned char server_rx[crypto_kx_SESSIONKEYBYTES], server_tx[crypto_kx_SESSIONKEYBYTES];

    crypto_kx_client_session_keys(client_rx, client_tx, client_pk, client_sk, server_pk);
    crypto_kx_server_session_keys(server_rx, server_tx, server_pk, server_sk, client_pk);

    // client_tx == server_rx, client_rx == server_tx
    if (sodium_memcmp(client_tx, server_rx, crypto_kx_SESSIONKEYBYTES) == 0) {
        printf("Key exchange successful\n");
    }

    return 0;
}
```

### Secure Memory

```cpp
#include <sodium.h>
#include <cstdio>

int main() {
    if (sodium_init() < 0) return 1;

    // Allocate guarded memory (with canary and guard pages)
    unsigned char *secret = (unsigned char *)sodium_malloc(32);
    randombytes_buf(secret, 32);

    // Make read-only (writes will crash)
    sodium_mprotect_readonly(secret);

    // Make read-write again
    sodium_mprotect_readwrite(secret);

    // Securely erase and free
    sodium_memzero(secret, 32);
    sodium_free(secret);

    return 0;
}
```

---

## libsodium API Conventions

### Function Naming Conventions

libsodium function names follow consistent prefix conventions:

| Pattern | Example | Description |
|---------|---------|-------------|
| `sodium_*` | `sodium_init()` | Core library functions |
| `crypto_secretbox_*` | `crypto_secretbox_easy(...)` | Secret-key authenticated encryption |
| `crypto_box_*` | `crypto_box_easy(...)` | Public-key authenticated encryption |
| `crypto_sign_*` | `crypto_sign_detached(...)` | Digital signatures |
| `crypto_generichash_*` | `crypto_generichash(...)` | Generic hashing (BLAKE2b) |
| `crypto_pwhash_*` | `crypto_pwhash_str(...)` | Password hashing (Argon2id) |
| `crypto_kx_*` | `crypto_kx_keypair(...)` | Key exchange |
| `crypto_aead_*` | `crypto_aead_xchacha20poly1305_ietf_encrypt(...)` | AEAD encryption |
| `randombytes_*` | `randombytes_buf(...)` | Random number generation |

### Memory Management

Most libsodium functions write to caller-provided buffers. The caller is responsible for allocating and freeing these buffers. Constants like `crypto_secretbox_KEYBYTES` define the required buffer sizes.

For sensitive data, use `sodium_malloc()` and `sodium_free()` instead of standard `malloc()`/`free()`:

```cpp
unsigned char *key = (unsigned char *)sodium_malloc(crypto_secretbox_KEYBYTES);
// ... use key ...
sodium_free(key);  // automatically zeros memory before freeing
```

### Return Values

- Most functions return `0` on success, `-1` on failure
- `sodium_init()` returns `0` on success, `1` if already initialized, `-1` on failure
- `crypto_pwhash_str_verify()` returns `0` if password matches, `-1` otherwise
- `sodium_memcmp()` returns `0` if buffers are equal (constant-time)

### Constants

Buffer sizes are defined as compile-time constants:

| Constant | Value | Description |
|----------|-------|-------------|
| `crypto_secretbox_KEYBYTES` | 32 | Secret key size |
| `crypto_secretbox_NONCEBYTES` | 24 | Nonce size |
| `crypto_secretbox_MACBYTES` | 16 | Authentication tag size |
| `crypto_box_PUBLICKEYBYTES` | 32 | Public key size |
| `crypto_box_SECRETKEYBYTES` | 32 | Secret key size |
| `crypto_sign_PUBLICKEYBYTES` | 32 | Signing public key size |
| `crypto_sign_SECRETKEYBYTES` | 64 | Signing secret key size |
| `crypto_sign_BYTES` | 64 | Signature size |
| `crypto_generichash_BYTES` | 32 | Default hash output size |
| `crypto_pwhash_STRBYTES` | 128 | Password hash string size |

---

## Comparison: libsodium vs Other Crypto Libraries

| Feature | libsodium | OpenSSL | Botan | libgcrypt |
|---------|-----------|---------|-------|-----------|
| Language | C | C | C++ | C |
| License | ISC | Apache 2.0 | BSD | LGPL |
| API Complexity | Simple | Complex | Moderate | Complex |
| Misuse Resistance | High | Low | Moderate | Low |
| Key Exchange | X25519 | ECDH/X25519 | ECDH/X25519 | ECDH |
| AEAD | XChaCha20-Poly1305 | AES-GCM, ChaCha20 | AES-GCM, ChaCha20 | AES-GCM |
| Password Hashing | Argon2id | scrypt, PBKDF2 | Argon2, bcrypt | scrypt |
| Digital Signatures | Ed25519 | ECDSA, Ed25519 | ECDSA, Ed25519 | ECDSA |
| Hashing | BLAKE2b, SHA-256/512 | SHA family, BLAKE2 | SHA, BLAKE2 | SHA family |
| Secure Memory | Yes | No | No | Yes |
| Code Size | ~30000 lines | ~500000 lines | ~200000 lines | ~100000 lines |
| Dependencies | None | None | None | libgpg-error |

libsodium focuses on providing a small, carefully selected set of high-quality cryptographic primitives with a hard-to-misuse API. It is particularly suitable for applications that need modern, secure-by-default cryptography without the complexity of full-featured TLS libraries.

---

## Environment Variables

| Variable | Effect |
|----------|--------|
| `SODIUM_DISABLE_AES256GCM` | When set, disables AES-256-GCM even if hardware support is available |

---

## Troubleshooting

### Download Fails

If GitHub is unreachable, you can manually download and place the tarball:

```bash
curl -L -o download/LibSodium/libsodium-1.0.21.tar.gz \
    https://github.com/jedisct1/libsodium/archive/refs/tags/1.0.21-RELEASE.tar.gz
```

Then re-run `cmake ..` and the extraction will proceed from the cached tarball.

### Build Fails

Ensure that CMake 3.20+, a C99-compatible compiler, and autotools are available:

```bash
cmake --version
cc --version
autoconf --version  # only needed if autogen.sh must be run
```

### autogen.sh Fails

If `autogen.sh` fails, you may need to install autotools:

```bash
# macOS
brew install autoconf automake libtool

# Ubuntu/Debian
sudo apt-get install autoconf automake libtool
```

Alternatively, download from the official releases page which includes pre-generated `configure` scripts:

```bash
curl -L -o download/LibSodium/libsodium-1.0.21.tar.gz \
    https://download.libsodium.org/libsodium/releases/libsodium-1.0.21.tar.gz
```

### Rebuild libsodium from Scratch

To force a full rebuild, remove the install and source directories:

```bash
rm -rf download/LibSodium/libsodium-install download/LibSodium/libsodium
cd build && cmake ..
```

### Header Not Found: `sodium.h`

If you see `'sodium.h' file not found`, ensure that the build has completed at least once. The header is installed during the CMake configure step:

```bash
cd build && cmake .. && make
```

After a successful build, the IDE diagnostics will resolve as `compile_commands.json` is updated.

---

## References

- [libsodium GitHub Repository](https://github.com/jedisct1/libsodium)
- [libsodium Documentation](https://doc.libsodium.org/)
- [libsodium Installation Guide](https://doc.libsodium.org/installation)
- [Secret-key Encryption](https://doc.libsodium.org/secret-key_cryptography/secretbox)
- [Public-key Encryption](https://doc.libsodium.org/public-key_cryptography/authenticated_encryption)
- [Sealed Boxes](https://doc.libsodium.org/public-key_cryptography/sealed_boxes)
- [Generic Hashing](https://doc.libsodium.org/hashing/generic_hashing)
- [Password Hashing](https://doc.libsodium.org/password_hashing)
- [Key Exchange](https://doc.libsodium.org/key_exchange)
- [Digital Signatures](https://doc.libsodium.org/public-key_cryptography/public-key_signatures)
- [Secure Memory](https://doc.libsodium.org/memory_management)
