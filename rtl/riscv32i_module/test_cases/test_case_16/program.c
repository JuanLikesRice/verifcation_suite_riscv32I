#include "constants.h"

int main(void) {
    // In ILP32, long is 32 bits.
    // Use a fixed memory address (adjust as appropriate for your system).
    volatile long *mem_ptr = (volatile long *) DATARAM_ORIGIN;
    
    // Test value: 0xDEADBEEF
    long test_val = 0xDEADBEEF;
    
    // Store the long value to memory.
    *mem_ptr = test_val;
    
    // Load the long value from memory.
    long loaded_val = *mem_ptr;
    
    // Check if the loaded value matches the expected test value.
    if (loaded_val != test_val) {
        fail(1);
    }
    
    // If the test passes, signal success.
    write_mmio(PERIPHERAL_SUCCESS, 0xDEADBEEF);
    while (1);
    return 0;
}
