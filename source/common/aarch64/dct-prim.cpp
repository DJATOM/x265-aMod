#include "dct-prim.h"


#if HAVE_NEON

#include <arm_neon.h>

#define X265_PRAGMA(text)       _Pragma(#text)
#if defined(__clang__)
#define X265_PRAGMA_UNROLL(n)   X265_PRAGMA(unroll(n))
#elif defined(__GNUC__)
#define X265_PRAGMA_UNROLL(n)   X265_PRAGMA(GCC unroll (n))
#else
#define X265_PRAGMA_UNROLL(n)
#endif

namespace
{
using namespace X265_NS;

static void transpose_4x4x16(int16x4_t &x0, int16x4_t &x1, int16x4_t &x2, int16x4_t &x3)
{
    int32x2_t s0, s1, s2, s3;

    s0 = vtrn1_s32(vreinterpret_s32_s16(x0), vreinterpret_s32_s16(x2));
    s1 = vtrn1_s32(vreinterpret_s32_s16(x1), vreinterpret_s32_s16(x3));
    s2 = vtrn2_s32(vreinterpret_s32_s16(x0), vreinterpret_s32_s16(x2));
    s3 = vtrn2_s32(vreinterpret_s32_s16(x1), vreinterpret_s32_s16(x3));

    x0 = vtrn1_s16(vreinterpret_s16_s32(s0), vreinterpret_s16_s32(s1));
    x1 = vtrn2_s16(vreinterpret_s16_s32(s0), vreinterpret_s16_s32(s1));
    x2 = vtrn1_s16(vreinterpret_s16_s32(s2), vreinterpret_s16_s32(s3));
    x3 = vtrn2_s16(vreinterpret_s16_s32(s2), vreinterpret_s16_s32(s3));
}



static int scanPosLast_opt(const uint16_t *scan, const coeff_t *coeff, uint16_t *coeffSign, uint16_t *coeffFlag,
                           uint8_t *coeffNum, int numSig, const uint16_t * /*scanCG4x4*/, const int /*trSize*/)
{

    // This is an optimized function for scanPosLast, which removes the rmw dependency, once integrated into mainline x265, should replace reference implementation
    // For clarity, left the original reference code in comments
    int scanPosLast = 0;

    uint16_t cSign = 0;
    uint16_t cFlag = 0;
    uint8_t cNum = 0;

    uint32_t prevcgIdx = 0;
    do
    {
        const uint32_t cgIdx = (uint32_t)scanPosLast >> MLS_CG_SIZE;

        const uint32_t posLast = scan[scanPosLast];

        const int curCoeff = coeff[posLast];
        const uint32_t isNZCoeff = (curCoeff != 0);
        /*
        NOTE: the new algorithm is complicated, so I keep reference code here
        uint32_t posy   = posLast >> log2TrSize;
        uint32_t posx   = posLast - (posy << log2TrSize);
        uint32_t blkIdx0 = ((posy >> MLS_CG_LOG2_SIZE) << codingParameters.log2TrSizeCG) + (posx >> MLS_CG_LOG2_SIZE);
        const uint32_t blkIdx = ((posLast >> (2 * MLS_CG_LOG2_SIZE)) & ~maskPosXY) + ((posLast >> MLS_CG_LOG2_SIZE) & maskPosXY);
        sigCoeffGroupFlag64 |= ((uint64_t)isNZCoeff << blkIdx);
        */

        // get L1 sig map
        numSig -= isNZCoeff;

        if (scanPosLast % (1 << MLS_CG_SIZE) == 0)
        {
            coeffSign[prevcgIdx] = cSign;
            coeffFlag[prevcgIdx] = cFlag;
            coeffNum[prevcgIdx] = cNum;
            cSign = 0;
            cFlag = 0;
            cNum = 0;
        }
        // TODO: optimize by instruction BTS
        cSign += (uint16_t)(((curCoeff < 0) ? 1 : 0) << cNum);
        cFlag = (cFlag << 1) + (uint16_t)isNZCoeff;
        cNum += (uint8_t)isNZCoeff;
        prevcgIdx = cgIdx;
        scanPosLast++;
    }
    while (numSig > 0);

    coeffSign[prevcgIdx] = cSign;
    coeffFlag[prevcgIdx] = cFlag;
    coeffNum[prevcgIdx] = cNum;
    return scanPosLast - 1;
}


#if (MLS_CG_SIZE == 4)
template<int log2TrSize>
static void nonPsyRdoQuant_neon(int16_t *m_resiDctCoeff, int64_t *costUncoded, int64_t *totalUncodedCost,
                                int64_t *totalRdCost, uint32_t blkPos)
{
    const int transformShift = MAX_TR_DYNAMIC_RANGE - X265_DEPTH -
                               log2TrSize; /* Represents scaling through forward transform */
    const int scaleBits = SCALE_BITS - 2 * transformShift;
    const uint32_t trSize = 1 << log2TrSize;

    int64x2_t vcost_sum_0 = vdupq_n_s64(0);
    int64x2_t vcost_sum_1 = vdupq_n_s64(0);
    for (int y = 0; y < MLS_CG_SIZE; y++)
    {
        int16x4_t in = vld1_s16(&m_resiDctCoeff[blkPos]);
        int32x4_t mul = vmull_s16(in, in);
        int64x2_t cost0, cost1;
        cost0 = vshll_n_s32(vget_low_s32(mul), scaleBits);
        cost1 = vshll_high_n_s32(mul, scaleBits);
        vst1q_s64(&costUncoded[blkPos + 0], cost0);
        vst1q_s64(&costUncoded[blkPos + 2], cost1);
        vcost_sum_0 = vaddq_s64(vcost_sum_0, cost0);
        vcost_sum_1 = vaddq_s64(vcost_sum_1, cost1);
        blkPos += trSize;
    }
    int64_t sum = vaddvq_s64(vaddq_s64(vcost_sum_0, vcost_sum_1));
    *totalUncodedCost += sum;
    *totalRdCost += sum;
}

template<int log2TrSize>
static void psyRdoQuant_neon(int16_t *m_resiDctCoeff, int16_t *m_fencDctCoeff, int64_t *costUncoded,
                             int64_t *totalUncodedCost, int64_t *totalRdCost, int64_t *psyScale, uint32_t blkPos)
{
    const int transformShift = MAX_TR_DYNAMIC_RANGE - X265_DEPTH -
                               log2TrSize; /* Represents scaling through forward transform */
    const int scaleBits = SCALE_BITS - 2 * transformShift;
    const uint32_t trSize = 1 << log2TrSize;
    //using preprocessor to bypass clang bug
    const int max = X265_MAX(0, (2 * transformShift + 1));

    int64x2_t vcost_sum_0 = vdupq_n_s64(0);
    int64x2_t vcost_sum_1 = vdupq_n_s64(0);
    int32x4_t vpsy = vdupq_n_s32(*psyScale);
    for (int y = 0; y < MLS_CG_SIZE; y++)
    {
        int32x4_t signCoef = vmovl_s16(vld1_s16(&m_resiDctCoeff[blkPos]));
        int32x4_t fencCoef = vmovl_s16(vld1_s16(&m_fencDctCoeff[blkPos]));
        int32x4_t predictedCoef = vsubq_s32(fencCoef, signCoef);
        int64x2_t cost0, cost1;
        cost0 = vmull_s32(vget_low_s32(signCoef), vget_low_s32(signCoef));
        cost1 = vmull_high_s32(signCoef, signCoef);
        cost0 = vshlq_n_s64(cost0, scaleBits);
        cost1 = vshlq_n_s64(cost1, scaleBits);
        int64x2_t neg0 = vmull_s32(vget_low_s32(predictedCoef), vget_low_s32(vpsy));
        int64x2_t neg1 = vmull_high_s32(predictedCoef, vpsy);
        if (max > 0)
        {
            int64x2_t shift = vdupq_n_s64(-max);
            neg0 = vshlq_s64(neg0, shift);
            neg1 = vshlq_s64(neg1, shift);
        }
        cost0 = vsubq_s64(cost0, neg0);
        cost1 = vsubq_s64(cost1, neg1);
        vst1q_s64(&costUncoded[blkPos + 0], cost0);
        vst1q_s64(&costUncoded[blkPos + 2], cost1);
        vcost_sum_0 = vaddq_s64(vcost_sum_0, cost0);
        vcost_sum_1 = vaddq_s64(vcost_sum_1, cost1);

        blkPos += trSize;
    }
    int64_t sum = vaddvq_s64(vaddq_s64(vcost_sum_0, vcost_sum_1));
    *totalUncodedCost += sum;
    *totalRdCost += sum;
}

#else
#error "MLS_CG_SIZE must be 4 for neon version"
#endif



template<int trSize>
int  count_nonzero_neon(const int16_t *quantCoeff)
{
    X265_CHECK(((intptr_t)quantCoeff & 15) == 0, "quant buffer not aligned\n");
    int count = 0;
    int16x8_t vcount = vdupq_n_s16(0);
    const int numCoeff = trSize * trSize;
    int i = 0;
    for (; (i + 8) <= numCoeff; i += 8)
    {
        int16x8_t in = vld1q_s16(&quantCoeff[i]);
        uint16x8_t tst = vtstq_s16(in, in);
        vcount = vaddq_s16(vcount, vreinterpretq_s16_u16(tst));
    }
    for (; i < numCoeff; i++)
    {
        count += quantCoeff[i] != 0;
    }

    return count - vaddvq_s16(vcount);
}

template<int trSize>
uint32_t copy_count_neon(int16_t *coeff, const int16_t *residual, intptr_t resiStride)
{
    uint32_t numSig = 0;
    int16x8_t vcount = vdupq_n_s16(0);
    for (int k = 0; k < trSize; k++)
    {
        int j = 0;
        for (; (j + 8) <= trSize; j += 8)
        {
            int16x8_t in = vld1q_s16(&residual[j]);
            vst1q_s16(&coeff[j], in);
            uint16x8_t tst = vtstq_s16(in, in);
            vcount = vaddq_s16(vcount, vreinterpretq_s16_u16(tst));
        }
        for (; j < trSize; j++)
        {
            coeff[j] = residual[j];
            numSig += (residual[j] != 0);
        }
        residual += resiStride;
        coeff += trSize;
    }

    return numSig - vaddvq_s16(vcount);
}

template<int shift>
static inline void partialButterfly16_neon(const int16_t *src, int16_t *dst)
{
    const int line = 16;

    int16x8_t O[line];
    int32x4_t EO[line];
    int32x4_t EEE[line];
    int32x4_t EEO[line];

    for (int i = 0; i < line; i += 2)
    {
        int16x8_t s0_lo = vld1q_s16(src + i * line);
        int16x8_t s0_hi = rev16(vld1q_s16(src + i * line + 8));

        int16x8_t s1_lo = vld1q_s16(src + (i + 1) * line);
        int16x8_t s1_hi = rev16(vld1q_s16(src + (i + 1) * line + 8));

        int32x4_t E0[2];
        E0[0] = vaddl_s16(vget_low_s16(s0_lo), vget_low_s16(s0_hi));
        E0[1] = vaddl_s16(vget_high_s16(s0_lo), vget_high_s16(s0_hi));

        int32x4_t E1[2];
        E1[0] = vaddl_s16(vget_low_s16(s1_lo), vget_low_s16(s1_hi));
        E1[1] = vaddl_s16(vget_high_s16(s1_lo), vget_high_s16(s1_hi));

        O[i + 0] = vsubq_s16(s0_lo, s0_hi);
        O[i + 1] = vsubq_s16(s1_lo, s1_hi);

        int32x4_t EE0 = vaddq_s32(E0[0], rev32(E0[1]));
        int32x4_t EE1 = vaddq_s32(E1[0], rev32(E1[1]));
        EO[i + 0] = vsubq_s32(E0[0], rev32(E0[1]));
        EO[i + 1] = vsubq_s32(E1[0], rev32(E1[1]));

        int32x4_t t0 = vreinterpretq_s32_s64(
            vzip1q_s64(vreinterpretq_s64_s32(EE0), vreinterpretq_s64_s32(EE1)));
        int32x4_t t1 = vrev64q_s32(vreinterpretq_s32_s64(vzip2q_s64(
            vreinterpretq_s64_s32(EE0), vreinterpretq_s64_s32(EE1))));


        EEE[i / 2] = vaddq_s32(t0, t1);
        EEO[i / 2] = vsubq_s32(t0, t1);
    }

    for (int i = 0; i < line; i += 4)
    {
        for (int k = 1; k < 16; k += 2)
        {
            int16x8_t c0_c4 = vld1q_s16(&g_t16[k][0]);

            int32x4_t t0 = vmull_s16(vget_low_s16(c0_c4),
                                     vget_low_s16(O[i + 0]));
            int32x4_t t1 = vmull_s16(vget_low_s16(c0_c4),
                                     vget_low_s16(O[i + 1]));
            int32x4_t t2 = vmull_s16(vget_low_s16(c0_c4),
                                     vget_low_s16(O[i + 2]));
            int32x4_t t3 = vmull_s16(vget_low_s16(c0_c4),
                                     vget_low_s16(O[i + 3]));
            t0 = vmlal_s16(t0, vget_high_s16(c0_c4), vget_high_s16(O[i + 0]));
            t1 = vmlal_s16(t1, vget_high_s16(c0_c4), vget_high_s16(O[i + 1]));
            t2 = vmlal_s16(t2, vget_high_s16(c0_c4), vget_high_s16(O[i + 2]));
            t3 = vmlal_s16(t3, vget_high_s16(c0_c4), vget_high_s16(O[i + 3]));

            int32x4_t t = vpaddq_s32(vpaddq_s32(t0, t1), vpaddq_s32(t2, t3));
            int16x4_t res = vrshrn_n_s32(t, shift);
            vst1_s16(dst + k * line, res);
        }

        for (int k = 2; k < 16; k += 4)
        {
            int32x4_t c0 = vmovl_s16(vld1_s16(&g_t16[k][0]));
            int32x4_t t0 = vmulq_s32(c0, EO[i + 0]);
            int32x4_t t1 = vmulq_s32(c0, EO[i + 1]);
            int32x4_t t2 = vmulq_s32(c0, EO[i + 2]);
            int32x4_t t3 = vmulq_s32(c0, EO[i + 3]);
            int32x4_t t = vpaddq_s32(vpaddq_s32(t0, t1), vpaddq_s32(t2, t3));

            int16x4_t res = vrshrn_n_s32(t, shift);
            vst1_s16(dst + k * line, res);
        }

        int32x4_t c0 = vld1q_s32(t8_even[0]);
        int32x4_t c4 = vld1q_s32(t8_even[1]);
        int32x4_t c8 = vld1q_s32(t8_even[2]);
        int32x4_t c12 = vld1q_s32(t8_even[3]);

        int32x4_t t0 = vpaddq_s32(EEE[i / 2 + 0], EEE[i / 2 + 1]);
        int32x4_t t1 = vmulq_s32(c0, t0);
        int16x4_t res0 = vrshrn_n_s32(t1, shift);
        vst1_s16(dst + 0 * line, res0);

        int32x4_t t2 = vmulq_s32(c4, EEO[i / 2 + 0]);
        int32x4_t t3 = vmulq_s32(c4, EEO[i / 2 + 1]);
        int16x4_t res4 = vrshrn_n_s32(vpaddq_s32(t2, t3), shift);
        vst1_s16(dst + 4 * line, res4);

        int32x4_t t4 = vmulq_s32(c8, EEE[i / 2 + 0]);
        int32x4_t t5 = vmulq_s32(c8, EEE[i / 2 + 1]);
        int16x4_t res8 = vrshrn_n_s32(vpaddq_s32(t4, t5), shift);
        vst1_s16(dst + 8 * line, res8);

        int32x4_t t6 = vmulq_s32(c12, EEO[i / 2 + 0]);
        int32x4_t t7 = vmulq_s32(c12, EEO[i / 2 + 1]);
        int16x4_t res12 = vrshrn_n_s32(vpaddq_s32(t6, t7), shift);
        vst1_s16(dst + 12 * line, res12);

        dst += 4;
    }
}

template<int shift>
static inline void partialButterfly32_neon(const int16_t *src, int16_t *dst)
{
    const int line = 32;

    int16x8_t O[line][2];
    int32x4_t EO[line][2];
    int32x4_t EEO[line];
    int32x4_t EEEE[line / 2];
    int32x4_t EEEO[line / 2];

    for (int i = 0; i < line; i += 2)
    {
        int16x8x4_t in_lo = vld1q_s16_x4(src + (i + 0) * line);
        in_lo.val[2] = rev16(in_lo.val[2]);
        in_lo.val[3] = rev16(in_lo.val[3]);

        int16x8x4_t in_hi = vld1q_s16_x4(src + (i + 1) * line);
        in_hi.val[2] = rev16(in_hi.val[2]);
        in_hi.val[3] = rev16(in_hi.val[3]);

        int32x4_t E0[4];
        E0[0] = vaddl_s16(vget_low_s16(in_lo.val[0]),
                          vget_low_s16(in_lo.val[3]));
        E0[1] = vaddl_s16(vget_high_s16(in_lo.val[0]),
                          vget_high_s16(in_lo.val[3]));
        E0[2] = vaddl_s16(vget_low_s16(in_lo.val[1]),
                          vget_low_s16(in_lo.val[2]));
        E0[3] = vaddl_s16(vget_high_s16(in_lo.val[1]),
                          vget_high_s16(in_lo.val[2]));

        int32x4_t E1[4];
        E1[0] = vaddl_s16(vget_low_s16(in_hi.val[0]),
                          vget_low_s16(in_hi.val[3]));
        E1[1] = vaddl_s16(vget_high_s16(in_hi.val[0]),
                          vget_high_s16(in_hi.val[3]));
        E1[2] = vaddl_s16(vget_low_s16(in_hi.val[1]),
                          vget_low_s16(in_hi.val[2]));
        E1[3] = vaddl_s16(vget_high_s16(in_hi.val[1]),
                          vget_high_s16(in_hi.val[2]));

        O[i + 0][0] = vsubq_s16(in_lo.val[0], in_lo.val[3]);
        O[i + 0][1] = vsubq_s16(in_lo.val[1], in_lo.val[2]);

        O[i + 1][0] = vsubq_s16(in_hi.val[0], in_hi.val[3]);
        O[i + 1][1] = vsubq_s16(in_hi.val[1], in_hi.val[2]);

        int32x4_t EE0[2];
        E0[3] = rev32(E0[3]);
        E0[2] = rev32(E0[2]);
        EE0[0] = vaddq_s32(E0[0], E0[3]);
        EE0[1] = vaddq_s32(E0[1], E0[2]);
        EO[i + 0][0] = vsubq_s32(E0[0], E0[3]);
        EO[i + 0][1] = vsubq_s32(E0[1], E0[2]);

        int32x4_t EE1[2];
        E1[3] = rev32(E1[3]);
        E1[2] = rev32(E1[2]);
        EE1[0] = vaddq_s32(E1[0], E1[3]);
        EE1[1] = vaddq_s32(E1[1], E1[2]);
        EO[i + 1][0] = vsubq_s32(E1[0], E1[3]);
        EO[i + 1][1] = vsubq_s32(E1[1], E1[2]);

        int32x4_t EEE0;
        EE0[1] = rev32(EE0[1]);
        EEE0 = vaddq_s32(EE0[0], EE0[1]);
        EEO[i + 0] = vsubq_s32(EE0[0], EE0[1]);

        int32x4_t EEE1;
        EE1[1] = rev32(EE1[1]);
        EEE1 = vaddq_s32(EE1[0], EE1[1]);
        EEO[i + 1] = vsubq_s32(EE1[0], EE1[1]);

        int32x4_t t0 = vreinterpretq_s32_s64(
            vzip1q_s64(vreinterpretq_s64_s32(EEE0),
                       vreinterpretq_s64_s32(EEE1)));
        int32x4_t t1 = vrev64q_s32(vreinterpretq_s32_s64(
            vzip2q_s64(vreinterpretq_s64_s32(EEE0),
                       vreinterpretq_s64_s32(EEE1))));

        EEEE[i / 2] = vaddq_s32(t0, t1);
        EEEO[i / 2] = vsubq_s32(t0, t1);
    }

    for (int k = 1; k < 32; k += 2)
    {
        int16_t *d = dst + k * line;

        int16x8_t c0_c1 = vld1q_s16(&g_t32[k][0]);
        int16x8_t c2_c3 = vld1q_s16(&g_t32[k][8]);
        int16x4_t c0 = vget_low_s16(c0_c1);
        int16x4_t c1 = vget_high_s16(c0_c1);
        int16x4_t c2 = vget_low_s16(c2_c3);
        int16x4_t c3 = vget_high_s16(c2_c3);

        for (int i = 0; i < line; i += 4)
        {
            int32x4_t t[4];
            for (int j = 0; j < 4; ++j) {
                t[j] = vmull_s16(c0, vget_low_s16(O[i + j][0]));
                t[j] = vmlal_s16(t[j], c1, vget_high_s16(O[i + j][0]));
                t[j] = vmlal_s16(t[j], c2, vget_low_s16(O[i + j][1]));
                t[j] = vmlal_s16(t[j], c3, vget_high_s16(O[i + j][1]));
            }

            int32x4_t t0123 = vpaddq_s32(vpaddq_s32(t[0], t[1]),
                                         vpaddq_s32(t[2], t[3]));
            int16x4_t res = vrshrn_n_s32(t0123, shift);
            vst1_s16(d, res);

            d += 4;
        }
    }

    for (int k = 2; k < 32; k += 4)
    {
        int16_t *d = dst + k * line;

        int32x4_t c0 = vmovl_s16(vld1_s16(&g_t32[k][0]));
        int32x4_t c1 = vmovl_s16(vld1_s16(&g_t32[k][4]));

        for (int i = 0; i < line; i += 4)
        {
            int32x4_t t[4];
            for (int j = 0; j < 4; ++j) {
                t[j] = vmulq_s32(c0, EO[i + j][0]);
                t[j] = vmlaq_s32(t[j], c1, EO[i + j][1]);
            }

            int32x4_t t0123 = vpaddq_s32(vpaddq_s32(t[0], t[1]),
                                         vpaddq_s32(t[2], t[3]));
            int16x4_t res = vrshrn_n_s32(t0123, shift);
            vst1_s16(d, res);

            d += 4;
        }
    }

    for (int k = 4; k < 32; k += 8)
    {
        int16_t *d = dst + k * line;

        int32x4_t c = vmovl_s16(vld1_s16(&g_t32[k][0]));

        for (int i = 0; i < line; i += 4)
        {
            int32x4_t t0 = vmulq_s32(c, EEO[i + 0]);
            int32x4_t t1 = vmulq_s32(c, EEO[i + 1]);
            int32x4_t t2 = vmulq_s32(c, EEO[i + 2]);
            int32x4_t t3 = vmulq_s32(c, EEO[i + 3]);

            int32x4_t t = vpaddq_s32(vpaddq_s32(t0, t1), vpaddq_s32(t2, t3));
            int16x4_t res = vrshrn_n_s32(t, shift);
            vst1_s16(d, res);

            d += 4;
        }
    }

    int32x4_t c0 = vld1q_s32(t8_even[0]);
    int32x4_t c8 = vld1q_s32(t8_even[1]);
    int32x4_t c16 = vld1q_s32(t8_even[2]);
    int32x4_t c24 = vld1q_s32(t8_even[3]);

    for (int i = 0; i < line; i += 4)
    {
        int32x4_t t0 = vpaddq_s32(EEEE[i / 2 + 0], EEEE[i / 2 + 1]);
        int32x4_t t1 = vmulq_s32(c0, t0);
        int16x4_t res0 = vrshrn_n_s32(t1, shift);
        vst1_s16(dst + 0 * line, res0);

        int32x4_t t2 = vmulq_s32(c8, EEEO[i / 2 + 0]);
        int32x4_t t3 = vmulq_s32(c8, EEEO[i / 2 + 1]);
        int16x4_t res8 = vrshrn_n_s32(vpaddq_s32(t2, t3), shift);
        vst1_s16(dst + 8 * line, res8);

        int32x4_t t4 = vmulq_s32(c16, EEEE[i / 2 + 0]);
        int32x4_t t5 = vmulq_s32(c16, EEEE[i / 2 + 1]);
        int16x4_t res16 = vrshrn_n_s32(vpaddq_s32(t4, t5), shift);
        vst1_s16(dst + 16 * line, res16);

        int32x4_t t6 = vmulq_s32(c24, EEEO[i / 2 + 0]);
        int32x4_t t7 = vmulq_s32(c24, EEEO[i / 2 + 1]);
        int16x4_t res24 = vrshrn_n_s32(vpaddq_s32(t6, t7), shift);
        vst1_s16(dst + 24 * line, res24);

        dst += 4;
    }
}

template<int shift>
static inline void partialButterfly8_neon(const int16_t *src, int16_t *dst)
{
    const int line = 8;

    int16x4_t O[line];
    int32x4_t EE[line / 2];
    int32x4_t EO[line / 2];

    for (int i = 0; i < line; i += 2)
    {
        int16x4_t s0_lo = vld1_s16(src + i * line);
        int16x4_t s0_hi = vrev64_s16(vld1_s16(src + i * line + 4));

        int16x4_t s1_lo = vld1_s16(src + (i + 1) * line);
        int16x4_t s1_hi = vrev64_s16(vld1_s16(src + (i + 1) * line + 4));

        int32x4_t E0 = vaddl_s16(s0_lo, s0_hi);
        int32x4_t E1 = vaddl_s16(s1_lo, s1_hi);

        O[i + 0] = vsub_s16(s0_lo, s0_hi);
        O[i + 1] = vsub_s16(s1_lo, s1_hi);

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
    int16x4_t c1 = vld1_s16(g_t8[1]);
    int16x4_t c3 = vld1_s16(g_t8[3]);
    int16x4_t c5 = vld1_s16(g_t8[5]);
    int16x4_t c7 = vld1_s16(g_t8[7]);

    for (int j = 0; j < line; j += 4)
    {
        // O
        int32x4_t t01 = vpaddq_s32(vmull_s16(c1, O[j + 0]),
                                   vmull_s16(c1, O[j + 1]));
        int32x4_t t23 = vpaddq_s32(vmull_s16(c1, O[j + 2]),
                                   vmull_s16(c1, O[j + 3]));
        int16x4_t res1 = vrshrn_n_s32(vpaddq_s32(t01, t23), shift);
        vst1_s16(d + 1 * line, res1);

        t01 = vpaddq_s32(vmull_s16(c3, O[j + 0]), vmull_s16(c3, O[j + 1]));
        t23 = vpaddq_s32(vmull_s16(c3, O[j + 2]), vmull_s16(c3, O[j + 3]));
        int16x4_t res3 = vrshrn_n_s32(vpaddq_s32(t01, t23), shift);
        vst1_s16(d + 3 * line, res3);

        t01 = vpaddq_s32(vmull_s16(c5, O[j + 0]), vmull_s16(c5, O[j + 1]));
        t23 = vpaddq_s32(vmull_s16(c5, O[j + 2]), vmull_s16(c5, O[j + 3]));
        int16x4_t res5 = vrshrn_n_s32(vpaddq_s32(t01, t23), shift);
        vst1_s16(d + 5 * line, res5);

        t01 = vpaddq_s32(vmull_s16(c7, O[j + 0]), vmull_s16(c7, O[j + 1]));
        t23 = vpaddq_s32(vmull_s16(c7, O[j + 2]), vmull_s16(c7, O[j + 3]));
        int16x4_t res7 = vrshrn_n_s32(vpaddq_s32(t01, t23), shift);
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

static void partialButterflyInverse4(const int16_t *src, int16_t *dst, int shift, int line)
{
    int j;
    int E[2], O[2];
    int add = 1 << (shift - 1);

    for (j = 0; j < line; j++)
    {
        /* Utilizing symmetry properties to the maximum to minimize the number of multiplications */
        O[0] = g_t4[1][0] * src[line] + g_t4[3][0] * src[3 * line];
        O[1] = g_t4[1][1] * src[line] + g_t4[3][1] * src[3 * line];
        E[0] = g_t4[0][0] * src[0] + g_t4[2][0] * src[2 * line];
        E[1] = g_t4[0][1] * src[0] + g_t4[2][1] * src[2 * line];

        /* Combining even and odd terms at each hierarchy levels to calculate the final spatial domain vector */
        dst[0] = (int16_t)(x265_clip3(-32768, 32767, (E[0] + O[0] + add) >> shift));
        dst[1] = (int16_t)(x265_clip3(-32768, 32767, (E[1] + O[1] + add) >> shift));
        dst[2] = (int16_t)(x265_clip3(-32768, 32767, (E[1] - O[1] + add) >> shift));
        dst[3] = (int16_t)(x265_clip3(-32768, 32767, (E[0] - O[0] + add) >> shift));

        src++;
        dst += 4;
    }
}



static void partialButterflyInverse16_neon(const int16_t *src, int16_t *orig_dst, int shift, int line)
{
#define FMAK(x,l) s[l] = vmlal_lane_s16(s[l],vld1_s16(&src[x*line]),vld1_s16(&g_t16[x][k]),l);
#define MULK(x,l) vmull_lane_s16(vld1_s16(&src[x*line]),vld1_s16(&g_t16[x][k]),l);
#define ODD3_15(k) FMAK(3,k);FMAK(5,k);FMAK(7,k);FMAK(9,k);FMAK(11,k);FMAK(13,k);FMAK(15,k);
#define EVEN6_14_STEP4(k) FMAK(6,k);FMAK(10,k);FMAK(14,k);


    int j, k;
    int32x4_t E[8], O[8];
    int32x4_t EE[4], EO[4];
    int32x4_t EEE[2], EEO[2];
    const int add = 1 << (shift - 1);


X265_PRAGMA_UNROLL(4)
    for (j = 0; j < line; j += 4)
    {
        /* Utilizing symmetry properties to the maximum to minimize the number of multiplications */

X265_PRAGMA_UNROLL(2)
        for (k = 0; k < 2; k++)
        {
            int32x4_t s;
            s = vmull_s16(vdup_n_s16(g_t16[4][k]), vld1_s16(&src[4 * line]));
            EEO[k] = vmlal_s16(s, vdup_n_s16(g_t16[12][k]),
                               vld1_s16(&src[12 * line]));
            s = vmull_s16(vdup_n_s16(g_t16[0][k]), vld1_s16(&src[0 * line]));
            EEE[k] = vmlal_s16(s, vdup_n_s16(g_t16[8][k]),
                               vld1_s16(&src[8 * line]));
        }

        /* Combining even and odd terms at each hierarchy levels to calculate the final spatial domain vector */
        EE[0] = vaddq_s32(EEE[0] , EEO[0]);
        EE[2] = vsubq_s32(EEE[1] , EEO[1]);
        EE[1] = vaddq_s32(EEE[1] , EEO[1]);
        EE[3] = vsubq_s32(EEE[0] , EEO[0]);


X265_PRAGMA_UNROLL(1)
        for (k = 0; k < 4; k += 4)
        {
            int32x4_t s[4];
            s[0] = MULK(2, 0);
            s[1] = MULK(2, 1);
            s[2] = MULK(2, 2);
            s[3] = MULK(2, 3);

            EVEN6_14_STEP4(0);
            EVEN6_14_STEP4(1);
            EVEN6_14_STEP4(2);
            EVEN6_14_STEP4(3);

            EO[k] = s[0];
            EO[k + 1] = s[1];
            EO[k + 2] = s[2];
            EO[k + 3] = s[3];
        }



        static const int32x4_t min = vdupq_n_s32(-32768);
        static const int32x4_t max = vdupq_n_s32(32767);
        const int32x4_t minus_shift = vdupq_n_s32(-shift);

X265_PRAGMA_UNROLL(4)
        for (k = 0; k < 4; k++)
        {
            E[k] = vaddq_s32(EE[k] , EO[k]);
            E[k + 4] = vsubq_s32(EE[3 - k] , EO[3 - k]);
        }

X265_PRAGMA_UNROLL(2)
        for (k = 0; k < 8; k += 4)
        {
            int32x4_t s[4];
            s[0] = MULK(1, 0);
            s[1] = MULK(1, 1);
            s[2] = MULK(1, 2);
            s[3] = MULK(1, 3);
            ODD3_15(0);
            ODD3_15(1);
            ODD3_15(2);
            ODD3_15(3);
            O[k] = s[0];
            O[k + 1] = s[1];
            O[k + 2] = s[2];
            O[k + 3] = s[3];
            int32x4_t t;
            int16x4_t x0, x1, x2, x3;

            E[k] = vaddq_s32(vdupq_n_s32(add), E[k]);
            t = vaddq_s32(E[k], O[k]);
            t = vshlq_s32(t, minus_shift);
            t = vmaxq_s32(t, min);
            t = vminq_s32(t, max);
            x0 = vmovn_s32(t);

            E[k + 1] = vaddq_s32(vdupq_n_s32(add), E[k + 1]);
            t = vaddq_s32(E[k + 1], O[k + 1]);
            t = vshlq_s32(t, minus_shift);
            t = vmaxq_s32(t, min);
            t = vminq_s32(t, max);
            x1 = vmovn_s32(t);

            E[k + 2] = vaddq_s32(vdupq_n_s32(add), E[k + 2]);
            t = vaddq_s32(E[k + 2], O[k + 2]);
            t = vshlq_s32(t, minus_shift);
            t = vmaxq_s32(t, min);
            t = vminq_s32(t, max);
            x2 = vmovn_s32(t);

            E[k + 3] = vaddq_s32(vdupq_n_s32(add), E[k + 3]);
            t = vaddq_s32(E[k + 3], O[k + 3]);
            t = vshlq_s32(t, minus_shift);
            t = vmaxq_s32(t, min);
            t = vminq_s32(t, max);
            x3 = vmovn_s32(t);

            transpose_4x4x16(x0, x1, x2, x3);
            vst1_s16(&orig_dst[0 * 16 + k], x0);
            vst1_s16(&orig_dst[1 * 16 + k], x1);
            vst1_s16(&orig_dst[2 * 16 + k], x2);
            vst1_s16(&orig_dst[3 * 16 + k], x3);
        }


X265_PRAGMA_UNROLL(2)
        for (k = 0; k < 8; k += 4)
        {
            int32x4_t t;
            int16x4_t x0, x1, x2, x3;

            t = vsubq_s32(E[7 - k], O[7 - k]);
            t = vshlq_s32(t, minus_shift);
            t = vmaxq_s32(t, min);
            t = vminq_s32(t, max);
            x0 = vmovn_s32(t);

            t = vsubq_s32(E[6 - k], O[6 - k]);
            t = vshlq_s32(t, minus_shift);
            t = vmaxq_s32(t, min);
            t = vminq_s32(t, max);
            x1 = vmovn_s32(t);

            t = vsubq_s32(E[5 - k], O[5 - k]);

            t = vshlq_s32(t, minus_shift);
            t = vmaxq_s32(t, min);
            t = vminq_s32(t, max);
            x2 = vmovn_s32(t);

            t = vsubq_s32(E[4 - k], O[4 - k]);
            t = vshlq_s32(t, minus_shift);
            t = vmaxq_s32(t, min);
            t = vminq_s32(t, max);
            x3 = vmovn_s32(t);

            transpose_4x4x16(x0, x1, x2, x3);
            vst1_s16(&orig_dst[0 * 16 + k + 8], x0);
            vst1_s16(&orig_dst[1 * 16 + k + 8], x1);
            vst1_s16(&orig_dst[2 * 16 + k + 8], x2);
            vst1_s16(&orig_dst[3 * 16 + k + 8], x3);
        }
        orig_dst += 4 * 16;
        src += 4;
    }

#undef MUL
#undef FMA
#undef FMAK
#undef MULK
#undef ODD3_15
#undef EVEN6_14_STEP4


}



static void partialButterflyInverse32_neon(const int16_t *src, int16_t *orig_dst, int shift, int line)
{
#define MUL(x) vmull_s16(vdup_n_s16(g_t32[x][k]),vld1_s16(&src[x*line]));
#define FMA(x) s = vmlal_s16(s,vdup_n_s16(g_t32[x][k]),vld1_s16(&src[x*line]));
#define FMAK(x,l) s[l] = vmlal_lane_s16(s[l],vld1_s16(&src[x*line]),vld1_s16(&g_t32[x][k]),l);
#define MULK(x,l) vmull_lane_s16(vld1_s16(&src[x*line]),vld1_s16(&g_t32[x][k]),l);
#define ODD31(k) FMAK(3,k);FMAK(5,k);FMAK(7,k);FMAK(9,k);FMAK(11,k);FMAK(13,k);FMAK(15,k);FMAK(17,k);FMAK(19,k);FMAK(21,k);FMAK(23,k);FMAK(25,k);FMAK(27,k);FMAK(29,k);FMAK(31,k);

#define ODD15(k) FMAK(6,k);FMAK(10,k);FMAK(14,k);FMAK(18,k);FMAK(22,k);FMAK(26,k);FMAK(30,k);
#define ODD7(k) FMAK(12,k);FMAK(20,k);FMAK(28,k);


    int j, k;
    int32x4_t E[16], O[16];
    int32x4_t EE[8], EO[8];
    int32x4_t EEE[4], EEO[4];
    int32x4_t EEEE[2], EEEO[2];
    int16x4_t dst[32];
    int add = 1 << (shift - 1);

X265_PRAGMA_UNROLL(8)
    for (j = 0; j < line; j += 4)
    {
X265_PRAGMA_UNROLL(4)
        for (k = 0; k < 16; k += 4)
        {
            int32x4_t s[4];
            s[0] = MULK(1, 0);
            s[1] = MULK(1, 1);
            s[2] = MULK(1, 2);
            s[3] = MULK(1, 3);
            ODD31(0);
            ODD31(1);
            ODD31(2);
            ODD31(3);
            O[k] = s[0];
            O[k + 1] = s[1];
            O[k + 2] = s[2];
            O[k + 3] = s[3];


        }


X265_PRAGMA_UNROLL(2)
        for (k = 0; k < 8; k += 4)
        {
            int32x4_t s[4];
            s[0] = MULK(2, 0);
            s[1] = MULK(2, 1);
            s[2] = MULK(2, 2);
            s[3] = MULK(2, 3);

            ODD15(0);
            ODD15(1);
            ODD15(2);
            ODD15(3);

            EO[k] = s[0];
            EO[k + 1] = s[1];
            EO[k + 2] = s[2];
            EO[k + 3] = s[3];
        }


        for (k = 0; k < 4; k += 4)
        {
            int32x4_t s[4];
            s[0] = MULK(4, 0);
            s[1] = MULK(4, 1);
            s[2] = MULK(4, 2);
            s[3] = MULK(4, 3);

            ODD7(0);
            ODD7(1);
            ODD7(2);
            ODD7(3);

            EEO[k] = s[0];
            EEO[k + 1] = s[1];
            EEO[k + 2] = s[2];
            EEO[k + 3] = s[3];
        }

X265_PRAGMA_UNROLL(2)
        for (k = 0; k < 2; k++)
        {
            int32x4_t s;
            s = MUL(8);
            EEEO[k] = FMA(24);
            s = MUL(0);
            EEEE[k] = FMA(16);
        }
        /* Combining even and odd terms at each hierarchy levels to calculate the final spatial domain vector */
        EEE[0] = vaddq_s32(EEEE[0], EEEO[0]);
        EEE[3] = vsubq_s32(EEEE[0], EEEO[0]);
        EEE[1] = vaddq_s32(EEEE[1], EEEO[1]);
        EEE[2] = vsubq_s32(EEEE[1], EEEO[1]);

X265_PRAGMA_UNROLL(4)
        for (k = 0; k < 4; k++)
        {
            EE[k] = vaddq_s32(EEE[k], EEO[k]);
            EE[k + 4] = vsubq_s32((EEE[3 - k]), (EEO[3 - k]));
        }

X265_PRAGMA_UNROLL(8)
        for (k = 0; k < 8; k++)
        {
            E[k] = vaddq_s32(EE[k], EO[k]);
            E[k + 8] = vsubq_s32((EE[7 - k]), (EO[7 - k]));
        }

        static const int32x4_t min = vdupq_n_s32(-32768);
        static const int32x4_t max = vdupq_n_s32(32767);



X265_PRAGMA_UNROLL(16)
        for (k = 0; k < 16; k++)
        {
            int32x4_t adde = vaddq_s32(vdupq_n_s32(add), E[k]);
            int32x4_t s = vaddq_s32(adde, O[k]);
            s = vshlq_s32(s, vdupq_n_s32(-shift));
            s = vmaxq_s32(s, min);
            s = vminq_s32(s, max);



            dst[k] = vmovn_s32(s);
            adde = vaddq_s32(vdupq_n_s32(add), (E[15 - k]));
            s  = vsubq_s32(adde, (O[15 - k]));
            s = vshlq_s32(s, vdupq_n_s32(-shift));
            s = vmaxq_s32(s, min);
            s = vminq_s32(s, max);

            dst[k + 16] = vmovn_s32(s);
        }


X265_PRAGMA_UNROLL(8)
        for (k = 0; k < 32; k += 4)
        {
            int16x4_t x0 = dst[k + 0];
            int16x4_t x1 = dst[k + 1];
            int16x4_t x2 = dst[k + 2];
            int16x4_t x3 = dst[k + 3];
            transpose_4x4x16(x0, x1, x2, x3);
            vst1_s16(&orig_dst[0 * 32 + k], x0);
            vst1_s16(&orig_dst[1 * 32 + k], x1);
            vst1_s16(&orig_dst[2 * 32 + k], x2);
            vst1_s16(&orig_dst[3 * 32 + k], x3);
        }
        orig_dst += 4 * 32;
        src += 4;
    }
#undef MUL
#undef FMA
#undef FMAK
#undef MULK
#undef ODD31
#undef ODD15
#undef ODD7

}


}

namespace X265_NS
{
// x265 private namespace
void dct8_neon(const int16_t *src, int16_t *dst, intptr_t srcStride)
{
    const int shift_pass1 = 2 + X265_DEPTH - 8;
    const int shift_pass2 = 9;

    ALIGN_VAR_32(int16_t, coef[8 * 8]);
    ALIGN_VAR_32(int16_t, block[8 * 8]);

    for (int i = 0; i < 8; i++)
    {
        memcpy(&block[i * 8], &src[i * srcStride], 8 * sizeof(int16_t));
    }

    partialButterfly8_neon<shift_pass1>(block, coef);
    partialButterfly8_neon<shift_pass2>(coef, dst);
}

void dct16_neon(const int16_t *src, int16_t *dst, intptr_t srcStride)
{
    const int shift_pass1 = 3 + X265_DEPTH - 8;
    const int shift_pass2 = 10;

    ALIGN_VAR_32(int16_t, coef[16 * 16]);
    ALIGN_VAR_32(int16_t, block[16 * 16]);

    for (int i = 0; i < 16; i++)
    {
        memcpy(&block[i * 16], &src[i * srcStride], 16 * sizeof(int16_t));
    }

    partialButterfly16_neon<shift_pass1>(block, coef);
    partialButterfly16_neon<shift_pass2>(coef, dst);
}

void dct32_neon(const int16_t *src, int16_t *dst, intptr_t srcStride)
{
    const int shift_pass1 = 4 + X265_DEPTH - 8;
    const int shift_pass2 = 11;

    ALIGN_VAR_32(int16_t, coef[32 * 32]);
    ALIGN_VAR_32(int16_t, block[32 * 32]);

    for (int i = 0; i < 32; i++)
    {
        memcpy(&block[i * 32], &src[i * srcStride], 32 * sizeof(int16_t));
    }

    partialButterfly32_neon<shift_pass1>(block, coef);
    partialButterfly32_neon<shift_pass2>(coef, dst);
}

void idct4_neon(const int16_t *src, int16_t *dst, intptr_t dstStride)
{
    const int shift_1st = 7;
    const int shift_2nd = 12 - (X265_DEPTH - 8);

    ALIGN_VAR_32(int16_t, coef[4 * 4]);
    ALIGN_VAR_32(int16_t, block[4 * 4]);

    partialButterflyInverse4(src, coef, shift_1st, 4); // Forward DST BY FAST ALGORITHM, block input, coef output
    partialButterflyInverse4(coef, block, shift_2nd, 4); // Forward DST BY FAST ALGORITHM, coef input, coeff output

    for (int i = 0; i < 4; i++)
    {
        memcpy(&dst[i * dstStride], &block[i * 4], 4 * sizeof(int16_t));
    }
}

void idct16_neon(const int16_t *src, int16_t *dst, intptr_t dstStride)
{
    const int shift_1st = 7;
    const int shift_2nd = 12 - (X265_DEPTH - 8);

    ALIGN_VAR_32(int16_t, coef[16 * 16]);
    ALIGN_VAR_32(int16_t, block[16 * 16]);

    partialButterflyInverse16_neon(src, coef, shift_1st, 16);
    partialButterflyInverse16_neon(coef, block, shift_2nd, 16);

    for (int i = 0; i < 16; i++)
    {
        memcpy(&dst[i * dstStride], &block[i * 16], 16 * sizeof(int16_t));
    }
}

void idct32_neon(const int16_t *src, int16_t *dst, intptr_t dstStride)
{
    const int shift_1st = 7;
    const int shift_2nd = 12 - (X265_DEPTH - 8);

    ALIGN_VAR_32(int16_t, coef[32 * 32]);
    ALIGN_VAR_32(int16_t, block[32 * 32]);

    partialButterflyInverse32_neon(src, coef, shift_1st, 32);
    partialButterflyInverse32_neon(coef, block, shift_2nd, 32);

    for (int i = 0; i < 32; i++)
    {
        memcpy(&dst[i * dstStride], &block[i * 32], 32 * sizeof(int16_t));
    }
}

void setupDCTPrimitives_neon(EncoderPrimitives &p)
{
    p.cu[BLOCK_4x4].nonPsyRdoQuant   = nonPsyRdoQuant_neon<2>;
    p.cu[BLOCK_8x8].nonPsyRdoQuant   = nonPsyRdoQuant_neon<3>;
    p.cu[BLOCK_16x16].nonPsyRdoQuant = nonPsyRdoQuant_neon<4>;
    p.cu[BLOCK_32x32].nonPsyRdoQuant = nonPsyRdoQuant_neon<5>;
    p.cu[BLOCK_4x4].psyRdoQuant = psyRdoQuant_neon<2>;
    p.cu[BLOCK_8x8].psyRdoQuant = psyRdoQuant_neon<3>;
    p.cu[BLOCK_16x16].psyRdoQuant = psyRdoQuant_neon<4>;
    p.cu[BLOCK_32x32].psyRdoQuant = psyRdoQuant_neon<5>;
    p.cu[BLOCK_8x8].dct   = dct8_neon;
    p.cu[BLOCK_16x16].dct = dct16_neon;
    p.cu[BLOCK_32x32].dct = dct32_neon;
    p.cu[BLOCK_4x4].idct   = idct4_neon;
    p.cu[BLOCK_16x16].idct = idct16_neon;
    p.cu[BLOCK_32x32].idct = idct32_neon;
    p.cu[BLOCK_4x4].count_nonzero = count_nonzero_neon<4>;
    p.cu[BLOCK_8x8].count_nonzero = count_nonzero_neon<8>;
    p.cu[BLOCK_16x16].count_nonzero = count_nonzero_neon<16>;
    p.cu[BLOCK_32x32].count_nonzero = count_nonzero_neon<32>;

    p.cu[BLOCK_4x4].copy_cnt   = copy_count_neon<4>;
    p.cu[BLOCK_8x8].copy_cnt   = copy_count_neon<8>;
    p.cu[BLOCK_16x16].copy_cnt = copy_count_neon<16>;
    p.cu[BLOCK_32x32].copy_cnt = copy_count_neon<32>;
    p.cu[BLOCK_4x4].psyRdoQuant_1p = nonPsyRdoQuant_neon<2>;
    p.cu[BLOCK_4x4].psyRdoQuant_2p = psyRdoQuant_neon<2>;
    p.cu[BLOCK_8x8].psyRdoQuant_1p = nonPsyRdoQuant_neon<3>;
    p.cu[BLOCK_8x8].psyRdoQuant_2p = psyRdoQuant_neon<3>;
    p.cu[BLOCK_16x16].psyRdoQuant_1p = nonPsyRdoQuant_neon<4>;
    p.cu[BLOCK_16x16].psyRdoQuant_2p = psyRdoQuant_neon<4>;
    p.cu[BLOCK_32x32].psyRdoQuant_1p = nonPsyRdoQuant_neon<5>;
    p.cu[BLOCK_32x32].psyRdoQuant_2p = psyRdoQuant_neon<5>;

    p.scanPosLast  = scanPosLast_opt;

}

};



#endif
