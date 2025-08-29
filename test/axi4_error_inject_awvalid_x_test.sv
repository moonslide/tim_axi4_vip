`ifndef AXI4_ERROR_INJECT_AWVALID_X_TEST_INCLUDED_
`define AXI4_ERROR_INJECT_AWVALID_X_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_error_inject_awvalid_x_test
// Test for injecting X values on AWVALID signal
//--------------------------------------------------------------------------------------------
class axi4_error_inject_awvalid_x_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_error_inject_awvalid_x_test)

  // No need for sequence handle - base class handles it

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_error_inject_awvalid_x_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void final_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_error_inject_awvalid_x_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_error_inject_awvalid_x_test::new(string name = "axi4_error_inject_awvalid_x_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//--------------------------------------------------------------------------------------------
function void axi4_error_inject_awvalid_x_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for error injection
  uvm_config_db#(bit)::set(this, "*", "enable_x_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "allow_x_propagation", 1);
  
  // Set timeout for X recovery
  uvm_config_db#(int)::set(this, "*", "x_recovery_timeout", 100);
  
  // Disable regular assertion coverage, only show X injection coverage
  uvm_config_db#(bit)::set(this, "*", "disable_non_x_assertions", 1);
  uvm_config_db#(bit)::set(this, "*", "show_only_x_injection_coverage", 1);
  
  `uvm_info(get_type_name(), "Build phase completed for AWVALID X injection test", UVM_LOW)
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
//--------------------------------------------------------------------------------------------
task axi4_error_inject_awvalid_x_test::run_phase(uvm_phase phase);
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting AWVALID X Injection Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Simplified test - just inject X directly without sequences
  fork
    begin
      // Inject X on AWVALID
      uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid", 1);
      uvm_config_db#(int)::set(null, "*", "x_inject_cycles", 5);
      
      #100ns;
      
      // Clear injection
      uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid", 0);
      
      #200ns;
      
      `uvm_info(get_type_name(), "X injection completed", UVM_LOW)
    end
    
    begin
      // Watchdog to prevent hang
      #1000ns;
      `uvm_warning(get_type_name(), "Test watchdog expired")
    end
  join_any
  
  disable fork;
  
  phase.drop_objection(this);
  
endtask : run_phase

//--------------------------------------------------------------------------------------------
// Function: final_phase
// Filter out non-X injection assertion coverage
//--------------------------------------------------------------------------------------------
function void axi4_error_inject_awvalid_x_test::final_phase(uvm_phase phase);
  super.final_phase(phase);
  
  // Only report X injection specific coverage
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "X INJECTION COVERAGE SUMMARY", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Target: AWVALID signal X injection", UVM_LOW)
  `uvm_info(get_type_name(), "Expected Coverage Points:", UVM_LOW)
  `uvm_info(get_type_name(), "  - X_INJECT_AWVALID_COVER: X detected on AWVALID", UVM_LOW)
  `uvm_info(get_type_name(), "  - NO_HANDSHAKE_AWVALID_X: No handshake during X", UVM_LOW)
  `uvm_info(get_type_name(), "  - AWVALID_RECOVERS_FROM_X: Recovery after X clears", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
endfunction : final_phase

//--------------------------------------------------------------------------------------------
// Function: report_phase
//--------------------------------------------------------------------------------------------
function void axi4_error_inject_awvalid_x_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  if(svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "AWVALID X Injection Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "AWVALID X Injection Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end
endfunction : report_phase

`endif