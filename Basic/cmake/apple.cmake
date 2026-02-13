# =============================================================================
# apple.cmake - Apple Configuration File
#
# Project: [CMake Template Project]
# Author: [mitsuruk]
# Date:    2025/11/26
# License: MIT License
# See LICENSE.md for details.
# =============================================================================

include_guard(GLOBAL)

message(STATUS "===============================================================")
  message(STATUS "Default macOS Framework Paths:")
  message(STATUS "  /System/Library/Frameworks")
  message(STATUS "  /Library/Frameworks")
# Locate the Homebrew installation directory with proper error handling
find_program(BREW_COMMAND brew)
if(BREW_COMMAND)
    execute_process(COMMAND brew --prefix OUTPUT_VARIABLE BREW_DIR ERROR_QUIET)
    string(STRIP "${BREW_DIR}" BREW_DIR)
    if(BREW_DIR)
        message(STATUS "homebrew directory = ${BREW_DIR}")
        set(CMAKE_PREFIX_PATH "${BREW_DIR};${CMAKE_PREFIX_PATH}")

        if(IS_DIRECTORY ${BREW_DIR}/include)
            target_include_directories(${PROJECT_NAME} PRIVATE ${BREW_DIR}/include)
        endif()

        if(IS_DIRECTORY ${BREW_DIR}/lib)
            # Prefer modifying CMAKE_PREFIX_PATH over using link_directories
            list(APPEND CMAKE_PREFIX_PATH "${BREW_DIR}")
        endif()
    else()
        message(WARNING "Homebrew found but brew --prefix failed")
    endif()
else()
    message(STATUS "Homebrew not found, using system defaults")
endif()

# [[ Add support for Metal C++ if its headers are available. ]]
if(IS_DIRECTORY /usr/local/include/metal-cpp)
    target_include_directories(${PROJECT_NAME} PRIVATE /usr/local/include/metal-cpp /usr/local/include/metal-cpp-extensions)
endif()


