`ifndef AXI4_WIDTH_CONFIG_TEST_INCLUDED_
`define AXI4_WIDTH_CONFIG_TEST_INCLUDED_

class axi4_width_config_test extends axi4_base_test;
  `uvm_component_utils(axi4_width_config_test)

  axi4_virtual_width_config_seq axi4_virtual_width_config_seq_h;

  extern function new(string name = "axi4_width_config_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
endclass : axi4_width_config_test

function axi4_width_config_test::new(string name = "axi4_width_config_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task axi4_width_config_test::run_phase(uvm_phase phase);
  axi4_virtual_width_config_seq_h = axi4_virtual_width_config_seq::type_id::create("axi4_virtual_width_config_seq_h");
  phase.raise_objection(this);
  axi4_virtual_width_config_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
endtask : run_phase

`endif

