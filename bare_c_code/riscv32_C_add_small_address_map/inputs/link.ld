SEARCH_DIR(.)
__DYNAMIC = 0;

MEMORY
{
    instrram   : ORIGIN = 0x00002000, LENGTH = 8192
    rom        : ORIGIN = 0x00004000,    LENGTH = 2048
    peripheral : ORIGIN = 0x00004800,   LENGTH = 2048
    dataram    : ORIGIN = 0x00005000,   LENGTH = 16384
}

_min_stack   = 0x2000;
_stack_len   = 8192;
_stack_start = ORIGIN(dataram) + LENGTH(dataram);

SECTIONS
{
    .text : { . = ALIGN(4); _stext = .; *(.text) _etext = .; } > instrram
    .rodata : { . = ALIGN(4); *(.rodata*) } > rom
    .data : { . = ALIGN(4); _sdata = .; *(.data*) _edata = .; } > dataram
    .bss : { . = ALIGN(4); _bss_start = .; *(.bss*) *(COMMON) _bss_end = .; } > dataram
    .stack (NOLOAD) : { . = ALIGN(4); . = . + _min_stack; _stack = .; } > dataram
    _end = .;
}
