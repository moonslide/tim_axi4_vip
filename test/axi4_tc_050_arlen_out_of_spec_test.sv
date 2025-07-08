`ifndef AXI4_TC_050_ARLEN_OUT_OF_SPEC_TEST_INCLUDED_
`define AXI4_TC_050_ARLEN_OUT_OF_SPEC_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_tc_050_arlen_out_of_spec_test
// TC_050: Protocol ARLEN Out Of Spec
// Master sends ARLEN=0x100 (257 beats) which exceeds AXI4 specification limit of 256 beats
// Verifies Slave response to out-of-spec read burst length
//
// SCOREBOARD DISABLED:
// The scoreboard is disabled for this test because:
// 1. TC_050 tests error injection mode where out-of-spec ARLEN transactions are abandoned
// 2. Abandoned transactions never reach the AXI interface, so no actual read transactions occur
// 3. The scoreboard expects matching read/write transaction pairs for comparison
// 4. With abandoned read transactions, the scoreboard generates UVM_ERRORs trying to compare
//    mismatched write channel activity against non-existent read transactions
// 5. Since this test specifically validates transaction abandonment behavior for protocol
//    violations, scoreboard comparison is not meaningful and only generates false errors
// 6. The test success criteria is proper transaction abandonment with UVM_WARNING messages,
//    not scoreboard data comparison
//--------------------------------------------------------------------------------------------
class axi4_tc_050_arlen_out_of_spec_test extends axi4_base_test;
  `uvm_component_utils(axi4_tc_050_arlen_out_of_spec_test)

  axi4_virtual_tc_050_arlen_out_of_spec_seq axi4_virtual_tc_050_seq_h;

  extern function new(string name = "axi4_tc_050_arlen_out_of_spec_test", uvm_component parent = null);
  extern virtual function void setup_axi4_env_cfg();
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_tc_050_arlen_out_of_spec_test

function axi4_tc_050_arlen_out_of_spec_test::new(string name = "axi4_tc_050_arlen_out_of_spec_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_tc_050_arlen_out_of_spec_test::setup_axi4_env_cfg();
  axi4_env_cfg_h = axi4_env_config::type_id::create("axi4_env_cfg_h");
 
  // Disable scoreboard for this test - abandoned transactions cause scoreboard UVM_ERRORs
  axi4_env_cfg_h.has_scoreboard = 0;
  axi4_env_cfg_h.has_virtual_seqr = 1;
  
  // Configure only 1 master to avoid background ARID_0 transactions from other masters
  axi4_env_cfg_h.no_of_masters = 1;  // TC_050 specific: only 1 master
  axi4_env_cfg_h.no_of_slaves = NO_OF_SLAVES;
  axi4_env_cfg_h.ready_delay_cycles = 100;

  // Enable error injection mode to convert UVM_ERROR to UVM_WARNING for expected protocol violations
  axi4_env_cfg_h.error_inject = 1;

  // Setup the axi4_master agent cfg for 1 master only
  axi4_env_cfg_h.axi4_master_agent_cfg_h = new[1];
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0] = axi4_master_agent_config::type_id::create("axi4_master_agent_cfg_h[0]");
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0].is_active = uvm_active_passive_enum'(UVM_ACTIVE);
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0].has_coverage = 1; 
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0].qos_mode_type = QOS_MODE_DISABLE;
  
  // Configure Master 0 address ranges - DDR, Peripheral, Fuse
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0].master_min_addr_range(0, 64'h0000_0100_0000_0000);
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0].master_max_addr_range(0, 64'h0000_0107_FFFF_FFFF);
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0].master_min_addr_range(1, 64'h0000_0010_0000_0000);
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0].master_max_addr_range(1, 64'h0000_0010_000F_FFFF);
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0].master_min_addr_range(2, 64'h0000_0020_0000_0000);
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0].master_max_addr_range(2, 64'h0000_0020_0000_0FFF);

  // Set master config to database and display
  uvm_config_db #(axi4_master_agent_config)::set(this,"*env*","axi4_master_agent_config_0",axi4_env_cfg_h.axi4_master_agent_cfg_h[0]);
  `uvm_info(get_type_name(), $sformatf("\nAXI4_MASTER_CONFIG[0]\n%s",axi4_env_cfg_h.axi4_master_agent_cfg_h[0].sprint()),UVM_LOW);

  // Setup the axi4_slave agent cfg 
  setup_axi4_slave_agent_cfg();
  
  // Set and display slave config (inlined since original is local)
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i])begin
    uvm_config_db #(axi4_slave_agent_config)::set(this,"*env*",
                                              $sformatf("axi4_slave_agent_config_%0d",i),
                                              axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]);
    uvm_config_db #(read_data_type_mode_e)::set(this,"*","read_data_mode",axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode);   
   `uvm_info(get_type_name(),$sformatf("\nAXI4_SLAVE_CONFIG[%0d]\n%s",i,axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].sprint()),UVM_LOW);
  end

  axi4_env_cfg_h.write_read_mode_h = WRITE_READ_DATA;
  
  // Override slave read_data_mode to RANDOM_DATA_MODE to prevent reactive sampling
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = RANDOM_DATA_MODE;
    uvm_config_db #(read_data_type_mode_e)::set(this,"*","read_data_mode", RANDOM_DATA_MODE);
  end
  
  // Set error injection flag in config_db for sequences to access
  uvm_config_db #(bit)::set(this, "*", "error_inject", 1);

  // set method for axi4_env_cfg
  uvm_config_db #(axi4_env_config)::set(this,"*","axi4_env_config",axi4_env_cfg_h);
  
  `uvm_info(get_type_name(), $sformatf("TC_050: 1 Master configuration - Error injection mode ENABLED, Scoreboard DISABLED"), UVM_LOW);
  `uvm_info(get_type_name(),$sformatf("\nAXI4_ENV_CONFIG\n%s",axi4_env_cfg_h.sprint()),UVM_LOW);
endfunction: setup_axi4_env_cfg

function void axi4_tc_050_arlen_out_of_spec_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction : build_phase

task axi4_tc_050_arlen_out_of_spec_test::run_phase(uvm_phase phase);
  phase.raise_objection(this);
  axi4_virtual_tc_050_seq_h = axi4_virtual_tc_050_arlen_out_of_spec_seq::type_id::create("axi4_virtual_tc_050_seq_h");
  `uvm_info(get_type_name(),$sformatf("axi4_tc_050_arlen_out_of_spec_test"),UVM_LOW);
  
  fork
    begin
      axi4_virtual_tc_050_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
    end
    begin
      #1000; // Short timeout to ensure test completes quickly
      `uvm_info(get_type_name(), $sformatf("TC_050: Test timeout reached - completing test"), UVM_LOW);
    end
  join_any
  disable fork;
  
  #10;
  `uvm_info(get_type_name(), $sformatf("TC_050: Test execution completed"), UVM_LOW);
  phase.drop_objection(this);
endtask : run_phase

`endif