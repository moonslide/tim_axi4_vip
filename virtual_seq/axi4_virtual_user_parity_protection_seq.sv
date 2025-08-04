`ifndef AXI4_VIRTUAL_USER_PARITY_PROTECTION_SEQ_INCLUDED_
`define AXI4_VIRTUAL_USER_PARITY_PROTECTION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_user_parity_protection_seq
// Virtual sequence to test USER signal parity protection across multiple masters
// Verifies that parity protection schemes work correctly in multi-master environment
//--------------------------------------------------------------------------------------------
class axi4_virtual_user_parity_protection_seq extends axi4_virtual_base_seq;
  
  `uvm_object_utils(axi4_virtual_user_parity_protection_seq)
  
  // Sequence handles
  axi4_master_user_parity_protection_seq master_parity_seq[];
  
  // Test parameters
  int num_transactions_per_master = 12;
  int target_slave = 2; // Target slave for parity protection testing
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_user_parity_protection_seq");
  extern virtual task body();
  
endclass : axi4_virtual_user_parity_protection_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_virtual_user_parity_protection_seq::new(string name = "axi4_virtual_user_parity_protection_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Coordinates USER signal parity protection testing across multiple masters
//-----------------------------------------------------------------------------
task axi4_virtual_user_parity_protection_seq::body();
  int active_masters;
  
  super.body();
  
  // Use limited masters for parity protection testing
  active_masters = (env_cfg_h.no_of_masters > 3) ? 3 : env_cfg_h.no_of_masters;
  
  `uvm_info(get_type_name(), $sformatf("Starting USER signal parity protection test with %0d masters", active_masters), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Each master will test %0d parity schemes targeting slave S%0d", 
                                        num_transactions_per_master, target_slave), UVM_MEDIUM)
  `uvm_info(get_type_name(), "Testing parity schemes: Even, Odd, Dual, and No parity", UVM_MEDIUM)
  
  // Create sequence array
  master_parity_seq = new[active_masters];
  
  // Start parity protection sequences on selected masters in parallel
  fork
    begin : all_master_parity_sequences
      for (int i = 0; i < active_masters; i++) begin
        automatic int master_id = i;
        fork
          begin
            `uvm_info(get_type_name(), $sformatf("Starting USER parity protection sequence on Master %0d", master_id), UVM_HIGH)
            
            // Create and configure the sequence
            master_parity_seq[master_id] = axi4_master_user_parity_protection_seq::type_id::create(
                                          $sformatf("master_parity_seq_%0d", master_id));
            
            // Set configuration via config_db
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_parity_seq[master_id].get_name()}, 
                                    "master_id", master_id);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_parity_seq[master_id].get_name()}, 
                                    "slave_id", target_slave);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_parity_seq[master_id].get_name()}, 
                                    "num_transactions", num_transactions_per_master);
            
            // Start on write sequencers (parity protection is typically for write data)
            master_parity_seq[master_id].start(p_sequencer.axi4_master_write_seqr_h_all[master_id]);
          end
        join_none
      end
      
      // Wait for all parity protection sequences to complete
      wait fork;
    end
  join
  
  // Allow additional time for all transactions to complete and parity to be verified
  #2500;
  
  `uvm_info(get_type_name(), "USER signal parity protection test completed", UVM_MEDIUM)
  `uvm_info(get_type_name(), "Expected behavior: All parity protection schemes should work correctly", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Even parity calculations should be correct", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Odd parity calculations should be correct", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Dual parity (even+odd) should provide enhanced protection", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Parity scheme identifiers should be preserved", UVM_MEDIUM)
  
endtask : body

`endif