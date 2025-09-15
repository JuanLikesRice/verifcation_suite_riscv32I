// Typedefs (since stdint.h is not used)
typedef unsigned int    uint32;
typedef unsigned long   uint64;
typedef unsigned long   uintptr;

#define CLINT_BASE      0x02000000UL
#define MTIMECMP        (*(volatile uint64*)(CLINT_BASE + 0x4000))
#define MTIME           (*(volatile uint64*)(CLINT_BASE + 0xBFF8))

#define MIE_MTIE        (1 << 7)
#define MSTATUS_MIE     (1 << 3)

volatile uint32 timer_triggered = 0;

// Forward declaration
void trap_handler(void);

// Set mtvec to our trap handler address
void init_mtvec() {
    uintptr trap_addr = (uintptr)&trap_handler;
    asm volatile("csrw mtvec, %0" :: "r"(trap_addr));
}

// Enable timer interrupt
void enable_timer_interrupt() {
    asm volatile("csrs mie, %0" :: "r"(MIE_MTIE));
    asm volatile("csrs mstatus, %0" :: "r"(MSTATUS_MIE));
}

// Set timer for future interrupt (e.g., 1 million cycles ahead)
void set_timer(uint64 delta) {
    uint64 now = MTIME;
    MTIMECMP = now + delta;
}

// Trap handler (called on interrupt)
void trap_handler() {
    set_timer(1000000);  // Set next timer interrupt
    timer_triggered = 1;
}

// Dumb delay loop (for blinking or polling effect)
void delay() {
    volatile uint32 i;
    for (i = 0; i < 100000; i++) {
        // prevent optimization
        asm volatile("");
    }
}

// Main entry point (from startup.S, sets _start to call this)
void main() {
    init_mtvec();
    enable_timer_interrupt();
    set_timer(1000000);

    while (1) {
        if (timer_triggered) {
            timer_triggered = 0;
        }
        delay();
    }
}
