`timescale 1ns/1ns

module pc(
input wire clk_i,
input wire reset_i,
input wire halt_i,
input wire isTakenBranch_i, 
input wire [31:0] targetPC_i,
output wire[31:0] pc_o
);

reg  [31:0] PC;
wire [31:0] nextPC;

  assign nextPC = isTakenBranch_i ?  targetPC_i  : PC + 4;
//   assign nextPC =  PC + 4;
  assign pc_o = PC;

  always @(posedge clk_i) begin
//     $display("Time: %3d\thalt: %d\tisTakenBranch: %d\tnextPC: %d\tpc_po: %d",$time, halt_pi, isTakenBranch_pi, PC, pc_po);
  	 if (reset_i)
	    PC  <= 32'b0;
	 else 
 	    if (isTakenBranch_i | ~halt_i)  begin
            PC <= nextPC;
	end
  end
   
endmodule