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

#define FUNCDEF_TU(ret, name, cpu, ...) \
    ret PFX(name ## _4x4_ ## cpu(__VA_ARGS__)); \
    ret PFX(name ## _8x8_ ## cpu(__VA_ARGS__)); \
    ret PFX(name ## _16x16_ ## cpu(__VA_ARGS__)); \
    ret PFX(name ## _32x32_ ## cpu(__VA_ARGS__)); \
    ret PFX(name ## _64x64_ ## cpu(__VA_ARGS__))

#define FUNCDEF_TU_S(ret, name, cpu, ...) \
    ret PFX(name ## _4_ ## cpu(__VA_ARGS__)); \
    ret PFX(name ## _8_ ## cpu(__VA_ARGS__)); \
    ret PFX(name ## _16_ ## cpu(__VA_ARGS__)); \
    ret PFX(name ## _32_ ## cpu(__VA_ARGS__)); \
    ret PFX(name ## _64_ ## cpu(__VA_ARGS__))

#define FUNCDEF_TU_S2(ret, name, cpu, ...) \
    ret PFX(name ## 4_ ## cpu(__VA_ARGS__)); \
    ret PFX(name ## 8_ ## cpu(__VA_ARGS__)); \
    ret PFX(name ## 16_ ## cpu(__VA_ARGS__)); \
    ret PFX(name ## 32_ ## cpu(__VA_ARGS__)); \
    ret PFX(name ## 64_ ## cpu(__VA_ARGS__))

#define FUNCDEF_PU(ret, name, cpu, ...) \
    ret PFX(name ## _4x4_   ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _8x8_   ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _16x16_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _32x32_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _64x64_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _8x4_   ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _4x8_   ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _16x8_  ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _8x16_  ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _16x32_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _32x16_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _64x32_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _32x64_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _16x12_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _12x16_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _16x4_  ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _4x16_  ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _32x24_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _24x32_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _32x8_  ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _8x32_  ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _64x48_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _48x64_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _64x16_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _16x64_ ## cpu)(__VA_ARGS__)

#define FUNCDEF_CHROMA_PU(ret, name, cpu, ...) \
    FUNCDEF_PU(ret, name, cpu, __VA_ARGS__); \
    ret PFX(name ## _4x2_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _4x4_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _2x4_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _8x2_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _2x8_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _8x6_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _6x8_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _8x12_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _12x8_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _6x16_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _16x6_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _2x16_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _16x2_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _4x12_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _12x4_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _32x12_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _12x32_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _32x4_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _4x32_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _32x48_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _48x32_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _16x24_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _24x16_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _8x64_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _64x8_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _64x24_ ## cpu)(__VA_ARGS__); \
    ret PFX(name ## _24x64_ ## cpu)(__VA_ARGS__);

#define DECLS(cpu) \
    FUNCDEF_PU(void, interp_8tap_horiz_pp, cpu, const pixel* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx); \
    FUNCDEF_PU(void, interp_8tap_horiz_ps, cpu, const pixel* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx, int isRowExt); \
    FUNCDEF_PU(void, interp_8tap_vert_pp, cpu, const pixel* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx); \
    FUNCDEF_PU(void, interp_8tap_vert_ps, cpu, const pixel* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx); \
    FUNCDEF_PU(void, interp_8tap_vert_sp, cpu, const int16_t* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx); \
    FUNCDEF_PU(void, interp_8tap_vert_ss, cpu, const int16_t* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx); \
    FUNCDEF_PU(void, interp_8tap_hv_pp, cpu, const pixel* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int idxX, int idxY); \
    FUNCDEF_CHROMA_PU(void, filterPixelToShort, cpu, const pixel* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride); \
    FUNCDEF_CHROMA_PU(void, filterPixelToShort_aligned, cpu, const pixel* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride); \
    FUNCDEF_CHROMA_PU(void, interp_horiz_pp, cpu, const pixel* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx); \
    FUNCDEF_CHROMA_PU(void, interp_4tap_horiz_pp, cpu, const pixel* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx); \
    FUNCDEF_CHROMA_PU(void, interp_horiz_ps, cpu, const pixel* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx, int isRowExt); \
    FUNCDEF_CHROMA_PU(void, interp_4tap_horiz_ps, cpu, const pixel* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx, int isRowExt); \
    FUNCDEF_CHROMA_PU(void, interp_4tap_vert_pp, cpu, const pixel* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx); \
    FUNCDEF_CHROMA_PU(void, interp_4tap_vert_ps, cpu, const pixel* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx); \
    FUNCDEF_CHROMA_PU(void, interp_4tap_vert_sp, cpu, const int16_t* src, intptr_t srcStride, pixel* dst, intptr_t dstStride, int coeffIdx); \
    FUNCDEF_CHROMA_PU(void, interp_4tap_vert_ss, cpu, const int16_t* src, intptr_t srcStride, int16_t* dst, intptr_t dstStride, int coeffIdx); \

DECLS(neon);
