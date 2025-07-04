`ifndef AXI4_VIRTUAL_UPPER_BOUNDARY_WRITE_SEQ_INCLUDED_
`define AXI4_VIRTUAL_UPPER_BOUNDARY_WRITE_SEQ_INCLUDED_

class axi4_virtual_upper_boundary_write_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_upper_boundary_write_seq)

  extern function new(string name="axi4_virtual_upper_boundary_write_seq");
  extern task body();
endclass

function axi4_virtual_upper_boundary_write_seq::new(string name);
  super.new(name);
endfunction

task axi4_virtual_upper_boundary_write_seq::body();
  axi4_master_upper_boundary_write_seq mseq;
  bit s_done;
  bit m_done;
  foreach (p_sequencer.axi4_master_write_seqr_h_all[i]) begin
    foreach (p_sequencer.axi4_slave_write_seqr_h_all[j]) begin
      axi4_slave_nbk_write_seq sseq;
      s_done = 0;
      sseq = axi4_slave_nbk_write_seq::type_id::create($sformatf("swr_%0d_%0d", i,j));
      fork
        begin
          sseq.start(p_sequencer.axi4_slave_write_seqr_h_all[j]);
          s_done = 1;
        end
        begin : slv_timeout
          #1us;
          if(!s_done)
            `uvm_error(get_type_name(), $sformatf("slave seq %0d_%0d timed out", i,j))
        end
      join_any;
    end
    mseq = axi4_master_upper_boundary_write_seq::type_id::create($sformatf("mseq_%0d", i));
    m_done = 0;
    fork
      begin
        mseq.start(p_sequencer.axi4_master_write_seqr_h_all[i]);
        m_done = 1;
      end
      begin : mst_timeout
        #1us;
        if(!m_done)
          `uvm_error(get_type_name(), $sformatf("master seq %0d timed out", i))
      end
    join_any;
  end
endtask

`endif
