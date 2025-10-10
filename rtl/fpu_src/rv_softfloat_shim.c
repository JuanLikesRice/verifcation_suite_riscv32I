#include <stdint.h>
#include "softfloat.h"

// Map RISC-V rm (0..4) to SoftFloat rounding modes.
static inline uint8_t map_rm(int rm) {
    switch (rm) {
        case 0: return softfloat_round_near_even;    // RNE
        case 1: return softfloat_round_minMag;       // RTZ
        case 2: return softfloat_round_min;          // RDN
        case 3: return softfloat_round_max;          // RUP
        case 4: return softfloat_round_near_maxMag;  // RMM (ties-to-away)
        default: return softfloat_round_near_even;   // treat others as RNE
    }
}

// Perform single-precision add with RISC-V rounding mode.
// Returns result bits; writes IEEE-754 exception flags into *flags_out:
//  bit0: inexact, bit1: underflow, bit2: overflow, bit3: divByZero, bit4: invalid
// (matches SoftFloat's softfloat_exceptionFlags bit layout)
uint32_t rv_f32_add_rm(uint32_t a_bits, uint32_t b_bits, int rm, uint8_t *flags_out) {
    softfloat_roundingMode = map_rm(rm);
    softfloat_exceptionFlags = 0;

    float32_t a, b, r;
    a.v = a_bits;
    b.v = b_bits;
    r = f32_add(a, b);

    if (flags_out) *flags_out = (uint8_t)softfloat_exceptionFlags;
    return r.v;
}
