`ifndef AXI4_VIRTUAL_PARALLEL_WRITE_SEQ_INCLUDED_
`define AXI4_VIRTUAL_PARALLEL_WRITE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_parallel_write_seq
// Virtual sequence that properly runs master and slave sequences in parallel
//--------------------------------------------------------------------------------------------
class axi4_virtual_parallel_write_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_parallel_write_seq)

  // Master sequences
  axi4_master_bk_write_seq axi4_master_bk_write_seq_h;

  // Slave sequences  
  axi4_slave_bk_write_seq axi4_slave_bk_write_seq_h;

  // Control variables
  int num_transactions = 1;
  bit enable_slave_seq = 1;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_parallel_write_seq");
  extern task body();
endclass : axi4_virtual_parallel_write_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_virtual_parallel_write_seq::new(string name = "axi4_virtual_parallel_write_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task - body
// Runs master and slave sequences properly in parallel
//--------------------------------------------------------------------------------------------
task axi4_virtual_parallel_write_seq::body();
  `uvm_info(get_type_name(), $sformatf("Starting parallel write sequence with %0d transactions", num_transactions), UVM_MEDIUM)
  
  // Create sequences
  axi4_master_bk_write_seq_h = axi4_master_bk_write_seq::type_id::create("axi4_master_bk_write_seq_h");
  
  // Check if slave sequencer exists and we should use it
  if (p_sequencer.axi4_slave_write_seqr_h != null && enable_slave_seq) begin
    `uvm_info(get_type_name(), "Running with active slave - parallel mode", UVM_HIGH)
    axi4_slave_bk_write_seq_h = axi4_slave_bk_write_seq::type_id::create("axi4_slave_bk_write_seq_h");
    
    // Start slave sequences in background to be ready for responses
    fork
      begin
        // Slave thread - runs multiple sequences to handle responses
        for(int i = 0; i < num_transactions * 2; i++) begin
          axi4_slave_bk_write_seq slave_seq = axi4_slave_bk_write_seq::type_id::create($sformatf("slave_seq_%0d", i));
          slave_seq.start(p_sequencer.axi4_slave_write_seqr_h);
        end
      end
    join_none
    
    // Give slaves time to be ready
    #10ns;
    
    // Now run master sequences
    for(int i = 0; i < num_transactions; i++) begin
      axi4_master_bk_write_seq master_seq = axi4_master_bk_write_seq::type_id::create($sformatf("master_seq_%0d", i));
      master_seq.start(p_sequencer.axi4_master_write_seqr_h);
      #10ns; // Small delay between transactions
    end
    
    // Wait a bit for any pending slave responses
    #100ns;
    
  end else begin
    // Slaves are passive - only run master sequences
    `uvm_info(get_type_name(), "Running with passive slaves - master only mode", UVM_HIGH)
    
    for(int i = 0; i < num_transactions; i++) begin
      axi4_master_bk_write_seq master_seq = axi4_master_bk_write_seq::type_id::create($sformatf("master_seq_%0d", i));
      master_seq.start(p_sequencer.axi4_master_write_seqr_h);
      #10ns;
    end
  end
  
  `uvm_info(get_type_name(), "Parallel write sequence completed", UVM_MEDIUM)
endtask : body

`endif