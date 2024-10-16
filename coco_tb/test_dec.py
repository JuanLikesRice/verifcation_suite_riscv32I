import cocotb
import random
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

async def cycle_counter(dut):
    while True:
        await RisingEdge(dut.hclk)
        dut.cycle_cnt.value = dut.cycle_cnt.value + 1

def ins_gen(itype, boundary=0):
    ins_name_list = []
    ins_list = []
    ins_pick = ''
    rs2 = ''
    rs1 = ''
    rd = ''
    imm = ''
    return_list = []
    if itype == 'R':
        # add,sll,slt,sltu,xor,srl,or,and,sub,sra
        opcode = 0b0110011
        funct7_all = [0b0000000, 0b0100000]
        funct3_all = [0b000,0b001,0b010,0b011,0b100,0b101,0b110,0b111]
        # boundary condition
        rs2 = random.randint(0, 31)
        rs1 = random.randint(0, 31)
        rd = random.randint(0, 31)
        # generating instruction list
        for funct3 in funct3_all:
            ins_temp = funct7_all[0] << 25 | rs2 << 20 | rs1 << 15 | funct3 << 12 | rd << 7 | opcode
            ins_list.append(ins_temp)
        # generating sub ins
        ins_temp = funct7_all[1] << 25 | rs2 << 20 | rs1 << 15 | 000 << 12 | rd << 7 | opcode
        ins_list.append(ins_temp)
        # generating sra ins
        ins_temp = funct7_all[1] << 25 | rs2 << 20 | rs1 << 15 | 101 << 12 | rd << 7 | opcode
        ins_list.append(ins_temp)
    elif itype == 'I':
        opcode = [0b0010011, 0b1100111, 0b0000011]
        imm = random.randint(-2048, 2047)
        rs1 = random.randint(0, 31)
        # addi, slti, sltiu, xori, ori, andi
        funct3_list1 = [0b000,0b010,0b011,0b100,0b110,0b111]
        # slli, srli, srai
        funct3_list2 = [0b001,0b101,0b101]
        # lb, lh, lw, lbu, lhu
        funct3_list3 = [0b000, 0b001, 0b010, 0b100, 0b101]
        # jalr
        funct3_list4 = [0b000]
        funct3_all = [funct3_list1, funct3_list2, funct3_list3, funct3_list4]
        rd = random.randint(0, 31)

        for i in range(0, len(funct3_all)):
            for funct3 in funct3_all[i]:
                ins_temp = imm << 20 | rs1 << 15 | funct3 << 12 | rd << 7 | opcode[i]
                ins_list.append(ins_temp)
        # for slli, srli, srai
        ins_list[6] = (ins_list[8] & (2 ** 25 - 1))
        ins_list[7] = (ins_list[8] & (2 ** 25 - 1))
        ins_list[8] = ((ins_list[8] & (2 ** 25 - 1)) | 0b0100000 << 25)
    elif itype == 'S':
        # sb,sh,sw
        opcode = 0b0100011
        imm = random.randint(-2048, 2047)
        imm11_5 = imm & (2**12-1 - (2**5-1))
        imm4_0 = imm & (2**5-1)
        rs2 = random.randint(0, 31)
        rs1 = random.randint(0, 31)
        funct3_all = [0b000, 0b001, 0b010]
        for funct3 in funct3_all:
            ins_temp = imm11_5 << 25 | rs2 << 20 | rs1 << 15 | funct3 << 12 | imm4_0<<7 | opcode
            ins_list.append(ins_temp)
    elif itype == 'B':
        # beq,bne,blt,bge,bltu,bgeu
        opcode = 0b1100011
        imm = random.randint(-2048, 2047)
        imm12 = imm & (2 ** 13)
        imm11 = imm & (2 ** 12)
        imm10_5 = imm & (2 ** 11 - 1 - (2 ** 5 - 1))
        imm4_1 = imm & (2 ** 5 - 1 - (2 ** 1 - 1))
        rs2 = random.randint(0, 31)
        rs1 = random.randint(0, 31)
        funct3_all = [0b000, 0b001, 0b100, 0b101, 0b110, 0b111]
        for funct3 in funct3_all:
            ins_temp = (imm12|imm10_5) << 25 | rs2 << 20 | rs1 << 15 | funct3 << 12 | (imm4_1|imm11)<<7 | opcode
            ins_list.append(ins_temp)
    elif itype == 'U':
        # auipc, lui
        opcode = [0b0010111, 0b0110111]
        rd = random.randint(0, 31)
        imm = random.randint(-524288, 524287)
        for unit in opcode:
            ins_temp = imm << 12 | rd << 7 | unit
            ins_list.append(ins_temp)
        pass
    elif itype == 'J':
        # jal
        opcode = 0b1101111
        imm20 = random.randint(0, 1)
        imm10_1 = random.randint(-512, 511)
        imm11 = random.randint(0, 1)
        imm19_12 = random.randint(-128, 127)
        rd = random.randint(0, 31)
        ins_temp = (imm20|imm10_1|imm11|imm19_12)  | rd << 7 | opcode
        ins_list.append(ins_temp)
    elif itype == 'M':
        # fence,fence.i
        opcode = 0b0001111
        pred = random.randint(0, 15)
        succ = random.randint(0, 15)
        #fence
        ins_temp = 0b0000<<28 | pred<<24 | succ<<20 | opcode
        ins_list.append(ins_temp)
        #fence.i
        ins_list.append(0b00000000000000000001000000001111)
        pass
    elif itype == 'P':
        # ecall,ebreak,csrrw,csrrs,csrrc,csrrwi,csrrsi,csrrci
        opcode = 0b1110011
        csr = random.randint(0, 4095)
        rs1 = random.randint(0, 31)
        rd  = random.randint(0, 31)
        funct3_all = [0b000, 0b001, 0b010, 0b011, 0b101, 0b110, 0b111]
        for funct3 in funct3_all:
            if funct3 == 0b000:
                # ecall
                ins_list.append(0b00000000000000000000000001110011)
                # ebreak
                ins_list.append(0b00000000000100000000000001110011)
            else:
                ins_temp = csr << 20 | rs1 << 15 | funct3 << 12 | rd << 7 | opcode
                ins_list.append(ins_temp)
    ins_pick =  ins_list[random.randint(0, len(ins_list)-1)]
    return_list.append(ins_pick)
    return_list.append(imm)
    return_list.append(rs2)
    return_list.append(rs1)
    return_list.append(rd)
    return return_list

# R type
@cocotb.test()
async def test_R(dut):
    clock = Clock(dut.hclk, 10, units="ns") # 100MHz clk signal
    cocotb.start_soon(clock.start())

    # sys reset
    dut.hrstn.value = 0
    await Timer(10, units="ns")
    dut.hrstn.value = 1

    # cycle_counter++
    dut.cycle_cnt.value = 0
    cocotb.start_soon(cycle_counter(dut))

    # Test R-Type Instruction
    INS = ins_gen('R')
    dut.inst_in.value = INS[0]
    await Timer(60, units="ns")
    assert dut.dec_rd.value  == INS[4], "dec_rd incorrect"
    assert dut.dec_rs1.value == INS[3], "dec_rs1 incorrect"
    assert dut.dec_rs2.value == INS[2], "dec_rs2 incorrect"

# I type
@cocotb.test()
async def test_addi(dut):
    clock = Clock(dut.hclk, 10, units="ns") # 100MHz
    cocotb.start_soon(clock.start())

    # reset
    dut.hrstn.value = 0
    await Timer(10, units="ns")
    dut.hrstn.value = 1

    # cycle_counter++
    dut.cycle_cnt.value = 0
    cocotb.start_soon(cycle_counter(dut))

    dut.inst_in.value = 0b00000000000100001000000010010011 # addi
    await Timer(60, units="ns")
    assert dut.dec_addi.value == 1, "dec_addi signal incorrect"
    assert dut.dec_imm_en.value == 1, "Immediate enable signal incorrect"
    assert dut.dec_rd.value == 1, "dec_rd incorrect"
    assert dut.dec_rs1.value == 1, "dec_rs1 incorrect"

# S type
@cocotb.test()
async def test_switch(dut):
    # 100MHz clk signal
    clock = Clock(dut.hclk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # reset signal
    dut.hrstn.value = 0
    await Timer(10, units="ns")
    dut.hrstn.value = 1

    # update cycle_counter
    dut.cycle_cnt.value = 0
    cocotb.start_soon(cycle_counter(dut))

    dut.inst_in.value = 0b00000000001100001010000000100011 # sw
    await Timer(60, units="ns")
    assert dut.dec_sw.value == 1, "dec_sw signal incorrect"
    # assert dut.dec_rs1.value == 1, "TEMP"
    # assert dut.dec_rs2.value == 1, "TEMP"
    # assert dut.dec_store_en.value == 1, "TEMP"

# B type
@cocotb.test()
async def test_beq(dut):
    # 100MHz clk signal
    clock = Clock(dut.hclk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # reset signal
    dut.hrstn.value = 0
    await Timer(10, units="ns")
    dut.hrstn.value = 1

    # update cycle_counter
    dut.cycle_cnt.value = 0
    cocotb.start_soon(cycle_counter(dut))

    dut.inst_in.value = 0b00000000000100001000000001100011 # beq
    await Timer(60, units="ns")
    assert dut.dec_beq.value == 1, "dec_sw signal incorrect"
    # assert dut.dec_rs1.value == 1, "TEMP"
    # assert dut.dec_rs2.value == 1, "TEMP"
    # assert dut.dec_store_en.value == 1, "TEMP"

# U type
@cocotb.test()
async def test_lui(dut):
    # 100MHz clk signal
    clock = Clock(dut.hclk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # reset signal
    dut.hrstn.value = 0
    await Timer(10, units="ns")
    dut.hrstn.value = 1

    # update cycle_counter
    dut.cycle_cnt.value = 0
    cocotb.start_soon(cycle_counter(dut))

    dut.inst_in.value = 0b00000000000000000001000010110111 # lui
    await Timer(60, units="ns")
    assert dut.dec_lui.value == 1, "dec_lui signal incorrect"
    # assert dut.dec_rs1.value == 1, "TEMP"
    # assert dut.dec_rs2.value == 1, "TEMP"
    # assert dut.dec_store_en.value == 1, "TEMP"

# J type
@cocotb.test()
async def test_jal(dut):
    # 100MHz clk signal
    clock = Clock(dut.hclk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # reset signal
    dut.hrstn.value = 0
    await Timer(10, units="ns")
    dut.hrstn.value = 1

    # update cycle_counter
    dut.cycle_cnt.value = 0
    cocotb.start_soon(cycle_counter(dut))

    dut.inst_in.value = 0b00000000000000000001000011101111 # jal
    await Timer(60, units="ns")
    assert dut.dec_jal.value == 1, "dec_jal signal incorrect"

# R & I type
@cocotb.test()
async def test_add_addi(dut):
    # 100MHz clk signal
    clock = Clock(dut.hclk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # reset signal
    dut.hrstn.value = 0
    await Timer(10, units="ns")
    dut.hrstn.value = 1

    # update cycle_counter
    dut.cycle_cnt.value = 0
    cocotb.start_soon(cycle_counter(dut))

    dut.inst_in.value = 0b00000000000100001000000110110011  # add
    await Timer(50, units="ns")
    assert dut.dec_add.value == 1, "dec_add signal incorrect"

    dut.inst_in.value = 0b00000000000100001000000010010011  # addi
    await Timer(100, units="ns")
    assert dut.dec_addi.value == 1, "dec_addi signal incorrect"
    assert dut.dec_imm_en.value == 1, "dec_imm_en signal incorrect"
    assert dut.dec_rd.value == 1, "dec_rd incorrect"
    assert dut.dec_rs1.value == 1, "dec_rs1 incorrect"

