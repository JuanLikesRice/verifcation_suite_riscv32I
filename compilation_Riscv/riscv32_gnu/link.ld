ENTRY(_start)

MEMORY {
    REGION_TEXT (rx) : ORIGIN = 0x00000100, LENGTH = 1K    /* Code section: Read, Execute */
    REGION_DATA (rw) : ORIGIN = 0x00000200, LENGTH = 512   /* Data section: Read, Write */
    REGION_BSS  (rw) : ORIGIN = 0x00000280, LENGTH = 1K    /* BSS section: Read, Write */
}

SECTIONS {
    /* Code section (Text) - should be RX (Read, Execute) */
    .text : {
        *(.text*)    /* All .text sections from all object files */
    } > REGION_TEXT

    /* Data section - should be RW (Read, Write) */
    .data : {
        *(.data*)
    } > REGION_DATA

    /* BSS section - should be RW (Read, Write) */
    .bss : {
        *(.bss*)
        _bss_end = .;
    } > REGION_BSS
}
