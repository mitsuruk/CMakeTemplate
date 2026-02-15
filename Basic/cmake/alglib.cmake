# =============================================================================
# ALGLIB CMake configuration
#
# This file configures ALGLIB library for the project.
# ALGLIB is a cross-platform numerical analysis and data processing library
# providing routines for linear algebra, interpolation, optimization, FFT,
# statistics, and more.
#
# Download directory: ${CMAKE_CURRENT_SOURCE_DIR}/download/alglib
# Install directory:  ${CMAKE_CURRENT_SOURCE_DIR}/download/alglib-install
#
# - If alglib-install/lib/libalglib.a already exists, skip download and build.
# - If download/alglib/src/ap.h already exists, skip download (reuse cache).
# - Otherwise, download from alglib.net, extract, compile, and install.
#
# Note: ALGLIB does not ship with a build system (no Makefile, no CMakeLists.txt).
#       Source files are compiled directly and archived into a static library.
#
# License: MIT License (this cmake file)
# Note: ALGLIB Free Edition is licensed under GNU GPL v2+.
# =============================================================================

include_guard(GLOBAL)

message(STATUS "===============================================================")
message(STATUS "ALGLIB configuration:")

# Path to download/install directories
set(ALGLIB_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/alglib)
set(ALGLIB_SOURCE_DIR ${ALGLIB_DOWNLOAD_DIR}/alglib)
set(ALGLIB_INSTALL_DIR ${ALGLIB_DOWNLOAD_DIR}/alglib-install)
set(ALGLIB_VERSION "4.07.0")
set(ALGLIB_URL "https://www.alglib.net/translator/re/alglib-${ALGLIB_VERSION}.cpp.gpl.zip")

# Source files are in alglib/src/ (zip extracts as alglib-cpp/src/)
set(ALGLIB_SRC_DIR ${ALGLIB_SOURCE_DIR}/src)

message(STATUS "ALGLIB_SOURCE_DIR  = ${ALGLIB_SOURCE_DIR}")
message(STATUS "ALGLIB_INSTALL_DIR = ${ALGLIB_INSTALL_DIR}")

# =============================================================================
# ALGLIB Library: Download, Build, and Install (cached in download/ directory)
# =============================================================================
if(EXISTS ${ALGLIB_INSTALL_DIR}/lib/libalglib.a)
    message(STATUS "ALGLIB already built: ${ALGLIB_INSTALL_DIR}/lib/libalglib.a")
else()
    # --- Download (skip if source already cached) ---
    if(EXISTS ${ALGLIB_SRC_DIR}/ap.h)
        message(STATUS "ALGLIB source already cached: ${ALGLIB_SOURCE_DIR}")
    else()
        set(ALGLIB_ARCHIVE ${ALGLIB_DOWNLOAD_DIR}/alglib-${ALGLIB_VERSION}.cpp.gpl.zip)

        if(NOT EXISTS ${ALGLIB_ARCHIVE})
            message(STATUS "Downloading ALGLIB ${ALGLIB_VERSION} from ${ALGLIB_URL} ...")
            file(DOWNLOAD
                ${ALGLIB_URL}
                ${ALGLIB_ARCHIVE}
                SHOW_PROGRESS
                TIMEOUT 300
                INACTIVITY_TIMEOUT 60
                STATUS DOWNLOAD_STATUS
            )
            list(GET DOWNLOAD_STATUS 0 DOWNLOAD_RESULT)
            if(NOT DOWNLOAD_RESULT EQUAL 0)
                list(GET DOWNLOAD_STATUS 1 DOWNLOAD_ERROR)
                file(REMOVE ${ALGLIB_ARCHIVE})
                message(FATAL_ERROR
                    "ALGLIB download failed: ${DOWNLOAD_ERROR}\n"
                    "You can manually download and place the file:\n"
                    "  curl -L -o download/alglib-${ALGLIB_VERSION}.cpp.gpl.zip ${ALGLIB_URL}\n"
                    "Then re-run cmake."
                )
            endif()
        else()
            message(STATUS "ALGLIB archive already cached: ${ALGLIB_ARCHIVE}")
        endif()

        message(STATUS "Extracting ALGLIB ${ALGLIB_VERSION} ...")

        # Clean up any previous partial extraction
        if(IS_DIRECTORY ${ALGLIB_DOWNLOAD_DIR}/alglib-tmp)
            file(REMOVE_RECURSE ${ALGLIB_DOWNLOAD_DIR}/alglib-tmp)
        endif()
        if(IS_DIRECTORY ${ALGLIB_SOURCE_DIR})
            file(REMOVE_RECURSE ${ALGLIB_SOURCE_DIR})
        endif()

        file(ARCHIVE_EXTRACT
            INPUT ${ALGLIB_ARCHIVE}
            DESTINATION ${ALGLIB_DOWNLOAD_DIR}/alglib-tmp
        )

        # The zip extracts to alglib-cpp/ — rename to alglib/
        file(GLOB ALGLIB_EXTRACTED_DIRS "${ALGLIB_DOWNLOAD_DIR}/alglib-tmp/*")
        list(LENGTH ALGLIB_EXTRACTED_DIRS ALGLIB_EXTRACTED_COUNT)
        if(ALGLIB_EXTRACTED_COUNT EQUAL 1)
            file(RENAME ${ALGLIB_EXTRACTED_DIRS} ${ALGLIB_SOURCE_DIR})
        else()
            file(RENAME ${ALGLIB_DOWNLOAD_DIR}/alglib-tmp ${ALGLIB_SOURCE_DIR})
        endif()

        # Clean up tmp dir if it still exists
        if(IS_DIRECTORY ${ALGLIB_DOWNLOAD_DIR}/alglib-tmp)
            file(REMOVE_RECURSE ${ALGLIB_DOWNLOAD_DIR}/alglib-tmp)
        endif()

        # Verify extraction
        if(NOT EXISTS ${ALGLIB_SRC_DIR}/ap.h)
            message(FATAL_ERROR
                "ALGLIB extraction failed: ${ALGLIB_SRC_DIR}/ap.h not found.\n"
                "Expected directory structure: alglib/src/*.h and alglib/src/*.cpp"
            )
        endif()

        message(STATUS "ALGLIB source cached: ${ALGLIB_SOURCE_DIR}")
    endif()

    # --- Compile all .cpp files into a static library ---
    message(STATUS "Building ALGLIB (compiling source files) ...")

    # Create install directories
    file(MAKE_DIRECTORY ${ALGLIB_INSTALL_DIR}/lib)
    file(MAKE_DIRECTORY ${ALGLIB_INSTALL_DIR}/include)

    # Detect compiler
    if(CMAKE_CXX_COMPILER)
        set(ALGLIB_CXX ${CMAKE_CXX_COMPILER})
    else()
        set(ALGLIB_CXX "c++")
    endif()

    # Compile all .cpp source files to .o
    # Exclude kernel files (kernels_avx2, kernels_fma, kernels_sse2) as they
    # require specific CPU instruction set flags and are only used in the
    # commercial ALGLIB edition with native HPC support.
    file(GLOB ALGLIB_SOURCES "${ALGLIB_SRC_DIR}/*.cpp")
    set(ALGLIB_OBJECTS "")
    foreach(SRC_FILE ${ALGLIB_SOURCES})
        get_filename_component(SRC_NAME ${SRC_FILE} NAME_WE)

        # Skip SIMD kernel files
        if(SRC_NAME MATCHES "^kernels_")
            message(STATUS "  Skipping ${SRC_NAME}.cpp (SIMD kernel, not needed)")
            continue()
        endif()

        set(OBJ_FILE "${ALGLIB_SRC_DIR}/${SRC_NAME}.o")
        list(APPEND ALGLIB_OBJECTS ${OBJ_FILE})

        message(STATUS "  Compiling ${SRC_NAME}.cpp ...")
        execute_process(
            COMMAND ${ALGLIB_CXX} -O2 -fPIC -std=c++17
                    -I${ALGLIB_SRC_DIR}
                    -c ${SRC_FILE}
                    -o ${OBJ_FILE}
            WORKING_DIRECTORY ${ALGLIB_SRC_DIR}
            RESULT_VARIABLE COMPILE_RESULT
            ERROR_VARIABLE COMPILE_ERROR
        )
        if(NOT COMPILE_RESULT EQUAL 0)
            message(FATAL_ERROR "ALGLIB: failed to compile ${SRC_NAME}.cpp\n${COMPILE_ERROR}")
        endif()
    endforeach()

    # Archive into static library
    message(STATUS "Creating libalglib.a ...")

    # Use CMAKE_AR if available, otherwise fallback to "ar"
    if(CMAKE_AR)
        set(ALGLIB_AR ${CMAKE_AR})
    else()
        find_program(ALGLIB_AR ar)
    endif()

    list(LENGTH ALGLIB_OBJECTS ALGLIB_OBJ_COUNT)
    message(STATUS "  Using ar: ${ALGLIB_AR}")
    message(STATUS "  Object file count: ${ALGLIB_OBJ_COUNT}")

    if(ALGLIB_OBJ_COUNT EQUAL 0)
        message(FATAL_ERROR "ALGLIB: no object files to archive")
    endif()

    set(ALGLIB_LIB_PATH ${ALGLIB_INSTALL_DIR}/lib/libalglib.a)

    # Remove stale library if exists
    file(REMOVE ${ALGLIB_LIB_PATH})

    # Add objects one by one to avoid command-line length limits
    foreach(OBJ ${ALGLIB_OBJECTS})
        execute_process(
            COMMAND ${ALGLIB_AR} rcs ${ALGLIB_LIB_PATH} ${OBJ}
            RESULT_VARIABLE AR_RESULT
            ERROR_VARIABLE AR_ERROR
        )
        if(NOT AR_RESULT EQUAL 0)
            message(FATAL_ERROR "ALGLIB: ar failed for ${OBJ}: ${AR_ERROR}")
        endif()
    endforeach()

    if(NOT EXISTS ${ALGLIB_LIB_PATH})
        message(FATAL_ERROR "ALGLIB: failed to create static library")
    endif()
    message(STATUS "Created ${ALGLIB_LIB_PATH}")

    # Copy header files to install directory
    file(GLOB ALGLIB_HEADERS "${ALGLIB_SRC_DIR}/*.h")
    foreach(HDR ${ALGLIB_HEADERS})
        file(COPY ${HDR} DESTINATION ${ALGLIB_INSTALL_DIR}/include)
    endforeach()

    message(STATUS "ALGLIB ${ALGLIB_VERSION} built and installed successfully")
endif()

# =============================================================================
# ALGLIB Library Configuration
# =============================================================================
# Create imported target
add_library(alglib_lib STATIC IMPORTED)
set_target_properties(alglib_lib PROPERTIES
    IMPORTED_LOCATION ${ALGLIB_INSTALL_DIR}/lib/libalglib.a
)

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${ALGLIB_INSTALL_DIR}/include
)

# Link ALGLIB to the project
target_link_libraries(${PROJECT_NAME} PRIVATE alglib_lib)

message(STATUS "ALGLIB linked to ${PROJECT_NAME}")
message(STATUS "===============================================================")
