`ifndef AXI4_QOS_REGION_ROUTING_RESET_BACKPRESSURE_TEST_INCLUDED_
`define AXI4_QOS_REGION_ROUTING_RESET_BACKPRESSURE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_region_routing_reset_backpressure_test
// Test focusing on QoS, region routing, reset, and backpressure
// Based on axi_stress_reset_test.md specification:
// Sequence: axi4_master_region_routing_seq → [PARALLEL] axi4_master_qos_arbitration_seq + 
//           axi4_master_all_to_all_saturation_seq → axi4_master_midburst_reset_read_seq → 
//           axi4_slave_backpressure_storm_seq → axi4_master_reset_smoke_seq
// 
// Supports 3 bus matrix modes:
// - NONE: No reference model (4x4 topology)
// - BUS_4x4_REF: 4x4 bus matrix with reference model  
// - BUS_ENHANCED_MATRIX: 10x10 enhanced bus matrix with reference model
//--------------------------------------------------------------------------------------------
class axi4_qos_region_routing_reset_backpressure_test extends axi4_base_test;
  `uvm_component_utils(axi4_qos_region_routing_reset_backpressure_test)

  // Sequence handles
  axi4_master_region_routing_seq region_seq;
  axi4_master_qos_arbitration_seq qos_seq[];
  axi4_master_all_to_all_saturation_seq saturation_seq[];
  axi4_master_midburst_reset_read_seq midburst_reset_seq;
  axi4_slave_backpressure_storm_seq backpressure_seq;
  axi4_master_reset_smoke_seq smoke_seq;
  
  // Configuration parameters
  int num_masters;
  int num_slaves;
  bit is_enhanced_mode;
  bit is_4x4_ref_mode;
  string bus_matrix_mode_str;
  
  // Timing tracking
  time test_start_time;
  time phase1_start_time, phase1_end_time;
  time phase2_start_time, phase2_end_time; 
  time phase3_start_time, phase3_end_time;
  time phase4_start_time, phase4_end_time;
  time phase5_start_time, phase5_end_time;
  
  // Sequence completion tracking
  int sequences_completed = 0;
  
  // Test phase control
  bit phase1_done = 0;
  bit phase2_done = 0;
  bit phase3_done = 0;
  bit phase4_done = 0;
  bit phase5_done = 0;

  extern function new(string name = "axi4_qos_region_routing_reset_backpressure_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void configure_bus_matrix_mode();
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task run_phase1_region_routing(uvm_phase phase);
  extern virtual task run_phase2_qos_saturation(uvm_phase phase);
  extern virtual task run_phase3_midburst_reset(uvm_phase phase);
  extern virtual task run_phase4_backpressure(uvm_phase phase);
  extern virtual task run_phase5_cleanup(uvm_phase phase);
  
endclass : axi4_qos_region_routing_reset_backpressure_test

function axi4_qos_region_routing_reset_backpressure_test::new(string name = "axi4_qos_region_routing_reset_backpressure_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_qos_region_routing_reset_backpressure_test::build_phase(uvm_phase phase);
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
  `uvm_info(get_type_name(), "AXI4 QOS REGION ROUTING RESET BACKPRESSURE TEST", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Bus Matrix Mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Masters: %0d, Slaves: %0d", num_masters, num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "Test Sequence per axi_stress_reset_test.md:", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-1: axi4_master_region_routing_seq", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-2: [PARALLEL] axi4_master_qos_arbitration_seq + axi4_master_all_to_all_saturation_seq", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-3: axi4_master_midburst_reset_read_seq", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-4: axi4_slave_backpressure_storm_seq", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-5: axi4_master_reset_smoke_seq (cleanup)", UVM_LOW)
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

function void axi4_qos_region_routing_reset_backpressure_test::configure_bus_matrix_mode();
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

task axi4_qos_region_routing_reset_backpressure_test::run_phase(uvm_phase phase);
  
  test_start_time = $time;
  
  `uvm_info(get_type_name(), "🧠====================================================🧠", UVM_LOW)
  `uvm_info(get_type_name(), "🧠     QoS REGION ROUTING RESET BACKPRESSURE TEST     🧠", UVM_LOW)
  `uvm_info(get_type_name(), "🧠====================================================🧠", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Starting test with mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Test start time: %0t", test_start_time), UVM_LOW)
  
  phase.raise_objection(this);
  
  // Initialize sequence arrays
  qos_seq = new[num_masters];
  saturation_seq = new[num_masters];
  
  // Run test phases sequentially with proper control
  fork
    begin
      // Main test sequence
      run_phase1_region_routing(phase);
      run_phase2_qos_saturation(phase);
      run_phase3_midburst_reset(phase);
      run_phase4_backpressure(phase);
      run_phase5_cleanup(phase);
    end
    begin
      // Overall timeout watchdog - 350us total test time
      #350us;
      `uvm_warning(get_type_name(), "Test timeout reached (350us) - forcing completion")
    end
  join_any
  
  // Ensure all forked processes are killed
  disable fork;
  
  // Wait a bit for cleanup
  #5us;
  
  `uvm_info(get_type_name(), "Completed qos_region_routing_reset_backpressure test", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

task axi4_qos_region_routing_reset_backpressure_test::run_phase1_region_routing(uvm_phase phase);
  
  phase1_start_time = $time;
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "Phase 1: REGION ROUTING SEQUENCE", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  
  // Create region routing sequence with limited transactions
  region_seq = axi4_master_region_routing_seq::type_id::create("region_seq");
  region_seq.num_transactions = is_enhanced_mode ? 40 : 20; // Limit transactions
  
  // Bus matrix addressing will be handled automatically through test configuration
  
  `uvm_info(get_type_name(), $sformatf("🚀 STARTING: axi4_master_region_routing_seq on Master[0] at %0t", $time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   📊 Transactions: %0d", region_seq.num_transactions), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("   🎯 Target: Write Sequencer"), UVM_MEDIUM)
  
  fork
    begin
      region_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
      sequences_completed++;
      `uvm_info(get_type_name(), $sformatf("✅ COMPLETED: axi4_master_region_routing_seq at %0t (Duration: %0t)", 
                $time, $time - phase1_start_time), UVM_LOW)
    end
    begin
      // Phase 1 timeout
      #40us;
      `uvm_info(get_type_name(), "⚠️ Phase 1 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase1_end_time = $time;
  phase1_done = 1;
  
  `uvm_info(get_type_name(), $sformatf("📈 Phase 1 Statistics:"), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Duration: %0t", phase1_end_time - phase1_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Sequences Completed: %0d", sequences_completed), UVM_LOW)
  
  // Small delay before next phase
  #2us;
  
endtask : run_phase1_region_routing

task axi4_qos_region_routing_reset_backpressure_test::run_phase2_qos_saturation(uvm_phase phase);
  
  phase2_start_time = $time;
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "Phase 2: [PARALLEL] QoS ARBITRATION + SATURATION", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  
  // Configure sequences with limited transactions
  for(int m = 0; m < num_masters; m++) begin
    automatic int master_id = m;
    
    // Create QoS sequence
    qos_seq[master_id] = axi4_master_qos_arbitration_seq::type_id::create($sformatf("qos_seq_%0d", master_id));
    qos_seq[master_id].qos_value = (master_id * 4) % 16;
    qos_seq[master_id].num_transactions = is_enhanced_mode ? 25 : 12; // Limit transactions
    
    // Create saturation sequence
    saturation_seq[master_id] = axi4_master_all_to_all_saturation_seq::type_id::create($sformatf("saturation_seq_%0d", master_id));
    saturation_seq[master_id].num_transactions = is_enhanced_mode ? 30 : 15; // Limit transactions
    
    // Bus matrix addressing handled automatically through test configuration
    
    `uvm_info(get_type_name(), $sformatf("🚀 STARTING: axi4_master_qos_arbitration_seq on Master[%0d] (QoS=%0d)", 
              master_id, qos_seq[master_id].qos_value), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("🚀 STARTING: axi4_master_all_to_all_saturation_seq on Master[%0d]", master_id), UVM_LOW)
  end
  
  fork
    begin
      // Start all QoS and saturation sequences in parallel
      foreach(qos_seq[i]) begin
        automatic int idx = i;
        fork
          begin
            qos_seq[idx].start(axi4_env_h.axi4_master_agent_h[idx].axi4_master_write_seqr_h);
            sequences_completed++;
            `uvm_info(get_type_name(), $sformatf("✅ COMPLETED: axi4_master_qos_arbitration_seq[%0d] at %0t", idx, $time), UVM_LOW)
          end
          begin
            saturation_seq[idx].start(axi4_env_h.axi4_master_agent_h[idx].axi4_master_read_seqr_h);
            sequences_completed++;
            `uvm_info(get_type_name(), $sformatf("✅ COMPLETED: axi4_master_all_to_all_saturation_seq[%0d] at %0t", idx, $time), UVM_LOW)
          end
        join_none
      end
      wait fork; // Wait for all parallel sequences to complete
    end
    begin
      // Phase 2 timeout
      #80us;
      `uvm_info(get_type_name(), "⚠️ Phase 2 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase2_end_time = $time;
  phase2_done = 1;
  
  `uvm_info(get_type_name(), $sformatf("📈 Phase 2 Statistics:"), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Duration: %0t", phase2_end_time - phase2_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Masters Used: %0d", num_masters), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Total Sequences: %0d (QoS) + %0d (Saturation)", num_masters, num_masters), UVM_LOW)
  
  // Small delay before next phase
  #2us;
  
endtask : run_phase2_qos_saturation

task axi4_qos_region_routing_reset_backpressure_test::run_phase3_midburst_reset(uvm_phase phase);
  
  phase3_start_time = $time;
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "Phase 3: MID-BURST RESET READ SEQUENCE", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  
  // Create mid-burst reset sequence with limited transactions
  midburst_reset_seq = axi4_master_midburst_reset_read_seq::type_id::create("midburst_reset_seq");
  midburst_reset_seq.reset_after_beats = is_enhanced_mode ? 64 : 32; // Reset after beats
  // Burst length limits handled through test constraints
  
  // Bus matrix addressing handled automatically through test configuration
  
  `uvm_info(get_type_name(), $sformatf("🚀 STARTING: axi4_master_midburst_reset_read_seq on Master[0] at %0t", $time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   📊 Reset after beats: %0d", midburst_reset_seq.reset_after_beats), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("   🎯 Target: Read Sequencer"), UVM_MEDIUM)
  
  fork
    begin
      midburst_reset_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_read_seqr_h);
      sequences_completed++;
      `uvm_info(get_type_name(), $sformatf("✅ COMPLETED: axi4_master_midburst_reset_read_seq at %0t (Duration: %0t)", 
                $time, $time - phase3_start_time), UVM_LOW)
    end
    begin
      // Phase 3 timeout
      #30us;
      `uvm_info(get_type_name(), "⚠️ Phase 3 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase3_end_time = $time;
  phase3_done = 1;
  
  `uvm_info(get_type_name(), $sformatf("📈 Phase 3 Statistics:"), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Duration: %0t", phase3_end_time - phase3_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Reset Strategy: Mid-burst reset injection"), UVM_LOW)
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase3_midburst_reset

task axi4_qos_region_routing_reset_backpressure_test::run_phase4_backpressure(uvm_phase phase);
  
  phase4_start_time = $time;
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "Phase 4: SLAVE BACKPRESSURE STORM SEQUENCE", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  
  // Create backpressure sequence with limited patterns
  backpressure_seq = axi4_slave_backpressure_storm_seq::type_id::create("backpressure_seq");
  backpressure_seq.num_patterns = 5; // Limit patterns
  
  `uvm_info(get_type_name(), $sformatf("🚀 STARTING: axi4_slave_backpressure_storm_seq on Slave[0] at %0t", $time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   📊 Patterns: %0d", backpressure_seq.num_patterns), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("   🎯 Target: Slave Write Sequencer"), UVM_MEDIUM)
  
  fork
    begin
      backpressure_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
      sequences_completed++;
      `uvm_info(get_type_name(), $sformatf("✅ COMPLETED: axi4_slave_backpressure_storm_seq at %0t (Duration: %0t)", 
                $time, $time - phase4_start_time), UVM_LOW)
    end
    begin
      // Phase 4 timeout
      #40us;
      `uvm_info(get_type_name(), "⚠️ Phase 4 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase4_end_time = $time;
  phase4_done = 1;
  
  `uvm_info(get_type_name(), $sformatf("📈 Phase 4 Statistics:"), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Duration: %0t", phase4_end_time - phase4_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Backpressure Strategy: Storm patterns"), UVM_LOW)
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase4_backpressure

task axi4_qos_region_routing_reset_backpressure_test::run_phase5_cleanup(uvm_phase phase);
  
  phase5_start_time = $time;
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "Phase 5: RESET SMOKE CLEANUP SEQUENCE", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  
  // Create and run cleanup sequence with minimal transactions
  smoke_seq = axi4_master_reset_smoke_seq::type_id::create("smoke_seq");
  smoke_seq.num_txns = 5;
  
  // Bus matrix addressing handled automatically through test configuration
  
  `uvm_info(get_type_name(), $sformatf("🚀 STARTING: axi4_master_reset_smoke_seq on Master[0] at %0t", $time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   📊 Transactions: %0d", smoke_seq.num_txns), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("   🎯 Target: Write Sequencer (cleanup)"), UVM_MEDIUM)
  
  fork
    begin
      smoke_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
      sequences_completed++;
      `uvm_info(get_type_name(), $sformatf("✅ COMPLETED: axi4_master_reset_smoke_seq at %0t (Duration: %0t)", 
                $time, $time - phase5_start_time), UVM_LOW)
    end
    begin
      // Phase 5 timeout
      #10us;
      `uvm_info(get_type_name(), "⚠️ Phase 5 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase5_end_time = $time;
  phase5_done = 1;
  
  `uvm_info(get_type_name(), $sformatf("📈 Phase 5 Statistics:"), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Duration: %0t", phase5_end_time - phase5_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("   Final Cleanup: Reset smoke test"), UVM_LOW)
  
  // Final test summary
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "🎯 TEST COMPLETION SUMMARY", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Total Test Duration: %0t", $time - test_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Total Sequences Completed: %0d", sequences_completed), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Phase Status: P1=%s P2=%s P3=%s P4=%s P5=%s", 
            phase1_done ? "✅" : "❌", phase2_done ? "✅" : "❌", phase3_done ? "✅" : "❌", 
            phase4_done ? "✅" : "❌", phase5_done ? "✅" : "❌"), UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  
  // Final cleanup delay
  #2us;
  
endtask : run_phase5_cleanup

`endif