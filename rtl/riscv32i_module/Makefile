.PHONY: all sim synth clean  sim_vlt build_vlt lint_vlt vlt_clean

SHELL := /bin/bash -o pipefail

DUT ?= riscv32i.v
SYNTH_TIMEOUT ?= 600
XILINX_CELLS_URL ?= https://github.com/Xilinx/XilinxUnisimLibrary.git
XILINX_CELLS_DIR ?= XilinxUnisimLibrary/verilog/src
IVERILOG ?= /usr/bin/iverilog
YOSYS ?= /usr/local/bin/yosys

all: sim synth gatesim

sim: riscv32i-sim
	./$< +VCDFILE=sim.vcd +VCDLEVEL=5 &> sim.log


riscv32i-sim: riscv32iTB.v ${DUT} main.v pipe.v ins_mem.v decode.v regfile.v excute.v pc.v dataMem.v hazard.v debug.v  tbmem.v | ${XILINX_CELLS_DIR}
	${IVERILOG} -g2001 -s riscv32iTB -y ${XILINX_CELLS_DIR} -o $@ $^

synth: riscv32i.netlist.v

riscv32i.netlist.v: ${DUT}
	timeout ${SYNTH_TIMEOUT} ${YOSYS} -p 'synth_xilinx -top riscv32i' -p stat $< -L synth.log -o $@

${XILINX_CELLS_DIR}:
	git clone ${XILINX_CELLS_URL}

gatesim: ./riscv32i-gatesim
	./$< +VCDFILE=gatesim.vcd +VCDLEVEL=5 | tee gatesim.log

riscv32i-gatesim: riscv32iTB.v riscv32i.netlist.v | ${XILINX_CELLS_DIR}
	${IVERILOG} -g2005-sv -s riscv32iTB -DGATESIM -y ${XILINX_CELLS_DIR} -y ${XILINX_CELLS_DIR}/unisims -o $@ $^


clear:
	$(RM) riscv32i-sim 
	

clean:
	$(RM) riscv32i-sim sim.log
	$(RM) riscv32i-gatesim gatesim.log gatesim.vcd
	$(RM) riscv32i.netlist.v synth.log
	
	
# # $(RM) -r XilinxUnisimLibrary


TB ?= riscv32iTB.v

VERILATOR ?= verilator
VLT_FLAGS  = -Wall --sv --binary --timing --trace-fst -j 0
VLT_FLAGS += -Wno-fatal              # don't exit on warnings
# Optional targeted mutes as you fix code:
# VLT_FLAGS += -Wno-ASSIGNIN -Wno-UNOPTFLAT -Wno-UNUSED -Wno-UNDRIVEN -Wno-WIDTH

RTL := main.v pipe.v ins_mem.v decode.v regfile.v excute.v pc.v dataMem.v hazard.v debug.v tbmem.v

sim_vlt: build_vlt
	./obj_dir/Vriscv32iTB +VCDFILE=sim.fst +VCDLEVEL=5 &> sim.log

build_vlt: riscv32iTB.v ${DUT} $(RTL)
	$(VERILATOR) $(VLT_FLAGS) -top-module riscv32iTB $^

lint_vlt:
	$(VERILATOR) --lint-only -Wall --sv $(TB) ${DUT} $(RTL) 2> lint_vlt.log

vlt_clean:
	$(RM) -r obj_dir sim_vlt.log sim.vcd


# VERILATOR ?= verilator
# RTL := $(DUT) main.v pipe.v ins_mem.v decode.v regfile.v excute.v pc.v dataMem.v hazard.v debug.v
# VLT_FLAGS = -Wall --sv --binary --timing --trace-vcd -j 0 -Wno-fatal

# sim_vlt: build_vlt
# 	./obj_dir/Vriscv32iTB +VCDFILE=sim.vcd +VCDLEVEL=5 &> sim.log

# build_vlt: $(TB) $(RTL)
# 	$(VERILATOR) $(VLT_FLAGS) -top-module riscv32iTB $^


