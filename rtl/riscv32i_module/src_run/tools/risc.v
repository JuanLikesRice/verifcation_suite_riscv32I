
   wire [N_param-1:0]	   instruction;
   wire [4:0]		   rd_o;
   wire [4:0]		   rs1_o;
   wire [4:0]		   rs2_o;
   wire [11:0]		   csr_o;
   wire [2:0]		   fun3_o;
   wire [6:0]		   fun7_o;
   wire [31:0]		   imm_o;
   wire [6:0]		   INST_typ_o, opcode_o;
   wire [63:0]		   Single_Instruction_o;
   wire			   i_en;
   wire [`size_X_LEN-1:0]  main2pc_initial_pc_i;
   wire			   reset;
   wire	       write_csr_wire,write_csr_wire_stage2;
   // Pre Stage 0
   wire [31:0] pc_stage_0,instruction_stage_0;
   wire	       we_pi;
   wire [31:0] pc_o,pc_i;
   wire [31:0] writeData_pi,operand1_po,operand2_po, csrData_pi;
   //stage 1 varibles
   wire [31:0] pc_stage_1;
   wire [31:0] instruction_stage_1;
   wire [ 4:0] rd_stage1;
   wire [ 2:0] fun3_stage1;
   wire [ 6:0] fun7_stage1;
   wire [ 6:0] INST_typ_stage1;
   wire [ 6:0] opcode_stage1;
   wire [ 4:0] rs1_stage1;
   wire [ 4:0] rs2_stage1;
   wire [11:0] csr_stage1;
   wire [31:0] csr_val_stage1;
   wire [31:0] operand1_stage1;
   wire [31:0] operand2_stage1;
   wire [31:0] imm_stage1;
   wire [63:0] Single_Instruction_stage1;
   wire [31:0] alu_result_1;
   wire [31:0] alu_result_2;


   //stage 2
   wire [31:0] pc_stage_2;
   wire [31:0] instruction_stage_2;
   wire [ 4:0] rd_stage2;
   wire [ 2:0] fun3_stage2;
   wire [ 6:0] fun7_stage2;
   wire [ 6:0] INST_typ_stage2;
   wire [ 6:0] opcode_stage2;
   wire [ 4:0] rs1_stage2;
   wire [ 4:0] rs2_stage2;
   wire [11:0] csr_stage2;
   wire [31:0] csr_val_stage2;
   wire [31:0] operand1_stage2;
   wire [31:0] operand2_stage2;
   wire [31:0] imm_stage2;
   wire [63:0] Single_Instruction_stage2;
   wire [31:0] alu_result_1_stage2;
   wire [31:0] alu_result_2_stage2;
   //Stage 3
   wire [31:0] pc_stage_3;
   wire [31:0] instruction_stage_3;
   wire [ 4:0] rd_stage3;
   wire [ 2:0] fun3_stage3;
   wire [ 6:0] fun7_stage3;
   wire [ 6:0] INST_typ_stage3;
   wire [ 6:0] opcode_stage3;
   wire [ 4:0] rs1_stage3;
   wire [ 4:0] rs2_stage3;
   wire [11:0] csr_stage3;
   wire [31:0] csr_val_stage3;
   wire [31:0] operand1_stage3;
   wire [31:0] operand2_stage3;
   wire [31:0] imm_stage3;
   wire [63:0] Single_Instruction_stage3;
   wire [31:0] alu_result_1_stage3;
   wire [31:0] alu_result_2_stage3;
   wire	       write_reg_file_wire_stage3;
   wire	       write_csr_wire_stage3;
   wire	       load_into_reg_stage3;
   wire [31:0] loaded_data_stage3;
   //Data Mem wires
   wire [31:0] loaded_data;
   wire	       load_into_reg;
   wire	       stall_mem_not_avalible;
   //Pc
   wire	       branch_inst_wire_stage2;
   wire	       jump_inst_wire_stage2;
   //Going into exect
   //exec 
   wire [31:0] operand1_into_exec;
   wire [31:0] operand2_into_exec;
   wire [31:0] result_secondary;
   wire	       jump_inst_wire,branch_inst_wire;
   //Hazard
   wire	       write_reg_file_wire_stage2;
   wire [31:0] rd_result_stage2;
   reg	       delete_reg1_reg2_reg;
   wire [31:0] csr_regfile_o;
   //Control signals 
   wire	       delete_reg1_reg2; 
   wire	       write_reg_stage3;
   wire	       write_reg_file_wire;
   wire	       data_clk;
   wire	       data_req_o;
   wire [31:0] data_addr_o;
   wire	       data_we_o;
   wire [3:0]  data_be_o;
   wire [31:0] data_wdata_o;
   wire [31:0] data_rdata_i;
   wire	       data_rvalid_i;
   wire	       data_gnt_i;
   wire [31:0] csr_into_exec;
   // param_module params ();
   reg			   halt_i;
   reg [511:0]		   pipeReg1, pipeReg2, pipeReg3;
   wire [63:0]		   pipeReg0_wire;
   wire [511:0]		   pipeReg1_wire, pipeReg2_wire, pipeReg3_wire;
   wire			   pc_valid;
   wire [31:0]		   final_value;
  wire [`pipe_len-1:0] u_pipeReg1_res, u_pipeReg2_res,u_pipeReg3_res;
   wire irq_prep;
   wire	enable_design;
   wire	pulsed_irq_prep;
   wire [31:0] interrupt_vector_i;
  wire	       initate_irq,end_condition,all_ready,ready_for_irq_handler,irq_service_done,irq_req_i;
   wire [31:0] irq_addr_i;
   wire	       irq_grant_o, override_all_stop;
   wire [31:0] nextPC_o;
   wire	       change_PC_condition_for_jump_or_branch;
   wire [31:0] mepc;
   wire	       mret_inst;
   wire	       pc_i_valid;
   wire	       stall_i;
   wire	       STALL_IF_not_ready_w,STALL_ID_not_ready_w;
   wire	       exec_stall;
   wire	       in_range_peripheral;
   wire	       data_req_o_intermediate;
