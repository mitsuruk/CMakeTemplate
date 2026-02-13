# =============================================================================
# boost.cmake - Boost Configuration File
#
# Project: [CMake Template Project]
# Author: [mitsuruk]
# Date:    2025/11/26
# License: MIT License
# See LICENSE.md for details.
# =============================================================================

include_guard(GLOBAL)

# 1. Define all component names in a single place
set(BOOST_COMPONENTS
    headers            # Common Boost headers (required by most Boost libraries)
    # atomic             # Atomic operations (lock-free primitives for concurrent processing)
    # chrono             # Time representation and measurement (similar functionality to `std::chrono`)
    # container          # High-speed alternatives to standard containers (small-size optimization and flat structure support)
    # context            # Low-level context switching (foundation for coroutines and fibers)
    # coroutine          # Cooperative multitasking (coroutine abstraction, built on `Boost::context`)
    # date_time          # Date/time and time interval calculations (supports calendar time and special date handling)
    # fiber              # User-land threads (cooperative scheduling between threads)
    # filesystem         # File and directory operations (API similar to `std::filesystem`)
    # graph              # Graph structures and algorithms (provides Dijkstra, DFS, etc.)
    # iostreams          # Custom I/O streams (supports compression/encryption/memory buffers, etc.)
    # json               # High-speed JSON parser and generator (fully RFC compliant)
    # locale             # Localization (i18n/l10n), message translation, currency and date localization
    # log_setup          # Boost.Log initialization support (supports configuration via config files, etc.)
    # log                # Advanced logging functionality (filters, formatting, asynchronous, etc.)
    # math_c99           # C99-compliant math functions (for double precision, e.g., `tgamma`, `lgamma`)
    # math_c99f          # C99-compliant math functions (for single precision)
    # math_tr1           # TR1 math function set (extensions provided before C++11)
    # math_tr1f          # TR1 math functions (single precision)
    # nowide             # Character encoding abstraction for Windows (unified `wchar_t` support)
    # prg_exec_monitor   # Exception and signal monitoring during test execution (also used internally by Boost.Test)
    # program_options    # Option parsing from command line and configuration files
    # random             # Pseudo-random number generators (provides various distributions and engines)
    # regex              # Regular expressions (Perl-compatible, Unicode support, search and replace)
    # serialization      # C++ object serialization and deserialization (supports XML/text/binary)
    # stacktrace_addr2line # Runtime stack trace output using addr2line (for Linux)
    # stacktrace_basic   # Stack trace output with minimal dependencies (for debugging)
    # stacktrace_noop    # Disables stack trace (used as replacement during build)
    # thread             # Thread abstraction and synchronization mechanisms (similar to `std::thread` but with Boost-specific features)
    # timer              # Elapsed time measurement (simpler than `boost::chrono`)
    # type_erasure       # Polymorphism through type erasure (generalization of `std::any` and `std::function`)
    # unit_test_framework # Integrated unit testing framework (test cases, automatic registration, etc.)
    # url                # URL parsing and generation (provides standards-compliant URL operations)
    # wave               # C++ preprocessor implementation (for token analysis and source transformation)
    # wserialization     # Wide character (UTF-16/UTF-32) support extension for Boost.Serialization

    # The following are not intended for use and can be removed
    # process          # Process creation, control, and pipe handling (UNIX/Windows supported)
    # math_tr1l        # TR1 math functions (extended precision)
    # math_c99l        # C99-compliant math functions (extended precision)
    # contract         # Contract programming (pre-conditions, post-conditions, class invariants, etc.)
    # charconv         # Fast numeric <-> string conversion (C++17 std::to_chars compatible)
    # numpy313         # [Unused] NumPy array support via Boost.Python (Python 3.13 compatible)
    # python313        # [Unused] C++/Python integration via Boost.Python (Python 3.13 compatible)
)

# 2. Search for Boost using only the component names
find_package(Boost 1.80.0 REQUIRED CONFIG COMPONENTS ${BOOST_COMPONENTS})

# 3. Automatically generate Boost::xxx style target names
set(BOOST_DYNAMIC_LIBS "")
foreach(comp IN LISTS BOOST_COMPONENTS)
    list(APPEND BOOST_DYNAMIC_LIBS "Boost::${comp}")
endforeach()

# 4. Link the targets
target_link_libraries(${PROJECT_NAME} PRIVATE ${BOOST_DYNAMIC_LIBS})

# 5. for Debug information
message(STATUS "Boost version: ${Boost_VERSION}")
message(STATUS "Boost include dirs: ${Boost_INCLUDE_DIRS}")
message(STATUS "Boost libraries: ${BOOST_DYNAMIC_LIBS}")
