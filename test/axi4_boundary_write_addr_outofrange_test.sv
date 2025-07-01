`ifndef AXI4_BOUNDARY_WRITE_ADDR_OUTOFRANGE_TEST_INCLUDED_
`define AXI4_BOUNDARY_WRITE_ADDR_OUTOFRANGE_TEST_INCLUDED_

class axi4_boundary_write_addr_outofrange_test extends axi4_base_test;
  `uvm_component_utils(axi4_boundary_write_addr_outofrange_test)

  axi4_virtual_boundary_write_addr_outofrange_seq axi4_virtual_boundary_write_addr_outofrange_seq_h;

  extern function new(string name="axi4_boundary_write_addr_outofrange_test", uvm_component parent=null);
  extern virtual task run_phase(uvm_phase phase);
endclass : axi4_boundary_write_addr_outofrange_test

function axi4_boundary_write_addr_outofrange_test::new(string name, uvm_component parent=null);
  super.new(name,parent);
endfunction

task axi4_boundary_write_addr_outofrange_test::run_phase(uvm_phase phase);
  axi4_virtual_boundary_write_addr_outofrange_seq_h = axi4_virtual_boundary_write_addr_outofrange_seq::type_id::create("axi4_virtual_boundary_write_addr_outofrange_seq_h");
  phase.raise_objection(this);
  axi4_virtual_boundary_write_addr_outofrange_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
endtask

`endif
