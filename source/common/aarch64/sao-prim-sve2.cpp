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

static inline uint8x16_t sve_count(int8x16_t in)
{
    // We do not care about initialising the values in the rest of the vector,
    // for VL > 128, as HISTSEG counts matching elements in 128-bit segments.
    svint8_t edge_type = svset_neonq_s8(svundef_s8(), in);

    // Use an arbitrary value outside of range [-2, 2] for lanes we don't
    // need to use the result from.
    const int DC = -3;
    // s_eoTable maps edge types to memory in order: {2, 0, 1, 3, 4}.
    // We use (edge_class - 2) resulting in   {0, -2, -1, 1, 2}
    int8x16_t idx = { 0, -2, -1, 1, 2, DC, DC, DC, DC, DC, DC, DC, DC, DC, DC,
                      DC };
    svint8_t svidx = svset_neonq_s8(svundef_s8(), idx);

    svuint8_t count = svhistseg_s8(svidx, edge_type);
    return svget_neonq_u8(count);
}

/*
 * Compute Edge Offset statistics (stats array).
 * To save some instructions compute stats as negative values - since output of
 * Neon comparison instructions for a matched condition is all 1s (-1).
 */
static inline void compute_eo_stats(const int8x16_t edge_type,
                                    const int16_t *diff, int64x2_t *stats)
{
    // Create a mask for each edge type.
    int8x16_t mask0 = vreinterpretq_s8_u8(vceqq_s8(edge_type, vdupq_n_s8(-2)));
    int8x16_t mask1 = vreinterpretq_s8_u8(vceqq_s8(edge_type, vdupq_n_s8(-1)));
    int8x16_t mask2 = vreinterpretq_s8_u8(vceqq_s8(edge_type, vdupq_n_s8(0)));
    int8x16_t mask3 = vreinterpretq_s8_u8(vceqq_s8(edge_type, vdupq_n_s8(1)));
    int8x16_t mask4 = vreinterpretq_s8_u8(vceqq_s8(edge_type, vdupq_n_s8(2)));

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
    stats[0] = x265_sdotq_s16(stats[0], diff_lo, mask0_lo);
    stats[0] = x265_sdotq_s16(stats[0], diff_hi, mask0_hi);
    stats[1] = x265_sdotq_s16(stats[1], diff_lo, mask1_lo);
    stats[1] = x265_sdotq_s16(stats[1], diff_hi, mask1_hi);
    stats[2] = x265_sdotq_s16(stats[2], diff_lo, mask2_lo);
    stats[2] = x265_sdotq_s16(stats[2], diff_hi, mask2_hi);
    stats[3] = x265_sdotq_s16(stats[3], diff_lo, mask3_lo);
    stats[3] = x265_sdotq_s16(stats[3], diff_hi, mask3_hi);
    stats[4] = x265_sdotq_s16(stats[4], diff_lo, mask4_lo);
    stats[4] = x265_sdotq_s16(stats[4], diff_hi, mask4_hi);
}

/*
 * Reduce and store Edge Offset statistics (count and stats).
 */
static inline void reduce_eo_stats(int64x2_t *vstats, uint16x8_t vcount,
                                   int32_t *stats, int32_t *count)
{
    // s_eoTable maps edge types to memory in order: {2, 0, 1, 3, 4}.
    // We already have the count values in the correct order for the store,
    // so widen to 32-bit and accumulate to the destination.
    int32x4_t c0123 = vmovl_s16(vget_low_s16(vreinterpretq_s16_u16(vcount)));
    vst1q_s32(count, vaddq_s32(vld1q_s32(count), c0123));
    count[4] += vcount[4];

    int32x4_t s01 = vcombine_s32(vmovn_s64(vstats[2]), vmovn_s64(vstats[0]));
    int32x4_t s23 = vcombine_s32(vmovn_s64(vstats[1]), vmovn_s64(vstats[3]));
    int32x4_t s0123 = vpaddq_s32(s01, s23);
    // Subtract from current stats, as we calculate the negation.
    vst1q_s32(stats, vsubq_s32(vld1q_s32(stats), s0123));
    stats[4] -= vaddvq_s64(vstats[4]);
}

namespace X265_NS {
void saoCuStatsE0_sve2(const int16_t *diff, const pixel *rec, intptr_t stride,
                       int endX, int endY, int32_t *stats, int32_t *count)
{
    // Separate buffers for each edge type, so that we can vectorise.
    int64x2_t tmp_stats[5] = { vdupq_n_s64(0), vdupq_n_s64(0), vdupq_n_s64(0),
                               vdupq_n_s64(0), vdupq_n_s64(0) };
    uint16x8_t count_acc_u16 = vdupq_n_u16(0);

    for (int y = 0; y < endY; y++)
    {
        uint8x16_t count_acc_u8 = vdupq_n_u8(0);

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

            edge_type = x265_sve_mask(x, endX, edge_type);
            count_acc_u8 = vaddq_u8(count_acc_u8, sve_count(edge_type));
            compute_eo_stats(edge_type, diff + x, tmp_stats);
        }

        // The width (endX) can be a maximum of 64, so we can safely
        // widen from 8-bit count accumulators after one inner loop iteration.
        // Technically the largest an accumulator could reach after one inner
        // loop iteration is 64, if every input value had the same edge type, so
        // we could complete two iterations (2 * 64 = 128) before widening.
        count_acc_u16 = vaddw_u8(count_acc_u16, vget_low_u8(count_acc_u8));

        diff += MAX_CU_SIZE;
        rec += stride;
    }

    reduce_eo_stats(tmp_stats, count_acc_u16, stats, count);
}

void saoCuStatsE1_sve2(const int16_t *diff, const pixel *rec, intptr_t stride,
                       int8_t *upBuff1, int endX, int endY, int32_t *stats,
                       int32_t *count)
{
    // Separate buffers for each edge type, so that we can vectorise.
    int64x2_t tmp_stats[5] = { vdupq_n_s64(0), vdupq_n_s64(0), vdupq_n_s64(0),
                               vdupq_n_s64(0), vdupq_n_s64(0) };
    uint16x8_t count_acc_u16 = vdupq_n_u16(0);

    // Negate upBuff1 (sign_up), so we can subtract and save repeated negations.
    for (int x = 0; x < endX; x += 16)
    {
        vst1q_s8(upBuff1 + x, vnegq_s8(vld1q_s8(upBuff1 + x)));
    }

    for (int y = 0; y < endY; y++)
    {
        uint8x16_t count_acc_u8 = vdupq_n_u8(0);

        for (int x = 0; x < endX; x += 16)
        {
            int8x16_t sign_up = vld1q_s8(upBuff1 + x);
            int8x16_t sign_down = signOf_neon(rec + x, rec + x + stride);

            // Subtract instead of add, as sign_up is negated.
            int8x16_t edge_type = vsubq_s8(sign_down, sign_up);

            // For reuse in the next iteration.
            vst1q_s8(upBuff1 + x, sign_down);

            edge_type = x265_sve_mask(x, endX, edge_type);
            count_acc_u8 = vaddq_u8(count_acc_u8, sve_count(edge_type));
            compute_eo_stats(edge_type, diff + x, tmp_stats);
        }

        // The width (endX) can be a maximum of 64, so we can safely
        // widen from 8-bit count accumulators after one inner loop iteration.
        // Technically the largest an accumulator could reach after one inner
        // loop iteration is 64, if every input value had the same edge type, so
        // we could complete two iterations (2 * 64 = 128) before widening.
        count_acc_u16 = vaddw_u8(count_acc_u16, vget_low_u8(count_acc_u8));

        diff += MAX_CU_SIZE;
        rec += stride;
    }

    reduce_eo_stats(tmp_stats, count_acc_u16, stats, count);
}

void saoCuStatsE2_sve2(const int16_t *diff, const pixel *rec, intptr_t stride,
                       int8_t *upBuff1, int8_t *upBufft, int endX, int endY,
                       int32_t *stats, int32_t *count)
{
    // Separate buffers for each edge type, so that we can vectorise.
    int64x2_t tmp_stats[5] = { vdupq_n_s64(0), vdupq_n_s64(0), vdupq_n_s64(0),
                               vdupq_n_s64(0), vdupq_n_s64(0) };
    uint16x8_t count_acc_u16 = vdupq_n_u16(0);

    // Negate upBuff1 (sign_up) so we can subtract and save repeated negations.
    for (int x = 0; x < endX; x += 16)
    {
        vst1q_s8(upBuff1 + x, vnegq_s8(vld1q_s8(upBuff1 + x)));
    }

    for (int y = 0; y < endY; y++)
    {
        uint8x16_t count_acc_u8 = vdupq_n_u8(0);

        upBufft[0] = x265_signOf(rec[-1] - rec[stride]);
        for (int x = 0; x < endX; x += 16)
        {
            int8x16_t sign_up = vld1q_s8(upBuff1 + x);
            int8x16_t sign_down = signOf_neon(rec + x, rec + x + stride + 1);

            // Subtract instead of add, as sign_up is negated.
            int8x16_t edge_type = vsubq_s8(sign_down, sign_up);

            // For reuse in the next iteration.
            vst1q_s8(upBufft + x + 1, sign_down);

            edge_type = x265_sve_mask(x, endX, edge_type);
            count_acc_u8 = vaddq_u8(count_acc_u8, sve_count(edge_type));
            compute_eo_stats(edge_type, diff + x, tmp_stats);
        }

        std::swap(upBuff1, upBufft);

        // The width (endX) can be a maximum of 64, so we can safely
        // widen from 8-bit count accumulators after one inner loop iteration.
        // Technically the largest an accumulator could reach after one inner
        // loop iteration is 64, if every input value had the same edge type, so
        // we could complete two iterations (2 * 64 = 128) before widening.
        count_acc_u16 = vaddw_u8(count_acc_u16, vget_low_u8(count_acc_u8));

        rec += stride;
        diff += MAX_CU_SIZE;
    }

    reduce_eo_stats(tmp_stats, count_acc_u16, stats, count);
}

void saoCuStatsE3_sve2(const int16_t *diff, const pixel *rec, intptr_t stride,
                       int8_t *upBuff1, int endX, int endY, int32_t *stats,
                       int32_t *count)
{
    // Separate buffers for each edge type, so that we can vectorise.
    int64x2_t tmp_stats[5] = { vdupq_n_s64(0), vdupq_n_s64(0), vdupq_n_s64(0),
                               vdupq_n_s64(0), vdupq_n_s64(0) };
    uint16x8_t count_acc_u16 = vdupq_n_u16(0);

    // Negate upBuff1 (sign_up) so we can subtract and save repeated negations.
    for (int x = 0; x < endX; x += 16)
    {
        vst1q_s8(upBuff1 + x, vnegq_s8(vld1q_s8(upBuff1 + x)));
    }

    for (int y = 0; y < endY; y++)
    {
        uint8x16_t count_acc_u8 = vdupq_n_u8(0);

        for (int x = 0; x < endX; x += 16)
        {
            int8x16_t sign_up = vld1q_s8(upBuff1 + x);
            int8x16_t sign_down = signOf_neon(rec + x, rec + x + stride - 1);

            // Subtract instead of add, as sign_up is negated.
            int8x16_t edge_type = vsubq_s8(sign_down, sign_up);

            // For reuse in the next iteration.
            vst1q_s8(upBuff1 + x - 1, sign_down);

            edge_type = x265_sve_mask(x, endX, edge_type);
            count_acc_u8 = vaddq_u8(count_acc_u8, sve_count(edge_type));
            compute_eo_stats(edge_type, diff + x, tmp_stats);
        }

        upBuff1[endX - 1] = x265_signOf(rec[endX] - rec[endX - 1 + stride]);

        // The width (endX) can be a maximum of 64, so we can safely
        // widen from 8-bit count accumulators after one inner loop iteration.
        // Technically the largest an accumulator could reach after one inner
        // loop iteration is 64, if every input value had the same edge type, so
        // we could complete two iterations (2 * 64 = 128) before widening.
        count_acc_u16 = vaddw_u8(count_acc_u16, vget_low_u8(count_acc_u8));

        rec += stride;
        diff += MAX_CU_SIZE;
    }

    reduce_eo_stats(tmp_stats, count_acc_u16, stats, count);
}

void setupSaoPrimitives_sve2(EncoderPrimitives &p)
{
    p.saoCuStatsE0 = saoCuStatsE0_sve2;
    p.saoCuStatsE1 = saoCuStatsE1_sve2;
    p.saoCuStatsE2 = saoCuStatsE2_sve2;
    p.saoCuStatsE3 = saoCuStatsE3_sve2;
}
} // namespace X265_NS
