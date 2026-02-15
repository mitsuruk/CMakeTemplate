# =============================================================================
# GMP (GNU Multiple Precision Arithmetic Library) CMake configuration
#
# This file configures GMP library for the project.
# GMP is a free library for arbitrary precision arithmetic, operating on
# signed integers, rational numbers, and floating-point numbers.
#
# Download directory: ${CMAKE_CURRENT_SOURCE_DIR}/download/gmp
# Install directory:  ${CMAKE_CURRENT_SOURCE_DIR}/download/gmp-install
#
# - If gmp-install/lib/libgmp.a already exists, skip download and build.
# - If download/gmp/configure already exists, skip download (reuse cache).
# - Otherwise, download from ftp.gnu.org, configure, build, and install.
#
# License: MIT License (this cmake file)
# Note: GMP library itself is dual-licensed under GNU LGPL v3 and GNU GPL v2.
# =============================================================================

include_guard(GLOBAL)

message(STATUS "===============================================================")
message(STATUS "GMP configuration:")

# Path to download/install directories
set(GMP_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(GMP_SOURCE_DIR ${GMP_DOWNLOAD_DIR}/gmp)
set(GMP_INSTALL_DIR ${GMP_DOWNLOAD_DIR}/gmp-install)
set(GMP_VERSION "6.3.0")
set(GMP_URL "https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.xz")

message(STATUS "GMP_SOURCE_DIR  = ${GMP_SOURCE_DIR}")
message(STATUS "GMP_INSTALL_DIR = ${GMP_INSTALL_DIR}")

# =============================================================================
# GMP Library: Download, Build, and Install (cached in download/ directory)
# =============================================================================
if(EXISTS ${GMP_INSTALL_DIR}/lib/libgmp.a AND EXISTS ${GMP_INSTALL_DIR}/lib/libgmpxx.a)
    message(STATUS "GMP already built: ${GMP_INSTALL_DIR}/lib/libgmp.a")
else()
    # --- Download (skip if source already cached) ---
    if(EXISTS ${GMP_SOURCE_DIR}/configure)
        message(STATUS "GMP source already cached: ${GMP_SOURCE_DIR}")
    else()
        set(GMP_ARCHIVE ${GMP_DOWNLOAD_DIR}/gmp-${GMP_VERSION}.tar.xz)
        set(GMP_URLS
            "https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.xz"
            "https://ftpmirror.gnu.org/gmp/gmp-${GMP_VERSION}.tar.xz"
        )

        set(GMP_DOWNLOADED FALSE)
        foreach(URL ${GMP_URLS})
            message(STATUS "Downloading GMP ${GMP_VERSION} from ${URL} ...")
            file(DOWNLOAD
                ${URL}
                ${GMP_ARCHIVE}
                SHOW_PROGRESS
                TIMEOUT 300
                INACTIVITY_TIMEOUT 60
                STATUS DOWNLOAD_STATUS
            )
            list(GET DOWNLOAD_STATUS 0 DOWNLOAD_RESULT)
            if(DOWNLOAD_RESULT EQUAL 0)
                set(GMP_DOWNLOADED TRUE)
                break()
            else()
                list(GET DOWNLOAD_STATUS 1 DOWNLOAD_ERROR)
                message(WARNING "Download from ${URL} failed: ${DOWNLOAD_ERROR}")
                file(REMOVE ${GMP_ARCHIVE})
            endif()
        endforeach()

        if(NOT GMP_DOWNLOADED)
            message(FATAL_ERROR
                "GMP download failed from all mirrors.\n"
                "You can manually download and place the file:\n"
                "  curl -L -o download/gmp-${GMP_VERSION}.tar.xz ${GMP_URL}\n"
                "Then re-run cmake."
            )
        endif()

        message(STATUS "Extracting GMP ${GMP_VERSION} ...")
        file(ARCHIVE_EXTRACT
            INPUT ${GMP_DOWNLOAD_DIR}/gmp-${GMP_VERSION}.tar.xz
            DESTINATION ${GMP_DOWNLOAD_DIR}
        )
        # Rename extracted directory (gmp-6.3.0 -> gmp)
        file(RENAME ${GMP_DOWNLOAD_DIR}/gmp-${GMP_VERSION} ${GMP_SOURCE_DIR})

        message(STATUS "GMP source cached: ${GMP_SOURCE_DIR}")
    endif()

    # --- Configure ---
    message(STATUS "Configuring GMP ...")
    execute_process(
        COMMAND ${GMP_SOURCE_DIR}/configure
                --prefix=${GMP_INSTALL_DIR}
                --enable-cxx
                --disable-shared
                --enable-static
                --with-pic
        WORKING_DIRECTORY ${GMP_SOURCE_DIR}
        RESULT_VARIABLE GMP_CONFIGURE_RESULT
    )
    if(NOT GMP_CONFIGURE_RESULT EQUAL 0)
        message(FATAL_ERROR "GMP configure failed")
    endif()

    # --- Build ---
    message(STATUS "Building GMP (this may take a while) ...")
    execute_process(
        COMMAND make -j4
        WORKING_DIRECTORY ${GMP_SOURCE_DIR}
        RESULT_VARIABLE GMP_BUILD_RESULT
    )
    if(NOT GMP_BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "GMP build failed")
    endif()

    # --- Install ---
    message(STATUS "Installing GMP to ${GMP_INSTALL_DIR} ...")
    execute_process(
        COMMAND make install
        WORKING_DIRECTORY ${GMP_SOURCE_DIR}
        RESULT_VARIABLE GMP_INSTALL_RESULT
    )
    if(NOT GMP_INSTALL_RESULT EQUAL 0)
        message(FATAL_ERROR "GMP install failed")
    endif()

    message(STATUS "GMP ${GMP_VERSION} built and installed successfully")
endif()

# =============================================================================
# GMP Library Configuration
# =============================================================================
# Create imported targets
add_library(gmp_lib STATIC IMPORTED)
set_target_properties(gmp_lib PROPERTIES
    IMPORTED_LOCATION ${GMP_INSTALL_DIR}/lib/libgmp.a
)

add_library(gmpxx_lib STATIC IMPORTED)
set_target_properties(gmpxx_lib PROPERTIES
    IMPORTED_LOCATION ${GMP_INSTALL_DIR}/lib/libgmpxx.a
)

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${GMP_INSTALL_DIR}/include
)

# Link GMP to the project (gmpxx must come before gmp)
target_link_libraries(${PROJECT_NAME} PRIVATE gmpxx_lib gmp_lib)

message(STATUS "GMP linked to ${PROJECT_NAME}")
message(STATUS "===============================================================")
