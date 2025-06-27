module pc(
input wire 			clk_i,
input wire 			reset_i,
input wire 			stage_IF_ready,
input wire 			jump_inst_wire, 
input wire 			branch_inst_wire,
input wire 			enable_design, 
input wire 	[31:0] 	targetPC_i,
input wire 	[31:0] 	initial_pc_i,
output wire [31:0] 	pc_o,
output wire		  	pc_valid,
output wire [31:0] 	nextPC_o,
output wire 		change_PC_condition_for_jump_or_branch,

input wire			mret_inst,

input wire [31:0]   interrupt_vector_i, // Interrupt vector address
input wire [31:0]   mepc, // Interrupt vector address
input wire 			irq_prep

);

reg  [31:0] PC;
wire [31:0] nextPC;
wire [31:0] nextPC_intermediate_0,nextPC_intermediate_1;
reg pc_valid_r;
// wire change_PC_condition_for_jump_or_branch;
assign change_PC_condition_for_jump_or_branch = jump_inst_wire | branch_inst_wire;

wire override_change_PC_condition_for_jump_or_branch;
assign override_change_PC_condition_for_jump_or_branch =  irq_prep;

assign nextPC_intermediate_0 	= change_PC_condition_for_jump_or_branch 			?  targetPC_i  			: PC + 4;
assign nextPC_intermediate_1	= override_change_PC_condition_for_jump_or_branch 	?  interrupt_vector_i  	: nextPC_intermediate_0;
assign nextPC					= mret_inst 										?  mepc  				: nextPC_intermediate_1;



assign pc_o = PC;
assign pc_valid = enable_design ;//pc_valid_r;
assign nextPC_o = nextPC;

always @(posedge clk_i) begin
//     $display("Time: %3d\thalt: %d\tisTakenBranch: %d\tnextPC: %d\tpc_po: %d",$time, halt_pi, isTakenBranch_pi, PC, pc_po);
  	 if (reset_i) begin
		pc_valid_r  <= 1'b1;
	    PC  		<= initial_pc_i; //32'h1CC;
      //Starting memory address, this logic must be changed later
	end else  if (enable_design) begin
            // PC <= nextPC;

 	    if (stage_IF_ready|change_PC_condition_for_jump_or_branch)  begin
            PC <= nextPC;
			pc_valid_r <= 1'b1;
		end 
		else begin
		pc_valid_r <= 1'b0;
		// PC <= nextPC;
		end
  end
end
//MARKER AUTOMATED HERE START

always @(negedge clk_i) begin
	#30
	if (jump_inst_wire)    begin $write("\nPC_module: JUMP!   Next cycle, New PC: %8h, Destroyed PC %8h", targetPC_i,PC + 4);end
	if (branch_inst_wire ) begin $write("\nPC_module: BRANCH! Next cycle, New PC: %8h, Destroyed PC %8h", targetPC_i,PC + 4);end

end

//MARKER AUTOMATED HERE END


   
endmodule
