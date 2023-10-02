# CMake toolchain file for cross compiling x265 for AArch64, using Clang.

set(CROSS_COMPILE_ARM64 1)
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(TARGET_TRIPLE aarch64-linux-gnu)

# specify the cross compiler (giving precedence to user-supplied CC/CXX)
if(NOT DEFINED CMAKE_C_COMPILER)
    set(CMAKE_C_COMPILER clang)
endif()
if(NOT DEFINED CMAKE_CXX_COMPILER)
    set(CMAKE_CXX_COMPILER clang++)
endif()

# specify compiler target
set(CMAKE_C_COMPILER_TARGET ${TARGET_TRIPLE})
set(CMAKE_CXX_COMPILER_TARGET ${TARGET_TRIPLE})

# specify assembler target
list(APPEND ASM_FLAGS "--target=${TARGET_TRIPLE}")

# specify the target environment
SET(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu)
