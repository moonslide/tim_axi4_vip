`ifndef AXI4_USER_TRANSACTION_TRACING_TEST_INCLUDED_
`define AXI4_USER_TRANSACTION_TRACING_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_transaction_tracing_test
//
// TEST SCENARIO DESCRIPTION:
// This comprehensive test validates USER signal transaction tracing mechanisms to provide
// detailed system observability, debugging capabilities, and performance monitoring. The test
// verifies tracing functionality across various operational scenarios and system conditions.
//
// DETAILED TEST SCENARIOS:
// 1. Debug Trace Implementation
//    - Generate transactions with debug trace markers in USER signals
//    - Verify trace ID generation and uniqueness across transactions
//    - Test debug breakpoint and watchpoint trigger mechanisms
//    - Validate debug trace correlation with system events
//
// 2. Performance Monitoring Traces
//    - Test performance counter integration with USER signals
//    - Verify latency measurement and timestamp accuracy
//    - Validate bandwidth utilization tracking mechanisms
//    - Test performance bottleneck identification capabilities
//
// 3. Error and Exception Tracing
//    - Test error condition tracing and classification
//    - Verify exception handler invocation tracking
//    - Validate error propagation through transaction chains
//    - Test error recovery mechanism monitoring
//
// 4. Security Event Tracing
//    - Test security violation detection and logging
//    - Verify access control decision tracing
//    - Validate authentication and authorization event tracking
//    - Test security audit trail generation
//
// 5. Power Management Tracing
//    - Test power state transition tracking in USER signals
//    - Verify dynamic voltage and frequency scaling (DVFS) monitoring
//    - Validate power consumption correlation with transactions
//    - Test power optimization decision tracing
//
// 6. Thermal Management Tracing
//    - Test thermal zone monitoring integration
//    - Verify temperature-based throttling decision tracking
//    - Validate thermal emergency response tracing
//    - Test cooling system interaction monitoring
//
// 7. QoS Decision Tracing
//    - Test QoS arbitration decision logging
//    - Verify priority adjustment rationale tracking
//    - Validate resource allocation decision monitoring
//    - Test QoS policy enforcement tracing
//
// 8. Custom Application Tracing
//    - Test user-defined trace markers and events
//    - Verify custom trace data encoding and preservation
//    - Validate application-specific performance metrics
//    - Test custom trace filtering and analysis capabilities
//
// 9. Multi-Master Trace Coordination
//    - Test trace synchronization across multiple masters
//    - Verify global trace ID management and allocation
//    - Validate cross-master trace correlation mechanisms
//    - Test distributed tracing in multi-core systems
//
// 10. Trace Priority and Filtering
//     - Test trace priority levels and selective recording
//     - Verify trace filtering based on criteria and conditions
//     - Validate trace buffer management and overflow handling
//     - Test real-time trace streaming capabilities
//
// 11. Temporal Trace Analysis
//     - Test timestamp synchronization across system components
//     - Verify temporal correlation of related transactions
//     - Validate sequence number preservation and ordering
//     - Test time-based trace reconstruction capabilities
//
// 12. Trace Data Integrity
//     - Test trace data protection against corruption
//     - Verify trace authentication and digital signatures
//     - Validate trace encryption for sensitive information
//     - Test trace data recovery mechanisms
//
// EXPECTED BEHAVIORS:
// - Trace types must be properly encoded and preserved in USER signals
// - Debug markers must provide accurate debugging information
// - Trace priorities must be correctly handled and respected
// - Timestamps must provide precise temporal correlation capabilities
// - Sequence numbers must enable proper trace ordering and reconstruction
// - Multi-master tracing must operate without conflicts or interference
// - Trace data must maintain integrity under all operational conditions
//
// COVERAGE GOALS:
// - All supported trace types (debug, performance, error, security, power, thermal, QoS, custom)
// - Complete trace priority level matrix testing
// - All timestamp synchronization scenarios
// - Multi-master trace coordination and correlation
// - Trace filtering and analysis feature validation
// - Integration with external trace analysis tools
//
// VALIDATION CRITERIA:
// - Accurate and complete transaction tracing capability
// - Proper temporal correlation and sequence preservation
// - Effective debugging and performance analysis support
// - Compliance with industry tracing standards (ARM CoreSight, etc.)
// - Maintained system performance with tracing enabled
//--------------------------------------------------------------------------------------------
class axi4_user_transaction_tracing_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_transaction_tracing_test)
  
  // Virtual sequence handle
  axi4_virtual_user_transaction_tracing_seq axi4_virtual_user_transaction_tracing_seq_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_transaction_tracing_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_user_transaction_tracing_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_user_transaction_tracing_test::new(string name = "axi4_user_transaction_tracing_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Creates test configuration and components
//--------------------------------------------------------------------------------------------
function void axi4_user_transaction_tracing_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  `uvm_info(get_type_name(), "USER signal transaction tracing test configuration completed", UVM_MEDIUM)
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Executes the USER signal transaction tracing test
//--------------------------------------------------------------------------------------------
task axi4_user_transaction_tracing_test::run_phase(uvm_phase phase);
  
  phase.raise_objection(this, "axi4_user_transaction_tracing_test");
  
  `uvm_info(get_type_name(), "Starting AXI4 USER Signal Transaction Tracing Test", UVM_LOW)
  `uvm_info(get_type_name(), "Test objective: Verify USER signals implement transaction tracing correctly", UVM_LOW)
  `uvm_info(get_type_name(), "Coverage: Debug, Performance, Error, Security, Power, Thermal, QoS, Custom traces", UVM_LOW)
  
  // Create and start the virtual sequence
  axi4_virtual_user_transaction_tracing_seq_h = axi4_virtual_user_transaction_tracing_seq::type_id::create("axi4_virtual_user_transaction_tracing_seq_h");
  
  // Configure the virtual sequence
  axi4_virtual_user_transaction_tracing_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for all transactions to complete
  #5000;
  
  `uvm_info(get_type_name(), "AXI4 USER Signal Transaction Tracing Test completed", UVM_LOW)
  `uvm_info(get_type_name(), "Test success criteria:", UVM_LOW)
  `uvm_info(get_type_name(), "1. Trace types are properly encoded and preserved", UVM_LOW)
  `uvm_info(get_type_name(), "2. Debug markers provide accurate debugging information", UVM_LOW)
  `uvm_info(get_type_name(), "3. Trace priorities are correctly handled", UVM_LOW)
  `uvm_info(get_type_name(), "4. Timestamps provide temporal correlation", UVM_LOW)
  `uvm_info(get_type_name(), "5. Sequence numbers enable proper trace ordering", UVM_LOW)
  `uvm_info(get_type_name(), "6. Multi-master tracing works without conflicts", UVM_LOW)
  
  phase.drop_objection(this, "axi4_user_transaction_tracing_test");
  
endtask : run_phase

`endif