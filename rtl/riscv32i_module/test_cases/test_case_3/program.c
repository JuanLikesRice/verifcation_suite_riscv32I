
#include "constants.h"

int main(void) {
    // Use a signed short pointer to force LH (signed half-word load)
    volatile short *half_ptr = (volatile short *)PERIPHERAL_S2;
    
    // Store 0xDEAD into memory using a half-word store.
    *half_ptr = (short)0xDEAD;
    
    // Load the value using LH
    short loaded = *half_ptr;
    
    // Check if the loaded half-word is as expected.
    if (loaded == (short)0xDEAD) {
        write_mmio(PERIPHERAL_S3,     0xDEADBEEF);
    } else {
        write_mmio(PERIPHERAL_SUCCESS, 0xBADF00D);
    }
    return 0;
}
