# ===== CONFIG =====
TOP ?= uart_rx_tb

FLIST_DIR = sim/filelists
FILELIST  = $(FLIST_DIR)/$(TOP).f
WLF_FILE  = $(TOP).wlf

ifeq ($(wildcard $(FILELIST)),)
$(error Missing filelist: $(FILELIST))
endif

# ===== COMMANDS =====
all: wave

lib:
	@if [ ! -d work ]; then vlib work; fi

compile: lib
	@echo "[Compile RTL & Testbench]"
	vlog -sv -f $(FILELIST)

wave: compile
	@echo "[Run GUI Live: $(TOP)]"
	vsim -voptargs=+acc $(TOP) -do "do sim/wave.do $(TOP) sim"

run_cli: compile
	@echo "[Run CLI & Dump WLF: $(TOP)]"
	vsim -c -voptargs=+acc $(TOP) -wlf $(WLF_FILE) -do "log -r /*; run -all; quit -f"

view_wave:
	@echo "[Open Waveform from WLF: $(WLF_FILE)]"
	vsim -gui -l /dev/null -view $(WLF_FILE) -do "do sim/wave.do $(TOP) $(TOP)"

syntax: lib
	@echo "[Syntax check using $(FILELIST)]"
	vlog -sv -lint -f $(FILELIST)

clean:
	rm -rf work transcript vsim.wlf *.wlf uvm_test_*.log *.vstf

.PHONY: all lib compile syntax wave run_cli view_wave clean
