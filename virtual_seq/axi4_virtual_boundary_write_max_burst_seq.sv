`ifndef AXI4_VIRTUAL_BOUNDARY_WRITE_MAX_BURST_SEQ_INCLUDED_
`define AXI4_VIRTUAL_BOUNDARY_WRITE_MAX_BURST_SEQ_INCLUDED_

class axi4_virtual_boundary_write_max_burst_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_boundary_write_max_burst_seq)

  axi4_master_bk_write_max_burst_seq axi4_master_bk_write_max_burst_seq_h;
  axi4_master_bk_read_max_burst_seq  axi4_master_bk_read_max_burst_seq_h;
  axi4_slave_bk_write_incr_burst_seq axi4_slave_bk_write_incr_burst_seq_h;
  axi4_slave_bk_read_incr_burst_seq  axi4_slave_bk_read_incr_burst_seq_h;

  extern function new(string name="axi4_virtual_boundary_write_max_burst_seq");
  extern task body();
endclass : axi4_virtual_boundary_write_max_burst_seq

function axi4_virtual_boundary_write_max_burst_seq::new(string name="axi4_virtual_boundary_write_max_burst_seq");
  super.new(name);
endfunction

task axi4_virtual_boundary_write_max_burst_seq::body();
  axi4_master_bk_write_max_burst_seq_h = axi4_master_bk_write_max_burst_seq::type_id::create("axi4_master_bk_write_max_burst_seq_h");
  axi4_master_bk_read_max_burst_seq_h  = axi4_master_bk_read_max_burst_seq::type_id::create("axi4_master_bk_read_max_burst_seq_h");
  axi4_slave_bk_write_incr_burst_seq_h = axi4_slave_bk_write_incr_burst_seq::type_id::create("axi4_slave_bk_write_incr_burst_seq_h");
  axi4_slave_bk_read_incr_burst_seq_h  = axi4_slave_bk_read_incr_burst_seq::type_id::create("axi4_slave_bk_read_incr_burst_seq_h");

  fork
    begin : SL_WR
      forever axi4_slave_bk_write_incr_burst_seq_h.start(p_sequencer.axi4_slave_write_seqr_h);
    end
    begin : SL_RD
      forever axi4_slave_bk_read_incr_burst_seq_h.start(p_sequencer.axi4_slave_read_seqr_h);
    end
  join_none

  axi4_master_bk_write_max_burst_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
  axi4_master_bk_read_max_burst_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
endtask

`endif
