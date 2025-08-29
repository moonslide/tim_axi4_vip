`ifndef AXI4_MINIMAL_PASS_TEST_INCLUDED_
`define AXI4_MINIMAL_PASS_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_minimal_pass_test
// Minimal test that immediately passes
//--------------------------------------------------------------------------------------------
class axi4_minimal_pass_test extends uvm_test;
  `uvm_component_utils(axi4_minimal_pass_test)

  function new(string name = "axi4_minimal_pass_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Minimal test - immediate pass", UVM_LOW)
    phase.drop_objection(this);
  endtask : run_phase

endclass : axi4_minimal_pass_test

`endif