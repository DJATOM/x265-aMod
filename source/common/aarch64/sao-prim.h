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

#include "neon-sve-bridge.h"
#include "primitives.h"
#include <arm_neon.h>

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
