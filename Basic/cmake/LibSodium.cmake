# =============================================================================
# LibSodium CMake configuration
#
# This file configures the libsodium library for the project.
# libsodium is a modern, portable, easy to use crypto library.
# Features: authenticated encryption, key exchange, signatures,
# password hashing, secret-key encryption, and more.
#
# Download directory: ${CMAKE_CURRENT_SOURCE_DIR}/download/LibSodium
# Install directory:  ${CMAKE_CURRENT_SOURCE_DIR}/download/LibSodium/libsodium-install
#
# - If libsodium-install/lib/libsodium.a already exists, skip download and build.
# - If download/LibSodium/libsodium/configure already exists, skip download (reuse cache).
# - Otherwise, download from GitHub, configure, build, and install.
#
# License: MIT License (this cmake file)
# Note: libsodium library itself is licensed under ISC License.
# =============================================================================

include_guard(GLOBAL)

message(STATUS "===============================================================")
message(STATUS "LibSodium configuration:")

# Path to download/install directories
set(LIBSODIUM_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/LibSodium)
set(LIBSODIUM_SOURCE_DIR ${LIBSODIUM_DOWNLOAD_DIR}/libsodium)
set(LIBSODIUM_INSTALL_DIR ${LIBSODIUM_DOWNLOAD_DIR}/libsodium-install)
set(LIBSODIUM_VERSION "1.0.21")
set(LIBSODIUM_URL "https://github.com/jedisct1/libsodium/archive/refs/tags/${LIBSODIUM_VERSION}-RELEASE.tar.gz")

message(STATUS "LIBSODIUM_SOURCE_DIR  = ${LIBSODIUM_SOURCE_DIR}")
message(STATUS "LIBSODIUM_INSTALL_DIR = ${LIBSODIUM_INSTALL_DIR}")

# =============================================================================
# LibSodium Library: Download, Build, and Install (cached in download/ directory)
# =============================================================================
if(EXISTS ${LIBSODIUM_INSTALL_DIR}/lib/libsodium.a)
    message(STATUS "libsodium already built: ${LIBSODIUM_INSTALL_DIR}/lib/libsodium.a")
else()
    # --- Download (skip if source already cached) ---
    if(EXISTS ${LIBSODIUM_SOURCE_DIR}/configure)
        message(STATUS "libsodium source already cached: ${LIBSODIUM_SOURCE_DIR}")
    else()
        set(LIBSODIUM_ARCHIVE ${LIBSODIUM_DOWNLOAD_DIR}/libsodium-${LIBSODIUM_VERSION}.tar.gz)
        set(LIBSODIUM_URLS
            "https://github.com/jedisct1/libsodium/archive/refs/tags/${LIBSODIUM_VERSION}-RELEASE.tar.gz"
            "https://download.libsodium.org/libsodium/releases/libsodium-${LIBSODIUM_VERSION}.tar.gz"
        )

        set(LIBSODIUM_DOWNLOADED FALSE)
        foreach(URL ${LIBSODIUM_URLS})
            message(STATUS "Downloading libsodium ${LIBSODIUM_VERSION} from ${URL} ...")
            file(DOWNLOAD
                ${URL}
                ${LIBSODIUM_ARCHIVE}
                SHOW_PROGRESS
                TIMEOUT 300
                INACTIVITY_TIMEOUT 60
                STATUS DOWNLOAD_STATUS
            )
            list(GET DOWNLOAD_STATUS 0 DOWNLOAD_RESULT)
            if(DOWNLOAD_RESULT EQUAL 0)
                set(LIBSODIUM_DOWNLOADED TRUE)
                break()
            else()
                list(GET DOWNLOAD_STATUS 1 DOWNLOAD_ERROR)
                message(WARNING "Download from ${URL} failed: ${DOWNLOAD_ERROR}")
                file(REMOVE ${LIBSODIUM_ARCHIVE})
            endif()
        endforeach()

        if(NOT LIBSODIUM_DOWNLOADED)
            message(FATAL_ERROR
                "libsodium download failed.\n"
                "You can manually download and place the file:\n"
                "  curl -L -o download/LibSodium/libsodium-${LIBSODIUM_VERSION}.tar.gz ${LIBSODIUM_URL}\n"
                "Then re-run cmake."
            )
        endif()

        message(STATUS "Extracting libsodium ${LIBSODIUM_VERSION} ...")
        file(ARCHIVE_EXTRACT
            INPUT ${LIBSODIUM_ARCHIVE}
            DESTINATION ${LIBSODIUM_DOWNLOAD_DIR}
        )
        # Rename extracted directory (libsodium-1.0.21-RELEASE -> libsodium)
        file(RENAME ${LIBSODIUM_DOWNLOAD_DIR}/libsodium-${LIBSODIUM_VERSION}-RELEASE ${LIBSODIUM_SOURCE_DIR})

        message(STATUS "libsodium source cached: ${LIBSODIUM_SOURCE_DIR}")
    endif()

    # --- Configure (autoconf-based build) ---
    # libsodium uses autoconf, not CMake.
    # Run ./configure with --prefix to set the install directory.

    # Check if autogen.sh needs to be run (GitHub archives may need it)
    if(NOT EXISTS ${LIBSODIUM_SOURCE_DIR}/configure AND EXISTS ${LIBSODIUM_SOURCE_DIR}/autogen.sh)
        message(STATUS "Running autogen.sh ...")
        execute_process(
            COMMAND sh autogen.sh
            WORKING_DIRECTORY ${LIBSODIUM_SOURCE_DIR}
            RESULT_VARIABLE LIBSODIUM_AUTOGEN_RESULT
        )
        if(NOT LIBSODIUM_AUTOGEN_RESULT EQUAL 0)
            message(FATAL_ERROR "libsodium autogen.sh failed")
        endif()
    endif()

    message(STATUS "Configuring libsodium ...")
    execute_process(
        COMMAND ${LIBSODIUM_SOURCE_DIR}/configure
                --prefix=${LIBSODIUM_INSTALL_DIR}
                --disable-shared
                --enable-static
                --with-pic
        WORKING_DIRECTORY ${LIBSODIUM_SOURCE_DIR}
        RESULT_VARIABLE LIBSODIUM_CONFIGURE_RESULT
    )
    if(NOT LIBSODIUM_CONFIGURE_RESULT EQUAL 0)
        message(FATAL_ERROR "libsodium configure failed")
    endif()

    # --- Build ---
    message(STATUS "Building libsodium ...")
    execute_process(
        COMMAND make -j4
        WORKING_DIRECTORY ${LIBSODIUM_SOURCE_DIR}
        RESULT_VARIABLE LIBSODIUM_BUILD_RESULT
    )
    if(NOT LIBSODIUM_BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "libsodium build failed")
    endif()

    # --- Install ---
    message(STATUS "Installing libsodium to ${LIBSODIUM_INSTALL_DIR} ...")
    execute_process(
        COMMAND make install
        WORKING_DIRECTORY ${LIBSODIUM_SOURCE_DIR}
        RESULT_VARIABLE LIBSODIUM_INSTALL_RESULT
    )
    if(NOT LIBSODIUM_INSTALL_RESULT EQUAL 0)
        message(FATAL_ERROR "libsodium install failed")
    endif()

    message(STATUS "libsodium ${LIBSODIUM_VERSION} built and installed successfully")
endif()

# =============================================================================
# LibSodium Library Configuration
# =============================================================================
# Create imported target
add_library(sodium_lib STATIC IMPORTED)
set_target_properties(sodium_lib PROPERTIES
    IMPORTED_LOCATION ${LIBSODIUM_INSTALL_DIR}/lib/libsodium.a
)

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${LIBSODIUM_INSTALL_DIR}/include
)

# Link libsodium to the project
target_link_libraries(${PROJECT_NAME} PRIVATE sodium_lib)

message(STATUS "libsodium linked to ${PROJECT_NAME}")
message(STATUS "===============================================================")
