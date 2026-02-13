# =============================================================================
# install.cmake - Installation Configuration File
#
# Project: [CMake Template Project]
# Author: [mitsuruk]
# Date:    2025/11/26
# License: MIT License
# See LICENSE.md for details.
# =============================================================================

include_guard(GLOBAL)

# Copies header files from src/include/mklib to /usr/local/include/mklib
# If the destination directory does not exist, it will be created
# If the directory has a hierarchy, it will be copied recursively
# Multiple PATTERNs can be specified
# install(DIRECTORY ${CMAKE_SOURCE_DIR}/src/include/mklib/
#     DESTINATION /usr/local/include/mklib
#     FILES_MATCHING
#     PATTERN "*.h"
#     PATTERN "*.hpp"
# )

#
# Installs specific files to a specified directory
# If the destination directory does not exist, it will be created
# As an example, it installs src/*.md to /usr/local/include/mklib
#
# # Searches for source files and adds them to the list
# file(GLOB ANOTHER_DIR_FILES ${CMAKE_SOURCE_DIR}/src/*.md)
# list(APPEND DOC_FILES ${ANOTHER_DIR_FILES})

# # For now, let's say the destination is /usr/local/include/mklib/
# # Installs the files to the specified directory
# install(FILES ${DOC_FILES} DESTINATION /usr/local/include/mklib)

# Below, please confirm again

#[[ The optimal way to install programs into /usr/local/bin.    ]]
# install(TARGETS ${PROJECT_NAME})

#[[ A better way to install programs into an optional directory.   ]]
# install(TARGETS ${PROJECT_NAME} DESTINATION ${PROJECT_SOURCE_DIR}/install)

#[[ A better way to install programs into a prefixed install directory.  ]]
# set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/install)
# install(TARGETS ${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_PREFIX})

# install (
# DIRECTORY ${CMAKE_SOURCE_DIR}/src/include/
# DESTINATION include
# FILES_MATCHING PATTERN "*.h*")

#[[ The optimal way to install programs into /usr/local/bin.    ]]
# install(TARGETS ${PROJECT_NAME})

#[[ A better way to install programs into an optional directory.   ]]
# install(TARGETS ${PROJECT_NAME} DESTINATION ${PROJECT_SOURCE_DIR}/install)

#[[ A better way to install programs into a prefixed install directory.  ]]
# set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/install)
# install(TARGETS ${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_PREFIX})

# install /usr/local/include
# install (
# DIRECTORY ${CMAKE_SOURCE_DIR}/src/include/
# DESTINATION include
# FILES_MATCHING PATTERN "*.h*")

# That's all, folks!
