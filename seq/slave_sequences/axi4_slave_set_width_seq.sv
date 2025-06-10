`ifndef AXI4_SLAVE_SET_WIDTH_SEQ_INCLUDED_
`define AXI4_SLAVE_SET_WIDTH_SEQ_INCLUDED_

class axi4_slave_set_width_seq extends axi4_slave_base_seq;
  `uvm_object_utils(axi4_slave_set_width_seq)
  `uvm_declare_p_sequencer(axi4_slave_write_sequencer)

  int address_width;
  int data_width;
  int index = 0;

  extern function new(string name = "axi4_slave_set_width_seq");
  extern task body();
endclass : axi4_slave_set_width_seq

function axi4_slave_set_width_seq::new(string name = "axi4_slave_set_width_seq");
  super.new(name);
endfunction : new

task axi4_slave_set_width_seq::body();
  super.body();
  if(!$cast(p_sequencer,m_sequencer)) begin
    `uvm_error(get_full_name(),"sequencer cast failed")
  end
  p_sequencer.axi4_slave_agent_cfg_h.address_width = address_width;
  p_sequencer.axi4_slave_agent_cfg_h.data_width    = data_width;

  axi4_env_config env_cfg;
  if(uvm_config_db#(axi4_env_config)::get(null, get_full_name(), "axi4_env_config", env_cfg)) begin
    if(index < env_cfg.slave_address_width.size()) begin
      env_cfg.slave_address_width[index] = address_width;
      env_cfg.slave_data_width[index]    = data_width;
      env_cfg.axi4_slave_agent_cfg_h[index].address_width = address_width;
      env_cfg.axi4_slave_agent_cfg_h[index].data_width    = data_width;
    end
  end
endtask : body

`endif
