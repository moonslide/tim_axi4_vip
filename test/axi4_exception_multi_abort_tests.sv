`ifndef AXI4_EXCEPTION_MULTI_ABORT_TESTS_INCLUDED_
`define AXI4_EXCEPTION_MULTI_ABORT_TESTS_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_exception_multi_abort_test
// Description:
// This test performs multiple abort events with random parameters and timing.
// - Number of aborts: 1-15 events (random)
// - Abort types: AWVALID, WVALID, ARVALID, WLAST, BREADY, RREADY
// - Abort duration: 5-50 cycles per abort (random)
// - Timing: Random delays between aborts (100-2000ns)
// - Context: Can abort during active transfers or idle periods
// - Supports all bus matrix modes (NONE/1x1, BASE/4x4, ENHANCED/10x10)
//--------------------------------------------------------------------------------------------
class axi4_exception_multi_abort_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_exception_multi_abort_test)

  extern function new(string name = "axi4_exception_multi_abort_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_exception_multi_abort_test

function axi4_exception_multi_abort_test::new(string name = "axi4_exception_multi_abort_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_exception_multi_abort_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for multiple abort exceptions
  uvm_config_db#(bit)::set(this, "*", "enable_exceptions", 1);
  uvm_config_db#(bit)::set(this, "*", "multi_abort", 1);
  uvm_config_db#(bit)::set(this, "*", "randomize_abort", 1);
  uvm_config_db#(int)::set(this, "*", "max_abort_duration", 50);
  
  `uvm_info(get_type_name(), "Build phase completed for Multi-Abort Exception test", UVM_LOW)
endfunction : build_phase

task axi4_exception_multi_abort_test::run_phase(uvm_phase phase);
  axi4_virtual_exception_multi_abort_seq multi_abort_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting Multi-Abort Exception Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Multiple abort events (1-15 times)", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random abort durations (5-50 cycles)", UVM_LOW)
  `uvm_info(get_type_name(), "  - Different abort types (AWVALID, ARVALID, etc.)", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random timing between aborts", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", 
            test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the multi-abort sequence
  multi_abort_seq = axi4_virtual_exception_multi_abort_seq::type_id::create("multi_abort_seq");
  multi_abort_seq.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for completion
  #1000ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

function void axi4_exception_multi_abort_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  if(svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "Multi-Abort Exception Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "Multi-Abort Exception Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end
endfunction : report_phase

//--------------------------------------------------------------------------------------------
// Class: axi4_exception_continuous_abort_test
// Description:
// This test continuously generates abort events throughout the simulation.
// - Abort model: Probability-based (5-30% chance at each interval)
// - Test duration: 5-20 us of continuous testing
// - Abort duration: 5-100 cycles per abort (random)
// - Abort types: Random selection from all abort types
// - Background traffic: Continuous normal transactions
// - Supports all bus matrix modes (NONE/1x1, BASE/4x4, ENHANCED/10x10)
//--------------------------------------------------------------------------------------------
class axi4_exception_continuous_abort_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_exception_continuous_abort_test)

  extern function new(string name = "axi4_exception_continuous_abort_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);

endclass : axi4_exception_continuous_abort_test

function axi4_exception_continuous_abort_test::new(string name = "axi4_exception_continuous_abort_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_exception_continuous_abort_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for continuous abort exceptions
  uvm_config_db#(bit)::set(this, "*", "enable_exceptions", 1);
  uvm_config_db#(bit)::set(this, "*", "continuous_abort", 1);
  uvm_config_db#(int)::set(this, "*", "abort_probability", 15);  // 15% chance
  
  `uvm_info(get_type_name(), "Build phase completed for Continuous Abort test", UVM_LOW)
endfunction : build_phase

task axi4_exception_continuous_abort_test::run_phase(uvm_phase phase);
  axi4_master_exception_continuous_abort_seq continuous_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting Continuous Abort Exception Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Continuous random aborts throughout test", UVM_LOW)
  `uvm_info(get_type_name(), "  - Probability-based abort injection", UVM_LOW)
  `uvm_info(get_type_name(), "  - Variable abort durations", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the continuous abort sequence
  continuous_seq = axi4_master_exception_continuous_abort_seq::type_id::create("continuous_seq");
  if (!continuous_seq.randomize()) begin
    `uvm_error(get_type_name(), "Failed to randomize continuous_seq")
  end
  continuous_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h);
  
  // Wait for completion
  #100ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

//--------------------------------------------------------------------------------------------
// Class: axi4_exception_random_timeout_test
// Description:
// This test generates multiple near-timeout scenarios to stress timeout recovery.
// - Number of timeouts: 1-10 events (random)
// - Stall cycles: 500-1023 (approaching 1024 timeout threshold)
// - Channel selection: Random between read and write channels
// - Timing: Random delays between timeout events (100-500ns)
// - Recovery testing: Verifies proper recovery after near-timeout
// - Supports all bus matrix modes (NONE/1x1, BASE/4x4, ENHANCED/10x10)
//--------------------------------------------------------------------------------------------
class axi4_exception_random_timeout_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_exception_random_timeout_test)

  extern function new(string name = "axi4_exception_random_timeout_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);

endclass : axi4_exception_random_timeout_test

function axi4_exception_random_timeout_test::new(string name = "axi4_exception_random_timeout_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_exception_random_timeout_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for random timeout scenarios
  uvm_config_db#(bit)::set(this, "*", "enable_exceptions", 1);
  uvm_config_db#(bit)::set(this, "*", "randomize_timeout", 1);
  uvm_config_db#(int)::set(this, "*", "timeout_threshold", 1024);
  
  `uvm_info(get_type_name(), "Build phase completed for Random Timeout test", UVM_LOW)
endfunction : build_phase

task axi4_exception_random_timeout_test::run_phase(uvm_phase phase);
  axi4_virtual_exception_random_timeout_seq timeout_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting Random Timeout Exception Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Multiple near-timeout events (1-10)", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random stall cycles (500-1023)", UVM_LOW)
  `uvm_info(get_type_name(), "  - Tests timeout recovery mechanisms", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the timeout sequence
  timeout_seq = axi4_virtual_exception_random_timeout_seq::type_id::create("timeout_seq");
  timeout_seq.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for completion
  #500ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

//--------------------------------------------------------------------------------------------
// Class: axi4_exception_mixed_random_test
// Test with mixed random exception types
//--------------------------------------------------------------------------------------------
class axi4_exception_mixed_random_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_exception_mixed_random_test)

  extern function new(string name = "axi4_exception_mixed_random_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);

endclass : axi4_exception_mixed_random_test

function axi4_exception_mixed_random_test::new(string name = "axi4_exception_mixed_random_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_exception_mixed_random_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for mixed exception types
  uvm_config_db#(bit)::set(this, "*", "enable_exceptions", 1);
  uvm_config_db#(bit)::set(this, "*", "mixed_exceptions", 1);
  
  `uvm_info(get_type_name(), "Build phase completed for Mixed Random Exception test", UVM_LOW)
endfunction : build_phase

task axi4_exception_mixed_random_test::run_phase(uvm_phase phase);
  axi4_virtual_exception_mixed_random_seq mixed_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting Mixed Random Exception Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Mix of different exception types", UVM_LOW)
  `uvm_info(get_type_name(), "  - Aborts, timeouts, illegal access, ECC errors", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random sequencing and timing", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the mixed exception sequence
  mixed_seq = axi4_virtual_exception_mixed_random_seq::type_id::create("mixed_seq");
  mixed_seq.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for completion
  #1000ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

`endif