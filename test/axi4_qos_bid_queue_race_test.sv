`ifndef AXI4_QOS_BID_QUEUE_RACE_TEST_INCLUDED_
`define AXI4_QOS_BID_QUEUE_RACE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_bid_queue_race_test
//
// AXI_ooo.md F1 (Phase 1) directed repro.
//
// Reuses axi4_qos_equal_priority_fairness_test's configuration verbatim (inherited via
// `extends`: all masters in WRITE_READ_QOS_MODE_ENABLE; all slaves in
// WRITE_READ_QOS_MODE_ENABLE and SLAVE_MEM_MODE) and only replaces the stimulus with a
// burst-length-skewed one, so the ONLY difference from a known-passing QoS test is the
// completion ORDER across master-slave pairs.
// Track-B (`ifdef BUS_MATRIX_FABRIC_IP): the inherited setup_axi4_slave_agent_cfg puts
// the slaves in ONLY_WRITE_QOS_MODE_ENABLE instead (read-side QoS mode OFF; see the
// parent's comment). This test's masters issue no reads, so that read-QoS path is unused.
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
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_qos_bid_queue_race_test

function axi4_qos_bid_queue_race_test::new(string name = "axi4_qos_bid_queue_race_test",
                                           uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Parent configuration verbatim (on Track-B that includes the parent's slave
// ONLY_WRITE_QOS_MODE_ENABLE override); only adds the Track-B scoreboard settings,
// set here rather than in axi4_qos_equal_priority_fairness_test so the parent
// is untouched.
//--------------------------------------------------------------------------------------------
function void axi4_qos_bid_queue_race_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
`ifdef BUS_MATRIX_FABRIC_IP
  // Track-B (commercial fabric IP in the path). Ledger: see
  // .claude/docs/error-records/20261020-trackb-user-qos-routing-sb-pairing-proposal.md §3
  axi4_env_cfg_h.sb_keyed_pairing             = 1;   // arbiter reorders; positional pairing invalid
  axi4_env_cfg_h.axid_passthrough_chk_cfg     = 0;   // fabric re-encodes AxID (landmine 12a/27); replaced by sb_outstanding_a?id + validate_response_correctness
  axi4_env_cfg_h.axqos_passthrough_chk_cfg    = 0;   // ARQOS: EXPECTED DIFFERENCE, fabric has no egress QoS ports (hdl_top ties 0); AWQOS is never compared
  axi4_env_cfg_h.axregion_passthrough_chk_cfg = 1;   // ARREGION only (measured forwarded by this fabric); AWREGION is never compared
  axi4_env_cfg_h.axuser_passthrough_chk_cfg   = 1;   // measured forwarded by this fabric
  axi4_env_cfg_h.sb_pair_awuser_id_mask       = '0;  // masters target different slave bases; AxUSER=0 carries no identity
  axi4_env_cfg_h.sb_pair_aruser_id_mask       = '0;  // masters target different slave bases; AxUSER=0 carries no identity
  `uvm_info(get_type_name(), "Track-B scoreboard ledger: keyed=1 axid=OFF(re-encoded) arqos=OFF(not forwarded; no QoS behaviour is verified on Track-B) awqos=never-compared arregion=ON(0 comparisons: this test issues no reads) awregion=never-compared axuser=ON(weak: stimulus AxUSER=0) awuser_id_mask=0 aruser_id_mask=0 slave_read_qos=OFF(inherited: slaves ONLY_WRITE_QOS_MODE_ENABLE; unused, this test issues no reads)", UVM_LOW)
`endif
endfunction : build_phase

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
