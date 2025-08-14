#!/bin/bash

# Test script for all 3 enhanced tests in all 3 modes
# Tests to run:
# 1. axi4_qos_region_routing_reset_backpressure_test
# 2. axi4_saturation_midburst_reset_qos_boundary_test  
# 3. axi4_write_heavy_midburst_reset_rw_contention_test

echo "=========================================="
echo "ENHANCED TESTS - 3 MODE VERIFICATION"
echo "=========================================="
echo "Tests: QoS Region, Saturation Midburst, Write Heavy"
echo "Modes: NONE (4x4 no ref), 4x4 (with ref), ENHANCED (10x10)"
echo "=========================================="

# Array of tests
tests=(
    "axi4_qos_region_routing_reset_backpressure_test"
    "axi4_saturation_midburst_reset_qos_boundary_test"
    "axi4_write_heavy_midburst_reset_rw_contention_test"
)

# Array of modes
modes=(
    "NONE"
    "4x4"
    "ENHANCED"
)

# Results file
RESULTS_FILE="enhanced_test_results.txt"
echo "Enhanced Test Results - $(date)" > $RESULTS_FILE
echo "===========================================" >> $RESULTS_FILE

# Function to run test and check results
run_test() {
    local test_name=$1
    local mode=$2
    local log_file="${test_name}_${mode}.log"
    
    echo ""
    echo "Running: $test_name with mode $mode"
    echo "Log: $log_file"
    echo "----------------------------------------"
    
    # Run test with specific mode
    make sim test=$test_name LOG_FILE=$log_file COMMAND_ADD="+BUS_MATRIX_MODE=$mode" > compile_${test_name}_${mode}.log 2>&1
    
    # Check for UVM_ERROR
    if [ -f $log_file ]; then
        error_count=$(grep -c "UVM_ERROR" $log_file 2>/dev/null || echo "0")
        test_pass=$(grep -c "TEST PASSED" $log_file 2>/dev/null || echo "0")
        
        if [ "$error_count" -eq "0" ] && [ "$test_pass" -gt "0" ]; then
            echo "✅ PASS: $test_name in $mode mode (0 UVM_ERROR)"
            echo "$test_name | $mode | PASS | 0 UVM_ERROR" >> $RESULTS_FILE
        else
            echo "❌ FAIL: $test_name in $mode mode ($error_count UVM_ERROR)"
            echo "$test_name | $mode | FAIL | $error_count UVM_ERROR" >> $RESULTS_FILE
        fi
        
        # Show mode confirmation from log
        grep "Bus Matrix Mode:" $log_file | head -1
        grep "Final Mode:" $log_file | head -1
    else
        echo "❌ ERROR: Log file not created for $test_name in $mode mode"
        echo "$test_name | $mode | ERROR | Log not created" >> $RESULTS_FILE
    fi
}

# Main test loop
for test in "${tests[@]}"; do
    for mode in "${modes[@]}"; do
        run_test $test $mode
    done
done

echo ""
echo "=========================================="
echo "VERIFICATION SUMMARY"
echo "=========================================="
cat $RESULTS_FILE

# Count results
echo ""
echo "Overall Statistics:"
echo "-------------------"
pass_count=$(grep -c "PASS" $RESULTS_FILE)
fail_count=$(grep -c "FAIL" $RESULTS_FILE)
error_count=$(grep -c "ERROR" $RESULTS_FILE)

echo "Total Tests Run: $((${#tests[@]} * ${#modes[@]}))"
echo "Passed: $pass_count"
echo "Failed: $fail_count"
echo "Errors: $error_count"

if [ "$fail_count" -eq "0" ] && [ "$error_count" -eq "0" ]; then
    echo ""
    echo "🎉 ALL TESTS PASSED! 🎉"
else
    echo ""
    echo "⚠️ Some tests failed. Check logs for details."
fi

echo ""
echo "Detailed logs available in:"
echo "- compile_*.log (compilation output)"
echo "- *_*.log (test execution logs)"
echo "- $RESULTS_FILE (summary)"