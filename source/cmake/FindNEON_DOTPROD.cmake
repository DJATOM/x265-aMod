include(FindPackageHandleStandardArgs)

# Check if Armv8.4 Neon DotProd is supported by the Arm CPU
if(APPLE)
    execute_process(COMMAND sysctl -a
                    COMMAND grep "hw.optional.arm.FEAT_DotProd: 1"
                    OUTPUT_VARIABLE has_dot_product
                    ERROR_QUIET
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
else()
    execute_process(COMMAND cat /proc/cpuinfo
                    COMMAND grep Features
                    COMMAND grep asimddp
                    OUTPUT_VARIABLE has_dot_product
                    ERROR_QUIET
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()

if(has_dot_product)
    set(CPU_HAS_NEON_DOTPROD 1)
endif()
