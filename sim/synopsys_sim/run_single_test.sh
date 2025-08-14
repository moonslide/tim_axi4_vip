#!/bin/bash

# Simple script to run a single test with specified mode
TEST_NAME=$1
MODE=$2

if [ -z "$TEST_NAME" ] || [ -z "$MODE" ]; then
    echo "Usage: $0 <test_name> <mode>"
    echo "Example: $0 axi4_qos_region_routing_reset_backpressure_test NONE"
    exit 1
fi

LOG_FILE="${TEST_NAME}_${MODE}.log"
echo "Running test: $TEST_NAME"
echo "Mode: $MODE"
echo "Log file: $LOG_FILE"

# Clean up before running
rm -rf simv* csrc* vc_hdrs.h ucli.key *.fsdb *.daidir* work.lib++* work/ *.vdb*

# Run the test
vcs -full64 -lca -kdb -sverilog +v2k \
    -debug_access+all -ntb_opts uvm-1.2 \
    -override_timescale=1ps/1ps \
    +nospecify +no_timing_check \
    +ntb_random_seed_automatic \
    +define+UVM_VERDI_COMPWAVE \
    -f ../axi4_compile.f \
    -debug_access+all -R \
    +UVM_TESTNAME=$TEST_NAME \
    +UVM_VERBOSITY=MEDIUM \
    +BUS_MATRIX_MODE=$MODE \
    -l $LOG_FILE 2>&1

# Check results
if [ -f $LOG_FILE ]; then
    echo ""
    echo "Test execution completed. Checking results..."
    
    # Check for errors - extract the actual count from the UVM report
    ERROR_COUNT=$(grep "^UVM_ERROR :" $LOG_FILE | awk '{print $3}' || echo "0")
    FATAL_COUNT=$(grep "^UVM_FATAL :" $LOG_FILE | awk '{print $3}' || echo "0")
    PASS_COUNT=$(grep -c "TEST RESULT: PASS" $LOG_FILE || echo "0")
    
    # Show bus matrix mode
    echo ""
    echo "Bus Matrix Configuration:"
    grep "Bus Matrix Mode:" $LOG_FILE | head -1
    grep "Final Mode:" $LOG_FILE | head -1
    
    echo ""
    echo "Test Results:"
    echo "- UVM_ERROR count: $ERROR_COUNT"
    echo "- UVM_FATAL count: $FATAL_COUNT"
    echo "- TEST PASSED count: $PASS_COUNT"
    
    if [ "$ERROR_COUNT" -eq "0" ] && [ "$FATAL_COUNT" -eq "0" ]; then
        echo ""
        echo "✅ Test completed without errors!"
    else
        echo ""
        echo "❌ Test failed with errors."
    fi
else
    echo "❌ Test log file not created. Compilation or runtime error."
fi