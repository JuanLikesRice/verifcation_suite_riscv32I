// CLI: rv_softfloat_cli_mul <rm> <hex_a> <hex_b>
// Prints: "<hex_result> <flags>"
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "softfloat.h"

static int rm_map(int rm) {
    switch (rm & 7) {
        case 0: return softfloat_round_near_even;   // RNE
        case 1: return softfloat_round_minMag;      // RTZ
        case 2: return softfloat_round_min;         // RDN
        case 3: return softfloat_round_max;         // RUP
        case 4: return softfloat_round_near_maxMag; // RMM
        default: return softfloat_round_near_even;
    }
}

int main(int argc, char **argv) {
    if (argc != 4) { fprintf(stderr, "usage: %s rm hexA hexB\n", argv[0]); return 2; }
    int rm = (int)strtol(argv[1], NULL, 0);
    uint32_t a_bits = (uint32_t)strtoul(argv[2], NULL, 0);
    uint32_t b_bits = (uint32_t)strtoul(argv[3], NULL, 0);

    softfloat_roundingMode = rm_map(rm);
    softfloat_exceptionFlags = 0;

    float32_t a; a.v = a_bits;
    float32_t b; b.v = b_bits;
    float32_t r = f32_mul(a, b);

    printf("%08X %02X\n", r.v, (unsigned)(softfloat_exceptionFlags & 0x1F));
    return 0;
}
