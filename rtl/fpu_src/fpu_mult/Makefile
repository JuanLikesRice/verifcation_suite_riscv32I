SIM               ?= icarus
TOPLEVEL_LANG     ?= verilog
TOPLEVEL          ?= FPU_ADDER_I
MODULE            ?= tests.test_fpu_mul     # <— set this for cocotb 1.9.x
VERILOG_SOURCES   := rtl/fpu_adder.v

export IVERILOG_COMPILE_ARGS += -g2005 +define+size_Fp_fmt=3
export COCOTB_LOG_LEVEL ?= INFO
export WAVES=1
export WAVE_FORMAT ?= fst
export WAVE_FILE   ?= waves.fst
export PYTHONPATH  := $(PWD):$(PYTHONPATH)

include $(shell cocotb-config --makefiles)/Makefile.sim





# # ---------- cocotb + Icarus ----------
# SIM                 ?= icarus
# TOPLEVEL_LANG       ?= verilog
# TOPLEVEL            ?= FPU_ADDER_I
# COCOTB_TEST_MODULES ?= tests.test_fpu_mul
# VERILOG_SOURCES     := rtl/fpu_adder.v

# export IVERILOG_COMPILE_ARGS += -g2005 +define+size_Fp_fmt=3
# export COCOTB_LOG_LEVEL ?= INFO
# export COCOTB_LOG_FILE  ?= sim.log

# cocotb waves (FST or VCD). Pick one:
export WAVES=1
export WAVE_FORMAT ?= fst          # set to vcd if you prefer
export WAVE_FILE   ?= waves.fst    # waves.vcd if VCD

COCOTB_MK := $(shell cocotb-config --makefiles)/Makefile.sim
include $(COCOTB_MK)

# ---------- SoftFloat oracles (no PIC) ----------
SOFTFLOAT_DIR   ?= $(HOME)/.cache/berkeley-softfloat-3
SOFTFLOAT_BUILD := $(SOFTFLOAT_DIR)/build/Linux-x86_64-GCC
SOFTFLOAT_INC   := $(SOFTFLOAT_DIR)/source/include
SOFTFLOAT_LIB   := $(SOFTFLOAT_BUILD)/softfloat.a

BUILD_DIR := build
CLI_ADD_SRC := rv_softfloat_cli.c         # keep available if you still use ADD tests
CLI_MUL_SRC := rv_softfloat_cli_mul.c
CLI_ADD_BIN := $(BUILD_DIR)/rv_softfloat_cli
CLI_MUL_BIN := $(BUILD_DIR)/rv_softfloat_cli_mul

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
oracle: $(CLI_MUL_BIN)  # build mul oracle (add one is optional)
	@true

# ---------- hook oracle into sim optionally ----------
FAST ?= 1
ifeq ($(FAST),1)
SIM_DEPS :=
else
SIM_DEPS := $(CLI_MUL_BIN)
endif

sim: $(SIM_DEPS)

.PHONY: resim
resim: $(SIM_DEPS)
	$(RM) results.xml
	$(MAKE) FAST=$(FAST) sim

.PHONY: fast
fast:
	$(MAKE) FAST=1 sim

# Cleaning
.PHONY: clean_oracle clean_all
clean_oracle:
	rm -rf $(BUILD_DIR)
	-$(MAKE) -C $(SOFTFLOAT_BUILD) clean

clean_all: clean clean_oracle
