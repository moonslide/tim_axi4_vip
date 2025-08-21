`ifndef AXI4_EXCEPTION_ILLEGAL_ACCESS_TEST_INCLUDED_
`define AXI4_EXCEPTION_ILLEGAL_ACCESS_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_exception_illegal_access_test
// Test for accessing protected/illegal addresses
//--------------------------------------------------------------------------------------------
class axi4_exception_illegal_access_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_exception_illegal_access_test)

  // Virtual sequence handle
  // No need for sequence handle - base class handles it

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_exception_illegal_access_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_exception_illegal_access_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_exception_illegal_access_test::new(string name = "axi4_exception_illegal_access_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//--------------------------------------------------------------------------------------------
function void axi4_exception_illegal_access_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for protected access handling
  uvm_config_db#(bit)::set(this, "*", "enable_protected_regions", 1);
  uvm_config_db#(bit)::set(this, "*", "enable_access_control", 1);
  
  // Set protected region
  uvm_config_db#(bit[63:0])::set(this, "*", "protected_addr", 64'h0000_0000_0000_1A00);
  uvm_config_db#(bit[31:0])::set(this, "*", "unlock_key", 32'hDEADBEEF);
  
  `uvm_info(get_type_name(), "Build phase completed for illegal access test", UVM_LOW)
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
//--------------------------------------------------------------------------------------------
task axi4_exception_illegal_access_test::run_phase(uvm_phase phase);
  
  // Create virtual sequence
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting Illegal Access Exception Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Access restricted memory regions", UVM_LOW)
  `uvm_info(get_type_name(), "  - Verify SLVERR response generation", UVM_LOW)
  `uvm_info(get_type_name(), "  - Verify access control enforcement", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  super.run_phase(phase);
  
  
  
  // Run the virtual sequence
  
  // Wait for completion
  #300ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

//--------------------------------------------------------------------------------------------
// Function: report_phase
//--------------------------------------------------------------------------------------------
function void axi4_exception_illegal_access_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  if(svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  
    `uvm_info(get_type_name(), "Illegal Access Exception Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  
    `uvm_info(get_type_name(), "Illegal Access Exception Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  
  end
endfunction : report_phase

`endif