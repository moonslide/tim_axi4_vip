`ifndef TC_035_TEST_INCLUDED_
`define TC_035_TEST_INCLUDED_
class tc_035_test extends axi4_base_test;
  `uvm_component_utils(tc_035_test)
  axi4_virtual_tc035_seq tc_seq_h;
  extern function new(string name = "tc_035_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual function void setup_axi4_env_cfg();
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();

endclass : tc_035_test

function tc_035_test::new(string name = "tc_035_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task tc_035_test::run_phase(uvm_phase phase);
  time wait_start; 
  tc_seq_h = axi4_virtual_tc035_seq::type_id::create("tc_seq_h");
  phase.raise_objection(this);
  // Preload unaligned address for read check
  axi4_env_h.axi4_scoreboard_h.preload_memory(0, 32'h00001001, 32'hFACE1001);
  tc_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  // Wait for the scoreboard to process the read response
  wait_start = $time;
  `uvm_info("TC035", $sformatf("Waiting for scoreboard response @ %0t", wait_start), UVM_LOW)
  wait (axi4_env_h.axi4_scoreboard_h.axi4_slave_tx_rresp_count > 0);
  `uvm_info("TC035", $sformatf("Scoreboard responded after %0t", $time - wait_start), UVM_LOW)
  if(axi4_env_h.axi4_scoreboard_h.axi4_slave_tx_h5.rresp != READ_SLVERR)
    `uvm_error("TC035", $sformatf("Expected SLVERR but got %s",axi4_env_h.axi4_scoreboard_h.axi4_slave_tx_h5.rresp.name()))
  phase.drop_objection(this);
endtask : run_phase

`endif

function void tc_035_test::setup_axi4_env_cfg();
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
  axi4_env_cfg_h.write_read_mode_h = ONLY_READ_DATA;
  uvm_config_db#(axi4_env_config)::set(this,"*","axi4_env_config",axi4_env_cfg_h);
endfunction : setup_axi4_env_cfg

function void tc_035_test::setup_axi4_master_agent_cfg();
  axi4_env_cfg_h.axi4_master_agent_cfg_h = new[1];
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0] = axi4_master_agent_config::type_id::create("mcfg");
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0].master_min_addr_range(0,32'h00001000);
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0].master_max_addr_range(0,32'h00001FFF);
endfunction

function void tc_035_test::setup_axi4_slave_agent_cfg();
  axi4_env_cfg_h.axi4_slave_agent_cfg_h = new[1];
  axi4_env_cfg_h.axi4_slave_agent_cfg_h[0] = axi4_slave_agent_config::type_id::create("scfg");
  axi4_env_cfg_h.axi4_slave_agent_cfg_h[0].min_address = 32'h00001000;
  axi4_env_cfg_h.axi4_slave_agent_cfg_h[0].max_address = 32'h00001FFF;
  axi4_env_cfg_h.axi4_slave_agent_cfg_h[0].read_data_mode = SLAVE_MEM_MODE;
  axi4_env_cfg_h.axi4_slave_agent_cfg_h[0].invalid_read_resp = READ_SLVERR;
endfunction
