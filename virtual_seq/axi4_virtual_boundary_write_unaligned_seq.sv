`ifndef AXI4_VIRTUAL_BOUNDARY_WRITE_UNALIGNED_SEQ_INCLUDED_
`define AXI4_VIRTUAL_BOUNDARY_WRITE_UNALIGNED_SEQ_INCLUDED_

class axi4_virtual_boundary_write_unaligned_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_boundary_write_unaligned_seq)

  axi4_master_bk_write_unaligned_addr_seq axi4_master_bk_write_unaligned_addr_seq_h;
  axi4_master_bk_read_unaligned_addr_seq  axi4_master_bk_read_unaligned_addr_seq_h;
  axi4_slave_bk_write_unaligned_addr_seq  axi4_slave_bk_write_unaligned_addr_seq_h;
  axi4_slave_bk_read_unaligned_addr_seq   axi4_slave_bk_read_unaligned_addr_seq_h;

  extern function new(string name="axi4_virtual_boundary_write_unaligned_seq");
  extern task body();
endclass : axi4_virtual_boundary_write_unaligned_seq

function axi4_virtual_boundary_write_unaligned_seq::new(string name);
  super.new(name);
endfunction

task axi4_virtual_boundary_write_unaligned_seq::body();
  axi4_master_bk_write_unaligned_addr_seq_h = axi4_master_bk_write_unaligned_addr_seq::type_id::create("axi4_master_bk_write_unaligned_addr_seq_h");
  axi4_master_bk_read_unaligned_addr_seq_h  = axi4_master_bk_read_unaligned_addr_seq::type_id::create("axi4_master_bk_read_unaligned_addr_seq_h");
  axi4_slave_bk_write_unaligned_addr_seq_h  = axi4_slave_bk_write_unaligned_addr_seq::type_id::create("axi4_slave_bk_write_unaligned_addr_seq_h");
  axi4_slave_bk_read_unaligned_addr_seq_h   = axi4_slave_bk_read_unaligned_addr_seq::type_id::create("axi4_slave_bk_read_unaligned_addr_seq_h");

  fork
    forever axi4_slave_bk_write_unaligned_addr_seq_h.start(p_sequencer.axi4_slave_write_seqr_h);
    forever axi4_slave_bk_read_unaligned_addr_seq_h.start(p_sequencer.axi4_slave_read_seqr_h);
  join_none

  axi4_master_bk_write_unaligned_addr_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
  axi4_master_bk_read_unaligned_addr_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
endtask

`endif
