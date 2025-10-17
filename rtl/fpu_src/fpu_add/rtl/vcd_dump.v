// Dumps waves to waves.vcd when run under cocotb + Icarus.
`ifdef COCOTB_SIM
module vcd_dump();
  initial begin
    $dumpfile("waves.vcd");
    // Dump the whole design tree; top is FPU_ADDER_I
    $dumpvars(0, FPU_ADDER_I);
  end
endmodule
`endif
