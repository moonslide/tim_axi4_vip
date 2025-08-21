#!/bin/bash

echo "Fixing duplicate super.run_phase() calls..."

# List of files to fix
ALL_TEST_FILES=(
    "test/axi4_error_inject_awaddr_x_test.sv"
    "test/axi4_error_inject_wdata_x_test.sv"
    "test/axi4_error_inject_arvalid_x_test.sv"
    "test/axi4_error_inject_bready_x_test.sv"
    "test/axi4_error_inject_rready_x_test.sv"
    "test/axi4_exception_abort_awvalid_test.sv"
    "test/axi4_exception_abort_arvalid_test.sv"
    "test/axi4_exception_ecc_error_test.sv"
    "test/axi4_exception_illegal_access_test.sv"
    "test/axi4_exception_near_timeout_test.sv"
)

for file in "${ALL_TEST_FILES[@]}"; do
    echo "Cleaning $file..."
    
    # Remove all the duplicate super.run_phase calls from run_phase
    sed -i '/^  \/\/ Call parent.*s run_phase which handles sequence selection and execution$/d' "$file"
    sed -i '/^  super.run_phase(phase);$/d' "$file"
    
    # Add single super.run_phase call after the test description
    # Find the last test description line and add super.run_phase after it
    sed -i '/`uvm_info(get_type_name(), "===============================================", UVM_LOW)$/a\  \n  // Call parent'\''s run_phase which handles sequence selection and execution\n  super.run_phase(phase);' "$file"
    
    # Remove duplicate lines from report_phase
    sed -i '/report_phase/,/endfunction/{/super.run_phase(phase);/d}' "$file"
done

echo "Fixed all duplicate super.run_phase() calls!"