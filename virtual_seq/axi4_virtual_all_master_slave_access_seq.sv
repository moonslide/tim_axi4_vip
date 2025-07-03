`ifndef AXI4_VIRTUAL_ALL_MASTER_SLAVE_ACCESS_SEQ_INCLUDED_
`define AXI4_VIRTUAL_ALL_MASTER_SLAVE_ACCESS_SEQ_INCLUDED_

class axi4_virtual_all_master_slave_access_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_all_master_slave_access_seq)

  extern function new(string name="axi4_virtual_all_master_slave_access_seq");
  extern task body();
endclass

function axi4_virtual_all_master_slave_access_seq::new(string name="axi4_virtual_all_master_slave_access_seq");
  super.new(name);
endfunction

task axi4_virtual_all_master_slave_access_seq::body();
  axi4_master_all_slave_access_seq mseq;
  foreach (p_sequencer.axi4_master_write_seqr_h_all[i]) begin
    // start slave responders on all slaves
    foreach (p_sequencer.axi4_slave_write_seqr_h_all[j]) begin
      axi4_slave_nbk_write_seq::type_id::create($sformatf("sl_wr_%0d_%0d", i, j)).start(p_sequencer.axi4_slave_write_seqr_h_all[j]);
    end
    foreach (p_sequencer.axi4_slave_read_seqr_h_all[j]) begin
      axi4_slave_nbk_read_seq::type_id::create($sformatf("sl_rd_%0d_%0d", i, j)).start(p_sequencer.axi4_slave_read_seqr_h_all[j]);
    end
    mseq = axi4_master_all_slave_access_seq::type_id::create($sformatf("mseq_%0d", i));
    mseq.start(p_sequencer.axi4_master_write_seqr_h_all[i]);
  end
endtask

`endif
