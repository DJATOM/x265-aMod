# CMake toolchain file for cross compiling x265 for aarch64
# This feature is only supported as experimental. Use with caution.
# Please report bugs on bitbucket
# Run cmake with: cmake -DCMAKE_TOOLCHAIN_FILE=crosscompile.cmake -G "Unix Makefiles" ../../source && ccmake ../../source

set(CROSS_COMPILE_ARM64 1)
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# specify the cross compiler
if(DEFINED ENV{CMAKE_C_COMPILER})
    set(CMAKE_C_COMPILER $ENV{CMAKE_C_COMPILER})
else()
    set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
endif()
if(DEFINED ENV{CMAKE_CXX_COMPILER})
    set(CMAKE_CXX_COMPILER $ENV{CMAKE_CXX_COMPILER})
else()
    set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
endif()

# specify the target environment
SET(CMAKE_FIND_ROOT_PATH  /usr/aarch64-linux-gnu)

# specify whether SVE/SVE2 is supported by the target platform
if(DEFINED ENV{CROSS_COMPILE_SVE2})
    set(CROSS_COMPILE_SVE2 1)
elseif(DEFINED ENV{CROSS_COMPILE_SVE})
    set(CROSS_COMPILE_SVE 1)
endif()

