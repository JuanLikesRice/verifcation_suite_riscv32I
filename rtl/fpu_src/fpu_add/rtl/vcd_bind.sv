// Auto-VCD for cocotb + Icarus using bind.
// Ensures the dumper is elaborated even when the DUT is the only top.
`ifdef COCOTB_SIM
module _cocotb_vcd_dump;
  initial begin
    $dumpfile("waves.vcd");
    // Dump complete hierarchy rooted at the DUT top
    $dumpvars(0, FPU_ADDER_I);
  end
endmodule

// Bind the dumper into the DUT so it always exists at elaboration.
bind FPU_ADDER_I _cocotb_vcd_dump _cocotb_vcd_dump_i();
`endif
