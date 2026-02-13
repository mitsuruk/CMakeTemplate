# =============================================================================
# CodeGenerators.cmake - External code generation configuration
#
# Project: [CMake Template Project]
# Author: [mitsuruk]
# Date:    2025/11/26
# License: MIT License
# See LICENSE.md for details.
# =============================================================================

# This file handles automatic code generation using tools such as:
#   - Flex & Bison (for lexical and syntactic analysis)
#   - gRPC & Protocol Buffers (for RPC interface definitions)
#   - ANTLR (for grammar-based parsers)
#
# Intended to be included from the top-level CMakeLists.txt.

include_guard(GLOBAL)

# ------------------------------------------------------------
## Integrate Flex and Bison if the 'grammar' directory is present
# ------------------------------------------------------------
if(EXISTS "${PROJECT_SOURCE_DIR}/grammar")
    # Indicate that Flex and Bison integration is beginning.
    message(STATUS "** Integrating Flex and Bison. **")

    # Locate the required Flex and Bison packages.
    find_package(BISON REQUIRED)
    find_package(FLEX REQUIRED)

    # Initialize a list to store all generated source files.
    set(GENERATED_YACC_LEX)

    # Locate all Bison grammar files (*.y) in the grammar directory.
    file(GLOB BISON_SOURCES "${PROJECT_SOURCE_DIR}/grammar/*.y")
    foreach(bison_file ${BISON_SOURCES})
        # Get the filename without its extension.
        get_filename_component(bison_name ${bison_file} NAME_WE)

        # Generate C source and header files from the Bison grammar file.
        BISON_TARGET(${bison_name} ${bison_file} ${PROJECT_BINARY_DIR}/${bison_name}.tab.c DEFINES_FILE ${PROJECT_BINARY_DIR}/${bison_name}.tab.h)

        # Add the generated files to the list of sources.
        list(APPEND GENERATED_YACC_LEX ${BISON_${bison_name}_OUTPUTS})
    endforeach()

    # Locate all Flex lexer files (*.l) in the grammar directory.
    file(GLOB FLEX_SOURCES "${PROJECT_SOURCE_DIR}/grammar/*.l")
    foreach(flex_file ${FLEX_SOURCES})
        # Get the filename without its extension.
        get_filename_component(flex_name ${flex_file} NAME_WE)

        # Generate C source file from the Flex lexer file.
        FLEX_TARGET(${flex_name} ${flex_file} ${PROJECT_BINARY_DIR}/${flex_name}.yy.c)

        # Add the generated files to the list of sources.
        list(APPEND GENERATED_YACC_LEX ${FLEX_${flex_name}_OUTPUTS})
    endforeach()

    # Add all generated lexer and parser sources to the main project target.
    target_sources(${PROJECT_NAME}
        PRIVATE
        ${GENERATED_YACC_LEX}
    )
endif() # End of Flex and Bison integration

# ------------------------------------------------------------
## Integrate gRPC and Protocol Buffers if the 'protos' directory is present
# ------------------------------------------------------------
if(EXISTS "${PROJECT_SOURCE_DIR}/protos")
    # Indicate that gRPC and Protocol Buffers integration is starting.
    message(STATUS "** Integrating gRPC and Protocol Buffers. **")

    # Locate the required Protobuf and gRPC packages.
    find_package(Protobuf CONFIG REQUIRED)
    find_package(gRPC CONFIG REQUIRED)

    # Cache key paths for protoc and its plugins.
    set(_PROTOBUF_LIBPROTOBUF protobuf::libprotobuf)
    set(_PROTOBUF_PROTOC $<TARGET_FILE:protobuf::protoc>)
    set(_GRPC_GRPCPP gRPC::grpc++)
    set(_GRPC_CPP_PLUGIN_EXECUTABLE $<TARGET_FILE:gRPC::grpc_cpp_plugin>)

    # Locate all .proto files in the protos directory.
    file(GLOB PROTO_FILES "${PROJECT_SOURCE_DIR}/protos/*.proto")

    # Initialize lists to store all generated sources and headers.
    set(GENERATED_GRPC_SRCS)
    set(GENERATED_GRPC_HDRS)

    foreach(proto_file ${PROTO_FILES})
        # Get the filename without its extension.
        get_filename_component(proto_name ${proto_file} NAME_WE)

        # Define the output filenames for the generated files.
        set(proto_src "${CMAKE_CURRENT_BINARY_DIR}/${proto_name}.pb.cc")
        set(proto_hdr "${CMAKE_CURRENT_BINARY_DIR}/${proto_name}.pb.h")
        set(grpc_src "${CMAKE_CURRENT_BINARY_DIR}/${proto_name}.grpc.pb.cc")
        set(grpc_hdr "${CMAKE_CURRENT_BINARY_DIR}/${proto_name}.grpc.pb.h")

        # Add a custom command to generate C++ code from the .proto file.
        add_custom_command(
            OUTPUT "${proto_src}" "${proto_hdr}" "${grpc_src}" "${grpc_hdr}"
            COMMAND ${_PROTOBUF_PROTOC}
            ARGS --proto_path="${PROJECT_SOURCE_DIR}/protos"
            --cpp_out="${CMAKE_CURRENT_BINARY_DIR}"
            --grpc_out="${CMAKE_CURRENT_BINARY_DIR}"
            --plugin=protoc-gen-grpc="${_GRPC_CPP_PLUGIN_EXECUTABLE}"
            "${proto_file}"
            DEPENDS "${proto_file}"
        )

        # Collect the generated source and header files.
        list(APPEND GENERATED_GRPC_SRCS "${proto_src}" "${grpc_src}")
        list(APPEND GENERATED_GRPC_HDRS "${proto_hdr}" "${grpc_hdr}")
    endforeach()

    # Create a static library containing all generated gRPC sources.
    set(PRJ_PROTO "${DIR_NAME}_grpc_proto")
    add_library(${PRJ_PROTO} ${GENERATED_GRPC_SRCS} ${GENERATED_GRPC_HDRS})

    # Link the necessary libraries to the generated gRPC library.
    target_link_libraries(${PRJ_PROTO}
        PRIVATE
        ${_PROTOBUF_LIBPROTOBUF}
        ${_GRPC_GRPCPP}
        gRPC::grpc++_reflection
    )

    # Add the directory containing generated files to the include path.
    target_include_directories(${PRJ_PROTO}
        PUBLIC
        ${CMAKE_CURRENT_BINARY_DIR}
    )

    # Optionally link the generated gRPC library to the main project.
    target_link_libraries(${PROJECT_NAME}
        PRIVATE
        ${PRJ_PROTO}
    )
endif() # End of gRPC and Protocol Buffers integration

# ------------------------------------------------------------
## Integrate ANTLR if the 'antlr' directory is present
# ------------------------------------------------------------
if(EXISTS "${PROJECT_SOURCE_DIR}/antlr")
    # Indicate that ANTLR integration is starting.
    message(STATUS "** Integrating ANTLR. **")

    # Set the C++ standard to C++17 for ANTLR-generated code.
    set(CMAKE_CXX_STANDARD 17)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)

    # Locate the ANTLR4 executable tool.
    find_program(ANTLR4_EXECUTABLE NAMES antlr REQUIRED)

    # Verify that the ANTLR4 executable was found.
    if(NOT ANTLR4_EXECUTABLE)
        message(FATAL_ERROR "ANTLR4 tool not found. Please install it and ensure 'antlr' is in your PATH.")
    endif()

    # Locate the ANTLR4 runtime library.
    find_package(antlr4-runtime CONFIG REQUIRED)

    # Locate all .g4 grammar files in the antlr directory.
    file(GLOB ANTLR4_GRAMMARS "${PROJECT_SOURCE_DIR}/antlr/*.g4")

    # Initialize lists to store generated sources and headers.
    set(GENERATED_ANTLR_SRCS)
    set(GENERATED_ANTLR_HDRS)

    foreach(grammar_file ${ANTLR4_GRAMMARS})
        # Get the filename without its extension.
        get_filename_component(grammar_name ${grammar_file} NAME_WE)

        # Define output filenames for the generated C++ files.
        set(parser_cpp "${CMAKE_CURRENT_BINARY_DIR}/${grammar_name}Parser.cpp")
        set(parser_h "${CMAKE_CURRENT_BINARY_DIR}/${grammar_name}Parser.h")
        set(lexer_cpp "${CMAKE_CURRENT_BINARY_DIR}/${grammar_name}Lexer.cpp")
        set(lexer_h "${CMAKE_CURRENT_BINARY_DIR}/${grammar_name}Lexer.h")
        set(listener_h "${CMAKE_CURRENT_BINARY_DIR}/${grammar_name}Listener.h")
        set(visitor_h "${CMAKE_CURRENT_BINARY_DIR}/${grammar_name}Visitor.h")

        # Add a custom command to generate C++ sources from the grammar file.
        add_custom_command(
            OUTPUT "${parser_cpp}" "${parser_h}" "${lexer_cpp}" "${lexer_h}" "${listener_h}" "${visitor_h}"
            COMMAND ${ANTLR4_EXECUTABLE}
            ARGS -Dlanguage=Cpp
            -o "${CMAKE_CURRENT_BINARY_DIR}"
            "${grammar_file}"
            DEPENDS "${grammar_file}"
            COMMENT "Generating ANTLR4 C++ files from ${grammar_file}"
            VERBATIM
        )

        # Add the generated files to the respective lists.
        list(APPEND GENERATED_ANTLR_SRCS "${parser_cpp}" "${lexer_cpp}")
        list(APPEND GENERATED_ANTLR_HDRS "${parser_h}" "${lexer_h}" "${listener_h}" "${visitor_h}")
    endforeach()

    # Create a static library for all generated ANTLR sources.
    set(PRJ_ANTLR "${DIR_NAME}_antlr")
    add_library(${PRJ_ANTLR} ${GENERATED_ANTLR_SRCS} ${GENERATED_ANTLR_HDRS})

    # Add include directories for the generated sources and ANTLR runtime headers.
    target_include_directories(${PRJ_ANTLR}
        PUBLIC
        ${CMAKE_CURRENT_BINARY_DIR}
    )
    
    # Add Homebrew ANTLR runtime path if available
    find_program(BREW_COMMAND brew)
    if(BREW_COMMAND)
        execute_process(COMMAND brew --prefix OUTPUT_VARIABLE BREW_DIR ERROR_QUIET)
        string(STRIP "${BREW_DIR}" BREW_DIR)
        if(BREW_DIR AND IS_DIRECTORY ${BREW_DIR}/include/antlr4-runtime)
            target_include_directories(${PRJ_ANTLR} PUBLIC ${BREW_DIR}/include/antlr4-runtime)
            message(STATUS "Using Homebrew ANTLR runtime at: ${BREW_DIR}/include/antlr4-runtime")
        endif()
    endif()

    # Link against the ANTLR4 runtime library.
    target_link_libraries(${PRJ_ANTLR}
        PUBLIC
        antlr4-runtime
    )

    # Optionally link the generated ANTLR library to the main project.
    target_link_libraries(${PROJECT_NAME}
        PRIVATE
        ${PRJ_ANTLR}
    )
endif() # End of ANTLR integration
