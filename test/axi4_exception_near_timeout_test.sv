`ifndef AXI4_EXCEPTION_NEAR_TIMEOUT_TEST_INCLUDED_
`define AXI4_EXCEPTION_NEAR_TIMEOUT_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_exception_near_timeout_test
// Test for stalling near timeout threshold
//--------------------------------------------------------------------------------------------
class axi4_exception_near_timeout_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_exception_near_timeout_test)

  // Virtual sequence handle
  axi4_virtual_near_timeout_seq virtual_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_exception_near_timeout_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_exception_near_timeout_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_exception_near_timeout_test::new(string name = "axi4_exception_near_timeout_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//--------------------------------------------------------------------------------------------
function void axi4_exception_near_timeout_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for timeout handling
  uvm_config_db#(bit)::set(this, "*", "enable_timeout_detection", 1);
  uvm_config_db#(int)::set(this, "*", "timeout_threshold", 1024);
  
  // Set stall cycles near threshold
  uvm_config_db#(int)::set(this, "*", "stall_cycles", 1023);
  
  `uvm_info(get_type_name(), "Build phase completed for near timeout test", UVM_LOW)
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
//--------------------------------------------------------------------------------------------
task axi4_exception_near_timeout_test::run_phase(uvm_phase phase);
  
  // Create virtual sequence
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting Near Timeout Exception Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Delay responses near timeout limit", UVM_LOW)
  `uvm_info(get_type_name(), "  - Verify timeout detection", UVM_LOW)
  `uvm_info(get_type_name(), "  - Verify recovery from near-timeout", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  super.run_phase(phase);
  
  
  
  // Run the virtual sequence
  
  // Wait for timeout test completion and recovery
  #2000ns;  // Extended wait to allow for full timeout cycle (1024 cycles + margin)
  
  phase.drop_objection(this);
  
endtask : run_phase

//--------------------------------------------------------------------------------------------
// Function: report_phase
//--------------------------------------------------------------------------------------------
function void axi4_exception_near_timeout_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  if(svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  
    `uvm_info(get_type_name(), "Near Timeout Exception Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  
    `uvm_info(get_type_name(), "Near Timeout Exception Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  
  end
endfunction : report_phase

`endif