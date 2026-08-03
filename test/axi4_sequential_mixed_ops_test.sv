`ifndef AXI4_SEQUENTIAL_MIXED_OPS_TEST_INCLUDED_
`define AXI4_SEQUENTIAL_MIXED_OPS_TEST_INCLUDED_

class axi4_sequential_mixed_ops_test extends axi4_base_test;
  `uvm_component_utils(axi4_sequential_mixed_ops_test)
  
  axi4_sequential_mixed_ops_virtual_seq axi4_sequential_mixed_ops_vseq_h;

  extern function new(string name = "axi4_sequential_mixed_ops_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_sequential_mixed_ops_test

function axi4_sequential_mixed_ops_test::new(string name = "axi4_sequential_mixed_ops_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task axi4_sequential_mixed_ops_test::run_phase(uvm_phase phase);
  phase.raise_objection(this, "axi4_sequential_mixed_ops_test");

  `uvm_info(get_type_name(), "==============================================", UVM_NONE);
  `uvm_info(get_type_name(), "  TEST CASE 3: SEQUENTIAL MIXED OPERATIONS", UVM_NONE);
  `uvm_info(get_type_name(), "==============================================", UVM_NONE);

  // Configure as mixed read/write test for sequential operations
  axi4_env_h.axi4_env_cfg_h.write_read_mode_h = WRITE_READ_DATA;
  `uvm_info(get_type_name(), "TC003: Configured as WRITE_READ_DATA test mode for mixed operations", UVM_MEDIUM);

  // Step 3 of axi4_sequential_mixed_ops_virtual_seq is a deliberate access-control probe
  // (M7 -> S7 write, "Expect: SLVERR" - see virtual_seq/axi4_sequential_mixed_ops_virtual_seq.sv:128),
  // mixed in among three legitimate OKAY transactions. The scoreboard already validates it
  // correctly ("Correctly generated WRITE_SLVERR ... access control validation successful"),
  // but axi4_performance_metrics counted the SLVERR as a "Protocol Issue" and failed the test:
  // this class's name matches none of its auto-detect patterns (*error*, *illegal*,
  // *violation*, *raw*, *slave_error*, *exception*), and allow_error_responses defaults to 0
  // (axi4_base_test.sv:172). Same convention as axi4_enhanced_bus_matrix_test.sv:45, which
  // sets this for the identical M7-security-violation scenario.
  axi4_env_h.axi4_env_cfg_h.allow_error_responses = 1;
  `uvm_info(get_type_name(), "TC003: allow_error_responses=1 - step 3 deliberately provokes SLVERR", UVM_MEDIUM);

  fork
    timeout_watchdog();
  join_none

  axi4_sequential_mixed_ops_vseq_h = axi4_sequential_mixed_ops_virtual_seq::type_id::create("axi4_sequential_mixed_ops_vseq_h");
  
  fork
    begin
      axi4_sequential_mixed_ops_vseq_h.start(axi4_env_h.axi4_virtual_seqr_h);
    end
  join
  
  `uvm_info(get_type_name(), "  TEST CASE 3: COMPLETED SUCCESSFULLY", UVM_NONE);
  phase.drop_objection(this);
endtask : run_phase

`endif