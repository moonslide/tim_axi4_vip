`ifndef AXI4_AW_W_CHANNEL_SEPARATION_TEST_INCLUDED_
`define AXI4_AW_W_CHANNEL_SEPARATION_TEST_INCLUDED_

class axi4_aw_w_channel_separation_test extends axi4_base_test;
  `uvm_component_utils(axi4_aw_w_channel_separation_test)

  axi4_virtual_aw_w_channel_separation_seq vseq;

  function new(string name="axi4_aw_w_channel_separation_test", uvm_component parent=null);
    super.new(name,parent);
  endfunction

  task run_phase(uvm_phase phase);
    vseq = axi4_virtual_aw_w_channel_separation_seq::type_id::create("vseq");
    phase.raise_objection(this);
    vseq.start(axi4_env_h.axi4_virtual_seqr_h);
    phase.drop_objection(this);
  endtask
endclass

`endif
