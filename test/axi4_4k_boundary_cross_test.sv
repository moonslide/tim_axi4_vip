`ifndef AXI4_4K_BOUNDARY_CROSS_TEST_INCLUDED_
`define AXI4_4K_BOUNDARY_CROSS_TEST_INCLUDED_

class axi4_4k_boundary_cross_test extends axi4_base_test;
  `uvm_component_utils(axi4_4k_boundary_cross_test)

  axi4_virtual_4k_boundary_cross_seq vseq;

  extern function new(string name="axi4_4k_boundary_cross_test", uvm_component parent=null);
  extern virtual task run_phase(uvm_phase phase);
endclass

function axi4_4k_boundary_cross_test::new(string name, uvm_component parent=null);
  super.new(name,parent);
endfunction

task axi4_4k_boundary_cross_test::run_phase(uvm_phase phase);
  vseq = axi4_virtual_4k_boundary_cross_seq::type_id::create("vseq");
  phase.raise_objection(this);
  vseq.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
endtask

`endif
