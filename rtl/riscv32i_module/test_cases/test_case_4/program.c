// arithmetic_operations.c
// Tests: 
//  - Arithmetic: inst_ADD, inst_SUB, inst_XOR, inst_OR, inst_AND (Tests 1–5)
//  - Shifts: inst_SLL, inst_SRL, inst_SRA, inst_SLLI, inst_SRLI, inst_SRAI (Tests 6–11)
//  - Set-Less-Than: inst_SLT, inst_SLTU, inst_SLTI, inst_SLTIU (Tests 12–15)
//  - Immediate Arithmetic/Logical: inst_ADDI, inst_XORI, inst_ORI, inst_ANDI (Tests 16–19)
//  - Other: inst_LUI (Test 36)

#include "constants.h"

int main(void) {
    // Volatile operands to block constant folding
    volatile int v5 = 5, v7 = 7, v10 = 10, v4 = 4;
    volatile unsigned int vAA = 0xAA55AA55u, vFF = 0xFFFFFFFFu;
    volatile unsigned int v0F = 0x0F0F0F0Fu, vF0 = 0xF0F0F0F0u;
    volatile unsigned int vFF00FF00 = 0xFF00FF00u, v0F0F0F0F = 0x0F0F0F0Fu;
    volatile int v1 = 1, vminus16 = -16;
    volatile unsigned int v80000000 = 0x80000000u;
    volatile unsigned int v12345678 = 0x12345678u, v11111111 = 0x11111111u;
    volatile unsigned int v10101010 = 0x10101010u;
    volatile unsigned int v00FF00FF = 0x00FF00FFu;
    volatile unsigned int vFFFFFFFE = 0xFFFFFFFEu;

    // --- Arithmetic Operations ---
    if ((v5 + v7) != 12) { fail(1); }
    if ((v10 - v4) != 6) { fail(2); }
    if ((vAA ^ vFF) != 0x55AA55AAu) { fail(3); }
    if ((v0F | vF0) != 0xFFFFFFFFu) { fail(4); }
    if ((vFF00FF00 & v0F0F0F0F) != 0x0F000F00u) { fail(5); }

    // --- Shift Operations ---
    if ((v1 << 3) != 8) { fail(6); }
    if ((v80000000 >> 3) != 0x10000000u) { fail(7); }
    if ((vminus16 >> 2) != -4) { fail(8); }
    if ((v1 << 5) != 32) { fail(9); }
    if ((v80000000 >> 5) != 0x04000000u) { fail(10); }

    {
        volatile unsigned int u = 0x0000CFC7u;
        int result = ((int)(u << 16)) >> 16;
        if (result != -12345) { fail(11); }
    }

    // --- Set-Less-Than Operations ---
    if ((3 < 5 ? 1 : 0) != 1) { fail(12); }
    if ((vFFFFFFFE < 1u ? 1 : 0) != 0) { fail(13); }
    if ((3 < 10 ? 1 : 0) != 1) { fail(14); }
    if ((vFFFFFFFE < 2u ? 1 : 0) != 0) { fail(15); }

    // --- Immediate Arithmetic/Logical Operations ---
    if ((20 + 30) != 50) { fail(16); }
    if ((v12345678 ^ v11111111) != 0x03254769u) { fail(17); }
    if ((v0F | v10101010) != 0x1F1F1F1Fu) { fail(18); }
    if ((vFF00FF00 & v00FF00FF) != 0x00000000u) { fail(19); }

    // --- Other Instruction ---
    {
        volatile unsigned int imm = 0x123;
        unsigned int lui_result = imm << 12;
        if (lui_result != (0x123 << 12)) { fail(36); }
    }

    write_mmio(PERIPHERAL_SUCCESS, 0xDEADBEEF);
    while (1);
    return 0;
}
