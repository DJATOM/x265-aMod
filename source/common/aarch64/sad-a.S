/*****************************************************************************
 * Copyright (C) 2020-2024 MulticoreWare, Inc
 *
 * Authors: Hongbin Liu <liuhongbin1@huawei.com>
 *          Sebastian Pop <spop@amazon.com>
            Hari Limaye <hari.limaye@arm.com>
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

#ifdef __APPLE__
.section __RODATA,__rodata
#else
.section .rodata
#endif

.align 4

.text

.macro SAD_START_4 f
    ldr             s0, [x0]
    ldr             s1, [x2]
    add             x0, x0, x1
    add             x2, x2, x3
    ld1             {v0.s}[1], [x0], x1
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
    \f              v16.8h, v0.8b, v1.8b
.endm

.macro SAD_8 h
.rept \h - 3
    SAD_START_8 uabal
.endr
    ldr             d0, [x0]
    ldr             d1, [x2]
    uabal           v16.8h, v0.8b, v1.8b
    ldr             d0, [x0, x1]
    ldr             d1, [x2, x3]
    uabal           v16.8h, v0.8b, v1.8b
.endm

.macro SAD_START_16
    movi            v16.16b, #0
    movi            v17.16b, #0
.endm

.macro SAD_16
    ld1             {v0.16b}, [x0], x1
    ld1             {v1.16b}, [x2], x3
    ld1             {v2.16b}, [x0], x1
    ld1             {v3.16b}, [x2], x3
    uabd            v20.16b, v0.16b, v1.16b
    uadalp          v16.8h, v20.16b
    uabd            v21.16b, v2.16b, v3.16b
    uadalp          v17.8h, v21.16b
.endm

.macro SAD_END_16
    add             v16.8h, v16.8h, v17.8h
    uaddlv          s0, v16.8h
    fmov            x0, d0
    ret
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
    uabd            v20.16b, v0.16b, v2.16b
    uadalp          v16.8h, v20.16b
    uabd            v21.16b, v1.16b, v3.16b
    uadalp          v17.8h, v21.16b
    uabd            v22.16b, v4.16b, v6.16b
    uadalp          v18.8h, v22.16b
    uabd            v23.16b, v5.16b, v7.16b
    uadalp          v19.8h, v23.16b
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
.endm

.macro SAD_64
    ld1             {v0.16b-v3.16b}, [x0], x1
    ld1             {v4.16b-v7.16b}, [x2], x3
    ld1             {v24.16b-v27.16b}, [x0], x1
    ld1             {v28.16b-v31.16b}, [x2], x3
    uabd            v20.16b, v0.16b, v4.16b
    uadalp          v16.8h, v20.16b
    uabd            v21.16b, v1.16b, v5.16b
    uadalp          v17.8h, v21.16b
    uabd            v22.16b, v2.16b, v6.16b
    uadalp          v18.8h, v22.16b
    uabd            v23.16b, v3.16b, v7.16b
    uadalp          v19.8h, v23.16b
    uabd            v20.16b, v24.16b, v28.16b
    uadalp          v16.8h, v20.16b
    uabd            v21.16b, v25.16b, v29.16b
    uadalp          v17.8h, v21.16b
    uabd            v22.16b, v26.16b, v30.16b
    uadalp          v18.8h, v22.16b
    uabd            v23.16b, v27.16b, v31.16b
    uadalp          v19.8h, v23.16b
.endm

.macro SAD_END_64
    uaddlp          v16.4s, v16.8h
    uadalp          v16.4s, v17.8h
    uadalp          v16.4s, v18.8h
    uadalp          v16.4s, v19.8h
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
    uabd            v20.16b, v0.16b, v1.16b
    uadalp          v16.8h, v20.16b
    uabd            v21.16b, v2.16b, v3.16b
    uadalp          v17.8h, v21.16b
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
    uabd            v20.16b, v0.16b, v2.16b
    uadalp          v16.8h, v20.16b
    uabal           v17.8h, v1.8b, v3.8b
    uabd            v20.16b, v4.16b, v6.16b
    uadalp          v16.8h, v20.16b
    uabal           v17.8h, v5.8b, v7.8b
.endm

.macro SAD_END_24
    add             v16.8h, v16.8h, v17.8h
    uaddlv          s0, v16.8h
    fmov            w0, s0
    ret
.endm

.macro SAD_START_48
    movi            v16.16b, #0
    movi            v17.16b, #0
    movi            v18.16b, #0
.endm

.macro SAD_48
    ld1             {v0.16b-v2.16b}, [x0], x1
    ld1             {v4.16b-v6.16b}, [x2], x3
    ld1             {v24.16b-v26.16b}, [x0], x1
    ld1             {v28.16b-v30.16b}, [x2], x3
    uabd            v20.16b, v0.16b, v4.16b
    uadalp          v16.8h, v20.16b
    uabd            v21.16b, v1.16b, v5.16b
    uadalp          v17.8h, v21.16b
    uabd            v22.16b, v2.16b, v6.16b
    uadalp          v18.8h, v22.16b
    uabd            v20.16b, v24.16b, v28.16b
    uadalp          v16.8h, v20.16b
    uabd            v21.16b, v25.16b, v29.16b
    uadalp          v17.8h, v21.16b
    uabd            v22.16b, v26.16b, v30.16b
    uadalp          v18.8h, v22.16b
.endm

.macro SAD_END_48
    uaddlp          v16.4s, v16.8h
    uadalp          v16.4s, v17.8h
    uadalp          v16.4s, v18.8h
    uaddlv          d0, v16.4s
    fmov            x0, d0
    ret
.endm

// Fully unrolled.
.macro SAD_FUNC w, h
function PFX(pixel_sad_\w\()x\h\()_neon)
    SAD_START_\w uabdl
    SAD_\w \h
.if \w > 8
    add             v16.8h, v16.8h, v17.8h
.endif
    uaddlv          s0, v16.8h
    fmov            w0, s0
    ret
endfunc
.endm

// Loop unrolled to process 4 rows per iteration.
.macro SAD_FUNC_LOOP w, h
function PFX(pixel_sad_\w\()x\h\()_neon)
    SAD_START_\w

    mov             w9, #\h/4
.Loop_\w\()x\h:
    sub             w9, w9, #1
.rept 2
    SAD_\w
.endr
    cbnz            w9, .Loop_\w\()x\h

    SAD_END_\w
endfunc
.endm

SAD_FUNC  4,  4
SAD_FUNC  4,  8
SAD_FUNC  4,  16
SAD_FUNC  8,  4
SAD_FUNC  8,  8
SAD_FUNC  8,  16
SAD_FUNC  8,  32

SAD_FUNC_LOOP  16, 4
SAD_FUNC_LOOP  16, 8
SAD_FUNC_LOOP  16, 12
SAD_FUNC_LOOP  16, 16
SAD_FUNC_LOOP  16, 32
SAD_FUNC_LOOP  16, 64
SAD_FUNC_LOOP  32, 8
SAD_FUNC_LOOP  32, 16
SAD_FUNC_LOOP  32, 24
SAD_FUNC_LOOP  32, 32
SAD_FUNC_LOOP  32, 64
SAD_FUNC_LOOP  64, 16
SAD_FUNC_LOOP  64, 32
SAD_FUNC_LOOP  64, 48
SAD_FUNC_LOOP  64, 64
SAD_FUNC_LOOP  12, 16
SAD_FUNC_LOOP  24, 32
SAD_FUNC_LOOP  48, 64

// SAD_X3 and SAD_X4 code start

.macro SAD_X_START_4 h, x, f
    ldr             s0, [x0]
    ldr             s1, [x1]
    ldr             s2, [x2]
    ldr             s3, [x3]
    add             x0, x0, x9
    add             x1, x1, x5
    add             x2, x2, x5
    add             x3, x3, x5
    ld1             {v0.s}[1], [x0], x9
    ld1             {v1.s}[1], [x1], x5
    ld1             {v2.s}[1], [x2], x5
    ld1             {v3.s}[1], [x3], x5
    \f              v16.8h, v0.8b, v1.8b
    \f              v17.8h, v0.8b, v2.8b
    \f              v18.8h, v0.8b, v3.8b
.if \x == 4
    ldr             s4, [x4]
    add             x4, x4, x5
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

.macro SAD_X_START_12 x
    SAD_X_START_16 \x
.endm

.macro SAD_X_12 base v1 v2
    // v2: unused
    // v31: bitmask for 12xh blocks
    ld1             {v0.16b}, [ \base ], x5
    and             v0.16b, v0.16b, v31.16b

    uabd            v24.16b, v0.16b, v6.16b
    uadalp          \v1\().8h, v24.16b
.endm

.macro SAD_X_END_12 x
    SAD_X_END_4 \x
.endm

.macro SAD_X_START_16 x
    movi v16.16b, #0
    movi v17.16b, #0
    movi v18.16b, #0
.if \x == 4
    movi v19.16b, #0
.endif
.endm

.macro SAD_X_16 base v1 v2
    // v2: unused
    ld1             {v0.16b}, [ \base ], x5
    uabd            v24.16b, v0.16b, v6.16b
    uadalp          \v1\().8h, v24.16b
.endm

.macro SAD_X_END_16 x
    SAD_X_END_4 \x
.endm

.macro SAD_X_START_LARGE x
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

.macro SAD_X_END_LARGE x
    uaddlp          v16.4s, v16.8h
    uadalp          v16.4s, v20.8h
    uaddlp          v17.4s, v17.8h
    uadalp          v17.4s, v21.8h
    uaddlp          v18.4s, v18.8h
    uadalp          v18.4s, v22.8h
.if \x == 3
    addv            s0, v16.4s
    addv            s1, v17.4s
    addv            s2, v18.4s
    stp             s0, s1, [x6], #8
    str             s2, [x6]
.elseif \x == 4
    uaddlp          v19.4s, v19.8h
    uadalp          v19.4s, v23.8h
    addp            v16.4s, v16.4s, v17.4s
    addp            v18.4s, v18.4s, v19.4s
    addp            v16.4s, v16.4s, v18.4s
    str             q16, [x6]
.endif
    ret
.endm

.macro SAD_X_START_24 x
    SAD_X_START_LARGE \x
    sub             x5, x5, #16
    sub             x9, x9, #16
.endm

.macro SAD_X_24 base v1 v2
    ld1             {v0.16b}, [ \base ], #16
    ld1             {v1.8b}, [ \base ], x5
    uabd            v24.16b, v0.16b, v6.16b
    uadalp          \v1\().8h, v24.16b
    uabal           \v2\().8h, v1.8b, v7.8b
.endm

.macro SAD_X_END_24 x
    SAD_X_END_LARGE \x
.endm

.macro SAD_X_START_32 x
    SAD_X_START_LARGE \x
.endm

.macro SAD_X_32 base v1 v2
    ld1             {v0.16b-v1.16b}, [ \base ], x5
    uabd            v24.16b, v0.16b, v6.16b
    uadalp          \v1\().8h, v24.16b
    uabd            v25.16b, v1.16b, v7.16b
    uadalp          \v2\().8h, v25.16b
.endm

.macro SAD_X_END_32 x
    SAD_X_END_LARGE \x
.endm

.macro SAD_X_START_48 x
    SAD_X_START_LARGE \x
.endm

.macro SAD_X_48 base v1 v2
    ld1             {v0.16b-v2.16b}, [ \base ], x5
    uabd            v24.16b, v0.16b, v4.16b
    uadalp          \v1\().8h, v24.16b
    uabd            v25.16b, v1.16b, v5.16b
    uadalp          \v2\().8h, v25.16b
    uabd            v26.16b, v2.16b, v6.16b
    uadalp          \v1\().8h, v26.16b
.endm

.macro SAD_X_END_48 x
    SAD_X_END_LARGE \x
.endm

.macro SAD_X_START_64 x
    SAD_X_START_LARGE \x
.endm

.macro SAD_X_64 base v1 v2
    ld1             {v0.16b-v3.16b}, [ \base ], x5
    uabd            v24.16b, v0.16b, v4.16b
    uadalp          \v1\().8h, v24.16b
    uabd            v25.16b, v1.16b, v5.16b
    uadalp          \v2\().8h, v25.16b
    uabd            v26.16b, v2.16b, v6.16b
    uadalp          \v1\().8h, v26.16b
    uabd            v27.16b, v3.16b, v7.16b
    uadalp          \v2\().8h, v27.16b
.endm

.macro SAD_X_END_64 x
    SAD_X_END_LARGE \x
.endm

// static void x264_pixel_sad_x3_##size(pixel *fenc, pixel *pix0, pixel *pix1, pixel *pix2, intptr_t i_stride, int scores[3])
// static void x264_pixel_sad_x4_##size(pixel *fenc, pixel *pix0, pixel *pix1,pixel *pix2, pixel *pix3, intptr_t i_stride, int scores[4])
.macro SAD_X_FUNC x, w, h
function PFX(sad_x\x\()_\w\()x\h\()_neon)
    mov             x9, #FENC_STRIDE

// Make function arguments for x == 3 look like x == 4.
.if \x == 3
    mov             x6, x5
    mov             x5, x4
.endif

    SAD_X_START_\w \h, \x, uabdl
    SAD_X_\w \h, \x
    SAD_X_END_\w \x
endfunc
.endm

.macro SAD_X_LOOP x, w, h
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

    SAD_X_START_\w \x
    mov             w12, #\h/4
.Loop_sad_x\x\()_\w\()x\h:
    sub             w12, w12, #1
 .rept 4
  .if \w == 12
    ld1             {v6.16b}, [x0], x9
    and             v6.16b, v6.16b, v31.16b
  .elseif \w == 16
    ld1             {v6.16b}, [x0], x9
  .elseif \w == 24
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
    cbnz            w12, .Loop_sad_x\x\()_\w\()x\h
    SAD_X_END_\w \x
endfunc
.endm


SAD_X_FUNC  3, 4,  4
SAD_X_FUNC  3, 4,  8
SAD_X_FUNC  3, 4,  16
SAD_X_FUNC  3, 8,  4
SAD_X_FUNC  3, 8,  8
SAD_X_FUNC  3, 8,  16
SAD_X_FUNC  3, 8,  32
SAD_X_LOOP  3, 12, 16
SAD_X_LOOP  3, 16, 4
SAD_X_LOOP  3, 16, 8
SAD_X_LOOP  3, 16, 12
SAD_X_LOOP  3, 16, 16
SAD_X_LOOP  3, 16, 32
SAD_X_LOOP  3, 16, 64
SAD_X_LOOP  3, 24, 32
SAD_X_LOOP  3, 32, 8
SAD_X_LOOP  3, 32, 16
SAD_X_LOOP  3, 32, 24
SAD_X_LOOP  3, 32, 32
SAD_X_LOOP  3, 32, 64
SAD_X_LOOP  3, 48, 64
SAD_X_LOOP  3, 64, 16
SAD_X_LOOP  3, 64, 32
SAD_X_LOOP  3, 64, 48
SAD_X_LOOP  3, 64, 64

SAD_X_FUNC  4, 4,  4
SAD_X_FUNC  4, 4,  8
SAD_X_FUNC  4, 4,  16
SAD_X_FUNC  4, 8,  4
SAD_X_FUNC  4, 8,  8
SAD_X_FUNC  4, 8,  16
SAD_X_FUNC  4, 8,  32
SAD_X_LOOP  4, 12, 16
SAD_X_LOOP  4, 16, 4
SAD_X_LOOP  4, 16, 8
SAD_X_LOOP  4, 16, 12
SAD_X_LOOP  4, 16, 16
SAD_X_LOOP  4, 16, 32
SAD_X_LOOP  4, 16, 64
SAD_X_LOOP  4, 24, 32
SAD_X_LOOP  4, 32, 8
SAD_X_LOOP  4, 32, 16
SAD_X_LOOP  4, 32, 24
SAD_X_LOOP  4, 32, 32
SAD_X_LOOP  4, 32, 64
SAD_X_LOOP  4, 48, 64
SAD_X_LOOP  4, 64, 16
SAD_X_LOOP  4, 64, 32
SAD_X_LOOP  4, 64, 48
SAD_X_LOOP  4, 64, 64

const sad12_mask, align=8
.byte 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 0, 0, 0
endconst
