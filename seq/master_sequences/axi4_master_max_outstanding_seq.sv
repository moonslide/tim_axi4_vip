`ifndef AXI4_MASTER_MAX_OUTSTANDING_SEQ_INCLUDED_
`define AXI4_MASTER_MAX_OUTSTANDING_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_max_outstanding_seq
//
// Back-to-back issuance whose ONLY throttle is the manager driver's outstanding
// credit (axi4_master_driver_proxy::configure_outstanding_credits, sized from
// axi4_master_agent_config::outstanding_write_tx / outstanding_read_tx).
//
// WHY THIS FILE WAS REWRITTEN (AXI_ooo.md Phase 4 / P4.2)
//   The previous version was dead in two independent ways and the plan called for
//   "rewrite as a credit-based sequence and register it in a test, or delete":
//     1. It was never started by any test - the only reference to it anywhere in
//        the repo was the `include in axi4_master_seq_pkg.sv. It has been given a
//        real caller: test/axi4_outstanding_depth_test.sv.
//     2. Its depth control was
//              if (i % max_outstanding == 0) #100ns;
//        which is a TIME DELAY, not a depth cap. It bounds nothing: it neither
//        counts transactions in flight nor waits for any of them to complete, so
//        the depth it produced was whatever the driver happened to allow -
//        which, before P4.1, was hardcoded 1 no matter what this sequence did.
//        The delay is gone. Depth is now enforced at the correct layer: the
//        driver blocks on a credit, so this sequence just issues as fast as the
//        sequencer will take items and the achieved depth IS the configured depth.
//        That is also what makes the test a real measurement rather than a
//        self-fulfilling one - the sequence asserts nothing about depth, the
//        driver's own AXI4_CREDIT high-water marks report it.
//
// Direction: one sequence body serves both channels. Start it on a write
// sequencer with read_direction = 0, on a read sequencer with read_direction = 1.
//--------------------------------------------------------------------------------------------
class axi4_master_max_outstanding_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_max_outstanding_seq)

  // 0 = NON_BLOCKING_WRITE on a write sequencer, 1 = NON_BLOCKING_READ on a read
  // sequencer.
  bit read_direction = 0;

  // Number of transactions issued back to back. No inter-item delay: the point is
  // to keep more requests pending than the credit allows, so the credit is what
  // is actually being measured.
  int num_transactions = 16;

  // Distinct IDs to spread over. Kept <= the ID width of the build; the depth
  // being exercised is a driver property, not an ID-space property, but distinct
  // IDs let a subordinate answer out of order if it wants to.
  int num_ids = 4;

  int use_bus_matrix_addressing = 0;  // 0=NONE, 1=4x4, 2=10x10

  extern function new(string name = "axi4_master_max_outstanding_seq");
  extern task body();

endclass : axi4_master_max_outstanding_seq

function axi4_master_max_outstanding_seq::new(string name = "axi4_master_max_outstanding_seq");
  super.new(name);
endfunction : new

task axi4_master_max_outstanding_seq::body();
  bit [63:0] target_addr;
  int        id_i;
  super.body();

  // Address base per bus-matrix mode, same choices the previous version made.
  if (use_bus_matrix_addressing == 1) begin
    target_addr = 64'h0000_0100_0000_0000;  // 4x4 BASE: DDR Memory
  end
  else if (use_bus_matrix_addressing == 2) begin
    target_addr = 64'h0000_0008_0000_0000;  // 10x10 ENHANCED: DDR Secure
  end
  else begin
    target_addr = 64'h0000_0000_0000_0000;  // NONE: slave 0 decode range
  end

  `uvm_info(get_type_name(),
            $sformatf("MAX_OUTSTANDING: %0d %s transactions back to back over %0d ids, matrix mode %0d - depth is bounded by the driver credit only",
                      num_transactions, read_direction ? "read" : "write", num_ids,
                      use_bus_matrix_addressing), UVM_LOW)

  for(int i = 0; i < num_transactions; i++) begin
    id_i = i % num_ids;
    req  = axi4_master_tx::type_id::create("req");

    start_item(req);
    if(read_direction) begin
      if(!req.randomize() with {
        tx_type        == READ;
        transfer_type  == NON_BLOCKING_READ;
        araddr[63:16]  == target_addr[63:16];
        araddr[15:0]   == (i * 'h40);
        arburst        == READ_INCR;
        arid           == id_i;
        arsize         == READ_4_BYTES;
        arlen          inside {[0:3]};
      }) begin
        `uvm_fatal(get_type_name(), "Randomization failed (read)")
      end
    end
    else begin
      if(!req.randomize() with {
        tx_type        == WRITE;
        transfer_type  == NON_BLOCKING_WRITE;
        awaddr[63:16]  == target_addr[63:16];
        awaddr[15:0]   == (i * 'h40);
        awburst        == WRITE_INCR;
        awid           == id_i;
        awsize         == WRITE_4_BYTES;
        awlen          inside {[0:3]};
      }) begin
        `uvm_fatal(get_type_name(), "Randomization failed (write)")
      end
    end
    finish_item(req);
    // Deliberately NO delay here - see the header.
  end

  `uvm_info(get_type_name(), "MAX_OUTSTANDING: issuance complete", UVM_LOW)

endtask : body

`endif
