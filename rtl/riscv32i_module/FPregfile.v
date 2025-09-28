
module Fp_reg_file #(
        parameter debug_param = 1
)(
		input wire	       clk,
		input wire	       reset, 
		input wire [5:0]   Fp_reg1_pi   , 
		input wire [5:0]   Fp_reg2_pi   , 
		input wire [5:0]   Fp_destReg_pi,
		input wire	       Fp_we_pi,
		input wire [31:0]  Fp_writeData_pi, 
		output wire [31:0] Fp_operand1_po,
		output wire [31:0] Fp_operand2_po
		);
   wire				   cntrl1, cntrl2;

   reg [31:0]			   Fp_REG_FILE[0:31];  // 32 32-bit registers
     wire [5:0]   FILTERED_Fp_reg1_pi   ;
     wire [5:0]   FILTERED_Fp_reg2_pi   ;
     wire [5:0]   FILTERED_Fp_destReg_pi;
   
    assign FILTERED_Fp_reg1_pi    = {5{Fp_reg1_pi   [5]}} & Fp_reg1_pi   [4:0]; 
    assign FILTERED_Fp_reg2_pi    = {5{Fp_reg2_pi   [5]}} & Fp_reg2_pi   [4:0]; 
    assign FILTERED_Fp_destReg_pi = {5{Fp_destReg_pi[5]}} & Fp_destReg_pi[4:0]; 



   // read while writing in WB stage   
   assign cntrl1      =  (FILTERED_Fp_reg1_pi  == FILTERED_Fp_destReg_pi) &&  Fp_we_pi;
   assign cntrl2      =  (FILTERED_Fp_reg2_pi  == FILTERED_Fp_destReg_pi) &&  Fp_we_pi;

   assign Fp_operand1_po              = cntrl1    ? Fp_writeData_pi : Fp_REG_FILE[FILTERED_Fp_reg1_pi];
   assign Fp_operand2_po              = cntrl2    ? Fp_writeData_pi : Fp_REG_FILE[FILTERED_Fp_reg2_pi];

   integer			   j;
   // integer p;

   initial begin 
      for (j=0; j < 32; j=j+1)begin 
	 Fp_REG_FILE[j] = 32'b0;	 
      end
   end
   integer i;
   integer o;

   always @(posedge clk) begin
      if (reset) begin 
         for (i=0; i < 32; i=i+1) begin 
	    Fp_REG_FILE[i] <= 32'b0;	
         end
      end else begin 
	 if (Fp_we_pi)  begin 
	    Fp_REG_FILE[FILTERED_Fp_destReg_pi] <= Fp_writeData_pi;
         end
      end
   end


generate
if (debug_param) begin : debug_fpRegfile
   //MARKER AUTOMATED HERE START
   integer k;
   integer n;
   always @(negedge clk) begin
      #100
	$write("\n\nFP32 REGFILE:   ");
      for (k=0; k < 32; k=k+1) begin 
	 // Fp_REG_FILE[i] <= 32'b0;
	 if (Fp_REG_FILE[k] != 0) begin
	    $write("   R%4d: %9h,", k, Fp_REG_FILE[k]);
	 end
      end
      $write("\nFP32 REGFILE*:  ");
      for (n=0; n < 32; n=n+1) begin 
	 // Fp_REG_FILE[i] <= 32'b0;
	 if (Fp_REG_FILE[n] != 0) begin
	    $write("   R%4d: %9d,", n, $signed(Fp_REG_FILE[n]));
	 end
      end

   end

   //MARKER AUTOMATED HERE END
end
endgenerate


endmodule
