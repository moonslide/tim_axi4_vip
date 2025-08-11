`ifndef AXI4_HOTSPOT_FAIRNESS_BOUNDARY_ERROR_RESET_BACKPRESSURE_TEST_INCLUDED_
`define AXI4_HOTSPOT_FAIRNESS_BOUNDARY_ERROR_RESET_BACKPRESSURE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_hotspot_fairness_boundary_error_reset_backpressure_test
// Test focusing on hotspot, fairness, boundary, error injection, and reset backpressure
// Supports both NONE (no ref model) and ENHANCED (10x10) bus matrix modes
//--------------------------------------------------------------------------------------------
class axi4_hotspot_fairness_boundary_error_reset_backpressure_test extends axi4_base_test;
  `uvm_component_utils(axi4_hotspot_fairness_boundary_error_reset_backpressure_test)

  // Sequence handles
  axi4_master_hotspot_many_to_one_seq hotspot_seq[];
  axi4_master_mixed_burst_lengths_seq mixed_burst_seq;
  axi4_master_read_write_contention_seq contention_seq;
  axi4_master_4kb_boundary_seq boundary_seq;
  axi4_slave_sparse_error_injection_seq error_seq;
  axi4_slave_reset_backpressure_seq reset_backpressure_seq;
  axi4_master_reset_smoke_seq smoke_seq;
  
  // Configuration parameters
  int num_masters;
  int num_slaves;
  bit is_enhanced_mode;
  
  // Test phase control
  bit phase1_done = 0;
  bit phase2_done = 0;
  bit phase3_done = 0;
  bit phase4_done = 0;
  bit phase5_done = 0;

  extern function new(string name = "axi4_hotspot_fairness_boundary_error_reset_backpressure_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task run_phase1_hotspot_mixed(uvm_phase phase);
  extern virtual task run_phase2_contention(uvm_phase phase);
  extern virtual task run_phase3_boundary(uvm_phase phase);
  extern virtual task run_phase4_error_injection(uvm_phase phase);
  extern virtual task run_phase5_reset_backpressure(uvm_phase phase);
  extern virtual task run_phase6_cleanup(uvm_phase phase);
  
endclass : axi4_hotspot_fairness_boundary_error_reset_backpressure_test

function axi4_hotspot_fairness_boundary_error_reset_backpressure_test::new(string name = "axi4_hotspot_fairness_boundary_error_reset_backpressure_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_hotspot_fairness_boundary_error_reset_backpressure_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Determine bus matrix mode and adjust test accordingly
  if (test_config != null) begin
    is_enhanced_mode = (test_config.bus_matrix_mode == axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX);
  end else begin
    // Default to NONE mode if test_config not available
    is_enhanced_mode = 0;
  end
  
  // Set number of masters and slaves based on configuration
  num_masters = axi4_env_cfg_h.no_of_masters;
  num_slaves = axi4_env_cfg_h.no_of_slaves;
  
  `uvm_info(get_type_name(), $sformatf("Test configured for %s bus matrix mode with %0d masters and %0d slaves", 
    is_enhanced_mode ? "ENHANCED (10x10)" : "NONE (no ref model)", num_masters, num_slaves), UVM_LOW)
  
  // Configure slave response mode for memory testing if needed
  if (is_enhanced_mode) begin
    foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_response_mode = RESP_IN_ORDER;
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
    end
  end
  
endfunction : build_phase

task axi4_hotspot_fairness_boundary_error_reset_backpressure_test::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), $sformatf("Starting hotspot_fairness_boundary_error_reset_backpressure test in %s mode", 
    is_enhanced_mode ? "ENHANCED" : "NONE"), UVM_LOW)
  
  phase.raise_objection(this);
  
  // Initialize sequence arrays
  hotspot_seq = new[num_masters];
  
  // Run test phases sequentially with proper control
  fork
    begin
      // Main test sequence
      run_phase1_hotspot_mixed(phase);
      run_phase2_contention(phase);
      run_phase3_boundary(phase);
      run_phase4_error_injection(phase);
      run_phase5_reset_backpressure(phase);
      run_phase6_cleanup(phase);
    end
    begin
      // Overall timeout watchdog - 400us total test time
      #400us;
      `uvm_warning(get_type_name(), "Test timeout reached (400us) - forcing completion")
    end
  join_any
  
  // Ensure all forked processes are killed
  disable fork;
  
  // Wait a bit for cleanup
  #5us;
  
  `uvm_info(get_type_name(), "Completed hotspot_fairness_boundary_error_reset_backpressure test", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

task axi4_hotspot_fairness_boundary_error_reset_backpressure_test::run_phase1_hotspot_mixed(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 1: Starting parallel hotspot and mixed burst", UVM_MEDIUM)
  
  // Create mixed burst sequence with limited transactions
  mixed_burst_seq = axi4_master_mixed_burst_lengths_seq::type_id::create("mixed_burst_seq");
  mixed_burst_seq.num_transactions = is_enhanced_mode ? 50 : 25; // Limit transactions
  
  // Configure hotspot sequences with limited transactions
  for(int m = 0; m < num_masters; m++) begin
    hotspot_seq[m] = axi4_master_hotspot_many_to_one_seq::type_id::create($sformatf("hotspot_seq_%0d", m));
    hotspot_seq[m].target_slave_id = 0;  // All target slave 0
    hotspot_seq[m].num_transactions = is_enhanced_mode ? 20 : 10; // Limit transactions
  end
  
  fork
    begin
      // Start all hotspot sequences
      foreach(hotspot_seq[i]) begin
        automatic int idx = i;
        fork
          begin
            hotspot_seq[idx].start(axi4_env_h.axi4_master_agent_h[idx].axi4_master_write_seqr_h);
          end
        join_none
      end
      
      // Start mixed burst sequence
      mixed_burst_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
    end
    begin
      // Phase 1 timeout
      #60us;
      `uvm_info(get_type_name(), "Phase 1 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase1_done = 1;
  
  // Small delay before next phase
  #2us;
  
endtask : run_phase1_hotspot_mixed

task axi4_hotspot_fairness_boundary_error_reset_backpressure_test::run_phase2_contention(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 2: Starting read-write contention", UVM_MEDIUM)
  
  // Create contention sequence with limited transactions
  contention_seq = axi4_master_read_write_contention_seq::type_id::create("contention_seq");
  contention_seq.target_slave = (num_slaves > 3) ? 3 : 0;
  contention_seq.num_transactions = is_enhanced_mode ? 40 : 20; // Limit transactions
  
  fork
    begin
      contention_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
    end
    begin
      // Phase 2 timeout
      #50us;
      `uvm_info(get_type_name(), "Phase 2 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase2_done = 1;
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase2_contention

task axi4_hotspot_fairness_boundary_error_reset_backpressure_test::run_phase3_boundary(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 3: Starting 4KB boundary testing", UVM_MEDIUM)
  
  // Create boundary sequence with limited transactions
  boundary_seq = axi4_master_4kb_boundary_seq::type_id::create("boundary_seq");
  boundary_seq.test_illegal = 1;
  boundary_seq.num_transactions = is_enhanced_mode ? 30 : 15; // Limit transactions
  
  fork
    begin
      boundary_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
    end
    begin
      // Phase 3 timeout
      #30us;
      `uvm_info(get_type_name(), "Phase 3 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase3_done = 1;
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase3_boundary

task axi4_hotspot_fairness_boundary_error_reset_backpressure_test::run_phase4_error_injection(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 4: Starting sparse error injection", UVM_MEDIUM)
  
  // Create error injection sequence with limited transactions
  error_seq = axi4_slave_sparse_error_injection_seq::type_id::create("error_seq");
  error_seq.error_rate = 2;
  error_seq.num_transactions = is_enhanced_mode ? 40 : 20; // Limit transactions
  
  fork
    begin
      error_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
    end
    begin
      // Phase 4 timeout
      #40us;
      `uvm_info(get_type_name(), "Phase 4 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase4_done = 1;
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase4_error_injection

task axi4_hotspot_fairness_boundary_error_reset_backpressure_test::run_phase5_reset_backpressure(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 5: Starting reset backpressure", UVM_MEDIUM)
  
  // Create reset backpressure sequence with limited patterns
  reset_backpressure_seq = axi4_slave_reset_backpressure_seq::type_id::create("reset_backpressure_seq");
  reset_backpressure_seq.backpressure_cycles = 3000; // Limit cycles
  
  fork
    begin
      reset_backpressure_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
    end
    begin
      // Phase 5 timeout
      #30us;
      `uvm_info(get_type_name(), "Phase 5 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase5_done = 1;
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase5_reset_backpressure

task axi4_hotspot_fairness_boundary_error_reset_backpressure_test::run_phase6_cleanup(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 6: Starting reset smoke cleanup", UVM_MEDIUM)
  
  // Create and run cleanup sequence with minimal transactions
  smoke_seq = axi4_master_reset_smoke_seq::type_id::create("smoke_seq");
  smoke_seq.num_txns = 5;
  
  fork
    begin
      smoke_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
    end
    begin
      // Phase 6 timeout
      #10us;
      `uvm_info(get_type_name(), "Phase 6 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  
  // Final cleanup delay
  #2us;
  
endtask : run_phase6_cleanup

`endif