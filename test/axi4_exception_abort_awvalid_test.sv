`ifndef AXI4_EXCEPTION_ABORT_AWVALID_TEST_INCLUDED_
`define AXI4_EXCEPTION_ABORT_AWVALID_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_exception_abort_awvalid_test
// Test for aborting AWVALID before handshake completes
//--------------------------------------------------------------------------------------------
class axi4_exception_abort_awvalid_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_exception_abort_awvalid_test)

  // Virtual sequence handle
  // No need for sequence handle - base class handles it

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_exception_abort_awvalid_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_exception_abort_awvalid_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_exception_abort_awvalid_test::new(string name = "axi4_exception_abort_awvalid_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//--------------------------------------------------------------------------------------------
function void axi4_exception_abort_awvalid_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for exception handling
  uvm_config_db#(bit)::set(this, "*", "enable_abort_handling", 1);
  uvm_config_db#(bit)::set(this, "*", "allow_premature_abort", 1);
  
  // Set abort window
  uvm_config_db#(int)::set(this, "*", "abort_after_cycles", 2);
  
  `uvm_info(get_type_name(), "Build phase completed for AWVALID abort test", UVM_LOW)
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
//--------------------------------------------------------------------------------------------
task axi4_exception_abort_awvalid_test::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting AWVALID Abort Exception Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Master aborts AWVALID before handshake", UVM_LOW)
  `uvm_info(get_type_name(), "  - Verify DUT does not latch invalid request", UVM_LOW)
  `uvm_info(get_type_name(), "  - Verify no write side effects occur", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  super.run_phase(phase);
  
endtask : run_phase

//--------------------------------------------------------------------------------------------
// Function: report_phase
//--------------------------------------------------------------------------------------------
function void axi4_exception_abort_awvalid_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  if(svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "AWVALID Abort Exception Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "AWVALID Abort Exception Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end
endfunction : report_phase

`endif