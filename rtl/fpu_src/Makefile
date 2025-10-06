SIM               := icarus
TOPLEVEL_LANG     := verilog
TOPLEVEL          := FPU_ADDER_I
COCOTB_TEST_MODULES := tests.test_fpu_adder
VERILOG_SOURCES   := rtl/fpu_adder.v

export IVERILOG_COMPILE_ARGS += -g2005 +define+size_Fp_fmt=3
export COCOTB_LOG_LEVEL = INFO
export COCOTB_LOG_FILE  = sim.log   # cocotb’s own log file

include $(shell cocotb-config --makefiles)/Makefile.sim

#  iverilog -g2001 -o sim FPU.v 
#  python3 src_run/fp32.py 1.25 751.375