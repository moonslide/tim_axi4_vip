`ifndef AXI4_VIRTUAL_WRITE_READ_SEQ_INCLUDED_
`define AXI4_VIRTUAL_WRITE_READ_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_write_read_seq
// Creates and starts the master and slave sequences
//--------------------------------------------------------------------------------------------
class axi4_virtual_write_read_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_write_read_seq)

  //Variable: axi4_master seq
  //Instantiation of axi4_master seq handles
  axi4_master_bk_write_seq axi4_master_bk_write_seq_h;
  axi4_master_nbk_write_seq axi4_master_nbk_write_seq_h;
  axi4_master_bk_read_seq axi4_master_bk_read_seq_h;
  axi4_master_nbk_read_seq axi4_master_nbk_read_seq_h;

  //Variable: axi4_slave seq's
  //Instantiation of axi4_slave seq handles
  axi4_slave_bk_write_seq axi4_slave_bk_write_seq_h;
  axi4_slave_nbk_write_seq axi4_slave_nbk_write_seq_h;
  axi4_slave_bk_read_seq axi4_slave_bk_read_seq_h;
  axi4_slave_nbk_read_seq axi4_slave_nbk_read_seq_h;

  // Processes used earlier to synchronize slave sequences with the
  // master sequences were leaving background threads running forever
  // causing tests to hang.  These handles are no longer required
  // after replacing the infinite loops with bounded repeats.

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_write_read_seq");
  extern task body();
endclass : axi4_virtual_write_read_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initialises new memory for the object
//
// Parameters:
//  name - axi4_virtual_write_read_seq
//--------------------------------------------------------------------------------------------
function axi4_virtual_write_read_seq::new(string name = "axi4_virtual_write_read_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task - body
// Creates and starts the data of master and slave sequences
//--------------------------------------------------------------------------------------------
task axi4_virtual_write_read_seq::body();
  axi4_master_bk_write_seq_h  = axi4_master_bk_write_seq::type_id::create("axi4_master_bk_write_seq_h");
  axi4_master_nbk_write_seq_h = axi4_master_nbk_write_seq::type_id::create("axi4_master_nbk_write_seq_h");
  axi4_master_bk_read_seq_h   = axi4_master_bk_read_seq::type_id::create("axi4_master_bk_read_seq_h");
  axi4_master_nbk_read_seq_h  = axi4_master_nbk_read_seq::type_id::create("axi4_master_nbk_read_seq_h");

  axi4_slave_bk_write_seq_h  = axi4_slave_bk_write_seq::type_id::create("axi4_slave_bk_write_seq_h");
  axi4_slave_nbk_write_seq_h = axi4_slave_nbk_write_seq::type_id::create("axi4_slave_nbk_write_seq_h");
  axi4_slave_bk_read_seq_h   = axi4_slave_bk_read_seq::type_id::create("axi4_slave_bk_read_seq_h");
  axi4_slave_nbk_read_seq_h  = axi4_slave_nbk_read_seq::type_id::create("axi4_slave_nbk_read_seq_h");

  `uvm_info(get_type_name(), $sformatf("DEBUG_MSHA :: Insdie axi4_virtual_write_read_seq"), UVM_NONE); 

  // Run a limited number of slave and master sequences.  Events are used
  // to serialize the blocking and non-blocking portions so that only one
  // sequence is active on a given sequencer at a time.  This mirrors the
  // original behaviour but terminates cleanly after a finite number of
  // iterations.

  event bk_sl_wr_done, bk_sl_rd_done, bk_mst_wr_done, bk_mst_rd_done;

  fork
    // Slave blocking write followed by non-blocking write
    begin : T1_BK_SL_WR
      for (int i = 0; i < 5; i++) begin
        `uvm_info(get_type_name(), $sformatf("BK_SL_WR iteration %0d", i), UVM_LOW)
        axi4_slave_bk_write_seq_h.start(p_sequencer.axi4_slave_write_seqr_h);
        -> bk_sl_wr_done;
      end
    end
    begin : T1_NBK_SL_WR
      for (int i = 0; i < 5; i++) begin
        @(bk_sl_wr_done);
        `uvm_info(get_type_name(), $sformatf("NBK_SL_WR iteration %0d", i), UVM_LOW)
        axi4_slave_nbk_write_seq_h.start(p_sequencer.axi4_slave_write_seqr_h);
      end
    end

    // Slave blocking read followed by non-blocking read
    begin : T2_BK_SL_RD
      for (int i = 0; i < 3; i++) begin
        `uvm_info(get_type_name(), $sformatf("BK_SL_RD iteration %0d", i), UVM_LOW)
        axi4_slave_bk_read_seq_h.start(p_sequencer.axi4_slave_read_seqr_h);
        -> bk_sl_rd_done;
      end
    end
    begin : T2_NBK_SL_RD
      for (int i = 0; i < 3; i++) begin
        @(bk_sl_rd_done);
        `uvm_info(get_type_name(), $sformatf("NBK_SL_RD iteration %0d", i), UVM_LOW)
        axi4_slave_nbk_read_seq_h.start(p_sequencer.axi4_slave_read_seqr_h);
      end
    end

    // Master blocking write followed by non-blocking write
    begin: T1_BK_WRITE
      for (int i = 0; i < 5; i++) begin
        `uvm_info(get_type_name(), $sformatf("BK_WRITE iteration %0d", i), UVM_LOW)
        axi4_master_bk_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
        -> bk_mst_wr_done;
      end
    end
    begin: T1_NBK_WRITE
      for (int i = 0; i < 5; i++) begin
        @(bk_mst_wr_done);
        `uvm_info(get_type_name(), $sformatf("NBK_WRITE iteration %0d", i), UVM_LOW)
        axi4_master_nbk_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
      end
    end

    // Master blocking read followed by non-blocking read
    begin: T2_BK_READ
      for (int i = 0; i < 3; i++) begin
        `uvm_info(get_type_name(), $sformatf("BK_READ iteration %0d", i), UVM_LOW)
        axi4_master_bk_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
        -> bk_mst_rd_done;
      end
    end
    begin: T2_NBK_READ
      for (int i = 0; i < 3; i++) begin
        @(bk_mst_rd_done);
        `uvm_info(get_type_name(), $sformatf("NBK_READ iteration %0d", i), UVM_LOW)
        axi4_master_nbk_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
      end
    end
  join
  `uvm_info(get_type_name(), "Completed all master/slave sequences", UVM_LOW)
endtask : body

`endif

