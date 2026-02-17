# =============================================================================
# Botan (Crypto and TLS for Modern C++) CMake configuration
#
# This file configures Botan library for the project.
# Botan is a C++ cryptography library that provides encryption, hashing,
# MAC, random number generation, TLS, and many other cryptographic operations.
#
# Download directory: ${CMAKE_CURRENT_SOURCE_DIR}/download/botan
# Install directory:  ${CMAKE_CURRENT_SOURCE_DIR}/download/botan-install
#
# - If botan-install/lib/libbotan-3.a already exists, skip download and build.
# - If download/botan/configure.py already exists, skip download (reuse cache).
# - Otherwise, download from GitHub, configure with configure.py, build, and install.
#
# Note: Botan uses a Python configure script (configure.py), not CMake.
#       Python 3 is required for building Botan.
#
# License: MIT License (this cmake file)
# Note: Botan library itself is licensed under the BSD 2-Clause License.
# =============================================================================

include_guard(GLOBAL)

message(STATUS "===============================================================")
message(STATUS "Botan configuration:")

# Path to download/install directories
set(BOTAN_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(BOTAN_SOURCE_DIR ${BOTAN_DOWNLOAD_DIR}/botan)
set(BOTAN_INSTALL_DIR ${BOTAN_DOWNLOAD_DIR}/botan-install)
set(BOTAN_VERSION "3.10.0")
set(BOTAN_URL "https://github.com/randombit/botan/archive/refs/tags/${BOTAN_VERSION}.tar.gz")

message(STATUS "BOTAN_SOURCE_DIR  = ${BOTAN_SOURCE_DIR}")
message(STATUS "BOTAN_INSTALL_DIR = ${BOTAN_INSTALL_DIR}")

# =============================================================================
# Botan Library: Download, Build, and Install (cached in download/ directory)
# =============================================================================
if(EXISTS ${BOTAN_INSTALL_DIR}/lib/libbotan-3.a)
    message(STATUS "Botan already built: ${BOTAN_INSTALL_DIR}/lib/libbotan-3.a")
else()
    # --- Download (skip if source already cached) ---
    if(EXISTS ${BOTAN_SOURCE_DIR}/configure.py)
        message(STATUS "Botan source already cached: ${BOTAN_SOURCE_DIR}")
    else()
        set(BOTAN_ARCHIVE ${BOTAN_DOWNLOAD_DIR}/botan-${BOTAN_VERSION}.tar.gz)
        set(BOTAN_URLS
            "https://github.com/randombit/botan/archive/refs/tags/${BOTAN_VERSION}.tar.gz"
        )

        set(BOTAN_DOWNLOADED FALSE)
        foreach(URL ${BOTAN_URLS})
            message(STATUS "Downloading Botan ${BOTAN_VERSION} from ${URL} ...")
            file(DOWNLOAD
                ${URL}
                ${BOTAN_ARCHIVE}
                SHOW_PROGRESS
                TIMEOUT 300
                INACTIVITY_TIMEOUT 60
                STATUS DOWNLOAD_STATUS
            )
            list(GET DOWNLOAD_STATUS 0 DOWNLOAD_RESULT)
            if(DOWNLOAD_RESULT EQUAL 0)
                set(BOTAN_DOWNLOADED TRUE)
                break()
            else()
                list(GET DOWNLOAD_STATUS 1 DOWNLOAD_ERROR)
                message(WARNING "Download from ${URL} failed: ${DOWNLOAD_ERROR}")
                file(REMOVE ${BOTAN_ARCHIVE})
            endif()
        endforeach()

        if(NOT BOTAN_DOWNLOADED)
            message(FATAL_ERROR
                "Botan download failed.\n"
                "You can manually download and place the file:\n"
                "  curl -L -o download/botan-${BOTAN_VERSION}.tar.gz ${BOTAN_URL}\n"
                "Then re-run cmake."
            )
        endif()

        message(STATUS "Extracting Botan ${BOTAN_VERSION} ...")
        file(ARCHIVE_EXTRACT
            INPUT ${BOTAN_ARCHIVE}
            DESTINATION ${BOTAN_DOWNLOAD_DIR}
        )
        # Rename extracted directory (botan-3.10.0 -> botan)
        file(RENAME ${BOTAN_DOWNLOAD_DIR}/botan-${BOTAN_VERSION} ${BOTAN_SOURCE_DIR})

        message(STATUS "Botan source cached: ${BOTAN_SOURCE_DIR}")
    endif()

    # --- Find Python 3 (required for configure.py) ---
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
    message(STATUS "Python3 found: ${Python3_EXECUTABLE}")

    # --- Configure (Python configure.py) ---
    message(STATUS "Configuring Botan with configure.py ...")
    execute_process(
        COMMAND ${Python3_EXECUTABLE} ${BOTAN_SOURCE_DIR}/configure.py
                --prefix=${BOTAN_INSTALL_DIR}
                --minimized-build
                --enable-modules=sha2_32,sha2_64,sha3,hmac,aes,gcm,ctr,auto_rng,system_rng,base64,hex
                --disable-shared-library
        WORKING_DIRECTORY ${BOTAN_SOURCE_DIR}
        RESULT_VARIABLE BOTAN_CONFIGURE_RESULT
    )
    if(NOT BOTAN_CONFIGURE_RESULT EQUAL 0)
        message(FATAL_ERROR "Botan configure.py failed")
    endif()

    # --- Build ---
    message(STATUS "Building Botan (this may take a while) ...")
    execute_process(
        COMMAND make -j4
        WORKING_DIRECTORY ${BOTAN_SOURCE_DIR}
        RESULT_VARIABLE BOTAN_BUILD_RESULT
    )
    if(NOT BOTAN_BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "Botan build failed")
    endif()

    # --- Install ---
    message(STATUS "Installing Botan to ${BOTAN_INSTALL_DIR} ...")
    execute_process(
        COMMAND make install
        WORKING_DIRECTORY ${BOTAN_SOURCE_DIR}
        RESULT_VARIABLE BOTAN_INSTALL_RESULT
    )
    if(NOT BOTAN_INSTALL_RESULT EQUAL 0)
        message(FATAL_ERROR "Botan install failed")
    endif()

    message(STATUS "Botan ${BOTAN_VERSION} built and installed successfully")
endif()

# =============================================================================
# Botan Library Configuration
# =============================================================================
# Botan requires C++20.
# On Linux, pthread must be explicitly linked. On macOS, it is linked by default.

# Set up imported library target
add_library(botan_lib STATIC IMPORTED)
set_target_properties(botan_lib PROPERTIES
    IMPORTED_LOCATION ${BOTAN_INSTALL_DIR}/lib/libbotan-3.a
)

# Add include directories (Botan 3.x installs headers to include/botan-3/)
target_include_directories(${PROJECT_NAME} PRIVATE ${BOTAN_INSTALL_DIR}/include/botan-3)

if(APPLE)
    # macOS: pthread is linked by default; link Security and CoreFoundation frameworks
    target_link_libraries(${PROJECT_NAME} PRIVATE botan_lib "-framework Security" "-framework CoreFoundation")
else()
    # Linux: explicitly link pthread
    find_package(Threads REQUIRED)
    target_link_libraries(${PROJECT_NAME} PRIVATE botan_lib Threads::Threads)
endif()

# Botan 3.x requires C++20
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_20)

message(STATUS "Botan linked to ${PROJECT_NAME}")
message(STATUS "===============================================================")
