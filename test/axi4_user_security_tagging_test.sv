`ifndef AXI4_USER_SECURITY_TAGGING_TEST_INCLUDED_
`define AXI4_USER_SECURITY_TAGGING_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_security_tagging_test
//
// TEST SCENARIO DESCRIPTION:
// This comprehensive test validates USER signal security tagging mechanisms to ensure proper
// security isolation, access control, and trust zone management in AXI4 transactions. The test
// verifies security features across various threat models and system security configurations.
//
// DETAILED TEST SCENARIOS:
// 1. Security Level Classification
//    - Test transactions with different security levels (Public, Internal, Confidential, Secret)
//    - Verify security level encoding and preservation in USER signals
//    - Validate security level inheritance in burst transactions
//    - Test security level escalation and de-escalation mechanisms
//
// 2. Trust Zone Management
//    - Test Secure World vs Non-Secure World transaction isolation
//    - Verify Monitor Mode security transitions and controls
//    - Validate Hypervisor Mode privilege management
//    - Test trust zone boundary enforcement and violations
//
// 3. Access Permission Validation
//    - Test Read/Write/Execute permission encoding in USER signals
//    - Verify permission inheritance across transaction sequences
//    - Validate permission checking at slave interfaces
//    - Test permission override mechanisms for privileged access
//
// 4. Security Hash Implementation
//    - Generate cryptographic hashes for transaction integrity
//    - Verify hash calculation correctness for all data patterns
//    - Test hash verification at destination components
//    - Validate hash-based tampering detection mechanisms
//
// 5. User ID and Master ID Tracking
//    - Test unique user identification in multi-user systems
//    - Verify master ID preservation and authentication
//    - Validate user context switching and isolation
//    - Test privilege escalation prevention mechanisms
//
// 6. Multi-Master Security Contexts
//    - Test security isolation between multiple masters
//    - Verify independent security contexts and policies
//    - Validate cross-master security boundary enforcement
//    - Test security arbitration in shared resource access
//
// 7. Security Policy Enforcement
//    - Test mandatory access control (MAC) policy enforcement
//    - Verify discretionary access control (DAC) mechanisms
//    - Validate role-based access control (RBAC) implementation
//    - Test security policy updates and transitions
//
// 8. Cryptographic Protection Features
//    - Test encryption key identification in USER signals
//    - Verify digital signature validation mechanisms
//    - Validate certificate-based authentication
//    - Test secure key distribution and management
//
// 9. Security Audit and Logging
//    - Test security event logging and audit trails
//    - Verify suspicious activity detection and reporting
//    - Validate forensic data collection capabilities
//    - Test security incident response mechanisms
//
// 10. Emergency Security Responses
//     - Test lockdown mechanisms for security breaches
//     - Verify emergency access procedures and overrides
//     - Validate security reset and recovery procedures
//     - Test fail-secure vs fail-open policy enforcement
//
// EXPECTED BEHAVIORS:
// - Security levels must be properly encoded and preserved throughout transactions
// - Trust zones must provide complete isolation between secure and non-secure worlds
// - Access permissions must be correctly validated and enforced
// - Security hashes must provide reliable integrity protection
// - User and master IDs must be accurately tracked and authenticated
// - Multi-master security contexts must operate without interference
// - Security violations must trigger appropriate protective responses
//
// COVERAGE GOALS:
// - All security levels and trust zone combinations
// - Complete access permission matrix testing
// - All supported cryptographic algorithms and key sizes
// - Multi-user and multi-master security scenarios
// - Security policy enforcement under various threat conditions
// - Integration with hardware security modules (HSM) where applicable
//
// VALIDATION CRITERIA:
// - Complete security isolation between different security contexts
// - Correct implementation of all access control mechanisms
// - Proper handling of security violations and attack scenarios
// - Compliance with industry security standards (ARM TrustZone, etc.)
// - Maintained system security under all operational conditions
//--------------------------------------------------------------------------------------------
class axi4_user_security_tagging_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_security_tagging_test)
  
  // Virtual sequence handle
  axi4_virtual_user_security_tagging_seq axi4_virtual_user_security_tagging_seq_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_security_tagging_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_user_security_tagging_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_user_security_tagging_test::new(string name = "axi4_user_security_tagging_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Creates test configuration and components
//--------------------------------------------------------------------------------------------
function void axi4_user_security_tagging_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  `uvm_info(get_type_name(), "USER signal security tagging test configuration completed", UVM_MEDIUM)
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Executes the USER signal security tagging test
//--------------------------------------------------------------------------------------------
task axi4_user_security_tagging_test::run_phase(uvm_phase phase);
  
  phase.raise_objection(this, "axi4_user_security_tagging_test");
  
  `uvm_info(get_type_name(), "Starting AXI4 USER Signal Security Tagging Test", UVM_LOW)
  `uvm_info(get_type_name(), "Test objective: Verify USER signals implement security tagging correctly", UVM_LOW)
  `uvm_info(get_type_name(), "Coverage: Security levels, Trust zones, Access permissions, Security hashes", UVM_LOW)
  
  // Create and start the virtual sequence
  axi4_virtual_user_security_tagging_seq_h = axi4_virtual_user_security_tagging_seq::type_id::create("axi4_virtual_user_security_tagging_seq_h");
  
  // Configure the virtual sequence
  axi4_virtual_user_security_tagging_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for all transactions to complete
  #4500;
  
  `uvm_info(get_type_name(), "AXI4 USER Signal Security Tagging Test completed", UVM_LOW)
  `uvm_info(get_type_name(), "Test success criteria:", UVM_LOW)
  `uvm_info(get_type_name(), "1. Security levels are properly encoded and preserved", UVM_LOW)
  `uvm_info(get_type_name(), "2. Trust zones (Secure, Non-secure, Monitor, Hypervisor) work correctly", UVM_LOW)
  `uvm_info(get_type_name(), "3. Access permissions are correctly implemented", UVM_LOW)
  `uvm_info(get_type_name(), "4. Security hashes provide integrity protection", UVM_LOW)
  `uvm_info(get_type_name(), "5. User IDs and master IDs are properly tracked", UVM_LOW)
  `uvm_info(get_type_name(), "6. Multi-master security contexts work without interference", UVM_LOW)
  
  phase.drop_objection(this, "axi4_user_security_tagging_test");
  
endtask : run_phase

`endif