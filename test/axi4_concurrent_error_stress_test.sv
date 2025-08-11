`ifndef AXI4_CONCURRENT_ERROR_STRESS_TEST_INCLUDED_
`define AXI4_CONCURRENT_ERROR_STRESS_TEST_INCLUDED_

class axi4_concurrent_error_stress_test extends axi4_base_test;
  `uvm_component_utils(axi4_concurrent_error_stress_test)
  
  axi4_concurrent_error_stress_virtual_seq axi4_concurrent_error_stress_vseq_h;

  extern function new(string name = "axi4_concurrent_error_stress_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_concurrent_error_stress_test

function axi4_concurrent_error_stress_test::new(string name = "axi4_concurrent_error_stress_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task axi4_concurrent_error_stress_test::run_phase(uvm_phase phase);
  phase.raise_objection(this, "axi4_concurrent_error_stress_test");

  `uvm_info(get_type_name(), "==============================================", UVM_NONE);
  `uvm_info(get_type_name(), "  TEST CASE 4: CONCURRENT ERROR STRESS", UVM_NONE);
  `uvm_info(get_type_name(), "==============================================", UVM_NONE);

  // Configure as mixed read/write test to handle error transactions properly
  axi4_env_h.axi4_env_cfg_h.write_read_mode_h = WRITE_READ_DATA;
  `uvm_info(get_type_name(), "TC004: Configured as WRITE_READ_DATA test mode", UVM_MEDIUM);

  fork
    timeout_watchdog();
  join_none

  axi4_concurrent_error_stress_vseq_h = axi4_concurrent_error_stress_virtual_seq::type_id::create("axi4_concurrent_error_stress_vseq_h");
  
  fork
    begin
      axi4_concurrent_error_stress_vseq_h.start(axi4_env_h.axi4_virtual_seqr_h);
    end
  join
  
  `uvm_info(get_type_name(), "  TEST CASE 4: COMPLETED SUCCESSFULLY", UVM_NONE);
  phase.drop_objection(this);
endtask : run_phase

`endif