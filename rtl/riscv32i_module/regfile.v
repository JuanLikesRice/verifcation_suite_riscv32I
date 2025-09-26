
module reg_file #(
        parameter debug_param = 1
)(
		input wire	   clk,
		input wire	   reset, 
		input wire [4:0]   reg1_pi, 
		input wire [4:0]   reg2_pi, 
		input wire [4:0]   destReg_pi,

		input wire	   we_pi, 
		input wire [31:0]  writeData_pi, 

		output wire [31:0] operand1_po,
		output wire [31:0] operand2_po,



		input wire	   write_csr,
		input wire [11:0]  csrReg_write_dest_reg,
		input wire [31:0]  csrReg_write_dest_reg_data,
		input wire [11:0]  csrReg_read_src_reg,
		output wire [31:0] csrReg_read_src_reg_data
		);

   wire				   cntrl1, cntrl2,cntrl_csr;
   reg [31:0]			   REG_FILE[0:31];  // 32 32-bit registers
   
   // read while writing in WB stage   
   assign cntrl1      =  (reg1_pi  == destReg_pi)                       &&  we_pi;
   assign cntrl2      =  (reg2_pi  == destReg_pi)                       &&  we_pi ;

   assign operand1_po              = cntrl1    ? writeData_pi : REG_FILE[reg1_pi];
   assign operand2_po              = cntrl2    ? writeData_pi : REG_FILE[reg2_pi];

   integer			   j;
   // integer p;

   initial begin 
      for (j=0; j < 32; j=j+1)begin 
	 REG_FILE[j] = 32'b0;	 
      end
   end
   integer i;
   integer o;

   always @(posedge clk) begin
      if (reset) begin 
         for (i=0; i < 32; i=i+1) begin 
	    REG_FILE[i] <= 32'b0;	
         end
      end else begin 
	 if (we_pi && (destReg_pi!=0))  begin 
	    REG_FILE[destReg_pi] <= writeData_pi;
         end
      end
   end

generate
if (debug_param) begin :debug_I_regfile
   //MARKER AUTOMATED HERE START
   integer k;
   integer n;
   always @(negedge clk) begin
      #100
	$write("\n\nREGFILE:   ");
      for (k=0; k < 32; k=k+1) begin 
	 // REG_FILE[i] <= 32'b0;
	 if (REG_FILE[k] != 0) begin
	    $write("   R%4d: %9h,", k, REG_FILE[k]);
	 end end
      $write("\nREGFILE*:  ");
      for (n=0; n < 32; n=n+1) begin 
	 // REG_FILE[i] <= 32'b0;
	 if (REG_FILE[n] != 0) begin
	    $write("   R%4d: %9d,", n, $signed(REG_FILE[n]));
	 end end end end
endgenerate

endmodule
