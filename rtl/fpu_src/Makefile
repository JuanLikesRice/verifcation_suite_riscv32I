# # SIM               := icarus
# # TOPLEVEL_LANG     := verilog
# # TOPLEVEL          := FPU_ADDER_I
# # COCOTB_TEST_MODULES := tests.test_fpu_adder
# # VERILOG_SOURCES   := rtl/fpu_adder.v

# # export IVERILOG_COMPILE_ARGS += -g2005 +define+size_Fp_fmt=3
# # export COCOTB_LOG_LEVEL = INFO
# # export COCOTB_LOG_FILE  = sim.log   # cocotb’s own log file

# # include $(shell cocotb-config --makefiles)/Makefile.sim

# # #  iverilog -g2001 -o sim FPU.v 
# # #  python3 src_run/fp32.py 1.25 751.375


# # # Build SoftFloat and a tiny CLI oracle (no PIC needed).

# # # SOFTFLOAT_DIR ?= berkeley-softfloat-3
# # # SOFTFLOAT_BUILD := $(SOFTFLOAT_DIR)/build/Linux-x86_64-GCC
# # # SOFTFLOAT_INC := $(SOFTFLOAT_DIR)/source/include
# # # SOFTFLOAT_LIB := $(SOFTFLOAT_BUILD)/softfloat.a

# # # BUILD_DIR := build

# # # CC := gcc
# # # CFLAGS := -O2 -std=c99 -Wall
# # # CLI_SRC := rv_softfloat_cli.c
# # # CLI_BIN := $(BUILD_DIR)/rv_softfloat_cli

# # # .PHONY: all softfloat cli clean

# # # all: cli

# # # softfloat:
# # # 	git clone --depth 1 https://github.com/ucb-bar/berkeley-softfloat-3.git $(SOFTFLOAT_DIR) || true
# # # 	$(MAKE) -C $(SOFTFLOAT_BUILD) clean
# # # 	$(MAKE) -C $(SOFTFLOAT_BUILD)

# # # $(BUILD_DIR):
# # # 	mkdir -p $(BUILD_DIR)

# # # cli: softfloat $(BUILD_DIR)
# # # 	$(CC) $(CFLAGS) -I$(SOFTFLOAT_INC) $(CLI_SRC) $(SOFTFLOAT_LIB) -o $(CLI_BIN)

# # # clean:
# # # 	rm -rf $(BUILD_DIR)
# # # 	-$(MAKE) -C $(SOFTFLOAT_BUILD) clean



# # ---- SoftFloat oracle (no PIC) ----
# # Put the clone in Linux FS to avoid WSL clock skew (recommended):

# # ---------- cocotb sim config ----------
# SIM               ?= icarus
# TOPLEVEL_LANG     ?= verilog
# TOPLEVEL          ?= FPU_ADDER_I
# MODULE            ?= tests.test_fpu_adder
# VERILOG_SOURCES   := rtl/fpu_adder.v

# export IVERILOG_COMPILE_ARGS += -g2005 +define+size_Fp_fmt=3
# export COCOTB_LOG_LEVEL ?= INFO
# export COCOTB_LOG_FILE  ?= sim.log

# COCOTB_MK := $(shell cocotb-config --makefiles)/Makefile.sim
# include $(COCOTB_MK)

# # ---------- SoftFloat oracle (CLI, no PIC) ----------
# # keep the clone on Linux FS to avoid WSL clock skew
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

# # ---------- hook oracle into sim (optional) ----------
# FAST ?= 1                       # FAST=1 -> don't depend on oracle
# ifeq ($(FAST),1)
# SIM_DEPS :=
# else
# SIM_DEPS := $(CLI_BIN)
# endif

# # append deps to cocotb's sim target (recipe lives in Makefile.sim)
# sim: $(SIM_DEPS)

# # always rerun sim (ignore up-to-date results.xml)
# .PHONY: resim
# resim: $(SIM_DEPS)
# 	$(RM) results.xml
# 	$(MAKE) FAST=$(FAST) sim

# # quick aliases
# .PHONY: fast
# fast:
# 	$(MAKE) FAST=1 sim

# # cleaning
# .PHONY: clean_oracle clean_all
# clean_oracle:
# 	rm -rf $(BUILD_DIR)
# 	-$(MAKE) -C $(SOFTFLOAT_BUILD) clean

# clean_all: clean clean_oracle
# ---------- cocotb sim config ----------


# SIM               ?= icarus
# TOPLEVEL_LANG     ?= verilog
# TOPLEVEL          ?=  tb_top
# COCOTB_TEST_MODULES ?= tests.test_fpu_adder
# VERILOG_SOURCES   := rtl/fpu_adder.v rtl/tb_top.v

# export IVERILOG_COMPILE_ARGS += -g2005 +define+size_Fp_fmt=3
# export COCOTB_LOG_LEVEL ?= INFO
# export COCOTB_LOG_FILE  ?= sim.log

# COCOTB_MK := $(shell cocotb-config --makefiles)/Makefile.sim
# export WAVES=1

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

# # ---------- hook oracle into sim (optional) ----------
# FAST ?= 1
# ifeq ($(FAST),1)
# SIM_DEPS :=
# else
# SIM_DEPS := $(CLI_BIN)
# endif

# sim: $(SIM_DEPS)

# .PHONY: resim
# resim: $(SIM_DEPS)
# 	$(RM) results.xml
# 	$(MAKE) FAST=$(FAST) sim

# .PHONY: fast
# fast:
# 	$(MAKE) FAST=1 sim

# # cleaning
# .PHONY: clean_oracle clean_all
# clean_oracle:
# 	rm -rf $(BUILD_DIR)
# 	-$(MAKE) -C $(SOFTFLOAT_BUILD) clean

# clean_all: clean clean_oracle


# ---------- cocotb + Icarus ----------
SIM                 ?= icarus
TOPLEVEL_LANG       ?= verilog
TOPLEVEL            ?= FPU_ADDER_I
COCOTB_TEST_MODULES ?= tests.test_fpu_adder
VERILOG_SOURCES     := rtl/fpu_adder.v

# Icarus options
export IVERILOG_COMPILE_ARGS += -g2005 +define+size_Fp_fmt=3
export COCOTB_LOG_LEVEL ?= INFO
export COCOTB_LOG_FILE  ?= sim.log

# # Let cocotb create waveforms (VCD) automatically
# export WAVES     = 1
# export WAVE_FILE ?= waves.vcd     # default is dump.vcd; override if you like

# cocotb auto-waves
export WAVES=1
export WAVE_FILE=waves.vcd

# force format = VCD (some setups default to FST)
export WAVE_FORMAT=vcd          # primary
export WAVEFORM_FORMAT=vcd      # fallback for older makefiles



# Include cocotb’s simulator rules
COCOTB_MK := $(shell cocotb-config --makefiles)/Makefile.sim
include $(COCOTB_MK)

# ---------- SoftFloat oracle (CLI, no PIC) ----------
SOFTFLOAT_DIR   ?= $(HOME)/.cache/berkeley-softfloat-3
SOFTFLOAT_BUILD := $(SOFTFLOAT_DIR)/build/Linux-x86_64-GCC
SOFTFLOAT_INC   := $(SOFTFLOAT_DIR)/source/include
SOFTFLOAT_LIB   := $(SOFTFLOAT_BUILD)/softfloat.a

BUILD_DIR := build
CLI_SRC   := rv_softfloat_cli.c
CLI_BIN   := $(BUILD_DIR)/rv_softfloat_cli

$(SOFTFLOAT_DIR):
	git clone --depth 1 https://github.com/ucb-bar/berkeley-softfloat-3.git $(SOFTFLOAT_DIR)

$(SOFTFLOAT_LIB): | $(SOFTFLOAT_DIR)
	$(MAKE) -C $(SOFTFLOAT_BUILD)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(CLI_BIN): $(CLI_SRC) $(SOFTFLOAT_LIB) | $(BUILD_DIR)
	$(CC) -O2 -std=c99 -Wall -I$(SOFTFLOAT_INC) $(CLI_SRC) $(SOFTFLOAT_LIB) -o $(CLI_BIN)

.PHONY: oracle
oracle: $(CLI_BIN)

# ---------- tie oracle into sim optionally ----------
FAST ?= 1
ifeq ($(FAST),1)
SIM_DEPS :=
else
SIM_DEPS := $(CLI_BIN)
endif

# Append deps to cocotb’s sim rule
sim: $(SIM_DEPS)

# Force a new run (delete previous XML so Makefile.sim always executes)
.PHONY: resim
resim: $(SIM_DEPS)
	$(RM) results.xml
	$(MAKE) FAST=$(FAST) sim

# Quick alias: run sim without rebuilding oracle
.PHONY: fast
fast:
	$(MAKE) FAST=1 sim

# Open waves quickly (optional)
.PHONY: wave
wave:
	gtkwave "$(WAVE_FILE)"

# Cleaning
.PHONY: clean_oracle clean_all
clean_oracle:
	rm -rf $(BUILD_DIR)
	-$(MAKE) -C $(SOFTFLOAT_BUILD) clean

clean_all: clean clean_oracle
