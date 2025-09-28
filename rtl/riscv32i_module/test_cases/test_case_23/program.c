#include "constants.h"

#define TEST_ADDR (DATARAM_ORIGIN + 0x100)

int main(void) {
    unsigned int result;

    // 1. Store constant bit pattern for 1.0f into memory
    *((volatile unsigned int*)TEST_ADDR) = 0x3F800000u;

    __asm__ volatile (
        // Load float 1.0 into f15
        "flw f15, 0(%1)\n"
        // Store f15 to TEST_ADDR+4
        "fsw f15, 4(%1)\n"
        // Load that back into f14
        "flw f14, 4(%1)\n"
        // Now load it into an integer register from memory (LW, not FMV)
        "lw %0, 4(%1)\n"
        : "=r"(result)          // output
        : "r"(TEST_ADDR)        // input base address
        : "f14", "f15", "memory"
    );

    // Write raw bits out to peripheral
    write_mmio(PERIPHERAL_S2, result);

    // Check expected pattern for float 1.0
    if (result != 0x3F800000u) {
        fail(1);
    }

    return 0;
}
