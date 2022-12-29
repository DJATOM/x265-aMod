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

.arch           armv8-a

#define PFX3(prefix, name) prefix ## _ ## name
#define PFX2(prefix, name) PFX3(prefix, name)
#define PFX(name)          PFX2(X265_NS, name)

#ifdef __APPLE__
#define PREFIX 1
#endif

#ifdef PREFIX
#define EXTERN_ASM _
#define HAVE_AS_FUNC 0
#elif defined __clang__
#define EXTERN_ASM
#define HAVE_AS_FUNC 0
#define PREFIX 1
#else
#define EXTERN_ASM
#define HAVE_AS_FUNC 1
#endif

#ifdef __ELF__
#define ELF
#else
#ifdef PREFIX
#define ELF #
#else
#define ELF @
#endif
#endif

#if HAVE_AS_FUNC
#define FUNC
#else
#ifdef PREFIX
#define FUNC #
#else
#define FUNC @
#endif
#endif

#define GLUE(a, b) a ## b
#define JOIN(a, b) GLUE(a, b)

#define PFX_C(name)        JOIN(JOIN(JOIN(EXTERN_ASM, X265_NS), _), name)

#ifdef __APPLE__
.macro endfunc
ELF .size \name, . - \name
FUNC .endfunc
.endm
#endif

.macro function name, export=1
#ifdef __APPLE__
    .global \name
    endfunc
#else
    .macro endfunc
ELF     .size   \name, . - \name
FUNC    .endfunc
        .purgem endfunc
    .endm
#endif
        .align  2
.if \export == 1
        .global EXTERN_ASM\name
ELF     .hidden EXTERN_ASM\name
ELF     .type   EXTERN_ASM\name, %function
FUNC    .func   EXTERN_ASM\name
EXTERN_ASM\name:
.else
ELF     .hidden \name
ELF     .type   \name, %function
FUNC    .func   \name
\name:
.endif
.endm

.macro  const   name, align=2
    .macro endconst
ELF     .size   \name, . - \name
        .purgem endconst
    .endm
#ifdef __MACH__
    .const_data
#else
    .section .rodata
#endif
    .align          \align
\name:
.endm

.macro  movrel rd, val, offset=0
#if defined(__APPLE__)
  .if \offset < 0
        adrp            \rd, \val@PAGE
        add             \rd, \rd, \val@PAGEOFF
        sub             \rd, \rd, -(\offset)
  .else
        adrp            \rd, \val+(\offset)@PAGE
        add             \rd, \rd, \val+(\offset)@PAGEOFF
  .endif
#elif defined(PIC) && defined(_WIN32)
  .if \offset < 0
        adrp            \rd, \val
        add             \rd, \rd, :lo12:\val
        sub             \rd, \rd, -(\offset)
  .else
        adrp            \rd, \val+(\offset)
        add             \rd, \rd, :lo12:\val+(\offset)
  .endif
#else
        adrp            \rd, \val+(\offset)
        add             \rd, \rd, :lo12:\val+(\offset)
#endif
.endm

#define FENC_STRIDE 64
#define FDEC_STRIDE 32

.macro SUMSUB_AB sum, diff, a, b
    add             \sum,  \a, \b
    sub             \diff, \a, \b
.endm

.macro SUMSUB_ABCD s1, d1, s2, d2, a, b, c, d
    SUMSUB_AB       \s1, \d1, \a, \b
    SUMSUB_AB       \s2, \d2, \c, \d
.endm

.macro HADAMARD4_V r1, r2, r3, r4, t1, t2, t3, t4
    SUMSUB_ABCD     \t1, \t2, \t3, \t4, \r1, \r2, \r3, \r4
    SUMSUB_ABCD     \r1, \r3, \r2, \r4, \t1, \t3, \t2, \t4
.endm

.macro ABS2 a b
    abs             \a, \a
    abs             \b, \b
.endm

.macro ABS8 v0, v1, v2, v3, v4, v5, v6, v7
    ABS2            \v0, \v1
    ABS2            \v2, \v3
    ABS2            \v4, \v5
    ABS2            \v6, \v7
.endm

.macro vtrn t1, t2, s1, s2
    trn1            \t1, \s1, \s2
    trn2            \t2, \s1, \s2
.endm

.macro trn4 t1, t2, t3, t4, s1, s2, s3, s4
    vtrn            \t1, \t2, \s1, \s2
    vtrn            \t3, \t4, \s3, \s4
.endm

.macro custom_printf string_number, number
    sub             sp, sp, #(31 * 64)
    str             x0, [sp, #(1 * 64)]
    str             x1, [sp, #(2 * 64)]
    str             x2, [sp, #(3 * 64)]
    str             x3, [sp, #(4 * 64)]
    str             x4, [sp, #(5 * 64)]
    str             x5, [sp, #(6 * 64)]
    str             x6, [sp, #(7 * 64)]
    str             x7, [sp, #(8 * 64)]
    str             x8, [sp, #(9 * 64)]
    str             x9, [sp, #(10 * 64)]
    str             x10, [sp, #(11 * 64)]
    str             x11, [sp, #(12 * 64)]
    str             x12, [sp, #(13 * 64)]
    str             x13, [sp, #(14 * 64)]
    str             x14, [sp, #(15 * 64)]
    str             x15, [sp, #(16 * 64)]
    str             x16, [sp, #(17 * 64)]
    str             x17, [sp, #(18 * 64)]
    str             x18, [sp, #(19 * 64)]
    str             x19, [sp, #(20 * 64)]
    str             x20, [sp, #(21 * 64)]
    str             x21, [sp, #(22 * 64)]
    str             x22, [sp, #(23 * 64)]
    str             x23, [sp, #(24 * 64)]
    str             x24, [sp, #(25 * 64)]
    str             x25, [sp, #(26 * 64)]
    str             x26, [sp, #(27 * 64)]
    str             x27, [sp, #(28 * 64)]
    str             x28, [sp, #(29 * 64)]
    str             x29, [sp, #(30 * 64)]
    str             x30, [sp, #(31 * 64)]

    sub             sp, sp, #(2 * 32)
    str             w0, [sp, #(1 * 32)]
    str             w8, [sp, #(2 * 32)]

    mov             x1, \number
    ldr             x0, =\string_number
    bl printf

    ldr             w0, [sp, #(1 * 32)]
    ldr             w8, [sp, #(2 * 32)]
    add             sp, sp, #(2 * 32)
    ldr             x0, [sp, #(1 * 64)]
    ldr             x1, [sp, #(2 * 64)]
    ldr             x2, [sp, #(3 * 64)]
    ldr             x3, [sp, #(4 * 64)]
    ldr             x4, [sp, #(5 * 64)]
    ldr             x5, [sp, #(6 * 64)]
    ldr             x6, [sp, #(7 * 64)]
    ldr             x7, [sp, #(8 * 64)]
    ldr             x8, [sp, #(9 * 64)]
    ldr             x9, [sp, #(10 * 64)]
    ldr             x10, [sp, #(11 * 64)]
    ldr             x11, [sp, #(12 * 64)]
    ldr             x12, [sp, #(13 * 64)]
    ldr             x13, [sp, #(14 * 64)]
    ldr             x14, [sp, #(15 * 64)]
    ldr             x15, [sp, #(16 * 64)]
    ldr             x16, [sp, #(17 * 64)]
    ldr             x17, [sp, #(18 * 64)]
    ldr             x18, [sp, #(19 * 64)]
    ldr             x19, [sp, #(20 * 64)]
    ldr             x20, [sp, #(21 * 64)]
    ldr             x21, [sp, #(22 * 64)]
    ldr             x22, [sp, #(23 * 64)]
    ldr             x23, [sp, #(24 * 64)]
    ldr             x24, [sp, #(25 * 64)]
    ldr             x25, [sp, #(26 * 64)]
    ldr             x26, [sp, #(27 * 64)]
    ldr             x27, [sp, #(28 * 64)]
    ldr             x28, [sp, #(29 * 64)]
    ldr             x29, [sp, #(30 * 64)]
    ldr             x30, [sp, #(31 * 64)]
    add             sp, sp, #(    31 * 64)       // Free the space at the end of the block.
.endm

.macro string_print msg, len
    sub             sp, sp, #(3 * 64)       // Allocate space for the whole block.
    str             x0, [sp, #(1 * 64)]
    str             x1, [sp, #(2 * 64)]
    str             x2, [sp, #(3 * 64)]
    sub             sp, sp, #(1 * 32)
    str             w8, [sp, #(1 * 32)]

    mov             x0, #1      /* fd := STDOUT_FILENO */
    ldr             x1, =\msg    /* buf := msg */
    ldr             x2, =\len    /* count := len */
    mov             w8, #64     /* write is syscall #64 */
    svc             #0          /* invoke syscall */

    ldr             w8, [sp, #(1 * 32)]
    add             sp, sp, #(1 * 32)       // Free the space at the end of the block
    ldr             x0, [sp, #(1 * 64)]
    ldr             x1, [sp, #(2 * 64)]
    ldr             x2, [sp, #(3 * 64)]
    ldr             w8, [sp, #(4 * 64)]
    add             sp, sp, #(3 * 64)       // Free the space at the end of the block.
.endm

.macro my_exit
    sub             sp, sp, #(31 * 64)
    mov             x1, #1
    ldr             x0, #4
    bl printf
.endm

.macro unit_test a, b, c, d
    ptrue           p0.b, vl4
    string_print    msg_temp_sve, len_temp_sve
    ld1b            {z0.b}, p0/z, [\c]
    mov             x11, v0.d[0]
    custom_printf   string_number, x11
    mov             x11, v0.d[1]
    custom_printf   string_number, x11
    uxtb            z0.h, p0/M, z0.h
    mov             x11, v0.d[0]
    custom_printf   string_number, x11
    mov             x11, v0.d[1]
    custom_printf   string_number, x11
    st1h            {z0.h}, p0, [\a]
    add             \a, \a, \b, lsl #1
    add             \c, \c, \d
    my_exit
.endm

.data
msg_temp_sve:
    .ascii        "#### SVE ####\n"
len_temp_sve = . - msg_temp_sve
msg_temp_neon:
    .ascii        "#### NEON ####\n"
len_temp_neon = . - msg_temp_neon
