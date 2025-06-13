`ifndef AXI4_AR_READY_DELAY_TEST_INCLUDED_
`define AXI4_AR_READY_DELAY_TEST_INCLUDED_

class axi4_ar_ready_delay_test extends axi4_base_test;
  `uvm_component_utils(axi4_ar_ready_delay_test)

  axi4_virtual_ar_ready_delay_seq vseq;

  function new(string name="axi4_ar_ready_delay_test", uvm_component parent=null);
    super.new(name,parent);
  endfunction

  task run_phase(uvm_phase phase);
    vseq = axi4_virtual_ar_ready_delay_seq::type_id::create("vseq");
    phase.raise_objection(this);
    vseq.start(axi4_env_h.axi4_virtual_seqr_h);
    phase.drop_objection(this);
  endtask
endclass

`endif
