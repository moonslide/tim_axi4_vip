`ifndef AXI4_VIRTUAL_AR_READY_DELAY_SEQ_INCLUDED_
`define AXI4_VIRTUAL_AR_READY_DELAY_SEQ_INCLUDED_

class axi4_virtual_ar_ready_delay_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_ar_ready_delay_seq)

  axi4_master_ar_ready_delay_seq m_seq;
  axi4_slave_ar_ready_delay_seq s_seq;

  extern function new(string name="axi4_virtual_ar_ready_delay_seq");
  extern task body();
endclass : axi4_virtual_ar_ready_delay_seq

function axi4_virtual_ar_ready_delay_seq::new(string name="axi4_virtual_ar_ready_delay_seq");
  super.new(name);
endfunction : new

task axi4_virtual_ar_ready_delay_seq::body();
  m_seq = axi4_master_ar_ready_delay_seq::type_id::create("m_seq");
  s_seq = axi4_slave_ar_ready_delay_seq::type_id::create("s_seq");
  fork
    s_seq.start(p_sequencer.axi4_slave_read_seqr_h);
  join_none
  m_seq.start(p_sequencer.axi4_master_read_seqr_h);
endtask : body

`endif
