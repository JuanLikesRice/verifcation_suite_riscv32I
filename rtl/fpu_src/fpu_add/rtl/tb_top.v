`timescale 1ns/1ps
module tb_top;
  // Drive-through regs so cocotb can poke them
  reg  [2:0]  rm;
  reg  [31:0] A;
  reg  [31:0] B;
  wire [31:0] Out;
  // wire [4:0] fflags; // uncomment if your DUT has this port

  FPU_ADDER_I dut (
    .rm(rm),
    .A (A),
    .B (B),
    .Out(Out)
    // ,.fflags(fflags)
  );

  initial begin
    // write into sim_build which always exists in cocotb’s icarus flow
    $dumpfile("sim_build/waves.vcd");
    $dumpvars(0, tb_top);
    $display("VCD dump enabled -> sim_build/waves.vcd");
  end
endmodule
