/* Width-aware typedefs (no headers) */
#if __riscv_xlen == 64
typedef unsigned long uaddr_t;   /* 64-bit pointer-sized integer (LP64) */
#else
typedef unsigned int  uaddr_t;   /* 32-bit on RV32 */
#endif
typedef unsigned int  u32;
typedef int           i32;

/* MMIO address (typed to pointer-size) */
#define PERIPHERAL_SUCCESS ((uaddr_t)0x00000600UL)

/* 32-bit MMIO write (common even on RV64 SoCs) */
static inline void write_mmio32(uaddr_t addr, u32 value) {
    *(volatile u32 *)(addr) = value;
}

int main(void) {
    /* Zero-extended halfword from LHU: 0xCFC7 = -12345 in 16-bit two's complement */
    u32 u = 0x0000CFC7u;

    /* slli 16; srai 16 -> sign-extend 16-bit into 32-bit 'int' */
    i32 result = ((i32)(u << 16)) >> 16;

    if (result == -12345) {
        write_mmio32(PERIPHERAL_SUCCESS, 0xDEADBEEF);
    } else {
        write_mmio32(PERIPHERAL_SUCCESS, 0xBADF00D);
    }

    for (;;);
    return 0;
}
