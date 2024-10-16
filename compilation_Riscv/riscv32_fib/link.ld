ENTRY(_start)

MEMORY {
    REGION_TEXT (rx) : ORIGIN = 0x00000100, LENGTH = 64K  /* Code section: Read, Execute */
    REGION_DATA (rw) : ORIGIN = 0x00010000, LENGTH = 64K  /* Data section: Read, Write */
    REGION_IO   (rw) : ORIGIN = 0x00001000, LENGTH = 64   /* I/O section: Read, Write */
}

SECTIONS {
    /* Code section (Text) */
    .text : {
        *(.text*)
    } > REGION_TEXT

    /* Data section */
    .data : {
        *(.data*)
    } > REGION_DATA

    /* BSS section */
    .bss : {
        *(.bss*)
        _bss_end = .;
    } > REGION_DATA
}
