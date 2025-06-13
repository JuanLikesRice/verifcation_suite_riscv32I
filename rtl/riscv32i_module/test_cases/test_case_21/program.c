// ========================
// RISCV Machine Timer Interrupt Test
// ========================

typedef unsigned int    uint32;
typedef unsigned long   uint64;
typedef unsigned long   uintptr;

// CLINT timer memory-mapped registers
#define CLINT_BASE      0x02000000UL
#define MTIMECMP        (*(volatile uint64*)(CLINT_BASE + 0x4000))
#define MTIME           (*(volatile uint64*)(CLINT_BASE + 0xBFF8))

// Peripheral writeback memory-mapped registers
#define PERIPHERAL_SUCCESS 0x00000600
#define PERIPHERAL_BYTE    0x00000604

// MIE / MSTATUS Bit Masks
#define MIE_MTIE        (1 << 7)  // Timer interrupt enable bit in mie
#define MSTATUS_MIE     (1 << 3)  // Global interrupt enable bit

// Globals
volatile uint32 timer_triggered = 0;  // Flag set inside trap handler

// Memory-mapped I/O write function
void write_mmio(unsigned int addr, unsigned int value) {
    volatile unsigned int *ptr = (volatile unsigned int *)addr;
    *ptr = value;
}

// Custom fail function with test ID
void fail(int id) {
    write_mmio(PERIPHERAL_BYTE, id);
    write_mmio(PERIPHERAL_SUCCESS, 0xBADF00D);
    while (1);
}

// Trap handler declaration
void trap_handler(void);

// --------------------------
// Setup Functions
// --------------------------

void init_mtvec() {
    uintptr trap_addr = (uintptr)&trap_handler;
    asm volatile("csrw mtvec, %0" :: "r"(trap_addr));
}

// Enable timer interrupt and global interrupt in M-mode
void enable_timer_interrupt() {
    asm volatile("csrs mie, %0" :: "r"(MIE_MTIE));
    asm volatile("csrs mstatus, %0" :: "r"(MSTATUS_MIE));
}

// Schedule timer interrupt for <delta> cycles in the future
void set_timer(uint64 delta) {
    uint64 now = MTIME;
    MTIMECMP = now + delta;
}

// Delay loop (dumb busy wait)
void delay() {
    for (volatile uint32 i = 0; i < 100000; ++i) {
        asm volatile("");  // prevent optimization
    }
}

// --------------------------
// Trap Handler (Interrupt Service Routine)
// --------------------------
// This function must be aligned and declared exactly as called by mtvec
void __attribute__((naked)) trap_handler(void) {
    asm volatile(
        // Save all registers (31 total)
        "addi sp, sp, -124\n\t"

        "sw ra,   0(sp)\n\t"
        "sw t0,   4(sp)\n\t"
        "sw t1,   8(sp)\n\t"
        "sw t2,  12(sp)\n\t"
        "sw s0,  16(sp)\n\t"
        "sw s1,  20(sp)\n\t"
        "sw s2,  24(sp)\n\t"
        "sw s3,  28(sp)\n\t"
        "sw s4,  32(sp)\n\t"
        "sw s5,  36(sp)\n\t"
        "sw s6,  40(sp)\n\t"
        "sw s7,  44(sp)\n\t"
        "sw s8,  48(sp)\n\t"
        "sw s9,  52(sp)\n\t"
        "sw s10, 56(sp)\n\t"
        "sw s11, 60(sp)\n\t"
        "sw t3,  64(sp)\n\t"
        "sw t4,  68(sp)\n\t"
        "sw t5,  72(sp)\n\t"
        "sw t6,  76(sp)\n\t"
        "sw a0,  80(sp)\n\t"
        "sw a1,  84(sp)\n\t"
        "sw a2,  88(sp)\n\t"
        "sw a3,  92(sp)\n\t"
        "sw a4,  96(sp)\n\t"
        "sw a5, 100(sp)\n\t"
        "sw a6, 104(sp)\n\t"
        "sw a7, 108(sp)\n\t"
        "sw gp, 112(sp)\n\t"
        "sw tp, 116(sp)\n\t"
        );


        write_mmio(PERIPHERAL_SUCCESS, 0xDEADBEEF);

        // "li   t0, 1536\n\t"                  // PERIPHERAL_SUCCESS
        // "lui  t1, 0xDEADC\n\t"
        // "addi t1, t1, -273\n\t"             // t1 = 0xDEADBEEF
        // "sw   t1, 0(t0)\n\t"


        asm volatile(        // // Set a flag to indicate interrupt fired

        "lw gp,  112(sp)\n\t"
        "lw tp,  116(sp)\n\t"
        "lw a0,   80(sp)\n\t"
        "lw a1,   84(sp)\n\t"
        "lw a2,   88(sp)\n\t"
        "lw a3,   92(sp)\n\t"
        "lw a4,   96(sp)\n\t"
        "lw a5,  100(sp)\n\t"
        "lw a6,  104(sp)\n\t"
        "lw a7,  108(sp)\n\t"
        "lw t3,   64(sp)\n\t"
        "lw t4,   68(sp)\n\t"
        "lw t5,   72(sp)\n\t"
        "lw t6,   76(sp)\n\t"
        "lw s0,   16(sp)\n\t"
        "lw s1,   20(sp)\n\t"
        "lw s2,   24(sp)\n\t"
        "lw s3,   28(sp)\n\t"
        "lw s4,   32(sp)\n\t"
        "lw s5,   36(sp)\n\t"
        "lw s6,   40(sp)\n\t"
        "lw s7,   44(sp)\n\t"
        "lw s8,   48(sp)\n\t"
        "lw s9,   52(sp)\n\t"
        "lw s10,  56(sp)\n\t"
        "lw s11,  60(sp)\n\t"
        "lw t0,    4(sp)\n\t"
        "lw t1,    8(sp)\n\t"
        "lw t2,   12(sp)\n\t"
        "lw ra,    0(sp)\n\t"

        "addi sp, sp, 124\n\t"

        // Return from machine mode
        "mret\n\t"
    );
}

// --------------------------
// Main Program
// --------------------------
void main() {
    init_mtvec();
    enable_timer_interrupt();
    set_timer(500000);  // Schedule interrupt

    while (1) {
        delay();  // Wait in delay loop
    }
}
