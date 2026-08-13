`ifndef AXI4_CONCURRENT_READS_TEST_INCLUDED_
`define AXI4_CONCURRENT_READS_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_concurrent_reads_test
// Test Case 1: Concurrent Read Operations (AxPROT & AxCACHE Focus)
// Based on claude.md specification - Table Master-Slave Access Test Matrix
//--------------------------------------------------------------------------------------------
class axi4_concurrent_reads_test extends axi4_base_test;
  
  `uvm_component_utils(axi4_concurrent_reads_test)

  // Virtual sequence for coordinating concurrent reads
  axi4_concurrent_reads_virtual_seq axi4_concurrent_reads_vseq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_concurrent_reads_test", uvm_component parent = null);
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_concurrent_reads_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_concurrent_reads_test::new(string name = "axi4_concurrent_reads_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agent_cfg
// Override to configure slaves with SLAVE_MEM_MODE for consistent responses
//--------------------------------------------------------------------------------------------
function void axi4_concurrent_reads_test::setup_axi4_slave_agent_cfg();
  // Call parent implementation first
  super.setup_axi4_slave_agent_cfg();
  
  // Configure all slaves to use SLAVE_MEM_MODE
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_response_mode = RESP_IN_ORDER;
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
    `uvm_info(get_type_name(), $sformatf("TC001: Configured slave[%0d] with SLAVE_MEM_MODE", i), UVM_MEDIUM);
  end
endfunction : setup_axi4_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Executes Test Case 1: Concurrent Read Operations
//--------------------------------------------------------------------------------------------
task axi4_concurrent_reads_test::run_phase(uvm_phase phase);
  
  phase.raise_objection(this, "axi4_concurrent_reads_test");

  `uvm_info(get_type_name(), "==============================================", UVM_NONE);
  `uvm_info(get_type_name(), "  TEST CASE 1: CONCURRENT READ OPERATIONS", UVM_NONE);
  `uvm_info(get_type_name(), "  Focus: AxPROT & AxCACHE Verification", UVM_NONE);
  `uvm_info(get_type_name(), "==============================================", UVM_NONE);

  // Configure as read-only test to avoid scoreboard write transaction errors
  axi4_env_h.axi4_env_cfg_h.write_read_mode_h = ONLY_READ_DATA;
  `uvm_info(get_type_name(), "TC001: Configured as ONLY_READ_DATA test mode", UVM_MEDIUM);

  // This test's whole focus is AxPROT/AxCACHE access control, so error
  // responses are the expected outcome, not a defect: of its 5 reads the
  // scoreboard expects READ_SLVERR for the ARPROT=111 access-control case and
  // READ_DECERR for two out-of-range addresses, and confirms all three
  // ("Correctly generated READ_SLVERR ... access control validation
  // successful").  axi4_performance_metrics still scored them as Protocol
  // Issues because this class name matches none of its auto-detect patterns
  // and allow_error_responses defaults to 0 (axi4_base_test.sv:172).  Same
  // convention as axi4_sequential_mixed_ops_test.sv:38.  The scoreboard
  // remains the real checker for response correctness.
  axi4_env_h.axi4_env_cfg_h.allow_error_responses = 1;
  `uvm_info(get_type_name(), "TC001: allow_error_responses=1 - AxPROT/decode rejections are expected", UVM_MEDIUM);

  // Start timeout watchdog
  fork
    timeout_watchdog();
  join_none

  // Create and execute the virtual sequence
  axi4_concurrent_reads_vseq_h = axi4_concurrent_reads_virtual_seq::type_id::create("axi4_concurrent_reads_vseq_h");
  
  fork
    begin
      axi4_concurrent_reads_vseq_h.start(axi4_env_h.axi4_virtual_seqr_h);
    end
  join
  
  `uvm_info(get_type_name(), "==============================================", UVM_NONE);
  `uvm_info(get_type_name(), "  TEST CASE 1: COMPLETED SUCCESSFULLY", UVM_NONE);
  `uvm_info(get_type_name(), "==============================================", UVM_NONE);

  phase.drop_objection(this);

endtask : run_phase

`endif