.PHONY: all sim synth clean  sim_vlt build_vlt lint_vlt vlt_clean

SHELL := /bin/bash -o pipefail

DUT ?= riscv32i.v
SYNTH_TIMEOUT ?= 600000
XILINX_CELLS_URL ?= https://github.com/Xilinx/XilinxUnisimLibrary.git
XILINX_CELLS_DIR ?= XilinxUnisimLibrary/verilog/src
IVERILOG ?= /usr/bin/iverilog
YOSYS ?= /usr/local/bin/yosys

OUT_DIR   := build_results
RTL_SRCS := $(DUT) main.v pipe.v ins_mem.v decode.v regfile.v FPregfile.v excute.v pc.v dataMem.v hazard.v debug.v
HDRS     := params.vh
INC      := .    

all: sim synth gatesim

sim: riscv32i-sim
	./$< +VCDFILE=sim.vcd +VCDLEVEL=5 &> sim.log


riscv32i-sim: riscv32iTB.v riscv32i_wrap.v ${DUT} main.v pipe.v ins_mem.v decode.v regfile.v FPregfile.v excute.v pc.v dataMem.v hazard.v debug.v  tbmem.v | ${XILINX_CELLS_DIR}
	${IVERILOG} -g2001 -s riscv32iTB -y ${XILINX_CELLS_DIR} -o $@ $^


# synth: riscv32i.netlist.v



synth: riscv32i.netlist.v


riscv32i.netlist.v: $(RTL_SRCS) $(HDRS) | $(OUT_DIR)
	timeout ${SYNTH_TIMEOUT} ${YOSYS} \
		-l $(OUT_DIR)/synth.log \
		-p "read_verilog -sv -I $(INC) $(RTL_SRCS)" \
		-p "hierarchy -check -top riscv32i" \
		-p "synth_xilinx -top riscv32i" \
		-p "write_verilog -noattr $@; stat"

# riscv32i.netlist.v: $(RTL_SRCS) $(HDRS) | $(OUT_DIR)
# 	timeout ${SYNTH_TIMEOUT} ${YOSYS} \
# 		-l $(OUT_DIR)/synth.log \
# 		-p "read_verilog -sv -I $(INC) $(RTL_SRCS)" \
# 		-p "hierarchy -check -top riscv32i" \
# 		-p "synth_xilinx -top riscv32i" \
# 		-p \"write_verilog -noattr $@; stat"



analyze: $(OUT_DIR)/stat.json $(OUT_DIR)/cell_usage.rpt $(OUT_DIR)/hierarchy.rpt

$(OUT_DIR)/stat.json $(OUT_DIR)/cell_usage.rpt $(OUT_DIR)/hierarchy.rpt: $(RTL_SRCS) $(HDRS) | $(OUT_DIR)
	${YOSYS} -l $(OUT_DIR)/analyze.log -p "\
		read_verilog -sv -I $(INC) $(RTL_SRCS); \
		hierarchy -top riscv32i; \
		proc; opt; memory; opt_clean; \
		stat -json > $(OUT_DIR)/stat.json; \
		tee -o $(OUT_DIR)/cell_usage.rpt stat; \
		tee -o $(OUT_DIR)/hierarchy.rpt hierarchy -auto-top -check; \
	"

$(OUT_DIR):
	mkdir -p $@



${XILINX_CELLS_DIR}:
	git clone ${XILINX_CELLS_URL}

gatesim: ./riscv32i-gatesim
	./$< +VCDFILE=gatesim.vcd +VCDLEVEL=5 | tee gatesim.log

riscv32i-gatesim: riscv32iTB.v riscv32i_wrap.v riscv32i.netlist.v | ${XILINX_CELLS_DIR}
	${IVERILOG} -g2005-sv -s riscv32iTB -DGATESIM -y ${XILINX_CELLS_DIR} -y ${XILINX_CELLS_DIR}/unisims -o $@ $^

clear:
	$(RM) riscv32i-sim sim.log

clean:
	$(RM) riscv32i-sim sim.log
	$(RM) riscv32i-gatesim gatesim.log gatesim.vcd
	$(RM) riscv32i.netlist.v synth.log
	
	
# # $(RM) -r XilinxUnisimLibrary


TB ?= riscv32iTB.v riscv32i_wrap.v

VERILATOR ?= verilator
VLT_FLAGS  = -Wall --sv --binary --timing --trace-fst -j 0
VLT_FLAGS += -Wno-fatal              # don't exit on warnings
# Optional targeted mutes as you fix code:
# VLT_FLAGS += -Wno-ASSIGNIN -Wno-UNOPTFLAT -Wno-UNUSED -Wno-UNDRIVEN -Wno-WIDTH

RTL := main.v pipe.v ins_mem.v decode.v regfile.v FPregfile.v excute.v pc.v dataMem.v hazard.v debug.v tbmem.v

sim_vlt: build_vlt
	./obj_dir/Vriscv32iTB +VCDFILE=sim.fst +VCDLEVEL=5 &> sim.log

build_vlt: riscv32iTB.v riscv32i_wrap.v ${DUT} $(RTL)
	$(VERILATOR) $(VLT_FLAGS) -top-module riscv32iTB $^

lint_vlt:
	$(VERILATOR) --lint-only -Wall --sv $(TB) ${DUT} $(RTL) 2> lint_vlt.log

vlt_clean:
	$(RM) -r obj_dir sim_vlt.log sim.vcd


# VERILATOR ?= verilator
# RTL := $(DUT) main.v pipe.v ins_mem.v decode.v regfile.v FPregfile.v excute.v pc.v dataMem.v hazard.v debug.v
# VLT_FLAGS = -Wall --sv --binary --timing --trace-vcd -j 0 -Wno-fatal

# sim_vlt: build_vlt
# 	./obj_dir/Vriscv32iTB +VCDFILE=sim.vcd +VCDLEVEL=5 &> sim.log

# build_vlt: $(TB) $(RTL)
# 	$(VERILATOR) $(VLT_FLAGS) -top-module riscv32iTB $^


