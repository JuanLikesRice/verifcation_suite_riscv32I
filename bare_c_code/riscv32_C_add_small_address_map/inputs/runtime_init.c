#include "constants.h"

/* Linker symbols */
extern unsigned int _bss_start, _bss_end;
extern unsigned int _sdata, _edata, _sidata;

int main(void);  /* user program */

/* Boot code that always runs before main */
void runtime_init(void) {
    /* Clear .bss */
    // for (unsigned int *p = &_bss_start; p < &_bss_end; )
        // *p++ = 0;

// #ifdef COPY_DATA_FROM_ROM   /* define this at compile time if you use ROM->RAM copy */
//     /* Copy .data from ROM (LMA) to RAM (VMA) */
//     for (unsigned int *s = &_sidata, *d = &_sdata; d < &_edata; )
//         *d++ = *s++;
// #endif

    int rc = main();

    /* After main finishes, signal via MMIO and stop */
    write_mmio(PERIPHERAL_SUCCESS, 0xDEADBEEF);  /* “good food” marker; change if you like */
    write_mmio(PERIPHERAL_S1, (unsigned)rc);
    for (;;)
        ;  /* halt */
}
