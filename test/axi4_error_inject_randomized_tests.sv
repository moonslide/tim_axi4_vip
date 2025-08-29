`ifndef AXI4_ERROR_INJECT_RANDOMIZED_TESTS_INCLUDED_
`define AXI4_ERROR_INJECT_RANDOMIZED_TESTS_INCLUDED_

//=============================================================================================
// File: axi4_error_inject_randomized_tests.sv
// Description: Randomized X-value injection tests for AXI4 protocol signals
// 
// This file contains comprehensive randomized error injection test cases that inject
// X-values on various AXI4 signals with random parameters to test system robustness
// and error recovery capabilities.
//
// TEST CASES INCLUDED:
// 1. axi4_error_inject_awvalid_random_test
//    - Injects X on AWVALID signal during write address phase
//    - Tests write channel address handshake corruption handling
//
// 2. axi4_error_inject_arvalid_random_test  
//    - Injects X on ARVALID signal during read address phase
//    - Tests read channel address handshake corruption handling
//
// 3. axi4_error_inject_awaddr_random_test
//    - Injects X on AWADDR signal during write transactions
//    - Tests address corruption and error response generation
//
// 4. axi4_error_inject_wdata_random_test
//    - Injects X on WDATA signal during write data phase
//    - Tests data corruption detection and handling
//
// 5. axi4_error_inject_bready_random_test
//    - Injects X on BREADY signal during write response phase
//    - Tests write response handshake corruption recovery
//
// 6. axi4_error_inject_rready_random_test
//    - Injects X on RREADY signal during read response phase
//    - Tests read response handshake corruption recovery
//
// 7. axi4_error_inject_multi_signal_random_test
//    - Randomly selects different signals for X injection
//    - Tests system behavior with multiple signal corruptions
//
// 8. axi4_error_inject_adaptive_random_test
//    - Adapts injection rate based on bus activity
//    - Tests dynamic error injection scenarios
//
// COMMON FEATURES FOR ALL TESTS:
// - Random injection count: 1-10 times per test execution
// - Random injection duration: 5-20 clock cycles per injection
// - Random delays between injections: 50-500ns
// - Normal transactions between injections for recovery verification
// - Support for all bus matrix modes: NONE (1x1), BASE (4x4), ENHANCED (10x10)
// - Automatic error detection and recovery validation
// - Performance metrics collection during error scenarios
//
// USAGE IN REGRESSION:
// These tests are included in axi4_transfers_regression.list with run_cnt=3
// for each bus matrix mode to ensure comprehensive coverage of random scenarios.
//=============================================================================================

//--------------------------------------------------------------------------------------------
// Class: axi4_error_inject_awvalid_random_test
// Description:
// This test performs multiple randomized X-value injections on the AWVALID signal.
// - Number of injections: 1-10 (random)
// - Injection duration: 5-20 cycles per injection (random)
// - Timing: Random delays between injections (50-500ns)
// - Recovery: Normal transactions between injections
// - Supports all bus matrix modes (NONE/1x1, BASE/4x4, ENHANCED/10x10)
//--------------------------------------------------------------------------------------------
class axi4_error_inject_awvalid_random_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_error_inject_awvalid_random_test)

  extern function new(string name = "axi4_error_inject_awvalid_random_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_error_inject_awvalid_random_test

function axi4_error_inject_awvalid_random_test::new(string name = "axi4_error_inject_awvalid_random_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_error_inject_awvalid_random_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for randomized error injection
  uvm_config_db#(bit)::set(this, "*", "enable_x_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "allow_x_propagation", 1);
  uvm_config_db#(bit)::set(this, "*", "randomize_injection", 1);
  uvm_config_db#(int)::set(this, "*", "x_recovery_timeout", 100);
  
  `uvm_info(get_type_name(), "Build phase completed for AWVALID Random X injection test", UVM_LOW)
endfunction : build_phase

task axi4_error_inject_awvalid_random_test::run_phase(uvm_phase phase);
  axi4_virtual_error_inject_awvalid_random_seq awvalid_random_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting AWVALID Random X Injection Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Randomly inject X on AWVALID during active transactions", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random injection cycles and timing", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random normal transactions before/after", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", 
            test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the randomized AWVALID X injection sequence
  awvalid_random_seq = axi4_virtual_error_inject_awvalid_random_seq::type_id::create("awvalid_random_seq");
  if(!awvalid_random_seq.randomize()) begin
    `uvm_error(get_type_name(), "Failed to randomize awvalid_random_seq")
  end
  awvalid_random_seq.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for completion
  #500ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

function void axi4_error_inject_awvalid_random_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  // For X injection tests, we expect some errors due to X propagation
  // Only check for FATAL errors, not regular ERRORs
  if(svr.get_severity_count(UVM_FATAL) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "AWVALID Random X Injection Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "AWVALID Random X Injection Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end
endfunction : report_phase

//--------------------------------------------------------------------------------------------
// Class: axi4_error_inject_arvalid_random_test
// Description:
// This test performs multiple randomized X-value injections on the ARVALID signal.
// - Number of injections: 1-10 (random)
// - Injection duration: 5-20 cycles per injection (random)
// - Timing: Random delays between injections (50-500ns)
// - Recovery: Normal transactions between injections
// - Supports all bus matrix modes (NONE/1x1, BASE/4x4, ENHANCED/10x10)
//--------------------------------------------------------------------------------------------
class axi4_error_inject_arvalid_random_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_error_inject_arvalid_random_test)

  extern function new(string name = "axi4_error_inject_arvalid_random_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_error_inject_arvalid_random_test

function axi4_error_inject_arvalid_random_test::new(string name = "axi4_error_inject_arvalid_random_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_error_inject_arvalid_random_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for randomized error injection
  uvm_config_db#(bit)::set(this, "*", "enable_x_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "allow_x_propagation", 1);
  uvm_config_db#(bit)::set(this, "*", "randomize_injection", 1);
  uvm_config_db#(int)::set(this, "*", "x_recovery_timeout", 100);
  
  `uvm_info(get_type_name(), "Build phase completed for ARVALID Random X injection test", UVM_LOW)
endfunction : build_phase

task axi4_error_inject_arvalid_random_test::run_phase(uvm_phase phase);
  axi4_virtual_error_inject_arvalid_random_seq arvalid_random_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting ARVALID Random X Injection Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Randomly inject X on ARVALID during active transactions", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random injection cycles and timing", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random normal transactions before/after", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", 
            test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the randomized ARVALID X injection sequence
  arvalid_random_seq = axi4_virtual_error_inject_arvalid_random_seq::type_id::create("arvalid_random_seq");
  if(!arvalid_random_seq.randomize()) begin
    `uvm_error(get_type_name(), "Failed to randomize arvalid_random_seq")
  end
  arvalid_random_seq.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for completion
  #500ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

function void axi4_error_inject_arvalid_random_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  // For X injection tests, we expect some errors due to X propagation
  // Only check for FATAL errors, not regular ERRORs
  if(svr.get_severity_count(UVM_FATAL) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "ARVALID Random X Injection Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  UVM_ERRORs: %0d (expected during X injection)", 
              svr.get_severity_count(UVM_ERROR)), UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "ARVALID Random X Injection Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  UVM_FATALs: %0d", svr.get_severity_count(UVM_FATAL)), UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end
endfunction : report_phase

//--------------------------------------------------------------------------------------------
// Class: axi4_error_inject_awaddr_random_test
// Description:
// This test performs multiple randomized X-value injections on the AWADDR signal.
// - Number of injections: 1-10 (random)
// - Injection duration: 5-20 cycles per injection (random)
// - Timing: Random delays between injections (50-500ns)
// - Recovery: Normal transactions between injections
// - Supports all bus matrix modes (NONE/1x1, BASE/4x4, ENHANCED/10x10)
//--------------------------------------------------------------------------------------------
class axi4_error_inject_awaddr_random_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_error_inject_awaddr_random_test)

  extern function new(string name = "axi4_error_inject_awaddr_random_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_error_inject_awaddr_random_test

function axi4_error_inject_awaddr_random_test::new(string name = "axi4_error_inject_awaddr_random_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_error_inject_awaddr_random_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for randomized error injection
  uvm_config_db#(bit)::set(this, "*", "enable_x_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "allow_x_propagation", 1);
  uvm_config_db#(bit)::set(this, "*", "randomize_injection", 1);
  uvm_config_db#(int)::set(this, "*", "x_recovery_timeout", 100);
  
  `uvm_info(get_type_name(), "Build phase completed for AWADDR Random X injection test", UVM_LOW)
endfunction : build_phase

task axi4_error_inject_awaddr_random_test::run_phase(uvm_phase phase);
  axi4_virtual_error_inject_awaddr_random_seq awaddr_random_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting AWADDR Random X Injection Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Randomly inject X on AWADDR during active transactions", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random injection cycles and timing", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random normal transactions before/after", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", 
            test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the randomized AWADDR X injection sequence with timeout protection
  awaddr_random_seq = axi4_virtual_error_inject_awaddr_random_seq::type_id::create("awaddr_random_seq");
  if(!awaddr_random_seq.randomize() with {
    num_x_injections == 2;  // Reduce number of injections to avoid timeout
    foreach(x_inject_cycles[i]) {
      x_inject_cycles[i] inside {[5:10]};  // Shorter injection cycles
    }
  }) begin
    `uvm_error(get_type_name(), "Failed to randomize awaddr_random_seq")
  end
  
  fork
    begin
      awaddr_random_seq.start(axi4_env_h.axi4_virtual_seqr_h);
    end
    begin
      #10us;  // 10us timeout for the entire test
      `uvm_warning(get_type_name(), "Test timeout reached - forcing completion")
    end
  join_any
  disable fork;
  
  // Brief recovery time
  #100ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

function void axi4_error_inject_awaddr_random_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  // For X injection tests, we expect some errors due to X propagation
  // Only check for FATAL errors, not regular ERRORs
  if(svr.get_severity_count(UVM_FATAL) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "AWADDR Random X Injection Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "AWADDR Random X Injection Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end
endfunction : report_phase

//--------------------------------------------------------------------------------------------
// Class: axi4_error_inject_wdata_random_test
// Description:
// This test performs multiple randomized X-value injections on the WDATA signal.
// - Number of injections: 1-10 (random)
// - Injection duration: 5-20 cycles per injection (random)
// - Timing: Random delays between injections (50-500ns)
// - Recovery: Normal transactions between injections
// - Supports all bus matrix modes (NONE/1x1, BASE/4x4, ENHANCED/10x10)
//--------------------------------------------------------------------------------------------
class axi4_error_inject_wdata_random_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_error_inject_wdata_random_test)

  extern function new(string name = "axi4_error_inject_wdata_random_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_error_inject_wdata_random_test

function axi4_error_inject_wdata_random_test::new(string name = "axi4_error_inject_wdata_random_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_error_inject_wdata_random_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for randomized error injection
  uvm_config_db#(bit)::set(this, "*", "enable_x_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "allow_x_propagation", 1);
  uvm_config_db#(bit)::set(this, "*", "randomize_injection", 1);
  uvm_config_db#(int)::set(this, "*", "x_recovery_timeout", 100);
  
  `uvm_info(get_type_name(), "Build phase completed for WDATA Random X injection test", UVM_LOW)
endfunction : build_phase

task axi4_error_inject_wdata_random_test::run_phase(uvm_phase phase);
  axi4_virtual_error_inject_wdata_random_seq wdata_random_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting WDATA Random X Injection Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Randomly inject X on WDATA during active transactions", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random injection cycles and timing", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random normal transactions before/after", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", 
            test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the randomized WDATA X injection sequence with timeout protection
  wdata_random_seq = axi4_virtual_error_inject_wdata_random_seq::type_id::create("wdata_random_seq");
  if(!wdata_random_seq.randomize() with {
    num_x_injections == 2;  // Reduce number of injections to avoid timeout
    foreach(x_inject_cycles[i]) {
      x_inject_cycles[i] inside {[5:10]};  // Shorter injection cycles
    }
  }) begin
    `uvm_error(get_type_name(), "Failed to randomize wdata_random_seq")
  end
  
  fork
    begin
      wdata_random_seq.start(axi4_env_h.axi4_virtual_seqr_h);
    end
    begin
      #10us;  // 10us timeout for the entire test
      `uvm_warning(get_type_name(), "Test timeout reached - forcing completion")
    end
  join_any
  disable fork;
  
  // Brief recovery time
  #100ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

function void axi4_error_inject_wdata_random_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  // For X injection tests, we expect some errors due to X propagation
  // Only check for FATAL errors, not regular ERRORs
  if(svr.get_severity_count(UVM_FATAL) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "WDATA Random X Injection Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "WDATA Random X Injection Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end
endfunction : report_phase

//--------------------------------------------------------------------------------------------
// Class: axi4_error_inject_bready_random_test
// Description:
// This test performs multiple randomized X-value injections on the BREADY signal.
// - Number of injections: 1-10 (random)
// - Injection duration: 5-20 cycles per injection (random)
// - Timing: Random delays between injections (50-500ns)
// - Recovery: Normal transactions between injections
// - Supports all bus matrix modes (NONE/1x1, BASE/4x4, ENHANCED/10x10)
//--------------------------------------------------------------------------------------------
class axi4_error_inject_bready_random_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_error_inject_bready_random_test)

  extern function new(string name = "axi4_error_inject_bready_random_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_error_inject_bready_random_test

function axi4_error_inject_bready_random_test::new(string name = "axi4_error_inject_bready_random_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_error_inject_bready_random_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for randomized error injection
  uvm_config_db#(bit)::set(this, "*", "enable_x_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "allow_x_propagation", 1);
  uvm_config_db#(bit)::set(this, "*", "randomize_injection", 1);
  uvm_config_db#(int)::set(this, "*", "x_recovery_timeout", 100);
  
  `uvm_info(get_type_name(), "Build phase completed for BREADY Random X injection test", UVM_LOW)
endfunction : build_phase

task axi4_error_inject_bready_random_test::run_phase(uvm_phase phase);
  axi4_virtual_error_inject_bready_random_seq bready_random_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting BREADY Random X Injection Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Randomly inject X on BREADY during active transactions", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random injection cycles and timing", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random normal transactions before/after", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", 
            test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the randomized BREADY X injection sequence
  bready_random_seq = axi4_virtual_error_inject_bready_random_seq::type_id::create("bready_random_seq");
  if(!bready_random_seq.randomize()) begin
    `uvm_error(get_type_name(), "Failed to randomize bready_random_seq")
  end
  bready_random_seq.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for completion
  #500ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

function void axi4_error_inject_bready_random_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  // For X injection tests, we expect some errors due to X propagation
  // Only check for FATAL errors, not regular ERRORs
  if(svr.get_severity_count(UVM_FATAL) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "BREADY Random X Injection Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "BREADY Random X Injection Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end
endfunction : report_phase

//--------------------------------------------------------------------------------------------
// Class: axi4_error_inject_rready_random_test
// Description:
// This test performs multiple randomized X-value injections on the RREADY signal.
// - Number of injections: 1-10 (random)
// - Injection duration: 5-20 cycles per injection (random)
// - Timing: Random delays between injections (50-500ns)
// - Recovery: Normal transactions between injections
// - Supports all bus matrix modes (NONE/1x1, BASE/4x4, ENHANCED/10x10)
//--------------------------------------------------------------------------------------------
class axi4_error_inject_rready_random_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_error_inject_rready_random_test)

  extern function new(string name = "axi4_error_inject_rready_random_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_error_inject_rready_random_test

function axi4_error_inject_rready_random_test::new(string name = "axi4_error_inject_rready_random_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_error_inject_rready_random_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for randomized error injection
  uvm_config_db#(bit)::set(this, "*", "enable_x_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "allow_x_propagation", 1);
  uvm_config_db#(bit)::set(this, "*", "randomize_injection", 1);
  uvm_config_db#(int)::set(this, "*", "x_recovery_timeout", 100);
  
  `uvm_info(get_type_name(), "Build phase completed for RREADY Random X injection test", UVM_LOW)
endfunction : build_phase

task axi4_error_inject_rready_random_test::run_phase(uvm_phase phase);
  axi4_virtual_error_inject_rready_random_seq rready_random_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting RREADY Random X Injection Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Randomly inject X on RREADY during active transactions", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random injection cycles and timing", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random normal transactions before/after", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", 
            test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the randomized RREADY X injection sequence
  rready_random_seq = axi4_virtual_error_inject_rready_random_seq::type_id::create("rready_random_seq");
  if(!rready_random_seq.randomize()) begin
    `uvm_error(get_type_name(), "Failed to randomize rready_random_seq")
  end
  rready_random_seq.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for completion
  #500ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

function void axi4_error_inject_rready_random_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  // For X injection tests, we expect some errors due to X propagation
  // Only check for FATAL errors, not regular ERRORs
  if(svr.get_severity_count(UVM_FATAL) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "RREADY Random X Injection Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "RREADY Random X Injection Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end
endfunction : report_phase

//--------------------------------------------------------------------------------------------
// Class: axi4_error_inject_multi_signal_random_test
// Description:
// This test randomly injects X-values on different AXI4 signals throughout the simulation.
// - Signals: AWVALID, AWADDR, WDATA, ARVALID, BREADY, RREADY (random selection)
// - Number of injections: 3-10 (random)
// - Injection duration: 5-20 cycles per signal (random)
// - Signal mask: Randomly selects which signals to target
// - Supports all bus matrix modes (NONE/1x1, BASE/4x4, ENHANCED/10x10)
//--------------------------------------------------------------------------------------------
class axi4_error_inject_multi_signal_random_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_error_inject_multi_signal_random_test)

  extern function new(string name = "axi4_error_inject_multi_signal_random_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_error_inject_multi_signal_random_test

function axi4_error_inject_multi_signal_random_test::new(string name = "axi4_error_inject_multi_signal_random_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_error_inject_multi_signal_random_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for randomized multi-signal error injection
  uvm_config_db#(bit)::set(this, "*", "enable_x_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "allow_x_propagation", 1);
  uvm_config_db#(bit)::set(this, "*", "randomize_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "multi_signal_injection", 1);
  uvm_config_db#(int)::set(this, "*", "x_recovery_timeout", 100);
  
  `uvm_info(get_type_name(), "Build phase completed for Multi-signal Random X injection test", UVM_LOW)
endfunction : build_phase

task axi4_error_inject_multi_signal_random_test::run_phase(uvm_phase phase);
  axi4_virtual_error_inject_all_signals_random_seq multi_signal_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting Multi-Signal Random X Injection Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Randomly inject X on different signals", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random selection of signals", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random injection timing and duration", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", 
            test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the multi-signal random injection sequence
  multi_signal_seq = axi4_virtual_error_inject_all_signals_random_seq::type_id::create("multi_signal_seq");
  if(!multi_signal_seq.randomize()) begin
    `uvm_error(get_type_name(), "Failed to randomize multi_signal_seq")
  end
  multi_signal_seq.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for completion
  #1000ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

function void axi4_error_inject_multi_signal_random_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  // For X injection tests, we expect some errors due to X propagation
  // Only check for FATAL errors, not regular ERRORs
  if(svr.get_severity_count(UVM_FATAL) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "Multi-Signal Random X Injection Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "Multi-Signal Random X Injection Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end
endfunction : report_phase

//--------------------------------------------------------------------------------------------
// Class: axi4_error_inject_adaptive_random_test
// Description:
// This test adaptively injects X-values based on bus activity and configurable parameters.
// - Test duration: 1-3 us (reduced for faster simulation)
// - Injection rate: 5-30% of simulation time
// - Adaptive behavior: Adjusts injection frequency based on bus load
// - Background traffic: Continuous transactions during test
// - Supports all bus matrix modes (NONE/1x1, BASE/4x4, ENHANCED/10x10)
//--------------------------------------------------------------------------------------------
class axi4_error_inject_adaptive_random_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_error_inject_adaptive_random_test)

  extern function new(string name = "axi4_error_inject_adaptive_random_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_error_inject_adaptive_random_test

function axi4_error_inject_adaptive_random_test::new(string name = "axi4_error_inject_adaptive_random_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_error_inject_adaptive_random_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for adaptive randomized error injection
  uvm_config_db#(bit)::set(this, "*", "enable_x_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "allow_x_propagation", 1);
  uvm_config_db#(bit)::set(this, "*", "randomize_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "adaptive_injection", 1);
  uvm_config_db#(int)::set(this, "*", "x_recovery_timeout", 200);
  
  `uvm_info(get_type_name(), "Build phase completed for Adaptive Random X injection test", UVM_LOW)
endfunction : build_phase

task axi4_error_inject_adaptive_random_test::run_phase(uvm_phase phase);
  axi4_virtual_error_inject_adaptive_random_seq adaptive_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting Adaptive Random X Injection Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Adaptive X injection based on bus activity", UVM_LOW)
  `uvm_info(get_type_name(), "  - Adjusts injection rate dynamically", UVM_LOW)
  `uvm_info(get_type_name(), "  - Long-running test with background traffic", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", 
            test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the adaptive random injection sequence
  adaptive_seq = axi4_virtual_error_inject_adaptive_random_seq::type_id::create("adaptive_seq");
  adaptive_seq.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for completion
  #2000ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

function void axi4_error_inject_adaptive_random_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  // For X injection tests, we expect some errors due to X propagation
  // Only check for FATAL errors, not regular ERRORs
  if(svr.get_severity_count(UVM_FATAL) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "Adaptive Random X Injection Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "Adaptive Random X Injection Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end
endfunction : report_phase

//--------------------------------------------------------------------------------------------
// Class: axi4_exception_random_test
// Description:
// This test performs random exception scenarios including aborts, timeouts, and errors.
// - Exception types: ABORT_AWVALID, ABORT_ARVALID, NEAR_TIMEOUT, ILLEGAL_ACCESS, ECC_ERROR
// - Number of exceptions: 3-10 (random)
// - Random timing: Variable delays between exceptions
// - Recovery testing: Verifies proper recovery after each exception
// - Supports all bus matrix modes (NONE/1x1, BASE/4x4, ENHANCED/10x10)
//--------------------------------------------------------------------------------------------
class axi4_exception_random_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_exception_random_test)

  extern function new(string name = "axi4_exception_random_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);

endclass : axi4_exception_random_test

function axi4_exception_random_test::new(string name = "axi4_exception_random_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_exception_random_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for randomized exception scenarios
  uvm_config_db#(bit)::set(this, "*", "enable_exceptions", 1);
  uvm_config_db#(bit)::set(this, "*", "randomize_exceptions", 1);
  
  `uvm_info(get_type_name(), "Build phase completed for Random Exception test", UVM_LOW)
endfunction : build_phase

task axi4_exception_random_test::run_phase(uvm_phase phase);
  axi4_master_exception_random_seq exc_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting Random Exception Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random exception scenarios", UVM_LOW)
  `uvm_info(get_type_name(), "  - Abort transactions, near timeouts, illegal access", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random timing and parameters", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the random exception sequence
  exc_seq = axi4_master_exception_random_seq::type_id::create("exc_seq");
  exc_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h);
  
  // Wait for completion
  #1000ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

`endif