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

// Fully unrolled.
.macro SSE_PP_4xN h
function PFX(pixel_sse_pp_4x\h\()_neon_dotprod)
    movi            v0.4s, #0
.rept \h / 4
    ldr             s16, [x0]
    ldr             s17, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    ld1             {v16.s}[1], [x0], x1
    ld1             {v16.s}[2], [x0], x1
    ld1             {v16.s}[3], [x0], x1
    ld1             {v17.s}[1], [x2], x3
    ld1             {v17.s}[2], [x2], x3
    ld1             {v17.s}[3], [x2], x3

    uabd            v1.16b, v16.16b, v17.16b
    udot            v0.4s, v1.16b, v1.16b
.endr
    addv            s0, v0.4s
    fmov            w0, s0
    ret
endfunc
.endm

SSE_PP_4xN 4
SSE_PP_4xN 8

// Fully unrolled.
.macro SSE_PP_8xN h
function PFX(pixel_sse_pp_8x\h\()_neon_dotprod)
    movi            v0.4s, #0
.rept \h
    ld1             {v16.8b}, [x0], x1
    ld1             {v17.8b}, [x2], x3

    uabd            v1.8b, v16.8b, v17.8b
    udot            v0.2s, v1.8b, v1.8b
.endr
    addv            s0, v0.4s
    fmov            w0, s0
    ret
endfunc
.endm

SSE_PP_8xN 8
SSE_PP_8xN 16

// Fully unrolled.
.macro SSE_PP_16xN h
function PFX(pixel_sse_pp_16x\h\()_neon_dotprod)
    movi            v0.4s, #0
    movi            v1.4s, #0
.rept \h / 2
    ld1             {v16.16b}, [x0], x1
    ld1             {v17.16b}, [x2], x3
    ld1             {v18.16b}, [x0], x1
    ld1             {v19.16b}, [x2], x3

    uabd            v2.16b, v16.16b, v17.16b
    udot            v0.4s, v2.16b, v2.16b
    uabd            v3.16b, v18.16b, v19.16b
    udot            v1.4s, v3.16b, v3.16b
.endr
    add             v0.4s, v0.4s, v1.4s
    addv            s0, v0.4s
    fmov            w0, s0
    ret
endfunc
.endm

SSE_PP_16xN 16
SSE_PP_16xN 32

// Loop unrolled to process 4 rows per iteration.
function PFX(pixel_sse_pp_32xh_neon_dotprod), export=0
    movi            v0.4s, #0
    movi            v1.4s, #0
.Loop_sse_pp_32xh:
    sub             w4, w4, #1
.rept 4
    ld1             {v16.16b,v17.16b}, [x0], x1
    ld1             {v18.16b,v19.16b}, [x2], x3

    uabd            v2.16b, v16.16b, v18.16b
    udot            v0.4s, v2.16b, v2.16b
    uabd            v3.16b, v17.16b, v19.16b
    udot            v1.4s, v3.16b, v3.16b
.endr
    cbnz            w4, .Loop_sse_pp_32xh
    add             v0.4s, v0.4s, v1.4s
    addv            s0, v0.4s
    fmov            w0, s0
    ret
endfunc

.macro SSE_PP_32xN h
function PFX(pixel_sse_pp_32x\h\()_neon_dotprod)
    mov             w4, \h / 4
    b               PFX(pixel_sse_pp_32xh_neon_dotprod)
endfunc
.endm

SSE_PP_32xN 32
SSE_PP_32xN 64

// Loop unrolled to process 4 rows per iteration.
function PFX(pixel_sse_pp_64x64_neon_dotprod)
    mov             w12, #16
    movi            v0.4s, #0
    movi            v1.4s, #0
.Loop_sse_pp_64:
    sub             w12, w12, #1
.rept 4
    ld1             {v16.16b-v19.16b}, [x0], x1
    ld1             {v20.16b-v23.16b}, [x2], x3

    uabd            v2.16b, v16.16b, v20.16b
    udot            v0.4s, v2.16b, v2.16b
    uabd            v3.16b, v17.16b, v21.16b
    udot            v1.4s, v3.16b, v3.16b
    uabd            v4.16b, v18.16b, v22.16b
    udot            v0.4s, v4.16b, v4.16b
    uabd            v5.16b, v19.16b, v23.16b
    udot            v1.4s, v5.16b, v5.16b
.endr
    cbnz            w12, .Loop_sse_pp_64
    add             v0.4s, v0.4s, v1.4s
    addv            s0, v0.4s
    fmov            w0, s0
    ret
endfunc
