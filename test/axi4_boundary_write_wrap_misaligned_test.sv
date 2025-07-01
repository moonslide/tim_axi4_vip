`ifndef AXI4_BOUNDARY_WRITE_WRAP_MISALIGNED_TEST_INCLUDED_
`define AXI4_BOUNDARY_WRITE_WRAP_MISALIGNED_TEST_INCLUDED_

class axi4_boundary_write_wrap_misaligned_test extends axi4_base_test;
  `uvm_component_utils(axi4_boundary_write_wrap_misaligned_test)

  axi4_virtual_boundary_write_wrap_misaligned_seq axi4_virtual_boundary_write_wrap_misaligned_seq_h;

  extern function new(string name="axi4_boundary_write_wrap_misaligned_test", uvm_component parent=null);
  extern virtual task run_phase(uvm_phase phase);
endclass : axi4_boundary_write_wrap_misaligned_test

function axi4_boundary_write_wrap_misaligned_test::new(string name, uvm_component parent=null);
  super.new(name,parent);
endfunction

task axi4_boundary_write_wrap_misaligned_test::run_phase(uvm_phase phase);
  axi4_virtual_boundary_write_wrap_misaligned_seq_h = axi4_virtual_boundary_write_wrap_misaligned_seq::type_id::create("axi4_virtual_boundary_write_wrap_misaligned_seq_h");
  phase.raise_objection(this);
  axi4_virtual_boundary_write_wrap_misaligned_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
endtask

`endif
