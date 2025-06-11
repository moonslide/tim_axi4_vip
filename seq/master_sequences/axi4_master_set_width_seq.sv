`ifndef AXI4_MASTER_SET_WIDTH_SEQ_INCLUDED_
`define AXI4_MASTER_SET_WIDTH_SEQ_INCLUDED_

class axi4_master_set_width_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_set_width_seq)
  `uvm_declare_p_sequencer(axi4_master_write_sequencer)

  int address_width;
  int data_width;

  extern function new(string name = "axi4_master_set_width_seq");
  extern task body();
endclass : axi4_master_set_width_seq

function axi4_master_set_width_seq::new(string name = "axi4_master_set_width_seq");
  super.new(name);
endfunction : new

task axi4_master_set_width_seq::body();
  super.body();
  if(!$cast(p_sequencer,m_sequencer)) begin
    `uvm_error(get_full_name(),"sequencer cast failed")
  end
  p_sequencer.axi4_master_agent_cfg_h.address_width = address_width;
  p_sequencer.axi4_master_agent_cfg_h.data_width    = data_width;

  // Update the master configuration connected to this sequencer
endtask : body

`endif
