ENTRY(_start)

MEMORY {
    REGION_TEXT (rx) : ORIGIN = 0x00000000, LENGTH = 32K  /* Instruction Memory */

    REGION_ROM (rx) : ORIGIN = 0x00080000, LENGTH = 512  /* ROM Memory */

    REGION_PERIPH (rw) : ORIGIN = 0x1A000000, LENGTH = 64K  /* Peripherals Memory */

    REGION_DATA (rw) : ORIGIN = 0x00010000, LENGTH = 64K  /* Data memory (stack/heap) */
}

SECTIONS {
    /* Code section (Text) - should be RX (Read, Execute) */
    .text : {
        *(.text*)    /* All .text sections from all object files */
    } > REGION_TEXT

    /* ROM section (Read-Only Data) */
    .rodata : {
        *(.rodata*)  /* All .rodata sections from all object files */
    } > REGION_ROM

    /* Peripherals section (Memory-Mapped I/O) */
    .peripherals : {
        *(.peripherals*)  /* Memory-mapped peripherals (if any) */
    } > REGION_PERIPH

    /* Data section - should be RW (Read, Write) */
    .data : {
        *(.data*)
    } > REGION_DATA

    /* BSS section - should be RW (Read, Write) */
    .bss : {
        *(.bss*)
        _bss_end = .;
    } > REGION_DATA
}
