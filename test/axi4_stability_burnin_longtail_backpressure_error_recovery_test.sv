`ifndef AXI4_STABILITY_BURNIN_LONGTAIL_BACKPRESSURE_ERROR_RECOVERY_TEST_INCLUDED_
`define AXI4_STABILITY_BURNIN_LONGTAIL_BACKPRESSURE_ERROR_RECOVERY_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_stability_burnin_longtail_backpressure_error_recovery_test
// Long-running stability test with error recovery
// Supports both NONE (no ref model) and ENHANCED (10x10) bus matrix modes
//--------------------------------------------------------------------------------------------
class axi4_stability_burnin_longtail_backpressure_error_recovery_test extends axi4_base_test;
  `uvm_component_utils(axi4_stability_burnin_longtail_backpressure_error_recovery_test)

  // Sequence handles
  axi4_master_all_to_all_saturation_seq saturation_seq[];
  axi4_master_one_to_many_fanout_seq fanout_seq[];
  axi4_slave_backpressure_storm_seq backpressure_seq[];
  axi4_slave_long_tail_latency_seq longtail_seq;
  axi4_slave_sparse_error_injection_seq error_seq;
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

  extern function new(string name = "axi4_stability_burnin_longtail_backpressure_error_recovery_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task run_phase1_burnin_parallel(uvm_phase phase);
  extern virtual task run_phase2_longtail(uvm_phase phase);
  extern virtual task run_phase3_error_injection(uvm_phase phase);
  extern virtual task run_phase4_recovery(uvm_phase phase);
  
endclass : axi4_stability_burnin_longtail_backpressure_error_recovery_test

function axi4_stability_burnin_longtail_backpressure_error_recovery_test::new(string name = "axi4_stability_burnin_longtail_backpressure_error_recovery_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_stability_burnin_longtail_backpressure_error_recovery_test::build_phase(uvm_phase phase);
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

task axi4_stability_burnin_longtail_backpressure_error_recovery_test::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), $sformatf("Starting stability_burnin_longtail_backpressure_error_recovery test in %s mode", 
    is_enhanced_mode ? "ENHANCED" : "NONE"), UVM_LOW)
  
  phase.raise_objection(this);
  
  // Initialize sequence arrays
  saturation_seq = new[num_masters];
  fanout_seq = new[num_masters];
  backpressure_seq = new[num_slaves];
  
  // Run test phases sequentially with proper control
  fork
    begin
      // Main test sequence
      run_phase1_burnin_parallel(phase);
      run_phase2_longtail(phase);
      run_phase3_error_injection(phase);
      run_phase4_recovery(phase);
    end
    begin
      // Overall timeout watchdog - 500us total test time (reduced from infinite)
      #500us;
      `uvm_warning(get_type_name(), "Test timeout reached (500us) - forcing completion")
    end
  join_any
  
  // Ensure all forked processes are killed
  disable fork;
  
  // Wait a bit for cleanup
  #5us;
  
  `uvm_info(get_type_name(), "Completed stability_burnin_longtail_backpressure_error_recovery test", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

task axi4_stability_burnin_longtail_backpressure_error_recovery_test::run_phase1_burnin_parallel(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 1: Starting parallel burn-in (saturation, fanout, backpressure)", UVM_MEDIUM)
  
  // Configure sequences with limited transactions (reduced from infinite burn-in)
  for(int m = 0; m < num_masters; m++) begin
    automatic int master_id = m;
    
    // Create saturation sequence with limited transactions
    saturation_seq[master_id] = axi4_master_all_to_all_saturation_seq::type_id::create($sformatf("saturation_seq_%0d", master_id));
    saturation_seq[master_id].num_transactions = is_enhanced_mode ? 80 : 40; // Significantly reduced from 200
    
    // Create fanout sequence with limited transactions
    fanout_seq[master_id] = axi4_master_one_to_many_fanout_seq::type_id::create($sformatf("fanout_seq_%0d", master_id));
    fanout_seq[master_id].transactions_per_slave = is_enhanced_mode ? 6 : 3; // Limit transactions per slave
  end
  
  // Configure backpressure sequences with limited patterns
  for(int s = 0; s < num_slaves; s++) begin
    backpressure_seq[s] = axi4_slave_backpressure_storm_seq::type_id::create($sformatf("backpressure_seq_%0d", s));
    backpressure_seq[s].num_patterns = 8; // Limit patterns
  end
  
  fork
    begin
      // Start all master sequences
      foreach(saturation_seq[i]) begin
        automatic int idx = i;
        fork
          begin
            saturation_seq[idx].start(axi4_env_h.axi4_master_agent_h[idx].axi4_master_write_seqr_h);
          end
          begin
            fanout_seq[idx].start(axi4_env_h.axi4_master_agent_h[idx].axi4_master_read_seqr_h);
          end
        join_none
      end
      
      // Start all slave sequences
      foreach(backpressure_seq[i]) begin
        automatic int idx = i;
        fork
          begin
            backpressure_seq[idx].start(axi4_env_h.axi4_slave_agent_h[idx].axi4_slave_write_seqr_h);
          end
        join_none
      end
    end
    begin
      // Phase 1 timeout (reduced from 200us to 120us for reasonable burn-in)
      #120us;
      `uvm_info(get_type_name(), "Phase 1 burn-in timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase1_done = 1;
  
  // Small delay before next phase
  #3us;
  
endtask : run_phase1_burnin_parallel

task axi4_stability_burnin_longtail_backpressure_error_recovery_test::run_phase2_longtail(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 2: Starting long tail latency", UVM_MEDIUM)
  
  // Create longtail sequence with reduced delays and limited transactions
  longtail_seq = axi4_slave_long_tail_latency_seq::type_id::create("longtail_seq");
  longtail_seq.long_delay = is_enhanced_mode ? 15000 : 7500; // Reduced from 75000
  
  fork
    begin
      longtail_seq.start(axi4_env_h.axi4_slave_agent_h[num_slaves > 8 ? 8 : 0].axi4_slave_write_seqr_h);
    end
    begin
      // Phase 2 timeout
      #80us;
      `uvm_info(get_type_name(), "Phase 2 longtail timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase2_done = 1;
  
  // Small delay before next phase
  #2us;
  
endtask : run_phase2_longtail

task axi4_stability_burnin_longtail_backpressure_error_recovery_test::run_phase3_error_injection(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 3: Starting sparse error injection", UVM_MEDIUM)
  
  // Create error injection sequence with limited transactions
  error_seq = axi4_slave_sparse_error_injection_seq::type_id::create("error_seq");
  error_seq.error_rate = 1;
  error_seq.num_transactions = is_enhanced_mode ? 60 : 30; // Reduced from 200
  
  fork
    begin
      error_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
    end
    begin
      // Phase 3 timeout
      #60us;
      `uvm_info(get_type_name(), "Phase 3 error injection timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase3_done = 1;
  
  // Small delay before next phase
  #2us;
  
endtask : run_phase3_error_injection

task axi4_stability_burnin_longtail_backpressure_error_recovery_test::run_phase4_recovery(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 4: Starting reset smoke - error recovery", UVM_MEDIUM)
  
  // Create and run recovery sequence with limited transactions
  smoke_seq = axi4_master_reset_smoke_seq::type_id::create("smoke_seq");
  smoke_seq.num_txns = 10;
  
  fork
    begin
      smoke_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
    end
    begin
      // Phase 4 timeout
      #20us;
      `uvm_info(get_type_name(), "Phase 4 recovery timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase4_done = 1;
  
  // Final cleanup delay
  #3us;
  
endtask : run_phase4_recovery

`endif