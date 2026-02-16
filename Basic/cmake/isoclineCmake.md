# isocline.cmake Reference

## Overview

`isocline.cmake` is a CMake configuration file that automatically downloads, builds, and links the isocline library.
It uses CMake's `file(DOWNLOAD)` and `execute_process` to manage the dependency, with caching in the `download/` directory to avoid redundant downloads and rebuilds.

isocline is a portable GNU readline alternative written in pure C. It provides rich interactive console input with features such as multi-line editing, syntax highlighting, tab completion with preview, Unicode support, 24-bit color, persistent history, brace matching, and BBCode-style formatted output.

isocline has no external dependencies and can be compiled as a single C file.

## File Information

| Item | Details |
|------|---------|
| Source Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/isocline/isocline` |
| Install Directory | `${CMAKE_CURRENT_SOURCE_DIR}/download/isocline/isocline-install` |
| Download URL | https://github.com/daanx/isocline/archive/refs/tags/v1.0.9.tar.gz |
| Version | 1.0.9 |
| License | MIT |

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
isocline/
├── cmake/
│   ├── isocline.cmake       # This configuration file
│   ├── isoclineCmake.md     # This document
│   └── isoclineCmake-jp.md  # Japanese version of this document
├── download/isocline/
│   ├── isocline/            # isocline source (cached, downloaded from GitHub)
│   └── isocline-install/    # isocline built artifacts (lib/, include/)
│       ├── include/
│       │   └── isocline.h
│       └── lib/
│           └── libisocline.a
├── src/
│   └── main.cpp
├── build/
└── CMakeLists.txt
```

## Usage

### Adding to CMakeLists.txt

```cmake
# Include isocline.cmake at the end of CMakeLists.txt
include("./cmake/isocline.cmake")
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
set(ISOCLINE_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/isocline)
set(ISOCLINE_SOURCE_DIR ${ISOCLINE_DOWNLOAD_DIR}/isocline)
set(ISOCLINE_INSTALL_DIR ${ISOCLINE_DOWNLOAD_DIR}/isocline-install)
set(ISOCLINE_VERSION "1.0.9")
set(ISOCLINE_URL "https://github.com/daanx/isocline/archive/refs/tags/v${ISOCLINE_VERSION}.tar.gz")
```

### 2. Cache Check and Conditional Build

```cmake
if(EXISTS ${ISOCLINE_INSTALL_DIR}/lib/libisocline.a)
    message(STATUS "isocline already built: ${ISOCLINE_INSTALL_DIR}/lib/libisocline.a")
else()
    # Download, configure, build, and install ...
endif()
```

The cache logic works as follows:

| Condition | Action |
|-----------|--------|
| `isocline-install/lib/libisocline.a` exists | Skip everything (use cached build) |
| `isocline/CMakeLists.txt` exists (install missing) | Skip download, run cmake configure/build/install |
| Nothing exists | Download, extract, configure, build, install |

### 3. Download (if needed)

```cmake
file(DOWNLOAD
    ${ISOCLINE_URL}
    ${ISOCLINE_DOWNLOAD_DIR}/isocline-${ISOCLINE_VERSION}.tar.gz
    SHOW_PROGRESS
    STATUS DOWNLOAD_STATUS
)
file(ARCHIVE_EXTRACT
    INPUT ${ISOCLINE_DOWNLOAD_DIR}/isocline-${ISOCLINE_VERSION}.tar.gz
    DESTINATION ${ISOCLINE_DOWNLOAD_DIR}
)
file(RENAME ${ISOCLINE_DOWNLOAD_DIR}/isocline-${ISOCLINE_VERSION} ${ISOCLINE_SOURCE_DIR})
```

- Downloads from GitHub (daanx/isocline releases)
- Extracts and renames `isocline-1.0.9/` to `isocline/` for a clean path

### 4. Configure and Build (CMake-based)

```cmake
execute_process(
    COMMAND ${CMAKE_COMMAND}
            -DCMAKE_INSTALL_PREFIX=${ISOCLINE_INSTALL_DIR}
            -DCMAKE_BUILD_TYPE=Release
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON
            ${ISOCLINE_SOURCE_DIR}
    WORKING_DIRECTORY ${ISOCLINE_BUILD_DIR}
)
execute_process(
    COMMAND ${CMAKE_COMMAND} --build . --target isocline -j4
    WORKING_DIRECTORY ${ISOCLINE_BUILD_DIR}
)
```

- Uses CMake to configure and build (unlike autoconf-based libraries)
- `-DCMAKE_POSITION_INDEPENDENT_CODE=ON`: Generates position-independent code
- Builds only the `isocline` library target (not examples or tests)
- All steps run at CMake configure time, not at build time

### 5. Install (Manual)

Since isocline's CMakeLists.txt does not include install rules, the install step is performed manually:

```cmake
file(COPY ${ISOCLINE_LIB_FILE} DESTINATION ${ISOCLINE_INSTALL_DIR}/lib)
file(COPY ${ISOCLINE_SOURCE_DIR}/include/isocline.h DESTINATION ${ISOCLINE_INSTALL_DIR}/include)
```

### 6. Linking the Library

```cmake
add_library(isocline_lib STATIC IMPORTED)
set_target_properties(isocline_lib PROPERTIES
    IMPORTED_LOCATION ${ISOCLINE_INSTALL_DIR}/lib/libisocline.a
)

target_include_directories(${PROJECT_NAME} PRIVATE ${ISOCLINE_INSTALL_DIR}/include)
target_link_libraries(${PROJECT_NAME} PRIVATE isocline_lib)
```

Unlike GSL, isocline is a single library with no additional dependencies (no `-lm` or CBLAS needed).

---

## isocline Library

isocline consists of a single library:

| Library | File | Description |
|---------|------|-------------|
| `libisocline` | `libisocline.a` | The isocline library containing all readline functionality |

The library is written in pure C with no external dependencies. It uses only standard POSIX APIs and ANSI escape sequences for terminal interaction.

---

## Key Features of isocline

| Feature | API Functions | Description |
|---------|---------------|-------------|
| Readline | `ic_readline`, `ic_readline_ex` | Read interactive input with rich editing |
| History | `ic_set_history`, `ic_history_add`, `ic_history_remove_last`, `ic_history_clear` | Persistent command history with file storage |
| Tab Completion | `ic_set_default_completer`, `ic_add_completion`, `ic_add_completions` | Customizable tab completion with preview |
| Filename Completion | `ic_complete_filename` | Built-in filename/path completion |
| Word Completion | `ic_complete_word`, `ic_complete_qword` | Word-boundary and quoted-word completion |
| Syntax Highlighting | `ic_set_default_highlighter`, `ic_highlight` | Custom syntax highlighting callback |
| BBCode Output | `ic_print`, `ic_println`, `ic_printf` | Styled terminal output using BBCode markup |
| Style Definition | `ic_style_def`, `ic_style_open`, `ic_style_close` | Define and apply custom named styles |
| Prompt Configuration | `ic_set_prompt_marker`, `ic_get_prompt_marker` | Configure prompt and continuation markers |
| Multi-line Editing | `ic_enable_multiline` | Multi-line input with Shift+Tab |
| Brace Matching | `ic_enable_brace_matching`, `ic_enable_brace_insertion` | Highlight matching braces, auto-insert closing braces |
| Hints | `ic_enable_hint`, `ic_set_hint_delay` | Inline completion hints |
| Color Control | `ic_enable_color` | Enable/disable color output |
| Terminal API | `ic_term_init`, `ic_term_write`, `ic_term_color_rgb` | Low-level terminal control |
| Async Stop | `ic_async_stop` | Thread-safe way to interrupt readline |
| Custom Allocator | `ic_init_custom_alloc`, `ic_malloc`, `ic_free` | Custom memory allocation |

---

## Usage Examples in C/C++

### Basic Readline Loop

```c
#include <isocline.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    ic_set_history("history.txt", -1);

    char *input;
    while ((input = ic_readline("prompt> ")) != NULL) {
        printf("you typed: %s\n", input);
        free(input);
    }
    return 0;
}
```

### Tab Completion

```c
#include <isocline.h>
#include <stdio.h>
#include <stdlib.h>

static const char *commands[] = {
    "help", "exit", "list", "add", "remove", NULL
};

static void completer(ic_completion_env_t *cenv, const char *prefix) {
    ic_add_completions(cenv, prefix, commands);
}

int main() {
    ic_set_default_completer(&completer, NULL);
    ic_enable_completion_preview(true);

    char *input;
    while ((input = ic_readline("$ ")) != NULL) {
        printf("command: %s\n", input);
        free(input);
    }
    return 0;
}
```

### Syntax Highlighting

```c
#include <isocline.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char *keywords[] = {
    "if", "else", "while", "for", "return", NULL
};

static void highlighter(ic_highlight_env_t *henv, const char *input, void *arg) {
    (void)arg;
    for (int i = 0; keywords[i] != NULL; i++) {
        size_t len = strlen(keywords[i]);
        if (strncmp(input, keywords[i], len) == 0 &&
            (input[len] == '\0' || input[len] == ' ')) {
            ic_highlight(henv, 0, (long)len, "keyword");
            break;
        }
    }
}

int main() {
    ic_style_def("keyword", "[blue]");
    ic_set_default_highlighter(&highlighter, NULL);

    char *input;
    while ((input = ic_readline("> ")) != NULL) {
        printf("%s\n", input);
        free(input);
    }
    return 0;
}
```

### BBCode Styled Output

```c
#include <isocline.h>

int main() {
    ic_println("[b]Bold[/b] and [i]italic[/i] text");
    ic_println("[red]Error:[/red] something failed");
    ic_println("[green]Success:[/green] operation completed");

    // Define custom styles
    ic_style_def("header", "[bold][underline]");
    ic_println("[header]My Application[/header]");

    // Printf-style with BBCode
    ic_printf("[blue]Result:[/blue] %d\n", 42);

    return 0;
}
```

### Filename Completion

```c
#include <isocline.h>
#include <stdio.h>
#include <stdlib.h>

static void completer(ic_completion_env_t *cenv, const char *prefix) {
    // Complete filenames with any extension, using default directory separator
    ic_complete_filename(cenv, prefix, 0, NULL, NULL);
}

int main() {
    ic_set_default_completer(&completer, NULL);
    ic_enable_completion_preview(true);

    char *input;
    while ((input = ic_readline("file> ")) != NULL) {
        printf("selected: %s\n", input);
        free(input);
    }
    return 0;
}
```

### Advanced Completion with Help Text

```c
#include <isocline.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void completer(ic_completion_env_t *cenv, const char *prefix) {
    // Add completions with display text and help descriptions
    if (strncmp("help", prefix, strlen(prefix)) == 0) {
        ic_add_completion_ex(cenv, "help", "help", "Show help information");
    }
    if (strncmp("exit", prefix, strlen(prefix)) == 0) {
        ic_add_completion_ex(cenv, "exit", "exit", "Exit the program");
    }
    if (strncmp("list", prefix, strlen(prefix)) == 0) {
        ic_add_completion_ex(cenv, "list", "list", "List all items");
    }
}

int main() {
    ic_set_default_completer(&completer, NULL);
    ic_enable_completion_preview(true);
    ic_enable_inline_help(true);

    char *input;
    while ((input = ic_readline("$ ")) != NULL) {
        printf("command: %s\n", input);
        free(input);
    }
    return 0;
}
```

### Multi-line Input with Custom Prompt

```c
#include <isocline.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    ic_enable_multiline(true);
    ic_enable_brace_matching(true);
    ic_enable_brace_insertion(true);
    ic_set_prompt_marker("> ", "  ");

    char *input;
    while ((input = ic_readline("")) != NULL) {
        printf("input:\n%s\n", input);
        free(input);
    }
    return 0;
}
```

---

## isocline API Conventions

### Function Naming Conventions

isocline function names follow a consistent `ic_` prefix convention:

| Pattern | Example | Description |
|---------|---------|-------------|
| `ic_readline*` | `ic_readline("prompt")` | Read interactive input |
| `ic_set_*` | `ic_set_history(...)` | Configure a setting |
| `ic_enable_*` | `ic_enable_multiline(true)` | Enable/disable a feature |
| `ic_add_completion*` | `ic_add_completion(cenv, str)` | Add completion candidates |
| `ic_complete_*` | `ic_complete_filename(...)` | Built-in completion helpers |
| `ic_print*` | `ic_println("text")` | BBCode-styled terminal output |
| `ic_style_*` | `ic_style_def("name", "[blue]")` | Define/manage named styles |
| `ic_highlight*` | `ic_highlight(henv, pos, len, style)` | Apply syntax highlighting |
| `ic_history_*` | `ic_history_add("entry")` | Manipulate history |
| `ic_term_*` | `ic_term_write("text")` | Low-level terminal operations |

### Memory Management

`ic_readline()` returns a heap-allocated `char*` that the caller must `free()`:

```c
char *input = ic_readline("prompt> ");
if (input != NULL) {
    // ... use input ...
    free(input);  // caller must free
}
```

When custom allocators are configured via `ic_init_custom_alloc()`, use `ic_free()` instead of `free()`.

### Return Values

- `ic_readline()` returns `NULL` on EOF (Ctrl+D), Ctrl+C, or error
- `ic_add_completion()` returns `true` if the completion was added
- Most configuration functions (`ic_set_*`, `ic_enable_*`) return `void`

### BBCode Markup Reference

| Tag | Effect |
|-----|--------|
| `[b]...[/b]` | Bold |
| `[i]...[/i]` | Italic |
| `[u]...[/u]` | Underline |
| `[red]...[/red]` | Red text (also: green, blue, yellow, cyan, magenta, white, black) |
| `[#RRGGBB]...[/#]` | 24-bit RGB color |
| `[bold]` | Same as `[b]` |
| `[underline]` | Same as `[u]` |
| `[italic]` | Same as `[i]` |
| `[reverse]` | Reverse video |

---

## Comparison: isocline vs Other Readline Libraries

| Feature | isocline | GNU readline | libedit | linenoise |
|---------|----------|-------------|---------|-----------|
| Language | C | C | C | C |
| License | MIT | GPL v3 | BSD | BSD |
| Dependencies | None | ncurses/termcap | ncurses | None |
| Unicode | Full | Partial | Partial | No |
| Multi-line | Yes | No | No | No |
| 24-bit Color | Yes | No | No | No |
| Syntax Highlighting | Yes | No | No | No |
| Completion Preview | Yes | No | No | No |
| Brace Matching | Yes | No | No | No |
| BBCode Output | Yes | No | No | No |
| History Search | Yes (Ctrl+R) | Yes (Ctrl+R) | Yes | No |
| Windows Support | Yes | No (Cygwin) | No | Partial |
| Code Size | ~8000 lines | ~40000 lines | ~30000 lines | ~1000 lines |

isocline provides the richest feature set among readline alternatives while remaining lightweight and dependency-free. It is particularly suitable for interactive CLI tools that need syntax highlighting, completion preview, and multi-line editing.

---

## Environment Variables

| Variable | Effect |
|----------|--------|
| `NO_COLOR` | When present, disables all color output |
| `CLICOLOR=1` | Enables `LS_COLORS` for filename completion colorization |
| `COLORTERM` | Force color palette: `truecolor`, `256color`, `16color`, `8color`, `monochrome` |
| `TERM` | Used for terminal capability detection |

---

## Troubleshooting

### Download Fails

If GitHub is unreachable, you can manually download and place the tarball:

```bash
curl -L -o download/isocline/isocline-1.0.9.tar.gz \
    https://github.com/daanx/isocline/archive/refs/tags/v1.0.9.tar.gz
```

Then re-run `cmake ..` and the extraction will proceed from the cached tarball.

### Build Fails

Ensure that CMake 3.10+ and a C99-compatible compiler are available:

```bash
cmake --version
cc --version
```

### Rebuild isocline from Scratch

To force a full rebuild, remove the install and source directories:

```bash
rm -rf download/isocline/isocline-install download/isocline/isocline
cd build && cmake ..
```

### Header Not Found: `isocline.h`

If you see `'isocline.h' file not found`, ensure that the build has completed at least once. The header is copied to the install directory during the CMake configure step:

```bash
cd build && cmake .. && make
```

After a successful build, the IDE diagnostics will resolve as `compile_commands.json` is updated.

---

## References

- [isocline GitHub Repository](https://github.com/daanx/isocline)
- [isocline API Documentation](https://daanx.github.io/isocline/)
- [isocline README](https://github.com/daanx/isocline/blob/main/readme.md)
- [Readline API Reference](https://daanx.github.io/isocline/group__readline.html)
- [History API Reference](https://daanx.github.io/isocline/group__history.html)
- [Completion API Reference](https://daanx.github.io/isocline/group__completion.html)
- [Highlighting API Reference](https://daanx.github.io/isocline/group__highlight.html)
- [BBCode API Reference](https://daanx.github.io/isocline/group__bbcode.html)
