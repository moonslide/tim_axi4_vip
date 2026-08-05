`ifndef AXI4_VIRTUAL_QOS_BID_QUEUE_RACE_SEQ_INCLUDED_
`define AXI4_VIRTUAL_QOS_BID_QUEUE_RACE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_qos_bid_queue_race_seq
//
// AXI_ooo.md F1 (Phase 1) repro.
//
// Three master-slave pairs write CONCURRENTLY in WRITE_READ_QOS_MODE_ENABLE, with
// master 0 issuing a long burst and masters 1 and 2 issuing single beats. All three
// masters push their AWID into the package-scope `awid_queue_for_qos` at roughly the
// same time (push order 0,1,2), but the short-burst pairs finish their write data
// phase first, so slaves 1 and 2 reach the BID assignment
// (slave/axi4_slave_driver_proxy.sv:422) BEFORE slave 0 does and pop the queue FRONT
// -- which is master 0's AWID.
//
// Expected pre-fix symptom: masters 1/2 are answered with a BID they never issued
// (and, once the queue runs dry, BID=0), caught by the scoreboard's
// "bid returned to the WRONG manager" check.
//--------------------------------------------------------------------------------------------
class axi4_virtual_qos_bid_queue_race_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_qos_bid_queue_race_seq)

  // Number of write rounds each master issues.
  int num_rounds = 5;

  // AWLEN for the "slow" master 0 vs. the "fast" masters 1/2.
  bit [7:0] slow_burst_len = 8'h0F;
  bit [7:0] fast_burst_len = 8'h00;

  extern function new(string name = "axi4_virtual_qos_bid_queue_race_seq");
  extern task body();

endclass : axi4_virtual_qos_bid_queue_race_seq

function axi4_virtual_qos_bid_queue_race_seq::new(string name = "axi4_virtual_qos_bid_queue_race_seq");
  super.new(name);
endfunction : new

task axi4_virtual_qos_bid_queue_race_seq::body();

  `uvm_info(get_type_name(), "Starting QoS shared-BID-queue race virtual sequence", UVM_LOW)

  // Single-variable control knob. +QOS_BID_RACE_NO_SKEW gives EVERY master the
  // long burst, so the burst length itself, the addresses, the QoS mode and the
  // transaction count are all unchanged and only the completion-order SKEW is
  // removed. A clean run under this knob on the same build is what makes the
  // skewed run's failure attributable to the shared queue rather than to
  // anything else this stimulus does.
  if($test$plusargs("QOS_BID_RACE_NO_SKEW")) begin
    fast_burst_len = slow_burst_len;
    `uvm_info(get_type_name(), "QOS_BID_RACE_NO_SKEW: all masters use the same burst length (control run)", UVM_LOW)
  end

  // Reactive slave sequences (SLAVE_MEM_MODE), same shape as the QoS tests.
  fork
    begin : SLAVE_WRITE
      forever begin
        axi4_slave_nbk_write_seq slave_wr_seq;
        slave_wr_seq = axi4_slave_nbk_write_seq::type_id::create("slave_wr_seq");
        slave_wr_seq.start(p_sequencer.axi4_slave_write_seqr_h);
      end
    end
    begin : SLAVE_READ
      forever begin
        axi4_slave_nbk_read_seq slave_rd_seq;
        slave_rd_seq = axi4_slave_nbk_read_seq::type_id::create("slave_rd_seq");
        slave_rd_seq.start(p_sequencer.axi4_slave_read_seqr_h);
      end
    end
  join_none

  fork
    begin : MASTER0_SLOW_WRITES
      if (p_sequencer.axi4_master_write_seqr_h_all.size() > 0) begin
        for(int r = 0; r < num_rounds; r++) begin
          axi4_master_qos_bid_race_write_seq wr_seq;
          wr_seq = axi4_master_qos_bid_race_write_seq::type_id::create("m0_wr_seq");
          wr_seq.master_id       = 0;
          wr_seq.target_slave_id = 0;
          wr_seq.burst_len       = slow_burst_len;
          wr_seq.txn_index       = r;
          wr_seq.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
        end
      end
    end

    begin : MASTER1_FAST_WRITES
      if (p_sequencer.axi4_master_write_seqr_h_all.size() > 1) begin
        for(int r = 0; r < num_rounds; r++) begin
          axi4_master_qos_bid_race_write_seq wr_seq;
          wr_seq = axi4_master_qos_bid_race_write_seq::type_id::create("m1_wr_seq");
          wr_seq.master_id       = 1;
          wr_seq.target_slave_id = 1;
          wr_seq.burst_len       = fast_burst_len;
          wr_seq.txn_index       = r;
          wr_seq.start(p_sequencer.axi4_master_write_seqr_h_all[1]);
        end
      end
    end

    begin : MASTER2_FAST_WRITES
      if (p_sequencer.axi4_master_write_seqr_h_all.size() > 2) begin
        for(int r = 0; r < num_rounds; r++) begin
          axi4_master_qos_bid_race_write_seq wr_seq;
          wr_seq = axi4_master_qos_bid_race_write_seq::type_id::create("m2_wr_seq");
          wr_seq.master_id       = 2;
          wr_seq.target_slave_id = 2;
          wr_seq.burst_len       = fast_burst_len;
          wr_seq.txn_index       = r;
          wr_seq.start(p_sequencer.axi4_master_write_seqr_h_all[2]);
        end
      end
    end
  join

  #200ns;

  `uvm_info(get_type_name(), "Completed QoS shared-BID-queue race virtual sequence", UVM_LOW)

endtask : body

`endif
