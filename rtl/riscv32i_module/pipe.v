module pipe_ff_fields #(
    parameter integer WIDTH = `pipe_len,

    parameter RST_PC_reg             = {`size_PC_reg        {1'b0}    },
    parameter RST_instruct           =  `size_instruct'h00000013, // NOP
    parameter RST_alu_res1           = {`size_alu_res1      {1'b0}    },
    parameter RST_csr_write_en       = {`size_csr_write_en  {1'b0}    },
    parameter RST_load_reg           = {`size_load_reg      {1'b0}    },
    parameter RST_jump_en            = {`size_jump_en       {1'b0}    },
    parameter RST_branch_en          = {`size_branch_en     {1'b0}    },
    parameter RST_reg_write_en       = {`size_reg_write_en  {1'b0}    },
    parameter RST_LD_ready           = {`size_LD_ready      {1'b0}    },
    parameter RST_SD_ready           = {`size_SD_ready      {1'b0}    },
    parameter RST_rd                 = {`size_rd            {1'b0}    },
    parameter RST_operand_amt        = {`size_operand_amt   {1'b0}    },
    parameter RST_opRs1_reg          = {`size_opRs1_reg     {1'b0}    },
    parameter RST_opRs2_reg          = {`size_opRs2_reg     {1'b0}    },
    parameter RST_op1_reg            = {`size_op1_reg       {1'b0}    },
    parameter RST_op2_reg            = {`size_op2_reg       {1'b0}    },
    parameter RST_immediate          = {`size_immediate     {1'b0}    },
    parameter RST_alu_res2           = {`size_alu_res2      {1'b0}    },
    parameter RST_rd_data            = {`size_rd_data       {1'b0}    },
    parameter RST_Single_Instruction = {`size_Single_Instruction{1'b0}},
    parameter RST_data_mem_loaded    = {`size_data_mem_loaded{1'b0}   },
    parameter RST_csr_reg            = {`size_csr_reg       {1'b0}    },
    parameter RST_csr_reg_val        = {`size_csr_reg_val   {1'b0}    }
) (
    input  wire                 clk,
    input  wire                 rst,   // sync, active high
    input  wire                 flush, // sync, active high
    input  wire                 en,    // tie 1 if unused

    // Field inputs
    input  wire [`size_PC_reg             -1:0] i_PC_reg,
    input  wire [`size_instruct           -1:0] i_instruct,
    input  wire [`size_alu_res1           -1:0] i_alu_res1,
    input  wire [`size_csr_write_en       -1:0] i_csr_write_en,
    input  wire [`size_load_reg           -1:0] i_load_reg,
    input  wire [`size_jump_en            -1:0] i_jump_en,
    input  wire [`size_branch_en          -1:0] i_branch_en,
    input  wire [`size_reg_write_en       -1:0] i_reg_write_en,
    input  wire [`size_LD_ready           -1:0] i_LD_ready,
    input  wire [`size_SD_ready           -1:0] i_SD_ready,
    input  wire [`size_rd                 -1:0] i_rd,
    input  wire [`size_operand_amt        -1:0] i_operand_amt,
    input  wire [`size_opRs1_reg          -1:0] i_opRs1_reg,
    input  wire [`size_opRs2_reg          -1:0] i_opRs2_reg,
    input  wire [`size_op1_reg            -1:0] i_op1_reg,
    input  wire [`size_op2_reg            -1:0] i_op2_reg,
    input  wire [`size_immediate          -1:0] i_immediate,
    input  wire [`size_alu_res2           -1:0] i_alu_res2,
    input  wire [`size_rd_data            -1:0] i_rd_data,
    input  wire [`size_Single_Instruction -1:0] i_Single_Instruction,
    input  wire [`size_data_mem_loaded    -1:0] i_data_mem_loaded,
    input  wire [`size_csr_reg            -1:0] i_csr_reg,
    input  wire [`size_csr_reg_val        -1:0] i_csr_reg_val,

    // Packed output bus and per-field outputs
    output wire [WIDTH-1:0]           o_bus,
    output wire [`size_PC_reg             -1:0] o_PC_reg,
    output wire [`size_instruct           -1:0] o_instruct,
    output wire [`size_alu_res1           -1:0] o_alu_res1,
    output wire [`size_csr_write_en       -1:0] o_csr_write_en,
    output wire [`size_load_reg           -1:0] o_load_reg,
    output wire [`size_jump_en            -1:0] o_jump_en,
    output wire [`size_branch_en          -1:0] o_branch_en,
    output wire [`size_reg_write_en       -1:0] o_reg_write_en,
    output wire [`size_LD_ready           -1:0] o_LD_ready,
    output wire [`size_SD_ready           -1:0] o_SD_ready,
    output wire [`size_rd                 -1:0] o_rd,
    output wire [`size_operand_amt        -1:0] o_operand_amt,
    output wire [`size_opRs1_reg          -1:0] o_opRs1_reg,
    output wire [`size_opRs2_reg          -1:0] o_opRs2_reg,
    output wire [`size_op1_reg            -1:0] o_op1_reg,
    output wire [`size_op2_reg            -1:0] o_op2_reg,
    output wire [`size_immediate          -1:0] o_immediate,
    output wire [`size_alu_res2           -1:0] o_alu_res2,
    output wire [`size_rd_data            -1:0] o_rd_data,
    output wire [`size_Single_Instruction -1:0] o_Single_Instruction,
    output wire [`size_data_mem_loaded    -1:0] o_data_mem_loaded,
    output wire [`size_csr_reg            -1:0] o_csr_reg,
    output wire [`size_csr_reg_val        -1:0] o_csr_reg_val
);
    // build input bus
    wire [WIDTH-1:0] din;
    assign din[`PC_reg             ] = i_PC_reg;
    assign din[`instruct           ] = i_instruct;
    assign din[`alu_res1           ] = i_alu_res1;
    assign din[`csr_write_en       ] = i_csr_write_en;
    assign din[`load_reg           ] = i_load_reg;
    assign din[`jump_en            ] = i_jump_en;
    assign din[`branch_en          ] = i_branch_en;
    assign din[`reg_write_en       ] = i_reg_write_en;
    assign din[`LD_ready           ] = i_LD_ready;
    assign din[`SD_ready           ] = i_SD_ready;
    assign din[`rd                 ] = i_rd;
    assign din[`operand_amt        ] = i_operand_amt;
    assign din[`opRs1_reg          ] = i_opRs1_reg;
    assign din[`opRs2_reg          ] = i_opRs2_reg;
    assign din[`op1_reg            ] = i_op1_reg;
    assign din[`op2_reg            ] = i_op2_reg;
    assign din[`immediate          ] = i_immediate;
    assign din[`alu_res2           ] = i_alu_res2;
    assign din[`rd_data            ] = i_rd_data;
    assign din[`Single_Instruction ] = i_Single_Instruction;
    assign din[`data_mem_loaded    ] = i_data_mem_loaded;
    assign din[`csr_reg            ] = i_csr_reg;
    assign din[`csr_reg_val        ] = i_csr_reg_val;

    // register
    reg [WIDTH-1:0] q;
    assign o_bus = q;

    always @(posedge clk) begin
        if (rst|flush) begin
            q[`PC_reg             ] <= RST_PC_reg;
            q[`instruct           ] <= RST_instruct;
            q[`alu_res1           ] <= RST_alu_res1;
            q[`csr_write_en       ] <= RST_csr_write_en;
            q[`load_reg           ] <= RST_load_reg;
            q[`jump_en            ] <= RST_jump_en;
            q[`branch_en          ] <= RST_branch_en;
            q[`reg_write_en       ] <= RST_reg_write_en;
            q[`LD_ready           ] <= RST_LD_ready;
            q[`SD_ready           ] <= RST_SD_ready;
            q[`rd                 ] <= RST_rd;
            q[`operand_amt        ] <= RST_operand_amt;
            q[`opRs1_reg          ] <= RST_opRs1_reg;
            q[`opRs2_reg          ] <= RST_opRs2_reg;
            q[`op1_reg            ] <= RST_op1_reg;
            q[`op2_reg            ] <= RST_op2_reg;
            q[`immediate          ] <= RST_immediate;
            q[`alu_res2           ] <= RST_alu_res2;
            q[`rd_data            ] <= RST_rd_data;
            q[`Single_Instruction ] <= RST_Single_Instruction;
            q[`data_mem_loaded    ] <= RST_data_mem_loaded;
            q[`csr_reg            ] <= RST_csr_reg;
            q[`csr_reg_val        ] <= RST_csr_reg_val;
        end else if (en) begin
            q <= din;
        end
    end

    // outputs
    assign o_PC_reg              = q[`PC_reg];
    assign o_instruct            = q[`instruct];
    assign o_alu_res1            = q[`alu_res1];
    assign o_csr_write_en        = q[`csr_write_en];
    assign o_load_reg            = q[`load_reg];
    assign o_jump_en             = q[`jump_en];
    assign o_branch_en           = q[`branch_en];
    assign o_reg_write_en        = q[`reg_write_en];
    assign o_LD_ready            = q[`LD_ready];
    assign o_SD_ready            = q[`SD_ready];
    assign o_rd                  = q[`rd];
    assign o_operand_amt         = q[`operand_amt];
    assign o_opRs1_reg           = q[`opRs1_reg];
    assign o_opRs2_reg           = q[`opRs2_reg];
    assign o_op1_reg             = q[`op1_reg];
    assign o_op2_reg             = q[`op2_reg];
    assign o_immediate           = q[`immediate];
    assign o_alu_res2            = q[`alu_res2];
    assign o_rd_data             = q[`rd_data];
    assign o_Single_Instruction  = q[`Single_Instruction];
    assign o_data_mem_loaded     = q[`data_mem_loaded];
    assign o_csr_reg             = q[`csr_reg];
    assign o_csr_reg_val         = q[`csr_reg_val];
endmodule
