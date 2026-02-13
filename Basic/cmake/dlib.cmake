# =============================================================================
# dlib CMake configuration
#
# This file configures dlib library for the project.
# dlib is a modern C++ toolkit containing machine learning algorithms
# and tools for creating complex software in C++.
#
# Download directory: ${CMAKE_CURRENT_SOURCE_DIR}/download/dlib
# Models directory:   ${CMAKE_CURRENT_SOURCE_DIR}/download/dlib-models
#
# Options:
#   -DDLIB_DOWNLOAD_MODELS=ON  : Download pre-trained models (default: OFF)
#
# License: MIT License
# See LICENSE.md for details.
# =============================================================================

include_guard(GLOBAL)

include(FetchContent)

message(STATUS "===============================================================")
message(STATUS "dlib configuration:")

# Path to download directory and dlib
set(DLIB_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/download)
set(DLIB_DIR ${DLIB_DOWNLOAD_DIR}/dlib)
set(DLIB_MODELS_DIR ${DLIB_DOWNLOAD_DIR}/dlib-models)

# =============================================================================
# dlib Library Download via FetchContent
# =============================================================================
FetchContent_Declare(
    dlib
    GIT_REPOSITORY https://github.com/davisking/dlib.git
    GIT_TAG        master
    GIT_SHALLOW    TRUE
    SOURCE_DIR     ${DLIB_DIR}
)

message(STATUS "Fetching dlib from GitHub (if not already downloaded)...")

# =============================================================================
# Pre-trained Models Download
# =============================================================================
# Option to download pre-trained models (disabled by default due to large size)
option(DLIB_DOWNLOAD_MODELS "Download dlib pre-trained models" OFF)

if(NOT DLIB_DOWNLOAD_MODELS)
    message(STATUS "Pre-trained models: SKIPPED (use -DDLIB_DOWNLOAD_MODELS=ON to download)")
endif()

if(DLIB_DOWNLOAD_MODELS)
    message(STATUS "===============================================================")
    message(STATUS "dlib models configuration:")

    # Declare dlib-models via FetchContent
    FetchContent_Declare(
        dlib-models
        GIT_REPOSITORY https://github.com/davisking/dlib-models.git
        GIT_TAG        master
        GIT_SHALLOW    TRUE
        SOURCE_DIR     ${DLIB_MODELS_DIR}
    )

    message(STATUS "Fetching dlib-models from GitHub (if not already downloaded)...")
    message(STATUS "This may take a while due to large model files...")

    # Populate dlib-models (download only, no add_subdirectory)
    FetchContent_GetProperties(dlib-models)
    if(NOT dlib-models_POPULATED)
        FetchContent_Populate(dlib-models)
        message(STATUS "dlib-models downloaded to: ${dlib-models_SOURCE_DIR}")
    endif()

    # Extract .bz2 files if they exist
    if(EXISTS ${DLIB_MODELS_DIR})
        message(STATUS "dlib-models found at: ${DLIB_MODELS_DIR}")

        # List of model files to extract
        set(DLIB_MODEL_FILES
            # Face Recognition
            "dlib_face_recognition_resnet_model_v1.dat.bz2"
            "face_recognition_densenet_model_v1.dat.bz2"
            "taguchi_face_recognition_resnet_model_v1.dat.bz2"
            # Face Detection & Landmarks
            "mmod_human_face_detector.dat.bz2"
            "shape_predictor_5_face_landmarks.dat.bz2"
            "shape_predictor_68_face_landmarks.dat.bz2"
            "shape_predictor_68_face_landmarks_GTX.dat.bz2"
            # Vehicle Detection
            "mmod_rear_end_vehicle_detector.dat.bz2"
            "mmod_front_and_rear_end_vehicle_detector.dat.bz2"
            # Image Classification
            "resnet34_1000_imagenet_classifier.dnn.bz2"
            "resnet50_1000_imagenet_classifier.dnn.bz2"
            "resnet34_stable_imagenet_1k.dat.bz2"
            "vit-s-16_stable_imagenet_1k.dat.bz2"
            # Other Models
            "mmod_dog_hipsterizer.dat.bz2"
            "dnn_gender_classifier_v1.dat.bz2"
            "dnn_age_predictor_v1.dat.bz2"
            "dcgan_162x162_synth_faces.dnn.bz2"
            "res50_self_supervised_cifar_10.dat.bz2"
            "highres_colorify.dnn.bz2"
        )

        # Find bunzip2 command
        find_program(BUNZIP2_EXECUTABLE bunzip2)
        if(NOT BUNZIP2_EXECUTABLE)
            message(WARNING "bunzip2 not found. Cannot extract model files.")
        else()
            foreach(MODEL_FILE ${DLIB_MODEL_FILES})
                set(MODEL_PATH "${DLIB_MODELS_DIR}/${MODEL_FILE}")
                # Get the extracted filename (remove .bz2 extension)
                string(REGEX REPLACE "\\.bz2$" "" EXTRACTED_FILE "${MODEL_FILE}")
                set(EXTRACTED_PATH "${DLIB_MODELS_DIR}/${EXTRACTED_FILE}")

                if(EXISTS ${MODEL_PATH} AND NOT EXISTS ${EXTRACTED_PATH})
                    message(STATUS "Extracting: ${MODEL_FILE}")
                    execute_process(
                        COMMAND ${BUNZIP2_EXECUTABLE} -k ${MODEL_PATH}
                        WORKING_DIRECTORY ${DLIB_MODELS_DIR}
                        RESULT_VARIABLE EXTRACT_RESULT
                    )
                    if(EXTRACT_RESULT EQUAL 0)
                        message(STATUS "  -> ${EXTRACTED_FILE}")
                    else()
                        message(WARNING "  Failed to extract ${MODEL_FILE}")
                    endif()
                elseif(EXISTS ${EXTRACTED_PATH})
                    message(STATUS "Model exists: ${EXTRACTED_FILE}")
                endif()
            endforeach()
        endif()

        # Export models directory path for use in code
        set(DLIB_MODELS_PATH "${DLIB_MODELS_DIR}" CACHE PATH "Path to dlib models directory")
        message(STATUS "DLIB_MODELS_PATH = ${DLIB_MODELS_PATH}")
    endif()
endif()

# =============================================================================
# dlib Library Build Configuration
# =============================================================================
# Disable X11/GUI support before fetching
set(DLIB_NO_GUI_SUPPORT ON CACHE BOOL "Disable dlib GUI support" FORCE)
message(STATUS "dlib GUI/X11 support: DISABLED")

# Fetch and configure dlib
FetchContent_GetProperties(dlib)
if(NOT dlib_POPULATED)
    FetchContent_Populate(dlib)
    message(STATUS "dlib downloaded to: ${dlib_SOURCE_DIR}")
endif()

# Add dlib as subdirectory
if(EXISTS ${dlib_SOURCE_DIR}/dlib/CMakeLists.txt)
    message(STATUS "dlib found at: ${dlib_SOURCE_DIR}")

    add_subdirectory(${dlib_SOURCE_DIR}/dlib dlib_build)

    # Link dlib to the project
    target_link_libraries(${PROJECT_NAME} PRIVATE dlib::dlib)

    # Add compile definition for models path if available
    if(DLIB_DOWNLOAD_MODELS AND EXISTS ${DLIB_MODELS_DIR})
        target_compile_definitions(${PROJECT_NAME} PRIVATE
            DLIB_MODELS_PATH="${DLIB_MODELS_DIR}"
        )
    endif()

    message(STATUS "dlib linked to ${PROJECT_NAME}")
else()
    message(FATAL_ERROR "dlib not found at ${dlib_SOURCE_DIR}. FetchContent failed.")
endif()

message(STATUS "===============================================================")
