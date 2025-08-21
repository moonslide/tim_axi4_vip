`ifndef AXI4_ERROR_INJECT_BREADY_X_TEST_INCLUDED_
`define AXI4_ERROR_INJECT_BREADY_X_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_error_inject_bready_x_test
// Test for injecting X values on BREADY signal
//--------------------------------------------------------------------------------------------
class axi4_error_inject_bready_x_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_error_inject_bready_x_test)

  // Virtual sequence handle
  // No need for sequence handle - base class handles it

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_error_inject_bready_x_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_error_inject_bready_x_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_error_inject_bready_x_test::new(string name = "axi4_error_inject_bready_x_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//--------------------------------------------------------------------------------------------
function void axi4_error_inject_bready_x_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for error injection
  uvm_config_db#(bit)::set(this, "*", "enable_x_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "allow_x_propagation", 1);
  
  // Set timeout for X recovery
  uvm_config_db#(int)::set(this, "*", "x_recovery_timeout", 100);
  
  `uvm_info(get_type_name(), "Build phase completed for BREADY X injection test", UVM_LOW)
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
//--------------------------------------------------------------------------------------------
task axi4_error_inject_bready_x_test::run_phase(uvm_phase phase);
  axi4_virtual_error_inject_bready_x_seq bready_x_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting BREADY X Injection Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Inject X on BREADY signal", UVM_LOW)
  `uvm_info(get_type_name(), "  - Verify protocol violation handling", UVM_LOW)
  `uvm_info(get_type_name(), "  - Verify recovery after X clears", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", 
            test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the specific BREADY X injection sequence
  bready_x_seq = axi4_virtual_error_inject_bready_x_seq::type_id::create("bready_x_seq");
  bready_x_seq.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for completion
  #300ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

//--------------------------------------------------------------------------------------------
// Function: report_phase
//--------------------------------------------------------------------------------------------
function void axi4_error_inject_bready_x_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  if(svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "BREADY X Injection Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "BREADY X Injection Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end
endfunction : report_phase

`endif