#define PERIPHERAL_SUCCESS 0x00002600
#define PERIPHERAL_BYTE    0x00002604

// Write a value to a memory-mapped register.
void write_mmio(unsigned int addr, unsigned int value) {
    volatile unsigned int *ptr = (volatile unsigned int *)addr;
    *ptr = value;
}

// Called when a test fails; test_index indicates the failing instruction.
void fail(int test_index) {
    write_mmio(PERIPHERAL_BYTE, test_index);
    write_mmio(PERIPHERAL_SUCCESS, 0xBADF00D);
    while (1);
}

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
