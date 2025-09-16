`default_nettype none
`include "params.vh"

module riscv32i_wrap
  # (
     parameter N_param = 32,
     parameter ADR_IMEM_START = 32'h00002000,
     parameter ADR_PMEM_START = 32'h00002600,
     parameter ADR_DMEM_START = 32'h00002600,
     parameter ADR_IMEM_SIZE  = 4096,
     parameter ADR_PMEM_SIZE  = 1024,
     parameter ADR_DMEM_SIZE  = 6656,
     parameter debug_param    = 0,
     parameter BRAM1_TBMEM0_PARAM = 1,
     parameter dispatch_print = 0
     
     )     (
	    input wire	       clk,
	    input wire [31:0]  GPIO0_R0_CH1, // control signals
	    input wire [31:0]  GPIO0_R0_CH2, // memory_offset
	    input wire [31:0]  GPIO0_R1_CH1, // initial_pc_i
	    input wire [31:0]  GPIO0_R1_CH2, // success_code

	    output wire	       STOP_sim,

	    // BRAM ports for Data Mem
	    output wire	       data_mem_clkb,
	    output wire	       data_mem_enb,
	    output wire	       data_mem_rstb,
	    output wire [3:0]  data_mem_web,
	    output wire [31:0] data_mem_addrb,
	    output wire [31:0] data_mem_dinb,
	    input wire	       data_mem_rstb_busy,
	    input wire [31:0]  data_mem_doutb,

	    // BRAM ports for peripheral Mem
	    output wire	       peripheral_mem_clkb,
	    output wire	       peripheral_mem_enb,
	    output wire	       peripheral_mem_rstb,
	    output wire [3:0]  peripheral_mem_web,
	    output wire [31:0] peripheral_mem_addrb,
	    output wire [31:0] peripheral_mem_dinb,
	    input wire	       peripheral_mem_rstb_busy,
	    input wire [31:0]  peripheral_mem_doutb,
	    input wire	       timer_timeout, 


	    // // BRAM ports for Ins Mem

	    output wire	       ins_mem_clkb,
	    output wire	       ins_mem_enb,
	    output wire	       ins_mem_rstb,
	    output wire [3:0]  ins_mem_web,
	    output wire [31:0] ins_mem_addrb,
	    output wire [31:0] ins_mem_dinb,
	    input wire	       ins_mem_rstb_busy,
	    input wire [31:0]  ins_mem_doutb
	    );



   reg			       enable_design_reg;
   reg			       stop_design;
   wire			       enable_design;
   wire			       start_design , reset;
   reg [31:0]		   cycle_to_end;
   wire [31:0]		 control_signals_in;
   reg [31:0]      Cycle_count  ;
   wire [31:0]		       memory_offset;
   wire [31:0]		       initial_pc_i ;
   wire [31:0]		       success_code  ;
   wire [31:0]		       final_value  ;


   wire			       ins_data_req_o     ;
   wire [31:0]		 ins_data_addr_o    ;
   wire			       ins_data_we_o      ;
   wire [ 3:0]		 ins_data_be_o      ;
   wire [31:0]		 ins_data_wdata_o   ;
   wire [31:0]		 ins_data_rdata_i   ;
   wire			       ins_data_rvalid_i  ;
   wire			       ins_data_gnt_i     ;  

   wire			       Dmem_data_req_o    ;
   wire [31:0]     Dmem_data_addr_o   ;
   wire			       Dmem_data_we_o     ;
   wire [ 3:0]		 Dmem_data_be_o     ;
   wire [31:0]		 Dmem_data_wdata_o  ;

   wire [31:0]		 Dmem_data_rdata_i  ;
   wire			       Dmem_data_rvalid_i ;
   wire			       Dmem_data_gnt_i    ;



   wire [31:0]		 tbmem_Dmem_data_rdata_i  ;
   wire			       tbmem_Dmem_data_rvalid_i ;
   wire			       tbmem_Dmem_data_gnt_i    ;
   wire [31:0]		 tbmem_ins_data_rdata_i   ;
   wire			       tbmem_ins_data_rvalid_i  ;
   wire			       tbmem_ins_data_gnt_i     ;  

   wire [31:0]		 bram_Dmem_data_rdata_i  ;
   wire			       bram_Dmem_data_rvalid_i ;
   wire			       bram_Dmem_data_gnt_i    ;
   wire [31:0]		 bram_ins_data_rdata_i   ;
   wire			       bram_ins_data_rvalid_i  ;
   wire			       bram_ins_data_gnt_i     ;  


   wire			       Pmem_data_req_o    ;
   wire [31:0]		 Pmem_data_addr_o   ;
   wire			       Pmem_data_we_o     ;
   wire [ 3:0]		 Pmem_data_be_o     ;
   wire [31:0]		 Pmem_data_wdata_o  ;
   wire [31:0]		 Pmem_data_rdata_i  ;
   wire			       Pmem_data_rvalid_i ;
   wire			       Pmem_data_gnt_i    ;
  
  wire  BRAM_MEM;
  assign BRAM_MEM = BRAM1_TBMEM0_PARAM;

  assign ins_data_rdata_i   = BRAM_MEM ? bram_ins_data_rdata_i   : tbmem_ins_data_rdata_i   ;
  assign ins_data_rvalid_i  = BRAM_MEM ? bram_ins_data_rvalid_i  : tbmem_ins_data_rvalid_i  ;
  assign ins_data_gnt_i     = BRAM_MEM ? bram_ins_data_gnt_i     : tbmem_ins_data_gnt_i     ;

  assign Dmem_data_rdata_i  = BRAM_MEM ? bram_Dmem_data_rdata_i  : tbmem_Dmem_data_rdata_i  ;
  assign Dmem_data_rvalid_i = BRAM_MEM ? bram_Dmem_data_rvalid_i : tbmem_Dmem_data_rvalid_i ;
  assign Dmem_data_gnt_i    = BRAM_MEM ? bram_Dmem_data_gnt_i    : tbmem_Dmem_data_gnt_i    ;


   pulse_generator pulse_generator_GPIO0_R0_CH1 (
						 .clk(clk),
						 .in(GPIO0_R0_CH1),
						 .out(control_signals_in)
						 );

   assign STOP_sim           = stop_design;
   assign  memory_offset     = GPIO0_R0_CH2;
   assign  initial_pc_i      = GPIO0_R1_CH1;
   assign  success_code      = GPIO0_R1_CH2;

   assign start_design    = control_signals_in[0];
   // assign reset           = control_signals_in[1];
   assign reset           = control_signals_in[2];

   assign enable_design = enable_design_reg & ~stop_design;


   wire			       finished_program;

   always @(posedge clk) begin
      if (reset) begin
	 cycle_to_end        <= 32'h0;
	 Cycle_count         <= 32'h0;
	 enable_design_reg   <=  1'b0;
	 stop_design         <=  1'b0;
      end else begin  
	 if (start_design) begin 
	    Cycle_count         <= 32'h0;
	    enable_design_reg   <=  1'b1;
	 end else if (enable_design_reg) begin
            Cycle_count         <= Cycle_count + 1;
	    enable_design_reg   <= enable_design_reg;
	 end      
	 if (finished_program)begin 
            cycle_to_end <= cycle_to_end + 1;
            stop_design  <= 1'b0;
	 end
	 if (cycle_to_end >= 30) begin
            stop_design <= 1'b1;
            
	   //  MARKER AUTOMATED HERE START
	   $write("\nCycle_count %5d,\n",Cycle_count);
	    $display("\n\n\n\n----TB FINISH:Test Passed----\n\n\n\n\nTEST FINISHED by success write :%h \n\n\n\n\n",success_code);
	    
	    //MARKER AUTOMATED HERE END
	 end 
      end
   end 


   wire Dmem_clk, Imem_clk, Pmem_clk;
   // Instantiation of riscv32i_main
   riscv32i #(
		  .N_param(32),
      .debug_param(debug_param),
.ADR_PMEM_START(ADR_PMEM_START),
.ADR_DMEM_START(ADR_DMEM_START),
      .dispatch_print(dispatch_print)
		   ) u_riscv32i_main (
				      .clk(             clk),
				      // .reset(           reset),
				      .Cycle_count(     Cycle_count),

				      // four GPIO IPUTS
				      .control_signal(    control_signals_in),
				      .memory_offset(     memory_offset),
				      .initial_pc_i(      initial_pc_i),
				      .success_code(      success_code),
				      
				      .finished_program(  finished_program),
				      // .final_value(     final_value),
				      

				      .Dmem_clk(            Dmem_clk),
				      .Dmem_data_req_o(     Dmem_data_req_o),
				      .Dmem_data_addr_o(    Dmem_data_addr_o),
				      .Dmem_data_we_o(      Dmem_data_we_o),
				      .Dmem_data_be_o(      Dmem_data_be_o),
				      .Dmem_data_wdata_o(   Dmem_data_wdata_o),
				      .Dmem_data_rdata_i(   Dmem_data_rdata_i),
				      .Dmem_data_rvalid_i(  Dmem_data_rvalid_i),
				      .Dmem_data_gnt_i(     Dmem_data_gnt_i),

				      .Pmem_clk(            Pmem_clk),
				      .Pmem_data_req_o(     Pmem_data_req_o),
				      .Pmem_data_addr_o(    Pmem_data_addr_o),
				      .Pmem_data_we_o(      Pmem_data_we_o),
				      .Pmem_data_be_o(      Pmem_data_be_o),
				      .Pmem_data_wdata_o(   Pmem_data_wdata_o),
				      .Pmem_data_rdata_i(   Pmem_data_rdata_i),
				      .Pmem_data_rvalid_i(  Pmem_data_rvalid_i),
				      .Pmem_data_gnt_i(     Pmem_data_gnt_i),
				      .timer_timeout(       timer_timeout),


				      // Memory interface signals
				      .ins_data_req_o     (ins_data_req_o),
				      .ins_data_addr_o    (ins_data_addr_o),
				      .ins_data_we_o      (ins_data_we_o),
				      .ins_data_be_o      (ins_data_be_o),
				      .ins_data_wdata_o   (ins_data_wdata_o),

				      .ins_data_rdata_i   (ins_data_rdata_i),
				      .ins_data_rvalid_i  (ins_data_rvalid_i),
				      .ins_data_gnt_i     (ins_data_gnt_i)
				      );


   data_mem_bram_wrapper  data_mem_bram_wrapper (
						 .clk               (    clk),
						 .reset             (    reset),

						 .ins_data_req_o    (         Dmem_data_req_o     ),
						 .ins_data_addr_o   (         Dmem_data_addr_o    ),
						 .ins_data_we_o     (         Dmem_data_we_o      ),
						 .ins_data_be_o     (         Dmem_data_be_o      ),
						 .ins_data_wdata_o  (         Dmem_data_wdata_o   ),
						 .ins_data_rdata_i  (    bram_Dmem_data_rdata_i   ),
						 .ins_data_rvalid_i (    bram_Dmem_data_rvalid_i  ),
						 .ins_data_gnt_i    (    bram_Dmem_data_gnt_i     ),

						 // .data_clk(Imem_clk),
						 .ins_mem_clkb (       data_mem_clkb),
						 .ins_mem_enb (        data_mem_enb),
						 .ins_mem_rstb (       data_mem_rstb),
						 .ins_mem_web (        data_mem_web),
						 .ins_mem_addrb (      data_mem_addrb),
						 .ins_mem_dinb (       data_mem_dinb),
						 .ins_mem_rstb_busy (  data_mem_rstb_busy),
						 .ins_mem_doutb (      data_mem_doutb)

						 );
   

   peripheral_mem_bram_wrapper  peripheral_mem_bram_wrapper (
							     .clk               (    clk),
							     .reset             (    reset),

							     .ins_data_req_o    (    Pmem_data_req_o),
							     .ins_data_addr_o   (    Pmem_data_addr_o),
							     .ins_data_we_o     (    Pmem_data_we_o),
							     .ins_data_be_o     (    Pmem_data_be_o),
							     .ins_data_wdata_o  (    Pmem_data_wdata_o),
							     .ins_data_rdata_i  (    Pmem_data_rdata_i),
							     .ins_data_rvalid_i (    Pmem_data_rvalid_i),
							     .ins_data_gnt_i    (    Pmem_data_gnt_i),


							     // .data_clk(Imem_clk),
							     .ins_mem_clkb (       peripheral_mem_clkb),
							     .ins_mem_enb (        peripheral_mem_enb),
							     .ins_mem_rstb (       peripheral_mem_rstb),
							     .ins_mem_web (        peripheral_mem_web),
							     .ins_mem_addrb (      peripheral_mem_addrb),
							     .ins_mem_dinb (       peripheral_mem_dinb),
							     .ins_mem_rstb_busy (  peripheral_mem_rstb_busy),
							     .ins_mem_doutb (      peripheral_mem_doutb)

							     );

   inst_mem_bram_wrapper  inst_mem_bram_wrapper (
						 .clk               (clk),
						 .reset             (reset),
						 .ins_data_req_o    (     ins_data_req_o),
						 .ins_data_addr_o   (     ins_data_addr_o),
						 .ins_data_we_o     (     ins_data_we_o),
						 .ins_data_be_o     (     ins_data_be_o),
						 .ins_data_wdata_o  (     ins_data_wdata_o),
						 .ins_data_rdata_i  (bram_ins_data_rdata_i),
						 .ins_data_rvalid_i (bram_ins_data_rvalid_i),
						 .ins_data_gnt_i    (bram_ins_data_gnt_i),
						 // .data_clk(Imem_clk),
						 .ins_mem_clkb (ins_mem_clkb),
						 .ins_mem_enb (ins_mem_enb),
						 .ins_mem_rstb (ins_mem_rstb),
						 .ins_mem_web (ins_mem_web),
						 .ins_mem_addrb (ins_mem_addrb),
						 .ins_mem_dinb (ins_mem_dinb),
						 .ins_mem_rstb_busy (ins_mem_rstb_busy),
						 .ins_mem_doutb (ins_mem_doutb)
						 );
   

generate
  if (BRAM1_TBMEM0_PARAM == 0) begin : g_with_bram1
    ri5cy_lsu_mem_bfm #(
      .MEM_WORDS      (ADR_DMEM_SIZE),
    //  .GRANT_MIN_CYC  (1),   // dummy; overridden below
      .GRANT_MAX_CYC  (4),
    //  .RESP_MIN_CYC   (1),
      .RESP_MAX_CYC   (30),
      .OUTSTANDING_MAX(32),
      .DEBUG(debug_param),
      .INIT_HEX       (""),
    //  .RESET_MEM_PARAM(32'h00000013),
      .ADDR_OFFSET(ADR_DMEM_START)
    ) u_data_mem (
      .clk            (clk),
      .rst_n          (~reset),
    //  .seed_i         ( 32'h2975bc20),
      .seed_i         ( 32'h2975bc21),
      .seed_valid_i   (1'b1),
      .data_req_i     (      Dmem_data_req_o),
      .data_addr_i    (      Dmem_data_addr_o),
      .data_we_i      (      Dmem_data_we_o),
      .data_be_i      (      Dmem_data_be_o),
      .data_wdata_i   (      Dmem_data_wdata_o),
      .data_gnt_o     (tbmem_Dmem_data_gnt_i),
      .data_rvalid_o  (tbmem_Dmem_data_rvalid_i),
      .data_rdata_o   (tbmem_Dmem_data_rdata_i)
    );

    ri5cy_lsu_mem_bfm #(
      .MEM_WORDS      (ADR_IMEM_SIZE),
      .OUTSTANDING_MAX(8),
      .DEBUG(0), // NEVER PRINT
      .INIT_HEX       ("out.hex"),
      .RESET_MEM_PARAM(32'h00000013),
      .ADDR_OFFSET(ADR_IMEM_START)
    ) u_ins_mem (
      .clk            (clk),
      .rst_n          (~reset),
    //  .seed_i         ( 32'h2975bc20),
      .seed_i         ( 32'h2975bc21),
      .seed_valid_i   (1'b1),
      .data_req_i     (      ins_data_req_o),
      .data_addr_i    (      ins_data_addr_o),
      .data_we_i      (      ins_data_we_o),
      .data_be_i      (      ins_data_be_o),
      .data_wdata_i   (      ins_data_wdata_o),
      .data_gnt_o     (tbmem_ins_data_gnt_i),
      .data_rvalid_o  (tbmem_ins_data_rvalid_i),
      .data_rdata_o   (tbmem_ins_data_rdata_i)
    );
  end
endgenerate



endmodule


