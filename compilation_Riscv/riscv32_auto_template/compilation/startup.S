.global _start

.section .text
_start:
    la sp, _stack_top    # Load the stack pointer address into `sp`
    call main            # Call the main function
    j _start             # Infinite loop after the main function returns

.section .data          # Use .data for initialized data
_stack_top:
    .word 0x00020000     # Define the top of the stack (adjust as needed)
