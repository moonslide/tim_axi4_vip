`ifndef AXI4_SAME_ID_NONADJACENT_REORDER_TEST_INCLUDED_
`define AXI4_SAME_ID_NONADJACENT_REORDER_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_same_id_nonadjacent_reorder_test
//
// AXI_ooo.md Phase 0 / P0.2 -- reproduction test for Finding F2:
// "same-ID responses stay in order" only holds for ADJACENT same-ID transactions;
// NON-ADJACENT same-ID transactions can be reordered by the VIP's own slave driver.
//
// WHAT IT PROVOKES
//   Phase 1 (preload): one single-beat write per SLOT, each to its own 4KB page with
//   its own payload. Distinct AWIDs, write responses in order -- deterministic.
//   Phase 2 (measure): reads of those same pages with the ARID pattern
//   A,B,A,C,A,D repeating (axi4_master_same_id_nonadjacent_preload_seq::id_for_slot).
//   Id A repeats but is NEVER adjacent to itself, which is precisely the case the
//   slave's tail-only same-ID detection misses:
//       slave/axi4_slave_driver_proxy.sv:806-807  arid == rd_response_id_queue[$]
//   Both A entries therefore share the shuffled queue
//       slave/axi4_slave_driver_proxy.sv:1782-1783  shuffle(); pop_front()
//   and the later A's read data can be returned before the earlier A's.
//
// READ SIDE ONLY, DELIBERATELY
//   The write path has the same tail-compare defect (`:276`) but ALSO carries F1's
//   unfixed empty-queue pop_front(). Reproducing F2 on the write side would conflate
//   two bugs, so this test uses ONLY_READ_RESP_OUT_OF_ORDER and leaves the write half
//   in order. A write-side twin belongs after Phase 1 lands.
//
// BACKLOG TUNING
//   set_minimum_transactions(2) makes the read response path wait (bounded, best
//   effort) until more than 2 reads are outstanding before answering
//   (slave/axi4_slave_driver_proxy.sv:1771-1775), so shuffle() has a real backlog to
//   reorder. The sibling cross-ID tests use 0 because they only need SOME reorder
//   across 8 distinct ids; here the interesting pair is 2 slots apart and a shallow
//   backlog would answer them in order by default.
//
// WHO CHECKS IT
//   env/axi4_scoreboard.sv's same-ID response-order checker (AXI_ooo.md Phase 3,
//   landed 2026-08-05), reporting under SB_SAMEID_ORDER_VIOLATION. This test used to
//   carry its own provisional uvm_subscriber probe because no such checker existed;
//   the probe was deleted when the scoreboard checker landed, after both were run on
//   the same seed and shown to convict the same reorders (see AXI_ooo.md Phase 3).
//   UPDATE 2026-08-05 (Phase 3 rework): the checker was default-OFF for part of that
//   day after adversarial review found a false-positive route in its address-keyed
//   write shadow; the rework re-keyed the shadow (owner port, write time, memory-model
//   window, payload survivability) and it is DEFAULT-ON again, so this test carries no
//   local re-enable any more -- only the SLAVE_MEM_MODE the CONTENT mechanism needs.
//   IT IS STILL THE ONLY PLACE F2 IS CONVICTABLE, for a reason that is now about the
//   BENCH and not the checker: the subordinate's memory model aligns every access to
//   DATA_WIDTH/8 and overwrites the whole word from a single-byte store
//   (AXI_data_integrity.md F8), so CONTENT only has usable ground truth where a test
//   arranges byte-replicated payloads on widely separated pages -- which this
//   sequence deliberately does and no other test does. Measured across a 50-test
//   sample: content_adjudicated=0 everywhere else. Do not read "the checker is on" as
//   "any test would catch this"; read the per-run summary line.
//
// EXPECTED BEFORE THE FIX (Phase 2 of AXI_ooo.md, blocked on decision D1)
//   UVM_ERROR > 0 from SB_SAMEID_ORDER_VIOLATION, and a non-zero "violations=" count
//   on the scoreboard's end-of-test "same-ID response order:" summary line.
//
// EXPECTED AFTER THE FIX
//   UVM_ERROR : 0 and "violations=0" on that summary line with a non-zero "checked=".
//
// HOW TO CONFIRM THE CORNER WAS ACTUALLY HIT (and what a green run does NOT prove
// before the fix): reordering is statistical -- rd_response_id_queue.shuffle() can
// return issue order. A run with 0 violations is only meaningful once Phase 2 has
// landed; before then, rerun with another +ntb_random_seed. Record the seed with any
// result quoted as evidence.
//--------------------------------------------------------------------------------------------
class axi4_same_id_nonadjacent_reorder_test extends axi4_base_test;
  `uvm_component_utils(axi4_same_id_nonadjacent_reorder_test)

  axi4_master_same_id_nonadjacent_preload_seq preload_seq_h;
  axi4_master_same_id_nonadjacent_read_seq    same_id_read_seq_h;

  // 6 slots per round (A,B,A,C,A,D) => 3 occurrences of the repeated id per round.
  int unsigned num_rounds = 4;

  // Drain between the preload writes and the reads, so the pages are committed.
  // Measured: the 24 preload writes are all issued and answered inside ~10ns, so 2us
  // is ~200x margin. Kept small on purpose -- idle clocking dominates wall time in
  // this bench (~2.2us of simulated time per wall minute at UVM_LOW).
  time preload_drain_time = 2us;

  // Drain after the reads, so every reordered R burst is observed before the
  // objection drops.
  time resp_drain_time = 4us;

  function new(string name = "axi4_same_id_nonadjacent_reorder_test", uvm_component parent = null);
    super.new(name, parent);
    // Test-scoped watchdog bound, ~100x expected runtime (same convention as the
    // cross-ID reorder tests).
    test_timeout = 2ms;
  endfunction : new

  virtual function void setup_axi4_slave_agent_cfg();
    // CONTROL EXPERIMENT. +SAMEID_INORDER_CONTROL leaves the slave in RESP_IN_ORDER,
    // i.e. same stimulus, same checker, no shuffling. It must report violations=0.
    // That is what separates "the checker found a real reorder" from "the checker
    // mis-attributes", and it is the only green reference available before the
    // Phase 2 fix exists.
    bit inorder_control = $test$plusargs("SAMEID_INORDER_CONTROL");

    super.setup_axi4_slave_agent_cfg();

    // The scoreboard's same-ID order checker is back ON repo-wide since the
    // AXI_ooo.md Phase 3 rework (env/axi4_env_config.sv::
    // sb_sameid_order_check_enable = 1), so this test no longer needs a local
    // re-enable -- it just needs SLAVE_MEM_MODE below, which the checker's
    // CONTENT mechanism requires. +SAMEID_NO_ORDER_CHECK is kept as an
    // A/B switch for the checker itself: it is the "green with the checker
    // muted" reference that shows F2 is invisible without it.
    if($test$plusargs("SAMEID_NO_ORDER_CHECK"))
      axi4_env_cfg_h.sb_sameid_order_check_enable = 0;
    foreach (axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
      // Only the READ side is reordered; the preload writes stay in order so the
      // unrelated F1 write-path defect cannot contaminate the verdict.
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_response_mode =
        inorder_control ? RESP_IN_ORDER : ONLY_READ_RESP_OUT_OF_ORDER;
      // Build a backlog before answering, so shuffle() has something to reorder.
      // The read-side gate that consumes this polls the queue actually popped and is
      // bounded at 50 clocks (slave/axi4_slave_driver_proxy.sv:1771-1775), so a
      // non-zero value here cannot hang the R channel.
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].set_minimum_transactions(2);
    end
  endfunction : setup_axi4_slave_agent_cfg

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    fork
      timeout_watchdog();
    join_none

    `uvm_info(get_type_name(),
              $sformatf("SAME-ID NON-ADJACENT REORDER phase 1/2: preloading %0d pages, one payload per SLOT",
                        axi4_master_same_id_nonadjacent_preload_seq::slots_for_rounds(num_rounds)),
              UVM_LOW)
    preload_seq_h = axi4_master_same_id_nonadjacent_preload_seq::type_id::create("preload_seq_h");
    preload_seq_h.num_rounds = num_rounds;
    preload_seq_h.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h_all[0]);
    #(preload_drain_time);

    `uvm_info(get_type_name(),
              $sformatf("SAME-ID NON-ADJACENT REORDER phase 2/2: %0d reads, ARID pattern A,B,A,C,A,D x%0d",
                        axi4_master_same_id_nonadjacent_preload_seq::slots_for_rounds(num_rounds),
                        num_rounds), UVM_LOW)
    same_id_read_seq_h = axi4_master_same_id_nonadjacent_read_seq::type_id::create("same_id_read_seq_h");
    same_id_read_seq_h.num_rounds = num_rounds;
    same_id_read_seq_h.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_read_seqr_h_all[0]);

    #(resp_drain_time);

    phase.drop_objection(this);
  endtask : run_phase

endclass : axi4_same_id_nonadjacent_reorder_test

`endif
