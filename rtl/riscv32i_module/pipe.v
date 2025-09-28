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
    parameter RST_csr_reg_val        = {`size_csr_reg_val   {1'b0}    },
   
   //  parameter RST_Fp_opRs1_reg       = {`size_Fp_opRs1_reg  {1'b0}},
   //  parameter RST_Fp_opRs2_reg       = {`size_Fp_opRs2_reg  {1'b0}},
   //  parameter RST_Fp_op1_reg         = {`size_Fp_op1_reg    {1'b0}},
   //  parameter RST_Fp_op2_reg         = {`size_Fp_op2_reg    {1'b0}},
    parameter RST_Fp_fmt             = {`size_Fp_fmt        {1'b0}}
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
    input  wire [`size_op1_reg            -1:0] i_op1_reg_overwrite,
    input  wire [`size_op2_reg            -1:0] i_op2_reg_overwrite,
    input  wire                                 i_op1_reg_overwrite_en,
    input  wire                                 i_op2_reg_overwrite_en,
    input  wire                                 i_csr_reg_val_overwrite_en,
    
    input  wire [`size_immediate          -1:0] i_immediate,
    input  wire [`size_alu_res2           -1:0] i_alu_res2,
    input  wire [`size_rd_data            -1:0] i_rd_data,
    input  wire [`size_Single_Instruction -1:0] i_Single_Instruction,
    input  wire [`size_data_mem_loaded    -1:0] i_data_mem_loaded,
    input  wire [`size_csr_reg            -1:0] i_csr_reg,
    input  wire [`size_csr_reg_val        -1:0] i_csr_reg_val,
    input  wire [`size_csr_reg_val        -1:0] i_csr_reg_val_overwrite,

   //  input  wire [`size_Fp_rd_data         -1:0] i_Fp_rd_data,
   //  input  wire [`size_Fp_rd              -1:0] i_Fp_rd     ,
   //  input  wire [`size_Fp_opRs1_reg-1:0]        i_Fp_opRs1_reg,
   //  input  wire [`size_Fp_opRs2_reg-1:0]        i_Fp_opRs2_reg,
   //  input  wire [`size_Fp_op1_reg  -1:0]        i_Fp_op1_reg,
   //  input  wire [`size_Fp_op2_reg  -1:0]        i_Fp_op2_reg,
    input  wire [`size_Fp_fmt      -1:0]        i_Fp_fmt,

   //  input  wire [`size_Fp_op1_reg  -1:0]        i_Fp_op1_reg_overwrite,
   //  input  wire [`size_Fp_op2_reg  -1:0]        i_Fp_op2_reg_overwrite,
   //  input  wire                                 i_Fp_op1_reg_overwrite_en,
   //  input  wire                                 i_Fp_op2_reg_overwrite_en,



    // Packed output bus and per-field outputs
    output wire [WIDTH-1:0]                    o_bus,
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
    output wire [`size_csr_reg_val        -1:0] o_csr_reg_val,
    output wire [`size_rst_bit            -1:0] o_rst_value,

   //  // ---- New FP outputs ----
   //  output wire [`size_Fp_rd_data         -1:0] o_Fp_rd_data,
   //  output wire [`size_Fp_rd              -1:0] o_Fp_rd     ,
   //  output wire [`size_Fp_opRs1_reg-1:0] o_Fp_opRs1_reg,
   //  output wire [`size_Fp_opRs2_reg-1:0] o_Fp_opRs2_reg,
   //  output wire [`size_Fp_op1_reg  -1:0] o_Fp_op1_reg,
   //  output wire [`size_Fp_op2_reg  -1:0] o_Fp_op2_reg,
    output wire [`size_Fp_fmt      -1:0] o_Fp_fmt


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
    assign din[`rst_bit            ] = 1'b0;


   //  assign din[`Fp_opRs1_reg       ] = i_Fp_opRs1_reg;
   //  assign din[`Fp_opRs2_reg       ] = i_Fp_opRs2_reg;

   //  assign din[`Fp_opRs1_reg       ] = i_Fp_opRs1_reg;
   //  assign din[`Fp_opRs2_reg       ] = i_Fp_opRs2_reg;
   //  assign din[`Fp_op1_reg         ] = i_Fp_op1_reg;
   //  assign din[`Fp_op2_reg         ] = i_Fp_op2_reg;
    assign din[`Fp_fmt             ] = i_Fp_fmt;

   //  assign din[`Fp_rd_data         ] = i_Fp_rd_data;
   //  assign din[`Fp_rd              ] = i_Fp_rd;

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
            q[`rst_bit            ] <= 1'b1;
            // q[`Fp_opRs1_reg       ] <= RST_Fp_opRs1_reg;
            // q[`Fp_opRs2_reg       ] <= RST_Fp_opRs2_reg;
            // q[`Fp_op1_reg         ] <= RST_Fp_op1_reg;
            // q[`Fp_op2_reg         ] <= RST_Fp_op2_reg;
            // q[`Fp_fmt             ] <= RST_Fp_fmt;
            // q[`Fp_rd_data         ] <= 0;
            // q[`Fp_rd              ] <= 0;
            q[`Fp_fmt              ] <= 0;

        end else if (en) begin
            q <= din;
        end else  begin 
         if (i_op1_reg_overwrite_en) begin 
            q[`op1_reg] <= i_op1_reg_overwrite;
         end
         if (i_op2_reg_overwrite_en) begin 
            q[`op2_reg] <= i_op2_reg_overwrite;
         end
         if (i_csr_reg_val_overwrite_en) begin 
            q[`csr_reg_val] <= i_csr_reg_val_overwrite;
         end

         // if (i_Fp_op1_reg_overwrite_en) begin 
         //    q[`Fp_op1_reg] <= i_Fp_op1_reg_overwrite;
         // end
         // if (i_Fp_op2_reg_overwrite_en) begin 
         //    q[`Fp_op2_reg] <= i_Fp_op2_reg_overwrite;
         // end
         
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
    assign o_rst_value           = q[`rst_bit];

   //  assign o_Fp_opRs1_reg        = q[`Fp_opRs1_reg];
   //  assign o_Fp_opRs2_reg        = q[`Fp_opRs2_reg];
   //  assign o_Fp_op1_reg          = q[`Fp_op1_reg];
   //  assign o_Fp_op2_reg          = q[`Fp_op2_reg];
   //  assign o_Fp_rd_data          = q[`Fp_rd_data    ];
   //  assign o_Fp_rd               = q[`Fp_rd         ];

    assign o_Fp_fmt              = q[`Fp_fmt];


endmodule





module pulse_generator(
		       input wire	  clk,
		       input wire [31:0]  in,
		       output wire [31:0] out
		       );

   reg [31:0]				  out_r;
   reg [31:0]				  prev_in;
   assign out = out_r;
   integer				  i;
   always @(posedge clk) begin
      for (i = 0; i < 32; i = i + 1) begin
         out_r[i]   <= in[i] & ~prev_in[i];
         prev_in[i] <= in[i];

      end
   end
endmodule


module pulse_generator_1bit(
			    input wire	clk,
			    input wire	in,
			    output wire	out
			    );
   reg					out_r;
   reg					prev_in;
   assign out = out_r;
   integer				i;
   always @(posedge clk) begin
      // for (i = 0; i < 32; i = i + 1) begin
      out_r   <= in & ~prev_in;
      prev_in <= in;
      // end
   end
endmodule


module data_mem_bram_wrapper #(  parameter MEM_DEPTH = 1096 ) (
							       input wire	  clk,
							       input wire	  reset,


							       // BRAM interface Signals

							       output wire	  ins_mem_clkb,
							       output wire	  ins_mem_enb,
							       output wire	  ins_mem_rstb,
							       output wire [3:0 ] ins_mem_web,
							       output wire [31:0] ins_mem_addrb,
							       output wire [31:0] ins_mem_dinb,
							       input wire	  ins_mem_rstb_busy,
							       input wire [31:0]  ins_mem_doutb,


							       // core Memory interface
							       input wire	  ins_data_req_o, 
							       input wire [31:0]  ins_data_addr_o, 
							       input wire	  ins_data_we_o, 
							       input wire [3:0]	  ins_data_be_o, 
							       input wire [31:0]  ins_data_wdata_o,
							       output wire [31:0] ins_data_rdata_i, 
							       output wire	  ins_data_rvalid_i, 
							       output wire	  ins_data_gnt_i      
							       );

   reg										  rvalid_reg,rvalid_reg_1,rvalid_reg_2,rvalid_reg_3,rvalid_reg_4,rvalid_reg_5,rvalid_reg_6,rvalid_reg_7;
   wire										  rstb_busy;
   assign ins_data_gnt_i     = ins_data_req_o;
   assign ins_data_rvalid_i  = rvalid_reg;
   // assign ins_data_gnt_i     = rvalid_reg;
   // assign ins_data_rvalid_i  = rvalid_reg_7;
   // assign  bram_web = 4'b0;


   assign ins_mem_clkb      = clk;
   assign ins_mem_enb       = ins_data_req_o;

   // assign enb = data_req_o;
   assign ins_mem_web = ins_data_we_o ? ins_data_be_o: 4'b0;

   assign ins_mem_rstb      = 1'b0;
   // assign ins_mem_web       = 4'b0000;
   assign ins_mem_addrb     = ins_data_addr_o;
   assign ins_mem_dinb      = ins_data_wdata_o;
   // assign ins_mem_rstb_busy = rstb_busy;
   assign ins_data_rdata_i = ins_mem_doutb;

   reg [31:0]									  cycle_taken;
   initial begin
      cycle_taken <= 0;
   end

   always @(posedge clk) begin
      if (reset) begin
         rvalid_reg <= 1'b0; rvalid_reg_1 <= 1'b0;  rvalid_reg_2 <= 1'b0;     rvalid_reg_3 <= 1'b0; rvalid_reg_4 <= 1'b0;  rvalid_reg_5 <= 1'b0; rvalid_reg_6 <= 1'b0;  rvalid_reg_7 <= 1'b0;
      end
      else begin
         rvalid_reg   <= ins_data_req_o; rvalid_reg_1 <= rvalid_reg;  rvalid_reg_2 <= rvalid_reg_1; rvalid_reg_3 <= rvalid_reg_2;  rvalid_reg_4 <= rvalid_reg_3; rvalid_reg_5 <= rvalid_reg_4;  rvalid_reg_6 <= rvalid_reg_5; rvalid_reg_7 <= rvalid_reg_6;
      end
   end
endmodule



//    peripheral
module  peripheral_mem_bram_wrapper #(  parameter MEM_DEPTH = 1096 ) (
								      input wire	 clk,
								      input wire	 reset,


								      // BRAM interface Signals

								      output wire	 ins_mem_clkb,
								      output wire	 ins_mem_enb,
								      output wire	 ins_mem_rstb,
								      output wire [3:0 ] ins_mem_web,
								      output wire [31:0] ins_mem_addrb,
								      output wire [31:0] ins_mem_dinb,
								      input wire	 ins_mem_rstb_busy,
								      input wire [31:0]	 ins_mem_doutb,


								      // core Memory interface
								      input wire	 ins_data_req_o, 
								      input wire [31:0]	 ins_data_addr_o, 
								      input wire	 ins_data_we_o, 
								      input wire [3:0]	 ins_data_be_o, 
								      input wire [31:0]	 ins_data_wdata_o,
								      output wire [31:0] ins_data_rdata_i, 
								      output wire	 ins_data_rvalid_i, 
								      output wire	 ins_data_gnt_i      
								      );

   reg											 rvalid_reg,rvalid_reg_1,rvalid_reg_2,rvalid_reg_3,rvalid_reg_4,rvalid_reg_5,rvalid_reg_6,rvalid_reg_7;
   wire											 rstb_busy;
   assign ins_data_gnt_i     = ins_data_req_o;
   assign ins_data_rvalid_i  = rvalid_reg;
   // assign ins_data_gnt_i     = rvalid_reg;
   // assign ins_data_rvalid_i  = rvalid_reg_6;
   // assign  bram_web = 4'b0;


   assign ins_mem_clkb      = clk;
   assign ins_mem_enb       = ins_data_req_o;

   // assign enb = data_req_o;
   assign ins_mem_web = ins_data_we_o ? ins_data_be_o: 4'b0;

   assign ins_mem_rstb      = 1'b0;
   // assign ins_mem_web       = 4'b0000;
   assign ins_mem_addrb     = ins_data_addr_o;
   assign ins_mem_dinb      = ins_data_wdata_o;
   // assign ins_mem_rstb_busy = rstb_busy;
   assign ins_data_rdata_i = ins_mem_doutb;

   reg [31:0]										 cycle_taken;
   initial begin
      cycle_taken <= 0;
   end

   always @(posedge clk) begin
      if (reset) begin
         rvalid_reg <= 1'b0; rvalid_reg_1 <= 1'b0;  rvalid_reg_2 <= 1'b0;     rvalid_reg_3 <= 1'b0; rvalid_reg_4 <= 1'b0;  rvalid_reg_5 <= 1'b0; rvalid_reg_6 <= 1'b0;  rvalid_reg_7 <= 1'b0;
      end
      else begin
         rvalid_reg   <= ins_data_req_o; rvalid_reg_1 <= rvalid_reg;  rvalid_reg_2 <= rvalid_reg_1; rvalid_reg_3 <= rvalid_reg_2;  rvalid_reg_4 <= rvalid_reg_3; rvalid_reg_5 <= rvalid_reg_4;  rvalid_reg_6 <= rvalid_reg_5; rvalid_reg_7 <= rvalid_reg_6;
      end
   end
endmodule



module inst_mem_bram_wrapper #(  parameter MEM_DEPTH = 1096 ) (
							       input wire	  clk,
							       input wire	  reset,


							       // BRAM interface Signals

							       output wire	  ins_mem_clkb,
							       output wire	  ins_mem_enb,
							       output wire	  ins_mem_rstb,
							       output wire [3:0 ] ins_mem_web,
							       output wire [31:0] ins_mem_addrb,
							       output wire [31:0] ins_mem_dinb,
							       input wire	  ins_mem_rstb_busy,
							       input wire [31:0]  ins_mem_doutb,


							       // core Memory interface
							       input wire	  ins_data_req_o, 
							       input wire [31:0]  ins_data_addr_o, 
							       input wire	  ins_data_we_o, 
							       input wire [3:0]	  ins_data_be_o, 
							       input wire [31:0]  ins_data_wdata_o,
							       output wire [31:0] ins_data_rdata_i, 
							       output wire	  ins_data_rvalid_i, 
							       output wire	  ins_data_gnt_i      
							       );

   reg										  rvalid_reg,rvalid_reg_1,rvalid_reg_2,rvalid_reg_3,rvalid_reg_4,rvalid_reg_5,rvalid_reg_6,rvalid_reg_7;
   wire										  rstb_busy;
   assign ins_data_gnt_i     = ins_data_req_o;
   assign ins_data_rvalid_i  = rvalid_reg;
  //  assign ins_data_rvalid_i  = rvalid_reg_3;
   // assign  bram_web = 4'b0;


   assign ins_mem_clkb      = clk;
   assign ins_mem_enb       = ins_data_req_o;
   assign ins_mem_rstb      = 1'b0;
   assign ins_mem_web       = 4'b0000;
   assign ins_mem_addrb     = ins_data_addr_o;
   assign ins_mem_dinb      = 32'b0;
   // assign ins_mem_rstb_busy = rstb_busy;
   assign ins_data_rdata_i = ins_mem_doutb;

   reg [31:0]									  cycle_taken;
   initial begin
      cycle_taken <= 0;
   end



   always @(posedge clk) begin
      if (reset) begin
         rvalid_reg <= 1'b0;
         rvalid_reg_1 <= 1'b0;
         rvalid_reg_2 <= 1'b0;   
         rvalid_reg_3 <= 1'b0;
         rvalid_reg_4 <= 1'b0;
         rvalid_reg_5 <= 1'b0;
         rvalid_reg_6 <= 1'b0;
         rvalid_reg_7 <= 1'b0;
      end
      else begin
         rvalid_reg   <= ins_data_req_o;
         rvalid_reg_1 <= rvalid_reg;
         rvalid_reg_2 <= rvalid_reg_1;
         rvalid_reg_3 <= rvalid_reg_2;
         rvalid_reg_4 <= rvalid_reg_3;
         rvalid_reg_5 <= rvalid_reg_4;
         rvalid_reg_6 <= rvalid_reg_5;
         rvalid_reg_7 <= rvalid_reg_6;
      end
   end
endmodule





module inst_mem_bram_wrapper_test_purpoeses #(  parameter MEM_DEPTH = 1096 ) (
									      input wire	 clk,
									      input wire	 reset,


									      // BRAM interface Signals

									      output wire	 ins_mem_clkb,
									      output wire	 ins_mem_enb,
									      output wire	 ins_mem_rstb,
									      output wire [3:0 ] ins_mem_web,
									      output wire [31:0] ins_mem_addrb,
									      output wire [31:0] ins_mem_dinb,
									      input wire	 ins_mem_rstb_busy,
									      input wire [31:0]	 ins_mem_doutb,


									      // core Memory interface
									      input wire	 ins_data_req_o, 
									      input wire [31:0]	 ins_data_addr_o, 
									      input wire	 ins_data_we_o, 
									      input wire [3:0]	 ins_data_be_o, 
									      input wire [31:0]	 ins_data_wdata_o,
									      output wire [31:0] ins_data_rdata_i, 
									      output wire	 ins_data_rvalid_i, 
									      output wire	 ins_data_gnt_i      
									      );

   reg												 rvalid_reg,rvalid_reg_1,rvalid_reg_2,rvalid_reg_3,rvalid_reg_4,rvalid_reg_5,rvalid_reg_6,rvalid_reg_7;
   wire												 rstb_busy;
   // assign ins_data_gnt_i     = ins_data_req_o;
   // assign ins_data_rvalid_i  = rvalid_reg_2;
   // assign  bram_web = 4'b0;


   wire												 grant, bram_en,req_done;
   // assign ins_data_req_o_w = req_done;
   // assign ins_data_req_o =ins_data_req_o_w;
   assign ins_data_gnt_i= grant;

   assign ins_mem_clkb      = clk;
   assign ins_mem_enb       = grant;
   assign ins_mem_rstb      = 1'b0;
   assign ins_mem_web       = 4'b0000;
   assign ins_mem_addrb     = ins_data_addr_o;
   assign ins_mem_dinb      = 32'b0;
   // assign ins_mem_rstb_busy = rstb_busy;
   assign ins_data_rdata_i = ins_mem_doutb;

   reg [31:0]											 cycle_taken;
   initial begin
      cycle_taken <= 0;
   end

   parameter N = 2;
   //   parameter L = 2;
   // assign ins_data_rvalid_i = req_done;

   parameter L = 1; // if you wnat ins_data_rvalid_i to be high after grant imediately
   assign ins_data_rvalid_i = bram_en;//req_done;
   timed_pulse #(
		 .N(N),
		 .L(L)
		 ) dut (
			.clk(clk),
			.reset(reset),
			.ins_data_req_o(ins_data_req_o),
			// .value_o(value_o),
			.grant(grant),
			.req_done(req_done),
			.bram_en(bram_en)
			);





endmodule


module timed_pulse #(
		     parameter N = 2, // Number of cycles to capture ins_data_req_o
		     parameter L = 3   // Number of cycles to wait after capture
		     ) (
			input	    clk,
			input	    reset,
			input	    ins_data_req_o,
			output reg  value_o,
			output wire grant,
			output wire req_done,
			output wire bram_en
			);

   reg [31:0]			    counter,counter_L;
   reg				    capture_done;
   reg				    delay_done;
   reg				    pulse_out;
   reg				    bram_read;
   wire				    grant_w;
   assign req_done = req_done_w;

   assign grant = grant_w;
   assign grant_w = (counter == (N - 1)) && ins_data_req_o;
   wire				    req_done_w;
   assign req_done_w = (counter_L == (L - 1));
   assign bram_en = bram_read;

   initial begin 
      bram_read <=0;
   end 
   always @ (posedge clk ) begin 
      if (grant) begin
	 bram_read <= 1;
      end else if (bram_read) begin
	 bram_read <= 0;
      end

   end 


   always @(posedge clk) begin
      if (reset) begin
	 counter       <= 0;
	 counter_L       <= 0;
	 capture_done  <= 0;
	 delay_done    <= 0;
	 value_o       <= 0;
	 pulse_out     <= 0;
      end else begin
	 if(!capture_done)
	   begin
              pulse_out <= 0;

              if (ins_data_req_o) begin
		 if (counter < N -1) begin
		    counter <= counter + 1;
		 end else begin
		    capture_done <= 1;
		    counter <= 0;
		 end
              end
	   end else begin//if (!delay_done) begin
              if (counter_L < L-1) begin
		 counter_L <= counter_L + 1;
              end else begin
		 counter_L <= 0;
		 capture_done <= 0;
		 pulse_out    <= 1;
              end
              // end else begin
              //    pulse_out <= 1;
              // end
	   end
      end
   end
   //   always @(posedge clk) begin
   //     if(reset) begin
   //        value_o <= 0;
   //     end else begin
   //         value_o <= pulse_out;
   //         pulse_out <= 0;
   //     end
   //   end

endmodule

