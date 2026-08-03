`ifndef AXI4_CROSS_ID_READ_REORDER_TEST_INCLUDED_
`define AXI4_CROSS_ID_READ_REORDER_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_cross_id_read_reorder_test
//
// Directed fail-then-pass test for codex_review.md Finding 5, read half.
//
// WHAT IT PROVOKES
//   Phase 1 (preload): 8 single-beat writes, one per 4KB page, each carrying a
//   different payload. Write responses stay IN ORDER here (only the read side is put
//   out of order), so the preload itself is deterministic.
//   Phase 2 (measure): 8 reads of those same 8 pages, each with a different ARID.
//   All 8 ARs are outstanding together (the driver returns from finish_item() at the
//   AR handshake), and the slave in ONLY_READ_RESP_OUT_OF_ORDER picks which burst to
//   answer next by shuffling its outstanding-ARID queue
//   (slave/axi4_slave_driver_proxy.sv:1754-1755). Legal AXI4: read data may be
//   returned out of order across different ARIDs.
//
// EXPECTED BEFORE THE FIX
//   The monitor took AR metadata from the head of an issue-order FIFO rather than
//   keying on RID, so a reordered burst was joined to another transaction's address
//   and expected data. Because every RID carries a different payload, that shows up
//   as a scoreboard read mismatch on legal traffic. UVM_ERROR > 0.
//
// EXPECTED AFTER THE FIX
//   RID-keyed join; UVM_ERROR : 0 with non-zero verified read counts.
//
// SCOPE LIMIT -- READ THIS BEFORE QUOTING THIS TEST AS EVIDENCE
//   This covers whole-burst read REORDER. It does NOT cover beat-level R INTERLEAVE
//   (different RIDs alternating beat by beat on the bus), because this VIP's slave
//   cannot produce it: the out-of-order read branch drives a whole burst atomically
//   in one loop (agent/slave_agent_bfm/axi4_slave_driver_bfm.sv:884-925) while the
//   proxy holds a single-key semaphore. So the per-RID beat accumulator half of the
//   Finding 5 fix is NOT exercised here. Producing that needs either an interleave
//   knob in the slave BFM or an interconnect DUT that interleaves.
//
// HOW TO CONFIRM THE CORNER WAS ACTUALLY HIT:
//   the "CROSS_ID_READ issue" order in the log must differ from the order the RIDs
//   complete in. Same order => the slave did not reorder and the run proves nothing;
//   rerun with another +ntb_random_seed.
//--------------------------------------------------------------------------------------------
class axi4_cross_id_read_reorder_test extends axi4_base_test;
  `uvm_component_utils(axi4_cross_id_read_reorder_test)

  axi4_master_cross_id_write_reorder_seq preload_seq_h;
  axi4_master_cross_id_read_reorder_seq  cross_id_read_seq_h;

  int unsigned num_ids = 8;

  // Drain between the preload writes and the reads, so the pages are committed in
  // the slave memory before they are read back.
  time preload_drain_time = 10us;

  // Drain after the reads, so every reordered R burst is scored before the
  // objection drops (end-of-test drain race).
  time resp_drain_time = 10us;

  function new(string name = "axi4_cross_id_read_reorder_test", uvm_component parent = null);
    super.new(name, parent);
    // See the write-side test: test-scoped watchdog bound, ~100x expected runtime.
    test_timeout = 500us;
  endfunction : new

  virtual function void setup_axi4_slave_agent_cfg();
    super.setup_axi4_slave_agent_cfg();
    foreach (axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
      // Only the READ side is reordered: the preload writes stay in order.
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_response_mode = ONLY_READ_RESP_OUT_OF_ORDER;
      // See the write-side test: uvm_tlm_fifo::size() is the capacity, not the
      // occupancy, so a non-zero minimum_transactions never releases.
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].set_minimum_transactions(0);
    end
  endfunction : setup_axi4_slave_agent_cfg

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    fork
      timeout_watchdog();
    join_none

    `uvm_info(get_type_name(),
              $sformatf("CROSS-ID READ REORDER phase 1/2: preloading %0d pages, one payload per ID",
                        num_ids), UVM_LOW)
    preload_seq_h = axi4_master_cross_id_write_reorder_seq::type_id::create("preload_seq_h");
    preload_seq_h.num_ids = num_ids;
    preload_seq_h.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h_all[0]);
    #(preload_drain_time);

    `uvm_info(get_type_name(),
              $sformatf("CROSS-ID READ REORDER phase 2/2: %0d outstanding reads, distinct ARID/address/payload each",
                        num_ids), UVM_LOW)
    cross_id_read_seq_h = axi4_master_cross_id_read_reorder_seq::type_id::create("cross_id_read_seq_h");
    cross_id_read_seq_h.num_ids = num_ids;
    cross_id_read_seq_h.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_read_seqr_h_all[0]);

    #(resp_drain_time);

    phase.drop_objection(this);
  endtask : run_phase

endclass : axi4_cross_id_read_reorder_test

`endif
