`ifndef AXI4_QOS_BASIC_PRIORITY_TEST_INCLUDED_
`define AXI4_QOS_BASIC_PRIORITY_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_basic_priority_test
// 
// TEST SCENARIO DESCRIPTION:
// ==========================
// This test validates the fundamental QoS (Quality of Service) priority arbitration mechanism
// in the AXI4 bus matrix system. It verifies that transactions with higher QoS values receive
// priority treatment over lower QoS transactions across multiple masters and slaves.
//
// DETAILED TEST SCENARIOS:
// 1. QoS Priority Order Test:
//    - Master generates 4 transactions with QoS values: 0xF (highest), 0x8, 0x4, 0x0 (lowest)
//    - Validates that higher QoS transactions are serviced before lower QoS transactions
//    - Tests both write and read channels independently
//
// 2. Equal Priority Fairness Test:
//    - Multiple masters generate transactions with identical QoS values (0x8)
//    - Verifies round-robin or fair arbitration when QoS priorities are equal
//    - Ensures no master is starved when all have equal priority
//
// 3. Mixed Priority Multi-Master Test:
//    - 4 masters simultaneously generate transactions with different QoS levels
//    - Master 0: QoS 0xF (critical priority)
//    - Master 1: QoS 0xC (high priority)  
//    - Master 2: QoS 0x8 (medium priority)
//    - Master 3: QoS 0x4 (low priority)
//    - Validates correct priority ordering across all masters
//
// EXPECTED BEHAVIORS:
// - Transactions with QoS 0xF should always be serviced first
// - Within same QoS level, fair arbitration should occur
// - Lower QoS transactions should wait for higher QoS completion
// - No deadlock or starvation should occur even with priority differences
// - Bus matrix should maintain QoS ordering while preserving AXI protocol compliance
//
// COVERAGE GOALS:
// - All QoS priority levels (0x0 to 0xF)
// - Multi-master QoS interaction scenarios
// - Write and read channel QoS handling
// - Priority arbitration fairness validation
// 
// Uses enhanced 4x4 bus matrix configuration (scaled from 10x10 specification)
//--------------------------------------------------------------------------------------------
class axi4_qos_basic_priority_test extends axi4_base_test;
  
  `uvm_component_utils(axi4_qos_basic_priority_test)
  
  // Virtual sequence handle
  axi4_virtual_qos_basic_priority_seq qos_priority_vseq;
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_qos_basic_priority_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_qos_basic_priority_test

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_qos_basic_priority_test::new(string name = "axi4_qos_basic_priority_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//-----------------------------------------------------------------------------
// Function: build_phase
// Configure the test for 10x10 enhanced bus matrix
//-----------------------------------------------------------------------------
function void axi4_qos_basic_priority_test::build_phase(uvm_phase phase);
  // Set configuration before calling super.build_phase()
  `uvm_info(get_type_name(), "Configuring QoS basic priority test", UVM_LOW)
  
  // Create and configure test_config BEFORE calling super.build_phase()
  test_config = axi4_test_config::type_id::create("test_config");
  test_config.configure_for_test(get_type_name());
  
  // Ensure we're using 10x10 configuration for this test BEFORE calling super.build_phase()
  if (test_config.num_masters < 10 || test_config.num_slaves < 10) begin
    `uvm_warning(get_type_name(), "QoS test designed for 10x10 bus matrix. Adjusting configuration.")
    test_config.num_masters = 10;
    test_config.num_slaves = 10;
  end
  
  // Set enhanced bus matrix mode for QoS testing BEFORE calling super.build_phase()
  test_config.bus_matrix_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
  
  // Store in config_db for use by environment and other components
  uvm_config_db#(axi4_test_config)::set(this, "*", "test_config", test_config);
  uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::set(this, "*", "bus_matrix_mode", test_config.bus_matrix_mode);
  
  super.build_phase(phase);
  
  // Enable QoS mode for all agents in QoS tests
  for (int i = 0; i < axi4_env_cfg_h.no_of_masters; i++) begin
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = WRITE_READ_QOS_MODE_ENABLE;
  end
  for (int i = 0; i < axi4_env_cfg_h.no_of_slaves; i++) begin
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = WRITE_READ_QOS_MODE_ENABLE;
  end
  `uvm_info(get_type_name(), "Enabled WRITE_READ_QOS_MODE for all agents", UVM_LOW)
  
  // Set reasonable timeout for basic priority test
  uvm_top.set_timeout(10ms, 0); // 10ms timeout for QoS test
  
  // Update config_db with the correct bus matrix mode
  uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::set(this, "*", "bus_matrix_mode", test_config.bus_matrix_mode);
  
  // Disable RREADY assertion checking during cleanup phase for QoS test
  uvm_config_db#(bit)::set(this, "*", "disable_rready_check_for_qos_cleanup", 1'b1);
  `uvm_info(get_type_name(), "Disabled RREADY assertion checking during cleanup phase for QoS test", UVM_LOW)
  
endfunction : build_phase

//-----------------------------------------------------------------------------
// Task: run_phase
// Run the QoS basic priority virtual sequence
//-----------------------------------------------------------------------------
task axi4_qos_basic_priority_test::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Starting QoS basic priority test", UVM_MEDIUM)
  
  // Create the virtual sequence
  qos_priority_vseq = axi4_virtual_qos_basic_priority_seq::type_id::create("qos_priority_vseq");
  
  phase.raise_objection(this);
  
  // Start the virtual sequence
  qos_priority_vseq.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Signal that we're entering cleanup phase
  uvm_config_db#(bit)::set(null, "*", "qos_test_cleanup_phase", 1'b1);
  
  // Add extra time for scoreboard checking
  #1000;
  
  phase.drop_objection(this);
  
  `uvm_info(get_type_name(), "QoS basic priority test completed", UVM_MEDIUM)
  
endtask : run_phase

`endif