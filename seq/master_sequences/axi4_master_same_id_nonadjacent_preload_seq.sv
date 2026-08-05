`ifndef AXI4_MASTER_SAME_ID_NONADJACENT_PRELOAD_SEQ_INCLUDED_
`define AXI4_MASTER_SAME_ID_NONADJACENT_PRELOAD_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_same_id_nonadjacent_preload_seq
//
// Preload half of the AXI_ooo.md Finding F2 (P0.2) reproduction.
//
// WHY THIS EXISTS SEPARATELY FROM axi4_master_cross_id_write_reorder_seq
//   That sequence keys its address AND its payload off the transaction's ID
//   (addr_for_id/data_for_id). F2 is about a REPEATED id, so an id-keyed map would
//   give the two A transactions the SAME address and the SAME payload -- exactly the
//   condition under which a swap compares equal and the bug hides. This sequence
//   therefore keys everything off the SLOT (issue position), not the id:
//
//     slot   0    1    2    3    4    5    6    7    8   ...
//     id     A    B    A    C    A    D    A    B    A   ...      (A repeats, never adjacent)
//     addr   +0  +4K  +8K  +Ck  ...                               (one 4KB page per SLOT)
//     data  D0   D1   D2   D3   ...                               (one payload per SLOT)
//
//   So every physical occurrence of id A carries its own distinguishable payload, and
//   "which A came back first" is answerable by reading the R data.
//
// PATTERN CHOICE
//   id_for_slot() is A,B,A,C,A,D repeating. Two properties are load bearing:
//     * A is repeated but NEVER adjacent to itself -- including across the round
//       boundary (slot 5 = D, slot 6 = A). Adjacent same-ID is the ONE case the
//       slave's tail-compare (slave/axi4_slave_driver_proxy.sv:806-807) actually
//       detects and routes to the strict-FIFO continuation queue; F2 is the
//       non-adjacent case that falls through into the shuffled queue.
//     * B/C/D rotate so no two neighbours share an id either.
//
// This sequence itself uses DISTINCT AWIDs and runs against a slave in
// ONLY_READ_RESP_OUT_OF_ORDER, so the write half is fully in order and deterministic.
// It is stimulus setup only -- it proves nothing on its own.
//--------------------------------------------------------------------------------------------
class axi4_master_same_id_nonadjacent_preload_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_same_id_nonadjacent_preload_seq)

  // Number of A,B,A,C,A,D rounds. num_slots = 6 * num_rounds.
  int unsigned num_rounds = 4;

  // Base of the address window.
  //
  // DELIBERATELY NOT the sibling cross-ID sequences' 0x0000_0100_0000_1000. In the
  // default NONE bus-matrix mode slave 0 owns [0 : 0xFFFF_FFFF]
  // (test/axi4_base_test.sv:379-380), so that base is OUT of range and the slave's
  // SLAVE_MEM_MODE read path takes its out-of-range branch and returns generated data
  // instead of what was written. Measured: every read came back with random data, so a
  // payload-based check could not distinguish a reorder from an out-of-range read.
  // num_rounds=4 uses 24 pages, 0x1000 .. 0x18000 -- comfortably in range, and not
  // address 0 (the slave BFM treats 0x0 specially).
  bit [63:0] base_addr = 64'h0000_0000_0000_1000;

  //------------------------------------------------------------------------
  // SLOT maps -- static, and the single source of truth shared by this
  // sequence, axi4_master_same_id_nonadjacent_read_seq, and the provisional
  // order probe inside axi4_same_id_nonadjacent_reorder_test.
  //------------------------------------------------------------------------
  static function int unsigned slots_for_rounds(int unsigned rounds);
    return rounds * 6;
  endfunction : slots_for_rounds

  static function bit [63:0] addr_for_slot(bit [63:0] base, int unsigned slot);
    return base + (slot * 64'h0000_0000_0000_1000);   // one 4KB page per SLOT
  endfunction : addr_for_slot

  // One distinct byte tag per slot, 0xA0 .. 0xA0+num_slots-1. Never 0x00/0xFF, so a
  // dropped or defaulted response cannot masquerade as a valid slot.
  static function bit [7:0] tag_for_slot(int unsigned slot);
    return 8'hA0 + slot[7:0];
  endfunction : tag_for_slot

  // The payload is the slot's tag REPLICATED across all four bytes, and that
  // replication is load bearing, not cosmetic.
  //
  // MEASURED TRAP (this bench, NONE bus-matrix mode): the write path stores one byte
  // at a time (slave/axi4_slave_driver_proxy.sv:1596-1604,
  // `store_write(byte_addr, tmp_wdata)` with only tmp_wdata[7:0] set) but the bus
  // matrix's memory model ALIGNS the address to DATA_WIDTH/8 = 128 bytes
  // (bm/axi4_bus_matrix_ref.sv:353-359). All four bytes of a 32-bit write therefore
  // land on the SAME associative-array entry and only the last one survives; the read
  // path then replicates that surviving byte across every byte lane
  // (`load_read` returns the whole word, task_memory_read takes tmp_rdata[7:0] for
  // every strobe, slave/axi4_slave_driver_proxy.sv:1676-1686). A payload like
  // 0x5A1D_<slot>_<~slot> collapses to a constant 0x5A5A5A5A for EVERY slot -- observed,
  // which is what made the first version of this test report a violation on all 24
  // reads including the ones that were answered in order.
  //
  // A byte-replicated payload survives that collapse AND is byte-exact under the
  // other memory model (axi4_slave_memory, used when no bus matrix is present), so
  // read-back == data_for_slot(slot) either way and the check does not depend on
  // which model the bench happens to instantiate.
  static function bit [31:0] data_for_slot(int unsigned slot);
    return {4{tag_for_slot(slot)}};
  endfunction : data_for_slot

  // A,B,A,C,A,D -- repeated id A, never adjacent to itself, not even across rounds.
  static function int unsigned id_for_slot(int unsigned slot);
    case (slot % 6)
      0, 2, 4 : return 0;   // A -- the repeated, non-adjacent id under test
      1       : return 1;   // B
      3       : return 2;   // C
      default : return 3;   // D
    endcase
  endfunction : id_for_slot

  function new(string name = "axi4_master_same_id_nonadjacent_preload_seq");
    super.new(name);
  endfunction : new

  task body();
    // super.body() intentionally not called -- see
    // axi4_master_cross_id_write_reorder_seq for why a shared `req` handle is unsafe
    // with several transactions in flight.
    automatic int unsigned n_slots = slots_for_rounds(num_rounds);

    for (int unsigned s = 0; s < n_slots; s++) begin
      automatic bit [63:0] addr = addr_for_slot(base_addr, s);
      automatic bit [31:0] data = data_for_slot(s);
      // Distinct AWID per slot: the write half must stay boring and in order.
      automatic awid_e     awid_v = awid_e'(`GET_AWID_ENUM(s % 16));
      axi4_master_tx       tx;

      tx = axi4_master_tx::type_id::create($sformatf("same_id_preload_%0d", s));
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
                   $sformatf("randomize() failed for same-ID preload slot=%0d addr=0x%0h", s, addr))
      end

      `uvm_info(get_type_name(),
                $sformatf("SAMEID_PRELOAD slot=%0d: AWID=%s ADDR=0x%016h DATA=0x%08h",
                          s, awid_v.name(), addr, data), UVM_LOW)

      finish_item(tx);
    end
  endtask : body

endclass : axi4_master_same_id_nonadjacent_preload_seq

`endif
