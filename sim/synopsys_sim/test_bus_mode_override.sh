#!/bin/bash

# Test script to verify BUS_MATRIX_MODE command line override works correctly

echo "============================================="
echo "Testing BUS_MATRIX_MODE Command Line Override"
echo "============================================="

# Test directory
TEST_DIR="sim_test_bus_mode"
mkdir -p $TEST_DIR
cd $TEST_DIR

echo ""
echo "1. Testing NONE mode (1 master/1 slave)..."
echo "============================================="
../run_test.csh axi4_error_inject_x_drive_test +UVM_TESTNAME=axi4_error_inject_x_drive_test +BUS_MATRIX_MODE=NONE +UVM_VERBOSITY=UVM_MEDIUM 2>&1 | tee none_mode.log
grep -E "NONE mode|Using 1 master|Command line override: BUS_MATRIX_MODE=NONE" none_mode.log
if [ $? -eq 0 ]; then
    echo "✓ NONE mode detected correctly"
else
    echo "✗ NONE mode NOT detected"
fi

echo ""
echo "2. Testing BASE mode (4 masters/4 slaves)..."
echo "============================================="
../run_test.csh axi4_error_inject_x_drive_test +UVM_TESTNAME=axi4_error_inject_x_drive_test +BUS_MATRIX_MODE=BASE +UVM_VERBOSITY=UVM_MEDIUM 2>&1 | tee base_mode.log
grep -E "BASE mode|Using 4 master|Command line override: BUS_MATRIX_MODE=BASE" base_mode.log
if [ $? -eq 0 ]; then
    echo "✓ BASE mode detected correctly"
else
    echo "✗ BASE mode NOT detected"
fi

echo ""
echo "3. Testing ENHANCED mode (10 masters/10 slaves)..."
echo "============================================="
../run_test.csh axi4_error_inject_x_drive_test +UVM_TESTNAME=axi4_error_inject_x_drive_test +BUS_MATRIX_MODE=ENHANCED +UVM_VERBOSITY=UVM_MEDIUM 2>&1 | tee enhanced_mode.log
grep -E "ENHANCED mode|Using all 10 master|Command line override: BUS_MATRIX_MODE=ENHANCED" enhanced_mode.log
if [ $? -eq 0 ]; then
    echo "✓ ENHANCED mode detected correctly"
else
    echo "✗ ENHANCED mode NOT detected"
fi

echo ""
echo "4. Testing default mode (should use test's default)..."
echo "============================================="
../run_test.csh axi4_error_inject_x_drive_test +UVM_TESTNAME=axi4_error_inject_x_drive_test +UVM_VERBOSITY=UVM_MEDIUM 2>&1 | tee default_mode.log
grep -E "Test configuration set:" default_mode.log
if [ $? -eq 0 ]; then
    echo "✓ Default mode runs without override"
else
    echo "✗ Default mode failed"
fi

echo ""
echo "============================================="
echo "Summary of Results:"
echo "============================================="
echo -n "NONE mode: "
grep -q "Using 1 master and 1 slave" none_mode.log && echo "PASS" || echo "FAIL"
echo -n "BASE mode: "
grep -q "Using 4 masters and 4 slaves" base_mode.log && echo "PASS" || echo "FAIL"
echo -n "ENHANCED mode: "
grep -q "Using all.*masters and.*slaves" enhanced_mode.log && echo "PASS" || echo "FAIL"

cd ..