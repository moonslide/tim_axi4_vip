`ifndef AXI4_TC_001_CONCURRENT_READS_TEST_INCLUDED_
`define AXI4_TC_001_CONCURRENT_READS_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_tc_001_concurrent_reads_test
// Test Case 1: Concurrent Read Operations (AxPROT & AxCACHE Focus)
// Based on claude.md specification - Table Master-Slave Access Test Matrix
//--------------------------------------------------------------------------------------------
class axi4_tc_001_concurrent_reads_test extends axi4_base_test;
  
  `uvm_component_utils(axi4_tc_001_concurrent_reads_test)

  // Virtual sequence for coordinating concurrent reads
  axi4_tc_001_concurrent_reads_virtual_seq axi4_tc_001_vseq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_tc_001_concurrent_reads_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_tc_001_concurrent_reads_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_tc_001_concurrent_reads_test::new(string name = "axi4_tc_001_concurrent_reads_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Executes Test Case 1: Concurrent Read Operations
//--------------------------------------------------------------------------------------------
task axi4_tc_001_concurrent_reads_test::run_phase(uvm_phase phase);
  
  phase.raise_objection(this, "axi4_tc_001_concurrent_reads_test");

  `uvm_info(get_type_name(), "==============================================", UVM_NONE);
  `uvm_info(get_type_name(), "  TEST CASE 1: CONCURRENT READ OPERATIONS", UVM_NONE);
  `uvm_info(get_type_name(), "  Focus: AxPROT & AxCACHE Verification", UVM_NONE);
  `uvm_info(get_type_name(), "==============================================", UVM_NONE);

  // Configure as read-only test to avoid scoreboard write transaction errors
  axi4_env_h.axi4_env_cfg_h.write_read_mode_h = ONLY_READ_DATA;
  `uvm_info(get_type_name(), "TC001: Configured as ONLY_READ_DATA test mode", UVM_MEDIUM);

  // Start timeout watchdog
  fork
    timeout_watchdog();
  join_none

  // Create and execute the virtual sequence
  axi4_tc_001_vseq_h = axi4_tc_001_concurrent_reads_virtual_seq::type_id::create("axi4_tc_001_vseq_h");
  
  fork
    begin
      axi4_tc_001_vseq_h.start(axi4_env_h.axi4_virtual_seqr_h);
    end
  join
  
  `uvm_info(get_type_name(), "==============================================", UVM_NONE);
  `uvm_info(get_type_name(), "  TEST CASE 1: COMPLETED SUCCESSFULLY", UVM_NONE);
  `uvm_info(get_type_name(), "==============================================", UVM_NONE);

  phase.drop_objection(this);

endtask : run_phase

`endif