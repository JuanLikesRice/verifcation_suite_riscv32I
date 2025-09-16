#include "constants.h"

int main(void) {
    // declare operands as volatile so the compiler must read them
    volatile int a1 = 5,      b1 = 7;
    volatile int a2 = 32652,  b2 = 4678;
    volatile int a3 = 32652,  b3 = -4678;
    volatile int a4 = -32652, b4 = 4678;
    volatile int a5 = -32652, b5 = -4678;

    // --- Arithmetic Operations ---
    if ((a1 * b1) != 35)           { fail(1); }
    if ((a2 * b2) != 152746056)    { fail(2); }
    if ((a3 * b3) != -152746056)   { fail(3); }
    if ((a4 * b4) != -152746056)   { fail(4); }
    if ((a5 * b5) != 152746056)    { fail(5); }

    write_mmio(PERIPHERAL_SUCCESS, 0xDEADBEEF);
    while (1);
    return 0;
}
