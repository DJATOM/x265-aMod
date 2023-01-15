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

#if HIGH_BIT_DEPTH
# if BIT_DEPTH == 10
#  define P2S_SHIFT 4
# elif BIT_DEPTH == 12
#  define P2S_SHIFT 2
# endif
.macro p2s_start
    add             x3, x3, x3
    add             x1, x1, x1
    movi            v31.8h, #0xe0, lsl #8
.endm

.macro p2s_start_sve2
    add             x3, x3, x3
    add             x1, x1, x1
    mov             z31.h, #0xe0, lsl #8
.endm

#else // if !HIGH_BIT_DEPTH
# define P2S_SHIFT 6
.macro p2s_start
    add             x3, x3, x3
    movi            v31.8h, #0xe0, lsl #8
.endm
.macro p2s_start_sve2
    add             x3, x3, x3
    mov             z31.h, #0xe0, lsl #8
.endm

#endif // HIGH_BIT_DEPTH

// The SVE2 version of the following code deteriorates
// the performance. So, its NEON version is used instead.
.macro p2s_2x2
#if HIGH_BIT_DEPTH
    ld1             {v0.s}[0], [x0], x1
    ld1             {v0.s}[1], [x0], x1
    shl             v3.8h, v0.8h, #P2S_SHIFT
#else
    ldrh            w10, [x0]
    add             x0, x0, x1
    ldrh            w11, [x0]
    orr             w10, w10, w11, lsl #16
    add             x0, x0, x1
    dup             v0.4s, w10
    ushll           v3.8h, v0.8b, #P2S_SHIFT
#endif
    add             v3.8h, v3.8h, v31.8h
    st1             {v3.s}[0], [x2], x3
    st1             {v3.s}[1], [x2], x3
.endm

// ################ NEON ######################

// filterPixelToShort(const pixel* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride)
.macro p2s_2xN_neon h
function PFX(filterPixelToShort_2x\h\()_neon)
    p2s_start
.rept \h / 2
    p2s_2x2
.endr
    ret
endfunc
.endm

p2s_2xN_neon 4
p2s_2xN_neon 8
p2s_2xN_neon 16

.macro p2s_6x2_neon
#if HIGH_BIT_DEPTH
    ld1             {v0.d}[0], [x0], #8
    ld1             {v1.s}[0], [x0], x1
    ld1             {v0.d}[1], [x0], #8
    ld1             {v1.s}[1], [x0], x1
    shl             v3.8h, v0.8h, #P2S_SHIFT
    shl             v4.8h, v1.8h, #P2S_SHIFT
#else
    ldr             s0, [x0]
    ldrh            w10, [x0, #4]
    add             x0, x0, x1
    ld1             {v0.s}[1], [x0]
    ldrh            w11, [x0, #4]
    add             x0, x0, x1
    orr             w10, w10, w11, lsl #16
    dup             v1.4s, w10
    ushll           v3.8h, v0.8b, #P2S_SHIFT
    ushll           v4.8h, v1.8b, #P2S_SHIFT
#endif
    add             v3.8h, v3.8h, v31.8h
    add             v4.8h, v4.8h, v31.8h
    st1             {v3.d}[0], [x2], #8
    st1             {v4.s}[0], [x2], x3
    st1             {v3.d}[1], [x2], #8
    st1             {v4.s}[1], [x2], x3
.endm

.macro p2s_6xN_neon h
function PFX(filterPixelToShort_6x\h\()_neon)
    p2s_start
    sub             x3, x3, #8
#if HIGH_BIT_DEPTH
    sub             x1, x1, #8
#endif
.rept \h / 2
    p2s_6x2_neon
.endr
    ret
endfunc
.endm

p2s_6xN_neon 8
p2s_6xN_neon 16

function PFX(filterPixelToShort_4x2_neon)
    p2s_start
#if HIGH_BIT_DEPTH
    ld1             {v0.d}[0], [x0], x1
    ld1             {v0.d}[1], [x0], x1
    shl             v3.8h, v0.8h, #P2S_SHIFT
#else
    ld1             {v0.s}[0], [x0], x1
    ld1             {v0.s}[1], [x0], x1
    ushll           v3.8h, v0.8b, #P2S_SHIFT
#endif
    add             v3.8h, v3.8h, v31.8h
    st1             {v3.d}[0], [x2], x3
    st1             {v3.d}[1], [x2], x3
    ret
endfunc

function PFX(filterPixelToShort_4x4_neon)
    p2s_start
#if HIGH_BIT_DEPTH
    ld1             {v0.d}[0], [x0], x1
    ld1             {v0.d}[1], [x0], x1
    shl             v3.8h, v0.8h, #P2S_SHIFT
#else
    ld1             {v0.s}[0], [x0], x1
    ld1             {v0.s}[1], [x0], x1
    ushll           v3.8h, v0.8b, #P2S_SHIFT
#endif
    add             v3.8h, v3.8h, v31.8h
    st1             {v3.d}[0], [x2], x3
    st1             {v3.d}[1], [x2], x3
#if HIGH_BIT_DEPTH
    ld1             {v1.d}[0], [x0], x1
    ld1             {v1.d}[1], [x0], x1
    shl             v4.8h, v1.8h, #P2S_SHIFT
#else
    ld1             {v1.s}[0], [x0], x1
    ld1             {v1.s}[1], [x0], x1
    ushll           v4.8h, v1.8b, #P2S_SHIFT
#endif
    add             v4.8h, v4.8h, v31.8h
    st1             {v4.d}[0], [x2], x3
    st1             {v4.d}[1], [x2], x3
    ret
endfunc

.macro p2s_4xN_neon h
function PFX(filterPixelToShort_4x\h\()_neon)
    p2s_start
.rept \h / 2
#if HIGH_BIT_DEPTH
    ld1             {v0.16b}, [x0], x1
    shl             v0.8h, v0.8h, #P2S_SHIFT
#else
    ld1             {v0.8b}, [x0], x1
    ushll           v0.8h, v0.8b, #P2S_SHIFT
#endif
    add             v2.4h, v0.4h, v31.4h
    st1             {v2.4h}, [x2], x3
#if HIGH_BIT_DEPTH
    ld1             {v1.16b}, [x0], x1
    shl             v1.8h, v1.8h, #P2S_SHIFT
#else
    ld1             {v1.8b}, [x0], x1
    ushll           v1.8h, v1.8b, #P2S_SHIFT
#endif
    add             v3.4h, v1.4h, v31.4h
    st1             {v3.4h}, [x2], x3
.endr
    ret
endfunc
.endm

p2s_4xN_neon 8
p2s_4xN_neon 16
p2s_4xN_neon 32

.macro p2s_8xN_neon h
function PFX(filterPixelToShort_8x\h\()_neon)
    p2s_start
.rept \h / 2
#if HIGH_BIT_DEPTH
    ld1             {v0.16b}, [x0], x1
    ld1             {v1.16b}, [x0], x1
    shl             v0.8h, v0.8h, #P2S_SHIFT
    shl             v1.8h, v1.8h, #P2S_SHIFT
#else
    ld1             {v0.8b}, [x0], x1
    ld1             {v1.8b}, [x0], x1
    ushll           v0.8h, v0.8b, #P2S_SHIFT
    ushll           v1.8h, v1.8b, #P2S_SHIFT
#endif
    add             v2.8h, v0.8h, v31.8h
    st1             {v2.8h}, [x2], x3
    add             v3.8h, v1.8h, v31.8h
    st1             {v3.8h}, [x2], x3
.endr
    ret
endfunc
.endm

p2s_8xN_neon 2
p2s_8xN_neon 4
p2s_8xN_neon 6
p2s_8xN_neon 8
p2s_8xN_neon 12
p2s_8xN_neon 16
p2s_8xN_neon 32
p2s_8xN_neon 64

.macro p2s_12xN_neon h
function PFX(filterPixelToShort_12x\h\()_neon)
    p2s_start
    sub             x3, x3, #16
.rept \h
#if HIGH_BIT_DEPTH
    ld1             {v0.16b-v1.16b}, [x0], x1
    shl             v2.8h, v0.8h, #P2S_SHIFT
    shl             v3.8h, v1.8h, #P2S_SHIFT
#else
    ld1             {v0.16b}, [x0], x1
    ushll           v2.8h, v0.8b,  #P2S_SHIFT
    ushll2          v3.8h, v0.16b, #P2S_SHIFT
#endif
    add             v2.8h, v2.8h, v31.8h
    add             v3.8h, v3.8h, v31.8h
    st1             {v2.16b}, [x2], #16
    st1             {v3.8b}, [x2], x3
.endr
    ret
endfunc
.endm

p2s_12xN_neon 16
p2s_12xN_neon 32

.macro p2s_16xN_neon h
function PFX(filterPixelToShort_16x\h\()_neon)
    p2s_start
.rept \h
#if HIGH_BIT_DEPTH
    ld1             {v0.16b-v1.16b}, [x0], x1
    shl             v2.8h, v0.8h, #P2S_SHIFT
    shl             v3.8h, v1.8h, #P2S_SHIFT
#else
    ld1             {v0.16b}, [x0], x1
    ushll           v2.8h, v0.8b,  #P2S_SHIFT
    ushll2          v3.8h, v0.16b, #P2S_SHIFT
#endif
    add             v2.8h, v2.8h, v31.8h
    add             v3.8h, v3.8h, v31.8h
    st1             {v2.16b-v3.16b}, [x2], x3
.endr
    ret
endfunc
.endm

p2s_16xN_neon 4
p2s_16xN_neon 8
p2s_16xN_neon 12
p2s_16xN_neon 16
p2s_16xN_neon 24
p2s_16xN_neon 32
p2s_16xN_neon 64

.macro p2s_24xN_neon h
function PFX(filterPixelToShort_24x\h\()_neon)
    p2s_start
.rept \h
#if HIGH_BIT_DEPTH
    ld1             {v0.16b-v2.16b}, [x0], x1
    shl             v3.8h, v0.8h, #P2S_SHIFT
    shl             v4.8h, v1.8h, #P2S_SHIFT
    shl             v5.8h, v2.8h, #P2S_SHIFT
#else
    ld1             {v0.8b-v2.8b}, [x0], x1
    ushll           v3.8h, v0.8b, #P2S_SHIFT
    ushll           v4.8h, v1.8b, #P2S_SHIFT
    ushll           v5.8h, v2.8b, #P2S_SHIFT
#endif
    add             v3.8h, v3.8h, v31.8h
    add             v4.8h, v4.8h, v31.8h
    add             v5.8h, v5.8h, v31.8h
    st1             {v3.16b-v5.16b}, [x2], x3
.endr
    ret
endfunc
.endm

p2s_24xN_neon 32
p2s_24xN_neon 64

.macro p2s_32xN_neon h
function PFX(filterPixelToShort_32x\h\()_neon)
    p2s_start
    mov             x9, #\h
.loop_filterP2S_32x\h:
    sub             x9, x9, #1
#if HIGH_BIT_DEPTH
    ld1             {v0.16b-v3.16b}, [x0], x1
    shl             v22.8h, v0.8h, #P2S_SHIFT
    shl             v23.8h, v1.8h, #P2S_SHIFT
    shl             v24.8h, v2.8h, #P2S_SHIFT
    shl             v25.8h, v3.8h, #P2S_SHIFT
#else
    ld1             {v0.16b-v1.16b}, [x0], x1
    ushll           v22.8h, v0.8b,  #P2S_SHIFT
    ushll2          v23.8h, v0.16b, #P2S_SHIFT
    ushll           v24.8h, v1.8b,  #P2S_SHIFT
    ushll2          v25.8h, v1.16b, #P2S_SHIFT
#endif
    add             v22.8h, v22.8h, v31.8h
    add             v23.8h, v23.8h, v31.8h
    add             v24.8h, v24.8h, v31.8h
    add             v25.8h, v25.8h, v31.8h
    st1             {v22.16b-v25.16b}, [x2], x3
    cbnz            x9, .loop_filterP2S_32x\h
    ret
endfunc
.endm

p2s_32xN_neon 8
p2s_32xN_neon 16
p2s_32xN_neon 24
p2s_32xN_neon 32
p2s_32xN_neon 48
p2s_32xN_neon 64

.macro p2s_64xN_neon h
function PFX(filterPixelToShort_64x\h\()_neon)
    p2s_start
#if HIGH_BIT_DEPTH
    sub             x1, x1, #64
#endif
    sub             x3, x3, #64
    mov             x9, #\h
.loop_filterP2S_64x\h:
    sub             x9, x9, #1
#if HIGH_BIT_DEPTH
    ld1             {v0.16b-v3.16b}, [x0], #64
    ld1             {v4.16b-v7.16b}, [x0], x1
    shl             v16.8h, v0.8h, #P2S_SHIFT
    shl             v17.8h, v1.8h, #P2S_SHIFT
    shl             v18.8h, v2.8h, #P2S_SHIFT
    shl             v19.8h, v3.8h, #P2S_SHIFT
    shl             v20.8h, v4.8h, #P2S_SHIFT
    shl             v21.8h, v5.8h, #P2S_SHIFT
    shl             v22.8h, v6.8h, #P2S_SHIFT
    shl             v23.8h, v7.8h, #P2S_SHIFT
#else
    ld1             {v0.16b-v3.16b}, [x0], x1
    ushll           v16.8h, v0.8b,  #P2S_SHIFT
    ushll2          v17.8h, v0.16b, #P2S_SHIFT
    ushll           v18.8h, v1.8b,  #P2S_SHIFT
    ushll2          v19.8h, v1.16b, #P2S_SHIFT
    ushll           v20.8h, v2.8b,  #P2S_SHIFT
    ushll2          v21.8h, v2.16b, #P2S_SHIFT
    ushll           v22.8h, v3.8b,  #P2S_SHIFT
    ushll2          v23.8h, v3.16b, #P2S_SHIFT
#endif
    add             v16.8h, v16.8h, v31.8h
    add             v17.8h, v17.8h, v31.8h
    add             v18.8h, v18.8h, v31.8h
    add             v19.8h, v19.8h, v31.8h
    add             v20.8h, v20.8h, v31.8h
    add             v21.8h, v21.8h, v31.8h
    add             v22.8h, v22.8h, v31.8h
    add             v23.8h, v23.8h, v31.8h
    st1             {v16.16b-v19.16b}, [x2], #64
    st1             {v20.16b-v23.16b}, [x2], x3
    cbnz            x9, .loop_filterP2S_64x\h
    ret
endfunc
.endm

p2s_64xN_neon 16
p2s_64xN_neon 32
p2s_64xN_neon 48
p2s_64xN_neon 64

function PFX(filterPixelToShort_48x64_neon)
    p2s_start
#if HIGH_BIT_DEPTH
    sub             x1, x1, #64
#endif
    sub             x3, x3, #64
    mov             x9, #64
.loop_filterP2S_48x64:
    sub            x9, x9, #1
#if HIGH_BIT_DEPTH
    ld1             {v0.16b-v3.16b}, [x0], #64
    ld1             {v4.16b-v5.16b}, [x0], x1
    shl             v16.8h, v0.8h, #P2S_SHIFT
    shl             v17.8h, v1.8h, #P2S_SHIFT
    shl             v18.8h, v2.8h, #P2S_SHIFT
    shl             v19.8h, v3.8h, #P2S_SHIFT
    shl             v20.8h, v4.8h, #P2S_SHIFT
    shl             v21.8h, v5.8h, #P2S_SHIFT
#else
    ld1             {v0.16b-v2.16b}, [x0], x1
    ushll           v16.8h, v0.8b,  #P2S_SHIFT
    ushll2          v17.8h, v0.16b, #P2S_SHIFT
    ushll           v18.8h, v1.8b,  #P2S_SHIFT
    ushll2          v19.8h, v1.16b, #P2S_SHIFT
    ushll           v20.8h, v2.8b,  #P2S_SHIFT
    ushll2          v21.8h, v2.16b, #P2S_SHIFT
#endif
    add             v16.8h, v16.8h, v31.8h
    add             v17.8h, v17.8h, v31.8h
    add             v18.8h, v18.8h, v31.8h
    add             v19.8h, v19.8h, v31.8h
    add             v20.8h, v20.8h, v31.8h
    add             v21.8h, v21.8h, v31.8h
    st1             {v16.16b-v19.16b}, [x2], #64
    st1             {v20.16b-v21.16b}, [x2], x3
    cbnz            x9, .loop_filterP2S_48x64
    ret
endfunc

// ##################### SVE2 #####################

// filterPixelToShort(const pixel* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride)
.macro p2s_2xN_sve2 h
function PFX(filterPixelToShort_2x\h\()_sve2)
     p2s_start_sve2
.rept \h / 2
    p2s_2x2
.endr
    ret
endfunc
.endm

p2s_2xN_sve2 4
p2s_2xN_sve2 8
p2s_2xN_sve2 16

// The SVE2 version of the following code deteriorates
// the performance. So, its NEON version is used instead.
.macro p2s_6x2_sve2
#if HIGH_BIT_DEPTH
    ld1             {v0.d}[0], [x0], #8
    ld1             {v1.s}[0], [x0], x1
    ld1             {v0.d}[1], [x0], #8
    ld1             {v1.s}[1], [x0], x1
    shl             v3.8h, v0.8h, #P2S_SHIFT
    shl             v4.8h, v1.8h, #P2S_SHIFT
#else
    ldr             s0, [x0]
    ldrh            w10, [x0, #4]
    add             x0, x0, x1
    ld1             {v0.s}[1], [x0]
    ldrh            w11, [x0, #4]
    add             x0, x0, x1
    orr             w10, w10, w11, lsl #16
    dup             v1.4s, w10
    ushll           v3.8h, v0.8b, #P2S_SHIFT
    ushll           v4.8h, v1.8b, #P2S_SHIFT
#endif
    add             v3.8h, v3.8h, v31.8h
    add             v4.8h, v4.8h, v31.8h
    st1             {v3.d}[0], [x2], #8
    st1             {v4.s}[0], [x2], x3
    st1             {v3.d}[1], [x2], #8
    st1             {v4.s}[1], [x2], x3
.endm

.macro p2s_6xN_sve2 h
function PFX(filterPixelToShort_6x\h\()_sve2)
    p2s_start_sve2
    sub             x3, x3, #8
#if HIGH_BIT_DEPTH
    sub             x1, x1, #8
#endif
.rept \h / 2
    p2s_6x2_sve2
.endr
    ret
endfunc
.endm

p2s_6xN_sve2 8
p2s_6xN_sve2 16

function PFX(filterPixelToShort_4x2_sve2)
    p2s_start_sve2
#if HIGH_BIT_DEPTH
    ptrue           p0.h, vl8
    index           z1.d, #0, x1
    index           z2.d, #0, x3
    ld1d            {z3.d}, p0/z, [x0, z1.d]
    lsl             z3.h, p0/m, z3.h, #P2S_SHIFT
    add             z3.h, p0/m, z3.h, z31.h
    st1d            {z3.d}, p0, [x2, z2.d]
#else
    ptrue           p0.h, vl4
    ld1b            {z0.h}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z1.h}, p0/z, [x0]
    lsl             z0.h, p0/m, z0.h, #P2S_SHIFT
    lsl             z1.h, p0/m, z1.h, #P2S_SHIFT
    add             z0.h, p0/m, z0.h, z31.h
    add             z1.h, p0/m, z1.h, z31.h
    st1h            {z0.h}, p0, [x2]
    add             x2, x2, x3
    st1h            {z1.h}, p0, [x2]
#endif
    ret
endfunc

function PFX(filterPixelToShort_4x4_sve2)
    p2s_start_sve2
#if HIGH_BIT_DEPTH
    ptrue           p0.h, vl8
    index           z1.d, #0, x1
    index           z2.d, #0, x3
.rept 2
    ld1d            {z3.d}, p0/z, [x0, z1.d]
    add             x0, x0, x1, lsl #1
    lsl             z3.h, p0/m, z3.h, #P2S_SHIFT
    add             z3.h, p0/m, z3.h, z31.h
    st1d            {z3.d}, p0, [x2, z2.d]
    add             x2, x2, x3, lsl #1
.endr
#else
    ptrue           p0.h, vl4
.rept 2
    ld1b            {z0.h}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z1.h}, p0/z, [x0]
    add             x0, x0, x1
    lsl             z0.h, p0/m, z0.h, #P2S_SHIFT
    lsl             z1.h, p0/m, z1.h, #P2S_SHIFT
    add             z0.h, p0/m, z0.h, z31.h
    add             z1.h, p0/m, z1.h, z31.h
    st1h            {z0.h}, p0, [x2]
    add             x2, x2, x3
    st1h            {z1.h}, p0, [x2]
    add             x2, x2, x3
.endr
#endif
    ret
endfunc

.macro p2s_4xN_sve2 h
function PFX(filterPixelToShort_4x\h\()_sve2)
    p2s_start_sve2
    ptrue           p0.h, vl4
.rept \h
#if HIGH_BIT_DEPTH
    ld1d            {z0.d}, p0/z, [x0]
    add             x0, x0, x1
    lsl             z0.h, p0/m, z0.h, #P2S_SHIFT
    add             z0.h, p0/m, z0.h, z31.h
    st1h            {z0.h}, p0, [x2]
    add             x2, x2, x3
#else
    ld1b            {z0.h}, p0/z, [x0]
    add             x0, x0, x1
    lsl             z0.h, p0/m, z0.h, #P2S_SHIFT
    add             z0.h, p0/m, z0.h, z31.h
    st1h            {z0.h}, p0, [x2]
    add             x2, x2, x3
#endif
.endr
    ret
endfunc
.endm

p2s_4xN_sve2 8
p2s_4xN_sve2 16
p2s_4xN_sve2 32

.macro p2s_8xN_sve2 h
function PFX(filterPixelToShort_8x\h\()_sve2)
    p2s_start_sve2
    ptrue           p0.h, vl8
.rept \h
#if HIGH_BIT_DEPTH
    ld1d            {z0.d}, p0/z, [x0]
    add             x0, x0, x1
    lsl             z0.h, p0/m, z0.h, #P2S_SHIFT
    add             z0.h, p0/m, z0.h, z31.h
    st1h            {z0.h}, p0, [x2]
    add             x2, x2, x3
#else
    ld1b            {z0.h}, p0/z, [x0]
    add             x0, x0, x1
    lsl             z0.h, p0/m, z0.h, #P2S_SHIFT
    add             z0.h, p0/m, z0.h, z31.h
    st1h            {z0.h}, p0, [x2]
    add             x2, x2, x3
#endif
.endr
    ret
endfunc
.endm

p2s_8xN_sve2 2
p2s_8xN_sve2 4
p2s_8xN_sve2 6
p2s_8xN_sve2 8
p2s_8xN_sve2 12
p2s_8xN_sve2 16
p2s_8xN_sve2 32
p2s_8xN_sve2 64

.macro p2s_12xN_sve2 h
function PFX(filterPixelToShort_12x\h\()_sve2)
    p2s_start_sve2
    ptrue           p0.h, vl8
    ptrue           p1.h, vl4
    mov             x11, #8
.rept \h
#if HIGH_BIT_DEPTH
    ld1h            {z0.h}, p0/z, [x0]
    ld1h            {z1.h}, p0/z, [x0, x11, lsl #1]
    add             x0, x0, x1
    lsl             z0.h, p0/m, z0.h, #P2S_SHIFT
    lsl             z1.h, p0/m, z1.h, #P2S_SHIFT
    add             z0.h, p0/m, z0.h, z31.h
    add             z1.h, p0/m, z1.h, z31.h
    st1h            {z0.h}, p0, [x2]
    st1h            {z1.h}, p1, [x2, x11, lsl #1]
    add             x2, x2, x3
#else
    ld1h            {z0.h}, p0/z, [x0]
    add             x0, x0, x1
    uunpklo         z1.h, z0.b
    uunpkhi         z2.h, z0.b
    lsl             z1.h, p0/m, z1.h, #P2S_SHIFT
    lsl             z2.h, p0/m, z2.h, #P2S_SHIFT
    add             z1.h, p0/m, z1.h, z31.h
    add             z2.h, p0/m, z2.h, z31.h
    st1h            {z1.h}, p0, [x2]
    st1h            {z2.h}, p1, [x2, x11, lsl #1]
    add             x2, x2, x3
#endif
.endr
    ret
endfunc
.endm

p2s_12xN_sve2 16
p2s_12xN_sve2 32

.macro p2s_16xN_sve2 h
function PFX(filterPixelToShort_16x\h\()_sve2)
    p2s_start_sve2
#if HIGH_BIT_DEPTH
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_filterPixelToShort_high_16x\h
    ptrue           p0.h, vl8
    mov             x11, #8
.rept \h
    ld1h            {z0.h}, p0/z, [x0]
    ld1h            {z1.h}, p0/z, [x0, x11, lsl #1]
    add             x0, x0, x1
    lsl             z0.h, p0/m, z0.h, #P2S_SHIFT
    lsl             z1.h, p0/m, z1.h, #P2S_SHIFT
    add             z0.h, p0/m, z0.h, z31.h
    add             z1.h, p0/m, z1.h, z31.h
    st1h            {z0.h}, p0, [x2]
    st1h            {z1.h}, p0, [x2, x11, lsl #1]
    add             x2, x2, x3
.endr
    ret
.vl_gt_16_filterPixelToShort_high_16x\h\():
    ptrue           p0.h, vl16
.rept \h
    ld1h            {z0.h}, p0/z, [x0]
    add             x0, x0, x1
    lsl             z0.h, p0/m, z0.h, #P2S_SHIFT
    add             z0.h, p0/m, z0.h, z31.h
    st1h            {z0.h}, p0, [x2]
    add             x2, x2, x3
.endr
    ret
#else
    ptrue           p0.h, vl8
    mov             x11, #8
.rept \h
    ld1h            {z0.h}, p0/z, [x0]
    add             x0, x0, x1
    uunpklo         z1.h, z0.b
    uunpkhi         z2.h, z0.b
    lsl             z1.h, p0/m, z1.h, #P2S_SHIFT
    lsl             z2.h, p0/m, z2.h, #P2S_SHIFT
    add             z1.h, p0/m, z1.h, z31.h
    add             z2.h, p0/m, z2.h, z31.h
    st1h            {z1.h}, p0, [x2]
    st1h            {z2.h}, p0, [x2, x11, lsl #1]
    add             x2, x2, x3
.endr
    ret
#endif
endfunc
.endm

p2s_16xN_sve2 4
p2s_16xN_sve2 8
p2s_16xN_sve2 12
p2s_16xN_sve2 16
p2s_16xN_sve2 24
p2s_16xN_sve2 32
p2s_16xN_sve2 64

.macro p2s_24xN_sve2 h
function PFX(filterPixelToShort_24x\h\()_sve2)
    p2s_start_sve2
#if HIGH_BIT_DEPTH
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_filterPixelToShort_high_24x\h
    ptrue           p0.h, vl8
    mov             x11, #8
    mov             x12, #16
.rept \h
    ld1h            {z0.h}, p0/z, [x0]
    ld1h            {z1.h}, p0/z, [x0, x11, lsl #1]
    ld1h            {z2.h}, p0/z, [x0, x12, lsl #1]
    add             x0, x0, x1
    lsl             z0.h, p0/m, z0.h, #P2S_SHIFT
    lsl             z1.h, p0/m, z1.h, #P2S_SHIFT
    lsl             z2.h, p0/m, z2.h, #P2S_SHIFT
    add             z0.h, p0/m, z0.h, z31.h
    add             z1.h, p0/m, z1.h, z31.h
    add             z2.h, p0/m, z2.h, z31.h
    st1h            {z0.h}, p0, [x2]
    st1h            {z1.h}, p0, [x2, x11, lsl #1]
    st1h            {z2.h}, p0, [x2, x12, lsl #1]
    add             x2, x2, x3
.endr
    ret
.vl_gt_16_filterPixelToShort_high_24x\h\():
    mov             w12, #\h
    mov             x8, #24
.vl_gt_16_filterPixelToShort_high_24_outx\h\():
    sub             w12, w12, #1
    mov             x9, #0
    whilelt         p0.h, x9, x8
.vl_gt_16_filterPixelToShort_high_24_innerx\h\():
    ld1h            {z0.h}, p0/z, [x0, x9, lsl #1]
    lsl             z0.h, p0/m, z0.h, #P2S_SHIFT
    add             z0.h, p0/m, z0.h, z31.h
    st1h            {z0.h}, p0, [x0, x9, lsl #1]
    inch            x9
    whilelt         p0.h, x9, x8
    b.first         .vl_gt_16_filterPixelToShort_high_24_innerx\h
    add             x2, x2, x3
    add             x0, x0, x1
    cbnz            w12, .vl_gt_16_filterPixelToShort_high_24_outx\h
    ret
#else
    // No gain here if you take into account vector
    // sizes greater than 128, as ptrues cannot be
    // perfectly adjusted
    ptrue           p0.h, vl8
    ptrue           p1.h, vl4
    mov             x11, #8
    mov             x12, #16
.rept \h
    ld1h            {z0.h}, p0/z, [x0]
    ld1h            {z1.h}, p1/z, [x0, x11, lsl #1]
    add             x0, x0, x1
    uunpklo         z2.h, z0.b
    uunpkhi         z3.h, z0.b
    uunpklo         z4.h, z1.b
    lsl             z2.h, p0/m, z2.h, #P2S_SHIFT
    lsl             z3.h, p0/m, z3.h, #P2S_SHIFT
    lsl             z4.h, p0/m, z4.h, #P2S_SHIFT
    add             z2.h, p0/m, z2.h, z31.h
    add             z3.h, p0/m, z3.h, z31.h
    add             z4.h, p0/m, z4.h, z31.h
    st1h            {z2.h}, p0, [x2]
    st1h            {z3.h}, p0, [x2, x11, lsl #1]
    st1h            {z4.h}, p0, [x2, x12, lsl #1]
    add             x2, x2, x3
.endr
    ret
#endif
endfunc
.endm

p2s_24xN_sve2 32
p2s_24xN_sve2 64

.macro p2s_32xN_sve2 h
function PFX(filterPixelToShort_32x\h\()_sve2)
    p2s_start_sve2
#if HIGH_BIT_DEPTH
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_filterPixelToShort_high_32x\h
    ptrue           p0.h, vl8
    mov             x11, #8
    mov             x12, #16
    mov             x13, #24
.rept \h
    ld1h            {z0.h}, p0/z, [x0]
    ld1h            {z1.h}, p0/z, [x0, x11, lsl #1]
    ld1h            {z2.h}, p0/z, [x0, x12, lsl #1]
    ld1h            {z3.h}, p0/z, [x0, x13, lsl #1]
    add             x0, x0, x1
    lsl             z0.h, p0/m, z0.h, #P2S_SHIFT
    lsl             z1.h, p0/m, z1.h, #P2S_SHIFT
    lsl             z2.h, p0/m, z2.h, #P2S_SHIFT
    lsl             z3.h, p0/m, z3.h, #P2S_SHIFT
    add             z0.h, p0/m, z0.h, z31.h
    add             z1.h, p0/m, z1.h, z31.h
    add             z2.h, p0/m, z2.h, z31.h
    add             z3.h, p0/m, z3.h, z31.h
    st1h            {z0.h}, p0, [x2]
    st1h            {z1.h}, p0, [x2, x11, lsl #1]
    st1h            {z2.h}, p0, [x2, x12, lsl #1]
    st1h            {z3.h}, p0, [x2, x13, lsl #1]
    add             x2, x2, x3
.endr
    ret
.vl_gt_16_filterPixelToShort_high_32x\h\():
    mov             w12, #\h
    mov             x8, #32
.vl_gt_16_filterPixelToShort_high_32_outx\h\():
    sub             w12, w12, #1
    mov             x9, #0
    whilelt         p0.h, x9, x8
.vl_gt_16_filterPixelToShort_high_32_innerx\h\():
    ld1h            {z0.h}, p0/z, [x0, x9, lsl #1]
    lsl             z0.h, p0/m, z0.h, #P2S_SHIFT
    add             z0.h, p0/m, z0.h, z31.h
    st1h            {z0.h}, p0, [x0, x9, lsl #1]
    inch            x9
    whilelt         p0.h, x9, x8
    b.first         .vl_gt_16_filterPixelToShort_high_32_innerx\h
    add             x2, x2, x3
    add             x0, x0, x1
    cbnz            w12, .vl_gt_16_filterPixelToShort_high_32_outx\h
    ret
#else
    mov             w12, #\h
    mov             x8, #16
.vl_gt_16_filterPixelToShort_32_outx\h\():
    sub             w12, w12, #1
    mov             x9, #0
    mov             x10, #0
    whilelt         p0.h, x9, x8
.vl_gt_16_filterPixelToShort_32_innerx\h\():
    ld1h            {z0.h}, p0/z, [x0, x9, lsl #1]
    uunpklo         z2.h, z0.b
    uunpkhi         z3.h, z0.b
    lsl             z2.h, p0/m, z2.h, #P2S_SHIFT
    lsl             z3.h, p0/m, z3.h, #P2S_SHIFT
    add             z2.h, p0/m, z2.h, z31.h
    add             z3.h, p0/m, z3.h, z31.h
    st1h            {z2.h}, p0, [x2, x10, lsl #1]
    inch            x10
    st1h            {z3.h}, p0, [x2, x10, lsl #1]
    inch            x10
    inch            x9
    whilelt         p0.h, x9, x8
    b.first         .vl_gt_16_filterPixelToShort_32_innerx\h
    add             x2, x2, x3
    add             x0, x0, x1
    cbnz            w12, .vl_gt_16_filterPixelToShort_32_outx\h
    ret
#endif
endfunc
.endm

p2s_32xN_sve2 8
p2s_32xN_sve2 16
p2s_32xN_sve2 24
p2s_32xN_sve2 32
p2s_32xN_sve2 48
p2s_32xN_sve2 64

.macro p2s_64xN_sve2 h
function PFX(filterPixelToShort_64x\h\()_sve2)
    p2s_start_sve2
#if HIGH_BIT_DEPTH
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_filterPixelToShort_high_64x\h
    ptrue           p0.h, vl8
    mov             x10, #8
    mov             x11, #16
    mov             x12, #24
    mov             x13, #32
    mov             x14, #40
    mov             x15, #48
    mov             x16, #56
.rept \h
    ld1h            {z0.h}, p0/z, [x0]
    ld1h            {z1.h}, p0/z, [x0, x10, lsl #1]
    ld1h            {z2.h}, p0/z, [x0, x11, lsl #1]
    ld1h            {z3.h}, p0/z, [x0, x12, lsl #1]
    ld1h            {z4.h}, p0/z, [x0, x13, lsl #1]
    ld1h            {z5.h}, p0/z, [x0, x14, lsl #1]
    ld1h            {z6.h}, p0/z, [x0, x15, lsl #1]
    ld1h            {z7.h}, p0/z, [x0, x16, lsl #1]
    add             x0, x0, x1
    lsl             z0.h, p0/m, z0.h, #P2S_SHIFT
    lsl             z1.h, p0/m, z1.h, #P2S_SHIFT
    lsl             z2.h, p0/m, z2.h, #P2S_SHIFT
    lsl             z3.h, p0/m, z3.h, #P2S_SHIFT
    lsl             z4.h, p0/m, z4.h, #P2S_SHIFT
    lsl             z5.h, p0/m, z5.h, #P2S_SHIFT
    lsl             z6.h, p0/m, z6.h, #P2S_SHIFT
    lsl             z7.h, p0/m, z7.h, #P2S_SHIFT
    add             z0.h, p0/m, z0.h, z31.h
    add             z1.h, p0/m, z1.h, z31.h
    add             z2.h, p0/m, z2.h, z31.h
    add             z3.h, p0/m, z3.h, z31.h
    add             z4.h, p0/m, z4.h, z31.h
    add             z5.h, p0/m, z5.h, z31.h
    add             z6.h, p0/m, z6.h, z31.h
    add             z7.h, p0/m, z7.h, z31.h
    st1h            {z0.h}, p0, [x2]
    st1h            {z1.h}, p0, [x2, x10, lsl #1]
    st1h            {z2.h}, p0, [x2, x11, lsl #1]
    st1h            {z3.h}, p0, [x2, x12, lsl #1]
    st1h            {z4.h}, p0, [x2, x13, lsl #1]
    st1h            {z5.h}, p0, [x2, x14, lsl #1]
    st1h            {z6.h}, p0, [x2, x15, lsl #1]
    st1h            {z7.h}, p0, [x2, x16, lsl #1]
    add             x2, x2, x3
.endr
    ret
.vl_gt_16_filterPixelToShort_high_64x\h\():
    mov             w12, #\h
    mov             x8, #64
.vl_gt_16_filterPixelToShort_high_64_outx\h\():
    sub             w12, w12, #1
    mov             x9, #0
    whilelt         p0.h, x9, x8
.vl_gt_16_filterPixelToShort_high_64_innerx\h\():
    ld1h            {z0.h}, p0/z, [x0, x9, lsl #1]
    lsl             z0.h, p0/m, z0.h, #P2S_SHIFT
    add             z0.h, p0/m, z0.h, z31.h
    st1h            {z0.h}, p0, [x0, x9, lsl #1]
    inch            x9
    whilelt         p0.h, x9, x8
    b.first         .vl_gt_16_filterPixelToShort_high_64_innerx\h
    add             x2, x2, x3
    add             x0, x0, x1
    cbnz            w12, .vl_gt_16_filterPixelToShort_high_64_outx\h
    ret
#else
    mov             w12, #\h
    mov             x8, #32
.vl_gt_16_filterPixelToShort_64_outx\h\():
    sub             w12, w12, #1
    mov             x9, #0
    mov             x10, #0
    whilelt         p0.h, x9, x8
.vl_gt_16_filterPixelToShort_64_innerx\h\():
    ld1h            {z0.h}, p0/z, [x0, x9, lsl #1]
    uunpklo         z2.h, z0.b
    uunpkhi         z3.h, z0.b
    lsl             z2.h, p0/m, z2.h, #P2S_SHIFT
    lsl             z3.h, p0/m, z3.h, #P2S_SHIFT
    add             z2.h, p0/m, z2.h, z31.h
    add             z3.h, p0/m, z3.h, z31.h
    st1h            {z2.h}, p0, [x2, x10, lsl #1]
    inch            x10
    st1h            {z3.h}, p0, [x2, x10, lsl #1]
    inch            x10
    inch            x9
    whilelt         p0.h, x9, x8
    b.first         .vl_gt_16_filterPixelToShort_64_innerx\h
    add             x2, x2, x3
    add             x0, x0, x1
    cbnz            w12, .vl_gt_16_filterPixelToShort_64_outx\h
    ret
#endif
endfunc
.endm

p2s_64xN_sve2 16
p2s_64xN_sve2 32
p2s_64xN_sve2 48
p2s_64xN_sve2 64

function PFX(filterPixelToShort_48x64_sve2)
    p2s_start_sve2
#if HIGH_BIT_DEPTH
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_filterPixelToShort_high_48x64
    ptrue           p0.h, vl8
    mov             x11, #8
    mov             x12, #16
    mov             x13, #24
    mov             x14, #32
    mov             x15, #40
.rept 64
    ld1h            {z0.h}, p0/z, [x0]
    ld1h            {z1.h}, p0/z, [x0, x11, lsl #1]
    ld1h            {z2.h}, p0/z, [x0, x12, lsl #1]
    ld1h            {z3.h}, p0/z, [x0, x13, lsl #1]
    ld1h            {z4.h}, p0/z, [x0, x14, lsl #1]
    ld1h            {z5.h}, p0/z, [x0, x15, lsl #1]
    add             x0, x0, x1
    lsl             z0.h, p0/m, z0.h, #P2S_SHIFT
    lsl             z1.h, p0/m, z1.h, #P2S_SHIFT
    lsl             z2.h, p0/m, z2.h, #P2S_SHIFT
    lsl             z3.h, p0/m, z3.h, #P2S_SHIFT
    lsl             z4.h, p0/m, z4.h, #P2S_SHIFT
    lsl             z5.h, p0/m, z5.h, #P2S_SHIFT
    add             z0.h, p0/m, z0.h, z31.h
    add             z1.h, p0/m, z1.h, z31.h
    add             z2.h, p0/m, z2.h, z31.h
    add             z3.h, p0/m, z3.h, z31.h
    add             z4.h, p0/m, z4.h, z31.h
    add             z5.h, p0/m, z5.h, z31.h
    st1h            {z0.h}, p0, [x2]
    st1h            {z1.h}, p0, [x2, x11, lsl #1]
    st1h            {z2.h}, p0, [x2, x12, lsl #1]
    st1h            {z3.h}, p0, [x2, x13, lsl #1]
    st1h            {z4.h}, p0, [x2, x14, lsl #1]
    st1h            {z5.h}, p0, [x2, x15, lsl #1]
    add             x2, x2, x3
.endr
    ret
.vl_gt_16_filterPixelToShort_high_48x64:
    mov             w12, #64
    mov             x8, #48
.vl_gt_16_filterPixelToShort_high_48_64_out:
    sub             w12, w12, #1
    mov             x9, #0
    whilelt         p0.h, x9, x8
.vl_gt_16_filterPixelToShort_high_48_64_inner:
    ld1h            {z0.h}, p0/z, [x0, x9, lsl #1]
    lsl             z0.h, p0/m, z0.h, #P2S_SHIFT
    add             z0.h, p0/m, z0.h, z31.h
    st1h            {z0.h}, p0, [x0, x9, lsl #1]
    inch            x9
    whilelt         p0.h, x9, x8
    b.first         .vl_gt_16_filterPixelToShort_high_48_64_inner
    add             x2, x2, x3
    add             x0, x0, x1
    cbnz            w12, .vl_gt_16_filterPixelToShort_high_48_64_out
    ret
#else
    mov             w12, #64
    mov             x8, #24
.vl_gt_16_filterPixelToShort_48_64_out:
    sub             w12, w12, #1
    mov             x9, #0
    mov             x10, #0
    whilelt         p0.h, x9, x8
.vl_gt_16_filterPixelToShort_48_64_inner:
    ld1h            {z0.h}, p0/z, [x0, x9, lsl #1]
    uunpklo         z2.h, z0.b
    uunpkhi         z3.h, z0.b
    lsl             z2.h, p0/m, z2.h, #P2S_SHIFT
    lsl             z3.h, p0/m, z3.h, #P2S_SHIFT
    add             z2.h, p0/m, z2.h, z31.h
    add             z3.h, p0/m, z3.h, z31.h
    st1h            {z2.h}, p0, [x2, x10, lsl #1]
    inch            x10
    st1h            {z3.h}, p0, [x2, x10, lsl #1]
    inch            x10
    inch            x9
    whilelt         p0.h, x9, x8
    b.first         .vl_gt_16_filterPixelToShort_48_64_inner
    add             x2, x2, x3
    add             x0, x0, x1
    cbnz            w12, .vl_gt_16_filterPixelToShort_48_64_out
    ret
#endif
endfunc
