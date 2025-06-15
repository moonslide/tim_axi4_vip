`ifndef AXI4_AW_W_CHANNEL_SEPARATION_TEST_INCLUDED_
`define AXI4_AW_W_CHANNEL_SEPARATION_TEST_INCLUDED_

class axi4_aw_w_channel_separation_test extends axi4_base_test;
  `uvm_component_utils(axi4_aw_w_channel_separation_test)

  axi4_virtual_aw_w_channel_separation_seq vseq;

  function void setup_axi4_env_cfg();
    super.setup_axi4_env_cfg();
    axi4_env_cfg_h.write_read_mode_h = ONLY_WRITE_DATA;
    axi4_env_cfg_h.check_wait_states = 1;
    uvm_config_db#(axi4_env_config)::set(this,"*","axi4_env_config",axi4_env_cfg_h);
  endfunction: setup_axi4_env_cfg

  function new(string name="axi4_aw_w_channel_separation_test", uvm_component parent=null);
    super.new(name,parent);
  endfunction

  task run_phase(uvm_phase phase);
    vseq = axi4_virtual_aw_w_channel_separation_seq::type_id::create("vseq");
    phase.raise_objection(this);
    vseq.start(axi4_env_h.axi4_virtual_seqr_h);
    phase.drop_objection(this);
  endtask
endclass

`endif
