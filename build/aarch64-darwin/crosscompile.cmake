# CMake toolchain file for cross compiling x265 for aarch64
# This feature is only supported as experimental. Use with caution.
# Please report bugs on bitbucket
# Run cmake with: cmake -DCMAKE_TOOLCHAIN_FILE=crosscompile.cmake -G "Unix Makefiles" ../../source && ccmake ../../source

set(CROSS_COMPILE_ARM64 1)
set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# specify the cross compiler
set(CMAKE_C_COMPILER gcc-12)
set(CMAKE_CXX_COMPILER g++-12)

# specify the target environment
SET(CMAKE_FIND_ROOT_PATH  /opt/homebrew/bin/)

# specify whether SVE/SVE2 is supported by the target platform
if(DEFINED ENV{CROSS_COMPILE_SVE2})
    set(CROSS_COMPILE_SVE2 1)
elseif(DEFINED ENV{CROSS_COMPILE_SVE})
    set(CROSS_COMPILE_SVE 1)
endif()

