#include "constants.h"

int main(void) {
    // ----- SLT Test: Signed Less-Than -----
    // 0xFFFFFFFF as a signed integer is -1.
    // Compare -1 and 1: Expect SLT to yield 1.
    signed int a_signed = -1;   // equivalent to 0xFFFFFFFF in 32-bit two's complement.
    signed int b_signed = 1;
    int slt_result = (a_signed < b_signed) ? 1 : 0;
    if (slt_result != 1) {  // If SLT result is not 1, test fails.
        fail(1);
    }
    
    // ----- SLTU Test: Unsigned Less-Than -----
    // 0xFFFFFFFF as an unsigned integer is 4294967295.
    // Compare 4294967295 and 1: Expect SLTU to yield 0.
    unsigned int a_unsigned = 0xFFFFFFFF; // 4294967295
    unsigned int b_unsigned = 1;
    int sltu_result = (a_unsigned < b_unsigned) ? 1 : 0;
    if (sltu_result != 0) {  // If SLTU result is not 0, test fails.
        fail(2);
    }
    
    // Both tests passed; signal overall success.
    write_mmio(PERIPHERAL_S2, 0xDEADBEEF);
    // while (1);
    return 0;
}
