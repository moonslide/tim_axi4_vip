`ifndef AXI4_TC_005_EXHAUSTIVE_RANDOM_READS_TEST_INCLUDED_
`define AXI4_TC_005_EXHAUSTIVE_RANDOM_READS_TEST_INCLUDED_

class axi4_tc_005_exhaustive_random_reads_test extends axi4_base_test;
  `uvm_component_utils(axi4_tc_005_exhaustive_random_reads_test)
  
  axi4_tc_005_exhaustive_random_reads_virtual_seq axi4_tc_005_vseq_h;

  extern function new(string name = "axi4_tc_005_exhaustive_random_reads_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_tc_005_exhaustive_random_reads_test

function axi4_tc_005_exhaustive_random_reads_test::new(string name = "axi4_tc_005_exhaustive_random_reads_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task axi4_tc_005_exhaustive_random_reads_test::run_phase(uvm_phase phase);
  phase.raise_objection(this, "axi4_tc_005_exhaustive_random_reads_test");

  `uvm_info(get_type_name(), "==============================================", UVM_NONE);
  `uvm_info(get_type_name(), "  TEST CASE 5: EXHAUSTIVE RANDOM READS", UVM_NONE);
  `uvm_info(get_type_name(), "==============================================", UVM_NONE);

  // Configure as read-only test to avoid scoreboard write transaction comparison errors
  axi4_env_h.axi4_env_cfg_h.write_read_mode_h = ONLY_READ_DATA;
  `uvm_info(get_type_name(), "TC005: Configured as ONLY_READ_DATA test mode", UVM_MEDIUM);

  fork
    timeout_watchdog();
  join_none

  axi4_tc_005_vseq_h = axi4_tc_005_exhaustive_random_reads_virtual_seq::type_id::create("axi4_tc_005_vseq_h");
  
  fork
    begin
      axi4_tc_005_vseq_h.start(axi4_env_h.axi4_virtual_seqr_h);
    end
  join
  
  `uvm_info(get_type_name(), "  TEST CASE 5: COMPLETED SUCCESSFULLY", UVM_NONE);
  phase.drop_objection(this);
endtask : run_phase

`endif