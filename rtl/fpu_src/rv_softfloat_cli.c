#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "softfloat.h"

static inline uint8_t map_rm(int rm) {
    switch (rm) {
        case 0: return softfloat_round_near_even;    // RNE
        case 1: return softfloat_round_minMag;       // RTZ
        case 2: return softfloat_round_min;          // RDN
        case 3: return softfloat_round_max;          // RUP
        case 4: return softfloat_round_near_maxMag;  // RMM
        default: return softfloat_round_near_even;
    }
}

int main(int argc, char** argv) {
    if (argc != 4) {
        fprintf(stderr, "usage: %s <rm 0..4> <A_hex> <B_hex>\n", argv[0]);
        return 2;
    }
    int rm = atoi(argv[1]);
    uint32_t a = (uint32_t)strtoul(argv[2], NULL, 0);
    uint32_t b = (uint32_t)strtoul(argv[3], NULL, 0);

    softfloat_roundingMode = map_rm(rm);
    softfloat_exceptionFlags = 0;

    float32_t fa, fb, fr;
    fa.v = a; fb.v = b;
    fr = f32_add(fa, fb);

    uint8_t flags = (uint8_t)softfloat_exceptionFlags;
    printf("0x%08X 0x%02X\n", fr.v, flags);  // <result_hex> <flags_hex>
    return 0;
}
