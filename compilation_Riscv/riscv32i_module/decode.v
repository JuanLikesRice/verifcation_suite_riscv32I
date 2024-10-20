module decode 
   # (
    parameter   N_param = 32   ) (
    input  wire i_clk,
    input  wire i_en,
    input  wire [N_param-1:0]  instruction,


    // 
    // outputs to register file
    output wire  [4:0] rd_o,
    output wire  [4:0] rs1_o,
    output wire  [4:0] rs2_o,
    output wire  [2:0] fun3_o,
    output wire  [6:0] fun7_o,
    output wire [31:0] imm_o,
    output wire [6:0] INST_typ_o,
    output wire [6:0] opcode_o
    // outputs to ALU
);

// Opcode Decoding Type
localparam [6:0] R_Type         =   7'b0110011; //0110011
localparam [6:0] I_Type_A       =   7'b0010011; // 0010011
localparam [6:0] I_Type_L       =   7'b0000011;
localparam [6:0] S_Type         =   7'b0100011;
localparam [6:0] B_Type         =   7'b1100011;
localparam [6:0] J_Type_lk      =   7'b1101111;
localparam [6:0] I_Type_lr      =   7'b1100111;
localparam [6:0] U_Type_lui     =   7'b0110111;
localparam [6:0] U_Type_auipc   =   7'b0010111;
localparam [6:0] I_Type_ECALL   =   7'b1110011;
localparam [31:0] NOOP        =   32'h00000013;
// Encoding Type
localparam [6:0] INST_typ_R =   7'b0000001;
localparam [6:0] INST_typ_I =   7'b0000010;
localparam [6:0] INST_typ_S =   7'b0000100;
localparam [6:0] INST_typ_B =   7'b0001000;
localparam [6:0] INST_typ_U =   7'b0010000;
localparam [6:0] INST_typ_J =   7'b0100000;
localparam [6:0] UNRECGONIZED=  7'b0000000;

// Instructions
localparam [63:0] inst_ADD   = 64'h0000_0000_0000_0001;
localparam [63:0] inst_SUB   = 64'h0000_0000_0000_0002;
localparam [63:0] inst_XOR   = 64'h0000_0000_0000_0004;
localparam [63:0] inst_OR    = 64'h0000_0000_0000_0008;

localparam [63:0] inst_AND   = 64'h0000_0000_0000_0010;
localparam [63:0] inst_SLL   = 64'h0000_0000_0000_0020;
localparam [63:0] inst_SRL   = 64'h0000_0000_0000_0040;
localparam [63:0] inst_SRA   = 64'h0000_0000_0000_0080;

localparam [63:0] inst_SLT   = 64'h0000_0000_0000_0100;
localparam [63:0] inst_SLTU  = 64'h0000_0000_0000_0200;
localparam [63:0] inst_ADDI  = 64'h0000_0000_0000_0400;
localparam [63:0] inst_XORI  = 64'h0000_0000_0000_0800;

localparam [63:0] inst_ORI   = 64'h0000_0000_0000_1000;
localparam [63:0] inst_ANDI  = 64'h0000_0000_0000_2000;
localparam [63:0] inst_SLLI  = 64'h0000_0000_0000_4000;
localparam [63:0] inst_SRLI  = 64'h0000_0000_0000_8000;

localparam [63:0] inst_SRAI  = 64'h0000_0000_0001_0000;
localparam [63:0] inst_SLTI  = 64'h0000_0000_0002_0000;
localparam [63:0] inst_SLTIU = 64'h0000_0000_0004_0000;
localparam [63:0] inst_LB    = 64'h0000_0000_0008_0000;

localparam [63:0] inst_LH    = 64'h0000_0000_0010_0000;
localparam [63:0] inst_LW    = 64'h0000_0000_0020_0000;
localparam [63:0] inst_LBU   = 64'h0000_0000_0040_0000;
localparam [63:0] inst_LHU   = 64'h0000_0000_0080_0000;

localparam [63:0] inst_SB    = 64'h0000_0000_0100_0000;
localparam [63:0] inst_SH    = 64'h0000_0000_0200_0000;
localparam [63:0] inst_SW    = 64'h0000_0000_0400_0000;
localparam [63:0] inst_BEQ   = 64'h0000_0000_0800_0000;

localparam [63:0] inst_BNE   = 64'h0000_0000_1000_0000;
localparam [63:0] inst_BLT   = 64'h0000_0000_2000_0000;
localparam [63:0] inst_BGE   = 64'h0000_0000_4000_0000;
localparam [63:0] inst_BLTU  = 64'h0000_0000_8000_0000;

localparam [63:0] inst_BGEU  = 64'h0000_0001_0000_0000;
localparam [63:0] inst_JAL   = 64'h0000_0002_0000_0000;
localparam [63:0] inst_JALR  = 64'h0000_0004_0000_0000;
localparam [63:0] inst_LUI   = 64'h0000_0008_0000_0000;

localparam [63:0] inst_AUIPC = 64'h0000_0010_0000_0000;
localparam [63:0] inst_ECALL = 64'h0000_0020_0000_0000;
localparam [63:0] inst_EBREAK= 64'h0000_0040_0000_0000;


// assign rd_o   = rd;
// assign fun3_o = fun3;
// assign fun7_o = fun7;
// assign rs1_o  = rs1;
// assign rs2_o  = rs2;
// assign imm_o  = imm;
// assign INST_typ_o = INST_typ;




wire [6:0] opcode;
reg  [31:0] imm;
reg  [6:0] INST_typ;
reg  [2:0] fun3;
reg  [6:0] fun7;
reg  [4:0] rd,rs1,rs2;
//FPGA 
initial begin 
    imm     <=0;
    INST_typ<=0;
    fun3    <=0;
    fun7    <=0;
    rd      <=0;
    rs1     <=0;
    rs2     <=0;
end


assign opcode = instruction[6:0];
assign opcode_o = instruction[6:0];

always @(*) begin
    case (opcode)
        R_Type: begin
            INST_typ <= INST_typ_R;
            rd     <= instruction[11:7];
            fun3   <= instruction[14:12];
            rs1    <= instruction[19:15];
            rs2    <= instruction[24:20];
            fun7   <= instruction[31:25];
            imm    <= 32'b0;
        end

        I_Type_A,I_Type_L, I_Type_lr,I_Type_ECALL: begin  
            INST_typ <= INST_typ_I;
            rd     <= instruction[11:7];
            fun3   <= instruction[14:12];
            rs1    <= instruction[19:15];
            rs2    <= 0;
            fun7   <= instruction[31:25];
            imm    <= {{20{instruction[31]}},instruction[31:20]};
        end

        S_Type: begin  
            INST_typ <= INST_typ_S;
            rd     <= 0;
            fun3   <= instruction[14:12];
            rs1    <= instruction[19:15];
            rs2    <= instruction[24:20];
            fun7   <= 0;
            imm    <= {{20{instruction[31]}},instruction[31:25],instruction[11:7]};
        end

        B_Type: begin  
            INST_typ <= INST_typ_B;
            rd     <= 0;
            fun3   <= instruction[14:12];
            rs1    <= instruction[19:15];
            rs2    <= instruction[24:20];
            fun7   <= 0;
            imm    <= { {20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0 }; // {{19{i_inst[31]}},i_inst[31],i_inst[7],i_inst[30:25],i_inst[11:8],1'b0} 
        end

        U_Type_auipc, U_Type_lui: begin  
            INST_typ <= INST_typ_U;
            rd       <= instruction[11:7];
            fun3     <= 0;
            rs1      <= 0;
            rs2      <= 0;
            fun7     <= 0;
            imm      <= { instruction[31:12], 12'b0};     
        end

       J_Type_lk: begin  
            INST_typ <= INST_typ_J;
            rd     <= instruction[11:7];
            fun3   <= 0; 
            rs1    <= 0; 
            rs2    <= 0; 
            fun7   <= 0; 
            imm    <= { {12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:25], instruction[24:21], 1'b0 };
        end

        default: begin
            INST_typ <= UNRECGONIZED;
            rd     <= 0;
            fun3   <= 0;
            rs1    <= 0; 
            rs2    <= 0; 
            fun7   <= 0; 
            imm    <= 0;
        end
    endcase

    // case (INST_typ)

    //     INST_typ_R: begin
    //         case ({fun3,fun7})

    //         {3'b000,7'b0000000}: begin  // ADDI
    //         Single_Instruction <= inst_ADD;
    //         end 
            
            
    //         endcase


    //     end

    //     INST_typ_I: begin
        
    //     end
        
    //     INST_typ_S: begin  

    //     end

    //     INST_typ_B: begin  

    //     end

    //     INST_typ_J: begin  

    //     end


    //     UNRECGONIZED: begin  

    //     end

    //     default: begin

    //     end
    
    // endcase

    
end


assign rd_o   = rd;
assign fun3_o = fun3;
assign fun7_o = fun7;
assign rs1_o  = rs1;
assign rs2_o  = rs2;
assign imm_o  = imm;
assign INST_typ_o = INST_typ;
// assign opcode_o = opcode;


endmodule









  

