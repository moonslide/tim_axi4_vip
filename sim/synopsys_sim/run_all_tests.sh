#!/bin/bash

# Comprehensive test script for all 3 enhanced tests in all 3 modes

echo "=========================================="
echo "COMPREHENSIVE 3-MODE TEST VERIFICATION"  
echo "=========================================="
echo "Date: $(date)"
echo ""

# Define tests and modes
tests=(
    "axi4_qos_region_routing_reset_backpressure_test"
    "axi4_saturation_midburst_reset_qos_boundary_test"
    "axi4_write_heavy_midburst_reset_rw_contention_test"
)

modes=(
    "NONE"
    "4x4"
    "ENHANCED"
)

# Results file
RESULTS_FILE="comprehensive_test_results.txt"
echo "Comprehensive Test Results - $(date)" > $RESULTS_FILE
echo "===========================================" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE

# Summary counters
total_tests=0
passed_tests=0
failed_tests=0

# Function to run test
run_test() {
    local test_name=$1
    local mode=$2
    local log_file="${test_name}_${mode}_final.log"
    
    echo "----------------------------------------"
    echo "Test: $test_name"
    echo "Mode: $mode"
    echo "Starting at: $(date +%T)"
    
    # Clean and run
    rm -rf simv* csrc* vc_hdrs.h ucli.key *.fsdb *.daidir* work.lib++* work/ *.vdb*
    
    # Run test
    vcs -full64 -lca -kdb -sverilog +v2k \
        -debug_access+all -ntb_opts uvm-1.2 \
        -override_timescale=1ps/1ps \
        +nospecify +no_timing_check \
        +ntb_random_seed_automatic \
        +define+UVM_VERDI_COMPWAVE \
        -f ../axi4_compile.f \
        -debug_access+all -R \
        +UVM_TESTNAME=$test_name \
        +UVM_VERBOSITY=MEDIUM \
        +BUS_MATRIX_MODE=$mode \
        -l $log_file > compile_${test_name}_${mode}_final.log 2>&1
    
    # Check results
    if [ -f $log_file ]; then
        # Extract key information
        mode_confirm=$(grep "Final Mode:" $log_file | head -1 | sed 's/.*Final Mode: //')
        error_count=$(grep -c "UVM_ERROR" $log_file | tail -1)
        fatal_count=$(grep -c "UVM_FATAL" $log_file | tail -1)
        
        # Determine pass/fail
        if [ "$error_count" = "0" ] && [ "$fatal_count" = "0" ]; then
            echo "✅ PASS: 0 UVM_ERROR, 0 UVM_FATAL"
            echo "$test_name | $mode | PASS | 0 UVM_ERROR | Mode: $mode_confirm" >> $RESULTS_FILE
            ((passed_tests++))
        else
            echo "❌ FAIL: $error_count UVM_ERROR, $fatal_count UVM_FATAL"
            echo "$test_name | $mode | FAIL | $error_count UVM_ERROR | Mode: $mode_confirm" >> $RESULTS_FILE
            ((failed_tests++))
        fi
    else
        echo "❌ ERROR: Test did not complete"
        echo "$test_name | $mode | ERROR | Test did not complete" >> $RESULTS_FILE
        ((failed_tests++))
    fi
    
    ((total_tests++))
    echo "Completed at: $(date +%T)"
}

# Main test execution
echo "Starting test execution..."
echo ""

for test in "${tests[@]}"; do
    for mode in "${modes[@]}"; do
        run_test $test $mode
    done
done

# Generate summary report
echo ""
echo "=========================================="
echo "FINAL VERIFICATION REPORT"
echo "=========================================="
echo ""

echo "Test Matrix Results:" >> $RESULTS_FILE
echo "-------------------" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE

# Print detailed results
echo "Detailed Results:"
echo "-----------------"
cat $RESULTS_FILE | grep "|"

echo ""
echo "Summary Statistics:"
echo "-------------------"
echo "Total Tests Run: $total_tests"
echo "Tests Passed: $passed_tests"
echo "Tests Failed: $failed_tests"
echo "Pass Rate: $(( passed_tests * 100 / total_tests ))%"

# Add summary to results file
echo "" >> $RESULTS_FILE
echo "Summary Statistics:" >> $RESULTS_FILE
echo "Total Tests: $total_tests" >> $RESULTS_FILE
echo "Passed: $passed_tests" >> $RESULTS_FILE
echo "Failed: $failed_tests" >> $RESULTS_FILE
echo "Pass Rate: $(( passed_tests * 100 / total_tests ))%" >> $RESULTS_FILE

# Final verdict
echo ""
if [ "$failed_tests" -eq "0" ]; then
    echo "🎉 VERIFICATION SUCCESSFUL! 🎉"
    echo "All enhanced tests passed in all 3 modes (NONE, 4x4, ENHANCED)"
    echo "" >> $RESULTS_FILE
    echo "✅ VERIFICATION SUCCESSFUL - All tests passed!" >> $RESULTS_FILE
else
    echo "⚠️ VERIFICATION INCOMPLETE"
    echo "Some tests failed. Check logs for details."
    echo "" >> $RESULTS_FILE
    echo "⚠️ VERIFICATION INCOMPLETE - Some tests failed" >> $RESULTS_FILE
fi

echo ""
echo "Results saved to: $RESULTS_FILE"
echo "Individual logs: *_*_final.log"
echo "Compilation logs: compile_*_*_final.log"