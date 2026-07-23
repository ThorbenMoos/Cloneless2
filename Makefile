MAKEFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

SOURCES = $(MAKEFILE_DIR)/src/*.vhd
TOPLEVEL = Cloneless
TOPTESTBENCH = TB_$(TOPLEVEL)_mid_pSquare_dSHARES_IPM_kRED
IOTOPLEVEL = chip_top
IOTOPTESTBENCH = TB_$(IOTOPLEVEL)_mid_pSquare_dSHARES_IPM_kRED
TESTBENCHPATH = $(MAKEFILE_DIR)/src/Testbenches
MACROPATH = $(MAKEFILE_DIR)/macros
WORKDIR = $(MAKEFILE_DIR)/work
GHDL_FLAGS = --workdir=$(WORKDIR)
GHDL_SIM_FLAGS = --stop-time=10us --ieee-asserts=disable-at-0
PDK_ROOT ?= $(MAKEFILE_DIR)/gf180mcu
PDK ?= gf180mcuD
PDK_COMMIT ?= d658698bd8bcf4e05fc7b5991a701247ba0d744c
PRECHECK_ROOT = $(MAKEFILE_DIR)/gf180mcu-precheck
PRECHECK_TAG = 1.7.3
ID = G802CLON

all: clean analyze sim convert sim_converted clone_pdk sim_with_io cell_replacement build_macros erase_macro_rtl build_design sim_postlayout waferspace_precheck

clean:
	rm -rf $(WORKDIR)
	rm -rf $(PDK_ROOT)
	rm -rf $(PRECHECK_ROOT)
	rm -rf $(MAKEFILE_DIR)/runs
	rm -rf $(MACROPATH)/*/runs
	rm -rf $(MAKEFILE_DIR)/*.v
	ghdl --clean
	
analyze:
	mkdir -p $(WORKDIR)
	ghdl -a $(GHDL_FLAGS) $(SOURCES)
	ghdl -a $(GHDL_FLAGS) $(TESTBENCHPATH)/$(TOPTESTBENCH).vhd
	ghdl -e $(GHDL_FLAGS) $(TOPTESTBENCH)

sim:
	ghdl -r $(GHDL_FLAGS) $(TOPTESTBENCH) $(GHDL_SIM_FLAGS)
	
convert:
	ghdl synth --latches --out=verilog $(GHDL_FLAGS) $(TOPLEVEL) > $(TOPLEVEL).v
	
sim_converted:
	iverilog -o $(TESTBENCHPATH)/$(TOPTESTBENCH)_verilog $(TESTBENCHPATH)/$(TOPTESTBENCH)_verilog.v $(TOPLEVEL).v
	vvp $(TESTBENCHPATH)/$(TOPTESTBENCH)_verilog

clone_pdk:
	rm -rf $(MAKEFILE_DIR)/gf180mcu
	ciel enable $(PDK_COMMIT) --pdk-root $(PDK_ROOT) --pdk-family $(PDK) --include-libraries all
	
sim_with_io:	
	iverilog -g2012 -o $(TESTBENCHPATH)/$(IOTOPTESTBENCH) $(TESTBENCHPATH)/$(IOTOPTESTBENCH).v $(PDK_ROOT)/$(PDK)/libs.ref/gf180mcu_fd_io/verilog/gf180mcu_fd_io.v $(MACROPATH)/gf180mcu_ws_ip__logo/vh/gf180mcu_ws_ip__logo.v $(MACROPATH)/gf180mcu_ws_ip__marker/vh/gf180mcu_ws_ip__marker.v $(MACROPATH)/gf180mcu_ws_ip__project_id/vh/gf180mcu_ws_ip__project_id.v $(MACROPATH)/gf180mcu_ws_ip__qrcode_id/vh/gf180mcu_ws_ip__qrcode_id.v $(MACROPATH)/gf180mcu_ws_ip__shuttle_id/vh/gf180mcu_ws_ip__shuttle_id.v ${TOPLEVEL}.v ${IOTOPLEVEL}.sv
	vvp $(TESTBENCHPATH)/$(IOTOPTESTBENCH)

cell_replacement:
	sed -z -i 's/module inv.*i;\nendmodule\n\n//g' $(TOPLEVEL).v
	sed -z -i 's/module nand2.*a2);\nendmodule\n\n//g' $(TOPLEVEL).v
	sed -z -i 's/module buff.*inter;\nendmodule\n\n//g' $(TOPLEVEL).v
	sed -z -i 's/module latch.*n11269_o;\nendmodule\n\n//g' $(TOPLEVEL).v
	sed -i 's/  inv /(* keep = "true" *) gf180mcu_fd_sc_mcu7t5v0__inv_1 /g' $(TOPLEVEL).v
	sed -i 's/  nand2 /(* keep = "true" *) gf180mcu_fd_sc_mcu7t5v0__nand2_1 /g' $(TOPLEVEL).v
	sed -i 's/  buff /(* keep = "true" *) gf180mcu_fd_sc_mcu7t5v0__buf_1 /g' $(TOPLEVEL).v
	sed -i 's/  latch /(* keep = "true" *) gf180mcu_fd_sc_mcu7t5v0__latrsnq_1 /g' $(TOPLEVEL).v
	sed -i 's/\.i(/\.I(/g' $(TOPLEVEL).v
	sed -i 's/\.zn(/\.ZN(/g' $(TOPLEVEL).v
	sed -i 's/\.i0(/\.I0(/g' $(TOPLEVEL).v
	sed -i 's/\.i1(/\.I1(/g' $(TOPLEVEL).v
	sed -i 's/\.s(/\.S(/g' $(TOPLEVEL).v
	sed -i 's/\.z(/\.Z(/g' $(TOPLEVEL).v
	sed -i 's/\.a1(/\.A1(/g' $(TOPLEVEL).v
	sed -i 's/\.a2(/\.A2(/g' $(TOPLEVEL).v
	sed -i 's/\.lat_e(/\.E(/g' $(TOPLEVEL).v
	sed -i 's/\.lat_setn(/\.SETN(/g' $(TOPLEVEL).v
	sed -i 's/\.lat_rn(/\.RN(/g' $(TOPLEVEL).v
	sed -i 's/\.lat_d(/\.D(/g' $(TOPLEVEL).v
	sed -i 's/\.lat_q(/\.Q(/g' $(TOPLEVEL).v
	sed -i 's/(input/(\n   `ifdef USE_POWER_PINS\n   inout wire VSS,\n   inout wire VDD,\n   `endif\n   input/g' $(TOPLEVEL).v
	sed -z -i 's/(\n    \./(\n    `ifdef USE_POWER_PINS\n    \.VSS(VSS),\n    \.VDD(VDD),\n    `endif\n    \./g' $(TOPLEVEL).v

build_macros:
	librelane macros/butterfly/butterfly.yaml --pdk $(PDK) --pdk-root $(PDK_ROOT) --manual-pdk
	librelane macros/ringoscillator_11/ringoscillator_11.yaml --pdk $(PDK) --pdk-root $(PDK_ROOT) --manual-pdk
	librelane macros/ringoscillator_23/ringoscillator_23.yaml --pdk $(PDK) --pdk-root $(PDK_ROOT) --manual-pdk
	librelane macros/ringoscillator_31/ringoscillator_31.yaml --pdk $(PDK) --pdk-root $(PDK_ROOT) --manual-pdk
	librelane macros/ringoscillator_47/ringoscillator_47.yaml --pdk $(PDK) --pdk-root $(PDK_ROOT) --manual-pdk
	librelane macros/ringoscillator_59/ringoscillator_59.yaml --pdk $(PDK) --pdk-root $(PDK_ROOT) --manual-pdk
	librelane macros/tappeddelaychain/tappeddelaychain.yaml --pdk $(PDK) --pdk-root $(PDK_ROOT) --manual-pdk

erase_macro_rtl:
	sed -z -i 's/module butterfly.*latch2_q));\nendmodule\n\n//g' $(TOPLEVEL).v
	sed -z -i 's/module ringoscillator_11.*nd_n10381};\nendmodule\n\n//g' $(TOPLEVEL).v
	sed -z -i 's/module ringoscillator_23.*nd_n10476};\nendmodule\n\n//g' $(TOPLEVEL).v
	sed -z -i 's/module ringoscillator_31.*nd_n10673};\nendmodule\n\n//g' $(TOPLEVEL).v
	sed -z -i 's/module ringoscillator_47.*nd_n10864};\nendmodule\n\n//g' $(TOPLEVEL).v
	sed -z -i 's/module ringoscillator_59.*nd_n11103};\nendmodule\n\n//g' $(TOPLEVEL).v
	sed -z -i 's/module tappeddelaychain.*genf_n1_ff_inst_n10499};\nendmodule\n\n//g' $(TOPLEVEL).v

build_design:
	librelane $(IOTOPLEVEL).yaml --pdk $(PDK) --pdk-root $(PDK_ROOT) --manual-pdk

sim_postlayout:	
	iverilog -o $(TESTBENCHPATH)/$(IOTOPTESTBENCH) $(PDK_ROOT)/$(PDK)/libs.ref/gf180mcu_fd_sc_mcu7t5v0/verilog/gf180mcu_fd_sc_mcu7t5v0.v $(PDK_ROOT)/$(PDK)/libs.ref/gf180mcu_fd_sc_mcu7t5v0/verilog/primitives.v $(PDK_ROOT)/$(PDK)/libs.ref/gf180mcu_fd_io/verilog/gf180mcu_fd_io.v $(MACROPATH)/gf180mcu_ws_ip__logo/vh/gf180mcu_ws_ip__logo.v $(MACROPATH)/gf180mcu_ws_ip__marker/vh/gf180mcu_ws_ip__marker.v $(MACROPATH)/gf180mcu_ws_ip__project_id/vh/gf180mcu_ws_ip__project_id.v $(MACROPATH)/gf180mcu_ws_ip__qrcode_id/vh/gf180mcu_ws_ip__qrcode_id.v $(MACROPATH)/gf180mcu_ws_ip__shuttle_id/vh/gf180mcu_ws_ip__shuttle_id.v $(MACROPATH)/butterfly/runs/RUN*/final/vh/butterfly.vh $(MACROPATH) $(MACROPATH)/ringoscillator_11/runs/RUN*/final/vh/ringoscillator_11.vh $(MACROPATH)/ringoscillator_23/runs/RUN*/final/vh/ringoscillator_23.vh $(MACROPATH)/ringoscillator_31/runs/RUN*/final/vh/ringoscillator_31.vh $(MACROPATH)/ringoscillator_47/runs/RUN*/final/vh/ringoscillator_47.vh $(MACROPATH)/ringoscillator_59/runs/RUN*/final/vh/ringoscillator_59.vh $(MACROPATH)/tappeddelaychain/runs/RUN*/final/vh/tappeddelaychain.vh $(MAKEFILE_DIR)/runs/RUN*/final/nl/$(IOTOPLEVEL).nl.v $(TESTBENCHPATH)/$(IOTOPTESTBENCH).v
	vvp $(TESTBENCHPATH)/$(IOTOPTESTBENCH)

waferspace_precheck:
	git clone https://github.com/wafer-space/gf180mcu-precheck --branch $(PRECHECK_TAG)
	python3 $(PRECHECK_ROOT)/precheck.py --input runs/RUN*/final/gds/$(IOTOPLEVEL).gds --top $(IOTOPLEVEL) --id $(ID)