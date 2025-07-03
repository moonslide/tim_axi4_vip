`ifndef AXI4_VIRTUAL_UPPER_BOUNDARY_READ_SEQ_INCLUDED_
`define AXI4_VIRTUAL_UPPER_BOUNDARY_READ_SEQ_INCLUDED_

class axi4_virtual_upper_boundary_read_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_upper_boundary_read_seq)

  extern function new(string name="axi4_virtual_upper_boundary_read_seq");
  extern task body();
endclass

function axi4_virtual_upper_boundary_read_seq::new(string name);
  super.new(name);
endfunction

task axi4_virtual_upper_boundary_read_seq::body();
  axi4_master_upper_boundary_read_seq mseq;
  foreach (p_sequencer.axi4_master_read_seqr_h_all[i]) begin
    foreach (p_sequencer.axi4_slave_read_seqr_h_all[j]) begin
      axi4_slave_nbk_read_seq::type_id::create($sformatf("sr_%0d_%0d", i,j)).start(p_sequencer.axi4_slave_read_seqr_h_all[j]);
    end
    mseq = axi4_master_upper_boundary_read_seq::type_id::create($sformatf("mseq_%0d", i));
    mseq.start(p_sequencer.axi4_master_read_seqr_h_all[i]);
  end
endtask

`endif
