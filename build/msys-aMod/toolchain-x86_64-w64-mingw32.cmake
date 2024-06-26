SET(CMAKE_SYSTEM_NAME Windows)
SET(CMAKE_SYSTEM_PROCESSOR AMD64)
SET(CMAKE_C_COMPILER x86_64-w64-mingw32-gcc)
SET(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++)
SET(CMAKE_RC_COMPILER windres)
SET(CMAKE_RANLIB x86_64-w64-mingw32-gcc-ranlib)
SET(CMAKE_ASM_YASM_COMPILER yasm)
SET(CMAKE_AR x86_64-w64-mingw32-gcc-ar)
# SET(ARCH_OPT znver2)
if(ARCH_OPT)
    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -march=${ARCH_OPT}")
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -march=${ARCH_OPT}")
endif()