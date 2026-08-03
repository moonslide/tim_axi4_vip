`ifndef AXI4_MASTER_CROSS_ID_READ_REORDER_SEQ_INCLUDED_
`define AXI4_MASTER_CROSS_ID_READ_REORDER_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_cross_id_read_reorder_seq
//
// Read-side counterpart of axi4_master_cross_id_write_reorder_seq, for
// codex_review.md Finding 5. Issues N single-beat NON_BLOCKING reads from one body,
// each with a DIFFERENT ARID and a DIFFERENT address, aimed at the pages the write
// sequence just filled -- so every RID carries a DIFFERENT payload back. Same
// reasoning as on the write side: with identical payloads a wrong RID->AR join
// compares equal and the bug hides.
//
// All N ARs are outstanding together (the driver proxy calls item_done() after the
// AR handshake, master/axi4_master_driver_proxy.sv:859-866), and the slave, in
// ONLY_READ_RESP_OUT_OF_ORDER, picks the next burst to answer by shuffling its
// outstanding ARID queue (slave/axi4_slave_driver_proxy.sv:1754-1755).
//
// SCOPE LIMIT, stated so nobody over-claims this test: this provokes whole-burst
// READ REORDER across RIDs. It does NOT provoke beat-level R INTERLEAVE, because
// this VIP's slave drives each read burst atomically -- one `for` loop over
// arlen+1 beats holding RVALID (agent/slave_agent_bfm/axi4_slave_driver_bfm.sv:
// 884-925) under the proxy's single-key semaphore_read_key. So it exercises the
// keyed RID->AR-metadata join, not the per-RID beat accumulator.
//--------------------------------------------------------------------------------------------
class axi4_master_cross_id_read_reorder_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_cross_id_read_reorder_seq)

  // Keep these three in step with the write sequence that preloaded the pages.
  int unsigned num_ids  = 8;
  int unsigned first_id = 0;
  bit [63:0]   base_addr = 64'h0000_0100_0000_1000;

  function new(string name = "axi4_master_cross_id_read_reorder_seq");
    super.new(name);
  endfunction : new

  task body();
    // super.body() intentionally not called -- see the write sequence for why
    // a shared `req` handle is unsafe with N transactions in flight.
    for (int unsigned i = 0; i < num_ids; i++) begin
      automatic int unsigned id_val = first_id + i;
      // One source of truth for the address/data map: the write sequence's
      // static functions.
      automatic bit [63:0]   addr   = axi4_master_cross_id_write_reorder_seq::addr_for_id(base_addr, id_val);
      automatic bit [31:0]   expected_data = axi4_master_cross_id_write_reorder_seq::data_for_id(id_val);
      // Explicit cast: see the write sequence -- the helper macro is a ternary chain.
      automatic arid_e       arid_v = arid_e'(`GET_ARID_ENUM(id_val));
      axi4_master_tx         tx;

      tx = axi4_master_tx::type_id::create($sformatf("cross_id_rd_%0d", id_val));
      start_item(tx);
      if (!tx.randomize() with {
        tx.tx_type       == READ;
        tx.transfer_type == NON_BLOCKING_READ;
        tx.arid          == local::arid_v;
        tx.araddr        == local::addr;
        tx.arlen         == 0;
        tx.arsize        == READ_4_BYTES;
        tx.arburst       == READ_INCR;
        tx.arlock        == READ_NORMAL_ACCESS;
        tx.arcache       == 4'h0;
        tx.arprot        == 3'h0;
        tx.aruser        == 4'h0;
      }) begin
        `uvm_fatal(get_type_name(),
                   $sformatf("randomize() failed for cross-ID read id=%0d addr=0x%0h", id_val, addr))
      end

      `uvm_info(get_type_name(),
                $sformatf("CROSS_ID_READ issue #%0d: ARID=%s ADDR=0x%016h EXPECT_DATA=0x%08h",
                          i, arid_v.name(), addr, expected_data), UVM_LOW)

      // Returns at the AR handshake, so all N reads become outstanding.
      finish_item(tx);
    end
  endtask : body

endclass : axi4_master_cross_id_read_reorder_seq

`endif
