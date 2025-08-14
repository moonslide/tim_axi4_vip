`ifndef AXI4_THROUGHPUT_ORDERING_LONGTAIL_THROTTLED_WRITE_TEST_INCLUDED_
`define AXI4_THROUGHPUT_ORDERING_LONGTAIL_THROTTLED_WRITE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_throughput_ordering_longtail_throttled_write_test
// Test focusing on throughput, ordering, long tail latency, and write throttling
// Based on axi_stress_reset_test.md specification:
// Sequence: axi4_master_one_to_many_fanout_seq → axi4_master_max_outstanding_seq → 
//          [PARALLEL] axi4_slave_long_tail_latency_seq + axi4_master_read_reorder_seq → 
//          axi4_slave_write_response_throttling_seq → axi4_master_reset_smoke_seq
// 
// Supports 3 bus matrix modes:
// - NONE: No reference model (4x4 topology)
// - BUS_4x4_REF: 4x4 bus matrix with reference model
// - BUS_ENHANCED_MATRIX: 10x10 enhanced bus matrix with reference model
//--------------------------------------------------------------------------------------------
class axi4_throughput_ordering_longtail_throttled_write_test extends axi4_base_test;
  `uvm_component_utils(axi4_throughput_ordering_longtail_throttled_write_test)

  // Sequence handles
  axi4_master_one_to_many_fanout_seq fanout_seq;
  axi4_master_max_outstanding_seq max_outstanding_seq;
  axi4_slave_long_tail_latency_seq longtail_seq;
  axi4_master_read_reorder_seq reorder_seq;
  axi4_slave_write_response_throttling_seq throttle_seq;
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

  extern function new(string name = "axi4_throughput_ordering_longtail_throttled_write_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void configure_bus_matrix_mode();
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task run_phase1_fanout_outstanding(uvm_phase phase);
  extern virtual task run_phase2_longtail_reorder(uvm_phase phase);
  extern virtual task run_phase3_throttling(uvm_phase phase);
  extern virtual task run_phase4_cleanup(uvm_phase phase);
  
endclass : axi4_throughput_ordering_longtail_throttled_write_test

function axi4_throughput_ordering_longtail_throttled_write_test::new(string name = "axi4_throughput_ordering_longtail_throttled_write_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_throughput_ordering_longtail_throttled_write_test::build_phase(uvm_phase phase);
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
  `uvm_info(get_type_name(), "AXI4 THROUGHPUT ORDERING LONGTAIL THROTTLED WRITE TEST", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Bus Matrix Mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Masters: %0d, Slaves: %0d", num_masters, num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "Test Sequence per axi_stress_reset_test.md:", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-1: axi4_master_one_to_many_fanout_seq", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-2: axi4_master_max_outstanding_seq", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-3: [PARALLEL] axi4_slave_long_tail_latency_seq + axi4_master_read_reorder_seq", UVM_LOW)
  `uvm_info(get_type_name(), "  Phase-4: axi4_slave_write_response_throttling_seq", UVM_LOW)
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

function void axi4_throughput_ordering_longtail_throttled_write_test::configure_bus_matrix_mode();
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

task axi4_throughput_ordering_longtail_throttled_write_test::run_phase(uvm_phase phase);
  
  test_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("TEST STARTING at time %0t", test_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), "Focus: Throughput, ordering, long tail impact, write throttling", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  phase.raise_objection(this);
  
  // Run test phases sequentially with proper control
  fork
    begin
      // Main test sequence as per markdown specification
      run_phase1_fanout_outstanding(phase);     // Phase 1: fanout
      run_phase2_longtail_reorder(phase);       // Phase 2: max outstanding then parallel longtail+reorder
      run_phase3_throttling(phase);             // Phase 3: throttling
      run_phase4_cleanup(phase);                // Phase 4: cleanup
    end
    begin
      // Overall timeout watchdog - 400us total test time (increased for 3 modes)
      #400us;
      `uvm_warning(get_type_name(), $sformatf("TEST TIMEOUT at %0t - forcing completion (400us limit reached)", $time))
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
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

task axi4_throughput_ordering_longtail_throttled_write_test::run_phase1_fanout_outstanding(uvm_phase phase);
  
  phase1_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("PHASE 1 STARTING at %0t: One-to-Many Fanout", phase1_start_time), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Mode: %s", is_enhanced_mode ? "ENHANCED 10x10" : (is_4x4_ref_mode ? "4x4 REF" : "NONE")), UVM_LOW)
  `uvm_info(get_type_name(), "Sequence: axi4_master_one_to_many_fanout_seq", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  // Create and configure fanout sequence with mode-specific transactions
  fanout_seq = axi4_master_one_to_many_fanout_seq::type_id::create("fanout_seq");
  
  // Force write-only since using write sequencer
  fanout_seq.write_only_mode = 1;
  
  // Configure addressing mode based on bus matrix mode
  if (is_enhanced_mode) begin
    fanout_seq.use_bus_matrix_addressing = 2;  // Use 10x10 enhanced matrix addresses
    fanout_seq.transactions_per_slave = 6; // More transactions for 10x10
    fanout_seq.num_slaves = 10;  // All 10 slaves
  end else if (is_4x4_ref_mode) begin
    fanout_seq.use_bus_matrix_addressing = 1;  // Use 4x4 base matrix addresses
    fanout_seq.transactions_per_slave = 4; // Medium for 4x4 ref
    fanout_seq.num_slaves = 4;  // Only 4 slaves
  end else begin
    fanout_seq.use_bus_matrix_addressing = 0;  // Use default test addresses
    fanout_seq.transactions_per_slave = 2; // Fewer for NONE mode
    fanout_seq.num_slaves = 4;  // Only 4 slaves
  end
  
  `uvm_info(get_type_name(), $sformatf("Created fanout_seq with %0d transactions per slave (%s mode)", 
            fanout_seq.transactions_per_slave, is_enhanced_mode ? "ENHANCED" : (is_4x4_ref_mode ? "4x4_REF" : "NONE")), UVM_MEDIUM)
  
  fork
    begin
      `uvm_info(get_type_name(), $sformatf("[%0t] Starting axi4_master_one_to_many_fanout_seq on master 0", $time), UVM_HIGH)
      fanout_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
      sequences_completed++;
      `uvm_info(get_type_name(), $sformatf("[%0t] Completed axi4_master_one_to_many_fanout_seq (%0d sequences done)", 
                $time, sequences_completed), UVM_HIGH)
    end
    begin
      // Phase 1 timeout
      #50us;
      `uvm_info(get_type_name(), $sformatf("[%0t] Phase 1 fanout timeout reached", $time), UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase1_done = 1;
  phase1_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("PHASE 1 COMPLETED at %0t (Duration: %0t)", 
            phase1_end_time, phase1_end_time - phase1_start_time), UVM_LOW)
  
  // Small delay before next phase
  #2us;
  
endtask : run_phase1_fanout_outstanding

task axi4_throughput_ordering_longtail_throttled_write_test::run_phase2_longtail_reorder(uvm_phase phase);
  
  phase2_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("PHASE 2 STARTING at %0t: Max Outstanding + [PARALLEL] Long Tail + Reorder", phase2_start_time), UVM_LOW)
  `uvm_info(get_type_name(), "Step 1: axi4_master_max_outstanding_seq", UVM_LOW)
  `uvm_info(get_type_name(), "Step 2: [PARALLEL] axi4_slave_long_tail_latency_seq + axi4_master_read_reorder_seq", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  // Step 1: Run max outstanding sequence first
  max_outstanding_seq = axi4_master_max_outstanding_seq::type_id::create("max_outstanding_seq");
  if (is_enhanced_mode) begin
    max_outstanding_seq.use_bus_matrix_addressing = 2;  // Use 10x10 enhanced matrix addresses
    max_outstanding_seq.num_transactions = 40; // More for 10x10
  end else if (is_4x4_ref_mode) begin
    max_outstanding_seq.use_bus_matrix_addressing = 1;  // Use 4x4 base matrix addresses
    max_outstanding_seq.num_transactions = 25; // Medium for 4x4 ref
  end else begin
    max_outstanding_seq.use_bus_matrix_addressing = 0;  // Use default test addresses
    max_outstanding_seq.num_transactions = 15; // Fewer for NONE
  end
  
  `uvm_info(get_type_name(), $sformatf("Created max_outstanding_seq with %0d transactions (%s mode)", 
            max_outstanding_seq.num_transactions, is_enhanced_mode ? "ENHANCED" : (is_4x4_ref_mode ? "4x4_REF" : "NONE")), UVM_MEDIUM)
  
  fork
    begin
      `uvm_info(get_type_name(), $sformatf("[%0t] Starting axi4_master_max_outstanding_seq", $time), UVM_HIGH)
      max_outstanding_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
      sequences_completed++;
      `uvm_info(get_type_name(), $sformatf("[%0t] Completed axi4_master_max_outstanding_seq (%0d sequences done)", 
                $time, sequences_completed), UVM_HIGH)
    end
    begin
      // Max outstanding timeout
      #40us;
      `uvm_info(get_type_name(), $sformatf("[%0t] Max outstanding timeout reached", $time), UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  #2us; // Small delay between steps
  
  // Step 2: Run longtail and reorder sequences in parallel
  `uvm_info(get_type_name(), $sformatf("[%0t] Starting PARALLEL execution of longtail + reorder sequences", $time), UVM_LOW)
  
  // Create and configure sequences with mode-specific parameters
  longtail_seq = axi4_slave_long_tail_latency_seq::type_id::create("longtail_seq");
  if (is_enhanced_mode) begin
    longtail_seq.long_delay = 8000; // Higher delay for 10x10
  end else if (is_4x4_ref_mode) begin
    longtail_seq.long_delay = 5000; // Medium delay for 4x4 ref
  end else begin
    longtail_seq.long_delay = 2500; // Lower delay for NONE
  end
  
  reorder_seq = axi4_master_read_reorder_seq::type_id::create("reorder_seq");
  if (is_enhanced_mode) begin
    reorder_seq.use_bus_matrix_addressing = 2;  // Use 10x10 enhanced matrix addresses
    reorder_seq.num_transactions = 35; // More for 10x10
  end else if (is_4x4_ref_mode) begin
    reorder_seq.use_bus_matrix_addressing = 1;  // Use 4x4 base matrix addresses
    reorder_seq.num_transactions = 25; // Medium for 4x4 ref
  end else begin
    reorder_seq.use_bus_matrix_addressing = 0;  // Use default test addresses
    reorder_seq.num_transactions = 15; // Fewer for NONE
  end
  
  `uvm_info(get_type_name(), $sformatf("Created longtail_seq with %0d delay, reorder_seq with %0d transactions", 
            longtail_seq.long_delay, reorder_seq.num_transactions), UVM_MEDIUM)
  
  fork
    begin
      // Start both sequences in parallel as per markdown spec
      fork
        begin
          // Use different slaves to avoid conflicts: slave 1 for longtail_seq
          int longtail_slave_id = (num_slaves > 8) ? 8 : 1;  // slave 8 for 10x10, slave 1 for 4x4/NONE
          `uvm_info(get_type_name(), $sformatf("[%0t] Starting axi4_slave_long_tail_latency_seq on slave %0d", 
                    $time, longtail_slave_id), UVM_HIGH)
          longtail_seq.start(axi4_env_h.axi4_slave_agent_h[longtail_slave_id].axi4_slave_write_seqr_h);
          sequences_completed++;
          `uvm_info(get_type_name(), $sformatf("[%0t] Completed axi4_slave_long_tail_latency_seq (%0d sequences done)", 
                    $time, sequences_completed), UVM_HIGH)
        end
        begin
          `uvm_info(get_type_name(), $sformatf("[%0t] Starting axi4_master_read_reorder_seq on master 0", $time), UVM_HIGH)
          reorder_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_read_seqr_h);
          sequences_completed++;
          `uvm_info(get_type_name(), $sformatf("[%0t] Completed axi4_master_read_reorder_seq (%0d sequences done)", 
                    $time, sequences_completed), UVM_HIGH)
        end
      join
    end
    begin
      // Phase 2 parallel execution timeout
      #100us;
      `uvm_info(get_type_name(), $sformatf("[%0t] Phase 2 parallel execution timeout reached", $time), UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase2_done = 1;
  phase2_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("PHASE 2 COMPLETED at %0t (Duration: %0t)", 
            phase2_end_time, phase2_end_time - phase2_start_time), UVM_LOW)
  
  // Small delay before next phase
  #2us;
  
endtask : run_phase2_longtail_reorder

task axi4_throughput_ordering_longtail_throttled_write_test::run_phase3_throttling(uvm_phase phase);
  
  phase3_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("PHASE 3 STARTING at %0t: Write Response Throttling", phase3_start_time), UVM_LOW)
  `uvm_info(get_type_name(), "Sequence: axi4_slave_write_response_throttling_seq", UVM_LOW)
  `uvm_info(get_type_name(), "Focus: Write response congestion impact testing", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  // Create throttling sequence with mode-specific parameters
  throttle_seq = axi4_slave_write_response_throttling_seq::type_id::create("throttle_seq");
  if (is_enhanced_mode) begin
    throttle_seq.num_responses = 50; // More responses for 10x10
    throttle_seq.throttle_delay = 150; // Higher throttling delay
  end else if (is_4x4_ref_mode) begin
    throttle_seq.num_responses = 35; // Medium for 4x4 ref
    throttle_seq.throttle_delay = 120; // Medium throttling delay
  end else begin
    throttle_seq.num_responses = 20; // Fewer for NONE
    throttle_seq.throttle_delay = 100; // Lower throttling delay
  end
  
  `uvm_info(get_type_name(), $sformatf("Created throttle_seq with %0d responses, %0d throttle delay (%s mode)", 
            throttle_seq.num_responses, throttle_seq.throttle_delay, 
            is_enhanced_mode ? "ENHANCED" : (is_4x4_ref_mode ? "4x4_REF" : "NONE")), UVM_MEDIUM)
  
  fork
    begin
      // Use slave 0 for throttling_seq (different from longtail_seq)
      `uvm_info(get_type_name(), $sformatf("[%0t] Starting axi4_slave_write_response_throttling_seq on slave 0", $time), UVM_HIGH)
      throttle_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
      sequences_completed++;
      `uvm_info(get_type_name(), $sformatf("[%0t] Completed axi4_slave_write_response_throttling_seq (%0d sequences done)", 
                $time, sequences_completed), UVM_HIGH)
    end
    begin
      // Phase 3 timeout
      #60us;
      `uvm_info(get_type_name(), $sformatf("[%0t] Phase 3 throttling timeout reached", $time), UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase3_done = 1;
  phase3_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("PHASE 3 COMPLETED at %0t (Duration: %0t)", 
            phase3_end_time, phase3_end_time - phase3_start_time), UVM_LOW)
  
  // Small delay before next phase
  #2us;
  
endtask : run_phase3_throttling

task axi4_throughput_ordering_longtail_throttled_write_test::run_phase4_cleanup(uvm_phase phase);
  
  phase4_start_time = $time;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("PHASE 4 STARTING at %0t: Reset Smoke Cleanup", phase4_start_time), UVM_LOW)
  `uvm_info(get_type_name(), "Sequence: axi4_master_reset_smoke_seq", UVM_LOW)
  `uvm_info(get_type_name(), "Purpose: Final system cleanup and stability verification", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
  // Create and run cleanup sequence with mode-appropriate transactions
  smoke_seq = axi4_master_reset_smoke_seq::type_id::create("smoke_seq");
  
  // Configure addressing mode based on bus matrix mode
  if (is_enhanced_mode) begin
    smoke_seq.use_bus_matrix_addressing = 2;  // Use 10x10 enhanced matrix addresses
    smoke_seq.num_txns = 8; // More cleanup for 10x10
  end else if (is_4x4_ref_mode) begin
    smoke_seq.use_bus_matrix_addressing = 1;  // Use 4x4 base matrix addresses
    smoke_seq.num_txns = 6; // Medium cleanup for 4x4 ref
  end else begin
    smoke_seq.use_bus_matrix_addressing = 0;  // Use default test addresses
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
      // Phase 4 timeout
      #15us;
      `uvm_info(get_type_name(), $sformatf("[%0t] Phase 4 cleanup timeout reached", $time), UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase4_done = 1;
  phase4_end_time = $time;
  
  `uvm_info(get_type_name(), $sformatf("PHASE 4 COMPLETED at %0t (Duration: %0t)", 
            phase4_end_time, phase4_end_time - phase4_start_time), UVM_LOW)
  
  // Final cleanup delay
  #3us;
  
endtask : run_phase4_cleanup

`endif