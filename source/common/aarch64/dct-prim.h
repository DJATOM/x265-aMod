#ifndef __DCT_PRIM_NEON_H__
#define __DCT_PRIM_NEON_H__


#include "common.h"
#include "primitives.h"
#include "contexts.h"   // costCoeffNxN_c
#include "threading.h"  // CLZ

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

// x265 private namespace
void setupDCTPrimitives_neon(EncoderPrimitives &p);
#if defined(HAVE_SVE) && HAVE_SVE_BRIDGE
void setupDCTPrimitives_sve(EncoderPrimitives &p);
#endif
};



#endif

