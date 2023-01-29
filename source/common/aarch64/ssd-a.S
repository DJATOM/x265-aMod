/*****************************************************************************
 * Copyright (C) 2021 MulticoreWare, Inc
 *
 * Authors: Sebastian Pop <spop@amazon.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111, USA.
 *
 * This program is also available under a commercial proprietary license.
 * For more information, contact us at license @ x265.com.
 *****************************************************************************/

#include "asm.S"

.arch armv8-a+sve2

#ifdef __APPLE__
.section __RODATA,__rodata
#else
.section .rodata
#endif

.align 4

.text

//############### NEON #################

.macro ret_v0_w0
    trn2            v1.2d, v0.2d, v0.2d
    add             v0.2s, v0.2s, v1.2s
    addp            v0.2s, v0.2s, v0.2s
    fmov            w0, s0
    ret
.endm

function PFX(pixel_sse_pp_4x4_neon)
    ld1             {v16.s}[0], [x0], x1
    ld1             {v17.s}[0], [x2], x3
    ld1             {v18.s}[0], [x0], x1
    ld1             {v19.s}[0], [x2], x3
    ld1             {v20.s}[0], [x0], x1
    ld1             {v21.s}[0], [x2], x3
    ld1             {v22.s}[0], [x0], x1
    ld1             {v23.s}[0], [x2], x3

    usubl           v1.8h, v16.8b, v17.8b
    usubl           v2.8h, v18.8b, v19.8b
    usubl           v3.8h, v20.8b, v21.8b
    usubl           v4.8h, v22.8b, v23.8b

    smull           v0.4s, v1.4h, v1.4h
    smlal           v0.4s, v2.4h, v2.4h
    smlal           v0.4s, v3.4h, v3.4h
    smlal           v0.4s, v4.4h, v4.4h
    ret_v0_w0
endfunc

function PFX(pixel_sse_pp_4x8_neon)
    ld1             {v16.s}[0], [x0], x1
    ld1             {v17.s}[0], [x2], x3
    usubl           v1.8h, v16.8b, v17.8b
    ld1             {v16.s}[0], [x0], x1
    ld1             {v17.s}[0], [x2], x3
    smull           v0.4s, v1.4h, v1.4h
.rept 6
    usubl           v1.8h, v16.8b, v17.8b
    ld1             {v16.s}[0], [x0], x1
    smlal           v0.4s, v1.4h, v1.4h
    ld1             {v17.s}[0], [x2], x3
.endr
    usubl           v1.8h, v16.8b, v17.8b
    smlal           v0.4s, v1.4h, v1.4h
    ret_v0_w0
endfunc

function PFX(pixel_sse_pp_8x8_neon)
    ld1             {v16.8b}, [x0], x1
    ld1             {v17.8b}, [x2], x3
    usubl           v1.8h, v16.8b, v17.8b
    ld1             {v16.8b}, [x0], x1
    smull           v0.4s, v1.4h, v1.4h
    smlal2          v0.4s, v1.8h, v1.8h
    ld1             {v17.8b}, [x2], x3

.rept 6
    usubl           v1.8h, v16.8b, v17.8b
    ld1             {v16.8b}, [x0], x1
    smlal           v0.4s, v1.4h, v1.4h
    smlal2          v0.4s, v1.8h, v1.8h
    ld1             {v17.8b}, [x2], x3
.endr
    usubl           v1.8h, v16.8b, v17.8b
    smlal           v0.4s, v1.4h, v1.4h
    smlal2          v0.4s, v1.8h, v1.8h
    ret_v0_w0
endfunc

function PFX(pixel_sse_pp_8x16_neon)
    ld1             {v16.8b}, [x0], x1
    ld1             {v17.8b}, [x2], x3
    usubl           v1.8h, v16.8b, v17.8b
    ld1             {v16.8b}, [x0], x1
    smull           v0.4s, v1.4h, v1.4h
    smlal2          v0.4s, v1.8h, v1.8h
    ld1             {v17.8b}, [x2], x3

.rept 14
    usubl           v1.8h, v16.8b, v17.8b
    ld1             {v16.8b}, [x0], x1
    smlal           v0.4s, v1.4h, v1.4h
    smlal2          v0.4s, v1.8h, v1.8h
    ld1             {v17.8b}, [x2], x3
.endr
    usubl           v1.8h, v16.8b, v17.8b
    smlal           v0.4s, v1.4h, v1.4h
    smlal2          v0.4s, v1.8h, v1.8h
    ret_v0_w0
endfunc

.macro sse_pp_16xN_neon h
function PFX(pixel_sse_pp_16x\h\()_neon)
    ld1             {v16.16b}, [x0], x1
    ld1             {v17.16b}, [x2], x3
    usubl           v1.8h, v16.8b, v17.8b
    usubl2          v2.8h, v16.16b, v17.16b
    ld1             {v16.16b}, [x0], x1
    ld1             {v17.16b}, [x2], x3
    smull           v0.4s, v1.4h, v1.4h
    smlal2          v0.4s, v1.8h, v1.8h
    smlal           v0.4s, v2.4h, v2.4h
    smlal2          v0.4s, v2.8h, v2.8h
.rept \h - 2
    usubl           v1.8h, v16.8b, v17.8b
    usubl2          v2.8h, v16.16b, v17.16b
    ld1             {v16.16b}, [x0], x1
    smlal           v0.4s, v1.4h, v1.4h
    smlal2          v0.4s, v1.8h, v1.8h
    ld1             {v17.16b}, [x2], x3
    smlal           v0.4s, v2.4h, v2.4h
    smlal2          v0.4s, v2.8h, v2.8h
.endr
    usubl           v1.8h, v16.8b, v17.8b
    usubl2          v2.8h, v16.16b, v17.16b
    smlal           v0.4s, v1.4h, v1.4h
    smlal2          v0.4s, v1.8h, v1.8h
    smlal           v0.4s, v2.4h, v2.4h
    smlal2          v0.4s, v2.8h, v2.8h
    ret_v0_w0
endfunc
.endm

sse_pp_16xN_neon 16
sse_pp_16xN_neon 32

function PFX(pixel_sse_pp_32x32_neon)
    mov             w12, #8
    movi            v0.16b, #0
    movi            v1.16b, #0
.loop_sse_pp_32:
    sub             w12, w12, #1
.rept 4
    ld1             {v16.16b,v17.16b}, [x0], x1
    ld1             {v18.16b,v19.16b}, [x2], x3
    usubl           v2.8h, v16.8b, v18.8b
    usubl2          v3.8h, v16.16b, v18.16b
    usubl           v4.8h, v17.8b, v19.8b
    usubl2          v5.8h, v17.16b, v19.16b
    smlal           v0.4s, v2.4h, v2.4h
    smlal2          v1.4s, v2.8h, v2.8h
    smlal           v0.4s, v3.4h, v3.4h
    smlal2          v1.4s, v3.8h, v3.8h
    smlal           v0.4s, v4.4h, v4.4h
    smlal2          v1.4s, v4.8h, v4.8h
    smlal           v0.4s, v5.4h, v5.4h
    smlal2          v1.4s, v5.8h, v5.8h
.endr
    cbnz            w12, .loop_sse_pp_32
    add             v0.4s, v0.4s, v1.4s
    ret_v0_w0
endfunc

function PFX(pixel_sse_pp_32x64_neon)
    mov             w12, #16
    movi            v0.16b, #0
    movi            v1.16b, #0
.loop_sse_pp_32x64:
    sub             w12, w12, #1
.rept 4
    ld1             {v16.16b,v17.16b}, [x0], x1
    ld1             {v18.16b,v19.16b}, [x2], x3
    usubl           v2.8h, v16.8b, v18.8b
    usubl2          v3.8h, v16.16b, v18.16b
    usubl           v4.8h, v17.8b, v19.8b
    usubl2          v5.8h, v17.16b, v19.16b
    smlal           v0.4s, v2.4h, v2.4h
    smlal2          v1.4s, v2.8h, v2.8h
    smlal           v0.4s, v3.4h, v3.4h
    smlal2          v1.4s, v3.8h, v3.8h
    smlal           v0.4s, v4.4h, v4.4h
    smlal2          v1.4s, v4.8h, v4.8h
    smlal           v0.4s, v5.4h, v5.4h
    smlal2          v1.4s, v5.8h, v5.8h
.endr
    cbnz            w12, .loop_sse_pp_32x64
    add             v0.4s, v0.4s, v1.4s
    ret_v0_w0
endfunc

function PFX(pixel_sse_pp_64x64_neon)
    mov             w12, #16
    movi            v0.16b, #0
    movi            v1.16b, #0

.loop_sse_pp_64:
    sub             w12, w12, #1
.rept 4
    ld1             {v16.16b-v19.16b}, [x0], x1
    ld1             {v20.16b-v23.16b}, [x2], x3

    usubl           v2.8h, v16.8b, v20.8b
    usubl2          v3.8h, v16.16b, v20.16b
    usubl           v4.8h, v17.8b, v21.8b
    usubl2          v5.8h, v17.16b, v21.16b
    smlal           v0.4s, v2.4h, v2.4h
    smlal2          v1.4s, v2.8h, v2.8h
    smlal           v0.4s, v3.4h, v3.4h
    smlal2          v1.4s, v3.8h, v3.8h
    smlal           v0.4s, v4.4h, v4.4h
    smlal2          v1.4s, v4.8h, v4.8h
    smlal           v0.4s, v5.4h, v5.4h
    smlal2          v1.4s, v5.8h, v5.8h

    usubl           v2.8h, v18.8b, v22.8b
    usubl2          v3.8h, v18.16b, v22.16b
    usubl           v4.8h, v19.8b, v23.8b
    usubl2          v5.8h, v19.16b, v23.16b
    smlal           v0.4s, v2.4h, v2.4h
    smlal2          v1.4s, v2.8h, v2.8h
    smlal           v0.4s, v3.4h, v3.4h
    smlal2          v1.4s, v3.8h, v3.8h
    smlal           v0.4s, v4.4h, v4.4h
    smlal2          v1.4s, v4.8h, v4.8h
    smlal           v0.4s, v5.4h, v5.4h
    smlal2          v1.4s, v5.8h, v5.8h
.endr
    cbnz            w12, .loop_sse_pp_64
    add             v0.4s, v0.4s, v1.4s
    ret_v0_w0
endfunc

function PFX(pixel_sse_ss_4x4_neon)
    add             x1, x1, x1
    add             x3, x3, x3
    ld1             {v16.8b}, [x0], x1
    ld1             {v17.8b}, [x2], x3
    sub             v2.4h, v16.4h, v17.4h
    ld1             {v16.8b}, [x0], x1
    ld1             {v17.8b}, [x2], x3
    smull           v0.4s, v2.4h, v2.4h
    sub             v2.4h, v16.4h, v17.4h
    ld1             {v16.8b}, [x0], x1
    ld1             {v17.8b}, [x2], x3
    smlal           v0.4s, v2.4h, v2.4h
    sub             v2.4h, v16.4h, v17.4h
    ld1             {v16.8b}, [x0], x1
    smlal           v0.4s, v2.4h, v2.4h
    ld1             {v17.8b}, [x2], x3
    sub             v2.4h, v16.4h, v17.4h
    smlal           v0.4s, v2.4h, v2.4h
    ret_v0_w0
endfunc

function PFX(pixel_sse_ss_8x8_neon)
    add             x1, x1, x1
    add             x3, x3, x3
    ld1             {v16.16b}, [x0], x1
    ld1             {v17.16b}, [x2], x3
    sub             v2.8h, v16.8h, v17.8h
    ld1             {v16.16b}, [x0], x1
    ld1             {v17.16b}, [x2], x3
    smull           v0.4s, v2.4h, v2.4h
    smull2          v1.4s, v2.8h, v2.8h
    sub             v2.8h, v16.8h, v17.8h
.rept 6
    ld1             {v16.16b}, [x0], x1
    ld1             {v17.16b}, [x2], x3
    smlal           v0.4s, v2.4h, v2.4h
    smlal2          v1.4s, v2.8h, v2.8h
    sub             v2.8h, v16.8h, v17.8h
.endr
    smlal           v0.4s, v2.4h, v2.4h
    smlal2          v1.4s, v2.8h, v2.8h
    add             v0.4s, v0.4s, v1.4s
    ret_v0_w0
endfunc

function PFX(pixel_sse_ss_16x16_neon)
    add             x1, x1, x1
    add             x3, x3, x3
    mov             w12, #4
    movi            v0.16b, #0
    movi            v1.16b, #0
.loop_sse_ss_16:
    sub             w12, w12, #1
.rept 4
    ld1             {v16.16b, v17.16b}, [x0], x1
    ld1             {v18.16b, v19.16b}, [x2], x3
    sub             v2.8h, v16.8h, v18.8h
    sub             v3.8h, v17.8h, v19.8h
    smlal           v0.4s, v2.4h, v2.4h
    smlal2          v1.4s, v2.8h, v2.8h
    smlal           v0.4s, v3.4h, v3.4h
    smlal2          v1.4s, v3.8h, v3.8h
.endr
    cbnz            w12, .loop_sse_ss_16
    add             v0.4s, v0.4s, v1.4s
    ret_v0_w0
endfunc

function PFX(pixel_sse_ss_32x32_neon)
    add             x1, x1, x1
    add             x3, x3, x3

    mov             w12, #8
    movi            v0.16b, #0
    movi            v1.16b, #0
.loop_sse_ss_32:
    sub             w12, w12, #1
.rept 4
    ld1             {v16.16b-v19.16b}, [x0], x1
    ld1             {v20.16b-v23.16b}, [x2], x3
    sub             v2.8h, v16.8h, v20.8h
    sub             v3.8h, v17.8h, v21.8h
    sub             v4.8h, v18.8h, v22.8h
    sub             v5.8h, v19.8h, v23.8h
    smlal           v0.4s, v2.4h, v2.4h
    smlal2          v1.4s, v2.8h, v2.8h
    smlal           v0.4s, v3.4h, v3.4h
    smlal2          v1.4s, v3.8h, v3.8h
    smlal           v0.4s, v4.4h, v4.4h
    smlal2          v1.4s, v4.8h, v4.8h
    smlal           v0.4s, v5.4h, v5.4h
    smlal2          v1.4s, v5.8h, v5.8h
.endr
    cbnz            w12, .loop_sse_ss_32
    add             v0.4s, v0.4s, v1.4s
    ret_v0_w0
endfunc

function PFX(pixel_sse_ss_64x64_neon)
    add             x1, x1, x1
    add             x3, x3, x3
    sub             x1, x1, #64
    sub             x3, x3, #64

    mov             w12, #32
    movi            v0.16b, #0
    movi            v1.16b, #0
.loop_sse_ss_64:
    sub             w12, w12, #1
.rept 2
    ld1             {v16.16b-v19.16b}, [x0], #64
    ld1             {v20.16b-v23.16b}, [x2], #64
    sub             v2.8h, v16.8h, v20.8h
    sub             v3.8h, v17.8h, v21.8h
    sub             v4.8h, v18.8h, v22.8h
    sub             v5.8h, v19.8h, v23.8h
    ld1             {v16.16b-v19.16b}, [x0], x1
    ld1             {v20.16b-v23.16b}, [x2], x3
    smlal           v0.4s, v2.4h, v2.4h
    smlal2          v1.4s, v2.8h, v2.8h
    smlal           v0.4s, v3.4h, v3.4h
    smlal2          v1.4s, v3.8h, v3.8h
    smlal           v0.4s, v4.4h, v4.4h
    smlal2          v1.4s, v4.8h, v4.8h
    smlal           v0.4s, v5.4h, v5.4h
    smlal2          v1.4s, v5.8h, v5.8h
    sub             v2.8h, v16.8h, v20.8h
    sub             v3.8h, v17.8h, v21.8h
    sub             v4.8h, v18.8h, v22.8h
    sub             v5.8h, v19.8h, v23.8h
    smlal           v0.4s, v2.4h, v2.4h
    smlal2          v1.4s, v2.8h, v2.8h
    smlal           v0.4s, v3.4h, v3.4h
    smlal2          v1.4s, v3.8h, v3.8h
    smlal           v0.4s, v4.4h, v4.4h
    smlal2          v1.4s, v4.8h, v4.8h
    smlal           v0.4s, v5.4h, v5.4h
    smlal2          v1.4s, v5.8h, v5.8h
.endr
    cbnz            w12, .loop_sse_ss_64
    add             v0.4s, v0.4s, v1.4s
    ret_v0_w0
endfunc

function PFX(pixel_ssd_s_4x4_neon)
    add             x1, x1, x1
    ld1             {v4.8b}, [x0], x1
    ld1             {v5.8b}, [x0], x1
    ld1             {v6.8b}, [x0], x1
    ld1             {v7.8b}, [x0]
    smull           v0.4s, v4.4h, v4.4h
    smull           v1.4s, v5.4h, v5.4h
    smlal           v0.4s, v6.4h, v6.4h
    smlal           v1.4s, v7.4h, v7.4h
    add             v0.4s, v0.4s, v1.4s
    ret_v0_w0
endfunc

function PFX(pixel_ssd_s_8x8_neon)
    add             x1, x1, x1
    ld1             {v4.16b}, [x0], x1
    ld1             {v5.16b}, [x0], x1
    smull           v0.4s, v4.4h, v4.4h
    smull2          v1.4s, v4.8h, v4.8h
    smlal           v0.4s, v5.4h, v5.4h
    smlal2          v1.4s, v5.8h, v5.8h
.rept 3
    ld1             {v4.16b}, [x0], x1
    ld1             {v5.16b}, [x0], x1
    smlal           v0.4s, v4.4h, v4.4h
    smlal2          v1.4s, v4.8h, v4.8h
    smlal           v0.4s, v5.4h, v5.4h
    smlal2          v1.4s, v5.8h, v5.8h
.endr
    add             v0.4s, v0.4s, v1.4s
    ret_v0_w0
endfunc

function PFX(pixel_ssd_s_16x16_neon)
    add             x1, x1, x1
    mov             w12, #4
    movi            v0.16b, #0
    movi            v1.16b, #0
.loop_ssd_s_16:
    sub             w12, w12, #1
.rept 2
    ld1             {v4.16b,v5.16b}, [x0], x1
    ld1             {v6.16b,v7.16b}, [x0], x1
    smlal           v0.4s, v4.4h, v4.4h
    smlal2          v1.4s, v4.8h, v4.8h
    smlal           v0.4s, v5.4h, v5.4h
    smlal2          v1.4s, v5.8h, v5.8h
    smlal           v0.4s, v6.4h, v6.4h
    smlal2          v1.4s, v6.8h, v6.8h
    smlal           v0.4s, v7.4h, v7.4h
    smlal2          v1.4s, v7.8h, v7.8h
.endr
    cbnz            w12, .loop_ssd_s_16
    add             v0.4s, v0.4s, v1.4s
    ret_v0_w0
endfunc

function PFX(pixel_ssd_s_32x32_neon)
    add             x1, x1, x1
    mov             w12, #8
    movi            v0.16b, #0
    movi            v1.16b, #0
.loop_ssd_s_32:
    sub             w12, w12, #1
.rept 4
    ld1             {v4.16b-v7.16b}, [x0], x1
    smlal           v0.4s, v4.4h, v4.4h
    smlal2          v1.4s, v4.8h, v4.8h
    smlal           v0.4s, v5.4h, v5.4h
    smlal2          v1.4s, v5.8h, v5.8h
    smlal           v0.4s, v6.4h, v6.4h
    smlal2          v1.4s, v6.8h, v6.8h
    smlal           v0.4s, v7.4h, v7.4h
    smlal2          v1.4s, v7.8h, v7.8h
.endr
    cbnz            w12, .loop_ssd_s_32
    add             v0.4s, v0.4s, v1.4s
    ret_v0_w0
endfunc

// ################  SVE2 ######################

function PFX(pixel_sse_pp_4x4_sve2)
    ptrue           p0.s, vl4
    ld1b            {z0.s}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z17.s}, p0/z, [x2]
    add             x2, x2, x3
    sub             z0.s, p0/m, z0.s, z17.s
    mul             z0.s, p0/m, z0.s, z0.s
.rept 3
    ld1b            {z16.s}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z17.s}, p0/z, [x2]
    add             x2, x2, x3
    sub             z16.s, p0/m, z16.s, z17.s
    mla             z0.s, p0/m, z16.s, z16.s
.endr
    uaddv           d0, p0, z0.s
    fmov            w0, s0
    ret
endfunc

function PFX(pixel_sse_pp_4x8_sve2)
    ptrue           p0.s, vl4
    ld1b            {z0.s}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z17.s}, p0/z, [x2]
    add             x2, x2, x3
    sub             z0.s, p0/m, z0.s, z17.s
    mul             z0.s, p0/m, z0.s, z0.s
.rept 7
    ld1b            {z16.s}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z17.s}, p0/z, [x2]
    add             x2, x2, x3
    sub             z16.s, p0/m, z16.s, z17.s
    mla             z0.s, p0/m, z16.s, z16.s
.endr
    uaddv           d0, p0, z0.s
    fmov            w0, s0
    ret
endfunc

function PFX(pixel_sse_pp_8x8_sve2)
    ptrue           p0.b, vl8
    mov             z3.d, #0
    mov             z4.d, #0
.rept 8
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z17.b}, p0/z, [x2]
    add             x2, x2, x3
    usublb          z1.h, z16.b, z17.b
    usublt          z2.h, z16.b, z17.b
    smlalb          z3.s, z1.h, z1.h
    smlalt          z4.s, z1.h, z1.h
    smlalb          z3.s, z2.h, z2.h
    smlalt          z4.s, z2.h, z2.h
.endr
    uaddv           d3, p0, z3.s
    fmov            w0, s3
    uaddv           d4, p0, z4.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
endfunc

function PFX(pixel_sse_pp_8x16_sve2)
    ptrue           p0.b, vl8
    mov             z3.d, #0
    mov             z4.d, #0
.rept 16
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z17.b}, p0/z, [x2]
    add             x2, x2, x3
    usublb          z1.h, z16.b, z17.b
    usublt          z2.h, z16.b, z17.b
    smlalb          z3.s, z1.h, z1.h
    smlalt          z4.s, z1.h, z1.h
    smlalb          z3.s, z2.h, z2.h
    smlalt          z4.s, z2.h, z2.h
.endr
    uaddv           d3, p0, z3.s
    fmov            w0, s3
    uaddv           d4, p0, z4.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
endfunc

.macro sse_pp_16xN_sve2 h
function PFX(pixel_sse_pp_16x\h\()_sve2)
    ptrue           p0.b, vl16
    mov             z3.d, #0
    mov             z4.d, #0
.rept \h
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z17.b}, p0/z, [x2]
    add             x2, x2, x3
    usublb          z1.h, z16.b, z17.b
    usublt          z2.h, z16.b, z17.b
    smlalb          z3.s, z1.h, z1.h
    smlalt          z4.s, z1.h, z1.h
    smlalb          z3.s, z2.h, z2.h
    smlalt          z4.s, z2.h, z2.h
.endr
    uaddv           d3, p0, z3.s
    fmov            w0, s3
    uaddv           d4, p0, z4.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
endfunc
.endm

sse_pp_16xN_sve2 16
sse_pp_16xN_sve2 32

function PFX(pixel_sse_pp_32x32_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sse_pp_32x32
    ptrue           p0.b, vl16
    mov             z20.d, #0
    mov             z21.d, #0
    mov             x11, #16
.rept 32
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, x11]
    add             x0, x0, x1
    ld1b            {z18.b}, p0/z, [x2]
    ld1b            {z19.b}, p0/z, [x2, x11]
    add             x2, x2, x3
    usublb          z1.h, z16.b, z18.b
    usublt          z2.h, z16.b, z18.b
    usublb          z3.h, z17.b, z19.b
    usublt          z4.h, z17.b, z19.b
    smlalb          z20.s, z1.h, z1.h
    smlalt          z21.s, z1.h, z1.h
    smlalb          z20.s, z2.h, z2.h
    smlalt          z21.s, z2.h, z2.h
    smlalb          z20.s, z3.h, z3.h
    smlalt          z21.s, z3.h, z3.h
    smlalb          z20.s, z4.h, z4.h
    smlalt          z21.s, z4.h, z4.h
.endr
    uaddv           d3, p0, z20.s
    fmov            w0, s3
    uaddv           d4, p0, z21.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
.vl_gt_16_pixel_sse_pp_32x32:
    ptrue           p0.b, vl32
    mov             z20.d, #0
    mov             z21.d, #0
.rept 32
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z18.b}, p0/z, [x2]
    add             x2, x2, x3
    usublb          z1.h, z16.b, z18.b
    usublt          z2.h, z16.b, z18.b
    smlalb          z20.s, z1.h, z1.h
    smlalt          z21.s, z1.h, z1.h
    smlalb          z20.s, z2.h, z2.h
    smlalt          z21.s, z2.h, z2.h
.endr
    uaddv           d3, p0, z20.s
    fmov            w0, s3
    uaddv           d4, p0, z21.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
endfunc

function PFX(pixel_sse_pp_32x64_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sse_pp_32x64
    ptrue           p0.b, vl16
    mov             z20.d, #0
    mov             z21.d, #0
    mov             x11, #16
.rept 64
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, x11]
    add             x0, x0, x1
    ld1b            {z18.b}, p0/z, [x2]
    ld1b            {z19.b}, p0/z, [x2, x11]
    add             x2, x2, x3
    usublb          z1.h, z16.b, z18.b
    usublt          z2.h, z16.b, z18.b
    usublb          z3.h, z17.b, z19.b
    usublt          z4.h, z17.b, z19.b
    smlalb          z20.s, z1.h, z1.h
    smlalt          z21.s, z1.h, z1.h
    smlalb          z20.s, z2.h, z2.h
    smlalt          z21.s, z2.h, z2.h
    smlalb          z20.s, z3.h, z3.h
    smlalt          z21.s, z3.h, z3.h
    smlalb          z20.s, z4.h, z4.h
    smlalt          z21.s, z4.h, z4.h
.endr
    uaddv           d3, p0, z20.s
    fmov            w0, s3
    uaddv           d4, p0, z21.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
.vl_gt_16_pixel_sse_pp_32x64:
    ptrue           p0.b, vl32
    mov             z20.d, #0
    mov             z21.d, #0
.rept 64
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z18.b}, p0/z, [x2]
    add             x2, x2, x3
    usublb          z1.h, z16.b, z18.b
    usublt          z2.h, z16.b, z18.b
    smlalb          z20.s, z1.h, z1.h
    smlalt          z21.s, z1.h, z1.h
    smlalb          z20.s, z2.h, z2.h
    smlalt          z21.s, z2.h, z2.h
.endr
    uaddv           d3, p0, z20.s
    fmov            w0, s3
    uaddv           d4, p0, z21.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
endfunc

function PFX(pixel_sse_pp_64x64_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sse_pp_64x64
    ptrue           p0.b, vl16
    mov             z24.d, #0
    mov             z25.d, #0
.rept 64
    mov             x11, #16
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, x11]
    add             x11, x11, #16
    ld1b            {z18.b}, p0/z, [x0, x11]
    add             x11, x11, #16
    ld1b            {z19.b}, p0/z, [x0, x11]
    add             x0, x0, x1
    mov             x11, #16
    ld1b            {z20.b}, p0/z, [x2]
    ld1b            {z21.b}, p0/z, [x2, x11]
    add             x11, x11, #16
    ld1b            {z22.b}, p0/z, [x2, x11]
    add             x11, x11, #16
    ld1b            {z23.b}, p0/z, [x2, x11]
    add             x2, x2, x3
    usublb          z1.h, z16.b, z20.b
    usublt          z2.h, z16.b, z20.b
    usublb          z3.h, z17.b, z21.b
    usublt          z4.h, z17.b, z21.b
    usublb          z5.h, z18.b, z22.b
    usublt          z6.h, z18.b, z22.b
    usublb          z7.h, z19.b, z23.b
    usublt          z8.h, z19.b, z23.b
    smlalb          z24.s, z1.h, z1.h
    smlalt          z25.s, z1.h, z1.h
    smlalb          z24.s, z2.h, z2.h
    smlalt          z25.s, z2.h, z2.h
    smlalb          z24.s, z3.h, z3.h
    smlalt          z25.s, z3.h, z3.h
    smlalb          z24.s, z4.h, z4.h
    smlalt          z25.s, z4.h, z4.h
    smlalb          z24.s, z5.h, z5.h
    smlalt          z25.s, z5.h, z5.h
    smlalb          z24.s, z6.h, z6.h
    smlalt          z25.s, z6.h, z6.h
    smlalb          z24.s, z7.h, z7.h
    smlalt          z25.s, z7.h, z7.h
    smlalb          z24.s, z8.h, z8.h
    smlalt          z25.s, z8.h, z8.h
.endr
    uaddv           d3, p0, z24.s
    fmov            w0, s3
    uaddv           d4, p0, z25.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
.vl_gt_16_pixel_sse_pp_64x64:
    cmp             x9, #48
    bgt             .vl_gt_48_pixel_sse_pp_64x64
    ptrue           p0.b, vl32
    mov             x11, #32
    mov             z24.d, #0
    mov             z25.d, #0
.rept 64
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, x11]
    add             x0, x0, x1
    ld1b            {z20.b}, p0/z, [x2]
    ld1b            {z21.b}, p0/z, [x2, x11]
    add             x2, x2, x3
    usublb          z1.h, z16.b, z20.b
    usublt          z2.h, z16.b, z20.b
    usublb          z3.h, z17.b, z21.b
    usublt          z4.h, z17.b, z21.b
    smlalb          z24.s, z1.h, z1.h
    smlalt          z25.s, z1.h, z1.h
    smlalb          z24.s, z2.h, z2.h
    smlalt          z25.s, z2.h, z2.h
    smlalb          z24.s, z3.h, z3.h
    smlalt          z25.s, z3.h, z3.h
    smlalb          z24.s, z4.h, z4.h
    smlalt          z25.s, z4.h, z4.h
.endr
    uaddv           d3, p0, z24.s
    fmov            w0, s3
    uaddv           d4, p0, z25.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
.vl_gt_48_pixel_sse_pp_64x64:
    ptrue           p0.b, vl64
    mov             z24.d, #0
    mov             z25.d, #0
.rept 64
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z20.b}, p0/z, [x2]
    add             x2, x2, x3
    usublb          z1.h, z16.b, z20.b
    usublt          z2.h, z16.b, z20.b
    smlalb          z24.s, z1.h, z1.h
    smlalt          z25.s, z1.h, z1.h
    smlalb          z24.s, z2.h, z2.h
    smlalt          z25.s, z2.h, z2.h
.endr
    uaddv           d3, p0, z24.s
    fmov            w0, s3
    uaddv           d4, p0, z25.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
endfunc

function PFX(pixel_sse_ss_4x4_sve2)
    ptrue           p0.b, vl8
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1, lsl #1
    ld1b            {z17.b}, p0/z, [x2]
    add             x2, x2, x3, lsl #1
    sub             z1.h, z16.h, z17.h
    smullb          z3.s, z1.h, z1.h
    smullt          z4.s, z1.h, z1.h
.rept 3
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1, lsl #1
    ld1b            {z17.b}, p0/z, [x2]
    add             x2, x2, x3, lsl #1
    sub             z1.h, z16.h, z17.h
    smlalb          z3.s, z1.h, z1.h
    smlalt          z4.s, z1.h, z1.h
.endr
    uaddv           d3, p0, z3.s
    fmov            w0, s3
    uaddv           d4, p0, z4.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
endfunc

function PFX(pixel_sse_ss_8x8_sve2)
    ptrue           p0.b, vl16
    mov             z3.d, #0
    mov             z4.d, #0
.rept 8
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1, lsl #1
    ld1b            {z17.b}, p0/z, [x2]
    add             x2, x2, x3, lsl #1
    sub             z1.h, z16.h, z17.h
    smlalb          z3.s, z1.h, z1.h
    smlalt          z4.s, z1.h, z1.h
.endr
    uaddv           d3, p0, z3.s
    fmov            w0, s3
    uaddv           d4, p0, z4.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
endfunc

function PFX(pixel_sse_ss_16x16_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sse_ss_16x16
    ptrue           p0.b, vl16
    mov             z3.d, #0
    mov             z4.d, #0
    mov             x11, #16
.rept 16
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, x11]
    add             x0, x0, x1, lsl #1
    ld1b            {z18.b}, p0/z, [x2]
    ld1b            {z19.b}, p0/z, [x2, x11]
    add             x2, x2, x3, lsl #1
    sub             z1.h, z16.h, z18.h
    sub             z2.h, z17.h, z19.h
    smlalb          z3.s, z1.h, z1.h
    smlalt          z4.s, z1.h, z1.h
    smlalb          z3.s, z2.h, z2.h
    smlalt          z4.s, z2.h, z2.h
.endr
    uaddv           d3, p0, z3.s
    fmov            w0, s3
    uaddv           d4, p0, z4.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
.vl_gt_16_pixel_sse_ss_16x16:
    ptrue           p0.b, vl32
    mov             z3.d, #0
    mov             z4.d, #0
.rept 16
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1, lsl #1
    ld1b            {z18.b}, p0/z, [x2]
    add             x2, x2, x3, lsl #1
    sub             z1.h, z16.h, z18.h
    smlalb          z3.s, z1.h, z1.h
    smlalt          z4.s, z1.h, z1.h
.endr
    uaddv           d3, p0, z3.s
    fmov            w0, s3
    uaddv           d4, p0, z4.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
endfunc

function PFX(pixel_sse_ss_32x32_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sse_ss_32x32
    ptrue           p0.b, vl16
    mov             z5.d, #0
    mov             z6.d, #0
.rept 32
    mov             x11, #16
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, x11]
    add             x11, x11, #16
    ld1b            {z18.b}, p0/z, [x0, x11]
    add             x11, x11, #16
    ld1b            {z19.b}, p0/z, [x0, x11]
    add             x0, x0, x1, lsl #1
    mov             x11, #16
    ld1b            {z20.b}, p0/z, [x2]
    ld1b            {z21.b}, p0/z, [x2, x11]
    add             x11, x11, #16
    ld1b            {z22.b}, p0/z, [x2, x11]
    add             x11, x11, #16
    ld1b            {z23.b}, p0/z, [x2, x11]
    add             x2, x2, x3, lsl #1
    sub             z1.h, z16.h, z20.h
    sub             z2.h, z17.h, z21.h
    sub             z3.h, z18.h, z22.h
    sub             z4.h, z19.h, z23.h
    smlalb          z5.s, z1.h, z1.h
    smlalt          z6.s, z1.h, z1.h
    smlalb          z5.s, z2.h, z2.h
    smlalt          z6.s, z2.h, z2.h
    smlalb          z5.s, z3.h, z3.h
    smlalt          z6.s, z3.h, z3.h
    smlalb          z5.s, z4.h, z4.h
    smlalt          z6.s, z4.h, z4.h
.endr
    uaddv           d3, p0, z5.s
    fmov            w0, s3
    uaddv           d4, p0, z6.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
.vl_gt_16_pixel_sse_ss_32x32:
    cmp             x9, #48
    bgt             .vl_gt_48_pixel_sse_ss_32x32
    ptrue           p0.b, vl32
    mov             z5.d, #0
    mov             z6.d, #0
    mov             x11, #32
.rept 32
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, x11]
    add             x0, x0, x1, lsl #1
    ld1b            {z20.b}, p0/z, [x2]
    ld1b            {z21.b}, p0/z, [x2, x11]
    add             x2, x2, x3, lsl #1
    sub             z1.h, z16.h, z20.h
    sub             z2.h, z17.h, z21.h
    smlalb          z5.s, z1.h, z1.h
    smlalt          z6.s, z1.h, z1.h
    smlalb          z5.s, z2.h, z2.h
    smlalt          z6.s, z2.h, z2.h
.endr
    uaddv           d3, p0, z5.s
    fmov            w0, s3
    uaddv           d4, p0, z6.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
.vl_gt_48_pixel_sse_ss_32x32:
    ptrue           p0.b, vl64
    mov             z5.d, #0
    mov             z6.d, #0
.rept 32
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1, lsl #1
    ld1b            {z20.b}, p0/z, [x2]
    add             x2, x2, x3, lsl #1
    sub             z1.h, z16.h, z20.h
    smlalb          z5.s, z1.h, z1.h
    smlalt          z6.s, z1.h, z1.h
.endr
    uaddv           d3, p0, z5.s
    fmov            w0, s3
    uaddv           d4, p0, z6.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
endfunc

function PFX(pixel_sse_ss_64x64_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sse_ss_64x64
    ptrue           p0.b, vl16
    mov             z5.d, #0
    mov             z6.d, #0
.rept 64
    mov             x11, #16
    ld1b            {z24.b}, p0/z, [x0]
    ld1b            {z25.b}, p0/z, [x0, x11]
    add             x11, x11, #16
    ld1b            {z26.b}, p0/z, [x0, x11]
    add             x11, x11, #16
    ld1b            {z27.b}, p0/z, [x0, x11]
    mov             x12, #16
    ld1b            {z28.b}, p0/z, [x2]
    ld1b            {z29.b}, p0/z, [x2, x12]
    add             x12, x12, #16
    ld1b            {z30.b}, p0/z, [x2, x12]
    add             x12, x12, #16
    ld1b            {z31.b}, p0/z, [x2, x12]
    sub             z0.h, z24.h, z28.h
    sub             z1.h, z25.h, z29.h
    sub             z2.h, z26.h, z30.h
    sub             z3.h, z27.h, z31.h
    smlalb          z5.s, z0.h, z0.h
    smlalt          z6.s, z0.h, z0.h
    smlalb          z5.s, z1.h, z1.h
    smlalt          z6.s, z1.h, z1.h
    smlalb          z5.s, z2.h, z2.h
    smlalt          z6.s, z2.h, z2.h
    smlalb          z5.s, z3.h, z3.h
    smlalt          z6.s, z3.h, z3.h
    add             x11, x11, #16
    ld1b            {z24.b}, p0/z, [x0, x11]
    add             x11, x11, #16
    ld1b            {z25.b}, p0/z, [x0, x11]
    add             x11, x11, #16
    ld1b            {z26.b}, p0/z, [x0, x11]
    add             x11, x11, #16
    ld1b            {z27.b}, p0/z, [x0, x11]
    add             x12, x12, #16
    ld1b            {z28.b}, p0/z, [x2, x12]
    add             x12, x12, #16
    ld1b            {z29.b}, p0/z, [x2, x12]
    add             x12, x12, #16
    ld1b            {z30.b}, p0/z, [x2, x12]
    add             x12, x12, #16
    ld1b            {z31.b}, p0/z, [x2, x12]
    sub             z0.h, z24.h, z28.h
    sub             z1.h, z25.h, z29.h
    sub             z2.h, z26.h, z30.h
    sub             z3.h, z27.h, z31.h
    smlalb          z5.s, z0.h, z0.h
    smlalt          z6.s, z0.h, z0.h
    smlalb          z5.s, z1.h, z1.h
    smlalt          z6.s, z1.h, z1.h
    smlalb          z5.s, z2.h, z2.h
    smlalt          z6.s, z2.h, z2.h
    smlalb          z5.s, z3.h, z3.h
    smlalt          z6.s, z3.h, z3.h
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3, lsl #1
.endr
    uaddv           d3, p0, z5.s
    fmov            w0, s3
    uaddv           d4, p0, z6.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
.vl_gt_16_pixel_sse_ss_64x64:
    cmp             x9, #48
    bgt             .vl_gt_48_pixel_sse_ss_64x64
    ptrue           p0.b, vl32
    mov             z5.d, #0
    mov             z6.d, #0
    mov             x11, #32
    mov             x12, #32
.rept 64
    ld1b            {z24.b}, p0/z, [x0]
    ld1b            {z25.b}, p0/z, [x0, x11]
    ld1b            {z28.b}, p0/z, [x2]
    ld1b            {z29.b}, p0/z, [x2, x12]
    sub             z0.h, z24.h, z28.h
    sub             z1.h, z25.h, z29.h
    smlalb          z5.s, z0.h, z0.h
    smlalt          z6.s, z0.h, z0.h
    smlalb          z5.s, z1.h, z1.h
    smlalt          z6.s, z1.h, z1.h
    add             x11, x11, #32
    ld1b            {z24.b}, p0/z, [x0, x11]
    add             x11, x11, #32
    ld1b            {z25.b}, p0/z, [x0, x11]
    add             x12, x12, #32
    ld1b            {z28.b}, p0/z, [x2, x12]
    add             x12, x12, #32
    ld1b            {z29.b}, p0/z, [x2, x12]
    sub             z0.h, z24.h, z28.h
    sub             z1.h, z25.h, z29.h
    smlalb          z5.s, z0.h, z0.h
    smlalt          z6.s, z0.h, z0.h
    smlalb          z5.s, z1.h, z1.h
    smlalt          z6.s, z1.h, z1.h
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3, lsl #1
.endr
    uaddv           d3, p0, z5.s
    fmov            w0, s3
    uaddv           d4, p0, z6.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
.vl_gt_48_pixel_sse_ss_64x64:
    cmp             x9, #112
    bgt             .vl_gt_112_pixel_sse_ss_64x64
    ptrue           p0.b, vl64
    mov             z5.d, #0
    mov             z6.d, #0
    mov             x11, #64
.rept 64
    ld1b            {z24.b}, p0/z, [x0]
    ld1b            {z28.b}, p0/z, [x2]
    sub             z0.h, z24.h, z28.h
    smlalb          z5.s, z0.h, z0.h
    smlalt          z6.s, z0.h, z0.h
    ld1b            {z24.b}, p0/z, [x0, x11]
    ld1b            {z28.b}, p0/z, [x2, x11]
    sub             z0.h, z24.h, z28.h
    smlalb          z5.s, z0.h, z0.h
    smlalt          z6.s, z0.h, z0.h
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3, lsl #1
.endr
    uaddv           d3, p0, z5.s
    fmov            w0, s3
    uaddv           d4, p0, z6.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
.vl_gt_112_pixel_sse_ss_64x64:
    ptrue           p0.b, vl128
    mov             z5.d, #0
    mov             z6.d, #0
.rept 64
    ld1b            {z24.b}, p0/z, [x0]
    ld1b            {z28.b}, p0/z, [x2]
    sub             z0.h, z24.h, z28.h
    smlalb          z5.s, z0.h, z0.h
    smlalt          z6.s, z0.h, z0.h
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3, lsl #1
.endr
    uaddv           d3, p0, z5.s
    fmov            w0, s3
    uaddv           d4, p0, z6.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
endfunc

function PFX(pixel_ssd_s_4x4_sve2)
    ptrue           p0.b, vl8
    mov             z0.d, #0
    mov             z1.d, #0
.rept 4
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1, lsl #1
    smlalb          z0.s, z16.h, z16.h
    smlalt          z1.s, z16.h, z16.h
.endr
    uaddv           d3, p0, z0.s
    fmov            w0, s3
    uaddv           d4, p0, z1.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
endfunc

function PFX(pixel_ssd_s_8x8_sve2)
    ptrue           p0.b, vl16
    mov             z0.d, #0
    mov             z1.d, #0
.rept 8
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1, lsl #1
    smlalb          z0.s, z16.h, z16.h
    smlalt          z1.s, z16.h, z16.h
.endr
    uaddv           d3, p0, z0.s
    fmov            w0, s3
    uaddv           d4, p0, z1.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
endfunc

function PFX(pixel_ssd_s_16x16_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_ssd_s_16x16
    ptrue           p0.b, vl16
    mov             z0.d, #0
    mov             z1.d, #0
    mov             x11, #16
.rept 16
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, x11]
    add             x0, x0, x1, lsl #1
    smlalb          z0.s, z16.h, z16.h
    smlalt          z1.s, z16.h, z16.h
    smlalb          z0.s, z17.h, z17.h
    smlalt          z1.s, z17.h, z17.h
.endr
    uaddv           d3, p0, z0.s
    fmov            w0, s3
    uaddv           d4, p0, z1.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
.vl_gt_16_pixel_ssd_s_16x16:
    ptrue           p0.b, vl32
    mov             z0.d, #0
    mov             z1.d, #0
.rept 16
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1, lsl #1
    smlalb          z0.s, z16.h, z16.h
    smlalt          z1.s, z16.h, z16.h
.endr
    uaddv           d3, p0, z0.s
    fmov            w0, s3
    uaddv           d4, p0, z1.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
endfunc

function PFX(pixel_ssd_s_32x32_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_ssd_s_32x32
    ptrue           p0.b, vl16
    mov             z0.d, #0
    mov             z1.d, #0
.rept 32
    mov             x11, #16
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, x11]
    add             x11, x11, #16
    ld1b            {z18.b}, p0/z, [x0, x11]
    add             x11, x11, #16
    ld1b            {z19.b}, p0/z, [x0, x11]
    add             x0, x0, x1, lsl #1
    smlalb          z0.s, z16.h, z16.h
    smlalt          z1.s, z16.h, z16.h
    smlalb          z0.s, z17.h, z17.h
    smlalt          z1.s, z17.h, z17.h
    smlalb          z0.s, z18.h, z18.h
    smlalt          z1.s, z18.h, z18.h
    smlalb          z0.s, z19.h, z19.h
    smlalt          z1.s, z19.h, z19.h
.endr
    uaddv           d3, p0, z0.s
    fmov            w0, s3
    uaddv           d4, p0, z1.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
.vl_gt_16_pixel_ssd_s_32x32:
    cmp             x9, #48
    bgt             .vl_gt_48_pixel_ssd_s_32x32
    ptrue           p0.b, vl32
    mov             z0.d, #0
    mov             z1.d, #0
    mov             x11, #32
.rept 32
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, x11]
    add             x0, x0, x1, lsl #1
    smlalb          z0.s, z16.h, z16.h
    smlalt          z1.s, z16.h, z16.h
    smlalb          z0.s, z17.h, z17.h
    smlalt          z1.s, z17.h, z17.h
.endr
    uaddv           d3, p0, z0.s
    fmov            w0, s3
    uaddv           d4, p0, z1.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
.vl_gt_48_pixel_ssd_s_32x32:
    ptrue           p0.b, vl64
    mov             z0.d, #0
    mov             z1.d, #0
.rept 32
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1, lsl #1
    smlalb          z0.s, z16.h, z16.h
    smlalt          z1.s, z16.h, z16.h
.endr
    uaddv           d3, p0, z0.s
    fmov            w0, s3
    uaddv           d4, p0, z1.s
    fmov            w1, s4
    add             w0, w0, w1
    ret
endfunc
