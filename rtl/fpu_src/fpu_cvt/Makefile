
# # ---------- cocotb + Icarus ----------
# SIM               ?= icarus
# TOPLEVEL_LANG     ?= verilog
# TOPLEVEL          ?= FPU_ADDER_I
# VERILOG_SOURCES   := rtl/fpu_adder.v

# # test discovery for cocotb 1.x
# export MODULE = tests.test_fpu_adder
# export PYTHONPATH := $(PWD):$(PYTHONPATH)

# # use your venv’s cocotb tools
# PYTHON       ?= $(PWD)/.venv/bin/python
# COCOTB_MK    := $(shell $(PYTHON) -m cocotb.config --makefiles)/Makefile.sim


# # # ---------- cocotb + Icarus ----------
# # SIM                 ?= icarus
# # TOPLEVEL_LANG       ?= verilog
# # TOPLEVEL            ?= FPU_ADDER_I
# # COCOTB_TEST_MODULES ?= tests.test_fpu_adder
# # VERILOG_SOURCES     := rtl/fpu_adder.v

# # Icarus options
# export IVERILOG_COMPILE_ARGS += -g2005 +define+size_Fp_fmt=3
# export COCOTB_LOG_LEVEL ?= INFO
# export COCOTB_LOG_FILE  ?= sim.log

# # # Let cocotb create waveforms (VCD) automatically
# # export WAVES     = 1
# # export WAVE_FILE ?= waves.vcd     # default is dump.vcd; override if you like

# # cocotb auto-waves
# export WAVES=1
# export WAVE_FILE=waves.vcd

# # force format = VCD (some setups default to FST)
# export WAVE_FORMAT=vcd          # primary
# export WAVEFORM_FORMAT=vcd      # fallback for older makefiles



# # Include cocotb’s simulator rules
# COCOTB_MK := $(shell cocotb-config --makefiles)/Makefile.sim
# include $(COCOTB_MK)

# # ---------- SoftFloat oracle (CLI, no PIC) ----------
# SOFTFLOAT_DIR   ?= $(HOME)/.cache/berkeley-softfloat-3
# SOFTFLOAT_BUILD := $(SOFTFLOAT_DIR)/build/Linux-x86_64-GCC
# SOFTFLOAT_INC   := $(SOFTFLOAT_DIR)/source/include
# SOFTFLOAT_LIB   := $(SOFTFLOAT_BUILD)/softfloat.a

# BUILD_DIR := build
# CLI_SRC   := rv_softfloat_cli.c
# CLI_BIN   := $(BUILD_DIR)/rv_softfloat_cli

# $(SOFTFLOAT_DIR):
# 	git clone --depth 1 https://github.com/ucb-bar/berkeley-softfloat-3.git $(SOFTFLOAT_DIR)

# $(SOFTFLOAT_LIB): | $(SOFTFLOAT_DIR)
# 	$(MAKE) -C $(SOFTFLOAT_BUILD)

# $(BUILD_DIR):
# 	mkdir -p $(BUILD_DIR)

# $(CLI_BIN): $(CLI_SRC) $(SOFTFLOAT_LIB) | $(BUILD_DIR)
# 	$(CC) -O2 -std=c99 -Wall -I$(SOFTFLOAT_INC) $(CLI_SRC) $(SOFTFLOAT_LIB) -o $(CLI_BIN)

# .PHONY: oracle
# oracle: $(CLI_BIN)

# # ---------- tie oracle into sim optionally ----------
# FAST ?= 1
# ifeq ($(FAST),1)
# SIM_DEPS :=
# else
# SIM_DEPS := $(CLI_BIN)
# endif

# # Append deps to cocotb’s sim rule
# sim: $(SIM_DEPS)

# # Force a new run (delete previous XML so Makefile.sim always executes)
# .PHONY: resim
# resim: $(SIM_DEPS)
# 	$(RM) results.xml
# 	$(MAKE) FAST=$(FAST) sim

# # Quick alias: run sim without rebuilding oracle
# .PHONY: fast
# fast:
# 	$(MAKE) FAST=1 sim

# # Open waves quickly (optional)
# .PHONY: wave
# wave:
# 	gtkwave "$(WAVE_FILE)"

# # Cleaning
# .PHONY: clean_oracle clean_all
# clean_oracle:
# 	rm -rf $(BUILD_DIR)
# 	-$(MAKE) -C $(SOFTFLOAT_BUILD) clean

# clean_all: clean clean_oracle


# --- simulator/config ---
SIM               ?= icarus
TOPLEVEL_LANG     ?= verilog
TOPLEVEL          ?= rv_FPU
MODULE            ?= tests.test_rv_fpu
VERILOG_SOURCES   := rtl/rv_fpu.v  # add other RTL files as needed

# --- compiler & logging ---
export IVERILOG_COMPILE_ARGS += -g2012 +define+size_Fp_fmt=3
export COCOTB_LOG_LEVEL ?= INFO
export COCOTB_LOG_FILE  ?= sim.log
export PYTHONPATH       := $(PWD):$(PYTHONPATH)

# --- waves ---
export WAVES=1
export WAVE_FORMAT ?= vcd
export WAVE_FILE   ?= waves.vcd

# IMPORTANT: include ONLY Makefile.sim
include $(shell cocotb-config --makefiles)/Makefile.sim

# ================= SoftFloat oracle builds (add + mul) =================
SOFTFLOAT_DIR   ?= $(HOME)/.cache/berkeley-softfloat-3
SOFTFLOAT_BUILD := $(SOFTFLOAT_DIR)/build/Linux-x86_64-GCC
SOFTFLOAT_INC   := $(SOFTFLOAT_DIR)/source/include
SOFTFLOAT_LIB   := $(SOFTFLOAT_BUILD)/softfloat.a

BUILD_DIR      := build
CLI_ADD_SRC    := rv_softfloat_cli.c
CLI_ADD_BIN    := $(BUILD_DIR)/rv_softfloat_cli
CLI_MUL_SRC    := rv_softfloat_cli_mul.c
CLI_MUL_BIN    := $(BUILD_DIR)/rv_softfloat_cli_mul

$(SOFTFLOAT_DIR):
	git clone --depth 1 https://github.com/ucb-bar/berkeley-softfloat-3.git $(SOFTFLOAT_DIR)

$(SOFTFLOAT_LIB): | $(SOFTFLOAT_DIR)
	$(MAKE) -C $(SOFTFLOAT_BUILD)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(CLI_ADD_BIN): $(CLI_ADD_SRC) $(SOFTFLOAT_LIB) | $(BUILD_DIR)
	$(CC) -O2 -std=c99 -Wall -I$(SOFTFLOAT_INC) $(CLI_ADD_SRC) $(SOFTFLOAT_LIB) -o $(CLI_ADD_BIN)

$(CLI_MUL_BIN): $(CLI_MUL_SRC) $(SOFTFLOAT_LIB) | $(BUILD_DIR)
	$(CC) -O2 -std=c99 -Wall -I$(SOFTFLOAT_INC) $(CLI_MUL_SRC) $(SOFTFLOAT_LIB) -o $(CLI_MUL_BIN)

.PHONY: oracle
oracle: $(CLI_ADD_BIN) $(CLI_MUL_BIN)

# Hook oracle into sim only if FAST=0
FAST ?= 1
ifeq ($(FAST),1)
SIM_DEPS :=
else
SIM_DEPS := $(CLI_ADD_BIN) $(CLI_MUL_BIN)
endif

sim: $(SIM_DEPS)

.PHONY: resim
resim: $(SIM_DEPS)
	$(RM) results.xml
	$(MAKE) FAST=$(FAST) sim

.PHONY: fast
fast:
	$(MAKE) FAST=1 sim

# cleaning
.PHONY: clean_all clean_oracle
clean_oracle:
	rm -rf $(BUILD_DIR)
	-$(MAKE) -C $(SOFTFLOAT_BUILD) clean

clean_all: clean clean_oracle
	@rm -rf sim_build results.xml __pycache__ *.vcd *.fst *.log results.csv results_table.log
