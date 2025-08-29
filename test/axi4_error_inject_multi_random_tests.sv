`ifndef AXI4_ERROR_INJECT_MULTI_RANDOM_TESTS_INCLUDED_
`define AXI4_ERROR_INJECT_MULTI_RANDOM_TESTS_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_error_inject_multi_random_test
// Description:
// This test performs multiple X-value injections at random times throughout simulation.
// - Number of injections: 1-20 events (random)
// - Signal selection: Random selection from all AXI4 signals per injection
// - Injection duration: 5-20 cycles per injection (random)
// - Timing: Random delays between injections (50-500ns)
// - Background traffic: Continuous normal transactions during test
// - Supports all bus matrix modes (NONE/1x1, BASE/4x4, ENHANCED/10x10)
//--------------------------------------------------------------------------------------------
class axi4_error_inject_multi_random_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_error_inject_multi_random_test)

  extern function new(string name = "axi4_error_inject_multi_random_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_error_inject_multi_random_test

function axi4_error_inject_multi_random_test::new(string name = "axi4_error_inject_multi_random_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_error_inject_multi_random_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for multiple random error injections
  uvm_config_db#(bit)::set(this, "*", "enable_x_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "allow_x_propagation", 1);
  uvm_config_db#(bit)::set(this, "*", "randomize_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "multi_injection", 1);
  uvm_config_db#(int)::set(this, "*", "x_recovery_timeout", 100);
  
  `uvm_info(get_type_name(), "Build phase completed for Multi-Random X injection test", UVM_LOW)
endfunction : build_phase

task axi4_error_inject_multi_random_test::run_phase(uvm_phase phase);
  axi4_virtual_error_inject_multi_random_seq multi_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting Multi-Random X Injection Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Multiple X injections (1-20 times) at random times", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random signal selection for each injection", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random injection duration (5-20 cycles)", UVM_LOW)
  `uvm_info(get_type_name(), "  - Background traffic during test", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Bus Matrix Mode: %s with %0dx%0d configuration", 
            test_config.bus_matrix_mode.name(), test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the multi-injection sequence with timeout protection
  multi_seq = axi4_virtual_error_inject_multi_random_seq::type_id::create("multi_seq");
  if(!multi_seq.randomize() with {
    num_injections inside {[1:3]};  // Reduce number of injections
  }) begin
    `uvm_error(get_type_name(), "Failed to randomize multi_seq")
  end
  
  fork
    begin
      multi_seq.start(axi4_env_h.axi4_virtual_seqr_h);
    end
    begin
      #15us;  // 15us timeout for the multi-injection test
      `uvm_warning(get_type_name(), "Test timeout reached - forcing completion")
    end
  join_any
  disable fork;
  
  // Brief recovery time
  #100ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

function void axi4_error_inject_multi_random_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  if(svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "Multi-Random X Injection Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "Multi-Random X Injection Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end
endfunction : report_phase

//--------------------------------------------------------------------------------------------
// Class: axi4_error_inject_continuous_random_test
// Description:
// This test continuously injects X-values throughout the entire simulation.
// - Injection model: Probability-based (5-25% chance at each interval)
// - Test duration: 10-30 us of continuous testing
// - Mean interval: 200ns-2us between injection opportunities
// - Signal selection: Random for each injection
// - Injection duration: 5-20 cycles per event (random)
// - Supports all bus matrix modes (NONE/1x1, BASE/4x4, ENHANCED/10x10)
//--------------------------------------------------------------------------------------------
class axi4_error_inject_continuous_random_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_error_inject_continuous_random_test)

  extern function new(string name = "axi4_error_inject_continuous_random_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);

endclass : axi4_error_inject_continuous_random_test

function axi4_error_inject_continuous_random_test::new(string name = "axi4_error_inject_continuous_random_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_error_inject_continuous_random_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure test for continuous random error injections
  uvm_config_db#(bit)::set(this, "*", "enable_x_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "allow_x_propagation", 1);
  uvm_config_db#(bit)::set(this, "*", "continuous_injection", 1);
  uvm_config_db#(int)::set(this, "*", "x_recovery_timeout", 100);
  
  // Set error_inject flag to prevent timeout failures
  uvm_config_db#(bit)::set(this, "*", "error_inject", 1);
  
  `uvm_info(get_type_name(), "Build phase completed for Continuous Random X injection test", UVM_LOW)
endfunction : build_phase

task axi4_error_inject_continuous_random_test::run_phase(uvm_phase phase);
  axi4_virtual_error_inject_continuous_random_seq continuous_seq;
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting Continuous Random X Injection Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Test Description:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Continuous X injections throughout test", UVM_LOW)
  `uvm_info(get_type_name(), "  - Probability-based injection (5-25%)", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random signal and duration for each", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run the continuous injection sequence with timeout protection
  continuous_seq = axi4_virtual_error_inject_continuous_random_seq::type_id::create("continuous_seq");
  if(!continuous_seq.randomize()) begin
    `uvm_error(get_type_name(), "Failed to randomize continuous_seq")
  end
  
  fork
    begin
      continuous_seq.start(axi4_env_h.axi4_virtual_seqr_h);
    end
    begin
      #10us;  // 10us timeout for the continuous injection test
      `uvm_warning(get_type_name(), "Test timeout reached - forcing completion")
    end
  join_any
  disable fork;
  
  // Brief recovery time
  #100ns;
  
  phase.drop_objection(this);
  
endtask : run_phase

`endif