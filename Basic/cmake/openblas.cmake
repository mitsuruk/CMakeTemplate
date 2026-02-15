# =============================================================================
# OpenBLAS CMake configuration
#
# This file configures OpenBLAS library for the project.
# OpenBLAS is an optimized BLAS (Basic Linear Algebra Subprograms) library
# based on GotoBLAS2, providing high-performance implementations of
# BLAS Level 1/2/3 and LAPACK routines.
#
# Download directory: ${CMAKE_CURRENT_SOURCE_DIR}/download/openblas
# Install directory:  ${CMAKE_CURRENT_SOURCE_DIR}/download/openblas-install
#
# - If openblas-install/lib/libopenblas.a already exists, skip download and build.
# - If download/openblas/Makefile already exists, skip download (reuse cache).
# - Otherwise, download from GitHub, build, and install.
#
# License: MIT License (this cmake file)
# Note: OpenBLAS library itself is licensed under BSD 3-Clause.
# =============================================================================

include_guard(GLOBAL)

message(STATUS "===============================================================")
message(STATUS "OpenBLAS configuration:")

# Path to download/install directories
set(OPENBLAS_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/openblas)
set(OPENBLAS_SOURCE_DIR ${OPENBLAS_DOWNLOAD_DIR}/openblas)
set(OPENBLAS_INSTALL_DIR ${OPENBLAS_DOWNLOAD_DIR}/openblas-install)
set(OPENBLAS_VERSION "0.3.28")
set(OPENBLAS_URL "https://github.com/OpenMathLib/OpenBLAS/releases/download/v${OPENBLAS_VERSION}/OpenBLAS-${OPENBLAS_VERSION}.tar.gz")

message(STATUS "OPENBLAS_SOURCE_DIR  = ${OPENBLAS_SOURCE_DIR}")
message(STATUS "OPENBLAS_INSTALL_DIR = ${OPENBLAS_INSTALL_DIR}")

# =============================================================================
# OpenBLAS Library: Download, Build, and Install (cached in download/ directory)
# =============================================================================
if(EXISTS ${OPENBLAS_INSTALL_DIR}/lib/libopenblas.a)
    message(STATUS "OpenBLAS already built: ${OPENBLAS_INSTALL_DIR}/lib/libopenblas.a")
else()
    # --- Download (skip if source already cached) ---
    if(EXISTS ${OPENBLAS_SOURCE_DIR}/Makefile)
        message(STATUS "OpenBLAS source already cached: ${OPENBLAS_SOURCE_DIR}")
    else()
        set(OPENBLAS_ARCHIVE ${OPENBLAS_DOWNLOAD_DIR}/OpenBLAS-${OPENBLAS_VERSION}.tar.gz)
        set(OPENBLAS_URLS
            "https://github.com/OpenMathLib/OpenBLAS/releases/download/v${OPENBLAS_VERSION}/OpenBLAS-${OPENBLAS_VERSION}.tar.gz"
            "https://github.com/xianyi/OpenBLAS/releases/download/v${OPENBLAS_VERSION}/OpenBLAS-${OPENBLAS_VERSION}.tar.gz"
        )

        set(OPENBLAS_DOWNLOADED FALSE)
        foreach(URL ${OPENBLAS_URLS})
            message(STATUS "Downloading OpenBLAS ${OPENBLAS_VERSION} from ${URL} ...")
            file(DOWNLOAD
                ${URL}
                ${OPENBLAS_ARCHIVE}
                SHOW_PROGRESS
                TIMEOUT 300
                INACTIVITY_TIMEOUT 60
                STATUS DOWNLOAD_STATUS
            )
            list(GET DOWNLOAD_STATUS 0 DOWNLOAD_RESULT)
            if(DOWNLOAD_RESULT EQUAL 0)
                set(OPENBLAS_DOWNLOADED TRUE)
                break()
            else()
                list(GET DOWNLOAD_STATUS 1 DOWNLOAD_ERROR)
                message(WARNING "Download from ${URL} failed: ${DOWNLOAD_ERROR}")
                file(REMOVE ${OPENBLAS_ARCHIVE})
            endif()
        endforeach()

        if(NOT OPENBLAS_DOWNLOADED)
            message(FATAL_ERROR
                "OpenBLAS download failed from all mirrors.\n"
                "You can manually download and place the file:\n"
                "  curl -L -o download/openblas/OpenBLAS-${OPENBLAS_VERSION}.tar.gz ${OPENBLAS_URL}\n"
                "Then re-run cmake."
            )
        endif()

        message(STATUS "Extracting OpenBLAS ${OPENBLAS_VERSION} ...")
        file(ARCHIVE_EXTRACT
            INPUT ${OPENBLAS_DOWNLOAD_DIR}/OpenBLAS-${OPENBLAS_VERSION}.tar.gz
            DESTINATION ${OPENBLAS_DOWNLOAD_DIR}
        )
        # Rename extracted directory (OpenBLAS-0.3.28 -> openblas)
        file(RENAME ${OPENBLAS_DOWNLOAD_DIR}/OpenBLAS-${OPENBLAS_VERSION} ${OPENBLAS_SOURCE_DIR})

        message(STATUS "OpenBLAS source cached: ${OPENBLAS_SOURCE_DIR}")
    endif()

    # --- Build ---
    # OpenBLAS uses make directly (no configure step needed).
    # Target "libs": Build libraries only (skip tests that cause LTO linker errors on macOS)
    # NO_LAPACK=1: Exclude LAPACK routines (BLAS only)
    # USE_OPENMP=0: Disable OpenMP (use pthreads instead)
    # NO_FORTRAN=1: Do not require a Fortran compiler
    # DYNAMIC_ARCH=0: Build for the host architecture only
    # NO_SHARED=1: Do not build shared libraries
    message(STATUS "Building OpenBLAS (this may take a while) ...")
    execute_process(
        COMMAND make libs netlib -j4
                NO_FORTRAN=1
                NO_LAPACK=1
                USE_OPENMP=0
                DYNAMIC_ARCH=0
                NO_SHARED=1
                PREFIX=${OPENBLAS_INSTALL_DIR}
        WORKING_DIRECTORY ${OPENBLAS_SOURCE_DIR}
        RESULT_VARIABLE OPENBLAS_BUILD_RESULT
    )
    if(NOT OPENBLAS_BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "OpenBLAS build failed")
    endif()

    # --- Install ---
    message(STATUS "Installing OpenBLAS to ${OPENBLAS_INSTALL_DIR} ...")
    execute_process(
        COMMAND make install
                NO_FORTRAN=1
                NO_LAPACK=1
                USE_OPENMP=0
                DYNAMIC_ARCH=0
                NO_SHARED=1
                PREFIX=${OPENBLAS_INSTALL_DIR}
        WORKING_DIRECTORY ${OPENBLAS_SOURCE_DIR}
        RESULT_VARIABLE OPENBLAS_INSTALL_RESULT
    )
    if(NOT OPENBLAS_INSTALL_RESULT EQUAL 0)
        message(FATAL_ERROR "OpenBLAS install failed")
    endif()

    message(STATUS "OpenBLAS ${OPENBLAS_VERSION} built and installed successfully")
endif()

# =============================================================================
# OpenBLAS Library Configuration
# =============================================================================
# Create imported target
add_library(openblas_lib STATIC IMPORTED)
set_target_properties(openblas_lib PROPERTIES
    IMPORTED_LOCATION ${OPENBLAS_INSTALL_DIR}/lib/libopenblas.a
)

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${OPENBLAS_INSTALL_DIR}/include
)

# Link OpenBLAS to the project
# -lpthread is required for OpenBLAS threading support
target_link_libraries(${PROJECT_NAME} PRIVATE openblas_lib m pthread)

message(STATUS "OpenBLAS linked to ${PROJECT_NAME}")
message(STATUS "===============================================================")
