# AXI4 VIP Unified Makefile
# This Makefile combines functionality from both /sim/Makefile and /sim/synopsys_sim/makefile
# Works with axi4_regression_makefile.py and provides standalone sim functionality

# Default values for regression script
test ?= axi4_default_test
SEED ?=
LOG_FILE ?= $(test).log
RUN_DIR ?= .
FSDB_DUMP ?= 0
COVERAGE ?= 0
COV_DIR ?= $(test).vdb
COMMAND_ADD ?=
CLEANUP_DELAY ?= 5

# Use standard VCS filenames - folder isolation handles conflicts
SIMV_NAME ?= simv

# Determine paths based on current working directory
# Get absolute paths to handle compile file relative path issues
SIM_ROOT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Auto-detect compile file path based on current working directory
ifeq ($(wildcard axi4_compile.f),axi4_compile.f)
    # Running from sim directory - use relative path
    COMPILE_FILE = axi4_compile.f
    VERDI_PATH = .
else ifeq ($(wildcard ../axi4_compile.f),../axi4_compile.f)
    # Running from synopsys_sim directory - use parent directory
    COMPILE_FILE = ../axi4_compile.f
    VERDI_PATH = ..
else ifeq ($(wildcard ../../axi4_compile.f),../../axi4_compile.f)
    # Running from run_folder_XX under synopsys_sim - use relative path to sim directory
    COMPILE_FILE = ../../axi4_compile.f
    VERDI_PATH = ../..
else ifeq ($(wildcard ../../../axi4_compile.f),../../../axi4_compile.f)
    # Running from run_folder_XX under sim directory - use relative path
    COMPILE_FILE = ../../../axi4_compile.f
    VERDI_PATH = ../../..
else
    # Fallback - assume run_folder_XX under synopsys_sim
    COMPILE_FILE = ../../axi4_compile.f
    VERDI_PATH = ../..
endif

# VCS base command with dynamic seed handling (like original script)
VCS_BASE_CMD = vcs -full64 -lca -kdb -sverilog +v2k \
               -debug_access+all -ntb_opts uvm-1.2 \
               -override_timescale=1ps/1ps \
               +nospecify +no_timing_check

# Handle SEED parameter - if not provided, use automatic
ifeq ($(SEED),)
    VCS_SEED = +ntb_random_seed_automatic
else
    VCS_SEED = +ntb_random_seed=$(SEED)
endif

# Build VCS command
VCS_FLAGS = $(VCS_BASE_CMD) $(VCS_SEED)

# Add FSDB dumping if enabled
ifeq ($(FSDB_DUMP),1)
VCS_FLAGS += +define+DUMP_FSDB
endif

# Interface configuration based on test name
# TC046-TC058 and boundary tests use 4x4 configuration
ifneq ($(filter %tc_04% %tc_05% %boundary% %unaligned% %4k% %all_master_slave_access% %base_matrix_test%,$(test)),)
VCS_FLAGS += +define+RUN_4X4_CONFIG
$(info Configuring for 4x4 interface matrix based on test: $(test))
endif

# TC001-TC005, enhanced matrix test, and QoS/USER tests use 10x10 configuration
ifneq ($(filter %tc_00% %enhanced_bus_matrix_test% %qos% %user%,$(test)),)
VCS_FLAGS += +define+RUN_10X10_CONFIG +define+BUS_MATRIX_10X10
$(info Configuring for 10x10 interface matrix based on test: $(test))
endif

# Add coverage flags if enabled (simple naming like original script)
ifeq ($(COVERAGE),1)
VCS_FLAGS += -cm line+cond+fsm+tgl+branch+assert -cm_seqnoconst -cm_dir $(test).vdb -cm_name $(test)
endif

# Add UVM and testbench specific flags (restored -R like original script)
VCS_FLAGS += +define+UVM_VERDI_COMPWAVE -f $(COMPILE_FILE) \
             -debug_access+all -R +UVM_TESTNAME=$(test) \
             +UVM_VERBOSITY=MEDIUM +plusarg_ignore


# Add any custom command line additions
ifneq ($(COMMAND_ADD),)
VCS_FLAGS += $(COMMAND_ADD)
endif

# Add log file
ifneq ($(LOG_FILE),)
VCS_FLAGS += -l $(LOG_FILE)
endif

.PHONY: all sim run_test verdi clean help

# Default target for standalone usage
all: clean sim

# Main target for running tests (simplified like original script)
sim:
	@echo "==============================================="
	@echo "Running AXI4 Test: $(test)"
	@echo "Seed: $(SEED)"
	@echo "Log File: $(LOG_FILE)"
	@echo "FSDB Dump: $(FSDB_DUMP)"
	@echo "Coverage: $(COVERAGE)"
	@echo "Compile File: $(COMPILE_FILE)"
	@echo "==============================================="
	@# Comprehensive cleanup of all simulation artifacts 
	@echo "Performing comprehensive cleanup of simulation artifacts..."
	rm -rf simv* csrc* vc_hdrs.h ucli.key *.fsdb *.daidir* work.lib++* work/ *.vdb* *.log
	rm -rf transcript* waveform.wlf* verdi* tr_db.log* *.vpd *.shm *.trn *.dsn
	rm -rf DVEfiles/ inter.vpd vcdplus.vpd novas.* .simvision/ INCA_libs/ cov_work/
	rm -rf urgReport/ AN.DB/ novas_dump.log nWaveLog/ debussy.log novas.conf novas.rc
	rm -rf *.key *.dmp *.tmp core* *.stackdump *.cm ./*.log.*
	@# Wait after cleanup to prevent VCS database access conflicts (configurable delay)
	@echo "Waiting $(CLEANUP_DELAY) seconds after cleanup to prevent database conflicts..."
	sleep $(CLEANUP_DELAY)
	@# Execute VCS
	$(VCS_FLAGS)

# Legacy target for backward compatibility
run_test: sim

# Verdi target for waveform viewing (restored to standard naming)
verdi:
	@echo "Starting Verdi for waveform analysis..."
	@if [ -f $(VERDI_PATH)/default.fsdb ]; then \
		echo "Using FSDB file: $(VERDI_PATH)/default.fsdb"; \
		verdi -ssf $(VERDI_PATH)/default.fsdb -elab simv.daidir/kdb &; \
	elif [ -f default.fsdb ]; then \
		echo "Using FSDB file: default.fsdb"; \
		verdi -ssf default.fsdb -elab simv.daidir/kdb &; \
	else \
		echo "No FSDB file found. Starting Verdi with database only."; \
		verdi -elab simv.daidir/kdb &; \
	fi

# Clean target
clean:
	@echo "Cleaning up simulation artifacts..."
	rm -rf simv* csrc vc_hdrs.h ucli.key *.fsdb *.daidir work.lib++ *.log *.vdb
	rm -rf work/ transcript waveform.wlf verdi* tr_db.log
	@echo "Clean completed."

# Help target
help:
	@echo "AXI4 VIP Unified Makefile"
	@echo "========================="
	@echo ""
	@echo "This Makefile works both standalone and with axi4_regression_makefile.py"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Clean and run simulation (default target)"
	@echo "  sim       - Run a test with specified parameters (primary target)"
	@echo "  run_test  - Alias for sim target (backward compatibility)"
	@echo "  verdi     - Launch Verdi for waveform analysis"
	@echo "  clean     - Clean up simulation artifacts"
	@echo "  help      - Display this help message"
	@echo ""
	@echo "Parameters:"
	@echo "  test         - Name of the test to run (default: axi4_default_test)"
	@echo "  SEED         - Random seed value (default: automatic, specify value to override)"
	@echo "  LOG_FILE     - Output log file name (default: \$${test}.log)"
	@echo "  FSDB_DUMP    - Enable FSDB dumping: 0|1 (default: 0)"
	@echo "  COVERAGE     - Enable coverage collection: 0|1 (default: 0)"
	@echo "  COV_DIR      - Coverage database directory (default: \$${test}.vdb)"
	@echo "  COMMAND_ADD  - Additional VCS command line options (default: empty)"
	@echo "  SIMV_NAME    - VCS executable name (default: simv)"
	@echo "  CLEANUP_DELAY - Delay after cleanup in seconds (default: 10)"
	@echo ""
	@echo "Usage Examples:"
	@echo "  make sim test=axi4_wstrb_test              # Auto-generate random seed"
	@echo "  make sim test=axi4_wstrb_test SEED=98765   # Use specific seed"
	@echo "  make sim test=axi4_burst_test COVERAGE=1 FSDB_DUMP=1"
	@echo "  make sim test=axi4_exclusive_test COMMAND_ADD='+define+DEBUG_MODE'"
	@echo "  make all test=axi4_test                    # Clean and run"
	@echo "  make verdi                                 # Launch Verdi"
	@echo ""
	@echo "Regression Script Usage:"
	@echo "  python3 axi4_regression_makefile.py --test-list my_tests.list"
	@echo "  python3 axi4_regression_makefile.py --cov --verbose"
	@echo ""
	@echo "Auto-detection:"
	@echo "  - Automatically detects if running from sim/, synopsys_sim/, or run_folder_XX/"
	@echo "  - Uses correct axi4_compile.f path based on location"
	@echo "  - Handles both automatic and manual seed generation"
	@echo "  - No symbolic links created - uses relative paths only"
	@echo ""
	@echo "Parallel Execution Support:"
	@echo "  - Uses folder isolation for parallel test execution"
	@echo "  - Each test runs in separate run_folder_XX directory"
	@echo "  - Standard VCS filenames work due to folder separation"
	@echo "  - Automatic cleanup prevents artifact conflicts"
