`ifndef AXI4_QOS_BID_QUEUE_RACE_TEST_INCLUDED_
`define AXI4_QOS_BID_QUEUE_RACE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_bid_queue_race_test
//
// AXI_ooo.md F1 (Phase 1) directed repro.
//
// Reuses axi4_qos_equal_priority_fairness_test's configuration verbatim (all masters
// and all slaves in WRITE_READ_QOS_MODE_ENABLE, slaves in SLAVE_MEM_MODE) and only
// replaces the stimulus with a burst-length-skewed one, so the ONLY difference from
// a known-passing QoS test is the completion ORDER across master-slave pairs.
//
// What it proves: `awid_queue_for_qos` is a single package-scope queue
// (pkg/axi4_globals_pkg.sv:309) pushed by every master driver proxy and popped
// FRONT-first by every slave driver proxy at the BID assignment
// (slave/axi4_slave_driver_proxy.sv:422). Nothing ties an entry to the pair that
// pushed it, so as soon as completion order differs from push order a slave labels
// its write response with ANOTHER master's AWID.
//
// Run: ./simv +UVM_TESTNAME=axi4_qos_bid_queue_race_test +BUS_MATRIX_MODE=ENHANCED
//--------------------------------------------------------------------------------------------
class axi4_qos_bid_queue_race_test extends axi4_qos_equal_priority_fairness_test;
  `uvm_component_utils(axi4_qos_bid_queue_race_test)

  axi4_virtual_qos_bid_queue_race_seq axi4_virtual_qos_bid_queue_race_seq_h;

  extern function new(string name = "axi4_qos_bid_queue_race_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_qos_bid_queue_race_test

function axi4_qos_bid_queue_race_test::new(string name = "axi4_qos_bid_queue_race_test",
                                           uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task axi4_qos_bid_queue_race_test::run_phase(uvm_phase phase);

  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "  QOS SHARED BID-QUEUE RACE TEST STARTING", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)

  phase.raise_objection(this);

  axi4_virtual_qos_bid_queue_race_seq_h =
    axi4_virtual_qos_bid_queue_race_seq::type_id::create("axi4_virtual_qos_bid_queue_race_seq_h");
  axi4_virtual_qos_bid_queue_race_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);

  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "  QOS SHARED BID-QUEUE RACE TEST COMPLETED", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)

  phase.drop_objection(this);

endtask : run_phase

`endif
