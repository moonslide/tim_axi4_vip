`ifndef AXI4_VIRTUAL_4K_BOUNDARY_CROSS_SEQ_INCLUDED_
`define AXI4_VIRTUAL_4K_BOUNDARY_CROSS_SEQ_INCLUDED_

class axi4_virtual_4k_boundary_cross_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_4k_boundary_cross_seq)

  extern function new(string name="axi4_virtual_4k_boundary_cross_seq");
  extern task body();
endclass

function axi4_virtual_4k_boundary_cross_seq::new(string name);
  super.new(name);
endfunction

task axi4_virtual_4k_boundary_cross_seq::body();
  axi4_master_4k_boundary_cross_seq mseq;
  foreach (p_sequencer.axi4_master_write_seqr_h_all[i]) begin
    foreach (p_sequencer.axi4_slave_write_seqr_h_all[j]) begin
      axi4_slave_nbk_write_seq::type_id::create($sformatf("swr_%0d_%0d", i,j)).start(p_sequencer.axi4_slave_write_seqr_h_all[j]);
    end
    foreach (p_sequencer.axi4_slave_read_seqr_h_all[j]) begin
      axi4_slave_nbk_read_seq::type_id::create($sformatf("sr_%0d_%0d", i,j)).start(p_sequencer.axi4_slave_read_seqr_h_all[j]);
    end
    mseq = axi4_master_4k_boundary_cross_seq::type_id::create($sformatf("mseq_%0d", i));
    mseq.start(p_sequencer.axi4_master_write_seqr_h_all[i]);
  end
endtask

`endif
