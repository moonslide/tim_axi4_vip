#!/bin/bash
#==============================================================================
# Example script showing how to use enhanced debug features for QoS tests
#==============================================================================

echo "==================================================================="
echo "AXI VIP QoS Debug Examples"
echo "==================================================================="
echo ""

# Function to run test and check results
run_test() {
    local test_name=$1
    local debug_opts=$2
    local desc=$3
    
    echo "-------------------------------------------------------------------"
    echo "Running: $desc"
    echo "Command: make run TEST=$test_name $debug_opts"
    echo "-------------------------------------------------------------------"
    
    # Show what the command would do (remove echo to actually run)
    echo "make run TEST=$test_name $debug_opts"
    echo ""
}

# Example 1: Debug QoS basic priority with transaction logging
run_test "axi4_qos_basic_priority_test" \
         "DEBUG_LEVEL=2 TRANS_RECORD=1 DUMP_FSDB=1" \
         "QoS Basic Priority Test with Transaction Debug and Waveforms"

# Example 2: Debug QoS fairness with full debug
run_test "axi4_qos_equal_priority_fairness_test" \
         "DEBUG_LEVEL=4 UVM_DEBUG=1 VERBOSITY=UVM_FULL" \
         "QoS Fairness Test with Full Debug and UVM Traces"

# Example 3: Debug USER signal passthrough with performance monitoring
run_test "axi4_user_signal_passthrough_test" \
         "PERF_MONITOR=1 DEBUG_LEVEL=1" \
         "USER Signal Test with Performance Monitoring"

# Example 4: Stress test with coverage
run_test "axi4_qos_saturation_stress_test" \
         "COVERAGE=1 DEBUG_LEVEL=2" \
         "QoS Saturation Stress Test with Coverage Collection"

echo "==================================================================="
echo "Advanced Debug Commands:"
echo "==================================================================="
echo ""
echo "# Get platform and configuration info:"
echo "make debug_info"
echo ""
echo "# Run all QoS tests with basic debug:"
echo "make run_all_qos DEBUG_LEVEL=1"
echo ""
echo "# Analyze all logs after running tests:"
echo "make analyze_logs"
echo ""
echo "# Generate HTML report:"
echo "make report"
echo ""
echo "# Open waveforms in Verdi:"
echo "make verdi"
echo ""
echo "==================================================================="
echo "Debug Features Summary:"
echo "==================================================================="
echo ""
echo "1. Transaction-level debugging shows:"
echo "   - Every AXI transaction (address, data, response)"
echo "   - QoS values for each transaction"
echo "   - USER signal contents"
echo "   - Transaction ordering and arbitration decisions"
echo ""
echo "2. Protocol-level debugging shows:"
echo "   - Channel handshakes (VALID/READY)"
echo "   - Burst calculations"
echo "   - ID tracking and ordering"
echo "   - Error responses"
echo ""
echo "3. Scoreboard debugging shows:"
echo "   - Expected vs actual comparisons"
echo "   - Transaction matching"
echo "   - Coverage hits"
echo "   - Performance metrics"
echo ""
echo "4. UVM debug traces show:"
echo "   - Configuration database entries"
echo "   - Phase transitions"
echo "   - Objection raising/dropping"
echo "   - Resource database access"
echo ""
echo "==================================================================="