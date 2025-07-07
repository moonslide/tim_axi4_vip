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
  axi4_slave_bk_read_seq axi4_slave_bk_read_seq_h;
  axi4_master_upper_boundary_read_seq axi4_master_upper_boundary_read_seq_h;
  
  // Create sequence handles
  axi4_slave_bk_read_seq_h = axi4_slave_bk_read_seq::type_id::create("axi4_slave_bk_read_seq_h");
  axi4_master_upper_boundary_read_seq_h = axi4_master_upper_boundary_read_seq::type_id::create("axi4_master_upper_boundary_read_seq_h");
  
  // Start slave responder and master sequence in parallel
  fork
    begin : T1_SL_RD
      forever begin
        axi4_slave_bk_read_seq_h.start(p_sequencer.axi4_slave_read_seqr_h);
      end
    end
    begin : T2_MASTER
      // Run master sequence
      axi4_master_upper_boundary_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
    end
  join_any
  
  // Disable the slave responder thread after master completes
  disable fork;
endtask

`endif
