# CMakeLists.txt for OmniTAK Mobile Android Native Library
#
# This builds the JNI bridge (omnitak_jni.cpp) and links it with
# the pre-built Rust static library (libomnitak_mobile.a)

cmake_minimum_required(VERSION 3.18.1)

project(omnitak_mobile)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable verbose output for debugging
set(CMAKE_VERBOSE_MAKEFILE ON)

# Determine the Android ABI
if(NOT ANDROID_ABI)
    message(FATAL_ERROR "ANDROID_ABI must be set")
endif()

message(STATUS "Building for Android ABI: ${ANDROID_ABI}")

# Path to the Rust library
# This should be set to where the pre-built Rust libraries are located
# Expected structure:
#   android/native/lib/${ANDROID_ABI}/libomnitak_mobile.a
set(RUST_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/lib/${ANDROID_ABI}")

if(NOT EXISTS "${RUST_LIB_DIR}")
    message(WARNING "Rust library directory not found: ${RUST_LIB_DIR}")
    message(WARNING "You need to build the Rust library and place it at:")
    message(WARNING "  android/native/lib/arm64-v8a/libomnitak_mobile.a")
    message(WARNING "  android/native/lib/armeabi-v7a/libomnitak_mobile.a")
    message(WARNING "  android/native/lib/x86_64/libomnitak_mobile.a")
    message(WARNING "  android/native/lib/x86/libomnitak_mobile.a")
endif()

# Include directory for Rust FFI header
set(RUST_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/include")

# Create include directory if it doesn't exist
file(MAKE_DIRECTORY ${RUST_INCLUDE_DIR})

# JNI bridge source
set(JNI_SOURCES
    omnitak_jni.cpp
)

# Create shared library for JNI
add_library(omnitak_mobile SHARED ${JNI_SOURCES})

# Include directories
target_include_directories(omnitak_mobile PRIVATE
    ${RUST_INCLUDE_DIR}
)

# Find and link Android libraries
find_library(log-lib log)
find_library(android-lib android)

# Link against the Rust static library if it exists
if(EXISTS "${RUST_LIB_DIR}/libomnitak_mobile.a")
    message(STATUS "Found Rust library at: ${RUST_LIB_DIR}/libomnitak_mobile.a")

    # Import the Rust library
    add_library(omnitak_rust STATIC IMPORTED)
    set_target_properties(omnitak_rust PROPERTIES
        IMPORTED_LOCATION "${RUST_LIB_DIR}/libomnitak_mobile.a"
    )

    # Link JNI library with Rust library and system libraries
    target_link_libraries(omnitak_mobile
        omnitak_rust
        ${log-lib}
        ${android-lib}
    )
else()
    message(WARNING "Rust static library not found, linking will fail at runtime")
    message(WARNING "Expected: ${RUST_LIB_DIR}/libomnitak_mobile.a")

    # Still link system libraries
    target_link_libraries(omnitak_mobile
        ${log-lib}
        ${android-lib}
    )
endif()

# Compiler flags
target_compile_options(omnitak_mobile PRIVATE
    -Wall
    -Wextra
    -fvisibility=hidden
)

# Set output directory
set_target_properties(omnitak_mobile PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}"
)

# Strip symbols in release builds
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_link_options(omnitak_mobile PRIVATE
        -Wl,--gc-sections
        -Wl,--strip-all
    )
endif()

# Print configuration summary
message(STATUS "========================================")
message(STATUS "OmniTAK Mobile Android Native Build")
message(STATUS "========================================")
message(STATUS "Android ABI: ${ANDROID_ABI}")
message(STATUS "Rust lib dir: ${RUST_LIB_DIR}")
message(STATUS "Rust include dir: ${RUST_INCLUDE_DIR}")
message(STATUS "Output directory: ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
message(STATUS "========================================")
