# =============================================================================
# replxx CMake configuration
#
# This file configures replxx library for the project.
# replxx is a readline and libedit replacement that supports UTF-8,
# syntax highlighting, hints, and works on Unix and Windows.
#
# Download directory: ${CMAKE_CURRENT_SOURCE_DIR}/download/replxx
#
# License: MIT License (this cmake file)
# Note: replxx library itself is BSD-3-Clause licensed.
# =============================================================================

include_guard(GLOBAL)

include(FetchContent)

message(STATUS "===============================================================")
message(STATUS "replxx configuration:")

# Path to download directory
set(REPLXX_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download/replxx)
set(REPLXX_SOURCE_DIR ${REPLXX_DOWNLOAD_DIR}/replxx)

message(STATUS "REPLXX_SOURCE_DIR = ${REPLXX_SOURCE_DIR}")

# =============================================================================
# replxx Library Download via FetchContent
# =============================================================================
FetchContent_Declare(
    replxx
    GIT_REPOSITORY https://github.com/AmokHuginnsson/replxx.git
    GIT_TAG        release-0.0.4
    GIT_SHALLOW    TRUE
    SOURCE_DIR     ${REPLXX_SOURCE_DIR}
)

message(STATUS "Fetching replxx from GitHub (if not already downloaded)...")

# Build options for replxx
set(REPLXX_BUILD_EXAMPLES OFF CACHE BOOL "Build replxx examples" FORCE)

# Fetch and make available
FetchContent_MakeAvailable(replxx)

message(STATUS "replxx fetched successfully")

# =============================================================================
# replxx Library Configuration
# =============================================================================
# Link replxx to the project
target_link_libraries(${PROJECT_NAME} PRIVATE replxx)

# Include directories (FetchContent_MakeAvailable handles this, but explicit for clarity)
target_include_directories(${PROJECT_NAME} PRIVATE
    ${REPLXX_SOURCE_DIR}/include
)

message(STATUS "replxx linked to ${PROJECT_NAME}")
message(STATUS "===============================================================")
