`ifndef AXI4_VIRTUAL_USER_SIGNAL_WIDTH_MISMATCH_SEQ_INCLUDED_
`define AXI4_VIRTUAL_USER_SIGNAL_WIDTH_MISMATCH_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_user_signal_width_mismatch_seq
// Virtual sequence to test USER signal behavior with different effective widths
// Verifies system handles various USER signal width patterns correctly
//--------------------------------------------------------------------------------------------
class axi4_virtual_user_signal_width_mismatch_seq extends axi4_virtual_base_seq;
  
  `uvm_object_utils(axi4_virtual_user_signal_width_mismatch_seq)
  
  // Sequence handles
  axi4_master_user_signal_width_mismatch_seq master_width_seq[];
  
  // Test parameters
  int num_transactions_per_master = 16;
  int target_slave = 2; // Target slave for width testing
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_user_signal_width_mismatch_seq");
  extern virtual task body();
  
endclass : axi4_virtual_user_signal_width_mismatch_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_virtual_user_signal_width_mismatch_seq::new(string name = "axi4_virtual_user_signal_width_mismatch_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Coordinates USER signal width testing across masters
//-----------------------------------------------------------------------------
task axi4_virtual_user_signal_width_mismatch_seq::body();
  int active_masters;
  
  super.body();
  
  // Use fewer masters for width testing to avoid pattern interference
  active_masters = (env_cfg_h.no_of_masters > 2) ? 2 : env_cfg_h.no_of_masters;
  
  `uvm_info(get_type_name(), $sformatf("Starting USER signal width mismatch test with %0d masters", active_masters), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Each master will test %0d different width patterns targeting slave S%0d", 
                                        num_transactions_per_master, target_slave), UVM_MEDIUM)
  `uvm_info(get_type_name(), "Testing effective widths: 8-bit, 16-bit, 24-bit, 32-bit and boundary conditions", UVM_MEDIUM)
  
  // Create sequence array
  master_width_seq = new[active_masters];
  
  // Start USER width testing sequences on selected masters sequentially
  // Sequential execution helps isolate width-specific behaviors
  for (int i = 0; i < active_masters; i++) begin
    `uvm_info(get_type_name(), $sformatf("Starting USER width test sequence on Master %0d", i), UVM_HIGH)
    
    // Create and configure the sequence
    master_width_seq[i] = axi4_master_user_signal_width_mismatch_seq::type_id::create(
                          $sformatf("master_width_seq_%0d", i));
    
    // Set configuration via config_db
    uvm_config_db#(int)::set(null, {get_full_name(), ".", master_width_seq[i].get_name()}, 
                            "master_id", i);
    uvm_config_db#(int)::set(null, {get_full_name(), ".", master_width_seq[i].get_name()}, 
                            "slave_id", target_slave);
    uvm_config_db#(int)::set(null, {get_full_name(), ".", master_width_seq[i].get_name()}, 
                            "num_transactions", num_transactions_per_master);
    
    // Alternate between write and read sequencers for different masters
    if (i & 1) begin
      master_width_seq[i].start(p_sequencer.axi4_master_write_seqr_h_all[i]);
    end
    else begin
      master_width_seq[i].start(p_sequencer.axi4_master_read_seqr_h_all[i]);
    end
    
    // Small delay between masters to separate their patterns
    #500;
  end
  
  // Additional time for all transactions to complete
  #1000;
  
  `uvm_info(get_type_name(), "USER signal width mismatch test completed", UVM_MEDIUM)
  `uvm_info(get_type_name(), "Expected behavior: System should handle all USER signal width patterns correctly", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Different effective bit widths should be supported", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Boundary conditions (min/max values) should work", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Sparse and dense bit patterns should be handled", UVM_MEDIUM)
  
endtask : body

`endif