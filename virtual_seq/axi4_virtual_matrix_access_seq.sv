`ifndef AXI4_VIRTUAL_MATRIX_ACCESS_SEQ_INCLUDED_
`define AXI4_VIRTUAL_MATRIX_ACCESS_SEQ_INCLUDED_

class axi4_virtual_matrix_access_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_matrix_access_seq)

  axi4_slave_bk_write_incr_burst_seq sl_wr;
  axi4_slave_bk_read_incr_burst_seq  sl_rd;

  extern function new(string name="axi4_virtual_matrix_access_seq");
  extern task body();
endclass : axi4_virtual_matrix_access_seq

function axi4_virtual_matrix_access_seq::new(string name);
  super.new(name);
endfunction

task axi4_virtual_matrix_access_seq::body();
  import axi4_config_pkg::*;
  super.body();
  sl_wr = axi4_slave_bk_write_incr_burst_seq::type_id::create("sl_wr");
  sl_rd = axi4_slave_bk_read_incr_burst_seq::type_id::create("sl_rd");
  fork
    forever sl_wr.start(p_sequencer.axi4_slave_write_seqr_h);
    forever sl_rd.start(p_sequencer.axi4_slave_read_seqr_h);
  join_none
  #10ns; // allow slave sequences to initialize

  foreach (p_sequencer.axi4_master_write_seqr_h_all[m]) begin
    foreach (slave_addr_table[s]) begin
      axi4_master_matrix_write_seq wr;
      axi4_master_matrix_read_seq rd;
      wr = axi4_master_matrix_write_seq::type_id::create($sformatf("wr_m%0d_s%0d", m, s));
      rd = axi4_master_matrix_read_seq::type_id::create($sformatf("rd_m%0d_s%0d", m, s));
      wr.addr = slave_addr_table[s].base_addr;
      wr.data = {$random};
      wr.start(p_sequencer.axi4_master_write_seqr_h_all[m]);
      rd.addr = slave_addr_table[s].base_addr;
      rd.start(p_sequencer.axi4_master_read_seqr_h_all[m]);
    end
  end
endtask

`endif
