`ifndef AXI4_AW_READY_DELAY_TEST_INCLUDED_
`define AXI4_AW_READY_DELAY_TEST_INCLUDED_

class axi4_aw_ready_delay_test extends axi4_base_test;
  `uvm_component_utils(axi4_aw_ready_delay_test)

  axi4_virtual_aw_ready_delay_seq vseq;

  function void setup_axi4_env_cfg();
    super.setup_axi4_env_cfg();
    axi4_env_cfg_h.write_read_mode_h = ONLY_WRITE_DATA;
    axi4_env_cfg_h.check_wait_states = 1;
    // landmine #56 (OPEN bullet): axi4_base_test.sv defaults every slave to
    // SLAVE_MEM_MODE, whose driver-proxy branch never calls get_next_item()
    // on the slave sequencer, so this test's own axi4_slave_aw_ready_delay_seq
    // sweep (aw_wait_states=0..6) never reaches the wire. Switch every active
    // slave to RANDOM_DATA_MODE so the sequencer-driven path runs.
    foreach (axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = RANDOM_DATA_MODE;
    end
    uvm_config_db#(axi4_env_config)::set(this,"*","axi4_env_config",axi4_env_cfg_h);

  endfunction: setup_axi4_env_cfg

  function new(string name="axi4_aw_ready_delay_test", uvm_component parent=null);
    super.new(name,parent);
  endfunction

  task run_phase(uvm_phase phase);
    vseq = axi4_virtual_aw_ready_delay_seq::type_id::create("vseq");
    phase.raise_objection(this);
    vseq.start(axi4_env_h.axi4_virtual_seqr_h);
    phase.drop_objection(this);
  endtask
endclass

`endif
