`ifndef AXI4_VIRTUAL_RREADY_STALL_SEQ_INCLUDED_
`define AXI4_VIRTUAL_RREADY_STALL_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_rready_stall_seq
//
// BENCH-065: runs n_reads back-to-back directed reads on master 0 with the
// requested RREADY stall position while slave 0 answers with its ordinary
// blocking read sequence (gapless RVALID). No other master, no X injection,
// no reset - the isolated reproduction the BENCH record asks for.
//--------------------------------------------------------------------------------------------
class axi4_virtual_rready_stall_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_rready_stall_seq)

  int        n_reads       = 2;
  int        burst_len     = 3;
  int        first_beat_ws = 0;
  int        stall_beat    = -1;
  int        stall_cycles  = 0;
  bit        direct_assign = 1'b0;
  bit [63:0] start_addr    = 64'h0000_0008_0000_1000;

  axi4_master_bk_read_rready_stall_seq axi4_master_bk_read_rready_stall_seq_h;
  axi4_slave_bk_read_incr_burst_seq    axi4_slave_bk_read_incr_burst_seq_h;

  extern function new(string name = "axi4_virtual_rready_stall_seq");
  extern task body();
endclass : axi4_virtual_rready_stall_seq

function axi4_virtual_rready_stall_seq::new(string name = "axi4_virtual_rready_stall_seq");
  super.new(name);
endfunction : new

task axi4_virtual_rready_stall_seq::body();
  axi4_slave_bk_read_incr_burst_seq_h = axi4_slave_bk_read_incr_burst_seq::type_id::create("axi4_slave_bk_read_incr_burst_seq_h");

  fork
    begin : SL_RD
      forever begin
        axi4_slave_bk_read_incr_burst_seq_h.start(p_sequencer.axi4_slave_read_seqr_h);
      end
    end
  join_none

  repeat(n_reads) begin
    axi4_master_bk_read_rready_stall_seq_h = axi4_master_bk_read_rready_stall_seq::type_id::create("axi4_master_bk_read_rready_stall_seq_h");
    axi4_master_bk_read_rready_stall_seq_h.burst_len     = burst_len;
    axi4_master_bk_read_rready_stall_seq_h.first_beat_ws = first_beat_ws;
    axi4_master_bk_read_rready_stall_seq_h.stall_beat    = stall_beat;
    axi4_master_bk_read_rready_stall_seq_h.stall_cycles  = stall_cycles;
    axi4_master_bk_read_rready_stall_seq_h.direct_assign = direct_assign;
    axi4_master_bk_read_rready_stall_seq_h.start_addr    = start_addr;
    axi4_master_bk_read_rready_stall_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
  end
endtask : body

`endif
