# =============================================================================
# glog (Google Logging Library) CMake configuration
#
# This file configures glog library for the project.
# glog is a C++ logging library that provides logging APIs based on
# C++-style streams and various helper macros.
#
# Download directory: ${CMAKE_CURRENT_SOURCE_DIR}/download/glog
# Install directory:  ${CMAKE_CURRENT_SOURCE_DIR}/download/glog-install
#
# - If glog-install/lib/libglog.a already exists, skip download and build.
# - If download/glog/CMakeLists.txt already exists, skip download (reuse cache).
# - Otherwise, download from GitHub, configure with CMake, build, and install.
#
# License: MIT License (this cmake file)
# Note: glog library itself is licensed under the BSD 3-Clause License.
# =============================================================================

include_guard(GLOBAL)

message(STATUS "===============================================================")
message(STATUS "glog configuration:")

# Path to download/install directories
set(GLOG_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(GLOG_SOURCE_DIR ${GLOG_DOWNLOAD_DIR}/glog)
set(GLOG_INSTALL_DIR ${GLOG_DOWNLOAD_DIR}/glog-install)
set(GLOG_BUILD_DIR ${GLOG_SOURCE_DIR}/_build)
set(GLOG_VERSION "0.7.1")
set(GLOG_URL "https://github.com/google/glog/archive/refs/tags/v${GLOG_VERSION}.tar.gz")

message(STATUS "GLOG_SOURCE_DIR  = ${GLOG_SOURCE_DIR}")
message(STATUS "GLOG_INSTALL_DIR = ${GLOG_INSTALL_DIR}")

# =============================================================================
# glog Library: Download, Build, and Install (cached in download/ directory)
# =============================================================================
if(EXISTS ${GLOG_INSTALL_DIR}/lib/libglog.a)
    message(STATUS "glog already built: ${GLOG_INSTALL_DIR}/lib/libglog.a")
else()
    # --- Download (skip if source already cached) ---
    if(EXISTS ${GLOG_SOURCE_DIR}/CMakeLists.txt)
        message(STATUS "glog source already cached: ${GLOG_SOURCE_DIR}")
    else()
        set(GLOG_ARCHIVE ${GLOG_DOWNLOAD_DIR}/glog-${GLOG_VERSION}.tar.gz)
        set(GLOG_URLS
            "https://github.com/google/glog/archive/refs/tags/v${GLOG_VERSION}.tar.gz"
        )

        set(GLOG_DOWNLOADED FALSE)
        foreach(URL ${GLOG_URLS})
            message(STATUS "Downloading glog ${GLOG_VERSION} from ${URL} ...")
            file(DOWNLOAD
                ${URL}
                ${GLOG_ARCHIVE}
                SHOW_PROGRESS
                TIMEOUT 300
                INACTIVITY_TIMEOUT 60
                STATUS DOWNLOAD_STATUS
            )
            list(GET DOWNLOAD_STATUS 0 DOWNLOAD_RESULT)
            if(DOWNLOAD_RESULT EQUAL 0)
                set(GLOG_DOWNLOADED TRUE)
                break()
            else()
                list(GET DOWNLOAD_STATUS 1 DOWNLOAD_ERROR)
                message(WARNING "Download from ${URL} failed: ${DOWNLOAD_ERROR}")
                file(REMOVE ${GLOG_ARCHIVE})
            endif()
        endforeach()

        if(NOT GLOG_DOWNLOADED)
            message(FATAL_ERROR
                "glog download failed.\n"
                "You can manually download and place the file:\n"
                "  curl -L -o download/glog-${GLOG_VERSION}.tar.gz ${GLOG_URL}\n"
                "Then re-run cmake."
            )
        endif()

        message(STATUS "Extracting glog ${GLOG_VERSION} ...")
        file(ARCHIVE_EXTRACT
            INPUT ${GLOG_ARCHIVE}
            DESTINATION ${GLOG_DOWNLOAD_DIR}
        )
        # Rename extracted directory (glog-0.7.1 -> glog)
        file(RENAME ${GLOG_DOWNLOAD_DIR}/glog-${GLOG_VERSION} ${GLOG_SOURCE_DIR})

        message(STATUS "glog source cached: ${GLOG_SOURCE_DIR}")
    endif()

    # --- Configure (CMake) ---
    message(STATUS "Configuring glog with CMake ...")
    file(MAKE_DIRECTORY ${GLOG_BUILD_DIR})
    execute_process(
        COMMAND ${CMAKE_COMMAND}
                -DCMAKE_INSTALL_PREFIX=${GLOG_INSTALL_DIR}
                -DBUILD_SHARED_LIBS=OFF
                -DWITH_GFLAGS=OFF
                -DWITH_GTEST=OFF
                -DWITH_UNWIND=OFF
                -DBUILD_TESTING=OFF
                -DCMAKE_BUILD_TYPE=Release
                -DCMAKE_POSITION_INDEPENDENT_CODE=ON
                ${GLOG_SOURCE_DIR}
        WORKING_DIRECTORY ${GLOG_BUILD_DIR}
        RESULT_VARIABLE GLOG_CONFIGURE_RESULT
    )
    if(NOT GLOG_CONFIGURE_RESULT EQUAL 0)
        message(FATAL_ERROR "glog CMake configure failed")
    endif()

    # --- Build ---
    message(STATUS "Building glog (this may take a while) ...")
    execute_process(
        COMMAND ${CMAKE_COMMAND} --build . --config Release -j4
        WORKING_DIRECTORY ${GLOG_BUILD_DIR}
        RESULT_VARIABLE GLOG_BUILD_RESULT
    )
    if(NOT GLOG_BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "glog build failed")
    endif()

    # --- Install ---
    message(STATUS "Installing glog to ${GLOG_INSTALL_DIR} ...")
    execute_process(
        COMMAND ${CMAKE_COMMAND} --install . --config Release
        WORKING_DIRECTORY ${GLOG_BUILD_DIR}
        RESULT_VARIABLE GLOG_INSTALL_RESULT
    )
    if(NOT GLOG_INSTALL_RESULT EQUAL 0)
        message(FATAL_ERROR "glog install failed")
    endif()

    message(STATUS "glog ${GLOG_VERSION} built and installed successfully")
endif()

# =============================================================================
# glog Library Configuration
# =============================================================================
# glog 0.7.x requires GLOG_USE_GLOG_EXPORT to be defined so that export.h
# is included and GLOG_EXPORT macro is properly set.
# It also requires linking with Threads (pthread).

find_package(Threads REQUIRED)

# Use find_package with the installed glog CMake config
set(glog_DIR ${GLOG_INSTALL_DIR}/lib/cmake/glog)
find_package(glog REQUIRED CONFIG)

# Link glog to the project (glog::glog carries include dirs and compile defs)
target_link_libraries(${PROJECT_NAME} PRIVATE glog::glog)

message(STATUS "glog linked to ${PROJECT_NAME}")
message(STATUS "===============================================================")
