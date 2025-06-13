`ifndef AXI4_WIDTH_CHECK_TEST_INCLUDED_
`define AXI4_WIDTH_CHECK_TEST_INCLUDED_

class axi4_width_check_test extends axi4_width_config_test;
  `uvm_component_utils(axi4_width_check_test)

  extern function new(string name="axi4_width_check_test", uvm_component parent=null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
endclass : axi4_width_check_test

function axi4_width_check_test::new(string name="axi4_width_check_test",
                                    uvm_component parent=null);
  super.new(name, parent);
endfunction : new

function void axi4_width_check_test::build_phase(uvm_phase phase);
  super.build_phase(phase);

  foreach (axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    if ((axi4_env_cfg_h.axi4_master_agent_cfg_h[i].addr_width < 1) ||
        (axi4_env_cfg_h.axi4_master_agent_cfg_h[i].addr_width > 64)) begin
      `uvm_fatal("WIDTH_RANGE",
                 $sformatf("Master[%0d] address width %0d out of range",
                          i,
                          axi4_env_cfg_h.axi4_master_agent_cfg_h[i].addr_width))
    end

    if ((axi4_env_cfg_h.axi4_master_agent_cfg_h[i].addr_width > ADDRESS_WIDTH) ||
        (axi4_env_cfg_h.axi4_master_agent_cfg_h[i].data_width > DATA_WIDTH)) begin
      `uvm_fatal("WIDTH_MISMATCH",
                 $sformatf("Master[%0d] width exceeds interface: addr %0d data %0d",
                          i,
                          axi4_env_cfg_h.axi4_master_agent_cfg_h[i].addr_width,
                          axi4_env_cfg_h.axi4_master_agent_cfg_h[i].data_width))
    end
  end

  foreach (axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    if ((axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].addr_width < 1) ||
        (axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].addr_width > 64)) begin
      `uvm_fatal("WIDTH_RANGE",
                 $sformatf("Slave[%0d] address width %0d out of range",
                          i,
                          axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].addr_width))
    end

    if ((axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].addr_width > ADDRESS_WIDTH) ||
        (axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].data_width > DATA_WIDTH)) begin
      `uvm_fatal("WIDTH_MISMATCH",
                 $sformatf("Slave[%0d] width exceeds interface: addr %0d data %0d",
                          i,
                          axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].addr_width,
                          axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].data_width))
    end
  end
endfunction : build_phase

task axi4_width_check_test::run_phase(uvm_phase phase);
  super.run_phase(phase);
endtask : run_phase

`endif
