# =============================================================================
# CMake build configuration
#
# Project: [CMake Template Project]
# Author: [mitsuruk]
# Date:    2026/02/12
# License: MIT License
# See LICENSE.md for details.
# =============================================================================
# Minimum CMake version
cmake_minimum_required(VERSION 3.20)
project(ProjectName)

# Set output directories for all project outputs
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# for debug build
# cmake -DCMAKE_BUILD_TYPE=Debug ..
# set(CMAKE_BUILD_TYPE Debug)

# Set include directories
include_directories(${CMAKE_SOURCE_DIR}/include)

# Function to explore subdirectories and add those with CMakeLists.txt
function(add_subdirectories)
    # Get the current directory
    set(CURRENT_DIR ${CMAKE_CURRENT_SOURCE_DIR})

    # Explore directories
    file(GLOB SUBDIRS RELATIVE ${CURRENT_DIR} ${CURRENT_DIR}/*)

    # Check each directory
    foreach(SUBDIR ${SUBDIRS})
        if(IS_DIRECTORY ${CURRENT_DIR}/${SUBDIR})
            # Check if the subdirectory contains CMakeLists.txt
            if(EXISTS ${CURRENT_DIR}/${SUBDIR}/CMakeLists.txt)
                message(STATUS "Adding subdirectory: ${SUBDIR}")
                add_subdirectory(${SUBDIR})
            endif()
        endif()
    endforeach()
endfunction()# Call the function to add subdirectories

add_subdirectories()
