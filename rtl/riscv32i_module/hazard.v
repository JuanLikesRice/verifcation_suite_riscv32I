module hazard #(
        parameter debug_param = 1
)(


	       input wire	  clk, 
		   input 		  rst,
	       input wire [4:0]	  rs1_stage1,             // Source Register  1  of instruction in EX stage
	       input wire [4:0]	  rs2_stage1,             // Source  Register 2  of instruction in EX stage
	       input wire [11:0]  csr_stage1,             // Source  Register 2  of instruction in EX stage

	       input wire [4:0]	  destination_reg_stage2, // Destination register of instruction in MEM stage (EX/MEM pipeline register)
	       input wire	      write_reg_stage2, 	  // Write Enable signal of instruction in MEM stage
	       input wire [4:0]	  destination_reg_stage3, // Destination register of instruction in WB stage (MEM/WB pipeline register)
	       input wire	      write_reg_stage3,       // Write Enable signal of instruction in WB stage

	       input wire [11:0]  csr_destination_reg_stage3, 	// Destination register of instruction in MEM stage (EX/MEM pipeline register)
	       input wire	      csr_write_reg_stage3, 		// Write Enable signal of instruction in MEM stage
	       input wire [11:0]  csr_destination_reg_stage2, 	// Destination register of instruction in MEM stage (EX/MEM pipeline register)
	       input wire	      csr_write_reg_stage2, 		// Write Enable signal of instruction in MEM stage
		   
	       input wire [31:0]  PC_stage1,
	       input wire [31:0]  PC_stage2,
	       input wire [31:0]  PC_stage3,

	       input wire [31:0]  rd_result_stage3,
	       input wire [31:0]  csr_wbstage_data,

	       input wire [31:0]  csr_memstage_data,
	       input wire [31:0]  csr_result_stage1,
	       output wire [31:0] csr_into_exec,

	       input wire [31:0]  rd_result_stage2,
	       input wire [31:0]  operand1_stage1,

	       input  wire [31:0]  	operand2_stage1,
	       output wire [31:0] 	operand2_into_exec,
		   input  wire 			memstage_load_into_reg,
		   input  wire 			load_data_valid,

	       output wire [31:0] operand1_into_exec,
		   output wire 			rs1_rs2_valid,
		   output wire exec_fwd1  ,
		   output wire exec_fwd2  ,
		   output wire exec_fwdCSR

	       );
   wire [1:0]			  src1Forward_alu;            // 2-bit signal indicating the actual data source for operand 1
   wire [1:0]			  src2Forward_alu;            // 2-bit signal indicating the actual data source for operand 2
   wire [1:0]			  csrForward_alu;            // 2-bit signal indicating the actual data source for operand 2
   
   wire				  memFwd1, wbFwd1;
   wire				  memFwd2, wbFwd2;
   wire				  csr_memFwd, csr_wbFwd;
	wire awaiting_LDmemresult,valid_LDmemresult;


   //foward from stage2 MEM reg to exec for CSR
   	assign csr_memFwd 	=  (csr_destination_reg_stage2  == csr_stage1) &&  csr_write_reg_stage2;
   	assign csr_wbFwd  	=  (csr_destination_reg_stage3  == csr_stage1) &&  csr_write_reg_stage3;
   	assign csr_into_exec =  csr_memFwd ? (csr_memstage_data) :( csr_wbFwd ? csr_wbstage_data   : csr_result_stage1  ) ;
   
	assign exec_fwd1   = wbFwd1 | memFwd1;
	assign exec_fwd2   = wbFwd2 | memFwd2;
	assign exec_fwdCSR = csr_memFwd|csr_wbFwd;
	
   	assign memFwd1 =  (destination_reg_stage2  == rs1_stage1) &&  write_reg_stage2; //foward from stage2 MEM reg to exec for RS1   	
   	assign  wbFwd1 =  (destination_reg_stage3  == rs1_stage1) &&  write_reg_stage3; //foward from stage3 WB  reg to exec for RS1
   	assign operand1_into_exec =  memFwd1 ? (rd_result_stage2) :(wbFwd1 ? rd_result_stage3 : operand1_stage1 ) ;

   	assign memFwd2 =  (rs2_stage1 == destination_reg_stage2)  &&  write_reg_stage2; //foward from stage2 MEM reg to exec for RS2
   	assign  wbFwd2 =  (rs2_stage1 == destination_reg_stage3)  &&  write_reg_stage3; //foward from stage3 WB  reg to exec for RS3
   	assign operand2_into_exec =  memFwd2 ? (rd_result_stage2) :(wbFwd2 ? rd_result_stage3 : operand2_stage1 ) ;
   
	assign  awaiting_LDmemresult = ((memstage_load_into_reg && ~load_data_valid) && (memFwd1|memFwd2|csr_memFwd));
	assign     valid_LDmemresult =  (memstage_load_into_reg &&  load_data_valid);
	assign        rs1_rs2_valid  =  ~awaiting_LDmemresult ;


	// localparam [1:0] S_0 = 2'b00, S_1 = 2'b01, S_2 = 2'b10, S_3 = 2'b11;
	// reg	       [1:0] current_state, next_state;
	// if rs1_rs2_valid && EXEC_STALL
	// always @ (posedge i_clk) begin 
	// 	if (rst) begin 
	// 		current_state <= S_0;
	// 	end else begin 
	// 		current_state <= next_state;
	// 	end
	// end
	// always @(*) begin 
	// 	case(current_state) 
	// 		S_0: begin
	// 			if (start_processing) begin 
	// 				stall_reg <= 1;
	// 				next_state <= S_1;
	// 			end else begin 
	// 				stall_reg <= 0;
	// 				next_state <= S_0;
	// 			end
	// 		 end
	// 		S_1: begin
	// 			if (process_end) begin 
	// 				if (accept_out) begin
	// 					stall_reg  <= 0;
	// 					next_state <= S_0;
	// 				end else begin 
	// 					stall_reg  <= 1;
	// 					next_state <= S_2;
	// 				end 
	// 			end else begin 
	// 				stall_reg  <= 1;
	// 				next_state <= S_1;
	// 			end
	// 		 end
	// 		S_2: begin
	// 			if (accept_out) begin 
	// 				stall_reg  <= 0;
	// 				next_state <= S_0;
	// 			end else begin 
	// 				stall_reg  <= 1;
	// 				next_state <= S_2;
	// 			end
	// 		 end
		
	// 	endcase
	// end 


    assign csrForward_alu	 = csr_memFwd ?  2'b10 : csr_wbFwd ? 2'b01 : 2'b00;
	assign src1Forward_alu 	 = memFwd1    ?  2'b10 : wbFwd1    ? 2'b01 : 2'b00;
	assign src2Forward_alu 	 = memFwd2    ?  2'b10 : wbFwd2    ? 2'b01 : 2'b00;

if (debug_param == 1) begin
   always @(negedge clk) begin
      #25

	if (memFwd1|wbFwd1)begin 
	   case(src1Forward_alu)
	     2'b11: begin $write("\n HAZARD: memFwd1 <wbFwd1 also qualified but will not take>, RS1 Stage2  to ALU %5d, PC from stage 2: %8h forwarded to PC %8h, Forwarded value %8h", rs1_stage1,PC_stage2,PC_stage1,operand1_into_exec );end
	     2'b10: begin $write("\n HAZARD: memFwd1, RS1 Stage2  to ALU %5d, PC from stage 2: %8h forwarded to PC %8h, Forwarded value %8h", rs1_stage1,PC_stage2,PC_stage1,operand1_into_exec );end
	     2'b01: begin $write("\n HAZARD: wbFwd1,  RS1 Stage3  to ALU %5d, PC from stage 3: %8h forwarded to PC %8h, Forwarded value %8h", rs1_stage1,PC_stage3,PC_stage1,operand1_into_exec );end
	   endcase
	end

      if (memFwd2|wbFwd2)begin 
	 case(src2Forward_alu)
	   2'b11: begin       $write("\n HAZARD: memFwd2 <wbFwd2 also qualified but will not take>, RS2 Stage2  to ALU %5d, PC from stage 2: %8h forwarded to PC %8h, Forwarded value %8h", rs2_stage1,PC_stage2,PC_stage1,operand2_into_exec );end
	   2'b10: begin       $write("\n HAZARD: memFwd2, RS2 Stage2  to ALU %5d, PC from stage 2: %8h forwarded to PC %8h, Forwarded value %8h", rs2_stage1,PC_stage2,PC_stage1,operand2_into_exec );end
	   2'b01: begin       $write("\n HAZARD: wbFwd2,  RS2 Stage3  to ALU %5d, PC from stage 3: %8h forwarded to PC %8h, Forwarded value %8h", rs2_stage1,PC_stage3,PC_stage1,operand2_into_exec );end
	 endcase
      end


      if (csr_memFwd|csr_wbFwd)begin 
	 case(csrForward_alu)
	   2'b11: begin       $write("\n HAZARD: csr_memFwd <wbFwd1 also qualified but will not take>, C_RS Stage2  to ALU %5d, PC from stage 2: %8h forwarded to PC %8h, Forwarded value %8h", csr_stage1,PC_stage2,PC_stage1,csr_into_exec );end
	   2'b10: begin       $write("\n HAZARD: csr_memFwd, C_RS Stage2  to ALU %5d, PC from stage 2: %8h forwarded to PC %8h, Forwarded value %8h",                                           csr_stage1,PC_stage2,PC_stage1,csr_into_exec );end
	   2'b01: begin       $write("\n HAZARD: csr_wbFwd,  C_RS Stage3  to ALU %5d, PC from stage 3: %8h forwarded to PC %8h, Forwarded value %8h",                                           csr_stage1,PC_stage3,PC_stage1,csr_into_exec );end
	 endcase
      end
   end
end


endmodule


