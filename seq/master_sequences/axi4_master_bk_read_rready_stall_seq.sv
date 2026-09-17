`ifndef AXI4_MASTER_BK_READ_RREADY_STALL_SEQ_INCLUDED_
`define AXI4_MASTER_BK_READ_RREADY_STALL_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_bk_read_rready_stall_seq
//
// BENCH-065 directed stimulus: ONE deterministic INCR read burst with a
// programmable RREADY back-pressure position.
//   * first_beat_ws  -> r_wait_states (the pre-existing first-beat delay)
//   * stall_beat     -> r_stall_beat  (interior beat 1..arlen, -1 = none)
//   * stall_cycles   -> r_stall_cycles
// direct_assign = 1 sets the two stall fields by DIRECT ASSIGNMENT after
// randomize() instead of constraining them - the usage pattern the BENCH-065
// record documents for SoC-side burst sequences - so the driver BFM's
// capture-time validation can be exercised with values the constraint would
// reject (beat 0, beat > arlen, negative cycles).
// ARID is pinned to ARID_0 and the address (chosen by the test per bus-matrix
// mode: slave 0 sits at 0x0000_0008_0000_0000 in ENHANCED, at
// 0x0000_0100_0000_0000 in the 4x4 BASE matrix, anywhere in NONE) to a region
// master 0 may read (claude.md, M0 -> S0: OKAY), so the run never provokes a
// DECERR, an abandon or a timeout on the measured RID.
//--------------------------------------------------------------------------------------------
class axi4_master_bk_read_rready_stall_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_bk_read_rready_stall_seq)

  int          burst_len     = 3;   // ARLEN: 4 beats, the BENCH-065 minimum
  int          first_beat_ws = 0;
  int          stall_beat    = -1;
  int          stall_cycles  = 0;
  bit          direct_assign = 1'b0;
  bit [63:0]   start_addr    = 64'h0000_0008_0000_1000;

  extern function new(string name = "axi4_master_bk_read_rready_stall_seq");
  extern task body();
endclass : axi4_master_bk_read_rready_stall_seq

function axi4_master_bk_read_rready_stall_seq::new(string name = "axi4_master_bk_read_rready_stall_seq");
  super.new(name);
endfunction : new

task axi4_master_bk_read_rready_stall_seq::body();
  super.body();
  req.transfer_type = BLOCKING_READ;

  start_item(req);
  if(direct_assign) begin
    if(!req.randomize() with {arid          == ARID_0;
                              araddr        == start_addr;
                              arlen         == burst_len;
                              arsize        == READ_4_BYTES;
                              arburst       == READ_INCR;
                              tx_type       == READ;
                              transfer_type == BLOCKING_READ;
                              ar_wait_states == 0;
                              r_wait_states  == first_beat_ws;}) begin
      `uvm_fatal("axi4","Rand failed");
    end
    // Deliberately bypasses r_mid_burst_stall_c.
    req.r_stall_beat   = stall_beat;
    req.r_stall_cycles = stall_cycles;
  end
  else begin
    if(!req.randomize() with {arid          == ARID_0;
                              araddr        == start_addr;
                              arlen         == burst_len;
                              arsize        == READ_4_BYTES;
                              arburst       == READ_INCR;
                              tx_type       == READ;
                              transfer_type == BLOCKING_READ;
                              ar_wait_states == 0;
                              r_wait_states  == first_beat_ws;
                              r_stall_beat   == stall_beat;
                              r_stall_cycles == stall_cycles;}) begin
      `uvm_fatal("axi4","Rand failed");
    end
  end
  `uvm_info(get_type_name(),$sformatf("BENCH-065 read: arlen=%0d r_wait_states=%0d r_stall_beat=%0d r_stall_cycles=%0d direct_assign=%0d",
                                      req.arlen,req.r_wait_states,req.r_stall_beat,req.r_stall_cycles,direct_assign),UVM_LOW)
  finish_item(req);
endtask : body

`endif
