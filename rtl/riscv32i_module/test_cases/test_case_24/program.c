#include "constants.h"

// static inline void mmio_write(unsigned int a, unsigned int v){ *(volatile unsigned int*)a = v; }

/* ---- FP control ---- */
static inline void enable_fp(void) {
    const unsigned int FS_DIRTY = (3u << 13);  // mstatus.FS=11
    __asm__ volatile ("csrs mstatus, %0" :: "r"(FS_DIRTY));
}
static inline void set_fcsr(unsigned int frm, unsigned int fflags) {
    unsigned int v = ((frm & 7u) << 5) | (fflags & 0x1Fu);
    __asm__ volatile ("csrw fcsr, %0" :: "r"(v));
}
static inline unsigned int read_fcsr(void){
    unsigned int v;
    __asm__ volatile ("csrr %0, fcsr" : "=r"(v));
    return v;
}

int main(void) {
    enable_fp();

    // round-to-nearest-even, clear flags
    set_fcsr(0u, 0u);

    volatile float a = 1.25f;
    volatile float b = 2.5f;
    float c = a + b;        // should be 3.75f, compiled as fadd.s

    // touch c so compiler keeps it
    volatile unsigned int out = *(volatile unsigned int*)&c;

    // record result and current fcsr to MMIO
    write_mmio(PERIPHERAL_S1, out);
    write_mmio(PERIPHERAL_S2 + 4, read_fcsr());
    return 0;
    // for(;;);
}
