# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../../rtl/pc_ctrl.v

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = pc_ctrl

# MODULE is the basename of the Python test file
MODULE = pc_ctrl_tb

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
