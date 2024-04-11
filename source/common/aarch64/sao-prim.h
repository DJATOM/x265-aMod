/*****************************************************************************
 * Copyright (C) 2024 MulticoreWare, Inc
 *
 * Authors: Hari Limaye <hari.limaye@arm.com>
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

#ifndef X265_COMMON_AARCH64_SAO_PRIM_H
#define X265_COMMON_AARCH64_SAO_PRIM_H

#include "primitives.h"
#include <arm_neon.h>

#if defined(HAVE_SVE) && HAVE_SVE_BRIDGE
#include <arm_neon_sve_bridge.h>

/* We can access instructions that are exclusive to the SVE or SVE2 instruction
 * sets from a predominantly Neon context by making use of the Neon-SVE bridge
 * intrinsics to reinterpret Neon vectors as SVE vectors - with the high part of
 * the SVE vector (if it's longer than 128 bits) being "don't care".
 *
 * While sub-optimal on machines that have SVE vector length > 128-bit - as the
 * remainder of the vector is unused - this approach is still beneficial when
 * compared to a Neon-only implementation. */

static inline int8x16_t x265_sve_mask(const int x, const int endX,
                                      const int8x16_t in)
{
    // Use predicate to shift "unused lanes" outside of range [-2, 2]
    svbool_t svpred = svwhilelt_b8(x, endX);
    svint8_t edge_type = svsel_s8(svpred, svset_neonq_s8(svundef_s8(), in),
                                  svdup_n_s8(-3));
    return svget_neonq_s8(edge_type);
}

static inline int64x2_t x265_sdotq_s16(int64x2_t acc, int16x8_t x, int16x8_t y)
{
    return svget_neonq_s64(svdot_s64(svset_neonq_s64(svundef_s64(), acc),
                                     svset_neonq_s16(svundef_s16(), x),
                                     svset_neonq_s16(svundef_s16(), y)));
}

#endif // defined(HAVE_SVE) && HAVE_SVE_BRIDGE

static inline int8x16_t signOf_neon(const pixel *a, const pixel *b)
{
#if HIGH_BIT_DEPTH
    uint16x8_t s0_lo = vld1q_u16(a);
    uint16x8_t s0_hi = vld1q_u16(a + 8);
    uint16x8_t s1_lo = vld1q_u16(b);
    uint16x8_t s1_hi = vld1q_u16(b + 8);

    // signOf(a - b) = -(a > b ? -1 : 0) | (a < b ? -1 : 0)
    int16x8_t cmp0_lo = vreinterpretq_s16_u16(vcgtq_u16(s0_lo, s1_lo));
    int16x8_t cmp0_hi = vreinterpretq_s16_u16(vcgtq_u16(s0_hi, s1_hi));
    int16x8_t cmp1_lo = vreinterpretq_s16_u16(vcgtq_u16(s1_lo, s0_lo));
    int16x8_t cmp1_hi = vreinterpretq_s16_u16(vcgtq_u16(s1_hi, s0_hi));

    int8x16_t cmp0 = vcombine_s8(vmovn_s16(cmp0_lo), vmovn_s16(cmp0_hi));
    int8x16_t cmp1 = vcombine_s8(vmovn_s16(cmp1_lo), vmovn_s16(cmp1_hi));
#else // HIGH_BIT_DEPTH
    uint8x16_t s0 = vld1q_u8(a);
    uint8x16_t s1 = vld1q_u8(b);

    // signOf(a - b) = -(a > b ? -1 : 0) | (a < b ? -1 : 0)
    int8x16_t cmp0 = vreinterpretq_s8_u8(vcgtq_u8(s0, s1));
    int8x16_t cmp1 = vreinterpretq_s8_u8(vcgtq_u8(s1, s0));
#endif // HIGH_BIT_DEPTH
    return vorrq_s8(vnegq_s8(cmp0), cmp1);
}

namespace X265_NS {
void setupSaoPrimitives_neon(EncoderPrimitives &p);

#if defined(HAVE_SVE) && HAVE_SVE_BRIDGE
void setupSaoPrimitives_sve(EncoderPrimitives &p);
#endif

#if defined(HAVE_SVE2) && HAVE_SVE_BRIDGE
void setupSaoPrimitives_sve2(EncoderPrimitives &p);
#endif
}

#endif // X265_COMMON_AARCH64_SAO_PRIM_H
