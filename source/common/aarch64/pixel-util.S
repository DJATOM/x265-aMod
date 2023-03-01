/*****************************************************************************
 * Copyright (C) 2020-2021 MulticoreWare, Inc
 *
 * Authors: Yimeng Su <yimeng.su@huawei.com>
 *          Hongbin Liu <liuhongbin1@huawei.com>
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

#if __ARM_FEATURE_SVE2
.arch armv8-a+sve2
#endif

#ifdef __APPLE__
.section __RODATA,__rodata
#else
.section .rodata
#endif

.align 4

.text

// ################### NEON ####################

// uint64_t pixel_var(const pixel* pix, intptr_t i_stride)
function PFX(pixel_var_8x8_neon)
    ld1             {v4.8b}, [x0], x1        // pix[x]
    uxtl            v0.8h, v4.8b             // sum = pix[x]
    umull           v1.8h, v4.8b, v4.8b
    uaddlp          v1.4s, v1.8h             // sqr = pix[x] * pix[x]

.rept 7
    ld1             {v4.8b}, [x0], x1        // pix[x]
    umull           v31.8h, v4.8b, v4.8b
    uaddw           v0.8h, v0.8h, v4.8b      // sum += pix[x]
    uadalp          v1.4s, v31.8h            // sqr += pix[x] * pix[x]
.endr
    uaddlv          s0, v0.8h
    uaddlv          d1, v1.4s
    fmov            w0, s0
    fmov            x1, d1
    orr             x0, x0, x1, lsl #32      // return sum + ((uint64_t)sqr << 32);
    ret
endfunc

.macro pixel_var_start
    movi            v0.16b, #0
    movi            v1.16b, #0
    movi            v2.16b, #0
    movi            v3.16b, #0
.endm

.macro pixel_var_1 v
    uaddw           v0.8h, v0.8h, \v\().8b
    umull           v30.8h, \v\().8b, \v\().8b
    uaddw2          v1.8h, v1.8h, \v\().16b
    umull2          v31.8h, \v\().16b, \v\().16b
    uadalp          v2.4s, v30.8h
    uadalp          v3.4s, v31.8h
.endm

.macro pixel_var_end
    uaddlv          s0, v0.8h
    uaddlv          s1, v1.8h
    add             v2.4s, v2.4s, v3.4s
    fadd            s0, s0, s1
    uaddlv          d2, v2.4s
    fmov            w0, s0
    fmov            x2, d2
    orr             x0, x0, x2, lsl #32
.endm

function PFX(pixel_var_16x16_neon)
    pixel_var_start
    mov             w12, #16
.loop_var_16:
    sub             w12, w12, #1
    ld1             {v4.16b}, [x0], x1
    pixel_var_1 v4
    cbnz            w12, .loop_var_16
    pixel_var_end
    ret
endfunc

function PFX(pixel_var_32x32_neon)
    pixel_var_start
    mov             w12, #32
.loop_var_32:
    sub             w12, w12, #1
    ld1             {v4.16b-v5.16b}, [x0], x1
    pixel_var_1 v4
    pixel_var_1 v5
    cbnz            w12, .loop_var_32
    pixel_var_end
    ret
endfunc

function PFX(pixel_var_64x64_neon)
    pixel_var_start
    mov             w12, #64
.loop_var_64:
    sub             w12, w12, #1
    ld1             {v4.16b-v7.16b}, [x0], x1
    pixel_var_1 v4
    pixel_var_1 v5
    pixel_var_1 v6
    pixel_var_1 v7
    cbnz            w12, .loop_var_64
    pixel_var_end
    ret
endfunc

// void getResidual4_neon(const pixel* fenc, const pixel* pred, int16_t* residual, intptr_t stride)
function PFX(getResidual4_neon)
    lsl             x4, x3, #1
.rept 2
    ld1             {v0.8b}, [x0], x3
    ld1             {v1.8b}, [x1], x3
    ld1             {v2.8b}, [x0], x3
    ld1             {v3.8b}, [x1], x3
    usubl           v4.8h, v0.8b, v1.8b
    usubl           v5.8h, v2.8b, v3.8b
    st1             {v4.8b}, [x2], x4
    st1             {v5.8b}, [x2], x4
.endr
    ret
endfunc

function PFX(getResidual8_neon)
    lsl             x4, x3, #1
.rept 4
    ld1             {v0.8b}, [x0], x3
    ld1             {v1.8b}, [x1], x3
    ld1             {v2.8b}, [x0], x3
    ld1             {v3.8b}, [x1], x3
    usubl           v4.8h, v0.8b, v1.8b
    usubl           v5.8h, v2.8b, v3.8b
    st1             {v4.16b}, [x2], x4
    st1             {v5.16b}, [x2], x4
.endr
    ret
endfunc

function PFX(getResidual16_neon)
    lsl             x4, x3, #1
.rept 8
    ld1             {v0.16b}, [x0], x3
    ld1             {v1.16b}, [x1], x3
    ld1             {v2.16b}, [x0], x3
    ld1             {v3.16b}, [x1], x3
    usubl           v4.8h, v0.8b, v1.8b
    usubl2          v5.8h, v0.16b, v1.16b
    usubl           v6.8h, v2.8b, v3.8b
    usubl2          v7.8h, v2.16b, v3.16b
    st1             {v4.8h-v5.8h}, [x2], x4
    st1             {v6.8h-v7.8h}, [x2], x4
.endr
    ret
endfunc

function PFX(getResidual32_neon)
    lsl             x4, x3, #1
    mov             w12, #4
.loop_residual_32:
    sub             w12, w12, #1
.rept 4
    ld1             {v0.16b-v1.16b}, [x0], x3
    ld1             {v2.16b-v3.16b}, [x1], x3
    ld1             {v4.16b-v5.16b}, [x0], x3
    ld1             {v6.16b-v7.16b}, [x1], x3
    usubl           v16.8h, v0.8b, v2.8b
    usubl2          v17.8h, v0.16b, v2.16b
    usubl           v18.8h, v1.8b, v3.8b
    usubl2          v19.8h, v1.16b, v3.16b
    usubl           v20.8h, v4.8b, v6.8b
    usubl2          v21.8h, v4.16b, v6.16b
    usubl           v22.8h, v5.8b, v7.8b
    usubl2          v23.8h, v5.16b, v7.16b
    st1             {v16.8h-v19.8h}, [x2], x4
    st1             {v20.8h-v23.8h}, [x2], x4
.endr
    cbnz            w12, .loop_residual_32
    ret
endfunc

// void pixel_sub_ps_neon(int16_t* a, intptr_t dstride, const pixel* b0, const pixel* b1, intptr_t sstride0, intptr_t sstride1)
function PFX(pixel_sub_ps_4x4_neon)
    lsl             x1, x1, #1
.rept 2
    ld1             {v0.8b}, [x2], x4
    ld1             {v1.8b}, [x3], x5
    ld1             {v2.8b}, [x2], x4
    ld1             {v3.8b}, [x3], x5
    usubl           v4.8h, v0.8b, v1.8b
    usubl           v5.8h, v2.8b, v3.8b
    st1             {v4.4h}, [x0], x1
    st1             {v5.4h}, [x0], x1
.endr
    ret
endfunc

function PFX(pixel_sub_ps_8x8_neon)
    lsl             x1, x1, #1
.rept 4
    ld1             {v0.8b}, [x2], x4
    ld1             {v1.8b}, [x3], x5
    ld1             {v2.8b}, [x2], x4
    ld1             {v3.8b}, [x3], x5
    usubl           v4.8h, v0.8b, v1.8b
    usubl           v5.8h, v2.8b, v3.8b
    st1             {v4.8h}, [x0], x1
    st1             {v5.8h}, [x0], x1
.endr
    ret
endfunc

function PFX(pixel_sub_ps_16x16_neon)
    lsl             x1, x1, #1
.rept 8
    ld1             {v0.16b}, [x2], x4
    ld1             {v1.16b}, [x3], x5
    ld1             {v2.16b}, [x2], x4
    ld1             {v3.16b}, [x3], x5
    usubl           v4.8h, v0.8b, v1.8b
    usubl2          v5.8h, v0.16b, v1.16b
    usubl           v6.8h, v2.8b, v3.8b
    usubl2          v7.8h, v2.16b, v3.16b
    st1             {v4.8h-v5.8h}, [x0], x1
    st1             {v6.8h-v7.8h}, [x0], x1
.endr
    ret
endfunc

function PFX(pixel_sub_ps_32x32_neon)
    lsl             x1, x1, #1
    mov             w12, #4
.loop_sub_ps_32:
    sub             w12, w12, #1
.rept 4
    ld1             {v0.16b-v1.16b}, [x2], x4
    ld1             {v2.16b-v3.16b}, [x3], x5
    ld1             {v4.16b-v5.16b}, [x2], x4
    ld1             {v6.16b-v7.16b}, [x3], x5
    usubl           v16.8h, v0.8b, v2.8b
    usubl2          v17.8h, v0.16b, v2.16b
    usubl           v18.8h, v1.8b, v3.8b
    usubl2          v19.8h, v1.16b, v3.16b
    usubl           v20.8h, v4.8b, v6.8b
    usubl2          v21.8h, v4.16b, v6.16b
    usubl           v22.8h, v5.8b, v7.8b
    usubl2          v23.8h, v5.16b, v7.16b
    st1             {v16.8h-v19.8h}, [x0], x1
    st1             {v20.8h-v23.8h}, [x0], x1
.endr
    cbnz            w12, .loop_sub_ps_32
    ret
endfunc

function PFX(pixel_sub_ps_64x64_neon)
    lsl             x1, x1, #1
    sub             x1, x1, #64
    mov             w12, #16
.loop_sub_ps_64:
    sub             w12, w12, #1
.rept 4
    ld1             {v0.16b-v3.16b}, [x2], x4
    ld1             {v4.16b-v7.16b}, [x3], x5
    usubl           v16.8h, v0.8b, v4.8b
    usubl2          v17.8h, v0.16b, v4.16b
    usubl           v18.8h, v1.8b, v5.8b
    usubl2          v19.8h, v1.16b, v5.16b
    usubl           v20.8h, v2.8b, v6.8b
    usubl2          v21.8h, v2.16b, v6.16b
    usubl           v22.8h, v3.8b, v7.8b
    usubl2          v23.8h, v3.16b, v7.16b
    st1             {v16.8h-v19.8h}, [x0], #64
    st1             {v20.8h-v23.8h}, [x0], x1
.endr
    cbnz            w12, .loop_sub_ps_64
    ret
endfunc

// chroma sub_ps
function PFX(pixel_sub_ps_4x8_neon)
    lsl             x1, x1, #1
.rept 4
    ld1             {v0.8b}, [x2], x4
    ld1             {v1.8b}, [x3], x5
    ld1             {v2.8b}, [x2], x4
    ld1             {v3.8b}, [x3], x5
    usubl           v4.8h, v0.8b, v1.8b
    usubl           v5.8h, v2.8b, v3.8b
    st1             {v4.4h}, [x0], x1
    st1             {v5.4h}, [x0], x1
.endr
    ret
endfunc

function PFX(pixel_sub_ps_8x16_neon)
    lsl             x1, x1, #1
.rept 8
    ld1             {v0.8b}, [x2], x4
    ld1             {v1.8b}, [x3], x5
    ld1             {v2.8b}, [x2], x4
    ld1             {v3.8b}, [x3], x5
    usubl           v4.8h, v0.8b, v1.8b
    usubl           v5.8h, v2.8b, v3.8b
    st1             {v4.8h}, [x0], x1
    st1             {v5.8h}, [x0], x1
.endr
    ret
endfunc

function PFX(pixel_sub_ps_16x32_neon)
    lsl             x1, x1, #1
.rept 16
    ld1             {v0.16b}, [x2], x4
    ld1             {v1.16b}, [x3], x5
    ld1             {v2.16b}, [x2], x4
    ld1             {v3.16b}, [x3], x5
    usubl           v4.8h, v0.8b, v1.8b
    usubl2          v5.8h, v0.16b, v1.16b
    usubl           v6.8h, v2.8b, v3.8b
    usubl2          v7.8h, v2.16b, v3.16b
    st1             {v4.8h-v5.8h}, [x0], x1
    st1             {v6.8h-v7.8h}, [x0], x1
.endr
    ret
endfunc

function PFX(pixel_sub_ps_32x64_neon)
    lsl             x1, x1, #1
    mov             w12, #8
.loop_sub_ps_32x64:
    sub             w12, w12, #1
.rept 4
    ld1             {v0.16b-v1.16b}, [x2], x4
    ld1             {v2.16b-v3.16b}, [x3], x5
    ld1             {v4.16b-v5.16b}, [x2], x4
    ld1             {v6.16b-v7.16b}, [x3], x5
    usubl           v16.8h, v0.8b, v2.8b
    usubl2          v17.8h, v0.16b, v2.16b
    usubl           v18.8h, v1.8b, v3.8b
    usubl2          v19.8h, v1.16b, v3.16b
    usubl           v20.8h, v4.8b, v6.8b
    usubl2          v21.8h, v4.16b, v6.16b
    usubl           v22.8h, v5.8b, v7.8b
    usubl2          v23.8h, v5.16b, v7.16b
    st1             {v16.8h-v19.8h}, [x0], x1
    st1             {v20.8h-v23.8h}, [x0], x1
.endr
    cbnz            w12, .loop_sub_ps_32x64
    ret
endfunc

// void x265_pixel_add_ps_neon(pixel* a, intptr_t dstride, const pixel* b0, const int16_t* b1, intptr_t sstride0, intptr_t sstride1);
function PFX(pixel_add_ps_4x4_neon)
    lsl             x5, x5, #1
.rept 2
    ld1             {v0.8b}, [x2], x4
    ld1             {v1.8b}, [x2], x4
    ld1             {v2.4h}, [x3], x5
    ld1             {v3.4h}, [x3], x5
    uxtl            v0.8h, v0.8b
    uxtl            v1.8h, v1.8b
    add             v4.8h, v0.8h, v2.8h
    add             v5.8h, v1.8h, v3.8h
    sqxtun          v4.8b, v4.8h
    sqxtun          v5.8b, v5.8h
    st1             {v4.s}[0], [x0], x1
    st1             {v5.s}[0], [x0], x1
.endr
    ret
endfunc

function PFX(pixel_add_ps_8x8_neon)
    lsl             x5, x5, #1
.rept 4
    ld1             {v0.8b}, [x2], x4
    ld1             {v1.8b}, [x2], x4
    ld1             {v2.8h}, [x3], x5
    ld1             {v3.8h}, [x3], x5
    uxtl            v0.8h, v0.8b
    uxtl            v1.8h, v1.8b
    add             v4.8h, v0.8h, v2.8h
    add             v5.8h, v1.8h, v3.8h
    sqxtun          v4.8b, v4.8h
    sqxtun          v5.8b, v5.8h
    st1             {v4.8b}, [x0], x1
    st1             {v5.8b}, [x0], x1
.endr
    ret
endfunc

.macro pixel_add_ps_16xN_neon h
function PFX(pixel_add_ps_16x\h\()_neon)
    lsl             x5, x5, #1
    mov             w12, #\h / 8
.loop_add_ps_16x\h\():
    sub             w12, w12, #1
.rept 4
    ld1             {v0.16b}, [x2], x4
    ld1             {v1.16b}, [x2], x4
    ld1             {v16.8h-v17.8h}, [x3], x5
    ld1             {v18.8h-v19.8h}, [x3], x5
    uxtl            v4.8h, v0.8b
    uxtl2           v5.8h, v0.16b
    uxtl            v6.8h, v1.8b
    uxtl2           v7.8h, v1.16b
    add             v24.8h, v4.8h, v16.8h
    add             v25.8h, v5.8h, v17.8h
    add             v26.8h, v6.8h, v18.8h
    add             v27.8h, v7.8h, v19.8h
    sqxtun          v4.8b, v24.8h
    sqxtun2         v4.16b, v25.8h
    sqxtun          v5.8b, v26.8h
    sqxtun2         v5.16b, v27.8h
    st1             {v4.16b}, [x0], x1
    st1             {v5.16b}, [x0], x1
.endr
    cbnz            w12, .loop_add_ps_16x\h
    ret
endfunc
.endm

pixel_add_ps_16xN_neon 16
pixel_add_ps_16xN_neon 32

.macro pixel_add_ps_32xN_neon h
 function PFX(pixel_add_ps_32x\h\()_neon)
    lsl             x5, x5, #1
    mov             w12, #\h / 4
.loop_add_ps_32x\h\():
    sub             w12, w12, #1
.rept 4
    ld1             {v0.16b-v1.16b}, [x2], x4
    ld1             {v16.8h-v19.8h}, [x3], x5
    uxtl            v4.8h, v0.8b
    uxtl2           v5.8h, v0.16b
    uxtl            v6.8h, v1.8b
    uxtl2           v7.8h, v1.16b
    add             v24.8h, v4.8h, v16.8h
    add             v25.8h, v5.8h, v17.8h
    add             v26.8h, v6.8h, v18.8h
    add             v27.8h, v7.8h, v19.8h
    sqxtun          v4.8b, v24.8h
    sqxtun2         v4.16b, v25.8h
    sqxtun          v5.8b, v26.8h
    sqxtun2         v5.16b, v27.8h
    st1             {v4.16b-v5.16b}, [x0], x1
.endr
    cbnz            w12, .loop_add_ps_32x\h
    ret
endfunc
.endm

pixel_add_ps_32xN_neon 32
pixel_add_ps_32xN_neon 64

function PFX(pixel_add_ps_64x64_neon)
    lsl             x5, x5, #1
    sub             x5, x5, #64
    mov             w12, #32
.loop_add_ps_64x64:
    sub             w12, w12, #1
.rept 2
    ld1             {v0.16b-v3.16b}, [x2], x4
    ld1             {v16.8h-v19.8h}, [x3], #64
    ld1             {v20.8h-v23.8h}, [x3], x5
    uxtl            v4.8h, v0.8b
    uxtl2           v5.8h, v0.16b
    uxtl            v6.8h, v1.8b
    uxtl2           v7.8h, v1.16b
    uxtl            v24.8h, v2.8b
    uxtl2           v25.8h, v2.16b
    uxtl            v26.8h, v3.8b
    uxtl2           v27.8h, v3.16b
    add             v0.8h, v4.8h, v16.8h
    add             v1.8h, v5.8h, v17.8h
    add             v2.8h, v6.8h, v18.8h
    add             v3.8h, v7.8h, v19.8h
    add             v4.8h, v24.8h, v20.8h
    add             v5.8h, v25.8h, v21.8h
    add             v6.8h, v26.8h, v22.8h
    add             v7.8h, v27.8h, v23.8h
    sqxtun          v0.8b, v0.8h
    sqxtun2         v0.16b, v1.8h
    sqxtun          v1.8b, v2.8h
    sqxtun2         v1.16b, v3.8h
    sqxtun          v2.8b, v4.8h
    sqxtun2         v2.16b, v5.8h
    sqxtun          v3.8b, v6.8h
    sqxtun2         v3.16b, v7.8h
    st1             {v0.16b-v3.16b}, [x0], x1
.endr
    cbnz            w12, .loop_add_ps_64x64
    ret
endfunc

// Chroma add_ps
function PFX(pixel_add_ps_4x8_neon)
    lsl             x5, x5, #1
.rept 4
    ld1             {v0.8b}, [x2], x4
    ld1             {v1.8b}, [x2], x4
    ld1             {v2.4h}, [x3], x5
    ld1             {v3.4h}, [x3], x5
    uxtl            v0.8h, v0.8b
    uxtl            v1.8h, v1.8b
    add             v4.8h, v0.8h, v2.8h
    add             v5.8h, v1.8h, v3.8h
    sqxtun          v4.8b, v4.8h
    sqxtun          v5.8b, v5.8h
    st1             {v4.s}[0], [x0], x1
    st1             {v5.s}[0], [x0], x1
.endr
    ret
endfunc

function PFX(pixel_add_ps_8x16_neon)
    lsl             x5, x5, #1
.rept 8
    ld1             {v0.8b}, [x2], x4
    ld1             {v1.8b}, [x2], x4
    ld1             {v2.8h}, [x3], x5
    ld1             {v3.8h}, [x3], x5
    uxtl            v0.8h, v0.8b
    uxtl            v1.8h, v1.8b
    add             v4.8h, v0.8h, v2.8h
    add             v5.8h, v1.8h, v3.8h
    sqxtun          v4.8b, v4.8h
    sqxtun          v5.8b, v5.8h
    st1             {v4.8b}, [x0], x1
    st1             {v5.8b}, [x0], x1
.endr
    ret
endfunc

// void scale1D_128to64(pixel *dst, const pixel *src)
function PFX(scale1D_128to64_neon)
.rept 2
    ld2             {v0.16b, v1.16b}, [x1], #32
    ld2             {v2.16b, v3.16b}, [x1], #32
    ld2             {v4.16b, v5.16b}, [x1], #32
    ld2             {v6.16b, v7.16b}, [x1], #32
    urhadd          v0.16b, v0.16b, v1.16b
    urhadd          v1.16b, v2.16b, v3.16b
    urhadd          v2.16b, v4.16b, v5.16b
    urhadd          v3.16b, v6.16b, v7.16b
    st1             {v0.16b-v3.16b}, [x0], #64
.endr
    ret
endfunc

.macro scale2D_1  v0, v1
    uaddlp          \v0\().8h, \v0\().16b
    uaddlp          \v1\().8h, \v1\().16b
    add             \v0\().8h, \v0\().8h, \v1\().8h
.endm

// void scale2D_64to32(pixel* dst, const pixel* src, intptr_t stride)
function PFX(scale2D_64to32_neon)
    mov             w12, #32
.loop_scale2D:
    ld1             {v0.16b-v3.16b}, [x1], x2
    sub             w12, w12, #1
    ld1             {v4.16b-v7.16b}, [x1], x2
    scale2D_1       v0, v4
    scale2D_1       v1, v5
    scale2D_1       v2, v6
    scale2D_1       v3, v7
    uqrshrn         v0.8b, v0.8h, #2
    uqrshrn2        v0.16b, v1.8h, #2
    uqrshrn         v1.8b, v2.8h, #2
    uqrshrn2        v1.16b, v3.8h, #2
    st1             {v0.16b-v1.16b}, [x0], #32
    cbnz            w12, .loop_scale2D
    ret
endfunc

// void planecopy_cp_c(const uint8_t* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int width, int height, int shift)
function PFX(pixel_planecopy_cp_neon)
    dup             v2.16b, w6
    sub             x5, x5, #1
.loop_h:
    mov             x6, x0
    mov             x12, x2
    mov             x7, #0
.loop_w:
    ldr             q0, [x6], #16
    ushl            v0.16b, v0.16b, v2.16b
    str             q0, [x12], #16
    add             x7, x7, #16
    cmp             x7, x4
    blt             .loop_w

    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .loop_h

// handle last row
    mov             x5, x4
    lsr             x5, x5, #3
.loopW8:
    ldr             d0, [x0], #8
    ushl            v0.8b, v0.8b, v2.8b
    str             d0, [x2], #8
    sub             x4, x4, #8
    sub             x5, x5, #1
    cbnz            x5, .loopW8

    mov             x5, #8
    sub             x5, x5, x4
    sub             x0, x0, x5
    sub             x2, x2, x5
    ldr             d0, [x0]
    ushl            v0.8b, v0.8b, v2.8b
    str             d0, [x2]
    ret
endfunc

//******* satd *******
.macro satd_4x4_neon
    ld1             {v0.s}[0], [x0], x1
    ld1             {v0.s}[1], [x0], x1
    ld1             {v1.s}[0], [x2], x3
    ld1             {v1.s}[1], [x2], x3
    ld1             {v2.s}[0], [x0], x1
    ld1             {v2.s}[1], [x0], x1
    ld1             {v3.s}[0], [x2], x3
    ld1             {v3.s}[1], [x2], x3

    usubl           v4.8h, v0.8b, v1.8b
    usubl           v5.8h, v2.8b, v3.8b

    add             v6.8h, v4.8h, v5.8h
    sub             v7.8h, v4.8h, v5.8h

    mov             v4.d[0], v6.d[1]
    add             v0.4h, v6.4h, v4.4h
    sub             v2.4h, v6.4h, v4.4h

    mov             v5.d[0], v7.d[1]
    add             v1.4h, v7.4h, v5.4h
    sub             v3.4h, v7.4h, v5.4h

    trn1            v4.4h, v0.4h, v1.4h
    trn2            v5.4h, v0.4h, v1.4h

    trn1            v6.4h, v2.4h, v3.4h
    trn2            v7.4h, v2.4h, v3.4h

    add             v0.4h, v4.4h, v5.4h
    sub             v1.4h, v4.4h, v5.4h

    add             v2.4h, v6.4h, v7.4h
    sub             v3.4h, v6.4h, v7.4h

    trn1            v4.2s, v0.2s, v1.2s
    trn2            v5.2s, v0.2s, v1.2s

    trn1            v6.2s, v2.2s, v3.2s
    trn2            v7.2s, v2.2s, v3.2s

    abs             v4.4h, v4.4h
    abs             v5.4h, v5.4h
    abs             v6.4h, v6.4h
    abs             v7.4h, v7.4h

    smax            v1.4h, v4.4h, v5.4h
    smax            v2.4h, v6.4h, v7.4h

    add             v0.4h, v1.4h, v2.4h
    uaddlp          v0.2s, v0.4h
    uaddlp          v0.1d, v0.2s
.endm

// int satd_4x4(const pixel* pix1, intptr_t stride_pix1, const pixel* pix2, intptr_t stride_pix2)
function PFX(pixel_satd_4x4_neon)
    satd_4x4_neon
    fmov            x0, d0
    ret
endfunc

.macro x265_satd_4x8_8x4_end_neon
    add             v0.8h, v4.8h, v6.8h
    add             v1.8h, v5.8h, v7.8h
    sub             v2.8h, v4.8h, v6.8h
    sub             v3.8h, v5.8h, v7.8h

    trn1            v16.8h, v0.8h, v1.8h
    trn2            v17.8h, v0.8h, v1.8h
    add             v4.8h, v16.8h, v17.8h
    trn1            v18.8h, v2.8h, v3.8h
    trn2            v19.8h, v2.8h, v3.8h
    sub             v5.8h, v16.8h, v17.8h
    add             v6.8h, v18.8h, v19.8h
    sub             v7.8h, v18.8h, v19.8h
    trn1            v0.4s, v4.4s, v6.4s
    trn2            v2.4s, v4.4s, v6.4s
    abs             v0.8h, v0.8h
    trn1            v1.4s, v5.4s, v7.4s
    trn2            v3.4s, v5.4s, v7.4s
    abs             v2.8h, v2.8h
    abs             v1.8h, v1.8h
    abs             v3.8h, v3.8h
    umax            v0.8h, v0.8h, v2.8h
    umax            v1.8h, v1.8h, v3.8h
    add             v0.8h, v0.8h, v1.8h
    uaddlv          s0, v0.8h
.endm

.macro pixel_satd_4x8_neon
    ld1r            {v1.2s}, [x2], x3
    ld1r            {v0.2s}, [x0], x1
    ld1r            {v3.2s}, [x2], x3
    ld1r            {v2.2s}, [x0], x1
    ld1r            {v5.2s}, [x2], x3
    ld1r            {v4.2s}, [x0], x1
    ld1r            {v7.2s}, [x2], x3
    ld1r            {v6.2s}, [x0], x1

    ld1             {v1.s}[1], [x2], x3
    ld1             {v0.s}[1], [x0], x1
    usubl           v0.8h, v0.8b, v1.8b
    ld1             {v3.s}[1], [x2], x3
    ld1             {v2.s}[1], [x0], x1
    usubl           v1.8h, v2.8b, v3.8b
    ld1             {v5.s}[1], [x2], x3
    ld1             {v4.s}[1], [x0], x1
    usubl           v2.8h, v4.8b, v5.8b
    ld1             {v7.s}[1], [x2], x3
    add             v4.8h, v0.8h, v1.8h
    sub             v5.8h, v0.8h, v1.8h
    ld1             {v6.s}[1], [x0], x1
    usubl           v3.8h, v6.8b, v7.8b
    add             v6.8h, v2.8h, v3.8h
    sub             v7.8h, v2.8h, v3.8h
    x265_satd_4x8_8x4_end_neon
.endm

// template<int w, int h>
// int satd4(const pixel* pix1, intptr_t stride_pix1, const pixel* pix2, intptr_t stride_pix2)
function PFX(pixel_satd_4x8_neon)
    pixel_satd_4x8_neon
    mov             w0, v0.s[0]
    ret
endfunc

function PFX(pixel_satd_4x16_neon)
    mov             w4, #0
    pixel_satd_4x8_neon
    mov             w5, v0.s[0]
    add             w4, w4, w5
    pixel_satd_4x8_neon
    mov             w5, v0.s[0]
    add             w0, w5, w4
    ret
endfunc

function PFX(pixel_satd_4x32_neon)
    mov             w4, #0
.rept 4
    pixel_satd_4x8_neon
    mov             w5, v0.s[0]
    add             w4, w4, w5
.endr
    mov             w0, w4
    ret
endfunc

function PFX(pixel_satd_12x16_neon)
    mov             x4, x0
    mov             x5, x2
    mov             w7, #0
    pixel_satd_4x8_neon
    mov             w6, v0.s[0]
    add             w7, w7, w6
    pixel_satd_4x8_neon
    mov             w6, v0.s[0]
    add             w7, w7, w6

    add             x0, x4, #4
    add             x2, x5, #4
    pixel_satd_4x8_neon
    mov             w6, v0.s[0]
    add             w7, w7, w6
    pixel_satd_4x8_neon
    mov             w6, v0.s[0]
    add             w7, w7, w6

    add             x0, x4, #8
    add             x2, x5, #8
    pixel_satd_4x8_neon
    mov             w6, v0.s[0]
    add             w7, w7, w6
    pixel_satd_4x8_neon
    mov             w6, v0.s[0]
    add             w0, w7, w6
    ret
endfunc

function PFX(pixel_satd_12x32_neon)
    mov             x4, x0
    mov             x5, x2
    mov             w7, #0
.rept 4
    pixel_satd_4x8_neon
    mov             w6, v0.s[0]
    add             w7, w7, w6
.endr

    add             x0, x4, #4
    add             x2, x5, #4
.rept 4
    pixel_satd_4x8_neon
    mov             w6, v0.s[0]
    add             w7, w7, w6
.endr

    add             x0, x4, #8
    add             x2, x5, #8
.rept 4
    pixel_satd_4x8_neon
    mov             w6, v0.s[0]
    add             w7, w7, w6
.endr

    mov             w0, w7
    ret
endfunc

function PFX(pixel_satd_8x4_neon)
    mov             x4, x0
    mov             x5, x2
    satd_4x4_neon
    add             x0, x4, #4
    add             x2, x5, #4
    umov            x6, v0.d[0]
    satd_4x4_neon
    umov            x0, v0.d[0]
    add             x0, x0, x6
    ret
endfunc

.macro LOAD_DIFF_8x4 v0 v1 v2 v3
    ld1             {v0.8b}, [x0], x1
    ld1             {v1.8b}, [x2], x3
    ld1             {v2.8b}, [x0], x1
    ld1             {v3.8b}, [x2], x3
    ld1             {v4.8b}, [x0], x1
    ld1             {v5.8b}, [x2], x3
    ld1             {v6.8b}, [x0], x1
    ld1             {v7.8b}, [x2], x3
    usubl           \v0, v0.8b, v1.8b
    usubl           \v1, v2.8b, v3.8b
    usubl           \v2, v4.8b, v5.8b
    usubl           \v3, v6.8b, v7.8b
.endm

.macro LOAD_DIFF_16x4 v0 v1 v2 v3 v4 v5 v6 v7
    ld1             {v0.16b}, [x0], x1
    ld1             {v1.16b}, [x2], x3
    ld1             {v2.16b}, [x0], x1
    ld1             {v3.16b}, [x2], x3
    ld1             {v4.16b}, [x0], x1
    ld1             {v5.16b}, [x2], x3
    ld1             {v6.16b}, [x0], x1
    ld1             {v7.16b}, [x2], x3
    usubl           \v0, v0.8b, v1.8b
    usubl           \v1, v2.8b, v3.8b
    usubl           \v2, v4.8b, v5.8b
    usubl           \v3, v6.8b, v7.8b
    usubl2          \v4, v0.16b, v1.16b
    usubl2          \v5, v2.16b, v3.16b
    usubl2          \v6, v4.16b, v5.16b
    usubl2          \v7, v6.16b, v7.16b
.endm

function PFX(satd_16x4_neon), export=0
    LOAD_DIFF_16x4  v16.8h, v17.8h, v18.8h, v19.8h, v20.8h, v21.8h, v22.8h, v23.8h
    b               PFX(satd_8x4v_8x8h_neon)
endfunc

function PFX(satd_8x8_neon), export=0
    LOAD_DIFF_8x4   v16.8h, v17.8h, v18.8h, v19.8h
    LOAD_DIFF_8x4   v20.8h, v21.8h, v22.8h, v23.8h
    b               PFX(satd_8x4v_8x8h_neon)
endfunc

// one vertical hadamard pass and two horizontal
function PFX(satd_8x4v_8x8h_neon), export=0
    HADAMARD4_V     v16.8h, v18.8h, v17.8h, v19.8h, v0.8h, v2.8h, v1.8h, v3.8h
    HADAMARD4_V     v20.8h, v21.8h, v22.8h, v23.8h, v0.8h, v1.8h, v2.8h, v3.8h
    trn4            v0.8h, v1.8h, v2.8h, v3.8h, v16.8h, v17.8h, v18.8h, v19.8h
    trn4            v4.8h, v5.8h, v6.8h, v7.8h, v20.8h, v21.8h, v22.8h, v23.8h
    SUMSUB_ABCD     v16.8h, v17.8h, v18.8h, v19.8h, v0.8h, v1.8h, v2.8h, v3.8h
    SUMSUB_ABCD     v20.8h, v21.8h, v22.8h, v23.8h, v4.8h, v5.8h, v6.8h, v7.8h
    trn4            v0.4s, v2.4s, v1.4s, v3.4s, v16.4s, v18.4s, v17.4s, v19.4s
    trn4            v4.4s, v6.4s, v5.4s, v7.4s, v20.4s, v22.4s, v21.4s, v23.4s
    ABS8            v0.8h, v1.8h, v2.8h, v3.8h, v4.8h, v5.8h, v6.8h, v7.8h
    smax            v0.8h, v0.8h, v2.8h
    smax            v1.8h, v1.8h, v3.8h
    smax            v2.8h, v4.8h, v6.8h
    smax            v3.8h, v5.8h, v7.8h
    ret
endfunc

function PFX(pixel_satd_8x8_neon)
    mov             x10, x30
    bl              PFX(satd_8x8_neon)
    add             v0.8h, v0.8h, v1.8h
    add             v1.8h, v2.8h, v3.8h
    add             v0.8h, v0.8h, v1.8h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_8x12_neon)
    mov             x4, x0
    mov             x5, x2
    mov             x7, #0
    satd_4x4_neon
    umov            x6, v0.d[0]
    add             x7, x7, x6
    add             x0, x4, #4
    add             x2, x5, #4
    satd_4x4_neon
    umov            x6, v0.d[0]
    add             x7, x7, x6
.rept 2
    sub             x0, x0, #4
    sub             x2, x2, #4
    mov             x4, x0
    mov             x5, x2
    satd_4x4_neon
    umov            x6, v0.d[0]
    add             x7, x7, x6
    add             x0, x4, #4
    add             x2, x5, #4
    satd_4x4_neon
    umov            x6, v0.d[0]
    add             x7, x7, x6
.endr
    mov             x0, x7
    ret
endfunc

function PFX(pixel_satd_8x16_neon)
    mov             x10, x30
    bl              PFX(satd_8x8_neon)
    add             v30.8h, v0.8h, v1.8h
    add             v31.8h, v2.8h, v3.8h
    bl              PFX(satd_8x8_neon)
    add             v30.8h, v30.8h, v0.8h
    add             v31.8h, v31.8h, v1.8h
    add             v30.8h, v30.8h, v2.8h
    add             v31.8h, v31.8h, v3.8h
    add             v0.8h, v30.8h, v31.8h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_8x32_neon)
    mov             x10, x30
    bl              PFX(satd_8x8_neon)
    add             v30.8h, v0.8h, v1.8h
    add             v31.8h, v2.8h, v3.8h
.rept 3
    bl              PFX(satd_8x8_neon)
    add             v30.8h, v30.8h, v0.8h
    add             v31.8h, v31.8h, v1.8h
    add             v30.8h, v30.8h, v2.8h
    add             v31.8h, v31.8h, v3.8h
.endr
    add             v0.8h, v30.8h, v31.8h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_8x64_neon)
    mov             x10, x30
    bl              PFX(satd_8x8_neon)
    add             v30.8h, v0.8h, v1.8h
    add             v31.8h, v2.8h, v3.8h
.rept 7
    bl              PFX(satd_8x8_neon)
    add             v30.8h, v30.8h, v0.8h
    add             v31.8h, v31.8h, v1.8h
    add             v30.8h, v30.8h, v2.8h
    add             v31.8h, v31.8h, v3.8h
.endr
    add             v0.8h, v30.8h, v31.8h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_16x4_neon)
    mov             x10, x30
    bl              PFX(satd_16x4_neon)
    add             v30.8h, v0.8h, v1.8h
    add             v31.8h, v2.8h, v3.8h
    add             v0.8h, v30.8h, v31.8h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_16x8_neon)
    mov             x10, x30
    bl              PFX(satd_16x4_neon)
    add             v30.8h, v0.8h, v1.8h
    add             v31.8h, v2.8h, v3.8h
    bl              PFX(satd_16x4_neon)
    add             v30.8h, v30.8h, v0.8h
    add             v31.8h, v31.8h, v1.8h
    add             v30.8h, v30.8h, v2.8h
    add             v31.8h, v31.8h, v3.8h
    add             v0.8h, v30.8h, v31.8h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_16x12_neon)
    mov             x10, x30
    bl              PFX(satd_16x4_neon)
    add             v30.8h, v0.8h, v1.8h
    add             v31.8h, v2.8h, v3.8h
.rept 2
    bl              PFX(satd_16x4_neon)
    add             v30.8h, v30.8h, v0.8h
    add             v31.8h, v31.8h, v1.8h
    add             v30.8h, v30.8h, v2.8h
    add             v31.8h, v31.8h, v3.8h
.endr
    add             v0.8h, v30.8h, v31.8h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_16x16_neon)
    mov             x10, x30
    bl              PFX(satd_16x4_neon)
    add             v30.8h, v0.8h, v1.8h
    add             v31.8h, v2.8h, v3.8h
.rept 3
    bl              PFX(satd_16x4_neon)
    add             v30.8h, v30.8h, v0.8h
    add             v31.8h, v31.8h, v1.8h
    add             v30.8h, v30.8h, v2.8h
    add             v31.8h, v31.8h, v3.8h
.endr
    add             v0.8h, v30.8h, v31.8h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_16x24_neon)
    mov             x10, x30
    bl              PFX(satd_16x4_neon)
    add             v30.8h, v0.8h, v1.8h
    add             v31.8h, v2.8h, v3.8h
.rept 5
    bl              PFX(satd_16x4_neon)
    add             v30.8h, v30.8h, v0.8h
    add             v31.8h, v31.8h, v1.8h
    add             v30.8h, v30.8h, v2.8h
    add             v31.8h, v31.8h, v3.8h
.endr
    add             v0.8h, v30.8h, v31.8h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

.macro pixel_satd_16x32_neon
    bl              PFX(satd_16x4_neon)
    add             v30.8h, v0.8h, v1.8h
    add             v31.8h, v2.8h, v3.8h
.rept 7
    bl              PFX(satd_16x4_neon)
    add             v30.8h, v30.8h, v0.8h
    add             v31.8h, v31.8h, v1.8h
    add             v30.8h, v30.8h, v2.8h
    add             v31.8h, v31.8h, v3.8h
.endr
.endm

function PFX(pixel_satd_16x32_neon)
    mov             x10, x30
    pixel_satd_16x32_neon
    add             v0.8h, v30.8h, v31.8h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_16x64_neon)
    mov             x10, x30
    bl              PFX(satd_16x4_neon)
    add             v30.8h, v0.8h, v1.8h
    add             v31.8h, v2.8h, v3.8h
.rept 15
    bl              PFX(satd_16x4_neon)
    add             v30.8h, v30.8h, v0.8h
    add             v31.8h, v31.8h, v1.8h
    add             v30.8h, v30.8h, v2.8h
    add             v31.8h, v31.8h, v3.8h
.endr
    add             v0.8h, v30.8h, v31.8h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_24x32_neon)
    mov             x10, x30
    mov             x7, #0
    mov             x4, x0
    mov             x5, x2
.rept 3
    movi            v30.8h, #0
    movi            v31.8h, #0
.rept 4
    bl              PFX(satd_8x8_neon)
    add             v30.8h, v30.8h, v0.8h
    add             v31.8h, v31.8h, v1.8h
    add             v30.8h, v30.8h, v2.8h
    add             v31.8h, v31.8h, v3.8h
.endr
    add             v0.8h, v30.8h, v31.8h
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

function PFX(pixel_satd_24x64_neon)
    mov             x10, x30
    mov             x7, #0
    mov             x4, x0
    mov             x5, x2
.rept 3
    movi            v30.8h, #0
    movi            v31.8h, #0
.rept 4
    bl              PFX(satd_8x8_neon)
    add             v30.8h, v30.8h, v0.8h
    add             v31.8h, v31.8h, v1.8h
    add             v30.8h, v30.8h, v2.8h
    add             v31.8h, v31.8h, v3.8h
.endr
    add             v0.8h, v30.8h, v31.8h
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
    movi            v30.8h, #0
    movi            v31.8h, #0
.rept 4
    bl              PFX(satd_8x8_neon)
    add             v30.8h, v30.8h, v0.8h
    add             v31.8h, v31.8h, v1.8h
    add             v30.8h, v30.8h, v2.8h
    add             v31.8h, v31.8h, v3.8h
.endr
    add             v0.8h, v30.8h, v31.8h
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

.macro pixel_satd_32x8
    mov             x4, x0
    mov             x5, x2
.rept 2
    bl              PFX(satd_16x4_neon)
    add             v30.8h, v30.8h, v0.8h
    add             v31.8h, v31.8h, v1.8h
    add             v30.8h, v30.8h, v2.8h
    add             v31.8h, v31.8h, v3.8h
.endr
    add             x0, x4, #16
    add             x2, x5, #16
.rept 2
    bl              PFX(satd_16x4_neon)
    add             v30.8h, v30.8h, v0.8h
    add             v31.8h, v31.8h, v1.8h
    add             v30.8h, v30.8h, v2.8h
    add             v31.8h, v31.8h, v3.8h
.endr
.endm

.macro satd_32x16_neon
    movi            v30.8h, #0
    movi            v31.8h, #0
    pixel_satd_32x8
    sub             x0, x0, #16
    sub             x2, x2, #16
    pixel_satd_32x8
    add             v0.8h, v30.8h, v31.8h
    uaddlv          s0, v0.8h
    mov             w6, v0.s[0]
.endm

.macro satd_64x16_neon
    mov             x8, x0
    mov             x9, x2
    satd_32x16_neon
    add             x7, x7, x6
    add             x0, x8, #32
    add             x2, x9, #32
    satd_32x16_neon
    add             x7, x7, x6
.endm

function PFX(pixel_satd_32x8_neon)
    mov             x10, x30
    mov             x7, #0
    mov             x4, x0
    mov             x5, x2
    movi            v30.8h, #0
    movi            v31.8h, #0
    pixel_satd_32x8
    add             v0.8h, v30.8h, v31.8h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_32x16_neon)
    mov             x10, x30
    satd_32x16_neon
    mov             x0, x6
    ret             x10
endfunc

function PFX(pixel_satd_32x24_neon)
    mov             x10, x30
    satd_32x16_neon
    movi            v30.8h, #0
    movi            v31.8h, #0
    sub             x0, x0, #16
    sub             x2, x2, #16
    pixel_satd_32x8
    add             v0.8h, v30.8h, v31.8h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    add             x0, x0, x6
    ret             x10
endfunc

function PFX(pixel_satd_32x32_neon)
    mov             x10, x30
    mov             x7, #0
    satd_32x16_neon
    sub             x0, x0, #16
    sub             x2, x2, #16
    add             x7, x7, x6
    satd_32x16_neon
    add             x0, x7, x6
    ret             x10
endfunc

function PFX(pixel_satd_32x48_neon)
    mov             x10, x30
    mov             x7, #0
.rept 2
    satd_32x16_neon
    sub             x0, x0, #16
    sub             x2, x2, #16
    add             x7, x7, x6
.endr
    satd_32x16_neon
    add             x0, x7, x6
    ret             x10
endfunc

function PFX(pixel_satd_32x64_neon)
    mov             x10, x30
    mov             x7, #0
.rept 3
    satd_32x16_neon
    sub             x0, x0, #16
    sub             x2, x2, #16
    add             x7, x7, x6
.endr
    satd_32x16_neon
    add             x0, x7, x6
    ret             x10
endfunc

function PFX(pixel_satd_64x16_neon)
    mov             x10, x30
    mov             x7, #0
    satd_64x16_neon
    mov             x0, x7
    ret             x10
endfunc

function PFX(pixel_satd_64x32_neon)
    mov             x10, x30
    mov             x7, #0
    satd_64x16_neon
    sub             x0, x0, #48
    sub             x2, x2, #48
    satd_64x16_neon
    mov             x0, x7
    ret             x10
endfunc

function PFX(pixel_satd_64x48_neon)
    mov             x10, x30
    mov             x7, #0
.rept 2
    satd_64x16_neon
    sub             x0, x0, #48
    sub             x2, x2, #48
.endr
    satd_64x16_neon
    mov             x0, x7
    ret             x10
endfunc

function PFX(pixel_satd_64x64_neon)
    mov             x10, x30
    mov             x7, #0
.rept 3
    satd_64x16_neon
    sub             x0, x0, #48
    sub             x2, x2, #48
.endr
    satd_64x16_neon
    mov             x0, x7
    ret             x10
endfunc

function PFX(pixel_satd_48x64_neon)
    mov             x10, x30
    mov             x7, #0
    mov             x8, x0
    mov             x9, x2
.rept 3
    satd_32x16_neon
    sub             x0, x0, #16
    sub             x2, x2, #16
    add             x7, x7, x6
.endr
    satd_32x16_neon
    add             x7, x7, x6

    add             x0, x8, #32
    add             x2, x9, #32
    pixel_satd_16x32_neon
    add             v0.8h, v30.8h, v31.8h
    uaddlv          s0, v0.8h
    mov             w6, v0.s[0]
    add             x7, x7, x6

    movi            v30.8h, #0
    movi            v31.8h, #0
    pixel_satd_16x32_neon
    add             v0.8h, v30.8h, v31.8h
    uaddlv          s0, v0.8h
    mov             w6, v0.s[0]
    add             x0, x7, x6
    ret             x10
endfunc

function PFX(sa8d_8x8_neon), export=0
    LOAD_DIFF_8x4   v16.8h, v17.8h, v18.8h, v19.8h
    LOAD_DIFF_8x4   v20.8h, v21.8h, v22.8h, v23.8h
    HADAMARD4_V     v16.8h, v18.8h, v17.8h, v19.8h, v0.8h, v2.8h, v1.8h, v3.8h
    HADAMARD4_V     v20.8h, v21.8h, v22.8h, v23.8h, v0.8h, v1.8h, v2.8h, v3.8h
    SUMSUB_ABCD     v0.8h, v16.8h, v1.8h, v17.8h, v16.8h, v20.8h, v17.8h, v21.8h
    SUMSUB_ABCD     v2.8h, v18.8h, v3.8h, v19.8h, v18.8h, v22.8h, v19.8h, v23.8h
    trn4            v4.8h, v5.8h, v6.8h, v7.8h, v0.8h, v1.8h, v2.8h, v3.8h
    trn4            v20.8h, v21.8h, v22.8h, v23.8h, v16.8h, v17.8h, v18.8h, v19.8h
    SUMSUB_ABCD     v2.8h, v3.8h, v24.8h, v25.8h, v20.8h, v21.8h, v4.8h, v5.8h
    SUMSUB_ABCD     v0.8h, v1.8h, v4.8h, v5.8h, v22.8h, v23.8h, v6.8h, v7.8h
    trn4            v20.4s, v22.4s, v21.4s, v23.4s, v2.4s, v0.4s, v3.4s, v1.4s
    trn4            v16.4s, v18.4s, v17.4s, v19.4s, v24.4s, v4.4s, v25.4s, v5.4s
    SUMSUB_ABCD     v0.8h, v2.8h, v1.8h, v3.8h, v20.8h, v22.8h, v21.8h, v23.8h
    SUMSUB_ABCD     v4.8h, v6.8h, v5.8h, v7.8h, v16.8h, v18.8h, v17.8h, v19.8h
    trn4            v16.2d, v20.2d, v17.2d, v21.2d, v0.2d, v4.2d, v1.2d, v5.2d
    trn4            v18.2d, v22.2d, v19.2d, v23.2d, v2.2d, v6.2d, v3.2d, v7.2d
    ABS8            v16.8h, v17.8h, v18.8h, v19.8h, v20.8h, v21.8h, v22.8h, v23.8h
    smax            v16.8h, v16.8h, v20.8h
    smax            v17.8h, v17.8h, v21.8h
    smax            v18.8h, v18.8h, v22.8h
    smax            v19.8h, v19.8h, v23.8h
    add             v0.8h, v16.8h, v17.8h
    add             v1.8h, v18.8h, v19.8h
    ret
endfunc

function PFX(pixel_sa8d_8x8_neon)
    mov             x10, x30
    bl              PFX(sa8d_8x8_neon)
    add             v0.8h, v0.8h, v1.8h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    add             w0, w0, #1
    lsr             w0, w0, #1
    ret             x10
endfunc

function PFX(pixel_sa8d_8x16_neon)
    mov             x10, x30
    bl              PFX(sa8d_8x8_neon)
    add             v0.8h, v0.8h, v1.8h
    uaddlv          s0, v0.8h
    mov             w5, v0.s[0]
    add             w5, w5, #1
    lsr             w5, w5, #1
    bl              PFX(sa8d_8x8_neon)
    add             v0.8h, v0.8h, v1.8h
    uaddlv          s0, v0.8h
    mov             w4, v0.s[0]
    add             w4, w4, #1
    lsr             w4, w4, #1
    add             w0, w4, w5
    ret             x10
endfunc

.macro sa8d_16x16 reg
    bl              PFX(sa8d_8x8_neon)
    uaddlp          v30.4s, v0.8h
    uaddlp          v31.4s, v1.8h
    bl              PFX(sa8d_8x8_neon)
    uadalp          v30.4s, v0.8h
    uadalp          v31.4s, v1.8h
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    bl              PFX(sa8d_8x8_neon)
    uadalp          v30.4s, v0.8h
    uadalp          v31.4s, v1.8h
    bl              PFX(sa8d_8x8_neon)
    uadalp          v30.4s, v0.8h
    uadalp          v31.4s, v1.8h
    add             v0.4s, v30.4s, v31.4s
    addv            s0, v0.4s
    mov             \reg, v0.s[0]
    add             \reg, \reg, #1
    lsr             \reg, \reg, #1
.endm

function PFX(pixel_sa8d_16x16_neon)
    mov             x10, x30
    sa8d_16x16      w0
    ret             x10
endfunc

function PFX(pixel_sa8d_16x32_neon)
    mov             x10, x30
    sa8d_16x16      w4
    sub             x0, x0, #8
    sub             x2, x2, #8
    sa8d_16x16      w5
    add             w0, w4, w5
    ret             x10
endfunc

function PFX(pixel_sa8d_32x32_neon)
    mov             x10, x30
    sa8d_16x16      w4
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16      w5
    sub             x0, x0, #24
    sub             x2, x2, #24
    sa8d_16x16      w6
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16      w7
    add             w4, w4, w5
    add             w6, w6, w7
    add             w0, w4, w6
    ret             x10
endfunc

function PFX(pixel_sa8d_32x64_neon)
    mov             x10, x30
    mov             w11, #4
    mov             w9, #0
.loop_sa8d_32:
    sub             w11, w11, #1
    sa8d_16x16      w4
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16      w5
    add             w4, w4, w5
    add             w9, w9, w4
    sub             x0, x0, #24
    sub             x2, x2, #24
    cbnz            w11, .loop_sa8d_32
    mov             w0, w9
    ret             x10
endfunc

function PFX(pixel_sa8d_64x64_neon)
    mov             x10, x30
    mov             w11, #4
    mov             w9, #0
.loop_sa8d_64:
    sub             w11, w11, #1
    sa8d_16x16      w4
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16      w5
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16      w6
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16      w7
    add             w4, w4, w5
    add             w6, w6, w7
    add             w8, w4, w6
    add             w9, w9, w8

    sub             x0, x0, #56
    sub             x2, x2, #56
    cbnz            w11, .loop_sa8d_64
    mov             w0, w9
    ret             x10
endfunc

/***** dequant_scaling*****/
// void dequant_scaling_c(const int16_t* quantCoef, const int32_t* deQuantCoef, int16_t* coef, int num, int per, int shift)
function PFX(dequant_scaling_neon)
    add             x5, x5, #4              // shift + 4
    lsr             x3, x3, #3              // num / 8
    cmp             x5, x4
    blt             .dequant_skip

    mov             x12, #1
    sub             x6, x5, x4          // shift - per
    sub             x6, x6, #1          // shift - per - 1
    lsl             x6, x12, x6         // 1 << shift - per - 1 (add)
    dup             v0.4s, w6
    sub             x7, x4, x5          // per - shift
    dup             v3.4s, w7

.dequant_loop1:
    ld1             {v19.8h}, [x0], #16 // quantCoef
    ld1             {v2.4s}, [x1], #16  // deQuantCoef
    ld1             {v20.4s}, [x1], #16
    sub             x3, x3, #1
    sxtl            v1.4s, v19.4h
    sxtl2           v19.4s, v19.8h

    mul             v1.4s, v1.4s, v2.4s // quantCoef * deQuantCoef
    mul             v19.4s, v19.4s, v20.4s
    add             v1.4s, v1.4s, v0.4s // quantCoef * deQuantCoef + add
    add             v19.4s, v19.4s, v0.4s

    sshl            v1.4s, v1.4s, v3.4s
    sshl            v19.4s, v19.4s, v3.4s
    sqxtn           v16.4h, v1.4s       // x265_clip3
    sqxtn2          v16.8h, v19.4s
    st1             {v16.8h}, [x2], #16
    cbnz            x3, .dequant_loop1
    ret

.dequant_skip:
    sub             x6, x4, x5          // per - shift
    dup             v0.8h, w6

.dequant_loop2:
    ld1             {v19.8h}, [x0], #16 // quantCoef
    ld1             {v2.4s}, [x1], #16  // deQuantCoef
    ld1             {v20.4s}, [x1], #16
    sub             x3, x3, #1
    sxtl            v1.4s, v19.4h
    sxtl2           v19.4s, v19.8h

    mul             v1.4s, v1.4s, v2.4s // quantCoef * deQuantCoef
    mul             v19.4s, v19.4s, v20.4s
    sqxtn           v16.4h, v1.4s       // x265_clip3
    sqxtn2          v16.8h, v19.4s

    sqshl           v16.8h, v16.8h, v0.8h // coefQ << per - shift
    st1             {v16.8h}, [x2], #16
    cbnz            x3, .dequant_loop2
    ret
endfunc

// void dequant_normal_c(const int16_t* quantCoef, int16_t* coef, int num, int scale, int shift)
function PFX(dequant_normal_neon)
    lsr             w2, w2, #4              // num / 16
    neg             w4, w4
    dup             v0.8h, w3
    dup             v1.4s, w4

.dqn_loop1:
    ld1             {v2.8h, v3.8h}, [x0], #32
    smull           v16.4s, v2.4h, v0.4h
    smull2          v17.4s, v2.8h, v0.8h
    smull           v18.4s, v3.4h, v0.4h
    smull2          v19.4s, v3.8h, v0.8h

    srshl           v16.4s, v16.4s, v1.4s
    srshl           v17.4s, v17.4s, v1.4s
    srshl           v18.4s, v18.4s, v1.4s
    srshl           v19.4s, v19.4s, v1.4s

    sqxtn           v2.4h, v16.4s
    sqxtn2          v2.8h, v17.4s
    sqxtn           v3.4h, v18.4s
    sqxtn2          v3.8h, v19.4s

    sub             w2, w2, #1
    st1             {v2.8h, v3.8h}, [x1], #32
    cbnz            w2, .dqn_loop1
    ret
endfunc

/********* ssim ***********/
// void ssim_4x4x2_core(const pixel* pix1, intptr_t stride1, const pixel* pix2, intptr_t stride2, int sums[2][4])
function PFX(ssim_4x4x2_core_neon)
    ld1             {v0.8b}, [x0], x1
    ld1             {v1.8b}, [x0], x1
    ld1             {v2.8b}, [x0], x1
    ld1             {v3.8b}, [x0], x1

    ld1             {v4.8b}, [x2], x3
    ld1             {v5.8b}, [x2], x3
    ld1             {v6.8b}, [x2], x3
    ld1             {v7.8b}, [x2], x3

    umull           v16.8h, v0.8b, v0.8b
    umull           v17.8h, v1.8b, v1.8b
    umull           v18.8h, v2.8b, v2.8b
    uaddlp          v30.4s, v16.8h
    umull           v19.8h, v3.8b, v3.8b
    umull           v20.8h, v4.8b, v4.8b
    umull           v21.8h, v5.8b, v5.8b
    uadalp          v30.4s, v17.8h
    umull           v22.8h, v6.8b, v6.8b
    umull           v23.8h, v7.8b, v7.8b

    umull           v24.8h, v0.8b, v4.8b
    uadalp          v30.4s, v18.8h
    umull           v25.8h, v1.8b, v5.8b
    umull           v26.8h, v2.8b, v6.8b
    umull           v27.8h, v3.8b, v7.8b
    uadalp          v30.4s, v19.8h

    uaddl           v28.8h, v0.8b, v1.8b
    uaddl           v29.8h, v4.8b, v5.8b
    uadalp          v30.4s, v20.8h
    uaddlp          v31.4s, v24.8h

    uaddw           v28.8h, v28.8h, v2.8b
    uaddw           v29.8h, v29.8h, v6.8b
    uadalp          v30.4s, v21.8h
    uadalp          v31.4s, v25.8h

    uaddw           v28.8h, v28.8h, v3.8b
    uaddw           v29.8h, v29.8h, v7.8b
    uadalp          v30.4s, v22.8h
    uadalp          v31.4s, v26.8h

    uaddlp          v28.4s, v28.8h
    uaddlp          v29.4s, v29.8h
    uadalp          v30.4s, v23.8h
    uadalp          v31.4s, v27.8h

    addp            v28.4s, v28.4s, v28.4s
    addp            v29.4s, v29.4s, v29.4s
    addp            v30.4s, v30.4s, v30.4s
    addp            v31.4s, v31.4s, v31.4s

    st4             {v28.2s, v29.2s, v30.2s, v31.2s}, [x4]
    ret
endfunc

// int psyCost_pp(const pixel* source, intptr_t sstride, const pixel* recon, intptr_t rstride)
function PFX(psyCost_4x4_neon)
    ld1r            {v4.2s}, [x0], x1
    ld1r            {v5.2s}, [x0], x1
    ld1             {v4.s}[1], [x0], x1
    ld1             {v5.s}[1], [x0], x1

    ld1r            {v6.2s}, [x2], x3
    ld1r            {v7.2s}, [x2], x3
    ld1             {v6.s}[1], [x2], x3
    ld1             {v7.s}[1], [x2], x3

    uaddl           v2.8h, v4.8b, v5.8b
    usubl           v3.8h, v4.8b, v5.8b
    uaddl           v18.8h, v6.8b, v7.8b
    usubl           v19.8h, v6.8b, v7.8b

    mov             v20.d[0], v2.d[1]
    add             v0.4h, v2.4h, v20.4h
    sub             v1.4h, v2.4h, v20.4h
    mov             v21.d[0], v3.d[1]
    add             v22.4h, v3.4h, v21.4h
    sub             v23.4h, v3.4h, v21.4h

    mov             v24.d[0], v18.d[1]
    add             v16.4h, v18.4h, v24.4h
    sub             v17.4h, v18.4h, v24.4h
    mov             v25.d[0], v19.d[1]
    add             v26.4h, v19.4h, v25.4h
    sub             v27.4h, v19.4h, v25.4h

    mov             v0.d[1], v22.d[0]
    mov             v1.d[1], v23.d[0]
    trn1            v22.8h, v0.8h, v1.8h
    trn2            v23.8h, v0.8h, v1.8h
    mov             v16.d[1], v26.d[0]
    mov             v17.d[1], v27.d[0]
    trn1            v26.8h, v16.8h, v17.8h
    trn2            v27.8h, v16.8h, v17.8h

    add             v2.8h, v22.8h, v23.8h
    sub             v3.8h, v22.8h, v23.8h
    add             v18.8h, v26.8h, v27.8h
    sub             v19.8h, v26.8h, v27.8h

    uaddl           v20.8h, v4.8b, v5.8b
    uaddl           v21.8h, v6.8b, v7.8b

    trn1            v0.4s, v2.4s, v3.4s
    trn2            v1.4s, v2.4s, v3.4s
    trn1            v16.4s, v18.4s, v19.4s
    trn2            v17.4s, v18.4s, v19.4s
    abs             v0.8h, v0.8h
    abs             v16.8h, v16.8h
    abs             v1.8h, v1.8h
    abs             v17.8h, v17.8h

    uaddlv          s20, v20.8h
    uaddlv          s21, v21.8h
    mov             v20.s[1], v21.s[0]

    smax            v0.8h, v0.8h, v1.8h
    smax            v16.8h, v16.8h, v17.8h

    trn1            v4.2d, v0.2d, v16.2d
    trn2            v5.2d, v0.2d, v16.2d
    add             v0.8h, v4.8h, v5.8h
    mov             v4.d[0], v0.d[1]
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

// uint32_t quant_c(const int16_t* coef, const int32_t* quantCoeff, int32_t* deltaU, int16_t* qCoef, int qBits, int add, int numCoeff)
function PFX(quant_neon)
    mov             w9, #1
    lsl             w9, w9, w4
    dup             v0.2s, w9
    neg             w9, w4
    dup             v1.4s, w9
    add             w9, w9, #8
    dup             v2.4s, w9
    dup             v3.4s, w5

    lsr             w6, w6, #2
    eor             v4.16b, v4.16b, v4.16b
    eor             w10, w10, w10
    eor             v17.16b, v17.16b, v17.16b

.loop_quant:

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
    eor             v16.16b, v7.16b, v5.16b
    sub             v16.4s, v16.4s, v5.4s
    sqxtn           v5.4h, v16.4s
    st1             {v5.4h}, [x3], #8

    subs            w6, w6, #1
    b.ne             .loop_quant

    addv            s4, v4.4s
    mov             w9, v4.s[0]
    add             w0, w10, w9
    ret
endfunc

// uint32_t nquant_c(const int16_t* coef, const int32_t* quantCoeff, int16_t* qCoef, int qBits, int add, int numCoeff)
function PFX(nquant_neon)
    neg             x12, x3
    dup             v0.4s, w12             // q0= -qbits
    dup             v1.4s, w4              // add

    lsr             w5, w5, #2
    movi            v4.4s, #0              // v4= accumulate numsig
    mov             x4, #0
    movi            v22.4s, #0

.loop_nquant:
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

    eor             v21.16b, v20.16b, v18.16b
    sub             v21.4s, v21.4s, v18.4s
    sqxtn           v16.4h, v21.4s
    abs             v17.4h, v16.4h
    st1             {v17.4h}, [x2], #8

    cbnz            w5, .loop_nquant

    uaddlv          d4, v4.4s
    fmov            x12, d4
    add             x0, x4, x12
    ret
endfunc

// void ssimDist_c(const pixel* fenc, uint32_t fStride, const pixel* recon, intptr_t rstride, uint64_t *ssBlock, int shift, uint64_t *ac_k)
.macro ssimDist_start
    movi            v0.16b, #0
    movi            v1.16b, #0
.endm

.macro ssimDist_1  v4 v5
    sub             v20.8h, \v4\().8h, \v5\().8h
    smull           v16.4s, \v4\().4h, \v4\().4h
    smull2          v17.4s, \v4\().8h, \v4\().8h
    smull           v18.4s, v20.4h, v20.4h
    smull2          v19.4s, v20.8h, v20.8h
    add             v0.4s, v0.4s, v16.4s
    add             v0.4s, v0.4s, v17.4s
    add             v1.4s, v1.4s, v18.4s
    add             v1.4s, v1.4s, v19.4s
.endm

.macro ssimDist_end
    uaddlv          d0, v0.4s
    uaddlv          d1, v1.4s
    str             d0, [x6]
    str             d1, [x4]
.endm

function PFX(ssimDist4_neon)
    ssimDist_start
.rept 4
    ld1             {v4.s}[0], [x0], x1
    ld1             {v5.s}[0], [x2], x3
    uxtl            v4.8h, v4.8b
    uxtl            v5.8h, v5.8b
    sub             v2.4h, v4.4h, v5.4h
    smull           v3.4s, v4.4h, v4.4h
    smull           v2.4s, v2.4h, v2.4h
    add             v0.4s, v0.4s, v3.4s
    add             v1.4s, v1.4s, v2.4s
.endr
    ssimDist_end
    ret
endfunc

function PFX(ssimDist8_neon)
    ssimDist_start
.rept 8
    ld1             {v4.8b}, [x0], x1
    ld1             {v5.8b}, [x2], x3
    uxtl            v4.8h, v4.8b
    uxtl            v5.8h, v5.8b
    ssimDist_1      v4, v5
.endr
    ssimDist_end
    ret
endfunc

function PFX(ssimDist16_neon)
    mov w12, #16
    ssimDist_start
.loop_ssimDist16:
    sub             w12, w12, #1
    ld1             {v4.16b}, [x0], x1
    ld1             {v5.16b}, [x2], x3
    uxtl            v6.8h, v4.8b
    uxtl            v7.8h, v5.8b
    uxtl2           v4.8h, v4.16b
    uxtl2           v5.8h, v5.16b
    ssimDist_1      v6, v7
    ssimDist_1      v4, v5
    cbnz            w12, .loop_ssimDist16
    ssimDist_end
    ret
endfunc

function PFX(ssimDist32_neon)
    mov w12, #32
    ssimDist_start
.loop_ssimDist32:
    sub             w12, w12, #1
    ld1             {v4.16b-v5.16b}, [x0], x1
    ld1             {v6.16b-v7.16b}, [x2], x3
    uxtl            v21.8h, v4.8b
    uxtl            v22.8h, v6.8b
    uxtl            v23.8h, v5.8b
    uxtl            v24.8h, v7.8b
    uxtl2           v25.8h, v4.16b
    uxtl2           v26.8h, v6.16b
    uxtl2           v27.8h, v5.16b
    uxtl2           v28.8h, v7.16b
    ssimDist_1      v21, v22
    ssimDist_1      v23, v24
    ssimDist_1      v25, v26
    ssimDist_1      v27, v28
    cbnz            w12, .loop_ssimDist32
    ssimDist_end
    ret
endfunc

function PFX(ssimDist64_neon)
    mov w12, #64
    ssimDist_start
.loop_ssimDist64:
    sub             w12, w12, #1
    ld1             {v4.16b-v7.16b}, [x0], x1
    ld1             {v16.16b-v19.16b}, [x2], x3
    uxtl            v21.8h, v4.8b
    uxtl            v22.8h, v16.8b
    uxtl            v23.8h, v5.8b
    uxtl            v24.8h, v17.8b
    uxtl2           v25.8h, v4.16b
    uxtl2           v26.8h, v16.16b
    uxtl2           v27.8h, v5.16b
    uxtl2           v28.8h, v17.16b
    ssimDist_1      v21, v22
    ssimDist_1      v23, v24
    ssimDist_1      v25, v26
    ssimDist_1      v27, v28
    uxtl            v21.8h, v6.8b
    uxtl            v22.8h, v18.8b
    uxtl            v23.8h, v7.8b
    uxtl            v24.8h, v19.8b
    uxtl2           v25.8h, v6.16b
    uxtl2           v26.8h, v18.16b
    uxtl2           v27.8h, v7.16b
    uxtl2           v28.8h, v19.16b
    ssimDist_1      v21, v22
    ssimDist_1      v23, v24
    ssimDist_1      v25, v26
    ssimDist_1      v27, v28
    cbnz            w12, .loop_ssimDist64
    ssimDist_end
    ret
endfunc

// void normFact_c(const pixel* src, uint32_t blockSize, int shift, uint64_t *z_k)

.macro normFact_start
    movi            v0.16b, #0
.endm

.macro normFact_1  v4
    smull           v16.4s, \v4\().4h, \v4\().4h
    smull2          v17.4s, \v4\().8h, \v4\().8h
    add             v0.4s, v0.4s, v16.4s
    add             v0.4s, v0.4s, v17.4s
.endm

.macro normFact_end
    uaddlv          d0, v0.4s
    str             d0, [x3]
.endm


function PFX(normFact8_neon)
    normFact_start
.rept 8
    ld1             {v4.8b}, [x0], x1
    uxtl            v4.8h, v4.8b
    normFact_1      v4
.endr
    normFact_end
    ret
endfunc

function PFX(normFact16_neon)
    mov w12, #16
    normFact_start
.loop_normFact16:
    sub             w12, w12, #1
    ld1             {v4.16b}, [x0], x1
    uxtl            v5.8h, v4.8b
    uxtl2           v4.8h, v4.16b
    normFact_1      v5
    normFact_1      v4
    cbnz            w12, .loop_normFact16
    normFact_end
    ret
endfunc

function PFX(normFact32_neon)
    mov w12, #32
    normFact_start
.loop_normFact32:
    sub             w12, w12, #1
    ld1             {v4.16b-v5.16b}, [x0], x1
    uxtl            v6.8h, v4.8b
    uxtl2           v4.8h, v4.16b
    uxtl            v7.8h, v5.8b
    uxtl2           v5.8h, v5.16b
    normFact_1      v4
    normFact_1      v5
    normFact_1      v6
    normFact_1      v7
    cbnz            w12, .loop_normFact32
    normFact_end
    ret
endfunc

function PFX(normFact64_neon)
    mov w12, #64
    normFact_start
.loop_normFact64:
    sub             w12, w12, #1
    ld1             {v4.16b-v7.16b}, [x0], x1
    uxtl            v26.8h, v4.8b
    uxtl2           v24.8h, v4.16b
    uxtl            v27.8h, v5.8b
    uxtl2           v25.8h, v5.16b
    normFact_1      v24
    normFact_1      v25
    normFact_1      v26
    normFact_1      v27
    uxtl            v26.8h, v6.8b
    uxtl2           v24.8h, v6.16b
    uxtl            v27.8h, v7.8b
    uxtl2           v25.8h, v7.16b
    normFact_1      v24
    normFact_1      v25
    normFact_1      v26
    normFact_1      v27
    cbnz            w12, .loop_normFact64
    normFact_end
    ret
endfunc

// void weight_pp_c(const pixel* src, pixel* dst, intptr_t stride, int width, int height, int w0, int round, int shift, int offset)
function PFX(weight_pp_neon)
    sub             x2, x2, x3
    ldr             w9, [sp]              // offset
    lsl             w5, w5, #6            // w0 << correction

    // count trailing zeros in w5 and compare against shift right amount.
    rbit            w10, w5
    clz             w10, w10
    cmp             w10, w7
    b.lt            .unfoldedShift

    // shift right only removes trailing zeros: hoist LSR out of the loop.
    lsr             w10, w5, w7           // w0 << correction >> shift
    dup             v25.16b, w10
    lsr             w6, w6, w7            // round >> shift
    add             w6, w6, w9            // round >> shift + offset
    dup             v26.8h, w6

    // Check arithmetic range.
    mov             w11, #255
    madd            w11, w11, w10, w6
    add             w11, w11, w9
    lsr             w11, w11, #16
    cbnz            w11, .widenTo32Bit

    // 16-bit arithmetic is enough.
.loopHpp:
    mov             x12, x3
.loopWpp:
    ldr             q0, [x0], #16
    sub             x12, x12, #16
    umull           v1.8h, v0.8b, v25.8b  // val *= w0 << correction >> shift
    umull2          v2.8h, v0.16b, v25.16b
    add             v1.8h, v1.8h, v26.8h  // val += round >> shift + offset
    add             v2.8h, v2.8h, v26.8h
    sqxtun          v0.8b, v1.8h          // val = x265_clip(val)
    sqxtun2         v0.16b, v2.8h
    str             q0, [x1], #16
    cbnz            x12, .loopWpp
    add             x1, x1, x2
    add             x0, x0, x2
    sub             x4, x4, #1
    cbnz            x4, .loopHpp
    ret

    // 32-bit arithmetic is needed.
.widenTo32Bit:
.loopHpp32:
    mov             x12, x3
.loopWpp32:
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
    cbnz            x12, .loopWpp32
    add             x1, x1, x2
    add             x0, x0, x2
    sub             x4, x4, #1
    cbnz            x4, .loopHpp32
    ret

    // The shift right cannot be moved out of the loop.
.unfoldedShift:
    dup             v25.8h, w5            // w0 << correction
    dup             v26.4s, w6            // round
    neg             w7, w7                // -shift
    dup             v27.4s, w7
    dup             v29.4s, w9            // offset
.loopHppUS:
    mov             x12, x3
.loopWppUS:
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
    cbnz            x12, .loopWppUS
    add             x1, x1, x2
    add             x0, x0, x2
    sub             x4, x4, #1
    cbnz            x4, .loopHppUS
    ret
endfunc

// int scanPosLast(
//     const uint16_t *scan,      // x0
//     const coeff_t *coeff,      // x1
//     uint16_t *coeffSign,       // x2
//     uint16_t *coeffFlag,       // x3
//     uint8_t *coeffNum,         // x4
//     int numSig,                // x5
//     const uint16_t* scanCG4x4, // x6
//     const int trSize)          // x7
function PFX(scanPosLast_neon)
    // convert unit of Stride(trSize) to int16_t
    add             x7, x7, x7

    // load scan table and convert to Byte
    ldp             q0, q1, [x6]
    xtn             v0.8b, v0.8h
    xtn2            v0.16b, v1.8h   // v0 - Zigzag scan table

    movrel          x10, g_SPL_and_mask
    ldr             q28, [x10]      // v28 = mask for pmovmskb
    movi            v31.16b, #0     // v31 = {0, ..., 0}
    add             x10, x7, x7     // 2*x7
    add             x11, x10, x7    // 3*x7
    add             x9, x4, #1      // CG count

.loop_spl:
    // position of current CG
    ldrh            w6, [x0], #32
    add             x6, x1, x6, lsl #1

    // loading current CG
    ldr             d2, [x6]
    ldr             d3, [x6, x7]
    ldr             d4, [x6, x10]
    ldr             d5, [x6, x11]
    mov             v2.d[1], v3.d[0]
    mov             v4.d[1], v5.d[0]
    sqxtn           v2.8b, v2.8h
    sqxtn2          v2.16b, v4.8h

    // Zigzag
    tbl             v3.16b, {v2.16b}, v0.16b

    // get sign
    cmhi            v5.16b, v3.16b, v31.16b   // v5 = non-zero
    cmlt            v3.16b, v3.16b, #0        // v3 = negative

    // val - w13 = pmovmskb(v3)
    and             v3.16b, v3.16b, v28.16b
    mov             d4, v3.d[1]
    addv            b23, v3.8b
    addv            b24, v4.8b
    mov             v23.b[1], v24.b[0]
    fmov            w13, s23

    // mask - w15 = pmovmskb(v5)
    and             v5.16b, v5.16b, v28.16b
    mov             d6, v5.d[1]
    addv            b25, v5.8b
    addv            b26, v6.8b
    mov             v25.b[1], v26.b[0]
    fmov            w15, s25

    // coeffFlag = reverse_bit(w15) in 16-bit
    rbit            w12, w15
    lsr             w12, w12, #16
    fmov            s30, w12
    strh            w12, [x3], #2

    // accelerate by preparing w13 = w13 & w15
    and             w13, w13, w15
    mov             x14, xzr
.loop_spl_1:
    cbz             w15, .pext_end
    clz             w6, w15
    lsl             w13, w13, w6
    lsl             w15, w15, w6
    extr            w14, w14, w13, #31
    bfm             w15, wzr, #1, #0
    b               .loop_spl_1
.pext_end:
    strh            w14, [x2], #2

    // compute coeffNum = popcount(coeffFlag)
    cnt             v30.8b, v30.8b
    addp            v30.8b, v30.8b, v30.8b
    fmov            w6, s30
    sub             x5, x5, x6
    strb            w6, [x4], #1

    cbnz            x5, .loop_spl

    // count trailing zeros
    rbit            w13, w12
    clz             w13, w13
    lsr             w12, w12, w13
    strh            w12, [x3, #-2]

    // get last pos
    sub             x9, x4, x9
    lsl             x0, x9, #4
    eor             w13, w13, #15
    add             x0, x0, x13
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
function PFX(costCoeffNxN_neon)
    // abs(coeff)
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
    dup             v4.16b, w7
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
    movrel          x1, PFX_C(entropyStateBits)
    mov             x4, #0
    mov             x11, #0
    movi            v31.16b, #0
    cbz             x2, .idx_zero
.loop_ccnn:
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
    cbnz            x2, .loop_ccnn
.idx_zero:

    add             x13, x3, x4, lsl #1
    add             x4, x4, x15
    str             h2, [x13]              // absCoeff[numNonZero] = tmpCoeff[blkPos]

    ldr             x9, [sp, #8]           // subPosBase
    uxth            w9, w9
    cmp             w9, #0
    cset            x2, eq
    add             x4, x4, x2
    cbz             x4, .exit_ccnn

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
.exit_ccnn:
    ubfx            w0, w0, #0, #24
    ret
endfunc

// ################### SVE2 #####################

// uint64_t pixel_var(const pixel* pix, intptr_t i_stride)
function PFX(pixel_var_8x8_sve2)
    ptrue           p0.h, vl8
    ld1b            {z0.h}, p0/z, [x0]
    add             x0, x0, x1
    mul             z31.h, z0.h, z0.h
    uaddlp          v1.4s, v31.8h
.rept 7
    ld1b            {z4.h}, p0/z, [x0]
    add             x0, x0, x1
    add             z0.h, z0.h, z4.h
    mul             z31.h, z4.h, z4.h
    uadalp          z1.s, p0/m, z31.h
.endr
    uaddlv          s0, v0.8h
    uaddlv          d1, v1.4s
    fmov            w0, s0
    fmov            x1, d1
    orr             x0, x0, x1, lsl #32
    ret
endfunc

function PFX(pixel_var_16x16_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_var_16x16
    pixel_var_start
    mov             w12, #16
.loop_var_16_sve2:
    sub             w12, w12, #1
    ld1             {v4.16b}, [x0], x1
    pixel_var_1 v4
    cbnz            w12, .loop_var_16_sve2
    pixel_var_end
    ret
.vl_gt_16_pixel_var_16x16:
    ptrue           p0.h, vl16
    mov             z0.d, #0
.rept 16
    ld1b            {z4.h}, p0/z, [x0]
    add             x0, x0, x1
    add             z0.h, z0.h, z4.h
    mul             z30.h, z4.h, z4.h
    uadalp          z1.s, p0/m, z30.h
.endr
    uaddv           d0, p0, z0.h
    uaddv           d1, p0, z1.s
    fmov            w0, s0
    fmov            x1, d1
    orr             x0, x0, x1, lsl #32
    ret
endfunc

function PFX(pixel_var_32x32_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_var_32x32
    pixel_var_start
    mov             w12, #32
.loop_var_32_sve2:
    sub             w12, w12, #1
    ld1             {v4.16b-v5.16b}, [x0], x1
    pixel_var_1 v4
    pixel_var_1 v5
    cbnz            w12, .loop_var_32_sve2
    pixel_var_end
    ret
.vl_gt_16_pixel_var_32x32:
    cmp             x9, #48
    bgt             .vl_gt_48_pixel_var_32x32
    ptrue           p0.b, vl32
    mov             z0.d, #0
    mov             z1.d, #0
.rept 32
    ld1b            {z4.b}, p0/z, [x0]
    add             x0, x0, x1
    uaddwb          z0.h, z0.h, z4.b
    uaddwt          z0.h, z0.h, z4.b
    umullb          z28.h, z4.b, z4.b
    umullt          z29.h, z4.b, z4.b
    uadalp          z1.s, p0/m, z28.h
    uadalp          z1.s, p0/m, z29.h
.endr
    uaddv           d0, p0, z0.h
    uaddv           d1, p0, z1.s
    fmov            w0, s0
    fmov            x1, d1
    orr             x0, x0, x1, lsl #32
    ret
.vl_gt_48_pixel_var_32x32:
    ptrue           p0.h, vl32
    mov             z0.d, #0
    mov             z1.d, #0
.rept 32
    ld1b            {z4.h}, p0/z, [x0]
    add             x0, x0, x1
    add             z0.h, z0.h, z4.h
    mul             z28.h, z4.h, z4.h
    uadalp          z1.s, p0/m, z28.h
.endr
    uaddv           d0, p0, z0.h
    uaddv           d1, p0, z1.s
    fmov            w0, s0
    fmov            x1, d1
    orr             x0, x0, x1, lsl #32
    ret
endfunc

function PFX(pixel_var_64x64_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_var_64x64
    pixel_var_start
    mov             w12, #64
.loop_var_64_sve2:
    sub             w12, w12, #1
    ld1             {v4.16b-v7.16b}, [x0], x1
    pixel_var_1 v4
    pixel_var_1 v5
    pixel_var_1 v6
    pixel_var_1 v7
    cbnz            w12, .loop_var_64_sve2
    pixel_var_end
    ret
.vl_gt_16_pixel_var_64x64:
    cmp             x9, #48
    bgt             .vl_gt_48_pixel_var_64x64
    ptrue           p0.b, vl32
    mov             z0.d, #0
    mov             z2.d, #0
.rept 64
    ld1b            {z4.b}, p0/z, [x0]
    ld1b            {z5.b}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x1
    uaddwb          z0.h, z0.h, z4.b
    uaddwt          z0.h, z0.h, z4.b
    uaddwb          z0.h, z0.h, z5.b
    uaddwt          z0.h, z0.h, z5.b
    umullb          z24.h, z4.b, z4.b
    umullt          z25.h, z4.b, z4.b
    umullb          z26.h, z5.b, z5.b
    umullt          z27.h, z5.b, z5.b
    uadalp          z2.s, p0/m, z24.h
    uadalp          z2.s, p0/m, z25.h
    uadalp          z2.s, p0/m, z26.h
    uadalp          z2.s, p0/m, z27.h
.endr
    uaddv           d0, p0, z0.h
    uaddv           d1, p0, z2.s
    fmov            w0, s0
    fmov            x1, d1
    orr             x0, x0, x1, lsl #32
    ret
.vl_gt_48_pixel_var_64x64:
    cmp             x9, #112
    bgt             .vl_gt_112_pixel_var_64x64
    ptrue           p0.b, vl64
    mov             z0.d, #0
    mov             z1.d, #0
.rept 64
    ld1b            {z4.b}, p0/z, [x0]
    add             x0, x0, x1
    uaddwb          z0.h, z0.h, z4.b
    uaddwt          z0.h, z0.h, z4.b
    umullb          z24.h, z4.b, z4.b
    umullt          z25.h, z4.b, z4.b
    uadalp          z2.s, p0/m, z24.h
    uadalp          z2.s, p0/m, z25.h
.endr
    uaddv           d0, p0, z0.h
    uaddv           d1, p0, z2.s
    fmov            w0, s0
    fmov            x1, d1
    orr             x0, x0, x1, lsl #32
    ret
.vl_gt_112_pixel_var_64x64:
    ptrue           p0.h, vl64
    mov             z0.d, #0
    mov             z1.d, #0
.rept 64
    ld1b            {z4.h}, p0/z, [x0]
    add             x0, x0, x1
    add             z0.h, z0.h, z4.h
    mul             z24.h, z4.h, z4.h
    uadalp          z1.s, p0/m, z24.h
.endr
    uaddv           d0, p0, z0.h
    uaddv           d1, p0, z1.s
    fmov            w0, s0
    fmov            x1, d1
    orr             x0, x0, x1, lsl #32
    ret
endfunc

// void getResidual4_neon(const pixel* fenc, const pixel* pred, int16_t* residual, intptr_t stride)
function PFX(getResidual4_sve2)
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

function PFX(getResidual8_sve2)
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

function PFX(getResidual16_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_getResidual16
    ptrue           p0.b, vl16
.rept 16
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x1]
    add             x0, x0, x3
    add             x1, x1, x3
    usublb          z4.h, z0.b, z1.b
    usublt          z5.h, z0.b, z1.b
    st2h            {z4.h, z5.h}, p0, [x2]
    add             x2, x2, x3, lsl #1
.endr
    ret
.vl_gt_16_getResidual16:
    ptrue           p0.h, vl16
.rept 16
    ld1b            {z0.h}, p0/z, [x0]
    ld1b            {z2.h}, p0/z, [x1]
    add             x0, x0, x3
    add             x1, x1, x3
    sub             z4.h, z0.h, z2.h
    st1h            {z4.h}, p0, [x2]
    add             x2, x2, x3, lsl #1
.endr
    ret
endfunc

function PFX(getResidual32_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_getResidual32
    ptrue           p0.b, vl16
.rept 32
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x0, #1, mul vl]
    ld1b            {z2.b}, p0/z, [x1]
    ld1b            {z3.b}, p0/z, [x1, #1, mul vl]
    add             x0, x0, x3
    add             x1, x1, x3
    usublb          z4.h, z0.b, z2.b
    usublt          z5.h, z0.b, z2.b
    usublb          z6.h, z1.b, z3.b
    usublt          z7.h, z1.b, z3.b
    st2h            {z4.h, z5.h}, p0, [x2]
    st2h            {z6.h, z7.h}, p0, [x2, #2, mul vl]
    add             x2, x2, x3, lsl #1
.endr
    ret
.vl_gt_16_getResidual32:
    cmp             x9, #48
    bgt             .vl_gt_48_getResidual32
    ptrue           p0.b, vl32
.rept 32
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z2.b}, p0/z, [x1]
    add             x0, x0, x3
    add             x1, x1, x3
    usublb          z4.h, z0.b, z2.b
    usublt          z5.h, z0.b, z2.b
    st2h            {z4.h, z5.h}, p0, [x2]
    add             x2, x2, x3, lsl #1
.endr
    ret
.vl_gt_48_getResidual32:
    ptrue           p0.h, vl32
.rept 32
    ld1b            {z0.h}, p0/z, [x0]
    ld1b            {z4.h}, p0/z, [x1]
    add             x0, x0, x3
    add             x1, x1, x3
    sub             z8.h, z0.h, z4.h
    st1h            {z8.h}, p0, [x2]
    add             x2, x2, x3, lsl #1
.endr
    ret
endfunc

// void pixel_sub_ps_neon(int16_t* a, intptr_t dstride, const pixel* b0, const pixel* b1, intptr_t sstride0, intptr_t sstride1)
function PFX(pixel_sub_ps_4x4_sve2)
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

function PFX(pixel_sub_ps_8x8_sve2)
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

function PFX(pixel_sub_ps_16x16_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sub_ps_16x16
    ptrue           p0.b, vl16
.rept 16
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z4.b}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5
    usublb          z8.h, z0.b, z4.b
    usublt          z9.h, z0.b, z4.b
    st2h            {z8.h, z9.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_16_pixel_sub_ps_16x16:
    ptrue           p0.h, vl16
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

function PFX(pixel_sub_ps_32x32_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sub_ps_32x32
    ptrue           p0.b, vl16
.rept 32
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z2.b}, p0/z, [x3]
    ld1b            {z3.b}, p0/z, [x3, #1, mul vl]
    add             x2, x2, x4
    add             x3, x3, x5
    usublb          z16.h, z0.b, z2.b
    usublt          z17.h, z0.b, z2.b
    usublb          z18.h, z1.b, z3.b
    usublt          z19.h, z1.b, z3.b
    st2h            {z16.h, z17.h}, p0, [x0]
    st2h            {z18.h, z19.h}, p0, [x0, #2, mul vl]
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_16_pixel_sub_ps_32x32:
    cmp             x9, #48
    bgt             .vl_gt_48_pixel_sub_ps_32x32
    ptrue           p0.b, vl32
.rept 32
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z2.b}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5
    usublb          z16.h, z0.b, z2.b
    usublt          z17.h, z0.b, z2.b
    st2h            {z16.h, z17.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_48_pixel_sub_ps_32x32:
    ptrue           p0.h, vl32
.rept 32
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

function PFX(pixel_sub_ps_64x64_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sub_ps_64x64
    ptrue           p0.b, vl16
.rept 64
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z2.b}, p0/z, [x2, #2, mul vl]
    ld1b            {z3.b}, p0/z, [x2, #3, mul vl]
    ld1b            {z4.b}, p0/z, [x3]
    ld1b            {z5.b}, p0/z, [x3, #1, mul vl]
    ld1b            {z6.b}, p0/z, [x3, #2, mul vl]
    ld1b            {z7.b}, p0/z, [x3, #3, mul vl]
    add             x2, x2, x4
    add             x3, x3, x5
    usublb          z16.h, z0.b, z4.b
    usublt          z17.h, z0.b, z4.b
    usublb          z18.h, z1.b, z5.b
    usublt          z19.h, z1.b, z5.b
    usublb          z20.h, z2.b, z6.b
    usublt          z21.h, z2.b, z6.b
    usublb          z22.h, z3.b, z7.b
    usublt          z23.h, z3.b, z7.b
    st2h            {z16.h, z17.h}, p0, [x0]
    st2h            {z18.h, z19.h}, p0, [x0, #2, mul vl]
    st2h            {z20.h, z21.h}, p0, [x0, #4, mul vl]
    st2h            {z22.h, z23.h}, p0, [x0, #6, mul vl]
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_16_pixel_sub_ps_64x64:
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sub_ps_64x64
    ptrue           p0.b, vl32
.rept 64
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z4.b}, p0/z, [x3]
    ld1b            {z5.b}, p0/z, [x3, #1, mul vl]
    add             x2, x2, x4
    add             x3, x3, x5
    usublb          z16.h, z0.b, z4.b
    usublt          z17.h, z0.b, z4.b
    usublb          z18.h, z1.b, z5.b
    usublt          z19.h, z1.b, z5.b
    st2h            {z16.h, z17.h}, p0, [x0]
    st2h            {z18.h, z19.h}, p0, [x0, #2, mul vl]
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_48_pixel_sub_ps_64x64:
    cmp             x9, #112
    bgt             .vl_gt_112_pixel_sub_ps_64x64
    ptrue           p0.b, vl64
.rept 64
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z4.b}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5
    usublb          z16.h, z0.b, z4.b
    usublt          z17.h, z0.b, z4.b
    st2h            {z16.h, z17.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_112_pixel_sub_ps_64x64:
    ptrue           p0.h, vl64
.rept 64
    ld1b            {z0.h}, p0/z, [x2]
    ld1b            {z8.h}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5
    sub             z16.h, z0.h, z8.h
    st1h            {z16.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc

// chroma sub_ps
function PFX(pixel_sub_ps_4x8_sve2)
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

function PFX(pixel_sub_ps_8x16_sve2)
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

function PFX(pixel_sub_ps_16x32_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sub_ps_16x32
    ptrue           p0.b, vl16
.rept 32
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z4.b}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5
    usublb          z8.h, z0.b, z4.b
    usublt          z9.h, z0.b, z4.b
    st2h            {z8.h, z9.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_16_pixel_sub_ps_16x32:
    ptrue           p0.h, vl16
.rept 32
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

function PFX(pixel_sub_ps_32x64_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sub_ps_32x64
    ptrue           p0.b, vl16
.rept 64
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z2.b}, p0/z, [x3]
    ld1b            {z3.b}, p0/z, [x3, #1, mul vl]
    add             x2, x2, x4
    add             x3, x3, x5
    usublb          z16.h, z0.b, z2.b
    usublt          z17.h, z0.b, z2.b
    usublb          z18.h, z1.b, z3.b
    usublt          z19.h, z1.b, z3.b
    st2h            {z16.h, z17.h}, p0, [x0]
    st2h            {z18.h, z19.h}, p0, [x0, #2, mul vl]
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_16_pixel_sub_ps_32x64:
    cmp             x9, #48
    bgt             .vl_gt_48_pixel_sub_ps_32x64
    ptrue           p0.b, vl32
.rept 64
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z2.b}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5
    usublb          z16.h, z0.b, z2.b
    usublt          z17.h, z0.b, z2.b
    st2h            {z16.h, z17.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_48_pixel_sub_ps_32x64:
    ptrue           p0.h, vl32
.rept 64
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

// void x265_pixel_add_ps_neon(pixel* a, intptr_t dstride, const pixel* b0, const int16_t* b1, intptr_t sstride0, intptr_t sstride1);
function PFX(pixel_add_ps_4x4_sve2)
    ptrue           p0.h, vl8
    ptrue           p1.h, vl4
.rept 4
    ld1b            {z0.h}, p0/z, [x2]
    ld1h            {z2.h}, p1/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5, lsl #1
    add             z4.h, z0.h, z2.h
    sqxtunb         z4.b, z4.h
    st1b            {z4.h}, p1, [x0]
    add             x0, x0, x1
.endr
    ret
endfunc

function PFX(pixel_add_ps_8x8_sve2)
    ptrue           p0.h, vl8
.rept 8
    ld1b            {z0.h}, p0/z, [x2]
    ld1h            {z2.h}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5, lsl #1
    add             z4.h, z0.h, z2.h
    sqxtunb         z4.b, z4.h
    st1b            {z4.h}, p0, [x0]
    add             x0, x0, x1
.endr
    ret
endfunc

.macro pixel_add_ps_16xN_sve2 h
function PFX(pixel_add_ps_16x\h\()_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_add_ps_16x\h
    ptrue           p0.b, vl16
.rept \h
    ld1b            {z0.h}, p0/z, [x2]
    ld1b            {z1.h}, p0/z, [x2, #1, mul vl]
    ld1h            {z2.h}, p0/z, [x3]
    ld1h            {z3.h}, p0/z, [x3, #1, mul vl]
    add             x2, x2, x4
    add             x3, x3, x5, lsl #1
    add             z24.h, z0.h, z2.h
    add             z25.h, z1.h, z3.h
    sqxtunb         z6.b, z24.h
    sqxtunb         z7.b, z25.h
    st1b            {z6.h}, p0, [x0]
    st1b            {z7.h}, p0, [x0, #1, mul vl]
    add             x0, x0, x1
.endr
    ret
.vl_gt_16_pixel_add_ps_16x\h\():
    ptrue           p0.b, vl32
.rept \h
    ld1b            {z0.h}, p0/z, [x2]
    ld1h            {z2.h}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5, lsl #1
    add             z24.h, z0.h, z2.h
    sqxtunb         z6.b, z24.h
    st1b            {z6.h}, p0, [x0]
    add             x0, x0, x1
.endr
    ret
endfunc
.endm

pixel_add_ps_16xN_sve2 16
pixel_add_ps_16xN_sve2 32

.macro pixel_add_ps_32xN_sve2 h
 function PFX(pixel_add_ps_32x\h\()_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_add_ps_32x\h
    ptrue           p0.b, vl16
.rept \h
    ld1b            {z0.h}, p0/z, [x2]
    ld1b            {z1.h}, p0/z, [x2, #1, mul vl]
    ld1b            {z2.h}, p0/z, [x2, #2, mul vl]
    ld1b            {z3.h}, p0/z, [x2, #3, mul vl]
    ld1h            {z4.h}, p0/z, [x3]
    ld1h            {z5.h}, p0/z, [x3, #1, mul vl]
    ld1h            {z6.h}, p0/z, [x3, #2, mul vl]
    ld1h            {z7.h}, p0/z, [x3, #3, mul vl]
    add             x2, x2, x4
    add             x3, x3, x5, lsl #1
    add             z24.h, z0.h, z4.h
    add             z25.h, z1.h, z5.h
    add             z26.h, z2.h, z6.h
    add             z27.h, z3.h, z7.h
    sqxtunb         z6.b, z24.h
    sqxtunb         z7.b, z25.h
    sqxtunb         z8.b, z26.h
    sqxtunb         z9.b, z27.h
    st1b            {z6.h}, p0, [x0]
    st1b            {z7.h}, p0, [x0, #1, mul vl]
    st1b            {z8.h}, p0, [x0, #2, mul vl]
    st1b            {z9.h}, p0, [x0, #3, mul vl]
    add             x0, x0, x1
.endr
    ret
.vl_gt_16_pixel_add_ps_32x\h\():
    cmp             x9, #48
    bgt             .vl_gt_48_pixel_add_ps_32x\h
    ptrue           p0.b, vl32
.rept \h
    ld1b            {z0.h}, p0/z, [x2]
    ld1b            {z1.h}, p0/z, [x2, #1, mul vl]
    ld1h            {z4.h}, p0/z, [x3]
    ld1h            {z5.h}, p0/z, [x3, #1, mul vl]
    add             x2, x2, x4
    add             x3, x3, x5, lsl #1
    add             z24.h, z0.h, z4.h
    add             z25.h, z1.h, z5.h
    sqxtunb         z6.b, z24.h
    sqxtunb         z7.b, z25.h
    st1b            {z6.h}, p0, [x0]
    st1b            {z7.h}, p0, [x0, #1, mul vl]
    add             x0, x0, x1
.endr
    ret
.vl_gt_48_pixel_add_ps_32x\h\():
    ptrue           p0.b, vl64
.rept \h
    ld1b            {z0.h}, p0/z, [x2]
    ld1h            {z4.h}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5, lsl #1
    add             z24.h, z0.h, z4.h
    sqxtunb         z6.b, z24.h
    st1b            {z6.h}, p0, [x0]
    add             x0, x0, x1
.endr
    ret
endfunc
.endm

pixel_add_ps_32xN_sve2 32
pixel_add_ps_32xN_sve2 64

function PFX(pixel_add_ps_64x64_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_add_ps_64x64
    ptrue           p0.b, vl16
.rept 64
    ld1b            {z0.h}, p0/z, [x2]
    ld1b            {z1.h}, p0/z, [x2, #1, mul vl]
    ld1b            {z2.h}, p0/z, [x2, #2, mul vl]
    ld1b            {z3.h}, p0/z, [x2, #3, mul vl]
    ld1b            {z4.h}, p0/z, [x2, #4 ,mul vl]
    ld1b            {z5.h}, p0/z, [x2, #5, mul vl]
    ld1b            {z6.h}, p0/z, [x2, #6, mul vl]
    ld1b            {z7.h}, p0/z, [x2, #7, mul vl]
    ld1h            {z8.h}, p0/z, [x3]
    ld1h            {z9.h}, p0/z, [x3, #1, mul vl]
    ld1h            {z10.h}, p0/z, [x3, #2, mul vl]
    ld1h            {z11.h}, p0/z, [x3, #3, mul vl]
    ld1h            {z12.h}, p0/z, [x3, #4, mul vl]
    ld1h            {z13.h}, p0/z, [x3, #5, mul vl]
    ld1h            {z14.h}, p0/z, [x3, #6, mul vl]
    ld1h            {z15.h}, p0/z, [x3, #7, mul vl]
    add             x2, x2, x4
    add             x3, x3, x5, lsl #1
    add             z24.h, z0.h, z8.h
    add             z25.h, z1.h, z9.h
    add             z26.h, z2.h, z10.h
    add             z27.h, z3.h, z11.h
    add             z28.h, z4.h, z12.h
    add             z29.h, z5.h, z13.h
    add             z30.h, z6.h, z14.h
    add             z31.h, z7.h, z15.h
    sqxtunb         z6.b, z24.h
    sqxtunb         z7.b, z25.h
    sqxtunb         z8.b, z26.h
    sqxtunb         z9.b, z27.h
    sqxtunb         z10.b, z28.h
    sqxtunb         z11.b, z29.h
    sqxtunb         z12.b, z30.h
    sqxtunb         z13.b, z31.h
    st1b            {z6.h}, p0, [x0]
    st1b            {z7.h}, p0, [x0, #1, mul vl]
    st1b            {z8.h}, p0, [x0, #2, mul vl]
    st1b            {z9.h}, p0, [x0, #3, mul vl]
    st1b            {z10.h}, p0, [x0, #4, mul vl]
    st1b            {z11.h}, p0, [x0, #5, mul vl]
    st1b            {z12.h}, p0, [x0, #6, mul vl]
    st1b            {z13.h}, p0, [x0, #7, mul vl]
    add             x0, x0, x1
.endr
    ret
.vl_gt_16_pixel_add_ps_64x64:
    cmp             x9, #48
    bgt             .vl_gt_48_pixel_add_ps_64x64
    ptrue           p0.b, vl32
.rept 64
    ld1b            {z0.h}, p0/z, [x2]
    ld1b            {z1.h}, p0/z, [x2, #1, mul vl]
    ld1b            {z2.h}, p0/z, [x2, #2, mul vl]
    ld1b            {z3.h}, p0/z, [x2, #3, mul vl]
    ld1h            {z8.h}, p0/z, [x3]
    ld1h            {z9.h}, p0/z, [x3, #1, mul vl]
    ld1h            {z10.h}, p0/z, [x3, #2, mul vl]
    ld1h            {z11.h}, p0/z, [x3, #3, mul vl]
    add             x2, x2, x4
    add             x3, x3, x5, lsl #1
    add             z24.h, z0.h, z8.h
    add             z25.h, z1.h, z9.h
    add             z26.h, z2.h, z10.h
    add             z27.h, z3.h, z11.h
    sqxtunb         z6.b, z24.h
    sqxtunb         z7.b, z25.h
    sqxtunb         z8.b, z26.h
    sqxtunb         z9.b, z27.h
    st1b            {z6.h}, p0, [x0]
    st1b            {z7.h}, p0, [x0, #1, mul vl]
    st1b            {z8.h}, p0, [x0, #2, mul vl]
    st1b            {z9.h}, p0, [x0, #3, mul vl]
    add             x0, x0, x1
.endr
    ret
.vl_gt_48_pixel_add_ps_64x64:
    cmp             x9, #112
    bgt             .vl_gt_112_pixel_add_ps_64x64
    ptrue           p0.b, vl64
.rept 64
    ld1b            {z0.h}, p0/z, [x2]
    ld1b            {z1.h}, p0/z, [x2, #1, mul vl]
    ld1h            {z8.h}, p0/z, [x3]
    ld1h            {z9.h}, p0/z, [x3, #1, mul vl]
    add             x2, x2, x4
    add             x3, x3, x5, lsl #1
    add             z24.h, z0.h, z8.h
    add             z25.h, z1.h, z9.h
    sqxtunb         z6.b, z24.h
    sqxtunb         z7.b, z25.h
    st1b            {z6.h}, p0, [x0]
    st1b            {z7.h}, p0, [x0, #1, mul vl]
    add             x0, x0, x1
.endr
    ret
.vl_gt_112_pixel_add_ps_64x64:
    ptrue           p0.b, vl128
.rept 64
    ld1b            {z0.h}, p0/z, [x2]
    ld1h            {z8.h}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5, lsl #1
    add             z24.h, z0.h, z8.h
    sqxtunb         z6.b, z24.h
    st1b            {z6.h}, p0, [x0]
    add             x0, x0, x1
.endr
    ret
endfunc

// Chroma add_ps
function PFX(pixel_add_ps_4x8_sve2)
    ptrue           p0.h,vl4
.rept 8
    ld1b            {z0.h}, p0/z, [x2]
    ld1h            {z2.h}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5, lsl #1
    add             z4.h, z0.h, z2.h
    sqxtunb         z4.b, z4.h
    st1b            {z4.h}, p0, [x0]
    add             x0, x0, x1
.endr
    ret
endfunc

function PFX(pixel_add_ps_8x16_sve2)
    ptrue           p0.h,vl8
.rept 16
    ld1b            {z0.h}, p0/z, [x2]
    ld1h            {z2.h}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5, lsl #1
    add             z4.h, z0.h, z2.h
    sqxtunb         z4.b, z4.h
    st1b            {z4.h}, p0, [x0]
    add             x0, x0, x1
.endr
    ret
endfunc

// void scale1D_128to64(pixel *dst, const pixel *src)
function PFX(scale1D_128to64_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_scale1D_128to64
    ptrue           p0.b, vl16
.rept 2
    ld2b            {z0.b, z1.b}, p0/z, [x1]
    ld2b            {z2.b, z3.b}, p0/z, [x1, #2, mul vl]
    ld2b            {z4.b, z5.b}, p0/z, [x1, #4, mul vl]
    ld2b            {z6.b, z7.b}, p0/z, [x1, #6, mul vl]
    add             x1, x1, #128
    urhadd          z0.b, p0/m, z0.b, z1.b
    urhadd          z2.b, p0/m, z2.b, z3.b
    urhadd          z4.b, p0/m, z4.b, z5.b
    urhadd          z6.b, p0/m, z6.b, z7.b
    st1b            {z0.b}, p0, [x0]
    st1b            {z2.b}, p0, [x0, #1, mul vl]
    st1b            {z4.b}, p0, [x0, #2, mul vl]
    st1b            {z6.b}, p0, [x0, #3, mul vl]
    add             x0, x0, #64
.endr
    ret
.vl_gt_16_scale1D_128to64:
    cmp             x9, #48
    bgt             .vl_gt_48_scale1D_128to64
    ptrue           p0.b, vl32
.rept 2
    ld2b            {z0.b, z1.b}, p0/z, [x1]
    ld2b            {z2.b, z3.b}, p0/z, [x1, #2, mul vl]
    add             x1, x1, #128
    urhadd          z0.b, p0/m, z0.b, z1.b
    urhadd          z2.b, p0/m, z2.b, z3.b
    st1b            {z0.b}, p0, [x0]
    st1b            {z2.b}, p0, [x0, #1, mul vl]
    add             x0, x0, #64
.endr
    ret
.vl_gt_48_scale1D_128to64:
    ptrue           p0.b, vl64
.rept 2
    ld2b            {z0.b, z1.b}, p0/z, [x1]
    add             x1, x1, #128
    urhadd          z0.b, p0/m, z0.b, z1.b
    st1b            {z0.b}, p0, [x0]
    add             x0, x0, #64
.endr
    ret
endfunc

// void planecopy_cp_c(const uint8_t* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int width, int height, int shift)
function PFX(pixel_planecopy_cp_sve2)
    ptrue           p0.b, vl16
    dup             z2.b, w6
    sub             x5, x5, #1
.loop_h_sve2:
    mov             x6, x0
    mov             x12, x2
    mov             x7, #0
.loop_w_sve2:
    ldr             z0, [x6]
    lsl             z0.b, p0/m, z0.b, z2.b
    str             z0, [x12]
    add             x6, x6, #16
    add             x12, x12, #16
    add             x7, x7, #16
    cmp             x7, x4
    blt             .loop_w_sve2

    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .loop_h_sve2

// handle last row
    mov             x5, x4
    lsr             x5, x5, #3
.loopW8_sve2:
    ldr             z0, [x0]
    add             x0, x0, #8
    lsl             z0.b, p0/m, z0.b, z2.b
    str             d0, [x2], #8
    sub             x4, x4, #8
    sub             x5, x5, #1
    cbnz            x5, .loopW8_sve2

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
.macro satd_4x4_sve2
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
function PFX(pixel_satd_4x4_sve2)
    ptrue           p0.h, vl4
    satd_4x4_sve2
    fmov            x0, d0
    ret
endfunc

.macro x265_satd_4x8_8x4_end_sve2
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

.macro pixel_satd_4x8_sve2
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
    x265_satd_4x8_8x4_end_sve2
.endm

// template<int w, int h>
// int satd4(const pixel* pix1, intptr_t stride_pix1, const pixel* pix2, intptr_t stride_pix2)
function PFX(pixel_satd_4x8_sve2)
    ptrue           p0.h, vl4
    pixel_satd_4x8_sve2
    mov             w0, v0.s[0]
    ret
endfunc

function PFX(pixel_satd_4x16_sve2)
    ptrue           p0.h, vl4
    mov             w4, #0
    pixel_satd_4x8_sve2
    mov             w5, v0.s[0]
    add             w4, w4, w5
    pixel_satd_4x8_sve2
    mov             w5, v0.s[0]
    add             w0, w5, w4
    ret
endfunc

function PFX(pixel_satd_4x32_sve2)
    ptrue           p0.h, vl4
    mov             w4, #0
.rept 4
    pixel_satd_4x8_sve2
    mov             w5, v0.s[0]
    add             w4, w4, w5
.endr
    mov             w0, w4
    ret
endfunc

function PFX(pixel_satd_12x16_sve2)
    ptrue           p0.h, vl4
    mov             x4, x0
    mov             x5, x2
    mov             w7, #0
    pixel_satd_4x8_sve2
    mov             w6, v0.s[0]
    add             w7, w7, w6
    pixel_satd_4x8_sve2
    mov             w6, v0.s[0]
    add             w7, w7, w6

    add             x0, x4, #4
    add             x2, x5, #4
    pixel_satd_4x8_sve2
    mov             w6, v0.s[0]
    add             w7, w7, w6
    pixel_satd_4x8_sve2
    mov             w6, v0.s[0]
    add             w7, w7, w6

    add             x0, x4, #8
    add             x2, x5, #8
    pixel_satd_4x8_sve2
    mov             w6, v0.s[0]
    add             w7, w7, w6
    pixel_satd_4x8_sve2
    mov             w6, v0.s[0]
    add             w0, w7, w6
    ret
endfunc

function PFX(pixel_satd_12x32_sve2)
    ptrue           p0.h, vl4
    mov             x4, x0
    mov             x5, x2
    mov             w7, #0
.rept 4
    pixel_satd_4x8_sve2
    mov             w6, v0.s[0]
    add             w7, w7, w6
.endr

    add             x0, x4, #4
    add             x2, x5, #4
.rept 4
    pixel_satd_4x8_sve2
    mov             w6, v0.s[0]
    add             w7, w7, w6
.endr

    add             x0, x4, #8
    add             x2, x5, #8
.rept 4
    pixel_satd_4x8_sve2
    mov             w6, v0.s[0]
    add             w7, w7, w6
.endr

    mov             w0, w7
    ret
endfunc

function PFX(pixel_satd_8x4_sve2)
    ptrue           p0.h, vl4
    mov             x4, x0
    mov             x5, x2
    satd_4x4_sve2
    add             x0, x4, #4
    add             x2, x5, #4
    umov            x6, v0.d[0]
    satd_4x4_sve2
    umov            x0, v0.d[0]
    add             x0, x0, x6
    ret
endfunc

.macro LOAD_DIFF_8x4_sve2 z0 z1 z2 z3
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

.macro LOAD_DIFF_16x4_sve2 z0 z1 z2 z3 z4 z5 z6 z7
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

function PFX(satd_16x4_sve2), export=0
    LOAD_DIFF_16x4_sve2  z16.h, z17.h, z18.h, z19.h, z20.h, z21.h, z22.h, z23.h
    b                    PFX(satd_8x4v_8x8h_sve2)
endfunc

function PFX(satd_8x8_sve2), export=0
    LOAD_DIFF_8x4_sve2   z16.h, z17.h, z18.h, z19.h
    LOAD_DIFF_8x4_sve2   z20.h, z21.h, z22.h, z23.h
    b                    PFX(satd_8x4v_8x8h_sve2)
endfunc

// one vertical hadamard pass and two horizontal
function PFX(satd_8x4v_8x8h_sve2), export=0
    HADAMARD4_V     z16.h, z18.h, z17.h, z19.h, z0.h, z2.h, z1.h, z3.h
    HADAMARD4_V     z20.h, z21.h, z22.h, z23.h, z0.h, z1.h, z2.h, z3.h
    trn4            z0.h, z1.h, z2.h, z3.h, z16.h, z17.h, z18.h, z19.h
    trn4            z4.h, z5.h, z6.h, z7.h, z20.h, z21.h, z22.h, z23.h
    SUMSUB_ABCD     z16.h, z17.h, z18.h, z19.h, z0.h, z1.h, z2.h, z3.h
    SUMSUB_ABCD     z20.h, z21.h, z22.h, z23.h, z4.h, z5.h, z6.h, z7.h
    trn4            z0.s, z2.s, z1.s, z3.s, z16.s, z18.s, z17.s, z19.s
    trn4            z4.s, z6.s, z5.s, z7.s, z20.s, z22.s, z21.s, z23.s
    ABS8_SVE2       z0.h, z1.h, z2.h, z3.h, z4.h, z5.h, z6.h, z7.h, p0
    smax            z0.h, p0/m, z0.h, z2.h
    smax            z1.h, p0/m, z1.h, z3.h
    smax            z4.h, p0/m, z4.h, z6.h
    smax            z5.h, p0/m, z5.h, z7.h
    ret
endfunc

function PFX(pixel_satd_8x8_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_8x8_sve2)
    add             z0.h, z0.h, z1.h
    add             z1.h, z4.h, z5.h
    add             z0.h, z0.h, z1.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_8x12_sve2)
    ptrue           p0.h, vl4
    mov             x4, x0
    mov             x5, x2
    mov             x7, #0
    satd_4x4_sve2
    umov            x6, v0.d[0]
    add             x7, x7, x6
    add             x0, x4, #4
    add             x2, x5, #4
    satd_4x4_sve2
    umov            x6, v0.d[0]
    add             x7, x7, x6
.rept 2
    sub             x0, x0, #4
    sub             x2, x2, #4
    mov             x4, x0
    mov             x5, x2
    satd_4x4_sve2
    umov            x6, v0.d[0]
    add             x7, x7, x6
    add             x0, x4, #4
    add             x2, x5, #4
    satd_4x4_sve2
    umov            x6, v0.d[0]
    add             x7, x7, x6
.endr
    mov             x0, x7
    ret
endfunc

function PFX(pixel_satd_8x16_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_8x8_sve2)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
    bl              PFX(satd_8x8_sve2)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_8x32_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_8x8_sve2)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
.rept 3
    bl              PFX(satd_8x8_sve2)
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

function PFX(pixel_satd_8x64_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_8x8_sve2)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
.rept 7
    bl              PFX(satd_8x8_sve2)
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

function PFX(pixel_satd_16x4_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_16x4_sve2)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_16x8_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_16x4_sve2)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
    bl              PFX(satd_16x4_sve2)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_16x12_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_16x4_sve2)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
.rept 2
    bl              PFX(satd_16x4_sve2)
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

function PFX(pixel_satd_16x16_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_16x4_sve2)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
.rept 3
    bl              PFX(satd_16x4_sve2)
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

function PFX(pixel_satd_16x24_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_16x4_sve2)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
.rept 5
    bl              PFX(satd_16x4_sve2)
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

.macro pixel_satd_16x32_sve2
    bl              PFX(satd_16x4_sve2)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
.rept 7
    bl              PFX(satd_16x4_sve2)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
.endr
.endm

function PFX(pixel_satd_16x32_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    pixel_satd_16x32_sve2
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_16x64_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(satd_16x4_sve2)
    add             z30.h, z0.h, z1.h
    add             z31.h, z4.h, z5.h
.rept 15
    bl              PFX(satd_16x4_sve2)
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

function PFX(pixel_satd_24x32_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
    mov             x4, x0
    mov             x5, x2
.rept 3
    movi            v30.2d, #0
    movi            v31.2d, #0
.rept 4
    bl              PFX(satd_8x8_sve2)
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

function PFX(pixel_satd_24x64_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
    mov             x4, x0
    mov             x5, x2
.rept 3
    movi            v30.2d, #0
    movi            v31.2d, #0
.rept 4
    bl              PFX(satd_8x8_sve2)
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
    bl              PFX(satd_8x8_sve2)
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

.macro pixel_satd_32x8_sve2
    mov             x4, x0
    mov             x5, x2
.rept 2
    bl              PFX(satd_16x4_sve2)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
.endr
    add             x0, x4, #16
    add             x2, x5, #16
.rept 2
    bl              PFX(satd_16x4_sve2)
    add             z30.h, z30.h, z0.h
    add             z31.h, z31.h, z1.h
    add             z30.h, z30.h, z4.h
    add             z31.h, z31.h, z5.h
.endr
.endm

.macro satd_32x16_sve2
    movi            v30.2d, #0
    movi            v31.2d, #0
    pixel_satd_32x8_sve2
    sub             x0, x0, #16
    sub             x2, x2, #16
    pixel_satd_32x8_sve2
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w6, v0.s[0]
.endm

.macro satd_64x16_sve2
    mov             x8, x0
    mov             x9, x2
    satd_32x16_sve2
    add             x7, x7, x6
    add             x0, x8, #32
    add             x2, x9, #32
    satd_32x16_sve2
    add             x7, x7, x6
.endm

function PFX(pixel_satd_32x8_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
    mov             x4, x0
    mov             x5, x2
    movi            v30.2d, #0
    movi            v31.2d, #0
    pixel_satd_32x8_sve2
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    ret             x10
endfunc

function PFX(pixel_satd_32x16_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    satd_32x16_sve2
    mov             x0, x6
    ret             x10
endfunc

function PFX(pixel_satd_32x24_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    satd_32x16_sve2
    movi            v30.2d, #0
    movi            v31.2d, #0
    sub             x0, x0, #16
    sub             x2, x2, #16
    pixel_satd_32x8_sve2
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    add             x0, x0, x6
    ret             x10
endfunc

function PFX(pixel_satd_32x32_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
    satd_32x16_sve2
    sub             x0, x0, #16
    sub             x2, x2, #16
    add             x7, x7, x6
    satd_32x16_sve2
    add             x0, x7, x6
    ret             x10
endfunc

function PFX(pixel_satd_32x48_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
.rept 2
    satd_32x16_sve2
    sub             x0, x0, #16
    sub             x2, x2, #16
    add             x7, x7, x6
.endr
    satd_32x16_sve2
    add             x0, x7, x6
    ret             x10
endfunc

function PFX(pixel_satd_32x64_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
.rept 3
    satd_32x16_sve2
    sub             x0, x0, #16
    sub             x2, x2, #16
    add             x7, x7, x6
.endr
    satd_32x16_sve2
    add             x0, x7, x6
    ret             x10
endfunc

function PFX(pixel_satd_64x16_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
    satd_64x16_sve2
    mov             x0, x7
    ret             x10
endfunc

function PFX(pixel_satd_64x32_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
    satd_64x16_sve2
    sub             x0, x0, #48
    sub             x2, x2, #48
    satd_64x16_sve2
    mov             x0, x7
    ret             x10
endfunc

function PFX(pixel_satd_64x48_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
.rept 2
    satd_64x16_sve2
    sub             x0, x0, #48
    sub             x2, x2, #48
.endr
    satd_64x16_sve2
    mov             x0, x7
    ret             x10
endfunc

function PFX(pixel_satd_64x64_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
.rept 3
    satd_64x16_sve2
    sub             x0, x0, #48
    sub             x2, x2, #48
.endr
    satd_64x16_sve2
    mov             x0, x7
    ret             x10
endfunc

function PFX(pixel_satd_48x64_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             x7, #0
    mov             x8, x0
    mov             x9, x2
.rept 3
    satd_32x16_sve2
    sub             x0, x0, #16
    sub             x2, x2, #16
    add             x7, x7, x6
.endr
    satd_32x16_sve2
    add             x7, x7, x6

    add             x0, x8, #32
    add             x2, x9, #32
    pixel_satd_16x32_sve2
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w6, v0.s[0]
    add             x7, x7, x6

    movi            v30.2d, #0
    movi            v31.2d, #0
    pixel_satd_16x32_sve2
    add             z0.h, z30.h, z31.h
    uaddlv          s0, v0.8h
    mov             w6, v0.s[0]
    add             x0, x7, x6
    ret             x10
endfunc

function PFX(sa8d_8x8_sve2), export=0
    LOAD_DIFF_8x4_sve2   z16.h, z17.h, z18.h, z19.h
    LOAD_DIFF_8x4_sve2   z20.h, z21.h, z22.h, z23.h
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
    ABS8_SVE2       z16.h, z17.h, z18.h, z19.h, z20.h, z21.h, z22.h, z23.h, p0
    smax            z16.h, p0/m, z16.h, z20.h
    smax            z17.h, p0/m, z17.h, z21.h
    smax            z18.h, p0/m, z18.h, z22.h
    smax            z19.h, p0/m, z19.h, z23.h
    add             z0.h, z16.h, z17.h
    add             z1.h, z18.h, z19.h
    ret
endfunc

function PFX(pixel_sa8d_8x8_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(sa8d_8x8_sve2)
    add             z0.h, z0.h, z1.h
    uaddlv          s0, v0.8h
    mov             w0, v0.s[0]
    add             w0, w0, #1
    lsr             w0, w0, #1
    ret             x10
endfunc

function PFX(pixel_sa8d_8x16_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    bl              PFX(sa8d_8x8_sve2)
    add             z0.h, z0.h, z1.h
    uaddlv          s0, v0.8h
    mov             w5, v0.s[0]
    add             w5, w5, #1
    lsr             w5, w5, #1
    bl              PFX(sa8d_8x8_sve2)
    add             z0.h, z0.h, z1.h
    uaddlv          s0, v0.8h
    mov             w4, v0.s[0]
    add             w4, w4, #1
    lsr             w4, w4, #1
    add             w0, w4, w5
    ret             x10
endfunc

// Migrating the following macro to SVE2 will decrease
// the performance as we need extra z30 and z31 initializations
// to zero and uaddvl which has greater latancy than addv
.macro sa8d_16x16_sve2 reg
    bl              PFX(sa8d_8x8_sve2)
    uaddlp          v30.4s, v0.8h
    uaddlp          v31.4s, v1.8h
    bl              PFX(sa8d_8x8_sve2)
    uadalp          v30.4s, v0.8h
    uadalp          v31.4s, v1.8h
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    bl              PFX(sa8d_8x8_sve2)
    uadalp          v30.4s, v0.8h
    uadalp          v31.4s, v1.8h
    bl              PFX(sa8d_8x8_sve2)
    uadalp          v30.4s, v0.8h
    uadalp          v31.4s, v1.8h
    add             v0.4s, v30.4s, v31.4s
    addv            s0, v0.4s
    mov             \reg, v0.s[0]
    add             \reg, \reg, #1
    lsr             \reg, \reg, #1
.endm

function PFX(pixel_sa8d_16x16_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    sa8d_16x16_sve2 w0
    ret             x10
endfunc

function PFX(pixel_sa8d_16x32_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    sa8d_16x16_sve2 w4
    sub             x0, x0, #8
    sub             x2, x2, #8
    sa8d_16x16_sve2 w5
    add             w0, w4, w5
    ret             x10
endfunc

function PFX(pixel_sa8d_32x32_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    sa8d_16x16_sve2 w4
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16_sve2 w5
    sub             x0, x0, #24
    sub             x2, x2, #24
    sa8d_16x16_sve2 w6
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16_sve2 w7
    add             w4, w4, w5
    add             w6, w6, w7
    add             w0, w4, w6
    ret             x10
endfunc

function PFX(pixel_sa8d_32x64_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             w11, #4
    mov             w9, #0
.loop_sa8d_32_sve2:
    sub             w11, w11, #1
    sa8d_16x16_sve2 w4
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16_sve2 w5
    add             w4, w4, w5
    add             w9, w9, w4
    sub             x0, x0, #24
    sub             x2, x2, #24
    cbnz            w11, .loop_sa8d_32_sve2
    mov             w0, w9
    ret             x10
endfunc

function PFX(pixel_sa8d_64x64_sve2)
    ptrue           p0.h, vl8
    mov             x10, x30
    mov             w11, #4
    mov             w9, #0
.loop_sa8d_64_sve2:
    sub             w11, w11, #1
    sa8d_16x16_sve2 w4
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16_sve2 w5
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16_sve2 w6
    sub             x0, x0, x1, lsl #4
    sub             x2, x2, x3, lsl #4
    add             x0, x0, #8
    add             x2, x2, #8
    sa8d_16x16_sve2 w7
    add             w4, w4, w5
    add             w6, w6, w7
    add             w8, w4, w6
    add             w9, w9, w8

    sub             x0, x0, #56
    sub             x2, x2, #56
    cbnz            w11, .loop_sa8d_64_sve2
    mov             w0, w9
    ret             x10
endfunc

/***** dequant_scaling*****/
// void dequant_scaling_c(const int16_t* quantCoef, const int32_t* deQuantCoef, int16_t* coef, int num, int per, int shift)
function PFX(dequant_scaling_sve2)
    ptrue           p0.h, vl8
    add             x5, x5, #4              // shift + 4
    lsr             x3, x3, #3              // num / 8
    cmp             x5, x4
    blt             .dequant_skip_sve2

    mov             x12, #1
    sub             x6, x5, x4          // shift - per
    sub             x6, x6, #1          // shift - per - 1
    lsl             x6, x12, x6         // 1 << shift - per - 1 (add)
    mov             z0.s, w6
    sub             x7, x4, x5          // per - shift
    mov             z3.s, w7

.dequant_loop1_sve2:
    ld1h            {z19.h}, p0/z, [x0]
    ld1w            {z2.s}, p0/z, [x1]
    add             x1, x1, #16
    ld1w            {z20.s}, p0/z, [x1]
    add             x0, x0, #16
    add             x1, x1, #16

    sub             x3, x3, #1
    sunpklo         z1.s, z19.h
    sunpkhi         z19.s, z19.h

    mul             z1.s, z1.s, z2.s // quantCoef * deQuantCoef
    mul             z19.s, z19.s, z20.s
    add             z1.s, z1.s, z0.s // quantCoef * deQuantCoef + add
    add             z19.s, z19.s, z0.s

    // No equivalent instructions in SVE2 for sshl
    // as sqshl has double latency
    sshl            v1.4s, v1.4s, v3.4s
    sshl            v19.4s, v19.4s, v3.4s

    sqxtnb          z16.h, z1.s
    sqxtnb          z17.h, z19.s
    st1h            {z16.s}, p0, [x2]
    st1h            {z17.s}, p0, [x2, #1, mul vl]
    add             x2, x2, #16
    cbnz            x3, .dequant_loop1_sve2
    ret

.dequant_skip_sve2:
    sub             x6, x4, x5          // per - shift
    mov             z0.h, w6

.dequant_loop2_sve2:
    ld1h            {z19.h}, p0/z, [x0]
    ld1w            {z2.s}, p0/z, [x1]
    add             x1, x1, #16
    ld1w            {z20.s}, p0/z, [x1]
    add             x0, x0, #16
    add             x1, x1, #16


    sub             x3, x3, #1
    sunpklo         z1.s, z19.h
    sunpkhi         z19.s, z19.h

    mul             z1.s, z1.s, z2.s // quantCoef * deQuantCoef
    mul             z19.s, z19.s, z20.s

    // Keeping NEON instructions here in order to have
    // one sqshl later
    sqxtn           v16.4h, v1.4s       // x265_clip3
    sqxtn2          v16.8h, v19.4s

    sqshl           z16.h, p0/m, z16.h, z0.h // coefQ << per - shift
    st1h            {z16.h}, p0, [x2]
    add             x2, x2, #16
    cbnz            x3, .dequant_loop2_sve2
    ret
endfunc

// void dequant_normal_c(const int16_t* quantCoef, int16_t* coef, int num, int scale, int shift)
function PFX(dequant_normal_sve2)
    lsr             w2, w2, #4              // num / 16
    neg             w4, w4
    mov             z0.h, w3
    mov             z1.s, w4
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_dequant_normal_sve2
.dqn_loop1_sve2:
    ld1             {v2.8h, v3.8h}, [x0], #32
    smull           v16.4s, v2.4h, v0.4h
    smull2          v17.4s, v2.8h, v0.8h
    smull           v18.4s, v3.4h, v0.4h
    smull2          v19.4s, v3.8h, v0.8h

    srshl           v16.4s, v16.4s, v1.4s
    srshl           v17.4s, v17.4s, v1.4s
    srshl           v18.4s, v18.4s, v1.4s
    srshl           v19.4s, v19.4s, v1.4s

    sqxtn           v2.4h, v16.4s
    sqxtn2          v2.8h, v17.4s
    sqxtn           v3.4h, v18.4s
    sqxtn2          v3.8h, v19.4s

    sub             w2, w2, #1
    st1             {v2.8h, v3.8h}, [x1], #32
    cbnz            w2, .dqn_loop1_sve2
    ret
.vl_gt_16_dequant_normal_sve2:
    ptrue           p0.h, vl16
.gt_16_dqn_loop1_sve2:
    ld1h            {z2.h}, p0/z, [x0]
    add             x0, x0, #32
    smullb          z16.s, z2.h, z0.h
    smullt          z17.s, z2.h, z0.h

    srshl           z16.s, p0/m, z16.s, z1.s
    srshl           z17.s, p0/m, z17.s, z1.s

    sqxtnb          z2.h, z16.s
    sqxtnt          z2.h, z17.s
    
    sub             w2, w2, #1
    st1h            {z2.h}, p0, [x1]
    add             x1, x1, #32
    cbnz            w2, .gt_16_dqn_loop1_sve2
    ret

endfunc

/********* ssim ***********/
// void ssim_4x4x2_core(const pixel* pix1, intptr_t stride1, const pixel* pix2, intptr_t stride2, int sums[2][4])
function PFX(ssim_4x4x2_core_sve2)
    ptrue           p0.b, vl16
    movi            v30.2d, #0
    movi            v31.2d, #0

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

    mul             z16.h, z0.h, z0.h
    mul             z17.h, z1.h, z1.h
    mul             z18.h, z2.h, z2.h
    uaddlp          v30.4s, v16.8h

    mul             z19.h, z3.h, z3.h
    mul             z20.h, z4.h, z4.h
    mul             z21.h, z5.h, z5.h
    uadalp          v30.4s, v17.8h

    mul             z22.h, z6.h, z6.h
    mul             z23.h, z7.h, z7.h
    mul             z24.h, z0.h, z4.h
    uadalp          v30.4s, v18.8h

    mul             z25.h, z1.h, z5.h
    mul             z26.h, z2.h, z6.h
    mul             z27.h, z3.h, z7.h
    uadalp          v30.4s, v19.8h

    add             z28.h, z0.h, z1.h
    add             z29.h, z4.h, z5.h
    uadalp          v30.4s, v20.8h
    uaddlp          v31.4s, v24.8h

    add             z28.h, z28.h, z2.h
    add             z29.h, z29.h, z6.h
    uadalp          v30.4s, v21.8h
    uadalp          v31.4s, v25.8h

    add             z28.h, z28.h, z3.h
    add             z29.h, z29.h, z7.h
    uadalp          v30.4s, v22.8h
    uadalp          v31.4s, v26.8h

    // Better use NEON instructions here
    uaddlp          v28.4s, v28.8h
    uaddlp          v29.4s, v29.8h
    uadalp          v30.4s, v23.8h
    uadalp          v31.4s, v27.8h

    addp            v28.4s, v28.4s, v28.4s
    addp            v29.4s, v29.4s, v29.4s
    addp            v30.4s, v30.4s, v30.4s
    addp            v31.4s, v31.4s, v31.4s

    st4             {v28.2s, v29.2s, v30.2s, v31.2s}, [x4]
    ret
endfunc

// int psyCost_pp(const pixel* source, intptr_t sstride, const pixel* recon, intptr_t rstride)
function PFX(psyCost_4x4_sve2)
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

    // SVE2 uaddv has 8 latency. So, use NEON addlv
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

// uint32_t quant_c(const int16_t* coef, const int32_t* quantCoeff, int32_t* deltaU, int16_t* qCoef, int qBits, int add, int numCoeff)
// No need to fully use SVE2 instructions for this function
function PFX(quant_sve2)
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

.loop_quant_sve2:
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
    b.ne             .loop_quant_sve2

    addv            s4, v4.4s
    mov             w9, v4.s[0]
    add             w0, w10, w9
    ret
endfunc

// uint32_t nquant_c(const int16_t* coef, const int32_t* quantCoeff, int16_t* qCoef, int qBits, int add, int numCoeff)
// No need to fully use SVE2 instructions for this function
function PFX(nquant_sve2)
    neg             x12, x3
    mov             z0.s, w12             // q0= -qbits
    mov             z1.s, w4              // add

    lsr             w5, w5, #2
    movi            v4.2d, #0              // v4= accumulate numsig
    mov             x4, #0
    movi            v22.2d, #0

.loop_nquant_sve2:
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

    cbnz            w5, .loop_nquant_sve2

    uaddlv          d4, v4.4s
    fmov            x12, d4
    add             x0, x4, x12
    ret
endfunc

// void ssimDist_c(const pixel* fenc, uint32_t fStride, const pixel* recon, intptr_t rstride, uint64_t *ssBlock, int shift, uint64_t *ac_k)
.macro ssimDist_start_sve2
    mov             z0.d, #0
    mov             z1.d, #0
.endm

.macro ssimDist_1_sve2  z0 z1 z2 z3
    sub             z16.s, \z0\().s, \z2\().s
    sub             z17.s, \z1\().s, \z3\().s
    mul             z18.s, \z0\().s, \z0\().s
    mul             z19.s, \z1\().s, \z1\().s
    mul             z20.s, z16.s, z16.s
    mul             z21.s, z17.s, z17.s
    add             z0.s, z0.s, z18.s
    add             z0.s, z0.s, z19.s
    add             z1.s, z1.s, z20.s
    add             z1.s, z1.s, z21.s
.endm

.macro ssimDist_end_sve2
    uaddv           d0, p0, z0.s
    uaddv           d1, p0, z1.s
    str             d0, [x6]
    str             d1, [x4]
.endm

function PFX(ssimDist4_sve2)
    ssimDist_start
    ptrue           p0.s, vl4
.rept 4
    ld1b            {z4.s}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z5.s}, p0/z, [x2]
    add             x2, x2, x3
    sub             z2.s, z4.s, z5.s
    mul             z3.s, z4.s, z4.s
    mul             z2.s, z2.s, z2.s
    add             z0.s, z0.s, z3.s
    add             z1.s, z1.s, z2.s
.endr
    ssimDist_end
    ret
endfunc

function PFX(ssimDist8_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_ssimDist8
    ssimDist_start
    ptrue           p0.s, vl4
.rept 8
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x1
    ld1b            {z6.s}, p0/z, [x2]
    ld1b            {z7.s}, p0/z, [x2, #1, mul vl]
    add             x2, x2, x3
    ssimDist_1_sve2 z4, z5, z6, z7
.endr
    ssimDist_end
    ret
.vl_gt_16_ssimDist8:
    ssimDist_start_sve2
    ptrue           p0.s, vl8
.rept 8
    ld1b            {z4.s}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z6.s}, p0/z, [x2]
    add             x2, x2, x3
    sub             z20.s, z4.s, z6.s
    mul             z16.s, z4.s, z4.s
    mul             z18.s, z20.s, z20.s
    add             z0.s, z0.s, z16.s
    add             z1.s, z1.s, z18.s
.endr
    ssimDist_end_sve2
    ret
endfunc

function PFX(ssimDist16_sve2)
    mov             w12, #16
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_ssimDist16
    ssimDist_start
    ptrue           p0.s, vl4
.loop_ssimDist16_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #3, mul vl]
    add             x0, x0, x1
    ld1b            {z8.s}, p0/z, [x2]
    ld1b            {z9.s}, p0/z, [x2, #1, mul vl]
    ld1b            {z10.s}, p0/z, [x2, #2, mul vl]
    ld1b            {z11.s}, p0/z, [x2, #3, mul vl]
    add             x2, x2, x3
    ssimDist_1_sve2 z4, z5, z8, z9
    ssimDist_1_sve2 z6, z7, z10, z11
    cbnz            w12, .loop_ssimDist16_sve2
    ssimDist_end
    ret
.vl_gt_16_ssimDist16:
    cmp             x9, #48
    bgt             .vl_gt_48_ssimDist16
    ssimDist_start_sve2
    ptrue           p0.s, vl8
.vl_gt_16_loop_ssimDist16_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x1
    ld1b            {z8.s}, p0/z, [x2]
    ld1b            {z9.s}, p0/z, [x2, #1, mul vl]
    add             x2, x2, x3
    ssimDist_1_sve2 z4, z5, z8, z9
    cbnz            w12, .vl_gt_16_loop_ssimDist16_sve2
    ssimDist_end_sve2
    ret
.vl_gt_48_ssimDist16:
    ssimDist_start_sve2
    ptrue           p0.s, vl16
.vl_gt_48_loop_ssimDist16_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z8.s}, p0/z, [x2]
    add             x2, x2, x3
    sub             z20.s, z4.s, z8.s
    mul             z16.s, z4.s, z4.s
    mul             z18.s, z20.s, z20.s
    add             z0.s, z0.s, z16.s
    add             z1.s, z1.s, z18.s
    cbnz            w12, .vl_gt_48_loop_ssimDist16_sve2
    ssimDist_end_sve2
    ret
endfunc

function PFX(ssimDist32_sve2)
    mov             w12, #32
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_ssimDist32
    ssimDist_start
    ptrue           p0.s, vl4
.loop_ssimDist32_sve2:
    sub             w12, w12, #1
    ld1b            {z2.s}, p0/z, [x0]
    ld1b            {z3.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z4.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z5.s}, p0/z, [x0, #3, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #4, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #5, mul vl]
    ld1b            {z8.s}, p0/z, [x0, #6, mul vl]
    ld1b            {z9.s}, p0/z, [x0, #7, mul vl]
    add             x0, x0, x1
    ld1b            {z10.s}, p0/z, [x2]
    ld1b            {z11.s}, p0/z, [x2, #1, mul vl]
    ld1b            {z12.s}, p0/z, [x2, #2, mul vl]
    ld1b            {z13.s}, p0/z, [x2, #3, mul vl]
    ld1b            {z14.s}, p0/z, [x2, #4, mul vl]
    ld1b            {z15.s}, p0/z, [x2, #5, mul vl]
    ld1b            {z30.s}, p0/z, [x2, #6, mul vl]
    ld1b            {z31.s}, p0/z, [x2, #7, mul vl]
    add             x2, x2, x3
    ssimDist_1_sve2 z2, z3, z10, z11
    ssimDist_1_sve2 z4, z5, z12, z13
    ssimDist_1_sve2 z6, z7, z14, z15
    ssimDist_1_sve2 z8, z9, z30, z31
    cbnz            w12, .loop_ssimDist32_sve2
    ssimDist_end
    ret
.vl_gt_16_ssimDist32:
    cmp             x9, #48
    bgt             .vl_gt_48_ssimDist32
    ssimDist_start_sve2
    ptrue           p0.s, vl8
.vl_gt_16_loop_ssimDist32_sve2:
    sub             w12, w12, #1
    ld1b            {z2.s}, p0/z, [x0]
    ld1b            {z3.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z4.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z5.s}, p0/z, [x0, #3, mul vl]
    add             x0, x0, x1
    ld1b            {z10.s}, p0/z, [x2]
    ld1b            {z11.s}, p0/z, [x2, #1, mul vl]
    ld1b            {z12.s}, p0/z, [x2, #2, mul vl]
    ld1b            {z13.s}, p0/z, [x2, #3, mul vl]
    add             x2, x2, x3
    ssimDist_1_sve2 z2, z3, z10, z11
    ssimDist_1_sve2 z4, z5, z12, z13
    cbnz            w12, .vl_gt_16_loop_ssimDist32_sve2
    ssimDist_end_sve2
    ret
.vl_gt_48_ssimDist32:
    cmp             x9, #112
    bgt             .vl_gt_112_ssimDist32
    ssimDist_start_sve2
    ptrue           p0.s, vl16
.vl_gt_48_loop_ssimDist32_sve2:
    sub             w12, w12, #1
    ld1b            {z2.s}, p0/z, [x0]
    ld1b            {z3.s}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x1
    ld1b            {z10.s}, p0/z, [x2]
    ld1b            {z11.s}, p0/z, [x2, #1, mul vl]
    add             x2, x2, x3
    ssimDist_1_sve2 z2, z3, z10, z11
    cbnz            w12, .vl_gt_48_loop_ssimDist32_sve2
    ssimDist_end_sve2
    ret
.vl_gt_112_ssimDist32:
    ssimDist_start_sve2
    ptrue           p0.s, vl32
.vl_gt_112_loop_ssimDist32_sve2:
    sub             w12, w12, #1
    ld1b            {z2.s}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z10.s}, p0/z, [x2]
    add             x2, x2, x3
    sub             z20.s, z2.s, z10.s
    mul             z16.s, z2.s, z2.s
    mul             z18.s, z20.s, z20.s
    add             z0.s, z0.s, z16.s
    add             z1.s, z1.s, z18.s
    cbnz            w12, .vl_gt_112_loop_ssimDist32_sve2
    ssimDist_end_sve2
    ret
endfunc

function PFX(ssimDist64_sve2)
    mov             w12, #64
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_ssimDist64
    ssimDist_start
    ptrue           p0.s, vl4
.loop_ssimDist64_sve2:
    sub             w12, w12, #1
    ld1b            {z2.s}, p0/z, [x0]
    ld1b            {z3.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z4.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z5.s}, p0/z, [x0, #3, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #4, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #5, mul vl]
    ld1b            {z8.s}, p0/z, [x0, #6, mul vl]
    ld1b            {z9.s}, p0/z, [x0, #7, mul vl]
    ld1b            {z23.s}, p0/z, [x2]
    ld1b            {z24.s}, p0/z, [x2, #1, mul vl]
    ld1b            {z25.s}, p0/z, [x2, #2, mul vl]
    ld1b            {z26.s}, p0/z, [x2, #3, mul vl]
    ld1b            {z27.s}, p0/z, [x2, #4, mul vl]
    ld1b            {z28.s}, p0/z, [x2, #5, mul vl]
    ld1b            {z29.s}, p0/z, [x2, #6, mul vl]
    ld1b            {z30.s}, p0/z, [x2, #7, mul vl]
    ssimDist_1_sve2 z2, z3, z23, z24
    ssimDist_1_sve2 z4, z5, z25, z26
    ssimDist_1_sve2 z6, z7, z27, z28
    ssimDist_1_sve2 z8, z9, z29, z30
    mov             x4, x0
    mov             x5, x2
    add             x4, x4, #32
    add             x5, x5, #32
    ld1b            {z2.s}, p0/z, [x4]
    ld1b            {z3.s}, p0/z, [x4, #1, mul vl]
    ld1b            {z4.s}, p0/z, [x4, #2, mul vl]
    ld1b            {z5.s}, p0/z, [x4, #3, mul vl]
    ld1b            {z6.s}, p0/z, [x4, #4, mul vl]
    ld1b            {z7.s}, p0/z, [x4, #5, mul vl]
    ld1b            {z8.s}, p0/z, [x4, #6, mul vl]
    ld1b            {z9.s}, p0/z, [x4, #7, mul vl]
    ld1b            {z23.s}, p0/z, [x5]
    ld1b            {z24.s}, p0/z, [x5, #1, mul vl]
    ld1b            {z25.s}, p0/z, [x5, #2, mul vl]
    ld1b            {z26.s}, p0/z, [x5, #3, mul vl]
    ld1b            {z27.s}, p0/z, [x5, #4, mul vl]
    ld1b            {z28.s}, p0/z, [x5, #5, mul vl]
    ld1b            {z29.s}, p0/z, [x5, #6, mul vl]
    ld1b            {z30.s}, p0/z, [x5, #7, mul vl]
    ssimDist_1_sve2 z2, z3, z23, z24
    ssimDist_1_sve2 z4, z5, z25, z26
    ssimDist_1_sve2 z6, z7, z27, z28
    ssimDist_1_sve2 z8, z9, z29, z30
    add             x0, x0, x1
    add             x2, x2, x3
    cbnz            w12, .loop_ssimDist64_sve2
    ssimDist_end
    ret
.vl_gt_16_ssimDist64:
    cmp             x9, #48
    bgt             .vl_gt_48_ssimDist64
    ssimDist_start_sve2
    ptrue           p0.s, vl8
.vl_gt_16_loop_ssimDist64_sve2:
    sub             w12, w12, #1
    ld1b            {z2.s}, p0/z, [x0]
    ld1b            {z3.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z4.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z5.s}, p0/z, [x0, #3, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #4, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #5, mul vl]
    ld1b            {z8.s}, p0/z, [x0, #6, mul vl]
    ld1b            {z9.s}, p0/z, [x0, #7, mul vl]
    ld1b            {z23.s}, p0/z, [x2]
    ld1b            {z24.s}, p0/z, [x2, #1, mul vl]
    ld1b            {z25.s}, p0/z, [x2, #2, mul vl]
    ld1b            {z26.s}, p0/z, [x2, #3, mul vl]
    ld1b            {z27.s}, p0/z, [x2, #4, mul vl]
    ld1b            {z28.s}, p0/z, [x2, #5, mul vl]
    ld1b            {z29.s}, p0/z, [x2, #6, mul vl]
    ld1b            {z30.s}, p0/z, [x2, #7, mul vl]
    ssimDist_1_sve2 z2, z3, z23, z24
    ssimDist_1_sve2 z4, z5, z25, z26
    ssimDist_1_sve2 z6, z7, z27, z28
    ssimDist_1_sve2 z8, z9, z29, z30
    add             x0, x0, x1
    add             x2, x2, x3
    cbnz            w12, .vl_gt_16_loop_ssimDist64_sve2
    ssimDist_end_sve2
    ret
.vl_gt_48_ssimDist64:
    cmp             x9, #112
    bgt             .vl_gt_112_ssimDist64
    ssimDist_start_sve2
    ptrue           p0.s, vl16
.vl_gt_48_loop_ssimDist64_sve2:
    sub             w12, w12, #1
    ld1b            {z2.s}, p0/z, [x0]
    ld1b            {z3.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z4.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z5.s}, p0/z, [x0, #3, mul vl]
    ld1b            {z23.s}, p0/z, [x2]
    ld1b            {z24.s}, p0/z, [x2, #1, mul vl]
    ld1b            {z25.s}, p0/z, [x2, #2, mul vl]
    ld1b            {z26.s}, p0/z, [x2, #3, mul vl]
    ssimDist_1_sve2 z2, z3, z23, z24
    ssimDist_1_sve2 z4, z5, z25, z26
    add             x0, x0, x1
    add             x2, x2, x3
    cbnz            w12, .vl_gt_48_loop_ssimDist64_sve2
    ssimDist_end_sve2
    ret
.vl_gt_112_ssimDist64:
    ssimDist_start_sve2
    ptrue           p0.s, vl32
.vl_gt_112_loop_ssimDist64_sve2:
    sub             w12, w12, #1
    ld1b            {z2.s}, p0/z, [x0]
    ld1b            {z3.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z23.s}, p0/z, [x2]
    ld1b            {z24.s}, p0/z, [x2, #1, mul vl]
    ssimDist_1_sve2 z2, z3, z23, z24
    add             x0, x0, x1
    add             x2, x2, x3
    cbnz            w12, .vl_gt_112_loop_ssimDist64_sve2
    ssimDist_end_sve2
    ret
endfunc

// void normFact_c(const pixel* src, uint32_t blockSize, int shift, uint64_t *z_k)
.macro normFact_start_sve2
    mov             z0.d, #0
.endm

.macro normFact_1_sve2  z0, z1
    mul             z16.s, \z0\().s, \z0\().s
    mul             z17.s, \z1\().s, \z1\().s
    add             z0.s, z0.s, z16.s
    add             z0.s, z0.s, z17.s
.endm

.macro normFact_end_sve2
    uaddv           d0, p0, z0.s
    str             d0, [x3]
.endm

function PFX(normFact8_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_normFact8
    normFact_start
    ptrue           p0.s, vl4
.rept 8
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x1
    normFact_1_sve2 z4, z5
.endr
    normFact_end
    ret
.vl_gt_16_normFact8:
    normFact_start_sve2
    ptrue           p0.s, vl8
.rept 8
    ld1b            {z4.s}, p0/z, [x0]
    add             x0, x0, x1
    mul             z16.s, z4.s, z4.s
    add             z0.s, z0.s, z16.s
.endr
    normFact_end_sve2
    ret
endfunc

function PFX(normFact16_sve2)
    mov             w12, #16
    cmp             x9, #16
    bgt             .vl_gt_16_normFact16
    normFact_start
    ptrue           p0.s, vl4
.loop_normFact16_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #3, mul vl]
    add             x0, x0, x1
    normFact_1_sve2 z4, z5
    normFact_1_sve2 z6, z7
    cbnz            w12, .loop_normFact16_sve2
    normFact_end
    ret
.vl_gt_16_normFact16:
    cmp             x9, #48
    bgt             .vl_gt_48_normFact16
    normFact_start_sve2
    ptrue           p0.s, vl8
.vl_gt_16_loop_normFact16_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x1
    normFact_1_sve2 z4, z5
    cbnz            w12, .vl_gt_16_loop_normFact16_sve2
    normFact_end_sve2
    ret
.vl_gt_48_normFact16:
    normFact_start_sve2
    ptrue           p0.s, vl16
.vl_gt_48_loop_normFact16_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    add             x0, x0, x1
    mul             z16.s, z4.s, z4.s
    add             z0.s, z0.s, z16.s
    cbnz            w12, .vl_gt_48_loop_normFact16_sve2
    normFact_end_sve2
    ret
endfunc

function PFX(normFact32_sve2)
    mov             w12, #32
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_normFact32
    normFact_start
    ptrue           p0.s, vl4
.loop_normFact32_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #3, mul vl]
    ld1b            {z8.s}, p0/z, [x0, #4, mul vl]
    ld1b            {z9.s}, p0/z, [x0, #5, mul vl]
    ld1b            {z10.s}, p0/z, [x0, #6, mul vl]
    ld1b            {z11.s}, p0/z, [x0, #7, mul vl]
    add             x0, x0, x1
    normFact_1_sve2 z4, z5
    normFact_1_sve2 z6, z7
    normFact_1_sve2 z8, z9
    normFact_1_sve2 z10, z11
    cbnz            w12, .loop_normFact32_sve2
    normFact_end
    ret
.vl_gt_16_normFact32:
    cmp             x9, #48
    bgt             .vl_gt_48_normFact32
    normFact_start_sve2
    ptrue           p0.s, vl8
.vl_gt_16_loop_normFact32_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #3, mul vl]
    add             x0, x0, x1
    normFact_1_sve2 z4, z5
    normFact_1_sve2 z6, z7
    cbnz            w12, .vl_gt_16_loop_normFact32_sve2
    normFact_end_sve2
    ret
.vl_gt_48_normFact32:
    cmp             x9, #112
    bgt             .vl_gt_112_normFact32
    normFact_start_sve2
    ptrue           p0.s, vl16
.vl_gt_48_loop_normFact32_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x1
    normFact_1_sve2 z4, z5
    cbnz            w12, .vl_gt_48_loop_normFact32_sve2
    normFact_end_sve2
    ret
.vl_gt_112_normFact32:
    normFact_start_sve2
    ptrue           p0.s, vl32
.vl_gt_112_loop_normFact32_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    add             x0, x0, x1
    mul             z16.s, z4.s, z4.s
    add             z0.s, z0.s, z16.s
    cbnz            w12, .vl_gt_112_loop_normFact32_sve2
    normFact_end_sve2
    ret
endfunc

function PFX(normFact64_sve2)
    mov             w12, #64
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_normFact64
    normFact_start
    ptrue           p0.s, vl4
.loop_normFact64_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #3, mul vl]
    ld1b            {z8.s}, p0/z, [x0, #4, mul vl]
    ld1b            {z9.s}, p0/z, [x0, #5, mul vl]
    ld1b            {z10.s}, p0/z, [x0, #6, mul vl]
    ld1b            {z11.s}, p0/z, [x0, #7, mul vl]
    normFact_1_sve2 z4, z5
    normFact_1_sve2 z6, z7
    normFact_1_sve2 z8, z9
    normFact_1_sve2 z10, z11
    mov             x2, x0
    add             x2, x2, #32
    ld1b            {z4.s}, p0/z, [x2]
    ld1b            {z5.s}, p0/z, [x2, #1, mul vl]
    ld1b            {z6.s}, p0/z, [x2, #2, mul vl]
    ld1b            {z7.s}, p0/z, [x2, #3, mul vl]
    ld1b            {z8.s}, p0/z, [x2, #4, mul vl]
    ld1b            {z9.s}, p0/z, [x2, #5, mul vl]
    ld1b            {z10.s}, p0/z, [x2, #6, mul vl]
    ld1b            {z11.s}, p0/z, [x2, #7, mul vl]
    normFact_1_sve2 z4, z5
    normFact_1_sve2 z6, z7
    normFact_1_sve2 z8, z9
    normFact_1_sve2 z10, z11
    add             x0, x0, x1
    cbnz            w12, .loop_normFact64_sve2
    normFact_end
    ret
.vl_gt_16_normFact64:
    cmp             x9, #48
    bgt             .vl_gt_48_normFact64
    normFact_start_sve2
    ptrue           p0.s, vl8
.vl_gt_16_loop_normFact64_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #3, mul vl]
    ld1b            {z8.s}, p0/z, [x0, #4, mul vl]
    ld1b            {z9.s}, p0/z, [x0, #5, mul vl]
    ld1b            {z10.s}, p0/z, [x0, #6, mul vl]
    ld1b            {z11.s}, p0/z, [x0, #7, mul vl]
    normFact_1_sve2 z4, z5
    normFact_1_sve2 z6, z7
    normFact_1_sve2 z8, z9
    normFact_1_sve2 z10, z11
    add             x0, x0, x1
    cbnz            w12, .vl_gt_16_loop_normFact64_sve2
    normFact_end_sve2
    ret
.vl_gt_48_normFact64:
    cmp             x9, #112
    bgt             .vl_gt_112_normFact64
    normFact_start_sve2
    ptrue           p0.s, vl16
.vl_gt_48_loop_normFact64_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #3, mul vl]
    normFact_1_sve2 z4, z5
    normFact_1_sve2 z6, z7
    add             x0, x0, x1
    cbnz            w12, .vl_gt_48_loop_normFact64_sve2
    normFact_end_sve2
    ret
.vl_gt_112_normFact64:
    normFact_start_sve2
    ptrue           p0.s, vl32
.vl_gt_112_loop_normFact64_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    normFact_1_sve2 z4, z5
    add             x0, x0, x1
    cbnz            w12, .vl_gt_112_loop_normFact64_sve2
    normFact_end_sve2
    ret
endfunc

// void weight_pp_c(const pixel* src, pixel* dst, intptr_t stride, int width, int height, int w0, int round, int shift, int offset)
function PFX(weight_pp_sve2)
    sub             x2, x2, x3
    ldr             w9, [sp]              // offset
    lsl             w5, w5, #6            // w0 << correction

    // count trailing zeros in w5 and compare against shift right amount.
    rbit            w10, w5
    clz             w10, w10
    cmp             w10, w7
    b.lt            .unfoldedShift_sve2

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
    cbnz            w11, .widenTo32Bit_sve2

    // 16-bit arithmetic is enough.
// umull has better performance than umull{b,t}.
// So, better use NEON instructions here
.loopHpp_sve2:
    mov             x12, x3
.loopWpp_sve2:
    ldr             q0, [x0], #16
    sub             x12, x12, #16
    umull           v1.8h, v0.8b, v25.8b  // val *= w0 << correction >> shift
    umull2          v2.8h, v0.16b, v25.16b
    add             v1.8h, v1.8h, v26.8h  // val += round >> shift + offset
    add             v2.8h, v2.8h, v26.8h
    sqxtun          v0.8b, v1.8h          // val = x265_clip(val)
    sqxtun2         v0.16b, v2.8h
    str             q0, [x1], #16
    cbnz            x12, .loopWpp_sve2
    add             x1, x1, x2
    add             x0, x0, x2
    sub             x4, x4, #1
    cbnz            x4, .loopHpp_sve2
    ret

    // 32-bit arithmetic is needed.
// umull has better performance than umull{b,t}.
// So, better use NEON instructions here
.widenTo32Bit_sve2:
.loopHpp32_sve2:
    mov             x12, x3
.loopWpp32_sve2:
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
    cbnz            x12, .loopWpp32_sve2
    add             x1, x1, x2
    add             x0, x0, x2
    sub             x4, x4, #1
    cbnz            x4, .loopHpp32_sve2
    ret

    // The shift right cannot be moved out of the loop.
.unfoldedShift_sve2:
    mov             z25.h, w5            // w0 << correction
    mov             z26.s, w6            // round
    neg             w7, w7                // -shift
    mov             z27.s, w7
    mov             z29.s, w9            // offset
.loopHppUS_sve2:
    mov             x12, x3
// umull has better performance than umull{b,t}.
// So, better use NEON instructions here
.loopWppUS_sve2:
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
    cbnz            x12, .loopWppUS_sve2
    add             x1, x1, x2
    add             x0, x0, x2
    sub             x4, x4, #1
    cbnz            x4, .loopHppUS_sve2
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
function PFX(costCoeffNxN_sve2)
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
    cbz             x2, .idx_zero_sve2
.loop_ccnn_sve2:
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
    cbnz            x2, .loop_ccnn_sve2
.idx_zero_sve2:

    add             x13, x3, x4, lsl #1
    add             x4, x4, x15
    str             h2, [x13]              // absCoeff[numNonZero] = tmpCoeff[blkPos]

    ldr             x9, [sp, #8]           // subPosBase
    uxth            w9, w9
    cmp             w9, #0
    cset            x2, eq
    add             x4, x4, x2
    cbz             x4, .exit_ccnn_sve2

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
.exit_ccnn_sve2:
    ubfx            w0, w0, #0, #24
    ret
endfunc

const g_SPL_and_mask, align=8
.byte 0x1, 0x2, 0x4, 0x8, 0x10, 0x20, 0x40, 0x80, 0x1, 0x2, 0x4, 0x8, 0x10, 0x20, 0x40, 0x80
endconst
