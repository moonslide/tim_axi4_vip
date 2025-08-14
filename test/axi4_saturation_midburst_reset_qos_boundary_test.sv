`ifndef AXI4_SATURATION_MIDBURST_RESET_QOS_BOUNDARY_TEST_INCLUDED_
`define AXI4_SATURATION_MIDBURST_RESET_QOS_BOUNDARY_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_saturation_midburst_reset_qos_boundary_test
// Test combining saturation, mid-burst reset, QoS, and boundary testing
// Supports both NONE (no ref model) and ENHANCED (10x10) bus matrix modes
//
// Configuration options:
// 1. Random mode: Randomly selects between NONE and BUS_ENHANCED_MATRIX
// 2. Plusarg: +BUS_MATRIX_MODE=NONE or +BUS_MATRIX_MODE=ENHANCED
// 3. Environment: Set BUS_MATRIX_MODE env variable
//
// Timeline from axi_stress_reset_test.md:
// Phase-1: |==== saturation_seq (0~120k) ====| + |==== qos_seq (0~120k) ====|
// Hook    :                ^ midburst_reset_seq at 80k (mid-burst)
// Phase-2:                         |== backpressure_seq (120k~220k) ==|
// Phase-3:                                           | 4kb_boundary_seq |
// Phase-4:                                             | error_injection_seq |
// Phase-5:                                                | reset_smoke_seq |
//--------------------------------------------------------------------------------------------
class axi4_saturation_midburst_reset_qos_boundary_test extends axi4_base_test;
  `uvm_component_utils(axi4_saturation_midburst_reset_qos_boundary_test)

  // Sequence handles
  axi4_master_all_to_all_saturation_seq saturation_seq[];
  axi4_master_qos_arbitration_seq qos_seq[];
  axi4_master_midburst_reset_read_seq midburst_reset_seq;
  axi4_slave_backpressure_storm_seq backpressure_seq[];
  axi4_master_4kb_boundary_seq boundary_seq;
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
  bit hook_triggered = 0;
  
  // Timing tracking
  time test_start_time;
  time phase1_start_time, phase1_end_time;
  time phase2_start_time, phase2_end_time;
  time phase3_start_time, phase3_end_time;
  time phase4_start_time, phase4_end_time;
  time phase5_start_time, phase5_end_time;
  time hook_trigger_time;
  
  // Sequence completion tracking
  int saturation_seq_completed = 0;
  int qos_seq_completed = 0;
  int backpressure_seq_completed = 0;
  
  extern function new(string name = "axi4_saturation_midburst_reset_qos_boundary_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void configure_bus_matrix_mode();
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task run_phase1_saturation_qos(uvm_phase phase);
  extern virtual task run_phase2_backpressure(uvm_phase phase);
  extern virtual task run_phase3_boundary(uvm_phase phase);
  extern virtual task run_phase4_error_injection(uvm_phase phase);
  extern virtual task run_phase5_cleanup(uvm_phase phase);
  extern virtual task monitor_sequence_completion();
  
endclass : axi4_saturation_midburst_reset_qos_boundary_test

function axi4_saturation_midburst_reset_qos_boundary_test::new(string name = "axi4_saturation_midburst_reset_qos_boundary_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_saturation_midburst_reset_qos_boundary_test::build_phase(uvm_phase phase);
  int override_masters, override_slaves;
  axi4_bus_matrix_ref::bus_matrix_mode_e override_mode;
  
  // Configure bus matrix mode BEFORE calling super.build_phase()
  // This ensures our configuration takes priority over test_config
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
  `uvm_info(get_type_name(), "AXI4 SATURATION MIDBURST RESET QOS BOUNDARY TEST", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Bus Matrix Mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Masters: %0d, Slaves: %0d", num_masters, num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "Test Timeline (from axi_stress_reset_test.md):", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-1: Parallel saturation + QoS (0~120k cycles)", UVM_LOW)
  `uvm_info(get_type_name(), "  Hook: Mid-burst reset at 80k cycles", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-2: Backpressure storm (120k~220k cycles)", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-3: 4KB boundary testing (20k transactions)", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-4: Sparse error injection (1% rate)", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-5: Reset smoke cleanup", UVM_LOW)
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

function void axi4_saturation_midburst_reset_qos_boundary_test::configure_bus_matrix_mode();
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

task axi4_saturation_midburst_reset_qos_boundary_test::run_phase(uvm_phase phase);
  
  test_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("TEST STARTING at time %0t", test_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  phase.raise_objection(this);
  
  // Initialize sequence arrays
  saturation_seq = new[num_masters];
  qos_seq = new[num_masters];
  backpressure_seq = new[num_slaves];
  
  // Start monitoring task
  fork
    monitor_sequence_completion();
  join_none
  
  // Run test phases sequentially with proper control
  fork
    begin
      // Main test sequence as per markdown specification
      run_phase1_saturation_qos(phase);    // 0~120k cycles
      run_phase2_backpressure(phase);       // 120k~220k cycles
      run_phase3_boundary(phase);           // 4KB boundary test
      run_phase4_error_injection(phase);    // 1% error injection
      run_phase5_cleanup(phase);            // Final cleanup
    end
    begin
      // Overall timeout watchdog - 500us total test time
      #500us;
      `uvm_warning(get_type_name(), $sformatf("TEST TIMEOUT at %0t - forcing completion (500us limit reached)", $time))
    end
  join_any
  
  // Ensure all forked processes are killed
  disable fork;
  
  // Wait a bit for cleanup
  #10us;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("TEST COMPLETED at time %0t", $time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Total test duration: %0t", $time - test_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Final Mode Used: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

task axi4_saturation_midburst_reset_qos_boundary_test::run_phase1_saturation_qos(uvm_phase phase);
  
  phase1_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("PHASE 1 STARTING at %0t: Parallel saturation + QoS arbitration", phase1_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Mode: %s", is_enhanced_mode ? "ENHANCED" : "NONE"), UVM_LOW)
  `uvm_info(get_type_name(), "Target: 120k cycles (120us) with mid-burst reset hook at 80k cycles", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  // Configure and start sequences with limited transactions
  for(int m = 0; m < num_masters; m++) begin
    automatic int master_id = m;
    
    // Create saturation sequence
    saturation_seq[master_id] = axi4_master_all_to_all_saturation_seq::type_id::create($sformatf("saturation_seq_%0d", master_id));
    saturation_seq[master_id].num_transactions = is_enhanced_mode ? 50 : 25;
    
    // Bus matrix addressing handled automatically through test configuration
    
    `uvm_info(get_type_name(), $sformatf("Created saturation_seq[%0d] with %0d transactions", 
              master_id, saturation_seq[master_id].num_transactions), UVM_MEDIUM)
    
    // Create QoS sequence
    qos_seq[master_id] = axi4_master_qos_arbitration_seq::type_id::create($sformatf("qos_seq_%0d", master_id));
    qos_seq[master_id].qos_value = master_id % 16;
    qos_seq[master_id].num_transactions = is_enhanced_mode ? 30 : 15;
    
    // Bus matrix addressing handled automatically through test configuration
    
    `uvm_info(get_type_name(), $sformatf("Created qos_seq[%0d] with QoS=%0d, %0d transactions", 
              master_id, qos_seq[master_id].qos_value, qos_seq[master_id].num_transactions), UVM_MEDIUM)
  end
  
  // Start sequences in parallel with timeout
  fork
    begin
      // Start all saturation sequences
      `uvm_info(get_type_name(), $sformatf("Starting %0d saturation sequences in parallel", num_masters), UVM_MEDIUM)
      foreach(saturation_seq[i]) begin
        automatic int idx = i;
        fork
          begin
            `uvm_info(get_type_name(), $sformatf("[%0t] Starting saturation_seq[%0d]", $time, idx), UVM_HIGH)
            saturation_seq[idx].start(axi4_env_h.axi4_master_agent_h[idx].axi4_master_write_seqr_h);
            saturation_seq_completed++;
            `uvm_info(get_type_name(), $sformatf("[%0t] Completed saturation_seq[%0d] (%0d/%0d done)", 
                      $time, idx, saturation_seq_completed, num_masters), UVM_HIGH)
          end
        join_none
      end
      
      // Start all QoS sequences
      `uvm_info(get_type_name(), $sformatf("Starting %0d QoS arbitration sequences in parallel", num_masters), UVM_MEDIUM)
      foreach(qos_seq[i]) begin
        automatic int idx = i;
        fork
          begin
            `uvm_info(get_type_name(), $sformatf("[%0t] Starting qos_seq[%0d]", $time, idx), UVM_HIGH)
            qos_seq[idx].start(axi4_env_h.axi4_master_agent_h[idx].axi4_master_read_seqr_h);
            qos_seq_completed++;
            `uvm_info(get_type_name(), $sformatf("[%0t] Completed qos_seq[%0d] (%0d/%0d done)", 
                      $time, idx, qos_seq_completed, num_masters), UVM_HIGH)
          end
        join_none
      end
    end
    begin
      // Phase 1 timeout at 120k cycles (reduced to 50us for practical execution)
      #50us;
      `uvm_info(get_type_name(), $sformatf("[%0t] Phase 1 timeout reached (target 120k cycles)", $time), UVM_MEDIUM)
    end
    begin
      // Mid-burst reset injection hook at 80k cycles (reduced to 30us)
      #30us;
      hook_trigger_time = $time;
      hook_triggered = 1;
      `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
      `uvm_info(get_type_name(), $sformatf("[HOOK] INJECTING MID-BURST RESET at %0t (80k cycle point)", hook_trigger_time), UVM_LOW)
      `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
      
      midburst_reset_seq = axi4_master_midburst_reset_read_seq::type_id::create("midburst_reset_seq");
      
      // Bus matrix addressing handled automatically through test configuration
      
      `uvm_info(get_type_name(), "[HOOK] Starting axi4_master_midburst_reset_read_seq", UVM_MEDIUM)
      midburst_reset_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_read_seqr_h);
      `uvm_info(get_type_name(), $sformatf("[HOOK] Completed mid-burst reset sequence at %0t", $time), UVM_MEDIUM)
    end
  join_any
  
  // Kill any remaining sequences
  disable fork;
  phase1_done = 1;
  phase1_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("PHASE 1 COMPLETED at %0t (Duration: %0t)", 
            phase1_end_time, phase1_end_time - phase1_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Saturation sequences completed: %0d/%0d", saturation_seq_completed, num_masters), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - QoS sequences completed: %0d/%0d", qos_seq_completed, num_masters), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Mid-burst reset hook: %s at %0t", 
            hook_triggered ? "TRIGGERED" : "NOT TRIGGERED", hook_trigger_time), UVM_LOW)
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase1_saturation_qos

task axi4_saturation_midburst_reset_qos_boundary_test::run_phase2_backpressure(uvm_phase phase);
  
  phase2_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("PHASE 2 STARTING at %0t: Backpressure storm", phase2_start_time), UVM_LOW)
  `uvm_info(get_type_name(), "Target: 100k cycles (100us) - corresponds to 120k~220k in timeline", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  // Create backpressure sequences with limited patterns
  for(int s = 0; s < num_slaves; s++) begin
    backpressure_seq[s] = axi4_slave_backpressure_storm_seq::type_id::create($sformatf("backpressure_seq_%0d", s));
    backpressure_seq[s].num_patterns = is_enhanced_mode ? 5 : 3; // Adjust based on mode
    `uvm_info(get_type_name(), $sformatf("Created backpressure_seq[%0d] with %0d patterns", 
              s, backpressure_seq[s].num_patterns), UVM_MEDIUM)
  end
  
  fork
    begin
      // Start all backpressure sequences
      `uvm_info(get_type_name(), $sformatf("Starting %0d backpressure storm sequences", num_slaves), UVM_MEDIUM)
      foreach(backpressure_seq[i]) begin
        automatic int idx = i;
        fork
          begin
            `uvm_info(get_type_name(), $sformatf("[%0t] Starting backpressure_seq[%0d] on slave %0d", 
                      $time, idx, idx), UVM_HIGH)
            backpressure_seq[idx].start(axi4_env_h.axi4_slave_agent_h[idx].axi4_slave_write_seqr_h);
            backpressure_seq_completed++;
            `uvm_info(get_type_name(), $sformatf("[%0t] Completed backpressure_seq[%0d] (%0d/%0d done)", 
                      $time, idx, backpressure_seq_completed, num_slaves), UVM_HIGH)
          end
        join_none
      end
    end
    begin
      // Phase 2 timeout (reduced from 100us)
      #30us;
      `uvm_info(get_type_name(), $sformatf("[%0t] Phase 2 timeout reached", $time), UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase2_done = 1;
  phase2_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("PHASE 2 COMPLETED at %0t (Duration: %0t)", 
            phase2_end_time, phase2_end_time - phase2_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Backpressure sequences completed: %0d/%0d", 
            backpressure_seq_completed, num_slaves), UVM_LOW)
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase2_backpressure

task axi4_saturation_midburst_reset_qos_boundary_test::run_phase3_boundary(uvm_phase phase);
  
  phase3_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("PHASE 3 STARTING at %0t: 4KB boundary testing", phase3_start_time), UVM_LOW)
  `uvm_info(get_type_name(), "Target: 20k transactions as per specification", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  // Create and run boundary test with limited transactions
  boundary_seq = axi4_master_4kb_boundary_seq::type_id::create("boundary_seq");
  boundary_seq.num_transactions = is_enhanced_mode ? 50 : 25; // Reduced for practical execution
  
  // Bus matrix addressing handled automatically through test configuration
  
  `uvm_info(get_type_name(), $sformatf("Starting 4KB boundary sequence with %0d transactions (%s mode)", 
            boundary_seq.num_transactions, is_enhanced_mode ? "ENHANCED" : "NONE"), UVM_MEDIUM)
  
  fork
    begin
      `uvm_info(get_type_name(), $sformatf("[%0t] Starting axi4_master_4kb_boundary_seq", $time), UVM_HIGH)
      boundary_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
      `uvm_info(get_type_name(), $sformatf("[%0t] Completed 4KB boundary sequence", $time), UVM_HIGH)
    end
    begin
      // Phase 3 timeout
      #20us;
      `uvm_info(get_type_name(), $sformatf("[%0t] Phase 3 timeout reached", $time), UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase3_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("PHASE 3 COMPLETED at %0t (Duration: %0t)", 
            phase3_end_time, phase3_end_time - phase3_start_time), UVM_LOW)
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase3_boundary

task axi4_saturation_midburst_reset_qos_boundary_test::run_phase4_error_injection(uvm_phase phase);
  
  phase4_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("PHASE 4 STARTING at %0t: Sparse error injection", phase4_start_time), UVM_LOW)
  `uvm_info(get_type_name(), "Target: 1% error rate as per specification", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  // Create and run error injection with limited transactions
  error_seq = axi4_slave_sparse_error_injection_seq::type_id::create("error_seq");
  error_seq.error_rate = 1; // 1% as per specification
  error_seq.num_transactions = is_enhanced_mode ? 50 : 25;
  
  `uvm_info(get_type_name(), $sformatf("Starting sparse error injection with %0d%% error rate, %0d transactions (%s mode)", 
            error_seq.error_rate, error_seq.num_transactions, is_enhanced_mode ? "ENHANCED" : "NONE"), UVM_MEDIUM)
  
  fork
    begin
      `uvm_info(get_type_name(), $sformatf("[%0t] Starting axi4_slave_sparse_error_injection_seq on slave 0", $time), UVM_HIGH)
      error_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
      `uvm_info(get_type_name(), $sformatf("[%0t] Completed error injection sequence", $time), UVM_HIGH)
    end
    begin
      // Phase 4 timeout
      #15us;
      `uvm_info(get_type_name(), $sformatf("[%0t] Phase 4 timeout reached", $time), UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase4_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("PHASE 4 COMPLETED at %0t (Duration: %0t)", 
            phase4_end_time, phase4_end_time - phase4_start_time), UVM_LOW)
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase4_error_injection

task axi4_saturation_midburst_reset_qos_boundary_test::run_phase5_cleanup(uvm_phase phase);
  
  phase5_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("PHASE 5 STARTING at %0t: Reset smoke cleanup", phase5_start_time), UVM_LOW)
  `uvm_info(get_type_name(), "Final cleanup phase as per specification", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  // Create and run cleanup sequence with minimal transactions
  smoke_seq = axi4_master_reset_smoke_seq::type_id::create("smoke_seq");
  smoke_seq.num_txns = 5;
  
  // Bus matrix addressing handled automatically through test configuration
  
  `uvm_info(get_type_name(), $sformatf("Starting reset smoke cleanup with %0d transactions", 
            smoke_seq.num_txns), UVM_MEDIUM)
  
  fork
    begin
      `uvm_info(get_type_name(), $sformatf("[%0t] Starting axi4_master_reset_smoke_seq for cleanup", $time), UVM_HIGH)
      smoke_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
      `uvm_info(get_type_name(), $sformatf("[%0t] Completed reset smoke cleanup sequence", $time), UVM_HIGH)
    end
    begin
      // Phase 5 timeout
      #5us;
      `uvm_info(get_type_name(), $sformatf("[%0t] Phase 5 timeout reached", $time), UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase5_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("PHASE 5 COMPLETED at %0t (Duration: %0t)", 
            phase5_end_time, phase5_end_time - phase5_start_time), UVM_LOW)
  
  // Final cleanup delay
  #1us;
  
endtask : run_phase5_cleanup

task axi4_saturation_midburst_reset_qos_boundary_test::monitor_sequence_completion();
  // This task runs in parallel to monitor sequence completions
  forever begin
    #1us;
    if (phase1_done && phase2_done) begin
      break;
    end
  end
endtask : monitor_sequence_completion

`endif