    .section .text
    .globl _start

_start:
    # Initialize stack pointer (adjust address based on your memory map)
    la sp, _stack_top

    # Jump to main
    call main

    # Hang here
1:  j 1b

    .section .bss
    .globl _stack_top
    .space 1024  # Allocate 1KB stack space (adjust as necessary)
_stack_top:
