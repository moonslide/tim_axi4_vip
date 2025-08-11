`ifndef AXI4_HOTSPOT_FAIRNESS_BOUNDARY_ERROR_RESET_BACKPRESSURE_TEST_INCLUDED_
`define AXI4_HOTSPOT_FAIRNESS_BOUNDARY_ERROR_RESET_BACKPRESSURE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_hotspot_fairness_boundary_error_reset_backpressure_test
// Test focusing on hotspot, fairness, boundary, error injection, and reset backpressure
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

  extern function new(string name = "axi4_hotspot_fairness_boundary_error_reset_backpressure_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_hotspot_fairness_boundary_error_reset_backpressure_test

function axi4_hotspot_fairness_boundary_error_reset_backpressure_test::new(string name = "axi4_hotspot_fairness_boundary_error_reset_backpressure_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task axi4_hotspot_fairness_boundary_error_reset_backpressure_test::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Starting hotspot_fairness_boundary_error_reset_backpressure test", UVM_LOW)
  
  phase.raise_objection(this);
  
  hotspot_seq = new[axi4_env_cfg_h.no_of_masters];
  
  // Step 1: Parallel hotspot and mixed burst lengths
  `uvm_info(get_type_name(), "Step 1: Parallel hotspot and mixed burst", UVM_MEDIUM)
  fork
    begin
      for(int m = 0; m < axi4_env_cfg_h.no_of_masters; m++) begin
        automatic int master_id = m;
        fork
          begin
            hotspot_seq[master_id] = axi4_master_hotspot_many_to_one_seq::type_id::create($sformatf("hotspot_seq_%0d", master_id));
            hotspot_seq[master_id].target_slave_id = 0;  // All target slave 0
            hotspot_seq[master_id].start(axi4_env_h.axi4_master_agent_h[master_id].axi4_master_write_seqr_h);
          end
        join_none
      end
    end
    begin
      mixed_burst_seq = axi4_master_mixed_burst_lengths_seq::type_id::create("mixed_burst_seq");
      mixed_burst_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
    end
  join
  
  // Step 2: Read-write contention
  `uvm_info(get_type_name(), "Step 2: Read-write contention", UVM_MEDIUM)
  contention_seq = axi4_master_read_write_contention_seq::type_id::create("contention_seq");
  contention_seq.target_slave = 3;
  contention_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
  
  // Step 3: 4KB boundary testing
  `uvm_info(get_type_name(), "Step 3: 4KB boundary testing", UVM_MEDIUM)
  boundary_seq = axi4_master_4kb_boundary_seq::type_id::create("boundary_seq");
  boundary_seq.test_illegal = 1;
  boundary_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
  
  // Step 4: Sparse error injection
  `uvm_info(get_type_name(), "Step 4: Sparse error injection", UVM_MEDIUM)
  error_seq = axi4_slave_sparse_error_injection_seq::type_id::create("error_seq");
  error_seq.error_rate = 2;
  error_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
  
  // Step 5: Reset backpressure
  `uvm_info(get_type_name(), "Step 5: Reset backpressure", UVM_MEDIUM)
  reset_backpressure_seq = axi4_slave_reset_backpressure_seq::type_id::create("reset_backpressure_seq");
  reset_backpressure_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
  
  #10us;
  
  `uvm_info(get_type_name(), "Completed hotspot_fairness_boundary_error_reset_backpressure test", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

`endif