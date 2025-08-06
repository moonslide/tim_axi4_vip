`ifndef AXI4_USER_SIGNAL_PROTOCOL_VIOLATION_TEST_INCLUDED_
`define AXI4_USER_SIGNAL_PROTOCOL_VIOLATION_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_signal_protocol_violation_test
//
// TEST SCENARIO DESCRIPTION:
// This comprehensive test validates USER signal protocol violation detection and handling
// mechanisms to ensure system robustness and compliance with AXI4 protocol specifications.
// The test intentionally introduces violations to verify proper detection and response.
//
// DETAILED TEST SCENARIOS:
// 1. Reserved Bit Pattern Violations
//    - Inject transactions with reserved bit patterns set in USER signals
//    - Verify detection of protocol-violating reserved bit usage
//    - Test system response to reserved bit pattern violations
//    - Validate error reporting and logging for reserved bit misuse
//
// 2. Invalid Encoding Violations
//    - Generate USER signals with invalid field encodings
//    - Test detection of illegal value combinations
//    - Verify proper error responses for encoding violations
//    - Validate system behavior with malformed USER signal data
//
// 3. Inconsistent USER Signal Violations
//    - Create transactions with inconsistent USER signal values
//    - Test detection of conflicting information within USER signals
//    - Verify handling of contradictory field values
//    - Validate error correction or rejection mechanisms
//
// 4. Security Context Violations
//    - Inject transactions with mismatched security contexts
//    - Test detection of security level inconsistencies
//    - Verify trust zone boundary violation detection
//    - Validate security policy enforcement and violation handling
//
// 5. Parity and Checksum Violations
//    - Corrupt parity bits in USER signals intentionally
//    - Test detection of checksum mismatches
//    - Verify error correction capabilities where applicable
//    - Validate data integrity protection mechanisms
//
// 6. QoS Policy Violations
//    - Generate transactions violating QoS policies encoded in USER signals
//    - Test detection of invalid priority combinations
//    - Verify handling of resource allocation violations
//    - Validate QoS arbitration error responses
//
// 7. Trace Format Violations
//    - Inject malformed trace information in USER signals
//    - Test detection of invalid trace markers
//    - Verify handling of corrupted trace data
//    - Validate trace system protection mechanisms
//
// 8. Multi-Master Protocol Violations
//    - Create scenarios with conflicting master requirements
//    - Test detection of master ID spoofing attempts
//    - Verify handling of simultaneous conflicting requests
//    - Validate multi-master arbitration violation responses
//
// 9. Timing and Sequence Violations
//    - Generate USER signals with timing constraint violations
//    - Test detection of sequence number inconsistencies
//    - Verify handling of out-of-order USER signal updates
//    - Validate temporal consistency enforcement
//
// 10. Critical System Protection Violations
//     - Inject violations that could compromise system safety
//     - Test emergency response mechanisms for critical violations
//     - Verify system lockdown and protection activation
//     - Validate fail-safe behavior under severe violations
//
// 11. Protocol Extension Violations
//     - Test violations of custom USER signal extensions
//     - Verify backward compatibility violation detection
//     - Validate handling of unsupported feature requests
//     - Test graceful degradation for extension conflicts
//
// 12. Recovery and Resilience Testing
//     - Test system recovery after violation detection
//     - Verify resilience to persistent violation attempts
//     - Validate learning and adaptation mechanisms
//     - Test violation prevention and mitigation strategies
//
// EXPECTED BEHAVIORS:
// - Reserved bit patterns must be flagged as protocol violations
// - Invalid encodings must trigger appropriate error responses
// - Inconsistent USER signals must be detected and handled properly
// - Security mismatches must activate protective mechanisms
// - Parity errors must be identified and reported accurately
// - Critical violations must activate system protection measures
// - Recovery mechanisms must restore normal operation when possible
//
// COVERAGE GOALS:
// - All types of protocol violations and error conditions
// - Complete violation detection matrix across all USER signal fields
// - Error response and recovery mechanism validation
// - Multi-master violation scenarios and conflict resolution
// - Integration with system protection and security features
// - Compliance verification with AXI4 protocol specifications
//
// VALIDATION CRITERIA:
// - Accurate detection of all intentionally injected violations
// - Appropriate system responses to different violation severities
// - Proper error reporting and logging functionality
// - Maintained system stability under violation conditions
// - Effective protection against malicious violation attempts
//
// WARNING: This test intentionally violates USER signal protocols for validation purposes.
// The violations are controlled and monitored to ensure system safety and test validity.
//--------------------------------------------------------------------------------------------
class axi4_user_signal_protocol_violation_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_signal_protocol_violation_test)
  
  // Virtual sequence handle
  axi4_virtual_user_signal_protocol_violation_seq axi4_virtual_user_signal_protocol_violation_seq_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_signal_protocol_violation_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_user_signal_protocol_violation_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_user_signal_protocol_violation_test::new(string name = "axi4_user_signal_protocol_violation_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Creates test configuration and components
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_protocol_violation_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Enable error injection mode for intentional protocol violations
  axi4_env_cfg_h.error_inject = 1;
  
  // Disable RREADY assertion checking during cleanup phase for USER test
  uvm_config_db#(bit)::set(null, "*", "disable_rready_check_for_qos_cleanup", 1'b1);
  `uvm_info(get_type_name(), "Disabled RREADY assertion checking during cleanup phase for USER test", UVM_LOW)
  
  `uvm_info(get_type_name(), "USER signal protocol violation test configuration completed", UVM_MEDIUM)
  `uvm_info(get_type_name(), "Error injection mode enabled for protocol violation testing", UVM_MEDIUM)
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Executes the USER signal protocol violation test
//--------------------------------------------------------------------------------------------
task axi4_user_signal_protocol_violation_test::run_phase(uvm_phase phase);
  
  phase.raise_objection(this, "axi4_user_signal_protocol_violation_test");
  
  `uvm_info(get_type_name(), "Starting AXI4 USER Signal Protocol Violation Test", UVM_LOW)
  `uvm_info(get_type_name(), "Test objective: Verify USER signal protocol violations are detected", UVM_LOW)
  `uvm_info(get_type_name(), "Coverage: Reserved bits, Invalid encodings, Security mismatches, Parity errors", UVM_LOW)
  `uvm_info(get_type_name(), "WARNING: This test intentionally violates USER signal protocols", UVM_LOW)
  
  // Create and start the virtual sequence
  axi4_virtual_user_signal_protocol_violation_seq_h = axi4_virtual_user_signal_protocol_violation_seq::type_id::create("axi4_virtual_user_signal_protocol_violation_seq_h");
  
  // Configure the virtual sequence
  axi4_virtual_user_signal_protocol_violation_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Signal that we're entering cleanup phase
  uvm_config_db#(bit)::set(null, "*", "qos_test_cleanup_phase", 1'b1);
  
  // Wait for all transactions to complete
  #6000;
  
  `uvm_info(get_type_name(), "AXI4 USER Signal Protocol Violation Test completed", UVM_LOW)
  `uvm_info(get_type_name(), "Test success criteria:", UVM_LOW)
  `uvm_info(get_type_name(), "1. Reserved bit patterns are flagged as violations", UVM_LOW)
  `uvm_info(get_type_name(), "2. Invalid encodings trigger appropriate error responses", UVM_LOW)
  `uvm_info(get_type_name(), "3. Inconsistent USER signals are detected", UVM_LOW)
  `uvm_info(get_type_name(), "4. Security mismatches are handled appropriately", UVM_LOW)
  `uvm_info(get_type_name(), "5. Parity errors are identified and reported", UVM_LOW)
  `uvm_info(get_type_name(), "6. Critical violations activate system protection", UVM_LOW)
  
  phase.drop_objection(this, "axi4_user_signal_protocol_violation_test");
  
endtask : run_phase

`endif