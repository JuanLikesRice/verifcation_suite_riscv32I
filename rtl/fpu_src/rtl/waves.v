`timescale 1ns/1ps
module __waves;
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, __waves);
  end
endmodule
