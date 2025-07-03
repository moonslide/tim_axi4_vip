`ifndef AXI4_UPPER_BOUNDARY_WRITE_TEST_INCLUDED_
`define AXI4_UPPER_BOUNDARY_WRITE_TEST_INCLUDED_

class axi4_upper_boundary_write_test extends axi4_base_test;
  `uvm_component_utils(axi4_upper_boundary_write_test)

  axi4_virtual_upper_boundary_write_seq vseq;

  extern function new(string name="axi4_upper_boundary_write_test", uvm_component parent=null);
  extern virtual task run_phase(uvm_phase phase);
endclass

function axi4_upper_boundary_write_test::new(string name, uvm_component parent=null);
  super.new(name,parent);
endfunction

task axi4_upper_boundary_write_test::run_phase(uvm_phase phase);
  vseq = axi4_virtual_upper_boundary_write_seq::type_id::create("vseq");
  phase.raise_objection(this);
  vseq.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
endtask

`endif
