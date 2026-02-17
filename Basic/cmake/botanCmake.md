# botan.cmake Reference

## Overview

`botan.cmake` is a CMake configuration file that automatically downloads, builds, and links the Botan library.
It uses CMake's `file(DOWNLOAD)` and `execute_process` to manage the dependency, with caching in the `download/` directory to avoid redundant downloads and rebuilds.

Botan is a C++ cryptography library that provides a wide variety of cryptographic algorithms and protocols, including hashing (SHA-2, SHA-3), message authentication (HMAC), symmetric encryption (AES-GCM), random number generation, Base64/Hex encoding, TLS, X.509 certificates, and more.

**Note:** Botan uses a Python `configure.py` script for its build system, not CMake. Python 3 is required.

## File Information

| Item | Details |
|------|---------|
| Source Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/botan` |
| Install Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/botan-install` |
| Download URL | https://github.com/randombit/botan/archive/refs/tags/3.10.0.tar.gz |
| Version | 3.10.0 |
| License | BSD 2-Clause License |
| Build System | Python `configure.py` (not CMake) |
| Language Standard | C++20 |

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
Botan/
├── cmake/
│   ├── botan.cmake          # This configuration file
│   ├── botanCmake.md        # This document (English)
│   └── botanCmake-jp.md     # This document (Japanese)
├── download/
│   ├── botan/               # Botan source (cached, downloaded from GitHub)
│   └── botan-install/       # Botan built artifacts (lib/, include/)
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

## Usage

### Adding to CMakeLists.txt

```cmake
# Include botan.cmake at the end of CMakeLists.txt
include("./cmake/botan.cmake")
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
set(BOTAN_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(BOTAN_SOURCE_DIR ${BOTAN_DOWNLOAD_DIR}/botan)
set(BOTAN_INSTALL_DIR ${BOTAN_DOWNLOAD_DIR}/botan-install)
set(BOTAN_VERSION "3.10.0")
set(BOTAN_URL "https://github.com/randombit/botan/archive/refs/tags/${BOTAN_VERSION}.tar.gz")
```

### 2. Cache Check and Conditional Build

```cmake
if(EXISTS ${BOTAN_INSTALL_DIR}/lib/libbotan-3.a)
    message(STATUS "Botan already built: ${BOTAN_INSTALL_DIR}/lib/libbotan-3.a")
else()
    # Download, configure, build, and install ...
endif()
```

The cache logic works as follows:

| Condition | Action |
|-----------|--------|
| `botan-install/lib/libbotan-3.a` exists | Skip everything (use cached build) |
| `botan/configure.py` exists (install missing) | Skip download, run configure/build/install |
| Nothing exists | Download, extract, configure, build, install |

### 3. Download (if needed)

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

- Downloads from GitHub tags (Botan uses tags, not GitHub Releases)
- Extracts and renames `botan-3.10.0/` to `botan/` for a clean path

### 4. Configure, Build, and Install (Python + Make)

```cmake
# Find Python 3
find_package(Python3 REQUIRED COMPONENTS Interpreter)

# Configure with Python configure.py
execute_process(
    COMMAND ${Python3_EXECUTABLE} ${BOTAN_SOURCE_DIR}/configure.py
            --prefix=${BOTAN_INSTALL_DIR}
            --minimized-build
            --enable-modules=sha2_32,sha2_64,sha3,hmac,aes,gcm,ctr,auto_rng,system_rng,base64,hex
            --disable-shared-library
    WORKING_DIRECTORY ${BOTAN_SOURCE_DIR}
)

# Build with make
execute_process(COMMAND make -j4
    WORKING_DIRECTORY ${BOTAN_SOURCE_DIR})

# Install
execute_process(COMMAND make install
    WORKING_DIRECTORY ${BOTAN_SOURCE_DIR})
```

- `--minimized-build`: Starts with no modules; only the explicitly enabled ones are built
- `--enable-modules=...`: Selectively enables the required cryptographic modules
- `--disable-shared-library`: Builds static library only (`libbotan-3.a`)
- All steps run at CMake configure time, not at build time

### 5. Linking the Library

```cmake
add_library(botan_lib STATIC IMPORTED)
set_target_properties(botan_lib PROPERTIES
    IMPORTED_LOCATION ${BOTAN_INSTALL_DIR}/lib/libbotan-3.a
)

target_include_directories(${PROJECT_NAME} PRIVATE ${BOTAN_INSTALL_DIR}/include/botan-3)
target_link_libraries(${PROJECT_NAME} PRIVATE botan_lib Threads::Threads)

# macOS frameworks
if(APPLE)
    target_link_libraries(${PROJECT_NAME} PRIVATE "-framework Security" "-framework CoreFoundation")
endif()

# Botan 3.x requires C++20
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_20)
```

---

## Enabled Modules

The minimized build enables only the following modules:

| Module | Description |
|--------|-------------|
| `sha2_32` | SHA-224, SHA-256 |
| `sha2_64` | SHA-384, SHA-512 |
| `sha3` | SHA-3, SHAKE |
| `hmac` | HMAC message authentication |
| `aes` | AES block cipher (128/192/256) |
| `gcm` | GCM authenticated encryption mode |
| `ctr` | CTR stream cipher mode |
| `auto_rng` | Auto-seeded random number generator |
| `system_rng` | OS-provided random number generator |
| `base64` | Base64 encoding/decoding |
| `hex` | Hexadecimal encoding/decoding |

To add more modules, edit the `--enable-modules=` line in `botan.cmake`. List all available modules with:

```bash
python3 download/botan/configure.py --list-modules
```

---

## Key Features of Botan

| Feature | Description |
|---------|-------------|
| Hash functions | SHA-256, SHA-384, SHA-512, SHA-3, BLAKE2, etc. |
| MAC | HMAC, CMAC, GMAC, Poly1305 |
| Symmetric encryption | AES-GCM, AES-CBC, ChaCha20-Poly1305, etc. |
| Public key crypto | RSA, ECDSA, Ed25519, X25519, etc. |
| Random number generation | `AutoSeeded_RNG`, `System_RNG` |
| Encoding | Base64, Hex |
| TLS | TLS 1.2 and TLS 1.3 |
| X.509 | Certificate parsing and generation |
| Key derivation | HKDF, PBKDF2, Argon2 |
| Thread safety | All operations are thread-safe |

---

## Usage Examples in C++

### SHA-256 Hash

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
    hmac->update("Message to authenticate");
    auto tag = hmac->final();

    std::cout << "HMAC tag: " << Botan::hex_encode(tag) << std::endl;

    // Verify
    hmac->set_key(key);
    hmac->update("Message to authenticate");
    bool ok = hmac->verify_mac(tag);
    std::cout << "Valid: " << (ok ? "yes" : "no") << std::endl;

    return 0;
}
```

### AES-256/GCM Encryption

```cpp
#include <botan/cipher_mode.h>
#include <botan/auto_rng.h>
#include <botan/hex.h>
#include <iostream>
#include <string>

int main() {
    Botan::AutoSeeded_RNG rng;
    auto key = rng.random_vec<Botan::secure_vector<uint8_t>>(32);

    // Encrypt
    auto enc = Botan::Cipher_Mode::create_or_throw("AES-256/GCM", Botan::Cipher_Dir::Encryption);
    enc->set_key(key);
    auto nonce = rng.random_vec<std::vector<uint8_t>>(enc->default_nonce_length());

    std::string plaintext = "Secret data";
    Botan::secure_vector<uint8_t> ct(plaintext.begin(), plaintext.end());
    enc->start(nonce);
    enc->finish(ct);

    // Decrypt
    auto dec = Botan::Cipher_Mode::create_or_throw("AES-256/GCM", Botan::Cipher_Dir::Decryption);
    dec->set_key(key);
    dec->start(nonce);
    Botan::secure_vector<uint8_t> pt(ct);
    dec->finish(pt);

    std::cout << "Recovered: " << std::string(pt.begin(), pt.end()) << std::endl;
    return 0;
}
```

### Random Number Generation

```cpp
#include <botan/auto_rng.h>
#include <botan/hex.h>
#include <iostream>

int main() {
    Botan::AutoSeeded_RNG rng;
    auto bytes = rng.random_vec<std::vector<uint8_t>>(32);
    std::cout << "Random: " << Botan::hex_encode(bytes) << std::endl;
    return 0;
}
```

### Base64 Encoding / Decoding

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

    std::cout << "Encoded: " << encoded << std::endl;
    std::cout << "Decoded: " << std::string(decoded.begin(), decoded.end()) << std::endl;
    return 0;
}
```

### Hex Encoding / Decoding

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
    std::cout << "Decoded: " << std::string(decoded.begin(), decoded.end()) << std::endl;
    return 0;
}
```

---

## Configure Options

Key `configure.py` flags used in `botan.cmake`:

| Flag | Description |
|------|-------------|
| `--prefix=DIR` | Installation prefix directory |
| `--minimized-build` | Start with no modules enabled |
| `--enable-modules=LIST` | Comma-separated list of modules to enable |
| `--disable-shared-library` | Do not build shared library (.so/.dylib) |

Other useful flags:

| Flag | Description |
|------|-------------|
| `--enable-static-library` | Build static library (default when shared is disabled) |
| `--cc=COMPILER` | Specify compiler (gcc, clang) |
| `--list-modules` | List all available modules |
| `--with-debug-info` | Include debug symbols |
| `--with-sanitizers` | Enable ASan/UBSan |

---

## Comparison with Other Crypto Libraries

| Feature | Botan | OpenSSL | libsodium | Crypto++ |
|---------|-------|---------|-----------|----------|
| Language | C++20 | C | C | C++ |
| API style | Modern C++ | C API | C API | C++ (templates) |
| Modular build | Yes | Partial | No | No |
| Hash algorithms | SHA-2/3, BLAKE2, etc. | SHA-2/3, etc. | BLAKE2b, SHA-256 | Extensive |
| AEAD | AES-GCM, ChaCha20-Poly1305 | AES-GCM, ChaCha20-Poly1305 | XChaCha20-Poly1305 | AES-GCM |
| TLS support | TLS 1.2/1.3 | TLS 1.2/1.3 | No | No |
| X.509 support | Yes | Yes | No | Yes |
| License | BSD 2-Clause | Apache 2.0 | ISC | Boost |
| Active maintenance | Active | Active | Active | Active |

---

## Troubleshooting

### Download Fails

If GitHub is unreachable, you can manually download and place the tarball:

```bash
curl -L -o download/botan-3.10.0.tar.gz https://github.com/randombit/botan/archive/refs/tags/3.10.0.tar.gz
```

Then re-run `cmake ..` and the extraction will proceed from the cached tarball.

### Configure Fails

Ensure Python 3 is available:

```bash
python3 --version
```

On macOS, ensure Xcode Command Line Tools are installed:

```bash
xcode-select --install
```

### Rebuild Botan from Scratch

To force a full rebuild, remove the install and source directories:

```bash
rm -rf download/botan-install download/botan
cd build && cmake ..
```

### Link Error: Undefined Reference to Botan Symbols

Verify that `libbotan-3.a` exists in `download/botan-install/lib/`. If missing, delete the install directory and re-run cmake.

On macOS, ensure the Security and CoreFoundation frameworks are linked:

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE "-framework Security" "-framework CoreFoundation")
```

### `<botan/hash.h> was not included correctly`

Botan 3.x installs headers to `include/botan-3/botan/`. Ensure `target_include_directories` points to the `include/botan-3` directory (not `include/botan-3/botan/`).

### Adding More Cryptographic Modules

If you need additional functionality (e.g., RSA, Ed25519, TLS), add the module names to the `--enable-modules=` list in `botan.cmake`. Then delete the install directory and rebuild:

```bash
rm -rf download/botan-install download/botan
cd build && cmake ..
```

---

## References

- [Botan GitHub Repository](https://github.com/randombit/botan)
- [Botan Documentation](https://botan.randombit.net/)
- [Botan API Reference](https://botan.randombit.net/doxygen/)
- [Botan Handbook](https://botan.randombit.net/handbook/)
- [CMake execute_process Documentation](https://cmake.org/cmake/help/latest/command/execute_process.html)
- [CMake file(DOWNLOAD) Documentation](https://cmake.org/cmake/help/latest/command/file.html#download)
