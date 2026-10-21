`ifndef AXI4_VIRTUAL_QOS_WR_TAGGED_SEQ_INCLUDED_
`define AXI4_VIRTUAL_QOS_WR_TAGGED_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_qos_wr_tagged_seq
//  Issues a caller-defined list of single-beat tagged writes from master 0, in
//  list order and back to back, each with its own AWQOS and AWID
//  (axi4_master_qos_tagged_write_seq), and keeps the subordinate sequences
//  running underneath. Returns once the last write has been handed to the
//  driver. Used by axi4_qos_wr_aw_order_test.
//--------------------------------------------------------------------------------------------
class axi4_virtual_qos_wr_tagged_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_qos_wr_tagged_seq)

  // Variables: wr_qos / wr_awid
  // One entry per write, issued in this order. Same length.
  bit [3:0] wr_qos[$];
  int       wr_awid[$];

  extern function new(string name = "axi4_virtual_qos_wr_tagged_seq");
  extern task body();
endclass : axi4_virtual_qos_wr_tagged_seq

function axi4_virtual_qos_wr_tagged_seq::new(string name = "axi4_virtual_qos_wr_tagged_seq");
  super.new(name);
endfunction : new

task axi4_virtual_qos_wr_tagged_seq::body();
  if(wr_qos.size() != wr_awid.size())
    `uvm_fatal(get_type_name(), $sformatf("wr_qos has %0d entries but wr_awid has %0d", wr_qos.size(), wr_awid.size()))

  fork
    forever begin
      axi4_slave_nbk_write_seq slave_wr_seq;
      slave_wr_seq = axi4_slave_nbk_write_seq::type_id::create("slave_wr_seq");
      slave_wr_seq.start(p_sequencer.axi4_slave_write_seqr_h);
    end
    forever begin
      axi4_slave_nbk_read_seq slave_rd_seq;
      slave_rd_seq = axi4_slave_nbk_read_seq::type_id::create("slave_rd_seq");
      slave_rd_seq.start(p_sequencer.axi4_slave_read_seqr_h);
    end
  join_none

  foreach(wr_qos[i]) begin
    axi4_master_qos_tagged_write_seq wr_seq;
    wr_seq            = axi4_master_qos_tagged_write_seq::type_id::create($sformatf("qos_tagged_wr_%0d", i));
    wr_seq.qos_value  = wr_qos[i];
    wr_seq.awid_value = wr_awid[i];
    wr_seq.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
  end
endtask : body

`endif
