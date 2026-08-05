`ifndef AXI4_MASTER_REFUSED_WRITE_SHADOW_READ_SEQ_INCLUDED_
`define AXI4_MASTER_REFUSED_WRITE_SHADOW_READ_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_refused_write_shadow_read_seq
//
// Measure half of the AXI_ooo.md Phase 3 (third fix pass) write-shadow commit-gate
// test. Reads W, Z, W, Z on MASTER 7 -- ALL WITH THE SAME ARID -- against a
// subordinate left in RESP_IN_ORDER.
//
// RESP_IN_ORDER is deliberate and is what makes this a clean false-positive probe:
// there is NO reordering anywhere in this test, so ANY SB_SAMEID_ORDER_VIOLATION it
// produces is by construction a FALSE one.
//
// Why one ARID for all four: sb_sameid_check_read_completion() returns immediately
// when a completion has no still-outstanding same-ID sibling. Reading W then Z on one
// id means that when the W burst completes, Z is the sibling the CONTENT mechanism
// scans -- and Z's shadow content (0xCC) is exactly what memory[W] now returns.
//   * gate that refused the SLVERR write -> shadow[W] = 0xAA, head MISMATCHES the
//     0xCC memory returns, Z matches it, and Z is convicted. FALSE VIOLATION.
//   * gate that mirrors store_write()     -> shadow[W] = 0xCC, head matches, silent.
//
// arprot is SECURE so the reads themselves are permitted on S7 for master 7 and come
// back READ_OKAY -- sb_sameid_check_read_completion() only adjudicates a clean burst.
// arsize=128B / arlen=0 so each R burst is one full-width beat and the compared lane
// mask equals the all-ones mask the writes used; the sibling scan only accuses a
// candidate whose mask equals the head's.
//--------------------------------------------------------------------------------------------
class axi4_master_refused_write_shadow_read_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_refused_write_shadow_read_seq)

  // Two full W,Z passes: two chances for the false conviction, and it keeps a
  // sibling outstanding when the first W completes.
  int unsigned num_passes = 2;

  function new(string name = "axi4_master_refused_write_shadow_read_seq");
    super.new(name);
  endfunction : new

  task body();
    // super.body() intentionally not called -- all reads outstanding at once.
    for (int unsigned p = 0; p < num_passes; p++) begin
      for (int unsigned k = 0; k < 2; k++) begin
        automatic bit [63:0] addr = (k == 0) ? axi4_master_refused_write_shadow_seq::addr_w()
                                             : axi4_master_refused_write_shadow_seq::addr_z();
        axi4_master_tx tx;
        tx = axi4_master_tx::type_id::create($sformatf("refused_shadow_rd_%0d_%0d", p, k));
        start_item(tx);
        if (!tx.randomize() with {
          tx.tx_type       == READ;
          tx.transfer_type == NON_BLOCKING_READ;
          tx.arid          == ARID_0;          // ONE id for every read -- see header
          tx.araddr        == local::addr;
          tx.arlen         == 0;
          tx.arsize        == READ_128_BYTES;
          tx.arburst       == READ_INCR;
          tx.arlock        == READ_NORMAL_ACCESS;
          tx.arcache       == 4'h0;
          tx.arprot        == READ_NORMAL_SECURE_DATA;
          tx.aruser        == 4'h0;
        }) `uvm_fatal(get_type_name(), $sformatf("randomize() failed for read pass=%0d k=%0d", p, k))
        `uvm_info(get_type_name(),
                  $sformatf("REFUSED_SHADOW read issue pass=%0d %s ADDR=0x%016h (ARID_0)",
                            p, (k == 0) ? "W" : "Z", addr), UVM_LOW)
        finish_item(tx);
      end
    end
  endtask : body

endclass : axi4_master_refused_write_shadow_read_seq

`endif
