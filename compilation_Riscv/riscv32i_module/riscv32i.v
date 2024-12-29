`define PC_reg             31:00   //[31:00]
`define instruct           63:32   //[31:00]
// `define write_reg_en_reg   64      //[1]
// `define control_reg        69:65   //[04:00]
// `define dest_reg           74:70   //[04:00]
// `define opcode_reg         80:75   //[05:00]

// `define alu_res_reg        176:145 //[31:00]
// `define data_mem_reg       208:177 //[31:00]
// `define ins_reg            240:209 //[31:00]
// `define halt_reg           241     //[1]



`define rd                  87:83 //[ 4:0]
`define fun3                90:88 //[ 2:0]
`define fun7                97:91 //[ 6:0]
`define INST_typ           104:98 //[ 6:0]
`define opcode             111:105 //[ 6:0]
`define operand_amt        115:112 //[ 3:0]
`define opRs1_reg          120:116 //[4:0]
`define opRs2_reg          127:121 //[4:0]
`define op1_reg            159:128 //[31:00]
`define op2_reg            191:160 //[31:00]
`define immediate          223:192 //[31:0]
`define Single_Instruction 287:224 //[63:00]     


module riscv32i 
   # (
    parameter   N_param = 32
   ) (
    input  wire clk,
    input  wire reset
    // input  wire en
);

    // wire i_clk;
    // wire i_en;
    wire  [N_param-1:0]  instruction;
    wire  [4:0] rd_o;
    wire  [4:0] rs1_o;
    wire  [4:0] rs2_o;
    wire  [2:0] fun3_o;
    wire  [6:0] fun7_o;
    wire  [31:0] imm_o;
    wire  [6:0] INST_typ_o, opcode_o;
    wire  [63:0] Single_Instruction_o;
    wire  i_en;

    // param_module params ();

    reg halt_i, isTakenBranch_i;
    reg [31:0] targetPC_i;

    reg [287:0] pipeReg0, pipeReg1, pipeReg2, pipeReg3;

    //branch_taken

    wire branch_taken;
    assign branch_taken = 0;

initial begin 
    halt_i          <= 0;
    targetPC_i      <= 0;
    isTakenBranch_i <= 0; 
end

    pc pc  (
        .clk_i(clk),
        .reset_i(reset),
        .halt_i(halt_i),
        .isTakenBranch_i(isTakenBranch_i),
        .targetPC_i(targetPC_i),
        .pc_o(pc_i)
    );
    ins_mem ins_mem(
        .clk(clk),
        .reset(reset),
        .pc_i(pc_i),
        .pc_o(pc_o),
        .instruction_o(instruction)
    );

// Pre Stage 0
    wire [31:0] pc_stage_0,instruction_stage_0;
    wire we_pi;
    wire [31:0] pc_o,pc_i;
    wire [31:0] writeData_pi,operand1_po,operand2_po;

    assign we_pi = 0;
    assign pc_stage_0          = pipeReg0[`PC_reg];
    assign instruction_stage_0 = pipeReg0[`instruct];

wire [31:0] pc_stage_1;
wire [31:0] instruction_stage_1;

wire [ 4:0] rd_stage1;
wire [ 2:0] fun3_stage1;
wire [ 6:0] fun7_stage1;
wire [ 6:0] INST_typ_stage1;
wire [ 6:0] opcode_stage1;
wire [ 4:0] rs1_stage1;
wire [ 4:0] rs2_stage1;
wire [31:0] operand1_stage1;
wire [31:0] operand2_stage1;
wire [31:0] imm_stage1;
wire [63:0] Single_Instruction_stage1;


    decode #(.N_param(N_param)) decode_debug
    (
   .i_clk(clk),
   .i_en(i_en),
   .instruction(instruction_stage_0),
   .rd_o(rd_o),
   .rs1_o(rs1_o),
   .rs2_o(rs2_o),
   .fun3_o(fun3_o),
   .fun7_o(fun7_o),
   .imm_o(imm_o),
   .INST_typ_o(INST_typ_o),
   .opcode_o(opcode_o),
   .Single_Instruction_o(Single_Instruction_o)
   );


 reg_file reg_file(
.clk(clk),
.reset(reset), 
.reg1_pi(rs1_o), 
.reg2_pi(rs2_o), 
.destReg_pi(rd_o), 
.we_pi(we_pi), 
.writeData_pi(writeData_pi), 
.operand1_po(operand1_po),
.operand2_po(operand2_po)
);

execute  #(.N_param(32)) execute 
    (.i_clk(clk),    
     .Single_Instruction_i(Single_Instruction_stage1),
     .operand1_pi(operand1_stage1),
     .operand2_pi(operand2_stage1),
     .instruction(instruction_stage_1),
     .pc_i(pc_stage_1),
     .rd_i(rd_stage1),
     .rs1_i(rs1_stage1), 
     .rs2_i(rs2_stage1), 
     .imm_i(imm_stage1)
   );

assign pc_stage_1 =                 pipeReg1[`PC_reg];
assign instruction_stage_1 =        pipeReg1[`instruct];
assign rd_stage1 =                  pipeReg1[`rd];
assign fun3_stage1 =                pipeReg1[`fun3];
assign fun7_stage1 =                pipeReg1[`fun7];
assign INST_typ_stage1 =            pipeReg1[`INST_typ];
assign opcode_stage1 =              pipeReg1[`opcode];
assign rs1_stage1 =                 pipeReg1[`opRs1_reg];
assign rs2_stage1 =                 pipeReg1[`opRs2_reg];
assign operand1_stage1 =            pipeReg1[`op1_reg];
assign operand2_stage1 =            pipeReg1[`op2_reg];
assign imm_stage1 =                 pipeReg1[`immediate];
assign Single_Instruction_stage1 =  pipeReg1[`Single_Instruction];


always @(posedge clk)begin
if (reset) begin 
    pipeReg0 <= 288'b0;
    pipeReg1 <= 288'b0;
    pipeReg2 <= 288'b0;
	pipeReg3 <= 288'b0;
end else if (branch_taken) begin 
    pipeReg1 <= 288'b0;
    pipeReg2 <= 288'b0;
	pipeReg3 <= 288'b0;
end
else begin

    // stage 0 --> //
    pipeReg0[`PC_reg]   <= pc_i;
    pipeReg0[`instruct] <= instruction;
    // <-- stage 0 //

    // stage 1 --> //
    pipeReg1[`PC_reg]             <= pc_stage_0;
    pipeReg1[`instruct]           <= instruction_stage_0;
    pipeReg1[`rd                ] <= rd_o;//  87:83 //[ 4:0]
    pipeReg1[`fun3              ] <= fun3_o;//  90:88 //[ 2:0]
    pipeReg1[`fun7              ] <= fun7_o;//  97:91 //[ 6:0]
    pipeReg1[`INST_typ          ] <= INST_typ_o;// 104:98 //[ 6:0]
    pipeReg1[`opcode            ] <= opcode_o;// 111:105 //[ 6:0]
    pipeReg1[`opRs1_reg         ] <= rs1_o;// 120:116 //[4:0]
    pipeReg1[`opRs2_reg         ] <= rs2_o;// 127:121 //[4:0]
    pipeReg1[`op1_reg           ] <= operand1_po;// 159:128 //[31:00]
    pipeReg1[`op2_reg           ] <= operand2_po;// 191:160 //[31:00]
    pipeReg1[`immediate         ] <= imm_o;// 223:192 //[31:0]
    pipeReg1[`Single_Instruction] <= Single_Instruction_o;// 287:224 //[63:00]     
    




    // pipeReg1[`operand_amt       ] <= ;// 115:112 //[ 3:0]
    
    // <-- stage 1 //



end 
end



// $display("PC: %h, Instruction: %h, word in processor %h", pc, instruction,pc >> 2);

//  always @(negedge clk) begin : checker
//             // $display("%t:   INST_typ_o:{%h},   fun3_o:{%h}, fun7_o:{%h},  opcode_o:{%h},   Sing_Instru:{%h},   insturction_in:{%h}    ",
//             // $time,          INST_typ_o,        fun3_o,      fun7_o,     opcode_o,Single_Instruction_o   , instruction_o    
//             // );
//             // $write("\n %t: ERR:{%b} fun3:{%h}, fun7:{%h},  opcode:{%h},  insturction:{%h}    ",
//             // $time,    ~ (|Single_Instruction_o),     fun3_o,      fun7_o,     opcode_o, instruction   
//             // );
//             $write("\n %d: E:%b I:{%h}    ",pc_o,~ (|Single_Instruction_o),  instruction   );


//  end


endmodule









  

