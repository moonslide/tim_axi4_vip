`ifndef AXI4_WIDTH_CONFIG_TEST_INCLUDED_
`define AXI4_WIDTH_CONFIG_TEST_INCLUDED_

class axi4_width_config_test extends axi4_write_read_test;
  `uvm_component_utils(axi4_width_config_test)

  extern function new(string name = "axi4_width_config_test", uvm_component parent = null);
  extern function void setup_axi4_env_cfg();
endclass : axi4_width_config_test

function axi4_width_config_test::new(string name = "axi4_width_config_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_width_config_test::setup_axi4_env_cfg();
  super.setup_axi4_env_cfg();
  axi4_env_cfg_h.master_address_width[0] = 64;
  axi4_env_cfg_h.master_data_width[0]    = 128;
  axi4_env_cfg_h.slave_address_width[0]  = 32;
  axi4_env_cfg_h.slave_data_width[0]     = 256;
endfunction : setup_axi4_env_cfg

`endif

