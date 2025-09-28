#include "constants.h"

#define TEST_ADDR ((volatile float*) (DATARAM_ORIGIN + 0x100))

int main(void) {
    volatile float *p = TEST_ADDR;

    unsigned int pattern = 0x3F800000u;  // float +1.0
    *((volatile unsigned int*)p) = pattern;  // store via integer store

    // Load the float from memory (should be FLW)
    volatile float f = *p;

    // Perform a trivial FP operation (f = f + 1.0f), forces FADD.S
    f = f + 1.0f;

    // Store back (should be FSW)
    *p = f;

    // Read back raw bits through integer load
    unsigned int got = *((volatile unsigned int*)p);

    // Report value to peripheral for debug
    write_mmio(PERIPHERAL_S2, got);

    // Expected pattern = 1.0f + 1.0f = 2.0f = 0x40000000
    // if (got != 0x40000000u) {
    //     fail(1);
    // }

    return 0;
}

