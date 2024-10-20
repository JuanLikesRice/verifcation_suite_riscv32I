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
    wire [N_param-1:0]  instruction;
    wire  [4:0] rd_o;
    wire  [4:0] rs1_o;
    wire  [4:0] rs2_o;
    wire  [2:0] fun3_o;
    wire  [6:0] fun7_o;
    wire [31:0] imm_o;
    wire [6:0] INST_typ_o, opcode_o;
    wire i_en;

    ins_mem ins_mem(
        .clk(clk),
        .reset(reset),
        .instruction_o(instruction)
    );

    decode #(.N_param(N_param)) decode_debug
    (
   .i_clk(clk),
   .i_en(i_en),
   .instruction(instruction),
   .rd_o(rd_o),
   .rs1_o(rs1_o),
   .rs2_o(rs2_o),
   .fun3_o(fun3_o),
   .fun7_o(fun7_o),
   .imm_o(imm_o),
   .INST_typ_o(INST_typ_o),
   .opcode_o(opcode_o)
   );
//    .(),
//    .(),
 always @(negedge clk) begin : checker
            $display("%t:   INST_typ_o:{%h},   fun3_o:{%h}, fun7_o:{%h},  opcode_o:{%h},          ",
            $time,          INST_typ_o,        fun3_o,      fun7_o,     opcode_o       
            );
 end


endmodule









  

