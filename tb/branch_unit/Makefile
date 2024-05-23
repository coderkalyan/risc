# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../../rtl/branch_unit.v

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = branch_unit

# MODULE is the basename of the Python test file
MODULE = branch_unit_tb

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
