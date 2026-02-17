# =============================================================================
# Exiv2 CMake configuration (FetchContent + install cache)
#
# This file configures Exiv2 library for the project.
# Exiv2 is a C++ library and command-line utility to read, write, delete,
# and modify Exif, IPTC, XMP, and ICC Profile image metadata.
#
# Download directory: ${CMAKE_CURRENT_SOURCE_DIR}/download/Exiv2
#
# On first build, FetchContent downloads and builds Exiv2 as a sub-project,
# then installs the built library into the install directory.
# On subsequent builds (even after deleting the build/ directory),
# the pre-built library is detected and reused, skipping recompilation.
#
# License: MIT License (this cmake file)
# Note: Exiv2 library itself is licensed under GNU GPL v2+.
# =============================================================================

include_guard(GLOBAL)

message(STATUS "===============================================================")
message(STATUS "Exiv2 configuration (FetchContent):")

# =============================================================================
# Path configuration
# =============================================================================
set(EXIV2_VERSION "0.28.7")
set(EXIV2_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/Exiv2)
set(EXIV2_INSTALL_DIR ${EXIV2_DOWNLOAD_DIR}/exiv2-install)

message(STATUS "EXIV2_DOWNLOAD_DIR = ${EXIV2_DOWNLOAD_DIR}")
message(STATUS "EXIV2_INSTALL_DIR  = ${EXIV2_INSTALL_DIR}")

# =============================================================================
# Check for pre-built Exiv2 library (cached install)
# =============================================================================
# After the first successful FetchContent build, the library is installed to
# EXIV2_INSTALL_DIR. On subsequent cmake configurations (even after deleting
# the build/ directory), this pre-built library is reused without recompilation.
# =============================================================================
set(EXIV2_INSTALLED_INCLUDE_DIR ${EXIV2_INSTALL_DIR}/include)
if(APPLE)
    set(EXIV2_INSTALLED_LIB ${EXIV2_INSTALL_DIR}/lib/libexiv2.dylib)
elseif(WIN32)
    set(EXIV2_INSTALLED_LIB ${EXIV2_INSTALL_DIR}/lib/exiv2.lib)
else()
    set(EXIV2_INSTALLED_LIB ${EXIV2_INSTALL_DIR}/lib/libexiv2.so)
endif()

if(EXISTS ${EXIV2_INSTALLED_LIB} AND EXISTS ${EXIV2_INSTALLED_INCLUDE_DIR}/exiv2/exiv2.hpp)
    # =========================================================================
    # Use pre-built (cached) Exiv2 library
    # =========================================================================
    message(STATUS "Exiv2 ${EXIV2_VERSION}: using cached install at ${EXIV2_INSTALL_DIR}")

    add_library(exiv2lib_cached SHARED IMPORTED)
    set_target_properties(exiv2lib_cached PROPERTIES
        IMPORTED_LOCATION ${EXIV2_INSTALLED_LIB}
    )
    if(APPLE)
        # Set SONAME for macOS dylib
        set_target_properties(exiv2lib_cached PROPERTIES
            IMPORTED_SONAME "@rpath/libexiv2.28.dylib"
        )
    endif()
    target_include_directories(${PROJECT_NAME} PRIVATE ${EXIV2_INSTALLED_INCLUDE_DIR})

    # Link system dependencies that are needed at runtime
    find_package(ZLIB REQUIRED)
    find_package(EXPAT REQUIRED)
    find_package(Iconv REQUIRED)

    target_link_libraries(${PROJECT_NAME} PRIVATE
        exiv2lib_cached
        ZLIB::ZLIB
        EXPAT::EXPAT
        Iconv::Iconv
    )

    if(APPLE)
        target_link_libraries(${PROJECT_NAME} PRIVATE "-framework CoreFoundation")
    endif()

    # Find and link Brotli (optional, but enabled by default in Exiv2)
    find_library(BROTLIDEC_LIB brotlidec)
    find_library(BROTLICOMMON_LIB brotlicommon)
    if(BROTLIDEC_LIB AND BROTLICOMMON_LIB)
        target_link_libraries(${PROJECT_NAME} PRIVATE ${BROTLIDEC_LIB} ${BROTLICOMMON_LIB})
    endif()
else()
    # =========================================================================
    # First build: FetchContent download, build, and install
    # =========================================================================
    message(STATUS "Exiv2 ${EXIV2_VERSION}: building from source via FetchContent")

    include(FetchContent)
    set(FETCHCONTENT_BASE_DIR ${EXIV2_DOWNLOAD_DIR})

    # Exiv2 build options
    set(EXIV2_ENABLE_XMP    ON  CACHE BOOL "" FORCE)
    set(EXIV2_ENABLE_NLS    OFF CACHE BOOL "" FORCE)
    set(EXIV2_ENABLE_INIH   OFF CACHE BOOL "" FORCE)
    set(EXIV2_BUILD_SAMPLES OFF CACHE BOOL "" FORCE)
    set(EXIV2_BUILD_EXIV2_COMMAND OFF CACHE BOOL "" FORCE)
    set(CMAKE_INSTALL_PREFIX ${EXIV2_INSTALL_DIR} CACHE PATH "" FORCE)

    FetchContent_Declare(
        exiv2
        GIT_REPOSITORY https://github.com/Exiv2/exiv2.git
        GIT_TAG        v${EXIV2_VERSION}
        GIT_SHALLOW    TRUE
    )
    FetchContent_MakeAvailable(exiv2)

    target_link_libraries(${PROJECT_NAME} PRIVATE exiv2lib)
    target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_BINARY_DIR})

    # Install Exiv2 library to EXIV2_INSTALL_DIR after the build completes.
    # This uses a POST_BUILD custom command so the install happens automatically
    # at the end of the first successful build.
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} --install ${EXIV2_DOWNLOAD_DIR}/exiv2-build
                --prefix ${EXIV2_INSTALL_DIR}
                --config $<CONFIG>
        COMMENT "Installing Exiv2 to ${EXIV2_INSTALL_DIR} for future builds..."
    )
endif()

message(STATUS "Exiv2 ${EXIV2_VERSION} linked to ${PROJECT_NAME}")
message(STATUS "===============================================================")
