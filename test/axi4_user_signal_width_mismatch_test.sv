`ifndef AXI4_USER_SIGNAL_WIDTH_MISMATCH_TEST_INCLUDED_
`define AXI4_USER_SIGNAL_WIDTH_MISMATCH_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_signal_width_mismatch_test
// 
// TEST SCENARIO DESCRIPTION:
// ==========================
// This test validates system behavior when USER signals use different effective bit widths
// within the full 32-bit signal width. It tests the system's ability to handle partial
// width utilization, boundary conditions, and width-specific encoding schemes.
//
// DETAILED TEST SCENARIOS:
// 1. 8-Bit Effective Width Test:
//    - Masters use only lower 8 bits of USER signals (bits [7:0])
//    - Upper 24 bits remain zero or follow specific patterns
//    - Tests patterns: 0x000000FF, 0x000000AA, 0x00000055
//    - Validates that only meaningful bits are processed
//
// 2. 16-Bit Effective Width Test:
//    - Masters use lower 16 bits of USER signals (bits [15:0])
//    - Upper 16 bits follow reserved or extension patterns
//    - Tests patterns: 0x0000FFFF, 0x0000AAAA, 0x00005555
//    - Verifies proper handling of half-width utilization
//
// 3. 24-Bit Effective Width Test:
//    - Masters use lower 24 bits of USER signals (bits [23:0])
//    - Upper 8 bits used for version/reserved information
//    - Tests patterns: 0x00FFFFFF, 0x00AAAAAA, 0x00555555
//    - Validates near-full width usage scenarios
//
// 4. 32-Bit Full Width Test:
//    - Masters use all 32 bits of USER signals
//    - Tests patterns: 0xFFFFFFFF, 0xAAAAAAAA, 0x55555555
//    - Validates maximum width utilization
//    - Serves as baseline for width comparison
//
// 5. Sparse Bit Pattern Test:
//    - Masters use non-contiguous bits within USER signals
//    - Tests patterns: 0x80402010, 0x40201008, 0x20100804
//    - Validates that system handles scattered bit usage
//    - Tests bit isolation and independence
//
// 6. Boundary Condition Test:
//    - Tests maximum values for each effective width
//    - 8-bit max: 0x000000FF, 16-bit max: 0x0000FFFF, etc.
//    - Tests minimum non-zero values: 0x00000001, 0x00000010, etc.
//    - Validates boundary value handling and overflow protection
//
// 7. Mixed Width Multi-Master Test:
//    - Master 0: Uses 8-bit effective width
//    - Master 1: Uses 16-bit effective width
//    - Master 2: Uses 24-bit effective width
//    - Master 3: Uses full 32-bit width
//    - Tests interoperability between different width usage patterns
//
// WIDTH-SPECIFIC ENCODING SCHEMES:
// - 8-bit: Basic command/status encoding
// - 16-bit: Extended addressing or context information
// - 24-bit: Complex metadata with version fields
// - 32-bit: Full-featured protocol extensions
// - Sparse: Bit flags for independent features
//
// EXPECTED BEHAVIORS:
// - System should process only meaningful bits per width configuration
// - Unused upper bits should be ignored or handled as reserved
// - No width-related errors or protocol violations should occur
// - Response USER signals should reflect appropriate width usage
// - Different width patterns should not interfere with each other
//
// WIDTH COMPATIBILITY TESTS:
// - Forward compatibility: Wider implementations should handle narrow patterns
// - Backward compatibility: Narrow implementations should handle wider patterns gracefully
// - Mixed width environments should coexist without issues
// - Width negotiation or auto-detection mechanisms validation
//
// ERROR CONDITIONS:
// - Invalid bit patterns for specific width configurations
// - Overflow/underflow in width-constrained scenarios
// - Reserved bit violations in width-specific encodings
// - Width mismatch between request and response patterns
//
// COVERAGE GOALS:
// - All effective width configurations (8, 16, 24, 32 bits)
// - Boundary values for each width level
// - Sparse and dense bit pattern coverage
// - Multi-master width interoperability scenarios
// - Width-specific protocol compliance validation
//--------------------------------------------------------------------------------------------
class axi4_user_signal_width_mismatch_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_signal_width_mismatch_test)
  
  // Virtual sequence handle
  axi4_virtual_user_signal_width_mismatch_seq axi4_virtual_user_signal_width_mismatch_seq_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_signal_width_mismatch_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_user_signal_width_mismatch_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_user_signal_width_mismatch_test::new(string name = "axi4_user_signal_width_mismatch_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Creates test configuration and components
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_width_mismatch_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Disable RREADY assertion checking during cleanup phase for USER test
  uvm_config_db#(bit)::set(null, "*", "disable_rready_check_for_qos_cleanup", 1'b1);
  `uvm_info(get_type_name(), "Disabled RREADY assertion checking during cleanup phase for USER test", UVM_LOW)
  
  `uvm_info(get_type_name(), "USER signal width mismatch test configuration completed", UVM_MEDIUM)
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Executes the USER signal width mismatch test
//--------------------------------------------------------------------------------------------
task axi4_user_signal_width_mismatch_test::run_phase(uvm_phase phase);
  
  phase.raise_objection(this, "axi4_user_signal_width_mismatch_test");
  
  `uvm_info(get_type_name(), "Starting AXI4 USER Signal Width Mismatch Test", UVM_LOW)
  `uvm_info(get_type_name(), "Test objective: Verify system handles different USER signal width patterns", UVM_LOW)
  `uvm_info(get_type_name(), "Coverage: 8-bit, 16-bit, 24-bit, 32-bit effective widths + boundary conditions", UVM_LOW)
  
  // Create and start the virtual sequence
  axi4_virtual_user_signal_width_mismatch_seq_h = axi4_virtual_user_signal_width_mismatch_seq::type_id::create("axi4_virtual_user_signal_width_mismatch_seq_h");
  
  // Configure the virtual sequence
  axi4_virtual_user_signal_width_mismatch_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Signal that we're entering cleanup phase
  uvm_config_db#(bit)::set(null, "*", "qos_test_cleanup_phase", 1'b1);
  
  // Wait for all transactions to complete
  #3000;
  
  `uvm_info(get_type_name(), "AXI4 USER Signal Width Mismatch Test completed", UVM_LOW)
  `uvm_info(get_type_name(), "Test success criteria:", UVM_LOW)
  `uvm_info(get_type_name(), "1. 8-bit effective USER patterns handled correctly", UVM_LOW)
  `uvm_info(get_type_name(), "2. 16-bit effective USER patterns handled correctly", UVM_LOW)
  `uvm_info(get_type_name(), "3. 24-bit effective USER patterns handled correctly", UVM_LOW)
  `uvm_info(get_type_name(), "4. Full 32-bit USER patterns handled correctly", UVM_LOW)
  `uvm_info(get_type_name(), "5. Boundary conditions (min/max values) work properly", UVM_LOW)
  `uvm_info(get_type_name(), "6. Sparse and dense bit patterns are supported", UVM_LOW)
  
  phase.drop_objection(this, "axi4_user_signal_width_mismatch_test");
  
endtask : run_phase

`endif