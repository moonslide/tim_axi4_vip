`ifndef AXI4_CROSS_ID_WRITE_REORDER_TEST_INCLUDED_
`define AXI4_CROSS_ID_WRITE_REORDER_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_cross_id_write_reorder_test
//
// Directed fail-then-pass test for codex_review.md Finding 5, write half:
// "monitor cannot correlate a legal cross-ID response reorder".
//
// WHAT IT PROVOKES
//   One master issues 8 single-beat writes back to back, each with a different AWID,
//   a different address (one 4KB page per ID) and a DIFFERENT payload. The slave is
//   put in ONLY_WRITE_RESP_OUT_OF_ORDER, so it returns the 8 B responses in a random
//   permutation of the issue order (slave/axi4_slave_driver_proxy.sv:620-621 shuffles
//   the outstanding-AWID queue). Legal AXI4 traffic: reordering across DIFFERENT IDs
//   is explicitly permitted; only same-ID responses must stay in order, and the slave
//   keeps those in order via its response_id_cont_queue.
//
// EXPECTED BEFORE THE FIX
//   The master monitor proxy took the AW/W metadata for a B response from the head of
//   an issue-order FIFO instead of keying on BID. With the responses permuted, each B
//   is joined to some other transaction's address and data, so the scoreboard's write
//   comparisons report mismatches on traffic that is perfectly legal, and/or the
//   "bid returned to the WRONG manager" accounting fires. UVM_ERROR > 0.
//
// EXPECTED AFTER THE FIX
//   The join is keyed by BID, every response lands on its own transaction, and the
//   run ends UVM_ERROR : 0 with non-zero verified counts on all write channels.
//
// WHY THE PAYLOADS DIFFER PER ID
//   With identical payloads a wrong join still compares equal, so the swapped-routing
//   half of the bug -- the dangerous half -- would pass silently. See the sequence.
//
// HOW TO CONFIRM THE CORNER WAS ACTUALLY HIT (do not trust a green run alone):
//   the CROSS_ID_WRITE issue order in the log must differ from the BID completion
//   order; grep "CROSS_ID_WRITE issue" and the scoreboard's write-response records.
//   If they are in the same order the slave did not reorder and the test proved
//   nothing -- rerun with a different +ntb_random_seed.
//--------------------------------------------------------------------------------------------
class axi4_cross_id_write_reorder_test extends axi4_base_test;
  `uvm_component_utils(axi4_cross_id_write_reorder_test)

  axi4_master_cross_id_write_reorder_seq cross_id_write_seq_h;

  // How many distinct AWIDs are kept outstanding. 8 makes an accidental
  // identity permutation a 1-in-40320 event.
  int unsigned num_ids = 8;

  // Response drain window before the objection drops. Measured reference: the
  // Track-B smoke test completes 10 writes + 10 reads through a REAL fabric
  // within ~1.1us of stimulus (/tmp/g10_axi4_trackb_smoke_test.log), so 10us is
  // ample for 8 single-beat writes against a directly wired reactive slave.
  // Without this the objection would drop at the last AW handshake -- responses
  // are still in flight there, and a mismatch would vanish into the drain race.
  time resp_drain_time = 10us;

  function new(string name = "axi4_cross_id_write_reorder_test", uvm_component parent = null);
    super.new(name, parent);
    // Test-scoped bound for the base watchdog (codex_review.md Finding 8):
    // ~100x the expected runtime, so a hang in the outstanding/reorder path
    // ends as a UVM verdict with test context instead of an external kill.
    test_timeout = 500us;
  endfunction : new

  virtual function void setup_axi4_slave_agent_cfg();
    super.setup_axi4_slave_agent_cfg();
    foreach (axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
      // Reactive memory slave: it answers what the master drives, and holds the
      // written payload so the read-side companion test can read it back.
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
      // THE knob under test: B responses come back in a random permutation.
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_response_mode = ONLY_WRITE_RESP_OUT_OF_ORDER;
      // Required with the out-of-order modes. The response path otherwise waits
      // on `axi4_slave_write_data_out_fifo_h.size > minimum_transactions`, and
      // uvm_tlm_fifo::size() returns the CAPACITY (16), not the occupancy, so the
      // wait can never be satisfied and every response spins to its timeout.
      // Same reason the pre-existing out-of-order tests set it to 0.
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].set_minimum_transactions(0);
    end
  endfunction : setup_axi4_slave_agent_cfg

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    fork
      timeout_watchdog();
    join_none

    `uvm_info(get_type_name(),
              $sformatf("CROSS-ID WRITE REORDER: %0d outstanding writes, distinct AWID/address/payload each",
                        num_ids), UVM_LOW)

    cross_id_write_seq_h = axi4_master_cross_id_write_reorder_seq::type_id::create("cross_id_write_seq_h");
    cross_id_write_seq_h.num_ids = num_ids;
    cross_id_write_seq_h.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h_all[0]);

    // Let every reordered B response arrive and be scored before ending.
    #(resp_drain_time);

    phase.drop_objection(this);
  endtask : run_phase

endclass : axi4_cross_id_write_reorder_test

`endif
