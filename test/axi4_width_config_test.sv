`ifndef AXI4_WIDTH_CONFIG_TEST_INCLUDED_
`define AXI4_WIDTH_CONFIG_TEST_INCLUDED_

class axi4_width_config_test extends axi4_write_read_test;
  `uvm_component_utils(axi4_width_config_test)


  // Dynamic arrays to hold per-agent width information
  int master_addr_widths[$];
  int master_data_widths[$];
  int master_start_addr[$];
  int master_size_kb[$];

  int slave_addr_widths[$];
  int slave_data_widths[$];
  int slave_start_addr[$];
  int slave_size_kb[$];


  function new(string name="axi4_width_config_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction


  //----------------------------------------------------------------------
  // Setup configuration for AXI4 master agents
  //----------------------------------------------------------------------
  virtual function void setup_axi4_master_agent_cfg();
    super.setup_axi4_master_agent_cfg();

    master_addr_widths = '{16, 32, 32, 48};
    master_data_widths = '{32, 64, 128, 512};
    master_start_addr  = '{'h100, 'h10000, 'h00030000, 'h00050000};
    master_size_kb     = '{10, 100, 50, 10};

    foreach (axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin

      axi4_env_cfg_h.axi4_master_agent_cfg_h[i].addr_width = master_addr_widths[i];
      axi4_env_cfg_h.axi4_master_agent_cfg_h[i].data_width = master_data_widths[i];
      axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(i, master_start_addr[i]);
      axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(i,

          master_start_addr[i] + master_size_kb[i] * 1024 - 1);
    end
  endfunction

  //----------------------------------------------------------------------
  // Setup configuration for AXI4 slave agents
  //----------------------------------------------------------------------
  virtual function void setup_axi4_slave_agent_cfg();
    super.setup_axi4_slave_agent_cfg();

    slave_addr_widths = '{32, 8, 6, 40};
    slave_data_widths = '{32, 8, 256, 1024};
    slave_start_addr  = '{'h00100000, 'h00104000, 'h00110000, 'h00140000};
    slave_size_kb     = '{10, 1, 100, 100};

    foreach (axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin

      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].addr_width = slave_addr_widths[i];
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].data_width = slave_data_widths[i];
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = slave_start_addr[i];
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address =

          slave_start_addr[i] + slave_size_kb[i] * 1024 - 1;

    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    axi4_virtual_write_read_seq wr_rd_seq;

    wr_rd_seq = axi4_virtual_write_read_seq::type_id::create("wr_rd_seq");
    `uvm_info(get_type_name(), "axi4_width_config_test", UVM_LOW)

    phase.raise_objection(this);
    wr_rd_seq.start(axi4_env_h.axi4_virtual_seqr_h);
    phase.drop_objection(this);
  endtask

endclass : axi4_width_config_test

`endif
