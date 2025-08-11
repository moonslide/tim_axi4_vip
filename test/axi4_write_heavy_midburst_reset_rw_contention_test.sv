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
  
  // Test phase control
  bit phase1_done = 0;
  bit phase2_done = 0;
  bit phase3_done = 0;
  bit phase4_done = 0;
  bit phase5_done = 0;

  extern function new(string name = "axi4_write_heavy_midburst_reset_rw_contention_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
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

task axi4_write_heavy_midburst_reset_rw_contention_test::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), $sformatf("Starting write_heavy_midburst_reset_rw_contention test in %s mode", 
    is_enhanced_mode ? "ENHANCED" : "NONE"), UVM_LOW)
  
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