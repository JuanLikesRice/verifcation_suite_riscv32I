#include "constants.h"

#define TEST_ADDR ((volatile float*) (DATARAM_ORIGIN + 0x100))

int main(void) {
    volatile float *p = TEST_ADDR;

    unsigned int pattern = 0x3F800000u;  // float +1.0
    *((volatile unsigned int*)p) = pattern;  // store via integer store
    volatile float f = *p;  // this should compile to FLW
    *p = f;

    unsigned int got = *((volatile unsigned int*)p);
    write_mmio(PERIPHERAL_S2, got);
    // if (got == pattern) {
    if (got != pattern) {
        fail(1);
    }
    // write_mmio(PERIPHERAL_SUCCESS, 0xDEADBEEF);
    return 0;
}
