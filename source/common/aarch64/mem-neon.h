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

#ifndef X265_COMMON_AARCH64_MEM_NEON_H
#define X265_COMMON_AARCH64_MEM_NEON_H

#include <arm_neon.h>
#include <stdint.h>

// Load 4 bytes into the low half of a uint8x8_t, zero the upper half.
static uint8x8_t inline load_u8x4x1(const uint8_t *s)
{
    uint8x8_t ret = vdup_n_u8(0);

    ret = vreinterpret_u8_u32(vld1_lane_u32((const uint32_t*)s,
                                            vreinterpret_u32_u8(ret), 0));
    return ret;
}

static uint8x8_t inline load_u8x4x2(const uint8_t *s, intptr_t stride)
{
    uint8x8_t ret = vdup_n_u8(0);

    ret = vreinterpret_u8_u32(vld1_lane_u32((const uint32_t*)s,
                                            vreinterpret_u32_u8(ret), 0));
    s += stride;
    ret = vreinterpret_u8_u32(vld1_lane_u32((const uint32_t*)s,
                                            vreinterpret_u32_u8(ret), 1));

    return ret;
}

// Store 4 bytes from the low half of a uint8x8_t.
static void inline store_u8x4x1(uint8_t *d, const uint8x8_t s)
{
    vst1_lane_u32((uint32_t *)d, vreinterpret_u32_u8(s), 0);
}

#endif // X265_COMMON_AARCH64_MEM_NEON_H
