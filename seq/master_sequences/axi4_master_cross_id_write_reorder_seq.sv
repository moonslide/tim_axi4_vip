`ifndef AXI4_MASTER_CROSS_ID_WRITE_REORDER_SEQ_INCLUDED_
`define AXI4_MASTER_CROSS_ID_WRITE_REORDER_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_cross_id_write_reorder_seq
//
// Directed stimulus for codex_review.md Finding 5 (monitor cannot correlate a legal
// cross-ID response reorder). Issues N single-beat NON_BLOCKING writes from ONE
// sequence body, each with:
//   * a DIFFERENT AWID   (0 .. num_ids-1)
//   * a DIFFERENT address (4KB apart, so every transaction is distinguishable)
//   * a DIFFERENT payload (data_for_id) -- this is the load-bearing part. With equal
//     payloads a monitor that joins a B response to the WRONG outstanding AW still
//     compares equal, so the dangerous half of the bug (swapped routing) passes
//     silently. Distinct payload per ID is what makes the swap observable.
//
// All N are outstanding simultaneously: the master driver proxy calls item_done()
// after the AW handshake (master/axi4_master_driver_proxy.sv:643-652), so
// finish_item() returns while the W and B threads are still detached. The slave,
// configured ONLY_WRITE_RESP_OUT_OF_ORDER, then returns the B responses in a random
// permutation (slave/axi4_slave_driver_proxy.sv:620-621 shuffles response_id_queue).
// With num_ids=8 the chance of the permutation accidentally being issue order is
// 1/8! = 1/40320, so a reorder is provoked in practice on every seed.
//
// Deliberately single-beat (awlen=0, awsize=WRITE_4_BYTES, full 4'hF strobe): this
// sequence isolates the cross-ID join. Multi-beat narrow bursts on this bench's wide
// data bus also exercise the sparse-WSTRB byte-address defect (codex_review.md
// Finding 6), which would confuse the verdict of a Finding 5 test.
//--------------------------------------------------------------------------------------------
class axi4_master_cross_id_write_reorder_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_cross_id_write_reorder_seq)

  // How many distinct AWIDs to keep outstanding at once.
  int unsigned num_ids = 8;

  // First AWID of the run; ids used are first_id .. first_id+num_ids-1.
  int unsigned first_id = 0;

  // Base of the address window. Same DDR-range base the existing out-of-order
  // tests use (seq/master_sequences/axi4_master_write_nbk_write_read_response_
  // out_of_order_seq.sv:96-103), which is known to decode in this bench.
  bit [63:0] base_addr = 64'h0000_0100_0000_1000;

  //------------------------------------------------------------------------
  // The address and data maps are STATIC and live here so the read-side
  // sequence (axi4_master_cross_id_read_reorder_seq) reads back exactly what
  // this sequence wrote, from one source of truth rather than two copies that
  // can drift.
  //------------------------------------------------------------------------
  static function bit [63:0] addr_for_id(bit [63:0] base, int unsigned id);
    return base + (id * 64'h0000_0000_0000_1000);   // one 4KB page per ID
  endfunction : addr_for_id

  static function bit [31:0] data_for_id(int unsigned id);
    // Distinct, non-trivial, and easy to eyeball in a log: 0xC51D_<id>_<~id>.
    return 32'hC51D_0000 | ((id & 32'hFF) << 8) | ((~id) & 32'hFF);
  endfunction : data_for_id

  function new(string name = "axi4_master_cross_id_write_reorder_seq");
    super.new(name);
  endfunction : new

  task body();
    // NOTE: super.body() is intentionally NOT called. It creates the single
    // shared `req` handle, and this sequence keeps N transactions in flight at
    // once -- reusing one object would let a later item mutate an earlier one
    // while the driver's detached W/B threads still hold a reference to it.
    // One freshly created item per iteration instead.
    for (int unsigned i = 0; i < num_ids; i++) begin
      automatic int unsigned id_val = first_id + i;
      automatic bit [63:0]   addr   = addr_for_id(base_addr, id_val);
      automatic bit [31:0]   data   = data_for_id(id_val);
      // Explicit cast: the helper macro is a ternary chain, and an enum variable
      // may not be assigned from a non-enum-typed expression without one.
      automatic awid_e       awid_v = awid_e'(`GET_AWID_ENUM(id_val));
      axi4_master_tx         tx;

      tx = axi4_master_tx::type_id::create($sformatf("cross_id_wr_%0d", id_val));
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
                   $sformatf("randomize() failed for cross-ID write id=%0d addr=0x%0h", id_val, addr))
      end

      `uvm_info(get_type_name(),
                $sformatf("CROSS_ID_WRITE issue #%0d: AWID=%s ADDR=0x%016h DATA=0x%08h",
                          i, awid_v.name(), addr, data), UVM_LOW)

      // Returns at the AW handshake, so the next ID is issued while this one is
      // still awaiting its B -- that is what creates the reorder window.
      finish_item(tx);
    end
  endtask : body

endclass : axi4_master_cross_id_write_reorder_seq

`endif
