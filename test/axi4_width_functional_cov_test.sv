`ifndef AXI4_WIDTH_FUNCTIONAL_COV_TEST_INCLUDED_
`define AXI4_WIDTH_FUNCTIONAL_COV_TEST_INCLUDED_

//------------------------------------------------------------------------------
// Class: axi4_width_functional_cov_test
// Iterates through valid address and data widths to hit width coverage bins
//------------------------------------------------------------------------------
class axi4_width_functional_cov_test extends axi4_base_test;
  `uvm_component_utils(axi4_width_functional_cov_test)

  // Virtual sequence handle to generate normal traffic
  axi4_virtual_write_read_seq axi4_virtual_write_read_seq_h;

  extern function new(string name="axi4_width_functional_cov_test", uvm_component parent=null);
  extern virtual task run_phase(uvm_phase phase);
endclass : axi4_width_functional_cov_test

function axi4_width_functional_cov_test::new(string name="axi4_width_functional_cov_test", uvm_component parent=null);
  super.new(name, parent);
endfunction : new

//------------------------------------------------------------------------------
// Task: run_phase
// Loops over width combinations, updates configs, and runs traffic
//------------------------------------------------------------------------------
task axi4_width_functional_cov_test::run_phase(uvm_phase phase);
  int addr_widths[] = '{32, 64};
  int data_widths[] = '{32, 64, 128, 256, 512, 1024};

  phase.raise_objection(this);
  foreach(addr_widths[aw]) begin
    foreach(data_widths[dw]) begin
      // update master configuration
      axi4_env_cfg_h.master_address_width[0] = addr_widths[aw];
      axi4_env_cfg_h.master_data_width[0]    = data_widths[dw];
      axi4_env_cfg_h.axi4_master_agent_cfg_h[0].address_width = addr_widths[aw];
      axi4_env_cfg_h.axi4_master_agent_cfg_h[0].data_width    = data_widths[dw];

      // update slave configuration
      axi4_env_cfg_h.slave_address_width[0] = addr_widths[aw];
      axi4_env_cfg_h.slave_data_width[0]    = data_widths[dw];
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[0].address_width = addr_widths[aw];
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[0].data_width    = data_widths[dw];

      // run basic traffic to record coverage
      axi4_virtual_write_read_seq_h = axi4_virtual_write_read_seq::type_id::create($sformatf("vseq_%0d_%0d", aw, dw));
      axi4_virtual_write_read_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
    end
  end
  phase.drop_objection(this);
endtask : run_phase

`endif
