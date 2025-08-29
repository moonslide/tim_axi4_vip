`ifndef AXI4_VIRTUAL_WRITE_SEQ_INCLUDED_
`define AXI4_VIRTUAL_WRITE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_write_seq
// Creates and starts the master and slave sequences
//--------------------------------------------------------------------------------------------
class axi4_virtual_write_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_write_seq)

  //Variable: axi4_master_write_seq_h
  //Instantiation of axi4_master_write_seq handle
  axi4_master_bk_write_seq axi4_master_bk_write_seq_h;
  axi4_master_nbk_write_seq axi4_master_nbk_write_seq_h;

  //Variable: axi4_slave_write_seq_h
  //Instantiation of axi4_slave_write_seq handle
  axi4_slave_bk_write_seq axi4_slave_bk_write_seq_h;
  axi4_slave_nbk_write_seq axi4_slave_nbk_write_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_write_seq");
  extern task body();
endclass : axi4_virtual_write_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initialises new memory for the object
//
// Parameters:
//  name - axi4_virtual_write_seq
//--------------------------------------------------------------------------------------------
function axi4_virtual_write_seq::new(string name = "axi4_virtual_write_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task - body
// Creates and starts the data of master and slave sequences
//--------------------------------------------------------------------------------------------
task axi4_virtual_write_seq::body();
  axi4_master_bk_write_seq_h = axi4_master_bk_write_seq::type_id::create("axi4_master_bk_write_seq_h");
  axi4_master_nbk_write_seq_h = axi4_master_nbk_write_seq::type_id::create("axi4_master_nbk_write_seq_h");

  `uvm_info(get_type_name(), $sformatf("DEBUG_MSHA :: Inside axi4_virtual_write_seq"), UVM_NONE); 
  
  // Check if slave sequencer exists (only in ACTIVE mode)
  if (p_sequencer.axi4_slave_write_seqr_h != null) begin
    axi4_slave_bk_write_seq_h = axi4_slave_bk_write_seq::type_id::create("axi4_slave_bk_write_seq_h");
    axi4_slave_nbk_write_seq_h = axi4_slave_nbk_write_seq::type_id::create("axi4_slave_nbk_write_seq_h");
    
    // Run master and slave sequences in parallel to avoid deadlock
    // Slave sequences should be ready to respond when master sends transactions
    fork 
      begin: T1_MASTER_WRITE
        repeat(5) begin
          axi4_master_bk_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
          axi4_master_nbk_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
        end
      end
      begin: T2_SLAVE_WRITE
        // Run more slave sequences to ensure they're available for all master transactions
        repeat(10) begin
          fork
            axi4_slave_bk_write_seq_h.start(p_sequencer.axi4_slave_write_seqr_h);
            axi4_slave_nbk_write_seq_h.start(p_sequencer.axi4_slave_write_seqr_h);
          join_any
        end
      end
    join
  end else begin
    // Slaves are passive - only run master sequences
    `uvm_info(get_type_name(), "Slave sequencer not found (PASSIVE mode) - running only master sequences", UVM_MEDIUM)
    repeat(5) begin
      axi4_master_bk_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
      axi4_master_nbk_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
    end
  end
 endtask : body

`endif

