
module leading_zeroth_bit 
#(  parameter Bit_Length   = 25,
    parameter Bit_Length_O = 6 ) (   
    input wire   [Bit_Length-1  :0] in_wire,
    output wire  [Bit_Length-1  :0] leading_one_oh,
    output wire  [Bit_Length_O-1:0] leading_zero,
    output wire all_zeros
);
integer i;
reg valid_r;
reg [Bit_Length-1  :0] leading_one_oh_r;    
reg [Bit_Length_O-1:0] leading_zero_r;

  always @ (*) begin
    valid_r          = 1'b0;
    leading_one_oh_r = {Bit_Length  {1'b0}};
    leading_zero_r   = {Bit_Length_O{1'b0}};
    
    // Scan from MSB down without break; gate with valid_r.
    for (i = Bit_Length-1; i >= 0; i = i - 1) begin
      if (!valid_r && (in_wire[i] == 1'b1)) begin
        valid_r               = 1'b1;
        leading_one_oh_r[i]   = 1'b1;
        leading_zero_r        = Bit_Length-i-1;
      end
    end
  end
assign  all_zeros = ~valid_r;
assign  leading_one_oh = leading_one_oh_r;
assign leading_zero    = leading_zero_r;
endmodule




`timescale 1ns/1ps

module leading_zeroth_bit_stimTB;

  localparam integer N = 5;

  reg  [N-1:0] in_wire;
  wire [N-1:0] leading_one_oh;

  // DUT
  leading_zeroth_bit #(.Bit_Length(N)) dut (
    .in_wire(in_wire),
    .leading_one_oh(leading_one_oh)
  );

  // Waveform dump
  initial begin
    $dumpfile("leading_zeroth_bit_tb.vcd");
    $dumpvars(2);
  end
//    initial begin 
//       // reg [8*128-1:0] vcdfile;  // A reg-based string: 128 characters
//       // integer vcdlevel;
//       // if ($value$plusargs("VCDFILE=%s", vcdfile))
//       $dumpfile("sim.vcd");
//       // if ($value$plusargs("VCDLEVEL=%d", vcdlevel))
//       $dumpvars(5); 
//    end
  // Hardcoded stimulus. Edit these lines only.
  initial begin
    in_wire = {N{1'b0}};                           #10;
    in_wire = 5'b1000_0;   #10;
    in_wire = 5'b0100_1;   #10;
    in_wire = 5'b0010_1;   #10;
    in_wire = 5'b0000_1;   #10;
    in_wire = 5'b0001_1;   #10;
    in_wire = 5'b0000_0;   #10;
    in_wire = 5'b1010_0;   #10;
    in_wire = 5'b0111_1;   #10;

    // add your own vectors below
    // in_wire = 25'bxxxxxxxxxxxxxxxxxxxxxxxxx;     #10;

    #20;
    $finish;
  end

endmodule
