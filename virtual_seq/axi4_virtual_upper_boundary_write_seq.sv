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
  axi4_slave_bk_write_seq axi4_slave_bk_write_seq_h;
  axi4_master_upper_boundary_write_seq axi4_master_upper_boundary_write_seq_h;
  
  // Create sequence handles
  axi4_slave_bk_write_seq_h = axi4_slave_bk_write_seq::type_id::create("axi4_slave_bk_write_seq_h");
  axi4_master_upper_boundary_write_seq_h = axi4_master_upper_boundary_write_seq::type_id::create("axi4_master_upper_boundary_write_seq_h");
  
  // Start slave responder (exactly like working test)
  fork
    begin : T1_SL_WR
      forever begin
        axi4_slave_bk_write_seq_h.start(p_sequencer.axi4_slave_write_seqr_h);
      end
    end
  join_none
  
  // Run master sequence
  axi4_master_upper_boundary_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
endtask

`endif
