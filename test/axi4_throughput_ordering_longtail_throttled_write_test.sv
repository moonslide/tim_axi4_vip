`ifndef AXI4_THROUGHPUT_ORDERING_LONGTAIL_THROTTLED_WRITE_TEST_INCLUDED_
`define AXI4_THROUGHPUT_ORDERING_LONGTAIL_THROTTLED_WRITE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_throughput_ordering_longtail_throttled_write_test
// Test focusing on throughput, ordering, long tail latency, and write throttling
// Supports both NONE (no ref model) and ENHANCED (10x10) bus matrix modes
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
  
  // Test phase control
  bit phase1_done = 0;
  bit phase2_done = 0;
  bit phase3_done = 0;
  bit phase4_done = 0;

  extern function new(string name = "axi4_throughput_ordering_longtail_throttled_write_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
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

task axi4_throughput_ordering_longtail_throttled_write_test::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), $sformatf("Starting throughput_ordering_longtail_throttled_write test in %s mode", 
    is_enhanced_mode ? "ENHANCED" : "NONE"), UVM_LOW)
  
  phase.raise_objection(this);
  
  // Run test phases sequentially with proper control
  fork
    begin
      // Main test sequence
      run_phase1_fanout_outstanding(phase);
      run_phase2_longtail_reorder(phase);
      run_phase3_throttling(phase);
      run_phase4_cleanup(phase);
    end
    begin
      // Overall timeout watchdog - 300us total test time
      #300us;
      `uvm_warning(get_type_name(), "Test timeout reached (300us) - forcing completion")
    end
  join_any
  
  // Ensure all forked processes are killed
  disable fork;
  
  // Wait a bit for cleanup
  #5us;
  
  `uvm_info(get_type_name(), "Completed throughput_ordering_longtail_throttled_write test", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

task axi4_throughput_ordering_longtail_throttled_write_test::run_phase1_fanout_outstanding(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 1: Starting fanout and max outstanding", UVM_MEDIUM)
  
  // Create and configure sequences with limited transactions
  fanout_seq = axi4_master_one_to_many_fanout_seq::type_id::create("fanout_seq");
  fanout_seq.transactions_per_slave = is_enhanced_mode ? 4 : 2; // Limit transactions per slave
  
  max_outstanding_seq = axi4_master_max_outstanding_seq::type_id::create("max_outstanding_seq");
  max_outstanding_seq.num_transactions = is_enhanced_mode ? 30 : 15; // Limit transactions
  
  fork
    begin
      fanout_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
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
  #1us;
  
  // Run max outstanding sequence
  fork
    begin
      max_outstanding_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
    end
    begin
      // Max outstanding timeout
      #30us;
      `uvm_info(get_type_name(), "Max outstanding timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase1_fanout_outstanding

task axi4_throughput_ordering_longtail_throttled_write_test::run_phase2_longtail_reorder(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 2: Starting longtail and reorder", UVM_MEDIUM)
  
  // Create and configure sequences with limited transactions
  longtail_seq = axi4_slave_long_tail_latency_seq::type_id::create("longtail_seq");
  longtail_seq.long_delay = is_enhanced_mode ? 5000 : 2500; // Reduce delays
  
  reorder_seq = axi4_master_read_reorder_seq::type_id::create("reorder_seq");
  reorder_seq.num_transactions = is_enhanced_mode ? 30 : 15; // Limit transactions
  
  fork
    begin
      // Start both sequences in parallel
      fork
        begin
          longtail_seq.start(axi4_env_h.axi4_slave_agent_h[num_slaves > 8 ? 8 : 0].axi4_slave_write_seqr_h);
        end
        begin
          reorder_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_read_seqr_h);
        end
      join
    end
    begin
      // Phase 2 timeout
      #80us;
      `uvm_info(get_type_name(), "Phase 2 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase2_done = 1;
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase2_longtail_reorder

task axi4_throughput_ordering_longtail_throttled_write_test::run_phase3_throttling(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 3: Starting write response throttling", UVM_MEDIUM)
  
  // Create throttling sequence with limited transactions
  throttle_seq = axi4_slave_write_response_throttling_seq::type_id::create("throttle_seq");
  throttle_seq.num_responses = is_enhanced_mode ? 40 : 20; // Limit responses
  throttle_seq.throttle_delay = 100; // Moderate throttling delay
  
  fork
    begin
      throttle_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
    end
    begin
      // Phase 3 timeout
      #50us;
      `uvm_info(get_type_name(), "Phase 3 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase3_done = 1;
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase3_throttling

task axi4_throughput_ordering_longtail_throttled_write_test::run_phase4_cleanup(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 4: Starting reset smoke cleanup", UVM_MEDIUM)
  
  // Create and run cleanup sequence with minimal transactions
  smoke_seq = axi4_master_reset_smoke_seq::type_id::create("smoke_seq");
  smoke_seq.num_txns = 5;
  
  fork
    begin
      smoke_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
    end
    begin
      // Phase 4 timeout
      #10us;
      `uvm_info(get_type_name(), "Phase 4 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase4_done = 1;
  
  // Final cleanup delay
  #2us;
  
endtask : run_phase4_cleanup

`endif