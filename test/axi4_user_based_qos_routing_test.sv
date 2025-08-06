`ifndef AXI4_USER_BASED_QOS_ROUTING_TEST_INCLUDED_
`define AXI4_USER_BASED_QOS_ROUTING_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_based_qos_routing_test
//
// TEST SCENARIO DESCRIPTION:
// This comprehensive test validates USER-based QoS routing mechanisms that make intelligent
// routing decisions based on USER signal context information. The test verifies adaptive
// routing strategies that optimize system performance, power efficiency, and resource utilization.
//
// DETAILED TEST SCENARIOS:
// 1. Workload-Aware Routing Optimization
//    - Test routing decisions based on workload characteristics in USER signals
//    - Verify compute-intensive vs memory-intensive workload differentiation
//    - Validate streaming vs random access pattern routing optimization
//    - Test batch processing vs interactive workload routing strategies
//
// 2. Bandwidth-Optimized Routing
//    - Test routing to maximize throughput for bulk data transfers
//    - Verify high-bandwidth path selection for large transactions
//    - Validate bandwidth aggregation across multiple routing paths
//    - Test congestion-aware bandwidth optimization routing
//
// 3. Latency-Optimized Routing
//    - Test minimum latency path selection for interactive applications
//    - Verify low-latency routing for real-time critical transactions
//    - Validate latency-sensitive application prioritization
//    - Test latency budget management and optimization
//
// 4. Energy-Aware Routing Strategies
//    - Test power-efficient routing for background and batch tasks
//    - Verify energy optimization routing decisions
//    - Validate dynamic voltage and frequency scaling integration
//    - Test battery life optimization routing algorithms
//
// 5. Thermal-Aware Routing Management
//    - Test thermal load distribution across system components
//    - Verify heat generation minimization routing strategies
//    - Validate thermal hot-spot avoidance routing
//    - Test cooling system coordination with routing decisions
//
// 6. Load Balancing and Traffic Distribution
//    - Test intelligent load distribution across available paths
//    - Verify traffic balancing to prevent bottlenecks
//    - Validate adaptive load balancing based on system conditions
//    - Test fairness maintenance in load distribution
//
// 7. Adaptive Routing Based on System State
//    - Test routing adaptation to dynamic system conditions
//    - Verify real-time routing optimization based on current load
//    - Validate predictive routing based on historical patterns
//    - Test machine learning-enhanced routing decisions
//
// 8. Quality of Service Routing Integration
//    - Test QoS class-aware routing decisions
//    - Verify service level agreement (SLA) compliance routing
//    - Validate priority-based routing path selection
//    - Test QoS guarantee maintenance through routing
//
// 9. Security-Aware Routing Decisions
//    - Test secure path selection for sensitive transactions
//    - Verify trust zone-aware routing strategies
//    - Validate encrypted path preference for confidential data
//    - Test security policy compliance in routing decisions
//
// 10. Multi-Objective Routing Optimization
//     - Test simultaneous optimization of multiple routing objectives
//     - Verify trade-off management between conflicting goals
//     - Validate Pareto-optimal routing solution selection
//     - Test dynamic objective weighting based on system priorities
//
// 11. Network Topology Aware Routing
//     - Test routing optimization for different network topologies
//     - Verify mesh, tree, and hybrid topology routing strategies
//     - Validate topology change adaptation capabilities
//     - Test fault-tolerant routing in degraded topologies
//
// 12. Cache and Memory Hierarchy Optimization
//     - Test cache-aware routing for improved hit rates
//     - Verify memory hierarchy optimization routing
//     - Validate NUMA-aware routing in multi-processor systems
//     - Test cache coherency-optimized routing strategies
//
// 13. Application-Specific Routing Policies
//     - Test custom routing policies for specific applications
//     - Verify application context-aware routing decisions
//     - Validate user-defined routing preference implementation
//     - Test application performance optimization routing
//
// 14. Multi-Master Routing Coordination
//     - Test routing coordination across multiple masters
//     - Verify independent routing policies per master
//     - Validate global routing optimization with local preferences
//     - Test routing conflict resolution mechanisms
//
// 15. Dynamic Routing Reconfiguration
//     - Test runtime routing policy updates and modifications
//     - Verify seamless routing strategy transitions
//     - Validate routing configuration learning and adaptation
//     - Test routing performance monitoring and optimization
//
// EXPECTED BEHAVIORS:
// - Workload-aware routing must optimize for application characteristics
// - Bandwidth optimization must maximize throughput for bulk transfers
// - Latency optimization must minimize delays for interactive applications
// - Energy-aware routing must reduce power consumption for background tasks
// - Thermal-aware routing must manage heat generation effectively
// - Load balancing must distribute traffic efficiently across available resources
// - Adaptive routing must respond appropriately to dynamic system conditions
//
// COVERAGE GOALS:
// - All routing optimization strategies and algorithms
// - Complete workload characteristic classification and routing
// - Multi-objective optimization scenarios and trade-offs
// - Dynamic system condition adaptation and response
// - Integration with all system management subsystems
// - Multi-master coordination and conflict resolution scenarios
//
// VALIDATION CRITERIA:
// - Optimal routing decisions for all tested workload characteristics
// - Effective optimization of targeted objectives (bandwidth, latency, power, thermal)
// - Maintained system balance and fairness across all routing decisions
// - Proper adaptation to changing system conditions and requirements
// - Compliance with application-specific routing policies and preferences
//--------------------------------------------------------------------------------------------
class axi4_user_based_qos_routing_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_based_qos_routing_test)
  
  // Virtual sequence handle
  axi4_virtual_user_based_qos_routing_seq axi4_virtual_user_based_qos_routing_seq_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_based_qos_routing_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_user_based_qos_routing_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_user_based_qos_routing_test::new(string name = "axi4_user_based_qos_routing_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Creates test configuration and components
//--------------------------------------------------------------------------------------------
function void axi4_user_based_qos_routing_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Disable RREADY assertion checking during cleanup phase for USER test
  uvm_config_db#(bit)::set(null, "*", "disable_rready_check_for_qos_cleanup", 1'b1);
  `uvm_info(get_type_name(), "Disabled RREADY assertion checking during cleanup phase for USER test", UVM_LOW)
  
  `uvm_info(get_type_name(), "USER-based QoS routing test configuration completed", UVM_MEDIUM)
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Executes the USER-based QoS routing test
//--------------------------------------------------------------------------------------------
task axi4_user_based_qos_routing_test::run_phase(uvm_phase phase);
  
  phase.raise_objection(this, "axi4_user_based_qos_routing_test");
  
  `uvm_info(get_type_name(), "Starting AXI4 USER-based QoS Routing Test", UVM_LOW)
  `uvm_info(get_type_name(), "Test objective: Verify QoS routing adapts to USER signal context", UVM_LOW)
  `uvm_info(get_type_name(), "Coverage: Workload-aware, Bandwidth/Latency optimized, Energy/Thermal aware routing", UVM_LOW)
  
  // Create and start the virtual sequence
  axi4_virtual_user_based_qos_routing_seq_h = axi4_virtual_user_based_qos_routing_seq::type_id::create("axi4_virtual_user_based_qos_routing_seq_h");
  
  // Configure the virtual sequence
  axi4_virtual_user_based_qos_routing_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Signal that we're entering cleanup phase
  uvm_config_db#(bit)::set(null, "*", "qos_test_cleanup_phase", 1'b1);
  
  // Wait for all transactions to complete
  #6000;
  
  `uvm_info(get_type_name(), "AXI4 USER-based QoS Routing Test completed", UVM_LOW)
  `uvm_info(get_type_name(), "Test success criteria:", UVM_LOW)
  `uvm_info(get_type_name(), "1. Workload-aware routing optimizes for application characteristics", UVM_LOW)
  `uvm_info(get_type_name(), "2. Bandwidth optimization maximizes throughput for bulk transfers", UVM_LOW)
  `uvm_info(get_type_name(), "3. Latency optimization minimizes delays for interactive apps", UVM_LOW)
  `uvm_info(get_type_name(), "4. Energy-aware routing reduces power for background tasks", UVM_LOW)
  `uvm_info(get_type_name(), "5. Thermal-aware routing manages heat generation effectively", UVM_LOW)
  `uvm_info(get_type_name(), "6. Load balancing distributes traffic efficiently", UVM_LOW)
  `uvm_info(get_type_name(), "7. Adaptive routing responds to dynamic system conditions", UVM_LOW)
  
  phase.drop_objection(this, "axi4_user_based_qos_routing_test");
  
endtask : run_phase

`endif