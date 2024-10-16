DUT ?= toggle_bit.v
DUTWAP ?= toggle_bit_wrapper.v
TEST_PY ?= test_toggle_bit.py
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(shell pwd)/DUT/$(DUT)
VERILOG_SOURCES += $(shell pwd)/DUT_Wrapper/$(DUTWAP)

TOPLEVEL = $(basename $(DUTWAP))
MODULE = $(basename $(TEST_PY))

include $(shell cocotb-config --makefiles)/Makefile.sim
