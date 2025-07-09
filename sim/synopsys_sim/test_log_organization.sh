#!/bin/bash
# Test script to verify log organization functionality

echo "Testing regression log organization..."

# Create a small test list with just a few tests
cat > test_log_org.list << EOF
axi4_blocking_test
axi4_nonblocking_test
axi4_wstrb_all_ones_test
EOF

# Run regression with the test list
echo "Running regression with 3 tests..."
python3 axi4_regression.py --test-list test_log_org.list -p 3 --timeout 300

# Check the results
if [ -d regression_result_* ]; then
    RESULT_DIR=$(ls -d regression_result_* | tail -1)
    echo ""
    echo "Checking log organization in $RESULT_DIR..."
    echo "Contents of logs folder:"
    ls -la $RESULT_DIR/logs/
    echo ""
    echo "Contents of pass_logs folder:"
    ls -la $RESULT_DIR/logs/pass_logs/
    echo ""
    echo "Contents of no_pass_logs folder:"
    ls -la $RESULT_DIR/logs/no_pass_logs/
    echo ""
    echo "Contents of main results folder (should not have individual test logs):"
    ls -la $RESULT_DIR/ | grep -E "\.log$" || echo "No individual test logs in main folder (correct)"
else
    echo "Error: No regression result folder found"
fi

# Clean up
rm -f test_log_org.list