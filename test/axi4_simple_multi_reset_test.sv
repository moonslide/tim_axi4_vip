`ifndef AXI4_SIMPLE_MULTI_RESET_TEST_INCLUDED_
`define AXI4_SIMPLE_MULTI_RESET_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_simple_multi_reset_test
// Simple test to verify multiple reset events work correctly on different interfaces
// Tests individual master/slave resets and global resets across all bus modes
//--------------------------------------------------------------------------------------------
class axi4_simple_multi_reset_test extends axi4_base_test;
  `uvm_component_utils(axi4_simple_multi_reset_test)
  
  // Expected reset counts for checker validation
  int expected_master_resets[10];
  int expected_slave_resets[10];
  int expected_global_resets = 0;

  extern function new(string name = "axi4_simple_multi_reset_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern function void setup_axi4_env_cfg();
  extern task run_phase(uvm_phase phase);

endclass : axi4_simple_multi_reset_test

function axi4_simple_multi_reset_test::new(string name = "axi4_simple_multi_reset_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_simple_multi_reset_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Disable error injection for reset testing
  uvm_config_db#(bit)::set(this, "*", "error_inject", 0);
  uvm_config_db#(bit)::set(this, "*", "x_inject_enable", 0);
endfunction : build_phase

function void axi4_simple_multi_reset_test::setup_axi4_env_cfg();
  super.setup_axi4_env_cfg();
  
  // Enable reset checker for verification
  axi4_env_cfg_h.has_reset_checker = 1;
  
  // Disable scoreboard for reset testing as we're not running transactions
  axi4_env_cfg_h.has_scoreboard = 0;
  
  // Configure based on bus matrix mode
  if(axi4_env_cfg_h.bus_matrix_mode != axi4_bus_matrix_ref::NONE) begin
    // For non-NONE modes, set slaves to reset test mode
    foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].reset_test_mode = 1;
    end
  end else begin
    // For NONE mode, set slaves to PASSIVE
    foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].is_active = uvm_active_passive_enum'(UVM_PASSIVE);
    end
  end
endfunction : setup_axi4_env_cfg

task axi4_simple_multi_reset_test::run_phase(uvm_phase phase);
  int num_masters = axi4_env_cfg_h.no_of_masters;
  int num_slaves = axi4_env_cfg_h.no_of_slaves;
  string bus_mode_str = axi4_env_cfg_h.bus_matrix_mode.name();
  
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "  SIMPLE MULTI-INTERFACE RESET TEST", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Bus Mode: %s", bus_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Masters: %0d, Slaves: %0d", num_masters, num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Initialize expected reset counts
  for(int i = 0; i < 10; i++) begin
    expected_master_resets[i] = 0;
    expected_slave_resets[i] = 0;
  end
  expected_global_resets = 0;
  
  // Wait for initial stabilization
  #100ns;
  
  //--------------------------------------------------------------------------------------------
  // Stage 1: Individual Master Resets
  //--------------------------------------------------------------------------------------------
  `uvm_info(get_type_name(), "Stage 1: Testing individual master resets", UVM_LOW)
  
  for(int i = 0; i < num_masters; i++) begin
    `uvm_info(get_type_name(), $sformatf("Resetting Master[%0d] for %0d cycles", i, 5+i), UVM_LOW)
    
    uvm_config_db#(int)::set(null, "*", $sformatf("reset_duration_master_%0d", i), 5+i);
    uvm_config_db#(bit)::set(null, "*", $sformatf("inject_reset_master_%0d", i), 1);
    
    expected_master_resets[i]++;
    
    #((5+i+5) * 10ns);
  end
  
  #100ns;
  
  //--------------------------------------------------------------------------------------------
  // Stage 2: Individual Slave Resets (if applicable)
  //--------------------------------------------------------------------------------------------
  if(axi4_env_cfg_h.bus_matrix_mode != axi4_bus_matrix_ref::NONE) begin
    `uvm_info(get_type_name(), "Stage 2: Testing individual slave resets", UVM_LOW)
    
    for(int i = 0; i < num_slaves; i++) begin
      `uvm_info(get_type_name(), $sformatf("Resetting Slave[%0d] for %0d cycles", i, 5+i), UVM_LOW)
      
      uvm_config_db#(int)::set(null, "*", $sformatf("reset_duration_slave_%0d", i), 5+i);
      uvm_config_db#(bit)::set(null, "*", $sformatf("inject_reset_slave_%0d", i), 1);
      
      expected_slave_resets[i]++;
      
      #((5+i+5) * 10ns);
    end
  end else begin
    `uvm_info(get_type_name(), "Stage 2: Skipping slave resets (NONE mode)", UVM_LOW)
  end
  
  #100ns;
  
  //--------------------------------------------------------------------------------------------
  // Stage 3: Simultaneous Master Resets (skip for now to simplify)
  //--------------------------------------------------------------------------------------------
  // Skip simultaneous reset to avoid confusion in counting
  `uvm_info(get_type_name(), "Stage 3: Skipping simultaneous resets (simplified test)", UVM_LOW)
  
  //--------------------------------------------------------------------------------------------
  // Stage 4: Global Reset
  //--------------------------------------------------------------------------------------------
  `uvm_info(get_type_name(), "Stage 4: Testing global reset", UVM_LOW)
  
  uvm_config_db#(int)::set(null, "*", "reset_duration_cycles", 10);
  uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);
  
  expected_global_resets++;
  
  #200ns;
  
  //--------------------------------------------------------------------------------------------
  // Configure reset checker with expected values
  //--------------------------------------------------------------------------------------------
  if(axi4_env_h.axi4_reset_checker_h != null) begin
    axi4_env_h.axi4_reset_checker_h.set_expected_resets(expected_master_resets, expected_slave_resets, expected_global_resets);
  end
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Simple Multi-Reset Test Completed", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

`endif