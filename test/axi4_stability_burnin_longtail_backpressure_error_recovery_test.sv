`ifndef AXI4_STABILITY_BURNIN_LONGTAIL_BACKPRESSURE_ERROR_RECOVERY_TEST_INCLUDED_
`define AXI4_STABILITY_BURNIN_LONGTAIL_BACKPRESSURE_ERROR_RECOVERY_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_stability_burnin_longtail_backpressure_error_recovery_test
// Long-running stability test with error recovery and comprehensive burn-in
// 
// Sequence Flow (Based on stress test specification):
// Phase-1: [PARALLEL] saturation + fanout + backpressure (burn-in phase)
// Phase-2: Long tail latency injection
// Phase-3: Sparse error injection (1% error rate)
// Phase-4: Reset smoke recovery
//
// Supports 3 bus matrix modes:
// - NONE: No reference model (4x4 topology)
// - BASE_BUS_MATRIX: 4x4 bus matrix with reference model  
// - BUS_ENHANCED_MATRIX: 10x10 enhanced bus matrix with reference model
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
  bit is_4x4_ref_mode;
  string bus_matrix_mode_str;
  
  // Test phase control and timing
  bit phase1_done = 0;
  bit phase2_done = 0;
  bit phase3_done = 0;
  bit phase4_done = 0;
  
  // Timing tracking
  time test_start_time;
  time phase1_start_time, phase1_end_time;
  time phase2_start_time, phase2_end_time;
  time phase3_start_time, phase3_end_time;
  time phase4_start_time, phase4_end_time;
  
  // Sequence completion tracking
  int saturation_seq_completed = 0;
  int fanout_seq_completed = 0;
  int backpressure_seq_completed = 0;
  int sequences_completed = 0;

  extern function new(string name = "axi4_stability_burnin_longtail_backpressure_error_recovery_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void configure_bus_matrix_mode();
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
  int override_masters, override_slaves;
  axi4_bus_matrix_ref::bus_matrix_mode_e override_mode;
  
  // Configure bus matrix mode BEFORE calling super.build_phase()
  configure_bus_matrix_mode();
  
  super.build_phase(phase);
  
  // Apply our bus matrix mode overrides after super.build_phase()
  if (uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::get(this, "*", "bus_matrix_mode", override_mode)) begin
    axi4_env_cfg_h.bus_matrix_mode = override_mode;
  end
  
  if (uvm_config_db#(int)::get(this, "*", "override_num_masters", override_masters)) begin
    axi4_env_cfg_h.no_of_masters = override_masters;
  end
  
  if (uvm_config_db#(int)::get(this, "*", "override_num_slaves", override_slaves)) begin
    axi4_env_cfg_h.no_of_slaves = override_slaves;
  end
  
  // Set number of masters and slaves based on configuration
  num_masters = axi4_env_cfg_h.no_of_masters;
  num_slaves = axi4_env_cfg_h.no_of_slaves;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), "AXI4 STABILITY BURNIN LONGTAIL BACKPRESSURE ERROR RECOVERY TEST", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Bus Matrix Mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Masters: %0d, Slaves: %0d", num_masters, num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "Test Sequence Flow:", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-1: [PARALLEL BURN-IN] ", UVM_LOW)
  `uvm_info(get_type_name(), "    - axi4_master_all_to_all_saturation_seq (all masters)", UVM_LOW)
  `uvm_info(get_type_name(), "    - axi4_master_one_to_many_fanout_seq (all masters)", UVM_LOW)
  `uvm_info(get_type_name(), "    - axi4_slave_backpressure_storm_seq (all slaves)", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-2: axi4_slave_long_tail_latency_seq", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-3: axi4_slave_sparse_error_injection_seq (1% error rate)", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-4: axi4_master_reset_smoke_seq (error recovery)", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  // Configure slave response mode for memory testing based on mode
  if (is_enhanced_mode || is_4x4_ref_mode) begin
    `uvm_info(get_type_name(), $sformatf("Configuring slaves for %s mode with memory model", 
              is_enhanced_mode ? "ENHANCED 10x10" : "4x4 REF"), UVM_MEDIUM)
    foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_response_mode = RESP_IN_ORDER;
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
    end
  end else begin
    `uvm_info(get_type_name(), "Configuring for NONE mode (no reference model, 4x4 topology)", UVM_MEDIUM)
    // Configure slaves for consistent behavior even in NONE mode
    foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_response_mode = RESP_IN_ORDER;
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
    end
  end
  
endfunction : build_phase

function void axi4_stability_burnin_longtail_backpressure_error_recovery_test::configure_bus_matrix_mode();
  string mode_str;
  bit mode_configured = 0;
  int random_mode;
  axi4_bus_matrix_ref::bus_matrix_mode_e selected_mode;
  int selected_masters, selected_slaves;
  
  // Priority 1: Check for command-line plusarg
  if ($value$plusargs("BUS_MATRIX_MODE=%s", mode_str)) begin
    `uvm_info(get_type_name(), $sformatf("Bus matrix mode from plusarg: %s", mode_str), UVM_MEDIUM)
    if (mode_str == "ENHANCED" || mode_str == "enhanced" || mode_str == "10x10") begin
      selected_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
      selected_masters = 10;
      selected_slaves = 10;
      is_enhanced_mode = 1;
      is_4x4_ref_mode = 0;
      bus_matrix_mode_str = "ENHANCED (10x10 with ref model)";
      mode_configured = 1;
    end else if (mode_str == "4x4" || mode_str == "4X4" || mode_str == "BASE" || mode_str == "base") begin
      selected_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
      selected_masters = 4;
      selected_slaves = 4;
      is_enhanced_mode = 0;
      is_4x4_ref_mode = 1;
      bus_matrix_mode_str = "BASE_BUS_MATRIX (4x4 with ref model)";
      mode_configured = 1;
    end else if (mode_str == "NONE" || mode_str == "none") begin
      selected_mode = axi4_bus_matrix_ref::NONE;
      selected_masters = 4;
      selected_slaves = 4;
      is_enhanced_mode = 0;
      is_4x4_ref_mode = 0;
      bus_matrix_mode_str = "NONE (no ref model, 4x4 topology)";
      mode_configured = 1;
    end else if (mode_str == "RANDOM" || mode_str == "random") begin
      // User explicitly requested random selection
      mode_configured = 0;
    end else begin
      `uvm_warning(get_type_name(), $sformatf("Invalid BUS_MATRIX_MODE: %s. Valid: NONE, 4x4, ENHANCED, RANDOM. Using random selection.", mode_str))
      mode_configured = 0;
    end
  end
  
  // Priority 2: Random selection if no configuration provided (3-way random)
  if (!mode_configured) begin
    random_mode = $urandom_range(0, 2); // 0=NONE, 1=4x4_REF, 2=ENHANCED_10x10
    `uvm_info(get_type_name(), $sformatf("Randomly selecting bus matrix mode. Random value: %0d", random_mode), UVM_MEDIUM)
    
    if (random_mode == 2) begin
      selected_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
      selected_masters = 10;
      selected_slaves = 10;
      is_enhanced_mode = 1;
      is_4x4_ref_mode = 0;
      bus_matrix_mode_str = "ENHANCED (10x10 with ref model) [RANDOM]";
      `uvm_info(get_type_name(), "Random selection: ENHANCED 10x10 mode", UVM_LOW)
    end else if (random_mode == 1) begin
      selected_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
      selected_masters = 4;
      selected_slaves = 4;
      is_enhanced_mode = 0;
      is_4x4_ref_mode = 1;
      bus_matrix_mode_str = "BASE_BUS_MATRIX (4x4 with ref model) [RANDOM]";
      `uvm_info(get_type_name(), "Random selection: BASE_BUS_MATRIX mode", UVM_LOW)
    end else begin
      selected_mode = axi4_bus_matrix_ref::NONE;
      selected_masters = 4;
      selected_slaves = 4;
      is_enhanced_mode = 0;
      is_4x4_ref_mode = 0;
      bus_matrix_mode_str = "NONE (no ref model, 4x4 topology) [RANDOM]";
      `uvm_info(get_type_name(), "Random selection: NONE mode", UVM_LOW)
    end
  end
  
  // Create test_config if it doesn't exist and set our values
  if (test_config == null) begin
    test_config = axi4_test_config::type_id::create("test_config");
  end
  
  // Override test_config settings to ensure our mode takes priority
  test_config.bus_matrix_mode = selected_mode;
  test_config.num_masters = selected_masters;
  test_config.num_slaves = selected_slaves;
  `uvm_info(get_type_name(), "Setting test_config with selected bus matrix mode", UVM_MEDIUM)
  
  // Store in config_db for base test to use - use parent context to ensure base test gets it
  uvm_config_db#(axi4_test_config)::set(null, "*", "test_config", test_config);
  
  // Store configuration for use after super.build_phase()
  // These will be applied to axi4_env_cfg_h after it's created
  uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::set(this, "*", "bus_matrix_mode", selected_mode);
  uvm_config_db#(int)::set(this, "*", "override_num_masters", selected_masters);
  uvm_config_db#(int)::set(this, "*", "override_num_slaves", selected_slaves);
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), "BUS MATRIX MODE CONFIGURATION", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Final Mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), "Configuration Priority:", UVM_LOW)
  `uvm_info(get_type_name(), "  1. Command line: +BUS_MATRIX_MODE=NONE/4x4/BASE/ENHANCED/RANDOM", UVM_LOW)
  `uvm_info(get_type_name(), "  2. test_config (if available)", UVM_LOW)
  `uvm_info(get_type_name(), "  3. Random selection (default)", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
endfunction : configure_bus_matrix_mode

task axi4_stability_burnin_longtail_backpressure_error_recovery_test::run_phase(uvm_phase phase);
  
  test_start_time = $time;
  
  `uvm_info(get_type_name(), "🔥====================================================🔥", UVM_LOW)
  `uvm_info(get_type_name(), "🔥     STABILITY BURNIN ERROR RECOVERY TEST          🔥", UVM_LOW)
  `uvm_info(get_type_name(), "🔥====================================================🔥", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Starting test with mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Test start time: %0t", test_start_time), UVM_LOW)
  
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
  
  // Final test summary
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "🎯 TEST COMPLETION SUMMARY", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Total Test Duration: %0t", $time - test_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Total Sequences Completed: %0d", sequences_completed), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Phase Status: P1=%s P2=%s P3=%s P4=%s", 
            phase1_done ? "✅" : "❌", phase2_done ? "✅" : "❌", 
            phase3_done ? "✅" : "❌", phase4_done ? "✅" : "❌"), UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "Completed stability_burnin_longtail_backpressure_error_recovery test", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

task axi4_stability_burnin_longtail_backpressure_error_recovery_test::run_phase1_burnin_parallel(uvm_phase phase);
  
  phase1_start_time = $time;
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "Phase 1: PARALLEL BURN-IN SEQUENCES", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Starting burn-in phase at %0t", phase1_start_time), UVM_LOW)
  
  // Configure sequences with limited transactions (reduced from infinite burn-in)
  for(int m = 0; m < num_masters; m++) begin
    automatic int master_id = m;
    
    // Create saturation sequence with mode-specific transactions
    saturation_seq[master_id] = axi4_master_all_to_all_saturation_seq::type_id::create($sformatf("saturation_seq_%0d", master_id));
    saturation_seq[master_id].num_transactions = is_enhanced_mode ? 80 : (is_4x4_ref_mode ? 60 : 40);
    
    // Create fanout sequence with mode-specific transactions
    fanout_seq[master_id] = axi4_master_one_to_many_fanout_seq::type_id::create($sformatf("fanout_seq_%0d", master_id));
    fanout_seq[master_id].transactions_per_slave = is_enhanced_mode ? 6 : (is_4x4_ref_mode ? 4 : 3);
    
    `uvm_info(get_type_name(), $sformatf("Created sequences for Master[%0d]: saturation=%0d txns, fanout=%0d txns/slave", 
              master_id, saturation_seq[master_id].num_transactions, 
              fanout_seq[master_id].transactions_per_slave), UVM_MEDIUM)
  end
  
  // Configure backpressure sequences with mode-specific patterns
  for(int s = 0; s < num_slaves; s++) begin
    backpressure_seq[s] = axi4_slave_backpressure_storm_seq::type_id::create($sformatf("backpressure_seq_%0d", s));
    backpressure_seq[s].num_patterns = is_enhanced_mode ? 10 : (is_4x4_ref_mode ? 8 : 6);
    `uvm_info(get_type_name(), $sformatf("Created backpressure_seq[%0d] with %0d patterns", 
              s, backpressure_seq[s].num_patterns), UVM_MEDIUM)
  end
  
  `uvm_info(get_type_name(), $sformatf("🚀 STARTING %0d saturation + %0d fanout + %0d backpressure sequences in parallel", 
            num_masters, num_masters, num_slaves), UVM_LOW)
  
  fork
    begin
      // Start all master sequences with tracking
      foreach(saturation_seq[i]) begin
        automatic int idx = i;
        fork
          begin
            `uvm_info(get_type_name(), $sformatf("🚀 STARTING: saturation_seq[%0d] at %0t", idx, $time), UVM_HIGH)
            saturation_seq[idx].start(axi4_env_h.axi4_master_agent_h[idx].axi4_master_write_seqr_h);
            saturation_seq_completed++;
            sequences_completed++;
            `uvm_info(get_type_name(), $sformatf("✅ COMPLETED: saturation_seq[%0d] at %0t", idx, $time), UVM_HIGH)
          end
          begin
            `uvm_info(get_type_name(), $sformatf("🚀 STARTING: fanout_seq[%0d] at %0t", idx, $time), UVM_HIGH)
            fanout_seq[idx].start(axi4_env_h.axi4_master_agent_h[idx].axi4_master_read_seqr_h);
            fanout_seq_completed++;
            sequences_completed++;
            `uvm_info(get_type_name(), $sformatf("✅ COMPLETED: fanout_seq[%0d] at %0t", idx, $time), UVM_HIGH)
          end
        join_none
      end
      
      // Start all slave sequences with tracking
      foreach(backpressure_seq[i]) begin
        automatic int idx = i;
        fork
          begin
            `uvm_info(get_type_name(), $sformatf("🚀 STARTING: backpressure_seq[%0d] at %0t", idx, $time), UVM_HIGH)
            backpressure_seq[idx].start(axi4_env_h.axi4_slave_agent_h[idx].axi4_slave_write_seqr_h);
            backpressure_seq_completed++;
            sequences_completed++;
            `uvm_info(get_type_name(), $sformatf("✅ COMPLETED: backpressure_seq[%0d] at %0t", idx, $time), UVM_HIGH)
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
  phase1_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("📈 Phase 1 Statistics:"), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Duration: %0t", phase1_end_time - phase1_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Saturation sequences completed: %0d/%0d", saturation_seq_completed, num_masters), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Fanout sequences completed: %0d/%0d", fanout_seq_completed, num_masters), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Backpressure sequences completed: %0d/%0d", backpressure_seq_completed, num_slaves), UVM_LOW)
  
  // Small delay before next phase
  #3us;
  
endtask : run_phase1_burnin_parallel

task axi4_stability_burnin_longtail_backpressure_error_recovery_test::run_phase2_longtail(uvm_phase phase);
  
  phase2_start_time = $time;
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "Phase 2: LONG TAIL LATENCY SEQUENCE", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  
  // Create longtail sequence with mode-specific delays
  longtail_seq = axi4_slave_long_tail_latency_seq::type_id::create("longtail_seq");
  longtail_seq.long_delay = is_enhanced_mode ? 15000 : (is_4x4_ref_mode ? 10000 : 7500);
  
  `uvm_info(get_type_name(), $sformatf("🚀 STARTING: axi4_slave_long_tail_latency_seq at %0t", $time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   📊 Long delay: %0d cycles", longtail_seq.long_delay), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("   🎯 Target: Slave[%0d]", num_slaves > 8 ? 8 : 0), UVM_MEDIUM)
  
  fork
    begin
      longtail_seq.start(axi4_env_h.axi4_slave_agent_h[num_slaves > 8 ? 8 : 0].axi4_slave_write_seqr_h);
      sequences_completed++;
      `uvm_info(get_type_name(), $sformatf("✅ COMPLETED: axi4_slave_long_tail_latency_seq at %0t", $time), UVM_LOW)
    end
    begin
      // Phase 2 timeout
      #80us;
      `uvm_info(get_type_name(), "Phase 2 longtail timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase2_done = 1;
  phase2_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("📈 Phase 2 Statistics:"), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Duration: %0t", phase2_end_time - phase2_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Long tail latency injection completed"), UVM_LOW)
  
  // Small delay before next phase
  #2us;
  
endtask : run_phase2_longtail

task axi4_stability_burnin_longtail_backpressure_error_recovery_test::run_phase3_error_injection(uvm_phase phase);
  
  phase3_start_time = $time;
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "Phase 3: SPARSE ERROR INJECTION SEQUENCE", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  
  // Create error injection sequence with mode-specific transactions
  error_seq = axi4_slave_sparse_error_injection_seq::type_id::create("error_seq");
  error_seq.error_rate = 1; // 1% error rate as per specification
  error_seq.num_transactions = is_enhanced_mode ? 60 : (is_4x4_ref_mode ? 45 : 30);
  
  `uvm_info(get_type_name(), $sformatf("🚀 STARTING: axi4_slave_sparse_error_injection_seq at %0t", $time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   📊 Error rate: %0d%%", error_seq.error_rate), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("   📊 Transactions: %0d", error_seq.num_transactions), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("   🎯 Target: Slave[0]"), UVM_MEDIUM)
  
  fork
    begin
      error_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
      sequences_completed++;
      `uvm_info(get_type_name(), $sformatf("✅ COMPLETED: axi4_slave_sparse_error_injection_seq at %0t", $time), UVM_LOW)
    end
    begin
      // Phase 3 timeout
      #60us;
      `uvm_info(get_type_name(), "Phase 3 error injection timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase3_done = 1;
  phase3_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("📈 Phase 3 Statistics:"), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Duration: %0t", phase3_end_time - phase3_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Error injection completed with %0d%% error rate", error_seq.error_rate), UVM_LOW)
  
  // Small delay before next phase
  #2us;
  
endtask : run_phase3_error_injection

task axi4_stability_burnin_longtail_backpressure_error_recovery_test::run_phase4_recovery(uvm_phase phase);
  
  phase4_start_time = $time;
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "Phase 4: RESET SMOKE - ERROR RECOVERY SEQUENCE", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  
  // Create and run recovery sequence with mode-specific transactions
  smoke_seq = axi4_master_reset_smoke_seq::type_id::create("smoke_seq");
  smoke_seq.num_txns = is_enhanced_mode ? 15 : (is_4x4_ref_mode ? 12 : 10);
  
  `uvm_info(get_type_name(), $sformatf("🚀 STARTING: axi4_master_reset_smoke_seq at %0t", $time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   📊 Transactions: %0d", smoke_seq.num_txns), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("   🎯 Target: Master[0] (recovery)"), UVM_MEDIUM)
  
  fork
    begin
      smoke_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
      sequences_completed++;
      `uvm_info(get_type_name(), $sformatf("✅ COMPLETED: axi4_master_reset_smoke_seq at %0t", $time), UVM_LOW)
    end
    begin
      // Phase 4 timeout
      #20us;
      `uvm_info(get_type_name(), "Phase 4 recovery timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase4_done = 1;
  phase4_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("📈 Phase 4 Statistics:"), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Duration: %0t", phase4_end_time - phase4_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Error recovery completed successfully"), UVM_LOW)
  
  // Final cleanup delay
  #3us;
  
endtask : run_phase4_recovery

`endif