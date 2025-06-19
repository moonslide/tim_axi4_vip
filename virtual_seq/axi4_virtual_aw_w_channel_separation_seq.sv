`ifndef AXI4_VIRTUAL_AW_W_CHANNEL_SEPARATION_SEQ_INCLUDED_
`define AXI4_VIRTUAL_AW_W_CHANNEL_SEPARATION_SEQ_INCLUDED_

class axi4_virtual_aw_w_channel_separation_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_aw_w_channel_separation_seq)

  axi4_master_aw_w_channel_separation_seq m_seq;
  axi4_slave_aw_w_channel_separation_seq s_seq;

  extern function new(string name="axi4_virtual_aw_w_channel_separation_seq");
  extern task body();
endclass : axi4_virtual_aw_w_channel_separation_seq

function axi4_virtual_aw_w_channel_separation_seq::new(string name="axi4_virtual_aw_w_channel_separation_seq");
  super.new(name);
endfunction : new

task axi4_virtual_aw_w_channel_separation_seq::body();
  foreach (p_sequencer.axi4_master_write_seqr_h_all[i]) begin
    axi4_master_aw_w_channel_separation_seq m_seq_local;
    axi4_slave_aw_w_channel_separation_seq s_seq_local;
    m_seq_local = axi4_master_aw_w_channel_separation_seq::type_id::create($sformatf("m_seq_%0d", i));
    s_seq_local = axi4_slave_aw_w_channel_separation_seq::type_id::create($sformatf("s_seq_%0d", i));
    fork
      s_seq_local.start(p_sequencer.axi4_slave_write_seqr_h_all[i]);
    join_none
    m_seq_local.start(p_sequencer.axi4_master_write_seqr_h_all[i]);
  end
endtask : body

`endif
