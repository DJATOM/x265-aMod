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

// Functions in this file:
// ***** luma_vpp *****
// ***** luma_vps *****
// ***** luma_vsp *****
// ***** luma_vss *****
// ***** luma_hpp *****
// ***** luma_hps *****
// ***** chroma_vpp *****
// ***** chroma_vps *****
// ***** chroma_vsp *****
// ***** chroma_vss *****
// ***** chroma_hpp *****
// ***** chroma_hps *****

#include "asm.S"

.arch armv8-a+sve2

#ifdef __APPLE__
.section __RODATA,__rodata
#else
.section .rodata
#endif

.align 4

.text

// Macros below follow these conventions:
// - input data in registers: v0, v1, v2, v3, v4, v5, v6, v7
// - constants in registers: v24, v25, v26, v27, v31
// - temporary registers: v16, v17, v18, v19, v20, v21, v22, v23, v28, v29, v30.
// - _32b macros output a result in v17.4s
// - _64b and _32b_1 macros output results in v17.4s, v18.4s

.macro vextin8 v
    ldp             d6, d7, [x11], #16
.if \v == 0
    // qpel_filter_0 only uses values in v3
    ext             v3.8b, v6.8b, v7.8b, #4
.else
.if \v != 3
    ext             v0.8b, v6.8b, v7.8b, #1
.endif
    ext             v1.8b, v6.8b, v7.8b, #2
    ext             v2.8b, v6.8b, v7.8b, #3
    ext             v3.8b, v6.8b, v7.8b, #4
    ext             v4.8b, v6.8b, v7.8b, #5
    ext             v5.8b, v6.8b, v7.8b, #6
    ext             v6.8b, v6.8b, v7.8b, #7
.endif
.endm

.macro vextin8_64 v
    ldp             q6, q7, [x11], #32
.if \v == 0
    // qpel_filter_0 only uses values in v3
    ext             v3.16b, v6.16b, v7.16b, #4
.else
.if \v != 3
    // qpel_filter_3 does not use values in v0
    ext             v0.16b, v6.16b, v7.16b, #1
.endif
    ext             v1.16b, v6.16b, v7.16b, #2
    ext             v2.16b, v6.16b, v7.16b, #3
    ext             v3.16b, v6.16b, v7.16b, #4
    ext             v4.16b, v6.16b, v7.16b, #5
    ext             v5.16b, v6.16b, v7.16b, #6
.if \v == 1
    ext             v6.16b, v6.16b, v7.16b, #7
    // qpel_filter_1 does not use v7
.else
    ext             v16.16b, v6.16b, v7.16b, #7
    ext             v7.16b, v6.16b, v7.16b, #8
    mov             v6.16b, v16.16b
.endif
.endif
.endm

.macro vextin8_chroma v
    ldp             d6, d7, [x11], #16
.if \v == 0
    // qpel_filter_chroma_0 only uses values in v1
    ext             v1.8b, v6.8b, v7.8b, #2
.else
    ext             v0.8b, v6.8b, v7.8b, #1
    ext             v1.8b, v6.8b, v7.8b, #2
    ext             v2.8b, v6.8b, v7.8b, #3
    ext             v3.8b, v6.8b, v7.8b, #4
.endif
.endm

.macro vextin8_chroma_64 v
    ldp             q16, q17, [x11], #32
.if \v == 0
    // qpel_filter_chroma_0 only uses values in v1
    ext             v1.16b, v16.16b, v17.16b, #2
.else
    ext             v0.16b, v16.16b, v17.16b, #1
    ext             v1.16b, v16.16b, v17.16b, #2
    ext             v2.16b, v16.16b, v17.16b, #3
    ext             v3.16b, v16.16b, v17.16b, #4
.endif
.endm

.macro qpel_load_32b v
.if \v == 0
    add             x6, x6, x11       // do not load 3 values that are not used in qpel_filter_0
    ld1             {v3.8b}, [x6], x1
.elseif \v == 1 || \v == 2 || \v == 3
.if \v != 3                           // not used in qpel_filter_3
    ld1             {v0.8b}, [x6], x1
.else
    add             x6, x6, x1
.endif
    ld1             {v1.8b}, [x6], x1
    ld1             {v2.8b}, [x6], x1
    ld1             {v3.8b}, [x6], x1
    ld1             {v4.8b}, [x6], x1
    ld1             {v5.8b}, [x6], x1
.if \v != 1                           // not used in qpel_filter_1
    ld1             {v6.8b}, [x6], x1
    ld1             {v7.8b}, [x6]
.else
    ld1             {v6.8b}, [x6]
.endif
.endif
.endm

.macro qpel_load_32b_sve2 v
.if \v == 0
    add             x6, x6, x11       // do not load 3 values that are not used in qpel_filter_0
    ld1b            {z3.h}, p0/z, [x6]
    add             x6, x6, x1
.elseif \v == 1 || \v == 2 || \v == 3
.if \v != 3                           // not used in qpel_filter_3
    ld1b            {z0.h}, p0/z, [x6]
    add             x6, x6, x1
.else
    add             x6, x6, x1
.endif
    ld1b            {z1.h}, p0/z, [x6]
    add             x6, x6, x1
    ld1b            {z2.h}, p0/z, [x6]
    add             x6, x6, x1
    ld1b            {z3.h}, p0/z, [x6]
    add             x6, x6, x1
    ld1b            {z4.h}, p0/z, [x6]
    add             x6, x6, x1
    ld1b            {z5.h}, p0/z, [x6]
    add             x6, x6, x1
.if \v != 1                           // not used in qpel_filter_1
    ld1b            {z6.h}, p0/z, [x6]
    add             x6, x6, x1
    ld1b            {z7.h}, p0/z, [x6]
.else
    ld1b            {z6.h}, p0/z, [x6]
.endif
.endif
.endm

.macro qpel_load_64b v
.if \v == 0
    add             x6, x6, x11       // do not load 3 values that are not used in qpel_filter_0
    ld1             {v3.16b}, [x6], x1
.elseif \v == 1 || \v == 2 || \v == 3
.if \v != 3                           // not used in qpel_filter_3
    ld1             {v0.16b}, [x6], x1
.else
    add             x6, x6, x1
.endif
    ld1             {v1.16b}, [x6], x1
    ld1             {v2.16b}, [x6], x1
    ld1             {v3.16b}, [x6], x1
    ld1             {v4.16b}, [x6], x1
    ld1             {v5.16b}, [x6], x1
.if \v != 1                           // not used in qpel_filter_1
    ld1             {v6.16b}, [x6], x1
    ld1             {v7.16b}, [x6]
.else
    ld1             {v6.16b}, [x6]
.endif
.endif
.endm

.macro qpel_load_64b_sve2 v
.if \v == 0
    add             x6, x6, x11       // do not load 3 values that are not used in qpel_filter_0
    ld1b            {z3.h}, p0/z, [x6]
    ld1b            {z11.h}, p0/z, [x6, #1, mul vl]
    add             x6, x6, x1
.elseif \v == 1 || \v == 2 || \v == 3
.if \v != 3                           // not used in qpel_filter_3
    ld1b            {z0.h}, p0/z, [x6]
    ld1b            {z29.h}, p0/z, [x6, #1, mul vl]
    add             x6, x6, x1
.else
    add             x6, x6, x1
.endif
    ld1b            {z1.h}, p0/z, [x6]
    ld1b            {z30.h}, p0/z, [x6, #1, mul vl]
    add             x6, x6, x1
    ld1b            {z2.h}, p0/z, [x6]
    ld1b            {z10.h}, p0/z, [x6, #1, mul vl]
    add             x6, x6, x1
    ld1b            {z3.h}, p0/z, [x6]
    ld1b            {z11.h}, p0/z, [x6, #1, mul vl]
    add             x6, x6, x1
    ld1b            {z4.h}, p0/z, [x6]
    ld1b            {z12.h}, p0/z, [x6, #1, mul vl]
    add             x6, x6, x1
    ld1b            {z5.h}, p0/z, [x6]
    ld1b            {z13.h}, p0/z, [x6, #1, mul vl]
    add             x6, x6, x1
.if \v != 1                           // not used in qpel_filter_1
    ld1b            {z6.h}, p0/z, [x6]
    ld1b            {z14.h}, p0/z, [x6, #1, mul vl]
    add             x6, x6, x1
    ld1b            {z7.h}, p0/z, [x6]
    ld1b            {z15.h}, p0/z, [x6, #1, mul vl]
.else
    ld1b            {z6.h}, p0/z, [x6]
    ld1b            {z14.h}, p0/z, [x6, #1, mul vl]
.endif
.endif
.endm

.macro qpel_load_64b_sve2_gt_16 v
.if \v == 0
    add             x6, x6, x11       // do not load 3 values that are not used in qpel_filter_0
    ld1b            {z3.h}, p2/z, [x6]
    add             x6, x6, x1
.elseif \v == 1 || \v == 2 || \v == 3
.if \v != 3                           // not used in qpel_filter_3
    ld1b            {z0.h}, p2/z, [x6]
    add             x6, x6, x1
.else
    add             x6, x6, x1
.endif
    ld1b            {z1.h}, p2/z, [x6]
    add             x6, x6, x1
    ld1b            {z2.h}, p2/z, [x6]
    add             x6, x6, x1
    ld1b            {z3.h}, p2/z, [x6]
    add             x6, x6, x1
    ld1b            {z4.h}, p2/z, [x6]
    add             x6, x6, x1
    ld1b            {z5.h}, p2/z, [x6]
    add             x6, x6, x1
.if \v != 1                           // not used in qpel_filter_1
    ld1b            {z6.h}, p2/z, [x6]
    add             x6, x6, x1
    ld1b            {z7.h}, p2/z, [x6]
.else
    ld1b            {z6.h}, p2/z, [x6]
.endif
.endif
.endm

.macro qpel_chroma_load_32b v
.if \v == 0
    // qpel_filter_chroma_0 only uses values in v1
    add             x6, x6, x1
    ldr             d1, [x6]
.else
    ld1             {v0.8b}, [x6], x1
    ld1             {v1.8b}, [x6], x1
    ld1             {v2.8b}, [x6], x1
    ld1             {v3.8b}, [x6]
.endif
.endm

.macro qpel_chroma_load_32b_sve2 v
.if \v == 0
    // qpel_filter_chroma_0 only uses values in v1
    add             x6, x6, x1
    ld1b            {z1.h}, p0/z, [x6]
.else
    ld1b            {z0.h}, p0/z, [x6]
    add             x6, x6, x1
    ld1b            {z1.h}, p0/z, [x6]
    add             x6, x6, x1
    ld1b            {z2.h}, p0/z, [x6]
    add             x6, x6, x1
    ld1b            {z3.h}, p0/z, [x6]
.endif
.endm

.macro qpel_chroma_load_64b v
.if \v == 0
    // qpel_filter_chroma_0 only uses values in v1
    add             x6, x6, x1
    ldr             q1, [x6]
.else
    ld1             {v0.16b}, [x6], x1
    ld1             {v1.16b}, [x6], x1
    ld1             {v2.16b}, [x6], x1
    ld1             {v3.16b}, [x6]
.endif
.endm

//          a, b,   c,  d,  e,   f, g,  h
// .hword   0, 0,   0, 64,  0,   0, 0,  0
.macro qpel_start_0
    movi            v24.16b, #64
.endm

.macro qpel_start_sve2_0
    mov             z24.h, #64
.endm

.macro qpel_filter_0_32b
    umull           v17.8h, v3.8b, v24.8b    // 64*d
.endm

.macro qpel_filter_sve2_0_32b
    mul             z17.h, z3.h, z24.h    // 64*d
.endm

.macro qpel_filter_0_64b
    qpel_filter_0_32b
    umull2          v18.8h, v3.16b, v24.16b  // 64*d
.endm

.macro qpel_filter_sve2_0_64b
    qpel_filter_sve2_0_32b
    mul             z18.h, z11.h, z24.h
.endm

.macro qpel_start_0_1
    movi            v24.8h, #64
.endm

.macro qpel_filter_0_32b_1
    smull           v17.4s, v3.4h, v24.4h    // 64*d0
    smull2          v18.4s, v3.8h, v24.8h    // 64*d1
.endm

//          a, b,   c,  d,  e,   f, g,  h
// .hword  -1, 4, -10, 58, 17,  -5, 1,  0
.macro qpel_start_1
    movi            v24.16b, #58
    movi            v25.16b, #10
    movi            v26.16b, #17
    movi            v27.16b, #5
.endm

.macro qpel_start_sve2_1
    mov             z24.h, #58
    mov             z25.h, #10
    mov             z26.h, #17
    mov             z27.h, #5
.endm

.macro qpel_filter_1_32b
    umull           v19.8h, v2.8b, v25.8b  // c*10
    umull           v17.8h, v3.8b, v24.8b  // d*58
    umull           v21.8h, v4.8b, v26.8b  // e*17
    umull           v23.8h, v5.8b, v27.8b  // f*5
    sub             v17.8h, v17.8h, v19.8h // d*58 - c*10
    ushll           v18.8h, v1.8b, #2      // b*4
    add             v17.8h, v17.8h, v21.8h // d*58 - c*10 + e*17
    usubl           v21.8h, v6.8b, v0.8b   // g - a
    add             v17.8h, v17.8h, v18.8h // d*58 - c*10 + e*17 + b*4
    sub             v21.8h, v21.8h, v23.8h // g - a - f*5
    add             v17.8h, v17.8h, v21.8h // d*58 - c*10 + e*17 + b*4 + g - a - f*5
.endm

.macro qpel_filter_sve2_1_32b
    mul             z19.h, z2.h, z25.h  // c*10
    mul             z17.h, z3.h, z24.h  // d*58
    mul             z21.h, z4.h, z26.h  // e*17
    mul             z23.h, z5.h, z27.h  // f*5
    sub             z17.h, z17.h, z19.h // d*58 - c*10
    lsl             z18.h, z1.h, #2      // b*4
    add             z17.h, z17.h, z21.h // d*58 - c*10 + e*17
    sub             z21.h, z6.h, z0.h   // g - a
    add             z17.h, z17.h, z18.h // d*58 - c*10 + e*17 + b*4
    sub             z21.h, z21.h, z23.h // g - a - f*5
    add             z17.h, z17.h, z21.h // d*58 - c*10 + e*17 + b*4 + g - a - f*5
.endm

.macro qpel_filter_1_64b
    qpel_filter_1_32b
    umull2          v20.8h, v2.16b, v25.16b  // c*10
    umull2          v18.8h, v3.16b, v24.16b  // d*58
    umull2          v21.8h, v4.16b, v26.16b  // e*17
    umull2          v23.8h, v5.16b, v27.16b  // f*5
    sub             v18.8h, v18.8h, v20.8h   // d*58 - c*10
    ushll2          v28.8h, v1.16b, #2       // b*4
    add             v18.8h, v18.8h, v21.8h   // d*58 - c*10 + e*17
    usubl2          v21.8h, v6.16b, v0.16b   // g - a
    add             v18.8h, v18.8h, v28.8h   // d*58 - c*10 + e*17 + b*4
    sub             v21.8h, v21.8h, v23.8h   // g - a - f*5
    add             v18.8h, v18.8h, v21.8h   // d*58 - c*10 + e*17 + b*4 + g - a - f*5
.endm

.macro qpel_filter_sve2_1_64b
    qpel_filter_sve2_1_32b
    mul             z20.h, z10.h, z25.h  // c*10
    mul             z18.h, z11.h, z24.h  // d*58
    mul             z21.h, z12.h, z26.h  // e*17
    mul             z23.h, z13.h, z27.h  // f*5
    sub             z18.h, z18.h, z20.h   // d*58 - c*10
    lsl             z28.h, z30.h, #2       // b*4
    add             z18.h, z18.h, z21.h   // d*58 - c*10 + e*17
    sub             z21.h, z14.h, z29.h   // g - a
    add             z18.h, z18.h, z28.h   // d*58 - c*10 + e*17 + b*4
    sub             z21.h, z21.h, z23.h   // g - a - f*5
    add             z18.h, z18.h, z21.h   // d*58 - c*10 + e*17 + b*4 + g - a - f*5
.endm

.macro qpel_start_1_1
    movi            v24.8h, #58
    movi            v25.8h, #10
    movi            v26.8h, #17
    movi            v27.8h, #5
.endm

.macro qpel_filter_1_32b_1
    smull           v17.4s, v3.4h, v24.4h    // 58 * d0
    smull2          v18.4s, v3.8h, v24.8h    // 58 * d1
    smull           v19.4s, v2.4h, v25.4h    // 10 * c0
    smull2          v20.4s, v2.8h, v25.8h    // 10 * c1
    smull           v21.4s, v4.4h, v26.4h    // 17 * e0
    smull2          v22.4s, v4.8h, v26.8h    // 17 * e1
    smull           v23.4s, v5.4h, v27.4h    //  5 * f0
    smull2          v16.4s, v5.8h, v27.8h    //  5 * f1
    sub             v17.4s, v17.4s, v19.4s   // 58 * d0 - 10 * c0
    sub             v18.4s, v18.4s, v20.4s   // 58 * d1 - 10 * c1
    sshll           v19.4s, v1.4h, #2        // 4 * b0
    sshll2          v20.4s, v1.8h, #2        // 4 * b1
    add             v17.4s, v17.4s, v21.4s   // 58 * d0 - 10 * c0 + 17 * e0
    add             v18.4s, v18.4s, v22.4s   // 58 * d1 - 10 * c1 + 17 * e1
    ssubl           v21.4s, v6.4h, v0.4h     // g0 - a0
    ssubl2          v22.4s, v6.8h, v0.8h     // g1 - a1
    add             v17.4s, v17.4s, v19.4s   // 58 * d0 - 10 * c0 + 17 * e0 + 4 * b0
    add             v18.4s, v18.4s, v20.4s   // 58 * d1 - 10 * c1 + 17 * e1 + 4 * b1
    sub             v21.4s, v21.4s, v23.4s   // g0 - a0 - 5 * f0
    sub             v22.4s, v22.4s, v16.4s   // g1 - a1 - 5 * f1
    add             v17.4s, v17.4s, v21.4s   // 58 * d0 - 10 * c0 + 17 * e0 + 4 * b0 + g0 - a0 - 5 * f0
    add             v18.4s, v18.4s, v22.4s   // 58 * d1 - 10 * c1 + 17 * e1 + 4 * b1 + g1 - a1 - 5 * f1
.endm

//          a, b,   c,  d,  e,   f, g,  h
// .hword  -1, 4, -11, 40, 40, -11, 4, -1
.macro qpel_start_2
    movi            v24.8h, #11
    movi            v25.8h, #40
.endm

.macro qpel_start_sve2_2
    mov             z24.h, #11
    mov             z25.h, #40
.endm

.macro qpel_filter_2_32b
    uaddl           v17.8h, v3.8b, v4.8b     // d + e
    uaddl           v19.8h, v2.8b, v5.8b     // c + f
    uaddl           v23.8h, v1.8b, v6.8b     // b + g
    uaddl           v21.8h, v0.8b, v7.8b     // a + h
    mul             v17.8h, v17.8h, v25.8h   // 40 * (d + e)
    mul             v19.8h, v19.8h, v24.8h   // 11 * (c + f)
    shl             v23.8h, v23.8h, #2       // (b + g) * 4
    add             v19.8h, v19.8h, v21.8h   // 11 * (c + f) + a + h
    add             v17.8h, v17.8h, v23.8h   // 40 * (d + e) + (b + g) * 4
    sub             v17.8h, v17.8h, v19.8h   // 40 * (d + e) + (b + g) * 4 - 11 * (c + f) - a - h
.endm

.macro qpel_filter_sve2_2_32b
    add             z17.h, z3.h, z4.h     // d + e
    add             z19.h, z2.h, z5.h     // c + f
    add             z23.h, z1.h, z6.h     // b + g
    add             z21.h, z0.h, z7.h     // a + h
    mul             z17.h, z17.h, z25.h   // 40 * (d + e)
    mul             z19.h, z19.h, z24.h   // 11 * (c + f)
    lsl             z23.h, z23.h, #2       // (b + g) * 4
    add             z19.h, z19.h, z21.h   // 11 * (c + f) + a + h
    add             z17.h, z17.h, z23.h   // 40 * (d + e) + (b + g) * 4
    sub             z17.h, z17.h, z19.h   // 40 * (d + e) + (b + g) * 4 - 11 * (c + f) - a - h
.endm

.macro qpel_filter_2_64b
    qpel_filter_2_32b
    uaddl2          v27.8h, v3.16b, v4.16b   // d + e
    uaddl2          v16.8h, v2.16b, v5.16b   // c + f
    uaddl2          v23.8h, v1.16b, v6.16b   // b + g
    uaddl2          v21.8h, v0.16b, v7.16b   // a + h
    mul             v27.8h, v27.8h, v25.8h   // 40 * (d + e)
    mul             v16.8h, v16.8h, v24.8h   // 11 * (c + f)
    shl             v23.8h, v23.8h, #2       // (b + g) * 4
    add             v16.8h, v16.8h, v21.8h   // 11 * (c + f) + a + h
    add             v27.8h, v27.8h, v23.8h   // 40 * (d + e) + (b + g) * 4
    sub             v18.8h, v27.8h, v16.8h   // 40 * (d + e) + (b + g) * 4 - 11 * (c + f) - a - h
.endm

.macro qpel_filter_sve2_2_64b
    qpel_filter_sve2_2_32b
    add             z27.h, z11.h, z12.h   // d + e
    add             z16.h, z10.h, z13.h   // c + f
    add             z23.h, z30.h, z14.h   // b + g
    add             z21.h, z29.h, z15.h   // a + h
    mul             z27.h, z27.h, z25.h   // 40 * (d + e)
    mul             z16.h, z16.h, z24.h   // 11 * (c + f)
    lsl             z23.h, z23.h, #2       // (b + g) * 4
    add             z16.h, z16.h, z21.h   // 11 * (c + f) + a + h
    add             z27.h, z27.h, z23.h   // 40 * (d + e) + (b + g) * 4
    sub             z18.h, z27.h, z16.h   // 40 * (d + e) + (b + g) * 4 - 11 * (c + f) - a - h
.endm

.macro qpel_start_2_1
    movi            v24.4s, #11
    movi            v25.4s, #40
.endm

.macro qpel_filter_2_32b_1
    saddl           v17.4s, v3.4h, v4.4h     // d0 + e0
    saddl2          v18.4s, v3.8h, v4.8h     // d1 + e1
    saddl           v19.4s, v2.4h, v5.4h     // c0 + f0
    saddl2          v20.4s, v2.8h, v5.8h     // c1 + f1
    mul             v19.4s, v19.4s, v24.4s   // 11 * (c0 + f0)
    mul             v20.4s, v20.4s, v24.4s   // 11 * (c1 + f1)
    saddl           v23.4s, v1.4h, v6.4h     // b0 + g0
    mul             v17.4s, v17.4s, v25.4s   // 40 * (d0 + e0)
    mul             v18.4s, v18.4s, v25.4s   // 40 * (d1 + e1)
    saddl2          v16.4s, v1.8h, v6.8h     // b1 + g1
    saddl           v21.4s, v0.4h, v7.4h     // a0 + h0
    saddl2          v22.4s, v0.8h, v7.8h     // a1 + h1
    shl             v23.4s, v23.4s, #2       // 4*(b0+g0)
    shl             v16.4s, v16.4s, #2       // 4*(b1+g1)
    add             v19.4s, v19.4s, v21.4s   // 11 * (c0 + f0) + a0 + h0
    add             v20.4s, v20.4s, v22.4s   // 11 * (c1 + f1) + a1 + h1
    add             v17.4s, v17.4s, v23.4s   // 40 * (d0 + e0) + 4*(b0+g0)
    add             v18.4s, v18.4s, v16.4s   // 40 * (d1 + e1) + 4*(b1+g1)
    sub             v17.4s, v17.4s, v19.4s   // 40 * (d0 + e0) + 4*(b0+g0) - (11 * (c0 + f0) + a0 + h0)
    sub             v18.4s, v18.4s, v20.4s   // 40 * (d1 + e1) + 4*(b1+g1) - (11 * (c1 + f1) + a1 + h1)
.endm

//          a, b,   c,  d,  e,   f, g,  h
// .hword   0, 1,  -5, 17, 58, -10, 4, -1
.macro qpel_start_3
    movi            v24.16b, #17
    movi            v25.16b, #5
    movi            v26.16b, #58
    movi            v27.16b, #10
.endm

.macro qpel_start_sve2_3
    mov             z24.h, #17
    mov             z25.h, #5
    mov             z26.h, #58
    mov             z27.h, #10
.endm

.macro qpel_filter_3_32b
    umull           v19.8h, v2.8b, v25.8b    // c * 5
    umull           v17.8h, v3.8b, v24.8b    // d * 17
    umull           v21.8h, v4.8b, v26.8b    // e * 58
    umull           v23.8h, v5.8b, v27.8b    // f * 10
    sub             v17.8h, v17.8h, v19.8h   // d * 17 - c * 5
    ushll           v19.8h, v6.8b, #2        // g * 4
    add             v17.8h, v17.8h, v21.8h   // d * 17 - c * 5 + e * 58
    usubl           v21.8h, v1.8b, v7.8b     // b - h
    add             v17.8h, v17.8h, v19.8h   // d * 17 - c * 5 + e * 58 + g * 4
    sub             v21.8h, v21.8h, v23.8h   // b - h - f * 10
    add             v17.8h, v17.8h, v21.8h   // d * 17 - c * 5 + e * 58 + g * 4 + b - h - f * 10
.endm

.macro qpel_filter_sve2_3_32b
    mul             z19.h, z2.h, z25.h    // c * 5
    mul             z17.h, z3.h, z24.h    // d * 17
    mul             z21.h, z4.h, z26.h    // e * 58
    mul             z23.h, z5.h, z27.h    // f * 10
    sub             z17.h, z17.h, z19.h   // d * 17 - c * 5
    lsl             z19.h, z6.h, #2        // g * 4
    add             z17.h, z17.h, z21.h   // d * 17 - c * 5 + e * 58
    sub             z21.h, z1.h, z7.h     // b - h
    add             z17.h, z17.h, z19.h   // d * 17 - c * 5 + e * 58 + g * 4
    sub             z21.h, z21.h, z23.h   // b - h - f * 10
    add             z17.h, z17.h, z21.h   // d * 17 - c * 5 + e * 58 + g * 4 + b - h - f * 10
.endm

.macro qpel_filter_3_64b
    qpel_filter_3_32b
    umull2          v16.8h, v2.16b, v25.16b  // c * 5
    umull2          v18.8h, v3.16b, v24.16b  // d * 17
    umull2          v21.8h, v4.16b, v26.16b  // e * 58
    umull2          v23.8h, v5.16b, v27.16b  // f * 10
    sub             v18.8h, v18.8h, v16.8h   // d * 17 - c * 5
    ushll2          v16.8h, v6.16b, #2       // g * 4
    add             v18.8h, v18.8h, v21.8h   // d * 17 - c * 5 + e * 58
    usubl2          v21.8h, v1.16b, v7.16b   // b - h
    add             v18.8h, v18.8h, v16.8h   // d * 17 - c * 5 + e * 58 + g * 4
    sub             v21.8h, v21.8h, v23.8h   // b - h - f * 10
    add             v18.8h, v18.8h, v21.8h   // d * 17 - c * 5 + e * 58 + g * 4 + b - h - f * 10
.endm

.macro qpel_filter_sve2_3_64b
    qpel_filter_sve2_3_32b
    mul             z16.h, z10.h, z25.h  // c * 5
    mul             z18.h, z11.h, z24.h  // d * 17
    mul             z21.h, z12.h, z26.h  // e * 58
    mul             z23.h, z13.h, z27.h  // f * 10
    sub             z18.h, z18.h, z16.h   // d * 17 - c * 5
    lsl             z16.h, z14.h, #2       // g * 4
    add             z18.h, z18.h, z21.h   // d * 17 - c * 5 + e * 58
    sub             z21.h, z30.h, z15.h   // b - h
    add             z18.h, z18.h, z16.h   // d * 17 - c * 5 + e * 58 + g * 4
    sub             z21.h, z21.h, z23.h   // b - h - f * 10
    add             z18.h, z18.h, z21.h   // d * 17 - c * 5 + e * 58 + g * 4 + b - h - f * 10
.endm

.macro qpel_start_3_1
    movi            v24.8h, #17
    movi            v25.8h, #5
    movi            v26.8h, #58
    movi            v27.8h, #10
.endm

.macro qpel_filter_3_32b_1
    smull           v17.4s, v3.4h, v24.4h    // 17 * d0
    smull2          v18.4s, v3.8h, v24.8h    // 17 * d1
    smull           v19.4s, v2.4h, v25.4h    //  5 * c0
    smull2          v20.4s, v2.8h, v25.8h    //  5 * c1
    smull           v21.4s, v4.4h, v26.4h    // 58 * e0
    smull2          v22.4s, v4.8h, v26.8h    // 58 * e1
    smull           v23.4s, v5.4h, v27.4h    // 10 * f0
    smull2          v16.4s, v5.8h, v27.8h    // 10 * f1
    sub             v17.4s, v17.4s, v19.4s   // 17 * d0 - 5 * c0
    sub             v18.4s, v18.4s, v20.4s   // 17 * d1 - 5 * c1
    sshll           v19.4s, v6.4h, #2        //  4 * g0
    sshll2          v20.4s, v6.8h, #2        //  4 * g1
    add             v17.4s, v17.4s, v21.4s   // 17 * d0 - 5 * c0 + 58 * e0
    add             v18.4s, v18.4s, v22.4s   // 17 * d1 - 5 * c1 + 58 * e1
    ssubl           v21.4s, v1.4h, v7.4h     // b0 - h0
    ssubl2          v22.4s, v1.8h, v7.8h     // b1 - h1
    add             v17.4s, v17.4s, v19.4s   // 17 * d0 - 5 * c0 + 58 * e0 + 4 * g0
    add             v18.4s, v18.4s, v20.4s   // 17 * d1 - 5 * c1 + 58 * e1 + 4 * g1
    sub             v21.4s, v21.4s, v23.4s   // b0 - h0 - 10 * f0
    sub             v22.4s, v22.4s, v16.4s   // b1 - h1 - 10 * f1
    add             v17.4s, v17.4s, v21.4s   // 17 * d0 - 5 * c0 + 58 * e0 + 4 * g0 + b0 - h0 - 10 * f0
    add             v18.4s, v18.4s, v22.4s   // 17 * d1 - 5 * c1 + 58 * e1 + 4 * g1 + b1 - h1 - 10 * f1
.endm

.macro qpel_start_chroma_0
    movi            v24.16b, #64
.endm

.macro qpel_start_chroma_sve2_0
    mov             z29.h, #64
.endm

.macro qpel_filter_chroma_0_32b
    umull           v17.8h, v1.8b, v24.8b    // 64*b
.endm

.macro qpel_filter_chroma_sve2_0_32b
    mul             z17.h, z1.h, z29.h    // 64*b
.endm

.macro qpel_filter_chroma_0_64b
    umull           v17.8h, v1.8b, v24.8b    // 64*b
    umull2          v18.8h, v1.16b, v24.16b  // 64*b
.endm

.macro qpel_start_chroma_0_1
    movi            v24.8h, #64
.endm

.macro qpel_filter_chroma_0_32b_1
    smull           v17.4s, v1.4h, v24.4h    // 64*b0
    smull2          v18.4s, v1.8h, v24.8h    // 64*b1
.endm

.macro qpel_start_chroma_1
    movi            v24.16b, #58
    movi            v25.16b, #10
.endm

.macro qpel_start_chroma_sve2_1
    mov             z29.h, #58
    mov             z30.h, #10
.endm

.macro qpel_filter_chroma_1_32b
    umull           v17.8h, v1.8b, v24.8b    // 58 * b
    umull           v19.8h, v2.8b, v25.8b    // 10 * c
    uaddl           v22.8h, v0.8b, v3.8b     // a + d
    shl             v22.8h, v22.8h, #1       // 2 * (a+d)
    sub             v17.8h, v17.8h, v22.8h   // 58*b - 2*(a+d)
    add             v17.8h, v17.8h, v19.8h   // 58*b-2*(a+d) + 10*c
.endm

.macro qpel_filter_chroma_sve2_1_32b
    mul             z17.h, z1.h, z29.h    // 58 * b
    mul             z19.h, z2.h, z30.h    // 10 * c
    add             z22.h, z0.h, z3.h     // a + d
    lsl             z22.h, z22.h, #1       // 2 * (a+d)
    sub             z17.h, z17.h, z22.h   // 58*b - 2*(a+d)
    add             z17.h, z17.h, z19.h   // 58*b-2*(a+d) + 10*c
.endm

.macro qpel_filter_chroma_1_64b
    umull           v17.8h, v1.8b, v24.8b    // 58 * b
    umull2          v18.8h, v1.16b, v24.16b  // 58 * b
    umull           v19.8h, v2.8b, v25.8b    // 10 * c
    umull2          v20.8h, v2.16b, v25.16b  // 10 * c
    uaddl           v22.8h, v0.8b, v3.8b     // a + d
    uaddl2          v23.8h, v0.16b, v3.16b   // a + d
    shl             v22.8h, v22.8h, #1       // 2 * (a+d)
    shl             v23.8h, v23.8h, #1       // 2 * (a+d)
    sub             v17.8h, v17.8h, v22.8h   // 58*b - 2*(a+d)
    sub             v18.8h, v18.8h, v23.8h   // 58*b - 2*(a+d)
    add             v17.8h, v17.8h, v19.8h   // 58*b-2*(a+d) + 10*c
    add             v18.8h, v18.8h, v20.8h   // 58*b-2*(a+d) + 10*c
.endm

.macro qpel_start_chroma_1_1
    movi            v24.8h, #58
    movi            v25.8h, #10
.endm

.macro qpel_filter_chroma_1_32b_1
    smull           v17.4s, v1.4h, v24.4h    // 58 * b0
    smull2          v18.4s, v1.8h, v24.8h    // 58 * b1
    smull           v19.4s, v2.4h, v25.4h    // 10 * c0
    smull2          v20.4s, v2.8h, v25.8h    // 10 * c1
    add             v22.8h, v0.8h, v3.8h     // a + d
    sshll           v21.4s, v22.4h, #1       // 2 * (a0+d0)
    sshll2          v22.4s, v22.8h, #1       // 2 * (a1+d1)
    sub             v17.4s, v17.4s, v21.4s   // 58*b0 - 2*(a0+d0)
    sub             v18.4s, v18.4s, v22.4s   // 58*b1 - 2*(a1+d1)
    add             v17.4s, v17.4s, v19.4s   // 58*b0-2*(a0+d0) + 10*c0
    add             v18.4s, v18.4s, v20.4s   // 58*b1-2*(a1+d1) + 10*c1
.endm

.macro qpel_start_chroma_2
    movi            v25.16b, #54
.endm

.macro qpel_start_chroma_sve2_2
    mov             z30.h, #54
.endm

.macro qpel_filter_chroma_2_32b
    umull           v17.8h, v1.8b, v25.8b    // 54 * b
    ushll           v19.8h, v0.8b, #2        // 4 * a
    ushll           v21.8h, v2.8b, #4        // 16 * c
    ushll           v23.8h, v3.8b, #1        // 2 * d
    add             v17.8h, v17.8h, v21.8h   // 54*b + 16*c
    add             v19.8h, v19.8h, v23.8h   // 4*a + 2*d
    sub             v17.8h, v17.8h, v19.8h   // 54*b+16*c - (4*a+2*d)
.endm

.macro qpel_filter_chroma_sve2_2_32b
    mul             z17.h, z1.h, z30.h    // 54 * b
    lsl             z19.h, z0.h, #2        // 4 * a
    lsl             z21.h, z2.h, #4        // 16 * c
    lsl             z23.h, z3.h, #1        // 2 * d
    add             z17.h, z17.h, z21.h   // 54*b + 16*c
    add             z19.h, z19.h, z23.h   // 4*a + 2*d
    sub             z17.h, z17.h, z19.h   // 54*b+16*c - (4*a+2*d)
.endm

.macro qpel_filter_chroma_2_64b
    umull           v17.8h, v1.8b, v25.8b    // 54 * b
    umull2          v18.8h, v1.16b, v25.16b  // 54 * b
    ushll           v19.8h, v0.8b, #2        // 4 * a
    ushll2          v20.8h, v0.16b, #2       // 4 * a
    ushll           v21.8h, v2.8b, #4        // 16 * c
    ushll2          v22.8h, v2.16b, #4       // 16 * c
    ushll           v23.8h, v3.8b, #1        // 2 * d
    ushll2          v24.8h, v3.16b, #1       // 2 * d
    add             v17.8h, v17.8h, v21.8h   // 54*b + 16*c
    add             v18.8h, v18.8h, v22.8h   // 54*b + 16*c
    add             v19.8h, v19.8h, v23.8h   // 4*a + 2*d
    add             v20.8h, v20.8h, v24.8h   // 4*a + 2*d
    sub             v17.8h, v17.8h, v19.8h   // 54*b+16*c - (4*a+2*d)
    sub             v18.8h, v18.8h, v20.8h   // 54*b+16*c - (4*a+2*d)
.endm

.macro qpel_start_chroma_2_1
    movi            v25.8h, #54
.endm

.macro qpel_filter_chroma_2_32b_1
    smull           v17.4s, v1.4h, v25.4h    // 54 * b0
    smull2          v18.4s, v1.8h, v25.8h    // 54 * b1
    sshll           v19.4s, v0.4h, #2        // 4 * a0
    sshll2          v20.4s, v0.8h, #2        // 4 * a1
    sshll           v21.4s, v2.4h, #4        // 16 * c0
    sshll2          v22.4s, v2.8h, #4        // 16 * c1
    sshll           v23.4s, v3.4h, #1        // 2 * d0
    sshll2          v24.4s, v3.8h, #1        // 2 * d1
    add             v17.4s, v17.4s, v21.4s   // 54*b0 + 16*c0
    add             v18.4s, v18.4s, v22.4s   // 54*b1 + 16*c1
    add             v19.4s, v19.4s, v23.4s   // 4*a0 + 2*d0
    add             v20.4s, v20.4s, v24.4s   // 4*a1 + 2*d1
    sub             v17.4s, v17.4s, v19.4s   // 54*b0+16*c0 - (4*a0+2*d0)
    sub             v18.4s, v18.4s, v20.4s   // 54*b1+16*c1 - (4*a1+2*d1)
.endm

.macro qpel_start_chroma_3
    movi            v25.16b, #46
    movi            v26.16b, #28
    movi            v27.16b, #6
.endm

.macro qpel_start_chroma_sve2_3
    mov             z28.h, #46
    mov             z29.h, #28
    mov             z30.h, #6
.endm

.macro qpel_filter_chroma_3_32b
    umull           v17.8h, v1.8b, v25.8b    // 46 * b
    umull           v19.8h, v2.8b, v26.8b    // 28 * c
    ushll           v21.8h, v3.8b, #2        // 4 * d
    umull           v23.8h, v0.8b, v27.8b    // 6 * a
    add             v17.8h, v17.8h, v19.8h   // 46*b + 28*c
    add             v21.8h, v21.8h, v23.8h   // 4*d + 6*a
    sub             v17.8h, v17.8h, v21.8h   // 46*b+28*c - (4*d+6*a)
.endm

.macro qpel_filter_chroma_sve2_3_32b
    mul             z17.h, z1.h, z28.h    // 46 * b
    mul             z19.h, z2.h, z29.h    // 28 * c
    lsl             z21.h, z3.h, #2        // 4 * d
    mul             z23.h, z0.h, z30.h    // 6 * a
    add             z17.h, z17.h, z19.h   // 46*b + 28*c
    add             z21.h, z21.h, z23.h   // 4*d + 6*a
    sub             z17.h, z17.h, z21.h   // 46*b+28*c - (4*d+6*a)
.endm

.macro qpel_filter_chroma_3_64b
    umull           v17.8h, v1.8b, v25.8b    // 46 * b
    umull2          v18.8h, v1.16b, v25.16b  // 46 * b
    umull           v19.8h, v2.8b, v26.8b    // 28 * c
    umull2          v20.8h, v2.16b, v26.16b  // 28 * c
    ushll           v21.8h, v3.8b, #2        // 4 * d
    ushll2          v22.8h, v3.16b, #2       // 4 * d
    umull           v23.8h, v0.8b, v27.8b    // 6 * a
    umull2          v24.8h, v0.16b, v27.16b  // 6 * a
    add             v17.8h, v17.8h, v19.8h   // 46*b + 28*c
    add             v18.8h, v18.8h, v20.8h   // 46*b + 28*c
    add             v21.8h, v21.8h, v23.8h   // 4*d + 6*a
    add             v22.8h, v22.8h, v24.8h   // 4*d + 6*a
    sub             v17.8h, v17.8h, v21.8h   // 46*b+28*c - (4*d+6*a)
    sub             v18.8h, v18.8h, v22.8h   // 46*b+28*c - (4*d+6*a)
.endm

.macro qpel_start_chroma_3_1
    movi            v25.8h, #46
    movi            v26.8h, #28
    movi            v27.8h, #6
.endm

.macro qpel_filter_chroma_3_32b_1
    smull           v17.4s, v1.4h, v25.4h    // 46 * b0
    smull2          v18.4s, v1.8h, v25.8h    // 46 * b1
    smull           v19.4s, v2.4h, v26.4h    // 28 * c0
    smull2          v20.4s, v2.8h, v26.8h    // 28 * c1
    sshll           v21.4s, v3.4h, #2        // 4 * d0
    sshll2          v22.4s, v3.8h, #2        // 4 * d1
    smull           v23.4s, v0.4h, v27.4h    // 6 * a0
    smull2          v24.4s, v0.8h, v27.8h    // 6 * a1
    add             v17.4s, v17.4s, v19.4s   // 46*b0 + 28*c0
    add             v18.4s, v18.4s, v20.4s   // 46*b1 + 28*c1
    add             v21.4s, v21.4s, v23.4s   // 4*d0 + 6*a0
    add             v22.4s, v22.4s, v24.4s   // 4*d1 + 6*a1
    sub             v17.4s, v17.4s, v21.4s   // 46*b0+28*c0 - (4*d0+6*a0)
    sub             v18.4s, v18.4s, v22.4s   // 46*b1+28*c1 - (4*d1+6*a1)
.endm

.macro qpel_start_chroma_4
    movi            v24.8h, #36
.endm

.macro qpel_start_chroma_sve2_4
    mov             z29.h, #36
.endm

.macro qpel_filter_chroma_4_32b
    uaddl           v20.8h, v0.8b, v3.8b     // a + d
    uaddl           v17.8h, v1.8b, v2.8b     // b + c
    shl             v20.8h, v20.8h, #2       // 4 * (a+d)
    mul             v17.8h, v17.8h, v24.8h   // 36 * (b+c)
    sub             v17.8h, v17.8h, v20.8h   // 36*(b+c) - 4*(a+d)
.endm

.macro qpel_filter_chroma_sve2_4_32b
    add             z20.h, z0.h, z3.h     // a + d
    add             z17.h, z1.h, z2.h     // b + c
    lsl             z20.h, z20.h, #2       // 4 * (a+d)
    mul             z17.h, z17.h, z29.h   // 36 * (b+c)
    sub             z17.h, z17.h, z20.h   // 36*(b+c) - 4*(a+d)
.endm

.macro qpel_filter_chroma_4_64b
    uaddl           v20.8h, v0.8b, v3.8b     // a + d
    uaddl2          v21.8h, v0.16b, v3.16b   // a + d
    uaddl           v17.8h, v1.8b, v2.8b     // b + c
    uaddl2          v18.8h, v1.16b, v2.16b   // b + c
    shl             v20.8h, v20.8h, #2       // 4 * (a+d)
    shl             v21.8h, v21.8h, #2       // 4 * (a+d)
    mul             v17.8h, v17.8h, v24.8h   // 36 * (b+c)
    mul             v18.8h, v18.8h, v24.8h   // 36 * (b+c)
    sub             v17.8h, v17.8h, v20.8h   // 36*(b+c) - 4*(a+d)
    sub             v18.8h, v18.8h, v21.8h   // 36*(b+c) - 4*(a+d)
.endm

.macro qpel_start_chroma_4_1
    movi            v24.8h, #36
.endm

.macro qpel_filter_chroma_4_32b_1
    add             v20.8h, v0.8h, v3.8h     // a + d
    add             v21.8h, v1.8h, v2.8h     // b + c
    smull           v17.4s, v21.4h, v24.4h   // 36 * (b0+c0)
    smull2          v18.4s, v21.8h, v24.8h   // 36 * (b1+c1)
    sshll           v21.4s, v20.4h, #2       // 4 * (a0+d0)
    sshll2          v22.4s, v20.8h, #2       // 4 * (a1+d1)
    sub             v17.4s, v17.4s, v21.4s   // 36*(b0+c0) - 4*(a0+d0)
    sub             v18.4s, v18.4s, v22.4s   // 36*(b1+c1) - 4*(a1+d1)
.endm

.macro qpel_start_chroma_5
    movi            v25.16b, #28
    movi            v26.16b, #46
    movi            v27.16b, #6
.endm

.macro qpel_start_chroma_sve2_5
    mov             z28.h, #28
    mov             z29.h, #46
    mov             z30.h, #6
.endm

.macro qpel_filter_chroma_5_32b
    umull           v17.8h, v1.8b, v25.8b    // 28 * b
    umull           v19.8h, v2.8b, v26.8b    // 46 * c
    ushll           v21.8h, v0.8b, #2        // 4 * a
    umull           v23.8h, v3.8b, v27.8b    // 6 * d
    add             v17.8h, v17.8h, v19.8h   // 28*b + 46*c
    add             v21.8h, v21.8h, v23.8h   // 4*a + 6*d
    sub             v17.8h, v17.8h, v21.8h   // 28*b+46*c - (4*a+6*d)
.endm

.macro qpel_filter_chroma_sve2_5_32b
    mul             z17.h, z1.h, z28.h    // 28 * b
    mul             z19.h, z2.h, z29.h    // 46 * c
    lsl             z21.h, z0.h, #2        // 4 * a
    mul             z23.h, z3.h, z30.h    // 6 * d
    add             z17.h, z17.h, z19.h   // 28*b + 46*c
    add             z21.h, z21.h, z23.h   // 4*a + 6*d
    sub             z17.h, z17.h, z21.h   // 28*b+46*c - (4*a+6*d)
.endm

.macro qpel_filter_chroma_5_64b
    umull           v17.8h, v1.8b, v25.8b    // 28 * b
    umull2          v18.8h, v1.16b, v25.16b  // 28 * b
    umull           v19.8h, v2.8b, v26.8b    // 46 * c
    umull2          v20.8h, v2.16b, v26.16b  // 46 * c
    ushll           v21.8h, v0.8b, #2        // 4 * a
    ushll2          v22.8h, v0.16b, #2       // 4 * a
    umull           v23.8h, v3.8b, v27.8b    // 6 * d
    umull2          v24.8h, v3.16b, v27.16b  // 6 * d
    add             v17.8h, v17.8h, v19.8h   // 28*b + 46*c
    add             v18.8h, v18.8h, v20.8h   // 28*b + 46*c
    add             v21.8h, v21.8h, v23.8h   // 4*a + 6*d
    add             v22.8h, v22.8h, v24.8h   // 4*a + 6*d
    sub             v17.8h, v17.8h, v21.8h   // 28*b+46*c - (4*a+6*d)
    sub             v18.8h, v18.8h, v22.8h   // 28*b+46*c - (4*a+6*d)
.endm

.macro qpel_start_chroma_5_1
    movi            v25.8h, #28
    movi            v26.8h, #46
    movi            v27.8h, #6
.endm

.macro qpel_filter_chroma_5_32b_1
    smull           v17.4s, v1.4h, v25.4h    // 28 * b0
    smull2          v18.4s, v1.8h, v25.8h    // 28 * b1
    smull           v19.4s, v2.4h, v26.4h    // 46 * c0
    smull2          v20.4s, v2.8h, v26.8h    // 46 * c1
    sshll           v21.4s, v0.4h, #2        // 4 * a0
    sshll2          v22.4s, v0.8h, #2        // 4 * a1
    smull           v23.4s, v3.4h, v27.4h    // 6 * d0
    smull2          v24.4s, v3.8h, v27.8h    // 6 * d1
    add             v17.4s, v17.4s, v19.4s   // 28*b0 + 46*c0
    add             v18.4s, v18.4s, v20.4s   // 28*b1 + 46*c1
    add             v21.4s, v21.4s, v23.4s   // 4*a0 + 6*d0
    add             v22.4s, v22.4s, v24.4s   // 4*a1 + 6*d1
    sub             v17.4s, v17.4s, v21.4s   // 28*b0+46*c0 - (4*a0+6*d0)
    sub             v18.4s, v18.4s, v22.4s   // 28*b1+46*c1 - (4*a1+6*d1)
.endm

.macro qpel_start_chroma_6
    movi            v25.16b, #54
.endm

.macro qpel_start_chroma_sve2_6
    mov             z30.h, #54
.endm

.macro qpel_filter_chroma_6_32b
    umull           v17.8h, v2.8b, v25.8b    // 54 * c
    ushll           v19.8h, v0.8b, #1        // 2 * a
    ushll           v21.8h, v1.8b, #4        // 16 * b
    ushll           v23.8h, v3.8b, #2        // 4 * d
    add             v17.8h, v17.8h, v21.8h   // 54*c + 16*b
    add             v19.8h, v19.8h, v23.8h   // 2*a + 4*d
    sub             v17.8h, v17.8h, v19.8h   // 54*c+16*b - (2*a+4*d)
.endm

.macro qpel_filter_chroma_sve2_6_32b
    mul             z17.h, z2.h, z30.h    // 54 * c
    lsl             z19.h, z0.h, #1        // 2 * a
    lsl             z21.h, z1.h, #4        // 16 * b
    lsl             z23.h, z3.h, #2        // 4 * d
    add             z17.h, z17.h, z21.h   // 54*c + 16*b
    add             z19.h, z19.h, z23.h   // 2*a + 4*d
    sub             z17.h, z17.h, z19.h   // 54*c+16*b - (2*a+4*d)
.endm

.macro qpel_filter_chroma_6_64b
    umull           v17.8h, v2.8b, v25.8b    // 54 * c
    umull2          v18.8h, v2.16b, v25.16b  // 54 * c
    ushll           v19.8h, v0.8b, #1        // 2 * a
    ushll2          v20.8h, v0.16b, #1       // 2 * a
    ushll           v21.8h, v1.8b, #4        // 16 * b
    ushll2          v22.8h, v1.16b, #4       // 16 * b
    ushll           v23.8h, v3.8b, #2        // 4 * d
    ushll2          v24.8h, v3.16b, #2       // 4 * d
    add             v17.8h, v17.8h, v21.8h   // 54*c + 16*b
    add             v18.8h, v18.8h, v22.8h   // 54*c + 16*b
    add             v19.8h, v19.8h, v23.8h   // 2*a + 4*d
    add             v20.8h, v20.8h, v24.8h   // 2*a + 4*d
    sub             v17.8h, v17.8h, v19.8h   // 54*c+16*b - (2*a+4*d)
    sub             v18.8h, v18.8h, v20.8h   // 54*c+16*b - (2*a+4*d)
.endm

.macro qpel_start_chroma_6_1
    movi            v25.8h, #54
.endm

.macro qpel_filter_chroma_6_32b_1
    smull           v17.4s, v2.4h, v25.4h    // 54 * c0
    smull2          v18.4s, v2.8h, v25.8h    // 54 * c1
    sshll           v19.4s, v0.4h, #1        // 2 * a0
    sshll2          v20.4s, v0.8h, #1        // 2 * a1
    sshll           v21.4s, v1.4h, #4        // 16 * b0
    sshll2          v22.4s, v1.8h, #4        // 16 * b1
    sshll           v23.4s, v3.4h, #2        // 4 * d0
    sshll2          v24.4s, v3.8h, #2        // 4 * d1
    add             v17.4s, v17.4s, v21.4s   // 54*c0 + 16*b0
    add             v18.4s, v18.4s, v22.4s   // 54*c1 + 16*b1
    add             v19.4s, v19.4s, v23.4s   // 2*a0 + 4*d0
    add             v20.4s, v20.4s, v24.4s   // 2*a1 + 4*d1
    sub             v17.4s, v17.4s, v19.4s   // 54*c0+16*b0 - (2*a0+4*d0)
    sub             v18.4s, v18.4s, v20.4s   // 54*c1+16*b1 - (2*a1+4*d1)
.endm

.macro qpel_start_chroma_7
    movi            v24.16b, #58
    movi            v25.16b, #10
.endm

.macro qpel_start_chroma_sve2_7
    mov             z29.h, #58
    mov             z30.h, #10
.endm

.macro qpel_filter_chroma_7_32b
    uaddl           v20.8h, v0.8b, v3.8b     // a + d
    umull           v17.8h, v2.8b, v24.8b    // 58 * c
    shl             v20.8h, v20.8h, #1       // 2 * (a+d)
    umull           v19.8h, v1.8b, v25.8b    // 10 * b
    sub             v17.8h, v17.8h, v20.8h   // 58*c - 2*(a+d)
    add             v17.8h, v17.8h, v19.8h   // 58*c-2*(a+d) + 10*b
.endm

.macro qpel_filter_chroma_sve2_7_32b
    add             z20.h, z0.h, z3.h     // a + d
    mul             z17.h, z2.h, z29.h    // 58 * c
    lsl             z20.h, z20.h, #1       // 2 * (a+d)
    mul             z19.h, z1.h, z30.h    // 10 * b
    sub             z17.h, z17.h, z20.h   // 58*c - 2*(a+d)
    add             z17.h, z17.h, z19.h   // 58*c-2*(a+d) + 10*b
.endm

.macro qpel_filter_chroma_7_64b
    uaddl           v20.8h, v0.8b, v3.8b     // a + d
    uaddl2          v21.8h, v0.16b, v3.16b   // a + d
    umull           v17.8h, v2.8b, v24.8b    // 58 * c
    umull2          v18.8h, v2.16b, v24.16b  // 58 * c
    shl             v20.8h, v20.8h, #1       // 2 * (a+d)
    shl             v21.8h, v21.8h, #1       // 2 * (a+d)
    umull           v22.8h, v1.8b, v25.8b    // 10 * b
    umull2          v23.8h, v1.16b, v25.16b  // 10 * b
    sub             v17.8h, v17.8h, v20.8h   // 58*c - 2*(a+d)
    sub             v18.8h, v18.8h, v21.8h   // 58*c - 2*(a+d)
    add             v17.8h, v17.8h, v22.8h   // 58*c-2*(a+d) + 10*b
    add             v18.8h, v18.8h, v23.8h   // 58*c-2*(a+d) + 10*b
.endm

.macro qpel_start_chroma_7_1
    movi            v24.8h, #58
    movi            v25.8h, #10
.endm

.macro qpel_filter_chroma_7_32b_1
    add             v20.8h, v0.8h, v3.8h     // a + d
    smull           v17.4s, v2.4h, v24.4h    // 58 * c0
    smull2          v18.4s, v2.8h, v24.8h    // 58 * c1
    sshll           v21.4s, v20.4h, #1       // 2 * (a0+d0)
    sshll2          v22.4s, v20.8h, #1       // 2 * (a1+d1)
    smull           v19.4s, v1.4h, v25.4h    // 10 * b0
    smull2          v20.4s, v1.8h, v25.8h    // 10 * b1
    sub             v17.4s, v17.4s, v21.4s   // 58*c0 - 2*(a0+d0)
    sub             v18.4s, v18.4s, v22.4s   // 58*c1 - 2*(a1+d1)
    add             v17.4s, v17.4s, v19.4s   // 58*c0-2*(a0+d0) + 10*b0
    add             v18.4s, v18.4s, v20.4s   // 58*c1-2*(a1+d1) + 10*b1
.endm

// ***** luma_vpp *****
// void interp_vert_pp_c(const pixel* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx)
.macro LUMA_VPP_4xN_NEON h
function x265_interp_8tap_vert_pp_4x\h\()_neon
    movrel          x10, g_luma_s16
    sub             x0, x0, x1
    sub             x0, x0, x1, lsl #1         // src -= 3 * srcStride
    lsl             x4, x4, #4
    ldr             q0, [x10, x4]              // q0 = luma interpolate coeff
    dup             v24.8h, v0.h[0]
    dup             v25.8h, v0.h[1]
    trn1            v24.2d, v24.2d, v25.2d
    dup             v26.8h, v0.h[2]
    dup             v27.8h, v0.h[3]
    trn1            v26.2d, v26.2d, v27.2d
    dup             v28.8h, v0.h[4]
    dup             v29.8h, v0.h[5]
    trn1            v28.2d, v28.2d, v29.2d
    dup             v30.8h, v0.h[6]
    dup             v31.8h, v0.h[7]
    trn1            v30.2d, v30.2d, v31.2d

    // prepare to load 8 lines
    ld1             {v0.s}[0], [x0], x1
    ld1             {v0.s}[1], [x0], x1
    ushll           v0.8h, v0.8b, #0
    ld1             {v1.s}[0], [x0], x1
    ld1             {v1.s}[1], [x0], x1
    ushll           v1.8h, v1.8b, #0
    ld1             {v2.s}[0], [x0], x1
    ld1             {v2.s}[1], [x0], x1
    ushll           v2.8h, v2.8b, #0
    ld1             {v3.s}[0], [x0], x1
    ld1             {v3.s}[1], [x0], x1
    ushll           v3.8h, v3.8b, #0

    mov             x9, #\h
.loop_4x\h:
    ld1             {v4.s}[0], [x0], x1
    ld1             {v4.s}[1], [x0], x1
    ushll           v4.8h, v4.8b, #0

    // row[0-1]
    mul             v16.8h, v0.8h, v24.8h
    ext             v21.16b, v0.16b, v1.16b, #8
    mul             v17.8h, v21.8h, v24.8h
    mov             v0.16b, v1.16b

    // row[2-3]
    mla             v16.8h, v1.8h, v26.8h
    ext             v21.16b, v1.16b, v2.16b, #8
    mla             v17.8h, v21.8h, v26.8h
    mov             v1.16b, v2.16b

    // row[4-5]
    mla             v16.8h, v2.8h, v28.8h
    ext             v21.16b, v2.16b, v3.16b, #8
    mla             v17.8h, v21.8h, v28.8h
    mov             v2.16b, v3.16b

    // row[6-7]
    mla             v16.8h, v3.8h, v30.8h
    ext             v21.16b, v3.16b, v4.16b, #8
    mla             v17.8h, v21.8h, v30.8h
    mov             v3.16b, v4.16b

    // sum row[0-7]
    trn1            v20.2d, v16.2d, v17.2d
    trn2            v21.2d, v16.2d, v17.2d
    add             v16.8h, v20.8h, v21.8h

    sqrshrun        v16.8b,  v16.8h,  #6
    st1             {v16.s}[0], [x2], x3
    st1             {v16.s}[1], [x2], x3

    sub             x9, x9, #2
    cbnz            x9, .loop_4x\h
    ret
endfunc
.endm

LUMA_VPP_4xN_NEON 4
LUMA_VPP_4xN_NEON 8
LUMA_VPP_4xN_NEON 16

.macro vpp_end
    add             v17.8h, v17.8h, v31.8h
    sqshrun         v17.8b, v17.8h, #6
.endm

.macro vpp_end_sve2
    add             z17.h, z17.h, z31.h
    sqshrun         v17.8b, v17.8h, #6
.endm

.macro FILTER_LUMA_VPP_NEON w, h, v
    lsl             x10, x1, #2      // x10 = 4 * x1
    sub             x11, x10, x1     // x11 = 3 * x1
    sub             x0, x0, x11      // src -= (8 / 2 - 1) * srcStride
    mov             x5, #\h
    mov             w12, #32
    dup             v31.8h, w12
    qpel_start_\v
.loop_luma_vpp_\v\()_\w\()x\h:
    mov             x7, x2
    mov             x9, #0
.loop_luma_vpp_w8_\v\()_\w\()x\h:
    add             x6, x0, x9
.if \w == 8 || \w == 24
    qpel_load_32b \v
    qpel_filter_\v\()_32b
    vpp_end
    str             d17, [x7], #8
    add             x9, x9, #8
.elseif \w == 12
    qpel_load_32b \v
    qpel_filter_\v\()_32b
    vpp_end
    str             d17, [x7], #8
    add             x6, x0, #8
    qpel_load_32b \v
    qpel_filter_\v\()_32b
    vpp_end
    fmov            w6, s17
    str             w6, [x7], #4
    add             x9, x9, #12
.else
    qpel_load_64b \v
    qpel_filter_\v\()_64b
    vpp_end
    add             v18.8h, v18.8h, v31.8h
    sqshrun2        v17.16b, v18.8h, #6
    str             q17, [x7], #16
    add             x9, x9, #16
.endif
    cmp             x9, #\w
    blt             .loop_luma_vpp_w8_\v\()_\w\()x\h
    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .loop_luma_vpp_\v\()_\w\()x\h
    ret
.endm

// void interp_vert_pp_c(const pixel* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx)
.macro LUMA_VPP_NEON w, h
function x265_interp_8tap_vert_pp_\w\()x\h\()_neon
    cmp             x4, #0
    b.eq            0f
    cmp             x4, #1
    b.eq            1f
    cmp             x4, #2
    b.eq            2f
    cmp             x4, #3
    b.eq            3f
0:
    FILTER_LUMA_VPP_NEON \w, \h, 0
1:
    FILTER_LUMA_VPP_NEON \w, \h, 1
2:
    FILTER_LUMA_VPP_NEON \w, \h, 2
3:
    FILTER_LUMA_VPP_NEON \w, \h, 3
endfunc
.endm

LUMA_VPP_NEON 8, 4
LUMA_VPP_NEON 8, 8
LUMA_VPP_NEON 8, 16
LUMA_VPP_NEON 8, 32
LUMA_VPP_NEON 12, 16
LUMA_VPP_NEON 16, 4
LUMA_VPP_NEON 16, 8
LUMA_VPP_NEON 16, 16
LUMA_VPP_NEON 16, 32
LUMA_VPP_NEON 16, 64
LUMA_VPP_NEON 16, 12
LUMA_VPP_NEON 24, 32
LUMA_VPP_NEON 32, 8
LUMA_VPP_NEON 32, 16
LUMA_VPP_NEON 32, 32
LUMA_VPP_NEON 32, 64
LUMA_VPP_NEON 32, 24
LUMA_VPP_NEON 48, 64
LUMA_VPP_NEON 64, 16
LUMA_VPP_NEON 64, 32
LUMA_VPP_NEON 64, 64
LUMA_VPP_NEON 64, 48

.macro FILTER_LUMA_VPP_SVE2 w, h, v
    lsl             x10, x1, #2      // x10 = 4 * x1
    sub             x11, x10, x1     // x11 = 3 * x1
    sub             x0, x0, x11      // src -= (8 / 2 - 1) * srcStride
    mov             x5, #\h
    mov             z31.h, #32
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_FILTER_LUMA_VPP_\v\()_\w\()x\h
    ptrue           p0.h, vl8
    qpel_start_sve2_\v
.loop_luma_vpp_sve2_\v\()_\w\()x\h:
    mov             x7, x2
    mov             x9, #0
.loop_luma_vpp_w8_sve2_\v\()_\w\()x\h:
    add             x6, x0, x9
.if \w == 8 || \w == 24
    qpel_load_32b_sve2 \v
    qpel_filter_sve2_\v\()_32b
    vpp_end_sve2
    str             d17, [x7], #8
    add             x9, x9, #8
.elseif \w == 12
    qpel_load_32b_sve2 \v
    qpel_filter_sve2_\v\()_32b
    vpp_end_sve2
    str             d17, [x7], #8
    add             x6, x0, #8
    qpel_load_32b_sve2 \v
    qpel_filter_sve2_\v\()_32b
    vpp_end_sve2
    fmov            w6, s17
    str             w6, [x7], #4
    add             x9, x9, #12
.else
    qpel_load_64b_sve2 \v
    qpel_filter_sve2_\v\()_64b
    vpp_end_sve2
    add             z18.h, z18.h, z31.h
    sqshrun2        v17.16b, v18.8h, #6
    str             q17, [x7], #16
    add             x9, x9, #16
.endif
    cmp             x9, #\w
    blt             .loop_luma_vpp_w8_sve2_\v\()_\w\()x\h
    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .loop_luma_vpp_sve2_\v\()_\w\()x\h
    ret
.vl_gt_16_FILTER_LUMA_VPP_\v\()_\w\()x\h:
    ptrue           p0.h, vl8
    ptrue           p2.h, vl16
    qpel_start_sve2_\v
.gt_16_loop_luma_vpp_sve2_\v\()_\w\()x\h:
    mov             x7, x2
    mov             x9, #0
.gt_16_loop_luma_vpp_w8_sve2_\v\()_\w\()x\h:
    add             x6, x0, x9
.if \w == 8 || \w == 24
    qpel_load_32b_sve2 \v
    qpel_filter_sve2_\v\()_32b
    vpp_end_sve2
    str             d17, [x7], #8
    add             x9, x9, #8
.elseif \w == 12
    qpel_load_32b_sve2 \v
    qpel_filter_sve2_\v\()_32b
    vpp_end_sve2
    str             d17, [x7], #8
    add             x6, x0, #8
    qpel_load_32b_sve2 \v
    qpel_filter_sve2_\v\()_32b
    vpp_end_sve2
    fmov            w6, s17
    str             w6, [x7], #4
    add             x9, x9, #12
.else
    qpel_load_64b_sve2_gt_16 \v
    qpel_filter_sve2_\v\()_32b
    vpp_end_sve2
    add             z18.h, z18.h, z31.h
    sqshrun2        v17.16b, v18.8h, #6
    str             q17, [x7], #16
    add             x9, x9, #16
.endif
    cmp             x9, #\w
    blt             .gt_16_loop_luma_vpp_w8_sve2_\v\()_\w\()x\h
    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .gt_16_loop_luma_vpp_sve2_\v\()_\w\()x\h
    ret
.endm

// void interp_vert_pp_c(const pixel* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx)
.macro LUMA_VPP_SVE2 w, h
function x265_interp_8tap_vert_pp_\w\()x\h\()_sve2
    cmp             x4, #0
    b.eq            0f
    cmp             x4, #1
    b.eq            1f
    cmp             x4, #2
    b.eq            2f
    cmp             x4, #3
    b.eq            3f
0:
    FILTER_LUMA_VPP_SVE2 \w, \h, 0
1:
    FILTER_LUMA_VPP_SVE2 \w, \h, 1
2:
    FILTER_LUMA_VPP_SVE2 \w, \h, 2
3:
    FILTER_LUMA_VPP_SVE2 \w, \h, 3
endfunc
.endm

LUMA_VPP_SVE2 8, 4
LUMA_VPP_SVE2 8, 8
LUMA_VPP_SVE2 8, 16
LUMA_VPP_SVE2 8, 32
LUMA_VPP_SVE2 12, 16
LUMA_VPP_SVE2 16, 4
LUMA_VPP_SVE2 16, 8
LUMA_VPP_SVE2 16, 16
LUMA_VPP_SVE2 16, 32
LUMA_VPP_SVE2 16, 64
LUMA_VPP_SVE2 16, 12
LUMA_VPP_SVE2 24, 32
LUMA_VPP_SVE2 32, 8
LUMA_VPP_SVE2 32, 16
LUMA_VPP_SVE2 32, 32
LUMA_VPP_SVE2 32, 64
LUMA_VPP_SVE2 32, 24
LUMA_VPP_SVE2 48, 64
LUMA_VPP_SVE2 64, 16
LUMA_VPP_SVE2 64, 32
LUMA_VPP_SVE2 64, 64
LUMA_VPP_SVE2 64, 48

// ***** luma_vps *****
// void interp_vert_ps_c(const pixel* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx)
.macro LUMA_VPS_4xN_NEON h
function x265_interp_8tap_vert_ps_4x\h\()_neon
    lsl             x3, x3, #1
    lsl             x5, x4, #6
    lsl             x4, x1, #2
    sub             x4, x4, x1
    sub             x0, x0, x4

    mov             w6, #8192
    dup             v28.4s, w6
    mov             x4, #\h
    movrel          x12, g_lumaFilter
    add             x12, x12, x5
    ld1r            {v16.2d}, [x12], #8
    ld1r            {v17.2d}, [x12], #8
    ld1r            {v18.2d}, [x12], #8
    ld1r            {v19.2d}, [x12], #8
    ld1r            {v20.2d}, [x12], #8
    ld1r            {v21.2d}, [x12], #8
    ld1r            {v22.2d}, [x12], #8
    ld1r            {v23.2d}, [x12], #8

.loop_vps_4x\h:
    mov             x6, x0

    ld1             {v0.s}[0], [x6], x1
    ld1             {v1.s}[0], [x6], x1
    ld1             {v2.s}[0], [x6], x1
    ld1             {v3.s}[0], [x6], x1
    ld1             {v4.s}[0], [x6], x1
    ld1             {v5.s}[0], [x6], x1
    ld1             {v6.s}[0], [x6], x1
    ld1             {v7.s}[0], [x6], x1
    uxtl            v0.8h, v0.8b
    uxtl            v0.4s, v0.4h

    uxtl            v1.8h, v1.8b
    uxtl            v1.4s, v1.4h
    mul             v0.4s, v0.4s, v16.4s

    uxtl            v2.8h, v2.8b
    uxtl            v2.4s, v2.4h
    mla             v0.4s, v1.4s, v17.4s

    uxtl            v3.8h, v3.8b
    uxtl            v3.4s, v3.4h
    mla             v0.4s, v2.4s, v18.4s

    uxtl            v4.8h, v4.8b
    uxtl            v4.4s, v4.4h
    mla             v0.4s, v3.4s, v19.4s

    uxtl            v5.8h, v5.8b
    uxtl            v5.4s, v5.4h
    mla             v0.4s, v4.4s, v20.4s

    uxtl            v6.8h, v6.8b
    uxtl            v6.4s, v6.4h
    mla             v0.4s, v5.4s, v21.4s

    uxtl            v7.8h, v7.8b
    uxtl            v7.4s, v7.4h
    mla             v0.4s, v6.4s, v22.4s

    mla             v0.4s, v7.4s, v23.4s

    sub             v0.4s, v0.4s, v28.4s
    sqxtn           v0.4h, v0.4s
    st1             {v0.8b}, [x2], x3

    add             x0, x0, x1
    sub             x4, x4, #1
    cbnz            x4, .loop_vps_4x\h
    ret
endfunc
.endm

LUMA_VPS_4xN_NEON 4
LUMA_VPS_4xN_NEON 8
LUMA_VPS_4xN_NEON 16


// void interp_vert_ps_c(const pixel* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx)
.macro LUMA_VPS_4xN_SVE2 h
function x265_interp_8tap_vert_ps_4x\h\()_sve2
    lsl             x3, x3, #1
    lsl             x5, x4, #6
    lsl             x4, x1, #2
    sub             x4, x4, x1
    sub             x0, x0, x4

    mov             z28.s, #8192
    mov             x4, #\h
    movrel          x12, g_lumaFilter
    add             x12, x12, x5
    ptrue           p0.s, vl4
    ld1rd           {z16.d}, p0/z, [x12]
    ld1rd           {z17.d}, p0/z, [x12, #8]
    ld1rd           {z18.d}, p0/z, [x12, #16]
    ld1rd           {z19.d}, p0/z, [x12, #24]
    ld1rd           {z20.d}, p0/z, [x12, #32]
    ld1rd           {z21.d}, p0/z, [x12, #40]
    ld1rd           {z22.d}, p0/z, [x12, #48]
    ld1rd           {z23.d}, p0/z, [x12, #56]

.loop_vps_sve2_4x\h:
    mov             x6, x0

    ld1b            {z0.s}, p0/z, [x6]
    add             x6, x6, x1
    ld1b            {z1.s}, p0/z, [x6]
    add             x6, x6, x1
    ld1b            {z2.s}, p0/z, [x6]
    add             x6, x6, x1
    ld1b            {z3.s}, p0/z, [x6]
    add             x6, x6, x1
    ld1b            {z4.s}, p0/z, [x6]
    add             x6, x6, x1
    ld1b            {z5.s}, p0/z, [x6]
    add             x6, x6, x1
    ld1b            {z6.s}, p0/z, [x6]
    add             x6, x6, x1
    ld1b            {z7.s}, p0/z, [x6]
    add             x6, x6, x1

    mul             z0.s, z0.s, z16.s
    mla             z0.s, p0/m, z1.s, z17.s
    mla             z0.s, p0/m, z2.s, z18.s
    mla             z0.s, p0/m, z3.s, z19.s
    mla             z0.s, p0/m, z4.s, z20.s
    mla             z0.s, p0/m, z5.s, z21.s
    mla             z0.s, p0/m, z6.s, z22.s
    mla             z0.s, p0/m, z7.s, z23.s

    sub             z0.s, z0.s, z28.s
    sqxtn           v0.4h, v0.4s
    st1             {v0.8b}, [x2], x3

    add             x0, x0, x1
    sub             x4, x4, #1
    cbnz            x4, .loop_vps_sve2_4x\h
    ret
endfunc
.endm

LUMA_VPS_4xN_SVE2 4
LUMA_VPS_4xN_SVE2 8
LUMA_VPS_4xN_SVE2 16

.macro vps_end
    sub             v17.8h, v17.8h, v31.8h
.endm

.macro vps_end_sve2
    sub             z17.h, z17.h, z31.h
.endm

.macro FILTER_VPS_NEON w, h, v
    lsl             x3, x3, #1
    lsl             x10, x1, #2      // x10 = 4 * x1
    sub             x11, x10, x1     // x11 = 3 * x1
    sub             x0, x0, x11      // src -= (8 / 2 - 1) * srcStride
    mov             x5, #\h
    mov             w12, #8192
    dup             v31.8h, w12
    qpel_start_\v
.loop_ps_\v\()_\w\()x\h:
    mov             x7, x2
    mov             x9, #0
.loop_ps_w8_\v\()_\w\()x\h:
    add             x6, x0, x9
.if \w == 8 || \w == 24
    qpel_load_32b \v
    qpel_filter_\v\()_32b
    vps_end
    str             q17, [x7], #16
    add             x9, x9, #8
.elseif \w == 12
    qpel_load_32b \v
    qpel_filter_\v\()_32b
    vps_end
    str             q17, [x7], #16
    add             x6, x0, #8
    qpel_load_32b \v
    qpel_filter_\v\()_32b
    vps_end
    str             d17, [x7], #8
    add             x9, x9, #12
.else
    qpel_load_64b \v
    qpel_filter_\v\()_64b
    vps_end
    sub             v18.8h, v18.8h, v31.8h
    stp             q17, q18, [x7], #32
    add             x9, x9, #16
.endif
    cmp             x9, #\w
    blt             .loop_ps_w8_\v\()_\w\()x\h
    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .loop_ps_\v\()_\w\()x\h
    ret
.endm

// void interp_vert_ps_c(const pixel* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx)
.macro LUMA_VPS_NEON w, h
function x265_interp_8tap_vert_ps_\w\()x\h\()_neon
    cmp             x4, #0
    beq             0f
    cmp             x4, #1
    beq             1f
    cmp             x4, #2
    beq             2f
    cmp             x4, #3
    beq             3f
0:
    FILTER_VPS_NEON \w, \h, 0
1:
    FILTER_VPS_NEON \w, \h, 1
2:
    FILTER_VPS_NEON \w, \h, 2
3:
    FILTER_VPS_NEON \w, \h, 3
endfunc
.endm

LUMA_VPS_NEON 8, 4
LUMA_VPS_NEON 8, 8
LUMA_VPS_NEON 8, 16
LUMA_VPS_NEON 8, 32
LUMA_VPS_NEON 12, 16
LUMA_VPS_NEON 16, 4
LUMA_VPS_NEON 16, 8
LUMA_VPS_NEON 16, 16
LUMA_VPS_NEON 16, 32
LUMA_VPS_NEON 16, 64
LUMA_VPS_NEON 16, 12
LUMA_VPS_NEON 24, 32
LUMA_VPS_NEON 32, 8
LUMA_VPS_NEON 32, 16
LUMA_VPS_NEON 32, 32
LUMA_VPS_NEON 32, 64
LUMA_VPS_NEON 32, 24
LUMA_VPS_NEON 48, 64
LUMA_VPS_NEON 64, 16
LUMA_VPS_NEON 64, 32
LUMA_VPS_NEON 64, 64
LUMA_VPS_NEON 64, 48

.macro FILTER_VPS_SVE2 w, h, v
    lsl             x3, x3, #1
    lsl             x10, x1, #2      // x10 = 4 * x1
    sub             x11, x10, x1     // x11 = 3 * x1
    sub             x0, x0, x11      // src -= (8 / 2 - 1) * srcStride
    mov             x5, #\h
    mov             z31.h, #8192
    rdvl            x14, #1
    cmp             x14, #16
    bgt             .vl_gt_16_FILTER_VPS_\v\()_\w\()x\h
    ptrue           p0.h, vl8
    qpel_start_sve2_\v
.loop_ps_sve2_\v\()_\w\()x\h:
    mov             x7, x2
    mov             x9, #0
.loop_ps_w8_sve2_\v\()_\w\()x\h:
    add             x6, x0, x9
.if \w == 8 || \w == 24
    qpel_load_32b_sve2 \v
    qpel_filter_sve2_\v\()_32b
    vps_end_sve2
    str             q17, [x7], #16
    add             x9, x9, #8
.elseif \w == 12
    qpel_load_32b_sve2 \v
    qpel_filter_sve2_\v\()_32b
    vps_end_sve2
    str             q17, [x7], #16
    add             x6, x0, #8
    qpel_load_32b_sve2 \v
    qpel_filter_sve2_\v\()_32b
    vps_end_sve2
    str             d17, [x7], #8
    add             x9, x9, #12
.else
    qpel_load_64b_sve2 \v
    qpel_filter_sve2_\v\()_64b
    vps_end_sve2
    sub             z18.h, z18.h, z31.h
    stp             q17, q18, [x7], #32
    add             x9, x9, #16
.endif
    cmp             x9, #\w
    blt             .loop_ps_w8_sve2_\v\()_\w\()x\h
    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .loop_ps_sve2_\v\()_\w\()x\h
    ret
.vl_gt_16_FILTER_VPS_\v\()_\w\()x\h:
    ptrue           p0.h, vl8
    ptrue           p2.h, vl16
    qpel_start_sve2_\v
.gt_16_loop_ps_sve2_\v\()_\w\()x\h:
    mov             x7, x2
    mov             x9, #0
.gt_16_loop_ps_w8_sve2_\v\()_\w\()x\h:
    add             x6, x0, x9
.if \w == 8 || \w == 24
    qpel_load_32b_sve2 \v
    qpel_filter_sve2_\v\()_32b
    vps_end_sve2
    str             q17, [x7], #16
    add             x9, x9, #8
.elseif \w == 12
    qpel_load_32b_sve2 \v
    qpel_filter_sve2_\v\()_32b
    vps_end_sve2
    str             q17, [x7], #16
    add             x6, x0, #8
    qpel_load_32b_sve2 \v
    qpel_filter_sve2_\v\()_32b
    vps_end_sve2
    str             d17, [x7], #8
    add             x9, x9, #12
.else
    qpel_load_64b_sve2_gt_16 \v
    qpel_filter_sve2_\v\()_32b
    vps_end_sve2
    sub             z18.h, z18.h, z31.h
    stp             q17, q18, [x7], #32
    add             x9, x9, #16
.endif
    cmp             x9, #\w
    blt             .gt_16_loop_ps_w8_sve2_\v\()_\w\()x\h
    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .gt_16_loop_ps_sve2_\v\()_\w\()x\h
    ret
.endm

// void interp_vert_ps_c(const pixel* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx)
.macro LUMA_VPS_SVE2 w, h
function x265_interp_8tap_vert_ps_\w\()x\h\()_sve2
    cmp             x4, #0
    beq             0f
    cmp             x4, #1
    beq             1f
    cmp             x4, #2
    beq             2f
    cmp             x4, #3
    beq             3f
0:
    FILTER_VPS_SVE2 \w, \h, 0
1:
    FILTER_VPS_SVE2 \w, \h, 1
2:
    FILTER_VPS_SVE2 \w, \h, 2
3:
    FILTER_VPS_SVE2 \w, \h, 3
endfunc
.endm

LUMA_VPS_SVE2 8, 4
LUMA_VPS_SVE2 8, 8
LUMA_VPS_SVE2 8, 16
LUMA_VPS_SVE2 8, 32
LUMA_VPS_SVE2 12, 16
LUMA_VPS_SVE2 16, 4
LUMA_VPS_SVE2 16, 8
LUMA_VPS_SVE2 16, 16
LUMA_VPS_SVE2 16, 32
LUMA_VPS_SVE2 16, 64
LUMA_VPS_SVE2 16, 12
LUMA_VPS_SVE2 24, 32
LUMA_VPS_SVE2 32, 8
LUMA_VPS_SVE2 32, 16
LUMA_VPS_SVE2 32, 32
LUMA_VPS_SVE2 32, 64
LUMA_VPS_SVE2 32, 24
LUMA_VPS_SVE2 48, 64
LUMA_VPS_SVE2 64, 16
LUMA_VPS_SVE2 64, 32
LUMA_VPS_SVE2 64, 64
LUMA_VPS_SVE2 64, 48

// ***** luma_vsp *****
// void interp_vert_sp_c(const int16_t* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx)
.macro LUMA_VSP_4xN_NEON h
function x265_interp_8tap_vert_sp_4x\h\()_neon
    lsl             x5, x4, #6
    lsl             x1, x1, #1
    lsl             x4, x1, #2
    sub             x4, x4, x1
    sub             x0, x0, x4

    mov             w12, #1
    lsl             w12, w12, #19
    add             w12, w12, #2048
    dup             v24.4s, w12
    mov             x4, #\h
    movrel          x12, g_lumaFilter
    add             x12, x12, x5
    ld1r            {v16.2d}, [x12], #8
    ld1r            {v17.2d}, [x12], #8
    ld1r            {v18.2d}, [x12], #8
    ld1r            {v19.2d}, [x12], #8
    ld1r            {v20.2d}, [x12], #8
    ld1r            {v21.2d}, [x12], #8
    ld1r            {v22.2d}, [x12], #8
    ld1r            {v23.2d}, [x12], #8
.loop_vsp_4x\h:
    mov             x6, x0

    ld1             {v0.8b}, [x6], x1
    ld1             {v1.8b}, [x6], x1
    ld1             {v2.8b}, [x6], x1
    ld1             {v3.8b}, [x6], x1
    ld1             {v4.8b}, [x6], x1
    ld1             {v5.8b}, [x6], x1
    ld1             {v6.8b}, [x6], x1
    ld1             {v7.8b}, [x6], x1

    sshll           v0.4s, v0.4h, #0
    sshll           v1.4s, v1.4h, #0
    mul             v0.4s, v0.4s, v16.4s
    sshll           v2.4s, v2.4h, #0
    mla             v0.4s, v1.4s, v17.4s
    sshll           v3.4s, v3.4h, #0
    mla             v0.4s, v2.4s, v18.4s
    sshll           v4.4s, v4.4h, #0
    mla             v0.4s, v3.4s, v19.4s
    sshll           v5.4s, v5.4h, #0
    mla             v0.4s, v4.4s, v20.4s
    sshll           v6.4s, v6.4h, #0
    mla             v0.4s, v5.4s, v21.4s
    sshll           v7.4s, v7.4h, #0
    mla             v0.4s, v6.4s, v22.4s

    mla             v0.4s, v7.4s, v23.4s

    add             v0.4s, v0.4s, v24.4s
    sqshrun         v0.4h, v0.4s, #12
    sqxtun          v0.8b, v0.8h
    st1             {v0.s}[0], [x2], x3

    add             x0, x0, x1
    sub             x4, x4, #1
    cbnz            x4, .loop_vsp_4x\h
    ret
endfunc
.endm

LUMA_VSP_4xN_NEON 4
LUMA_VSP_4xN_NEON 8
LUMA_VSP_4xN_NEON 16

// void interp_vert_sp_c(const int16_t* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx)
.macro LUMA_VSP_4xN_SVE2 h
function x265_interp_8tap_vert_sp_4x\h\()_sve2
    lsl             x5, x4, #6
    lsl             x1, x1, #1
    lsl             x4, x1, #2
    sub             x4, x4, x1
    sub             x0, x0, x4

    mov             w12, #1
    lsl             w12, w12, #19
    add             w12, w12, #2048
    dup             v24.4s, w12
    mov             x4, #\h
    movrel          x12, g_lumaFilter
    add             x12, x12, x5

    ptrue           p0.s, vl4
    ld1rd           {z16.d}, p0/z, [x12]
    ld1rd           {z17.d}, p0/z, [x12, #8]
    ld1rd           {z18.d}, p0/z, [x12, #16]
    ld1rd           {z19.d}, p0/z, [x12, #24]
    ld1rd           {z20.d}, p0/z, [x12, #32]
    ld1rd           {z21.d}, p0/z, [x12, #40]
    ld1rd           {z22.d}, p0/z, [x12, #48]
    ld1rd           {z23.d}, p0/z, [x12, #56]

.loop_vsp_sve2_4x\h:
    mov             x6, x0

    ld1             {v0.8b}, [x6], x1
    ld1             {v1.8b}, [x6], x1
    ld1             {v2.8b}, [x6], x1
    ld1             {v3.8b}, [x6], x1
    ld1             {v4.8b}, [x6], x1
    ld1             {v5.8b}, [x6], x1
    ld1             {v6.8b}, [x6], x1
    ld1             {v7.8b}, [x6], x1

    sunpklo         z0.s, z0.h
    sunpklo         z1.s, z1.h
    mul             z0.s, z0.s, z16.s
    sunpklo         z2.s, z2.h
    mla             z0.s, p0/m, z1.s, z17.s
    sunpklo         z3.s, z3.h
    mla             z0.s, p0/m, z2.s, z18.s
    sunpklo         z4.s, z4.h
    mla             z0.s, p0/m, z3.s, z19.s
    sunpklo         z5.s, z5.h
    mla             z0.s, p0/m, z4.s, z20.s
    sunpklo         z6.s, z6.h
    mla             z0.s, p0/m, z5.s, z21.s
    sunpklo         z7.s, z7.h
    mla             z0.s, p0/m, z6.s, z22.s

    mla             z0.s, p0/m, z7.s, z23.s

    add             z0.s, z0.s, z24.s
    sqshrun         v0.4h, v0.4s, #12
    sqxtun          v0.8b, v0.8h
    st1             {v0.s}[0], [x2], x3

    add             x0, x0, x1
    sub             x4, x4, #1
    cbnz            x4, .loop_vsp_sve2_4x\h
    ret
endfunc
.endm

LUMA_VSP_4xN_SVE2 4
LUMA_VSP_4xN_SVE2 8
LUMA_VSP_4xN_SVE2 16

.macro vsp_end
    add             v17.4s, v17.4s, v31.4s
    add             v18.4s, v18.4s, v31.4s
    sqshrun         v17.4h, v17.4s, #12
    sqshrun2        v17.8h, v18.4s, #12
    sqxtun          v17.8b, v17.8h
.endm

.macro FILTER_VSP_NEON w, h, v
    lsl             x1, x1, #1
    lsl             x10, x1, #2      // x10 = 4 * x1
    sub             x11, x10, x1     // x11 = 3 * x1
    sub             x0, x0, x11
    mov             x5, #\h
    mov             w12, #1
    lsl             w12, w12, #19
    add             w12, w12, #2048
    dup             v31.4s, w12
    mov             x12, #\w
    lsl             x12, x12, #1
    qpel_start_\v\()_1
.loop_luma_vsp_\v\()_\w\()x\h:
    mov             x7, x2
    mov             x9, #0
.loop_luma_vsp_w8_\v\()_\w\()x\h:
    add             x6, x0, x9
    qpel_load_64b \v
    qpel_filter_\v\()_32b_1
    vsp_end
    str             d17, [x7], #8
    add             x9, x9, #16
.if \w == 12
    add             x6, x0, #16
    qpel_load_64b \v
    qpel_filter_\v\()_32b_1
    vsp_end
    str             s17, [x7], #4
    add             x9, x9, #8
.endif
    cmp             x9, x12
    blt             .loop_luma_vsp_w8_\v\()_\w\()x\h
    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .loop_luma_vsp_\v\()_\w\()x\h
    ret
.endm

// void interp_vert_sp_c(const int16_t* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx)
.macro LUMA_VSP_NEON w, h
function x265_interp_8tap_vert_sp_\w\()x\h\()_neon
    cmp             x4, #0
    beq             0f
    cmp             x4, #1
    beq             1f
    cmp             x4, #2
    beq             2f
    cmp             x4, #3
    beq             3f
0:
    FILTER_VSP_NEON \w, \h, 0
1:
    FILTER_VSP_NEON \w, \h, 1
2:
    FILTER_VSP_NEON \w, \h, 2
3:
    FILTER_VSP_NEON \w, \h, 3
endfunc
.endm

LUMA_VSP_NEON 8, 4
LUMA_VSP_NEON 8, 8
LUMA_VSP_NEON 8, 16
LUMA_VSP_NEON 8, 32
LUMA_VSP_NEON 12, 16
LUMA_VSP_NEON 16, 4
LUMA_VSP_NEON 16, 8
LUMA_VSP_NEON 16, 16
LUMA_VSP_NEON 16, 32
LUMA_VSP_NEON 16, 64
LUMA_VSP_NEON 16, 12
LUMA_VSP_NEON 32, 8
LUMA_VSP_NEON 32, 16
LUMA_VSP_NEON 32, 32
LUMA_VSP_NEON 32, 64
LUMA_VSP_NEON 32, 24
LUMA_VSP_NEON 64, 16
LUMA_VSP_NEON 64, 32
LUMA_VSP_NEON 64, 64
LUMA_VSP_NEON 64, 48
LUMA_VSP_NEON 24, 32
LUMA_VSP_NEON 48, 64

// ***** luma_vss *****
.macro vss_end
    sshr            v17.4s, v17.4s, #6
    sshr            v18.4s, v18.4s, #6
    uzp1            v17.8h, v17.8h, v18.8h
.endm

.macro vss_end_sve2
    asr             z17.s, z17.s, #6
    asr             z18.s, z18.s, #6
    uzp1            v17.8h, v17.8h, v18.8h
.endm

.macro FILTER_VSS_NEON w, h, v
    lsl             x1, x1, #1
    lsl             x10, x1, #2      // x10 = 4 * x1
    sub             x11, x10, x1     // x11 = 3 * x1
    sub             x0, x0, x11
    lsl             x3, x3, #1
    mov             x5, #\h
    mov             x12, #\w
    lsl             x12, x12, #1
    qpel_start_\v\()_1
.loop_luma_vss_\v\()_\w\()x\h:
    mov             x7, x2
    mov             x9, #0
.loop_luma_vss_w8_\v\()_\w\()x\h:
    add             x6, x0, x9
    qpel_load_64b \v
    qpel_filter_\v\()_32b_1
    vss_end
.if \w == 4
    str             s17, [x7], #4
    add             x9, x9, #4
.else
    str             q17, [x7], #16
    add             x9, x9, #16
.if \w == 12
    add             x6, x0, x9
    qpel_load_64b \v
    qpel_filter_\v\()_32b_1
    vss_end
    str             d17, [x7], #8
    add             x9, x9, #8
.endif
.endif
    cmp             x9, x12
    blt             .loop_luma_vss_w8_\v\()_\w\()x\h
    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .loop_luma_vss_\v\()_\w\()x\h
    ret
.endm

.macro FILTER_VSS_SVE2 w, h, v
    lsl             x1, x1, #1
    lsl             x10, x1, #2      // x10 = 4 * x1
    sub             x11, x10, x1     // x11 = 3 * x1
    sub             x0, x0, x11
    lsl             x3, x3, #1
    mov             x5, #\h
    mov             x12, #\w
    lsl             x12, x12, #1
    qpel_start_\v\()_1
.loop_luma_vss_sve2_\v\()_\w\()x\h:
    mov             x7, x2
    mov             x9, #0
.loop_luma_vss_w8_sve2_\v\()_\w\()x\h:
    add             x6, x0, x9
    qpel_load_64b \v
    qpel_filter_\v\()_32b_1
    vss_end_sve2
.if \w == 4
    str             s17, [x7], #4
    add             x9, x9, #4
.else
    str             q17, [x7], #16
    add             x9, x9, #16
.if \w == 12
    add             x6, x0, x9
    qpel_load_64b \v
    qpel_filter_\v\()_32b_1
    vss_end_sve2
    str             d17, [x7], #8
    add             x9, x9, #8
.endif
.endif
    cmp             x9, x12
    blt             .loop_luma_vss_w8_sve2_\v\()_\w\()x\h
    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .loop_luma_vss_sve2_\v\()_\w\()x\h
    ret
.endm

// void interp_vert_ss_c(const int16_t* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx)
.macro LUMA_VSS_NEON w, h
function x265_interp_8tap_vert_ss_\w\()x\h\()_neon
    cmp             x4, #0
    beq             0f
    cmp             x4, #1
    beq             1f
    cmp             x4, #2
    beq             2f
    cmp             x4, #3
    beq             3f
0:
    FILTER_VSS_NEON \w, \h, 0
1:
    FILTER_VSS_NEON \w, \h, 1
2:
    FILTER_VSS_NEON \w, \h, 2
3:
    FILTER_VSS_NEON \w, \h, 3
endfunc
.endm

LUMA_VSS_NEON 4, 4
LUMA_VSS_NEON 4, 8
LUMA_VSS_NEON 4, 16
LUMA_VSS_NEON 8, 4
LUMA_VSS_NEON 8, 8
LUMA_VSS_NEON 8, 16
LUMA_VSS_NEON 8, 32
LUMA_VSS_NEON 12, 16
LUMA_VSS_NEON 16, 4
LUMA_VSS_NEON 16, 8
LUMA_VSS_NEON 16, 16
LUMA_VSS_NEON 16, 32
LUMA_VSS_NEON 16, 64
LUMA_VSS_NEON 16, 12
LUMA_VSS_NEON 32, 8
LUMA_VSS_NEON 32, 16
LUMA_VSS_NEON 32, 32
LUMA_VSS_NEON 32, 64
LUMA_VSS_NEON 32, 24
LUMA_VSS_NEON 64, 16
LUMA_VSS_NEON 64, 32
LUMA_VSS_NEON 64, 64
LUMA_VSS_NEON 64, 48
LUMA_VSS_NEON 24, 32
LUMA_VSS_NEON 48, 64

// void interp_vert_ss_c(const int16_t* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx)
.macro LUMA_VSS_SVE2 w, h
function x265_interp_8tap_vert_ss_\w\()x\h\()_sve2
    cmp             x4, #0
    beq             0f
    cmp             x4, #1
    beq             1f
    cmp             x4, #2
    beq             2f
    cmp             x4, #3
    beq             3f
0:
    FILTER_VSS_SVE2 \w, \h, 0
1:
    FILTER_VSS_SVE2 \w, \h, 1
2:
    FILTER_VSS_SVE2 \w, \h, 2
3:
    FILTER_VSS_SVE2 \w, \h, 3
endfunc
.endm

LUMA_VSS_SVE2 4, 4
LUMA_VSS_SVE2 4, 8
LUMA_VSS_SVE2 4, 16
LUMA_VSS_SVE2 8, 4
LUMA_VSS_SVE2 8, 8
LUMA_VSS_SVE2 8, 16
LUMA_VSS_SVE2 8, 32
LUMA_VSS_SVE2 12, 16
LUMA_VSS_SVE2 16, 4
LUMA_VSS_SVE2 16, 8
LUMA_VSS_SVE2 16, 16
LUMA_VSS_SVE2 16, 32
LUMA_VSS_SVE2 16, 64
LUMA_VSS_SVE2 16, 12
LUMA_VSS_SVE2 32, 8
LUMA_VSS_SVE2 32, 16
LUMA_VSS_SVE2 32, 32
LUMA_VSS_SVE2 32, 64
LUMA_VSS_SVE2 32, 24
LUMA_VSS_SVE2 64, 16
LUMA_VSS_SVE2 64, 32
LUMA_VSS_SVE2 64, 64
LUMA_VSS_SVE2 64, 48
LUMA_VSS_SVE2 24, 32
LUMA_VSS_SVE2 48, 64

// ***** luma_hpp *****
.macro hpp_end
    add             v17.8h, v17.8h, v31.8h
    sqshrun         v17.8b, v17.8h, #6
.endm

.macro FILTER_HPP_NEON w, h, v
    mov             w6, #\h
    sub             x3, x3, #\w
    mov             w12, #32
    dup             v31.8h, w12
    qpel_start_\v
.if \w == 4
.rept \h
    mov             x11, x0
    sub             x11, x11, #4
    vextin8 \v
    qpel_filter_\v\()_32b
    hpp_end
    str             s17, [x2], #4
    add             x0, x0, x1
    add             x2, x2, x3
.endr
    ret
.else
.loop1_hpp_\v\()_\w\()x\h:
    mov             x7, #\w
    mov             x11, x0
    sub             x11, x11, #4
.loop2_hpp_\v\()_\w\()x\h:
    vextin8 \v
    qpel_filter_\v\()_32b
    hpp_end
    str             d17, [x2], #8
    sub             x11, x11, #8
    sub             x7, x7, #8
.if \w == 12
    vextin8 \v
    qpel_filter_\v\()_32b
    hpp_end
    str             s17, [x2], #4
    sub             x7, x7, #4
.endif
    cbnz            x7, .loop2_hpp_\v\()_\w\()x\h
    sub             x6, x6, #1
    add             x0, x0, x1
    add             x2, x2, x3
    cbnz            x6, .loop1_hpp_\v\()_\w\()x\h
    ret
.endif
.endm

// void interp_horiz_pp_c(const pixel* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx)
.macro LUMA_HPP_NEON w, h
function x265_interp_horiz_pp_\w\()x\h\()_neon
    cmp             x4, #0
    beq             0f
    cmp             x4, #1
    beq             1f
    cmp             x4, #2
    beq             2f
    cmp             x4, #3
    beq             3f
0:
    FILTER_HPP_NEON \w, \h, 0
1:
    FILTER_HPP_NEON \w, \h, 1
2:
    FILTER_HPP_NEON \w, \h, 2
3:
    FILTER_HPP_NEON \w, \h, 3
endfunc
.endm

LUMA_HPP_NEON 4, 4
LUMA_HPP_NEON 4, 8
LUMA_HPP_NEON 4, 16
LUMA_HPP_NEON 8, 4
LUMA_HPP_NEON 8, 8
LUMA_HPP_NEON 8, 16
LUMA_HPP_NEON 8, 32
LUMA_HPP_NEON 12, 16
LUMA_HPP_NEON 16, 4
LUMA_HPP_NEON 16, 8
LUMA_HPP_NEON 16, 12
LUMA_HPP_NEON 16, 16
LUMA_HPP_NEON 16, 32
LUMA_HPP_NEON 16, 64
LUMA_HPP_NEON 24, 32
LUMA_HPP_NEON 32, 8
LUMA_HPP_NEON 32, 16
LUMA_HPP_NEON 32, 24
LUMA_HPP_NEON 32, 32
LUMA_HPP_NEON 32, 64
LUMA_HPP_NEON 48, 64
LUMA_HPP_NEON 64, 16
LUMA_HPP_NEON 64, 32
LUMA_HPP_NEON 64, 48
LUMA_HPP_NEON 64, 64

// ***** luma_hps *****
.macro hps_end
    sub             v17.8h, v17.8h, v31.8h
.endm

.macro FILTER_HPS_NEON w, h, v
    sub             x3, x3, #\w
    lsl             x3, x3, #1
    mov             w12, #8192
    dup             v31.8h, w12
    qpel_start_\v
.if \w == 4
.loop_hps_\v\()_\w\()x\h\():
    mov             x11, x0
    sub             x11, x11, #4
    vextin8 \v
    qpel_filter_\v\()_32b
    hps_end
    str             d17, [x2], #8
    sub             w6, w6, #1
    add             x0, x0, x1
    add             x2, x2, x3
    cbnz            w6, .loop_hps_\v\()_\w\()x\h
    ret
.else
.loop1_hps_\v\()_\w\()x\h\():
    mov             w7, #\w
    mov             x11, x0
    sub             x11, x11, #4
.loop2_hps_\v\()_\w\()x\h\():
.if \w == 8 || \w == 12 || \w == 24
    vextin8 \v
    qpel_filter_\v\()_32b
    hps_end
    str             q17, [x2], #16
    sub             w7, w7, #8
    sub             x11, x11, #8
.if \w == 12
    vextin8 \v
    qpel_filter_\v\()_32b
    hps_end
    str             d17, [x2], #8
    sub             w7, w7, #4
.endif
.elseif \w == 16 || \w == 32 || \w == 48 || \w == 64
    vextin8_64 \v
    qpel_filter_\v\()_64b
    hps_end
    sub             v18.8h, v18.8h, v31.8h
    stp             q17, q18, [x2], #32
    sub             w7, w7, #16
    sub             x11, x11, #16
.endif
    cbnz            w7, .loop2_hps_\v\()_\w\()x\h
    sub             w6, w6, #1
    add             x0, x0, x1
    add             x2, x2, x3
    cbnz            w6, .loop1_hps_\v\()_\w\()x\h
    ret
.endif
.endm

// void interp_horiz_ps_c(const pixel* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx, int isRowExt)
.macro LUMA_HPS_NEON w, h
function x265_interp_horiz_ps_\w\()x\h\()_neon
    mov             w10, #\h
    cmp             w5, #0
    b.eq            6f
    sub             x0, x0, x1, lsl #2
    add             x0, x0, x1
    add             w10, w10, #7
6:
    mov             w6, w10
    cmp             w4, #0
    b.eq            0f
    cmp             w4, #1
    b.eq            1f
    cmp             w4, #2
    b.eq            2f
    cmp             w4, #3
    b.eq            3f
0:
    FILTER_HPS_NEON \w, \h, 0
1:
    FILTER_HPS_NEON \w, \h, 1
2:
    FILTER_HPS_NEON \w, \h, 2
3:
    FILTER_HPS_NEON \w, \h, 3
endfunc
.endm

LUMA_HPS_NEON 4, 4
LUMA_HPS_NEON 4, 8
LUMA_HPS_NEON 4, 16
LUMA_HPS_NEON 8, 4
LUMA_HPS_NEON 8, 8
LUMA_HPS_NEON 8, 16
LUMA_HPS_NEON 8, 32
LUMA_HPS_NEON 12, 16
LUMA_HPS_NEON 16, 4
LUMA_HPS_NEON 16, 8
LUMA_HPS_NEON 16, 12
LUMA_HPS_NEON 16, 16
LUMA_HPS_NEON 16, 32
LUMA_HPS_NEON 16, 64
LUMA_HPS_NEON 24, 32
LUMA_HPS_NEON 32, 8
LUMA_HPS_NEON 32, 16
LUMA_HPS_NEON 32, 24
LUMA_HPS_NEON 32, 32
LUMA_HPS_NEON 32, 64
LUMA_HPS_NEON 48, 64
LUMA_HPS_NEON 64, 16
LUMA_HPS_NEON 64, 32
LUMA_HPS_NEON 64, 48
LUMA_HPS_NEON 64, 64

// ***** chroma_vpp *****
.macro FILTER_CHROMA_VPP_NEON w, h, v
    qpel_start_chroma_\v
    mov             w12, #32
    dup             v31.8h, w12
    sub             x0, x0, x1
    mov             x5, #\h
.loop_chroma_vpp_\v\()_\w\()x\h:
    mov             x7, x2
    mov             x9, #0
.loop_chroma_vpp_w8_\v\()_\w\()x\h:
    add             x6, x0, x9
    qpel_chroma_load_32b \v
    qpel_filter_chroma_\v\()_32b
    vpp_end
    add             x9, x9, #8
.if \w == 2
    fmov            w12, s17
    strh            w12, [x7], #2
.elseif \w == 4
    str             s17, [x7], #4
.elseif \w == 6
    str             s17, [x7], #4
    umov            w12, v17.h[2]
    strh            w12, [x7], #2
.elseif \w == 12
    str             d17, [x7], #8
    add             x6, x0, x9
    qpel_chroma_load_32b \v
    qpel_filter_chroma_\v\()_32b
    vpp_end
    str             s17, [x7], #4
    add             x9, x9, #8
.else
    str             d17, [x7], #8
.endif
    cmp             x9, #\w
    blt             .loop_chroma_vpp_w8_\v\()_\w\()x\h
    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .loop_chroma_vpp_\v\()_\w\()x\h
    ret
.endm

// void interp_vert_pp_c(const pixel* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx)
.macro CHROMA_VPP_NEON w, h
function x265_interp_4tap_vert_pp_\w\()x\h\()_neon
    cmp             x4, #0
    beq             0f
    cmp             x4, #1
    beq             1f
    cmp             x4, #2
    beq             2f
    cmp             x4, #3
    beq             3f
    cmp             x4, #4
    beq             4f
    cmp             x4, #5
    beq             5f
    cmp             x4, #6
    beq             6f
    cmp             x4, #7
    beq             7f
0:
    FILTER_CHROMA_VPP_NEON  \w, \h, 0
1:
    FILTER_CHROMA_VPP_NEON  \w, \h, 1
2:
    FILTER_CHROMA_VPP_NEON  \w, \h, 2
3:
    FILTER_CHROMA_VPP_NEON  \w, \h, 3
4:
    FILTER_CHROMA_VPP_NEON  \w, \h, 4
5:
    FILTER_CHROMA_VPP_NEON  \w, \h, 5
6:
    FILTER_CHROMA_VPP_NEON  \w, \h, 6
7:
    FILTER_CHROMA_VPP_NEON  \w, \h, 7
endfunc
.endm

CHROMA_VPP_NEON 2, 4
CHROMA_VPP_NEON 2, 8
CHROMA_VPP_NEON 2, 16
CHROMA_VPP_NEON 4, 2
CHROMA_VPP_NEON 4, 4
CHROMA_VPP_NEON 4, 8
CHROMA_VPP_NEON 4, 16
CHROMA_VPP_NEON 4, 32
CHROMA_VPP_NEON 6, 8
CHROMA_VPP_NEON 6, 16
CHROMA_VPP_NEON 8, 2
CHROMA_VPP_NEON 8, 4
CHROMA_VPP_NEON 8, 6
CHROMA_VPP_NEON 8, 8
CHROMA_VPP_NEON 8, 16
CHROMA_VPP_NEON 8, 32
CHROMA_VPP_NEON 8, 12
CHROMA_VPP_NEON 8, 64
CHROMA_VPP_NEON 12, 16
CHROMA_VPP_NEON 12, 32
CHROMA_VPP_NEON 16, 4
CHROMA_VPP_NEON 16, 8
CHROMA_VPP_NEON 16, 12
CHROMA_VPP_NEON 16, 16
CHROMA_VPP_NEON 16, 32
CHROMA_VPP_NEON 16, 64
CHROMA_VPP_NEON 16, 24
CHROMA_VPP_NEON 32, 8
CHROMA_VPP_NEON 32, 16
CHROMA_VPP_NEON 32, 24
CHROMA_VPP_NEON 32, 32
CHROMA_VPP_NEON 32, 64
CHROMA_VPP_NEON 32, 48
CHROMA_VPP_NEON 24, 32
CHROMA_VPP_NEON 24, 64
CHROMA_VPP_NEON 64, 16
CHROMA_VPP_NEON 64, 32
CHROMA_VPP_NEON 64, 48
CHROMA_VPP_NEON 64, 64
CHROMA_VPP_NEON 48, 64

.macro FILTER_CHROMA_VPP_SVE2 w, h, v
    ptrue           p0.h, vl8
    qpel_start_chroma_sve2_\v
    mov             z31.h, #32
    sub             x0, x0, x1
    mov             x5, #\h
.loop_chroma_vpp_sve2_\v\()_\w\()x\h:
    mov             x7, x2
    mov             x9, #0
.loop_chroma_vpp_w8_sve2_\v\()_\w\()x\h:
    add             x6, x0, x9
    qpel_chroma_load_32b_sve2 \v
    qpel_filter_chroma_sve2_\v\()_32b
    vpp_end_sve2
    add             x9, x9, #8
.if \w == 2
    fmov            w12, s17
    strh            w12, [x7], #2
.elseif \w == 4
    str             s17, [x7], #4
.elseif \w == 6
    str             s17, [x7], #4
    umov            w12, v17.h[2]
    strh            w12, [x7], #2
.elseif \w == 12
    str             d17, [x7], #8
    add             x6, x0, x9
    qpel_chroma_load_32b_sve2 \v
    qpel_filter_chroma_sve2_\v\()_32b
    vpp_end_sve2
    str             s17, [x7], #4
    add             x9, x9, #8
.else
    str             d17, [x7], #8
.endif
    cmp             x9, #\w
    blt             .loop_chroma_vpp_w8_sve2_\v\()_\w\()x\h
    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .loop_chroma_vpp_sve2_\v\()_\w\()x\h
    ret
.endm

// void interp_vert_pp_c(const pixel* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx)
.macro CHROMA_VPP_SVE2 w, h
function x265_interp_4tap_vert_pp_\w\()x\h\()_sve2
    cmp             x4, #0
    beq             0f
    cmp             x4, #1
    beq             1f
    cmp             x4, #2
    beq             2f
    cmp             x4, #3
    beq             3f
    cmp             x4, #4
    beq             4f
    cmp             x4, #5
    beq             5f
    cmp             x4, #6
    beq             6f
    cmp             x4, #7
    beq             7f
0:
    FILTER_CHROMA_VPP_SVE2  \w, \h, 0
1:
    FILTER_CHROMA_VPP_SVE2  \w, \h, 1
2:
    FILTER_CHROMA_VPP_SVE2  \w, \h, 2
3:
    FILTER_CHROMA_VPP_SVE2  \w, \h, 3
4:
    FILTER_CHROMA_VPP_SVE2  \w, \h, 4
5:
    FILTER_CHROMA_VPP_SVE2  \w, \h, 5
6:
    FILTER_CHROMA_VPP_SVE2  \w, \h, 6
7:
    FILTER_CHROMA_VPP_SVE2  \w, \h, 7
endfunc
.endm

CHROMA_VPP_SVE2 2, 4
CHROMA_VPP_SVE2 2, 8
CHROMA_VPP_SVE2 2, 16
CHROMA_VPP_SVE2 4, 2
CHROMA_VPP_SVE2 4, 4
CHROMA_VPP_SVE2 4, 8
CHROMA_VPP_SVE2 4, 16
CHROMA_VPP_SVE2 4, 32
CHROMA_VPP_SVE2 6, 8
CHROMA_VPP_SVE2 6, 16
CHROMA_VPP_SVE2 8, 2
CHROMA_VPP_SVE2 8, 4
CHROMA_VPP_SVE2 8, 6
CHROMA_VPP_SVE2 8, 8
CHROMA_VPP_SVE2 8, 16
CHROMA_VPP_SVE2 8, 32
CHROMA_VPP_SVE2 8, 12
CHROMA_VPP_SVE2 8, 64
CHROMA_VPP_SVE2 12, 16
CHROMA_VPP_SVE2 12, 32
CHROMA_VPP_SVE2 16, 4
CHROMA_VPP_SVE2 16, 8
CHROMA_VPP_SVE2 16, 12
CHROMA_VPP_SVE2 16, 16
CHROMA_VPP_SVE2 16, 32
CHROMA_VPP_SVE2 16, 64
CHROMA_VPP_SVE2 16, 24
CHROMA_VPP_SVE2 32, 8
CHROMA_VPP_SVE2 32, 16
CHROMA_VPP_SVE2 32, 24
CHROMA_VPP_SVE2 32, 32
CHROMA_VPP_SVE2 32, 64
CHROMA_VPP_SVE2 32, 48
CHROMA_VPP_SVE2 24, 32
CHROMA_VPP_SVE2 24, 64
CHROMA_VPP_SVE2 64, 16
CHROMA_VPP_SVE2 64, 32
CHROMA_VPP_SVE2 64, 48
CHROMA_VPP_SVE2 64, 64
CHROMA_VPP_SVE2 48, 64

// ***** chroma_vps *****
.macro FILTER_CHROMA_VPS_NEON w, h, v
    qpel_start_chroma_\v
    mov             w12, #8192
    dup             v31.8h, w12
    lsl             x3, x3, #1
    sub             x0, x0, x1
    mov             x5, #\h
.loop_vps_\v\()_\w\()x\h:
    mov             x7, x2
    mov             x9, #0
.loop_vps_w8_\v\()_\w\()x\h:
    add             x6, x0, x9
    qpel_chroma_load_32b \v
    qpel_filter_chroma_\v\()_32b
    vps_end
    add             x9, x9, #8
.if \w == 2
    str             s17, [x7], #4
.elseif \w == 4
    str             d17, [x7], #8
.elseif \w == 6
    str             d17, [x7], #8
    st1             {v17.s}[2], [x7], #4
.elseif \w == 12
    str             q17, [x7], #16
    add             x6, x0, x9
    qpel_chroma_load_32b \v
    qpel_filter_chroma_\v\()_32b
    vps_end
    str             d17, [x7], #8
    add             x9, x9, #8
.else
    str             q17, [x7], #16
.endif
    cmp             x9, #\w
    blt             .loop_vps_w8_\v\()_\w\()x\h

    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .loop_vps_\v\()_\w\()x\h
    ret
.endm

// void interp_vert_ps_c(const pixel* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx)
.macro CHROMA_VPS_NEON w, h
function x265_interp_4tap_vert_ps_\w\()x\h\()_neon
    cmp             x4, #0
    beq             0f
    cmp             x4, #1
    beq             1f
    cmp             x4, #2
    beq             2f
    cmp             x4, #3
    beq             3f
    cmp             x4, #4
    beq             4f
    cmp             x4, #5
    beq             5f
    cmp             x4, #6
    beq             6f
    cmp             x4, #7
    beq             7f
0:
    FILTER_CHROMA_VPS_NEON  \w, \h, 0
1:
    FILTER_CHROMA_VPS_NEON  \w, \h, 1
2:
    FILTER_CHROMA_VPS_NEON  \w, \h, 2
3:
    FILTER_CHROMA_VPS_NEON  \w, \h, 3
4:
    FILTER_CHROMA_VPS_NEON  \w, \h, 4
5:
    FILTER_CHROMA_VPS_NEON  \w, \h, 5
6:
    FILTER_CHROMA_VPS_NEON  \w, \h, 6
7:
    FILTER_CHROMA_VPS_NEON  \w, \h, 7
endfunc
.endm

CHROMA_VPS_NEON 2, 4
CHROMA_VPS_NEON 2, 8
CHROMA_VPS_NEON 2, 16
CHROMA_VPS_NEON 4, 2
CHROMA_VPS_NEON 4, 4
CHROMA_VPS_NEON 4, 8
CHROMA_VPS_NEON 4, 16
CHROMA_VPS_NEON 4, 32
CHROMA_VPS_NEON 6, 8
CHROMA_VPS_NEON 6, 16
CHROMA_VPS_NEON 8, 2
CHROMA_VPS_NEON 8, 4
CHROMA_VPS_NEON 8, 6
CHROMA_VPS_NEON 8, 8
CHROMA_VPS_NEON 8, 16
CHROMA_VPS_NEON 8, 32
CHROMA_VPS_NEON 8, 12
CHROMA_VPS_NEON 8, 64
CHROMA_VPS_NEON 12, 16
CHROMA_VPS_NEON 12, 32
CHROMA_VPS_NEON 16, 4
CHROMA_VPS_NEON 16, 8
CHROMA_VPS_NEON 16, 12
CHROMA_VPS_NEON 16, 16
CHROMA_VPS_NEON 16, 32
CHROMA_VPS_NEON 16, 64
CHROMA_VPS_NEON 16, 24
CHROMA_VPS_NEON 32, 8
CHROMA_VPS_NEON 32, 16
CHROMA_VPS_NEON 32, 24
CHROMA_VPS_NEON 32, 32
CHROMA_VPS_NEON 32, 64
CHROMA_VPS_NEON 32, 48
CHROMA_VPS_NEON 24, 32
CHROMA_VPS_NEON 24, 64
CHROMA_VPS_NEON 64, 16
CHROMA_VPS_NEON 64, 32
CHROMA_VPS_NEON 64, 48
CHROMA_VPS_NEON 64, 64
CHROMA_VPS_NEON 48, 64

.macro FILTER_CHROMA_VPS_SVE2 w, h, v
    ptrue           p0.h, vl8
    qpel_start_chroma_sve2_\v
    mov             z31.h, #8192
    lsl             x3, x3, #1
    sub             x0, x0, x1
    mov             x5, #\h
.loop_vps_sve2_\v\()_\w\()x\h:
    mov             x7, x2
    mov             x9, #0
.loop_vps_w8_sve2_\v\()_\w\()x\h:
    add             x6, x0, x9
    qpel_chroma_load_32b_sve2 \v
    qpel_filter_chroma_sve2_\v\()_32b
    vps_end_sve2
    add             x9, x9, #8
.if \w == 2
    str             s17, [x7], #4
.elseif \w == 4
    str             d17, [x7], #8
.elseif \w == 6
    str             d17, [x7], #8
    st1             {v17.s}[2], [x7], #4
.elseif \w == 12
    str             q17, [x7], #16
    add             x6, x0, x9
    qpel_chroma_load_32b_sve2 \v
    qpel_filter_chroma_sve2_\v\()_32b
    vps_end_sve2
    str             d17, [x7], #8
    add             x9, x9, #8
.else
    str             q17, [x7], #16
.endif
    cmp             x9, #\w
    blt             .loop_vps_w8_sve2_\v\()_\w\()x\h

    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .loop_vps_sve2_\v\()_\w\()x\h
    ret
.endm

// void interp_vert_ps_c(const pixel* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx)
.macro CHROMA_VPS_SVE2 w, h
function x265_interp_4tap_vert_ps_\w\()x\h\()_sve2
    cmp             x4, #0
    beq             0f
    cmp             x4, #1
    beq             1f
    cmp             x4, #2
    beq             2f
    cmp             x4, #3
    beq             3f
    cmp             x4, #4
    beq             4f
    cmp             x4, #5
    beq             5f
    cmp             x4, #6
    beq             6f
    cmp             x4, #7
    beq             7f
0:
    FILTER_CHROMA_VPS_SVE2  \w, \h, 0
1:
    FILTER_CHROMA_VPS_SVE2  \w, \h, 1
2:
    FILTER_CHROMA_VPS_SVE2  \w, \h, 2
3:
    FILTER_CHROMA_VPS_SVE2  \w, \h, 3
4:
    FILTER_CHROMA_VPS_SVE2  \w, \h, 4
5:
    FILTER_CHROMA_VPS_SVE2  \w, \h, 5
6:
    FILTER_CHROMA_VPS_SVE2  \w, \h, 6
7:
    FILTER_CHROMA_VPS_SVE2  \w, \h, 7
endfunc
.endm

CHROMA_VPS_SVE2 2, 4
CHROMA_VPS_SVE2 2, 8
CHROMA_VPS_SVE2 2, 16
CHROMA_VPS_SVE2 4, 2
CHROMA_VPS_SVE2 4, 4
CHROMA_VPS_SVE2 4, 8
CHROMA_VPS_SVE2 4, 16
CHROMA_VPS_SVE2 4, 32
CHROMA_VPS_SVE2 6, 8
CHROMA_VPS_SVE2 6, 16
CHROMA_VPS_SVE2 8, 2
CHROMA_VPS_SVE2 8, 4
CHROMA_VPS_SVE2 8, 6
CHROMA_VPS_SVE2 8, 8
CHROMA_VPS_SVE2 8, 16
CHROMA_VPS_SVE2 8, 32
CHROMA_VPS_SVE2 8, 12
CHROMA_VPS_SVE2 8, 64
CHROMA_VPS_SVE2 12, 16
CHROMA_VPS_SVE2 12, 32
CHROMA_VPS_SVE2 16, 4
CHROMA_VPS_SVE2 16, 8
CHROMA_VPS_SVE2 16, 12
CHROMA_VPS_SVE2 16, 16
CHROMA_VPS_SVE2 16, 32
CHROMA_VPS_SVE2 16, 64
CHROMA_VPS_SVE2 16, 24
CHROMA_VPS_SVE2 32, 8
CHROMA_VPS_SVE2 32, 16
CHROMA_VPS_SVE2 32, 24
CHROMA_VPS_SVE2 32, 32
CHROMA_VPS_SVE2 32, 64
CHROMA_VPS_SVE2 32, 48
CHROMA_VPS_SVE2 24, 32
CHROMA_VPS_SVE2 24, 64
CHROMA_VPS_SVE2 64, 16
CHROMA_VPS_SVE2 64, 32
CHROMA_VPS_SVE2 64, 48
CHROMA_VPS_SVE2 64, 64
CHROMA_VPS_SVE2 48, 64

// ***** chroma_vsp *****
.macro FILTER_CHROMA_VSP_NEON w, h, v
    lsl             x1, x1, #1
    sub             x0, x0, x1
    mov             x5, #\h
    mov             w12, #1
    lsl             w12, w12, #19
    add             w12, w12, #2048
    dup             v31.4s, w12
    mov             x12, #\w
    lsl             x12, x12, #1
    qpel_start_chroma_\v\()_1
.loop_vsp_\v\()_\w\()x\h:
    mov             x7, x2
    mov             x9, #0
.loop_vsp_w8_\v\()_\w\()x\h:
    add             x6, x0, x9
    qpel_chroma_load_64b \v
    qpel_filter_chroma_\v\()_32b_1
    vsp_end
    add             x9, x9, #16
.if \w == 4
    str             s17, [x7], #4
.elseif \w == 12
    str             d17, [x7], #8
    add             x6, x0, x9
    qpel_chroma_load_64b \v
    qpel_filter_chroma_\v\()_32b_1
    vsp_end
    str             s17, [x7], #4
    add             x9, x9, #8
.else
    str             d17, [x7], #8
.endif
    cmp             x9, x12
    blt             .loop_vsp_w8_\v\()_\w\()x\h
    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .loop_vsp_\v\()_\w\()x\h
    ret
.endm

// void interp_vert_sp_c(const int16_t* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx)
.macro CHROMA_VSP_NEON w, h
function x265_interp_4tap_vert_sp_\w\()x\h\()_neon
    cmp             x4, #0
    beq             0f
    cmp             x4, #1
    beq             1f
    cmp             x4, #2
    beq             2f
    cmp             x4, #3
    beq             3f
    cmp             x4, #4
    beq             4f
    cmp             x4, #5
    beq             5f
    cmp             x4, #6
    beq             6f
    cmp             x4, #7
    beq             7f
0:
    FILTER_CHROMA_VSP_NEON  \w, \h, 0
1:
    FILTER_CHROMA_VSP_NEON  \w, \h, 1
2:
    FILTER_CHROMA_VSP_NEON  \w, \h, 2
3:
    FILTER_CHROMA_VSP_NEON  \w, \h, 3
4:
    FILTER_CHROMA_VSP_NEON  \w, \h, 4
5:
    FILTER_CHROMA_VSP_NEON  \w, \h, 5
6:
    FILTER_CHROMA_VSP_NEON  \w, \h, 6
7:
    FILTER_CHROMA_VSP_NEON  \w, \h, 7
endfunc
.endm

CHROMA_VSP_NEON 4, 4
CHROMA_VSP_NEON 4, 8
CHROMA_VSP_NEON 4, 16
CHROMA_VSP_NEON 4, 32
CHROMA_VSP_NEON 8, 2
CHROMA_VSP_NEON 8, 4
CHROMA_VSP_NEON 8, 6
CHROMA_VSP_NEON 8, 8
CHROMA_VSP_NEON 8, 16
CHROMA_VSP_NEON 8, 32
CHROMA_VSP_NEON 8, 12
CHROMA_VSP_NEON 8, 64
CHROMA_VSP_NEON 12, 16
CHROMA_VSP_NEON 12, 32
CHROMA_VSP_NEON 16, 4
CHROMA_VSP_NEON 16, 8
CHROMA_VSP_NEON 16, 12
CHROMA_VSP_NEON 16, 16
CHROMA_VSP_NEON 16, 32
CHROMA_VSP_NEON 16, 64
CHROMA_VSP_NEON 16, 24
CHROMA_VSP_NEON 32, 8
CHROMA_VSP_NEON 32, 16
CHROMA_VSP_NEON 32, 24
CHROMA_VSP_NEON 32, 32
CHROMA_VSP_NEON 32, 64
CHROMA_VSP_NEON 32, 48
CHROMA_VSP_NEON 24, 32
CHROMA_VSP_NEON 24, 64
CHROMA_VSP_NEON 64, 16
CHROMA_VSP_NEON 64, 32
CHROMA_VSP_NEON 64, 48
CHROMA_VSP_NEON 64, 64
CHROMA_VSP_NEON 48, 64

// void interp_vert_sp_c(const int16_t* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx)
// ***** chroma_vss *****
.macro FILTER_CHROMA_VSS_NEON w, h, v
    lsl             x1, x1, #1
    sub             x0, x0, x1
    lsl             x3, x3, #1
    mov             x5, #\h
    mov             x12, #\w
    lsl             x12, x12, #1
    qpel_start_chroma_\v\()_1
.loop_vss_\v\()_\w\()x\h:
    mov             x7, x2
    mov             x9, #0
.if \w == 4
.rept 2
    add             x6, x0, x9
    qpel_chroma_load_64b \v
    qpel_filter_chroma_\v\()_32b_1
    vss_end
    str             s17, [x7], #4
    add             x9, x9, #4
.endr
.else
.loop_vss_w8_\v\()_\w\()x\h:
    add             x6, x0, x9
    qpel_chroma_load_64b \v
    qpel_filter_chroma_\v\()_32b_1
    vss_end
    str             q17, [x7], #16
    add             x9, x9, #16
.if \w == 12
    add             x6, x0, x9
    qpel_chroma_load_64b \v
    qpel_filter_chroma_\v\()_32b_1
    vss_end
    str             d17, [x7], #8
    add             x9, x9, #8
.endif
    cmp             x9, x12
    blt             .loop_vss_w8_\v\()_\w\()x\h
.endif
    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .loop_vss_\v\()_\w\()x\h
    ret
.endm

// void interp_vert_ss_c(const int16_t* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx)
.macro CHROMA_VSS_NEON w, h
function x265_interp_4tap_vert_ss_\w\()x\h\()_neon
    cmp             x4, #0
    beq             0f
    cmp             x4, #1
    beq             1f
    cmp             x4, #2
    beq             2f
    cmp             x4, #3
    beq             3f
    cmp             x4, #4
    beq             4f
    cmp             x4, #5
    beq             5f
    cmp             x4, #6
    beq             6f
    cmp             x4, #7
    beq             7f
0:
    FILTER_CHROMA_VSS_NEON  \w, \h, 0
1:
    FILTER_CHROMA_VSS_NEON  \w, \h, 1
2:
    FILTER_CHROMA_VSS_NEON  \w, \h, 2
3:
    FILTER_CHROMA_VSS_NEON  \w, \h, 3
4:
    FILTER_CHROMA_VSS_NEON  \w, \h, 4
5:
    FILTER_CHROMA_VSS_NEON  \w, \h, 5
6:
    FILTER_CHROMA_VSS_NEON  \w, \h, 6
7:
    FILTER_CHROMA_VSS_NEON  \w, \h, 7
endfunc
.endm

CHROMA_VSS_NEON 4, 4
CHROMA_VSS_NEON 4, 8
CHROMA_VSS_NEON 4, 16
CHROMA_VSS_NEON 4, 32
CHROMA_VSS_NEON 8, 2
CHROMA_VSS_NEON 8, 4
CHROMA_VSS_NEON 8, 6
CHROMA_VSS_NEON 8, 8
CHROMA_VSS_NEON 8, 16
CHROMA_VSS_NEON 8, 32
CHROMA_VSS_NEON 8, 12
CHROMA_VSS_NEON 8, 64
CHROMA_VSS_NEON 12, 16
CHROMA_VSS_NEON 12, 32
CHROMA_VSS_NEON 16, 4
CHROMA_VSS_NEON 16, 8
CHROMA_VSS_NEON 16, 12
CHROMA_VSS_NEON 16, 16
CHROMA_VSS_NEON 16, 32
CHROMA_VSS_NEON 16, 64
CHROMA_VSS_NEON 16, 24
CHROMA_VSS_NEON 32, 8
CHROMA_VSS_NEON 32, 16
CHROMA_VSS_NEON 32, 24
CHROMA_VSS_NEON 32, 32
CHROMA_VSS_NEON 32, 64
CHROMA_VSS_NEON 32, 48
CHROMA_VSS_NEON 24, 32
CHROMA_VSS_NEON 24, 64
CHROMA_VSS_NEON 64, 16
CHROMA_VSS_NEON 64, 32
CHROMA_VSS_NEON 64, 48
CHROMA_VSS_NEON 64, 64
CHROMA_VSS_NEON 48, 64

.macro FILTER_CHROMA_VSS_SVE2 w, h, v
    lsl             x1, x1, #1
    sub             x0, x0, x1
    lsl             x3, x3, #1
    mov             x5, #\h
    mov             x12, #\w
    lsl             x12, x12, #1
    qpel_start_chroma_\v\()_1
.loop_vss_sve2_\v\()_\w\()x\h:
    mov             x7, x2
    mov             x9, #0
.if \w == 4
.rept 2
    add             x6, x0, x9
    qpel_chroma_load_64b \v
    qpel_filter_chroma_\v\()_32b_1
    vss_end_sve2
    str             s17, [x7], #4
    add             x9, x9, #4
.endr
.else
.loop_vss_w8_sve2_\v\()_\w\()x\h:
    add             x6, x0, x9
    qpel_chroma_load_64b \v
    qpel_filter_chroma_\v\()_32b_1
    vss_end_sve2
    str             q17, [x7], #16
    add             x9, x9, #16
.if \w == 12
    add             x6, x0, x9
    qpel_chroma_load_64b \v
    qpel_filter_chroma_\v\()_32b_1
    vss_end_sve2
    str             d17, [x7], #8
    add             x9, x9, #8
.endif
    cmp             x9, x12
    blt             .loop_vss_w8_sve2_\v\()_\w\()x\h
.endif
    add             x0, x0, x1
    add             x2, x2, x3
    sub             x5, x5, #1
    cbnz            x5, .loop_vss_sve2_\v\()_\w\()x\h
    ret
.endm

// void interp_vert_ss_c(const int16_t* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx)
.macro CHROMA_VSS_SVE2 w, h
function x265_interp_4tap_vert_ss_\w\()x\h\()_sve2
    cmp             x4, #0
    beq             0f
    cmp             x4, #1
    beq             1f
    cmp             x4, #2
    beq             2f
    cmp             x4, #3
    beq             3f
    cmp             x4, #4
    beq             4f
    cmp             x4, #5
    beq             5f
    cmp             x4, #6
    beq             6f
    cmp             x4, #7
    beq             7f
0:
    FILTER_CHROMA_VSS_SVE2  \w, \h, 0
1:
    FILTER_CHROMA_VSS_SVE2  \w, \h, 1
2:
    FILTER_CHROMA_VSS_SVE2  \w, \h, 2
3:
    FILTER_CHROMA_VSS_SVE2  \w, \h, 3
4:
    FILTER_CHROMA_VSS_SVE2  \w, \h, 4
5:
    FILTER_CHROMA_VSS_SVE2  \w, \h, 5
6:
    FILTER_CHROMA_VSS_SVE2  \w, \h, 6
7:
    FILTER_CHROMA_VSS_SVE2  \w, \h, 7
endfunc
.endm

CHROMA_VSS_SVE2 4, 4
CHROMA_VSS_SVE2 4, 8
CHROMA_VSS_SVE2 4, 16
CHROMA_VSS_SVE2 4, 32
CHROMA_VSS_SVE2 8, 2
CHROMA_VSS_SVE2 8, 4
CHROMA_VSS_SVE2 8, 6
CHROMA_VSS_SVE2 8, 8
CHROMA_VSS_SVE2 8, 16
CHROMA_VSS_SVE2 8, 32
CHROMA_VSS_SVE2 8, 12
CHROMA_VSS_SVE2 8, 64
CHROMA_VSS_SVE2 12, 16
CHROMA_VSS_SVE2 12, 32
CHROMA_VSS_SVE2 16, 4
CHROMA_VSS_SVE2 16, 8
CHROMA_VSS_SVE2 16, 12
CHROMA_VSS_SVE2 16, 16
CHROMA_VSS_SVE2 16, 32
CHROMA_VSS_SVE2 16, 64
CHROMA_VSS_SVE2 16, 24
CHROMA_VSS_SVE2 32, 8
CHROMA_VSS_SVE2 32, 16
CHROMA_VSS_SVE2 32, 24
CHROMA_VSS_SVE2 32, 32
CHROMA_VSS_SVE2 32, 64
CHROMA_VSS_SVE2 32, 48
CHROMA_VSS_SVE2 24, 32
CHROMA_VSS_SVE2 24, 64
CHROMA_VSS_SVE2 64, 16
CHROMA_VSS_SVE2 64, 32
CHROMA_VSS_SVE2 64, 48
CHROMA_VSS_SVE2 64, 64
CHROMA_VSS_SVE2 48, 64

// ***** chroma_hpp *****
.macro FILTER_CHROMA_HPP_NEON w, h, v
    qpel_start_chroma_\v
    mov             w12, #32
    dup             v31.8h, w12
    mov             w6, #\h
    sub             x3, x3, #\w
.if \w == 2 || \w == 4 || \w == 6 || \w == 12
.loop4_chroma_hpp_\v\()_\w\()x\h:
    mov             x11, x0
    sub             x11, x11, #2
    vextin8_chroma \v
    qpel_filter_chroma_\v\()_32b
    hpp_end
.if \w == 2
    fmov            w12, s17
    strh            w12, [x2], #2
.elseif \w == 4
    str             s17, [x2], #4
.elseif \w == 6
    str             s17, [x2], #4
    umov            w12, v17.h[2]
    strh            w12, [x2], #2
.elseif \w == 12
    str             d17, [x2], #8
    sub             x11, x11, #8
    vextin8_chroma \v
    qpel_filter_chroma_\v\()_32b
    hpp_end
    str             s17, [x2], #4
.endif
    sub             w6, w6, #1
    add             x0, x0, x1
    add             x2, x2, x3
    cbnz            w6, .loop4_chroma_hpp_\v\()_\w\()x\h
    ret
.else
.loop2_chroma_hpp_\v\()_\w\()x\h:
    mov             x7, #\w
    lsr             x7, x7, #3
    mov             x11, x0
    sub             x11, x11, #2
.loop3_chroma_hpp_\v\()_\w\()x\h:
.if \w == 8 || \w == 24
    vextin8_chroma \v
    qpel_filter_chroma_\v\()_32b
    hpp_end
    str             d17, [x2], #8
    sub             x7, x7, #1
    sub             x11, x11, #8
.elseif \w == 16 || \w == 32 || \w == 48 || \w == 64
    vextin8_chroma_64 \v
    qpel_filter_chroma_\v\()_64b
    hpp_end
    add             v18.8h, v18.8h, v31.8h
    sqshrun2        v17.16b, v18.8h, #6
    str             q17, [x2], #16
    sub             x7, x7, #2
    sub             x11, x11, #16
.endif
    cbnz            x7, .loop3_chroma_hpp_\v\()_\w\()x\h
    sub             w6, w6, #1
    add             x0, x0, x1
    add             x2, x2, x3
    cbnz            w6, .loop2_chroma_hpp_\v\()_\w\()x\h
    ret
.endif
.endm

// void interp_horiz_pp_c(const pixel* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx)
.macro CHROMA_HPP_NEON w, h
function x265_interp_4tap_horiz_pp_\w\()x\h\()_neon
    cmp             x4, #0
    beq             0f
    cmp             x4, #1
    beq             1f
    cmp             x4, #2
    beq             2f
    cmp             x4, #3
    beq             3f
    cmp             x4, #4
    beq             4f
    cmp             x4, #5
    beq             5f
    cmp             x4, #6
    beq             6f
    cmp             x4, #7
    beq             7f
0:
    FILTER_CHROMA_HPP_NEON  \w, \h, 0
1:
    FILTER_CHROMA_HPP_NEON  \w, \h, 1
2:
    FILTER_CHROMA_HPP_NEON  \w, \h, 2
3:
    FILTER_CHROMA_HPP_NEON  \w, \h, 3
4:
    FILTER_CHROMA_HPP_NEON  \w, \h, 4
5:
    FILTER_CHROMA_HPP_NEON  \w, \h, 5
6:
    FILTER_CHROMA_HPP_NEON  \w, \h, 6
7:
    FILTER_CHROMA_HPP_NEON  \w, \h, 7
endfunc
.endm

CHROMA_HPP_NEON 2, 4
CHROMA_HPP_NEON 2, 8
CHROMA_HPP_NEON 2, 16
CHROMA_HPP_NEON 4, 2
CHROMA_HPP_NEON 4, 4
CHROMA_HPP_NEON 4, 8
CHROMA_HPP_NEON 4, 16
CHROMA_HPP_NEON 4, 32
CHROMA_HPP_NEON 6, 8
CHROMA_HPP_NEON 6, 16
CHROMA_HPP_NEON 8, 2
CHROMA_HPP_NEON 8, 4
CHROMA_HPP_NEON 8, 6
CHROMA_HPP_NEON 8, 8
CHROMA_HPP_NEON 8, 12
CHROMA_HPP_NEON 8, 16
CHROMA_HPP_NEON 8, 32
CHROMA_HPP_NEON 8, 64
CHROMA_HPP_NEON 12, 16
CHROMA_HPP_NEON 12, 32
CHROMA_HPP_NEON 16, 4
CHROMA_HPP_NEON 16, 8
CHROMA_HPP_NEON 16, 12
CHROMA_HPP_NEON 16, 16
CHROMA_HPP_NEON 16, 24
CHROMA_HPP_NEON 16, 32
CHROMA_HPP_NEON 16, 64
CHROMA_HPP_NEON 24, 32
CHROMA_HPP_NEON 24, 64
CHROMA_HPP_NEON 32, 8
CHROMA_HPP_NEON 32, 16
CHROMA_HPP_NEON 32, 24
CHROMA_HPP_NEON 32, 32
CHROMA_HPP_NEON 32, 48
CHROMA_HPP_NEON 32, 64
CHROMA_HPP_NEON 48, 64
CHROMA_HPP_NEON 64, 16
CHROMA_HPP_NEON 64, 32
CHROMA_HPP_NEON 64, 48
CHROMA_HPP_NEON 64, 64

// ***** chroma_hps *****
.macro CHROMA_HPS_2_4_6_12 w, v
    mov             x11, x0
    sub             x11, x11, #2
    vextin8_chroma \v
    qpel_filter_chroma_\v\()_32b
    hps_end
    sub             x11, x11, #8
.if \w == 2
    str             s17, [x2], #4
.elseif \w == 4
    str             d17, [x2], #8
.elseif \w == 6
    str             d17, [x2], #8
    st1             {v17.s}[2], [x2], #4
.elseif \w == 12
    str             q17, [x2], #16
    vextin8_chroma \v
    qpel_filter_chroma_\v\()_32b
    sub             v17.8h, v17.8h, v31.8h
    str             d17, [x2], #8
.endif
    add             x0, x0, x1
    add             x2, x2, x3
.endm

.macro FILTER_CHROMA_HPS w, h, v
    qpel_start_chroma_\v
    mov             w12, #8192
    dup             v31.8h, w12
    sub             x3, x3, #\w
    lsl             x3, x3, #1

.if \w == 2 || \w == 4 || \w == 6 || \w == 12
    cmp             x5, #0
    beq             0f
    sub             x0, x0, x1
.rept 3
    CHROMA_HPS_2_4_6_12 \w, \v
.endr
0:
.rept \h
    CHROMA_HPS_2_4_6_12 \w, \v
.endr
    ret
.else
    mov             w10, #\h
    cmp             x5, #0
    beq             9f
    sub             x0, x0, x1
    add             w10, w10, #3
9:
    mov             w6, w10
.loop1_chroma_hps_\v\()_\w\()x\h\():
    mov             x7, #\w
    lsr             x7, x7, #3
    mov             x11, x0
    sub             x11, x11, #2
.loop2_chroma_hps_\v\()_\w\()x\h\():
.if \w == 8 || \w == 24
    vextin8_chroma \v
    qpel_filter_chroma_\v\()_32b
    hps_end
    str             q17, [x2], #16
    sub             x7, x7, #1
    sub             x11, x11, #8
.elseif \w == 16 || \w == 32 || \w == 48 || \w == 64
    vextin8_chroma_64 \v
    qpel_filter_chroma_\v\()_64b
    hps_end
    sub             v18.8h, v18.8h, v31.8h
    stp             q17, q18, [x2], #32
    sub             x7, x7, #2
    sub             x11, x11, #16
.endif
    cbnz            x7, .loop2_chroma_hps_\v\()_\w\()x\h\()
    sub             w6, w6, #1
    add             x0, x0, x1
    add             x2, x2, x3
    cbnz            w6, .loop1_chroma_hps_\v\()_\w\()x\h\()
    ret
.endif
.endm

// void interp_horiz_ps_c(const pixel* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx, int isRowExt)
.macro CHROMA_HPS w, h
function x265_interp_4tap_horiz_ps_\w\()x\h\()_neon
    cmp             x4, #0
    beq             0f
    cmp             x4, #1
    beq             1f
    cmp             x4, #2
    beq             2f
    cmp             x4, #3
    beq             3f
    cmp             x4, #4
    beq             4f
    cmp             x4, #5
    beq             5f
    cmp             x4, #6
    beq             6f
    cmp             x4, #7
    beq             7f
0:
    FILTER_CHROMA_HPS  \w, \h, 0
1:
    FILTER_CHROMA_HPS  \w, \h, 1
2:
    FILTER_CHROMA_HPS  \w, \h, 2
3:
    FILTER_CHROMA_HPS  \w, \h, 3
4:
    FILTER_CHROMA_HPS  \w, \h, 4
5:
    FILTER_CHROMA_HPS  \w, \h, 5
6:
    FILTER_CHROMA_HPS  \w, \h, 6
7:
    FILTER_CHROMA_HPS  \w, \h, 7
endfunc
.endm

CHROMA_HPS 2, 4
CHROMA_HPS 2, 8
CHROMA_HPS 2, 16
CHROMA_HPS 4, 2
CHROMA_HPS 4, 4
CHROMA_HPS 4, 8
CHROMA_HPS 4, 16
CHROMA_HPS 4, 32
CHROMA_HPS 6, 8
CHROMA_HPS 6, 16
CHROMA_HPS 8, 2
CHROMA_HPS 8, 4
CHROMA_HPS 8, 6
CHROMA_HPS 8, 8
CHROMA_HPS 8, 12
CHROMA_HPS 8, 16
CHROMA_HPS 8, 32
CHROMA_HPS 8, 64
CHROMA_HPS 12, 16
CHROMA_HPS 12, 32
CHROMA_HPS 16, 4
CHROMA_HPS 16, 8
CHROMA_HPS 16, 12
CHROMA_HPS 16, 16
CHROMA_HPS 16, 24
CHROMA_HPS 16, 32
CHROMA_HPS 16, 64
CHROMA_HPS 24, 32
CHROMA_HPS 24, 64
CHROMA_HPS 32, 8
CHROMA_HPS 32, 16
CHROMA_HPS 32, 24
CHROMA_HPS 32, 32
CHROMA_HPS 32, 48
CHROMA_HPS 32, 64
CHROMA_HPS 48, 64
CHROMA_HPS 64, 16
CHROMA_HPS 64, 32
CHROMA_HPS 64, 48
CHROMA_HPS 64, 64

const g_luma_s16, align=8
//       a, b,   c,  d,  e,   f, g,  h
.hword   0, 0,   0, 64,  0,   0, 0,  0
.hword  -1, 4, -10, 58, 17,  -5, 1,  0
.hword  -1, 4, -11, 40, 40, -11, 4, -1
.hword   0, 1,  -5, 17, 58, -10, 4, -1
endconst

const g_lumaFilter, align=8
.word 0,0,0,0,0,0,64,64,0,0,0,0,0,0,0,0
.word -1,-1,4,4,-10,-10,58,58,17,17,-5,-5,1,1,0,0
.word -1,-1,4,4,-11,-11,40,40,40,40,-11,-11,4,4,-1,-1
.word 0,0,1,1,-5,-5,17,17,58,58,-10,-10,4,4,-1,-1
endconst
