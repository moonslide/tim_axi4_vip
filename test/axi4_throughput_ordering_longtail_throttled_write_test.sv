`ifndef AXI4_THROUGHPUT_ORDERING_LONGTAIL_THROTTLED_WRITE_TEST_INCLUDED_
`define AXI4_THROUGHPUT_ORDERING_LONGTAIL_THROTTLED_WRITE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_throughput_ordering_longtail_throttled_write_test
// Test focusing on throughput, ordering, long tail latency, and write throttling
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

  extern function new(string name = "axi4_throughput_ordering_longtail_throttled_write_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_throughput_ordering_longtail_throttled_write_test

function axi4_throughput_ordering_longtail_throttled_write_test::new(string name = "axi4_throughput_ordering_longtail_throttled_write_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task axi4_throughput_ordering_longtail_throttled_write_test::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Starting throughput_ordering_longtail_throttled_write test", UVM_LOW)
  
  phase.raise_objection(this);
  
  // Sequential execution as per test plan
  
  // Step 1: One-to-many fanout
  `uvm_info(get_type_name(), "Step 1: One-to-many fanout", UVM_MEDIUM)
  fanout_seq = axi4_master_one_to_many_fanout_seq::type_id::create("fanout_seq");
  fanout_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
  
  // Step 2: Max outstanding
  `uvm_info(get_type_name(), "Step 2: Max outstanding", UVM_MEDIUM)
  max_outstanding_seq = axi4_master_max_outstanding_seq::type_id::create("max_outstanding_seq");
  max_outstanding_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
  
  // Step 3: Parallel long tail latency and read reorder
  `uvm_info(get_type_name(), "Step 3: Long tail latency and read reorder", UVM_MEDIUM)
  fork
    begin
      longtail_seq = axi4_slave_long_tail_latency_seq::type_id::create("longtail_seq");
      longtail_seq.start(axi4_env_h.axi4_slave_agent_h[8].axi4_slave_write_seqr_h);
    end
    begin
      reorder_seq = axi4_master_read_reorder_seq::type_id::create("reorder_seq");
      reorder_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_read_seqr_h);
    end
  join
  
  // Step 4: Write response throttling
  `uvm_info(get_type_name(), "Step 4: Write response throttling", UVM_MEDIUM)
  throttle_seq = axi4_slave_write_response_throttling_seq::type_id::create("throttle_seq");
  throttle_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
  
  // Step 5: Reset smoke cleanup
  `uvm_info(get_type_name(), "Step 5: Reset smoke cleanup", UVM_MEDIUM)
  smoke_seq = axi4_master_reset_smoke_seq::type_id::create("smoke_seq");
  smoke_seq.num_txns = 5;
  smoke_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
  
  #10us;
  
  `uvm_info(get_type_name(), "Completed throughput_ordering_longtail_throttled_write test", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

`endif