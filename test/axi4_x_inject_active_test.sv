`ifndef AXI4_X_INJECT_ACTIVE_TEST_INCLUDED_
`define AXI4_X_INJECT_ACTIVE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_x_inject_active_test
// Test for injecting X values during ACTIVE transactions (not idle)
//--------------------------------------------------------------------------------------------
class axi4_x_inject_active_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_x_inject_active_test)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_x_inject_active_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_x_inject_active_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_x_inject_active_test::new(string name = "axi4_x_inject_active_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//--------------------------------------------------------------------------------------------
function void axi4_x_inject_active_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for active X injection
  uvm_config_db#(bit)::set(this, "*", "enable_x_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "x_inject_during_active", 1);
  uvm_config_db#(bit)::set(this, "*", "allow_x_propagation", 1);
  
  // Set timeout for X recovery
  uvm_config_db#(int)::set(this, "*", "x_recovery_timeout", 100);
  
  `uvm_info(get_type_name(), "Build phase completed for Active X injection test", UVM_LOW)
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
//--------------------------------------------------------------------------------------------
task axi4_x_inject_active_test::run_phase(uvm_phase phase);
  axi4_virtual_x_inject_awvalid_active_seq active_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting Active X Injection Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Inject X during active transactions (not idle)", UVM_LOW)
  `uvm_info(get_type_name(), "  - X injected while valid signals are HIGH", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random timing for injection points", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", 
            test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the active X injection sequence
  active_seq = axi4_virtual_x_inject_awvalid_active_seq::type_id::create("active_seq");
  active_seq.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for completion
  #500ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

//--------------------------------------------------------------------------------------------
// Function: report_phase
//--------------------------------------------------------------------------------------------
function void axi4_x_inject_active_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  if(svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "Active X Injection Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "Active X Injection Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end
endfunction : report_phase

//--------------------------------------------------------------------------------------------
// Class: axi4_x_inject_random_test
// Test for random X injection during long-running tests
//--------------------------------------------------------------------------------------------
class axi4_x_inject_random_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_x_inject_random_test)

  extern function new(string name = "axi4_x_inject_random_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);

endclass : axi4_x_inject_random_test

function axi4_x_inject_random_test::new(string name = "axi4_x_inject_random_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_x_inject_random_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure for random X injection
  uvm_config_db#(bit)::set(this, "*", "enable_x_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "x_inject_random", 1);
  uvm_config_db#(bit)::set(this, "*", "allow_x_propagation", 1);
  
  `uvm_info(get_type_name(), "Build phase completed for Random X injection test", UVM_LOW)
endfunction : build_phase

task axi4_x_inject_random_test::run_phase(uvm_phase phase);
  axi4_virtual_x_inject_random_seq random_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting Random X Injection Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random X injection during long test", UVM_LOW)
  `uvm_info(get_type_name(), "  - Multiple injections at random intervals", UVM_LOW)
  `uvm_info(get_type_name(), "  - Different signals targeted randomly", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the random X injection sequence
  random_seq = axi4_virtual_x_inject_random_seq::type_id::create("random_seq");
  random_seq.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for completion
  #1000ns;
  
  phase.drop_objection(this);
  
endtask : run_phase`endif
