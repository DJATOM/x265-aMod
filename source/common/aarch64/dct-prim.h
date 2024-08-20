#ifndef __DCT_PRIM_NEON_H__
#define __DCT_PRIM_NEON_H__


#include "common.h"
#include "primitives.h"
#include "contexts.h"   // costCoeffNxN_c
#include "threading.h"  // CLZ
#include <arm_neon.h>

namespace X265_NS
{
// First two columns of the 4x4 dct transform matrix, duplicated to 4x4 to allow
// processing two lines at once.
const int32_t t8_even[4][4] =
{
    { 64,  64, 64,  64 },
    { 83,  36, 83,  36 },
    { 64, -64, 64, -64 },
    { 36, -83, 36, -83 },
};

const uint8_t rev16_tbl[16] =
{
    14, 15, 12, 13, 10, 11, 8, 9, 6, 7, 4, 5, 2, 3, 0, 1
};

const uint8_t rev32_tbl[16] =
{
    12, 13, 14, 15, 8, 9, 10, 11, 4, 5, 6, 7, 0, 1, 2, 3
};

static inline int16x8_t rev16(const int16x8_t a)
{
    const uint8x16_t tbl = vld1q_u8(rev16_tbl);
    const int8x16_t a_s8 = vreinterpretq_s8_s16(a);

    return vreinterpretq_s16_s8(vqtbx1q_s8(a_s8, a_s8, tbl));
}

static inline int32x4_t rev32(const int32x4_t a)
{
    const uint8x16_t tbl = vld1q_u8(rev32_tbl);
    const int8x16_t a_s8 = vreinterpretq_s8_s32(a);

    return vreinterpretq_s32_s8(vqtbx1q_s8(a_s8, a_s8, tbl));
}

// x265 private namespace
void setupDCTPrimitives_neon(EncoderPrimitives &p);
#if defined(HAVE_SVE) && HAVE_SVE_BRIDGE
void setupDCTPrimitives_sve(EncoderPrimitives &p);
#endif
};



#endif

