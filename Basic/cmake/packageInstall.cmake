# =============================================================================
# packageInstall.cmake - CMake package installation script
#
# Project: [CMake Template Project]
# Author: [mitsuruk]
# Date:    2025/11/26
# License: MIT License
# See LICENSE.md for details.
# =============================================================================

include_guard(GLOBAL)

# -----------------------------------------------------------------------------
# Set the package name and version
# -----------------------------------------------------------------------------
# set(PACKAGE_NAME cmdTest)
set(PACKAGE_NAME ${PROJECT_NAME})
set(PACKAGE_VERSION 0.0.1)

# -----------------------------------------------------------------------------
# Check PACKAGE_NAME
# -----------------------------------------------------------------------------
if(NOT DEFINED PACKAGE_NAME OR PACKAGE_NAME STREQUAL "")
    message(FATAL_ERROR "PACKAGE_NAME is not set. Please call: set(PACKAGE_NAME your_package_name)")
endif()

# -----------------------------------------------------------------------------
# Check PACKAGE_VERSION
# -----------------------------------------------------------------------------
if(NOT DEFINED PACKAGE_VERSION OR PACKAGE_VERSION STREQUAL "")
    message(FATAL_ERROR "PACKAGE_VERSION is not set. Please call: set(PACKAGE_VERSION x.y.z)")
endif()

# -----------------------------------------------------------------------------
# Include CMake package configuration helpers
# https://cmake.org/cmake/help/latest/module/CMakePackageConfigHelpers.html
# -----------------------------------------------------------------------------
include(CMakePackageConfigHelpers)

# -----------------------------------------------------------------------------
# Set the library’s public include directories
# https://cmake.org/cmake/help/latest/command/target_include_directories.html
# -----------------------------------------------------------------------------

#[[ Adds include directories to a target. ]]
if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src/include)
    target_include_directories(${PROJECT_NAME} PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/include>
        $<INSTALL_INTERFACE:include>
    )
endif()

# -----------------------------------------------------------------------------
# Creates version file.
# https://cmake.org/cmake/help/latest/module/CMakePackageConfigHelpers.html#command:write_basic_package_version_file
# -----------------------------------------------------------------------------
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}ConfigVersion.cmake
    VERSION ${PACKAGE_VERSION}
    COMPATIBILITY AnyNewerVersion
)

# -----------------------------------------------------------------------------
# Create the target configuration file
# -----------------------------------------------------------------------------
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/cmake)
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/cmake/${PACKAGE_NAME}Config.cmake.in
    "include(\"\${CMAKE_CURRENT_LIST_DIR}/${PACKAGE_NAME}Targets.cmake\")"
)

# -----------------------------------------------------------------------------
# Specify the installation destination for the package configuration file.
# When @ONLY is specified, configure_file replaces only variables in @VAR@ format.
# Variables in ${VAR} format are preserved and written as-is.
# This is useful when generating CMake scripts or when you want ${VAR} to appear in the output.
# If @ONLY is not specified, configure_file replaces both @VAR@ and ${VAR} formats.
# -----------------------------------------------------------------------------
configure_file(${CMAKE_CURRENT_BINARY_DIR}/cmake/${PACKAGE_NAME}Config.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}Config.cmake @ONLY)

# -----------------------------------------------------------------------------
# Automatically detect and install valid targets
# https://cmake.org/cmake/help/latest/command/install.html
# -----------------------------------------------------------------------------

# Get all targets defined in the project
get_property(ALL_TARGETS DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY BUILDSYSTEM_TARGETS)

# Initialize the list of targets for installation
set(INSTALL_TARGETS "")

# Filter and collect installable targets
# Prioritize main targets (e.g., shared libraries); export others using aliases
foreach(target ${ALL_TARGETS})
    if(TARGET ${target})
        get_target_property(target_type ${target} TYPE)
        # Only target executables, static libraries, and shared libraries for installation
        if(target_type MATCHES "EXECUTABLE|STATIC_LIBRARY|SHARED_LIBRARY")
            list(APPEND INSTALL_TARGETS ${target})
            message(STATUS "Added installable target: ${target} (${target_type})")
        else()
            message(STATUS "Skipped target: ${target} (${target_type})")
        endif()
    endif()
endforeach()

# Install only if there are existing targets
if(INSTALL_TARGETS)
    install(TARGETS ${INSTALL_TARGETS} EXPORT ${PACKAGE_NAME}Targets
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        RUNTIME DESTINATION bin
        INCLUDES DESTINATION include
    )
    message(STATUS "Installing targets: ${INSTALL_TARGETS}")
else()
    message(FATAL_ERROR "No installable targets found. Please define at least one executable, static library, or shared library target.")
endif()

# -----------------------------------------------------------------------------
# Install include directory.
# -----------------------------------------------------------------------------
if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src/include)
    install(DIRECTORY src/include/ DESTINATION include)
endif()

# -----------------------------------------------------------------------------
# Export target configuration
# EXPORT ${PACKAGE_NAME}Targets: Installs the listed targets into an export set named ${PACKAGE_NAME}Targets
# FILE ${PACKAGE_NAME}Targets.cmake: Specifies the filename of the export file
# NAMESPACE ${PACKAGE_NAME}::: Adds a namespace prefix to the exported targets
# DESTINATION lib/cmake/${PACKAGE_NAME}: Destination path for the installed export file
# -----------------------------------------------------------------------------
install(EXPORT ${PACKAGE_NAME}Targets
    FILE ${PACKAGE_NAME}Targets.cmake
    NAMESPACE ${PACKAGE_NAME}::
    DESTINATION lib/cmake/${PACKAGE_NAME}
)

# -----------------------------------------------------------------------------
# Install configuration files.
# -----------------------------------------------------------------------------
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}Config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}ConfigVersion.cmake"
    DESTINATION lib/cmake/${PACKAGE_NAME}
)

# -----------------------------------------------------------------------------
# Reference: How to uninstall installed target files
# -----------------------------------------------------------------------------
# sudo xargs rm < install_manifest.txt
