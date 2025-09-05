`default_nettype none
`include "params.vh"

module riscv32i
  # (
     parameter N_param = 32,
     parameter debug_param    = 0,
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
   reg [31:0]		       cycle_to_end;
   wire [31:0]		       control_signals_in;
   reg [31:0]		       Cycle_count  ;
   wire [31:0]		       memory_offset;
   wire [31:0]		       initial_pc_i ;
   wire [31:0]		       success_code  ;
   wire [31:0]		       final_value  ;


   wire			       ins_data_req_o;
   wire [31:0]		       ins_data_addr_o;
   wire			       ins_data_we_o;
   wire [ 3:0]		       ins_data_be_o;
   wire [31:0]		       ins_data_wdata_o;
   wire [31:0]		       ins_data_rdata_i;
   wire			       ins_data_rvalid_i;
   wire			       ins_data_gnt_i;



   wire			       Dmem_data_req_o;
   wire [31:0]		       Dmem_data_addr_o;
   wire			       Dmem_data_we_o;
   wire [ 3:0]		       Dmem_data_be_o;
   wire [31:0]		       Dmem_data_wdata_o;
   wire [31:0]		       Dmem_data_rdata_i;
   wire			       Dmem_data_rvalid_i;
   wire			       Dmem_data_gnt_i;


   wire			       Pmem_data_req_o;
   wire [31:0]		       Pmem_data_addr_o;
   wire			       Pmem_data_we_o;
   wire [ 3:0]		       Pmem_data_be_o;
   wire [31:0]		       Pmem_data_wdata_o;
   wire [31:0]		       Pmem_data_rdata_i;
   wire			       Pmem_data_rvalid_i;
   wire			       Pmem_data_gnt_i;



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
   riscv32i_main #(
		   .N_param(32),
         .debug_param(debug_param),
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

						 .ins_data_req_o    (    Dmem_data_req_o),
						 .ins_data_addr_o   (    Dmem_data_addr_o),
						 .ins_data_we_o     (    Dmem_data_we_o),
						 .ins_data_be_o     (    Dmem_data_be_o),
						 .ins_data_wdata_o  (    Dmem_data_wdata_o),
						 .ins_data_rdata_i  (    Dmem_data_rdata_i),
						 .ins_data_rvalid_i (    Dmem_data_rvalid_i),
						 .ins_data_gnt_i    (    Dmem_data_gnt_i),


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
						 .ins_data_req_o    (ins_data_req_o),
						 .ins_data_addr_o   (ins_data_addr_o),
						 .ins_data_we_o     (ins_data_we_o),
						 .ins_data_be_o     (ins_data_be_o),
						 .ins_data_wdata_o  (ins_data_wdata_o),
						 .ins_data_rdata_i  (ins_data_rdata_i),
						 .ins_data_rvalid_i (ins_data_rvalid_i),
						 .ins_data_gnt_i    (ins_data_gnt_i),
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
   


endmodule




module riscv32i_main 
  # (
     parameter N_param = 32,
      parameter debug_param = 0,
      parameter dispatch_print = 0
      

     ) (
	input wire	   clk,
	// input  wire reset,

	input wire [31:0]  Cycle_count,

	input wire [31:0]  control_signal,
	input wire [31:0]  memory_offset,
	input wire [31:0]  initial_pc_i,
	// output wire [31:0]  final_value,
	input wire [31:0]  success_code,
	output wire	   finished_program,

	// // BRAM ports for Data Mem// output wire        data_mem_clkb,// output wire        data_mem_enb,// output wire        data_mem_rstb,// output wire [3:0 ] data_mem_web,// output wire [31:0] data_mem_addrb,// output wire [31:0] data_mem_dinb,// input  wire        data_mem_rstb_busy,// input  wire [31:0] data_mem_doutb,

	// Memory interface signals
	output wire	   Dmem_clk,
	output wire	   Dmem_data_req_o,
	output wire [31:0] Dmem_data_addr_o,
	output wire	   Dmem_data_we_o,
	output wire [3:0]  Dmem_data_be_o,
	output wire [31:0] Dmem_data_wdata_o,
	input wire [31:0]  Dmem_data_rdata_i,
	input wire	   Dmem_data_rvalid_i,
	input wire	   Dmem_data_gnt_i,
	input wire	   timer_timeout,

	// peripheral interface signals
	output wire	   Pmem_clk,
	output wire	   Pmem_data_req_o,
	output wire [31:0] Pmem_data_addr_o,
	output wire	   Pmem_data_we_o,
	output wire [3:0]  Pmem_data_be_o,
	output wire [31:0] Pmem_data_wdata_o,
	input wire [31:0]  Pmem_data_rdata_i,
	input wire	   Pmem_data_rvalid_i,
	input wire	   Pmem_data_gnt_i,

	// //bram  Ins_mem// output wire        ins_mem_clkb,// output wire        ins_mem_enb,// output wire        ins_mem_rstb,// output wire [3:0 ] ins_mem_web,// output wire [31:0] ins_mem_addrb,// output wire [31:0] ins_mem_dinb,// input  wire        ins_mem_rstb_busy,// input  wire [31:0] ins_mem_doutb
	input wire	   Imem_clk,
	output wire	   ins_data_req_o,
	output wire [31:0] ins_data_addr_o,
	output wire	   ins_data_we_o,
	output wire [3:0]  ins_data_be_o,
	output wire [31:0] ins_data_wdata_o,
	input wire [31:0]  ins_data_rdata_i,
	input wire	   ins_data_rvalid_i,
	input wire	   ins_data_gnt_i

	);


wire [2:0] fun3_o;
wire [3:0] data_be_o;
wire [4:0] rd_o, rs1_o, rs2_o;
wire [ 4:0] rd_stage1, rd_stage2, rd_stage3, rs1_stage1, rs1_stage2, rs2_stage1, rs2_stage2;
wire [6:0] fun7_o, INST_typ_o, opcode_o;
wire [11:0] csr_o, csr_stage1, csr_stage2, csr_stage3;
wire [31:0] alu_result_1, alu_result_1_stage2, alu_result_1_stage3, alu_result_2, alu_result_2_stage2, alu_result_2_stage3, csr_into_exec, csr_regfile_o, csr_val_stage1, csr_val_stage2, csr_val_stage3, csrData_pi, data_addr_o, data_rdata_i, data_wdata_o, final_value, imm_o, imm_stage1, imm_stage2, imm_stage3, instruction_stage_0, instruction_stage_1, instruction_stage_2, instruction_stage_3, interrupt_vector_i, irq_addr_i, loaded_data, loaded_data_stage3, mepc, nextPC_o, operand1_into_exec, operand1_po, operand1_stage1, operand1_stage2, operand1_stage3, operand2_into_exec, operand2_po, operand2_stage1, operand2_stage2, operand2_stage3, pc_i, pc_o, pc_stage_0, pc_stage_1, pc_stage_2, pc_stage_3, rd_result_stage2, writeData_pi;
wire [63:0] pipeReg0_wire, Single_Instruction_o, Single_Instruction_stage1, Single_Instruction_stage2, Single_Instruction_stage3;
reg  [511:0] pipeReg1, pipeReg2, pipeReg3;
wire [511:0] pipeReg1_wire, pipeReg2_wire, pipeReg3_wire;
reg delete_reg1_reg2_reg, halt_i;
wire all_ready, branch_inst_wire, branch_inst_wire_stage2, change_PC_condition_for_jump_or_branch, data_clk, data_gnt_i, data_req_o, data_req_o_intermediate, data_rvalid_i, data_we_o, delete_reg1_reg2, enable_design, end_condition, exec_stall, i_en, in_range_peripheral, initate_irq, irq_grant_o, irq_prep, irq_req_i, irq_service_done, jump_inst_wire, jump_inst_wire_stage2, load_into_reg, load_into_reg_stage3, mret_inst, override_all_stop, pc_i_valid, pc_valid, pulsed_irq_prep, ready_for_irq_handler, reset, stall_i, STALL_ID_not_ready_w, STALL_IF_not_ready_w, stall_mem_not_avalible, we_pi, write_csr_wire, write_csr_wire_stage2, write_csr_wire_stage3, write_reg_file_wire, write_reg_file_wire_stage2, write_reg_file_wire_stage3, write_reg_stage3;
wire [N_param-1:0] instruction;
wire [`pipe_len-1:0] u_pipeReg1_res, u_pipeReg2_res, u_pipeReg3_res;
wire [`size_X_LEN-1:0] main2pc_initial_pc_i;
   // Writing to WB regsiter
   wire	       stage_WB_ready;  // Writestage ready for new register
   wire	       stage_MEM_done;  // Memstage done
   wire	       stage3_MEM_valid; // enables new write to PipeReg3
   wire	       stage_MEM_ready;   // MEM  ready for new register
   wire	       stage_EXEC_done;   // EXEC done
   wire	       stage2_EXEC_valid; // enables new write to PipeReg2
   wire	       stage_EXEC_ready;   // EXEC  ready for new register
   wire	       stage_DECO_done;   //  DECO done
   wire	       stage1_DECO_valid; // enables new write to PipeReg1
   wire	       stage_DECO_ready;   // DECO  ready for new register
   wire	       stage_IF_done;      //  IF    done
   wire	       stage0_IF_valid;   // enables new write to PipeReg0
   wire	       stage_IF_ready;   // IF  ready for PC register
   wire	       stop_request_overide_datamem, reset_able_datamem;  
   wire	       stop_request_overide_insmem, reset_able_insmem;  

   initial begin 
      halt_i          <= 0;
   end


   assign  initate_irq             = 1'b0;  
   assign  end_condition           = (final_value == success_code);  
   assign  all_ready               = 1'b0;  
   // assign  ready_for_irq_handler   = 1'b1;  //reset_able_datamem & reset_able_datamem;
     assign  ready_for_irq_handler   = reset_able_datamem & reset_able_datamem;

   assign  irq_service_done        = 1'b0;  
   assign  irq_req_i               = 1'b0;  
   assign  irq_addr_i              = 32'h0;
   //writing into destination reg
   assign write_reg_stage3 = write_reg_file_wire_stage3|load_into_reg_stage3;
   //flush from branch
   assign delete_reg1_reg2 = branch_inst_wire_stage2 | jump_inst_wire_stage2| irq_prep | mret_inst;
   //Value being wrtten to regfile in WBB stage, also may be forwarded to ALU
   assign writeData_pi     = load_into_reg_stage3 ? loaded_data_stage3 : alu_result_1_stage3;
   // assign csrData_pi       = alu_result_2_stage3;
   //Value being wrtten to regfile in MEM stage, also may be forwarded to ALU
   assign rd_result_stage2 = load_into_reg ? loaded_data : alu_result_1_stage2;

   assign  stop_request_overide_datamem = 1'b0;
   assign  stop_request_overide_insmem = 1'b0;
   assign mret_inst =   (Single_Instruction_stage2 == `inst_MRET);

   // assign Dmem_data_req_o = in_range_peripheral ?  1'b0 : Dmem_data_req_o_intermediate;
   // assign  Dmem_data_req_o   =    Dmem_data_req_o_intermediate;
   assign  Dmem_data_req_o   =   in_range_peripheral ? 1'b0                     : data_req_o_intermediate;
   assign  Pmem_data_req_o   =   in_range_peripheral ? data_req_o_intermediate  : 1'b0 ;
   assign Dmem_clk          = data_clk            ; 
   // assign Dmem_data_req_o   = data_req_o          ; 
   assign Dmem_data_addr_o  = data_addr_o         ; 
   assign Dmem_data_we_o    = data_we_o           ; 
   assign Dmem_data_be_o    = data_be_o           ; 
   assign Dmem_data_wdata_o = data_wdata_o        ; 
   assign Pmem_clk          =  data_clk           ;
   // assign Pmem_data_req_o   =  data_req_o         ;
   assign Pmem_data_addr_o  =  data_addr_o        ;
   assign Pmem_data_we_o    =  data_we_o          ;
   assign Pmem_data_be_o    =  data_be_o          ;
   assign Pmem_data_wdata_o =  data_wdata_o       ;
   assign data_rdata_i      = in_range_peripheral  ? Pmem_data_rdata_i             : Dmem_data_rdata_i     ;
   assign data_rvalid_i     = in_range_peripheral  ? Pmem_data_rvalid_i            : Dmem_data_rvalid_i    ;
   assign data_gnt_i        = in_range_peripheral  ? Pmem_data_gnt_i               : Dmem_data_gnt_i       ;
   assign stage_MEM_done    = ~stall_mem_not_avalible;
   assign stage_WB_ready    = 1'b1;
   assign stage3_MEM_valid  = stage_WB_ready & stage_MEM_done;
   assign stage_EXEC_done   = 1'b1;
   assign stage_MEM_ready   = stage3_MEM_valid; // 
   assign stage2_EXEC_valid = stage_MEM_ready & stage_EXEC_done;
   assign stage_DECO_done   = ~STALL_ID_not_ready_w;
   assign stage_EXEC_ready  = stage2_EXEC_valid; // 
   assign stage1_DECO_valid = stage_EXEC_ready & stage_DECO_done;

   assign stage_IF_done     = ~STALL_IF_not_ready_w;
   assign stage_DECO_ready  = stage1_DECO_valid; // 
   assign stage0_IF_valid   = stage_DECO_ready & stage_IF_done;
   assign stage_IF_ready   = stage0_IF_valid; // 

   //for PC counter 

   assign instruction_stage_0          =  delete_reg1_reg2_reg ? 32'h00000013 : instruction;
   assign     exec_stall = ~stage_EXEC_ready;
   assign       pc_i_valid = 1'b1;
   assign stall_i = ~stage0_IF_valid;

//MARKER AUTOMATED HERE START

   wire [63:0] pipeReg0_wire_debug;
   assign pipeReg0_wire_debug[31:0] = pc_stage_0;
   assign pipeReg0_wire_debug[`instruct] = instruction_stage_0;
   // assign pipeReg0_wire_debug[511:64] = pipeReg1[511:64];
if (debug_param == 1) begin 
   debug # (.Param_delay(5),.regCount(0), .pc_en(1)
            ) debug_0 (.i_clk(clk),.pipeReg({448'b0,pipeReg0_wire_debug}), .pc_o(pc_i), .Cycle_count(Cycle_count));
   debug # (.Param_delay(10),.regCount(1) ) debug_1 (.i_clk(clk), .pipeReg(u_pipeReg1_res));
   debug # (.Param_delay(15),.regCount(2) ) debug_2 (.i_clk(clk), .pipeReg(u_pipeReg1_res));
   debug # (.Param_delay(20),.regCount(3) ) debug_3 (.i_clk(clk), .pipeReg(u_pipeReg3_res));
end
   //MARKER AUTOMATED HERE END


   
   pulse_generator_1bit pulse_generator_1bit (
					      .clk(clk),
					      .in(  irq_prep),
					      .out( pulsed_irq_prep)
					      );

   main_fsm #(.debug_param(debug_param)) main_fsm (
					    .clk(                         clk),
					    .control_signal(              control_signal),
					    // .initate_irq(                 initate_irq),
					    .end_condition(               end_condition),
					    .all_ready(                   all_ready),
					    .ready_for_irq_handler(       ready_for_irq_handler),
					    // .irq_service_done(            irq_service_done),
					    .irq_req_i(                   irq_req_i),
					    .irq_addr_i(                  irq_addr_i),
					    .program_finished(            finished_program),
					    .irq_grant_o(                 irq_grant_o),
					    .override_all_stop(           override_all_stop),
					    .enable_design(               enable_design),
					    .reset(                       reset),
					    .write_csr(                   write_csr_wire_stage3),
					    .csrReg_write_dest_reg(       csr_stage3),
					    .csrReg_write_dest_reg_data(  csr_val_stage3),
					    .csrReg_read_src_reg(         csr_o),
					    .csrReg_read_src_reg_data(    csr_regfile_o),
					    .mepc(                        mepc),
					    .mret_inst(                   mret_inst),
					    .irq_prep(                    irq_prep),
					    .timer_timeout(               timer_timeout),
					    .nextPC_o(                                nextPC_o),
					    .pc_stage_2(                              pc_stage_2),
					    .change_PC_condition_for_jump_or_branch(  change_PC_condition_for_jump_or_branch),
					    .interrupt_vector_i(          interrupt_vector_i),
					    .Single_Instruction_stage2(Single_Instruction_stage2),
					    .initial_pc_i(          initial_pc_i),
					    .initial_pc_o(  main2pc_initial_pc_i)



					    );
   pc #(.debug_param(debug_param) ) pc  (
           .clk_i(clk),
           .reset_i(reset),
           .stage_IF_ready(stage_IF_ready),
           .jump_inst_wire(jump_inst_wire_stage2),
           .branch_inst_wire(branch_inst_wire_stage2),
           .targetPC_i(alu_result_2_stage2),
           .enable_design(enable_design),
           .pc_o(pc_i),
           .initial_pc_i(main2pc_initial_pc_i),
           .pc_valid(pc_valid),

           .nextPC_o(                                nextPC_o),
           .PC_jump_or_branch(  change_PC_condition_for_jump_or_branch),
           .interrupt_vector_i(                      interrupt_vector_i),
           .irq_prep(                                irq_prep),
           .mret_inst(                               mret_inst),
           .mepc(                                    mepc)
	   );

   ins_mem ins_mem (
		    .clk                 (clk),
		    .reset               (reset),
		    .pc_i                (pc_i),
		    .pc_i_valid          (pc_valid),
		    .STALL_IF_not_ready_w(STALL_IF_not_ready_w),
		    .STALL_ID_not_ready_w(STALL_ID_not_ready_w),
		    .instruction_o_w     (instruction),
		    .stall_i_EXEC        (exec_stall),
		    .abort_rvalid(        delete_reg1_reg2),

		    .stop_request_overide(      stop_request_overide_insmem),
		    .reset_able(                reset_able_insmem),



		    // Memory interface signals
		   //  .data_clk             (Imem_clk),
		    .data_req_o_w         (ins_data_req_o),
		    .data_addr_o_w        (ins_data_addr_o),
		    .data_we_o_w          (ins_data_we_o),
		    .data_be_o_w          (ins_data_be_o),
		    .data_wdata_o_w       (ins_data_wdata_o),
		    .data_rdata_i         (ins_data_rdata_i),
		    .data_rvalid_i        (ins_data_rvalid_i),
		    .data_gnt_i           (ins_data_gnt_i)
		    );



   reg_file #(.debug_param(debug_param))reg_file(
		     .clk(clk),
		     .reset(reset), 
		     .reg1_pi(rs1_o), 
		     .reg2_pi(rs2_o), 
		     .destReg_pi(rd_stage3),
		     .we_pi(write_reg_file_wire_stage3), 
		     .writeData_pi(writeData_pi), 
		     .operand1_po(operand1_po),
		     .operand2_po(operand2_po)
		     );
  
   decode #(.N_param(`size_X_LEN)) decode_debug
     (
      .i_clk(clk),
      .i_en(i_en),
      .instruction(instruction_stage_0),
      .rd_o(rd_o),
      .rs1_o(rs1_o),
      .csr_o(csr_o),
      .rs2_o(rs2_o),
      .fun3_o(fun3_o),
      .fun7_o(fun7_o),
      .imm_o(imm_o),
      .INST_typ_o(INST_typ_o),
      .opcode_o(opcode_o),
      .Single_Instruction_o(Single_Instruction_o)
      );
   execute  #(.N_param(`size_X_LEN), .debug_param(debug_param)) execute 
     (.i_clk(clk),    
      .Single_Instruction_i(Single_Instruction_stage1),
      .operand1_pi(operand1_into_exec),
      .operand2_pi(operand2_into_exec),
      .csr_op_in(csr_into_exec),
      .instruction(instruction_stage_1),
      .pc_i(pc_stage_1),
      .rd_i(rd_stage1),
      .rs1_i(rs1_stage1), 
      .rs2_i(rs2_stage1), 
      .csr_i(csr_stage1),
      .imm_i(imm_stage1),
      .alu_result_1(alu_result_1),
      .alu_result_2(alu_result_2),
      .branch_inst_wire(branch_inst_wire),
      .jump_inst_wire(jump_inst_wire),
      .write_reg_file_wire(write_reg_file_wire),
      .write_csr_wire(         write_csr_wire)
      
      );
   dataMem dataMem 
     (
      .final_value(               final_value),
      .clk(                       clk),
      .reset(                     reset),
      .Single_Instruction(        Single_Instruction_stage2),
      .address_i(                 alu_result_1_stage2),
      .storeData(                 operand2_stage2),
      .pc_i(                      pc_stage_2),
      .loadData_w(                loaded_data),
      .memory_offset(             memory_offset),
      .stall_mem_not_avalible(    stall_mem_not_avalible),
      .load_into_reg(             load_into_reg),
      .stop_request_overide(      stop_request_overide_datamem),
      .reset_able(                reset_able_datamem),
      .in_range_peripheral(       in_range_peripheral),
      //
      .data_clk(         data_clk                     ),
      .data_req_o(       data_req_o_intermediate ),
      .data_addr_o(      data_addr_o             ),
      .data_we_o(        data_we_o               ),
      .data_be_o(        data_be_o               ),
      .data_wdata_o(     data_wdata_o            ),
      .data_rdata_i(     data_rdata_i            ),
      .data_rvalid_i(    data_rvalid_i           ),
      .data_gnt_i(       data_gnt_i              )
      //


      );
   hazard #(.debug_param(debug_param)) hazard (
		  .clk(clk),
		  .rs1_stage1(rs1_stage1),
		  .rs2_stage1(rs2_stage1),
		  .destination_reg_stage2(rd_stage2),
		  .write_reg_stage2(write_reg_file_wire_stage2),
		  .destination_reg_stage3(rd_stage3),
		  .write_reg_stage3(write_reg_stage3),
		  .PC_stage1(pc_stage_1), 
		  .PC_stage2(pc_stage_2), 
		  .PC_stage3(pc_stage_3),
		  .rd_result_stage2(rd_result_stage2),
		  .writeData_pi(writeData_pi),
		  .operand1_stage1(operand1_stage1),
		  .operand1_into_exec(operand1_into_exec),
		  .operand2_into_exec(operand2_into_exec),
		  .operand2_stage1(operand2_stage1),


		  .csr_into_exec(csr_into_exec),

		  .csr_stage1(                               csr_stage1),
		  .csr_result_stage1(                    csr_val_stage1),

		  .csr_destination_reg_stage2(               csr_stage2),
		  .csr_write_reg_stage2(          write_csr_wire_stage2),
		  .csr_destination_reg_stage3(               csr_stage3),
		  .csr_write_reg_stage3(          write_csr_wire_stage3),
		  .csr_memstage_data(                    csr_val_stage2),
		  .csr_wbstage_data(                     csr_val_stage3)

		  );

    pipe_ff_fields u_pipeReg0 (
        .clk                  (clk),
        .rst                  (reset),
        .flush                (delete_reg1_reg2),
        .en                   (stage0_IF_valid&&enable_design),
        .i_PC_reg             (pc_i),
        // .i_instruct           (),
        .o_PC_reg             (pc_stage_0)
        // .o_instruct           (instr     `uction_stage_0),
    );

    pipe_ff_fields u_pipeReg1 (
        .clk                  (clk),
        .rst                  (reset),
        .flush                ( (~stage1_DECO_valid && stage2_EXEC_valid) || delete_reg1_reg2),
        .en                   ( ( stage1_DECO_valid && enable_design)),
        .o_bus                (u_pipeReg1_res),
      // inputs
      .i_PC_reg             (pc_stage_0         ),
      .i_instruct           (instruction_stage_0        ),
      .i_rd                 (rd_o            ),
      .i_opRs1_reg          (rs1_o),
      .i_opRs2_reg          (rs2_o),
      .i_op1_reg            (operand1_po),
      .i_op2_reg            (operand2_po),
      .i_immediate          (imm_o),
      .i_Single_Instruction (Single_Instruction_o),
      .i_csr_reg            (csr_o),
      .i_csr_reg_val        (csr_regfile_o),
      .o_PC_reg             (pc_stage_1                 ),        // outputs
      .o_instruct           (instruction_stage_1        ),
      .o_rd                 (rd_stage1                  ),
      .o_opRs1_reg          (rs1_stage1                 ),
      .o_opRs2_reg          (rs2_stage1                 ),
      .o_op1_reg            (operand1_stage1            ),
      .o_op2_reg            (operand2_stage1            ),
      .o_immediate          (imm_stage1                 ),
      .o_Single_Instruction (Single_Instruction_stage1  ),
      .o_csr_reg            (csr_stage1                 ),
      .o_csr_reg_val        (csr_val_stage1             )    );

    pipe_ff_fields u_pipeReg2 (
        .clk                  (clk),
        .rst                  (reset),
        .flush                (  delete_reg1_reg2),
        .en                   ( ( stage2_EXEC_valid && enable_design)),
        .o_bus                (u_pipeReg2_res),

        // input
        .i_PC_reg             (pc_stage_1             ),
        .i_instruct           (instruction_stage_1    ),
        .i_alu_res1           (alu_result_1           ),
        .i_csr_write_en       (write_csr_wire         ),
        .i_load_reg           (`size_load_reg'b0      ),
        .i_jump_en            (jump_inst_wire         ),
        .i_branch_en          (branch_inst_wire       ),
        .i_reg_write_en       (write_reg_file_wire    ),
        .i_LD_ready           (`size_LD_ready'b0      ),
        .i_SD_ready           (`size_SD_ready'b0      ),
        .i_rd                 (rd_stage1              ),
        .i_operand_amt        (`size_operand_amt'b0   ),
        .i_opRs1_reg          (rs1_stage1             ),
        .i_opRs2_reg          (rs2_stage1             ),
        .i_op1_reg            (operand1_into_exec     ),
        .i_op2_reg            (operand2_into_exec     ),
        .i_immediate          (imm_stage1             ),
        .i_alu_res2           (alu_result_2           ),
        .i_rd_data            (`size_rd_data'b0),
        .i_Single_Instruction (Single_Instruction_stage1),
        .i_data_mem_loaded    (`size_data_mem_loaded'b0),
        .i_csr_reg            (csr_stage1             ),
        .i_csr_reg_val        (alu_result_2           ),
        // outputs
        .o_PC_reg             (pc_stage_2             ),
        .o_instruct           (instruction_stage_2    ),
        .o_alu_res1           (alu_result_1_stage2    ),
        .o_csr_write_en       (write_csr_wire_stage2  ),
        // .o_load_reg           (alu_result_2           ),
        .o_jump_en            (jump_inst_wire_stage2  ),
        .o_branch_en          (branch_inst_wire_stage2),
        .o_reg_write_en       (write_reg_file_wire_stage2),
        // .o_LD_ready           (                      0),
        // .o_SD_ready           (                      0),
        .o_rd                 (rd_stage2              ),
        // .o_operand_amt        (                      0),
        .o_opRs1_reg          (rs1_stage2             ),
        .o_opRs2_reg          (rs2_stage2             ),
        .o_op1_reg            (operand1_stage2        ),
        .o_op2_reg            (operand2_stage2        ),
        .o_immediate          (imm_stage2             ),
        .o_alu_res2           (alu_result_2_stage2           ),
        // .o_rd_data            (                      0),
        .o_Single_Instruction (Single_Instruction_stage2),
        // .o_data_mem_loaded    (                      0),
        .o_csr_reg            (csr_stage2             ),
        .o_csr_reg_val        (csr_val_stage2           ));

    pipe_ff_fields u_pipeReg3 (
        .clk                  (clk),
        .rst                  (reset),
        .flush                (1'b0),
        .en                   ( ( stage3_MEM_valid && enable_design)),
        .o_bus                (u_pipeReg3_res),

        // input 
        .i_PC_reg             (pc_stage_2       ),
        .i_instruct           (instruction_stage_2),
        .i_alu_res1           (alu_result_1_stage2),
        .i_csr_write_en       (write_csr_wire_stage2),
        .i_load_reg           (load_into_reg      ),
        .i_jump_en            (`size_jump_en'b0   ),
        .i_branch_en          (`size_branch_en'b0 ),
        .i_reg_write_en       (write_reg_file_wire_stage2 ),
        .i_LD_ready           (`size_LD_ready'b0  ),
        .i_SD_ready           (`size_SD_ready'b0  ),
        .i_rd                 (rd_stage2          ),
        .i_operand_amt        (`size_operand_amt'b0),
        .i_opRs1_reg          (rs1_stage2         ),
        .i_opRs2_reg          (rs2_stage2         ),
        .i_op1_reg            (operand1_stage2    ),
        .i_op2_reg            (operand2_stage2    ),
        .i_immediate          (imm_stage2         ),
        .i_alu_res2           (alu_result_2_stage2),
        .i_rd_data            (`size_rd_data'b0   ),
        .i_Single_Instruction (Single_Instruction_stage2),
        .i_data_mem_loaded    (loaded_data        ),
        .i_csr_reg            (csr_stage2         ),
        .i_csr_reg_val        (csr_val_stage2     ),
        // outputs
        .o_PC_reg             (pc_stage_3             ),
        .o_instruct           (instruction_stage_3    ),
        .o_alu_res1           (alu_result_1_stage3    ),
        .o_csr_write_en       (write_csr_wire_stage3  ),
        .o_load_reg           (load_into_reg_stage3   ),
        // .o_jump_en            (  ),
        // .o_branch_en          (),
        .o_reg_write_en       (write_reg_file_wire_stage3),
        // .o_LD_ready           (                      0),
        // .o_SD_ready           (                      0),
        .o_rd                 (rd_stage3              ),
        // .o_operand_amt        (                      0),
        // .o_opRs1_reg          (             ),
        // .o_opRs2_reg          (             ),
        .o_op1_reg            (operand1_stage3        ),
        .o_op2_reg            (operand2_stage3        ),
        .o_immediate          (imm_stage3             ),
        .o_alu_res2           (alu_result_2_stage3           ),
        // .o_rd_data            (                      0),
        .o_Single_Instruction (Single_Instruction_stage3),
        .o_data_mem_loaded    (     loaded_data_stage3),
        .o_csr_reg            (csr_stage3             ),
        .o_csr_reg_val        (csr_val_stage3           ));


always @(posedge clk)begin
  if (reset) begin 
    delete_reg1_reg2_reg <=0;
  end else if (enable_design) begin
    delete_reg1_reg2_reg <= delete_reg1_reg2;
  end 
end 



endmodule
