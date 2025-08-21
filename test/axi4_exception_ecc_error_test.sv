`ifndef AXI4_EXCEPTION_ECC_ERROR_TEST_INCLUDED_
`define AXI4_EXCEPTION_ECC_ERROR_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_exception_ecc_error_test
// Test for simulating ECC/parity errors
//--------------------------------------------------------------------------------------------
class axi4_exception_ecc_error_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_exception_ecc_error_test)

  // Virtual sequence handle
  // No need for sequence handle - base class handles it

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_exception_ecc_error_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_exception_ecc_error_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_exception_ecc_error_test::new(string name = "axi4_exception_ecc_error_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//--------------------------------------------------------------------------------------------
function void axi4_exception_ecc_error_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for ECC error handling
  uvm_config_db#(bit)::set(this, "*", "enable_ecc_checking", 1);
  uvm_config_db#(bit)::set(this, "*", "inject_ecc_errors", 1);
  
  // Set ECC error location
  uvm_config_db#(bit[63:0])::set(this, "*", "ecc_error_addr", 64'h0000_0000_0000_1B00);
  
  `uvm_info(get_type_name(), "Build phase completed for ECC error test", UVM_LOW)
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
//--------------------------------------------------------------------------------------------
task axi4_exception_ecc_error_test::run_phase(uvm_phase phase);
  
  // Create virtual sequence
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting ECC Error Exception Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Inject ECC errors on data path", UVM_LOW)
  `uvm_info(get_type_name(), "  - Verify error detection and reporting", UVM_LOW)
  `uvm_info(get_type_name(), "  - Verify error recovery mechanism", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  super.run_phase(phase);
  
  
  
  // Run the virtual sequence
  
  // Wait for completion
  #200ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

//--------------------------------------------------------------------------------------------
// Function: report_phase
//--------------------------------------------------------------------------------------------
function void axi4_exception_ecc_error_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  if(svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  
    `uvm_info(get_type_name(), "ECC Error Exception Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  
    `uvm_info(get_type_name(), "ECC Error Exception Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  
  end
endfunction : report_phase

`endif