# =============================================================================
# GSL (GNU Scientific Library) CMake configuration
#
# This file configures GSL library for the project.
# GSL is a free numerical library for C and C++ programmers, providing
# routines for mathematical functions, linear algebra, statistics, FFT,
# random numbers, and more.
#
# Download directory: ${CMAKE_CURRENT_SOURCE_DIR}/download/gsl
# Install directory:  ${CMAKE_CURRENT_SOURCE_DIR}/download/gsl-install
#
# - If gsl-install/lib/libgsl.a already exists, skip download and build.
# - If download/gsl/configure already exists, skip download (reuse cache).
# - Otherwise, download from ftp.gnu.org, configure, build, and install.
#
# License: MIT License (this cmake file)
# Note: GSL library itself is licensed under GNU GPL v3.
# =============================================================================

include_guard(GLOBAL)

message(STATUS "===============================================================")
message(STATUS "GSL configuration:")

# Path to download/install directories
set(GSL_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/gsl)
set(GSL_SOURCE_DIR ${GSL_DOWNLOAD_DIR}/gsl)
set(GSL_INSTALL_DIR ${GSL_DOWNLOAD_DIR}/gsl-install)
set(GSL_VERSION "2.8")
set(GSL_URL "https://ftp.gnu.org/gnu/gsl/gsl-${GSL_VERSION}.tar.gz")

message(STATUS "GSL_SOURCE_DIR  = ${GSL_SOURCE_DIR}")
message(STATUS "GSL_INSTALL_DIR = ${GSL_INSTALL_DIR}")

# =============================================================================
# GSL Library: Download, Build, and Install (cached in download/ directory)
# =============================================================================
if(EXISTS ${GSL_INSTALL_DIR}/lib/libgsl.a AND EXISTS ${GSL_INSTALL_DIR}/lib/libgslcblas.a)
    message(STATUS "GSL already built: ${GSL_INSTALL_DIR}/lib/libgsl.a")
else()
    # --- Download (skip if source already cached) ---
    if(EXISTS ${GSL_SOURCE_DIR}/configure)
        message(STATUS "GSL source already cached: ${GSL_SOURCE_DIR}")
    else()
        set(GSL_ARCHIVE ${GSL_DOWNLOAD_DIR}/gsl-${GSL_VERSION}.tar.gz)
        set(GSL_URLS
            "https://ftp.gnu.org/gnu/gsl/gsl-${GSL_VERSION}.tar.gz"
            "https://ftpmirror.gnu.org/gsl/gsl-${GSL_VERSION}.tar.gz"
        )

        set(GSL_DOWNLOADED FALSE)
        foreach(URL ${GSL_URLS})
            message(STATUS "Downloading GSL ${GSL_VERSION} from ${URL} ...")
            file(DOWNLOAD
                ${URL}
                ${GSL_ARCHIVE}
                SHOW_PROGRESS
                TIMEOUT 300
                INACTIVITY_TIMEOUT 60
                STATUS DOWNLOAD_STATUS
            )
            list(GET DOWNLOAD_STATUS 0 DOWNLOAD_RESULT)
            if(DOWNLOAD_RESULT EQUAL 0)
                set(GSL_DOWNLOADED TRUE)
                break()
            else()
                list(GET DOWNLOAD_STATUS 1 DOWNLOAD_ERROR)
                message(WARNING "Download from ${URL} failed: ${DOWNLOAD_ERROR}")
                file(REMOVE ${GSL_ARCHIVE})
            endif()
        endforeach()

        if(NOT GSL_DOWNLOADED)
            message(FATAL_ERROR
                "GSL download failed from all mirrors.\n"
                "You can manually download and place the file:\n"
                "  curl -L -o download/gsl-${GSL_VERSION}.tar.gz ${GSL_URL}\n"
                "Then re-run cmake."
            )
        endif()

        message(STATUS "Extracting GSL ${GSL_VERSION} ...")
        file(ARCHIVE_EXTRACT
            INPUT ${GSL_DOWNLOAD_DIR}/gsl-${GSL_VERSION}.tar.gz
            DESTINATION ${GSL_DOWNLOAD_DIR}
        )
        # Rename extracted directory (gsl-2.8 -> gsl)
        file(RENAME ${GSL_DOWNLOAD_DIR}/gsl-${GSL_VERSION} ${GSL_SOURCE_DIR})

        message(STATUS "GSL source cached: ${GSL_SOURCE_DIR}")
    endif()

    # --- Configure ---
    message(STATUS "Configuring GSL ...")
    execute_process(
        COMMAND ${GSL_SOURCE_DIR}/configure
                --prefix=${GSL_INSTALL_DIR}
                --disable-shared
                --enable-static
                --with-pic
        WORKING_DIRECTORY ${GSL_SOURCE_DIR}
        RESULT_VARIABLE GSL_CONFIGURE_RESULT
    )
    if(NOT GSL_CONFIGURE_RESULT EQUAL 0)
        message(FATAL_ERROR "GSL configure failed")
    endif()

    # --- Build ---
    message(STATUS "Building GSL (this may take a while) ...")
    execute_process(
        COMMAND make -j4
        WORKING_DIRECTORY ${GSL_SOURCE_DIR}
        RESULT_VARIABLE GSL_BUILD_RESULT
    )
    if(NOT GSL_BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "GSL build failed")
    endif()

    # --- Install ---
    message(STATUS "Installing GSL to ${GSL_INSTALL_DIR} ...")
    execute_process(
        COMMAND make install
        WORKING_DIRECTORY ${GSL_SOURCE_DIR}
        RESULT_VARIABLE GSL_INSTALL_RESULT
    )
    if(NOT GSL_INSTALL_RESULT EQUAL 0)
        message(FATAL_ERROR "GSL install failed")
    endif()

    message(STATUS "GSL ${GSL_VERSION} built and installed successfully")
endif()

# =============================================================================
# GSL Library Configuration
# =============================================================================
# Create imported targets
add_library(gsl_lib STATIC IMPORTED)
set_target_properties(gsl_lib PROPERTIES
    IMPORTED_LOCATION ${GSL_INSTALL_DIR}/lib/libgsl.a
)

add_library(gslcblas_lib STATIC IMPORTED)
set_target_properties(gslcblas_lib PROPERTIES
    IMPORTED_LOCATION ${GSL_INSTALL_DIR}/lib/libgslcblas.a
)

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${GSL_INSTALL_DIR}/include
)

# Link GSL to the project (gsl must come before gslcblas)
target_link_libraries(${PROJECT_NAME} PRIVATE gsl_lib gslcblas_lib m)

message(STATUS "GSL linked to ${PROJECT_NAME}")
message(STATUS "===============================================================")
