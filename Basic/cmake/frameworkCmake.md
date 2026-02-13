# framework.cmake Documentation

## Overview

`framework.cmake` is a configuration file for linking system frameworks to a project in macOS/Apple environments. It provides a comprehensive list of all frameworks available on macOS 15.1 (Sequoia).

## File Information

| Item | Content |
|------|---------|
| Project | CMake Template Project |
| Author | mitsuruk |
| Created | 2025/11/26 |
| License | MIT License |
| Target OS | macOS 15.1 (24B83) "Sequoia" |

---

## Include Guard

```cmake
include_guard(GLOBAL)
```

This file uses `include_guard(GLOBAL)` to ensure it is only executed once even if included multiple times.

**Why it's needed:**

- Prevents duplicate calls to `target_link_libraries`
- Avoids duplicate linking of the same framework
- Prevents linker errors and warnings

---

## Basic Structure

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE
    # "-framework FrameworkName"
    # Uncomment the frameworks you want to use
)
```

All frameworks are provided in a commented-out state. Uncomment the necessary frameworks to use them.

---

## Framework List

### SwiftUI Integration Frameworks

| Framework | Description |
|-----------|-------------|
| `_AppIntents_AppKit` | Integration of AppIntents and AppKit |
| `_AppIntents_SwiftUI` | Integration of AppIntents and SwiftUI |
| `_AVKit_SwiftUI` | Integration of AVKit and SwiftUI |
| `_CoreData_CloudKit` | Integration of CoreData and CloudKit |
| `_MapKit_SwiftUI` | Integration of MapKit and SwiftUI |
| `_PhotosUI_SwiftUI` | Integration of PhotosUI and SwiftUI |
| `_SwiftData_SwiftUI` | Integration of SwiftData and SwiftUI |

### Core System Frameworks

| Framework | Description |
|-----------|-------------|
| `Foundation` | Basic data types, collections, and OS features |
| `CoreFoundation` | C-based foundational framework |
| `CoreServices` | File system, metadata, and launch services |
| `System` | Low-level system interface |
| `Security` | Encryption, authentication, and Keychain |

### UI/Application Frameworks

| Framework | Description |
|-----------|-------------|
| `AppKit` | macOS application UI |
| `SwiftUI` | Declarative UI framework |
| `Cocoa` | AppKit + Foundation integration |
| `Carbon` | Legacy UI framework |

### Graphics/Media Frameworks

| Framework | Description |
|-----------|-------------|
| `Metal` | Low-level GPU access |
| `MetalKit` | Metal helpers |
| `MetalPerformanceShaders` | GPU-optimized shaders |
| `OpenGL` | Legacy 3D graphics |
| `OpenCL` | GPU computing |
| `CoreGraphics` | 2D graphics |
| `CoreImage` | Image processing |
| `QuartzCore` | Animation, compositing |
| `SceneKit` | 3D scene management |
| `SpriteKit` | 2D game engine |
| `RealityKit` | AR/VR experiences |

### Audio/Video Frameworks

| Framework | Description |
|-----------|-------------|
| `AVFoundation` | Audio/video processing |
| `AVKit` | Media player UI |
| `CoreAudio` | Low-level audio |
| `CoreMedia` | Media pipeline |
| `VideoToolbox` | Hardware video processing |
| `AudioToolbox` | Audio processing tools |

### Machine Learning/AI Frameworks

| Framework | Description |
|-----------|-------------|
| `CoreML` | Machine learning model execution |
| `CreateML` | Machine learning model creation |
| `Vision` | Computer vision |
| `NaturalLanguage` | Natural language processing |
| `SoundAnalysis` | Sound classification |
| `Speech` | Speech recognition |

### Network/Communication Frameworks

| Framework | Description |
|-----------|-------------|
| `Network` | Modern networking API |
| `CFNetwork` | Core Foundation networking |
| `NetworkExtension` | VPN, content filters |
| `MultipeerConnectivity` | P2P communication |

### Data Management Frameworks

| Framework | Description |
|-----------|-------------|
| `CoreData` | Object graph persistence |
| `SwiftData` | Data persistence for Swift |
| `CloudKit` | iCloud data synchronization |

### Hardware Access Frameworks

| Framework | Description |
|-----------|-------------|
| `IOKit` | Hardware access |
| `CoreBluetooth` | Bluetooth LE |
| `CoreLocation` | Location services |
| `CoreMotion` | Motion sensors |
| `CoreHaptics` | Haptic feedback |

### Virtualization/System Extensions

| Framework | Description |
|-----------|-------------|
| `Virtualization` | Virtual machines |
| `Hypervisor` | Hypervisor API |
| `DriverKit` | User-space drivers |
| `SystemExtensions` | System extensions |

---

## Usage

### 1. Uncomment the Required Frameworks

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE
    "-framework Foundation"
    "-framework CoreGraphics"
    "-framework Metal"
    # Other required frameworks
)
```

### 2. Include from the Main CMakeLists.txt

```cmake
if(APPLE)
    include(cmake/framework.cmake)
endif()
```

---

## How to Find Frameworks

You can check the frameworks installed on the system using the commands listed in the comments at the end of the file:

```bash
# System frameworks
find /System/Library/Frameworks -name "*.framework" -depth 1

# User-installed frameworks (Xcode, etc.)
find /Library/Frameworks -name "*.framework" -depth 1
```

---

## Dependencies

| Dependency | Required/Optional | Description |
|------------|-------------------|-------------|
| `${PROJECT_NAME}` | Required | Main project target name |
| macOS | Required | macOS only |

---

## Notes

1. **Platform restriction**: This file is macOS-only. Use it within an `if(APPLE)` guard.

2. **Framework availability**: Some frameworks are only available on specific macOS versions or later.

3. **Underscore prefix**: Frameworks starting with `_` (e.g., `_SwiftUI_MapKit`) are for internal integration and are generally not used directly.

4. **Deprecated frameworks**: `QTKit`, `Carbon`, `OpenGL`, and others are deprecated. Consider alternatives for new projects.

5. **PRIVATE specifier**: Frameworks are linked with `PRIVATE`. If building a library, change to `PUBLIC` or `INTERFACE` as needed.

6. **Swift integration**: When using SwiftUI-related frameworks, integration with Swift may be required.
