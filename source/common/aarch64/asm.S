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
#elif defined(PIC)
        adrp            \rd, \val+(\offset)
        add             \rd, \rd, :lo12:\val+(\offset)
#else
        ldr             \rd, =\val+\offset
#endif
.endm

#define FENC_STRIDE 64
#define FDEC_STRIDE 32
