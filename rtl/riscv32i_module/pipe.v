module pipe_ff_fields #(
    parameter integer WIDTH = `pipe_len,

    parameter [`PC_reg             ] RST_PC_reg             = {`size_PC_reg        {1'b0}    },
    parameter [`instruct           ] RST_instruct           =  `size_instruct'h00000013, // NOP
    parameter [`alu_res1           ] RST_alu_res1           = {`size_alu_res1      {1'b0}    },
    parameter [`csr_write_en       ] RST_csr_write_en       = {`size_csr_write_en  {1'b0}    },
    parameter [`load_reg           ] RST_load_reg           = {`size_load_reg      {1'b0}    },
    parameter [`jump_en            ] RST_jump_en            = {`size_jump_en       {1'b0}    },
    parameter [`branch_en          ] RST_branch_en          = {`size_branch_en     {1'b0}    },
    parameter [`reg_write_en       ] RST_reg_write_en       = {`size_reg_write_en  {1'b0}    },
    parameter [`LD_ready           ] RST_LD_ready           = {`size_LD_ready      {1'b0}    },
    parameter [`SD_ready           ] RST_SD_ready           = {`size_SD_ready      {1'b0}    },
    parameter [`rd                 ] RST_rd                 = {`size_rd            {1'b0}    },
    parameter [`operand_amt        ] RST_operand_amt        = {`size_operand_amt   {1'b0}    },
    parameter [`opRs1_reg          ] RST_opRs1_reg          = {`size_opRs1_reg     {1'b0}    },
    parameter [`opRs2_reg          ] RST_opRs2_reg          = {`size_opRs2_reg     {1'b0}    },
    parameter [`op1_reg            ] RST_op1_reg            = {`size_op1_reg       {1'b0}    },
    parameter [`op2_reg            ] RST_op2_reg            = {`size_op2_reg       {1'b0}    },
    parameter [`immediate          ] RST_immediate          = {`size_immediate     {1'b0}    },
    parameter [`alu_res2           ] RST_alu_res2           = {`size_alu_res2      {1'b0}    },
    parameter [`rd_data            ] RST_rd_data            = {`size_rd_data       {1'b0}    },
    parameter [`Single_Instruction ] RST_Single_Instruction = {`size_Single_Instruction{1'b0}},
    parameter [`data_mem_loaded    ] RST_data_mem_loaded    = {`size_data_mem_loaded{1'b0}   },
    parameter [`csr_reg            ] RST_csr_reg            = {`size_csr_reg       {1'b0}    },
    parameter [`csr_reg_val        ] RST_csr_reg_val        = {`size_csr_reg_val   {1'b0}    }
) (
    input  wire                 clk,
    input  wire                 rst,   // sync, active high
    input  wire                 flush, // sync, active high
    input  wire                 en,    // tie 1 if unused

    // Field inputs
    input  wire [`PC_reg             ] i_PC_reg,
    input  wire [`instruct           ] i_instruct,
    input  wire [`alu_res1           ] i_alu_res1,
    input  wire [`csr_write_en       ] i_csr_write_en,
    input  wire [`load_reg           ] i_load_reg,
    input  wire [`jump_en            ] i_jump_en,
    input  wire [`branch_en          ] i_branch_en,
    input  wire [`reg_write_en       ] i_reg_write_en,
    input  wire [`LD_ready           ] i_LD_ready,
    input  wire [`SD_ready           ] i_SD_ready,
    input  wire [`rd                 ] i_rd,
    input  wire [`operand_amt        ] i_operand_amt,
    input  wire [`opRs1_reg          ] i_opRs1_reg,
    input  wire [`opRs2_reg          ] i_opRs2_reg,
    input  wire [`op1_reg            ] i_op1_reg,
    input  wire [`op2_reg            ] i_op2_reg,
    input  wire [`immediate          ] i_immediate,
    input  wire [`alu_res2           ] i_alu_res2,
    input  wire [`rd_data            ] i_rd_data,
    input  wire [`Single_Instruction ] i_Single_Instruction,
    input  wire [`data_mem_loaded    ] i_data_mem_loaded,
    input  wire [`csr_reg            ] i_csr_reg,
    input  wire [`csr_reg_val        ] i_csr_reg_val,

    // Packed output bus and per-field outputs
    output wire [WIDTH-1:0]           o_bus,
    output wire [`PC_reg             ] o_PC_reg,
    output wire [`instruct           ] o_instruct,
    output wire [`alu_res1           ] o_alu_res1,
    output wire [`csr_write_en       ] o_csr_write_en,
    output wire [`load_reg           ] o_load_reg,
    output wire [`jump_en            ] o_jump_en,
    output wire [`branch_en          ] o_branch_en,
    output wire [`reg_write_en       ] o_reg_write_en,
    output wire [`LD_ready           ] o_LD_ready,
    output wire [`SD_ready           ] o_SD_ready,
    output wire [`rd                 ] o_rd,
    output wire [`operand_amt        ] o_operand_amt,
    output wire [`opRs1_reg          ] o_opRs1_reg,
    output wire [`opRs2_reg          ] o_opRs2_reg,
    output wire [`op1_reg            ] o_op1_reg,
    output wire [`op2_reg            ] o_op2_reg,
    output wire [`immediate          ] o_immediate,
    output wire [`alu_res2           ] o_alu_res2,
    output wire [`rd_data            ] o_rd_data,
    output wire [`Single_Instruction ] o_Single_Instruction,
    output wire [`data_mem_loaded    ] o_data_mem_loaded,
    output wire [`csr_reg            ] o_csr_reg,
    output wire [`csr_reg_val        ] o_csr_reg_val
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
