# CocoTB Makefile

CWD = $(shell pwd)

REPO_DIR := /home/shaun/repos/hdmi_transmitter

SIM ?= verilator
TOPLEVELLANG ?= verilog
EXTRA_ARGS += --timing
EXTRA_ARGS += --trace --trace-structs

VERILOG_SOURCES += $(REPO_DIR)/rtl/tmds_encoder.sv

TOPLEVEL = tmds_encoder

MODULE = tb_tmds_encoder

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 10ps

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: lint
lint:
	verilator --lint-only -sv -Wall $(VERILOG_SOURCES)

WAVES = dump.vcd

.PHONY: waves
waves:
	gtkwave $(WAVES)

# .PHONY: clean
# clean:
# 	rm -rf __pycache__/
