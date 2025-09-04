/* ==========================================================
 * RV32I  –  Machine-Timer-Interrupt demo
 * Custom MTIME / MTIMECMP map: 0x700 – 0x70F
 * NO standard headers
 * ========================================================== */

/* ---------- simple typedefs ---------- */
typedef unsigned int        uint32;          /* 32-bit */
typedef unsigned long long  uint64;          /* 64-bit */
typedef unsigned long       uintptr;         /* native pointer */

/* ---------- string-ify helper (for asm immediates) ---------- */
#define  _STR(x)  #x
#define  STR(x)   _STR(x)

/* ---------- MMIO addresses ---------- */
// #define MTIME_LO        (*(volatile uint32 *)0x00002700U)
// #define MTIME_HI        (*(volatile uint32 *)0x00002704U)
// #define MTIMECMP_LO     (*(volatile uint32 *)0x00002708U)
// #define MTIMECMP_HI     (*(volatile uint32 *)0x0000270CU)

#define CLINT_BASE   0x02000000UL
#define MTIMECMP_LO  (*(volatile uint32 *)(CLINT_BASE + 0x4000))
#define MTIMECMP_HI  (*(volatile uint32 *)(CLINT_BASE + 0x4004))
#define MTIME_LO     (*(volatile uint32 *)(CLINT_BASE + 0xBFF8))
#define MTIME_HI     (*(volatile uint32 *)(CLINT_BASE + 0xBFFC))


/* test-bench peripherals (unchanged) */
#define PERIPHERAL_SUCCESS   0x00002600
#define PERIPHERAL_BYTE      0x00002604

/* ---------- CSR bit masks ---------- */
#define MIE_MTIE       (1U << 7)     /* mie  – machine-timer enable   */
#define MSTATUS_MIE    (1U << 3)     /* mstatus – global int enable   */

/* ---------- globals ---------- */
volatile uint32 timer_triggered = 0;

/* ==========================================================
 * Low-level helpers
 * ========================================================== */
static inline void write_mmio(uint32 addr, uint32 val)
{
    *(volatile uint32 *)addr = val;
}

/* 64-bit read of mtime with rollover guard             */
static inline uint64 read_mtime(void)
{
    uint32 hi, lo;
    do {
        hi = MTIME_HI;
        lo = MTIME_LO;
    } while (hi != MTIME_HI);
    return ((uint64)hi << 32) | lo;
}

/* Safe 64-bit write to mtimecmp (spec §3.2.1 sequence) */
static inline void set_timer(uint64 delta)
{
    uint64 now     = read_mtime();
    uint64 cmp     = now + delta;
    uint32 cmp_lo  = (uint32)cmp;
    uint32 cmp_hi  = (uint32)(cmp >> 32);

    MTIMECMP_HI = 0xFFFFFFFFU;   /* block comparator            */
    MTIMECMP_LO = cmp_lo;
    MTIMECMP_HI = cmp_hi;
    // asm volatile("fence rw,rw"); /* ensure ordering              */
}

static inline void csr_write_mtvec(uintptr addr)
{
    asm volatile("csrw mtvec, %0" :: "r"(addr));
}

static inline void enable_timer_interrupts(void)
{
    asm volatile("csrs mie,     %0" :: "r"(MIE_MTIE));
    asm volatile("csrs mstatus, %0" :: "r"(MSTATUS_MIE));
}

/* ==========================================================
 * Naked interrupt handler – saves ALL 31 GPRs
 * 128-byte 16-aligned frame
 * ========================================================== */


/* -------- helper must come first (or at least a prototype) -------- */
static void on_timer_irq(void) __attribute__((noinline));
static void on_timer_irq(void)
{
    /* MMIO write for test bench */
    *(volatile uint32 *)PERIPHERAL_SUCCESS = 0xDEADBEEF;
    timer_triggered = 1;
    asm volatile("csrc mie, %0" :: "r"(MIE_MTIE));  // disable machine-timer interrupt

}

/* -------- unchanged naked wrapper, but now “call” is valid -------- */
void __attribute__((naked)) trap_handler(void)
{

// void __attribute__((naked)) trap_handler(void)
// {
    asm volatile(
        /* ---------- prologue ---------- */
        "addi  sp, sp, -128            \n\t"
        "sw    ra,   0(sp)             \n\t"
        "sw    t0,   4(sp)             \n\t"
        "sw    t1,   8(sp)             \n\t"
        "sw    t2,  12(sp)             \n\t"
        "sw    s0,  16(sp)             \n\t"
        "sw    s1,  20(sp)             \n\t"
        "sw    s2,  24(sp)             \n\t"
        "sw    s3,  28(sp)             \n\t"
        "sw    s4,  32(sp)             \n\t"
        "sw    s5,  36(sp)             \n\t"
        "sw    s6,  40(sp)             \n\t"
        "sw    s7,  44(sp)             \n\t"
        "sw    s8,  48(sp)             \n\t"
        "sw    s9,  52(sp)             \n\t"
        "sw    s10, 56(sp)             \n\t"
        "sw    s11, 60(sp)             \n\t"
        "sw    t3,  64(sp)             \n\t"
        "sw    t4,  68(sp)             \n\t"
        "sw    t5,  72(sp)             \n\t"
        "sw    t6,  76(sp)             \n\t"
        "sw    a0,  80(sp)             \n\t"
        "sw    a1,  84(sp)             \n\t"
        "sw    a2,  88(sp)             \n\t"
        "sw    a3,  92(sp)             \n\t"
        "sw    a4,  96(sp)             \n\t"
        "sw    a5, 100(sp)             \n\t"
        "sw    a6, 104(sp)             \n\t"
        "sw    a7, 108(sp)             \n\t"
        "sw    gp, 112(sp)             \n\t"
        "sw    tp, 116(sp)             \n\t"
        /* ---------- body ---------- */
        "call  on_timer_irq        \n\t"   /*  <-- safe C helper  */
        /* ---------- epilogue ---------- */
        "lw    tp, 116(sp)             \n\t"
        "lw    gp, 112(sp)             \n\t"
        "lw    a7, 108(sp)             \n\t"
        "lw    a6, 104(sp)             \n\t"
        "lw    a5, 100(sp)             \n\t"
        "lw    a4,  96(sp)             \n\t"
        "lw    a3,  92(sp)             \n\t"
        "lw    a2,  88(sp)             \n\t"
        "lw    a1,  84(sp)             \n\t"
        "lw    a0,  80(sp)             \n\t"
        "lw    t6,  76(sp)             \n\t"
        "lw    t5,  72(sp)             \n\t"
        "lw    t4,  68(sp)             \n\t"
        "lw    t3,  64(sp)             \n\t"
        "lw    s11, 60(sp)             \n\t"
        "lw    s10, 56(sp)             \n\t"
        "lw    s9,  52(sp)             \n\t"
        "lw    s8,  48(sp)             \n\t"
        "lw    s7,  44(sp)             \n\t"
        "lw    s6,  40(sp)             \n\t"
        "lw    s5,  36(sp)             \n\t"
        "lw    s4,  32(sp)             \n\t"
        "lw    s3,  28(sp)             \n\t"
        "lw    s2,  24(sp)             \n\t"
        "lw    s1,  20(sp)             \n\t"
        "lw    s0,  16(sp)             \n\t"
        "lw    t2,  12(sp)             \n\t"
        "lw    t1,   8(sp)             \n\t"
        "lw    t0,   4(sp)             \n\t"
        "lw    ra,   0(sp)             \n\t"
        "addi  sp,  sp, 128            \n\t"

        "mret                                   \n\t"
        :
        :
        : "memory", "cc"
    );
}

/* ==========================================================
 * Init & main loop
 * ========================================================== */
static void init_mtvec(void)
{
    uintptr base = ((uintptr)&trap_handler) & ~0x3UL;
    csr_write_mtvec(base);
}

static inline void delay(void)
{
    for (volatile uint32 i = 0; i < 10U; ++i)
        asm volatile("");
}


static inline void end_all(void)
{
    while (1);
}


void main(void)
{
    init_mtvec();                  /* point mtvec at ISR        */
    set_timer(5);                /* fire in ~100 cycles      */
    enable_timer_interrupts();     /* MIE + MTIE                */

    while (1){
        delay();
        if (timer_triggered)  {
            end_all();

        }

    }    }