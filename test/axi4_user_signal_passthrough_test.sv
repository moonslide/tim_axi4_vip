`ifndef AXI4_USER_SIGNAL_PASSTHROUGH_TEST_INCLUDED_
`define AXI4_USER_SIGNAL_PASSTHROUGH_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_signal_passthrough_test
// 
// TEST SCENARIO DESCRIPTION:
// ==========================
// This test validates that USER sideband signals correctly propagate through all AXI4
// channels in the bus matrix interconnect. It verifies signal integrity and proper
// correlation between request and response USER signals across multiple masters and slaves.
//
// DETAILED TEST SCENARIOS:
// 1. Write Channel USER Signal Passthrough:
//    - AWUSER (32-bit): Masters generate varied patterns (0x00000000, 0xFFFFFFFF, 0xAAAAAAAA, etc.)
//    - WUSER (32-bit): Correlates with AWUSER but uses different patterns for verification
//    - BUSER (16-bit): Slave responses should correlate with AWUSER requests
//    - Tests 4 masters × multiple patterns × multiple slaves
//
// 2. Read Channel USER Signal Passthrough:
//    - ARUSER (32-bit): Masters generate specific read-context patterns
//    - RUSER (16-bit): Slave responses should correlate with ARUSER requests
//    - Validates per-burst and per-beat RUSER correlation for multi-beat reads
//    - Tests address phase to data phase USER signal preservation
//
// 3. Multi-Master USER Signal Isolation:
//    - Each master uses unique USER signal patterns for identification
//    - Master 0: 0x12345678 base pattern, Master 1: 0x87654321 base pattern, etc.
//    - Validates that USER signals from different masters don't interfere
//    - Ensures proper multiplexing and demultiplexing in interconnect
//
// 4. Cross-Channel USER Signal Consistency:
//    - Write transactions: AWUSER and WUSER patterns are related but distinct
//    - Read transactions: ARUSER patterns include transaction context
//    - Response correlation: BUSER/RUSER should reflect request USER values
//    - Tests that interconnect maintains USER signal relationships
//
// 5. USER Signal Width and Format Validation:
//    - AWUSER[31:0]: Tests full 32-bit width utilization
//    - ARUSER[31:0]: Tests full 32-bit width utilization  
//    - WUSER[31:0]: Tests full 32-bit width utilization
//    - BUSER[15:0]: Tests 16-bit response correlation
//    - RUSER[15:0]: Tests 16-bit response correlation
//    - Validates that no bits are lost or corrupted during propagation
//
// USER SIGNAL PATTERNS TESTED:
// - All zeros (0x00000000) and all ones (0xFFFFFFFF)
// - Alternating patterns (0xAAAAAAAA, 0x55555555)
// - Magic values (0xDEADBEEF, 0xCAFEBABE)
// - Incremental patterns (0x12345678, 0x87654321)
// - Sparse bit patterns for signal integrity verification
//
// EXPECTED BEHAVIORS:
// - All USER signal bits should propagate without corruption
// - Response USER signals should correlate with corresponding request USER signals
// - No cross-talk between different masters' USER signals
// - Timing relationships between USER signals and protocol signals maintained
// - USER signals should be stable during entire transaction duration
//
// VERIFICATION METHODS:
// - Scoreboard correlation between request and response USER signals
// - Pattern integrity checking at slave interfaces
// - Multi-master USER signal isolation verification
// - Timing relationship validation between USER and protocol signals
//
// COVERAGE GOALS:
// - All USER signal bit positions (0-31 for requests, 0-15 for responses)
// - All master-slave combination USER signal paths
// - Various USER signal pattern types and combinations
// - Write and read channel USER signal propagation paths
//--------------------------------------------------------------------------------------------
class axi4_user_signal_passthrough_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_signal_passthrough_test)
  
  // Virtual sequence handle
  axi4_virtual_user_signal_passthrough_seq axi4_virtual_user_signal_passthrough_seq_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_signal_passthrough_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_user_signal_passthrough_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_user_signal_passthrough_test::new(string name = "axi4_user_signal_passthrough_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Creates test configuration and components
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_passthrough_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  `uvm_info(get_type_name(), "USER signal passthrough test configuration completed", UVM_MEDIUM)
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Executes the USER signal passthrough test
//--------------------------------------------------------------------------------------------
task axi4_user_signal_passthrough_test::run_phase(uvm_phase phase);
  
  phase.raise_objection(this, "axi4_user_signal_passthrough_test");
  
  `uvm_info(get_type_name(), "Starting AXI4 USER Signal Passthrough Test", UVM_LOW)
  `uvm_info(get_type_name(), "Test objective: Verify USER signals passthrough correctly on all AXI channels", UVM_LOW)
  `uvm_info(get_type_name(), "Coverage: AWUSER, ARUSER, WUSER → Slave, BUSER, RUSER ← Slave", UVM_LOW)
  
  // Create and start the virtual sequence
  axi4_virtual_user_signal_passthrough_seq_h = axi4_virtual_user_signal_passthrough_seq::type_id::create("axi4_virtual_user_signal_passthrough_seq_h");
  
  // Configure the virtual sequence
  axi4_virtual_user_signal_passthrough_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Wait for all transactions to complete
  #3000;
  
  `uvm_info(get_type_name(), "AXI4 USER Signal Passthrough Test completed", UVM_LOW)
  `uvm_info(get_type_name(), "Test success criteria:", UVM_LOW)
  `uvm_info(get_type_name(), "1. All AWUSER values correctly propagated to slave", UVM_LOW)
  `uvm_info(get_type_name(), "2. All ARUSER values correctly propagated to slave", UVM_LOW)
  `uvm_info(get_type_name(), "3. All WUSER values correctly propagated to slave", UVM_LOW)
  `uvm_info(get_type_name(), "4. BUSER responses correlate with AWUSER requests", UVM_LOW)
  `uvm_info(get_type_name(), "5. RUSER responses correlate with ARUSER requests", UVM_LOW)
  `uvm_info(get_type_name(), "6. No USER signal corruption or loss detected", UVM_LOW)
  
  phase.drop_objection(this, "axi4_user_signal_passthrough_test");
  
endtask : run_phase

`endif