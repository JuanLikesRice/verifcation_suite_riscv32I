    .global _start                 # Entry point
    .section .text
    .align 2
_start:
    la sp, _stack_start            # set stack pointer (symbol from link.ld)
    call runtime_init              # jump into runtime init in C
    j _start                       # safety loop if runtime_init ever returns
