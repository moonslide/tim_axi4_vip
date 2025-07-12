# AXI4 VIP Makefile
# This Makefile provides targets for running tests with the axi4_regression_makefile.py script

# Default values
TEST_NAME ?= axi4_default_test
SEED ?= 12345
LOG_FILE ?= $(TEST_NAME).log
RUN_DIR ?= .
FSDB_DUMP ?= 0
COVERAGE ?= 0
COV_DIR ?= $(TEST_NAME).vdb
COMMAND_ADD ?=

# VCS base command
VCS_BASE_CMD = vcs -full64 -lca -kdb -sverilog +v2k \
               -debug_access+all -ntb_opts uvm-1.2 \
               +ntb_random_seed=$(SEED) -override_timescale=1ps/1ps \
               +nospecify +no_timing_check

# Conditional compilation flags
VCS_FLAGS = $(VCS_BASE_CMD)

# Add FSDB dumping if enabled
ifeq ($(FSDB_DUMP),1)
VCS_FLAGS += +define+DUMP_FSDB
endif

# Add coverage flags if enabled
ifeq ($(COVERAGE),1)
VCS_FLAGS += -cm line+cond+fsm+tgl+branch+assert -cm_dir $(COV_DIR) -cm_name $(TEST_NAME)
endif

# Add UVM and testbench specific flags
VCS_FLAGS += +define+UVM_VERDI_COMPWAVE -f axi4_compile.f \
             -debug_access+all -R +UVM_TESTNAME=$(TEST_NAME) \
             +UVM_VERBOSITY=MEDIUM +plusarg_ignore

# Add any custom command line additions
ifneq ($(COMMAND_ADD),)
VCS_FLAGS += $(COMMAND_ADD)
endif

# Final log file flag
VCS_FLAGS += -l $(LOG_FILE)

.PHONY: run_test clean help

# Main target for running tests
run_test:
	@echo "==============================================="
	@echo "Running AXI4 Test: $(TEST_NAME)"
	@echo "Seed: $(SEED)"
	@echo "Log File: $(LOG_FILE)"
	@echo "Run Directory: $(RUN_DIR)"
	@echo "FSDB Dump: $(FSDB_DUMP)"
	@echo "Coverage: $(COVERAGE)"
	@echo "==============================================="
	@# Change to the run directory and execute VCS
	cd $(RUN_DIR) && \
	rm -rf simv* csrc vc_hdrs.h ucli.key *.fsdb *.daidir work.lib++ && \
	$(VCS_FLAGS)

# Clean target
clean:
	@echo "Cleaning up simulation artifacts..."
	rm -rf simv* csrc vc_hdrs.h ucli.key *.fsdb *.daidir work.lib++ *.log *.vdb

# Help target
help:
	@echo "AXI4 VIP Makefile"
	@echo "=================="
	@echo ""
	@echo "Targets:"
	@echo "  run_test  - Run a test with specified parameters"
	@echo "  clean     - Clean up simulation artifacts"
	@echo "  help      - Display this help message"
	@echo ""
	@echo "Parameters:"
	@echo "  TEST_NAME    - Name of the test to run (default: axi4_default_test)"
	@echo "  SEED         - Random seed value (default: 12345)"
	@echo "  LOG_FILE     - Output log file name (default: \$${TEST_NAME}.log)"
	@echo "  RUN_DIR      - Directory to run the test in (default: .)"
	@echo "  FSDB_DUMP    - Enable FSDB dumping: 0|1 (default: 0)"
	@echo "  COVERAGE     - Enable coverage collection: 0|1 (default: 0)"
	@echo "  COV_DIR      - Coverage database directory (default: \$${TEST_NAME}.vdb)"
	@echo "  COMMAND_ADD  - Additional VCS command line options (default: empty)"
	@echo ""
	@echo "Examples:"
	@echo "  make run_test TEST_NAME=axi4_wstrb_test SEED=98765"
	@echo "  make run_test TEST_NAME=axi4_burst_test COVERAGE=1 FSDB_DUMP=1"
	@echo "  make run_test TEST_NAME=axi4_exclusive_test COMMAND_ADD='+define+DEBUG_MODE'"