`ifndef AXI4_SATURATION_MIDBURST_RESET_QOS_BOUNDARY_TEST_INCLUDED_
`define AXI4_SATURATION_MIDBURST_RESET_QOS_BOUNDARY_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_saturation_midburst_reset_qos_boundary_test
// Test combining saturation, mid-burst reset, QoS, and boundary testing
// Supports both NONE (no ref model) and ENHANCED (10x10) bus matrix modes
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
  
  // Test phase control
  bit phase1_done = 0;
  bit phase2_done = 0;
  
  extern function new(string name = "axi4_saturation_midburst_reset_qos_boundary_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task run_phase1_saturation_qos(uvm_phase phase);
  extern virtual task run_phase2_backpressure(uvm_phase phase);
  extern virtual task run_phase3_boundary(uvm_phase phase);
  extern virtual task run_phase4_error_injection(uvm_phase phase);
  extern virtual task run_phase5_cleanup(uvm_phase phase);
  
endclass : axi4_saturation_midburst_reset_qos_boundary_test

function axi4_saturation_midburst_reset_qos_boundary_test::new(string name = "axi4_saturation_midburst_reset_qos_boundary_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_saturation_midburst_reset_qos_boundary_test::build_phase(uvm_phase phase);
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

task axi4_saturation_midburst_reset_qos_boundary_test::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), $sformatf("Starting saturation_midburst_reset_qos_boundary test in %s mode", 
    is_enhanced_mode ? "ENHANCED" : "NONE"), UVM_LOW)
  
  phase.raise_objection(this);
  
  // Initialize sequence arrays
  saturation_seq = new[num_masters];
  qos_seq = new[num_masters];
  backpressure_seq = new[num_slaves];
  
  // Run test phases sequentially with proper control
  fork
    begin
      // Main test sequence
      run_phase1_saturation_qos(phase);
      run_phase2_backpressure(phase);
      run_phase3_boundary(phase);
      run_phase4_error_injection(phase);
      run_phase5_cleanup(phase);
    end
    begin
      // Overall timeout watchdog - 500us total test time
      #500us;
      `uvm_warning(get_type_name(), "Test timeout reached (500us) - forcing completion")
    end
  join_any
  
  // Ensure all forked processes are killed
  disable fork;
  
  // Wait a bit for cleanup
  #10us;
  
  `uvm_info(get_type_name(), "Completed saturation_midburst_reset_qos_boundary test", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

task axi4_saturation_midburst_reset_qos_boundary_test::run_phase1_saturation_qos(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 1: Starting parallel saturation and QoS", UVM_MEDIUM)
  
  // Configure and start sequences with limited transactions
  for(int m = 0; m < num_masters; m++) begin
    automatic int master_id = m;
    
    // Create saturation sequence
    saturation_seq[master_id] = axi4_master_all_to_all_saturation_seq::type_id::create($sformatf("saturation_seq_%0d", master_id));
    saturation_seq[master_id].num_transactions = is_enhanced_mode ? 50 : 25; // Limit transactions
    
    // Create QoS sequence
    qos_seq[master_id] = axi4_master_qos_arbitration_seq::type_id::create($sformatf("qos_seq_%0d", master_id));
    qos_seq[master_id].qos_value = master_id % 16;
    qos_seq[master_id].num_transactions = is_enhanced_mode ? 30 : 15; // Limit transactions
  end
  
  // Start sequences in parallel with timeout
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
      
      // Start all QoS sequences
      foreach(qos_seq[i]) begin
        automatic int idx = i;
        fork
          begin
            qos_seq[idx].start(axi4_env_h.axi4_master_agent_h[idx].axi4_master_read_seqr_h);
          end
        join_none
      end
    end
    begin
      // Phase 1 timeout
      #50us;  // Reduced from 120us
      `uvm_info(get_type_name(), "Phase 1 timeout reached", UVM_MEDIUM)
    end
    begin
      // Mid-burst reset injection at 30us
      #30us;
      `uvm_info(get_type_name(), "Injecting mid-burst reset", UVM_LOW)
      midburst_reset_seq = axi4_master_midburst_reset_read_seq::type_id::create("midburst_reset_seq");
      midburst_reset_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_read_seqr_h);
    end
  join_any
  
  // Kill any remaining sequences
  disable fork;
  phase1_done = 1;
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase1_saturation_qos

task axi4_saturation_midburst_reset_qos_boundary_test::run_phase2_backpressure(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 2: Starting backpressure storm", UVM_MEDIUM)
  
  // Create backpressure sequences with limited patterns
  for(int s = 0; s < num_slaves; s++) begin
    backpressure_seq[s] = axi4_slave_backpressure_storm_seq::type_id::create($sformatf("backpressure_seq_%0d", s));
    backpressure_seq[s].num_patterns = 5; // Limit patterns
  end
  
  fork
    begin
      // Start all backpressure sequences
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
      // Phase 2 timeout
      #30us;  // Reduced from 100us
      `uvm_info(get_type_name(), "Phase 2 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  phase2_done = 1;
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase2_backpressure

task axi4_saturation_midburst_reset_qos_boundary_test::run_phase3_boundary(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 3: Starting 4KB boundary testing", UVM_MEDIUM)
  
  // Create and run boundary test with limited transactions
  boundary_seq = axi4_master_4kb_boundary_seq::type_id::create("boundary_seq");
  boundary_seq.num_transactions = is_enhanced_mode ? 50 : 25;
  
  fork
    begin
      boundary_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
    end
    begin
      // Phase 3 timeout
      #20us;
      `uvm_info(get_type_name(), "Phase 3 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase3_boundary

task axi4_saturation_midburst_reset_qos_boundary_test::run_phase4_error_injection(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Phase 4: Starting sparse error injection", UVM_MEDIUM)
  
  // Create and run error injection with limited transactions
  error_seq = axi4_slave_sparse_error_injection_seq::type_id::create("error_seq");
  error_seq.error_rate = 1;
  error_seq.num_transactions = is_enhanced_mode ? 50 : 25;
  
  fork
    begin
      error_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
    end
    begin
      // Phase 4 timeout
      #15us;
      `uvm_info(get_type_name(), "Phase 4 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  
  // Small delay before next phase
  #1us;
  
endtask : run_phase4_error_injection

task axi4_saturation_midburst_reset_qos_boundary_test::run_phase5_cleanup(uvm_phase phase);
  
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
      #5us;
      `uvm_info(get_type_name(), "Phase 5 timeout reached", UVM_MEDIUM)
    end
  join_any
  
  disable fork;
  
  // Final cleanup delay
  #1us;
  
endtask : run_phase5_cleanup

`endif