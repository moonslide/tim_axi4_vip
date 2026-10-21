`ifndef AXI4_VIRTUAL_QOS_RD_TAGGED_SEQ_INCLUDED_
`define AXI4_VIRTUAL_QOS_RD_TAGGED_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_qos_rd_tagged_seq
//  Issues n_writes single-beat writes from master 0 (so the scoreboard's
//  write-side checks have something to compare), then a caller-defined list
//  of single-beat reads from master 0, in list
//  order and back to back, each with its own ARQOS and ARID
//  (axi4_master_qos_tagged_read_seq),
//  and keeps the subordinate sequences running underneath. Returns once the
//  last AR has been handed to the driver; the caller decides how long to wait
//  for the R bursts (they are non-blocking).
//
//  Used by the subordinate read-QoS arbitration tests:
//    axi4_qos_rd_hold_single_read_test, axi4_qos_rd_priority_order_test,
//    axi4_qos_rd_bypass_bound_test.
//--------------------------------------------------------------------------------------------
class axi4_virtual_qos_rd_tagged_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_qos_rd_tagged_seq)

  // Variables: rd_qos / rd_arid
  // One entry per read, issued in this order. Same length.
  bit [3:0] rd_qos[$];
  int       rd_arid[$];

  // Variable: n_writes
  // Writes issued before the reads (non-blocking: each returns once its AW is out).
  int       n_writes = 1;

  extern function new(string name = "axi4_virtual_qos_rd_tagged_seq");
  extern task body();
endclass : axi4_virtual_qos_rd_tagged_seq

function axi4_virtual_qos_rd_tagged_seq::new(string name = "axi4_virtual_qos_rd_tagged_seq");
  super.new(name);
endfunction : new

task axi4_virtual_qos_rd_tagged_seq::body();
  if(rd_qos.size() != rd_arid.size())
    `uvm_fatal(get_type_name(), $sformatf("rd_qos has %0d entries but rd_arid has %0d", rd_qos.size(), rd_arid.size()))

  // Subordinate sequences, kept alive for the whole test (same pattern as the
  // other QoS virtual sequences).
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

  repeat(n_writes) begin
    axi4_master_qos_priority_write_seq wr_seq;
    wr_seq           = axi4_master_qos_priority_write_seq::type_id::create("qos_ctrl_wr");
    wr_seq.master_id = 0;
    wr_seq.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
  end

  foreach(rd_qos[i]) begin
    axi4_master_qos_tagged_read_seq rd_seq;
    rd_seq            = axi4_master_qos_tagged_read_seq::type_id::create($sformatf("qos_tagged_rd_%0d", i));
    rd_seq.qos_value  = rd_qos[i];
    rd_seq.arid_value = rd_arid[i];
    rd_seq.start(p_sequencer.axi4_master_read_seqr_h_all[0]);
  end
endtask : body

`endif
