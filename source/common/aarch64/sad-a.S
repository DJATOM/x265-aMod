/*****************************************************************************
 * Copyright (C) 2020-2021 MulticoreWare, Inc
 *
 * Authors: Hongbin Liu <liuhongbin1@huawei.com>
 *          Sebastian Pop <spop@amazon.com>
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

.arch armv8-a+sve2

#ifdef __APPLE__
.section __RODATA,__rodata
#else
.section .rodata
#endif

.align 4

.text

.macro SAD_START_4 f
    ld1             {v0.s}[0], [x0], x1
    ld1             {v0.s}[1], [x0], x1
    ld1             {v1.s}[0], [x2], x3
    ld1             {v1.s}[1], [x2], x3
    \f              v16.8h, v0.8b, v1.8b
.endm

.macro SAD_4 h
.rept \h / 2 - 1
    SAD_START_4 uabal
.endr
.endm

.macro SAD_START_8 f
    ld1             {v0.8b}, [x0], x1
    ld1             {v1.8b}, [x2], x3
    ld1             {v2.8b}, [x0], x1
    ld1             {v3.8b}, [x2], x3
    \f              v16.8h, v0.8b, v1.8b
    \f              v17.8h, v2.8b, v3.8b
.endm

.macro SAD_8 h
.rept \h / 2 - 1
    SAD_START_8 uabal
.endr
.endm

.macro SAD_START_16 f
    ld1             {v0.16b}, [x0], x1
    ld1             {v1.16b}, [x2], x3
    ld1             {v2.16b}, [x0], x1
    ld1             {v3.16b}, [x2], x3
    \f              v16.8h, v0.8b, v1.8b
    \f\()2          v17.8h, v0.16b, v1.16b
    uabal           v16.8h, v2.8b, v3.8b
    uabal2          v17.8h, v2.16b, v3.16b
.endm

.macro SAD_16 h
.rept \h / 2 - 1
    SAD_START_16 uabal
.endr
.endm

.macro SAD_START_32
    movi            v16.16b, #0
    movi            v17.16b, #0
    movi            v18.16b, #0
    movi            v19.16b, #0
.endm

.macro SAD_32
    ld1             {v0.16b-v1.16b}, [x0], x1
    ld1             {v2.16b-v3.16b}, [x2], x3
    ld1             {v4.16b-v5.16b}, [x0], x1
    ld1             {v6.16b-v7.16b}, [x2], x3
    uabal           v16.8h, v0.8b, v2.8b
    uabal2          v17.8h, v0.16b, v2.16b
    uabal           v18.8h, v1.8b, v3.8b
    uabal2          v19.8h, v1.16b, v3.16b
    uabal           v16.8h, v4.8b, v6.8b
    uabal2          v17.8h, v4.16b, v6.16b
    uabal           v18.8h, v5.8b, v7.8b
    uabal2          v19.8h, v5.16b, v7.16b
.endm

.macro SAD_END_32
    add             v16.8h, v16.8h, v17.8h
    add             v17.8h, v18.8h, v19.8h
    add             v16.8h, v16.8h, v17.8h
    uaddlv          s0, v16.8h
    fmov            w0, s0
    ret
.endm

.macro SAD_START_64
    movi            v16.16b, #0
    movi            v17.16b, #0
    movi            v18.16b, #0
    movi            v19.16b, #0
    movi            v20.16b, #0
    movi            v21.16b, #0
    movi            v22.16b, #0
    movi            v23.16b, #0
.endm

.macro SAD_64
    ld1             {v0.16b-v3.16b}, [x0], x1
    ld1             {v4.16b-v7.16b}, [x2], x3
    ld1             {v24.16b-v27.16b}, [x0], x1
    ld1             {v28.16b-v31.16b}, [x2], x3
    uabal           v16.8h, v0.8b, v4.8b
    uabal2          v17.8h, v0.16b, v4.16b
    uabal           v18.8h, v1.8b, v5.8b
    uabal2          v19.8h, v1.16b, v5.16b
    uabal           v20.8h, v2.8b, v6.8b
    uabal2          v21.8h, v2.16b, v6.16b
    uabal           v22.8h, v3.8b, v7.8b
    uabal2          v23.8h, v3.16b, v7.16b

    uabal           v16.8h, v24.8b, v28.8b
    uabal2          v17.8h, v24.16b, v28.16b
    uabal           v18.8h, v25.8b, v29.8b
    uabal2          v19.8h, v25.16b, v29.16b
    uabal           v20.8h, v26.8b, v30.8b
    uabal2          v21.8h, v26.16b, v30.16b
    uabal           v22.8h, v27.8b, v31.8b
    uabal2          v23.8h, v27.16b, v31.16b
.endm

.macro SAD_END_64
    add             v16.8h, v16.8h, v17.8h
    add             v17.8h, v18.8h, v19.8h
    add             v16.8h, v16.8h, v17.8h
    uaddlp          v16.4s, v16.8h
    add             v18.8h, v20.8h, v21.8h
    add             v19.8h, v22.8h, v23.8h
    add             v17.8h, v18.8h, v19.8h
    uaddlp          v17.4s, v17.8h
    add             v16.4s, v16.4s, v17.4s
    uaddlv          d0, v16.4s
    fmov            x0, d0
    ret
.endm

.macro SAD_START_12
    movrel          x12, sad12_mask
    ld1             {v31.16b}, [x12]
    movi            v16.16b, #0
    movi            v17.16b, #0
.endm

.macro SAD_12
    ld1             {v0.16b}, [x0], x1
    and             v0.16b, v0.16b, v31.16b
    ld1             {v1.16b}, [x2], x3
    and             v1.16b, v1.16b, v31.16b
    ld1             {v2.16b}, [x0], x1
    and             v2.16b, v2.16b, v31.16b
    ld1             {v3.16b}, [x2], x3
    and             v3.16b, v3.16b, v31.16b
    uabal           v16.8h, v0.8b, v1.8b
    uabal2          v17.8h, v0.16b, v1.16b
    uabal           v16.8h, v2.8b, v3.8b
    uabal2          v17.8h, v2.16b, v3.16b
.endm

.macro SAD_END_12
    add             v16.8h, v16.8h, v17.8h
    uaddlv          s0, v16.8h
    fmov            w0, s0
    ret
.endm

.macro SAD_START_24
    movi            v16.16b, #0
    movi            v17.16b, #0
    movi            v18.16b, #0
    sub             x1, x1, #16
    sub             x3, x3, #16
.endm

.macro SAD_24
    ld1             {v0.16b}, [x0], #16
    ld1             {v1.8b}, [x0], x1
    ld1             {v2.16b}, [x2], #16
    ld1             {v3.8b}, [x2], x3
    ld1             {v4.16b}, [x0], #16
    ld1             {v5.8b}, [x0], x1
    ld1             {v6.16b}, [x2], #16
    ld1             {v7.8b}, [x2], x3
    uabal           v16.8h, v0.8b, v2.8b
    uabal2          v17.8h, v0.16b, v2.16b
    uabal           v18.8h, v1.8b, v3.8b
    uabal           v16.8h, v4.8b, v6.8b
    uabal2          v17.8h, v4.16b, v6.16b
    uabal           v18.8h, v5.8b, v7.8b
.endm

.macro SAD_END_24
    add             v16.8h, v16.8h, v17.8h
    add             v16.8h, v16.8h, v18.8h
    uaddlv          s0, v16.8h
    fmov            w0, s0
    ret
.endm

.macro SAD_START_48
    movi            v16.16b, #0
    movi            v17.16b, #0
    movi            v18.16b, #0
    movi            v19.16b, #0
    movi            v20.16b, #0
    movi            v21.16b, #0
.endm

.macro SAD_48
    ld1             {v0.16b-v2.16b}, [x0], x1
    ld1             {v4.16b-v6.16b}, [x2], x3
    ld1             {v24.16b-v26.16b}, [x0], x1
    ld1             {v28.16b-v30.16b}, [x2], x3
    uabal           v16.8h, v0.8b, v4.8b
    uabal2          v17.8h, v0.16b, v4.16b
    uabal           v18.8h, v1.8b, v5.8b
    uabal2          v19.8h, v1.16b, v5.16b
    uabal           v20.8h, v2.8b, v6.8b
    uabal2          v21.8h, v2.16b, v6.16b

    uabal           v16.8h, v24.8b, v28.8b
    uabal2          v17.8h, v24.16b, v28.16b
    uabal           v18.8h, v25.8b, v29.8b
    uabal2          v19.8h, v25.16b, v29.16b
    uabal           v20.8h, v26.8b, v30.8b
    uabal2          v21.8h, v26.16b, v30.16b
.endm

.macro SAD_END_48
    add             v16.8h, v16.8h, v17.8h
    add             v17.8h, v18.8h, v19.8h
    add             v16.8h, v16.8h, v17.8h
    uaddlv          s0, v16.8h
    fmov            w0, s0
    add             v18.8h, v20.8h, v21.8h
    uaddlv          s1, v18.8h
    fmov            w1, s1
    add             w0, w0, w1
    ret
.endm

.macro SAD_SVE2_4 h
    mov             z16.d, #0
    ptrue           p0.h, vl4
.rept \h
    ld1b            {z0.h}, p0/z, [x0]
    ld1b            {z1.h}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    uaba            z16.h, z0.h, z1.h
.endr
    uaddv           d5, p0, z16.h
    fmov            w0, s5
    ret
.endm

.macro SAD_SVE2_8 h
    mov             z16.d, #0
    ptrue           p0.h, vl8
.rept \h
    ld1b            {z0.h}, p0/z, [x0]
    ld1b            {z1.h}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    uaba            z16.h, z0.h, z1.h
.endr
    uaddv           d5, p0, z16.h
    fmov            w0, s5
    ret
.endm

.macro SAD_SVE2_16 h
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sad_16x\h
    mov             z16.d, #0
    ptrue           p0.b, vl16
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z2.b}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    uabalb          z16.h, z0.b, z2.b
    uabalt          z16.h, z0.b, z2.b
.endr
    uaddv           d5, p0, z16.h
    fmov            w0, s5
    ret
.vl_gt_16_pixel_sad_16x\h\():
    mov             z16.d, #0
    ptrue           p0.h, vl16
.rept \h
    ld1b            {z0.h}, p0/z, [x0]
    ld1b            {z2.h}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    uaba            z16.h, z0.h, z2.h
.endr
    uaddv           d5, p0, z16.h
    fmov            w0, s5
    ret
.endm

.macro SAD_SVE2_32 h
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sad_32x\h
    mov             z16.d, #0
    ptrue           p0.b, vl16
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z4.b}, p0/z, [x2]
    ld1b            {z5.b}, p0/z, [x2, #1, mul vl]
    add             x0, x0, x1
    add             x2, x2, x3
    uabalb          z16.h, z0.b, z4.b
    uabalt          z16.h, z0.b, z4.b
    uabalb          z16.h, z1.b, z5.b
    uabalt          z16.h, z1.b, z5.b
.endr
    uaddv           d5, p0, z16.h
    fmov            w0, s5
    ret
.vl_gt_16_pixel_sad_32x\h\():
    ptrue           p0.b, vl32
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z4.b}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    uabalb          z16.h, z0.b, z4.b
    uabalt          z16.h, z0.b, z4.b
.endr
    uaddv           d5, p0, z16.h
    fmov            w0, s5
    ret
.endm

.macro SAD_SVE2_64 h
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sad_64x\h
    mov             z16.d, #0
    mov             z17.d, #0
    mov             z18.d, #0
    mov             z19.d, #0
    mov             z20.d, #0
    mov             z21.d, #0
    mov             z22.d, #0
    mov             z23.d, #0
    mov             z24.d, #0
    ptrue           p0.b, vl16
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z2.b}, p0/z, [x0, #2, mul vl]
    ld1b            {z3.b}, p0/z, [x0, #3, mul vl]
    ld1b            {z4.b}, p0/z, [x2]
    ld1b            {z5.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z6.b}, p0/z, [x2, #2, mul vl]
    ld1b            {z7.b}, p0/z, [x2, #3, mul vl]
    add             x0, x0, x1
    add             x2, x2, x3
    uabalb          z16.h, z0.b, z4.b
    uabalt          z17.h, z0.b, z4.b
    uabalb          z18.h, z1.b, z5.b
    uabalt          z19.h, z1.b, z5.b
    uabalb          z20.h, z2.b, z6.b
    uabalt          z21.h, z2.b, z6.b
    uabalb          z22.h, z3.b, z7.b
    uabalt          z23.h, z3.b, z7.b
.endr
    add             z16.h, z16.h, z17.h
    add             z17.h, z18.h, z19.h
    add             z16.h, z16.h, z17.h
    uadalp          z24.s, p0/m, z16.h
    add             z18.h, z20.h, z21.h
    add             z19.h, z22.h, z23.h
    add             z17.h, z18.h, z19.h
    uadalp          z24.s, p0/m, z17.h
    uaddv           d5, p0, z24.s
    fmov            x0, d5
    ret
.vl_gt_16_pixel_sad_64x\h\():
    cmp             x9, #48
    bgt             .vl_gt_48_pixel_sad_64x\h
    mov             z16.d, #0
    mov             z17.d, #0
    mov             z18.d, #0
    mov             z19.d, #0
    mov             z24.d, #0
    ptrue           p0.b, vl32
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z4.b}, p0/z, [x2]
    ld1b            {z5.b}, p0/z, [x2, #1, mul vl]
    add             x0, x0, x1
    add             x2, x2, x3
    uabalb          z16.h, z0.b, z4.b
    uabalt          z17.h, z0.b, z4.b
    uabalb          z18.h, z1.b, z5.b
    uabalt          z19.h, z1.b, z5.b
.endr
    add             z16.h, z16.h, z17.h
    add             z17.h, z18.h, z19.h
    add             z16.h, z16.h, z17.h
    uadalp          z24.s, p0/m, z16.h
    uaddv           d5, p0, z24.s
    fmov            x0, d5
    ret
.vl_gt_48_pixel_sad_64x\h\():
    mov             z16.d, #0
    mov             z17.d, #0
    mov             z24.d, #0
    ptrue           p0.b, vl64
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z4.b}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    uabalb          z16.h, z0.b, z4.b
    uabalt          z17.h, z0.b, z4.b
.endr
    add             z16.h, z16.h, z17.h
    uadalp          z24.s, p0/m, z16.h
    uaddv           d5, p0, z24.s
    fmov            x0, d5
    ret
.endm

.macro SAD_SVE2_12 h
    mov             z16.d, #0
    mov             w10, #12
    whilelt         p0.b, wzr, w10
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z8.b}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    uabalb          z16.h, z0.b, z8.b
    uabalt          z16.h, z0.b, z8.b
.endr
    uaddv           d5, p0, z16.h
    fmov            w0, s5
    ret
.endm

.macro SAD_SVE2_24 h
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sad_24x\h
    mov             z16.d, #0
    ptrue           p0.b, vl16
    ptrue           p1.b, vl8
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p1/z, [x0, #1, mul vl]
    ld1b            {z8.b}, p0/z, [x2]
    ld1b            {z9.b}, p1/z, [x2, #1, mul vl]
    add             x0, x0, x1
    add             x2, x2, x3
    uabalb          z16.h, z0.b, z8.b
    uabalt          z16.h, z0.b, z8.b
    uabalb          z16.h, z1.b, z9.b
    uabalt          z16.h, z1.b, z9.b
.endr
    uaddv           d5, p0, z16.h
    fmov            w0, s5
    ret
.vl_gt_16_pixel_sad_24x\h\():
    mov             z16.d, #0
    mov             w10, #24
    whilelt         p0.b, wzr, w10
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z8.b}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    uabalb          z16.h, z0.b, z8.b
    uabalt          z16.h, z0.b, z8.b
.endr
    uaddv           d5, p0, z16.h
    fmov            w0, s5
    ret
.endm

.macro SAD_SVE2_48 h
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sad_48x\h
    mov             z16.d, #0
    mov             z17.d, #0
    mov             z18.d, #0
    mov             z19.d, #0
    mov             z20.d, #0
    mov             z21.d, #0
    ptrue           p0.b, vl16
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z2.b}, p0/z, [x0, #2, mul vl]
    ld1b            {z8.b}, p0/z, [x2]
    ld1b            {z9.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z10.b}, p0/z, [x2, #2, mul vl]
    add             x0, x0, x1
    add             x2, x2, x3
    uabalb          z16.h, z0.b, z8.b
    uabalt          z17.h, z0.b, z8.b
    uabalb          z18.h, z1.b, z9.b
    uabalt          z19.h, z1.b, z9.b
    uabalb          z20.h, z2.b, z10.b
    uabalt          z21.h, z2.b, z10.b
.endr
    add             z16.h, z16.h, z17.h
    add             z17.h, z18.h, z19.h
    add             z16.h, z16.h, z17.h
    uaddv           d5, p0, z16.h
    fmov            w0, s5
    add             z18.h, z20.h, z21.h
    uaddv           d6, p0, z18.h
    fmov            w1, s6
    add             w0, w0, w1
    ret
.vl_gt_16_pixel_sad_48x\h\():
    cmp             x9, #48
    bgt             .vl_gt_48_pixel_sad_48x\h
    mov             z16.d, #0
    mov             z17.d, #0
    mov             z18.d, #0
    mov             z19.d, #0
    ptrue           p0.b, vl32
    ptrue           p1.b, vl16
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p1/z, [x0, #1, mul vl]
    ld1b            {z8.b}, p0/z, [x2]
    ld1b            {z9.b}, p1/z, [x2, #1, mul vl]
    add             x0, x0, x1
    add             x2, x2, x3
    uabalb          z16.h, z0.b, z8.b
    uabalt          z17.h, z0.b, z8.b
    uabalb          z18.h, z1.b, z9.b
    uabalt          z19.h, z1.b, z9.b
.endr
    add             z16.h, z16.h, z17.h
    add             z17.h, z18.h, z19.h
    add             z16.h, z16.h, z17.h
    uaddv           d5, p0, z16.h
    fmov            w0, s5
    ret
.vl_gt_48_pixel_sad_48x\h\():
    mov             z16.d, #0
    mov             z17.d, #0
    mov             w10, #48
    whilelt         p0.b, wzr, w10
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z8.b}, p0/z, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    uabalb          z16.h, z0.b, z8.b
    uabalt          z17.h, z0.b, z8.b
.endr
    add             z16.h, z16.h, z17.h
    uaddv           d5, p0, z16.h
    fmov            w0, s5
    ret
.endm

// Fully unrolled.
.macro SAD_FUNC_NEON w, h
function PFX(pixel_sad_\w\()x\h\()_neon)
    SAD_START_\w uabdl
    SAD_\w \h
.if \w > 4
    add             v16.8h, v16.8h, v17.8h
.endif
    uaddlv          s0, v16.8h
    fmov            w0, s0
    ret
endfunc
.endm

// Loop unrolled 4.
.macro SAD_FUNC_LOOP_NEON w, h
function PFX(pixel_sad_\w\()x\h\()_neon)
    SAD_START_\w

    mov             w9, #\h/8
.loop_\w\()x\h:
    sub             w9, w9, #1
.rept 4
    SAD_\w
.endr
    cbnz            w9, .loop_\w\()x\h

    SAD_END_\w
endfunc
.endm

SAD_FUNC_NEON  4,  4
SAD_FUNC_NEON  4,  8
SAD_FUNC_NEON  4,  16
SAD_FUNC_NEON  8,  4
SAD_FUNC_NEON  8,  8
SAD_FUNC_NEON  8,  16
SAD_FUNC_NEON  8,  32
SAD_FUNC_NEON  16, 4
SAD_FUNC_NEON  16, 8
SAD_FUNC_NEON  16, 12
SAD_FUNC_NEON  16, 16
SAD_FUNC_NEON  16, 32
SAD_FUNC_NEON  16, 64

SAD_FUNC_LOOP_NEON  32, 8
SAD_FUNC_LOOP_NEON  32, 16
SAD_FUNC_LOOP_NEON  32, 24
SAD_FUNC_LOOP_NEON  32, 32
SAD_FUNC_LOOP_NEON  32, 64
SAD_FUNC_LOOP_NEON  64, 16
SAD_FUNC_LOOP_NEON  64, 32
SAD_FUNC_LOOP_NEON  64, 48
SAD_FUNC_LOOP_NEON  64, 64
SAD_FUNC_LOOP_NEON  12, 16
SAD_FUNC_LOOP_NEON  24, 32
SAD_FUNC_LOOP_NEON  48, 64

// Fully unrolled.
.macro SAD_FUNC_SVE2 w, h
function PFX(pixel_sad_\w\()x\h\()_sve2)
    SAD_SVE2_\w \h
endfunc
.endm

// Loop unrolled 4.
.macro SAD_FUNC_LOOP_SVE2 w, h
function PFX(pixel_sad_\w\()x\h\()_sve2)
    SAD_SVE2_\w \h
endfunc
.endm

SAD_FUNC_SVE2  4,  4
SAD_FUNC_SVE2  4,  8
SAD_FUNC_SVE2  4,  16
SAD_FUNC_SVE2  8,  4
SAD_FUNC_SVE2  8,  8
SAD_FUNC_SVE2  8,  16
SAD_FUNC_SVE2  8,  32
SAD_FUNC_SVE2  16, 4
SAD_FUNC_SVE2  16, 8
SAD_FUNC_SVE2  16, 12
SAD_FUNC_SVE2  16, 16
SAD_FUNC_SVE2  16, 32
SAD_FUNC_SVE2  16, 64

SAD_FUNC_LOOP_SVE2  32, 8
SAD_FUNC_LOOP_SVE2  32, 16
SAD_FUNC_LOOP_SVE2  32, 24
SAD_FUNC_LOOP_SVE2  32, 32
SAD_FUNC_LOOP_SVE2  32, 64
SAD_FUNC_LOOP_SVE2  64, 16
SAD_FUNC_LOOP_SVE2  64, 32
SAD_FUNC_LOOP_SVE2  64, 48
SAD_FUNC_LOOP_SVE2  64, 64
SAD_FUNC_LOOP_SVE2  12, 16
SAD_FUNC_LOOP_SVE2  24, 32
SAD_FUNC_LOOP_SVE2  48, 64

// SAD_X3 and SAD_X4 code start

.macro SAD_X_START_4 h, x, f
    ld1             {v0.s}[0], [x0], x9
    ld1             {v0.s}[1], [x0], x9
    ld1             {v1.s}[0], [x1], x5
    ld1             {v1.s}[1], [x1], x5
    ld1             {v2.s}[0], [x2], x5
    ld1             {v2.s}[1], [x2], x5
    ld1             {v3.s}[0], [x3], x5
    ld1             {v3.s}[1], [x3], x5
    \f              v16.8h, v0.8b, v1.8b
    \f              v17.8h, v0.8b, v2.8b
    \f              v18.8h, v0.8b, v3.8b
.if \x == 4
    ld1             {v4.s}[0], [x4], x5
    ld1             {v4.s}[1], [x4], x5
    \f              v19.8h, v0.8b, v4.8b
.endif
.endm

.macro SAD_X_4 h, x
.rept \h/2 - 1
    SAD_X_START_4 \h, \x, uabal
.endr
.endm

.macro SAD_X_END_4 x
    uaddlv          s0, v16.8h
    uaddlv          s1, v17.8h
    uaddlv          s2, v18.8h
    stp             s0, s1, [x6]
.if \x == 3
    str             s2, [x6, #8]
.elseif \x == 4
    uaddlv          s3, v19.8h
    stp             s2, s3, [x6, #8]
.endif
    ret
.endm

.macro SAD_X_START_8 h, x, f
    ld1             {v0.8b}, [x0], x9
    ld1             {v1.8b}, [x1], x5
    ld1             {v2.8b}, [x2], x5
    ld1             {v3.8b}, [x3], x5
    \f              v16.8h, v0.8b, v1.8b
    \f              v17.8h, v0.8b, v2.8b
    \f              v18.8h, v0.8b, v3.8b
.if \x == 4
    ld1             {v4.8b}, [x4], x5
    \f              v19.8h, v0.8b, v4.8b
.endif
.endm

.macro SAD_X_8 h x
.rept \h - 1
    SAD_X_START_8 \h, \x, uabal
.endr
.endm

.macro SAD_X_END_8 x
    SAD_X_END_4 \x
.endm

.macro SAD_X_START_12 h, x, f
    ld1             {v0.16b}, [x0], x9
    and             v0.16b, v0.16b, v31.16b
    ld1             {v1.16b}, [x1], x5
    and             v1.16b, v1.16b, v31.16b
    ld1             {v2.16b}, [x2], x5
    and             v2.16b, v2.16b, v31.16b
    ld1             {v3.16b}, [x3], x5
    and             v3.16b, v3.16b, v31.16b
    \f              v16.8h, v1.8b, v0.8b
    \f\()2          v20.8h, v1.16b, v0.16b
    \f              v17.8h, v2.8b, v0.8b
    \f\()2          v21.8h, v2.16b, v0.16b
    \f              v18.8h, v3.8b, v0.8b
    \f\()2          v22.8h, v3.16b, v0.16b
.if \x == 4
    ld1             {v4.16b}, [x4], x5
    and             v4.16b, v4.16b, v31.16b
    \f              v19.8h, v4.8b, v0.8b
    \f\()2          v23.8h, v4.16b, v0.16b
.endif
.endm

.macro SAD_X_12 h x
.rept \h - 1
    SAD_X_START_12 \h, \x, uabal
.endr
.endm

.macro SAD_X_END_12 x
    SAD_X_END_16 \x
.endm

.macro SAD_X_START_16 h, x, f
    ld1             {v0.16b}, [x0], x9
    ld1             {v1.16b}, [x1], x5
    ld1             {v2.16b}, [x2], x5
    ld1             {v3.16b}, [x3], x5
    \f              v16.8h, v1.8b, v0.8b
    \f\()2          v20.8h, v1.16b, v0.16b
    \f              v17.8h, v2.8b, v0.8b
    \f\()2          v21.8h, v2.16b, v0.16b
    \f              v18.8h, v3.8b, v0.8b
    \f\()2          v22.8h, v3.16b, v0.16b
.if \x == 4
    ld1             {v4.16b}, [x4], x5
    \f              v19.8h, v4.8b, v0.8b
    \f\()2          v23.8h, v4.16b, v0.16b
.endif
.endm

.macro SAD_X_16 h x
.rept \h - 1
    SAD_X_START_16 \h, \x, uabal
.endr
.endm

.macro SAD_X_END_16 x
    add             v16.8h, v16.8h, v20.8h
    add             v17.8h, v17.8h, v21.8h
    add             v18.8h, v18.8h, v22.8h
.if \x == 4
    add             v19.8h, v19.8h, v23.8h
.endif

    SAD_X_END_4 \x
.endm

.macro SAD_X_START_24 x
    SAD_X_START_32 \x
    sub             x5, x5, #16
    sub             x9, x9, #16
.endm

.macro SAD_X_24 base v1 v2
    ld1             {v0.16b}, [ \base ], #16
    ld1             {v1.8b}, [ \base ], x5
    uabal           \v1\().8h, v0.8b, v6.8b
    uabal           \v1\().8h, v1.8b, v7.8b
    uabal2          \v2\().8h, v0.16b, v6.16b
.endm

.macro SAD_X_END_24 x
    SAD_X_END_16 \x
.endm

.macro SAD_X_START_32 x
    movi v16.16b, #0
    movi v17.16b, #0
    movi v18.16b, #0
    movi v20.16b, #0
    movi v21.16b, #0
    movi v22.16b, #0
.if \x == 4
    movi v19.16b, #0
    movi v23.16b, #0
.endif
.endm

.macro SAD_X_32 base v1 v2
    ld1             {v0.16b-v1.16b}, [ \base ], x5
    uabal           \v1\().8h, v0.8b, v6.8b
    uabal           \v1\().8h, v1.8b, v7.8b
    uabal2          \v2\().8h, v0.16b, v6.16b
    uabal2          \v2\().8h, v1.16b, v7.16b
.endm

.macro SAD_X_END_32 x
    SAD_X_END_16 \x
.endm

.macro SAD_X_START_48 x
    SAD_X_START_32 \x
.endm

.macro SAD_X_48 x1 v1 v2
    ld1             {v0.16b-v2.16b}, [ \x1 ], x5
    uabal           \v1\().8h, v0.8b, v4.8b
    uabal           \v1\().8h, v1.8b, v5.8b
    uabal           \v1\().8h, v2.8b, v6.8b
    uabal2          \v2\().8h, v0.16b, v4.16b
    uabal2          \v2\().8h, v1.16b, v5.16b
    uabal2          \v2\().8h, v2.16b, v6.16b
.endm

.macro SAD_X_END_48 x
    SAD_X_END_64 \x
.endm

.macro SAD_X_START_64 x
    SAD_X_START_32 \x
.endm

.macro SAD_X_64 x1 v1 v2
    ld1             {v0.16b-v3.16b}, [ \x1 ], x5
    uabal           \v1\().8h, v0.8b, v4.8b
    uabal           \v1\().8h, v1.8b, v5.8b
    uabal           \v1\().8h, v2.8b, v6.8b
    uabal           \v1\().8h, v3.8b, v7.8b
    uabal2          \v2\().8h, v0.16b, v4.16b
    uabal2          \v2\().8h, v1.16b, v5.16b
    uabal2          \v2\().8h, v2.16b, v6.16b
    uabal2          \v2\().8h, v3.16b, v7.16b
.endm

.macro SAD_X_END_64 x
    uaddlp          v16.4s, v16.8h
    uaddlp          v17.4s, v17.8h
    uaddlp          v18.4s, v18.8h
    uaddlp          v20.4s, v20.8h
    uaddlp          v21.4s, v21.8h
    uaddlp          v22.4s, v22.8h
    add             v16.4s, v16.4s, v20.4s
    add             v17.4s, v17.4s, v21.4s
    add             v18.4s, v18.4s, v22.4s
    trn2            v20.2d, v16.2d, v16.2d
    trn2            v21.2d, v17.2d, v17.2d
    trn2            v22.2d, v18.2d, v18.2d
    add             v16.2s, v16.2s, v20.2s
    add             v17.2s, v17.2s, v21.2s
    add             v18.2s, v18.2s, v22.2s
    uaddlp          v16.1d, v16.2s
    uaddlp          v17.1d, v17.2s
    uaddlp          v18.1d, v18.2s
    stp             s16, s17, [x6], #8
.if \x == 3
    str             s18, [x6]
.elseif \x == 4
    uaddlp          v19.4s, v19.8h
    uaddlp          v23.4s, v23.8h
    add             v19.4s, v19.4s, v23.4s
    trn2            v23.2d, v19.2d, v19.2d
    add             v19.2s, v19.2s, v23.2s
    uaddlp          v19.1d, v19.2s
    stp             s18, s19, [x6]
.endif
    ret
.endm

.macro SAD_X_SVE2_4 h x
    mov             z16.d, #0
    mov             z17.d, #0
    mov             z18.d, #0
    mov             z19.d, #0
    ptrue           p0.h, vl4
.rept \h
    ld1b            {z0.h}, p0/z, [x0]
    ld1b            {z1.h}, p0/z, [x1]
    ld1b            {z2.h}, p0/z, [x2]
    ld1b            {z3.h}, p0/z, [x3]
    add             x0, x0, x9
    add             x1, x1, x5
    add             x2, x2, x5
    add             x3, x3, x5
.if \x == 4
    ld1b            {z4.h}, p0/z, [x4]
    add             x4, x4, x5
.endif
    uaba            z16.h, z0.h, z1.h
    uaba            z17.h, z0.h, z2.h
    uaba            z18.h, z0.h, z3.h
.if \x == 4
    uaba            z19.h, z0.h, z4.h
.endif
.endr
    uaddv           d0, p0, z16.h
    uaddv           d1, p0, z17.h
    uaddv           d2, p0, z18.h
    stp             s0, s1, [x6]
.if \x == 3
    str             s2, [x6, #8]
.elseif \x == 4
    uaddv           d3, p0, z19.h
    stp             s2, s3, [x6, #8]
.endif
    ret
.endm

.macro SAD_X_SVE2_8 h x
    mov             z16.d, #0
    mov             z17.d, #0
    mov             z18.d, #0
    mov             z19.d, #0
    ptrue           p0.h, vl8
.rept \h
    ld1b            {z0.h}, p0/z, [x0]
    ld1b            {z1.h}, p0/z, [x1]
    ld1b            {z2.h}, p0/z, [x2]
    ld1b            {z3.h}, p0/z, [x3]
    add             x0, x0, x9
    add             x1, x1, x5
    add             x2, x2, x5
    add             x3, x3, x5
.if \x == 4
    ld1b            {z4.h}, p0/z, [x4]
    add             x4, x4, x5
.endif
    uaba            z16.h, z0.h, z1.h
    uaba            z17.h, z0.h, z2.h
    uaba            z18.h, z0.h, z3.h
.if \x == 4
    uaba            z19.h, z0.h, z4.h
.endif
.endr
    uaddv           d0, p0, z16.h
    uaddv           d1, p0, z17.h
    uaddv           d2, p0, z18.h
    stp             s0, s1, [x6]
.if \x == 3
    str             s2, [x6, #8]
.elseif \x == 4
    uaddv           d3, p0, z19.h
    stp             s2, s3, [x6, #8]
.endif
    ret
.endm

.macro SAD_X_SVE2_12 h x
    mov             z16.d, #0
    mov             z17.d, #0
    mov             z18.d, #0
    mov             z19.d, #0
    mov             w10, #12
    whilelt         p0.b, wzr, w10
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    add             x0, x0, x9
    ld1b            {z2.b}, p0/z, [x1]
    add             x1, x1, x5
    ld1b            {z4.b}, p0/z, [x2]
    add             x2, x2, x5
    ld1b            {z6.b}, p0/z, [x3]
    add             x3, x3, x5
.if \x == 4
    ld1b            {z8.b}, p0/z, [x4]
    add             x4, x4, x5
.endif
    uabalb          z16.h, z2.b, z0.b
    uabalt          z16.h, z2.b, z0.b
    uabalb          z17.h, z4.b, z0.b
    uabalt          z17.h, z4.b, z0.b
    uabalb          z18.h, z6.b, z0.b
    uabalt          z18.h, z6.b, z0.b
.if \x == 4
    uabalb          z19.h, z8.b, z0.b
    uabalt          z19.h, z8.b, z0.b
.endif
.endr
    uaddv           d0, p0, z16.h
    uaddv           d1, p0, z17.h
    uaddv           d2, p0, z18.h
    stp             s0, s1, [x6]
.if \x == 3
    str             s2, [x6, #8]
.elseif \x == 4
    uaddv           d3, p0, z19.h
    stp             s2, s3, [x6, #8]
.endif
    ret
.endm

.macro SAD_X_SVE2_16 h x
    mov             z16.d, #0
    mov             z17.d, #0
    mov             z18.d, #0
    mov             z19.d, #0
    ptrue           p0.b, vl16
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z2.b}, p0/z, [x1]
    ld1b            {z4.b}, p0/z, [x2]
    ld1b            {z6.b}, p0/z, [x3]
    add             x0, x0, x9
    add             x1, x1, x5
    add             x2, x2, x5
    add             x3, x3, x5
.if \x == 4
    ld1b            {z8.b}, p0/z, [x4]
    add             x4, x4, x5
.endif
    uabalb          z16.h, z2.b, z0.b
    uabalt          z16.h, z2.b, z0.b
    uabalb          z17.h, z4.b, z0.b
    uabalt          z17.h, z4.b, z0.b
    uabalb          z18.h, z6.b, z0.b
    uabalt          z18.h, z6.b, z0.b
.if \x == 4
    uabalb          z19.h, z8.b, z0.b
    uabalt          z19.h, z8.b, z0.b
.endif
.endr
    uaddv           d0, p0, z16.h
    uaddv           d1, p0, z17.h
    uaddv           d2, p0, z18.h
    stp             s0, s1, [x6]
.if \x == 3
    str             s2, [x6, #8]
.elseif \x == 4
    uaddv           d3, p0, z19.h
    stp             s2, s3, [x6, #8]
.endif
    ret
.endm

.macro SAD_X_SVE2_24_INNER base z
    ld1b            {z4.b}, p0/z, [ \base ]
    ld1b            {z5.b}, p1/z, [ \base , #1, mul vl]
    add             \base, \base, x5
    uabalb          \z\().h, z4.b, z0.b
    uabalt          \z\().h, z4.b, z0.b
    uabalb          \z\().h, z5.b, z1.b
    uabalt          \z\().h, z5.b, z1.b
.endm

.macro SAD_X_SVE2_24_INNER_GT_16 base z
    ld1b            {z4.b}, p0/z, [ \base ]
    add             \base, \base, x5
    uabalb          \z\().h, z4.b, z0.b
    uabalt          \z\().h, z4.b, z0.b
.endm

.macro SAD_X_SVE2_24 h x
    rdvl            x10, #1
    cmp             x10, #16
    bgt             .vl_gt_16_pixel_sad_x24x\h\()_\x
    mov             z20.d, #0
    mov             z21.d, #0
    mov             z22.d, #0
    mov             z23.d, #0
    ptrue           p0.b, vl16
    ptrue           p1.b, vl8
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p1/z, [x0, #1, mul vl]
    add             x0, x0, x9
    SAD_X_SVE2_24_INNER x1, z20
    SAD_X_SVE2_24_INNER x2, z21
    SAD_X_SVE2_24_INNER x3, z22
.if \x == 4
    SAD_X_SVE2_24_INNER x4, z23
.endif
.endr
    uaddv           d0, p0, z20.h
    uaddv           d1, p0, z21.h
    uaddv           d2, p0, z22.h
    stp             s0, s1, [x6]
.if \x == 3
    str             s2, [x6, #8]
.elseif \x == 4
    uaddv           d3, p0, z23.h
    stp             s2, s3, [x6, #8]
.endif
    ret
.vl_gt_16_pixel_sad_x24x\h\()_\x:
    mov             z20.d, #0
    mov             z21.d, #0
    mov             z22.d, #0
    mov             z23.d, #0
    mov             w10, #24
    whilelt         p0.b, wzr, w10
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    add             x0, x0, x9
    SAD_X_SVE2_24_INNER_GT_16 x1, z20
    SAD_X_SVE2_24_INNER_GT_16 x2, z21
    SAD_X_SVE2_24_INNER_GT_16 x3, z22
.if \x == 4
    SAD_X_SVE2_24_INNER_GT_16 x4, z23
.endif
.endr
    uaddv           d0, p0, z20.h
    uaddv           d1, p0, z21.h
    uaddv           d2, p0, z22.h
    stp             s0, s1, [x6]
.if \x == 3
    str             s2, [x6, #8]
.elseif \x == 4
    uaddv           d3, p0, z23.h
    stp             s2, s3, [x6, #8]
.endif
    ret
.endm

.macro SAD_X_SVE2_32_INNER base z
    ld1b            {z4.b}, p0/z, [ \base ]
    ld1b            {z5.b}, p0/z, [ \base , #1, mul vl]
    add             \base, \base, x5
    uabalb          \z\().h, z4.b, z0.b
    uabalt          \z\().h, z4.b, z0.b
    uabalb          \z\().h, z5.b, z1.b
    uabalt          \z\().h, z5.b, z1.b
.endm

.macro SAD_X_SVE2_32_INNER_GT_16 base z
    ld1b            {z4.b}, p0/z, [ \base ]
    add             \base, \base, x5
    uabalb          \z\().h, z4.b, z0.b
    uabalt          \z\().h, z4.b, z0.b
.endm

.macro SAD_X_SVE2_32 h x
    rdvl            x10, #1
    cmp             x10, #16
    bgt             .vl_gt_16_pixel_sad_x32x\h\()_\x
    mov             z20.d, #0
    mov             z21.d, #0
    mov             z22.d, #0
    mov             z23.d, #0
    ptrue           p0.b, vl16
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x9
    SAD_X_SVE2_32_INNER x1, z20
    SAD_X_SVE2_32_INNER x2, z21
    SAD_X_SVE2_32_INNER x3, z22
.if \x == 4
    SAD_X_SVE2_32_INNER x4, z23
.endif
.endr
    uaddv           d0, p0, z20.h
    uaddv           d1, p0, z21.h
    uaddv           d2, p0, z22.h
    stp             s0, s1, [x6]
.if \x == 3
    str             s2, [x6, #8]
.elseif \x == 4
    uaddv           d3, p0, z23.h
    stp             s2, s3, [x6, #8]
.endif
    ret
.vl_gt_16_pixel_sad_x32x\h\()_\x:
    mov             z20.d, #0
    mov             z21.d, #0
    mov             z22.d, #0
    mov             z23.d, #0
    ptrue           p0.b, vl32
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    add             x0, x0, x9
    SAD_X_SVE2_32_INNER_GT_16 x1, z20
    SAD_X_SVE2_32_INNER_GT_16 x2, z21
    SAD_X_SVE2_32_INNER_GT_16 x3, z22
.if \x == 4
    SAD_X_SVE2_32_INNER_GT_16 x4, z23
.endif
.endr
    uaddv           d0, p0, z20.h
    uaddv           d1, p0, z21.h
    uaddv           d2, p0, z22.h
    stp             s0, s1, [x6]
.if \x == 3
    str             s2, [x6, #8]
.elseif \x == 4
    uaddv           d3, p0, z23.h
    stp             s2, s3, [x6, #8]
.endif
    ret
.endm

.macro SAD_X_SVE2_48_INNER base z1 z2
    ld1b            {z6.b}, p0/z, [ \base ]
    ld1b            {z7.b}, p0/z, [ \base , #1, mul vl]
    ld1b            {z8.b}, p0/z, [ \base , #2, mul vl]
    add             \base, \base, x5
    uabalb          \z1\().h, z6.b, z0.b
    uabalt          \z1\().h, z6.b, z0.b
    uabalb          \z1\().h, z7.b, z1.b
    uabalt          \z2\().h, z7.b, z1.b
    uabalb          \z2\().h, z8.b, z2.b
    uabalt          \z2\().h, z8.b, z2.b
.endm

.macro SAD_X_SVE2_48 h x
    mov             z16.d, #0
    mov             z17.d, #0
    mov             z18.d, #0
    mov             z19.d, #0
    mov             z20.d, #0
    mov             z21.d, #0
    mov             z22.d, #0
    mov             z23.d, #0
    ptrue           p0.b, vl16
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z2.b}, p0/z, [x0, #2, mul vl]
    add             x0, x0, x9
    SAD_X_SVE2_48_INNER x1, z16, z20
    SAD_X_SVE2_48_INNER x2, z17, z21
    SAD_X_SVE2_48_INNER x3, z18, z22
.if \x == 4
    SAD_X_SVE2_48_INNER x4, z19, z23
.endif
.endr
.endm

.macro SAD_X_SVE2_64_INNER base z1 z2
    ld1b            {z8.b}, p0/z, [ \base ]
    ld1b            {z9.b}, p0/z, [ \base , #1, mul vl]
    ld1b            {z10.b}, p0/z, [ \base , #2, mul vl]
    ld1b            {z11.b}, p0/z, [ \base , #3, mul vl]
    add             \base, \base, x5
    uabalb          \z1\().h, z8.b, z0.b
    uabalt          \z1\().h, z8.b, z0.b
    uabalb          \z1\().h, z9.b, z1.b
    uabalt          \z1\().h, z9.b, z1.b
    uabalb          \z2\().h, z10.b, z2.b
    uabalt          \z2\().h, z10.b, z2.b
    uabalb          \z2\().h, z11.b, z3.b
    uabalt          \z2\().h, z11.b, z3.b
.endm

.macro SAD_X_SVE2_64 h x
    mov             z16.d, #0
    mov             z17.d, #0
    mov             z18.d, #0
    mov             z19.d, #0
    mov             z20.d, #0
    mov             z21.d, #0
    mov             z22.d, #0
    mov             z23.d, #0
    ptrue           p0.b, vl16
.rept \h
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z2.b}, p0/z, [x0, #2, mul vl]
    ld1b            {z3.b}, p0/z, [x0, #3, mul vl]
    add             x0, x0, x9
    SAD_X_SVE2_64_INNER x1, z16, z20
    SAD_X_SVE2_64_INNER x2, z17, z21
    SAD_X_SVE2_64_INNER x3, z18, z22
.if \x == 4
    SAD_X_SVE2_64_INNER x4, z19, z23
.endif
.endr
.endm

// static void x264_pixel_sad_x3_##size(pixel *fenc, pixel *pix0, pixel *pix1, pixel *pix2, intptr_t i_stride, int scores[3])
// static void x264_pixel_sad_x4_##size(pixel *fenc, pixel *pix0, pixel *pix1,pixel *pix2, pixel *pix3, intptr_t i_stride, int scores[4])
.macro SAD_X_FUNC_NEON x, w, h
function PFX(sad_x\x\()_\w\()x\h\()_neon)
    mov             x9, #FENC_STRIDE

// Make function arguments for x == 3 look like x == 4.
.if \x == 3
    mov             x6, x5
    mov             x5, x4
.endif

.if \w == 12
    movrel          x12, sad12_mask
    ld1             {v31.16b}, [x12]
.endif

    SAD_X_START_\w \h, \x, uabdl
    SAD_X_\w \h, \x
    SAD_X_END_\w \x
endfunc
.endm

.macro SAD_X_LOOP_NEON x, w, h
function PFX(sad_x\x\()_\w\()x\h\()_neon)
    mov             x9, #FENC_STRIDE

// Make function arguments for x == 3 look like x == 4.
.if \x == 3
    mov             x6, x5
    mov             x5, x4
.endif
    SAD_X_START_\w \x
    mov             w12, #\h/4
.loop_sad_x\x\()_\w\()x\h:
    sub             w12, w12, #1
 .rept 4
  .if \w == 24
    ld1             {v6.16b}, [x0], #16
    ld1             {v7.8b}, [x0], x9
  .elseif \w == 32
    ld1             {v6.16b-v7.16b}, [x0], x9
  .elseif \w == 48
    ld1             {v4.16b-v6.16b}, [x0], x9
  .elseif \w == 64
    ld1             {v4.16b-v7.16b}, [x0], x9
  .endif
    SAD_X_\w x1, v16, v20
    SAD_X_\w x2, v17, v21
    SAD_X_\w x3, v18, v22
  .if \x == 4
    SAD_X_\w x4, v19, v23
  .endif
 .endr
    cbnz            w12, .loop_sad_x\x\()_\w\()x\h
    SAD_X_END_\w \x
endfunc
.endm

SAD_X_FUNC_NEON  3, 4,  4
SAD_X_FUNC_NEON  3, 4,  8
SAD_X_FUNC_NEON  3, 4,  16
SAD_X_FUNC_NEON  3, 8,  4
SAD_X_FUNC_NEON  3, 8,  8
SAD_X_FUNC_NEON  3, 8,  16
SAD_X_FUNC_NEON  3, 8,  32
SAD_X_FUNC_NEON  3, 12, 16
SAD_X_FUNC_NEON  3, 16, 4
SAD_X_FUNC_NEON  3, 16, 8
SAD_X_FUNC_NEON  3, 16, 12
SAD_X_FUNC_NEON  3, 16, 16
SAD_X_FUNC_NEON  3, 16, 32
SAD_X_FUNC_NEON  3, 16, 64
SAD_X_LOOP_NEON  3, 24, 32
SAD_X_LOOP_NEON  3, 32, 8
SAD_X_LOOP_NEON  3, 32, 16
SAD_X_LOOP_NEON  3, 32, 24
SAD_X_LOOP_NEON  3, 32, 32
SAD_X_LOOP_NEON  3, 32, 64
SAD_X_LOOP_NEON  3, 48, 64
SAD_X_LOOP_NEON  3, 64, 16
SAD_X_LOOP_NEON  3, 64, 32
SAD_X_LOOP_NEON  3, 64, 48
SAD_X_LOOP_NEON  3, 64, 64

SAD_X_FUNC_NEON  4, 4,  4
SAD_X_FUNC_NEON  4, 4,  8
SAD_X_FUNC_NEON  4, 4,  16
SAD_X_FUNC_NEON  4, 8,  4
SAD_X_FUNC_NEON  4, 8,  8
SAD_X_FUNC_NEON  4, 8,  16
SAD_X_FUNC_NEON  4, 8,  32
SAD_X_FUNC_NEON  4, 12, 16
SAD_X_FUNC_NEON  4, 16, 4
SAD_X_FUNC_NEON  4, 16, 8
SAD_X_FUNC_NEON  4, 16, 12
SAD_X_FUNC_NEON  4, 16, 16
SAD_X_FUNC_NEON  4, 16, 32
SAD_X_FUNC_NEON  4, 16, 64
SAD_X_LOOP_NEON  4, 24, 32
SAD_X_LOOP_NEON  4, 32, 8
SAD_X_LOOP_NEON  4, 32, 16
SAD_X_LOOP_NEON  4, 32, 24
SAD_X_LOOP_NEON  4, 32, 32
SAD_X_LOOP_NEON  4, 32, 64
SAD_X_LOOP_NEON  4, 48, 64
SAD_X_LOOP_NEON  4, 64, 16
SAD_X_LOOP_NEON  4, 64, 32
SAD_X_LOOP_NEON  4, 64, 48
SAD_X_LOOP_NEON  4, 64, 64

.macro SAD_X_FUNC_SVE2 x, w, h
function PFX(sad_x\x\()_\w\()x\h\()_sve2)
    mov             x9, #FENC_STRIDE

// Make function arguments for x == 3 look like x == 4.
.if \x == 3
    mov             x6, x5
    mov             x5, x4
.endif

    SAD_X_SVE2_\w \h, \x
endfunc
.endm

.macro SAD_X_LOOP_SVE2 x, w, h
function PFX(sad_x\x\()_\w\()x\h\()_sve2)
    mov             x9, #FENC_STRIDE

// Make function arguments for x == 3 look like x == 4.
.if \x == 3
    mov             x6, x5
    mov             x5, x4
.endif

.if \w == 48
    SAD_X_SVE2_\w \h, \x
    // No need to migrate the following function to
    // SVE2
    SAD_X_END_\w \x
.endif

.if \w == 64
    SAD_X_SVE2_\w \h, \x
    // No need to migrate the following function to
    // SVE2
    SAD_X_END_\w \x
.endif

    SAD_X_SVE2_\w \h, \x
    ret
endfunc
.endm


SAD_X_FUNC_SVE2  3, 4,  4
SAD_X_FUNC_SVE2  3, 4,  8
SAD_X_FUNC_SVE2  3, 4,  16
SAD_X_FUNC_SVE2  3, 8,  4
SAD_X_FUNC_SVE2  3, 8,  8
SAD_X_FUNC_SVE2  3, 8,  16
SAD_X_FUNC_SVE2  3, 8,  32
SAD_X_FUNC_SVE2  3, 12, 16
SAD_X_FUNC_SVE2  3, 16, 4
SAD_X_FUNC_SVE2  3, 16, 8
SAD_X_FUNC_SVE2  3, 16, 12
SAD_X_FUNC_SVE2  3, 16, 16
SAD_X_FUNC_SVE2  3, 16, 32
SAD_X_FUNC_SVE2  3, 16, 64
SAD_X_LOOP_SVE2  3, 24, 32
SAD_X_LOOP_SVE2  3, 32, 8
SAD_X_LOOP_SVE2  3, 32, 16
SAD_X_LOOP_SVE2  3, 32, 24
SAD_X_LOOP_SVE2  3, 32, 32
SAD_X_LOOP_SVE2  3, 32, 64
SAD_X_LOOP_SVE2  3, 48, 64
SAD_X_LOOP_SVE2  3, 64, 16
SAD_X_LOOP_SVE2  3, 64, 32
SAD_X_LOOP_SVE2  3, 64, 48
SAD_X_LOOP_SVE2  3, 64, 64

SAD_X_FUNC_SVE2  4, 4,  4
SAD_X_FUNC_SVE2  4, 4,  8
SAD_X_FUNC_SVE2  4, 4,  16
SAD_X_FUNC_SVE2  4, 8,  4
SAD_X_FUNC_SVE2  4, 8,  8
SAD_X_FUNC_SVE2  4, 8,  16
SAD_X_FUNC_SVE2  4, 8,  32
SAD_X_FUNC_SVE2  4, 12, 16
SAD_X_FUNC_SVE2  4, 16, 4
SAD_X_FUNC_SVE2  4, 16, 8
SAD_X_FUNC_SVE2  4, 16, 12
SAD_X_FUNC_SVE2  4, 16, 16
SAD_X_FUNC_SVE2  4, 16, 32
SAD_X_FUNC_SVE2  4, 16, 64
SAD_X_LOOP_SVE2  4, 24, 32
SAD_X_LOOP_SVE2  4, 32, 8
SAD_X_LOOP_SVE2  4, 32, 16
SAD_X_LOOP_SVE2  4, 32, 24
SAD_X_LOOP_SVE2  4, 32, 32
SAD_X_LOOP_SVE2  4, 32, 64
SAD_X_LOOP_SVE2  4, 48, 64
SAD_X_LOOP_SVE2  4, 64, 16
SAD_X_LOOP_SVE2  4, 64, 32
SAD_X_LOOP_SVE2  4, 64, 48
SAD_X_LOOP_SVE2  4, 64, 64

const sad12_mask, align=8
.byte 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 0, 0, 0
endconst
