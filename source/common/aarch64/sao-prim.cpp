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

#include "sao-prim.h"
#include "sao.h"
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

// Predicate mask indices.
static const int8_t quad_reg_byte_indices[16] = {
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
};

static inline int8x16_t mask_inactive_elems(const int rem, int8x16_t edge_type)
{
    // Compute a predicate mask where the bits of an element are 0 if the index
    // is less than the remainder (active), and 1 otherwise.
    const int8x16_t indices = vld1q_s8(quad_reg_byte_indices);
    int8x16_t pred = vreinterpretq_s8_u8(vcgeq_s8(indices, vdupq_n_s8(rem)));

    // Use predicate mask to shift "unused lanes" outside of range [-2, 2]
    pred = vshlq_n_s8(pred, 3);
    return veorq_s8(edge_type, pred);
}

/*
 * Compute Edge Offset statistics (count and stats).
 * To save some instructions compute count and stats as negative values - since
 * output of Neon comparison instructions for a matched condition is all 1s (-1).
 */
static inline void compute_eo_stats(const int8x16_t edge_type,
                                    const int16_t *diff, int16x8_t *count,
                                    int32x4_t *stats)
{
    // Create a mask for each edge type.
    int8x16_t mask0 = vreinterpretq_s8_u8(vceqq_s8(edge_type, vdupq_n_s8(-2)));
    int8x16_t mask1 = vreinterpretq_s8_u8(vceqq_s8(edge_type, vdupq_n_s8(-1)));
    int8x16_t mask2 = vreinterpretq_s8_u8(vceqq_s8(edge_type, vdupq_n_s8(0)));
    int8x16_t mask3 = vreinterpretq_s8_u8(vceqq_s8(edge_type, vdupq_n_s8(1)));
    int8x16_t mask4 = vreinterpretq_s8_u8(vceqq_s8(edge_type, vdupq_n_s8(2)));

    // Compute negative counts for each edge type.
    count[0] = vpadalq_s8(count[0], mask0);
    count[1] = vpadalq_s8(count[1], mask1);
    count[2] = vpadalq_s8(count[2], mask2);
    count[3] = vpadalq_s8(count[3], mask3);
    count[4] = vpadalq_s8(count[4], mask4);

    // Widen the masks to 16-bit.
    int16x8_t mask0_lo = vreinterpretq_s16_s8(vzip1q_s8(mask0, mask0));
    int16x8_t mask0_hi = vreinterpretq_s16_s8(vzip2q_s8(mask0, mask0));
    int16x8_t mask1_lo = vreinterpretq_s16_s8(vzip1q_s8(mask1, mask1));
    int16x8_t mask1_hi = vreinterpretq_s16_s8(vzip2q_s8(mask1, mask1));
    int16x8_t mask2_lo = vreinterpretq_s16_s8(vzip1q_s8(mask2, mask2));
    int16x8_t mask2_hi = vreinterpretq_s16_s8(vzip2q_s8(mask2, mask2));
    int16x8_t mask3_lo = vreinterpretq_s16_s8(vzip1q_s8(mask3, mask3));
    int16x8_t mask3_hi = vreinterpretq_s16_s8(vzip2q_s8(mask3, mask3));
    int16x8_t mask4_lo = vreinterpretq_s16_s8(vzip1q_s8(mask4, mask4));
    int16x8_t mask4_hi = vreinterpretq_s16_s8(vzip2q_s8(mask4, mask4));

    int16x8_t diff_lo = vld1q_s16(diff);
    int16x8_t diff_hi = vld1q_s16(diff + 8);

    // Compute negative stats for each edge type.
    int16x8_t stats0 = vmulq_s16(diff_lo, mask0_lo);
    int16x8_t stats1 = vmulq_s16(diff_lo, mask1_lo);
    int16x8_t stats2 = vmulq_s16(diff_lo, mask2_lo);
    int16x8_t stats3 = vmulq_s16(diff_lo, mask3_lo);
    int16x8_t stats4 = vmulq_s16(diff_lo, mask4_lo);
    stats0 = vmlaq_s16(stats0, diff_hi, mask0_hi);
    stats1 = vmlaq_s16(stats1, diff_hi, mask1_hi);
    stats2 = vmlaq_s16(stats2, diff_hi, mask2_hi);
    stats3 = vmlaq_s16(stats3, diff_hi, mask3_hi);
    stats4 = vmlaq_s16(stats4, diff_hi, mask4_hi);

    stats[0] = vpadalq_s16(stats[0], stats0);
    stats[1] = vpadalq_s16(stats[1], stats1);
    stats[2] = vpadalq_s16(stats[2], stats2);
    stats[3] = vpadalq_s16(stats[3], stats3);
    stats[4] = vpadalq_s16(stats[4], stats4);
}

/*
 * Reduce and store Edge Offset statistics (count and stats).
 */
static inline void reduce_eo_stats(int32x4_t *vstats, int16x8_t *vcount,
                                   int32_t *stats, int32_t *count)
{
    // s_eoTable maps edge types to memory in order: {2, 0, 1, 3, 4}.
    int16x8_t c01 = vpaddq_s16(vcount[2], vcount[0]);
    int16x8_t c23 = vpaddq_s16(vcount[1], vcount[3]);
    int16x8_t c0123 = vpaddq_s16(c01, c23);

    // Subtract from current count, as we calculate the negation.
    vst1q_s32(count, vsubq_s32(vld1q_s32(count), vpaddlq_s16(c0123)));
    count[4] -= vaddvq_s16(vcount[4]);

    int32x4_t s01 = vpaddq_s32(vstats[2], vstats[0]);
    int32x4_t s23 = vpaddq_s32(vstats[1], vstats[3]);
    int32x4_t s0123 = vpaddq_s32(s01, s23);

    // Subtract from current stats, as we calculate the negation.
    vst1q_s32(stats, vsubq_s32(vld1q_s32(stats), s0123));
    stats[4] -= vaddvq_s32(vstats[4]);
}

namespace X265_NS {
void saoCuStatsBO_neon(const int16_t *diff, const pixel *rec, intptr_t stride,
                       int endX, int endY, int32_t *stats, int32_t *count)
{
#if HIGH_BIT_DEPTH
    const int n_elem = 4;
    const int elem_width = 16;
#else
    const int n_elem = 8;
    const int elem_width = 8;
#endif

    // Additional temporary buffer for accumulation.
    int32_t stats_tmp[32] = { 0 };
    int32_t count_tmp[32] = { 0 };

    // Byte-addressable pointers to buffers, to optimise address calculation.
    uint8_t *stats_b[2] = {
        reinterpret_cast<uint8_t *>(stats),
        reinterpret_cast<uint8_t *>(stats_tmp),
    };
    uint8_t *count_b[2] = {
        reinterpret_cast<uint8_t *>(count),
        reinterpret_cast<uint8_t *>(count_tmp),
    };

    // Combine shift for index calculation with shift for address calculation.
    const int right_shift = X265_DEPTH - X265_NS::SAO::SAO_BO_BITS;
    const int left_shift = 2;
    const int shift = right_shift - left_shift;
    // Mask out bits 7, 1 & 0 to account for combination of shifts.
    const int mask = 0x7c;

    // Compute statistics into temporary buffers.
    for (int y = 0; y < endY; y++)
    {
        int x = 0;
        for (; x + n_elem < endX; x += n_elem)
        {
            uint64_t class_idx_64 =
                *reinterpret_cast<const uint64_t *>(rec + x) >> shift;

            for (int i = 0; i < n_elem; ++i)
            {
                const int idx = i & 1;
                const int off  = (class_idx_64 >> (i * elem_width)) & mask;
                *reinterpret_cast<uint32_t*>(stats_b[idx] + off) += diff[x + i];
                *reinterpret_cast<uint32_t*>(count_b[idx] + off) += 1;
            }
        }

        if (x < endX)
        {
            uint64_t class_idx_64 =
                *reinterpret_cast<const uint64_t *>(rec + x) >> shift;

            for (int i = 0; (i + x) < endX; ++i)
            {
                const int idx = i & 1;
                const int off  = (class_idx_64 >> (i * elem_width)) & mask;
                *reinterpret_cast<uint32_t*>(stats_b[idx] + off) += diff[x + i];
                *reinterpret_cast<uint32_t*>(count_b[idx] + off) += 1;
            }
        }

        diff += MAX_CU_SIZE;
        rec += stride;
    }

    // Reduce temporary buffers to destination using Neon.
    for (int i = 0; i < 32; i += 4)
    {
        int32x4_t s0 = vld1q_s32(stats_tmp + i);
        int32x4_t s1 = vld1q_s32(stats + i);
        vst1q_s32(stats + i, vaddq_s32(s0, s1));

        int32x4_t c0 = vld1q_s32(count_tmp + i);
        int32x4_t c1 = vld1q_s32(count + i);
        vst1q_s32(count + i, vaddq_s32(c0, c1));
    }
}

void saoCuStatsE0_neon(const int16_t *diff, const pixel *rec, intptr_t stride,
                       int endX, int endY, int32_t *stats, int32_t *count)
{
    // Separate buffers for each edge type, so that we can vectorise.
    int16x8_t tmp_count[5] = { vdupq_n_s16(0), vdupq_n_s16(0), vdupq_n_s16(0),
                               vdupq_n_s16(0), vdupq_n_s16(0) };
    int32x4_t tmp_stats[5] = { vdupq_n_s32(0), vdupq_n_s32(0), vdupq_n_s32(0),
                               vdupq_n_s32(0), vdupq_n_s32(0) };

    for (int y = 0; y < endY; y++)
    {
        // Calculate negated sign_left(x) directly, to save negation when
        // reusing sign_right(x) as sign_left(x + 1).
        int8x16_t neg_sign_left = vdupq_n_s8(x265_signOf(rec[-1] - rec[0]));
        for (int x = 0; x < endX; x += 16)
        {
            int8x16_t sign_right = signOf_neon(rec + x, rec + x + 1);

            // neg_sign_left(x) = sign_right(x + 1), reusing one from previous
            // iteration.
            neg_sign_left = vextq_s8(neg_sign_left, sign_right, 15);

            // Subtract instead of add, as sign_left is negated.
            int8x16_t edge_type = vsubq_s8(sign_right, neg_sign_left);

            // For reuse in the next iteration.
            neg_sign_left = sign_right;

            edge_type = mask_inactive_elems(endX - x, edge_type);
            compute_eo_stats(edge_type, diff + x, tmp_count, tmp_stats);
        }

        diff += MAX_CU_SIZE;
        rec += stride;
    }

    reduce_eo_stats(tmp_stats, tmp_count, stats, count);
}

void saoCuStatsE1_neon(const int16_t *diff, const pixel *rec, intptr_t stride,
                       int8_t *upBuff1, int endX, int endY, int32_t *stats,
                       int32_t *count)
{
    // Separate buffers for each edge type, so that we can vectorise.
    int16x8_t tmp_count[5] = { vdupq_n_s16(0), vdupq_n_s16(0), vdupq_n_s16(0),
                               vdupq_n_s16(0), vdupq_n_s16(0) };
    int32x4_t tmp_stats[5] = { vdupq_n_s32(0), vdupq_n_s32(0), vdupq_n_s32(0),
                               vdupq_n_s32(0), vdupq_n_s32(0) };

    // Negate upBuff1 (sign_up), so we can subtract and save repeated negations.
    for (int x = 0; x < endX; x += 16)
    {
        vst1q_s8(upBuff1 + x, vnegq_s8(vld1q_s8(upBuff1 + x)));
    }

    for (int y = 0; y < endY; y++)
    {
        for (int x = 0; x < endX; x += 16)
        {
            int8x16_t sign_up = vld1q_s8(upBuff1 + x);
            int8x16_t sign_down = signOf_neon(rec + x, rec + x + stride);

            // Subtract instead of add, as sign_up is negated.
            int8x16_t edge_type = vsubq_s8(sign_down, sign_up);

            // For reuse in the next iteration.
            vst1q_s8(upBuff1 + x, sign_down);

            edge_type = mask_inactive_elems(endX - x, edge_type);
            compute_eo_stats(edge_type, diff + x, tmp_count, tmp_stats);
        }

        diff += MAX_CU_SIZE;
        rec += stride;
    }

    reduce_eo_stats(tmp_stats, tmp_count, stats, count);
}

void saoCuStatsE2_neon(const int16_t *diff, const pixel *rec, intptr_t stride,
                       int8_t *upBuff1, int8_t *upBufft, int endX, int endY,
                       int32_t *stats, int32_t *count)
{
    // Separate buffers for each edge type, so that we can vectorise.
    int16x8_t tmp_count[5] = { vdupq_n_s16(0), vdupq_n_s16(0), vdupq_n_s16(0),
                               vdupq_n_s16(0), vdupq_n_s16(0) };
    int32x4_t tmp_stats[5] = { vdupq_n_s32(0), vdupq_n_s32(0), vdupq_n_s32(0),
                               vdupq_n_s32(0), vdupq_n_s32(0) };

    // Negate upBuff1 (sign_up) so we can subtract and save repeated negations.
    for (int x = 0; x < endX; x += 16)
    {
        vst1q_s8(upBuff1 + x, vnegq_s8(vld1q_s8(upBuff1 + x)));
    }

    for (int y = 0; y < endY; y++)
    {
        upBufft[0] = x265_signOf(rec[-1] - rec[stride]);
        for (int x = 0; x < endX; x += 16)
        {
            int8x16_t sign_up = vld1q_s8(upBuff1 + x);
            int8x16_t sign_down = signOf_neon(rec + x, rec + x + stride + 1);

            // Subtract instead of add, as sign_up is negated.
            int8x16_t edge_type = vsubq_s8(sign_down, sign_up);

            // For reuse in the next iteration.
            vst1q_s8(upBufft + x + 1, sign_down);

            edge_type = mask_inactive_elems(endX - x, edge_type);
            compute_eo_stats(edge_type, diff + x, tmp_count, tmp_stats);
        }

        std::swap(upBuff1, upBufft);

        rec += stride;
        diff += MAX_CU_SIZE;
    }

    reduce_eo_stats(tmp_stats, tmp_count, stats, count);
}

void saoCuStatsE3_neon(const int16_t *diff, const pixel *rec, intptr_t stride,
                       int8_t *upBuff1, int endX, int endY, int32_t *stats,
                       int32_t *count)
{
    // Separate buffers for each edge type, so that we can vectorise.
    int16x8_t tmp_count[5] = { vdupq_n_s16(0), vdupq_n_s16(0), vdupq_n_s16(0),
                               vdupq_n_s16(0), vdupq_n_s16(0) };
    int32x4_t tmp_stats[5] = { vdupq_n_s32(0), vdupq_n_s32(0), vdupq_n_s32(0),
                               vdupq_n_s32(0), vdupq_n_s32(0) };

    // Negate upBuff1 (sign_up) so we can subtract and save repeated negations.
    for (int x = 0; x < endX; x += 16)
    {
        vst1q_s8(upBuff1 + x, vnegq_s8(vld1q_s8(upBuff1 + x)));
    }

    for (int y = 0; y < endY; y++)
    {
        for (int x = 0; x < endX; x += 16)
        {
            int8x16_t sign_up = vld1q_s8(upBuff1 + x);
            int8x16_t sign_down = signOf_neon(rec + x, rec + x + stride - 1);

            // subtraction instead of addition, as sign_up is negated.
            int8x16_t edge_type = vsubq_s8(sign_down, sign_up);

            // For reuse in the next iteration.
            vst1q_s8(upBuff1 + x - 1, sign_down);

            edge_type = mask_inactive_elems(endX - x, edge_type);
            compute_eo_stats(edge_type, diff + x, tmp_count, tmp_stats);
        }

        upBuff1[endX - 1] = x265_signOf(rec[endX] - rec[endX - 1 + stride]);

        rec += stride;
        diff += MAX_CU_SIZE;
    }

    reduce_eo_stats(tmp_stats, tmp_count, stats, count);
}

void setupSaoPrimitives_neon(EncoderPrimitives &p)
{
    p.saoCuStatsBO = saoCuStatsBO_neon;
    p.saoCuStatsE0 = saoCuStatsE0_neon;
    p.saoCuStatsE1 = saoCuStatsE1_neon;
    p.saoCuStatsE2 = saoCuStatsE2_neon;
    p.saoCuStatsE3 = saoCuStatsE3_neon;
}
} // namespace X265_NS
