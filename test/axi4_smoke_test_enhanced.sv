`ifndef AXI4_SMOKE_TEST_ENHANCED_INCLUDED_
`define AXI4_SMOKE_TEST_ENHANCED_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_smoke_test_enhanced  
// Simple smoke test to verify ENHANCED mode basic functionality
//--------------------------------------------------------------------------------------------
class axi4_smoke_test_enhanced extends axi4_base_test;
  `uvm_component_utils(axi4_smoke_test_enhanced)

  // Sequence handles
  axi4_master_bk_write_seq write_seq;
  axi4_master_bk_read_seq read_seq;
  
  extern function new(string name = "axi4_smoke_test_enhanced", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_smoke_test_enhanced

function axi4_smoke_test_enhanced::new(string name = "axi4_smoke_test_enhanced", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_smoke_test_enhanced::build_phase(uvm_phase phase);
  // Create and configure test_config BEFORE calling super.build_phase
  test_config = axi4_test_config::type_id::create("test_config");
  
  // Force ENHANCED mode configuration
  test_config.bus_matrix_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
  test_config.num_masters = 10;
  test_config.num_slaves = 10;
  
  // Set in config_db so parent class will use it
  uvm_config_db#(axi4_test_config)::set(this, "*", "test_config", test_config);
  
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "AXI4 SMOKE TEST - ENHANCED MODE", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Masters: %0d, Slaves: %0d", test_config.num_masters, test_config.num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  
  // Now call parent's build_phase which will use our test_config
  super.build_phase(phase);
  
  // Disable coverage for this simple test after configs are created
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].has_coverage = 0;
  end
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].has_coverage = 0;
  end
  
endfunction : build_phase

task axi4_smoke_test_enhanced::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Starting smoke test in ENHANCED mode", UVM_LOW)
  
  phase.raise_objection(this);
  
  // Very simple test - just one write and one read
  write_seq = axi4_master_bk_write_seq::type_id::create("write_seq");
  read_seq = axi4_master_bk_read_seq::type_id::create("read_seq");
  
  fork
    begin
      // Timeout watchdog
      #10us;
      `uvm_warning(get_type_name(), "Test timeout reached")
    end
    begin
      // Run simple write on master 0
      `uvm_info(get_type_name(), "Starting write sequence on Master[0]", UVM_LOW)
      write_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
      `uvm_info(get_type_name(), "Write sequence completed", UVM_LOW)
      
      #100ns;
      
      // Run simple read on master 0
      `uvm_info(get_type_name(), "Starting read sequence on Master[0]", UVM_LOW)
      read_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_read_seqr_h);
      `uvm_info(get_type_name(), "Read sequence completed", UVM_LOW)
    end
  join_any
  
  // Kill any remaining threads
  disable fork;
  
  #100ns;
  
  `uvm_info(get_type_name(), "Smoke test completed", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

`endif