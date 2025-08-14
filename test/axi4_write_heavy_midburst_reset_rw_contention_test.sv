`ifndef AXI4_WRITE_HEAVY_MIDBURST_RESET_RW_CONTENTION_TEST_INCLUDED_
`define AXI4_WRITE_HEAVY_MIDBURST_RESET_RW_CONTENTION_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_write_heavy_midburst_reset_rw_contention_test
// Write-heavy test with mid-burst reset and read-write contention
// Supports both NONE (no ref model) and ENHANCED (10x10) bus matrix modes
//--------------------------------------------------------------------------------------------
class axi4_write_heavy_midburst_reset_rw_contention_test extends axi4_base_test;
  `uvm_component_utils(axi4_write_heavy_midburst_reset_rw_contention_test)

  // Sequence handles
  axi4_master_mixed_burst_lengths_seq mixed_burst_seq;
  axi4_slave_write_response_throttling_seq throttle_seq;
  axi4_master_all_to_all_saturation_seq saturation_seq[];
  axi4_master_midburst_reset_write_seq midburst_reset_seq;
  axi4_master_read_write_contention_seq contention_seq;
  axi4_master_reset_smoke_seq smoke_seq;
  
  // Configuration parameters
  int num_masters;
  int num_slaves;
  bit is_enhanced_mode;
  bit is_4x4_ref_mode;
  string bus_matrix_mode_str;
  
  // Test phase control
  bit phase1_done = 0;
  bit phase2_done = 0;
  bit phase3_done = 0;
  bit phase4_done = 0;
  bit phase5_done = 0;

  extern function new(string name = "axi4_write_heavy_midburst_reset_rw_contention_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void configure_bus_matrix_mode();
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task run_phase1_mixed_burst(uvm_phase phase);
  extern virtual task run_phase2_throttling(uvm_phase phase);
  extern virtual task run_phase3_saturation_midburst(uvm_phase phase);
  extern virtual task run_phase4_contention(uvm_phase phase);
  extern virtual task run_phase5_cleanup(uvm_phase phase);
  
endclass : axi4_write_heavy_midburst_reset_rw_contention_test

function axi4_write_heavy_midburst_reset_rw_contention_test::new(string name = "axi4_write_heavy_midburst_reset_rw_contention_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_write_heavy_midburst_reset_rw_contention_test::build_phase(uvm_phase phase);
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
  `uvm_info(get_type_name(), "AXI4 WRITE HEAVY MIDBURST RESET RW CONTENTION TEST", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Bus Matrix Mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Masters: %0d, Slaves: %0d", num_masters, num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "Test Sequence per axi_stress_reset_test.md:", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-1: axi4_master_mixed_burst_lengths_seq", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-2: axi4_slave_write_response_throttling_seq", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-3: [PARALLEL] axi4_master_all_to_all_saturation_seq + axi4_master_midburst_reset_write_seq", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-4: axi4_master_read_write_contention_seq", UVM_LOW)
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

function void axi4_write_heavy_midburst_reset_rw_contention_test::configure_bus_matrix_mode();
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

task axi4_write_heavy_midburst_reset_rw_contention_test::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), "🧠====================================================🧠", UVM_LOW)
  `uvm_info(get_type_name(), "🧠  WRITE HEAVY MIDBURST RESET RW CONTENTION TEST    🧠", UVM_LOW)
  `uvm_info(get_type_name(), "🧠====================================================🧠", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Starting test with mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Test start time: %0t", $time), UVM_LOW)
  
  phase.raise_objection(this);
  
  // Initialize sequence arrays
  saturation_seq = new[num_masters];
  
  // Run test phases sequentially with proper control
  fork
    begin
      // Main test sequence
      run_phase1_mixed_burst(phase);
      run_phase2_throttling(phase);
      run_phase3_saturation_midburst(phase);
      run_phase4_contention(phase);
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
  
  `uvm_info(get_type_name(), "Completed write_heavy_midburst_reset_rw_contention test", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

task axi4_write_heavy_midburst_reset_rw_contention_test::run_phase1_mixed_burst(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 1: Starting mixed burst lengths", UVM_MEDIUM)
  
  // Create mixed burst sequence with limited transactions
  mixed_burst_seq = axi4_master_mixed_burst_lengths_seq::type_id::create("mixed_burst_seq");
  mixed_burst_seq.num_transactions = is_enhanced_mode ? 50 : 25; // Limit transactions
  
  fork
    begin
      mixed_burst_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
    end
    begin
      // Phase 1 timeout
      #40us;
      `uvm_info(get_type_name(), "Phase 1 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase1_done = 1;
  
  // Small delay before next phase
  #2us;
  
endtask : run_phase1_mixed_burst

task axi4_write_heavy_midburst_reset_rw_contention_test::run_phase2_throttling(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 2: Starting write response throttling", UVM_MEDIUM)
  
  // Create throttling sequence with limited transactions
  throttle_seq = axi4_slave_write_response_throttling_seq::type_id::create("throttle_seq");
  throttle_seq.num_responses = is_enhanced_mode ? 40 : 20; // Limit responses
  throttle_seq.throttle_delay = 100; // Moderate throttling delay
  
  fork
    begin
      throttle_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
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
  #2us;
  
endtask : run_phase2_throttling

task axi4_write_heavy_midburst_reset_rw_contention_test::run_phase3_saturation_midburst(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 3: Starting parallel saturation and mid-burst reset", UVM_MEDIUM)
  
  // Configure saturation sequences with limited transactions
  for(int m = 0; m < num_masters; m++) begin
    saturation_seq[m] = axi4_master_all_to_all_saturation_seq::type_id::create($sformatf("saturation_seq_%0d", m));
    saturation_seq[m].num_transactions = is_enhanced_mode ? 35 : 18; // Limit transactions
  end
  
  // Create mid-burst reset sequence
  midburst_reset_seq = axi4_master_midburst_reset_write_seq::type_id::create("midburst_reset_seq");
  midburst_reset_seq.reset_after_beats = is_enhanced_mode ? 128 : 64; // Reset after beats
  
  fork
    begin
      // Start all saturation sequences
      foreach(saturation_seq[i]) begin
        automatic int idx = i;
        fork
          begin
            saturation_seq[idx].start(axi4_env_h.axi4_master_agent_h[idx].axi4_master_write_seqr_h);
          end
        join_none
      end
      
      // Wait a bit then inject mid-burst reset
      #20us;
      midburst_reset_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
    end
    begin
      // Phase 3 timeout
      #80us;
      `uvm_info(get_type_name(), "Phase 3 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase3_done = 1;
  
  // Small delay before next phase
  #2us;
  
endtask : run_phase3_saturation_midburst

task axi4_write_heavy_midburst_reset_rw_contention_test::run_phase4_contention(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 4: Starting read-write contention", UVM_MEDIUM)
  
  // Create contention sequence with limited transactions
  contention_seq = axi4_master_read_write_contention_seq::type_id::create("contention_seq");
  contention_seq.num_transactions = is_enhanced_mode ? 40 : 20; // Limit transactions
  contention_seq.target_slave = (num_slaves > 1) ? 1 : 0;
  
  fork
    begin
      contention_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
    end
    begin
      // Phase 4 timeout
      #60us;
      `uvm_info(get_type_name(), "Phase 4 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase4_done = 1;
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase4_contention

task axi4_write_heavy_midburst_reset_rw_contention_test::run_phase5_cleanup(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 5: Starting reset smoke cleanup", UVM_MEDIUM)
  
  // Create and run cleanup sequence with minimal transactions
  smoke_seq = axi4_master_reset_smoke_seq::type_id::create("smoke_seq");
  smoke_seq.num_txns = 5;
  
  fork
    begin
      smoke_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
    end
    begin
      // Phase 5 timeout
      #10us;
      `uvm_info(get_type_name(), "Phase 5 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase5_done = 1;
  
  // Final cleanup delay
  #2us;
  
endtask : run_phase5_cleanup

`endif