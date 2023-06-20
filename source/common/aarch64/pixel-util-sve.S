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

#include "asm-sve.S"
#include "pixel-util-common.S"

.arch armv8-a+sve

#ifdef __APPLE__
.section __RODATA,__rodata
#else
.section .rodata
#endif

.align 4

.text

function PFX(getResidual4_sve)
    ptrue           p0.h, vl8
    ptrue           p1.b, vl8
.rept 4
    ld1b            {z0.h}, p0/z, [x0]
    ld1b            {z1.h}, p0/z, [x1]
    add             x0, x0, x3
    add             x1, x1, x3
    sub             z2.h, z0.h, z1.h
    st1b            {z2.b}, p1, [x2]
    add             x2, x2, x3, lsl #1
.endr
    ret
endfunc

function PFX(getResidual8_sve)
    ptrue           p0.h, vl8
.rept 8
    ld1b            {z0.h}, p0/z, [x0]
    ld1b            {z1.h}, p0/z, [x1]
    add             x0, x0, x3
    add             x1, x1, x3
    sub             z2.h, z0.h, z1.h
    st1h            {z2.h}, p0, [x2]
    add             x2, x2, x3, lsl #1
.endr
    ret
endfunc

function PFX(pixel_sub_ps_4x4_sve)
    ptrue           p0.h, vl4
.rept 4
    ld1b            {z0.h}, p0/z, [x2]
    ld1b            {z4.h}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5
    sub             z8.h, z0.h, z4.h
    st1h            {z8.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc

function PFX(pixel_sub_ps_8x8_sve)
    ptrue           p0.h, vl8
.rept 8
    ld1b            {z0.h}, p0/z, [x2]
    ld1b            {z4.h}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5
    sub             z8.h, z0.h, z4.h
    st1h            {z8.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc

function PFX(pixel_sub_ps_4x8_sve)
    ptrue           p0.h, vl4
.rept 8
    ld1b            {z0.h}, p0/z, [x2]
    ld1b            {z4.h}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5
    sub             z8.h, z0.h, z4.h
    st1h            {z8.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc

function PFX(pixel_sub_ps_8x16_sve)
    ptrue           p0.h, vl8
.rept 16
    ld1b            {z0.h}, p0/z, [x2]
    ld1b            {z4.h}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5
    sub             z8.h, z0.h, z4.h
    st1h            {z8.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc

// void planecopy_cp_c(const uint8_t* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int width, int height, int shift)
function PFX(pixel_planecopy_cp_sve)
    ptrue           p0.b, vl16
    dup             z2.b, w6
    sub             x5, x5, #1
.loop_h_sve:
    mov             x6, x0
    mov             x12, x2
    mov             x7, #0
.loop_w_sve:
    ldr             z0, [x6]
    lsl             z0.b, p0/m, z0.b, z2.b
    str             z0, [x12]
    add             x6, x6, #16
    add             x12, x12, #16
    add             x7, x7, #16
    cmp             x7, x4
    blt             .loop_w_sve

    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .loop_h_sve

// handle last row
    mov             x5, x4
    lsr             x5, x5, #3
.loopW8_sve:
    ldr             z0, [x0]
    add             x0, x0, #8
    lsl             z0.b, p0/m, z0.b, z2.b
    str             d0, [x2], #8
    sub             x4, x4, #8
    sub             x5, x5, #1
    cbnz            x5, .loopW8_sve

    mov             x5, #8
    sub             x5, x5, x4
    sub             x0, x0, x5
    sub             x2, x2, x5
    ldr             d0, [x0]
    lsl             z0.b, p0/m, z0.b, z2.b
    str             d0, [x2]
    ret
endfunc

//******* satd *******
.macro satd_4x4_sve
    ld1b            {z0.h}, p0/z, [x0]
    ld1b            {z2.h}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    ld1b            {z1.h}, p0/z, [x0]
    ld1b            {z3.h}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    ld1b            {z4.h}, p0/z, [x0]
    ld1b            {z6.h}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    ld1b            {z5.h}, p0/z, [x0]
    ld1b            {z7.h}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3

    sub             z0.h, z0.h, z2.h
    sub             z1.h, z1.h, z3.h
    sub             z2.h, z4.h, z6.h
    sub             z3.h, z5.h, z7.h

    add             z4.h, z0.h, z2.h
    add             z5.h, z1.h, z3.h
    sub             z6.h, z0.h, z2.h
    sub             z7.h, z1.h, z3.h

    add             z0.h, z4.h, z5.h
    sub             z1.h, z4.h, z5.h

    add             z2.h, z6.h, z7.h
    sub             z3.h, z6.h, z7.h

    trn1            z4.h, z0.h, z2.h
    trn2            z5.h, z0.h, z2.h

    trn1            z6.h, z1.h, z3.h
    trn2            z7.h, z1.h, z3.h

    add             z0.h, z4.h, z5.h
    sub             z1.h, z4.h, z5.h

    add             z2.h, z6.h, z7.h
    sub             z3.h, z6.h, z7.h

    trn1            z4.s, z0.s, z1.s
    trn2            z5.s, z0.s, z1.s

    trn1            z6.s, z2.s, z3.s
    trn2            z7.s, z2.s, z3.s

    abs             z4.h, p0/m, z4.h
    abs             z5.h, p0/m, z5.h
    abs             z6.h, p0/m, z6.h
    abs             z7.h, p0/m, z7.h

    smax            z4.h, p0/m, z4.h, z5.h
    smax            z6.h, p0/m, z6.h, z7.h

    add             z0.h, z4.h, z6.h

    uaddlp          v0.2s, v0.4h
    uaddlp          v0.1d, v0.2s
.endm

// int satd_4x4(const pixel* pix1, intptr_t stride_pix1, const pixel* pix2, intptr_t stride_pix2)
function PFX(pixel_satd_4x4_sve)
    ptrue           p0.h, vl4
    satd_4x4_sve
    fmov            x0, d0
    ret
endfunc

.macro x265_satd_4x8_8x4_end_sve
    ptrue           p0.h, vl8
    add             z0.h, z4.h, z6.h
    add             z1.h, z5.h, z7.h
    sub             z2.h, z4.h, z6.h
    sub             z3.h, z5.h, z7.h

    trn1            z16.h, z0.h, z1.h
    trn2            z17.h, z0.h, z1.h
    add             z4.h, z16.h, z17.h
    trn1            z18.h, z2.h, z3.h
    trn2            z19.h, z2.h, z3.h
    sub             z5.h, z16.h, z17.h
    add             z6.h, z18.h, z19.h
    sub             z7.h, z18.h, z19.h
    trn1            z0.s, z4.s, z6.s
    trn2            z2.s, z4.s, z6.s
    abs             z0.h, p0/m, z0.h
    trn1            z1.s, z5.s, z7.s
    trn2            z3.s, z5.s, z7.s
    abs             z2.h, p0/m, z2.h
    abs             z1.h, p0/m, z1.h
    abs             z3.h, p0/m, z3.h
    umax            z0.h, p0/m, z0.h, z2.h
    umax            z1.h, p0/m, z1.h, z3.h
    add             z0.h, z0.h, z1.h
    uaddlv          s0, v0.8h
.endm

.macro pixel_satd_4x8_sve
    ld1b           {z1.h}, p0/z, [x2]
    ld1b           {z0.h}, p0/z, [x0]
    add             x2, x2, x3
    add             x0, x0, x1
    ld1b           {z3.h}, p0/z, [x2]
    ld1b           {z2.h}, p0/z, [x0]
    add             x2, x2, x3
    add             x0, x0, x1
    ld1b           {z5.h}, p0/z, [x2]
    ld1b           {z4.h}, p0/z, [x0]
    add             x2, x2, x3
    add             x0, x0, x1
    ld1b           {z7.h}, p0/z, [x2]
    ld1b           {z6.h}, p0/z, [x0]
    add             x2, x2, x3
    add             x0, x0, x1

    ld1b           {z13.h}, p0/z, [x2]
    ld1b           {z12.h}, p0/z, [x0]
    add             x2, x2, x3
    add             x0, x0, x1
    sub             z0.h, z0.h, z1.h
    sub             z8.h, z12.h, z13.h

    ld1b           {z13.h}, p0/z, [x2]
    ld1b           {z12.h}, p0/z, [x0]
    add             x2, x2, x3
    add             x0, x0, x1
    sub             z1.h, z2.h, z3.h
    sub             z9.h, z12.h, z13.h

    ld1b           {z13.h}, p0/z, [x2]
    ld1b           {z12.h}, p0/z, [x0]
    add             x2, x2, x3
    add             x0, x0, x1
    sub             z2.h, z4.h, z5.h
    sub             z10.h, z12.h, z13.h

    ld1b           {z13.h}, p0/z, [x2]
    ld1b           {z12.h}, p0/z, [x0]
    add             x2, x2, x3
    add             x0, x0, x1
    sub             z3.h, z6.h, z7.h
    sub             z11.h, z12.h, z13.h

    mov             v0.d[1], v8.d[0]
    mov             v1.d[1], v9.d[0]
    mov             v2.d[1], v10.d[0]
    mov             v3.d[1], v11.d[0]

    add             z4.h, z0.h, z1.h
    sub             z5.h, z0.h, z1.h
    add             z6.h, z2.h, z3.h
    sub             z7.h, z2.h, z3.h
    x265_satd_4x8_8x4_end_sve
.endm

// template<int w, int h>
// int satd4(const pixel* pix1, intptr_t stride_pix1, const pixel* pix2, intptr_t stride_pix2)
function PFX(pixel_satd_4x8_sve)
    ptrue           p0.h, vl4
    pixel_satd_4x8_sve
    mov             w0, v0.s[0]
    ret
endfunc

function PFX(pixel_satd_4x16_sve)
    ptrue           p0.h, vl4
    mov             w4, #0
    pixel_satd_4x8_sve
    mov             w5, v0.s[0]
    add             w4, w4, w5
    pixel_satd_4x8_sve
    mov             w5, v0.s[0]
    add             w0, w5, w4
    ret
endfunc

function PFX(pixel_satd_4x32_sve)
    ptrue           p0.h, vl4
    mov             w4, #0
.rept 4
    pixel_satd_4x8_sve
    mov             w5, v0.s[0]
    add             w4, w4, w5
.endr
    mov             w0, w4
    ret
endfunc

function PFX(pixel_satd_12x16_sve)
    ptrue           p0.h, vl4
    mov             x4, x0
    mov             x5, x2
    mov             w7, #0
    pixel_satd_4x8_sve
    mov             w6, v0.s[0]
    add             w7, w7, w6
    pixel_satd_4x8_sve
    mov             w6, v0.s[0]
    add             w7, w7, w6

    add             x0, x4, #4
    add             x2, x5, #4
    pixel_satd_4x8_sve
    mov             w6, v0.s[0]
    add             w7, w7, w6
    pixel_satd_4x8_sve
    mov             w6, v0.s[0]
    add             w7, w7, w6

    add             x0, x4, #8
    add             x2, x5, #8
    pixel_satd_4x8_sve
    mov             w6, v0.s[0]
    add             w7, w7, w6
    pixel_satd_4x8_sve
    mov             w6, v0.s[0]
    add             w0, w7, w6
    ret
endfunc

function PFX(pixel_satd_12x32_sve)
    ptrue           p0.h, vl4
    mov             x4, x0
    mov             x5, x2
    mov             w7, #0
.rept 4
    pixel_satd_4x8_sve
    mov             w6, v0.s[0]
    add             w7, w7, w6
.endr

    add             x0, x4, #4
    add             x2, x5, #4
.rept 4
    pixel_satd_4x8_sve
    mov             w6, v0.s[0]
    add             w7, w7, w6
.endr

    add             x0, x4, #8
    add             x2, x5, #8
.rept 4
    pixel_satd_4x8_sve
    mov             w6, v0.s[0]
    add             w7, w7, w6
.endr

    mov             w0, w7
    ret
endfunc

function PFX(pixel_satd_8x4_sve)
    ptrue           p0.h, vl4
    mov             x4, x0
    mov             x5, x2
    satd_4x4_sve
    add             x0, x4, #4
    add             x2, x5, #4
    umov            x6, v0.d[0]
    satd_4x4_sve
    umov            x0, v0.d[0]
    add             x0, x0, x6
    ret
endfunc

.macro LOAD_DIFF_8x4_sve z0 z1 z2 z3
    ld1b            {z0.h}, p0/z, [x0]
    ld1b            {z1.h}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    ld1b            {z2.h}, p0/z, [x0]
    ld1b            {z3.h}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    ld1b            {z4.h}, p0/z, [x0]
    ld1b            {z5.h}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    ld1b            {z6.h}, p0/z, [x0]
    ld1b            {z7.h}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    sub             \z0, z0.h, z1.h
    sub             \z1, z2.h, z3.h
    sub             \z2, z4.h, z5.h
    sub             \z3, z6.h, z7.h
.endm

.macro LOAD_DIFF_16x4_sve z0 z1 z2 z3 z4 z5 z6 z7
    ld1b            {z0.h}, p0/z, [x0]
    ld1b            {z1.h}, p0/z, [x0, #1, mul vl]
    ld1b            {z2.h}, p0/z, [x2]
    ld1b            {z3.h}, p0/z, [x2, #1, mul vl]
    add             x0, x0, x1
    add             x2, x2, x3
    ld1b            {z4.h}, p0/z, [x0]
    ld1b            {z5.h}, p0/z, [x0, #1, mul vl]
    ld1b            {z6.h}, p0/z, [x2]
    ld1b            {z7.h}, p0/z, [x2, #1, mul vl]
    add             x0, x0, x1
    add             x2, x2, x3
    ld1b            {z8.h}, p0/z, [x0]
    ld1b            {z9.h}, p0/z, [x0, #1, mul vl]
    ld1b            {z10.h}, p0/z, [x2]
    ld1b            {z11.h}, p0/z, [x2, #1, mul vl]
    add             x0, x0, x1
    add             x2, x2, x3
    ld1b            {z12.h}, p0/z, [x0]
    ld1b            {z13.h}, p0/z, [x0, #1, mul vl]
    ld1b            {z14.h}, p0/z, [x2]
    ld1b            {z15.h}, p0/z, [x2, #1, mul vl]
    add             x0, x0, x1
    add             x2, x2, x3

    sub             \z0, z0.h, z2.h
    sub             \z4, z1.h, z3.h
    sub             \z1, z4.h, z6.h
    sub             \z5, z5.h, z7.h
    sub             \z2, z8.h, z10.h
    sub             \z6, z9.h, z11.h
    sub             \z3, z12.h, z14.h
    sub             \z7, z13.h, z15.h
.endm

function PFX(satd_16x4_sve), export=0
    LOAD_DIFF_16x4_sve  z16.h, z17.h, z18.h, z19.h, z20.h, z21.h, z22.h, z23.h
    b                    PFX(satd_8x4v_8x8h_sve)
endfunc

function PFX(satd_8x8_sve), export=0
    LOAD_DIFF_8x4_sve   z16.h, z17.h, z18.h, z19.h
    LOAD_DIFF_8x4_sve   z20.h, z21.h, z22.h, z23.h
    b                    PFX(satd_8x4v_8x8h_sve)
endfunc

// one vertical hadamard pass and two horizontal
function PFX(satd_8x4v_8x8h_sve), export=0
    HADAMARD4_V     z16.h, z18.h, z17.h, z19.h, z0.h, z2.h, z1.h, z3.h
    HADAMARD4_V     z20.h, z21.h, z22.h, z23.h, z0.h, z1.h, z2.h, z3.h
    trn4            z0.h, z1.h, z2.h, z3.h, z16.h, z17.h, z18.h, z19.h
    trn4            z4.h, z5.h, z6.h, z7.h, z20.h, z21.h, z22.h, z23.h
    SUMSUB_ABCD     z16.h, z17.h, z18.h, z19.h, z0.h, z1.h, z2.h, z3.h
    SUMSUB_ABCD     z20.h, z21.h, z22.h, z23.h, z4.h, z5.h, z6.h, z7.h
    trn4            z0.s, z2.s, z1.s, z3.s, z16.s, z18.s, z17.s, z19.s
    trn4            z4.s, z6.s, z5.s, z7.s, z20.s, z22.s, z21.s, z23.s
    ABS8_SVE        z0.h, z1.h, z2.h, z3.h, z4.h, z5.h, z6.h, z7.h, p0
    smax            z0.h, p0/m, z0.h, z2.h
    smax            z1.h, p0/m, z1.h, z3.h
    smax            z4.h, p0/m, z4.h, z6.h
    smax            z5.h, p0/m, z5.h, z7.h
    ret
endfunc

function PFX(pixel_satd_8x8_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_8x8_sve)
    add             z0.h, z0.h, z1.h
    add             z1.h, z4.h, z5.h
    add             z0.h, z0.h, z1.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_8x12_sve)
    ptrue           p0.h, vl4
    mov             x4, x0
    mov             x5, x2
    mov             x7, #0
    satd_4x4_sve
    umov            x6, v0.d[0]
    add             x7, x7, x6
    add             x0, x4, #4
    add             x2, x5, #4
    satd_4x4_sve
    umov            x6, v0.d[0]
    add             x7, x7, x6
.rept 2
    sub             x0, x0, #4
    sub             x2, x2, #4
    mov             x4, x0
    mov             x5, x2
    satd_4x4_sve
    umov            x6, v0.d[0]
    add             x7, x7, x6
    add             x0, x4, #4
    add             x2, x5, #4
    satd_4x4_sve
    umov            x6, v0.d[0]
    add             x7, x7, x6
.endr
    mov             x0, x7
    ret
endfunc

function PFX(pixel_satd_8x16_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_8x8_sve)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
    bl              PFX(satd_8x8_sve)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_8x32_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_8x8_sve)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
.rept 3
    bl              PFX(satd_8x8_sve)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
.endr
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_8x64_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_8x8_sve)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
.rept 7
    bl              PFX(satd_8x8_sve)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
.endr
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_16x4_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_16x4_sve)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_16x8_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_16x4_sve)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
    bl              PFX(satd_16x4_sve)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_16x12_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_16x4_sve)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
.rept 2
    bl              PFX(satd_16x4_sve)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
.endr
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_16x16_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_16x4_sve)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
.rept 3
    bl              PFX(satd_16x4_sve)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
.endr
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_16x24_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_16x4_sve)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
.rept 5
    bl              PFX(satd_16x4_sve)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
.endr
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

.macro pixel_satd_16x32_sve
    bl              PFX(satd_16x4_sve)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
.rept 7
    bl              PFX(satd_16x4_sve)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
.endr
.endm

function PFX(pixel_satd_16x32_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    pixel_satd_16x32_sve
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_16x64_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_16x4_sve)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
.rept 15
    bl              PFX(satd_16x4_sve)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
.endr
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_24x32_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
    mov             x4, x0
    mov             x5, x2
.rept 3
    movi            v30.2d, #0
    movi            v31.2d, #0
.rept 4
    bl              PFX(satd_8x8_sve)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
.endr
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w6, v0.s[0]
    add             x7, x7, x6
    add             x4, x4, #8
    add             x5, x5, #8
    mov             x0, x4
    mov             x2, x5
.endr
    mov             x0, x7
    ret             x10
endfunc

function PFX(pixel_satd_24x64_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
    mov             x4, x0
    mov             x5, x2
.rept 3
    movi            v30.2d, #0
    movi            v31.2d, #0
.rept 4
    bl              PFX(satd_8x8_sve)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
.endr
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w6, v0.s[0]
    add             x7, x7, x6
    add             x4, x4, #8
    add             x5, x5, #8
    mov             x0, x4
    mov             x2, x5
.endr
    sub             x4, x4, #24
    sub             x5, x5, #24
    add             x0, x4, x1, lsl #5
    add             x2, x5, x3, lsl #5
    mov             x4, x0
    mov             x5, x2
.rept 3
    movi            v30.2d, #0
    movi            v31.2d, #0
.rept 4
    bl              PFX(satd_8x8_sve)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
.endr
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w6, v0.s[0]
    add             x7, x7, x6
    add             x4, x4, #8
    add             x5, x5, #8
    mov             x0, x4
    mov             x2, x5
.endr
    mov             x0, x7
    ret             x10
endfunc

.macro pixel_satd_32x8_sve
    mov             x4, x0
    mov             x5, x2
.rept 2
    bl              PFX(satd_16x4_sve)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
.endr
    add             x0, x4, #16
    add             x2, x5, #16
.rept 2
    bl              PFX(satd_16x4_sve)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
.endr
.endm

.macro satd_32x16_sve
    movi            v30.2d, #0
    movi            v31.2d, #0
    pixel_satd_32x8_sve
    sub             x0, x0, #16
    sub             x2, x2, #16
    pixel_satd_32x8_sve
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w6, v0.s[0]
.endm

.macro satd_64x16_sve
    mov             x8, x0
    mov             x9, x2
    satd_32x16_sve
    add             x7, x7, x6
    add             x0, x8, #32
    add             x2, x9, #32
    satd_32x16_sve
    add             x7, x7, x6
.endm

function PFX(pixel_satd_32x8_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
    mov             x4, x0
    mov             x5, x2
    movi            v30.2d, #0
    movi            v31.2d, #0
    pixel_satd_32x8_sve
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_32x16_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    satd_32x16_sve
    mov             x0, x6
    ret             x10
endfunc

function PFX(pixel_satd_32x24_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    satd_32x16_sve
    movi            v30.2d, #0
    movi            v31.2d, #0
    sub             x0, x0, #16
    sub             x2, x2, #16
    pixel_satd_32x8_sve
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    add             x0, x0, x6
    ret             x10
endfunc

function PFX(pixel_satd_32x32_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
    satd_32x16_sve
    sub             x0, x0, #16
    sub             x2, x2, #16
    add             x7, x7, x6
    satd_32x16_sve
    add             x0, x7, x6
    ret             x10
endfunc

function PFX(pixel_satd_32x48_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
.rept 2
    satd_32x16_sve
    sub             x0, x0, #16
    sub             x2, x2, #16
    add             x7, x7, x6
.endr
    satd_32x16_sve
    add             x0, x7, x6
    ret             x10
endfunc

function PFX(pixel_satd_32x64_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
.rept 3
    satd_32x16_sve
    sub             x0, x0, #16
    sub             x2, x2, #16
    add             x7, x7, x6
.endr
    satd_32x16_sve
    add             x0, x7, x6
    ret             x10
endfunc

function PFX(pixel_satd_64x16_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
    satd_64x16_sve
    mov             x0, x7
    ret             x10
endfunc

function PFX(pixel_satd_64x32_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
    satd_64x16_sve
    sub             x0, x0, #48
    sub             x2, x2, #48
    satd_64x16_sve
    mov             x0, x7
    ret             x10
endfunc

function PFX(pixel_satd_64x48_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
.rept 2
    satd_64x16_sve
    sub             x0, x0, #48
    sub             x2, x2, #48
.endr
    satd_64x16_sve
    mov             x0, x7
    ret             x10
endfunc

function PFX(pixel_satd_64x64_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
.rept 3
    satd_64x16_sve
    sub             x0, x0, #48
    sub             x2, x2, #48
.endr
    satd_64x16_sve
    mov             x0, x7
    ret             x10
endfunc

function PFX(pixel_satd_48x64_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
    mov             x8, x0
    mov             x9, x2
.rept 3
    satd_32x16_sve
    sub             x0, x0, #16
    sub             x2, x2, #16
    add             x7, x7, x6
.endr
    satd_32x16_sve
    add             x7, x7, x6

    add             x0, x8, #32
    add             x2, x9, #32
    pixel_satd_16x32_sve
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w6, v0.s[0]
    add             x7, x7, x6

    movi            v30.2d, #0
    movi            v31.2d, #0
    pixel_satd_16x32_sve
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w6, v0.s[0]
    add             x0, x7, x6
    ret             x10
endfunc

function PFX(sa8d_8x8_sve), export=0
    LOAD_DIFF_8x4_sve   z16.h, z17.h, z18.h, z19.h
    LOAD_DIFF_8x4_sve   z20.h, z21.h, z22.h, z23.h
    HADAMARD4_V     z16.h, z18.h, z17.h, z19.h, z0.h, z2.h, z1.h, z3.h
    HADAMARD4_V     z20.h, z21.h, z22.h, z23.h, z0.h, z1.h, z2.h, z3.h
    SUMSUB_ABCD     z0.h, z16.h, z1.h, z17.h, z16.h, z20.h, z17.h, z21.h
    SUMSUB_ABCD     z2.h, z18.h, z3.h, z19.h, z18.h, z22.h, z19.h, z23.h
    trn4            z4.h, z5.h, z6.h, z7.h, z0.h, z1.h, z2.h, z3.h
    trn4            z20.h, z21.h, z22.h, z23.h, z16.h, z17.h, z18.h, z19.h
    SUMSUB_ABCD     z2.h, z3.h, z24.h, z25.h, z20.h, z21.h, z4.h, z5.h
    SUMSUB_ABCD     z0.h, z1.h, z4.h, z5.h, z22.h, z23.h, z6.h, z7.h
    trn4            z20.s, z22.s, z21.s, z23.s, z2.s, z0.s, z3.s, z1.s
    trn4            z16.s, z18.s, z17.s, z19.s, z24.s, z4.s, z25.s, z5.s
    SUMSUB_ABCD     z0.h, z2.h, z1.h, z3.h, z20.h, z22.h, z21.h, z23.h
    SUMSUB_ABCD     z4.h, z6.h, z5.h, z7.h, z16.h, z18.h, z17.h, z19.h
    trn4            z16.d, z20.d, z17.d, z21.d, z0.d, z4.d, z1.d, z5.d
    trn4            z18.d, z22.d, z19.d, z23.d, z2.d, z6.d, z3.d, z7.d
    ABS8_SVE        z16.h, z17.h, z18.h, z19.h, z20.h, z21.h, z22.h, z23.h, p0
    smax            z16.h, p0/m, z16.h, z20.h
    smax            z17.h, p0/m, z17.h, z21.h
    smax            z18.h, p0/m, z18.h, z22.h
    smax            z19.h, p0/m, z19.h, z23.h
    add             z0.h, z16.h, z17.h
    add             z1.h, z18.h, z19.h
    ret
endfunc

function PFX(pixel_sa8d_8x8_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(sa8d_8x8_sve)
    add             z0.h, z0.h, z1.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    add             w0, w0, #1
    lsr             w0, w0, #1
    ret             x10
endfunc

function PFX(pixel_sa8d_8x16_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(sa8d_8x8_sve)
    add             z0.h, z0.h, z1.h
    uaddlv          s0, v0.8h
    mov             w5, v0.s[0]
    add             w5, w5, #1
    lsr             w5, w5, #1
    bl              PFX(sa8d_8x8_sve)
    add             z0.h, z0.h, z1.h
    uaddlv          s0, v0.8h
    mov             w4, v0.s[0]
    add             w4, w4, #1
    lsr             w4, w4, #1
    add             w0, w4, w5
    ret             x10
endfunc

// Migrating the following macro to sve will decrease
// the performance as we need extra z30 and z31 initializations
// to zero and uaddvl which has greater latancy than addv
.macro sa8d_16x16_sve reg
    bl              PFX(sa8d_8x8_sve)
    uaddlp          v30.4s, v0.8h
    uaddlp          v31.4s, v1.8h
    bl              PFX(sa8d_8x8_sve)
    uadalp          v30.4s, v0.8h
    uadalp          v31.4s, v1.8h
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    bl              PFX(sa8d_8x8_sve)
    uadalp          v30.4s, v0.8h
    uadalp          v31.4s, v1.8h
    bl              PFX(sa8d_8x8_sve)
    uadalp          v30.4s, v0.8h
    uadalp          v31.4s, v1.8h
    add             v0.4s, v30.4s, v31.4s
    addv            s0, v0.4s
    mov             \reg, v0.s[0]
    add             \reg, \reg, #1
    lsr             \reg, \reg, #1
.endm

function PFX(pixel_sa8d_16x16_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    sa8d_16x16_sve w0
    ret             x10
endfunc

function PFX(pixel_sa8d_16x32_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    sa8d_16x16_sve w4
    sub             x0, x0, #8
    sub             x2, x2, #8
    sa8d_16x16_sve w5
    add             w0, w4, w5
    ret             x10
endfunc

function PFX(pixel_sa8d_32x32_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    sa8d_16x16_sve w4
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16_sve w5
    sub             x0, x0, #24
    sub             x2, x2, #24
    sa8d_16x16_sve w6
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16_sve w7
    add             w4, w4, w5
    add             w6, w6, w7
    add             w0, w4, w6
    ret             x10
endfunc

function PFX(pixel_sa8d_32x64_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             w11, #4
    mov             w9, #0
.loop_sa8d_32_sve:
    sub             w11, w11, #1
    sa8d_16x16_sve w4
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16_sve w5
    add             w4, w4, w5
    add             w9, w9, w4
    sub             x0, x0, #24
    sub             x2, x2, #24
    cbnz            w11, .loop_sa8d_32_sve
    mov             w0, w9
    ret             x10
endfunc

function PFX(pixel_sa8d_64x64_sve)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             w11, #4
    mov             w9, #0
.loop_sa8d_64_sve:
    sub             w11, w11, #1
    sa8d_16x16_sve w4
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16_sve w5
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16_sve w6
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16_sve w7
    add             w4, w4, w5
    add             w6, w6, w7
    add             w8, w4, w6
    add             w9, w9, w8

    sub             x0, x0, #56
    sub             x2, x2, #56
    cbnz            w11, .loop_sa8d_64_sve
    mov             w0, w9
    ret             x10
endfunc

// int psyCost_pp(const pixel* source, intptr_t sstride, const pixel* recon, intptr_t rstride)
function PFX(psyCost_4x4_sve)
    ptrue           p0.h, vl4
    ptrue           p2.h, vl8

    ld1b            {z0.h}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z1.h}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z2.h}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z3.h}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z4.h}, p0/z, [x2]
    add             x2, x2, x3
    ld1b            {z5.h}, p0/z, [x2]
    add             x2, x2, x3
    ld1b            {z6.h}, p0/z, [x2]
    add             x2, x2, x3
    ld1b            {z7.h}, p0/z, [x2]
    add             x2, x2, x3

    add             z8.h, z0.h, z1.h
    add             z9.h, z2.h, z3.h
    sub             z10.h, z0.h, z1.h
    sub             z11.h, z2.h, z3.h
    add             z12.h, z4.h, z5.h
    add             z13.h, z6.h, z7.h
    sub             z14.h, z4.h, z5.h
    sub             z15.h, z6.h, z7.h

    add             z30.h, z8.h, z9.h
    sub             z31.h, z8.h, z9.h
    add             z22.h, z10.h, z11.h
    sub             z23.h, z10.h, z11.h

    add             z16.h, z12.h, z13.h
    sub             z17.h, z12.h, z13.h
    add             z26.h, z14.h, z15.h
    sub             z27.h, z14.h, z15.h

    // Better use NEON instrauctions here
    mov             v30.d[1], v22.d[0]
    mov             v31.d[1], v23.d[0]
    trn1            v22.8h, v30.8h, v31.8h
    trn2            v23.8h, v30.8h, v31.8h
    mov             v16.d[1], v26.d[0]
    mov             v17.d[1], v27.d[0]
    trn1            v26.8h, v16.8h, v17.8h
    trn2            v27.8h, v16.8h, v17.8h

    add             z28.h, z22.h, z23.h
    sub             z29.h, z22.h, z23.h
    add             z18.h, z26.h, z27.h
    sub             z19.h, z26.h, z27.h

    add             z20.h, z0.h, z1.h
    add             z16.h, z2.h, z3.h
    add             z21.h, z4.h, z5.h
    add             z17.h, z6.h, z7.h
    // Take advantage of NEON instructions here
    // in order to reduce the namber of trn instructions
    // later
    mov             v20.d[1], v16.d[0]
    mov             v21.d[1], v17.d[0]

    trn1            z30.s, z28.s, z29.s
    trn2            z31.s, z28.s, z29.s
    trn1            z16.s, z18.s, z19.s
    trn2            z17.s, z18.s, z19.s
    abs             z30.h, p2/m, z30.h
    abs             z16.h, p2/m, z16.h
    abs             z31.h, p2/m, z31.h
    abs             z17.h, p2/m, z17.h

    // sve uaddv has 8 latency. So, use NEON addlv
    uaddlv          s20, v20.8h
    uaddlv          s21, v21.8h
    mov             v20.s[1], v21.s[0]

    smax            z30.h, p2/m, z30.h, z31.h
    smax            z16.h, p2/m, z16.h, z17.h

    trn1            z4.d, z30.d, z16.d
    trn2            z5.d, z30.d, z16.d
    add             z30.h, z4.h, z5.h
    mov             v4.d[0], v30.d[1]

    mov             v0.16b, v30.16b
    uaddlv          s0, v0.4h
    uaddlv          s4, v4.4h

    ushr            v20.2s, v20.2s, #2
    mov             v0.s[1], v4.s[0]
    sub             v0.2s, v0.2s, v20.2s
    mov             w0, v0.s[0]
    mov             w1, v0.s[1]
    subs            w0, w0, w1
    cneg            w0, w0, mi

    ret
endfunc

/********* ssim ***********/
// uint32_t quant_c(const int16_t* coef, const int32_t* quantCoeff, int32_t* deltaU, int16_t* qCoef, int qBits, int add, int numCoeff)
// No need to fully use sve instructions for this function
function PFX(quant_sve)
    mov             w9, #1
    lsl             w9, w9, w4
    mov             z0.s, w9
    neg             w9, w4
    mov             z1.s, w9
    add             w9, w9, #8
    mov             z2.s, w9
    mov             z3.s, w5

    lsr             w6, w6, #2
    eor             z4.d, z4.d, z4.d
    eor             w10, w10, w10
    eor             z17.d, z17.d, z17.d

.loop_quant_sve:
    ld1             {v18.4h}, [x0], #8
    ld1             {v7.4s}, [x1], #16
    sxtl            v6.4s, v18.4h

    cmlt            v5.4s, v6.4s, #0

    abs             v6.4s, v6.4s


    mul             v6.4s, v6.4s, v7.4s

    add             v7.4s, v6.4s, v3.4s
    sshl            v7.4s, v7.4s, v1.4s

    mls             v6.4s, v7.4s, v0.s[0]
    sshl            v16.4s, v6.4s, v2.4s
    st1             {v16.4s}, [x2], #16

    // numsig
    cmeq            v16.4s, v7.4s, v17.4s
    add             v4.4s, v4.4s, v16.4s
    add             w10, w10, #4

    // level *= sign
    eor             z16.d, z7.d, z5.d
    sub             v16.4s, v16.4s, v5.4s
    sqxtn           v5.4h, v16.4s
    st1             {v5.4h}, [x3], #8

    subs            w6, w6, #1
    b.ne             .loop_quant_sve

    addv            s4, v4.4s
    mov             w9, v4.s[0]
    add             w0, w10, w9
    ret
endfunc

// uint32_t nquant_c(const int16_t* coef, const int32_t* quantCoeff, int16_t* qCoef, int qBits, int add, int numCoeff)
// No need to fully use sve instructions for this function
function PFX(nquant_sve)
    neg             x12, x3
    mov             z0.s, w12             // q0= -qbits
    mov             z1.s, w4              // add

    lsr             w5, w5, #2
    movi            v4.2d, #0              // v4= accumulate numsig
    mov             x4, #0
    movi            v22.2d, #0

.loop_nquant_sve:
    ld1             {v16.4h}, [x0], #8
    sub             w5, w5, #1
    sxtl            v19.4s, v16.4h         // v19 = coef[blockpos]

    cmlt            v18.4s, v19.4s, #0     // v18 = sign

    abs             v19.4s, v19.4s         // v19 = level=abs(coef[blockpos])
    ld1             {v20.4s}, [x1], #16    // v20 = quantCoeff[blockpos]
    mul             v19.4s, v19.4s, v20.4s // v19 = tmplevel = abs(level) * quantCoeff[blockpos];

    add             v20.4s, v19.4s, v1.4s  // v20 = tmplevel+add
    sshl            v20.4s, v20.4s, v0.4s  // v20 = level =(tmplevel+add) >> qbits

    // numsig
    cmeq            v21.4s, v20.4s, v22.4s
    add             v4.4s, v4.4s, v21.4s
    add             x4, x4, #4

    eor             z21.d, z20.d, z18.d
    sub             v21.4s, v21.4s, v18.4s
    sqxtn           v16.4h, v21.4s
    abs             v17.4h, v16.4h
    st1             {v17.4h}, [x2], #8

    cbnz            w5, .loop_nquant_sve

    uaddlv          d4, v4.4s
    fmov            x12, d4
    add             x0, x4, x12
    ret
endfunc

// void weight_pp_c(const pixel* src, pixel* dst, intptr_t stride, int width, int height, int w0, int round, int shift, int offset)
function PFX(weight_pp_sve)
    sub             x2, x2, x3
    ldr             w9, [sp]              // offset
    lsl             w5, w5, #6            // w0 << correction

    // count trailing zeros in w5 and compare against shift right amount.
    rbit            w10, w5
    clz             w10, w10
    cmp             w10, w7
    b.lt            .unfoldedShift_sve

    // shift right only removes trailing zeros: hoist LSR out of the loop.
    lsr             w10, w5, w7           // w0 << correction >> shift
    mov             z25.b, w10
    lsr             w6, w6, w7            // round >> shift
    add             w6, w6, w9            // round >> shift + offset
    mov             z26.h, w6

    // Check arithmetic range.
    mov             w11, #255
    madd            w11, w11, w10, w6
    add             w11, w11, w9
    lsr             w11, w11, #16
    cbnz            w11, .widenTo32Bit_sve

    // 16-bit arithmetic is enough.
// umull has better performance than umull{b,t}.
// So, better use NEON instructions here
.loopHpp_sve:
    mov             x12, x3
.loopWpp_sve:
    ldr             q0, [x0], #16
    sub             x12, x12, #16
    umull           v1.8h, v0.8b, v25.8b  // val *= w0 << correction >> shift
    umull2          v2.8h, v0.16b, v25.16b
    add             v1.8h, v1.8h, v26.8h  // val += round >> shift + offset
    add             v2.8h, v2.8h, v26.8h
    sqxtun          v0.8b, v1.8h          // val = x265_clip(val)
    sqxtun2         v0.16b, v2.8h
    str             q0, [x1], #16
    cbnz            x12, .loopWpp_sve
    add             x1, x1, x2
    add             x0, x0, x2
    sub             x4, x4, #1
    cbnz            x4, .loopHpp_sve
    ret

    // 32-bit arithmetic is needed.
// umull has better performance than umull{b,t}.
// So, better use NEON instructions here
.widenTo32Bit_sve:
.loopHpp32_sve:
    mov             x12, x3
.loopWpp32_sve:
    ldr             d0, [x0], #8
    sub             x12, x12, #8
    uxtl            v0.8h, v0.8b
    umull           v1.4s, v0.4h, v25.4h  // val *= w0 << correction >> shift
    umull2          v2.4s, v0.8h, v25.8h
    add             v1.4s, v1.4s, v26.4s  // val += round >> shift + offset
    add             v2.4s, v2.4s, v26.4s
    sqxtn           v0.4h, v1.4s          // val = x265_clip(val)
    sqxtn2          v0.8h, v2.4s
    sqxtun          v0.8b, v0.8h
    str             d0, [x1], #8
    cbnz            x12, .loopWpp32_sve
    add             x1, x1, x2
    add             x0, x0, x2
    sub             x4, x4, #1
    cbnz            x4, .loopHpp32_sve
    ret

    // The shift right cannot be moved out of the loop.
.unfoldedShift_sve:
    mov             z25.h, w5            // w0 << correction
    mov             z26.s, w6            // round
    neg             w7, w7                // -shift
    mov             z27.s, w7
    mov             z29.s, w9            // offset
.loopHppUS_sve:
    mov             x12, x3
// umull has better performance than umull{b,t}.
// So, better use NEON instructions here
.loopWppUS_sve:
    ldr             d0, [x0], #8
    sub             x12, x12, #8
    uxtl            v0.8h, v0.8b
    umull           v1.4s, v0.4h, v25.4h  // val *= w0
    umull2          v2.4s, v0.8h, v25.8h
    add             v1.4s, v1.4s, v26.4s  // val += round
    add             v2.4s, v2.4s, v26.4s
    sshl            v1.4s, v1.4s, v27.4s  // val >>= shift
    sshl            v2.4s, v2.4s, v27.4s
    add             v1.4s, v1.4s, v29.4s  // val += offset
    add             v2.4s, v2.4s, v29.4s
    sqxtn           v0.4h, v1.4s          // val = x265_clip(val)
    sqxtn2          v0.8h, v2.4s
    sqxtun          v0.8b, v0.8h
    str             d0, [x1], #8
    cbnz            x12, .loopWppUS_sve
    add             x1, x1, x2
    add             x0, x0, x2
    sub             x4, x4, #1
    cbnz            x4, .loopHppUS_sve
    ret
endfunc

// uint32_t costCoeffNxN(
//    uint16_t *scan,        // x0
//    coeff_t *coeff,        // x1
//    intptr_t trSize,       // x2
//    uint16_t *absCoeff,    // x3
//    uint8_t *tabSigCtx,    // x4
//    uint16_t scanFlagMask, // x5
//    uint8_t *baseCtx,      // x6
//    int offset,            // x7
//    int scanPosSigOff,     // sp
//    int subPosBase)        // sp + 8
function PFX(costCoeffNxN_sve)
    // abs(coeff)
    // Better use NEON instructions here
    // to avoid 4 additional add instructions
    add             x2, x2, x2
    ld1             {v1.d}[0], [x1], x2
    ld1             {v1.d}[1], [x1], x2
    ld1             {v2.d}[0], [x1], x2
    ld1             {v2.d}[1], [x1], x2
    abs             v1.8h, v1.8h
    abs             v2.8h, v2.8h

    // WARNING: beyond-bound read here!
    // loading scan table
    ldr             w2, [sp]
    eor             w15, w2, #15
    add             x1, x0, x15, lsl #1
    ldp             q20, q21, [x1]
    uzp1            v20.16b, v20.16b, v21.16b
    movi            v21.16b, #15
    eor             v0.16b, v20.16b, v21.16b

    // reorder coeff
    uzp1           v22.16b, v1.16b, v2.16b
    uzp2           v23.16b, v1.16b, v2.16b
    tbl            v24.16b, {v22.16b}, v0.16b
    tbl            v25.16b, {v23.16b}, v0.16b
    zip1           v2.16b, v24.16b, v25.16b
    zip2           v3.16b, v24.16b, v25.16b

    // loading tabSigCtx (+offset)
    ldr             q1, [x4]
    tbl             v1.16b, {v1.16b}, v0.16b
    mov             z4.b, w7
    movi            v5.16b, #0
    tbl             v4.16b, {v4.16b}, v5.16b
    add             v1.16b, v1.16b, v4.16b

    // register mapping
    // x0 - sum
    // x1 - entropyStateBits
    // v1 - sigCtx
    // {v3,v2} - abs(coeff)
    // x2 - scanPosSigOff
    // x3 - absCoeff
    // x4 - numNonZero
    // x5 - scanFlagMask
    // x6 - baseCtx
    mov             x0, #0
    movrel          x1, x265_entropyStateBits
    mov             x4, #0
    mov             x11, #0
    movi            v31.16b, #0
    cbz             x2, .idx_zero_sve
.loop_ccnn_sve:
//   {
//        const uint32_t cnt = tabSigCtx[blkPos] + offset + posOffset;
//        ctxSig = cnt & posZeroMask;
//        const uint32_t mstate = baseCtx[ctxSig];
//        const uint32_t mps = mstate & 1;
//        const uint32_t stateBits = x265_entropyStateBits[mstate ^ sig];
//        uint32_t nextState = (stateBits >> 24) + mps;
//        if ((mstate ^ sig) == 1)
//            nextState = sig;
//        baseCtx[ctxSig] = (uint8_t)nextState;
//        sum += stateBits;
//    }
//    absCoeff[numNonZero] = tmpCoeff[blkPos];
//    numNonZero += sig;
//    scanPosSigOff--;

    add             x13, x3, x4, lsl #1
    sub             x2, x2, #1
    str             h2, [x13]             // absCoeff[numNonZero] = tmpCoeff[blkPos]
    fmov            w14, s1               // x14 = ctxSig
    uxtb            w14, w14
    ubfx            w11, w5, #0, #1       // x11 = sig
    lsr             x5, x5, #1
    add             x4, x4, x11           // numNonZero += sig
    ext             v1.16b, v1.16b, v31.16b, #1
    ext             v2.16b, v2.16b, v3.16b, #2
    ext             v3.16b, v3.16b, v31.16b, #2
    ldrb            w9, [x6, x14]         // mstate = baseCtx[ctxSig]
    and             w10, w9, #1           // mps = mstate & 1
    eor             w9, w9, w11           // x9 = mstate ^ sig
    add             x12, x1, x9, lsl #2
    ldr             w13, [x12]
    add             w0, w0, w13           // sum += x265_entropyStateBits[mstate ^ sig]
    ldrb            w13, [x12, #3]
    add             w10, w10, w13         // nextState = (stateBits >> 24) + mps
    cmp             w9, #1
    csel            w10, w11, w10, eq
    strb            w10, [x6, x14]
    cbnz            x2, .loop_ccnn_sve
.idx_zero_sve:

    add             x13, x3, x4, lsl #1
    add             x4, x4, x15
    str             h2, [x13]              // absCoeff[numNonZero] = tmpCoeff[blkPos]

    ldr             x9, [sp, #8]           // subPosBase
    uxth            w9, w9
    cmp             w9, #0
    cset            x2, eq
    add             x4, x4, x2
    cbz             x4, .exit_ccnn_sve

    sub             w2, w2, #1
    uxtb            w2, w2
    fmov            w3, s1
    and             w2, w2, w3

    ldrb            w3, [x6, x2]         // mstate = baseCtx[ctxSig]
    eor             w4, w5, w3            // x5 = mstate ^ sig
    and             w3, w3, #1            // mps = mstate & 1
    add             x1, x1, x4, lsl #2
    ldr             w11, [x1]
    ldrb            w12, [x1, #3]
    add             w0, w0, w11           // sum += x265_entropyStateBits[mstate ^ sig]
    add             w3, w3, w12           // nextState = (stateBits >> 24) + mps
    cmp             w4, #1
    csel            w3, w5, w3, eq
    strb            w3, [x6, x2]
.exit_ccnn_sve:
    ubfx            w0, w0, #0, #24
    ret
endfunc
