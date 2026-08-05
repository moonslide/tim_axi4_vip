`ifndef AXI4_WRITE_RESP_OOO_EMPTY_QUEUE_TEST_INCLUDED_
`define AXI4_WRITE_RESP_OOO_EMPTY_QUEUE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_write_resp_ooo_empty_queue_test
//
// Phase 0 / P0.1 repro test for AXI_ooo.md finding F1:
// "write-path OOO empty-queue pop_front(): read side fixed, write side NOT".
//
// THE BUG THIS PROVOKES
//   With slave_response_mode = ONLY_WRITE_RESP_OUT_OF_ORDER the subordinate's
//   WRITE_RESPONSE_CHANNEL thread picks the BID it will drive from one of two
//   bookkeeping queues (slave/axi4_slave_driver_proxy.sv:613-623):
//     :613-617  drive_id_cont branch -> response_id_cont_queue.pop_front()   NO size() guard
//     :619-622  shuffle branch       -> response_id_queue.shuffle()/pop_front()  NO size() guard
//   and the wait that was supposed to guarantee something is queued is
//     :602      `if (get_minimum_transactions > 0)` -- an EARLY EXIT that skips the
//               wait entirely for the minimum_transactions == 0 setting every
//               out-of-order test uses, and
//     :604      `while (write_data_out_fifo.size > minimum_transactions)` -- which
//               waits for the wrong direction (DRAIN) on the wrong object (the write
//               DATA fifo, not the ID queue that is actually popped).
//   Commit 238ffbc fixed exactly this on the READ side (:1738-1783: a two-gate wait
//   that polls the queue actually popped, plus size() guards on both pops). The write
//   side was not touched.
//   SystemVerilog pop_front() on an empty queue returns 0, and the subordinate BFM
//   drives that value directly in the out-of-order modes
//   (agent/slave_agent_bfm/axi4_slave_driver_bfm.sv:594-599, `bid <= bid_local`), so
//   the symptom is a SILENT BID = 0 on the B channel -- no uvm_error on the
//   subordinate side at all. This is worse than the read-side symptom, which at least
//   produced a visible timeout.
//
// HOW THIS TEST MAKES THE SYMPTOM UNAMBIGUOUS
//   Every AWID in the run is NON-ZERO (the sequence starts at AWID 5). A BID = 0 on
//   the B channel therefore cannot be a legitimate response in this run -- it can only
//   come from a pop of an empty queue. The pre-existing axi4_cross_id_write_reorder_test
//   cannot serve as an F1 repro for precisely this reason: it uses AWID 0..7, where a
//   bogus BID = 0 is indistinguishable from transaction #0's real response.
//   (That test targets a different, already-fixed bug -- codex_review.md Finding 5,
//   the monitor's BID-keyed join -- and is not duplicated here.)
//
// EXPECTED SYMPTOM BEFORE THE FIX (Phase 1)
//   At least one `WRESP_PHASE_ENTER bid_local=0x0` in the log while no write in the
//   run used AWID 0, i.e. the subordinate drove BID = 0 for a transaction whose real
//   AWID (`WRESP_PHASE_BOUND awid=...`) was 5..12. Depending on whether the scoreboard
//   notices, this shows up either as UVM_ERROR (response attributed to the wrong
//   outstanding AWID / owed-response accounting) or -- if it does not -- as a green run
//   that nevertheless contains the bogus BID, which is itself a checker gap to record.
//
// EXPECTED AFTER THE FIX (Phase 1, mirror of 238ffbc onto the write path)
//   Every driven BID equals the AWID the response was bound to, no BID = 0 appears,
//   and the run ends UVM_ERROR : 0 with TEST RESULT: PASS.
//
// RETRY NOTE (2026-08-04) -- the corrected trigger, and the gate it ran into
//   The first version of this test (stages 1-3, fast distinct-AWID issuance) stayed
//   green on 3 seeds; AXI_ooo.md section 1a records why (F7: the subordinate's three
//   write channel threads are closed by `join`, so the address push and the response
//   pop are forced into the same loop iteration). The adversarial review's corrected
//   trigger is the DATA-BEFORE-ADDRESS race: the response thread only does
//   `data_tx.await()` (slave/axi4_slave_driver_proxy.sv:370), never awaits the address
//   thread, and AXI4 permits W before AW. Stages 4 and 5 of the sequence chase exactly
//   that ordering (same-ID pair storm to drain response_id_queue; long W bursts to make
//   AW run ahead of W as far as this VIP allows).
//   What to watch in the log, besides BID = 0:
//     "WRITE_RESP_THREAD::Waiting for write addr data in out-of-order mode"
//       (slave/axi4_slave_driver_proxy.sv:450, UVM_MEDIUM) -- printed only when the
//       response thread reached the write-addr-FIFO gate at :445 BEFORE the address
//       thread had put anything there, i.e. the data-before-address ordering really
//       happened. The address thread pushes response_id_queue at :271-273 BEFORE it
//       puts the FIFO at :302, so that gate transitively orders the push ahead of the
//       :621 pop. If this message appears and BID is still never 0, the race window is
//       real but a second, previously unnoticed guard closes it.
//
// HOW TO READ THE RESULT (do not trust a green run alone -- the point of this test is
// the log evidence, and a green UVM summary does not by itself clear F1):
//   ./simv +UVM_TESTNAME=axi4_write_resp_ooo_empty_queue_test +UVM_VERBOSITY=UVM_LOW \
//          +uvm_set_verbosity=*,WDBG,UVM_HIGH,run +ntb_random_seed=<N> | tee <log>
//   grep -n "WRESP_PHASE_ENTER"    <log>   # bid_local actually driven, one per response
//   grep -n "WRESP_PHASE_BOUND"    <log>   # the AWID that response really belongs to
//   grep -n "OOO_EMPTY_QUEUE"      <log>   # AWID issue order, per stage
//   A `bid_local=0x0` line, or any ENTER/BOUND pair whose ids differ, is the red result.
//--------------------------------------------------------------------------------------------
class axi4_write_resp_ooo_empty_queue_test extends axi4_base_test;
  `uvm_component_utils(axi4_write_resp_ooo_empty_queue_test)

  axi4_master_write_resp_ooo_empty_queue_seq ooo_empty_queue_seq_h;

  // First AWID of the run. Non-zero by design -- see the header.
  int unsigned first_id = 5;

  // Distinct AWIDs in the sequence's stage 3. first_id + burst_ids - 1 must stay
  // inside `AXI_ID_WIDTH (4 bits => 15 on the baseline build).
  int unsigned burst_ids = 8;

  // Response drain window before the objection drops. Same reasoning as
  // axi4_cross_id_write_reorder_test: without it the objection would drop at the
  // last AW handshake, while responses are still in flight, and a wrong BID would
  // vanish into the drain race.
  time resp_drain_time = 6us;

  function new(string name = "axi4_write_resp_ooo_empty_queue_test", uvm_component parent = null);
    super.new(name, parent);
    // Test-scoped bound for the base watchdog (codex_review.md Finding 8). The
    // sequence itself spends 2 x 2us between stages plus the drain window, so
    // 500us is ~30x the expected runtime: a hang in the out-of-order response
    // path ends as a UVM verdict with test context instead of an external kill.
    test_timeout = 500us;
  endfunction : new

  virtual function void setup_axi4_slave_agent_cfg();
    super.setup_axi4_slave_agent_cfg();
    foreach (axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
      // Reactive memory slave: it answers what the master drives.
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
      // THE knob under test: the write response path takes the
      // response_id_queue / response_id_cont_queue branch at :600-623.
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_response_mode = ONLY_WRITE_RESP_OUT_OF_ORDER;
      // 0 is the setting that triggers the :602 early-exit, i.e. the response
      // thread does NOT wait for anything to be queued before it pops. It is
      // also the setting all three pre-existing out-of-order tests use, because
      // the :604 wait tests uvm_tlm_fifo::size() -- the CAPACITY (16), not the
      // occupancy -- so with a non-zero value it can never be satisfied.
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].set_minimum_transactions(0);
    end
  endfunction : setup_axi4_slave_agent_cfg

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    fork
      timeout_watchdog();
    join_none

    `uvm_info(get_type_name(),
              $sformatf("WRITE RESP OOO EMPTY QUEUE: AWIDs %0d..%0d, all non-zero so BID=0 can only mean an empty pop",
                        first_id, first_id + burst_ids - 1), UVM_LOW)

    ooo_empty_queue_seq_h = axi4_master_write_resp_ooo_empty_queue_seq::type_id::create("ooo_empty_queue_seq_h");
    ooo_empty_queue_seq_h.first_id  = first_id;
    ooo_empty_queue_seq_h.burst_ids = burst_ids;
    ooo_empty_queue_seq_h.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h_all[0]);

    // Let every response arrive and be scored before ending.
    #(resp_drain_time);

    phase.drop_objection(this);
  endtask : run_phase

endclass : axi4_write_resp_ooo_empty_queue_test

`endif
