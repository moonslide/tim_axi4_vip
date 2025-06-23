`ifndef AXI4_VIRTUAL_TC024_SEQ_INCLUDED_
`define AXI4_VIRTUAL_TC024_SEQ_INCLUDED_
class axi4_virtual_tc024_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_tc024_seq)
  axi4_master_bk_write_wrap4_seq axi4_master_seq_h;
  axi4_slave_bk_write_seq axi4_slave_seq_h;
  extern function new(string name = "axi4_virtual_tc024_seq");
  extern task body();
endclass : axi4_virtual_tc024_seq

function axi4_virtual_tc024_seq::new(string name = "axi4_virtual_tc024_seq");
  super.new(name);
endfunction : new

task axi4_virtual_tc024_seq::body();
  axi4_master_seq_h = axi4_master_bk_write_wrap4_seq::type_id::create("axi4_master_seq_h");
  axi4_slave_seq_h  = axi4_slave_bk_write_seq::type_id::create("axi4_slave_seq_h");
  fork
    begin : SL
      forever axi4_slave_seq_h.start(p_sequencer.axi4_slave_write_seqr_h);
    end
  join_none
  axi4_master_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
endtask : body

`endif
