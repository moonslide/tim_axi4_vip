`ifndef AXI4_USER_PARITY_PROTECTION_TEST_INCLUDED_
`define AXI4_USER_PARITY_PROTECTION_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_parity_protection_test
//
// TEST SCENARIO DESCRIPTION:
// This comprehensive test validates USER signal parity protection mechanisms to ensure data
// integrity in AXI4 transactions. The test verifies multiple parity schemes and their correct
// implementation across various transaction scenarios and system conditions.
//
// DETAILED TEST SCENARIOS:
// 1. Even Parity Protection Validation
//    - Generate transactions with even parity USER signals
//    - Verify parity calculation correctness for all data patterns
//    - Test parity preservation through read/write channels
//    - Validate parity checking at slave interfaces
//
// 2. Odd Parity Protection Validation
//    - Generate transactions with odd parity USER signals
//    - Verify parity calculation correctness for complementary patterns
//    - Test parity consistency across burst transactions
//    - Validate error detection for incorrect odd parity
//
// 3. Dual Parity Protection (Even + Odd)
//    - Implement enhanced protection using both parity schemes
//    - Verify dual parity provides superior error detection
//    - Test recovery mechanisms when single parity fails
//    - Validate system behavior under dual parity conflicts
//
// 4. No Parity Scheme Testing
//    - Test systems configured without parity protection
//    - Verify normal operation when parity is disabled
//    - Validate that parity bits are treated as user data
//    - Test backward compatibility with non-parity systems
//
// 5. Multi-Master Parity Coordination
//    - Test parity protection with multiple masters
//    - Verify each master maintains independent parity schemes
//    - Validate parity scheme identification in USER signals
//    - Test arbitration with mixed parity requirements
//
// 6. Parity Error Injection and Detection
//    - Intentionally corrupt parity bits in USER signals
//    - Verify error detection mechanisms activate correctly
//    - Test error reporting and logging functionality
//    - Validate system recovery after parity errors
//
// 7. Dynamic Parity Scheme Switching
//    - Test runtime switching between parity schemes
//    - Verify seamless transitions without data corruption
//    - Validate parity scheme negotiation between components
//    - Test fallback mechanisms for unsupported schemes
//
// 8. Burst Transaction Parity Consistency
//    - Verify parity protection across entire burst sequences
//    - Test parity calculation for variable burst lengths
//    - Validate parity preservation in out-of-order responses
//    - Test parity coherency in interleaved transactions
//
// EXPECTED BEHAVIORS:
// - Even parity calculations must be mathematically correct for all test data
// - Odd parity calculations must complement even parity results appropriately
// - Dual parity schemes must provide enhanced error detection capabilities
// - Parity scheme identifiers must be preserved and transmitted correctly
// - Error detection must trigger appropriate system responses and logging
// - Multi-master scenarios must maintain independent parity protection
// - System performance must not degrade significantly with parity enabled
//
// COVERAGE GOALS:
// - 100% of supported parity schemes (even, odd, dual, none)
// - All possible parity bit patterns and calculations
// - Error injection scenarios covering single and multiple bit errors
// - Multi-master coordination with different parity requirements
// - Dynamic reconfiguration and scheme switching scenarios
// - Integration with other USER signal features (security, QoS, tracing)
//
// VALIDATION CRITERIA:
// - Mathematical correctness of all parity calculations
// - Proper error detection and reporting for corrupted parity
// - Seamless operation across different parity schemes
// - Maintained data integrity under all test conditions
// - Compliance with AXI4 protocol requirements for USER signals
//--------------------------------------------------------------------------------------------
class axi4_user_parity_protection_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_parity_protection_test)
  
  // Virtual sequence handle
  axi4_virtual_user_parity_protection_seq axi4_virtual_user_parity_protection_seq_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_parity_protection_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_user_parity_protection_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_user_parity_protection_test::new(string name = "axi4_user_parity_protection_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Creates test configuration and components
//--------------------------------------------------------------------------------------------
function void axi4_user_parity_protection_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  `uvm_info(get_type_name(), "USER signal parity protection test configuration completed", UVM_MEDIUM)
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Executes the USER signal parity protection test
//--------------------------------------------------------------------------------------------
task axi4_user_parity_protection_test::run_phase(uvm_phase phase);
  
  phase.raise_objection(this, "axi4_user_parity_protection_test");
  
  `uvm_info(get_type_name(), "Starting AXI4 USER Signal Parity Protection Test", UVM_LOW)
  `uvm_info(get_type_name(), "Test objective: Verify USER signals implement parity protection correctly", UVM_LOW)
  `uvm_info(get_type_name(), "Coverage: Even parity, Odd parity, Dual parity, and No parity schemes", UVM_LOW)
  
  // Create and start the virtual sequence
  axi4_virtual_user_parity_protection_seq_h = axi4_virtual_user_parity_protection_seq::type_id::create("axi4_virtual_user_parity_protection_seq_h");
  
  // Configure the virtual sequence
  axi4_virtual_user_parity_protection_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for all transactions to complete
  #4000;
  
  `uvm_info(get_type_name(), "AXI4 USER Signal Parity Protection Test completed", UVM_LOW)
  `uvm_info(get_type_name(), "Test success criteria:", UVM_LOW)
  `uvm_info(get_type_name(), "1. Even parity calculations are correct for all test data", UVM_LOW)
  `uvm_info(get_type_name(), "2. Odd parity calculations are correct for all test data", UVM_LOW)
  `uvm_info(get_type_name(), "3. Dual parity (even+odd) provides enhanced protection", UVM_LOW)
  `uvm_info(get_type_name(), "4. Parity scheme identifiers are preserved in USER signals", UVM_LOW)
  `uvm_info(get_type_name(), "5. Data integrity is maintained through parity checking", UVM_LOW)
  `uvm_info(get_type_name(), "6. Multi-master parity protection works without conflicts", UVM_LOW)
  
  phase.drop_objection(this, "axi4_user_parity_protection_test");
  
endtask : run_phase

`endif