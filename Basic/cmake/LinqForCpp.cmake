# =============================================================================
# LinqForCpp CMake configuration
#
# This file configures the LinqForCpp header-only library for the project.
# LinqForCpp is a C++ implementation of LINQ (Language Integrated Query),
# bringing C#-style query capabilities to C++.
#
# Download directory: ${CMAKE_CURRENT_SOURCE_DIR}/download/LinqForCpp
# Install directory:  ${CMAKE_CURRENT_SOURCE_DIR}/download/LinqForCpp/LinqForCpp-install
#
# - If LinqForCpp-install/include/SingleHeader/Linq.hpp already exists,
#   skip download (reuse cache).
# - Otherwise, download LinqForCpp.zip from GitHub and install.
#
# Note: LinqForCpp is header-only. No compilation or linking is needed.
#
# License: MIT License (this cmake file)
# Note: LinqForCpp library itself is licensed under MIT License.
# =============================================================================

include_guard(GLOBAL)

message(STATUS "===============================================================")
message(STATUS "LinqForCpp configuration:")

# Path to download/install directories
set(LINQFORCPP_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/LinqForCpp)
set(LINQFORCPP_INSTALL_DIR ${LINQFORCPP_DOWNLOAD_DIR}/LinqForCpp-install)
set(LINQFORCPP_VERSION "1.0.1")
set(LINQFORCPP_URL "https://github.com/harayuu9/LinqForCpp/releases/download/v${LINQFORCPP_VERSION}/LinqForCpp.zip")

message(STATUS "LINQFORCPP_INSTALL_DIR = ${LINQFORCPP_INSTALL_DIR}")

# =============================================================================
# LinqForCpp: Download and Install (cached in download/ directory)
# =============================================================================
if(EXISTS ${LINQFORCPP_INSTALL_DIR}/include/SingleHeader/Linq.hpp)
    message(STATUS "LinqForCpp already installed: ${LINQFORCPP_INSTALL_DIR}/include/SingleHeader/Linq.hpp")
else()
    # Create install directory structure
    file(MAKE_DIRECTORY ${LINQFORCPP_INSTALL_DIR}/include)

    # Check if LinqForCpp.zip is already cached in download/
    set(LINQFORCPP_CACHED ${LINQFORCPP_DOWNLOAD_DIR}/LinqForCpp.zip)

    if(EXISTS ${LINQFORCPP_CACHED})
        message(STATUS "LinqForCpp source already cached: ${LINQFORCPP_CACHED}")
    else()
        message(STATUS "Downloading LinqForCpp ${LINQFORCPP_VERSION} from GitHub ...")
        file(DOWNLOAD
            ${LINQFORCPP_URL}
            ${LINQFORCPP_CACHED}
            SHOW_PROGRESS
            TIMEOUT 120
            INACTIVITY_TIMEOUT 30
            STATUS DOWNLOAD_STATUS
        )
        list(GET DOWNLOAD_STATUS 0 DOWNLOAD_RESULT)
        if(NOT DOWNLOAD_RESULT EQUAL 0)
            list(GET DOWNLOAD_STATUS 1 DOWNLOAD_ERROR)
            file(REMOVE ${LINQFORCPP_CACHED})
            message(FATAL_ERROR
                "LinqForCpp download failed: ${DOWNLOAD_ERROR}\n"
                "You can manually download and place the file:\n"
                "  curl -L -o download/LinqForCpp/LinqForCpp.zip ${LINQFORCPP_URL}\n"
                "Then re-run cmake."
            )
        endif()
    endif()

    # Extract zip to install directory
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xzf ${LINQFORCPP_CACHED}
        WORKING_DIRECTORY ${LINQFORCPP_INSTALL_DIR}/include
        RESULT_VARIABLE EXTRACT_RESULT
    )
    if(NOT EXTRACT_RESULT EQUAL 0)
        file(REMOVE_RECURSE ${LINQFORCPP_INSTALL_DIR}/include)
        message(FATAL_ERROR
            "LinqForCpp extraction failed.\n"
            "Try removing the cached file and re-running cmake:\n"
            "  rm download/LinqForCpp/LinqForCpp.zip\n"
        )
    endif()

    # Verify installation
    if(NOT EXISTS ${LINQFORCPP_INSTALL_DIR}/include/SingleHeader/Linq.hpp)
        message(FATAL_ERROR "LinqForCpp installation failed")
    endif()

    # -------------------------------------------------------------------------
    # Patch: Fix namespace bug in SingleHeader/Linq.hpp (v1.0.1)
    #
    # The single-header generator places IteratorBase and all Builder structs
    # outside the linq namespace due to a premature closing brace after the
    # Allocator alias. This causes "no template named 'iterator_traits'" and
    # similar errors because the code expects to be inside namespace linq.
    #
    # Fix: remove the premature "}" after the Allocator alias (the final "}"
    # at the end of the file correctly closes namespace linq).
    # -------------------------------------------------------------------------
    set(LINQFORCPP_HPP ${LINQFORCPP_INSTALL_DIR}/include/SingleHeader/Linq.hpp)
    file(READ ${LINQFORCPP_HPP} LINQFORCPP_CONTENT)
    string(REPLACE
        "using Allocator = std::allocator<T>;\n}"
        "using Allocator = std::allocator<T>;\n// } -- removed: premature namespace close (patched)"
        LINQFORCPP_CONTENT "${LINQFORCPP_CONTENT}"
    )
    file(WRITE ${LINQFORCPP_HPP} "${LINQFORCPP_CONTENT}")
    message(STATUS "LinqForCpp: patched SingleHeader/Linq.hpp (namespace fix)")

    message(STATUS "LinqForCpp ${LINQFORCPP_VERSION} installed successfully")
endif()

# =============================================================================
# LinqForCpp Library Configuration
# =============================================================================
# Header-only: just add include directory, no linking needed
# Use SingleHeader/Linq.hpp for single-header usage
target_include_directories(${PROJECT_NAME} PRIVATE
    ${LINQFORCPP_INSTALL_DIR}/include
)

message(STATUS "LinqForCpp headers added to ${PROJECT_NAME}")
message(STATUS "===============================================================")
