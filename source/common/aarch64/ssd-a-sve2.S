/*****************************************************************************
 * Copyright (C) 2022-2023 MulticoreWare, Inc
 *
 * Authors: David Chen <david.chen@myais.com.cn>
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

#include "asm-sve.S"

.arch armv8-a+sve2

#ifdef __APPLE__
.section __RODATA,__rodata
#else
.section .rodata
#endif

.align 4

.text

function PFX(pixel_sse_pp_8x8_sve2)
    ptrue           p0.b, vl8
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    usublb          z1.h, z16.b, z17.b
    usublt          z2.h, z16.b, z17.b
    smullb          z0.s, z1.h, z1.h
    smlalt          z0.s, z1.h, z1.h
    smlalb          z0.s, z2.h, z2.h
    smlalt          z0.s, z2.h, z2.h
.rept 7
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    usublb          z1.h, z16.b, z17.b
    usublt          z2.h, z16.b, z17.b
    smlalb          z0.s, z1.h, z1.h
    smlalt          z0.s, z1.h, z1.h
    smlalb          z0.s, z2.h, z2.h
    smlalt          z0.s, z2.h, z2.h
.endr
    uaddv           d0, p0, z0.s
    fmov            w0, s0
    ret
endfunc

function PFX(pixel_sse_pp_8x16_sve2)
    ptrue           p0.b, vl8
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    usublb          z1.h, z16.b, z17.b
    usublt          z2.h, z16.b, z17.b
    smullb          z0.s, z1.h, z1.h
    smlalt          z0.s, z1.h, z1.h
    smlalb          z0.s, z2.h, z2.h
    smlalt          z0.s, z2.h, z2.h
.rept 15
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    usublb          z1.h, z16.b, z17.b
    usublt          z2.h, z16.b, z17.b
    smlalb          z0.s, z1.h, z1.h
    smlalt          z0.s, z1.h, z1.h
    smlalb          z0.s, z2.h, z2.h
    smlalt          z0.s, z2.h, z2.h
.endr
    uaddv           d0, p0, z0.s
    fmov            w0, s0
    ret
endfunc

.macro sse_pp_16xN_sve2 h
function PFX(pixel_sse_pp_16x\h\()_sve2)
    ptrue           p0.b, vl16
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    usublb          z1.h, z16.b, z17.b
    usublt          z2.h, z16.b, z17.b
    smullb          z0.s, z1.h, z1.h
    smlalt          z0.s, z1.h, z1.h
    smlalb          z0.s, z2.h, z2.h
    smlalt          z0.s, z2.h, z2.h
.rept \h - 1
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    usublb          z1.h, z16.b, z17.b
    usublt          z2.h, z16.b, z17.b
    smlalb          z0.s, z1.h, z1.h
    smlalt          z0.s, z1.h, z1.h
    smlalb          z0.s, z2.h, z2.h
    smlalt          z0.s, z2.h, z2.h
.endr
    uaddv           d0, p0, z0.s
    fmov            w0, s0
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
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z18.b}, p0/z, [x2]
    ld1b            {z19.b}, p0/z, [x2, #1, mul vl]
    add             x0, x0, x1
    add             x2, x2, x3
    usublb          z1.h, z16.b, z18.b
    usublt          z2.h, z16.b, z18.b
    usublb          z3.h, z17.b, z19.b
    usublt          z4.h, z17.b, z19.b
    smullb          z0.s, z1.h, z1.h
    smlalt          z0.s, z1.h, z1.h
    smlalb          z0.s, z2.h, z2.h
    smlalt          z0.s, z2.h, z2.h
    smlalb          z0.s, z3.h, z3.h
    smlalt          z0.s, z3.h, z3.h
    smlalb          z0.s, z4.h, z4.h
    smlalt          z0.s, z4.h, z4.h
.rept 31
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z18.b}, p0/z, [x2]
    ld1b            {z19.b}, p0/z, [x2, #1, mul vl]
    add             x0, x0, x1
    add             x2, x2, x3
    usublb          z1.h, z16.b, z18.b
    usublt          z2.h, z16.b, z18.b
    usublb          z3.h, z17.b, z19.b
    usublt          z4.h, z17.b, z19.b
    smlalb          z0.s, z1.h, z1.h
    smlalt          z0.s, z1.h, z1.h
    smlalb          z0.s, z2.h, z2.h
    smlalt          z0.s, z2.h, z2.h
    smlalb          z0.s, z3.h, z3.h
    smlalt          z0.s, z3.h, z3.h
    smlalb          z0.s, z4.h, z4.h
    smlalt          z0.s, z4.h, z4.h
.endr
    uaddv           d3, p0, z0.s
    fmov            w0, s3
    ret
.vl_gt_16_pixel_sse_pp_32x32:
    ptrue           p0.b, vl32
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z18.b}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    usublb          z1.h, z16.b, z18.b
    usublt          z2.h, z16.b, z18.b
    smullb          z0.s, z1.h, z1.h
    smlalt          z0.s, z1.h, z1.h
    smlalb          z0.s, z2.h, z2.h
    smlalt          z0.s, z2.h, z2.h
.rept 31
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z18.b}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    usublb          z1.h, z16.b, z18.b
    usublt          z2.h, z16.b, z18.b
    smullb          z0.s, z1.h, z1.h
    smlalt          z0.s, z1.h, z1.h
    smlalb          z0.s, z2.h, z2.h
    smlalt          z0.s, z2.h, z2.h
.endr
    uaddv           d3, p0, z0.s
    fmov            w0, s3
    ret
endfunc

function PFX(pixel_sse_pp_32x64_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sse_pp_32x64
    ptrue           p0.b, vl16
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z18.b}, p0/z, [x2]
    ld1b            {z19.b}, p0/z, [x2, #1, mul vl]
    add             x0, x0, x1
    add             x2, x2, x3
    usublb          z1.h, z16.b, z18.b
    usublt          z2.h, z16.b, z18.b
    usublb          z3.h, z17.b, z19.b
    usublt          z4.h, z17.b, z19.b
    smullb          z20.s, z1.h, z1.h
    smullt          z21.s, z1.h, z1.h
    smlalb          z20.s, z2.h, z2.h
    smlalt          z21.s, z2.h, z2.h
    smlalb          z20.s, z3.h, z3.h
    smlalt          z21.s, z3.h, z3.h
    smlalb          z20.s, z4.h, z4.h
    smlalt          z21.s, z4.h, z4.h
.rept 63
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z18.b}, p0/z, [x2]
    ld1b            {z19.b}, p0/z, [x2, #1, mul vl]
    add             x0, x0, x1
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
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z18.b}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    usublb          z1.h, z16.b, z18.b
    usublt          z2.h, z16.b, z18.b
    smullb          z20.s, z1.h, z1.h
    smullt          z21.s, z1.h, z1.h
    smlalb          z20.s, z2.h, z2.h
    smlalt          z21.s, z2.h, z2.h
.rept 63
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z18.b}, p0/z, [x2]
    add             x0, x0, x1
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
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z18.b}, p0/z, [x0, #2, mul vl]
    ld1b            {z19.b}, p0/z, [x0, #3, mul vl]
    ld1b            {z20.b}, p0/z, [x2]
    ld1b            {z21.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z22.b}, p0/z, [x2, #2, mul vl]
    ld1b            {z23.b}, p0/z, [x2, #3, mul vl]
    add             x0, x0, x1
    add             x2, x2, x3
    usublb          z1.h, z16.b, z20.b
    usublt          z2.h, z16.b, z20.b
    usublb          z3.h, z17.b, z21.b
    usublt          z4.h, z17.b, z21.b
    usublb          z5.h, z18.b, z22.b
    usublt          z6.h, z18.b, z22.b
    usublb          z7.h, z19.b, z23.b
    usublt          z8.h, z19.b, z23.b
    smullb          z24.s, z1.h, z1.h
    smullt          z25.s, z1.h, z1.h
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
.rept 63
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z18.b}, p0/z, [x0, #2, mul vl]
    ld1b            {z19.b}, p0/z, [x0, #3, mul vl]
    ld1b            {z20.b}, p0/z, [x2]
    ld1b            {z21.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z22.b}, p0/z, [x2, #2, mul vl]
    ld1b            {z23.b}, p0/z, [x2, #3, mul vl]
    add             x0, x0, x1
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
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z20.b}, p0/z, [x2]
    ld1b            {z21.b}, p0/z, [x2, #1, mul vl]
    add             x0, x0, x1
    add             x2, x2, x3
    usublb          z1.h, z16.b, z20.b
    usublt          z2.h, z16.b, z20.b
    usublb          z3.h, z17.b, z21.b
    usublt          z4.h, z17.b, z21.b
    smullb          z24.s, z1.h, z1.h
    smullt          z25.s, z1.h, z1.h
    smlalb          z24.s, z2.h, z2.h
    smlalt          z25.s, z2.h, z2.h
    smlalb          z24.s, z3.h, z3.h
    smlalt          z25.s, z3.h, z3.h
    smlalb          z24.s, z4.h, z4.h
    smlalt          z25.s, z4.h, z4.h
.rept 63
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z20.b}, p0/z, [x2]
    ld1b            {z21.b}, p0/z, [x2, #1, mul vl]
    add             x0, x0, x1
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
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z20.b}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    usublb          z1.h, z16.b, z20.b
    usublt          z2.h, z16.b, z20.b
    smullb          z24.s, z1.h, z1.h
    smullt          z25.s, z1.h, z1.h
    smlalb          z24.s, z2.h, z2.h
    smlalt          z25.s, z2.h, z2.h
.rept 63
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z20.b}, p0/z, [x2]
    add             x0, x0, x1
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
    ld1b            {z17.b}, p0/z, [x2]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3, lsl #1
    sub             z1.h, z16.h, z17.h
    smullb          z3.s, z1.h, z1.h
    smullt          z4.s, z1.h, z1.h
.rept 3
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x2]
    add             x0, x0, x1, lsl #1
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
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x2]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3, lsl #1
    sub             z1.h, z16.h, z17.h
    smullb          z3.s, z1.h, z1.h
    smullt          z4.s, z1.h, z1.h
.rept 7
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x2]
    add             x0, x0, x1, lsl #1
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
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z18.b}, p0/z, [x2]
    ld1b            {z19.b}, p0/z, [x2, #1, mul vl]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3, lsl #1
    sub             z1.h, z16.h, z18.h
    sub             z2.h, z17.h, z19.h
    smullb          z3.s, z1.h, z1.h
    smullt          z4.s, z1.h, z1.h
    smlalb          z3.s, z2.h, z2.h
    smlalt          z4.s, z2.h, z2.h
.rept 15
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z18.b}, p0/z, [x2]
    ld1b            {z19.b}, p0/z, [x2, #1, mul vl]
    add             x0, x0, x1, lsl #1
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
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z18.b}, p0/z, [x2]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3, lsl #1
    sub             z1.h, z16.h, z18.h
    smullb          z3.s, z1.h, z1.h
    smullt          z4.s, z1.h, z1.h
.rept 15
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z18.b}, p0/z, [x2]
    add             x0, x0, x1, lsl #1
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
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z18.b}, p0/z, [x0, #2, mul vl]
    ld1b            {z19.b}, p0/z, [x0, #3, mul vl]
    ld1b            {z20.b}, p0/z, [x2]
    ld1b            {z21.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z22.b}, p0/z, [x2, #2, mul vl]
    ld1b            {z23.b}, p0/z, [x2, #3, mul vl]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3, lsl #1
    sub             z1.h, z16.h, z20.h
    sub             z2.h, z17.h, z21.h
    sub             z3.h, z18.h, z22.h
    sub             z4.h, z19.h, z23.h
    smullb          z5.s, z1.h, z1.h
    smullt          z6.s, z1.h, z1.h
    smlalb          z5.s, z2.h, z2.h
    smlalt          z6.s, z2.h, z2.h
    smlalb          z5.s, z3.h, z3.h
    smlalt          z6.s, z3.h, z3.h
    smlalb          z5.s, z4.h, z4.h
    smlalt          z6.s, z4.h, z4.h
.rept 31
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z18.b}, p0/z, [x0, #2, mul vl]
    ld1b            {z19.b}, p0/z, [x0, #3, mul vl]
    ld1b            {z20.b}, p0/z, [x2]
    ld1b            {z21.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z22.b}, p0/z, [x2, #2, mul vl]
    ld1b            {z23.b}, p0/z, [x2, #3, mul vl]
    add             x0, x0, x1, lsl #1
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
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z20.b}, p0/z, [x2]
    ld1b            {z21.b}, p0/z, [x2, #1, mul vl]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3, lsl #1
    sub             z1.h, z16.h, z20.h
    sub             z2.h, z17.h, z21.h
    smullb          z5.s, z1.h, z1.h
    smullt          z6.s, z1.h, z1.h
    smlalb          z5.s, z2.h, z2.h
    smlalt          z6.s, z2.h, z2.h
.rept 31
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z20.b}, p0/z, [x2]
    ld1b            {z21.b}, p0/z, [x2, #1, mul vl]
    add             x0, x0, x1, lsl #1
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
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z20.b}, p0/z, [x2]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3, lsl #1
    sub             z1.h, z16.h, z20.h
    smullb          z5.s, z1.h, z1.h
    smullt          z6.s, z1.h, z1.h
.rept 31
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z20.b}, p0/z, [x2]
    add             x0, x0, x1, lsl #1
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
    ld1b            {z24.b}, p0/z, [x0]
    ld1b            {z25.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z26.b}, p0/z, [x0, #2, mul vl]
    ld1b            {z27.b}, p0/z, [x0, #3, mul vl]
    ld1b            {z28.b}, p0/z, [x2]
    ld1b            {z29.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z30.b}, p0/z, [x2, #2, mul vl]
    ld1b            {z31.b}, p0/z, [x2, #3, mul vl]
    sub             z0.h, z24.h, z28.h
    sub             z1.h, z25.h, z29.h
    sub             z2.h, z26.h, z30.h
    sub             z3.h, z27.h, z31.h
    smullb          z5.s, z0.h, z0.h
    smullt          z6.s, z0.h, z0.h
    smlalb          z5.s, z1.h, z1.h
    smlalt          z6.s, z1.h, z1.h
    smlalb          z5.s, z2.h, z2.h
    smlalt          z6.s, z2.h, z2.h
    smlalb          z5.s, z3.h, z3.h
    smlalt          z6.s, z3.h, z3.h
    ld1b            {z24.b}, p0/z, [x0, #4, mul vl]
    ld1b            {z25.b}, p0/z, [x0, #5, mul vl]
    ld1b            {z26.b}, p0/z, [x0, #6, mul vl]
    ld1b            {z27.b}, p0/z, [x0, #7, mul vl]
    ld1b            {z28.b}, p0/z, [x2, #4, mul vl]
    ld1b            {z29.b}, p0/z, [x2, #5, mul vl]
    ld1b            {z30.b}, p0/z, [x2, #6, mul vl]
    ld1b            {z31.b}, p0/z, [x2, #7, mul vl]
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
.rept 63
    ld1b            {z24.b}, p0/z, [x0]
    ld1b            {z25.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z26.b}, p0/z, [x0, #2, mul vl]
    ld1b            {z27.b}, p0/z, [x0, #3, mul vl]
    ld1b            {z28.b}, p0/z, [x2]
    ld1b            {z29.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z30.b}, p0/z, [x2, #2, mul vl]
    ld1b            {z31.b}, p0/z, [x2, #3, mul vl]
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
    ld1b            {z24.b}, p0/z, [x0, #4, mul vl]
    ld1b            {z25.b}, p0/z, [x0, #5, mul vl]
    ld1b            {z26.b}, p0/z, [x0, #6, mul vl]
    ld1b            {z27.b}, p0/z, [x0, #7, mul vl]
    ld1b            {z28.b}, p0/z, [x2, #4, mul vl]
    ld1b            {z29.b}, p0/z, [x2, #5, mul vl]
    ld1b            {z30.b}, p0/z, [x2, #6, mul vl]
    ld1b            {z31.b}, p0/z, [x2, #7, mul vl]
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
    ld1b            {z24.b}, p0/z, [x0]
    ld1b            {z25.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z28.b}, p0/z, [x2]
    ld1b            {z29.b}, p0/z, [x2, #1, mul vl]
    sub             z0.h, z24.h, z28.h
    sub             z1.h, z25.h, z29.h
    smullb          z5.s, z0.h, z0.h
    smullt          z6.s, z0.h, z0.h
    smlalb          z5.s, z1.h, z1.h
    smlalt          z6.s, z1.h, z1.h
    ld1b            {z24.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z25.b}, p0/z, [x0, #2, mul vl]
    ld1b            {z28.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z29.b}, p0/z, [x2, #2, mul vl]
    sub             z0.h, z24.h, z28.h
    sub             z1.h, z25.h, z29.h
    smlalb          z5.s, z0.h, z0.h
    smlalt          z6.s, z0.h, z0.h
    smlalb          z5.s, z1.h, z1.h
    smlalt          z6.s, z1.h, z1.h
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3, lsl #1
.rept 63
    ld1b            {z24.b}, p0/z, [x0]
    ld1b            {z25.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z28.b}, p0/z, [x2]
    ld1b            {z29.b}, p0/z, [x2, #1, mul vl]
    sub             z0.h, z24.h, z28.h
    sub             z1.h, z25.h, z29.h
    smlalb          z5.s, z0.h, z0.h
    smlalt          z6.s, z0.h, z0.h
    smlalb          z5.s, z1.h, z1.h
    smlalt          z6.s, z1.h, z1.h
    ld1b            {z24.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z25.b}, p0/z, [x0, #2, mul vl]
    ld1b            {z28.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z29.b}, p0/z, [x2, #2, mul vl]
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
    ld1b            {z24.b}, p0/z, [x0]
    ld1b            {z28.b}, p0/z, [x2]
    sub             z0.h, z24.h, z28.h
    smullb          z5.s, z0.h, z0.h
    smullt          z6.s, z0.h, z0.h
    ld1b            {z24.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z28.b}, p0/z, [x2, #1, mul vl]
    sub             z0.h, z24.h, z28.h
    smlalb          z5.s, z0.h, z0.h
    smlalt          z6.s, z0.h, z0.h
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3, lsl #1
.rept 63
    ld1b            {z24.b}, p0/z, [x0]
    ld1b            {z28.b}, p0/z, [x2]
    sub             z0.h, z24.h, z28.h
    smlalb          z5.s, z0.h, z0.h
    smlalt          z6.s, z0.h, z0.h
    ld1b            {z24.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z28.b}, p0/z, [x2, #1, mul vl]
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
    ld1b            {z24.b}, p0/z, [x0]
    ld1b            {z28.b}, p0/z, [x2]
    sub             z0.h, z24.h, z28.h
    smullb          z5.s, z0.h, z0.h
    smullt          z6.s, z0.h, z0.h
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3, lsl #1
.rept 63
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
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1, lsl #1
    smullb          z0.s, z16.h, z16.h
    smlalt          z0.s, z16.h, z16.h
.rept 3
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1, lsl #1
    smlalb          z0.s, z16.h, z16.h
    smlalt          z0.s, z16.h, z16.h
.endr
    uaddv           d3, p0, z0.s
    fmov            w0, s3
    ret
endfunc

function PFX(pixel_ssd_s_8x8_sve2)
    ptrue           p0.b, vl16
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1, lsl #1
    smullb          z0.s, z16.h, z16.h
    smlalt          z0.s, z16.h, z16.h
.rept 7
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1, lsl #1
    smlalb          z0.s, z16.h, z16.h
    smlalt          z0.s, z16.h, z16.h
.endr
    uaddv           d3, p0, z0.s
    fmov            w0, s3
    ret
endfunc

function PFX(pixel_ssd_s_16x16_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_ssd_s_16x16
    ptrue           p0.b, vl16
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x1, lsl #1
    smullb          z0.s, z16.h, z16.h
    smlalt          z0.s, z16.h, z16.h
    smlalb          z0.s, z17.h, z17.h
    smlalt          z0.s, z17.h, z17.h
.rept 15
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x1, lsl #1
    smlalb          z0.s, z16.h, z16.h
    smlalt          z0.s, z16.h, z16.h
    smlalb          z0.s, z17.h, z17.h
    smlalt          z0.s, z17.h, z17.h
.endr
    uaddv           d3, p0, z0.s
    fmov            w0, s3
    ret
.vl_gt_16_pixel_ssd_s_16x16:
    ptrue           p0.b, vl32
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1, lsl #1
    smullb          z0.s, z16.h, z16.h
    smlalt          z0.s, z16.h, z16.h
.rept 15
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1, lsl #1
    smlalb          z0.s, z16.h, z16.h
    smlalt          z0.s, z16.h, z16.h
.endr
    uaddv           d3, p0, z0.s
    fmov            w0, s3
    ret
endfunc

function PFX(pixel_ssd_s_32x32_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_ssd_s_32x32
    ptrue           p0.b, vl16
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z18.b}, p0/z, [x0, #2, mul vl]
    ld1b            {z19.b}, p0/z, [x0, #3, mul vl]
    add             x0, x0, x1, lsl #1
    smullb          z0.s, z16.h, z16.h
    smlalt          z0.s, z16.h, z16.h
    smlalb          z0.s, z17.h, z17.h
    smlalt          z0.s, z17.h, z17.h
    smlalb          z0.s, z18.h, z18.h
    smlalt          z0.s, z18.h, z18.h
    smlalb          z0.s, z19.h, z19.h
    smlalt          z0.s, z19.h, z19.h
.rept 31
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z18.b}, p0/z, [x0, #2, mul vl]
    ld1b            {z19.b}, p0/z, [x0, #3, mul vl]
    add             x0, x0, x1, lsl #1
    smlalb          z0.s, z16.h, z16.h
    smlalt          z0.s, z16.h, z16.h
    smlalb          z0.s, z17.h, z17.h
    smlalt          z0.s, z17.h, z17.h
    smlalb          z0.s, z18.h, z18.h
    smlalt          z0.s, z18.h, z18.h
    smlalb          z0.s, z19.h, z19.h
    smlalt          z0.s, z19.h, z19.h
.endr
    uaddv           d3, p0, z0.s
    fmov            w0, s3
    ret
.vl_gt_16_pixel_ssd_s_32x32:
    cmp             x9, #48
    bgt             .vl_gt_48_pixel_ssd_s_32x32
    ptrue           p0.b, vl32
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x1, lsl #1
    smullb          z0.s, z16.h, z16.h
    smlalt          z0.s, z16.h, z16.h
    smlalb          z0.s, z17.h, z17.h
    smlalt          z0.s, z17.h, z17.h
.rept 31
    ld1b            {z16.b}, p0/z, [x0]
    ld1b            {z17.b}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x1, lsl #1
    smlalb          z0.s, z16.h, z16.h
    smlalt          z0.s, z16.h, z16.h
    smlalb          z0.s, z17.h, z17.h
    smlalt          z0.s, z17.h, z17.h
.endr
    uaddv           d3, p0, z0.s
    fmov            w0, s3
    ret
.vl_gt_48_pixel_ssd_s_32x32:
    ptrue           p0.b, vl64
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1, lsl #1
    smullb          z0.s, z16.h, z16.h
    smlalt          z0.s, z16.h, z16.h
.rept 31
    ld1b            {z16.b}, p0/z, [x0]
    add             x0, x0, x1, lsl #1
    smlalb          z0.s, z16.h, z16.h
    smlalt          z0.s, z16.h, z16.h
.endr
    uaddv           d3, p0, z0.s
    fmov            w0, s3
    ret
endfunc
