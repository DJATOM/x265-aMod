/*****************************************************************************
 * Copyright (C) 2024 MulticoreWare, Inc
 *
 * Authors: Hari Limaye <hari.limaye@arm.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111, USA.
 *
 * This program is also available under a commercial proprietary license.
 * For more information, contact us at license @ x265.com.
 *****************************************************************************/

#include "asm.S"

.arch armv8.2-a+dotprod

#ifdef __APPLE__
.section __RODATA,__rodata
#else
.section .rodata
#endif

.align 4

.text

// Fully unrolled with single accumulator for smaller block heights.
.macro SAD_NEON_DOTPROD_16_S h
function PFX(pixel_sad_16x\h\()_neon_dotprod)
    movi            v0.16b, #0
    movi            v1.16b, #1
.rept \h - 2
    ldr             q2, [x0]
    ldr             q3, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    uabd            v4.16b, v2.16b, v3.16b
    udot            v0.4s, v4.16b, v1.16b
.endr
    ldr             q2, [x0]
    ldr             q3, [x2]
    uabd            v4.16b, v2.16b, v3.16b
    udot            v0.4s, v4.16b, v1.16b
    ldr             q2, [x0, x1]
    ldr             q3, [x2, x3]
    uabd            v4.16b, v2.16b, v3.16b
    udot            v0.4s, v4.16b, v1.16b

    addv            s0, v0.4s
    fmov            w0, s0
    ret
endfunc
.endm

.macro SAD_NEON_DOTPROD_START
    // v31: 1 across all lanes for use in UDOT instructions.
    movi            v31.16b, #1
    movi            v16.16b, #0
    movi            v17.16b, #0
.endm

.macro SAD_NEON_DOTPROD_END
    add             v16.4s, v16.4s, v17.4s
    addv            s0, v16.4s
    fmov            w0, s0
    ret
.endm

// Fully unrolled.
.macro SAD_NEON_DOTPROD_16 h
function PFX(pixel_sad_16x\h\()_neon_dotprod)
    SAD_NEON_DOTPROD_START
.rept \h / 2
    ld1             {v0.16b}, [x0], x1
    ld1             {v1.16b}, [x0], x1
    ld1             {v2.16b}, [x2], x3
    ld1             {v3.16b}, [x2], x3
    uabd            v20.16b, v0.16b, v2.16b
    udot            v16.4s, v20.16b, v31.16b
    uabd            v21.16b, v1.16b, v3.16b
    udot            v17.4s, v21.16b, v31.16b
.endr
    SAD_NEON_DOTPROD_END
endfunc
.endm

// Process four rows of width 32.
.macro SAD_NEON_DOTPROD_32
.rept 4
    ld1             {v0.16b-v1.16b}, [x0], x1
    ld1             {v2.16b-v3.16b}, [x2], x3
    uabd            v20.16b, v0.16b, v2.16b
    udot            v16.4s, v20.16b, v31.16b
    uabd            v21.16b, v1.16b, v3.16b
    udot            v17.4s, v21.16b, v31.16b
.endr
.endm

// Process four rows of width 48.
.macro SAD_NEON_DOTPROD_48
.rept 4
    ld1             {v0.16b-v2.16b}, [x0], x1
    ld1             {v4.16b-v6.16b}, [x2], x3
    uabd            v20.16b, v0.16b, v4.16b
    udot            v16.4s, v20.16b, v31.16b
    uabd            v21.16b, v1.16b, v5.16b
    udot            v17.4s, v21.16b, v31.16b
    uabd            v20.16b, v2.16b, v6.16b
    udot            v16.4s, v20.16b, v31.16b
.endr
.endm

// Process four rows of width 64.
.macro SAD_NEON_DOTPROD_64
.rept 4
    ld1             {v0.16b-v3.16b}, [x0], x1
    ld1             {v4.16b-v7.16b}, [x2], x3
    uabd            v20.16b, v0.16b, v4.16b
    udot            v16.4s, v20.16b, v31.16b
    uabd            v21.16b, v1.16b, v5.16b
    udot            v17.4s, v21.16b, v31.16b
    uabd            v20.16b, v2.16b, v6.16b
    udot            v16.4s, v20.16b, v31.16b
    uabd            v21.16b, v3.16b, v7.16b
    udot            v17.4s, v21.16b, v31.16b
.endr
.endm

// Loop unrolled to process 4 rows per iteration.
.macro SAD_NEON_DOTPROD_LOOP w, h
function PFX(pixel_sad_\w\()x\h\()_neon_dotprod)
    SAD_NEON_DOTPROD_START
    mov             w9, #\h/4
.Loop_\w\()x\h:
    sub             w9, w9, #1

    SAD_NEON_DOTPROD_\w

    cbnz            w9, .Loop_\w\()x\h
    SAD_NEON_DOTPROD_END
endfunc
.endm

SAD_NEON_DOTPROD_16_S 4
SAD_NEON_DOTPROD_16_S 8
SAD_NEON_DOTPROD_16_S 12
SAD_NEON_DOTPROD_16_S 16
SAD_NEON_DOTPROD_16 32
SAD_NEON_DOTPROD_16 64
SAD_NEON_DOTPROD_LOOP  32, 8
SAD_NEON_DOTPROD_LOOP  32, 16
SAD_NEON_DOTPROD_LOOP  32, 24
SAD_NEON_DOTPROD_LOOP  32, 32
SAD_NEON_DOTPROD_LOOP  32, 64
SAD_NEON_DOTPROD_LOOP  48, 64
SAD_NEON_DOTPROD_LOOP  64, 16
SAD_NEON_DOTPROD_LOOP  64, 32
SAD_NEON_DOTPROD_LOOP  64, 48
SAD_NEON_DOTPROD_LOOP  64, 64
