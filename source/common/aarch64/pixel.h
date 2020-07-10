/*****************************************************************************
 * Copyright (C) 2020 MulticoreWare, Inc
 *
 * Authors: Hongbin Liu <liuhongbin1@huawei.com>
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

#ifndef X265_I386_PIXEL_AARCH64_H
#define X265_I386_PIXEL_AARCH64_H

void x265_pixel_avg_pp_4x4_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_4x8_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_4x16_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_8x4_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_8x8_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_8x16_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_8x32_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_12x16_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_16x4_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_16x8_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_16x12_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_16x16_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_16x32_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_16x64_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_24x32_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_32x8_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_32x16_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_32x24_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_32x32_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_32x64_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_48x64_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_64x16_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_64x32_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_64x48_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);
void x265_pixel_avg_pp_64x64_neon (pixel* dst, intptr_t dstride, const pixel* src0, intptr_t sstride0, const pixel* src1, intptr_t sstride1, int);

void x265_sad_x3_4x4_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_4x8_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_4x16_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_8x4_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_8x8_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_8x16_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_8x32_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_12x16_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_16x4_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_16x8_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_16x12_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_16x16_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_16x32_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_16x64_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_24x32_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_32x8_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_32x16_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_32x24_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_32x32_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_32x64_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_48x64_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_64x16_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_64x32_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_64x48_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);
void x265_sad_x3_64x64_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, intptr_t frefstride, int32_t* res);

void x265_sad_x4_4x4_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_4x8_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_4x16_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_8x4_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_8x8_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_8x16_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_8x32_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_12x16_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_16x4_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_16x8_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_16x12_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_16x16_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_16x32_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_16x64_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_24x32_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_32x8_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_32x16_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_32x24_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_32x32_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_32x64_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_48x64_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_64x16_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_64x32_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_64x48_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);
void x265_sad_x4_64x64_neon(const pixel* fenc, const pixel* fref0, const pixel* fref1, const pixel* fref2, const pixel* fref3, intptr_t frefstride, int32_t* res);

#endif // ifndef X265_I386_PIXEL_AARCH64_H
