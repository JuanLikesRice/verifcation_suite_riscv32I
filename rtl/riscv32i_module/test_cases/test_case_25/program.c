#include "constants.h"

#define TEST_ADDR   (DATARAM_ORIGIN + 0x200)
#define TEST_ADDR2  (DATARAM_ORIGIN + 0x204)

int main(void) {
    unsigned int result;

    // initialize memory
    *((volatile unsigned int*)TEST_ADDR) = 0x12345678;

    __asm__ volatile (
        // load from TEST_ADDR into t1
        "lw   t1, 0(%1)\n"
        // store t1 into TEST_ADDR2
        "sw   t1, 0(%2)\n"
        // load back into t2
        "lw   t2, 0(%2)\n"
        // branch if not equal
        "bne  t1, t2, 1f\n"
        // if equal, write result = t1
        "mv   %0, t1\n"
        "j    2f\n"
        "1:\n"
        // call fail(1)
        "li   a0, 1\n"
        "jal  fail\n"
        "2:\n"
        : "=r"(result)
        : "r"(TEST_ADDR), "r"(TEST_ADDR2)
        : "t1", "t2", "a0", "memory"
    );

    write_mmio(PERIPHERAL_S2, result);
    return 0;
}
