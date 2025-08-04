`ifndef AXI4_QOS_WITH_USER_PRIORITY_BOOST_TEST_INCLUDED_
`define AXI4_QOS_WITH_USER_PRIORITY_BOOST_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_with_user_priority_boost_test
//
// TEST SCENARIO DESCRIPTION:
// This comprehensive test validates QoS priority boosting mechanisms that leverage USER signal
// context information to make intelligent priority decisions. The test verifies that USER signal
// data enhances QoS arbitration beyond basic priority levels for optimal system performance.
//
// DETAILED TEST SCENARIOS:
// 1. Security-Critical Priority Boost
//    - Test maximum priority boost for security-critical transactions
//    - Verify security context overrides standard QoS arbitration
//    - Validate cryptographic operation priority elevation
//    - Test security audit transaction priority guarantees
//
// 2. Real-Time Deadline Priority Boost
//    - Test priority elevation for deadline-urgent transactions
//    - Verify temporal constraint-based priority adjustment
//    - Validate soft and hard deadline differentiation
//    - Test deadline miss prevention mechanisms
//
// 3. Emergency Context Priority Override
//    - Test emergency situation priority override mechanisms
//    - Verify safety-critical transaction immediate prioritization
//    - Validate emergency response system transaction handling
//    - Test fault recovery operation priority guarantees
//
// 4. Performance-Critical Path Boost
//    - Test priority boost for performance-critical code paths
//    - Verify hot path transaction priority elevation
//    - Validate performance bottleneck mitigation priority
//    - Test cache-critical and memory-intensive operation prioritization
//
// 5. Power-Aware Priority Adjustment
//    - Test priority reduction for power-saving contexts
//    - Verify energy-efficient transaction scheduling
//    - Validate battery life optimization priority adjustments
//    - Test dynamic voltage and frequency scaling integration
//
// 6. Deadline-Urgent Transaction Handling
//    - Test immediate priority boost for deadline-critical transactions
//    - Verify deadline proximity-based priority scaling
//    - Validate deadline miss cost assessment integration
//    - Test adaptive deadline management and priority adjustment
//
// 7. Multi-Master Priority Coordination
//    - Test priority boost coordination across multiple masters
//    - Verify independent boost mechanisms per master
//    - Validate cross-master priority conflict resolution
//    - Test global priority arbitration with individual boosts
//
// 8. Context-Aware Quality of Service
//    - Test application context-based priority adjustments
//    - Verify user experience optimization priority boosts
//    - Validate interactive vs batch workload differentiation
//    - Test multimedia and real-time application prioritization
//
// 9. Thermal Management Priority Integration
//    - Test thermal-aware priority adjustment mechanisms
//    - Verify priority reduction for high-thermal-impact operations
//    - Validate cooling system coordination with priority decisions
//    - Test thermal emergency response priority overrides
//
// 10. Machine Learning Enhanced Priority
//     - Test AI/ML-based priority boost decisions
//     - Verify predictive priority adjustment capabilities
//     - Validate learning from historical transaction patterns
//     - Test adaptive optimization based on system behavior
//
// 11. Network and I/O Priority Coordination
//     - Test network QoS integration with USER signal priorities
//     - Verify I/O subsystem priority coordination
//     - Validate storage access priority optimization
//     - Test distributed system priority synchronization
//
// 12. Dynamic Priority Boost Adjustment
//     - Test runtime priority boost parameter modification
//     - Verify adaptive boost level adjustment based on load
//     - Validate automatic boost calibration mechanisms
//     - Test priority boost effectiveness monitoring
//
// 13. Priority Boost Conflict Resolution
//     - Test handling of multiple simultaneous boost requests
//     - Verify priority boost hierarchy and precedence rules
//     - Validate conflict resolution algorithms
//     - Test fairness maintenance under boost conditions
//
// 14. System-Wide Priority Impact Analysis
//     - Test overall system performance impact of priority boosts
//     - Verify maintenance of system stability under boost conditions
//     - Validate prevention of priority inversion scenarios
//     - Test long-term system behavior with continuous boosts
//
// EXPECTED BEHAVIORS:
// - Security-critical transactions must receive maximum priority boost
// - Real-time deadlines must trigger appropriate priority elevation
// - Emergency contexts must override normal QoS arbitration completely
// - Performance-critical paths must receive consistent priority boosts
// - Power-saving contexts must appropriately reduce unnecessary high priority
// - Deadline-urgent transactions must prevent deadline misses effectively
// - Multi-master priority boosts must operate without interference
//
// COVERAGE GOALS:
// - All priority boost trigger conditions and contexts
// - Complete boost level matrix across different scenarios
// - Multi-master boost coordination and conflict scenarios
// - Integration with all USER signal feature categories
// - Dynamic boost adjustment and calibration mechanisms
// - System performance and stability under various boost loads
//
// VALIDATION CRITERIA:
// - Appropriate priority elevation for all identified boost scenarios
// - Maintained system fairness and prevention of starvation
// - Effective deadline miss prevention and performance optimization
// - Proper integration with existing QoS arbitration mechanisms
// - Sustained system stability under continuous priority boost operations
//--------------------------------------------------------------------------------------------
class axi4_qos_with_user_priority_boost_test extends axi4_base_test;
  `uvm_component_utils(axi4_qos_with_user_priority_boost_test)
  
  // Virtual sequence handle
  axi4_virtual_qos_with_user_priority_boost_seq axi4_virtual_qos_with_user_priority_boost_seq_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_qos_with_user_priority_boost_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_qos_with_user_priority_boost_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_qos_with_user_priority_boost_test::new(string name = "axi4_qos_with_user_priority_boost_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Creates test configuration and components
//--------------------------------------------------------------------------------------------
function void axi4_qos_with_user_priority_boost_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Enable QoS mode for all agents in QoS tests
  for (int i = 0; i < axi4_env_cfg_h.no_of_masters; i++) begin
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = WRITE_READ_QOS_MODE_ENABLE;
  end
  for (int i = 0; i < axi4_env_cfg_h.no_of_slaves; i++) begin
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = WRITE_READ_QOS_MODE_ENABLE;
  end
  `uvm_info(get_type_name(), "Enabled WRITE_READ_QOS_MODE for all agents", UVM_LOW)
  
  `uvm_info(get_type_name(), "QoS with USER priority boost test configuration completed", UVM_MEDIUM)
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Executes the QoS with USER priority boost test
//--------------------------------------------------------------------------------------------
task axi4_qos_with_user_priority_boost_test::run_phase(uvm_phase phase);
  
  phase.raise_objection(this, "axi4_qos_with_user_priority_boost_test");
  
  `uvm_info(get_type_name(), "Starting AXI4 QoS with USER Priority Boost Test", UVM_LOW)
  `uvm_info(get_type_name(), "Test objective: Verify USER signals enhance QoS priority decisions", UVM_LOW)
  `uvm_info(get_type_name(), "Coverage: Security, Real-time, Emergency, Performance, Power, Deadline boosts", UVM_LOW)
  
  // Create and start the virtual sequence
  axi4_virtual_qos_with_user_priority_boost_seq_h = axi4_virtual_qos_with_user_priority_boost_seq::type_id::create("axi4_virtual_qos_with_user_priority_boost_seq_h");
  
  // Configure the virtual sequence
  axi4_virtual_qos_with_user_priority_boost_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for all transactions to complete
  #5500;
  
  `uvm_info(get_type_name(), "AXI4 QoS with USER Priority Boost Test completed", UVM_LOW)
  `uvm_info(get_type_name(), "Test success criteria:", UVM_LOW)
  `uvm_info(get_type_name(), "1. Security-critical transactions receive maximum priority boost", UVM_LOW)
  `uvm_info(get_type_name(), "2. Real-time deadlines trigger appropriate priority elevation", UVM_LOW)
  `uvm_info(get_type_name(), "3. Emergency contexts override normal QoS arbitration", UVM_LOW)
  `uvm_info(get_type_name(), "4. Performance-critical paths receive priority boosts", UVM_LOW)
  `uvm_info(get_type_name(), "5. Power-saving contexts reduce unnecessary high priority", UVM_LOW)
  `uvm_info(get_type_name(), "6. Deadline-urgent transactions prevent deadline misses", UVM_LOW)
  `uvm_info(get_type_name(), "7. Multi-master priority boosts work without interference", UVM_LOW)
  
  phase.drop_objection(this, "axi4_qos_with_user_priority_boost_test");
  
endtask : run_phase

`endif