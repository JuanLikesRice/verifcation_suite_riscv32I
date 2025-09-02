
      wire [2:0] fun3_o;
   wire [ 2:0] fun3_stage1, fun3_stage2, fun3_stage3;
   wire [3:0] data_be_o;
   wire [4:0] rd_o, rs1_o, rs2_o;
   wire [ 4:0] rd_stage1, rd_stage2, rd_stage3, rs1_stage1, rs1_stage2, rs1_stage3, rs2_stage1, rs2_stage2, rs2_stage3;
   wire [6:0] fun7_o, INST_typ_o, opcode_o;
   wire [ 6:0] fun7_stage1, fun7_stage2, fun7_stage3, INST_typ_stage1, INST_typ_stage2, INST_typ_stage3, opcode_stage1, opcode_stage2, opcode_stage3;
   wire [11:0] csr_o, csr_stage1, csr_stage2, csr_stage3;
   wire [31:0] alu_result_1, alu_result_1_stage2, alu_result_1_stage3, alu_result_2, alu_result_2_stage2, alu_result_2_stage3, csr_into_exec, csr_regfile_o, csr_val_stage1, csr_val_stage2, csr_val_stage3, csrData_pi, data_addr_o, data_rdata_i, data_wdata_o, final_value, imm_o, imm_stage1, imm_stage2, imm_stage3, instruction_stage_0, instruction_stage_1, instruction_stage_2, instruction_stage_3, interrupt_vector_i, irq_addr_i, loaded_data, loaded_data_stage3, mepc, nextPC_o, operand1_into_exec, operand1_po, operand1_stage1, operand1_stage2, operand1_stage3, operand2_into_exec, operand2_po, operand2_stage1, operand2_stage2, operand2_stage3, pc_i, pc_o, pc_stage_0, pc_stage_1, pc_stage_2, pc_stage_3, rd_result_stage2, result_secondary, writeData_pi;
   wire [63:0] pipeReg0_wire, Single_Instruction_o, Single_Instruction_stage1, Single_Instruction_stage2, Single_Instruction_stage3;
   reg [511:0] pipeReg1, pipeReg2, pipeReg3;
   wire [511:0] pipeReg1_wire, pipeReg2_wire, pipeReg3_wire;
   reg delete_reg1_reg2_reg, halt_i;
   wire all_ready, branch_inst_wire, branch_inst_wire_stage2, change_PC_condition_for_jump_or_branch, data_clk, data_gnt_i, data_req_o, data_req_o_intermediate, data_rvalid_i, data_we_o, delete_reg1_reg2, enable_design, end_condition, exec_stall, i_en, in_range_peripheral, initate_irq, irq_grant_o, irq_prep, irq_req_i, irq_service_done, jump_inst_wire, jump_inst_wire_stage2, load_into_reg, load_into_reg_stage3, mret_inst, override_all_stop, pc_i_valid, pc_valid, pulsed_irq_prep, ready_for_irq_handler, reset, stall_i, STALL_ID_not_ready_w, STALL_IF_not_ready_w, stall_mem_not_avalible, we_pi, write_csr_wire, write_csr_wire_stage2, write_csr_wire_stage3, write_reg_file_wire, write_reg_file_wire_stage2, write_reg_file_wire_stage3, write_reg_stage3;
   wire [N_param-1:0] instruction;
   wire [`pipe_len-1:0] u_pipeReg1_res, u_pipeReg2_res, u_pipeReg3_res;
   wire [`size_X_LEN-1:0] main2pc_initial_pc_i;
