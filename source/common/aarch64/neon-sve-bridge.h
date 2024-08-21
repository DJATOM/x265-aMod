/*****************************************************************************
 * Copyright (C) 2024 MulticoreWare, Inc
 *
 * Authors: Hari Limaye <hari.limaye@arm.com>
 *          Jonathan Wright <jonathan.wright@arm.com>
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

#ifndef X265_COMMON_AARCH64_NEON_SVE_BRIDGE_H
#define X265_COMMON_AARCH64_NEON_SVE_BRIDGE_H

#include <arm_neon.h>

#if defined(HAVE_SVE) && HAVE_SVE_BRIDGE
#include <arm_sve.h>
#include <arm_neon_sve_bridge.h>

/* We can access instructions that are exclusive to the SVE or SVE2 instruction
 * sets from a predominantly Neon context by making use of the Neon-SVE bridge
 * intrinsics to reinterpret Neon vectors as SVE vectors - with the high part of
 * the SVE vector (if it's longer than 128 bits) being "don't care".
 *
 * While sub-optimal on machines that have SVE vector length > 128-bit - as the
 * remainder of the vector is unused - this approach is still beneficial when
 * compared to a Neon-only implementation. */

static inline int32x4_t x265_vld1sh_s32(const int16_t *ptr)
{
    return svget_neonq_s32(svld1sh_s32(svptrue_pat_b32(SV_VL4), ptr));
}

static inline int64x2_t x265_sdotq_s16(int64x2_t acc, int16x8_t x, int16x8_t y)
{
    return svget_neonq_s64(svdot_s64(svset_neonq_s64(svundef_s64(), acc),
                                     svset_neonq_s16(svundef_s16(), x),
                                     svset_neonq_s16(svundef_s16(), y)));
}

static inline int8x16_t x265_sve_mask(const int x, const int endX,
                                      const int8x16_t in)
{
    // Use predicate to shift "unused lanes" outside of range [-2, 2]
    svbool_t svpred = svwhilelt_b8(x, endX);
    svint8_t edge_type = svsel_s8(svpred, svset_neonq_s8(svundef_s8(), in),
                                  svdup_n_s8(-3));
    return svget_neonq_s8(edge_type);
}

#endif // defined(HAVE_SVE) && HAVE_SVE_BRIDGE

#endif // X265_COMMON_AARCH64_NEON_SVE_BRIDGE_H
