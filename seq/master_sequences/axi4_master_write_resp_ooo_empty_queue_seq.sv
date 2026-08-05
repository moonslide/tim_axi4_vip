`ifndef AXI4_MASTER_WRITE_RESP_OOO_EMPTY_QUEUE_SEQ_INCLUDED_
`define AXI4_MASTER_WRITE_RESP_OOO_EMPTY_QUEUE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_write_resp_ooo_empty_queue_seq
//
// Directed stimulus for AXI_ooo.md finding F1 (Phase 0 / P0.1): the WRITE response
// out-of-order path of the subordinate driver proxy pops `response_id_queue` /
// `response_id_cont_queue` with NO size() guard
// (slave/axi4_slave_driver_proxy.sv:613-623). SystemVerilog `pop_front()` on an
// empty queue returns 0, and in the out-of-order modes the BFM drives that value
// straight onto the bus (agent/slave_agent_bfm/axi4_slave_driver_bfm.sv:594-599,
// `bid <= bid_local`). So an empty pop is a silent BID = 0 for a transaction whose
// AWID was something else -- no uvm_error anywhere on the subordinate side.
//
// WHAT THIS SEQUENCE DOES DIFFERENTLY FROM axi4_master_cross_id_write_reorder_seq
//   That sequence exists for codex_review.md Finding 5 (monitor BID-keyed join,
//   already fixed) and issues 8 writes with AWID 0..7. Two properties make it
//   USELESS as an F1 detector and this sequence deliberately inverts both:
//     1. It USES AWID 0. A bogus BID = 0 from an empty pop is then
//        indistinguishable from the legitimate response of transaction #0.
//        Here EVERY AWID is NON-ZERO (`first_id` defaults to 5), so any
//        BID = 0 observed on the B channel is, by construction, proof that an
//        empty queue was popped.
//     2. It issues a single wide batch of DISTINCT IDs, which never arms the
//        `drive_id_cont` / `response_id_cont_queue` branch (that branch needs
//        two ADJACENT same-AWID addresses, slave/axi4_slave_driver_proxy.sv:276).
//        The cont-queue pop at :614 is the site whose read-side twin at :1777
//        DID get a size() guard in commit 238ffbc -- the asymmetry F1 calls out.
//        This sequence's stage 2 arms it on purpose.
//
// RETRY (2026-08-04): the corrected trigger
//   The first attempt at this repro used stages 1-3 only (fast distinct-AWID
//   issuance) and stayed green on 3 seeds -- see AXI_ooo.md section 1a. The
//   adversarial review's corrected hypothesis is a DATA-BEFORE-ADDRESS race:
//   the subordinate's WRITE_RESPONSE_CHANNEL thread only does `data_tx.await()`
//   (slave/axi4_slave_driver_proxy.sv:370) and never awaits the ADDRESS thread,
//   while AXI4 legally allows W to be delivered before AW. The same shape is
//   already documented and FIXED for QoS mode in the same file (:375-396,
//   `wait(qos_queue.size() > 0)`); the OOO write path has no such guard.
//   Stages 4-5 below exist to drive the subordinate towards that ordering with
//   the only levers a manager sequence actually has on this bench:
//     Stage 4 - a same-ID PAIR STORM. Every adjacent same-AWID pair re-arms
//               `drive_id_cont` and pushes TWO entries into
//               response_id_cont_queue while removing one from
//               response_id_queue (:276-284). That is the one code path that
//               can leave response_id_queue empty at all, and it is also the
//               path whose pop at :614 has no size() guard (its read-side twin
//               at :1777 does). Run many pairs so the two queues' depths keep
//               diverging instead of settling.
//     Stage 5 - AW RUN-AHEAD. The manager proxy calls item_done() at the AW
//               handshake (master/axi4_master_driver_proxy.sv:643,652) while
//               the W thread is still gated by write_data_channel_key, so a
//               long multi-beat burst lets AW for later writes stack up in the
//               subordinate BFM's aw_capture_q (AW_ACCEPT_DEPTH 16) while W is
//               still draining an earlier one. This is the widest AW/W skew
//               this VIP can produce; if the response thread can ever run
//               ahead of the address thread's push, it is here.
//
// THE FIRST THREE STAGES (all single-beat, all back to back with no inter-item delay;
// the master driver proxy returns from finish_item() at the AW handshake, so the
// next item is issued while the previous one is still awaiting its B):
//   Stage 1 - ONE lone write. Narrowest possible window: the subordinate's
//             response thread has exactly one address to be raced against. If it
//             reaches the pop before WRITE_ADDRESS_CHANNEL has pushed the AWID,
//             the queue is empty and BID = 0 goes out for AWID = first_id.
//   Stage 2 - AWID first_id, first_id, first_id+1. The adjacent same-ID pair is
//             what sets drive_id_cont and moves two entries into
//             response_id_cont_queue; the third, different ID then goes to the
//             shuffle queue. This is the state where the unguarded cont pop at
//             :614 and the unguarded shuffle pop at :621 can disagree about which
//             queue actually holds anything.
//   Stage 3 - `burst_ids` distinct non-zero AWIDs issued as fast as the master
//             will accept them. Maximum backlog pressure on the shuffle queue and
//             the only stage where `response_id_queue.shuffle()` at :620 has more
//             than one element to permute.
//
// Stages 1-4 are single-beat (awlen=0, WRITE_4_BYTES, full 4'hF strobe) for the same
// reason the cross-ID sequence is: multi-beat narrow bursts on this bench's wide data
// bus also exercise the sparse-WSTRB byte-address defect (codex_review.md Finding 6),
// which would confuse the verdict. Stage 5 must be multi-beat to create the AW/W skew
// it is for, so it builds WSTRB/WDATA EXPLICITLY (byte lanes walking with the address,
// issue_burst_write below) instead of letting the solver pick them.
//--------------------------------------------------------------------------------------------
class axi4_master_write_resp_ooo_empty_queue_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_write_resp_ooo_empty_queue_seq)

  // First AWID used. MUST stay non-zero: the whole detection scheme is
  // "BID = 0 cannot be legitimate in this run".
  int unsigned first_id = 5;

  // Number of distinct AWIDs in stage 3 (first_id .. first_id+burst_ids-1).
  // Kept small so the log stays readable and the stage still finishes inside
  // the test's drain window.
  int unsigned burst_ids = 8;

  // Settle time between stages, so each stage's B responses land before the next
  // stage's addresses arrive and the log can be read stage by stage.
  time stage_gap = 1us;

  // Base of the address window. Same DDR-range base the existing out-of-order
  // tests use (seq/master_sequences/axi4_master_cross_id_write_reorder_seq.sv:42),
  // which is known to decode in this bench. One 4KB page per issued write.
  bit [63:0] base_addr = 64'h0000_0100_0000_1000;

  // Running page index, so every write in the run has its own address even when
  // two of them share an AWID.
  int unsigned page_idx = 0;

  // Stage 4: number of adjacent same-AWID PAIRS to issue. Each pair re-arms
  // drive_id_cont and moves entries between response_id_queue and
  // response_id_cont_queue (slave/axi4_slave_driver_proxy.sv:276-284) -- the
  // only path that can drain response_id_queue, and the site of the second
  // unguarded pop (:614).
  int unsigned pair_storm = 12;

  // Stage 5: burst length (awlen) and count for the AW-run-ahead stage. A long
  // W burst keeps write_data_channel_key held while the manager proxy has
  // already called item_done() at the AW handshake, so later AWs stack up in
  // the subordinate BFM's aw_capture_q while W is still draining.
  int unsigned runahead_awlen = 15;
  int unsigned runahead_count = 8;

  function new(string name = "axi4_master_write_resp_ooo_empty_queue_seq");
    super.new(name);
  endfunction : new

  // Distinct, non-trivial payload, easy to eyeball: 0xE1D0_<page>_<~page>.
  static function bit [31:0] data_for_page(int unsigned page);
    return 32'hE1D0_0000 | ((page & 32'hFF) << 8) | ((~page) & 32'hFF);
  endfunction : data_for_page

  // Issues ONE single-beat non-blocking write with the given AWID on its own page.
  task issue_write(int unsigned id_val, string stage);
    automatic bit [63:0] addr = base_addr + (page_idx * 64'h0000_0000_0000_1000);
    automatic bit [31:0] data = data_for_page(page_idx);
    // Explicit cast: the helper macro is a ternary chain, and an enum variable
    // may not be assigned from a non-enum-typed expression without one.
    automatic awid_e     awid_v = awid_e'(`GET_AWID_ENUM(id_val));
    axi4_master_tx       tx;

    tx = axi4_master_tx::type_id::create($sformatf("ooo_empty_wr_%0d", page_idx));
    start_item(tx);
    if (!tx.randomize() with {
      tx.tx_type       == WRITE;
      tx.transfer_type == NON_BLOCKING_WRITE;
      tx.awid          == local::awid_v;
      tx.awaddr        == local::addr;
      tx.wdata.size()  == 1;
      tx.wdata[0]      == local::data;
      tx.wstrb.size()  == 1;
      tx.wstrb[0]      == 4'hF;
      tx.awlen         == 0;
      tx.awsize        == WRITE_4_BYTES;
      tx.awburst       == WRITE_INCR;
      tx.awlock        == WRITE_NORMAL_ACCESS;
      tx.awcache       == 4'h0;
      tx.awprot        == 3'h0;
      tx.awuser        == 4'h0;
      tx.wuser         == 4'h0;
    }) begin
      `uvm_fatal(get_type_name(),
                 $sformatf("randomize() failed for OOO-empty-queue write id=%0d addr=0x%0h", id_val, addr))
    end

    `uvm_info(get_type_name(),
              $sformatf("OOO_EMPTY_QUEUE %s issue #%0d: AWID=%s(%0d) ADDR=0x%016h DATA=0x%08h",
                        stage, page_idx, awid_v.name(), id_val, addr, data), UVM_LOW)

    page_idx++;
    // Returns at the AW handshake, so the next item is issued while this one is
    // still awaiting its B -- that is what creates the race window.
    finish_item(tx);
  endtask : issue_write

  // Issues ONE multi-beat (awlen+1 beats) narrow INCR write with the given AWID.
  // Narrow (4-byte) beats on the wide data bus, so the byte lanes walk with the
  // address: beat n covers bytes [4n +: 4] of the page. The strobe is built
  // explicitly rather than randomized so the run cannot also trip the sparse
  // WSTRB byte-address defect (codex_review.md Finding 6) and confuse the verdict.
  task issue_burst_write(int unsigned id_val, int unsigned len, string stage);
    automatic bit [63:0] addr   = base_addr + (page_idx * 64'h0000_0000_0000_1000);
    automatic awid_e     awid_v = awid_e'(`GET_AWID_ENUM(id_val));
    automatic int unsigned beats = len + 1;
    bit [DATA_WIDTH-1:0]        data_q[$];
    bit [(DATA_WIDTH/8)-1:0]    strb_q[$];
    axi4_master_tx              tx;

    // Data must sit in the same byte lanes the strobe selects.
    for (int unsigned b = 0; b < beats; b++) begin
      automatic int unsigned lane = (4*b) % (DATA_WIDTH/8);
      strb_q.push_back({{(DATA_WIDTH/8-4){1'b0}}, 4'hF} << lane);
      data_q.push_back({{(DATA_WIDTH-32){1'b0}}, (data_for_page(page_idx) ^ b)} << (8*lane));
    end

    tx = axi4_master_tx::type_id::create($sformatf("ooo_empty_burst_%0d", page_idx));
    start_item(tx);
    if (!tx.randomize() with {
      tx.tx_type       == WRITE;
      tx.transfer_type == NON_BLOCKING_WRITE;
      tx.awid          == local::awid_v;
      tx.awaddr        == local::addr;
      tx.awlen         == local::len;
      tx.awsize        == WRITE_4_BYTES;
      tx.awburst       == WRITE_INCR;
      tx.awlock        == WRITE_NORMAL_ACCESS;
      tx.awcache       == 4'h0;
      tx.awprot        == 3'h0;
      tx.awuser        == 4'h0;
      tx.wuser         == 4'h0;
      tx.wdata.size()  == local::beats;
      tx.wstrb.size()  == local::beats;
      foreach (tx.wdata[b]) tx.wdata[b] == local::data_q[b];
      foreach (tx.wstrb[b]) tx.wstrb[b] == local::strb_q[b];
    }) begin
      `uvm_fatal(get_type_name(),
                 $sformatf("randomize() failed for OOO-empty-queue burst id=%0d addr=0x%0h len=%0d", id_val, addr, len))
    end

    `uvm_info(get_type_name(),
              $sformatf("OOO_EMPTY_QUEUE %s issue #%0d: AWID=%s(%0d) ADDR=0x%016h AWLEN=%0d",
                        stage, page_idx, awid_v.name(), id_val, addr, len), UVM_LOW)

    page_idx++;
    finish_item(tx);
  endtask : issue_burst_write

  task body();
    // NOTE: super.body() is intentionally NOT called. It creates the single
    // shared `req` handle, and this sequence keeps several transactions in flight
    // at once -- reusing one object would let a later item mutate an earlier one
    // while the driver's detached W/B threads still hold a reference to it.

    // ---- Stage 1: one lone write, narrowest race window --------------------
    `uvm_info(get_type_name(), "OOO_EMPTY_QUEUE STAGE1: single lone write", UVM_LOW)
    issue_write(first_id, "STAGE1");
    #(stage_gap);

    // ---- Stage 2: adjacent same-ID pair, then a different ID ---------------
    // Arms drive_id_cont / response_id_cont_queue (slave proxy :276-281).
    `uvm_info(get_type_name(), "OOO_EMPTY_QUEUE STAGE2: same-ID pair then different ID", UVM_LOW)
    issue_write(first_id,     "STAGE2");
    issue_write(first_id,     "STAGE2");
    issue_write(first_id + 1, "STAGE2");
    #(stage_gap);

    // ---- Stage 3: rapid distinct-ID backlog --------------------------------
    `uvm_info(get_type_name(), "OOO_EMPTY_QUEUE STAGE3: rapid distinct-ID backlog", UVM_LOW)
    for (int unsigned i = 0; i < burst_ids; i++) begin
      issue_write(first_id + i, "STAGE3");
    end
    #(stage_gap);

    // ---- Stage 4: same-ID pair storm (RETRY) -------------------------------
    // Every pair re-arms drive_id_cont and swaps entries between
    // response_id_queue and response_id_cont_queue (slave proxy :276-284) --
    // the only path that can leave response_id_queue empty, and the site of the
    // second unguarded pop (:614).
    `uvm_info(get_type_name(), "OOO_EMPTY_QUEUE STAGE4: same-ID pair storm", UVM_LOW)
    for (int unsigned p = 0; p < pair_storm; p++) begin
      automatic int unsigned id_p = first_id + (p % burst_ids);
      issue_write(id_p, "STAGE4");
      issue_write(id_p, "STAGE4");
    end
    #(stage_gap);

    // ---- Stage 5: AW run-ahead via long W bursts (RETRY) -------------------
    // The manager proxy returns from item_done() at the AW handshake while the
    // W thread still holds write_data_channel_key for a 16-beat burst, so later
    // AWs stack up in the subordinate BFM's aw_capture_q while W drains. This
    // is the widest AW/W skew this VIP can produce; if the response thread can
    // ever reach its pop before the address thread's push, it is here.
    `uvm_info(get_type_name(), "OOO_EMPTY_QUEUE STAGE5: AW run-ahead, long W bursts", UVM_LOW)
    for (int unsigned i = 0; i < runahead_count; i++) begin
      issue_burst_write(first_id + (i % burst_ids), runahead_awlen, "STAGE5");
    end
  endtask : body

endclass : axi4_master_write_resp_ooo_empty_queue_seq

`endif
