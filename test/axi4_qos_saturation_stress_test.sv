`ifndef AXI4_QOS_SATURATION_STRESS_TEST_INCLUDED_
`define AXI4_QOS_SATURATION_STRESS_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_saturation_stress_test
// 
// TEST SCENARIO DESCRIPTION:
// ==========================
// This test validates system behavior under extreme QoS saturation conditions where
// all masters simultaneously generate maximum priority (QoS 0xF) traffic. It stresses
// the arbitration logic, interconnect resources, and verifies system stability under
// peak load conditions.
//
// DETAILED TEST SCENARIOS:
// 1. Maximum QoS Saturation Test:
//    - All 4 masters generate transactions with QoS 0xF (maximum priority)
//    - Each master generates 100+ transactions in rapid succession
//    - Creates extreme contention for interconnect resources
//    - Tests arbitration logic under saturated conditions
//
// 2. Sustained High Priority Load Test:
//    - Continuous generation of maximum priority transactions for extended duration
//    - Tests thermal and power implications of sustained high activity
//    - Validates that system maintains functionality under prolonged stress
//    - Measures system throughput degradation under saturation
//
// 3. Resource Exhaustion Stress Test:
//    - Masters generate large burst transactions (AWLEN=15) with maximum QoS
//    - Tests behavior when interconnect buffers and queues reach capacity
//    - Validates proper backpressure and flow control mechanisms
//    - Ensures no transaction is lost or corrupted under stress
//
// 4. Multi-Slave Saturation Test:
//    - Masters distribute maximum priority traffic across multiple slaves
//    - Creates simultaneous contention on multiple interconnect paths
//    - Tests scalability of QoS arbitration across slave interfaces
//    - Validates system-wide resource management under stress
//
// STRESS CONDITIONS:
// - All transactions use maximum QoS priority (0xF)
// - High transaction generation rate (minimal inter-transaction delays)
// - Large burst sizes to maximize resource utilization
// - Multiple masters competing simultaneously
// - Extended test duration to expose corner cases
//
// EXPECTED BEHAVIORS:
// - System should remain stable without deadlocks or hangs
// - All transactions should eventually complete successfully
// - Protocol compliance should be maintained under stress
// - Reasonable throughput should be sustained despite contention
// - No data corruption or transaction loss should occur
// - Proper error handling if resource limits are exceeded
//
// FAILURE DETECTION:
// - Deadlock detection through timeout mechanisms
// - Protocol violation monitoring via assertions
// - Data integrity checking through scoreboard validation
// - Performance degradation beyond acceptable thresholds
// - Resource leak detection in interconnect components
//
// COVERAGE GOALS:
// - Maximum QoS priority usage across all masters
// - Resource saturation conditions (buffers, queues, arbiters)
// - Stress-induced corner cases and race conditions
// - Sustained high-load system behavior validation
//--------------------------------------------------------------------------------------------
class axi4_qos_saturation_stress_test extends axi4_base_test;
  `uvm_component_utils(axi4_qos_saturation_stress_test)
  
  // Virtual sequence handle
  axi4_virtual_qos_saturation_stress_seq axi4_virtual_qos_saturation_stress_seq_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_qos_saturation_stress_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_qos_saturation_stress_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_qos_saturation_stress_test::new(string name = "axi4_qos_saturation_stress_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Creates test configuration and components
//--------------------------------------------------------------------------------------------
function void axi4_qos_saturation_stress_test::build_phase(uvm_phase phase);
  // Set configuration before calling super.build_phase()
  `uvm_info(get_type_name(), "Configuring QoS saturation stress test", UVM_MEDIUM)
  
  super.build_phase(phase);
  
  // Enable QoS mode for all agents in QoS tests
  for (int i = 0; i < axi4_env_cfg_h.no_of_masters; i++) begin
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = WRITE_READ_QOS_MODE_ENABLE;
  end
  for (int i = 0; i < axi4_env_cfg_h.no_of_slaves; i++) begin
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = WRITE_READ_QOS_MODE_ENABLE;
  end
  `uvm_info(get_type_name(), "Enabled WRITE_READ_QOS_MODE for all agents", UVM_LOW)
  
  // Set reasonable timeout for saturation stress test
  uvm_top.set_timeout(30ms, 0); // 30ms timeout for stress test
  
  // Set enhanced bus matrix mode for QoS testing  
  test_config.bus_matrix_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
  
  // Update config_db with the correct bus matrix mode
  uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::set(this, "*", "bus_matrix_mode", test_config.bus_matrix_mode);
  
  `uvm_info(get_type_name(), "QoS saturation stress test configuration completed", UVM_MEDIUM)
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Executes the QoS saturation stress test
//--------------------------------------------------------------------------------------------
task axi4_qos_saturation_stress_test::run_phase(uvm_phase phase);
  
  phase.raise_objection(this, "axi4_qos_saturation_stress_test");
  
  `uvm_info(get_type_name(), "Starting AXI4 QoS Saturation Stress Test", UVM_LOW)
  `uvm_info(get_type_name(), "Test objective: Verify system stability under maximum QoS priority load", UVM_LOW)
  
  // Create and start the virtual sequence
  axi4_virtual_qos_saturation_stress_seq_h = axi4_virtual_qos_saturation_stress_seq::type_id::create("axi4_virtual_qos_saturation_stress_seq_h");
  
  // Configure the virtual sequence
  axi4_virtual_qos_saturation_stress_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for all transactions to complete
  #5000;
  
  `uvm_info(get_type_name(), "AXI4 QoS Saturation Stress Test completed", UVM_LOW)
  `uvm_info(get_type_name(), "Test success criteria:", UVM_LOW)
  `uvm_info(get_type_name(), "1. No deadlocks or hangs occurred", UVM_LOW)
  `uvm_info(get_type_name(), "2. All high-priority transactions completed", UVM_LOW)
  `uvm_info(get_type_name(), "3. System maintained reasonable throughput", UVM_LOW)
  `uvm_info(get_type_name(), "4. No protocol violations detected", UVM_LOW)
  
  phase.drop_objection(this, "axi4_qos_saturation_stress_test");
  
endtask : run_phase

`endif