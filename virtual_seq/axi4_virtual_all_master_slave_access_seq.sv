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
  axi4_slave_bk_write_seq axi4_slave_bk_write_seq_h;
  axi4_slave_bk_read_seq axi4_slave_bk_read_seq_h;
  axi4_master_bk_write_seq axi4_master_bk_write_seq_h;
  axi4_master_bk_read_seq axi4_master_bk_read_seq_h;
  
  // Create sequence handles
  axi4_slave_bk_write_seq_h = axi4_slave_bk_write_seq::type_id::create("axi4_slave_bk_write_seq_h");
  axi4_slave_bk_read_seq_h = axi4_slave_bk_read_seq::type_id::create("axi4_slave_bk_read_seq_h");
  axi4_master_bk_write_seq_h = axi4_master_bk_write_seq::type_id::create("axi4_master_bk_write_seq_h");
  axi4_master_bk_read_seq_h = axi4_master_bk_read_seq::type_id::create("axi4_master_bk_read_seq_h");
  
  // Start slave responders (exactly like working test)
  fork
    begin : T1_SL_WR
      forever begin
        axi4_slave_bk_write_seq_h.start(p_sequencer.axi4_slave_write_seqr_h);
      end
    end
    begin : T2_SL_RD
      forever begin
        axi4_slave_bk_read_seq_h.start(p_sequencer.axi4_slave_read_seqr_h);
      end
    end
  join_none
  
  // Run master sequences (adapted from working test pattern)
  fork
    begin: T1_WRITE
      repeat(4) begin // Increase repetitions to cover all masters 
        axi4_master_bk_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
      end
    end
    begin: T2_READ
      repeat(6) begin // Increase repetitions to cover all masters
        axi4_master_bk_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
      end
    end
  join
endtask

`endif
