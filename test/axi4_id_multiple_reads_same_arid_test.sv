`ifndef AXI4_ID_MULTIPLE_READS_SAME_ARID_TEST_INCLUDED_
`define AXI4_ID_MULTIPLE_READS_SAME_ARID_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_id_multiple_reads_same_arid_test
// ID_MULTIPLE_READS_SAME_ARID: ID Multiple Reads Same ARID  
// Verifies that Slave responds to multiple read requests with the same ARID in order
//--------------------------------------------------------------------------------------------
class axi4_id_multiple_reads_same_arid_test extends axi4_base_test;
  `uvm_component_utils(axi4_id_multiple_reads_same_arid_test)

  axi4_virtual_id_multiple_reads_same_arid_seq axi4_virtual_id_multiple_reads_same_arid_seq_h;

  extern function new(string name = "axi4_id_multiple_reads_same_arid_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_id_multiple_reads_same_arid_test

function axi4_id_multiple_reads_same_arid_test::new(string name = "axi4_id_multiple_reads_same_arid_test",
                                 uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_id_multiple_reads_same_arid_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction : build_phase

task axi4_id_multiple_reads_same_arid_test::run_phase(uvm_phase phase);
  
  phase.raise_objection(this);
  
  axi4_virtual_id_multiple_reads_same_arid_seq_h = axi4_virtual_id_multiple_reads_same_arid_seq::type_id::create("axi4_virtual_id_multiple_reads_same_arid_seq_h");
  
  `uvm_info(get_type_name(),$sformatf("axi4_id_multiple_reads_same_arid_test"),UVM_LOW);
  axi4_virtual_id_multiple_reads_same_arid_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  #10;
  
  phase.drop_objection(this);

endtask : run_phase

`endif