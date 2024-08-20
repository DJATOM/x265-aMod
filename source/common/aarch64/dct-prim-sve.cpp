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

#include "dct-prim.h"
#include "neon-sve-bridge.h"
#include <arm_neon.h>


namespace
{
using namespace X265_NS;

// First four elements (duplicated) of rows 1, 3, 5 and 7 in g_t8 (8x8 DCT
// matrix.)
const int16_t t8_odd[4][8] =
{
    { 89,  75,  50,  18, 89,  75,  50,  18 },
    { 75, -18, -89, -50, 75, -18, -89, -50 },
    { 50, -89,  18,  75, 50, -89,  18,  75 },
    { 18, -50,  75, -89, 18, -50,  75, -89 },
};

template<int shift>
static inline void partialButterfly8_sve(const int16_t *src, int16_t *dst)
{
    const int line = 8;

    int16x8_t O[line / 2];
    int32x4_t EE[line / 2];
    int32x4_t EO[line / 2];

    for (int i = 0; i < line; i += 2)
    {
        int16x8_t s_lo = vcombine_s16(vld1_s16(src + i * line),
                                      vld1_s16(src + (i + 1) * line));
        int16x8_t s_hi = vcombine_s16(
            vrev64_s16(vld1_s16(src + i * line + 4)),
            vrev64_s16(vld1_s16(src + (i + 1) * line + 4)));

        int32x4_t E0 = vaddl_s16(vget_low_s16(s_lo), vget_low_s16(s_hi));
        int32x4_t E1 = vaddl_s16(vget_high_s16(s_lo), vget_high_s16(s_hi));

        O[i / 2] = vsubq_s16(s_lo, s_hi);

        int32x4_t t0 = vreinterpretq_s32_s64(
            vzip1q_s64(vreinterpretq_s64_s32(E0), vreinterpretq_s64_s32(E1)));
        int32x4_t t1 = vrev64q_s32(vreinterpretq_s32_s64(
            vzip2q_s64(vreinterpretq_s64_s32(E0), vreinterpretq_s64_s32(E1))));

        EE[i / 2] = vaddq_s32(t0, t1);
        EO[i / 2] = vsubq_s32(t0, t1);
    }

    int16_t *d = dst;

    int32x4_t c0 = vld1q_s32(t8_even[0]);
    int32x4_t c2 = vld1q_s32(t8_even[1]);
    int32x4_t c4 = vld1q_s32(t8_even[2]);
    int32x4_t c6 = vld1q_s32(t8_even[3]);
    int16x8_t c1 = vld1q_s16(t8_odd[0]);
    int16x8_t c3 = vld1q_s16(t8_odd[1]);
    int16x8_t c5 = vld1q_s16(t8_odd[2]);
    int16x8_t c7 = vld1q_s16(t8_odd[3]);

    for (int j = 0; j < line; j += 4)
    {
        // O
        int64x2_t t01 = x265_sdotq_s16(vdupq_n_s64(0), O[j / 2 + 0], c1);
        int64x2_t t23 = x265_sdotq_s16(vdupq_n_s64(0), O[j / 2 + 1], c1);
        int32x4_t t0123 = vcombine_s32(vmovn_s64(t01), vmovn_s64(t23));
        int16x4_t res1 = vrshrn_n_s32(t0123, shift);
        vst1_s16(d + 1 * line, res1);

        t01 = x265_sdotq_s16(vdupq_n_s64(0), O[j / 2 + 0], c3);
        t23 = x265_sdotq_s16(vdupq_n_s64(0), O[j / 2 + 1], c3);
        t0123 = vcombine_s32(vmovn_s64(t01), vmovn_s64(t23));
        int16x4_t res3 = vrshrn_n_s32(t0123, shift);
        vst1_s16(d + 3 * line, res3);

        t01 = x265_sdotq_s16(vdupq_n_s64(0), O[j / 2 + 0], c5);
        t23 = x265_sdotq_s16(vdupq_n_s64(0), O[j / 2 + 1], c5);
        t0123 = vcombine_s32(vmovn_s64(t01), vmovn_s64(t23));
        int16x4_t res5 = vrshrn_n_s32(t0123, shift);
        vst1_s16(d + 5 * line, res5);

        t01 = x265_sdotq_s16(vdupq_n_s64(0), O[j / 2 + 0], c7);
        t23 = x265_sdotq_s16(vdupq_n_s64(0), O[j / 2 + 1], c7);
        t0123 = vcombine_s32(vmovn_s64(t01), vmovn_s64(t23));
        int16x4_t res7 = vrshrn_n_s32(t0123, shift);
        vst1_s16(d + 7 * line, res7);

        // EE and EO
        int32x4_t t0 = vpaddq_s32(EE[j / 2 + 0], EE[j / 2 + 1]);
        int32x4_t t1 = vmulq_s32(c0, t0);
        int16x4_t res0 = vrshrn_n_s32(t1, shift);
        vst1_s16(d + 0 * line, res0);

        int32x4_t t2 = vmulq_s32(c2, EO[j / 2 + 0]);
        int32x4_t t3 = vmulq_s32(c2, EO[j / 2 + 1]);
        int16x4_t res2 = vrshrn_n_s32(vpaddq_s32(t2, t3), shift);
        vst1_s16(d + 2 * line, res2);

        int32x4_t t4 = vmulq_s32(c4, EE[j / 2 + 0]);
        int32x4_t t5 = vmulq_s32(c4, EE[j / 2 + 1]);
        int16x4_t res4 = vrshrn_n_s32(vpaddq_s32(t4, t5), shift);
        vst1_s16(d + 4 * line, res4);

        int32x4_t t6 = vmulq_s32(c6, EO[j / 2 + 0]);
        int32x4_t t7 = vmulq_s32(c6, EO[j / 2 + 1]);
        int16x4_t res6 = vrshrn_n_s32(vpaddq_s32(t6, t7), shift);
        vst1_s16(d + 6 * line, res6);

        d += 4;
    }
}

}


namespace X265_NS
{
// x265 private namespace
void dct8_sve(const int16_t *src, int16_t *dst, intptr_t srcStride)
{
    const int shift_pass1 = 2 + X265_DEPTH - 8;
    const int shift_pass2 = 9;

    ALIGN_VAR_32(int16_t, coef[8 * 8]);
    ALIGN_VAR_32(int16_t, block[8 * 8]);

    for (int i = 0; i < 8; i++)
    {
        memcpy(&block[i * 8], &src[i * srcStride], 8 * sizeof(int16_t));
    }

    partialButterfly8_sve<shift_pass1>(block, coef);
    partialButterfly8_sve<shift_pass2>(coef, dst);
}

void setupDCTPrimitives_sve(EncoderPrimitives &p)
{
    p.cu[BLOCK_8x8].dct   = dct8_sve;
}

};
