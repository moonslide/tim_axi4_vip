`ifndef AXI4_HOTSPOT_FAIRNESS_BOUNDARY_ERROR_RESET_BACKPRESSURE_TEST_INCLUDED_
`define AXI4_HOTSPOT_FAIRNESS_BOUNDARY_ERROR_RESET_BACKPRESSURE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_hotspot_fairness_boundary_error_reset_backpressure_test
// Test focusing on hotspot, fairness, boundary, error injection, and reset backpressure
// Based on axi_stress_reset_test.md specification:
// Sequence: [PARALLEL] axi4_master_hotspot_many_to_one_seq + axi4_master_mixed_burst_lengths_seq →
//          axi4_master_read_write_contention_seq → axi4_master_4kb_boundary_seq →
//          axi4_slave_sparse_error_injection_seq → axi4_slave_reset_backpressure_seq
//
// Focus: Arbitration fairness, WLAST/RLAST, 4KB boundary, error isolation, reset overlap
//
// Supports 3 bus matrix modes:
// - NONE: No reference model (4x4 topology)
// - BASE_BUS_MATRIX: 4x4 bus matrix with reference model
// - BUS_ENHANCED_MATRIX: 10x10 enhanced bus matrix with reference model
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
  bit is_4x4_ref_mode;
  string bus_matrix_mode_str;
  
  // Timing tracking
  time test_start_time;
  time phase1_start_time, phase1_end_time;
  time phase2_start_time, phase2_end_time;
  time phase3_start_time, phase3_end_time;
  time phase4_start_time, phase4_end_time;
  time phase5_start_time, phase5_end_time;
  time phase6_start_time, phase6_end_time;
  
  // Sequence completion tracking
  int sequences_completed = 0;
  int hotspot_seq_completed = 0;
  
  // Test phase control
  bit phase1_done = 0;
  bit phase2_done = 0;
  bit phase3_done = 0;
  bit phase4_done = 0;
  bit phase5_done = 0;

  extern function new(string name = "axi4_hotspot_fairness_boundary_error_reset_backpressure_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void configure_bus_matrix_mode();
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
  `uvm_info(get_type_name(), "AXI4 HOTSPOT FAIRNESS BOUNDARY ERROR RESET BACKPRESSURE TEST", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Bus Matrix Mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Masters: %0d, Slaves: %0d", num_masters, num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "Test Sequence per axi_stress_reset_test.md:", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-1: [PARALLEL] axi4_master_hotspot_many_to_one_seq + axi4_master_mixed_burst_lengths_seq", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-2: axi4_master_read_write_contention_seq", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-3: axi4_master_4kb_boundary_seq", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-4: axi4_slave_sparse_error_injection_seq", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-5: axi4_slave_reset_backpressure_seq", UVM_LOW)
  `uvm_info(get_type_name(), "Focus: Arbitration fairness, WLAST/RLAST, 4KB boundary, error isolation, reset overlap", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  // Configure slave response mode for memory testing based on mode
  // Configure slaves for all modes - they need to respond to transactions
  if (is_enhanced_mode) begin
    `uvm_info(get_type_name(), "Configuring slaves for BUS_ENHANCED_MATRIX 10x10 mode with memory model", UVM_MEDIUM)
  end else if (is_4x4_ref_mode) begin
    `uvm_info(get_type_name(), "Configuring slaves for BASE_BUS_MATRIX 4x4 mode with memory model", UVM_MEDIUM)
  end else begin
    `uvm_info(get_type_name(), "Configuring slaves for NONE mode (no reference model, but slaves still active)", UVM_MEDIUM)
  end
  
  // Always configure slaves with memory mode - needed for proper operation
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_response_mode = RESP_IN_ORDER;
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
  end
  
endfunction : build_phase

function void axi4_hotspot_fairness_boundary_error_reset_backpressure_test::configure_bus_matrix_mode();
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
      bus_matrix_mode_str = "BUS_ENHANCED_MATRIX (10x10 with ref model)";
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
    random_mode = $urandom_range(0, 2); // 0=NONE, 1=BASE_BUS_MATRIX, 2=BUS_ENHANCED_MATRIX
    `uvm_info(get_type_name(), $sformatf("Randomly selecting bus matrix mode. Random value: %0d", random_mode), UVM_MEDIUM)
    
    if (random_mode == 2) begin
      selected_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
      selected_masters = 10;
      selected_slaves = 10;
      is_enhanced_mode = 1;
      is_4x4_ref_mode = 0;
      bus_matrix_mode_str = "BUS_ENHANCED_MATRIX (10x10 with ref model) [RANDOM]";
      `uvm_info(get_type_name(), "Random selection: BUS_ENHANCED_MATRIX 10x10 mode", UVM_LOW)
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

task axi4_hotspot_fairness_boundary_error_reset_backpressure_test::run_phase(uvm_phase phase);
  
  test_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("TEST STARTING at time %0t", test_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), "Focus: Hotspot fairness, boundary testing, error isolation, reset overlap", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  phase.raise_objection(this);
  
  // Initialize sequence arrays
  hotspot_seq = new[num_masters];
  
  // Run test phases sequentially with proper control
  fork
    begin
      // Main test sequence as per markdown specification
      run_phase1_hotspot_mixed(phase);         // Phase 1: [PARALLEL] hotspot + mixed burst
      run_phase2_contention(phase);            // Phase 2: read-write contention
      run_phase3_boundary(phase);              // Phase 3: 4KB boundary
      run_phase4_error_injection(phase);       // Phase 4: error injection
      run_phase5_reset_backpressure(phase);    // Phase 5: reset backpressure
      run_phase6_cleanup(phase);               // Phase 6: cleanup
    end
    begin
      // Overall timeout watchdog - 450us total test time (increased for 3 modes)
      #450us;
      `uvm_warning(get_type_name(), $sformatf("TEST TIMEOUT at %0t - forcing completion (450us limit reached)", $time))
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
  `uvm_info(get_type_name(), $sformatf("Total Sequences Completed: %0d", sequences_completed), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Hotspot Sequences Completed: %0d/%0d", hotspot_seq_completed, num_masters), UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

task axi4_hotspot_fairness_boundary_error_reset_backpressure_test::run_phase1_hotspot_mixed(uvm_phase phase);
  
  phase1_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("PHASE 1 STARTING at %0t: [PARALLEL] Hotspot + Mixed Burst", phase1_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Mode: %s", is_enhanced_mode ? "BUS_ENHANCED_MATRIX 10x10" : (is_4x4_ref_mode ? "BASE_BUS_MATRIX 4x4" : "NONE")), UVM_LOW)
  `uvm_info(get_type_name(), "Parallel: axi4_master_hotspot_many_to_one_seq + axi4_master_mixed_burst_lengths_seq", UVM_LOW)
  `uvm_info(get_type_name(), "Focus: Many-to-one arbitration fairness, mixed burst lengths (WLAST/RLAST)", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  // Create mixed burst sequence with mode-specific transactions
  mixed_burst_seq = axi4_master_mixed_burst_lengths_seq::type_id::create("mixed_burst_seq");
  
  // Configure addressing mode based on bus matrix mode
  if (is_enhanced_mode) begin
    mixed_burst_seq.use_bus_matrix_addressing = 2;  // Use 10x10 enhanced matrix addresses
  end else if (is_4x4_ref_mode) begin
    mixed_burst_seq.use_bus_matrix_addressing = 1;  // Use 4x4 base matrix addresses
  end else begin
    mixed_burst_seq.use_bus_matrix_addressing = 0;  // Use default test addresses
  end
  
  // Force write-only since using write sequencer
  mixed_burst_seq.write_only_mode = 1;
  
  if (is_enhanced_mode) begin
    mixed_burst_seq.num_transactions = 60; // More transactions for 10x10
  end else if (is_4x4_ref_mode) begin
    mixed_burst_seq.num_transactions = 40; // Medium for 4x4 ref
  end else begin
    mixed_burst_seq.num_transactions = 25; // Fewer for NONE
  end
  
  // Configure hotspot sequences with mode-specific transactions
  for(int m = 0; m < num_masters; m++) begin
    hotspot_seq[m] = axi4_master_hotspot_many_to_one_seq::type_id::create($sformatf("hotspot_seq_%0d", m));
    hotspot_seq[m].target_slave_id = 0;  // All target slave 0 for hotspot testing
    
    // Configure addressing mode based on bus matrix mode
    if (is_enhanced_mode) begin
      hotspot_seq[m].use_bus_matrix_addressing = 2;  // Use 10x10 enhanced matrix addresses
    end else if (is_4x4_ref_mode) begin
      hotspot_seq[m].use_bus_matrix_addressing = 1;  // Use 4x4 base matrix addresses
    end else begin
      hotspot_seq[m].use_bus_matrix_addressing = 0;  // Use default test addresses
    end
    
    // Force write-only since using write sequencer
    hotspot_seq[m].write_only_mode = 1;
    
    if (is_enhanced_mode) begin
      hotspot_seq[m].num_transactions = 25; // More for 10x10
    end else if (is_4x4_ref_mode) begin
      hotspot_seq[m].num_transactions = 18; // Medium for 4x4 ref
    end else begin
      hotspot_seq[m].num_transactions = 10; // Fewer for NONE
    end
  end
  
  `uvm_info(get_type_name(), $sformatf("Created mixed_burst_seq with %0d transactions (%s mode)", 
            mixed_burst_seq.num_transactions, is_enhanced_mode ? "ENHANCED" : (is_4x4_ref_mode ? "4x4_REF" : "NONE")), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Created %0d hotspot sequences targeting slave 0, %0d transactions each", 
            num_masters, hotspot_seq[0].num_transactions), UVM_MEDIUM)
  
  fork
    begin
      // Start all sequences in parallel as per markdown spec
      fork
        begin
          // Start all hotspot sequences
          `uvm_info(get_type_name(), $sformatf("[%0t] Starting %0d axi4_master_hotspot_many_to_one_seq sequences in parallel", 
                    $time, num_masters), UVM_HIGH)
          foreach(hotspot_seq[i]) begin
            automatic int idx = i;
            fork
              begin
                `uvm_info(get_type_name(), $sformatf("[%0t] Starting hotspot_seq[%0d] on master %0d", $time, idx, idx), UVM_HIGH)
                hotspot_seq[idx].start(axi4_env_h.axi4_master_agent_h[idx].axi4_master_write_seqr_h);
                hotspot_seq_completed++;
                `uvm_info(get_type_name(), $sformatf("[%0t] Completed hotspot_seq[%0d] (%0d/%0d hotspot done)", 
                          $time, idx, hotspot_seq_completed, num_masters), UVM_HIGH)
              end
            join_none
          end
        end
        begin
          // Start mixed burst sequence in parallel
          `uvm_info(get_type_name(), $sformatf("[%0t] Starting axi4_master_mixed_burst_lengths_seq on master 0", $time), UVM_HIGH)
          mixed_burst_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
          sequences_completed++;
          `uvm_info(get_type_name(), $sformatf("[%0t] Completed axi4_master_mixed_burst_lengths_seq (%0d sequences done)", 
                    $time, sequences_completed), UVM_HIGH)
        end
      join
    end
    begin
      // Phase 1 timeout
      #80us;
      `uvm_info(get_type_name(), $sformatf("[%0t] Phase 1 parallel execution timeout reached", $time), UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase1_done = 1;
  phase1_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("PHASE 1 COMPLETED at %0t (Duration: %0t)", 
            phase1_end_time, phase1_end_time - phase1_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Hotspot sequences completed: %0d/%0d", hotspot_seq_completed, num_masters), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - Mixed burst sequence completed: %s", sequences_completed > 0 ? "YES" : "NO"), UVM_LOW)
  
  // Small delay before next phase
  #3us;
  
endtask : run_phase1_hotspot_mixed

task axi4_hotspot_fairness_boundary_error_reset_backpressure_test::run_phase2_contention(uvm_phase phase);
  
  phase2_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("PHASE 2 STARTING at %0t: Read-Write Contention", phase2_start_time), UVM_LOW)
  `uvm_info(get_type_name(), "Sequence: axi4_master_read_write_contention_seq", UVM_LOW)
  `uvm_info(get_type_name(), "Focus: Same slave R/W contention, data coherency, priority arbitration", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  // Create contention sequence with mode-specific parameters
  contention_seq = axi4_master_read_write_contention_seq::type_id::create("contention_seq");
  contention_seq.target_slave = (num_slaves > 3) ? 3 : 0; // Use slave 3 if available, else slave 0
  contention_seq.write_only_mode = 1; // Force write-only since using write sequencer
  if (is_enhanced_mode) begin
    contention_seq.num_transactions = 50; // More for 10x10
  end else if (is_4x4_ref_mode) begin
    contention_seq.num_transactions = 35; // Medium for 4x4 ref
  end else begin
    contention_seq.num_transactions = 20; // Fewer for NONE
  end
  
  `uvm_info(get_type_name(), $sformatf("Created contention_seq with %0d transactions, targeting slave %0d (%s mode)", 
            contention_seq.num_transactions, contention_seq.target_slave, 
            is_enhanced_mode ? "ENHANCED" : (is_4x4_ref_mode ? "4x4_REF" : "NONE")), UVM_MEDIUM)
  
  fork
    begin
      `uvm_info(get_type_name(), $sformatf("[%0t] Starting axi4_master_read_write_contention_seq on master 0", $time), UVM_HIGH)
      contention_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
      sequences_completed++;
      `uvm_info(get_type_name(), $sformatf("[%0t] Completed axi4_master_read_write_contention_seq (%0d sequences done)", 
                $time, sequences_completed), UVM_HIGH)
    end
    begin
      // Phase 2 timeout
      #60us;
      `uvm_info(get_type_name(), $sformatf("[%0t] Phase 2 contention timeout reached", $time), UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase2_done = 1;
  phase2_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("PHASE 2 COMPLETED at %0t (Duration: %0t)", 
            phase2_end_time, phase2_end_time - phase2_start_time), UVM_LOW)
  
  // Small delay before next phase
  #2us;
  
endtask : run_phase2_contention

task axi4_hotspot_fairness_boundary_error_reset_backpressure_test::run_phase3_boundary(uvm_phase phase);
  
  phase3_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("PHASE 3 STARTING at %0t: 4KB Boundary Testing", phase3_start_time), UVM_LOW)
  `uvm_info(get_type_name(), "Sequence: axi4_master_4kb_boundary_seq", UVM_LOW)
  `uvm_info(get_type_name(), "Focus: 4KB boundary crossing validation, legal/illegal address testing", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  // Create boundary sequence with mode-specific parameters
  boundary_seq = axi4_master_4kb_boundary_seq::type_id::create("boundary_seq");
  boundary_seq.test_illegal = 1; // Test both legal and illegal boundary crossings
  boundary_seq.write_only_mode = 1; // Force write-only since using write sequencer
  if (is_enhanced_mode) begin
    boundary_seq.num_transactions = 40; // More for 10x10
  end else if (is_4x4_ref_mode) begin
    boundary_seq.num_transactions = 25; // Medium for 4x4 ref
  end else begin
    boundary_seq.num_transactions = 15; // Fewer for NONE
  end
  
  `uvm_info(get_type_name(), $sformatf("Created boundary_seq with %0d transactions, testing illegal boundaries (%s mode)", 
            boundary_seq.num_transactions, is_enhanced_mode ? "ENHANCED" : (is_4x4_ref_mode ? "4x4_REF" : "NONE")), UVM_MEDIUM)
  
  fork
    begin
      `uvm_info(get_type_name(), $sformatf("[%0t] Starting axi4_master_4kb_boundary_seq on master 0 (write-only mode)", $time), UVM_HIGH)
      boundary_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
      sequences_completed++;
      `uvm_info(get_type_name(), $sformatf("[%0t] Completed axi4_master_4kb_boundary_seq (%0d sequences done)", 
                $time, sequences_completed), UVM_HIGH)
    end
    begin
      // Phase 3 timeout
      #40us;
      `uvm_info(get_type_name(), $sformatf("[%0t] Phase 3 boundary testing timeout reached", $time), UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase3_done = 1;
  phase3_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("PHASE 3 COMPLETED at %0t (Duration: %0t)", 
            phase3_end_time, phase3_end_time - phase3_start_time), UVM_LOW)
  
  // Small delay before next phase
  #2us;
  
endtask : run_phase3_boundary

task axi4_hotspot_fairness_boundary_error_reset_backpressure_test::run_phase4_error_injection(uvm_phase phase);
  
  phase4_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("PHASE 4 STARTING at %0t: Sparse Error Injection", phase4_start_time), UVM_LOW)
  `uvm_info(get_type_name(), "Sequence: axi4_slave_sparse_error_injection_seq", UVM_LOW)
  `uvm_info(get_type_name(), "Focus: Error isolation, SLVERR/DECERR injection, system resilience", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  // Create error injection sequence with mode-specific parameters
  error_seq = axi4_slave_sparse_error_injection_seq::type_id::create("error_seq");
  error_seq.error_rate = 2; // 2% error rate for testing error isolation
  if (is_enhanced_mode) begin
    error_seq.num_transactions = 50; // More for 10x10
  end else if (is_4x4_ref_mode) begin
    error_seq.num_transactions = 35; // Medium for 4x4 ref
  end else begin
    error_seq.num_transactions = 20; // Fewer for NONE
  end
  
  `uvm_info(get_type_name(), $sformatf("Created error_seq with %0d%% error rate, %0d transactions (%s mode)", 
            error_seq.error_rate, error_seq.num_transactions, 
            is_enhanced_mode ? "ENHANCED" : (is_4x4_ref_mode ? "4x4_REF" : "NONE")), UVM_MEDIUM)
  
  fork
    begin
      `uvm_info(get_type_name(), $sformatf("[%0t] Starting axi4_slave_sparse_error_injection_seq on slave 0", $time), UVM_HIGH)
      error_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
      sequences_completed++;
      `uvm_info(get_type_name(), $sformatf("[%0t] Completed axi4_slave_sparse_error_injection_seq (%0d sequences done)", 
                $time, sequences_completed), UVM_HIGH)
    end
    begin
      // Phase 4 timeout
      #50us;
      `uvm_info(get_type_name(), $sformatf("[%0t] Phase 4 error injection timeout reached", $time), UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase4_done = 1;
  phase4_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("PHASE 4 COMPLETED at %0t (Duration: %0t)", 
            phase4_end_time, phase4_end_time - phase4_start_time), UVM_LOW)
  
  // Small delay before next phase
  #2us;
  
endtask : run_phase4_error_injection

task axi4_hotspot_fairness_boundary_error_reset_backpressure_test::run_phase5_reset_backpressure(uvm_phase phase);
  
  phase5_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("PHASE 5 STARTING at %0t: Reset Backpressure", phase5_start_time), UVM_LOW)
  `uvm_info(get_type_name(), "Sequence: axi4_slave_reset_backpressure_seq", UVM_LOW)
  `uvm_info(get_type_name(), "Focus: Reset overlap with backpressure, system recovery, state cleanup", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  // Create reset backpressure sequence with mode-specific parameters
  reset_backpressure_seq = axi4_slave_reset_backpressure_seq::type_id::create("reset_backpressure_seq");
  if (is_enhanced_mode) begin
    reset_backpressure_seq.backpressure_cycles = 5000; // More cycles for 10x10
  end else if (is_4x4_ref_mode) begin
    reset_backpressure_seq.backpressure_cycles = 3500; // Medium for 4x4 ref
  end else begin
    reset_backpressure_seq.backpressure_cycles = 2500; // Fewer for NONE
  end
  
  `uvm_info(get_type_name(), $sformatf("Created reset_backpressure_seq with %0d backpressure cycles (%s mode)", 
            reset_backpressure_seq.backpressure_cycles, 
            is_enhanced_mode ? "ENHANCED" : (is_4x4_ref_mode ? "4x4_REF" : "NONE")), UVM_MEDIUM)
  
  fork
    begin
      `uvm_info(get_type_name(), $sformatf("[%0t] Starting axi4_slave_reset_backpressure_seq on slave 0", $time), UVM_HIGH)
      reset_backpressure_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
      sequences_completed++;
      `uvm_info(get_type_name(), $sformatf("[%0t] Completed axi4_slave_reset_backpressure_seq (%0d sequences done)", 
                $time, sequences_completed), UVM_HIGH)
    end
    begin
      // Phase 5 timeout
      #40us;
      `uvm_info(get_type_name(), $sformatf("[%0t] Phase 5 reset backpressure timeout reached", $time), UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase5_done = 1;
  phase5_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("PHASE 5 COMPLETED at %0t (Duration: %0t)", 
            phase5_end_time, phase5_end_time - phase5_start_time), UVM_LOW)
  
  // Small delay before next phase
  #2us;
  
endtask : run_phase5_reset_backpressure

task axi4_hotspot_fairness_boundary_error_reset_backpressure_test::run_phase6_cleanup(uvm_phase phase);
  
  phase6_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("PHASE 6 STARTING at %0t: Reset Smoke Cleanup", phase6_start_time), UVM_LOW)
  `uvm_info(get_type_name(), "Sequence: axi4_master_reset_smoke_seq", UVM_LOW)
  `uvm_info(get_type_name(), "Purpose: Final system cleanup and stability verification", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  // Create and run cleanup sequence with mode-appropriate transactions
  smoke_seq = axi4_master_reset_smoke_seq::type_id::create("smoke_seq");
  
  // Configure addressing mode based on bus matrix mode
  if (is_enhanced_mode) begin
    smoke_seq.use_bus_matrix_addressing = 2;  // Use 10x10 enhanced matrix addresses
  end else if (is_4x4_ref_mode) begin
    smoke_seq.use_bus_matrix_addressing = 1;  // Use 4x4 base matrix addresses
  end else begin
    smoke_seq.use_bus_matrix_addressing = 0;  // Use default test addresses
  end
  
  if (is_enhanced_mode) begin
    smoke_seq.num_txns = 10; // More cleanup for 10x10
  end else if (is_4x4_ref_mode) begin
    smoke_seq.num_txns = 7; // Medium cleanup for 4x4 ref
  end else begin
    smoke_seq.num_txns = 5; // Basic cleanup for NONE
  end
  
  `uvm_info(get_type_name(), $sformatf("Created smoke_seq with %0d transactions (%s mode)", 
            smoke_seq.num_txns, is_enhanced_mode ? "ENHANCED" : (is_4x4_ref_mode ? "4x4_REF" : "NONE")), UVM_MEDIUM)
  
  fork
    begin
      `uvm_info(get_type_name(), $sformatf("[%0t] Starting axi4_master_reset_smoke_seq for final cleanup", $time), UVM_HIGH)
      smoke_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
      sequences_completed++;
      `uvm_info(get_type_name(), $sformatf("[%0t] Completed axi4_master_reset_smoke_seq (%0d sequences done)", 
                $time, sequences_completed), UVM_HIGH)
    end
    begin
      // Phase 6 timeout
      #15us;
      `uvm_info(get_type_name(), $sformatf("[%0t] Phase 6 cleanup timeout reached", $time), UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase6_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("PHASE 6 COMPLETED at %0t (Duration: %0t)", 
            phase6_end_time, phase6_end_time - phase6_start_time), UVM_LOW)
  
  // Final cleanup delay
  #3us;
  
endtask : run_phase6_cleanup

`endif