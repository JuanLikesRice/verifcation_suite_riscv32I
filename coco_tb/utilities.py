import random

def ins_gen(itype, boundary=0):
    ins_name_list = []
    ins_list = []
    ins_pick = ''
    rs2 = ''
    rs1 = ''
    rd = ''
    imm = ''
    return_list = []
    # # # # # # # # # #
    # generation part #
    # # # # # # # # # #
    if itype == 'R':
        # add,sll,slt,sltu,xor,srl,or,and,sub,sra
        opcode = 0b0110011
        funct7_all = [0b0000000, 0b0100000]
        funct3_all = [0b000,0b001,0b010,0b011,0b100,0b101,0b110,0b111]
        # boundary condition
        rs2 = random.randint(0, 2**5-1)
        rs1 = random.randint(0, 2**5-1)
        rd  = random.randint(0, 2**5-1)
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
        opcode = [0b0010011, 0b0000011, 0b1100111]
        imm = random.randint(0, 2**12-1)
        rs1 = random.randint(0, 2**5-1)
        # addi, slti, sltiu, xori, ori, andi
        funct3_list1 = [0b000,0b010,0b011,0b100,0b110,0b111]
        # slli, srli, srai
        funct3_list2 = [0b001,0b101,0b101]
        # lb, lh, lw, lbu, lhu
        funct3_list3 = [0b000, 0b001, 0b010, 0b100, 0b101]
        # jalr
        funct3_list4 = [0b000]
        funct3_all = [funct3_list1, funct3_list2, funct3_list3, funct3_list4]
        rd = random.randint(0, 2**5-1)

        for i in range(0, len(funct3_all)):
            for funct3 in funct3_all[i]:
                if i==0 or i ==1:
                    ins_temp = imm << 20 | rs1 << 15 | funct3 << 12 | rd << 7 | opcode[0]
                elif i==2:
                    ins_temp = imm << 20 | rs1 << 15 | funct3 << 12 | rd << 7 | opcode[1]
                elif i==3:
                    ins_temp = imm << 20 | rs1 << 15 | funct3 << 12 | rd << 7 | opcode[2]
                else:
                    assert("Error")
                ins_list.append(ins_temp)
        # for slli, srli, srai
        ins_list[6] = (ins_list[8] & (2 ** 25 - 1))
        ins_list[7] = (ins_list[8] & (2 ** 25 - 1))
        ins_list[8] = ((ins_list[8] & (2 ** 25 - 1)) | 0b0100000 << 25)
    elif itype == 'S':
        # sb,sh,sw
        opcode = 0b0100011
        imm = random.randint(0, 2**12-1)
        imm11_5 = imm & ((2**12-1 - (2**5-1))) >> 5
        imm4_0 = imm & (2**5-1)
        rs2 = random.randint(0, 2**5-1)
        rs1 = random.randint(0, 2**5-1)
        funct3_all = [0b000, 0b001, 0b010]
        for funct3 in funct3_all:
            print(imm11_5," ", rs2," ", rs1," ", funct3," ", imm4_0, " ",opcode)
            ins_temp = imm11_5 << 25 | rs2 << 20 | rs1 << 15 | funct3 << 12 | imm4_0<<7 | opcode
            print(ins_temp)
            print("\n\n")
            ins_list.append(ins_temp)
    elif itype == 'B':
        # beq,bne,blt,bge,bltu,bgeu
        opcode = 0b1100011
        imm = random.randint(0, 2**13-1)
        imm12 = imm & (2 ** 13)
        imm11 = imm & (2 ** 12)
        imm10_5 = imm & (2 ** 11 - 1 - (2 ** 5 - 1)) >> 5
        imm4_1 = imm & (2 ** 5 - 1 - (2 ** 1 - 1))  >> 1
        rs2 = random.randint(0, 2**5-1)
        rs1 = random.randint(0, 2**5-1)
        funct3_all = [0b000, 0b001, 0b100, 0b101, 0b110, 0b111]
        for funct3 in funct3_all:
            ins_temp = (imm12|imm10_5) << 25 | rs2 << 20 | rs1 << 15 | funct3 << 12 | (imm4_1|imm11)<<7 | opcode
            ins_list.append(ins_temp)
    elif itype == 'U':
        # auipc, lui
        opcode = [0b0010111, 0b0110111]
        rd = random.randint(0, 2**5-1)
        imm = random.randint(0, 2**20-1)
        for unit in opcode:
            ins_temp = imm << 12 | rd << 7 | unit
            ins_list.append(ins_temp)
        pass
    elif itype == 'J':
        # jal
        opcode = 0b1101111
        imm = random.randint(0, 2**20-1)
        imm20 = imm & (2**20)
        imm10_1 = imm & (2 ** 10 - 1 - (2 ** 1 - 1))  >> 1
        imm11 = imm & (2 ** 12 - 1)
        imm19_12 = imm & (2 ** 20 - 1 - (2 ** 12 - 1))  >> 12
        rd = random.randint(0, 2**5-1)
        ins_temp = (imm20|imm10_1|imm11|imm19_12) << 12 | rd << 7 | opcode
        ins_list.append(ins_temp)
    elif itype == 'M':
        # fence,fence.i
        opcode = 0b0001111
        pred = random.randint(0, 2**4-1)
        succ = random.randint(0, 2**4-1)
        #fence
        ins_temp = 0b0000<<28 | pred<<24 | succ<<20 | opcode
        ins_list.append(ins_temp)
        #fence.i
        ins_list.append(0b00000000000000000001000000001111)
        pass
    elif itype == 'P':
        # ecall,ebreak,csrrw,csrrs,csrrc,csrrwi,csrrsi,csrrci
        opcode = 0b1110011
        csr = random.randint(0, 2**12-1)
        rs1 = random.randint(0, 2**5-1)
        rd  = random.randint(0, 2**5-1)
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
    # # # # # # # #
    # return part #
    # # # # # # # #
    if itype == 'R':
        return_list.append(imm)
        return_list.append(rs2)
        return_list.append(rs1)
        return_list.append(rd)
    elif itype == 'I':
        return_list.append(imm)
        return_list.append(rs1)
        return_list.append(rd)
    elif itype == 'S':
        return_list.append(imm11_5)
        return_list.append(rs2)
        return_list.append(rs1)
        return_list.append(imm4_0)
    elif itype == 'B':
        return_list.append(imm12|imm10_5)
        return_list.append(rs2)
        return_list.append(rs1)
        return_list.append(imm4_1|imm11)
    elif itype == 'U':
        return_list.append(imm)
        return_list.append(rd)
    elif itype == 'J':
        return_list.append(imm20|imm10_1|imm11|imm19_12)
        return_list.append(rd)
    elif itype == 'M':
        pass
    elif itype == 'P':
        pass
    return return_list

# # # # # # #
# test part #
# # # # # # #
if __name__ == '__main__':
    INS = ins_gen('S')
