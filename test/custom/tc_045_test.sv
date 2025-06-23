`ifndef TC_045_TEST_INCLUDED_
`define TC_045_TEST_INCLUDED_
class tc_045_test extends axi4_base_test;
  `uvm_component_utils(tc_045_test)
  axi4_virtual_tc045_seq tc_seq_h;
  extern function new(string name = "tc_045_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual function void setup_axi4_env_cfg();
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();

endclass : tc_045_test

function tc_045_test::new(string name = "tc_045_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task tc_045_test::run_phase(uvm_phase phase);
  tc_seq_h = axi4_virtual_tc045_seq::type_id::create("tc_seq_h");
  phase.raise_objection(this);
  tc_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
endtask : run_phase

`endif

function void tc_045_test::setup_axi4_env_cfg();
  axi4_env_cfg_h = axi4_env_config::type_id::create("axi4_env_cfg_h");
  axi4_env_cfg_h.has_scoreboard = 1;
  axi4_env_cfg_h.has_virtual_seqr = 1;
  axi4_env_cfg_h.no_of_masters = 1;
  axi4_env_cfg_h.no_of_slaves = 1;
  axi4_env_cfg_h.ready_delay_cycles = 100;
  setup_axi4_master_agent_cfg();
  set_and_display_master_config();
  setup_axi4_slave_agent_cfg();
  set_and_display_slave_config();
  axi4_env_cfg_h.write_read_mode_h = ONLY_WRITE_DATA;
  uvm_config_db#(axi4_env_config)::set(this,"*","axi4_env_config",axi4_env_cfg_h);
endfunction : setup_axi4_env_cfg

function void tc_045_test::setup_axi4_master_agent_cfg();
  axi4_env_cfg_h.axi4_master_agent_cfg_h = new[1];
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0] = axi4_master_agent_config::type_id::create("mcfg");
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0].master_min_addr_range(0,32'h00004000);
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0].master_max_addr_range(0,32'h00004FFF);
endfunction

function void tc_045_test::setup_axi4_slave_agent_cfg();
  axi4_env_cfg_h.axi4_slave_agent_cfg_h = new[1];
  axi4_env_cfg_h.axi4_slave_agent_cfg_h[0] = axi4_slave_agent_config::type_id::create("scfg");
  axi4_env_cfg_h.axi4_slave_agent_cfg_h[0].min_address = 32'h00004000;
  axi4_env_cfg_h.axi4_slave_agent_cfg_h[0].max_address = 32'h00004FFF;
endfunction
