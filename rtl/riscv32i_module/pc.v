module pc  #(
        parameter debug_param = 1
)(
	  input wire			clk_i,
	  input wire			reset_i,
	  input wire			stage_IF_ready,
	  input wire			jump_inst_wire, 
	  input wire			branch_inst_wire,
	  input wire			enable_design, 

	  input wire [`size_X_LEN-1:0]	targetPC_i,   		// branch jump instruction destinatiom
	  input wire [`size_X_LEN-1:0]	initial_pc_i, 		// starting pc on boot
	  input wire [`size_X_LEN-1:0]	interrupt_vector_i, // PC to jump to in vector vector address

	  output wire [`size_X_LEN-1:0]	pc_o, //definitive PC to jump to
	  output wire			        pc_valid, //PC valid
	  output wire [`size_X_LEN-1:0]	nextPC_o,
	  output wire			PC_jump_or_branch,


	  // interr
	  input wire			mret_inst,
	  input wire [`size_X_LEN-1:0]	mepc, // Interrupt vector address
	  input wire			irq_prep
	  );

   reg [`size_X_LEN-1:0]		PC;
   wire [`size_X_LEN-1:0]		nextPC;
   wire [`size_X_LEN-1:0]		nextPC_intermediate_0,nextPC_intermediate_1;
   reg	pc_valid_r;
   wire	override_PC;
   reg	state_r;
   wire	pc_valid_next;

   assign PC_jump_or_branch 	= jump_inst_wire | branch_inst_wire;
   assign override_PC 			= irq_prep;
   assign nextPC_intermediate_0 = PC_jump_or_branch ?  targetPC_i  			: PC + 4;
   assign nextPC_intermediate_1 = override_PC 		?  interrupt_vector_i	: nextPC_intermediate_0;
   assign nextPC				= mret_inst 		?  mepc  				: nextPC_intermediate_1;
   assign pc_o 					= PC;
   assign pc_valid 				= enable_design;
   assign nextPC_o 				= nextPC;

   assign pc_valid_next = stage_IF_ready|PC_jump_or_branch|override_PC|mret_inst; 

   always @(posedge clk_i) begin
		if (reset_i) begin
	 		pc_valid_r  <= 1'b0;
	 		state_r		<= 1'b1; // reset stage
    	end else  if (enable_design) begin
	 		if (state_r) begin
	 		   PC 		<= initial_pc_i; // start of new code
	 		   state_r <= 1'b0;
	 		end 
			else if (pc_valid_next)  begin
     		    PC <= nextPC;
	 		   	pc_valid_r <= 1'b1;
	 		end 
				else begin
				pc_valid_r <= 1'b0;
				end
    	end
	end

if (debug_param == 1) begin 
   //MARKER AUTOMATED HERE START
   always @(negedge clk_i) begin
      #30
	if (jump_inst_wire)    begin $write("\nPC_module: JUMP!   Next cycle, New PC: %8h, Destroyed PC %8h", targetPC_i,PC + 4);end
      if (branch_inst_wire ) begin $write("\nPC_module: BRANCH! Next cycle, New PC: %8h, Destroyed PC %8h", targetPC_i,PC + 4);end
   end
   //MARKER AUTOMATED HERE END
end

   
endmodule
