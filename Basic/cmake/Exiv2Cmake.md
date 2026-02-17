# Exiv2.cmake Reference

## Overview

`Exiv2.cmake` is a CMake configuration file that automatically downloads, builds, and links the Exiv2 library using CMake's `FetchContent` module.
On the first build, FetchContent downloads and builds Exiv2 as a sub-project, then installs the built library into `exiv2-install/` for future use.
On subsequent builds (even after deleting the `build/` directory), the pre-built library is detected and reused, skipping recompilation entirely.

Exiv2 is a C++ library and command-line utility to read, write, delete, and modify Exif, IPTC, XMP, and ICC Profile image metadata. It supports a wide range of image formats including JPEG, PNG, TIFF, WebP, CR2, NEF, and many more.

Exiv2 is a C++ library. The main header `<exiv2/exiv2.hpp>` provides the complete API.

## File Information

| Item | Details |
|------|---------|
| Download Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/Exiv2` |
| Install Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/Exiv2/exiv2-install` |
| Git Repository | https://github.com/Exiv2/exiv2.git |
| Git Tag | v0.28.7 |
| Version | 0.28.7 |
| License | GNU GPL v2+ |

---

## Include Guard

```cmake
include_guard(GLOBAL)
```

This file uses `include_guard(GLOBAL)` to ensure it is only executed once, even if included multiple times.

**Why it's needed:**

- Prevents duplicate `FetchContent_Declare` / `FetchContent_MakeAvailable` calls
- Prevents duplicate linking in `target_link_libraries`

---

## Directory Structure

```
Exiv2/
├── cmake/
│   ├── Exiv2.cmake        # This configuration file
│   ├── Exiv2Cmake.md      # This document
│   └── Exiv2Cmake-jp.md   # Japanese version of this document
├── download/Exiv2/
│   ├── exiv2-src/          # Exiv2 source (git clone, cached by FetchContent)
│   ├── exiv2-build/        # Exiv2 CMake build directory (managed by FetchContent)
│   ├── exiv2-subbuild/     # FetchContent sub-build directory
│   └── exiv2-install/      # Pre-built library cache (lib/, include/)
│       ├── include/exiv2/  # Exiv2 headers
│       └── lib/            # libexiv2.dylib / libexiv2.so
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## Usage

### Adding to CMakeLists.txt

```cmake
include("./cmake/Exiv2.cmake")
```

### Build

```bash
mkdir build && cd build
cmake ..
make
```

---

## Processing Flow

### Build Caching Strategy

`Exiv2.cmake` uses a two-phase approach to avoid unnecessary recompilation:

| Phase | Condition | Action |
|-------|-----------|--------|
| First build | `exiv2-install/` does not exist | FetchContent downloads, builds, links, and installs Exiv2 |
| Subsequent builds | `exiv2-install/lib/libexiv2.dylib` exists | Uses cached install directly (no FetchContent, no recompilation) |

This means deleting the `build/` directory only requires recompiling your own source files (~2 seconds), not the entire Exiv2 library (~15 seconds).

### Phase 1: First Build (FetchContent)

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

- `GIT_SHALLOW TRUE`: Clones only the latest commit of the specified tag, significantly reducing download size and time
- `FetchContent_MakeAvailable`: Downloads (if not cached), configures, and makes the `exiv2lib` target available
- All transitive dependencies (zlib, expat, brotli, etc.) are resolved automatically by CMake through the `exiv2lib` target
- After the build, a `POST_BUILD` command installs Exiv2 to `exiv2-install/` for future use

### Phase 2: Cached Build (IMPORTED Library)

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

- The pre-built library at `exiv2-install/` is used directly as an `IMPORTED` target
- System dependencies (zlib, expat, iconv, brotli, CoreFoundation) are linked explicitly
- FetchContent is NOT invoked, so `cmake ..` is fast

### Build Options

```cmake
set(EXIV2_ENABLE_XMP    ON  CACHE BOOL "" FORCE)
set(EXIV2_ENABLE_NLS    OFF CACHE BOOL "" FORCE)
set(EXIV2_ENABLE_INIH   OFF CACHE BOOL "" FORCE)
set(EXIV2_BUILD_SAMPLES OFF CACHE BOOL "" FORCE)
set(EXIV2_BUILD_EXIV2_COMMAND OFF CACHE BOOL "" FORCE)
```

- `EXIV2_ENABLE_XMP=ON`: Enables XMP metadata support
- `EXIV2_ENABLE_NLS=OFF`: Disables internationalization (not needed)
- `EXIV2_ENABLE_INIH=OFF`: Disables inih config parser (not needed)
- `EXIV2_BUILD_SAMPLES=OFF`: Skips sample applications
- `EXIV2_BUILD_EXIV2_COMMAND=OFF`: Skips command-line tool (we only need the library)

---

## Exiv2 Build Options

| Option | Default | This Project | Description |
|--------|---------|-------------|-------------|
| `EXIV2_ENABLE_XMP` | ON | ON | Enable XMP metadata support |
| `EXIV2_ENABLE_EXTERNAL_XMP` | OFF | (default) | Use external XMP SDK instead of bundled |
| `EXIV2_ENABLE_NLS` | OFF | OFF | Enable Native Language Support (i18n) |
| `EXIV2_ENABLE_INIH` | ON | OFF | Enable inih library for .ini config |
| `EXIV2_ENABLE_BROTLI` | ON | (default) | Enable Brotli for JPEG XL compressed boxes |
| `EXIV2_ENABLE_BMFF` | ON | (default) | Enable BMFF (HEIF, AVIF) support |
| `EXIV2_BUILD_SAMPLES` | OFF | OFF | Build sample applications |
| `EXIV2_BUILD_EXIV2_COMMAND` | ON | OFF | Build exiv2 command-line tool |
| `BUILD_SHARED_LIBS` | ON | (default) | Build shared libraries |

---

## Key Features of Exiv2

| Feature | Header | Description |
|---------|--------|-------------|
| Exif Metadata | `exiv2/exif.hpp` | Read/write Exif tags (camera info, GPS, exposure, etc.) |
| IPTC Metadata | `exiv2/iptc.hpp` | Read/write IPTC tags (captions, keywords, copyright) |
| XMP Metadata | `exiv2/xmp_exiv2.hpp` | Read/write XMP properties (Dublin Core, etc.) |
| Image I/O | `exiv2/image.hpp` | Open, read, and write image files |
| Type System | `exiv2/types.hpp` | Rational numbers, byte order, data types |
| Tag Info | `exiv2/tags.hpp` | Tag names, descriptions, and type information |
| Value Types | `exiv2/value.hpp` | Type-safe value representations |
| Error Handling | `exiv2/error.hpp` | Exception-based error handling |
| Version | `exiv2/version.hpp` | Library version information |

### Supported Image Formats

| Format | Read | Write | Extensions |
|--------|------|-------|------------|
| JPEG | Yes | Yes | .jpg, .jpeg |
| TIFF | Yes | Yes | .tif, .tiff |
| PNG | Yes | Yes | .png |
| WebP | Yes | Yes | .webp |
| DNG | Yes | Yes | .dng |
| CR2 (Canon) | Yes | Yes | .cr2 |
| NEF (Nikon) | Yes | Yes | .nef |
| ARW (Sony) | Yes | Yes | .arw |
| ORF (Olympus) | Yes | Yes | .orf |
| RAF (Fuji) | Yes | Yes | .raf |
| PEF (Pentax) | Yes | Yes | .pef |
| HEIF/HEIC | Yes | Read only | .heif, .heic |
| AVIF | Yes | Read only | .avif |

---

## Usage Examples in C++

### Reading Exif Metadata

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

### Reading Specific Exif Tags

```cpp
#include <exiv2/exiv2.hpp>
#include <iostream>

int main() {
    auto image = Exiv2::ImageFactory::open("photo.jpg");
    image->readMetadata();

    Exiv2::ExifData &exifData = image->exifData();

    auto it = exifData.findKey(Exiv2::ExifKey("Exif.Image.Make"));
    if (it != exifData.end()) {
        std::cout << "Camera: " << it->value() << "\n";
    }

    it = exifData.findKey(Exiv2::ExifKey("Exif.Photo.FNumber"));
    if (it != exifData.end()) {
        std::cout << "F-Number: " << it->value() << "\n";
    }

    return 0;
}
```

### Writing Exif Metadata

```cpp
#include <exiv2/exiv2.hpp>
#include <iostream>

int main() {
    auto image = Exiv2::ImageFactory::open("photo.jpg");
    image->readMetadata();

    Exiv2::ExifData &exifData = image->exifData();

    // Set string values
    exifData["Exif.Image.Make"] = "MyCamera";
    exifData["Exif.Image.Model"] = "Model X";
    exifData["Exif.Image.Software"] = "MyApp v1.0";

    // Set rational values (e.g., exposure time 1/125s)
    exifData["Exif.Photo.ExposureTime"] = Exiv2::URational(1, 125);
    exifData["Exif.Photo.FNumber"] = Exiv2::URational(28, 10);

    // Set integer values
    exifData["Exif.Photo.ISOSpeedRatings"] = uint16_t(800);
    exifData["Exif.Image.ImageWidth"] = uint32_t(4032);
    exifData["Exif.Image.ImageLength"] = uint32_t(3024);

    // Set date/time
    exifData["Exif.Image.DateTime"] = "2026:01:15 14:30:00";

    image->writeMetadata();
    std::cout << "Metadata written successfully.\n";
    return 0;
}
```

### Writing GPS Coordinates

```cpp
#include <exiv2/exiv2.hpp>
#include <iostream>

int main() {
    auto image = Exiv2::ImageFactory::open("photo.jpg");
    image->readMetadata();

    Exiv2::ExifData &exifData = image->exifData();

    // GPS coordinates for Tokyo Tower (35.6586N, 139.7454E)
    exifData["Exif.GPSInfo.GPSLatitudeRef"] = "N";
    exifData["Exif.GPSInfo.GPSLatitude"] = "35/1 39/1 3096/100";
    exifData["Exif.GPSInfo.GPSLongitudeRef"] = "E";
    exifData["Exif.GPSInfo.GPSLongitude"] = "139/1 44/1 4344/100";

    image->writeMetadata();
    std::cout << "GPS data written.\n";
    return 0;
}
```

### Reading/Writing IPTC Metadata

```cpp
#include <exiv2/exiv2.hpp>
#include <iostream>

int main() {
    auto image = Exiv2::ImageFactory::open("photo.jpg");
    image->readMetadata();

    Exiv2::IptcData &iptcData = image->iptcData();

    // Write IPTC data
    iptcData["Iptc.Application2.Headline"] = "Beautiful Sunset";
    iptcData["Iptc.Application2.Caption"] = "A stunning sunset over the ocean";
    iptcData["Iptc.Application2.Keywords"] = "sunset";
    iptcData["Iptc.Application2.City"] = "Kamakura";
    iptcData["Iptc.Application2.CountryName"] = "Japan";
    iptcData["Iptc.Application2.Copyright"] = "2026 Photographer";

    image->writeMetadata();

    // Read IPTC data
    image->readMetadata();
    for (const auto &entry : image->iptcData()) {
        std::cout << entry.key() << " = " << entry.value() << "\n";
    }
    return 0;
}
```

### Reading/Writing XMP Metadata

```cpp
#include <exiv2/exiv2.hpp>
#include <iostream>

int main() {
    Exiv2::XmpParser::initialize();

    auto image = Exiv2::ImageFactory::open("photo.jpg");
    image->readMetadata();

    Exiv2::XmpData &xmpData = image->xmpData();

    // Write XMP Dublin Core properties
    xmpData["Xmp.dc.title"] = "My Photo";
    xmpData["Xmp.dc.creator"] = "John Doe";
    xmpData["Xmp.dc.description"] = "A sample photograph";
    xmpData["Xmp.dc.rights"] = "Creative Commons CC-BY";

    image->writeMetadata();

    // Read XMP data
    image->readMetadata();
    for (const auto &entry : image->xmpData()) {
        std::cout << entry.key() << " [" << entry.typeName()
                  << "] = " << entry.value() << "\n";
    }

    Exiv2::XmpParser::terminate();
    return 0;
}
```

### Deleting Metadata

```cpp
#include <exiv2/exiv2.hpp>
#include <iostream>

int main() {
    auto image = Exiv2::ImageFactory::open("photo.jpg");
    image->readMetadata();

    // Delete a specific Exif key
    Exiv2::ExifData &exifData = image->exifData();
    auto it = exifData.findKey(Exiv2::ExifKey("Exif.Image.Software"));
    if (it != exifData.end()) {
        exifData.erase(it);
    }

    // Delete all IPTC data
    image->iptcData().clear();

    image->writeMetadata();
    std::cout << "Metadata deleted.\n";
    return 0;
}
```

---

## Exiv2 API Conventions

### Opening an Image

All metadata operations start with opening an image file:

```cpp
auto image = Exiv2::ImageFactory::open("photo.jpg");
image->readMetadata();
```

`ImageFactory::open()` returns a `std::unique_ptr<Exiv2::Image>`.

### Metadata Types

Exiv2 supports three metadata families, each with its own data container:

| Family | Container | Key Format | Example Key |
|--------|-----------|------------|-------------|
| Exif | `Exiv2::ExifData` | `Exif.<Group>.<Tag>` | `Exif.Image.Make` |
| IPTC | `Exiv2::IptcData` | `Iptc.<Record>.<Tag>` | `Iptc.Application2.Headline` |
| XMP | `Exiv2::XmpData` | `Xmp.<Schema>.<Property>` | `Xmp.dc.title` |

### Value Types

Exiv2 uses typed values for metadata entries:

| Exif Type | C++ Type | Description |
|-----------|----------|-------------|
| Ascii | `std::string` | ASCII string (e.g., camera make) |
| Short | `uint16_t` | 16-bit unsigned integer (e.g., ISO) |
| Long | `uint32_t` | 32-bit unsigned integer (e.g., width) |
| Rational | `Exiv2::URational` | Unsigned rational (e.g., f-number, exposure time) |
| SRational | `Exiv2::Rational` | Signed rational (e.g., exposure bias) |
| Undefined | `Exiv2::DataBuf` | Raw byte data |

### Error Handling

Exiv2 uses C++ exceptions for error handling:

```cpp
try {
    auto image = Exiv2::ImageFactory::open("nonexistent.jpg");
    image->readMetadata();
} catch (const Exiv2::Error &e) {
    std::cerr << "Error: " << e.what() << "\n";
}
```

---

## Comparison: Exiv2 vs Other Libraries

| Feature | Exiv2 | libexif | ExifTool | ImageMagick |
|---------|-------|---------|----------|-------------|
| Language | C++ | C | Perl | C |
| License | GPL v2+ | LGPL | GPL/Artistic | Apache 2 |
| Exif | Yes | Yes | Yes | Yes |
| IPTC | Yes | No | Yes | Yes |
| XMP | Yes | No | Yes | Yes |
| ICC Profile | Yes | No | Yes | Yes |
| RAW formats | Yes | No | Yes | Partial |
| Write support | Yes | Limited | Yes | Yes |
| Programmatic API | Yes | Yes | Perl/CLI | Yes |
| Lightweight | Yes | Yes | No (Perl) | No (large) |

Exiv2 provides a comprehensive C++ API for image metadata, supporting Exif, IPTC, and XMP in a single library. It is the de facto standard library used by many photo applications (e.g., GIMP, darktable, digikam, gThumb).

---

## Troubleshooting

### Git Clone Fails

If cloning from GitHub fails (network issues, firewall, etc.), you can manually clone the repository:

```bash
cd download/Exiv2
git clone --depth 1 --branch v0.28.7 https://github.com/Exiv2/exiv2.git exiv2-src
```

Then re-run `cmake ..` and FetchContent will detect the existing source.

### CMake Configure Fails

On macOS, ensure Xcode Command Line Tools are installed:

```bash
xcode-select --install
```

### Rebuild Exiv2 from Scratch

To force a full rebuild of Exiv2 (including re-download), remove the entire download directory:

```bash
rm -rf download/Exiv2
rm -rf build
mkdir build && cd build
cmake ..
```

To force only a rebuild (keeping the cached source), remove just the install directory:

```bash
rm -rf download/Exiv2/exiv2-install
rm -rf build
mkdir build && cd build
cmake ..
```

### Build Takes Too Long

The first build downloads and compiles Exiv2 from source (~15 seconds). Subsequent builds reuse the cached install and only compile your own source files (~2 seconds). To speed up the initial build:

```bash
cmake --build build -j$(nproc)   # Linux
cmake --build build -j$(sysctl -n hw.ncpu)  # macOS
```

---

## References

- [Exiv2 Official Website](https://exiv2.org/)
- [Exiv2 GitHub Repository](https://github.com/Exiv2/exiv2)
- [Exiv2 API Documentation](https://exiv2.org/doc/index.html)
- [Exiv2 Releases](https://github.com/Exiv2/exiv2/releases)
- [Exif Tag Reference](https://exiv2.org/tags.html)
- [IPTC Tag Reference](https://exiv2.org/iptc.html)
- [XMP Namespace Reference](https://exiv2.org/tags-xmp-dc.html)
- [CMake FetchContent Documentation](https://cmake.org/cmake/help/latest/module/FetchContent.html)
