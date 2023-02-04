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

/* ################## NEON #################### */

/* void blockcopy_sp(pixel* a, intptr_t stridea, const int16_t* b, intptr_t strideb)
 *
 * r0   - a
 * r1   - stridea
 * r2   - b
 * r3   - strideb */
function PFX(blockcopy_sp_4x4_neon)
    lsl             x3, x3, #1
.rept 2
    ld1             {v0.8h}, [x2], x3
    ld1             {v1.8h}, [x2], x3
    xtn             v0.8b, v0.8h
    xtn             v1.8b, v1.8h
    st1             {v0.s}[0], [x0], x1
    st1             {v1.s}[0], [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_sp_8x8_neon)
    lsl             x3, x3, #1
.rept 4
    ld1             {v0.8h}, [x2], x3
    ld1             {v1.8h}, [x2], x3
    xtn             v0.8b, v0.8h
    xtn             v1.8b, v1.8h
    st1             {v0.d}[0], [x0], x1
    st1             {v1.d}[0], [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_sp_16x16_neon)
    lsl             x3, x3, #1
    movrel          x11, xtn_xtn2_table
    ld1             {v31.16b}, [x11]
.rept 8
    ld1             {v0.8h-v1.8h}, [x2], x3
    ld1             {v2.8h-v3.8h}, [x2], x3
    tbl             v0.16b, {v0.16b,v1.16b}, v31.16b
    tbl             v1.16b, {v2.16b,v3.16b}, v31.16b
    st1             {v0.16b}, [x0], x1
    st1             {v1.16b}, [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_sp_32x32_neon)
    mov             w12, #4
    lsl             x3, x3, #1
    movrel          x11, xtn_xtn2_table
    ld1             {v31.16b}, [x11]
.loop_csp32:
    sub             w12, w12, #1
.rept 4
    ld1             {v0.8h-v3.8h}, [x2], x3
    ld1             {v4.8h-v7.8h}, [x2], x3
    tbl             v0.16b, {v0.16b,v1.16b}, v31.16b
    tbl             v1.16b, {v2.16b,v3.16b}, v31.16b
    tbl             v2.16b, {v4.16b,v5.16b}, v31.16b
    tbl             v3.16b, {v6.16b,v7.16b}, v31.16b
    st1             {v0.16b-v1.16b}, [x0], x1
    st1             {v2.16b-v3.16b}, [x0], x1
.endr
    cbnz            w12, .loop_csp32
    ret
endfunc

function PFX(blockcopy_sp_64x64_neon)
    mov             w12, #16
    lsl             x3, x3, #1
    sub             x3, x3, #64
    movrel          x11, xtn_xtn2_table
    ld1             {v31.16b}, [x11]
.loop_csp64:
    sub             w12, w12, #1
.rept 4
    ld1             {v0.8h-v3.8h}, [x2], #64
    ld1             {v4.8h-v7.8h}, [x2], x3
    tbl             v0.16b, {v0.16b,v1.16b}, v31.16b
    tbl             v1.16b, {v2.16b,v3.16b}, v31.16b
    tbl             v2.16b, {v4.16b,v5.16b}, v31.16b
    tbl             v3.16b, {v6.16b,v7.16b}, v31.16b
    st1             {v0.16b-v3.16b}, [x0], x1
.endr
    cbnz            w12, .loop_csp64
    ret
endfunc

// void blockcopy_ps(int16_t* a, intptr_t stridea, const pixel* b, intptr_t strideb)
function PFX(blockcopy_ps_4x4_neon)
    lsl             x1, x1, #1
.rept 2
    ld1             {v0.8b}, [x2], x3
    ld1             {v1.8b}, [x2], x3
    uxtl            v0.8h, v0.8b
    uxtl            v1.8h, v1.8b
    st1             {v0.4h}, [x0], x1
    st1             {v1.4h}, [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_ps_8x8_neon)
    lsl             x1, x1, #1
.rept 4
    ld1             {v0.8b}, [x2], x3
    ld1             {v1.8b}, [x2], x3
    uxtl            v0.8h, v0.8b
    uxtl            v1.8h, v1.8b
    st1             {v0.8h}, [x0], x1
    st1             {v1.8h}, [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_ps_16x16_neon)
    lsl             x1, x1, #1
.rept 8
    ld1             {v4.16b}, [x2], x3
    ld1             {v5.16b}, [x2], x3
    uxtl            v0.8h, v4.8b
    uxtl2           v1.8h, v4.16b
    uxtl            v2.8h, v5.8b
    uxtl2           v3.8h, v5.16b
    st1             {v0.8h-v1.8h}, [x0], x1
    st1             {v2.8h-v3.8h}, [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_ps_32x32_neon)
    lsl             x1, x1, #1
    mov             w12, #4
.loop_cps32:
    sub             w12, w12, #1
.rept 4
    ld1             {v16.16b-v17.16b}, [x2], x3
    ld1             {v18.16b-v19.16b}, [x2], x3
    uxtl            v0.8h, v16.8b
    uxtl2           v1.8h, v16.16b
    uxtl            v2.8h, v17.8b
    uxtl2           v3.8h, v17.16b
    uxtl            v4.8h, v18.8b
    uxtl2           v5.8h, v18.16b
    uxtl            v6.8h, v19.8b
    uxtl2           v7.8h, v19.16b
    st1             {v0.8h-v3.8h}, [x0], x1
    st1             {v4.8h-v7.8h}, [x0], x1
.endr
    cbnz            w12, .loop_cps32
    ret
endfunc

function PFX(blockcopy_ps_64x64_neon)
    lsl             x1, x1, #1
    sub             x1, x1, #64
    mov             w12, #16
.loop_cps64:
    sub             w12, w12, #1
.rept 4
    ld1             {v16.16b-v19.16b}, [x2], x3
    uxtl            v0.8h, v16.8b
    uxtl2           v1.8h, v16.16b
    uxtl            v2.8h, v17.8b
    uxtl2           v3.8h, v17.16b
    uxtl            v4.8h, v18.8b
    uxtl2           v5.8h, v18.16b
    uxtl            v6.8h, v19.8b
    uxtl2           v7.8h, v19.16b
    st1             {v0.8h-v3.8h}, [x0], #64
    st1             {v4.8h-v7.8h}, [x0], x1
.endr
    cbnz            w12, .loop_cps64
    ret
endfunc

// void x265_blockcopy_ss(int16_t* a, intptr_t stridea, const int16_t* b, intptr_t strideb)
function PFX(blockcopy_ss_4x4_neon)
    lsl             x1, x1, #1
    lsl             x3, x3, #1
.rept 2
    ld1             {v0.8b}, [x2], x3
    ld1             {v1.8b}, [x2], x3
    st1             {v0.8b}, [x0], x1
    st1             {v1.8b}, [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_ss_8x8_neon)
    lsl             x1, x1, #1
    lsl             x3, x3, #1
.rept 4
    ld1             {v0.8h}, [x2], x3
    ld1             {v1.8h}, [x2], x3
    st1             {v0.8h}, [x0], x1
    st1             {v1.8h}, [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_ss_16x16_neon)
    lsl             x1, x1, #1
    lsl             x3, x3, #1
.rept 8
    ld1             {v0.8h-v1.8h}, [x2], x3
    ld1             {v2.8h-v3.8h}, [x2], x3
    st1             {v0.8h-v1.8h}, [x0], x1
    st1             {v2.8h-v3.8h}, [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_ss_32x32_neon)
    lsl             x1, x1, #1
    lsl             x3, x3, #1
    mov             w12, #4
.loop_css32:
    sub             w12, w12, #1
.rept 8
    ld1             {v0.8h-v3.8h}, [x2], x3
    st1             {v0.8h-v3.8h}, [x0], x1
.endr
    cbnz            w12, .loop_css32
    ret
endfunc

function PFX(blockcopy_ss_64x64_neon)
    lsl             x1, x1, #1
    sub             x1, x1, #64
    lsl             x3, x3, #1
    sub             x3, x3, #64
    mov             w12, #8
.loop_css64:
    sub             w12, w12, #1
.rept 8
    ld1             {v0.8h-v3.8h}, [x2], #64
    ld1             {v4.8h-v7.8h}, [x2], x3
    st1             {v0.8h-v3.8h}, [x0], #64
    st1             {v4.8h-v7.8h}, [x0], x1
.endr
    cbnz            w12, .loop_css64
    ret
endfunc

/******** Chroma blockcopy********/
function PFX(blockcopy_ss_4x8_neon)
    lsl             x1, x1, #1
    lsl             x3, x3, #1
.rept 4
    ld1             {v0.8b}, [x2], x3
    ld1             {v1.8b}, [x2], x3
    st1             {v0.8b}, [x0], x1
    st1             {v1.8b}, [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_ss_8x16_neon)
    lsl             x1, x1, #1
    lsl             x3, x3, #1
.rept 8
    ld1             {v0.8h}, [x2], x3
    ld1             {v1.8h}, [x2], x3
    st1             {v0.8h}, [x0], x1
    st1             {v1.8h}, [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_ss_16x32_neon)
    lsl             x1, x1, #1
    lsl             x3, x3, #1
.rept 16
    ld1             {v0.8h-v1.8h}, [x2], x3
    ld1             {v2.8h-v3.8h}, [x2], x3
    st1             {v0.8h-v1.8h}, [x0], x1
    st1             {v2.8h-v3.8h}, [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_ss_32x64_neon)
    lsl             x1, x1, #1
    lsl             x3, x3, #1
    mov             w12, #8
.loop_css32x64:
    sub             w12, w12, #1
.rept 8
    ld1             {v0.8h-v3.8h}, [x2], x3
    st1             {v0.8h-v3.8h}, [x0], x1
.endr
    cbnz            w12, .loop_css32x64
    ret
endfunc

// chroma blockcopy_ps
function PFX(blockcopy_ps_4x8_neon)
    lsl             x1, x1, #1
.rept 4
    ld1             {v0.8b}, [x2], x3
    ld1             {v1.8b}, [x2], x3
    uxtl            v0.8h, v0.8b
    uxtl            v1.8h, v1.8b
    st1             {v0.4h}, [x0], x1
    st1             {v1.4h}, [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_ps_8x16_neon)
    lsl             x1, x1, #1
.rept 8
    ld1             {v0.8b}, [x2], x3
    ld1             {v1.8b}, [x2], x3
    uxtl            v0.8h, v0.8b
    uxtl            v1.8h, v1.8b
    st1             {v0.8h}, [x0], x1
    st1             {v1.8h}, [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_ps_16x32_neon)
    lsl             x1, x1, #1
.rept 16
    ld1             {v4.16b}, [x2], x3
    ld1             {v5.16b}, [x2], x3
    uxtl            v0.8h, v4.8b
    uxtl2           v1.8h, v4.16b
    uxtl            v2.8h, v5.8b
    uxtl2           v3.8h, v5.16b
    st1             {v0.8h-v1.8h}, [x0], x1
    st1             {v2.8h-v3.8h}, [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_ps_32x64_neon)
    lsl             x1, x1, #1
    mov             w12, #8
.loop_cps32x64:
    sub             w12, w12, #1
.rept 4
    ld1             {v16.16b-v17.16b}, [x2], x3
    ld1             {v18.16b-v19.16b}, [x2], x3
    uxtl            v0.8h, v16.8b
    uxtl2           v1.8h, v16.16b
    uxtl            v2.8h, v17.8b
    uxtl2           v3.8h, v17.16b
    uxtl            v4.8h, v18.8b
    uxtl2           v5.8h, v18.16b
    uxtl            v6.8h, v19.8b
    uxtl2           v7.8h, v19.16b
    st1             {v0.8h-v3.8h}, [x0], x1
    st1             {v4.8h-v7.8h}, [x0], x1
.endr
    cbnz            w12, .loop_cps32x64
    ret
endfunc

// chroma blockcopy_sp
function PFX(blockcopy_sp_4x8_neon)
    lsl             x3, x3, #1
.rept 4
    ld1             {v0.8h}, [x2], x3
    ld1             {v1.8h}, [x2], x3
    xtn             v0.8b, v0.8h
    xtn             v1.8b, v1.8h
    st1             {v0.s}[0], [x0], x1
    st1             {v1.s}[0], [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_sp_8x16_neon)
    lsl             x3, x3, #1
.rept 8
    ld1             {v0.8h}, [x2], x3
    ld1             {v1.8h}, [x2], x3
    xtn             v0.8b, v0.8h
    xtn             v1.8b, v1.8h
    st1             {v0.d}[0], [x0], x1
    st1             {v1.d}[0], [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_sp_16x32_neon)
    lsl             x3, x3, #1
    movrel          x11, xtn_xtn2_table
    ld1             {v31.16b}, [x11]
.rept 16
    ld1             {v0.8h-v1.8h}, [x2], x3
    ld1             {v2.8h-v3.8h}, [x2], x3
    tbl             v0.16b, {v0.16b,v1.16b}, v31.16b
    tbl             v1.16b, {v2.16b,v3.16b}, v31.16b
    st1             {v0.16b}, [x0], x1
    st1             {v1.16b}, [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_sp_32x64_neon)
    mov             w12, #8
    lsl             x3, x3, #1
    movrel          x11, xtn_xtn2_table
    ld1             {v31.16b}, [x11]
.loop_csp32x64:
    sub             w12, w12, #1
.rept 4
    ld1             {v0.8h-v3.8h}, [x2], x3
    ld1             {v4.8h-v7.8h}, [x2], x3
    tbl             v0.16b, {v0.16b,v1.16b}, v31.16b
    tbl             v1.16b, {v2.16b,v3.16b}, v31.16b
    tbl             v2.16b, {v4.16b,v5.16b}, v31.16b
    tbl             v3.16b, {v6.16b,v7.16b}, v31.16b
    st1             {v0.16b-v1.16b}, [x0], x1
    st1             {v2.16b-v3.16b}, [x0], x1
.endr
    cbnz            w12, .loop_csp32x64
    ret
endfunc

/* blockcopy_pp(pixel* dst, intptr_t dstStride, const pixel* src, intptr_t srcStride) */

function PFX(blockcopy_pp_2x4_neon)
    ldrh            w9, [x2]
    add             x4, x1, x1
    add             x14, x3, x3
    strh            w9, [x0]
    ldrh            w10, [x2, x3]
    add             x5, x4, x1
    add             x15, x14, x3
    strh            w10, [x0, x1]
    ldrh            w11, [x2, x14]
    strh            w11, [x0, x4]
    ldrh            w12, [x2, x15]
    strh            w12, [x0, x5]
    ret
endfunc

.macro blockcopy_pp_2xN_neon h
function PFX(blockcopy_pp_2x\h\()_neon)
    add             x4, x1, x1
    add             x5, x4, x1
    add             x6, x5, x1

    add             x14, x3, x3
    add             x15, x14, x3
    add             x16, x15, x3

.rept \h / 4
    ldrh            w9, [x2]
    strh            w9, [x0]
    ldrh            w10, [x2, x3]
    strh            w10, [x0, x1]
    ldrh            w11, [x2, x14]
    strh            w11, [x0, x4]
    ldrh            w12, [x2, x15]
    strh            w12, [x0, x5]
    add             x2, x2, x16
    add             x0, x0, x6
.endr
    ret
endfunc
.endm

blockcopy_pp_2xN_neon 8
blockcopy_pp_2xN_neon 16

function PFX(blockcopy_pp_4x2_neon)
    ldr             w9, [x2]
    str             w9, [x0]
    ldr             w10, [x2, x3]
    str             w10, [x0, x1]
    ret
endfunc

function PFX(blockcopy_pp_4x4_neon)
    ldr             w9, [x2]
    add             x4, x1, x1
    add             x14, x3, x3
    str             w9, [x0]
    ldr             w10, [x2, x3]
    add             x5, x4, x1
    add             x15, x14, x3
    str             w10, [x0, x1]
    ldr             w11, [x2, x14]
    str             w11, [x0, x4]
    ldr             w12, [x2, x15]
    str             w12, [x0, x5]
    ret
endfunc

.macro blockcopy_pp_4xN_neon h
function PFX(blockcopy_pp_4x\h\()_neon)
    add             x4, x1, x1
    add             x5, x4, x1
    add             x6, x5, x1

    add             x14, x3, x3
    add             x15, x14, x3
    add             x16, x15, x3

.rept \h / 4
    ldr             w9, [x2]
    str             w9, [x0]
    ldr             w10, [x2, x3]
    str             w10, [x0, x1]
    ldr             w11, [x2, x14]
    str             w11, [x0, x4]
    ldr             w12, [x2, x15]
    str             w12, [x0, x5]
    add             x2, x2, x16
    add             x0, x0, x6
.endr
    ret
endfunc
.endm

blockcopy_pp_4xN_neon 8
blockcopy_pp_4xN_neon 16
blockcopy_pp_4xN_neon 32

.macro blockcopy_pp_6xN_neon h
function PFX(blockcopy_pp_6x\h\()_neon)
    sub             x1, x1, #4
.rept \h
    ld1             {v0.8b}, [x2], x3
    st1             {v0.s}[0], [x0], #4
    st1             {v0.h}[2], [x0], x1
.endr
    ret
endfunc
.endm

blockcopy_pp_6xN_neon 8
blockcopy_pp_6xN_neon 16

.macro blockcopy_pp_8xN_neon h
function PFX(blockcopy_pp_8x\h\()_neon)
.rept \h
    ld1             {v0.4h}, [x2], x3
    st1             {v0.4h}, [x0], x1
.endr
    ret
endfunc
.endm

blockcopy_pp_8xN_neon 2
blockcopy_pp_8xN_neon 4
blockcopy_pp_8xN_neon 6
blockcopy_pp_8xN_neon 8
blockcopy_pp_8xN_neon 12
blockcopy_pp_8xN_neon 16
blockcopy_pp_8xN_neon 32

function PFX(blockcopy_pp_8x64_neon)
    mov             w12, #4
.loop_pp_8x64:
    sub             w12, w12, #1
.rept 16
    ld1             {v0.4h}, [x2], x3
    st1             {v0.4h}, [x0], x1
.endr
    cbnz            w12, .loop_pp_8x64
    ret
endfunc

.macro blockcopy_pp_16xN_neon h
function PFX(blockcopy_pp_16x\h\()_neon)
.rept \h
    ld1             {v0.8h}, [x2], x3
    st1             {v0.8h}, [x0], x1
.endr
    ret
endfunc
.endm

blockcopy_pp_16xN_neon 4
blockcopy_pp_16xN_neon 8
blockcopy_pp_16xN_neon 12
blockcopy_pp_16xN_neon 16

.macro blockcopy_pp_16xN1_neon h
function PFX(blockcopy_pp_16x\h\()_neon)
    mov             w12, #\h / 8
.loop_16x\h\():
.rept 8
    ld1             {v0.8h}, [x2], x3
    st1             {v0.8h}, [x0], x1
.endr
    sub             w12, w12, #1
    cbnz            w12, .loop_16x\h
    ret
endfunc
.endm

blockcopy_pp_16xN1_neon 24
blockcopy_pp_16xN1_neon 32
blockcopy_pp_16xN1_neon 64

function PFX(blockcopy_pp_12x16_neon)
    sub             x1, x1, #8
.rept 16
    ld1             {v0.16b}, [x2], x3
    str             d0, [x0], #8
    st1             {v0.s}[2], [x0], x1
.endr
    ret
endfunc

function PFX(blockcopy_pp_12x32_neon)
    sub             x1, x1, #8
    mov             w12, #4
.loop_pp_12x32:
    sub             w12, w12, #1
.rept 8
    ld1             {v0.16b}, [x2], x3
    str             d0, [x0], #8
    st1             {v0.s}[2], [x0], x1
.endr
    cbnz            w12, .loop_pp_12x32
    ret
endfunc

function PFX(blockcopy_pp_24x32_neon)
    mov             w12, #4
.loop_24x32:
    sub             w12, w12, #1
.rept 8
    ld1             {v0.8b-v2.8b}, [x2], x3
    st1             {v0.8b-v2.8b}, [x0], x1
.endr
    cbnz            w12, .loop_24x32
    ret
endfunc

function PFX(blockcopy_pp_24x64_neon)
    mov             w12, #4
.loop_24x64:
    sub             w12, w12, #1
.rept 16
    ld1             {v0.8b-v2.8b}, [x2], x3
    st1             {v0.8b-v2.8b}, [x0], x1
.endr
    cbnz            w12, .loop_24x64
    ret
endfunc

function PFX(blockcopy_pp_32x8_neon)
.rept 8
    ld1             {v0.16b-v1.16b}, [x2], x3
    st1             {v0.16b-v1.16b}, [x0], x1
.endr
    ret
endfunc

.macro blockcopy_pp_32xN_neon h
function PFX(blockcopy_pp_32x\h\()_neon)
    mov             w12, #\h / 8
.loop_32x\h\():
    sub             w12, w12, #1
.rept 8
    ld1             {v0.16b-v1.16b}, [x2], x3
    st1             {v0.16b-v1.16b}, [x0], x1
.endr
    cbnz            w12, .loop_32x\h
    ret
endfunc
.endm

blockcopy_pp_32xN_neon 16
blockcopy_pp_32xN_neon 24
blockcopy_pp_32xN_neon 32
blockcopy_pp_32xN_neon 64
blockcopy_pp_32xN_neon 48

function PFX(blockcopy_pp_48x64_neon)
    mov             w12, #8
.loop_48x64:
    sub             w12, w12, #1
.rept 8
    ld1             {v0.16b-v2.16b}, [x2], x3
    st1             {v0.16b-v2.16b}, [x0], x1
.endr
    cbnz            w12, .loop_48x64
    ret
endfunc

.macro blockcopy_pp_64xN_neon h
function PFX(blockcopy_pp_64x\h\()_neon)
    mov             w12, #\h / 4
.loop_64x\h\():
    sub             w12, w12, #1
.rept 4
    ld1             {v0.16b-v3.16b}, [x2], x3
    st1             {v0.16b-v3.16b}, [x0], x1
.endr
    cbnz            w12, .loop_64x\h
    ret
endfunc
.endm

blockcopy_pp_64xN_neon 16
blockcopy_pp_64xN_neon 32
blockcopy_pp_64xN_neon 48
blockcopy_pp_64xN_neon 64

// void x265_blockfill_s_neon(int16_t* dst, intptr_t dstride, int16_t val)
function PFX(blockfill_s_4x4_neon)
    dup             v0.4h, w2
    lsl             x1, x1, #1
.rept 4
    st1             {v0.4h}, [x0], x1
.endr
    ret
endfunc

function PFX(blockfill_s_8x8_neon)
    dup             v0.8h, w2
    lsl             x1, x1, #1
.rept 8
    st1             {v0.8h}, [x0], x1
.endr
    ret
endfunc

function PFX(blockfill_s_16x16_neon)
    dup             v0.8h, w2
    mov             v1.16b, v0.16b
    lsl             x1, x1, #1
.rept 16
    stp             q0, q1, [x0]
    add             x0, x0, x1
.endr
    ret
endfunc

function PFX(blockfill_s_32x32_neon)
    dup             v0.8h, w2
    mov             v1.16b, v0.16b
    mov             v2.16b, v0.16b
    mov             v3.16b, v0.16b
    lsl             x1, x1, #1
.rept 32
    st1             {v0.8h-v3.8h}, [x0], x1
.endr
    ret
endfunc

function PFX(blockfill_s_64x64_neon)
    dup             v0.8h, w2
    mov             v1.16b, v0.16b
    mov             v2.16b, v0.16b
    mov             v3.16b, v0.16b
    lsl             x1, x1, #1
    sub             x1, x1, #64
.rept 64
    st1             {v0.8h-v3.8h}, [x0], #64
    st1             {v0.8h-v3.8h}, [x0], x1
.endr
    ret
endfunc

// uint32_t copy_count(int16_t* coeff, const int16_t* residual, intptr_t resiStride)
function PFX(copy_cnt_4_neon)
    lsl             x2, x2, #1
    movi            v4.8b, #0
.rept 2
    ld1             {v0.8b}, [x1], x2
    ld1             {v1.8b}, [x1], x2
    stp             d0, d1, [x0], #16
    cmeq            v0.4h, v0.4h, #0
    cmeq            v1.4h, v1.4h, #0
    add             v4.4h, v4.4h, v0.4h
    add             v4.4h, v4.4h, v1.4h
.endr
    saddlv          s4, v4.4h
    fmov            w12, s4
    add             w0, w12, #16
    ret
endfunc

function PFX(copy_cnt_8_neon)
    lsl             x2, x2, #1
    movi            v4.8b, #0
.rept 4
    ld1             {v0.16b}, [x1], x2
    ld1             {v1.16b}, [x1], x2
    stp             q0, q1, [x0], #32
    cmeq            v0.8h, v0.8h, #0
    cmeq            v1.8h, v1.8h, #0
    add             v4.8h, v4.8h, v0.8h
    add             v4.8h, v4.8h, v1.8h
.endr
    saddlv          s4, v4.8h
    fmov            w12, s4
    add             w0, w12, #64
    ret
endfunc

function PFX(copy_cnt_16_neon)
    lsl             x2, x2, #1
    movi            v4.8b, #0
.rept 16
    ld1             {v0.16b-v1.16b}, [x1], x2
    st1             {v0.16b-v1.16b}, [x0], #32
    cmeq            v0.8h, v0.8h, #0
    cmeq            v1.8h, v1.8h, #0
    add             v4.8h, v4.8h, v0.8h
    add             v4.8h, v4.8h, v1.8h
.endr
    saddlv          s4, v4.8h
    fmov            w12, s4
    add             w0, w12, #256
    ret
endfunc

function PFX(copy_cnt_32_neon)
    lsl             x2, x2, #1
    movi            v4.8b, #0
.rept 32
    ld1             {v0.16b-v3.16b}, [x1], x2
    st1             {v0.16b-v3.16b}, [x0], #64
    cmeq            v0.8h, v0.8h, #0
    cmeq            v1.8h, v1.8h, #0
    cmeq            v2.8h, v2.8h, #0
    cmeq            v3.8h, v3.8h, #0
    add             v0.8h, v0.8h, v1.8h
    add             v2.8h, v2.8h, v3.8h
    add             v4.8h, v4.8h, v0.8h
    add             v4.8h, v4.8h, v2.8h
.endr
    saddlv          s4, v4.8h
    fmov            w12, s4
    add             w0, w12, #1024
    ret
endfunc

// int  count_nonzero_c(const int16_t* quantCoeff)
function PFX(count_nonzero_4_neon)
    movi            v16.16b, #1
    movi            v17.16b, #0
    trn1            v16.16b, v16.16b, v17.16b
    ldp             q0, q1, [x0]
    cmhi            v0.8h, v0.8h, v17.8h
    cmhi            v1.8h, v1.8h, v17.8h
    and             v0.16b, v0.16b, v16.16b
    and             v1.16b, v1.16b, v16.16b
    add             v0.8h, v0.8h, v1.8h
    uaddlv          s0, v0.8h
    fmov            w0, s0
    ret
endfunc

.macro COUNT_NONZERO_8
    ld1             {v0.16b-v3.16b}, [x0], #64
    ld1             {v4.16b-v7.16b}, [x0], #64
    cmhi            v0.8h, v0.8h, v17.8h
    cmhi            v1.8h, v1.8h, v17.8h
    cmhi            v2.8h, v2.8h, v17.8h
    cmhi            v3.8h, v3.8h, v17.8h
    cmhi            v4.8h, v4.8h, v17.8h
    cmhi            v5.8h, v5.8h, v17.8h
    cmhi            v6.8h, v6.8h, v17.8h
    cmhi            v7.8h, v7.8h, v17.8h
    and             v0.16b, v0.16b, v16.16b
    and             v1.16b, v1.16b, v16.16b
    and             v2.16b, v2.16b, v16.16b
    and             v3.16b, v3.16b, v16.16b
    and             v4.16b, v4.16b, v16.16b
    and             v5.16b, v5.16b, v16.16b
    and             v6.16b, v6.16b, v16.16b
    and             v7.16b, v7.16b, v16.16b
    add             v0.8h, v0.8h, v1.8h
    add             v2.8h, v2.8h, v3.8h
    add             v4.8h, v4.8h, v5.8h
    add             v6.8h, v6.8h, v7.8h
    add             v0.8h, v0.8h, v2.8h
    add             v4.8h, v4.8h, v6.8h
    add             v0.8h, v0.8h, v4.8h
.endm

function PFX(count_nonzero_8_neon)
    movi            v16.16b, #1
    movi            v17.16b, #0
    trn1            v16.16b, v16.16b, v17.16b
    COUNT_NONZERO_8
    uaddlv          s0, v0.8h
    fmov            w0, s0
    ret
endfunc

function PFX(count_nonzero_16_neon)
    movi            v16.16b, #1
    movi            v17.16b, #0
    trn1            v16.16b, v16.16b, v17.16b
    movi            v18.16b, #0
.rept 4
    COUNT_NONZERO_8
    add             v18.16b, v18.16b, v0.16b
.endr
    uaddlv          s0, v18.8h
    fmov            w0, s0
    ret
endfunc

function PFX(count_nonzero_32_neon)
    movi            v16.16b, #1
    movi            v17.16b, #0
    trn1            v16.16b, v16.16b, v17.16b
    movi            v18.16b, #0
    mov             w12, #16
.loop_count_nonzero_32:
    sub             w12, w12, #1
    COUNT_NONZERO_8
    add             v18.16b, v18.16b, v0.16b
    cbnz            w12, .loop_count_nonzero_32

    uaddlv          s0, v18.8h
    fmov            w0, s0
    ret
endfunc

// void cpy2Dto1D_shl(int16_t* dst, const int16_t* src, intptr_t srcStride, int shift)
.macro cpy2Dto1D_shl_start
    add             x2, x2, x2
    dup             v0.8h, w3
.endm

function PFX(cpy2Dto1D_shl_4x4_neon)
    cpy2Dto1D_shl_start
    ld1             {v2.d}[0], [x1], x2
    ld1             {v2.d}[1], [x1], x2
    ld1             {v3.d}[0], [x1], x2
    ld1             {v3.d}[1], [x1], x2
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    st1             {v2.16b-v3.16b}, [x0]
    ret
endfunc

function PFX(cpy2Dto1D_shl_8x8_neon)
    cpy2Dto1D_shl_start
.rept 4
    ld1             {v2.16b}, [x1], x2
    ld1             {v3.16b}, [x1], x2
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    st1             {v2.16b-v3.16b}, [x0], #32
.endr
    ret
endfunc

function PFX(cpy2Dto1D_shl_16x16_neon)
    cpy2Dto1D_shl_start
    mov             w12, #4
.loop_cpy2Dto1D_shl_16:
    sub             w12, w12, #1
.rept 4
    ld1             {v2.16b-v3.16b}, [x1], x2
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    st1             {v2.16b-v3.16b}, [x0], #32
.endr
    cbnz            w12, .loop_cpy2Dto1D_shl_16
    ret
endfunc

function PFX(cpy2Dto1D_shl_32x32_neon)
    cpy2Dto1D_shl_start
    mov             w12, #16
.loop_cpy2Dto1D_shl_32:
    sub             w12, w12, #1
.rept 2
    ld1             {v2.16b-v5.16b}, [x1], x2
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    sshl            v4.8h, v4.8h, v0.8h
    sshl            v5.8h, v5.8h, v0.8h
    st1             {v2.16b-v5.16b}, [x0], #64
.endr
    cbnz            w12, .loop_cpy2Dto1D_shl_32
    ret
endfunc

function PFX(cpy2Dto1D_shl_64x64_neon)
    cpy2Dto1D_shl_start
    mov             w12, #32
    sub             x2, x2, #64
.loop_cpy2Dto1D_shl_64:
    sub             w12, w12, #1
.rept 2
    ld1             {v2.16b-v5.16b}, [x1], #64
    ld1             {v16.16b-v19.16b}, [x1], x2
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    sshl            v4.8h, v4.8h, v0.8h
    sshl            v5.8h, v5.8h, v0.8h
    sshl            v16.8h, v16.8h, v0.8h
    sshl            v17.8h, v17.8h, v0.8h
    sshl            v18.8h, v18.8h, v0.8h
    sshl            v19.8h, v19.8h, v0.8h
    st1             {v2.16b-v5.16b}, [x0], #64
    st1             {v16.16b-v19.16b}, [x0], #64
.endr
    cbnz            w12, .loop_cpy2Dto1D_shl_64
    ret
endfunc

// void cpy2Dto1D_shr(int16_t* dst, const int16_t* src, intptr_t srcStride, int shift)
.macro cpy2Dto1D_shr_start
    add             x2, x2, x2
    dup             v0.8h, w3
    cmeq            v1.8h, v1.8h, v1.8h
    sshl            v1.8h, v1.8h, v0.8h
    sri             v1.8h, v1.8h, #1
    neg             v0.8h, v0.8h
.endm

function PFX(cpy2Dto1D_shr_4x4_neon)
    cpy2Dto1D_shr_start
    ld1             {v2.d}[0], [x1], x2
    ld1             {v2.d}[1], [x1], x2
    ld1             {v3.d}[0], [x1], x2
    ld1             {v3.d}[1], [x1], x2
    sub             v2.8h, v2.8h, v1.8h
    sub             v3.8h, v3.8h, v1.8h
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    stp             q2, q3, [x0]
    ret
endfunc

function PFX(cpy2Dto1D_shr_8x8_neon)
    cpy2Dto1D_shr_start
.rept 4
    ld1             {v2.16b}, [x1], x2
    ld1             {v3.16b}, [x1], x2
    sub             v2.8h, v2.8h, v1.8h
    sub             v3.8h, v3.8h, v1.8h
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    stp             q2, q3, [x0], #32
.endr
    ret
endfunc

function PFX(cpy2Dto1D_shr_16x16_neon)
    cpy2Dto1D_shr_start
    mov             w12, #4
.loop_cpy2Dto1D_shr_16:
    sub             w12, w12, #1
.rept 4
    ld1             {v2.8h-v3.8h}, [x1], x2
    sub             v2.8h, v2.8h, v1.8h
    sub             v3.8h, v3.8h, v1.8h
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    st1             {v2.8h-v3.8h}, [x0], #32
.endr
    cbnz            w12, .loop_cpy2Dto1D_shr_16
    ret
endfunc

function PFX(cpy2Dto1D_shr_32x32_neon)
    cpy2Dto1D_shr_start
    mov             w12, #16
.loop_cpy2Dto1D_shr_32:
    sub             w12, w12, #1
.rept 2
    ld1             {v2.8h-v5.8h}, [x1], x2
    sub             v2.8h, v2.8h, v1.8h
    sub             v3.8h, v3.8h, v1.8h
    sub             v4.8h, v4.8h, v1.8h
    sub             v5.8h, v5.8h, v1.8h
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    sshl            v4.8h, v4.8h, v0.8h
    sshl            v5.8h, v5.8h, v0.8h
    st1             {v2.8h-v5.8h}, [x0], #64
.endr
    cbnz            w12, .loop_cpy2Dto1D_shr_32
    ret
endfunc

// void cpy1Dto2D_shl(int16_t* dst, const int16_t* src, intptr_t dstStride, int shift)
.macro cpy1Dto2D_shl_start
    add             x2, x2, x2
    dup             v0.8h, w3
.endm

function PFX(cpy1Dto2D_shl_4x4_neon)
    cpy1Dto2D_shl_start
    ld1             {v2.16b-v3.16b}, [x1]
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    st1             {v2.d}[0], [x0], x2
    st1             {v2.d}[1], [x0], x2
    st1             {v3.d}[0], [x0], x2
    st1             {v3.d}[1], [x0], x2
    ret
endfunc

function PFX(cpy1Dto2D_shl_8x8_neon)
    cpy1Dto2D_shl_start
.rept 4
    ld1             {v2.16b-v3.16b}, [x1], #32
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    st1             {v2.16b}, [x0], x2
    st1             {v3.16b}, [x0], x2
.endr
    ret
endfunc

function PFX(cpy1Dto2D_shl_16x16_neon)
    cpy1Dto2D_shl_start
    mov             w12, #4
.loop_cpy1Dto2D_shl_16:
    sub             w12, w12, #1
.rept 4
    ld1             {v2.16b-v3.16b}, [x1], #32
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    st1             {v2.16b-v3.16b}, [x0], x2
.endr
    cbnz            w12, .loop_cpy1Dto2D_shl_16
    ret
endfunc

function PFX(cpy1Dto2D_shl_32x32_neon)
    cpy1Dto2D_shl_start
    mov             w12, #16
.loop_cpy1Dto2D_shl_32:
    sub             w12, w12, #1
.rept 2
    ld1             {v2.16b-v5.16b}, [x1], #64
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    sshl            v4.8h, v4.8h, v0.8h
    sshl            v5.8h, v5.8h, v0.8h
    st1             {v2.16b-v5.16b}, [x0], x2
.endr
    cbnz            w12, .loop_cpy1Dto2D_shl_32
    ret
endfunc

function PFX(cpy1Dto2D_shl_64x64_neon)
    cpy1Dto2D_shl_start
    mov             w12, #32
    sub             x2, x2, #64
.loop_cpy1Dto2D_shl_64:
    sub             w12, w12, #1
.rept 2
    ld1             {v2.16b-v5.16b}, [x1], #64
    ld1             {v16.16b-v19.16b}, [x1], #64
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    sshl            v4.8h, v4.8h, v0.8h
    sshl            v5.8h, v5.8h, v0.8h
    sshl            v16.8h, v16.8h, v0.8h
    sshl            v17.8h, v17.8h, v0.8h
    sshl            v18.8h, v18.8h, v0.8h
    sshl            v19.8h, v19.8h, v0.8h
    st1             {v2.16b-v5.16b}, [x0], #64
    st1             {v16.16b-v19.16b}, [x0], x2
.endr
    cbnz            w12, .loop_cpy1Dto2D_shl_64
    ret
endfunc

// void cpy1Dto2D_shr(int16_t* dst, const int16_t* src, intptr_t dstStride, int shift)
.macro cpy1Dto2D_shr_start
    add             x2, x2, x2
    dup             v0.8h, w3
    cmeq            v1.8h, v1.8h, v1.8h
    sshl            v1.8h, v1.8h, v0.8h
    sri             v1.8h, v1.8h, #1
    neg             v0.8h, v0.8h
.endm

function PFX(cpy1Dto2D_shr_4x4_neon)
    cpy1Dto2D_shr_start
    ld1             {v2.16b-v3.16b}, [x1]
    sub             v2.8h, v2.8h, v1.8h
    sub             v3.8h, v3.8h, v1.8h
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    st1             {v2.d}[0], [x0], x2
    st1             {v2.d}[1], [x0], x2
    st1             {v3.d}[0], [x0], x2
    st1             {v3.d}[1], [x0], x2
    ret
endfunc

function PFX(cpy1Dto2D_shr_8x8_neon)
    cpy1Dto2D_shr_start
.rept 4
    ld1             {v2.16b-v3.16b}, [x1], #32
    sub             v2.8h, v2.8h, v1.8h
    sub             v3.8h, v3.8h, v1.8h
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    st1             {v2.16b}, [x0], x2
    st1             {v3.16b}, [x0], x2
.endr
    ret
endfunc

function PFX(cpy1Dto2D_shr_16x16_neon)
    cpy1Dto2D_shr_start
    mov             w12, #4
.loop_cpy1Dto2D_shr_16:
    sub             w12, w12, #1
.rept 4
    ld1             {v2.8h-v3.8h}, [x1], #32
    sub             v2.8h, v2.8h, v1.8h
    sub             v3.8h, v3.8h, v1.8h
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    st1             {v2.8h-v3.8h}, [x0], x2
.endr
    cbnz            w12, .loop_cpy1Dto2D_shr_16
    ret
endfunc

function PFX(cpy1Dto2D_shr_32x32_neon)
    cpy1Dto2D_shr_start
    mov             w12, #16
.loop_cpy1Dto2D_shr_32:
    sub             w12, w12, #1
.rept 2
    ld1             {v2.16b-v5.16b}, [x1], #64
    sub             v2.8h, v2.8h, v1.8h
    sub             v3.8h, v3.8h, v1.8h
    sub             v4.8h, v4.8h, v1.8h
    sub             v5.8h, v5.8h, v1.8h
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    sshl            v4.8h, v4.8h, v0.8h
    sshl            v5.8h, v5.8h, v0.8h
    st1             {v2.16b-v5.16b}, [x0], x2
.endr
    cbnz            w12, .loop_cpy1Dto2D_shr_32
    ret
endfunc

function PFX(cpy1Dto2D_shr_64x64_neon)
    cpy1Dto2D_shr_start
    mov             w12, #32
    sub             x2, x2, #64
.loop_cpy1Dto2D_shr_64:
    sub             w12, w12, #1
.rept 2
    ld1             {v2.16b-v5.16b}, [x1], #64
    ld1             {v16.16b-v19.16b}, [x1], #64
    sub             v2.8h, v2.8h, v1.8h
    sub             v3.8h, v3.8h, v1.8h
    sub             v4.8h, v4.8h, v1.8h
    sub             v5.8h, v5.8h, v1.8h
    sub             v16.8h, v16.8h, v1.8h
    sub             v17.8h, v17.8h, v1.8h
    sub             v18.8h, v18.8h, v1.8h
    sub             v19.8h, v19.8h, v1.8h
    sshl            v2.8h, v2.8h, v0.8h
    sshl            v3.8h, v3.8h, v0.8h
    sshl            v4.8h, v4.8h, v0.8h
    sshl            v5.8h, v5.8h, v0.8h
    sshl            v16.8h, v16.8h, v0.8h
    sshl            v17.8h, v17.8h, v0.8h
    sshl            v18.8h, v18.8h, v0.8h
    sshl            v19.8h, v19.8h, v0.8h
    st1             {v2.16b-v5.16b}, [x0], #64
    st1             {v16.16b-v19.16b}, [x0], x2
.endr
    cbnz            w12, .loop_cpy1Dto2D_shr_64
    ret
endfunc

/* ###################### SVE2 ####################### */

/* void blockcopy_sp(pixel* a, intptr_t stridea, const int16_t* b, intptr_t strideb)
 *
 * r0   - a
 * r1   - stridea
 * r2   - b
 * r3   - strideb */
function PFX(blockcopy_sp_4x4_sve2)
    ptrue           p0.h, vl4
.rept 4
    ld1h            {z0.h}, p0/z, [x2]
    st1b            {z0.h}, p0, [x0]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1
.endr
    ret
endfunc

function PFX(blockcopy_sp_8x8_sve2)
    ptrue           p0.h, vl8
.rept 8
    ld1h            {z0.h}, p0/z, [x2]
    st1b            {z0.h}, p0, [x0]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1
.endr
    ret
endfunc

function PFX(blockcopy_sp_16x16_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_blockcopy_sp_16_16
    ptrue           p0.h, vl8
.rept 16
    ld1h            {z0.h}, p0/z, [x2]
    ld1h            {z1.h}, p0/z, [x2, #1, mul vl]
    st1b            {z0.h}, p0, [x0]
    st1b            {z1.h}, p0, [x0, #1, mul vl]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1
.endr
    ret
.vl_gt_16_blockcopy_sp_16_16:
    ptrue           p0.h, vl16
.rept 16
    ld1h            {z0.h}, p0/z, [x2]
    st1b            {z0.h}, p0, [x0]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1
.endr
    ret
endfunc

function PFX(blockcopy_sp_32x32_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_blockcopy_sp_32_32
    ptrue           p0.h, vl8
.rept 32
    ld1h            {z0.h}, p0/z, [x2]
    ld1h            {z1.h}, p0/z, [x2, #1, mul vl]
    ld1h            {z2.h}, p0/z, [x2, #2, mul vl]
    ld1h            {z3.h}, p0/z, [x2, #3, mul vl]
    st1b            {z0.h}, p0, [x0]
    st1b            {z1.h}, p0, [x0, #1, mul vl]
    st1b            {z2.h}, p0, [x0, #2, mul vl]
    st1b            {z3.h}, p0, [x0, #3, mul vl]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1
.endr
    ret
.vl_gt_16_blockcopy_sp_32_32:
    cmp             x9, #32
    bgt             .vl_gt_32_blockcopy_sp_32_32
    ptrue           p0.h, vl16
.rept 32
    ld1h            {z0.h}, p0/z, [x2]
    ld1h            {z1.h}, p0/z, [x2, #1, mul vl]
    st1b            {z0.h}, p0, [x0]
    st1b            {z1.h}, p0, [x0, #1, mul vl]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1
.endr
    ret
.vl_gt_32_blockcopy_sp_32_32:
    cmp             x9, #48
    bgt             .vl_gt_48_blockcopy_sp_32_32
    ptrue           p0.h, mul4
    ptrue           p1.h, vl8
.rept 32
    ld1h            {z0.h}, p0/z, [x2]
    ld1h            {z1.h}, p1/z, [x2, #1, mul vl]
    st1b            {z0.h}, p0, [x0]
    st1b            {z1.h}, p1, [x0, #1, mul vl]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1
.endr
    ret
.vl_gt_48_blockcopy_sp_32_32:
    ptrue           p0.h, vl32
.rept 32
    ld1h            {z0.h}, p0/z, [x2]
    st1b            {z0.h}, p0, [x0]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1
.endr
    ret
endfunc

function PFX(blockcopy_sp_64x64_sve2)
    mov             x8, #64
    mov             w12, #64
.L_init_blockcopy_sp_64x64:
    sub             w12, w12, 1
    mov             x9, #0
    whilelt         p0.h, x9, x8
.L_blockcopy_sp_64x64:
    ld1h            {z0.h}, p0/z, [x2, x9, lsl #1]
    st1b            {z0.h}, p0, [x0, x9]
    inch            x9
    whilelt         p0.h, x9, x8
    b.first         .L_blockcopy_sp_64x64
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1
    cbnz            w12, .L_init_blockcopy_sp_64x64
    ret
endfunc

// void blockcopy_ps(int16_t* a, intptr_t stridea, const pixel* b, intptr_t strideb)
function PFX(blockcopy_ps_4x4_sve2)
    ptrue           p0.h, vl4
.rept 4
    ld1b            {z0.h}, p0/z, [x2]
    st1h            {z0.h}, p1, [x0]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3
.endr
    ret
endfunc

function PFX(blockcopy_ps_8x8_sve2)
    ptrue p0.h, vl8
.rept 8
    ld1b {z0.h}, p0/z, [x2]
    st1h {z0.h}, p0, [x0]
    add x0, x0, x1, lsl #1
    add x2, x2, x3
.endr
  ret
endfunc

function PFX(blockcopy_ps_16x16_sve2)
    ptrue           p0.b, vl16
.rept 16
    ld1b            {z0.b}, p0/z, [x2]
    uunpklo         z1.h, z0.b
    uunpkhi         z2.h, z0.b
    st1h            {z1.h}, p0, [x0]
    st1h            {z2.h}, p0, [x0, #1, mul vl]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3
.endr
    ret
endfunc

function PFX(blockcopy_ps_32x32_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_blockcopy_ps_32_32
    ptrue           p0.b, vl16
.rept 32
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, #1, mul vl]
    uunpklo         z2.h, z0.b
    uunpkhi         z3.h, z0.b
    uunpklo         z4.h, z1.b
    uunpkhi         z5.h, z1.b
    st1h            {z2.h}, p0, [x0]
    st1h            {z3.h}, p0, [x0, #1, mul vl]
    st1h            {z4.h}, p0, [x0, #2, mul vl]
    st1h            {z5.h}, p0, [x0, #3, mul vl]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3
.endr
    ret
.vl_gt_16_blockcopy_ps_32_32:
    ptrue           p0.b, vl32
.rept 32
    ld1b            {z0.b}, p0/z, [x2]
    uunpklo         z2.h, z0.b
    uunpkhi         z3.h, z0.b
    st1h            {z2.h}, p0, [x0]
    st1h            {z3.h}, p0, [x0, #1, mul vl]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3
.endr
    ret
endfunc

function PFX(blockcopy_ps_64x64_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_blockcopy_ps_64_64
    ptrue           p0.b, vl16
.rept 64
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z2.b}, p0/z, [x2, #2, mul vl]
    ld1b            {z3.b}, p0/z, [x2, #3, mul vl]
    uunpklo         z4.h, z0.b
    uunpkhi         z5.h, z0.b
    uunpklo         z6.h, z1.b
    uunpkhi         z7.h, z1.b
    uunpklo         z8.h, z2.b
    uunpkhi         z9.h, z2.b
    uunpklo         z10.h, z3.b
    uunpkhi         z11.h, z3.b
    st1h            {z4.h}, p0, [x0]
    st1h            {z5.h}, p0, [x0, #1, mul vl]
    st1h            {z6.h}, p0, [x0, #2, mul vl]
    st1h            {z7.h}, p0, [x0, #3, mul vl]
    st1h            {z8.h}, p0, [x0, #4, mul vl]
    st1h            {z9.h}, p0, [x0, #5, mul vl]
    st1h            {z10.h}, p0, [x0, #6, mul vl]
    st1h            {z11.h}, p0, [x0, #7, mul vl]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3
.endr
    ret
.vl_gt_16_blockcopy_ps_64_64:
    cmp             x9, #48
    bgt             .vl_gt_48_blockcopy_ps_64_64
    ptrue           p0.b, vl32
.rept 64
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, #1, mul vl]
    uunpklo         z4.h, z0.b
    uunpkhi         z5.h, z0.b
    uunpklo         z6.h, z1.b
    uunpkhi         z7.h, z1.b
    st1h            {z4.h}, p0, [x0]
    st1h            {z5.h}, p0, [x0, #1, mul vl]
    st1h            {z6.h}, p0, [x0, #2, mul vl]
    st1h            {z7.h}, p0, [x0, #3, mul vl]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3
.endr
    ret
.vl_gt_48_blockcopy_ps_64_64:
    ptrue           p0.b, vl64
.rept 64
    ld1b            {z0.b}, p0/z, [x2]
    uunpklo         z4.h, z0.b
    uunpkhi         z5.h, z0.b
    st1h            {z4.h}, p0, [x0]
    st1h            {z5.h}, p0, [x0, #1, mul vl]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3
.endr
    ret
endfunc

// void x265_blockcopy_ss(int16_t* a, intptr_t stridea, const int16_t* b, intptr_t strideb)
function PFX(blockcopy_ss_4x4_sve2)
    ptrue           p0.h, vl8
    lsl             x3, x3, #1
    lsl             x1, x1, #1
    index           z1.d, #0, x3
    index           z2.d, #0, x1
.rept 2
    ld1d            {z0.d}, p0/z, [x2, z1.d]
    st1d            {z0.d}, p0, [x0, z2.d]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc

function PFX(blockcopy_ss_8x8_sve2)
    ptrue           p0.h, vl8
.rept 8
    ld1h            {z0.h}, p0/z, [x2]
    st1h            {z0.h}, p0, [x0]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc

function PFX(blockcopy_ss_16x16_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_blockcopy_ss_16_16
    ptrue           p0.h, vl8
.rept 16
    ld1h            {z0.h}, p0/z, [x2]
    ld1h            {z1.h}, p0/z, [x2, #1, mul vl]
    st1h            {z0.h}, p0, [x0]
    st1h            {z1.h}, p0, [x0, #1, mul vl]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_16_blockcopy_ss_16_16:
    ptrue           p0.h, vl16
.rept 16
    ld1h            {z0.h}, p0/z, [x2]
    st1h            {z0.h}, p0, [x0]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc

function PFX(blockcopy_ss_32x32_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_blockcopy_ss_32_32
    ptrue           p0.h, vl8
.rept 32
    ld1h            {z0.h}, p0/z, [x2]
    ld1h            {z1.h}, p0/z, [x2, #1, mul vl]
    ld1h            {z2.h}, p0/z, [x2, #2, mul vl]
    ld1h            {z3.h}, p0/z, [x2, #3, mul vl]
    st1h            {z0.h}, p0, [x0]
    st1h            {z1.h}, p0, [x0, #1, mul vl]
    st1h            {z2.h}, p0, [x0, #2, mul vl]
    st1h            {z3.h}, p0, [x0, #3, mul vl]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_16_blockcopy_ss_32_32:
    cmp             x9, #32
    bgt             .vl_gt_32_blockcopy_ss_32_32
    ptrue           p0.h, vl16
.rept 32
    ld1h            {z0.h}, p0/z, [x2]
    ld1h            {z1.h}, p0/z, [x2, #1, mul vl]
    st1h            {z0.h}, p0, [x0]
    st1h            {z1.h}, p0, [x0, #1, mul vl]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_32_blockcopy_ss_32_32:
    cmp             x9, #48
    bgt             .vl_gt_48_blockcopy_ss_32_32
    ptrue           p0.h, mul4
    ptrue           p1.h, vl8
.rept 32
    ld1h            {z0.h}, p0/z, [x2]
    ld1h            {z1.h}, p1/z, [x2, #1, mul vl]
    st1h            {z0.h}, p0, [x0]
    st1h            {z1.h}, p1, [x0, #1, mul vl]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_48_blockcopy_ss_32_32:
    ptrue           p0.h, vl32
.rept 32
    ld1h            {z0.h}, p0/z, [x2]
    st1h            {z0.h}, p0, [x0]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc

function PFX(blockcopy_ss_64x64_sve2)
    mov             x8, #64
    mov             w12, #64
.L_init_blockcopy_ss_64x64:
    sub             w12, w12, 1
    mov             x9, #0
    whilelt         p0.h, x9, x8
.L_blockcopy_ss_64x64:
    ld1h            {z0.h}, p0/z, [x2, x9, lsl #1]
    st1h            {z0.h}, p0, [x0, x9, lsl #1]
    inch            x9
    whilelt         p0.h, x9, x8
    b.first         .L_blockcopy_ss_64x64
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
    cbnz            w12, .L_init_blockcopy_ss_64x64
    ret
endfunc

/******** Chroma blockcopy********/
function PFX(blockcopy_ss_4x8_sve2)
    ptrue           p0.h, vl8
    lsl             x3, x3, #1
    lsl             x1, x1, #1
    index           z1.d, #0, x3
    index           z2.d, #0, x1
.rept 4
    ld1d            {z0.d}, p0/z, [x2, z1.d]
    st1d            {z0.d}, p0, [x0, z2.d]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc

function PFX(blockcopy_ss_8x16_sve2)
    ptrue           p0.h, vl8
.rept 16
    ld1h            {z0.h}, p0/z, [x2]
    st1h            {z0.h}, p0, [x0]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret    
endfunc

function PFX(blockcopy_ss_16x32_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_blockcopy_ss_16_32
    ptrue           p0.h, vl8
.rept 32
    ld1h            {z0.h}, p0/z, [x2]
    ld1h            {z1.h}, p0/z, [x2, #1, mul vl]
    st1h            {z0.h}, p0, [x0]
    st1h            {z1.h}, p0, [x0, #1, mul vl]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_16_blockcopy_ss_16_32:
    ptrue           p0.h, vl16
.rept 32
    ld1h            {z0.h}, p0/z, [x2]
    st1h            {z0.h}, p0, [x0]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc

function PFX(blockcopy_ss_32x64_sve2)
    mov             x8, #32
    mov             w12, #64
.L_init_blockcopy_ss_32x64:
    sub             w12, w12, 1
    mov             x9, #0
    whilelt         p0.h, x9, x8
.L_blockcopy_ss_32x64:
    ld1h            {z0.h}, p0/z, [x2, x9, lsl #1]
    st1h            {z0.h}, p0, [x0, x9, lsl #1]
    inch            x9
    whilelt         p0.h, x9, x8
    b.first         .L_blockcopy_ss_32x64
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
    cbnz            w12, .L_init_blockcopy_ss_32x64
    ret
endfunc

// chroma blockcopy_ps
function PFX(blockcopy_ps_4x8_sve2)
    ptrue           p0.h, vl4
.rept 8
    ld1b            {z0.h}, p0/z, [x2]
    st1h            {z0.h}, p1, [x0]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3
.endr
    ret
endfunc

function PFX(blockcopy_ps_8x16_sve2)
    ptrue           p0.h, vl8
.rept 16
    ld1b            {z0.h}, p0/z, [x2]
    st1h            {z0.h}, p1, [x0]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3
.endr
    ret
endfunc

function PFX(blockcopy_ps_16x32_sve2)
    ptrue           p0.b, vl16
.rept 32
    ld1b            {z0.b}, p0/z, [x2]
    uunpklo         z1.h, z0.b
    uunpkhi         z2.h, z0.b
    st1h            {z1.h}, p0, [x0]
    st1h            {z2.h}, p0, [x0, #1, mul vl]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3
.endr
    ret
endfunc

function PFX(blockcopy_ps_32x64_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_blockcopy_ps_32_64
    ptrue           p0.b, vl16
.rept 64
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, #1, mul vl]
    uunpklo         z2.h, z0.b
    uunpkhi         z3.h, z0.b
    uunpklo         z4.h, z1.b
    uunpkhi         z5.h, z1.b
    st1h            {z2.h}, p0, [x0]
    st1h            {z3.h}, p0, [x0, #1, mul vl]
    st1h            {z4.h}, p0, [x0, #2, mul vl]
    st1h            {z5.h}, p0, [x0, #3, mul vl]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3
.endr
    ret
.vl_gt_16_blockcopy_ps_32_64:
    ptrue           p0.b, vl32
.rept 64
    ld1b            {z0.b}, p0/z, [x2]
    uunpklo         z2.h, z0.b
    uunpkhi         z3.h, z0.b
    st1h            {z2.h}, p0, [x0]
    st1h            {z3.h}, p0, [x0, #1, mul vl]
    add             x0, x0, x1, lsl #1
    add             x2, x2, x3
.endr
    ret
endfunc

// chroma blockcopy_sp
function PFX(blockcopy_sp_4x8_sve2)
    ptrue           p0.h, vl4
.rept 8
    ld1h            {z0.h}, p0/z, [x2]
    st1b            {z0.h}, p0, [x0]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1
.endr
    ret
endfunc

function PFX(blockcopy_sp_8x16_sve2)
    ptrue           p0.h, vl8
.rept 16
    ld1h            {z0.h}, p0/z, [x2]
    st1b            {z0.h}, p0, [x0]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1
.endr
    ret
endfunc

function PFX(blockcopy_sp_16x32_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_blockcopy_sp_16_32
    ptrue           p0.h, vl8
.rept 32
    ld1h            {z0.h}, p0/z, [x2]
    ld1h            {z1.h}, p0/z, [x2, #1, mul vl]
    st1b            {z0.h}, p0, [x0]
    st1b            {z1.h}, p0, [x0, #1, mul vl]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1
.endr
    ret
.vl_gt_16_blockcopy_sp_16_32:
    ptrue           p0.h, vl16
.rept 32
    ld1h            {z0.h}, p0/z, [x2]
    st1b            {z0.h}, p0, [x0]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1
.endr
    ret
endfunc

function PFX(blockcopy_sp_32x64_sve2)
    mov             x8, #32
    mov             w12, #64
.L_init_blockcopy_sp_32x64:
    sub             w12, w12, 1
    mov             x9, #0
    whilelt         p0.h, x9, x8
.L_blockcopy_sp_32x64:
    ld1h            {z0.h}, p0/z, [x2, x9, lsl #1]
    st1b            {z0.h}, p0, [x0, x9]
    inch            x9
    whilelt         p0.h, x9, x8
    b.first         .L_blockcopy_sp_32x64
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1
    cbnz            w12, .L_init_blockcopy_sp_32x64
    ret
endfunc

/* blockcopy_pp(pixel* dst, intptr_t dstStride, const pixel* src, intptr_t srcStride) */

function PFX(blockcopy_pp_2x4_sve2)
    ptrue           p0.d, vl2
    index           z1.d, #0, x3
    index           z2.d, #0, x1
.rept 2
    ld1h            {z0.d}, p0/z, [x2, z1.d]
    st1h            {z0.d}, p0, [x0, z2.d]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc

.macro blockcopy_pp_2xN_sve2 h
function PFX(blockcopy_pp_2x\h\()_sve2)
    ptrue           p0.d, vl2
    index           z1.d, #0, x3
    index           z2.d, #0, x1
.rept \h / 2
    ld1h            {z0.d}, p0/z, [x2, z1.d]
    st1h            {z0.d}, p0, [x0, z2.d]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc
.endm

blockcopy_pp_2xN_sve2 8
blockcopy_pp_2xN_sve2 16

function PFX(blockcopy_pp_4x2_sve2)
    ptrue           p0.d, vl2
    index           z1.d, #0, x3
    index           z2.d, #0, x1
    ld1w            {z0.d}, p0/z, [x2, z1.d]
    st1w            {z0.d}, p0, [x0, z2.d]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
    ret
endfunc

function PFX(blockcopy_pp_4x4_sve2)
    ptrue           p0.d, vl2
    index           z1.d, #0, x3
    index           z2.d, #0, x1
.rept 2
    ld1w            {z0.d}, p0/z, [x2, z1.d]
    st1w            {z0.d}, p0, [x0, z2.d]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc

.macro blockcopy_pp_4xN_sve2 h
function PFX(blockcopy_pp_4x\h\()_sve2)
    ptrue           p0.d, vl2
    index           z1.d, #0, x3
    index           z2.d, #0, x1
.rept \h / 2
    ld1w            {z0.d}, p0/z, [x2, z1.d]
    st1w            {z0.d}, p0, [x0, z2.d]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc
.endm

blockcopy_pp_4xN_sve2 8
blockcopy_pp_4xN_sve2 16
blockcopy_pp_4xN_sve2 32

// There is no performance improvement if the following
// function is migrated to SVE2. So, it is left intact
.macro blockcopy_pp_6xN_sve2 h
function PFX(blockcopy_pp_6x\h\()_sve2)
    sub             x1, x1, #4
.rept \h
    ld1             {v0.8b}, [x2], x3
    st1             {v0.s}[0], [x0], #4
    st1             {v0.h}[2], [x0], x1
.endr
    ret
endfunc
.endm

blockcopy_pp_6xN_sve2 8
blockcopy_pp_6xN_sve2 16

.macro blockcopy_pp_8xN_sve2 h
function PFX(blockcopy_pp_8x\h\()_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_blockcopy_pp_8xN_\h
    ptrue           p0.d, vl2
    index           z1.d, #0, x3
    index           z2.d, #0, x1
.rept \h /2
    ld1d            {z0.d}, p0/z, [x2, z1.d]
    st1d            {z0.d}, p0, [x0, z2.d]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_16_blockcopy_pp_8xN_\h\():
    cmp             x9, #48
    bgt             .vl_gt_48_blockcopy_pp_8xN_\h
    ptrue           p0.d, vl4
    index           z1.d, #0, x3
    index           z2.d, #0, x1
.rept \h / 2
    ld1d            {z0.d}, p0/z, [x2, z1.d]
    st1d            {z0.d}, p0, [x0, z2.d]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_48_blockcopy_pp_8xN_\h\():
    ptrue           p0.d, vl8
    index           z1.d, #0, x3
    index           z2.d, #0, x1
    ld1d            {z0.d}, p0/z, [x2, z1.d]
    st1d            {z0.d}, p0, [x0, z2.d]
    ret
endfunc
.endm

blockcopy_pp_8xN_sve2 2
blockcopy_pp_8xN_sve2 4
blockcopy_pp_8xN_sve2 6
blockcopy_pp_8xN_sve2 8
blockcopy_pp_8xN_sve2 12
blockcopy_pp_8xN_sve2 16
blockcopy_pp_8xN_sve2 32

function PFX(blockcopy_pp_8x64_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_blockcopy_pp_8x64
    ptrue           p0.d, vl2
    index           z1.d, #0, x3
    index           z2.d, #0, x1
.rept 32
    ld1d            {z0.d}, p0/z, [x2, z1.d]
    st1d            {z0.d}, p0, [x0, z2.d]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_16_blockcopy_pp_8x64:
    cmp             x9, #48
    bgt             .vl_gt_48_blockcopy_pp_8x64
    ptrue           p0.d, vl4
    index           z1.d, #0, x3
    index           z2.d, #0, x1
.rept 16
    ld1d            {z0.d}, p0/z, [x2, z1.d]
    st1d            {z0.d}, p0, [x0, z2.d]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_48_blockcopy_pp_8x64:
    cmp             x9, #112
    bgt             .vl_gt_112_blockcopy_pp_8x64
    ptrue           p0.d, vl8
    index           z1.d, #0, x3
    index           z2.d, #0, x1
.rept 8
    ld1d            {z0.d}, p0/z, [x2, z1.d]
    st1d            {z0.d}, p0, [x0, z2.d]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_112_blockcopy_pp_8x64:
    ptrue           p0.d, vl16
    index           z1.d, #0, x3
    index           z2.d, #0, x1
.rept 4
    ld1d            {z0.d}, p0/z, [x2, z1.d]
    st1d            {z0.d}, p0, [x0, z2.d]
    add             x2, x2, x3, lsl #1
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc

.macro blockcopy_pp_16xN_sve2 h
function PFX(blockcopy_pp_16x\h\()_sve2)
    ptrue           p0.d, vl2
.rept \h
    ld1d            {z0.d}, p0/z, [x2]
    st1d            {z0.d}, p0, [x0]
    add             x2, x2, x3
    add             x0, x0, x1
.endr
    ret
endfunc
.endm

blockcopy_pp_16xN_sve2 4
blockcopy_pp_16xN_sve2 8
blockcopy_pp_16xN_sve2 12
blockcopy_pp_16xN_sve2 16

.macro blockcopy_pp_16xN1_sve2 h
function PFX(blockcopy_pp_16x\h\()_sve2)
    mov             w12, #\h / 8
    ptrue           p0.d, vl2
.L_blockcopy_pp_16xN1_\h:
    sub             w12, w12, #1
.rept 8
    ld1d            {z0.d}, p0/z, [x2]
    st1d            {z0.d}, p0, [x0]
    add             x2, x2, x3
    add             x0, x0, x1
.endr
    cbnz            w12, .L_blockcopy_pp_16xN1_\h
    ret
endfunc
.endm

blockcopy_pp_16xN1_sve2 24
blockcopy_pp_16xN1_sve2 32
blockcopy_pp_16xN1_sve2 64

// There is no performance improvement if the following
// function is migrated to SVE2. So, it is left intact
function PFX(blockcopy_pp_12x16_sve2)
    sub             x1, x1, #8
.rept 16
    ld1             {v0.16b}, [x2], x3
    str             d0, [x0], #8
    st1             {v0.s}[2], [x0], x1
.endr
    ret
endfunc

// There is no performance improvement if the following
// function is migrated to SVE2. So, it is left intact
function PFX(blockcopy_pp_12x32_sve2)
    sub             x1, x1, #8
    mov             w12, #4
.loop_pp_12x32_sve2:
    sub             w12, w12, #1
.rept 8
    ld1             {v0.16b}, [x2], x3
    str             d0, [x0], #8
    st1             {v0.s}[2], [x0], x1
.endr
    cbnz            w12, .loop_pp_12x32_sve2
    ret
endfunc

function PFX(blockcopy_pp_24x32_sve2)
    mov             w12, #32
    mov             x8, #3
.L_blockcopy_pp_24x32:
    sub             w12, w12, #1
    mov             x9, #0
    whilelt         p0.d, x9, x8
.L_blockcopy_pp_24x32_inner:
    ld1d            {z0.d}, p0/z, [x2, x9, lsl #3]
    st1d            {z0.d}, p0, [x0, x9, lsl #3]
    incd            x9
    whilelt         p0.d, x9, x8
    b.first         .L_blockcopy_pp_24x32_inner
    add             x2, x2, x3
    add             x0, x0, x1
    cbnz            w12, .L_blockcopy_pp_24x32
    ret
endfunc

function PFX(blockcopy_pp_24x64_sve2)
    mov             w12, #64
    mov             x8, #3
.L_blockcopy_pp_24x64:
    sub             w12, w12, #1
    mov             x9, #0
    whilelt         p0.d, x9, x8
.L_blockcopy_pp_24x64_inner:
    ld1d            {z0.d}, p0/z, [x2, x9, lsl #3]
    st1d            {z0.d}, p0, [x0, x9, lsl #3]
    incd            x9
    whilelt         p0.d, x9, x8
    b.first         .L_blockcopy_pp_24x64_inner
    add             x2, x2, x3
    add             x0, x0, x1
    cbnz            w12, .L_blockcopy_pp_24x64
    ret
endfunc

function PFX(blockcopy_pp_32x8_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_blockcopy_pp_32_8
    ptrue           p0.b, vl16
.rept 8
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, #1, mul vl]
    st1b            {z0.b}, p0, [x0]
    st1b            {z1.b}, p0, [x0, #1, mul vl]
    add             x2, x2, x3
    add             x0, x0, x1
.endr
    ret
.vl_gt_16_blockcopy_pp_32_8:
    ptrue           p0.b, vl32
.rept 8
    ld1b            {z0.b}, p0/z, [x2]
    st1b            {z0.b}, p0, [x0]
    add             x2, x2, x3
    add             x0, x0, x1
.endr
    ret
endfunc

.macro blockcopy_pp_32xN_sve2 h
function PFX(blockcopy_pp_32x\h\()_sve2)
    mov             w12, #\h / 8
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_blockcopy_pp_32xN_\h
    ptrue           p0.b, vl16
.L_le_16_blockcopy_pp_32xN_\h:
    sub             w12, w12, #1
.rept 8
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, #1, mul vl]
    st1b            {z0.b}, p0, [x0]
    st1b            {z1.b}, p0, [x0, #1, mul vl]
    add             x2, x2, x3
    add             x0, x0, x1
.endr
    cbnz            w12, .L_le_16_blockcopy_pp_32xN_\h
    ret
.vl_gt_16_blockcopy_pp_32xN_\h:
    ptrue           p0.b, vl32
.L_gt_16_blockcopy_pp_32xN_\h:
    sub             w12, w12, #1
.rept 8
    ld1b            {z0.b}, p0/z, [x2]
    st1b            {z0.b}, p0, [x0]
    add             x2, x2, x3
    add             x0, x0, x1
.endr
    ret
    cbnz            w12, .L_gt_16_blockcopy_pp_32xN_\h
    ret
endfunc
.endm

blockcopy_pp_32xN_sve2 16
blockcopy_pp_32xN_sve2 24
blockcopy_pp_32xN_sve2 32
blockcopy_pp_32xN_sve2 64
blockcopy_pp_32xN_sve2 48

function PFX(blockcopy_pp_48x64_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_blockcopy_pp_48_64
    ptrue           p0.b, vl16
.rept 64
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z2.b}, p0/z, [x2, #2, mul vl]
    st1b            {z0.b}, p0, [x0]
    st1b            {z1.b}, p0, [x0, #1, mul vl]
    st1b            {z2.b}, p0, [x0, #2, mul vl]
    add             x2, x2, x3
    add             x0, x0, x1
.endr
    ret
.vl_gt_16_blockcopy_pp_48_64:
    mov             w12, #64
    mov             x8, 48
.L_blockcopy_pp_48x64_out:
    sub             w12, w12, #1
    mov             x9, #0
    whilelt         p0.b, x9, x8
.L_blockcopy_pp_48x64_inner:
    ld1b            {z0.b}, p0/z, [x2, x9]
    st1b            {z0.b}, p0, [x0, x9]
    incb            x9
    whilelt         p0.b, x9, x8
    b.first         .L_blockcopy_pp_48x64_inner
    add             x2, x2, x3
    add             x0, x0, x1
    cbnz            w12, .L_blockcopy_pp_48x64_out
    ret
endfunc

.macro blockcopy_pp_64xN_sve2 h
function PFX(blockcopy_pp_64x\h\()_sve2)
    mov             w12, #\h / 4
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_blockcopy_pp_64xN_\h
    ptrue           p0.b, vl16
.L_le_16_blockcopy_pp_64xN_\h:
    sub             w12, w12, #1
.rept 4
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z2.b}, p0/z, [x2, #2, mul vl]
    ld1b            {z3.b}, p0/z, [x2, #3, mul vl]
    st1b            {z0.b}, p0, [x0]
    st1b            {z1.b}, p0, [x0, #1, mul vl]
    st1b            {z2.b}, p0, [x0, #2, mul vl]
    st1b            {z3.b}, p0, [x0, #3, mul vl]
    add             x2, x2, x3
    add             x0, x0, x1
.endr
    cbnz            w12, .L_le_16_blockcopy_pp_64xN_\h
    ret
.vl_gt_16_blockcopy_pp_64xN_\h:
    cmp             x9, #32
    bgt             .vl_gt_32_blockcopy_pp_64xN_\h
    ptrue           p0.b, vl32
.L_le_32_blockcopy_pp_64xN_\h:
    sub             w12, w12, #1
.rept 4
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, #1, mul vl]
    st1b            {z0.b}, p0, [x0]
    st1b            {z1.b}, p0, [x0, #1, mul vl]
    add             x2, x2, x3
    add             x0, x0, x1
.endr
    cbnz            w12, .L_le_32_blockcopy_pp_64xN_\h
    ret
.vl_gt_32_blockcopy_pp_64xN_\h:
    cmp             x9, #48
    bgt             .vl_gt_48_blockcopy_pp_64xN_\h
    ptrue           p0.b, mul4
    ptrue           p1.b, vl16
.L_le_48_blockcopy_pp_64xN_\h:
    sub             w12, w12, #1
.rept 4
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p1/z, [x2, #1, mul vl]
    st1b            {z0.b}, p0, [x0]
    st1b            {z1.b}, p1, [x0, #1, mul vl]
    add             x2, x2, x3
    add             x0, x0, x1
.endr
    cbnz            w12, .L_le_48_blockcopy_pp_64xN_\h
    ret
.vl_gt_48_blockcopy_pp_64xN_\h:
    ptrue           p0.b, vl64
.L_blockcopy_pp_64xN_\h:
    sub             w12, w12, #1
.rept 4
    ld1b            {z0.b}, p0/z, [x2]
    st1b            {z0.b}, p0, [x0]
    add             x2, x2, x3
    add             x0, x0, x1
.endr
    cbnz            w12, .L_blockcopy_pp_64xN_\h
    ret
endfunc
.endm

blockcopy_pp_64xN_sve2 16
blockcopy_pp_64xN_sve2 32
blockcopy_pp_64xN_sve2 48
blockcopy_pp_64xN_sve2 64

// void x265_blockfill_s_neon(int16_t* dst, intptr_t dstride, int16_t val)
// There is no performance improvement if the following
// function is migrated to SVE2. So, it is left intact
function PFX(blockfill_s_4x4_sve2)
    dup             v0.4h, w2
    lsl             x1, x1, #1
.rept 4
    st1             {v0.4h}, [x0], x1
.endr
    ret
endfunc

// There is no performance improvement if the following
// function is migrated to SVE2. So, it is left intact
function PFX(blockfill_s_8x8_sve2)
    dup             v0.8h, w2
    lsl             x1, x1, #1
.rept 8
    st1             {v0.8h}, [x0], x1
.endr
    ret
endfunc

function PFX(blockfill_s_16x16_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_blockfill_s_16x16
    dup             z0.h, w2
    ptrue           p0.h, vl8
.rept 16
    st1h            {z0.h}, p0, [x0]
    st1h            {z0.h}, p0, [x0, #1, mul vl]
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_16_blockfill_s_16x16:
    dup             z0.h, w2
    ptrue           p0.h, vl16
.rept 16
    st1h            {z0.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc

function PFX(blockfill_s_32x32_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_blockfill_s_32_32
    dup             z0.h, w2
    ptrue           p0.h, vl8
.rept 32
    st1h            {z0.h}, p0, [x0]
    st1h            {z0.h}, p0, [x0, #1, mul vl]
    st1h            {z0.h}, p0, [x0, #2, mul vl]
    st1h            {z0.h}, p0, [x0, #3, mul vl]
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_16_blockfill_s_32_32:
    cmp             x9, #32
    bgt             .vl_gt_32_blockfill_s_32_32
    dup             z0.h, w2
    ptrue           p0.h, vl16
.rept 32
    st1h            {z0.h}, p0, [x0]
    st1h            {z0.h}, p0, [x0, #1, mul vl]
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_32_blockfill_s_32_32:
    cmp             x9, #48
    bgt             .vl_gt_48_blockfill_s_32_32
    dup             z0.h, w2
    ptrue           p0.h, mul4
    ptrue           p1.h, vl8
.rept 32
    st1h            {z0.h}, p0, [x0]
    st1h            {z0.h}, p1, [x0, #1, mul vl]
    add             x0, x0, x1, lsl #1
.endr
    ret
.vl_gt_48_blockfill_s_32_32:
    dup             z0.h, w2
    ptrue           p0.h, vl32
.rept 32
    st1h            {z0.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    ret
endfunc

function PFX(blockfill_s_64x64_sve2)
    mov             x8, #64
    mov             w12, #64
    dup             z0.h, w2
.L_init_blockfill_s_64x64:
    sub             w12, w12, 1
    mov             x9, #0
    whilelt         p0.h, x9, x8
.L_blockfill_s_64x64:
    st1h            {z0.h}, p0, [x0, x9, lsl #1]
    inch            x9
    whilelt         p0.h, x9, x8
    b.first         .L_blockfill_s_64x64
    add             x0, x0, x1, lsl #1
    cbnz            w12, .L_init_blockfill_s_64x64
    ret
endfunc

// uint32_t copy_count(int16_t* coeff, const int16_t* residual, intptr_t resiStride)
function PFX(copy_cnt_4_sve2)
    ptrue           p0.h, vl8
    mov             x15, #0
    lsl             x2, x2, #1
    index           z1.d, #0, x2
.rept 2
    ld1d            {z0.d}, p0/z, [x1, z1.d]
    add             x1, x1, x2, lsl #1
    st1d            {z0.d}, p0, [x0]
    add             x0, x0, #16
    cmpne           p2.h, p0/z, z0.h, #0
    incp            x15, p2.h
.endr
    mov             x0, x15
    ret
endfunc

function PFX(copy_cnt_8_sve2)
    ptrue           p0.h, vl8
    mov             x15, #0
.rept 8
    ld1h            {z0.h}, p0/z, [x1]
    st1h            {z0.h}, p0, [x0]
    add             x1, x1, x2, lsl #1
    add             x0, x0, #16
    cmpne           p2.h, p0/z, z0.h, #0
    incp            x15, p2.h
.endr
    mov             x0, x15
    ret
endfunc

function PFX(copy_cnt_16_sve2)
    mov             x15, #0
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_copy_cnt_16
    ptrue           p0.h, vl8
.rept 16
    ld1h            {z0.h}, p0/z, [x1]
    ld1h            {z1.h}, p0/z, [x1, #1, mul vl]
    st1h            {z0.h}, p0, [x0]
    st1h            {z1.h}, p0, [x0, #1, mul vl]
    add             x1, x1, x2, lsl #1
    add             x0, x0, #32
    cmpne           p2.h, p0/z, z0.h, #0
    cmpne           p3.h, p0/z, z1.h, #0
    incp            x15, p2.h
    incp            x15, p3.h
.endr
    mov             x0, x15
    ret
.vl_gt_16_copy_cnt_16:
    ptrue           p0.h, vl16
.rept 16
    ld1h            {z0.h}, p0/z, [x1]
    st1h            {z0.h}, p0, [x0]
    add             x1, x1, x2, lsl #1
    add             x0, x0, #32
    cmpne           p2.h, p0/z, z0.h, #0
    incp            x15, p2.h
.endr
    mov             x0, x15
    ret
endfunc

function PFX(copy_cnt_32_sve2)
    mov             x15, #0
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_copy_cnt_32
    ptrue           p0.h, vl8
.rept 32
    ld1h            {z0.h}, p0/z, [x1]
    ld1h            {z1.h}, p0/z, [x1, #1, mul vl]
    ld1h            {z2.h}, p0/z, [x1, #2, mul vl]
    ld1h            {z3.h}, p0/z, [x1, #3, mul vl]
    st1h            {z0.h}, p0, [x0]
    st1h            {z1.h}, p0, [x0, #1, mul vl]
    st1h            {z2.h}, p0, [x0, #2, mul vl]
    st1h            {z3.h}, p0, [x0, #3, mul vl]
    add             x1, x1, x2, lsl #1
    add             x0, x0, #64
    cmpne           p2.h, p0/z, z0.h, #0
    cmpne           p3.h, p0/z, z1.h, #0
    cmpne           p4.h, p0/z, z2.h, #0
    cmpne           p5.h, p0/z, z3.h, #0
    incp            x15, p2.h
    incp            x15, p3.h
    incp            x15, p4.h
    incp            x15, p5.h
.endr
    mov             x0, x15
    ret
.vl_gt_16_copy_cnt_32:
    cmp             x9, #48
    bgt             .vl_gt_48_copy_cnt_32
    ptrue           p0.h, vl16
.rept 32
    ld1h            {z0.h}, p0/z, [x1]
    ld1h            {z1.h}, p0/z, [x1, #1, mul vl]
    st1h            {z0.h}, p0, [x0]
    st1h            {z1.h}, p0, [x0, #1, mul vl]
    add             x1, x1, x2, lsl #1
    add             x0, x0, #64
    cmpne           p2.h, p0/z, z0.h, #0
    cmpne           p3.h, p0/z, z1.h, #0
    incp            x15, p2.h
    incp            x15, p3.h
.endr
    mov             x0, x15
    ret
.vl_gt_48_copy_cnt_32:
    ptrue           p0.h, vl32
.rept 32
    ld1h            {z0.h}, p0/z, [x1]
    st1h            {z0.h}, p0, [x0]
    add             x1, x1, x2, lsl #1
    add             x0, x0, #64
    cmpne           p2.h, p0/z, z0.h, #0
    incp            x15, p2.h
.endr
    mov             x10, x15
    ret
endfunc

// int  count_nonzero_c(const int16_t* quantCoeff)
function PFX(count_nonzero_4_sve2)
    mov             x15, #0
    ptrue           p5.h, vl8
    ld1h            {z0.h}, p5/z, [x0]
    ld1h            {z1.h}, p5/z, [x0, #1, mul vl]
    cmphi           p0.h, p5/z, z0.h, #0
    cmphi           p1.h, p5/z, z1.h, #0
    incp            x15, p0.h
    incp            x15, p1.h
    mov             x0, x15
    ret
endfunc

function PFX(count_nonzero_8_sve2)
    index           z1.d, #0, #8
    mov             x15, #0
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_count_nonzero_8
    ptrue           p7.h, vl8
.rept 8
    ld1d            {z0.d}, p7/z, [x0, z1.d]
    add             x0, x0, #16
    cmphi           p0.h, p7/z, z0.h, #0
    incp            x15, p0.h
.endr
    mov             x0, x15
    ret
.vl_gt_16_count_nonzero_8:
    cmp             x9, #48
    bgt             .vl_gt_48_count_nonzero_8
    ptrue           p7.h, vl16
.rept 4
    ld1d            {z0.d}, p7/z, [x0, z1.d]
    add             x0, x0, #32
    cmphi           p0.h, p7/z, z0.h, #0
    incp            x15, p0.h
.endr
    mov             x0, x15
    ret
.vl_gt_48_count_nonzero_8:
    ptrue           p7.h, vl32
.rept 2
    ld1d            {z0.d}, p7/z, [x0, z1.d]
    add             x0, x0, #64
    cmphi           p0.h, p7/z, z0.h, #0
    incp            x15, p0.h
.endr
    mov             x0, x15
    ret
endfunc

function PFX(count_nonzero_16_sve2)
    index           z1.d, #0, #8
    mov             x15, #0
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_count_nonzero_16
    ptrue           p7.h, vl8
.rept 32
    ld1d            {z0.d}, p7/z, [x0, z1.d]
    add             x0, x0, #16
    cmphi           p0.h, p7/z, z0.h, #0
    incp            x15, p0.h
.endr
    mov             x0, x15
    ret
.vl_gt_16_count_nonzero_16:
    cmp             x9, #48
    bgt             .vl_gt_48_count_nonzero_16
    ptrue           p7.h, vl16
.rept 16
    ld1d            {z0.d}, p7/z, [x0, z1.d]
    add             x0, x0, #32
    cmphi           p0.h, p7/z, z0.h, #0
    incp            x15, p0.h
.endr
    mov             x0, x15
    ret
.vl_gt_48_count_nonzero_16:
    cmp             x9, #112
    bgt             .vl_gt_112_count_nonzero_16
    ptrue           p7.h, vl32
.rept 8
    ld1d            {z0.d}, p7/z, [x0, z1.d]
    add             x0, x0, #64
    cmphi           p0.h, p7/z, z0.h, #0
    incp            x15, p0.h
.endr
    mov             x0, x15
    ret
.vl_gt_112_count_nonzero_16:
    ptrue           p7.h, vl64
.rept 2
    ld1d            {z0.d}, p7/z, [x0, z1.d]
    add             x0, x0, #128
    cmphi           p0.h, p7/z, z0.h, #0
    incp            x15, p0.h
.endr
    mov             x0, x15
    ret
endfunc

function PFX(count_nonzero_32_sve2)
    index           z1.d, #0, #8
    mov             x15, #0
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_count_nonzero_32
    ptrue           p7.h, vl8
.rept 128
    ld1d            {z0.d}, p7/z, [x0, z1.d]
    add             x0, x0, #16
    cmphi           p0.h, p7/z, z0.h, #0
    incp            x15, p0.h
.endr
    mov             x0, x15
    ret
.vl_gt_16_count_nonzero_32:
    cmp             x9, #48
    bgt             .vl_gt_48_count_nonzero_32
    ptrue           p7.h, vl16
.rept 32
    ld1d            {z0.d}, p7/z, [x0, z1.d]
    add             x0, x0, #32
    cmphi           p0.h, p7/z, z0.h, #0
    incp            x15, p0.h
.endr
    mov             x0, x15
    ret
.vl_gt_48_count_nonzero_32:
    cmp             x9, #112
    bgt             .vl_gt_112_count_nonzero_32
    ptrue           p7.h, vl32
.rept 16
    ld1d            {z0.d}, p7/z, [x0, z1.d]
    add             x0, x0, #64
    cmphi           p0.h, p7/z, z0.h, #0
    incp            x15, p0.h
.endr
    mov             x0, x15
    ret
.vl_gt_112_count_nonzero_32:
    cmp             x9, #240
    bgt             .vl_gt_240_count_nonzero_32
    ptrue           p7.h, vl64
.rept 8
    ld1d            {z0.d}, p7/z, [x0, z1.d]
    add             x0, x0, #128
    cmphi           p0.h, p7/z, z0.h, #0
    incp            x15, p0.h
.endr
    mov             x0, x15
    ret
.vl_gt_240_count_nonzero_32:
    ptrue           p7.h, vl128
.rept 4
    ld1d            {z0.d}, p7/z, [x0, z1.d]
    add             x0, x0, #256
    cmphi           p0.h, p7/z, z0.h, #0
    incp            x15, p0.h
.endr
    mov             x0, x15
    ret
endfunc

// void cpy2Dto1D_shl(int16_t* dst, const int16_t* src, intptr_t srcStride, int shift)

function PFX(cpy2Dto1D_shl_4x4_sve2)
    dup             z0.h, w3
    ptrue           p0.h, vl8
    lsl             x2, x2, #1
    index           z1.d, #0, x2
    index           z2.d, #0, #8
.rept 2
    ld1d            {z3.d}, p0/z, [x1, z1.d]
    lsl             z3.h, p0/m, z3.h, z0.h
    st1d            {z3.d}, p0, [x0, z2.d]
    add             x1, x1, x2, lsl #1
    add             x0, x0, #16
.endr
    ret
endfunc

function PFX(cpy2Dto1D_shl_8x8_sve2)
    dup             z0.h, w3
    ptrue           p0.h, vl8
.rept 8
    ld1h            {z1.h}, p0/z, [x1]
    lsl             z1.h, p0/m, z1.h, z0.h
    st1h            {z1.h}, p0, [x0]
    add             x1, x1, x2, lsl #1
    add             x0, x0, #16
.endr
    ret
endfunc

function PFX(cpy2Dto1D_shl_16x16_sve2)
    dup             z0.h, w3
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_cpy2Dto1D_shl_16x16
    ptrue           p0.h, vl8
.rept 16
    ld1h            {z1.h}, p0/z, [x1]
    ld1h            {z2.h}, p0/z, [x1, #1, mul vl]
    lsl             z1.h, p0/m, z1.h, z0.h
    lsl             z2.h, p0/m, z2.h, z0.h
    st1h            {z1.h}, p0, [x0]
    st1h            {z2.h}, p0, [x0, #1, mul vl]
    add             x1, x1, x2, lsl #1
    add             x0, x0, #32
.endr
    ret
.vl_gt_16_cpy2Dto1D_shl_16x16:
    ptrue           p0.h, vl16
.rept 16
    ld1h            {z1.h}, p0/z, [x1]
    lsl             z1.h, p0/m, z1.h, z0.h
    st1h            {z1.h}, p0, [x0]
    add             x1, x1, x2, lsl #1
    add             x0, x0, #32
.endr
    ret
endfunc

function PFX(cpy2Dto1D_shl_32x32_sve2)
    dup             z0.h, w3
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_cpy2Dto1D_shl_32x32
    ptrue           p0.h, vl8
.rept 32
    ld1h            {z1.h}, p0/z, [x1]
    ld1h            {z2.h}, p0/z, [x1, #1, mul vl]
    ld1h            {z3.h}, p0/z, [x1, #2, mul vl]
    ld1h            {z4.h}, p0/z, [x1, #3, mul vl]
    lsl             z1.h, p0/m, z1.h, z0.h
    lsl             z2.h, p0/m, z2.h, z0.h
    lsl             z3.h, p0/m, z3.h, z0.h
    lsl             z4.h, p0/m, z4.h, z0.h
    st1h            {z1.h}, p0, [x0]
    st1h            {z2.h}, p0, [x0, #1, mul vl]
    st1h            {z3.h}, p0, [x0, #2, mul vl]
    st1h            {z4.h}, p0, [x0, #3, mul vl]
    add             x1, x1, x2, lsl #1
    add             x0, x0, #64
.endr
    ret
.vl_gt_16_cpy2Dto1D_shl_32x32:
    cmp             x9, #32
    bgt             .vl_gt_32_cpy2Dto1D_shl_32x32
    ptrue           p0.h, vl16
.rept 32
    ld1h            {z1.h}, p0/z, [x1]
    ld1h            {z2.h}, p0/z, [x1, #1, mul vl]
    lsl             z1.h, p0/m, z1.h, z0.h
    lsl             z2.h, p0/m, z2.h, z0.h
    st1h            {z1.h}, p0, [x0]
    st1h            {z2.h}, p0, [x0, #1, mul vl]
    add             x1, x1, x2, lsl #1
    add             x0, x0, #64
.endr
    ret
.vl_gt_32_cpy2Dto1D_shl_32x32:
    cmp             x9, #48
    bgt             .vl_gt_48_cpy2Dto1D_shl_32x32
    ptrue           p0.h, mul4
    ptrue           p1.h, vl8
.rept 32
    ld1h            {z1.h}, p0/z, [x1]
    ld1h            {z2.h}, p1/z, [x1, #1, mul vl]
    lsl             z1.h, p0/m, z1.h, z0.h
    lsl             z2.h, p1/m, z2.h, z0.h
    st1h            {z1.h}, p0, [x0]
    st1h            {z2.h}, p1, [x0, #1, mul vl]
    add             x1, x1, x2, lsl #1
    add             x0, x0, #64
.endr
    ret
.vl_gt_48_cpy2Dto1D_shl_32x32:
    ptrue           p0.h, vl32
.rept 32
    ld1h            {z1.h}, p0/z, [x1]
    lsl             z1.h, p0/m, z1.h, z0.h
    st1h            {z1.h}, p0, [x0]
    add             x1, x1, x2, lsl #1
    add             x0, x0, #64
.endr
    ret
endfunc

function PFX(cpy2Dto1D_shl_64x64_sve2)
    dup             z0.h, w3
    mov             x8, #64
    mov             w12, #64
.L_init_cpy2Dto1D_shl_64x64:
    sub             w12, w12, 1
    mov             x9, #0
    whilelt         p0.h, x9, x8
.L_cpy2Dto1D_shl_64x64:
    ld1h            {z1.h}, p0/z, [x1, x9, lsl #1]
    lsl             z1.h, p0/m, z1.h, z0.h
    st1h            {z1.h}, p0, [x0, x9, lsl #1]
    inch            x9
    whilelt         p0.h, x9, x8
    b.first         .L_cpy2Dto1D_shl_64x64
    add             x1, x1, x2, lsl #1
    addvl           x0, x0, #1
    cbnz            w12, .L_init_cpy2Dto1D_shl_64x64
    ret
endfunc

// void cpy2Dto1D_shr(int16_t* dst, const int16_t* src, intptr_t srcStride, int shift)

function PFX(cpy2Dto1D_shr_4x4_sve2)
    dup             z0.h, w3
    sub             w4, w3, #1
    dup             z1.h, w4
    ptrue           p0.h, vl8
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
    lsl             x2, x2, #1
    index           z3.d, #0, x2
    index           z4.d, #0, #8
.rept 2
    ld1d            {z5.d}, p0/z, [x1, z3.d]
    add             x1, x1, x2, lsl #1
    add             z5.h, p0/m, z5.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    st1d            {z5.d}, p0, [x0, z4.d]
    add             x0, x0, #16
.endr
    ret
endfunc

function PFX(cpy2Dto1D_shr_8x8_sve2)
    dup             z0.h, w3
    sub             w4, w3, #1
    dup             z1.h, w4
    ptrue           p0.h, vl8
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
.rept 8
    ld1d            {z5.d}, p0/z, [x1]
    add             x1, x1, x2, lsl #1
    add             z5.h, p0/m, z5.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    st1d            {z5.d}, p0, [x0]
    add             x0, x0, #16
.endr
    ret
endfunc

function PFX(cpy2Dto1D_shr_16x16_sve2)
    dup             z0.h, w3
    sub             w4, w3, #1
    dup             z1.h, w4
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_cpy2Dto1D_shr_16x16
    ptrue           p0.h, vl8
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
.rept 16
    ld1d            {z5.d}, p0/z, [x1]
    ld1d            {z6.d}, p0/z, [x1, #1, mul vl]
    add             x1, x1, x2, lsl #1
    add             z5.h, p0/m, z5.h, z2.h
    add             z6.h, p0/m, z6.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    asr             z6.h, p0/m, z6.h, z0.h
    st1d            {z5.d}, p0, [x0]
    st1d            {z6.d}, p0, [x0, #1, mul vl]
    add             x0, x0, #32
.endr
    ret
.vl_gt_16_cpy2Dto1D_shr_16x16:
    ptrue           p0.h, vl16
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
.rept 8
    ld1d            {z5.d}, p0/z, [x1]
    add             x1, x1, x2, lsl #1
    add             z5.h, p0/m, z5.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    st1d            {z5.d}, p0, [x0]
    add             x0, x0, #32
.endr
    ret
endfunc

function PFX(cpy2Dto1D_shr_32x32_sve2)
    dup             z0.h, w3
    sub             w4, w3, #1
    dup             z1.h, w4
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_cpy2Dto1D_shr_32x32
    ptrue           p0.h, vl8
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
.rept 32
    ld1d            {z5.d}, p0/z, [x1]
    ld1d            {z6.d}, p0/z, [x1, #1, mul vl]
    ld1d            {z7.d}, p0/z, [x1, #2, mul vl]
    ld1d            {z8.d}, p0/z, [x1, #3, mul vl]
    add             x1, x1, x2, lsl #1
    add             z5.h, p0/m, z5.h, z2.h
    add             z6.h, p0/m, z6.h, z2.h
    add             z7.h, p0/m, z7.h, z2.h
    add             z8.h, p0/m, z8.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    asr             z6.h, p0/m, z6.h, z0.h
    asr             z7.h, p0/m, z7.h, z0.h
    asr             z8.h, p0/m, z8.h, z0.h
    st1d            {z5.d}, p0, [x0]
    st1d            {z6.d}, p0, [x0, #1, mul vl]
    st1d            {z7.d}, p0, [x0, #2, mul vl]
    st1d            {z8.d}, p0, [x0, #3, mul vl]
    add             x0, x0, #64
.endr
    ret
.vl_gt_16_cpy2Dto1D_shr_32x32:
    cmp             x9, #48
    bgt             .vl_gt_48_cpy2Dto1D_shr_32x32
    ptrue           p0.h, vl16
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
.rept 32
    ld1d            {z5.d}, p0/z, [x1]
    ld1d            {z6.d}, p0/z, [x1, #1, mul vl]
    add             x1, x1, x2, lsl #1
    add             z5.h, p0/m, z5.h, z2.h
    add             z6.h, p0/m, z6.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    asr             z6.h, p0/m, z6.h, z0.h
    st1d            {z5.d}, p0, [x0]
    st1d            {z6.d}, p0, [x0, #1, mul vl]
    add             x0, x0, #64
.endr
    ret
.vl_gt_48_cpy2Dto1D_shr_32x32:
    ptrue           p0.h, vl32
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
.rept 32
    ld1d            {z5.d}, p0/z, [x1]
    add             x1, x1, x2, lsl #1
    add             z5.h, p0/m, z5.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    st1d            {z5.d}, p0, [x0]
    add             x0, x0, #64
.endr
    ret
endfunc

// void cpy1Dto2D_shl(int16_t* dst, const int16_t* src, intptr_t dstStride, int shift)

function PFX(cpy1Dto2D_shl_4x4_sve2)
    dup             z0.h, w3
    ptrue           p0.h, vl8
    lsl             x2, x2, #1
    index           z1.d, #0, #8
    index           z2.d, #0, x2
.rept 2
    ld1d            {z3.d}, p0/z, [x1, z1.d]
    lsl             z3.h, p0/m, z3.h, z0.h
    st1d            {z3.d}, p0, [x0, z2.d]
    add             x1, x1, #16
    add             x0, x0, x2, lsl #1
.endr
    ret
endfunc

function PFX(cpy1Dto2D_shl_8x8_sve2)
    dup             z0.h, w3
    ptrue           p0.h, vl8
.rept 8
    ld1h            {z1.h}, p0/z, [x1]
    lsl             z1.h, p0/m, z1.h, z0.h
    st1h            {z1.h}, p0, [x0]
    add             x1, x1, #16
    add             x0, x0, x2, lsl #1
.endr
    ret
endfunc

function PFX(cpy1Dto2D_shl_16x16_sve2)
    dup             z0.h, w3
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_cpy1Dto2D_shl_16x16
    ptrue           p0.h, vl8
.rept 16
    ld1h            {z1.h}, p0/z, [x1]
    ld1h            {z2.h}, p0/z, [x1, #1, mul vl]
    lsl             z1.h, p0/m, z1.h, z0.h
    lsl             z2.h, p0/m, z2.h, z0.h
    st1h            {z1.h}, p0, [x0]
    st1h            {z2.h}, p0, [x0, #1, mul vl]
    add             x1, x1, #32
    add             x0, x0, x2, lsl #1
.endr
    ret
.vl_gt_16_cpy1Dto2D_shl_16x16:
    ptrue           p0.h, vl16
.rept 16
    ld1h            {z1.h}, p0/z, [x1]
    lsl             z1.h, p0/m, z1.h, z0.h
    st1h            {z1.h}, p0, [x0]
    add             x1, x1, #32
    add             x0, x0, x2, lsl #1
.endr
    ret
endfunc

function PFX(cpy1Dto2D_shl_32x32_sve2)
    dup             z0.h, w3
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_cpy1Dto2D_shl_32x32
    ptrue           p0.h, vl8
.rept 32
    ld1h            {z1.h}, p0/z, [x1]
    ld1h            {z2.h}, p0/z, [x1, #1, mul vl]
    ld1h            {z3.h}, p0/z, [x1, #2, mul vl]
    ld1h            {z4.h}, p0/z, [x1, #3, mul vl]
    lsl             z1.h, p0/m, z1.h, z0.h
    lsl             z2.h, p0/m, z2.h, z0.h
    lsl             z3.h, p0/m, z3.h, z0.h
    lsl             z4.h, p0/m, z4.h, z0.h
    st1h            {z1.h}, p0, [x0]
    st1h            {z2.h}, p0, [x0, #1, mul vl]
    st1h            {z3.h}, p0, [x0, #2, mul vl]
    st1h            {z4.h}, p0, [x0, #3, mul vl]
    add             x1, x1, #64
    add             x0, x0, x2, lsl #1
.endr
    ret
.vl_gt_16_cpy1Dto2D_shl_32x32:
    cmp             x9, #32
    bgt             .vl_gt_32_cpy1Dto2D_shl_32x32
    ptrue           p0.h, vl16
.rept 32
    ld1h            {z1.h}, p0/z, [x1]
    ld1h            {z2.h}, p0/z, [x1, #1, mul vl]
    lsl             z1.h, p0/m, z1.h, z0.h
    lsl             z2.h, p0/m, z2.h, z0.h
    st1h            {z1.h}, p0, [x0]
    st1h            {z2.h}, p0, [x0, #1, mul vl]
    add             x1, x1, #64
    add             x0, x0, x2, lsl #1
.endr
    ret
.vl_gt_32_cpy1Dto2D_shl_32x32:
    cmp             x9, #48
    bgt             .vl_gt_48_cpy1Dto2D_shl_32x32
    ptrue           p0.h, mul4
    ptrue           p1.h, vl8
.rept 32
    ld1h            {z1.h}, p0/z, [x1]
    ld1h            {z2.h}, p1/z, [x1, #1, mul vl]
    lsl             z1.h, p0/m, z1.h, z0.h
    lsl             z2.h, p1/m, z2.h, z0.h
    st1h            {z1.h}, p0, [x0]
    st1h            {z2.h}, p1, [x0, #1, mul vl]
    add             x1, x1, #64
    add             x0, x0, x2, lsl #1
.endr
    ret
.vl_gt_48_cpy1Dto2D_shl_32x32:
    ptrue           p0.h, vl32
.rept 32
    ld1h            {z1.h}, p0/z, [x1]
    lsl             z1.h, p0/m, z1.h, z0.h
    st1h            {z1.h}, p0, [x0]
    add             x1, x1, #64
    add             x0, x0, x2, lsl #1
.endr
    ret
endfunc

function PFX(cpy1Dto2D_shl_64x64_sve2)
    dup             z0.h, w3
    mov             x8, #64
    mov             w12, #64
.L_init_cpy1Dto2D_shl_64x64:
    sub             w12, w12, 1
    mov             x9, #0
    whilelt         p0.h, x9, x8
.L_cpy1Dto2D_shl_64x64:
    ld1h            {z1.h}, p0/z, [x1, x9, lsl #1]
    lsl             z1.h, p0/m, z1.h, z0.h
    st1h            {z1.h}, p0, [x0, x9, lsl #1]
    inch            x9
    whilelt         p0.h, x9, x8
    b.first         .L_cpy1Dto2D_shl_64x64
    addvl           x1, x1, #1
    add             x0, x0, x2, lsl #1
    cbnz            w12, .L_init_cpy1Dto2D_shl_64x64
    ret
endfunc

// void cpy1Dto2D_shr(int16_t* dst, const int16_t* src, intptr_t dstStride, int shift)

function PFX(cpy1Dto2D_shr_4x4_sve2)
    dup             z0.h, w3
    sub             w4, w3, #1
    dup             z1.h, w4
    ptrue           p0.h, vl8
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
    lsl             x2, x2, #1
    index           z3.d, #0, #8
    index           z4.d, #0, x2
.rept 2
    ld1d            {z5.d}, p0/z, [x1, z3.d]
    add             x1, x1, #16
    add             z5.h, p0/m, z5.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    st1d            {z5.d}, p0, [x0, z4.d]
    add             x0, x0, x2, lsl #1
.endr
    ret
endfunc

function PFX(cpy1Dto2D_shr_8x8_sve2)
    dup             z0.h, w3
    sub             w4, w3, #1
    dup             z1.h, w4
    ptrue           p0.h, vl8
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
.rept 8
    ld1d            {z5.d}, p0/z, [x1]
    add             x1, x1, #16
    add             z5.h, p0/m, z5.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    st1d            {z5.d}, p0, [x0]
    add             x0, x0, x2, lsl #1
.endr
    ret
endfunc

function PFX(cpy1Dto2D_shr_16x16_sve2)
    dup             z0.h, w3
    sub             w4, w3, #1
    dup             z1.h, w4
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_cpy1Dto2D_shr_16x16
    ptrue           p0.h, vl8
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
.rept 16
    ld1d            {z5.d}, p0/z, [x1]
    ld1d            {z6.d}, p0/z, [x1, #1, mul vl]
    add             x1, x1, #32
    add             z5.h, p0/m, z5.h, z2.h
    add             z6.h, p0/m, z6.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    asr             z6.h, p0/m, z6.h, z0.h
    st1d            {z5.d}, p0, [x0]
    st1d            {z6.d}, p0, [x0, #1, mul vl]
    add             x0, x0, x2, lsl #1
.endr
    ret
.vl_gt_16_cpy1Dto2D_shr_16x16:
    ptrue           p0.h, vl16
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
.rept 8
    ld1d            {z5.d}, p0/z, [x1]
    add             x1, x1, #32
    add             z5.h, p0/m, z5.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    st1d            {z5.d}, p0, [x0]
    add             x0, x0, x2, lsl #1
.endr
    ret
endfunc

function PFX(cpy1Dto2D_shr_32x32_sve2)
    dup             z0.h, w3
    sub             w4, w3, #1
    dup             z1.h, w4
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_cpy1Dto2D_shr_32x32
    ptrue           p0.h, vl8
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
.rept 32
    ld1d            {z5.d}, p0/z, [x1]
    ld1d            {z6.d}, p0/z, [x1, #1, mul vl]
    ld1d            {z7.d}, p0/z, [x1, #2, mul vl]
    ld1d            {z8.d}, p0/z, [x1, #3, mul vl]
    add             x1, x1, #64
    add             z5.h, p0/m, z5.h, z2.h
    add             z6.h, p0/m, z6.h, z2.h
    add             z7.h, p0/m, z7.h, z2.h
    add             z8.h, p0/m, z8.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    asr             z6.h, p0/m, z6.h, z0.h
    asr             z7.h, p0/m, z7.h, z0.h
    asr             z8.h, p0/m, z8.h, z0.h
    mov             x11, #2
    st1d            {z5.d}, p0, [x0]
    st1d            {z6.d}, p0, [x0, #1, mul vl]
    st1d            {z7.d}, p0, [x0, #2, mul vl]
    st1d            {z8.d}, p0, [x0, #3, mul vl]
    add             x0, x0, x2, lsl #1
.endr
    ret
.vl_gt_16_cpy1Dto2D_shr_32x32:
    cmp             x9, #48
    bgt             .vl_gt_48_cpy2Dto1D_shr_32x32
    ptrue           p0.h, vl16
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
.rept 32
    ld1d            {z5.d}, p0/z, [x1]
    ld1d            {z6.d}, p0/z, [x1, #1, mul vl]
    add             x1, x1, #64
    add             z5.h, p0/m, z5.h, z2.h
    add             z6.h, p0/m, z6.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    asr             z6.h, p0/m, z6.h, z0.h
    st1d            {z5.d}, p0, [x0]
    st1d            {z6.d}, p0, [x0, #1, mul vl]
    add             x0, x0, x2, lsl #1
.endr
    ret
.vl_gt_48_cpy1Dto2D_shr_32x32:
    ptrue           p0.h, vl32
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
.rept 32
    ld1d            {z5.d}, p0/z, [x1]
    add             x1, x1, #64
    add             z5.h, p0/m, z5.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    st1d            {z5.d}, p0, [x0]
    add             x0, x0, x2, lsl #1
.endr
    ret
endfunc

function PFX(cpy1Dto2D_shr_64x64_sve2)
    dup             z0.h, w3
    sub             w4, w3, #1
    dup             z1.h, w4
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_cpy1Dto2D_shr_64x64
    ptrue           p0.h, vl8
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
.rept 128
    ld1d            {z5.d}, p0/z, [x1]
    ld1d            {z6.d}, p0/z, [x1, #1, mul vl]
    ld1d            {z7.d}, p0/z, [x1, #2, mul vl]
    ld1d            {z8.d}, p0/z, [x1, #3, mul vl]
    ld1d            {z9.d}, p0/z, [x1, #4, mul vl]
    ld1d            {z10.d}, p0/z, [x1, #5, mul vl]
    ld1d            {z11.d}, p0/z, [x1, #6, mul vl]
    ld1d            {z12.d}, p0/z, [x1, #7, mul vl]
    add             x1, x1, #128
    add             z5.h, p0/m, z5.h, z2.h
    add             z6.h, p0/m, z6.h, z2.h
    add             z7.h, p0/m, z7.h, z2.h
    add             z8.h, p0/m, z8.h, z2.h
    add             z9.h, p0/m, z9.h, z2.h
    add             z10.h, p0/m, z10.h, z2.h
    add             z11.h, p0/m, z11.h, z2.h
    add             z12.h, p0/m, z12.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    asr             z6.h, p0/m, z6.h, z0.h
    asr             z7.h, p0/m, z7.h, z0.h
    asr             z8.h, p0/m, z8.h, z0.h
    asr             z9.h, p0/m, z9.h, z0.h
    asr             z10.h, p0/m, z10.h, z0.h
    asr             z11.h, p0/m, z11.h, z0.h
    asr             z12.h, p0/m, z12.h, z0.h
    st1d            {z5.d}, p0, [x0]
    st1d            {z6.d}, p0, [x0, #1, mul vl]
    st1d            {z7.d}, p0, [x0, #2, mul vl]
    st1d            {z8.d}, p0, [x0, #3, mul vl]
    st1d            {z9.d}, p0, [x0, #4, mul vl]
    st1d            {z10.d}, p0, [x0, #5, mul vl]
    st1d            {z11.d}, p0, [x0, #6, mul vl]
    st1d            {z12.d}, p0, [x0, #7, mul vl]
    add             x0, x0, x2, lsl #1
.endr
    ret
.vl_gt_16_cpy1Dto2D_shr_64x64:
    cmp             x9, #48
    bgt             .vl_gt_48_cpy1Dto2D_shr_64x64
    ptrue           p0.h, vl16
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
.rept 128
    ld1d            {z5.d}, p0/z, [x1]
    ld1d            {z6.d}, p0/z, [x1, #1, mul vl]
    ld1d            {z7.d}, p0/z, [x1, #2, mul vl]
    ld1d            {z8.d}, p0/z, [x1, #3, mul vl]
    add             x1, x1, #128
    add             z5.h, p0/m, z5.h, z2.h
    add             z6.h, p0/m, z6.h, z2.h
    add             z7.h, p0/m, z7.h, z2.h
    add             z8.h, p0/m, z8.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    asr             z6.h, p0/m, z6.h, z0.h
    asr             z7.h, p0/m, z7.h, z0.h
    asr             z8.h, p0/m, z8.h, z0.h
    st1d            {z5.d}, p0, [x0]
    st1d            {z6.d}, p0, [x0, #1, mul vl]
    st1d            {z7.d}, p0, [x0, #2, mul vl]
    st1d            {z8.d}, p0, [x0, #3, mul vl]
    add             x0, x0, x2, lsl #1
.endr
    ret
.vl_gt_48_cpy1Dto2D_shr_64x64:
    cmp             x9, #112
    bgt             .vl_gt_112_cpy1Dto2D_shr_64x64
    ptrue           p0.h, vl32
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
.rept 128
    ld1d            {z5.d}, p0/z, [x1]
    ld1d            {z6.d}, p0/z, [x1, #1, mul vl]
    add             x1, x1, #128
    add             z5.h, p0/m, z5.h, z2.h
    add             z6.h, p0/m, z6.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    asr             z6.h, p0/m, z6.h, z0.h
    st1d            {z5.d}, p0, [x0]
    st1d            {z6.d}, p0, [x0, #1, mul vl]
    add             x0, x0, x2, lsl #1
.endr
    ret
.vl_gt_112_cpy1Dto2D_shr_64x64:
    ptrue           p0.h, vl64
    mov             z2.h, #1
    lsl             z2.h, p0/m, z2.h, z1.h
.rept 128
    ld1d            {z5.d}, p0/z, [x1]
    add             x1, x1, #128
    add             z5.h, p0/m, z5.h, z2.h
    asr             z5.h, p0/m, z5.h, z0.h
    st1d            {z5.d}, p0, [x0]
    add             x0, x0, x2, lsl #1
.endr
    ret
endfunc

const xtn_xtn2_table, align=4
.byte    0, 2, 4, 6, 8, 10, 12, 14
.byte    16, 18, 20, 22, 24, 26, 28, 30
endconst