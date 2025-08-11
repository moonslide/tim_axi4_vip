`ifndef AXI4_CONCURRENT_WRITES_RAW_TEST_INCLUDED_
`define AXI4_CONCURRENT_WRITES_RAW_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_concurrent_writes_raw_test
// Test Case 2: Concurrent Write Operations and Read-After-Write Verification
// Based on claude.md specification - Focus on AWPROT & AWCACHE attributes
//--------------------------------------------------------------------------------------------
class axi4_concurrent_writes_raw_test extends axi4_base_test;
  
  `uvm_component_utils(axi4_concurrent_writes_raw_test)

  // Virtual sequence for coordinating concurrent writes and read-after-write
  axi4_concurrent_writes_raw_virtual_seq axi4_concurrent_writes_raw_vseq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_concurrent_writes_raw_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_concurrent_writes_raw_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_concurrent_writes_raw_test::new(string name = "axi4_concurrent_writes_raw_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Executes Test Case 2: Concurrent Write Operations and Read-After-Write Verification
//--------------------------------------------------------------------------------------------
task axi4_concurrent_writes_raw_test::run_phase(uvm_phase phase);
  
  phase.raise_objection(this, "axi4_concurrent_writes_raw_test");

  `uvm_info(get_type_name(), "==============================================", UVM_NONE);
  `uvm_info(get_type_name(), "  TEST CASE 2: CONCURRENT WRITE OPERATIONS", UVM_NONE);
  `uvm_info(get_type_name(), "  Focus: AWPROT & AWCACHE + Read-After-Write", UVM_NONE);
  `uvm_info(get_type_name(), "==============================================", UVM_NONE);

  // Start timeout watchdog
  fork
    timeout_watchdog();
  join_none

  // Create and execute the virtual sequence
  axi4_concurrent_writes_raw_vseq_h = axi4_concurrent_writes_raw_virtual_seq::type_id::create("axi4_concurrent_writes_raw_vseq_h");
  
  fork
    begin
      axi4_concurrent_writes_raw_vseq_h.start(axi4_env_h.axi4_virtual_seqr_h);
    end
  join
  
  `uvm_info(get_type_name(), "==============================================", UVM_NONE);
  `uvm_info(get_type_name(), "  TEST CASE 2: COMPLETED SUCCESSFULLY", UVM_NONE);
  `uvm_info(get_type_name(), "==============================================", UVM_NONE);

  phase.drop_objection(this);

endtask : run_phase

`endif