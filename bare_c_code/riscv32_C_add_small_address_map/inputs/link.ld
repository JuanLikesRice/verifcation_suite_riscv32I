SEARCH_DIR(.)
__DYNAMIC = 0;

MEMORY
{
    /* Define the memory regions according to the new map */
    instrram   : ORIGIN = 0x00000000, LENGTH = 1280  /* Instruction Memory:     1280 B */
    rom        : ORIGIN = 0x00000500, LENGTH =  256  /* ROM (Boot):              256 B */
    peripheral : ORIGIN = 0x00000600, LENGTH =  512  /* Peripherals:             512 B */
    dataram    : ORIGIN = 0x00000800, LENGTH = 6144  /* Data Memory:            2048 B */
}

/* Stack information */
_min_stack  = 0x800;          /* Minimum stack size: 2048 B */
_stack_len  =  2048;            /* Total stack size (words) */
_stack_start = ORIGIN(dataram) + LENGTH(dataram);  /* Stack starts at the end of Data RAM */

/* Define sections and their placement in memory */
SECTIONS
{
    .text : {
        . = ALIGN(4);
        _stext = .;            /* Start of the .text section */
        *(.text)               /* All text (code) sections */
        _etext = .;            /* End of the .text section */
    } > instrram               /* Map .text to Instruction Memory */

    .rodata : {
        . = ALIGN(4);
        *(.rodata)             /* Read-only data section */
    } > rom                    /* Map read-only data to ROM (Boot) */

    .data : {
        . = ALIGN(4);
        _sdata = .;            /* Start of the .data section */
        *(.data)               /* Initialized data */
        _edata = .;            /* End of the .data section */
    } > dataram                /* Map .data to Data Memory */

    .bss : {
        . = ALIGN(4);
        _bss_start = .;        /* Start of the .bss section */
        *(.bss)                /* Uninitialized data */
        _bss_end = .;          /* End of the .bss section */
    } > dataram                /* Map .bss to Data Memory */

    .stack (NOLOAD) : {
        . = ALIGN(4);
        . = . + _min_stack;    /* Reserve stack space */
        _stack = .;
    } > dataram                /* Stack is placed in Data Memory */

    _end = .;                  /* End of all sections */
}
