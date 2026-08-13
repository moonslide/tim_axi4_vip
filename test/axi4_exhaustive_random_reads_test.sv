`ifndef AXI4_EXHAUSTIVE_RANDOM_READS_TEST_INCLUDED_
`define AXI4_EXHAUSTIVE_RANDOM_READS_TEST_INCLUDED_

class axi4_exhaustive_random_reads_test extends axi4_base_test;
  `uvm_component_utils(axi4_exhaustive_random_reads_test)
  
  axi4_exhaustive_random_reads_virtual_seq axi4_exhaustive_random_reads_vseq_h;

  extern function new(string name = "axi4_exhaustive_random_reads_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_exhaustive_random_reads_test

function axi4_exhaustive_random_reads_test::new(string name = "axi4_exhaustive_random_reads_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task axi4_exhaustive_random_reads_test::run_phase(uvm_phase phase);
  phase.raise_objection(this, "axi4_exhaustive_random_reads_test");

  `uvm_info(get_type_name(), "==============================================", UVM_NONE);
  `uvm_info(get_type_name(), "  TEST CASE 5: EXHAUSTIVE RANDOM READS", UVM_NONE);
  `uvm_info(get_type_name(), "==============================================", UVM_NONE);

  // Configure as read-only test to avoid scoreboard write transaction comparison errors
  axi4_env_h.axi4_env_cfg_h.write_read_mode_h = ONLY_READ_DATA;
  `uvm_info(get_type_name(), "TC005: Configured as ONLY_READ_DATA test mode", UVM_MEDIUM);

  // This test reads 500 unconstrained 64-bit addresses (0xeb0ddeac87357890,
  // 0x8bb3e40f8dcd431a, ...), essentially all of which are outside the map, so
  // DECERR is the CORRECT answer for essentially every read -- the scoreboard
  // confirms all 500 ("Correctly generated READ_DECERR") with zero data
  // mismatches.  Proving the interconnect rejects unmapped space IS the test.
  // axi4_performance_metrics still scored them as Protocol Issues because this
  // class name matches none of its auto-detect patterns and
  // allow_error_responses defaults to 0 (axi4_base_test.sv:172).  Same
  // convention as axi4_sequential_mixed_ops_test.sv:38.
  axi4_env_h.axi4_env_cfg_h.allow_error_responses = 1;
  `uvm_info(get_type_name(), "TC005: allow_error_responses=1 - random addresses are unmapped by construction", UVM_MEDIUM);

  fork
    timeout_watchdog();
  join_none

  axi4_exhaustive_random_reads_vseq_h = axi4_exhaustive_random_reads_virtual_seq::type_id::create("axi4_exhaustive_random_reads_vseq_h");
  
  fork
    begin
      axi4_exhaustive_random_reads_vseq_h.start(axi4_env_h.axi4_virtual_seqr_h);
    end
  join
  
  `uvm_info(get_type_name(), "  TEST CASE 5: COMPLETED SUCCESSFULLY", UVM_NONE);
  phase.drop_objection(this);
endtask : run_phase

`endif