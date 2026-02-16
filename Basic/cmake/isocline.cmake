# =============================================================================
# isocline CMake configuration
#
# This file configures the isocline library for the project.
# isocline is a portable GNU readline alternative for interactive console
# input, written in pure C with no external dependencies.
# Features: multi-line editing, syntax highlighting, tab completion,
# Unicode support, 24-bit color, persistent history, and more.
#
# Download directory: ${CMAKE_CURRENT_SOURCE_DIR}/download/isocline
# Install directory:  ${CMAKE_CURRENT_SOURCE_DIR}/download/isocline-install
#
# - If isocline-install/lib/libisocline.a already exists, skip download and build.
# - If download/isocline/CMakeLists.txt already exists, skip download (reuse cache).
# - Otherwise, download from GitHub, configure, build, and install.
#
# License: MIT License (this cmake file)
# Note: isocline library itself is licensed under MIT License.
# =============================================================================

include_guard(GLOBAL)

message(STATUS "===============================================================")
message(STATUS "isocline configuration:")

# Path to download/install directories
set(ISOCLINE_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/isocline)
set(ISOCLINE_SOURCE_DIR ${ISOCLINE_DOWNLOAD_DIR}/isocline)
set(ISOCLINE_INSTALL_DIR ${ISOCLINE_DOWNLOAD_DIR}/isocline/isocline-install)
set(ISOCLINE_VERSION "1.0.9")
set(ISOCLINE_URL "https://github.com/daanx/isocline/archive/refs/tags/v${ISOCLINE_VERSION}.tar.gz")

message(STATUS "ISOCLINE_SOURCE_DIR  = ${ISOCLINE_SOURCE_DIR}")
message(STATUS "ISOCLINE_INSTALL_DIR = ${ISOCLINE_INSTALL_DIR}")

# =============================================================================
# isocline Library: Download, Build, and Install (cached in download/ directory)
# =============================================================================
if(EXISTS ${ISOCLINE_INSTALL_DIR}/lib/libisocline.a)
    message(STATUS "isocline already built: ${ISOCLINE_INSTALL_DIR}/lib/libisocline.a")
else()
    # --- Download (skip if source already cached) ---
    if(EXISTS ${ISOCLINE_SOURCE_DIR}/CMakeLists.txt)
        message(STATUS "isocline source already cached: ${ISOCLINE_SOURCE_DIR}")
    else()
        set(ISOCLINE_ARCHIVE ${ISOCLINE_DOWNLOAD_DIR}/isocline-${ISOCLINE_VERSION}.tar.gz)
        set(ISOCLINE_URLS
            "https://github.com/daanx/isocline/archive/refs/tags/v${ISOCLINE_VERSION}.tar.gz"
        )

        set(ISOCLINE_DOWNLOADED FALSE)
        foreach(URL ${ISOCLINE_URLS})
            message(STATUS "Downloading isocline ${ISOCLINE_VERSION} from ${URL} ...")
            file(DOWNLOAD
                ${URL}
                ${ISOCLINE_ARCHIVE}
                SHOW_PROGRESS
                TIMEOUT 300
                INACTIVITY_TIMEOUT 60
                STATUS DOWNLOAD_STATUS
            )
            list(GET DOWNLOAD_STATUS 0 DOWNLOAD_RESULT)
            if(DOWNLOAD_RESULT EQUAL 0)
                set(ISOCLINE_DOWNLOADED TRUE)
                break()
            else()
                list(GET DOWNLOAD_STATUS 1 DOWNLOAD_ERROR)
                message(WARNING "Download from ${URL} failed: ${DOWNLOAD_ERROR}")
                file(REMOVE ${ISOCLINE_ARCHIVE})
            endif()
        endforeach()

        if(NOT ISOCLINE_DOWNLOADED)
            message(FATAL_ERROR
                "isocline download failed.\n"
                "You can manually download and place the file:\n"
                "  curl -L -o download/isocline/isocline-${ISOCLINE_VERSION}.tar.gz ${ISOCLINE_URL}\n"
                "Then re-run cmake."
            )
        endif()

        message(STATUS "Extracting isocline ${ISOCLINE_VERSION} ...")
        file(ARCHIVE_EXTRACT
            INPUT ${ISOCLINE_ARCHIVE}
            DESTINATION ${ISOCLINE_DOWNLOAD_DIR}
        )
        # Rename extracted directory (isocline-1.0.9 -> isocline)
        file(RENAME ${ISOCLINE_DOWNLOAD_DIR}/isocline-${ISOCLINE_VERSION} ${ISOCLINE_SOURCE_DIR})

        message(STATUS "isocline source cached: ${ISOCLINE_SOURCE_DIR}")
    endif()

    # --- Configure (CMake-based build) ---
    set(ISOCLINE_BUILD_DIR ${ISOCLINE_SOURCE_DIR}/build)
    file(MAKE_DIRECTORY ${ISOCLINE_BUILD_DIR})

    message(STATUS "Configuring isocline ...")
    execute_process(
        COMMAND ${CMAKE_COMMAND}
                -DCMAKE_INSTALL_PREFIX=${ISOCLINE_INSTALL_DIR}
                -DCMAKE_BUILD_TYPE=Release
                -DCMAKE_POSITION_INDEPENDENT_CODE=ON
                ${ISOCLINE_SOURCE_DIR}
        WORKING_DIRECTORY ${ISOCLINE_BUILD_DIR}
        RESULT_VARIABLE ISOCLINE_CONFIGURE_RESULT
    )
    if(NOT ISOCLINE_CONFIGURE_RESULT EQUAL 0)
        message(FATAL_ERROR "isocline configure failed")
    endif()

    # --- Build ---
    message(STATUS "Building isocline ...")
    execute_process(
        COMMAND ${CMAKE_COMMAND} --build . --target isocline -j4
        WORKING_DIRECTORY ${ISOCLINE_BUILD_DIR}
        RESULT_VARIABLE ISOCLINE_BUILD_RESULT
    )
    if(NOT ISOCLINE_BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "isocline build failed")
    endif()

    # --- Install (manual, since isocline CMakeLists.txt has no install rules) ---
    message(STATUS "Installing isocline to ${ISOCLINE_INSTALL_DIR} ...")
    file(MAKE_DIRECTORY ${ISOCLINE_INSTALL_DIR}/lib)
    file(MAKE_DIRECTORY ${ISOCLINE_INSTALL_DIR}/include)

    # Copy the static library
    file(GLOB ISOCLINE_LIB_FILES
        "${ISOCLINE_BUILD_DIR}/libisocline.a"
        "${ISOCLINE_BUILD_DIR}/Release/libisocline.a"
        "${ISOCLINE_BUILD_DIR}/Debug/libisocline.a"
    )
    if(ISOCLINE_LIB_FILES)
        list(GET ISOCLINE_LIB_FILES 0 ISOCLINE_LIB_FILE)
        file(COPY ${ISOCLINE_LIB_FILE} DESTINATION ${ISOCLINE_INSTALL_DIR}/lib)
    else()
        message(FATAL_ERROR "isocline build produced no libisocline.a")
    endif()

    # Copy the header file
    file(COPY ${ISOCLINE_SOURCE_DIR}/include/isocline.h
         DESTINATION ${ISOCLINE_INSTALL_DIR}/include)

    message(STATUS "isocline ${ISOCLINE_VERSION} built and installed successfully")
endif()

# =============================================================================
# isocline Library Configuration
# =============================================================================
# Create imported target
add_library(isocline_lib STATIC IMPORTED)
set_target_properties(isocline_lib PROPERTIES
    IMPORTED_LOCATION ${ISOCLINE_INSTALL_DIR}/lib/libisocline.a
)

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${ISOCLINE_INSTALL_DIR}/include
)

# Link isocline to the project
target_link_libraries(${PROJECT_NAME} PRIVATE isocline_lib)

message(STATUS "isocline linked to ${PROJECT_NAME}")
message(STATUS "===============================================================")
