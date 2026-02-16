# =============================================================================
# mpdecimal (Arbitrary Precision Decimal Floating-Point) CMake configuration
#
# This file configures mpdecimal library for the project.
# mpdecimal is a package for correctly-rounded arbitrary precision decimal
# floating-point arithmetic, implementing the General Decimal Arithmetic
# Specification (IEEE 754-2008).
#
# Download directory: ${CMAKE_CURRENT_SOURCE_DIR}/download/mpdecimal
# Install directory:  ${CMAKE_CURRENT_SOURCE_DIR}/download/mpdecimal/mpdecimal-install
#
# - If mpdecimal-install/lib/libmpdec.a already exists, skip download and build.
# - If download/mpdecimal/configure already exists, skip download (reuse cache).
# - Otherwise, download from bytereef.org, configure, build, and install.
#
# License: MIT License (this cmake file)
# Note: mpdecimal library itself is licensed under the Simplified BSD License.
# =============================================================================

include_guard(GLOBAL)

message(STATUS "===============================================================")
message(STATUS "mpdecimal configuration:")

# Path to download/install directories
set(MPDECIMAL_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/mpdecimal)
set(MPDECIMAL_SOURCE_DIR ${MPDECIMAL_DOWNLOAD_DIR}/mpdecimal)
set(MPDECIMAL_INSTALL_DIR ${MPDECIMAL_DOWNLOAD_DIR}/mpdecimal-install)
set(MPDECIMAL_VERSION "4.0.1")
set(MPDECIMAL_URL "https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-${MPDECIMAL_VERSION}.tar.gz")

message(STATUS "MPDECIMAL_SOURCE_DIR  = ${MPDECIMAL_SOURCE_DIR}")
message(STATUS "MPDECIMAL_INSTALL_DIR = ${MPDECIMAL_INSTALL_DIR}")

# =============================================================================
# mpdecimal Library: Download, Build, and Install (cached in download/ directory)
# =============================================================================
if(EXISTS ${MPDECIMAL_INSTALL_DIR}/lib/libmpdec.a AND EXISTS ${MPDECIMAL_INSTALL_DIR}/lib/libmpdec++.a)
    message(STATUS "mpdecimal already built: ${MPDECIMAL_INSTALL_DIR}/lib/libmpdec.a")
else()
    # --- Download (skip if source already cached) ---
    if(EXISTS ${MPDECIMAL_SOURCE_DIR}/configure)
        message(STATUS "mpdecimal source already cached: ${MPDECIMAL_SOURCE_DIR}")
    else()
        set(MPDECIMAL_ARCHIVE ${MPDECIMAL_DOWNLOAD_DIR}/mpdecimal-${MPDECIMAL_VERSION}.tar.gz)
        set(MPDECIMAL_URLS
            "https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-${MPDECIMAL_VERSION}.tar.gz"
        )

        set(MPDECIMAL_DOWNLOADED FALSE)
        foreach(URL ${MPDECIMAL_URLS})
            message(STATUS "Downloading mpdecimal ${MPDECIMAL_VERSION} from ${URL} ...")
            file(DOWNLOAD
                ${URL}
                ${MPDECIMAL_ARCHIVE}
                SHOW_PROGRESS
                TIMEOUT 300
                INACTIVITY_TIMEOUT 60
                STATUS DOWNLOAD_STATUS
            )
            list(GET DOWNLOAD_STATUS 0 DOWNLOAD_RESULT)
            if(DOWNLOAD_RESULT EQUAL 0)
                set(MPDECIMAL_DOWNLOADED TRUE)
                break()
            else()
                list(GET DOWNLOAD_STATUS 1 DOWNLOAD_ERROR)
                message(WARNING "Download from ${URL} failed: ${DOWNLOAD_ERROR}")
                file(REMOVE ${MPDECIMAL_ARCHIVE})
            endif()
        endforeach()

        if(NOT MPDECIMAL_DOWNLOADED)
            message(FATAL_ERROR
                "mpdecimal download failed.\n"
                "You can manually download and place the file:\n"
                "  curl -L -o download/mpdecimal/mpdecimal-${MPDECIMAL_VERSION}.tar.gz ${MPDECIMAL_URL}\n"
                "Then re-run cmake."
            )
        endif()

        message(STATUS "Extracting mpdecimal ${MPDECIMAL_VERSION} ...")
        file(ARCHIVE_EXTRACT
            INPUT ${MPDECIMAL_DOWNLOAD_DIR}/mpdecimal-${MPDECIMAL_VERSION}.tar.gz
            DESTINATION ${MPDECIMAL_DOWNLOAD_DIR}
        )
        # Rename extracted directory (mpdecimal-4.0.1 -> mpdecimal)
        file(RENAME ${MPDECIMAL_DOWNLOAD_DIR}/mpdecimal-${MPDECIMAL_VERSION} ${MPDECIMAL_SOURCE_DIR})

        message(STATUS "mpdecimal source cached: ${MPDECIMAL_SOURCE_DIR}")
    endif()

    # --- Configure ---
    message(STATUS "Configuring mpdecimal ...")
    execute_process(
        COMMAND ${MPDECIMAL_SOURCE_DIR}/configure
                --prefix=${MPDECIMAL_INSTALL_DIR}
                --disable-shared
                --enable-static
                --enable-pc
        WORKING_DIRECTORY ${MPDECIMAL_SOURCE_DIR}
        RESULT_VARIABLE MPDECIMAL_CONFIGURE_RESULT
    )
    if(NOT MPDECIMAL_CONFIGURE_RESULT EQUAL 0)
        message(FATAL_ERROR "mpdecimal configure failed")
    endif()

    # --- Build ---
    message(STATUS "Building mpdecimal (this may take a while) ...")
    execute_process(
        COMMAND make -j4
        WORKING_DIRECTORY ${MPDECIMAL_SOURCE_DIR}
        RESULT_VARIABLE MPDECIMAL_BUILD_RESULT
    )
    if(NOT MPDECIMAL_BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "mpdecimal build failed")
    endif()

    # --- Install ---
    message(STATUS "Installing mpdecimal to ${MPDECIMAL_INSTALL_DIR} ...")
    execute_process(
        COMMAND make install
        WORKING_DIRECTORY ${MPDECIMAL_SOURCE_DIR}
        RESULT_VARIABLE MPDECIMAL_INSTALL_RESULT
    )
    if(NOT MPDECIMAL_INSTALL_RESULT EQUAL 0)
        message(FATAL_ERROR "mpdecimal install failed")
    endif()

    message(STATUS "mpdecimal ${MPDECIMAL_VERSION} built and installed successfully")
endif()

# =============================================================================
# mpdecimal Library Configuration
# =============================================================================
# Create imported targets
add_library(mpdec_lib STATIC IMPORTED)
set_target_properties(mpdec_lib PROPERTIES
    IMPORTED_LOCATION ${MPDECIMAL_INSTALL_DIR}/lib/libmpdec.a
)

add_library(mpdecpp_lib STATIC IMPORTED)
set_target_properties(mpdecpp_lib PROPERTIES
    IMPORTED_LOCATION ${MPDECIMAL_INSTALL_DIR}/lib/libmpdec++.a
)

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${MPDECIMAL_INSTALL_DIR}/include
)

# Link mpdecimal to the project (mpdec++ must come before mpdec)
target_link_libraries(${PROJECT_NAME} PRIVATE mpdecpp_lib mpdec_lib m)

message(STATUS "mpdecimal linked to ${PROJECT_NAME}")
message(STATUS "===============================================================")
