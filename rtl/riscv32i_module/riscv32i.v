`default_nettype none
`include "params.vh"

module riscv32i 
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
wire [31:0] alu_result_1, alu_result_1_stage2, alu_result_1_stage3, alu_result_2, alu_result_2_stage2, alu_result_2_stage3, csr_into_exec, csr_regfile_o, csr_val_stage1, csr_val_stage2, csr_val_stage3, csrData_pi, data_addr_o, data_rdata_i, data_wdata_o, final_value, imm_o, imm_stage1, imm_stage2, imm_stage3, instruction_stage_0, instruction_stage_1, instruction_stage_2, instruction_stage_3, interrupt_vector_i, irq_addr_i, loaded_data, loaded_data_stage3, mepc, nextPC_o, operand1_into_exec, operand1_po, operand1_stage1, operand1_stage2, operand1_stage3, operand2_into_exec, operand2_po, operand2_stage1, operand2_stage2, operand2_stage3, pc_i,pc_o, pc_stage_0, pc_stage_1, pc_stage_2, pc_stage_3, rd_result_stage2, writeData_pi;
wire [63:0] pipeReg0_wire, Single_Instruction_o, Single_Instruction_stage1, Single_Instruction_stage2, Single_Instruction_stage3;
reg  [511:0] pipeReg1, pipeReg2, pipeReg3;
wire [511:0] pipeReg1_wire, pipeReg2_wire, pipeReg3_wire;
reg delete_reg1_reg2_reg, halt_i;
wire all_ready, branch_inst_wire, branch_inst_wire_stage2, change_PC_condition_for_jump_or_branch, data_clk, data_gnt_i, data_req_o, data_req_o_intermediate, data_rvalid_i, data_we_o, delete_reg1_reg2, enable_design, end_condition, exec_stall, i_en, in_range_peripheral, initate_irq, irq_grant_o, irq_prep, irq_req_i, irq_service_done, jump_inst_wire, jump_inst_wire_stage2, load_into_reg, load_into_reg_stage3, mret_inst, override_all_stop, pc_i_valid, pc_valid, pulsed_irq_prep, ready_for_irq_handler, reset, stall_i, STALL_DECODE, STALL_FETCH, stall_MEMSTAGE, we_pi, write_csr_wire, write_csr_wire_stage2, write_csr_wire_stage3, write_reg_file_wire, write_reg_file_wire_stage2, write_reg_file_wire_stage3, write_reg_stage3;
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
 
   wire stage0_reg_empty, stage1_reg_empty, stage2_reg_empty, stage3_reg_empty;
   wire stage0_en,stage1_en,stage2_en,stage3_en;
   wire stage0_flush,stage1_flush,stage2_flush,stage3_flush;
   wire insM_ivalid;

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

         //   .en                   ( ( stage3_MEM_valid && enable_design)),
   assign stage3_en           =  stage3_MEM_valid;
   assign stage3_flush        =   1'b0 ;
   
   assign stage_MEM_done    = ~stall_MEMSTAGE;
   assign stage3_MEM_valid  = stage_MEM_done;
   assign stage_MEM_ready   = stage3_MEM_valid || stage2_reg_empty; // 

   assign stage2_en           =  ~stage1_reg_empty && stage_MEM_ready;
   assign stage2_flush        =  delete_reg1_reg2 || (stage1_reg_empty && stage_MEM_ready) ;
   
   assign stage_EXEC_done   = 1'b1;
   assign stage2_EXEC_valid = (stage_MEM_ready && stage_EXEC_done);
   assign stage_EXEC_ready  = stage2_EXEC_valid || stage1_reg_empty; // 
   
   assign stage1_en           =  ~stage0_reg_empty && stage_EXEC_ready; // no decode valid, its always valid
   assign stage1_flush        =  delete_reg1_reg2 || (stage0_reg_empty && stage_EXEC_ready) ;

   assign STALL_DECODE        = 1'b0;
   assign stage_DECO_ready    = (~STALL_DECODE && stage_EXEC_ready) || stage0_reg_empty; // 

   assign stage0_en           =  (insM_ivalid && stage_DECO_ready )&& enable_design;
   assign stage0_flush        =  delete_reg1_reg2 || (~insM_ivalid && stage_DECO_ready) ;

   //for PC counter 
   assign stage_IF_ready      = ~STALL_FETCH; // ready for PC reg to update



   
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

// FIXME  pc_valid_r in case of enable design OFF, then on again
   pc #(.debug_param(debug_param) ) pc  (
           .clk_i(               clk),
           .reset_i(             reset),
           .Fetch_wants_next_PC(    stage_IF_ready),
           .jump_inst_wire(         jump_inst_wire_stage2),
           .branch_inst_wire(       branch_inst_wire_stage2),
           .targetPC_i(             alu_result_2_stage2),
           .enable_design(          enable_design),
           .pc_o(                   pc_i),
           .initial_pc_i(           main2pc_initial_pc_i),
           .pc_valid(               pc_valid),

           .nextPC_o(               nextPC_o),
           .PC_jump_or_branch(      change_PC_condition_for_jump_or_branch),
           .interrupt_vector_i(     interrupt_vector_i),
           .irq_prep(               irq_prep),
           .mret_inst(              mret_inst),
           .mepc(                   mepc)
	   );

   ins_mem ins_mem (
		    .clk                 ( clk),
		    .reset               ( reset),
		    .pc_i                ( pc_i),
		    .pc_i_valid          ( pc_valid),
		    .STALL_FETCH(          STALL_FETCH),
		    .STALL_DECODE(         ~stage_DECO_ready),
		    .instruction_o_w(      instruction),
		    .abort_rvalid(         delete_reg1_reg2),
		    .reset_able(           reset_able_insmem),
         .instruction_valid(     insM_ivalid),
         .pc_o(pc_o),
         .enable_design(enable_design),
         //  .stop_request_overide(      stop_request_overide_insmem),
		   //  .stall_in             (exec_stall),
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

    pipe_ff_fields u_pipeReg0 (
        .clk                  (clk),
        .rst                  (reset),
        .flush                (stage0_flush),
        .en                   (stage0_en   ),
        .i_PC_reg             (pc_o),
        .i_instruct           (instruction),
        .o_PC_reg             (pc_stage_0),
        .o_instruct           (instruction_stage_0),
        .o_rst_value          (stage0_reg_empty)
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

    pipe_ff_fields u_pipeReg1 (
        .clk                  (clk),
        .rst                  (reset),
        .flush                (stage1_flush),// (~stage1_DECO_valid && stage2_EXEC_valid) || delete_reg1_reg2),
        .en                   (stage1_en   ),// ( stage1_DECO_valid && enable_design)),
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
      .o_csr_reg_val        (csr_val_stage1             ),
      .o_rst_value          (stage1_reg_empty)
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
      .stall_mem_not_avalible(    stall_MEMSTAGE),
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





    pipe_ff_fields u_pipeReg2 (
        .clk                  (clk),
        .rst                  (reset),
        .flush                (stage2_flush),//  delete_reg1_reg2),
        .en                   (stage2_en   ),// ( stage2_EXEC_valid && enable_design)),
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
        .o_csr_reg_val        (csr_val_stage2           ),
      .o_rst_value          (stage2_reg_empty)
        );

    pipe_ff_fields u_pipeReg3 (
        .clk                  (clk),
        .rst                  (reset),
        .flush                (stage3_flush),//1'b0),
        .en                   (stage3_en   ),// ( stage3_MEM_valid && enable_design)),
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
        .o_csr_reg_val        (csr_val_stage3           ),
        .o_rst_value          (stage3_reg_empty)
        );


always @(posedge clk)begin
  if (reset) begin 
    delete_reg1_reg2_reg <=0;
  end else if (enable_design) begin
    delete_reg1_reg2_reg <= delete_reg1_reg2;
  end 
end 



//MARKER AUTOMATED HERE START

   wire [63:0] pipeReg0_wire_debug;
   assign pipeReg0_wire_debug[31:0] = pc_stage_0;
   assign pipeReg0_wire_debug[`instruct] = instruction_stage_0;
   // assign pipeReg0_wire_debug[511:64] = pipeReg1[511:64];
if (debug_param == 1) begin 
   debug # (.Param_delay(5),.regCount(0), .pc_en(1)
            ) debug_0 (.i_clk(clk),.pipeReg({448'b0,pipeReg0_wire_debug}), .pc_o(pc_i), .Cycle_count(Cycle_count));
   debug # (.Param_delay(10),.regCount(1) ) debug_1 (.i_clk(clk), .pipeReg(u_pipeReg1_res));
   debug # (.Param_delay(15),.regCount(2) ) debug_2 (.i_clk(clk), .pipeReg(u_pipeReg2_res));
   debug # (.Param_delay(20),.regCount(3) ) debug_3 (.i_clk(clk), .pipeReg(u_pipeReg3_res));
end
   //MARKER AUTOMATED HERE END



endmodule

