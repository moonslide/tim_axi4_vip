#!/bin/bash

# Script to fix multiple super.run_phase() calls in exception tests

echo "Fixing exception tests with multiple super.run_phase() calls..."

# Fix axi4_exception_abort_arvalid_test
echo "Fixing axi4_exception_abort_arvalid_test.sv..."
sed -i '59,75d' axi4_exception_abort_arvalid_test.sv
sed -i '59i\  `uvm_info(get_type_name(), "===============================================", UVM_LOW)' axi4_exception_abort_arvalid_test.sv
sed -i '60i\  `uvm_info(get_type_name(), "Starting ARVALID Abort Exception Test", UVM_LOW)' axi4_exception_abort_arvalid_test.sv
sed -i '61i\  `uvm_info(get_type_name(), "===============================================", UVM_LOW)' axi4_exception_abort_arvalid_test.sv
sed -i '62i\  ' axi4_exception_abort_arvalid_test.sv
sed -i '63i\  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)' axi4_exception_abort_arvalid_test.sv
sed -i '64i\  `uvm_info(get_type_name(), "  - Master aborts ARVALID before handshake", UVM_LOW)' axi4_exception_abort_arvalid_test.sv
sed -i '65i\  `uvm_info(get_type_name(), "  - Verify DUT does not latch invalid request", UVM_LOW)' axi4_exception_abort_arvalid_test.sv
sed -i '66i\  `uvm_info(get_type_name(), "  - Verify no read side effects occur", UVM_LOW)' axi4_exception_abort_arvalid_test.sv
sed -i '67i\  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)' axi4_exception_abort_arvalid_test.sv
sed -i '68i\  `uvm_info(get_type_name(), "===============================================", UVM_LOW)' axi4_exception_abort_arvalid_test.sv
sed -i '69i\  ' axi4_exception_abort_arvalid_test.sv
sed -i '70i\  // Call parent run_phase which handles sequence selection and execution' axi4_exception_abort_arvalid_test.sv
sed -i '71i\  super.run_phase(phase);' axi4_exception_abort_arvalid_test.sv
sed -i '72i\  ' axi4_exception_abort_arvalid_test.sv

# Fix axi4_exception_ecc_error_test
echo "Fixing axi4_exception_ecc_error_test.sv..."
sed -i '59,75d' axi4_exception_ecc_error_test.sv
sed -i '59i\  `uvm_info(get_type_name(), "===============================================", UVM_LOW)' axi4_exception_ecc_error_test.sv
sed -i '60i\  `uvm_info(get_type_name(), "Starting ECC Error Exception Test", UVM_LOW)' axi4_exception_ecc_error_test.sv
sed -i '61i\  `uvm_info(get_type_name(), "===============================================", UVM_LOW)' axi4_exception_ecc_error_test.sv
sed -i '62i\  ' axi4_exception_ecc_error_test.sv
sed -i '63i\  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)' axi4_exception_ecc_error_test.sv
sed -i '64i\  `uvm_info(get_type_name(), "  - Inject ECC errors on data path", UVM_LOW)' axi4_exception_ecc_error_test.sv
sed -i '65i\  `uvm_info(get_type_name(), "  - Verify error detection and reporting", UVM_LOW)' axi4_exception_ecc_error_test.sv
sed -i '66i\  `uvm_info(get_type_name(), "  - Verify error recovery mechanism", UVM_LOW)' axi4_exception_ecc_error_test.sv
sed -i '67i\  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)' axi4_exception_ecc_error_test.sv
sed -i '68i\  `uvm_info(get_type_name(), "===============================================", UVM_LOW)' axi4_exception_ecc_error_test.sv
sed -i '69i\  ' axi4_exception_ecc_error_test.sv
sed -i '70i\  // Call parent run_phase which handles sequence selection and execution' axi4_exception_ecc_error_test.sv
sed -i '71i\  super.run_phase(phase);' axi4_exception_ecc_error_test.sv
sed -i '72i\  ' axi4_exception_ecc_error_test.sv

# Fix axi4_exception_illegal_access_test
echo "Fixing axi4_exception_illegal_access_test.sv..."
sed -i '60,77d' axi4_exception_illegal_access_test.sv
sed -i '60i\  `uvm_info(get_type_name(), "===============================================", UVM_LOW)' axi4_exception_illegal_access_test.sv
sed -i '61i\  `uvm_info(get_type_name(), "Starting Illegal Access Exception Test", UVM_LOW)' axi4_exception_illegal_access_test.sv
sed -i '62i\  `uvm_info(get_type_name(), "===============================================", UVM_LOW)' axi4_exception_illegal_access_test.sv
sed -i '63i\  ' axi4_exception_illegal_access_test.sv
sed -i '64i\  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)' axi4_exception_illegal_access_test.sv
sed -i '65i\  `uvm_info(get_type_name(), "  - Access restricted memory regions", UVM_LOW)' axi4_exception_illegal_access_test.sv
sed -i '66i\  `uvm_info(get_type_name(), "  - Verify SLVERR response generation", UVM_LOW)' axi4_exception_illegal_access_test.sv
sed -i '67i\  `uvm_info(get_type_name(), "  - Verify access control enforcement", UVM_LOW)' axi4_exception_illegal_access_test.sv
sed -i '68i\  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)' axi4_exception_illegal_access_test.sv
sed -i '69i\  `uvm_info(get_type_name(), "===============================================", UVM_LOW)' axi4_exception_illegal_access_test.sv
sed -i '70i\  ' axi4_exception_illegal_access_test.sv
sed -i '71i\  // Call parent run_phase which handles sequence selection and execution' axi4_exception_illegal_access_test.sv
sed -i '72i\  super.run_phase(phase);' axi4_exception_illegal_access_test.sv
sed -i '73i\  ' axi4_exception_illegal_access_test.sv

# Fix axi4_exception_near_timeout_test
echo "Fixing axi4_exception_near_timeout_test.sv..."
sed -i '59,75d' axi4_exception_near_timeout_test.sv
sed -i '59i\  `uvm_info(get_type_name(), "===============================================", UVM_LOW)' axi4_exception_near_timeout_test.sv
sed -i '60i\  `uvm_info(get_type_name(), "Starting Near Timeout Exception Test", UVM_LOW)' axi4_exception_near_timeout_test.sv
sed -i '61i\  `uvm_info(get_type_name(), "===============================================", UVM_LOW)' axi4_exception_near_timeout_test.sv
sed -i '62i\  ' axi4_exception_near_timeout_test.sv
sed -i '63i\  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)' axi4_exception_near_timeout_test.sv
sed -i '64i\  `uvm_info(get_type_name(), "  - Delay responses near timeout limit", UVM_LOW)' axi4_exception_near_timeout_test.sv
sed -i '65i\  `uvm_info(get_type_name(), "  - Verify timeout detection", UVM_LOW)' axi4_exception_near_timeout_test.sv
sed -i '66i\  `uvm_info(get_type_name(), "  - Verify recovery from near-timeout", UVM_LOW)' axi4_exception_near_timeout_test.sv
sed -i '67i\  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)' axi4_exception_near_timeout_test.sv
sed -i '68i\  `uvm_info(get_type_name(), "===============================================", UVM_LOW)' axi4_exception_near_timeout_test.sv
sed -i '69i\  ' axi4_exception_near_timeout_test.sv
sed -i '70i\  // Call parent run_phase which handles sequence selection and execution' axi4_exception_near_timeout_test.sv
sed -i '71i\  super.run_phase(phase);' axi4_exception_near_timeout_test.sv
sed -i '72i\  ' axi4_exception_near_timeout_test.sv

# Also remove wrong comments from report_phase in all files
echo "Cleaning up report_phase comments..."
for file in axi4_exception_*.sv; do
  sed -i '/^  \/\/ Call parent.*run_phase.*$/d' $file
done

echo "Done! All exception tests have been fixed."