#include "common.h"
#include "x265.h"
#include "arm64-utils.h"
#include <arm_neon.h>

namespace X265_NS
{



void transpose8x8(uint8_t *dst, const uint8_t *src, intptr_t dstride, intptr_t sstride)
{
    uint8x8_t a0 = vld1_u8(src + 0 * sstride);
    uint8x8_t a1 = vld1_u8(src + 1 * sstride);
    uint8x8_t a2 = vld1_u8(src + 2 * sstride);
    uint8x8_t a3 = vld1_u8(src + 3 * sstride);
    uint8x8_t a4 = vld1_u8(src + 4 * sstride);
    uint8x8_t a5 = vld1_u8(src + 5 * sstride);
    uint8x8_t a6 = vld1_u8(src + 6 * sstride);
    uint8x8_t a7 = vld1_u8(src + 7 * sstride);

    uint32x2_t b0 = vtrn1_u32(vreinterpret_u32_u8(a0), vreinterpret_u32_u8(a4));
    uint32x2_t b1 = vtrn1_u32(vreinterpret_u32_u8(a1), vreinterpret_u32_u8(a5));
    uint32x2_t b2 = vtrn1_u32(vreinterpret_u32_u8(a2), vreinterpret_u32_u8(a6));
    uint32x2_t b3 = vtrn1_u32(vreinterpret_u32_u8(a3), vreinterpret_u32_u8(a7));
    uint32x2_t b4 = vtrn2_u32(vreinterpret_u32_u8(a0), vreinterpret_u32_u8(a4));
    uint32x2_t b5 = vtrn2_u32(vreinterpret_u32_u8(a1), vreinterpret_u32_u8(a5));
    uint32x2_t b6 = vtrn2_u32(vreinterpret_u32_u8(a2), vreinterpret_u32_u8(a6));
    uint32x2_t b7 = vtrn2_u32(vreinterpret_u32_u8(a3), vreinterpret_u32_u8(a7));

    uint16x4_t c0 = vtrn1_u16(vreinterpret_u16_u32(b0),
                              vreinterpret_u16_u32(b2));
    uint16x4_t c1 = vtrn1_u16(vreinterpret_u16_u32(b1),
                              vreinterpret_u16_u32(b3));
    uint16x4_t c2 = vtrn2_u16(vreinterpret_u16_u32(b0),
                              vreinterpret_u16_u32(b2));
    uint16x4_t c3 = vtrn2_u16(vreinterpret_u16_u32(b1),
                              vreinterpret_u16_u32(b3));
    uint16x4_t c4 = vtrn1_u16(vreinterpret_u16_u32(b4),
                              vreinterpret_u16_u32(b6));
    uint16x4_t c5 = vtrn1_u16(vreinterpret_u16_u32(b5),
                              vreinterpret_u16_u32(b7));
    uint16x4_t c6 = vtrn2_u16(vreinterpret_u16_u32(b4),
                              vreinterpret_u16_u32(b6));
    uint16x4_t c7 = vtrn2_u16(vreinterpret_u16_u32(b5),
                              vreinterpret_u16_u32(b7));

    uint8x8_t d0 = vtrn1_u8(vreinterpret_u8_u16(c0), vreinterpret_u8_u16(c1));
    uint8x8_t d1 = vtrn2_u8(vreinterpret_u8_u16(c0), vreinterpret_u8_u16(c1));
    uint8x8_t d2 = vtrn1_u8(vreinterpret_u8_u16(c2), vreinterpret_u8_u16(c3));
    uint8x8_t d3 = vtrn2_u8(vreinterpret_u8_u16(c2), vreinterpret_u8_u16(c3));
    uint8x8_t d4 = vtrn1_u8(vreinterpret_u8_u16(c4), vreinterpret_u8_u16(c5));
    uint8x8_t d5 = vtrn2_u8(vreinterpret_u8_u16(c4), vreinterpret_u8_u16(c5));
    uint8x8_t d6 = vtrn1_u8(vreinterpret_u8_u16(c6), vreinterpret_u8_u16(c7));
    uint8x8_t d7 = vtrn2_u8(vreinterpret_u8_u16(c6), vreinterpret_u8_u16(c7));

    vst1_u8(dst + 0 * dstride, d0);
    vst1_u8(dst + 1 * dstride, d1);
    vst1_u8(dst + 2 * dstride, d2);
    vst1_u8(dst + 3 * dstride, d3);
    vst1_u8(dst + 4 * dstride, d4);
    vst1_u8(dst + 5 * dstride, d5);
    vst1_u8(dst + 6 * dstride, d6);
    vst1_u8(dst + 7 * dstride, d7);
}






void transpose16x16(uint8_t *dst, const uint8_t *src, intptr_t dstride, intptr_t sstride)
{
    uint8x16_t a0 = vld1q_u8(src + 0 * sstride);
    uint8x16_t a1 = vld1q_u8(src + 1 * sstride);
    uint8x16_t a2 = vld1q_u8(src + 2 * sstride);
    uint8x16_t a3 = vld1q_u8(src + 3 * sstride);
    uint8x16_t a4 = vld1q_u8(src + 4 * sstride);
    uint8x16_t a5 = vld1q_u8(src + 5 * sstride);
    uint8x16_t a6 = vld1q_u8(src + 6 * sstride);
    uint8x16_t a7 = vld1q_u8(src + 7 * sstride);
    uint8x16_t a8 = vld1q_u8(src + 8 * sstride);
    uint8x16_t a9 = vld1q_u8(src + 9 * sstride);
    uint8x16_t aA = vld1q_u8(src + 10 * sstride);
    uint8x16_t aB = vld1q_u8(src + 11 * sstride);
    uint8x16_t aC = vld1q_u8(src + 12 * sstride);
    uint8x16_t aD = vld1q_u8(src + 13 * sstride);
    uint8x16_t aE = vld1q_u8(src + 14 * sstride);
    uint8x16_t aF = vld1q_u8(src + 15 * sstride);

    uint64x2_t b0 = vtrn1q_u64(vreinterpretq_u64_u8(a0),
                               vreinterpretq_u64_u8(a8));
    uint64x2_t b1 = vtrn1q_u64(vreinterpretq_u64_u8(a1),
                               vreinterpretq_u64_u8(a9));
    uint64x2_t b2 = vtrn1q_u64(vreinterpretq_u64_u8(a2),
                               vreinterpretq_u64_u8(aA));
    uint64x2_t b3 = vtrn1q_u64(vreinterpretq_u64_u8(a3),
                               vreinterpretq_u64_u8(aB));
    uint64x2_t b4 = vtrn1q_u64(vreinterpretq_u64_u8(a4),
                               vreinterpretq_u64_u8(aC));
    uint64x2_t b5 = vtrn1q_u64(vreinterpretq_u64_u8(a5),
                               vreinterpretq_u64_u8(aD));
    uint64x2_t b6 = vtrn1q_u64(vreinterpretq_u64_u8(a6),
                               vreinterpretq_u64_u8(aE));
    uint64x2_t b7 = vtrn1q_u64(vreinterpretq_u64_u8(a7),
                               vreinterpretq_u64_u8(aF));
    uint64x2_t b8 = vtrn2q_u64(vreinterpretq_u64_u8(a0),
                               vreinterpretq_u64_u8(a8));
    uint64x2_t b9 = vtrn2q_u64(vreinterpretq_u64_u8(a1),
                               vreinterpretq_u64_u8(a9));
    uint64x2_t bA = vtrn2q_u64(vreinterpretq_u64_u8(a2),
                               vreinterpretq_u64_u8(aA));
    uint64x2_t bB = vtrn2q_u64(vreinterpretq_u64_u8(a3),
                               vreinterpretq_u64_u8(aB));
    uint64x2_t bC = vtrn2q_u64(vreinterpretq_u64_u8(a4),
                               vreinterpretq_u64_u8(aC));
    uint64x2_t bD = vtrn2q_u64(vreinterpretq_u64_u8(a5),
                               vreinterpretq_u64_u8(aD));
    uint64x2_t bE = vtrn2q_u64(vreinterpretq_u64_u8(a6),
                               vreinterpretq_u64_u8(aE));
    uint64x2_t bF = vtrn2q_u64(vreinterpretq_u64_u8(a7),
                               vreinterpretq_u64_u8(aF));

    uint32x4_t c0 = vtrn1q_u32(vreinterpretq_u32_u64(b0),
                               vreinterpretq_u32_u64(b4));
    uint32x4_t c1 = vtrn1q_u32(vreinterpretq_u32_u64(b1),
                               vreinterpretq_u32_u64(b5));
    uint32x4_t c2 = vtrn1q_u32(vreinterpretq_u32_u64(b2),
                               vreinterpretq_u32_u64(b6));
    uint32x4_t c3 = vtrn1q_u32(vreinterpretq_u32_u64(b3),
                               vreinterpretq_u32_u64(b7));
    uint32x4_t c4 = vtrn2q_u32(vreinterpretq_u32_u64(b0),
                               vreinterpretq_u32_u64(b4));
    uint32x4_t c5 = vtrn2q_u32(vreinterpretq_u32_u64(b1),
                               vreinterpretq_u32_u64(b5));
    uint32x4_t c6 = vtrn2q_u32(vreinterpretq_u32_u64(b2),
                               vreinterpretq_u32_u64(b6));
    uint32x4_t c7 = vtrn2q_u32(vreinterpretq_u32_u64(b3),
                               vreinterpretq_u32_u64(b7));
    uint32x4_t c8 = vtrn1q_u32(vreinterpretq_u32_u64(b8),
                               vreinterpretq_u32_u64(bC));
    uint32x4_t c9 = vtrn1q_u32(vreinterpretq_u32_u64(b9),
                               vreinterpretq_u32_u64(bD));
    uint32x4_t cA = vtrn1q_u32(vreinterpretq_u32_u64(bA),
                               vreinterpretq_u32_u64(bE));
    uint32x4_t cB = vtrn1q_u32(vreinterpretq_u32_u64(bB),
                               vreinterpretq_u32_u64(bF));
    uint32x4_t cC = vtrn2q_u32(vreinterpretq_u32_u64(b8),
                               vreinterpretq_u32_u64(bC));
    uint32x4_t cD = vtrn2q_u32(vreinterpretq_u32_u64(b9),
                               vreinterpretq_u32_u64(bD));
    uint32x4_t cE = vtrn2q_u32(vreinterpretq_u32_u64(bA),
                               vreinterpretq_u32_u64(bE));
    uint32x4_t cF = vtrn2q_u32(vreinterpretq_u32_u64(bB),
                               vreinterpretq_u32_u64(bF));

    uint16x8_t d0 = vtrn1q_u16(vreinterpretq_u16_u32(c0),
                               vreinterpretq_u16_u32(c2));
    uint16x8_t d1 = vtrn1q_u16(vreinterpretq_u16_u32(c1),
                               vreinterpretq_u16_u32(c3));
    uint16x8_t d2 = vtrn2q_u16(vreinterpretq_u16_u32(c0),
                               vreinterpretq_u16_u32(c2));
    uint16x8_t d3 = vtrn2q_u16(vreinterpretq_u16_u32(c1),
                               vreinterpretq_u16_u32(c3));
    uint16x8_t d4 = vtrn1q_u16(vreinterpretq_u16_u32(c4),
                               vreinterpretq_u16_u32(c6));
    uint16x8_t d5 = vtrn1q_u16(vreinterpretq_u16_u32(c5),
                               vreinterpretq_u16_u32(c7));
    uint16x8_t d6 = vtrn2q_u16(vreinterpretq_u16_u32(c4),
                               vreinterpretq_u16_u32(c6));
    uint16x8_t d7 = vtrn2q_u16(vreinterpretq_u16_u32(c5),
                               vreinterpretq_u16_u32(c7));
    uint16x8_t d8 = vtrn1q_u16(vreinterpretq_u16_u32(c8),
                               vreinterpretq_u16_u32(cA));
    uint16x8_t d9 = vtrn1q_u16(vreinterpretq_u16_u32(c9),
                               vreinterpretq_u16_u32(cB));
    uint16x8_t dA = vtrn2q_u16(vreinterpretq_u16_u32(c8),
                               vreinterpretq_u16_u32(cA));
    uint16x8_t dB = vtrn2q_u16(vreinterpretq_u16_u32(c9),
                               vreinterpretq_u16_u32(cB));
    uint16x8_t dC = vtrn1q_u16(vreinterpretq_u16_u32(cC),
                               vreinterpretq_u16_u32(cE));
    uint16x8_t dD = vtrn1q_u16(vreinterpretq_u16_u32(cD),
                               vreinterpretq_u16_u32(cF));
    uint16x8_t dE = vtrn2q_u16(vreinterpretq_u16_u32(cC),
                               vreinterpretq_u16_u32(cE));
    uint16x8_t dF = vtrn2q_u16(vreinterpretq_u16_u32(cD),
                               vreinterpretq_u16_u32(cF));

    uint8x16_t e0 = vtrn1q_u8(vreinterpretq_u8_u16(d0),
                              vreinterpretq_u8_u16(d1));
    uint8x16_t e1 = vtrn2q_u8(vreinterpretq_u8_u16(d0),
                              vreinterpretq_u8_u16(d1));
    uint8x16_t e2 = vtrn1q_u8(vreinterpretq_u8_u16(d2),
                              vreinterpretq_u8_u16(d3));
    uint8x16_t e3 = vtrn2q_u8(vreinterpretq_u8_u16(d2),
                              vreinterpretq_u8_u16(d3));
    uint8x16_t e4 = vtrn1q_u8(vreinterpretq_u8_u16(d4),
                              vreinterpretq_u8_u16(d5));
    uint8x16_t e5 = vtrn2q_u8(vreinterpretq_u8_u16(d4),
                              vreinterpretq_u8_u16(d5));
    uint8x16_t e6 = vtrn1q_u8(vreinterpretq_u8_u16(d6),
                              vreinterpretq_u8_u16(d7));
    uint8x16_t e7 = vtrn2q_u8(vreinterpretq_u8_u16(d6),
                              vreinterpretq_u8_u16(d7));
    uint8x16_t e8 = vtrn1q_u8(vreinterpretq_u8_u16(d8),
                              vreinterpretq_u8_u16(d9));
    uint8x16_t e9 = vtrn2q_u8(vreinterpretq_u8_u16(d8),
                              vreinterpretq_u8_u16(d9));
    uint8x16_t eA = vtrn1q_u8(vreinterpretq_u8_u16(dA),
                              vreinterpretq_u8_u16(dB));
    uint8x16_t eB = vtrn2q_u8(vreinterpretq_u8_u16(dA),
                              vreinterpretq_u8_u16(dB));
    uint8x16_t eC = vtrn1q_u8(vreinterpretq_u8_u16(dC),
                              vreinterpretq_u8_u16(dD));
    uint8x16_t eD = vtrn2q_u8(vreinterpretq_u8_u16(dC),
                              vreinterpretq_u8_u16(dD));
    uint8x16_t eE = vtrn1q_u8(vreinterpretq_u8_u16(dE),
                              vreinterpretq_u8_u16(dF));
    uint8x16_t eF = vtrn2q_u8(vreinterpretq_u8_u16(dE),
                              vreinterpretq_u8_u16(dF));

    vst1q_u8(dst + 0 * dstride, e0);
    vst1q_u8(dst + 1 * dstride, e1);
    vst1q_u8(dst + 2 * dstride, e2);
    vst1q_u8(dst + 3 * dstride, e3);
    vst1q_u8(dst + 4 * dstride, e4);
    vst1q_u8(dst + 5 * dstride, e5);
    vst1q_u8(dst + 6 * dstride, e6);
    vst1q_u8(dst + 7 * dstride, e7);
    vst1q_u8(dst + 8 * dstride, e8);
    vst1q_u8(dst + 9 * dstride, e9);
    vst1q_u8(dst + 10 * dstride, eA);
    vst1q_u8(dst + 11 * dstride, eB);
    vst1q_u8(dst + 12 * dstride, eC);
    vst1q_u8(dst + 13 * dstride, eD);
    vst1q_u8(dst + 14 * dstride, eE);
    vst1q_u8(dst + 15 * dstride, eF);
}


void transpose32x32(uint8_t *dst, const uint8_t *src, intptr_t dstride, intptr_t sstride)
{
    //assumption: there is no partial overlap
    transpose16x16(dst, src, dstride, sstride);
    transpose16x16(dst + 16 * dstride + 16, src + 16 * sstride + 16, dstride, sstride);
    if (dst == src)
    {
        uint8_t tmp[16 * 16] __attribute__((aligned(64)));
        transpose16x16(tmp, src + 16, 16, sstride);
        transpose16x16(dst + 16, src + 16 * sstride, dstride, sstride);
        for (int i = 0; i < 16; i++)
        {
            vst1q_u8(dst + (16 + i) * dstride, vld1q_u8(tmp + 16 * i));
        }
    }
    else
    {
        transpose16x16(dst + 16 * dstride, src + 16, dstride, sstride);
        transpose16x16(dst + 16, src + 16 * sstride, dstride, sstride);
    }

}



void transpose8x8(uint16_t *dst, const uint16_t *src, intptr_t dstride, intptr_t sstride)
{
    uint16x8_t a0 = vld1q_u16(src + 0 * sstride);
    uint16x8_t a1 = vld1q_u16(src + 1 * sstride);
    uint16x8_t a2 = vld1q_u16(src + 2 * sstride);
    uint16x8_t a3 = vld1q_u16(src + 3 * sstride);
    uint16x8_t a4 = vld1q_u16(src + 4 * sstride);
    uint16x8_t a5 = vld1q_u16(src + 5 * sstride);
    uint16x8_t a6 = vld1q_u16(src + 6 * sstride);
    uint16x8_t a7 = vld1q_u16(src + 7 * sstride);

    uint64x2_t b0 = vtrn1q_u64(vreinterpretq_u64_u16(a0),
                               vreinterpretq_u64_u16(a4));
    uint64x2_t b1 = vtrn1q_u64(vreinterpretq_u64_u16(a1),
                               vreinterpretq_u64_u16(a5));
    uint64x2_t b2 = vtrn1q_u64(vreinterpretq_u64_u16(a2),
                               vreinterpretq_u64_u16(a6));
    uint64x2_t b3 = vtrn1q_u64(vreinterpretq_u64_u16(a3),
                               vreinterpretq_u64_u16(a7));
    uint64x2_t b4 = vtrn2q_u64(vreinterpretq_u64_u16(a0),
                               vreinterpretq_u64_u16(a4));
    uint64x2_t b5 = vtrn2q_u64(vreinterpretq_u64_u16(a1),
                               vreinterpretq_u64_u16(a5));
    uint64x2_t b6 = vtrn2q_u64(vreinterpretq_u64_u16(a2),
                               vreinterpretq_u64_u16(a6));
    uint64x2_t b7 = vtrn2q_u64(vreinterpretq_u64_u16(a3),
                               vreinterpretq_u64_u16(a7));

    uint32x4_t c0 = vtrn1q_u32(vreinterpretq_u32_u64(b0),
                               vreinterpretq_u32_u64(b2));
    uint32x4_t c1 = vtrn1q_u32(vreinterpretq_u32_u64(b1),
                               vreinterpretq_u32_u64(b3));
    uint32x4_t c2 = vtrn2q_u32(vreinterpretq_u32_u64(b0),
                               vreinterpretq_u32_u64(b2));
    uint32x4_t c3 = vtrn2q_u32(vreinterpretq_u32_u64(b1),
                               vreinterpretq_u32_u64(b3));
    uint32x4_t c4 = vtrn1q_u32(vreinterpretq_u32_u64(b4),
                               vreinterpretq_u32_u64(b6));
    uint32x4_t c5 = vtrn1q_u32(vreinterpretq_u32_u64(b5),
                               vreinterpretq_u32_u64(b7));
    uint32x4_t c6 = vtrn2q_u32(vreinterpretq_u32_u64(b4),
                               vreinterpretq_u32_u64(b6));
    uint32x4_t c7 = vtrn2q_u32(vreinterpretq_u32_u64(b5),
                               vreinterpretq_u32_u64(b7));

    uint16x8_t d0 = vtrn1q_u16(vreinterpretq_u16_u32(c0),
                               vreinterpretq_u16_u32(c1));
    uint16x8_t d1 = vtrn2q_u16(vreinterpretq_u16_u32(c0),
                               vreinterpretq_u16_u32(c1));
    uint16x8_t d2 = vtrn1q_u16(vreinterpretq_u16_u32(c2),
                               vreinterpretq_u16_u32(c3));
    uint16x8_t d3 = vtrn2q_u16(vreinterpretq_u16_u32(c2),
                               vreinterpretq_u16_u32(c3));
    uint16x8_t d4 = vtrn1q_u16(vreinterpretq_u16_u32(c4),
                               vreinterpretq_u16_u32(c5));
    uint16x8_t d5 = vtrn2q_u16(vreinterpretq_u16_u32(c4),
                               vreinterpretq_u16_u32(c5));
    uint16x8_t d6 = vtrn1q_u16(vreinterpretq_u16_u32(c6),
                               vreinterpretq_u16_u32(c7));
    uint16x8_t d7 = vtrn2q_u16(vreinterpretq_u16_u32(c6),
                               vreinterpretq_u16_u32(c7));

    vst1q_u16(dst + 0 * dstride, d0);
    vst1q_u16(dst + 1 * dstride, d1);
    vst1q_u16(dst + 2 * dstride, d2);
    vst1q_u16(dst + 3 * dstride, d3);
    vst1q_u16(dst + 4 * dstride, d4);
    vst1q_u16(dst + 5 * dstride, d5);
    vst1q_u16(dst + 6 * dstride, d6);
    vst1q_u16(dst + 7 * dstride, d7);
}

void transpose16x16(uint16_t *dst, const uint16_t *src, intptr_t dstride, intptr_t sstride)
{
    //assumption: there is no partial overlap
    transpose8x8(dst, src, dstride, sstride);
    transpose8x8(dst + 8 * dstride + 8, src + 8 * sstride + 8, dstride, sstride);

    if (dst == src)
    {
        uint16_t tmp[8 * 8];
        transpose8x8(tmp, src + 8, 8, sstride);
        transpose8x8(dst + 8, src + 8 * sstride, dstride, sstride);
        for (int i = 0; i < 8; i++)
        {
            vst1q_u16(dst + (8 + i) * dstride, vld1q_u16(tmp + 8 * i));
        }
    }
    else
    {
        transpose8x8(dst + 8 * dstride, src + 8, dstride, sstride);
        transpose8x8(dst + 8, src + 8 * sstride, dstride, sstride);
    }

}



void transpose32x32(uint16_t *dst, const uint16_t *src, intptr_t dstride, intptr_t sstride)
{
    //assumption: there is no partial overlap
    for (int i = 0; i < 4; i++)
    {
        transpose8x8(dst + i * 8 * (1 + dstride), src + i * 8 * (1 + sstride), dstride, sstride);
        for (int j = i + 1; j < 4; j++)
        {
            if (dst == src)
            {
                uint16_t tmp[8 * 8] __attribute__((aligned(64)));
                transpose8x8(tmp, src + 8 * i + 8 * j * sstride, 8, sstride);
                transpose8x8(dst + 8 * i + 8 * j * dstride, src + 8 * j + 8 * i * sstride, dstride, sstride);
                for (int k = 0; k < 8; k++)
                {
                    vst1q_u16(dst + 8 * j + (8 * i + k) * dstride,
                              vld1q_u16(tmp + 8 * k));
                }
            }
            else
            {
                transpose8x8(dst + 8 * (j + i * dstride), src + 8 * (i + j * sstride), dstride, sstride);
                transpose8x8(dst + 8 * (i + j * dstride), src + 8 * (j + i * sstride), dstride, sstride);
            }

        }
    }
}




}



