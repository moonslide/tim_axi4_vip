`ifndef AXI4_MATRIX_MASTER_SLAVE_ACCESS_TEST_INCLUDED_
`define AXI4_MATRIX_MASTER_SLAVE_ACCESS_TEST_INCLUDED_

class axi4_matrix_master_slave_access_test extends axi4_base_test;
  `uvm_component_utils(axi4_matrix_master_slave_access_test)

  axi4_virtual_matrix_access_seq v_seq;

  extern function new(string name="axi4_matrix_master_slave_access_test", uvm_component parent=null);
  extern virtual task run_phase(uvm_phase phase);
endclass : axi4_matrix_master_slave_access_test

function axi4_matrix_master_slave_access_test::new(string name, uvm_component parent=null);
  super.new(name,parent);
endfunction

task axi4_matrix_master_slave_access_test::run_phase(uvm_phase phase);
  v_seq = axi4_virtual_matrix_access_seq::type_id::create("v_seq");
  phase.raise_objection(this);
  v_seq.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
endtask

`endif
