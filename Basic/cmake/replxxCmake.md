# replxx.cmake Reference

## Overview

`replxx.cmake` is a CMake configuration file that automatically downloads, builds, and links the replxx library.
It uses CMake's `FetchContent` module to manage dependencies.

replxx is an alternative library to GNU readline / libedit, featuring UTF-8 support, syntax highlighting, hint functionality, and cross-platform compatibility.
The name derives from "REPL (Read-Eval-Print Loop) + xx (C++)".

## File Information

| Item | Details |
|------|---------|
| Download Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/replxx` |
| Repository | https://github.com/AmokHuginnsson/replxx |
| Version | release-0.0.4 |
| License | BSD-3-Clause |

---

## Include Guard

```cmake
include_guard(GLOBAL)
```

This file uses `include_guard(GLOBAL)` to ensure it is only executed once, even if included multiple times.

**Why it's needed:**

- Prevents duplicate invocation errors from `FetchContent_MakeAvailable(replxx)`
- Prevents duplicate linking in `target_link_libraries`

---

## Directory Structure

```
Basic/
├── cmake/
│   └── replxx.cmake    # This configuration file
├── download/
│   └── replxx/         # replxx library (GitHub: AmokHuginnsson/replxx)
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## Usage

### Adding to CMakeLists.txt

```cmake
# Automatically include replxx.cmake if it exists
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/replxx.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/replxx.cmake)
endif()
```

### Build

```bash
mkdir build && cd build
cmake ..
make
```

---

## Processing Flow

### 1. Setting the Download Directory

```cmake
set(REPLXX_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(REPLXX_SOURCE_DIR ${REPLXX_DOWNLOAD_DIR}/replxx)
```

### 2. Declaring replxx with FetchContent

```cmake
FetchContent_Declare(
    replxx
    GIT_REPOSITORY https://github.com/AmokHuginnsson/replxx.git
    GIT_TAG        release-0.0.4
    GIT_SHALLOW    TRUE
    SOURCE_DIR     ${REPLXX_SOURCE_DIR}
)
```

- `GIT_TAG release-0.0.4`: Uses a stable release version
- `GIT_SHALLOW TRUE`: Fetches only the latest commit (faster)
- `SOURCE_DIR`: Explicitly specifies the download location

### 3. Setting Build Options

```cmake
set(REPLXX_BUILD_EXAMPLES OFF CACHE BOOL "Build replxx examples" FORCE)
```

Disables building sample programs to reduce build time.

### 4. Download and Build

```cmake
FetchContent_MakeAvailable(replxx)
```

### 5. Linking the Library

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE replxx)
target_include_directories(${PROJECT_NAME} PRIVATE ${REPLXX_SOURCE_DIR}/include)
```

---

## Key Features of replxx

| Feature | Description |
|---------|-------------|
| Line editing | Cursor movement, character deletion, line editing |
| History | Recall previous inputs with up/down arrow keys |
| Completion | Custom completion with the Tab key |
| Syntax highlighting | Colorize text as it is typed |
| Hint display | Show candidates in gray while typing |
| UTF-8 support | Correctly handles multibyte characters such as Japanese |
| Multi-line editing | Edit input that spans multiple lines |

---

## Usage Examples in C++

### Basic Usage

```cpp
#include <replxx.hxx>
#include <string>
#include <iostream>

int main() {
    replxx::Replxx rx;

    // Load history file
    rx.history_load("history.txt");

    // Main loop
    while (true) {
        // Display prompt and get input
        const char* input = rx.input("> ");

        if (input == nullptr) {
            // Ctrl+D (EOF)
            std::cout << std::endl;
            break;
        }

        std::string line(input);

        // Quit command
        if (line == ".quit" || line == ".") {
            break;
        }

        // Skip empty lines
        if (line.empty()) {
            continue;
        }

        // Add to history
        rx.history_add(line);

        // Process input
        std::cout << "You entered: " << line << std::endl;
    }

    // Save history
    rx.history_save("history.txt");

    return 0;
}
```

### Implementing Completion

```cpp
#include <replxx.hxx>
#include <vector>
#include <string>

// Callback that returns completion candidates
replxx::Replxx::completions_t completionCallback(
    const std::string& context,
    int& contextLen
) {
    replxx::Replxx::completions_t completions;

    // List of commands
    std::vector<std::string> commands = {
        ".help", ".quit", ".reset", ".save", ".load", ".log"
    };

    // Add matching completion candidates
    for (const auto& cmd : commands) {
        if (cmd.find(context) == 0) {
            completions.emplace_back(cmd);
        }
    }

    return completions;
}

int main() {
    replxx::Replxx rx;

    // Set completion callback
    rx.set_completion_callback(completionCallback);

    // ...
}
```

### Implementing Syntax Highlighting

```cpp
#include <replxx.hxx>

// Highlight callback
void highlightCallback(
    const std::string& context,
    replxx::Replxx::colors_t& colors
) {
    // Color commands (starting with .) in green
    if (!context.empty() && context[0] == '.') {
        for (size_t i = 0; i < context.size(); ++i) {
            colors[i] = replxx::Replxx::Color::GREEN;
        }
    }
}

int main() {
    replxx::Replxx rx;

    // Set highlight callback
    rx.set_highlighter_callback(highlightCallback);

    // ...
}
```

### Implementing Hint Functionality

```cpp
#include <replxx.hxx>

// Hint callback
replxx::Replxx::hints_t hintCallback(
    const std::string& context,
    int& contextLen,
    replxx::Replxx::Color& color
) {
    replxx::Replxx::hints_t hints;
    color = replxx::Replxx::Color::GRAY;

    // Show ".help" as a hint when ".h" is typed
    if (context == ".h") {
        hints.emplace_back("elp");
    }

    return hints;
}

int main() {
    replxx::Replxx rx;

    // Set hint callback
    rx.set_hint_callback(hintCallback);

    // ...
}
```

---

## Key Bindings

replxx supports Emacs-style key bindings.
The following key bindings are available in this project's REPL.

### Cursor Movement

| Key | Action |
|-----|--------|
| `Ctrl+A` | Move to beginning of line |
| `Ctrl+E` | Move to end of line |
| `Ctrl+B` / `←` | Move one character left |
| `Ctrl+F` / `→` | Move one character right |
| `Alt+B` | Move one word left |
| `Alt+F` | Move one word right |

### Editing

| Key | Action |
|-----|--------|
| `Ctrl+D` | Delete character under cursor / EOF if input is empty |
| `Ctrl+H` / `Backspace` | Delete character to the left of cursor |
| `Ctrl+K` | Delete from cursor to end of line |
| `Ctrl+U` | Delete from beginning of line to cursor |
| `Ctrl+W` | Delete word to the left of cursor |
| `Ctrl+T` | Transpose character at cursor with the one to its left |
| `Ctrl+Y` | Yank (paste deleted text) |

### History

| Key | Action |
|-----|--------|
| `Ctrl+P` / `↑` | Navigate backward through history |
| `Ctrl+N` / `↓` | Navigate forward through history |
| `Ctrl+R` | Incremental search backward through history |
| `Ctrl+S` | Incremental search forward through history |
| `Alt+<` | Move to beginning of history |
| `Alt+>` | Move to end of history |

### Completion and Other

| Key | Action |
|-----|--------|
| `Tab` | Completion (command completion in this project) |
| `Ctrl+L` | Clear screen |
| `Ctrl+C` | Cancel current input |
| `Ctrl+D` | EOF (exits the REPL if input is empty) |

### Features Enabled in This Project

The following features are configured in this project's `run_repl()`:

| Feature | Setting | Description |
|---------|---------|-------------|
| History size | `rx.set_max_history_size(1000)` | Retains up to 1000 history entries |
| History persistence | `.llama_history` | Saves and restores history to/from a file |
| Tab completion | `set_completion_callback` | Completes commands starting with `.` |
| Syntax highlighting | `set_highlighter_callback` | Displays commands in green |

---

## History Management

```cpp
replxx::Replxx rx;

// Set maximum history size
rx.set_max_history_size(1000);

// Load history file
rx.history_load("~/.myapp_history");

// Add to history
rx.history_add("command");

// Save history
rx.history_save("~/.myapp_history");

// Clear history
rx.history_clear();
```

---

## Comparison with std::getline

| Feature | std::getline | replxx |
|---------|-------------|--------|
| Line editing | x | o |
| History | x | o |
| Completion | x | o |
| Syntax highlighting | x | o |
| Hint display | x | o |
| UTF-8 | Partial | o |
| Windows | o | o |

---

## Troubleshooting

### FetchContent Fails

The CMake version may be too old. CMake 3.11 or later is required.

```bash
cmake --version
```

### Link Error: replxx Not Found

Verify that `FetchContent_MakeAvailable(replxx)` has been executed.

### Japanese Characters Not Displayed Correctly

Verify that the terminal character encoding is set to UTF-8.

```bash
echo $LANG
# Should display something like ja_JP.UTF-8
```

---

## References

- [replxx GitHub](https://github.com/AmokHuginnsson/replxx)
- [replxx README](https://github.com/AmokHuginnsson/replxx/blob/master/README.md)
- [CMake FetchContent Documentation](https://cmake.org/cmake/help/latest/module/FetchContent.html)
