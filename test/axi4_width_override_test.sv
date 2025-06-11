`ifndef AXI4_WIDTH_OVERRIDE_TEST_INCLUDED_
`define AXI4_WIDTH_OVERRIDE_TEST_INCLUDED_

//------------------------------------------------------------------------------
// Class: axi4_width_override_test
// Simple test that overrides address and data widths using the config class
//------------------------------------------------------------------------------
class axi4_width_override_test extends axi4_base_test;
  `uvm_component_utils(axi4_width_override_test)

  extern function new(string name="axi4_width_override_test", uvm_component parent=null);
  extern function void setup_axi4_env_cfg();
endclass : axi4_width_override_test

function axi4_width_override_test::new(string name="axi4_width_override_test", uvm_component parent=null);
  super.new(name, parent);
endfunction : new

function void axi4_width_override_test::setup_axi4_env_cfg();
  super.setup_axi4_env_cfg();

  // Override widths for all masters
  foreach (axi4_env_cfg_h.master_address_width[i]) begin
    axi4_env_cfg_h.master_address_width[i] = 64;
    axi4_env_cfg_h.master_data_width[i]    = 128;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].address_width = 64;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].data_width    = 128;
  end

  // Override widths for all slaves
  foreach (axi4_env_cfg_h.slave_address_width[i]) begin
    axi4_env_cfg_h.slave_address_width[i] = 32;
    axi4_env_cfg_h.slave_data_width[i]    = 64;
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].address_width = 32;
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].data_width    = 64;
  end
endfunction : setup_axi4_env_cfg

`endif
