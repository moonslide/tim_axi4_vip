`ifndef AXI4_USER_SIGNAL_CORRUPTION_TEST_INCLUDED_
`define AXI4_USER_SIGNAL_CORRUPTION_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_signal_corruption_test
//
// TEST SCENARIO DESCRIPTION:
// This comprehensive test validates USER signal corruption detection and recovery mechanisms
// to ensure system resilience against various fault conditions, environmental effects, and
// hardware-induced errors. The test intentionally introduces corruption to verify robustness.
//
// DETAILED TEST SCENARIOS:
// 1. Single Bit Error Corruption
//    - Inject single bit flips in various USER signal fields
//    - Test error correction capabilities using ECC or parity
//    - Verify detection of uncorrectable single bit errors
//    - Validate error reporting and logging for single bit faults
//
// 2. Multiple Bit Error Corruption
//    - Generate multiple simultaneous bit errors in USER signals
//    - Test detection limits of error correction mechanisms
//    - Verify proper handling when correction is impossible
//    - Validate escalation procedures for severe bit errors
//
// 3. Burst Error Corruption
//    - Inject contiguous bit error patterns (burst errors)
//    - Test burst error detection and classification capabilities
//    - Verify handling of errors spanning multiple signal fields
//    - Validate recovery strategies for extended corruption
//
// 4. Stuck Bit Fault Simulation
//    - Simulate permanently stuck-at-0 and stuck-at-1 conditions
//    - Test detection of persistent bit fault patterns
//    - Verify workaround mechanisms for stuck bit conditions
//    - Validate long-term system adaptation to stuck faults
//
// 5. Intermittent Error Patterns
//    - Generate sporadic, non-repeatable corruption events
//    - Test detection of transient error conditions
//    - Verify statistical analysis of error patterns
//    - Validate adaptive thresholds for intermittent faults
//
// 6. Environmental Effect Simulation
//    - Simulate electromagnetic interference (EMI) effects
//    - Test cosmic ray and radiation-induced bit flips
//    - Verify temperature-induced signal degradation handling
//    - Validate voltage fluctuation impact on USER signals
//
// 7. Cross-Talk and Signal Integrity Issues
//    - Simulate cross-talk between adjacent USER signal lines
//    - Test detection of signal integrity degradation
//    - Verify handling of timing-related corruption
//    - Validate mitigation strategies for signal quality issues
//
// 8. Systematic Corruption Patterns
//    - Generate predictable corruption patterns for analysis
//    - Test detection of systematic vs random corruption
//    - Verify pattern-based error prediction capabilities
//    - Validate targeted mitigation for systematic issues
//
// 9. Cascading Error Propagation
//    - Test corruption propagation through transaction chains
//    - Verify error containment and isolation mechanisms
//    - Validate prevention of error amplification
//    - Test system stability under cascading failures
//
// 10. Recovery Mechanism Validation
//     - Test automatic error recovery procedures
//     - Verify rollback and retry mechanisms
//     - Validate graceful degradation strategies
//     - Test restoration of normal operation post-recovery
//
// 11. Multi-Master Corruption Scenarios
//     - Test corruption affecting multiple masters simultaneously
//     - Verify independent error handling per master
//     - Validate cross-master error correlation analysis
//     - Test system-wide protection coordination
//
// 12. Severe Corruption and Protection Activation
//     - Generate corruption levels that threaten system safety
//     - Test emergency protection mechanism activation
//     - Verify fail-safe behavior under severe corruption
//     - Validate system isolation and containment procedures
//
// 13. Error Pattern Learning and Adaptation
//     - Test adaptive error detection threshold adjustment
//     - Verify machine learning-based error prediction
//     - Validate proactive mitigation based on error history
//     - Test system optimization based on corruption patterns
//
// 14. Diagnostic and Forensic Capabilities
//     - Test detailed error analysis and classification
//     - Verify corruption source identification capabilities
//     - Validate forensic data collection for error analysis
//     - Test root cause analysis support features
//
// EXPECTED BEHAVIORS:
// - Single bit errors must be correctable or clearly detectable
// - Multiple bit errors must be properly detected and handled
// - Burst errors must trigger appropriate error handling procedures
// - Stuck bit faults must be identified and compensated where possible
// - Intermittent errors must be tracked and analyzed statistically
// - Severe corruption must activate protection mechanisms
// - Recovery mechanisms must restore normal operation when feasible
//
// COVERAGE GOALS:
// - All types of bit-level corruption scenarios
// - Complete error detection and correction capability validation
// - Environmental and physical fault simulation coverage
// - Multi-master corruption and coordination scenarios
// - Recovery and resilience mechanism effectiveness
// - Integration with system-level fault tolerance features
//
// VALIDATION CRITERIA:
// - Accurate detection of all intentionally introduced corruption
// - Effective error correction within system capabilities
// - Proper escalation when errors exceed correction limits
// - Maintained system functionality under manageable corruption
// - Graceful degradation or protection under severe corruption
//
// WARNING: This test intentionally corrupts USER signals for validation purposes.
// The corruption is controlled and monitored to ensure system safety and test validity.
//--------------------------------------------------------------------------------------------
class axi4_user_signal_corruption_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_signal_corruption_test)
  
  // Virtual sequence handle
  axi4_virtual_user_signal_corruption_seq axi4_virtual_user_signal_corruption_seq_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_signal_corruption_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_user_signal_corruption_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_user_signal_corruption_test::new(string name = "axi4_user_signal_corruption_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Creates test configuration and components
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_corruption_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Disable RREADY assertion checking during cleanup phase for USER test
  uvm_config_db#(bit)::set(null, "*", "disable_rready_check_for_qos_cleanup", 1'b1);
  `uvm_info(get_type_name(), "Disabled RREADY assertion checking during cleanup phase for USER test", UVM_LOW)
  
  `uvm_info(get_type_name(), "USER signal corruption test configuration completed", UVM_MEDIUM)
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Executes the USER signal corruption test
//--------------------------------------------------------------------------------------------
task axi4_user_signal_corruption_test::run_phase(uvm_phase phase);
  
  phase.raise_objection(this, "axi4_user_signal_corruption_test");
  
  `uvm_info(get_type_name(), "Starting AXI4 USER Signal Corruption Test", UVM_LOW)
  `uvm_info(get_type_name(), "Test objective: Verify USER signal corruption detection and recovery", UVM_LOW)
  `uvm_info(get_type_name(), "Coverage: Bit flips, Burst errors, Stuck bits, Environmental effects", UVM_LOW)
  `uvm_info(get_type_name(), "WARNING: This test intentionally corrupts USER signals", UVM_LOW)
  
  // Create and start the virtual sequence
  axi4_virtual_user_signal_corruption_seq_h = axi4_virtual_user_signal_corruption_seq::type_id::create("axi4_virtual_user_signal_corruption_seq_h");
  
  // Configure the virtual sequence
  axi4_virtual_user_signal_corruption_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Signal that we're entering cleanup phase
  uvm_config_db#(bit)::set(null, "*", "qos_test_cleanup_phase", 1'b1);
  
  // Wait for all transactions to complete
  #7000;
  
  `uvm_info(get_type_name(), "AXI4 USER Signal Corruption Test completed", UVM_LOW)
  `uvm_info(get_type_name(), "Test success criteria:", UVM_LOW)
  `uvm_info(get_type_name(), "1. Single bit errors are correctable or detectable", UVM_LOW)
  `uvm_info(get_type_name(), "2. Multiple bit errors are properly detected", UVM_LOW)
  `uvm_info(get_type_name(), "3. Burst errors trigger appropriate error handling", UVM_LOW)
  `uvm_info(get_type_name(), "4. Stuck bit faults are identified and reported", UVM_LOW)
  `uvm_info(get_type_name(), "5. Intermittent errors are tracked and logged", UVM_LOW)
  `uvm_info(get_type_name(), "6. Severe corruption activates protection mechanisms", UVM_LOW)
  `uvm_info(get_type_name(), "7. Recovery mechanisms restore normal operation", UVM_LOW)
  
  phase.drop_objection(this, "axi4_user_signal_corruption_test");
  
endtask : run_phase

`endif