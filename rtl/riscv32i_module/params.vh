`ifndef PARAMS_VH
`define PARAMS_VH

`define size_X_LEN             32
`define size_CSR_ENTRIES       4096
`define size_CSR_bit            12
`define pipe_len               512+64



`define size_PC_reg                `size_X_LEN
`define size_instruct              `size_X_LEN    
`define size_alu_res1              `size_X_LEN    
`define size_csr_write_en          1              
`define size_load_reg              1              
`define size_jump_en               1              
`define size_branch_en             1              
`define size_reg_write_en          1              
`define size_LD_ready              1              
`define size_SD_ready              1              
`define size_rd                    5              
`define size_operand_amt           4              
`define size_opRs1_reg             5              
`define size_opRs2_reg             5              
`define size_op1_reg               `size_X_LEN    
`define size_op2_reg               `size_X_LEN    
`define size_immediate             `size_X_LEN    
`define size_alu_res2              `size_X_LEN    
`define size_rd_data               `size_X_LEN    
`define size_Single_Instruction    64             
`define size_data_mem_loaded       `size_X_LEN    
`define size_csr_reg               12             
`define size_csr_reg_val           `size_X_LEN    
`define size_rst_bit               1              
`define size_Fp_opRs1_reg          5                
`define size_Fp_opRs2_reg          5  
`define size_Fp_rd                 5              
`define size_Fp_op1_reg            `size_X_LEN      
`define size_Fp_op2_reg            `size_X_LEN      
`define size_Fp_rd_data            `size_X_LEN     
`define size_Fp_fmt                3     


`define PC_reg_end          `size_PC_reg
`define PC_reg              `size_PC_reg-1:0

`define instruct_end        `size_instruct      + `PC_reg_end   
`define instruct            (`instruct_end-1)   : `PC_reg_end

`define alu_res1_end        `size_alu_res1   + `instruct_end
`define alu_res1            `alu_res1_end -1 : `instruct_end

`define csr_write_en_end    `alu_res1_end       +`size_csr_write_en
`define csr_write_en        `csr_write_en_end   -1

`define load_reg_end        `csr_write_en_end + `size_load_reg
`define load_reg            `load_reg_end -1            

`define jump_en_end        `load_reg_end + `size_jump_en
`define jump_en            `jump_en_end -1            

`define branch_en_end      `jump_en_end + `size_branch_en
`define branch_en          `branch_en_end -1            

`define reg_write_en_end    `branch_en_end + `size_reg_write_en
`define reg_write_en        `reg_write_en_end -1        
    
`define LD_ready_end        `reg_write_en_end +  `size_LD_ready
`define LD_ready            `LD_ready_end - 1

`define SD_ready_end        `LD_ready_end + `size_SD_ready
`define SD_ready            `SD_ready_end-1    

`define rd_end              `SD_ready_end   + `size_rd
`define rd                  `rd_end -1 : `SD_ready_end

`define operand_amt_end     `size_operand_amt  +`rd_end     
`define operand_amt         `operand_amt_end -1:`rd_end

`define opRs1_reg_end       `size_opRs1_reg +`operand_amt_end    
`define opRs1_reg           `opRs1_reg_end-1:`operand_amt_end

`define opRs2_reg_end       `size_opRs2_reg +`opRs1_reg_end    
`define opRs2_reg           `opRs2_reg_end-1:`opRs1_reg_end

`define op1_reg_end         `size_op1_reg + `opRs2_reg_end            
`define op1_reg             `op1_reg_end-1 :`opRs2_reg_end
`define op2_reg_end               `size_op2_reg + `op1_reg_end          
`define op2_reg                   `op2_reg_end-1: `op1_reg_end 

`define immediate_end            (`size_immediate + `op2_reg_end)
`define immediate                (`immediate_end-1):`op2_reg_end
`define alu_res2_end             (`size_alu_res2 + `immediate_end)
`define alu_res2                 (`alu_res2_end-1):`immediate_end
`define rd_data_end              (`size_rd_data + `alu_res2_end)
`define rd_data                  (`rd_data_end-1):`alu_res2_end
`define Single_Instruction_end   (`size_Single_Instruction + `rd_data_end)
`define Single_Instruction       (`Single_Instruction_end-1):`rd_data_end
`define data_mem_loaded_end      (`size_data_mem_loaded + `Single_Instruction_end)
`define data_mem_loaded          (`data_mem_loaded_end-1):`Single_Instruction_end
`define csr_reg_end              (`size_csr_reg + `data_mem_loaded_end)
`define csr_reg                  (`csr_reg_end-1):`data_mem_loaded_end
`define csr_reg_val_end          (`size_csr_reg_val + `csr_reg_end)
`define csr_reg_val              (`csr_reg_val_end-1):`csr_reg_end

`define rst_bit_end          (`size_rst_bit+`csr_reg_val_end)
`define rst_bit               `rst_bit_end-1
// `define rst_bit              (`rst_bit_end-1):`csr_reg_val_end

`define Fp_opRs1_reg_end       `size_Fp_opRs1_reg      +`rst_bit_end    
`define Fp_opRs1_reg                `Fp_opRs1_reg_end-1:`rst_bit_end
`define Fp_opRs2_reg_end       `size_Fp_opRs2_reg      +`Fp_opRs1_reg_end    
`define Fp_opRs2_reg                `Fp_opRs2_reg_end-1:`Fp_opRs1_reg_end
`define Fp_op1_reg_end         `size_Fp_op1_reg +       `Fp_opRs2_reg_end            
`define Fp_op1_reg                  `Fp_op1_reg_end-1 : `Fp_opRs2_reg_end
`define Fp_op2_reg_end         `size_Fp_op2_reg +       `Fp_op1_reg_end          
`define Fp_op2_reg                  `Fp_op2_reg_end-1:  `Fp_op1_reg_end 
`define Fp_fmt_end             `size_Fp_fmt +           `Fp_op2_reg_end          
`define Fp_fmt                      `Fp_fmt_end-1:      `Fp_op2_reg_end 

`define Fp_rd_data_end          `size_Fp_rd_data +       `Fp_fmt_end          
`define Fp_rd_data                   `Fp_rd_data_end-1:  `Fp_fmt_end 

`define Fp_rd_end               `size_Fp_rd +       `Fp_rd_data_end          
`define Fp_rd                        `Fp_rd_end-1:  `Fp_rd_data_end 





// `define immediate          223:192 //[31:0]
// `define alu_res2           255:224 //[31:0]
// `define rd_data            287:256 //[31:0]
// `define Single_Instruction 351:288 //[63:00]   
// `define data_mem_loaded    383:352  
// `define csr_reg            395:384 //[11:0]
// `define csr_reg_val        427:396 //[31:0]
// `define PC_reg              31:00   //[31:00]
// `define instruct            63:32   //[31:00]
// `define alu_res1            95:64   //[31:00]

// `define csr_write_en        96
// `define load_reg           101
// `define jump_en            102     //[ 4:0]
// `define branch_en          103     //[ 4:0]
// `define reg_write_en       104     //[ 4:0]
// `define LD_ready           105     //[ 4:0]
// `define SD_ready           106     //[ 4:0]
 

// `define immediate          223:192 //[31:0]
// `define alu_res2           255:224 //[31:0]
// `define rd_data            287:256 //[31:0]
// `define Single_Instruction 351:288 //[63:00]   
// `define data_mem_loaded    383:352  
// `define csr_reg            395:384 //[11:0]
// `define csr_reg_val        427:396 //[31:0]


// Opcode Decoding Type
`define R_Type            7'b0110011 //0110011
`define I_Type_A          7'b0010011 // 0010011
`define I_Type_L          7'b0000011
`define S_Type            7'b0100011
`define B_Type            7'b1100011
`define J_Type_lk         7'b1101111
`define I_Type_JALR       7'b1100111
`define U_Type_lui        7'b0110111
`define U_Type_auipc      7'b0010111
`define I_Type_ECALL      7'b1110011
`define F_TYPE_FENCE      7'b0001111


// FLOATING TYPES
`define FP_load           7'b0000111
`define FP_store          7'b0100111
// `define FP_convt          7'b1010011

`define FP_TYPE           7'b1010011 
// fadd.s    fsub.s   fmul.s fdiv.s fsqrt.s 
// fsgnj.s fsgnjn.s fsgnjx.s fmin.s  fmax.s 
// fcvt.wu.s fmv.x.w   feq.s  flt.s   fle.s 
//  fclass.s fcvt.s   fcvr.s.wu fmv.w.x
// 

`define FP_convt          7'b1010101 //fcvt.w.s 

`define FP_madd           7'b1000011
`define FP_msub           7'b1000111
`define FP_nmsub          7'b1001011
`define FP_nmadd          7'b1001111

`define FP_nmadd          7'b1001111
`define NOOP             32'h00000013


`define ONE_OP      4'b0001
`define TWO_OP      4'b0010

// Encoding Type
`define INST_typ_R             7'b0000001
`define INST_typ_I             7'b0000010
`define INST_typ_I_ECALL       7'b1000010
`define INST_typ_S             7'b0000100
`define INST_typ_B             7'b0001000
`define INST_typ_U             7'b0010000
`define INST_typ_J             7'b0100000
`define INST_typ_F             7'b1000000
`define UNRECGONIZED           7'b0000000

// Instructions
`define inst_UNKNOWN    64'h0000_0000_0000_0000
`define inst_ADD        64'h0000_0000_0000_0001
`define inst_SUB        64'h0000_0000_0000_0002
`define inst_XOR        64'h0000_0000_0000_0004
`define inst_OR         64'h0000_0000_0000_0008

`define inst_AND        64'h0000_0000_0000_0010
`define inst_SLL        64'h0000_0000_0000_0020
`define inst_SRL        64'h0000_0000_0000_0040
`define inst_SRA        64'h0000_0000_0000_0080

`define inst_SLT        64'h0000_0000_0000_0100
`define inst_SLTU       64'h0000_0000_0000_0200
`define inst_ADDI       64'h0000_0000_0000_0400
`define inst_XORI       64'h0000_0000_0000_0800

`define inst_ORI        64'h0000_0000_0000_1000
`define inst_ANDI       64'h0000_0000_0000_2000
`define inst_SLLI       64'h0000_0000_0000_4000
`define inst_SRLI       64'h0000_0000_0000_8000

`define inst_SRAI       64'h0000_0000_0001_0000
`define inst_SLTI       64'h0000_0000_0002_0000
`define inst_SLTIU      64'h0000_0000_0004_0000
`define inst_LB         64'h0000_0000_0008_0000

`define inst_LH         64'h0000_0000_0010_0000
`define inst_LW         64'h0000_0000_0020_0000
`define inst_LBU        64'h0000_0000_0040_0000
`define inst_LHU        64'h0000_0000_0080_0000

`define inst_SB         64'h0000_0000_0100_0000
`define inst_SH         64'h0000_0000_0200_0000
`define inst_SW         64'h0000_0000_0400_0000
`define inst_BEQ        64'h0000_0000_0800_0000

`define inst_BNE        64'h0000_0000_1000_0000
`define inst_BLT        64'h0000_0000_2000_0000
`define inst_BGE        64'h0000_0000_4000_0000
`define inst_BLTU       64'h0000_0000_8000_0000

`define inst_BGEU       64'h0000_0001_0000_0000
`define inst_JAL        64'h0000_0002_0000_0000
`define inst_JALR       64'h0000_0004_0000_0000
`define inst_LUI        64'h0000_0008_0000_0000

`define inst_AUIPC      64'h0000_0010_0000_0000
`define inst_ECALL      64'h0000_0020_0000_0000
`define inst_EBREAK     64'h0000_0040_0000_0000
`define inst_FENCE      64'h0000_0080_0000_0000

`define inst_FENCEI     64'h0000_0100_0000_0000
`define inst_CSRRW      64'h0000_0200_0000_0000
`define inst_CSRRS      64'h0000_0400_0000_0000
`define inst_CSRRC      64'h0000_0800_0000_0000
`define inst_CSRRWI     64'h0000_1000_0000_0000
`define inst_CSRRSI     64'h0000_2000_0000_0000
`define inst_CSRRCI     64'h0000_4000_0000_0000


`define inst_MRET       64'h0000_8000_0000_0000
`define inst_SRET       64'h0001_0000_0000_0000
`define inst_WFI        64'h0002_0000_0000_0000


`define inst_MUL        64'h0004_0000_0000_0000 //  mul  
`define inst_MULH       64'h0008_0000_0000_0000 //  mulh 
`define inst_MULSU      64'h0010_0000_0000_0000 //  mulsu
`define inst_MULU       64'h0020_0000_0000_0000 //  mulu 
`define inst_DIV        64'h0040_0000_0000_0000 //  div  
`define inst_DIVU       64'h0080_0000_0000_0000 //  divu 
`define inst_REM        64'h0100_0000_0000_0000 //  rem  
`define inst_REMU       64'h0200_0000_0000_0000 //  remu 
`define inst_FSW        64'h0400_0000_0000_0000 //  FP ST 
`define inst_FLW        64'h0800_0000_0000_0000 //  FP LW




`define CSR_MSTATUS 12'h300  
// Machine Status Register (mstatus)
`define CSR_MIE     12'h304  
// Machine Interrupt-Enable (mie)
`define CSR_MTVEC   12'h305  
// Machine Trap-Vector Base Address (mtvec)
`define CSR_MSCRATCH 12'h340 
`define CSR_MEPC    12'h341  
// Machine Exception Program Counter (mepc)
`define CSR_MCAUSE  12'h342  
// Machine Cause Register (mcause)
`define CSR_MTVAL   12'h343  
// Machine Trap Value (mtval)
`define CSR_MIP     12'h344  
// Machine Interrupt-Pending (mip)



`endif

















