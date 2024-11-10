# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../../rtl/decoder.v

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = decoder

# MODULE is the basename of the Python test file
MODULE = decoder_tb

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
