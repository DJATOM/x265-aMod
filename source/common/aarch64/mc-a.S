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

.data
msg_pixel_avg_pp_4xh:
    .ascii        "#### Executing function msg_pixel_avg_pp_4xh ####\n"
len_pixel_avg_pp_4xh = . - msg_pixel_avg_pp_4xh
msg_pixel_avg_pp_12x16:
    .ascii        "#### Executing function msg_pixel_avg_pp_12x16 ####\n"
len_pixel_avg_pp_12x16 = . - msg_pixel_avg_pp_12x16

string_number:
    .asciz "The content of register is: %x\n"

.text

/* ############## NEON ###################*/

.macro pixel_avg_pp_4xN_neon h
function PFX(pixel_avg_pp_4x\h\()_neon)
.rept \h
    ld1             {v0.s}[0], [x2], x3
    ld1             {v1.s}[0], [x4], x5
    urhadd          v2.8b, v0.8b, v1.8b
    st1             {v2.s}[0], [x0], x1
.endr
    ret
endfunc
.endm

pixel_avg_pp_4xN_neon 4
pixel_avg_pp_4xN_neon 8
pixel_avg_pp_4xN_neon 16

.macro pixel_avg_pp_8xN_neon h
function PFX(pixel_avg_pp_8x\h\()_neon)
.rept \h
    ld1             {v0.8b}, [x2], x3
    ld1             {v1.8b}, [x4], x5
    urhadd          v2.8b, v0.8b, v1.8b
    st1             {v2.8b}, [x0], x1
.endr
    ret
endfunc
.endm

pixel_avg_pp_8xN_neon 4
pixel_avg_pp_8xN_neon 8
pixel_avg_pp_8xN_neon 16
pixel_avg_pp_8xN_neon 32

function PFX(pixel_avg_pp_12x16_neon)
    sub             x1, x1, #4
    sub             x3, x3, #4
    sub             x5, x5, #4
.rept 16
    ld1             {v0.s}[0], [x2], #4
    ld1             {v1.8b}, [x2], x3
    ld1             {v2.s}[0], [x4], #4
    ld1             {v3.8b}, [x4], x5
    urhadd          v4.8b, v0.8b, v2.8b
    urhadd          v5.8b, v1.8b, v3.8b
    st1             {v4.s}[0], [x0], #4
    st1             {v5.8b}, [x0], x1
.endr
    ret
endfunc

.macro pixel_avg_pp_16xN_neon h
function PFX(pixel_avg_pp_16x\h\()_neon)
.rept \h
    ld1             {v0.16b}, [x2], x3
    ld1             {v1.16b}, [x4], x5
    urhadd          v2.16b, v0.16b, v1.16b
    st1             {v2.16b}, [x0], x1
.endr
    ret
endfunc
.endm

pixel_avg_pp_16xN_neon 4
pixel_avg_pp_16xN_neon 8
pixel_avg_pp_16xN_neon 12
pixel_avg_pp_16xN_neon 16
pixel_avg_pp_16xN_neon 32

function PFX(pixel_avg_pp_16x64_neon)
    mov             w12, #8
.lpavg_16x64:
    sub             w12, w12, #1
.rept 8
    ld1             {v0.16b}, [x2], x3
    ld1             {v1.16b}, [x4], x5
    urhadd          v2.16b, v0.16b, v1.16b
    st1             {v2.16b}, [x0], x1
.endr
    cbnz            w12, .lpavg_16x64
    ret
endfunc

function PFX(pixel_avg_pp_24x32_neon)
    sub             x1, x1, #16
    sub             x3, x3, #16
    sub             x5, x5, #16
    mov             w12, #4
.lpavg_24x32:
    sub             w12, w12, #1
.rept 8
    ld1             {v0.16b}, [x2], #16
    ld1             {v1.8b}, [x2], x3
    ld1             {v2.16b}, [x4], #16
    ld1             {v3.8b}, [x4], x5
    urhadd          v0.16b, v0.16b, v2.16b
    urhadd          v1.8b, v1.8b, v3.8b
    st1             {v0.16b}, [x0], #16
    st1             {v1.8b}, [x0], x1
.endr
    cbnz            w12, .lpavg_24x32
    ret
endfunc

.macro pixel_avg_pp_32xN_neon h
function PFX(pixel_avg_pp_32x\h\()_neon)
.rept \h
    ld1             {v0.16b-v1.16b}, [x2], x3
    ld1             {v2.16b-v3.16b}, [x4], x5
    urhadd          v0.16b, v0.16b, v2.16b
    urhadd          v1.16b, v1.16b, v3.16b
    st1             {v0.16b-v1.16b}, [x0], x1
.endr
    ret
endfunc
.endm

pixel_avg_pp_32xN_neon 8
pixel_avg_pp_32xN_neon 16
pixel_avg_pp_32xN_neon 24

.macro pixel_avg_pp_32xN1_neon h
function PFX(pixel_avg_pp_32x\h\()_neon)
    mov             w12, #\h / 8
.lpavg_32x\h\():
    sub             w12, w12, #1
.rept 8
    ld1             {v0.16b-v1.16b}, [x2], x3
    ld1             {v2.16b-v3.16b}, [x4], x5
    urhadd          v0.16b, v0.16b, v2.16b
    urhadd          v1.16b, v1.16b, v3.16b
    st1             {v0.16b-v1.16b}, [x0], x1
.endr
    cbnz            w12, .lpavg_32x\h
    ret
endfunc
.endm

pixel_avg_pp_32xN1_neon 32
pixel_avg_pp_32xN1_neon 64

function PFX(pixel_avg_pp_48x64_neon)
    mov             w12, #8
.lpavg_48x64:
    sub             w12, w12, #1
.rept 8
    ld1             {v0.16b-v2.16b}, [x2], x3
    ld1             {v3.16b-v5.16b}, [x4], x5
    urhadd          v0.16b, v0.16b, v3.16b
    urhadd          v1.16b, v1.16b, v4.16b
    urhadd          v2.16b, v2.16b, v5.16b
    st1             {v0.16b-v2.16b}, [x0], x1
.endr
    cbnz            w12, .lpavg_48x64
    ret
endfunc

.macro pixel_avg_pp_64xN_neon h
function PFX(pixel_avg_pp_64x\h\()_neon)
    mov             w12, #\h / 4
.lpavg_64x\h\():
    sub             w12, w12, #1
.rept 4
    ld1             {v0.16b-v3.16b}, [x2], x3
    ld1             {v4.16b-v7.16b}, [x4], x5
    urhadd          v0.16b, v0.16b, v4.16b
    urhadd          v1.16b, v1.16b, v5.16b
    urhadd          v2.16b, v2.16b, v6.16b
    urhadd          v3.16b, v3.16b, v7.16b
    st1             {v0.16b-v3.16b}, [x0], x1
.endr
    cbnz            w12, .lpavg_64x\h
    ret
endfunc
.endm

pixel_avg_pp_64xN_neon 16
pixel_avg_pp_64xN_neon 32
pixel_avg_pp_64xN_neon 48
pixel_avg_pp_64xN_neon 64

// void addAvg(const int16_t* src0, const int16_t* src1, pixel* dst, intptr_t src0Stride, intptr_t src1Stride, intptr_t dstStride)
.macro addAvg_start
    lsl             x3, x3, #1
    lsl             x4, x4, #1
    mov             w11, #0x40
    dup             v30.16b, w11
.endm

.macro addAvg_2xN_neon h
function PFX(addAvg_2x\h\()_neon)
    addAvg_start
.rept \h / 2
    ldr             w10, [x0]
    ldr             w11, [x1]
    add             x0, x0, x3
    add             x1, x1, x4
    ldr             w12, [x0]
    ldr             w13, [x1]
    add             x0, x0, x3
    add             x1, x1, x4
    dup             v0.2s, w10
    dup             v1.2s, w11
    dup             v2.2s, w12
    dup             v3.2s, w13
    add             v0.4h, v0.4h, v1.4h
    add             v2.4h, v2.4h, v3.4h
    saddl           v0.4s, v0.4h, v30.4h
    saddl           v2.4s, v2.4h, v30.4h
    shrn            v0.4h, v0.4s, #7
    shrn2           v0.8h, v2.4s, #7
    sqxtun          v0.8b, v0.8h
    st1             {v0.h}[0], [x2], x5
    st1             {v0.h}[2], [x2], x5
.endr
    ret
endfunc
.endm

addAvg_2xN_neon 4
addAvg_2xN_neon 8
addAvg_2xN_neon 16

.macro addAvg_4xN_neon h
function PFX(addAvg_4x\h\()_neon)
    addAvg_start
.rept \h / 2
    ld1             {v0.8b}, [x0], x3
    ld1             {v1.8b}, [x1], x4
    ld1             {v2.8b}, [x0], x3
    ld1             {v3.8b}, [x1], x4
    add             v0.4h, v0.4h, v1.4h
    add             v2.4h, v2.4h, v3.4h
    saddl           v0.4s, v0.4h, v30.4h
    saddl           v2.4s, v2.4h, v30.4h
    shrn            v0.4h, v0.4s, #7
    shrn2           v0.8h, v2.4s, #7
    sqxtun          v0.8b, v0.8h
    st1             {v0.s}[0], [x2], x5
    st1             {v0.s}[1], [x2], x5
.endr
    ret
endfunc
.endm

addAvg_4xN_neon 2
addAvg_4xN_neon 4
addAvg_4xN_neon 8
addAvg_4xN_neon 16
addAvg_4xN_neon 32

.macro addAvg_6xN_neon h
function PFX(addAvg_6x\h\()_neon)
    addAvg_start
    mov             w12, #\h / 2
    sub             x5, x5, #4
.loop_addavg_6x\h:
    sub             w12, w12, #1
    ld1             {v0.16b}, [x0], x3
    ld1             {v1.16b}, [x1], x4
    ld1             {v2.16b}, [x0], x3
    ld1             {v3.16b}, [x1], x4
    add             v0.8h, v0.8h, v1.8h
    add             v2.8h, v2.8h, v3.8h
    saddl           v16.4s, v0.4h, v30.4h
    saddl2          v17.4s, v0.8h, v30.8h
    saddl           v18.4s, v2.4h, v30.4h
    saddl2          v19.4s, v2.8h, v30.8h
    shrn            v0.4h, v16.4s, #7
    shrn2           v0.8h, v17.4s, #7
    shrn            v1.4h, v18.4s, #7
    shrn2           v1.8h, v19.4s, #7
    sqxtun          v0.8b, v0.8h
    sqxtun          v1.8b, v1.8h
    str             s0, [x2], #4
    st1             {v0.h}[2], [x2], x5
    str             s1, [x2], #4
    st1             {v1.h}[2], [x2], x5
    cbnz            w12, .loop_addavg_6x\h
    ret
endfunc
.endm

addAvg_6xN_neon 8
addAvg_6xN_neon 16

.macro addAvg_8xN_neon h
function PFX(addAvg_8x\h\()_neon)
    addAvg_start
.rept \h / 2
    ld1             {v0.16b}, [x0], x3
    ld1             {v1.16b}, [x1], x4
    ld1             {v2.16b}, [x0], x3
    ld1             {v3.16b}, [x1], x4
    add             v0.8h, v0.8h, v1.8h
    add             v2.8h, v2.8h, v3.8h
    saddl           v16.4s, v0.4h, v30.4h
    saddl2          v17.4s, v0.8h, v30.8h
    saddl           v18.4s, v2.4h, v30.4h
    saddl2          v19.4s, v2.8h, v30.8h
    shrn            v0.4h, v16.4s, #7
    shrn2           v0.8h, v17.4s, #7
    shrn            v1.4h, v18.4s, #7
    shrn2           v1.8h, v19.4s, #7
    sqxtun          v0.8b, v0.8h
    sqxtun          v1.8b, v1.8h
    st1             {v0.8b}, [x2], x5
    st1             {v1.8b}, [x2], x5
.endr
    ret
endfunc
.endm

.macro addAvg_8xN1_neon h
function PFX(addAvg_8x\h\()_neon)
    addAvg_start
    mov             w12, #\h / 2
.loop_addavg_8x\h:
    sub             w12, w12, #1
    ld1             {v0.16b}, [x0], x3
    ld1             {v1.16b}, [x1], x4
    ld1             {v2.16b}, [x0], x3
    ld1             {v3.16b}, [x1], x4
    add             v0.8h, v0.8h, v1.8h
    add             v2.8h, v2.8h, v3.8h
    saddl           v16.4s, v0.4h, v30.4h
    saddl2          v17.4s, v0.8h, v30.8h
    saddl           v18.4s, v2.4h, v30.4h
    saddl2          v19.4s, v2.8h, v30.8h
    shrn            v0.4h, v16.4s, #7
    shrn2           v0.8h, v17.4s, #7
    shrn            v1.4h, v18.4s, #7
    shrn2           v1.8h, v19.4s, #7
    sqxtun          v0.8b, v0.8h
    sqxtun          v1.8b, v1.8h
    st1             {v0.8b}, [x2], x5
    st1             {v1.8b}, [x2], x5
    cbnz            w12, .loop_addavg_8x\h
    ret
endfunc
.endm

addAvg_8xN_neon 2
addAvg_8xN_neon 4
addAvg_8xN_neon 6
addAvg_8xN_neon 8
addAvg_8xN_neon 12
addAvg_8xN_neon 16
addAvg_8xN1_neon 32
addAvg_8xN1_neon 64

.macro addAvg_12xN_neon h
function PFX(addAvg_12x\h\()_neon)
    addAvg_start
    sub             x3, x3, #16
    sub             x4, x4, #16
    sub             x5, x5, #8
    mov             w12, #\h
.loop_addAvg_12X\h\():
    sub             w12, w12, #1
    ld1             {v0.16b}, [x0], #16
    ld1             {v1.16b}, [x1], #16
    ld1             {v2.8b}, [x0], x3
    ld1             {v3.8b}, [x1], x4
    add             v0.8h, v0.8h, v1.8h
    add             v2.4h, v2.4h, v3.4h
    saddl           v16.4s, v0.4h, v30.4h
    saddl2          v17.4s, v0.8h, v30.8h
    saddl           v18.4s, v2.4h, v30.4h
    shrn            v0.4h, v16.4s, #7
    shrn2           v0.8h, v17.4s, #7
    shrn            v1.4h, v18.4s, #7
    sqxtun          v0.8b, v0.8h
    sqxtun          v1.8b, v1.8h
    st1             {v0.8b}, [x2], #8
    st1             {v1.s}[0], [x2], x5
    cbnz            w12, .loop_addAvg_12X\h
    ret
endfunc
.endm

addAvg_12xN_neon 16
addAvg_12xN_neon 32

.macro addavg_1 v0, v1
    add             \v0\().8h, \v0\().8h, \v1\().8h
    saddl           v16.4s, \v0\().4h, v30.4h
    saddl2          v17.4s, \v0\().8h, v30.8h
    shrn            \v0\().4h, v16.4s, #7
    shrn2           \v0\().8h, v17.4s, #7
.endm

.macro addAvg_16xN_neon h
function PFX(addAvg_16x\h\()_neon)
    addAvg_start
    mov             w12, #\h
.loop_addavg_16x\h:
    sub             w12, w12, #1
    ld1             {v0.8h-v1.8h}, [x0], x3
    ld1             {v2.8h-v3.8h}, [x1], x4
    addavg_1        v0, v2
    addavg_1        v1, v3
    sqxtun          v0.8b, v0.8h
    sqxtun2         v0.16b, v1.8h
    st1             {v0.16b}, [x2], x5
    cbnz            w12, .loop_addavg_16x\h
    ret
endfunc
.endm

addAvg_16xN_neon 4
addAvg_16xN_neon 8
addAvg_16xN_neon 12
addAvg_16xN_neon 16
addAvg_16xN_neon 24
addAvg_16xN_neon 32
addAvg_16xN_neon 64

.macro addAvg_24xN_neon h
function PFX(addAvg_24x\h\()_neon)
    addAvg_start
    mov             w12, #\h
.loop_addavg_24x\h\():
    sub             w12, w12, #1
    ld1             {v0.16b-v2.16b}, [x0], x3
    ld1             {v3.16b-v5.16b}, [x1], x4
    addavg_1        v0, v3
    addavg_1        v1, v4
    addavg_1        v2, v5
    sqxtun          v0.8b, v0.8h
    sqxtun          v1.8b, v1.8h
    sqxtun          v2.8b, v2.8h
    st1             {v0.8b-v2.8b}, [x2], x5
    cbnz            w12, .loop_addavg_24x\h
    ret
endfunc
.endm

addAvg_24xN_neon 32
addAvg_24xN_neon 64

.macro addAvg_32xN_neon h
function PFX(addAvg_32x\h\()_neon)
    addAvg_start
    mov             w12, #\h
.loop_addavg_32x\h\():
    sub             w12, w12, #1
    ld1             {v0.8h-v3.8h}, [x0], x3
    ld1             {v4.8h-v7.8h}, [x1], x4
    addavg_1        v0, v4
    addavg_1        v1, v5
    addavg_1        v2, v6
    addavg_1        v3, v7
    sqxtun          v0.8b, v0.8h
    sqxtun          v1.8b, v1.8h
    sqxtun          v2.8b, v2.8h
    sqxtun          v3.8b, v3.8h
    st1             {v0.8b-v3.8b}, [x2], x5
    cbnz            w12, .loop_addavg_32x\h
    ret
endfunc
.endm

addAvg_32xN_neon 8
addAvg_32xN_neon 16
addAvg_32xN_neon 24
addAvg_32xN_neon 32
addAvg_32xN_neon 48
addAvg_32xN_neon 64

function PFX(addAvg_48x64_neon)
    addAvg_start
    sub             x3, x3, #64
    sub             x4, x4, #64
    mov             w12, #64
.loop_addavg_48x64:
    sub             w12, w12, #1
    ld1             {v0.8h-v3.8h}, [x0], #64
    ld1             {v4.8h-v7.8h}, [x1], #64
    ld1             {v20.8h-v21.8h}, [x0], x3
    ld1             {v22.8h-v23.8h}, [x1], x4
    addavg_1        v0, v4
    addavg_1        v1, v5
    addavg_1        v2, v6
    addavg_1        v3, v7
    addavg_1        v20, v22
    addavg_1        v21, v23
    sqxtun          v0.8b, v0.8h
    sqxtun2         v0.16b, v1.8h
    sqxtun          v1.8b, v2.8h
    sqxtun2         v1.16b, v3.8h
    sqxtun          v2.8b, v20.8h
    sqxtun2         v2.16b, v21.8h
    st1             {v0.16b-v2.16b}, [x2], x5
    cbnz            w12, .loop_addavg_48x64
    ret
endfunc

.macro addAvg_64xN_neon h
function PFX(addAvg_64x\h\()_neon)
    addAvg_start
    mov             w12, #\h
    sub             x3, x3, #64
    sub             x4, x4, #64
.loop_addavg_64x\h\():
    sub             w12, w12, #1
    ld1             {v0.8h-v3.8h}, [x0], #64
    ld1             {v4.8h-v7.8h}, [x1], #64
    ld1             {v20.8h-v23.8h}, [x0], x3
    ld1             {v24.8h-v27.8h}, [x1], x4
    addavg_1        v0, v4
    addavg_1        v1, v5
    addavg_1        v2, v6
    addavg_1        v3, v7
    addavg_1        v20, v24
    addavg_1        v21, v25
    addavg_1        v22, v26
    addavg_1        v23, v27
    sqxtun          v0.8b, v0.8h
    sqxtun2         v0.16b, v1.8h
    sqxtun          v1.8b, v2.8h
    sqxtun2         v1.16b, v3.8h
    sqxtun          v2.8b, v20.8h
    sqxtun2         v2.16b, v21.8h
    sqxtun          v3.8b, v22.8h
    sqxtun2         v3.16b, v23.8h
    st1             {v0.16b-v3.16b}, [x2], x5
    cbnz            w12, .loop_addavg_64x\h
    ret
endfunc
.endm

addAvg_64xN_neon 16
addAvg_64xN_neon 32
addAvg_64xN_neon 48
addAvg_64xN_neon 64

/* ################### SVE2 ######################### */

.macro pixel_avg_pp_4xN_sve2 h
function PFX(pixel_avg_pp_4x\h\()_sve2)
    ptrue           p6.s, vl1
    ptrue           p7.b, vl8
.rept \h
    //string_print msg_pixel_avg_pp_4xh, len_pixel_avg_pp_4xh
    ld1w            {z0.s}, p6/z, [x2]
    add             x2, x2, x3
    ld1w            {z1.s}, p6/z, [x4]
    add             x4, x4, x5
    urhadd          z0.b, p7/m, z0.b, z1.b
    st1w            {z0.s}, p6, [x0]
    add             x0, x0, x1
.endr
    ret
endfunc
.endm

pixel_avg_pp_4xN_sve2 4
pixel_avg_pp_4xN_sve2 8
pixel_avg_pp_4xN_sve2 16

.macro pixel_avg_pp_8xN_sve2 h
function PFX(pixel_avg_pp_8x\h\()_sve2)
    ptrue           p6.b, vl8
.rept \h
    ld1b            {z0.b}, p6/z, [x2]
    add             x2, x2, x3
    ld1b            {z1.b}, p6/z, [x4]
    add             x4, x4, x5
    urhadd          z0.b, p6/m, z0.b, z1.b
    st1b            {z0.b}, p6, [x0]
    add             x0, x0, x1
.endr
    ret
endfunc
.endm

pixel_avg_pp_8xN_sve2 4
pixel_avg_pp_8xN_sve2 8
pixel_avg_pp_8xN_sve2 16
pixel_avg_pp_8xN_sve2 32

function PFX(pixel_avg_pp_12x16_sve2)
    //string_print msg_pixel_avg_pp_12x16, len_pixel_avg_pp_12x16
    sub             x1, x1, #4
    sub             x3, x3, #4
    sub             x5, x5, #4
    ptrue           p0.s, vl1
    ptrue           p1.b, vl8
.rept 16
    ld1w            {z0.s}, p0/z, [x2]
    add             x2, x2, #4
    ld1b            {z1.b}, p1/z, [x2]
    add             x2, x2, x3
    ld1w            {z2.s}, p0/z, [x4]
    add             x4, x4, #4
    ld1b            {z3.b}, p1/z, [x4]
    add             x4, x4, x5
    urhadd          z0.b, p1/m, z0.b, z2.b
    urhadd          z1.b, p1/m, z1.b, z3.b
    st1b            {z0.b}, p1, [x0]
    add             x0, x0, #4
    st1b            {z1.b}, p1, [x0]
    add             x0, x0, x1
.endr
    ret
endfunc

.macro pixel_avg_pp_16xN_sve2 h
function PFX(pixel_avg_pp_16x\h\()_sve2)
    ptrue           p7.b, vl16
.rept \h
    ld1b            {z0.b}, p7/z, [x2]
    add             x2, x2, x3
    ld1b            {z1.b}, p7/z, [x4]
    add             x4, x4, x5
    urhadd          z0.b, p7/m, z0.b, z1.b
    st1b            {z0.b}, p7, [x0]
    add             x0, x0, x1
.endr
    ret
endfunc
.endm

pixel_avg_pp_16xN_sve2 4
pixel_avg_pp_16xN_sve2 8
pixel_avg_pp_16xN_sve2 12
pixel_avg_pp_16xN_sve2 16
pixel_avg_pp_16xN_sve2 32

function PFX(pixel_avg_pp_16x64_sve2)
    mov             w12, #8
    ptrue           p0.b, vl16
.loop_pixel_avg_pp_16x64:
    sub             w12, w12, #1
.rept 8
    ld1b            {z0.b}, p0/z, [x2]
    add             x2, x2, x3
    ld1b            {z1.b}, p0/z, [x4]
    add             x4, x4, x5
    urhadd          z0.b, p0/m, z0.b, z1.b
    st1b            {z0.b}, p0, [x0]
    add             x0, x0, x1
.endr
    cbnz            w12, .loop_pixel_avg_pp_16x64
    ret
endfunc

function PFX(pixel_avg_pp_24x32_sve2)
    sub             x1, x1, #16
    sub             x3, x3, #16
    sub             x5, x5, #16
    mov             w12, #4
    ptrue           p0.b, vl16
    ptrue           p1.b, vl8
.loop_pixel_avg_pp_24x32:
    sub             w12, w12, #1
.rept 8
    ld1b            {z0.b}, p0/z, [x2]
    add             x2, x2, #16
    ld1b            {z1.b}, p1/z, [x2]
    add             x2, x2, x3
    ld1b            {z2.b}, p0/z, [x4]
    add             x4, x4, #16
    ld1b            {z3.b}, p1/z, [x4]
    add             x4, x4, x5
    urhadd          z0.b, p0/m, z0.b, z2.b
    urhadd          z1.b, p1/m, z1.b, z3.b
    st1b            {z0.b}, p0, [x0]
    add             x0, x0, #16
    st1b            {z1.b}, p1, [x0]
    add             x0, x0, x1
.endr
    cbnz            w12, .loop_pixel_avg_pp_24x32
    ret
endfunc

.macro pixel_avg_pp_32xN_sve2 h
function PFX(pixel_avg_pp_32x\h\()_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_avg_pp_32_\h
    ptrue           p0.b, vl16
    mov             x11, #16
.rept \h
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, x11]
    add             x2, x2, x3
    ld1b            {z2.b}, p0/z, [x4]
    ld1b            {z3.b}, p0/z, [x4, x11]
    add             x4, x4, x5
    urhadd          z0.b, p0/m, z0.b, z2.b
    urhadd          z1.b, p0/m, z1.b, z3.b
    st1b            {z0.b}, p0, [x0]
    st1b            {z1.b}, p0, [x0, x11]
    add             x0, x0, x1
.endr
    ret
.vl_gt_16_pixel_avg_pp_32_\h:
    ptrue           p0.b, vl32
.rept \h
    ld1b            {z0.b}, p0/z, [x2]
    add             x2, x2, x3
    ld1b            {z2.b}, p0/z, [x4]
    add             x4, x4, x5
    urhadd          z0.b, p0/m, z0.b, z2.b
    st1b            {z0.b}, p0, [x0]
    add             x0, x0, x1
.endr
    ret
endfunc
.endm

pixel_avg_pp_32xN_sve2 8
pixel_avg_pp_32xN_sve2 16
pixel_avg_pp_32xN_sve2 24

.macro pixel_avg_pp_32xN1_sve2 h
function PFX(pixel_avg_pp_32x\h\()_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_avg_pp_32xN1_\h
    ptrue           p0.b, vl16
    mov             w12, #\h / 8
    mov             x11, #16
.eq_16_loop_pixel_avg_pp_32xN1_\h\():
    sub             w12, w12, #1
.rept 8
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, x11]
    add             x2, x2, x3
    ld1b            {z2.b}, p0/z, [x4]
    ld1b            {z3.b}, p0/z, [x4, x11]
    add             x4, x4, x5
    urhadd          z0.b, p0/m, z0.b, z2.b
    urhadd          z1.b, p0/m, z1.b, z3.b
    st1b            {z0.b}, p0, [x0]
    st1b            {z1.b}, p0, [x0, x11]
    add             x0, x0, x1
.endr
    cbnz            w12, .eq_16_loop_pixel_avg_pp_32xN1_\h
    ret
.vl_gt_16_pixel_avg_pp_32xN1_\h:
    ptrue           p0.b, vl32
    mov             w12, #\h / 8
.eq_32_loop_pixel_avg_pp_32xN1_\h\():
    sub             w12, w12, #1
.rept 8
    ld1b            {z0.b}, p0/z, [x2]
    add             x2, x2, x3
    ld1b            {z2.b}, p0/z, [x4]
    add             x4, x4, x5
    urhadd          z0.b, p0/m, z0.b, z2.b
    st1b            {z0.b}, p0, [x0]
    add             x0, x0, x1
.endr
    cbnz            w12, .eq_32_loop_pixel_avg_pp_32xN1_\h
    ret
endfunc
.endm

pixel_avg_pp_32xN1_sve2 32
pixel_avg_pp_32xN1_sve2 64

function PFX(pixel_avg_pp_48x64_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_avg_pp_48x64
    ptrue           p0.b, vl16
    mov             w12, #8
    mov             x11, #16
    mov             x14, #32
.vl_eq_16_pixel_avg_pp_48x64:
    sub             w12, w12, #1
.rept 8
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, x11]
    ld1b            {z2.b}, p0/z, [x2, x14]
    add             x2, x2, x3
    ld1b            {z3.b}, p0/z, [x4]
    ld1b            {z4.b}, p0/z, [x4, x11]
    ld1b            {z5.b}, p0/z, [x4, x14]
    add             x4, x4, x5
    urhadd          z0.b, p0/m, z0.b, z3.b
    urhadd          z1.b, p0/m, z1.b, z4.b
    urhadd          z2.b, p0/m, z2.b, z5.b
    st1b            {z0.b}, p0, [x0]
    st1b            {z1.b}, p0, [x0, x11]
    st1b            {z2.b}, p0, [x0, x14]
    add             x0, x0, x1
.endr
    cbnz            w12, .vl_eq_16_pixel_avg_pp_48x64
    ret
.vl_gt_16_pixel_avg_pp_48x64:
    // No need for extra checks as ptrues cannot
    // be perfectly adjusted
    ptrue           p0.b, vl32
    ptrue           p1.b, vl16
    mov             w12, #8
    mov             x11, #32
.vl_eq_32_pixel_avg_pp_48x64:
    sub             w12, w12, #1
.rept 8
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p1/z, [x2, x11]
    add             x2, x2, x3
    ld1b            {z2.b}, p0/z, [x4]
    ld1b            {z3.b}, p1/z, [x4, x11]
    add             x4, x4, x5
    urhadd          z0.b, p0/m, z0.b, z2.b
    urhadd          z1.b, p1/m, z1.b, z3.b
    st1b            {z0.b}, p0, [x0]
    st1b            {z1.b}, p1, [x0, x11]
    add             x0, x0, x1
.endr
    cbnz            w12, .vl_eq_32_pixel_avg_pp_48x64
    ret
endfunc

.macro pixel_avg_pp_64xN_sve2 h
function PFX(pixel_avg_pp_64x\h\()_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_avg_pp_64x\h
    ptrue           p0.b, vl16
    mov             w12, #\h / 4
    mov             x11, #16
    mov             x14, #32
    mov             x15, #48
.vl_eq_16_pixel_avg_pp_64x\h\():
    sub             w12, w12, #1
.rept 4
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, x11]
    ld1b            {z2.b}, p0/z, [x2, x14]
    ld1b            {z3.b}, p0/z, [x2, x15]
    add             x2, x2, x3
    ld1b            {z4.b}, p0/z, [x4]
    ld1b            {z5.b}, p0/z, [x4, x11]
    ld1b            {z6.b}, p0/z, [x4, x14]
    ld1b            {z7.b}, p0/z, [x4, x15]
    add             x4, x4, x5
    urhadd          z0.b, p0/m, z0.b, z4.b
    urhadd          z1.b, p0/m, z1.b, z5.b
    urhadd          z2.b, p0/m, z2.b, z6.b
    urhadd          z3.b, p0/m, z3.b, z7.b
    st1b            {z0.b}, p0, [x0]
    st1b            {z1.b}, p0, [x0, x11]
    st1b            {z2.b}, p0, [x0, x14]
    st1b            {z3.b}, p0, [x0, x15]
    add             x0, x0, x1
.endr
    cbnz            w12, .vl_eq_16_pixel_avg_pp_64x\h
    ret
.vl_gt_16_pixel_avg_pp_64x\h\():
    cmp             x9, #32
    bgt             .vl_gt_32_pixel_avg_pp_64x\h
    ptrue           p0.b, vl32
    mov             w12, #\h / 4
    mov             x11, #32
.vl_eq_32_pixel_avg_pp_64x\h\():
    sub             w12, w12, #1
.rept 4
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, x11]
    add             x2, x2, x3
    ld1b            {z2.b}, p0/z, [x4]
    ld1b            {z3.b}, p0/z, [x4, x11]
    add             x4, x4, x5
    urhadd          z0.b, p0/m, z0.b, z2.b
    urhadd          z1.b, p0/m, z1.b, z3.b
    st1b            {z0.b}, p0, [x0]
    st1b            {z1.b}, p0, [x0, x11]
    add             x0, x0, x1
.endr
    cbnz            w12, .vl_eq_32_pixel_avg_pp_64x\h
    ret
.vl_gt_32_pixel_avg_pp_64x\h\():
    cmp             x9, #48
    bgt             .vl_gt_48_pixel_avg_pp_64x\h
    ptrue           p0.b, mul4
    ptrue           p0.b, vl16
    mov             w12, #\h / 4
    mov             x11, #48
.vl_eq_48_pixel_avg_pp_64x\h\():
    sub             w12, w12, #1
.rept 4
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p1/z, [x2, x11]
    add             x2, x2, x3
    ld1b            {z2.b}, p0/z, [x4]
    ld1b            {z3.b}, p1/z, [x4, x11]
    add             x4, x4, x5
    urhadd          z0.b, p0/m, z0.b, z2.b
    urhadd          z1.b, p1/m, z1.b, z3.b
    st1b            {z0.b}, p0, [x0]
    st1b            {z1.b}, p1, [x0, x11]
    add             x0, x0, x1
.endr
    cbnz            w12, .vl_eq_48_pixel_avg_pp_64x\h
    ret
.vl_gt_48_pixel_avg_pp_64x\h\():
    ptrue           p0.b, vl64
    mov             w12, #\h / 4
.vl_eq_64_pixel_avg_pp_64x\h\():
    sub             w12, w12, #1
.rept 4
    ld1b            {z0.b}, p0/z, [x2]
    add             x2, x2, x3
    ld1b            {z2.b}, p0/z, [x4]
    add             x4, x4, x5
    urhadd          z0.b, p0/m, z0.b, z2.b
    st1b            {z0.b}, p0, [x0]
    add             x0, x0, x1
.endr
    cbnz            w12, .vl_eq_64_pixel_avg_pp_64x\h
    ret
endfunc
.endm

pixel_avg_pp_64xN_sve2 16
pixel_avg_pp_64xN_sve2 32
pixel_avg_pp_64xN_sve2 48
pixel_avg_pp_64xN_sve2 64

// void addAvg(const int16_t* src0, const int16_t* src1, pixel* dst, intptr_t src0Stride, intptr_t src1Stride, intptr_t dstStride)

.macro addAvg_2xN_sve2 h
function PFX(addAvg_2x\h\()_sve2)
    mov             z30.b, #0x40
    ptrue           p0.s, vl2
    ptrue           p1.h, vl4
    ptrue           p2.h, vl2
.rept \h / 2
    ld1rw           {z0.s}, p0/z, [x0]
    ld1rw           {z1.s}, p0/z, [x1]
    add             x0, x0, x3, lsl #1
    add             x1, x1, x4, lsl #1
    ld1rw           {z2.s}, p0/z, [x0]
    ld1rw           {z3.s}, p0/z, [x1]
    add             x0, x0, x3, lsl #1
    add             x1, x1, x4, lsl #1
    add             z0.h, p1/m, z0.h, z1.h
    add             z2.h, p1/m, z2.h, z3.h
    saddlb          z1.s, z0.h, z30.h
    saddlt          z3.s, z0.h, z30.h
    saddlb          z4.s, z2.h, z30.h
    saddlt          z5.s, z2.h, z30.h
    shrnb           z2.h, z1.s, #7
    shrnt           z2.h, z3.s, #7
    shrnb           z3.h, z4.s, #7
    shrnt           z3.h, z5.s, #7
    sqxtunb         z0.b, z2.h
    sqxtunb         z1.b, z3.h
    st1b            {z0.h}, p2, [x2]
    add             x2, x2, x5
    st1b            {z1.h}, p2, [x2]
    add             x2, x2, x5
.endr
    ret
endfunc
.endm

addAvg_2xN_sve2 4
addAvg_2xN_sve2 8
addAvg_2xN_sve2 16

.macro addAvg_4xN_sve2 h
function PFX(addAvg_4x\h\()_sve2)
    mov             z30.b, #0x40
    ptrue           p0.b, vl8
    ptrue           p1.h, vl4
.rept \h / 2
    ld1b            {z0.b}, p0/z, [x0]
    add             x0, x0, x3, lsl #1
    ld1b            {z1.b}, p0/z, [x1]
    add             x1, x1, x4, lsl #1
    ld1b            {z2.b}, p0/z, [x0]
    add             x0, x0, x3, lsl #1
    ld1b            {z3.b}, p0/z, [x1]
    add             x1, x1, x4, lsl #1
    add             z0.h, p1/m, z0.h, z1.h
    add             z2.h, p1/m, z2.h, z3.h
    saddlb          z1.s, z0.h, z30.h
    saddlt          z3.s, z0.h, z30.h
    saddlb          z4.s, z2.h, z30.h
    saddlt          z5.s, z2.h, z30.h
    shrnb           z2.h, z1.s, #7
    shrnt           z2.h, z3.s, #7
    shrnb           z3.h, z4.s, #7
    shrnt           z3.h, z5.s, #7
    sqxtunb         z0.b, z2.h
    sqxtunb         z1.b, z3.h
    st1b            {z0.h}, p1, [x2]
    add             x2, x2, x5
    st1b            {z1.h}, p1, [x2]
    add             x2, x2, x5
.endr
    ret
endfunc
.endm

addAvg_4xN_sve2 2
addAvg_4xN_sve2 4
addAvg_4xN_sve2 8
addAvg_4xN_sve2 16
addAvg_4xN_sve2 32

.macro addAvg_6xN_sve2 h
function PFX(addAvg_6x\h\()_sve2)
    mov             z30.b, #0x40
    mov             w12, #\h / 2
    ptrue           p0.b, vl16
    ptrue           p2.h, vl6
.loop_sve2_addavg_6x\h\():
    sub             w12, w12, #1
    ld1b            {z0.b}, p0/z, [x0]
    add             x0, x0, x3, lsl #1
    ld1b            {z1.b}, p0/z, [x1]
    add             x1, x1, x4, lsl #1
    ld1b            {z2.b}, p0/z, [x0]
    add             x0, x0, x3, lsl #1
    ld1b            {z3.b}, p0/z, [x1]
    add             x1, x1, x4, lsl #1
    add             z0.h, p0/m, z0.h, z1.h
    add             z2.h, p0/m, z2.h, z3.h
    saddlb          z1.s, z0.h, z30.h
    saddlt          z3.s, z0.h, z30.h
    saddlb          z4.s, z2.h, z30.h
    saddlt          z5.s, z2.h, z30.h
    shrnb           z2.h, z1.s, #7
    shrnt           z2.h, z3.s, #7
    shrnb           z3.h, z4.s, #7
    shrnt           z3.h, z5.s, #7
    sqxtunb         z0.b, z2.h
    sqxtunb         z1.b, z3.h
    st1b            {z0.h}, p2, [x2]
    add             x2, x2, x5
    st1b            {z1.h}, p2, [x2]
    add             x2, x2, x5
    cbnz            w12, .loop_sve2_addavg_6x\h
    ret
endfunc
.endm

addAvg_6xN_sve2 8
addAvg_6xN_sve2 16

.macro addAvg_8xN_sve2 h
function PFX(addAvg_8x\h\()_sve2)
    mov             z30.b, #0x40
    ptrue           p0.b, vl16
    ptrue           p2.h, vl8
.rept \h / 2
    ld1b            {z0.b}, p0/z, [x0]
    add             x0, x0, x3, lsl #1
    ld1b            {z1.b}, p0/z, [x1]
    add             x1, x1, x4, lsl #1
    ld1b            {z2.b}, p0/z, [x0]
    add             x0, x0, x3, lsl #1
    ld1b            {z3.b}, p0/z, [x1]
    add             x1, x1, x4, lsl #1
    add             z0.h, p0/m, z0.h, z1.h
    add             z2.h, p0/m, z2.h, z3.h
    saddlb          z1.s, z0.h, z30.h
    saddlt          z3.s, z0.h, z30.h
    saddlb          z4.s, z2.h, z30.h
    saddlt          z5.s, z2.h, z30.h
    shrnb           z2.h, z1.s, #7
    shrnt           z2.h, z3.s, #7
    shrnb           z3.h, z4.s, #7
    shrnt           z3.h, z5.s, #7
    sqxtunb         z0.b, z2.h
    sqxtunb         z1.b, z3.h
    st1b            {z0.h}, p2, [x2]
    add             x2, x2, x5
    st1b            {z1.h}, p2, [x2]
    add             x2, x2, x5
.endr
    ret
endfunc
.endm

.macro addAvg_8xN1_sve2 h
function PFX(addAvg_8x\h\()_sve2)
    mov             z30.b, #0x40
    mov             w12, #\h / 2
    ptrue           p0.b, vl16
    ptrue           p2.h, vl8
.loop_sve2_addavg_8x\h\():
    sub             w12, w12, #1
    ld1b            {z0.b}, p0/z, [x0]
    add             x0, x0, x3, lsl #1
    ld1b            {z1.b}, p0/z, [x1]
    add             x1, x1, x4, lsl #1
    ld1b            {z2.b}, p0/z, [x0]
    add             x0, x0, x3, lsl #1
    ld1b            {z3.b}, p0/z, [x1]
    add             x1, x1, x4, lsl #1
    add             z0.h, p0/m, z0.h, z1.h
    add             z2.h, p0/m, z2.h, z3.h
    saddlb          z1.s, z0.h, z30.h
    saddlt          z3.s, z0.h, z30.h
    saddlb          z4.s, z2.h, z30.h
    saddlt          z5.s, z2.h, z30.h
    shrnb           z2.h, z1.s, #7
    shrnt           z2.h, z3.s, #7
    shrnb           z3.h, z4.s, #7
    shrnt           z3.h, z5.s, #7
    sqxtunb         z0.b, z2.h
    sqxtunb         z1.b, z3.h
    st1b            {z0.h}, p2, [x2]
    add             x2, x2, x5
    st1b            {z1.h}, p2, [x2]
    add             x2, x2, x5
    cbnz            w12, .loop_sve2_addavg_8x\h
    ret
endfunc
.endm

addAvg_8xN_sve2 2
addAvg_8xN_sve2 4
addAvg_8xN_sve2 6
addAvg_8xN_sve2 8
addAvg_8xN_sve2 12
addAvg_8xN_sve2 16
addAvg_8xN1_sve2 32
addAvg_8xN1_sve2 64

.macro addAvg_12xN_sve2 h
function PFX(addAvg_12x\h\()_sve2)
    // No need for extra checks as ptrues cannot
    // be perfectly adjusted
    mov             z30.b, #0x40
    mov             w12, #\h
    ptrue           p0.b, vl16
    ptrue           p1.b, vl8
    ptrue           p2.h, vl8
    ptrue           p3.h, vl4
    mov             x11, #16
    mov             x10, #8
.loop_sve2_addavg_12x\h\():
    sub             w12, w12, #1
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x1]
    ld1b            {z2.b}, p1/z, [x0, x11]
    ld1b            {z3.b}, p1/z, [x1, x11]
    add             x0, x0, x3, lsl #1
    add             x1, x1, x4, lsl #1
    add             z0.h, p2/m, z0.h, z1.h
    add             z2.h, p3/m, z2.h, z3.h
    saddlb          z1.s, z0.h, z30.h
    saddlt          z3.s, z0.h, z30.h
    saddlb          z4.s, z2.h, z30.h
    saddlt          z5.s, z2.h, z30.h
    shrnb           z2.h, z1.s, #7
    shrnt           z2.h, z3.s, #7
    shrnb           z3.h, z4.s, #7
    shrnt           z3.h, z5.s, #7
    sqxtunb         z0.b, z2.h
    sqxtunb         z1.b, z3.h
    st1b            {z0.h}, p2, [x2]
    st1b            {z1.h}, p3, [x2, x10]
    add             x2, x2, x5
    cbnz            w12, .loop_sve2_addavg_12x\h
    ret
endfunc
.endm

addAvg_12xN_sve2 16
addAvg_12xN_sve2 32

.macro addAvg_16xN_sve2 h
function PFX(addAvg_16x\h\()_sve2)
    mov             z30.b, #0x40
    mov             w12, #\h
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_addAvg_16x\h
    ptrue           p0.b, vl16
    ptrue           p1.h, vl8
    mov             x11, #16
    mov             x10, #8
.loop_eq_16_sve2_addavg_16x\h\():
    sub             w12, w12, #1
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x1]
    ld1b            {z2.b}, p0/z, [x0, x11]
    ld1b            {z3.b}, p0/z, [x1, x11]
    add             x0, x0, x3, lsl #1
    add             x1, x1, x4, lsl #1
    add             z0.h, p0/m, z0.h, z1.h
    add             z2.h, p1/m, z2.h, z3.h
    saddlb          z1.s, z0.h, z30.h
    saddlt          z3.s, z0.h, z30.h
    saddlb          z4.s, z2.h, z30.h
    saddlt          z5.s, z2.h, z30.h
    shrnb           z2.h, z1.s, #7
    shrnt           z2.h, z3.s, #7
    shrnb           z3.h, z4.s, #7
    shrnt           z3.h, z5.s, #7
    sqxtunb         z0.b, z2.h
    sqxtunb         z1.b, z3.h
    st1b            {z0.h}, p1, [x2]
    st1b            {z1.h}, p1, [x2, x10]
    add             x2, x2, x5
    cbnz            w12, .loop_eq_16_sve2_addavg_16x\h
    ret
.vl_gt_16_addAvg_16x\h\():
    ptrue           p0.b, vl32
    ptrue           p1.h, vl16
.loop_gt_16_sve2_addavg_16x\h\():
    sub             w12, w12, #1
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x1]
    add             x0, x0, x3, lsl #1
    add             x1, x1, x4, lsl #1
    add             z0.h, p1/m, z0.h, z1.h
    saddlb          z1.s, z0.h, z30.h
    saddlt          z3.s, z0.h, z30.h
    shrnb           z2.h, z1.s, #7
    shrnt           z2.h, z3.s, #7
    sqxtunb         z0.b, z2.h
    st1b            {z0.h}, p1, [x2]
    add             x2, x2, x5
    cbnz            w12, .loop_gt_16_sve2_addavg_16x\h
    ret
endfunc
.endm

addAvg_16xN_sve2 4
addAvg_16xN_sve2 8
addAvg_16xN_sve2 12
addAvg_16xN_sve2 16
addAvg_16xN_sve2 24
addAvg_16xN_sve2 32
addAvg_16xN_sve2 64

.macro addAvg_24xN_sve2 h
function PFX(addAvg_24x\h\()_sve2)
    mov             z30.b, #0x40
    mov             w12, #\h
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_addAvg_24x\h
    ptrue           p0.b, vl16
    ptrue           p1.h, vl8
    mov             x11, #16
    mov             x13, #32
    mov             x14, #8
.loop_eq_16_sve2_addavg_24x\h\():
    sub             w12, w12, #1
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x0, x11]
    ld1b            {z2.b}, p0/z, [x0, x13]
    ld1b            {z3.b}, p0/z, [x1]
    ld1b            {z4.b}, p0/z, [x1, x11]
    ld1b            {z5.b}, p0/z, [x1, x13]
    add             x0, x0, x3, lsl #1
    add             x1, x1, x4, lsl #1
    add             z0.h, p1/m, z0.h, z3.h
    add             z1.h, p1/m, z1.h, z4.h
    add             z2.h, p1/m, z2.h, z5.h
    saddlb          z3.s, z0.h, z30.h
    saddlt          z4.s, z0.h, z30.h
    saddlb          z5.s, z1.h, z30.h
    saddlt          z6.s, z1.h, z30.h
    saddlb          z7.s, z2.h, z30.h
    saddlt          z8.s, z2.h, z30.h
    shrnb           z0.h, z3.s, #7
    shrnt           z0.h, z4.s, #7
    shrnb           z1.h, z5.s, #7
    shrnt           z1.h, z6.s, #7
    shrnb           z2.h, z7.s, #7
    shrnt           z2.h, z8.s, #7
    sqxtunb         z0.b, z0.h
    sqxtunb         z1.b, z1.h
    sqxtunb         z2.b, z2.h
    st1b            {z0.h}, p1, [x2]
    st1b            {z1.h}, p1, [x2, x14]
    st1b            {z2.h}, p1, [x2, x11]
    add             x2, x2, x5
    cbnz            w12, .loop_eq_16_sve2_addavg_24x\h
    ret
.vl_gt_16_addAvg_24x\h\():
    // No need for extra checks as ptrues cannot
    // be perfectly adjusted
    ptrue           p0.b, vl32
    ptrue           p1.b, vl16
    ptrue           p2.h, vl32
    ptrue           p3.h, vl16
    mov             x11, #32
    mov             x10, #16
.loop_gt_16_sve2_addavg_24x\h\():
    sub             w12, w12, #1
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p1/z, [x0, x11]
    ld1b            {z2.b}, p0/z, [x1]
    ld1b            {z3.b}, p1/z, [x1, x11]
    add             x0, x0, x3, lsl #1
    add             x1, x1, x4, lsl #1
    add             z0.h, p2/m, z0.h, z2.h
    add             z1.h, p3/m, z1.h, z3.h
    saddlb          z3.s, z0.h, z30.h
    saddlt          z4.s, z0.h, z30.h
    saddlb          z5.s, z1.h, z30.h
    saddlt          z6.s, z1.h, z30.h
    shrnb           z0.h, z3.s, #7
    shrnt           z0.h, z4.s, #7
    shrnb           z1.h, z5.s, #7
    shrnt           z1.h, z6.s, #7
    sqxtunb         z0.b, z0.h
    sqxtunb         z1.b, z1.h
    st1b            {z0.h}, p2, [x2]
    st1b            {z1.h}, p3, [x2, x10]
    add             x2, x2, x5
    cbnz            w12, .loop_gt_16_sve2_addavg_24x\h
    ret
endfunc
.endm

addAvg_24xN_sve2 32
addAvg_24xN_sve2 64

.macro addAvg_32xN_sve2 h
function PFX(addAvg_32x\h\()_sve2)
    mov             z30.b, #0x40
    mov             w12, #\h
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_addAvg_32x\h
    ptrue           p0.b, vl16
    ptrue           p1.h, vl8
    mov             x11, #16
    mov             x14, #32
    mov             x15, #48
    mov             x16, #8
    mov             x17, #24
.loop_eq_16_sve2_addavg_32x\h\():
    sub             w12, w12, #1
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x0, x11]
    ld1b            {z2.b}, p0/z, [x0, x14]
    ld1b            {z3.b}, p0/z, [x0, x15]
    ld1b            {z4.b}, p0/z, [x1]
    ld1b            {z5.b}, p0/z, [x1, x11]
    ld1b            {z6.b}, p0/z, [x1, x14]
    ld1b            {z7.b}, p0/z, [x1, x15]
    add             x0, x0, x3, lsl #1
    add             x1, x1, x4, lsl #1
    add             z0.h, p1/m, z0.h, z4.h
    add             z1.h, p1/m, z1.h, z5.h
    add             z2.h, p1/m, z2.h, z6.h
    add             z3.h, p1/m, z3.h, z7.h
    saddlb          z4.s, z0.h, z30.h
    saddlt          z5.s, z0.h, z30.h
    saddlb          z6.s, z1.h, z30.h
    saddlt          z7.s, z1.h, z30.h
    saddlb          z8.s, z2.h, z30.h
    saddlt          z9.s, z2.h, z30.h
    saddlb          z10.s, z3.h, z30.h
    saddlt          z11.s, z3.h, z30.h
    shrnb           z0.h, z4.s, #7
    shrnt           z0.h, z5.s, #7
    shrnb           z1.h, z6.s, #7
    shrnt           z1.h, z7.s, #7
    shrnb           z2.h, z8.s, #7
    shrnt           z2.h, z9.s, #7
    shrnb           z3.h, z10.s, #7
    shrnt           z3.h, z11.s, #7
    sqxtunb         z0.b, z0.h
    sqxtunb         z1.b, z1.h
    sqxtunb         z2.b, z2.h
    sqxtunb         z3.b, z3.h
    st1b            {z0.h}, p1, [x2]
    st1b            {z1.h}, p1, [x2, x16]
    st1b            {z2.h}, p1, [x2, x11]
    st1b            {z3.h}, p1, [x2, x17]
    add             x2, x2, x5
    cbnz            w12, .loop_eq_16_sve2_addavg_32x\h
    ret
.vl_gt_16_addAvg_32x\h\():
    // No need for extra checks for 48-bit 
    // as ptrues cannot be perfectly adjusted
    cmp             x9, #48
    bgt             .vl_gt_48_addAvg_32x\h
    ptrue           p0.b, vl32
    ptrue           p1.h, vl16
    mov             x11, #32
    mov             x10, #16
.loop_gt_eq_32_sve2_addavg_32x\h\():
    sub             w12, w12, #1
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x0, x11]
    ld1b            {z2.b}, p0/z, [x1]
    ld1b            {z3.b}, p0/z, [x1, x11]
    add             x0, x0, x3, lsl #1
    add             x1, x1, x4, lsl #1
    add             z0.h, p1/m, z0.h, z2.h
    add             z1.h, p1/m, z1.h, z3.h
    saddlb          z4.s, z0.h, z30.h
    saddlt          z5.s, z0.h, z30.h
    saddlb          z6.s, z1.h, z30.h
    saddlt          z7.s, z1.h, z30.h
    shrnb           z0.h, z4.s, #7
    shrnt           z0.h, z5.s, #7
    shrnb           z1.h, z6.s, #7
    shrnt           z1.h, z7.s, #7
    sqxtunb         z0.b, z0.h
    sqxtunb         z1.b, z1.h
    st1b            {z0.h}, p1, [x2]
    st1b            {z1.h}, p1, [x2, x10]
    add             x2, x2, x5
    cbnz            w12, .loop_gt_eq_32_sve2_addavg_32x\h
    ret
.vl_gt_48_addAvg_32x\h\():
    ptrue           p0.b, vl64
    ptrue           p1.h, vl32
.loop_eq_64_sve2_addavg_32x\h\():
    sub             w12, w12, #1
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x1]
    add             x0, x0, x3, lsl #1
    add             x1, x1, x4, lsl #1
    add             z0.h, p1/m, z0.h, z1.h
    saddlb          z1.s, z0.h, z30.h
    saddlt          z2.s, z0.h, z30.h
    shrnb           z0.h, z1.s, #7
    shrnt           z0.h, z2.s, #7
    sqxtunb         z0.b, z0.h
    st1b            {z0.h}, p1, [x2]
    add             x2, x2, x5
    cbnz            w12, .loop_eq_64_sve2_addavg_32x\h
    ret
endfunc
.endm

addAvg_32xN_sve2 8
addAvg_32xN_sve2 16
addAvg_32xN_sve2 24
addAvg_32xN_sve2 32
addAvg_32xN_sve2 48
addAvg_32xN_sve2 64

function PFX(addAvg_48x64_sve2)
    mov             z30.b, #0x40
    mov             w12, 64
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_addAvg_48x64
    ptrue           p0.b, vl16
    ptrue           p1.h, vl8
.loop_eq_16_sve2_addavg_48x64:
    sub             w12, w12, #1
    mov             x14, #16
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x0, x14]
    add             x14, x14, #16
    ld1b            {z2.b}, p0/z, [x0, x14]
    add             x14, x14, #16
    ld1b            {z3.b}, p0/z, [x0, x14]
    add             x14, x14, #16
    ld1b            {z20.b}, p0/z, [x0, x14]
    add             x14, x14, #16
    ld1b            {z21.b}, p0/z, [x0, x14]
    mov             x14, #16
    ld1b            {z4.b}, p0/z, [x1]
    ld1b            {z5.b}, p0/z, [x1, x14]
    add             x14, x14, #16
    ld1b            {z6.b}, p0/z, [x1, x14]
    add             x14, x14, #16
    ld1b            {z7.b}, p0/z, [x1, x14]
    add             x14, x14, #16
    ld1b            {z22.b}, p0/z, [x1, x14]
    add             x14, x14, #16
    ld1b            {z23.b}, p0/z, [x1, x14]
    add             x0, x0, x3, lsl #1
    add             x1, x1, x4, lsl #1
    add             z0.h, p1/m, z0.h, z4.h
    add             z1.h, p1/m, z1.h, z5.h
    add             z2.h, p1/m, z2.h, z6.h
    add             z3.h, p1/m, z3.h, z7.h
    add             z20.h, p1/m, z20.h, z22.h
    add             z21.h, p1/m, z21.h, z23.h
    saddlb          z4.s, z0.h, z30.h
    saddlt          z5.s, z0.h, z30.h
    saddlb          z6.s, z1.h, z30.h
    saddlt          z7.s, z1.h, z30.h
    saddlb          z8.s, z2.h, z30.h
    saddlt          z9.s, z2.h, z30.h
    saddlb          z10.s, z3.h, z30.h
    saddlt          z11.s, z3.h, z30.h
    saddlb          z12.s, z20.h, z30.h
    saddlt          z13.s, z20.h, z30.h
    saddlb          z14.s, z21.h, z30.h
    saddlt          z15.s, z21.h, z30.h
    shrnb           z0.h, z4.s, #7
    shrnt           z0.h, z5.s, #7
    shrnb           z1.h, z6.s, #7
    shrnt           z1.h, z7.s, #7
    shrnb           z2.h, z8.s, #7
    shrnt           z2.h, z9.s, #7
    shrnb           z3.h, z10.s, #7
    shrnt           z3.h, z11.s, #7
    shrnb           z20.h, z12.s, #7
    shrnt           z20.h, z13.s, #7
    shrnb           z21.h, z14.s, #7
    shrnt           z21.h, z15.s, #7
    sqxtunb         z0.b, z0.h
    sqxtunb         z1.b, z1.h
    sqxtunb         z2.b, z2.h
    sqxtunb         z3.b, z3.h
    sqxtunb         z20.b, z20.h
    sqxtunb         z21.b, z21.h
    mov             x14, #8
    st1b            {z0.h}, p1, [x2]
    st1b            {z1.h}, p1, [x2, x14]
    add             x14, x14, #8
    st1b            {z2.h}, p1, [x2, x14]
    add             x14, x14, #8
    st1b            {z3.h}, p1, [x2, x14]
    add             x14, x14, #8
    st1b            {z20.h}, p1, [x2, x14]
    add             x14, x14, #8
    st1b            {z21.h}, p1, [x2, x14]
    add             x2, x2, x5
    cbnz            w12, .loop_eq_16_sve2_addavg_48x64
    ret
.vl_gt_16_addAvg_48x64:
    // No need for extra checks as ptrues cannot
    // be perfectly adjusted
    ptrue           p0.b, vl32
    ptrue           p1.h, vl16
.loop_gt_eq_32_sve2_addavg_48x64:
    sub             w12, w12, #1
    mov             x14, #16
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x0, x14]
    add             x14, x14, #32
    ld1b            {z2.b}, p0/z, [x0, x14]
    mov             x14, #16
    ld1b            {z4.b}, p0/z, [x1]
    ld1b            {z5.b}, p0/z, [x1, x14]
    add             x14, x14, #32
    ld1b            {z6.b}, p0/z, [x1, x14]
    add             x0, x0, x3, lsl #1
    add             x1, x1, x4, lsl #1
    add             z0.h, p1/m, z0.h, z4.h
    add             z1.h, p1/m, z1.h, z5.h
    add             z2.h, p1/m, z2.h, z6.h
    saddlb          z4.s, z0.h, z30.h
    saddlt          z5.s, z0.h, z30.h
    saddlb          z6.s, z1.h, z30.h
    saddlt          z7.s, z1.h, z30.h
    saddlb          z8.s, z2.h, z30.h
    saddlt          z9.s, z2.h, z30.h
    shrnb           z0.h, z4.s, #7
    shrnt           z0.h, z5.s, #7
    shrnb           z1.h, z6.s, #7
    shrnt           z1.h, z7.s, #7
    shrnb           z2.h, z8.s, #7
    shrnt           z2.h, z9.s, #7
    sqxtunb         z0.b, z0.h
    sqxtunb         z1.b, z1.h
    sqxtunb         z2.b, z2.h
    mov             x14, #8
    st1b            {z0.h}, p1, [x2]
    st1b            {z1.h}, p1, [x2, x14]
    add             x14, x14, #16
    st1b            {z2.h}, p1, [x2, x14]
    add             x2, x2, x5
    cbnz            w12, .loop_gt_eq_32_sve2_addavg_48x64
    ret
endfunc

.macro addAvg_64xN_sve2 h
function PFX(addAvg_64x\h\()_sve2)
    mov             z30.b, #0x40
    mov             w12, #\h
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_addAvg_64x\h
    ptrue           p0.b, vl16
    ptrue           p1.h, vl8
.loop_eq_16_sve2_addavg_64x\h\():
    sub             w12, w12, #1
    mov             x14, #16
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x0, x14]
    add             x14, x14, #16
    ld1b            {z2.b}, p0/z, [x0, x14]
    add             x14, x14, #16
    ld1b            {z3.b}, p0/z, [x0, x14]
    add             x14, x14, #16
    ld1b            {z20.b}, p0/z, [x0, x14]
    add             x14, x14, #16
    ld1b            {z21.b}, p0/z, [x0, x14]
    add             x14, x14, #16
    ld1b            {z22.b}, p0/z, [x0, x14]
    add             x14, x14, #16
    ld1b            {z23.b}, p0/z, [x0, x14]
    mov             x14, #16
    ld1b            {z4.b}, p0/z, [x1]
    ld1b            {z5.b}, p0/z, [x1, x14]
    add             x14, x14, #16
    ld1b            {z6.b}, p0/z, [x1, x14]
    add             x14, x14, #16
    ld1b            {z7.b}, p0/z, [x1, x14]
    add             x14, x14, #16
    ld1b            {z24.b}, p0/z, [x1, x14]
    add             x14, x14, #16
    ld1b            {z25.b}, p0/z, [x1, x14]
    add             x14, x14, #16
    ld1b            {z26.b}, p0/z, [x1, x14]
    add             x14, x14, #16
    ld1b            {z27.b}, p0/z, [x1, x14]
    add             x0, x0, x3, lsl #1
    add             x1, x1, x4, lsl #1
    add             z0.h, p1/m, z0.h, z4.h
    add             z1.h, p1/m, z1.h, z5.h
    add             z2.h, p1/m, z2.h, z6.h
    add             z3.h, p1/m, z3.h, z7.h
    add             z20.h, p1/m, z20.h, z24.h
    add             z21.h, p1/m, z21.h, z25.h
    add             z22.h, p1/m, z22.h, z26.h
    add             z23.h, p1/m, z23.h, z27.h
    saddlb          z4.s, z0.h, z30.h
    saddlt          z5.s, z0.h, z30.h
    saddlb          z6.s, z1.h, z30.h
    saddlt          z7.s, z1.h, z30.h
    saddlb          z8.s, z2.h, z30.h
    saddlt          z9.s, z2.h, z30.h
    saddlb          z10.s, z3.h, z30.h
    saddlt          z11.s, z3.h, z30.h
    saddlb          z12.s, z20.h, z30.h
    saddlt          z13.s, z20.h, z30.h
    saddlb          z14.s, z21.h, z30.h
    saddlt          z15.s, z21.h, z30.h
    saddlb          z16.s, z22.h, z30.h
    saddlt          z17.s, z22.h, z30.h
    saddlb          z18.s, z23.h, z30.h
    saddlt          z19.s, z23.h, z30.h
    shrnb           z0.h, z4.s, #7
    shrnt           z0.h, z5.s, #7
    shrnb           z1.h, z6.s, #7
    shrnt           z1.h, z7.s, #7
    shrnb           z2.h, z8.s, #7
    shrnt           z2.h, z9.s, #7
    shrnb           z3.h, z10.s, #7
    shrnt           z3.h, z11.s, #7
    shrnb           z20.h, z12.s, #7
    shrnt           z20.h, z13.s, #7
    shrnb           z21.h, z14.s, #7
    shrnt           z21.h, z15.s, #7
    shrnb           z22.h, z16.s, #7
    shrnt           z22.h, z17.s, #7
    shrnb           z23.h, z18.s, #7
    shrnt           z23.h, z19.s, #7
    sqxtunb         z0.b, z0.h
    sqxtunb         z1.b, z1.h
    sqxtunb         z2.b, z2.h
    sqxtunb         z3.b, z3.h
    sqxtunb         z20.b, z20.h
    sqxtunb         z21.b, z21.h
    sqxtunb         z22.b, z22.h
    sqxtunb         z23.b, z23.h
    mov             x14, #8
    st1b            {z0.h}, p1, [x2]
    st1b            {z1.h}, p1, [x2, x14]
    add             x14, x14, #8
    st1b            {z2.h}, p1, [x2, x14]
    add             x14, x14, #8
    st1b            {z3.h}, p1, [x2, x14]
    add             x14, x14, #8
    st1b            {z20.h}, p1, [x2, x14]
    add             x14, x14, #8
    st1b            {z21.h}, p1, [x2, x14]
    add             x14, x14, #8
    st1b            {z22.h}, p1, [x2, x14]
    add             x14, x14, #8
    st1b            {z23.h}, p1, [x2, x14]
    add             x2, x2, x5
    cbnz            w12, .loop_eq_16_sve2_addavg_64x\h
    ret
.vl_gt_16_addAvg_64x\h\():
    // No need for extra checks for 48-bit 
    // as ptrues cannot be perfectly adjusted
    cmp             x9, #48
    bgt             .vl_gt_48_addAvg_64x\h
    ptrue           p0.b, vl32
    ptrue           p1.h, vl16
.loop_gt_eq_32_sve2_addavg_64x\h\():
    sub             w12, w12, #1
    mov             x14, #16
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x0, x14]
    add             x14, x14, #32
    ld1b            {z2.b}, p0/z, [x0, x14]
    add             x14, x14, #32
    ld1b            {z3.b}, p0/z, [x0, x14]
    mov             x14, #16
    ld1b            {z4.b}, p0/z, [x1]
    ld1b            {z5.b}, p0/z, [x1, x14]
    add             x14, x14, #32
    ld1b            {z6.b}, p0/z, [x1, x14]
    add             x14, x14, #32
    ld1b            {z7.b}, p0/z, [x1, x14]
    add             x0, x0, x3, lsl #1
    add             x1, x1, x4, lsl #1
    add             z0.h, p1/m, z0.h, z4.h
    add             z1.h, p1/m, z1.h, z5.h
    add             z2.h, p1/m, z2.h, z6.h
    add             z3.h, p1/m, z3.h, z7.h
    saddlb          z4.s, z0.h, z30.h
    saddlt          z5.s, z0.h, z30.h
    saddlb          z6.s, z1.h, z30.h
    saddlt          z7.s, z1.h, z30.h
    saddlb          z8.s, z2.h, z30.h
    saddlt          z9.s, z2.h, z30.h
    saddlb          z10.s, z3.h, z30.h
    saddlt          z11.s, z3.h, z30.h
    shrnb           z0.h, z4.s, #7
    shrnt           z0.h, z5.s, #7
    shrnb           z1.h, z6.s, #7
    shrnt           z1.h, z7.s, #7
    shrnb           z2.h, z8.s, #7
    shrnt           z2.h, z9.s, #7
    shrnb           z3.h, z10.s, #7
    shrnt           z3.h, z11.s, #7
    sqxtunb         z0.b, z0.h
    sqxtunb         z1.b, z1.h
    sqxtunb         z2.b, z2.h
    sqxtunb         z3.b, z3.h
    mov             x14, #8
    st1b            {z0.h}, p1, [x2]
    st1b            {z1.h}, p1, [x2, x14]
    add             x14, x14, #16
    st1b            {z2.h}, p1, [x2, x14]
    add             x14, x14, #16
    st1b            {z3.h}, p1, [x2, x14]
    add             x2, x2, x5
    cbnz            w12, .loop_gt_eq_32_sve2_addavg_64x\h
    ret
.vl_gt_48_addAvg_64x\h\():
    // No need for extra checks for 80 and 112-bit 
    // as ptrues cannot be perfectly adjusted
    cmp             x9, #112
    bgt             .vl_gt_112_addAvg_64x\h
    ptrue           p0.b, vl64
    ptrue           p1.h, vl32
    mov             x11, #64
    mov             x10, #32
.loop_gt_eq_48_sve2_addavg_64x\h\():
    sub             w12, w12, #1
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z1.b}, p0/z, [x0, x11]
    ld1b            {z4.b}, p0/z, [x1]
    ld1b            {z5.b}, p0/z, [x1, x11]
    add             x0, x0, x3, lsl #1
    add             x1, x1, x4, lsl #1
    add             z0.h, p1/m, z0.h, z4.h
    add             z1.h, p1/m, z1.h, z5.h
    saddlb          z4.s, z0.h, z30.h
    saddlt          z5.s, z0.h, z30.h
    saddlb          z6.s, z1.h, z30.h
    saddlt          z7.s, z1.h, z30.h
    shrnb           z0.h, z4.s, #7
    shrnt           z0.h, z5.s, #7
    shrnb           z1.h, z6.s, #7
    shrnt           z1.h, z7.s, #7
    sqxtunb         z0.b, z0.h
    sqxtunb         z1.b, z1.h
    st1b            {z0.h}, p1, [x2]
    st1b            {z1.h}, p1, [x2, x10]
    add             x2, x2, x5
    cbnz            w12, .loop_gt_eq_48_sve2_addavg_64x\h
    ret
.vl_gt_112_addAvg_64x\h\():
    ptrue           p0.b, vl128
    ptrue           p1.h, vl64
.loop_gt_eq_128_sve2_addavg_64x\h\():
    sub             w12, w12, #1
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z4.b}, p0/z, [x1]
    add             x0, x0, x3, lsl #1
    add             x1, x1, x4, lsl #1
    add             z0.h, p1/m, z0.h, z4.h
    saddlb          z4.s, z0.h, z30.h
    saddlt          z5.s, z0.h, z30.h
    shrnb           z0.h, z4.s, #7
    shrnt           z0.h, z5.s, #7
    sqxtunb         z0.b, z0.h
    st1b            {z0.h}, p1, [x2]
    add             x2, x2, x5
    cbnz            w12, .loop_gt_eq_128_sve2_addavg_64x\h
    ret
endfunc
.endm

addAvg_64xN_sve2 16
addAvg_64xN_sve2 32
addAvg_64xN_sve2 48
addAvg_64xN_sve2 64
