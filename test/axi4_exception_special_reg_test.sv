`ifndef AXI4_EXCEPTION_SPECIAL_REG_TEST_INCLUDED_
`define AXI4_EXCEPTION_SPECIAL_REG_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_exception_special_reg_test
// Test for special function register access patterns
//--------------------------------------------------------------------------------------------
class axi4_exception_special_reg_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_exception_special_reg_test)

  // No need for sequence handle - base class handles it

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_exception_special_reg_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_exception_special_reg_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_exception_special_reg_test::new(string name = "axi4_exception_special_reg_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//--------------------------------------------------------------------------------------------
function void axi4_exception_special_reg_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for special register handling
  uvm_config_db#(bit)::set(this, "*", "enable_special_registers", 1);
  uvm_config_db#(bit)::set(this, "*", "track_special_access", 1);
  
  // Set special register location
  uvm_config_db#(bit[63:0])::set(this, "*", "special_reg_addr", 64'h0000_0000_0000_1C00);
  uvm_config_db#(int)::set(this, "*", "num_special_reads", 4);
  
  `uvm_info(get_type_name(), "Build phase completed for special register test", UVM_LOW)
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
//--------------------------------------------------------------------------------------------
task axi4_exception_special_reg_test::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting Special Register Exception Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Consecutive reads to special register 0x1C00", UVM_LOW)
  `uvm_info(get_type_name(), "  - Verify special behaviors:", UVM_LOW)
  `uvm_info(get_type_name(), "    * Read-to-clear", UVM_LOW)
  `uvm_info(get_type_name(), "    * Counter increment", UVM_LOW)
  `uvm_info(get_type_name(), "    * Constant value", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", 
            test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Call parent's run_phase which handles sequence execution and objections
  super.run_phase(phase);
  
endtask : run_phase

//--------------------------------------------------------------------------------------------
// Function: report_phase
//--------------------------------------------------------------------------------------------
function void axi4_exception_special_reg_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  if(svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "Special Register Exception Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "Special Register Exception Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end
endfunction : report_phase

`endif