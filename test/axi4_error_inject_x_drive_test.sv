`ifndef AXI4_ERROR_INJECT_X_DRIVE_TEST_INCLUDED_
`define AXI4_ERROR_INJECT_X_DRIVE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_error_inject_x_drive_test
// Test for X-value injection on multiple AXI4 signals simultaneously
//--------------------------------------------------------------------------------------------
class axi4_error_inject_x_drive_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_error_inject_x_drive_test)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_error_inject_x_drive_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);

endclass : axi4_error_inject_x_drive_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_error_inject_x_drive_test::new(string name = "axi4_error_inject_x_drive_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//--------------------------------------------------------------------------------------------
function void axi4_error_inject_x_drive_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Enable X-value injection on multiple signals
  uvm_config_db#(bit)::set(this, "*", "inject_x_on_awvalid", 1);
  uvm_config_db#(bit)::set(this, "*", "inject_x_on_wdata", 1);
  uvm_config_db#(bit)::set(this, "*", "inject_x_on_arvalid", 1);
  
  `uvm_info(get_type_name(), "Configured for X-value injection on multiple AXI4 signals", UVM_LOW)
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
//--------------------------------------------------------------------------------------------
task axi4_error_inject_x_drive_test::run_phase(uvm_phase phase);
  `uvm_info(get_type_name(), "Starting X-drive error injection test", UVM_LOW)
  
  // Call parent run_phase which handles the sequence execution
  super.run_phase(phase);
  
  `uvm_info(get_type_name(), "X-drive error injection test completed", UVM_LOW)
endtask : run_phase

`endif