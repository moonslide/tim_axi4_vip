`ifndef AXI4_VIRTUAL_USER_SIGNAL_CORRUPTION_SEQ_INCLUDED_
`define AXI4_VIRTUAL_USER_SIGNAL_CORRUPTION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_user_signal_corruption_seq
// Virtual sequence to test USER signal corruption across multiple masters
// Verifies that signal corruption is detected and recovery mechanisms work
//--------------------------------------------------------------------------------------------
class axi4_virtual_user_signal_corruption_seq extends axi4_virtual_base_seq;
  
  `uvm_object_utils(axi4_virtual_user_signal_corruption_seq)
  
  // Sequence handles
  axi4_master_user_signal_corruption_seq master_corruption_seq[];
  
  // Test parameters
  int num_transactions_per_master = 10;
  int target_slave = 2; // Target slave for corruption testing
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_user_signal_corruption_seq");
  extern virtual task body();
  
endclass : axi4_virtual_user_signal_corruption_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_virtual_user_signal_corruption_seq::new(string name = "axi4_virtual_user_signal_corruption_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Coordinates USER signal corruption testing across multiple masters
//-----------------------------------------------------------------------------
task axi4_virtual_user_signal_corruption_seq::body();
  int active_masters;
  
  super.body();
  
  // Use all available masters for corruption testing (different corruption sources)
  active_masters = (env_cfg_h.no_of_masters > 4) ? 4 : env_cfg_h.no_of_masters;
  
  `uvm_info(get_type_name(), $sformatf("Starting USER signal corruption test with %0d masters", active_masters), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Each master will test %0d corruption scenarios targeting slave S%0d", 
                                        num_transactions_per_master, target_slave), UVM_MEDIUM)
  `uvm_info(get_type_name(), "Testing corruption types: Bit flips, Burst errors, Stuck bits, Intermittent faults", UVM_MEDIUM)
  `uvm_info(get_type_name(), "WARNING: This test intentionally corrupts USER signals", UVM_LOW)
  
  // Create sequence array
  master_corruption_seq = new[active_masters];
  
  // Start corruption sequences on all masters with staggered timing
  // Each master represents a different corruption source/environment
  fork
    begin : all_master_corruption_sequences
      for (int i = 0; i < active_masters; i++) begin
        automatic int master_id = i;
        fork
          begin
            // Stagger starts to simulate different corruption onset times
            #(master_id * 150);
            
            `uvm_info(get_type_name(), $sformatf("Starting USER corruption sequence on Master %0d", master_id), UVM_HIGH)
            
            // Create and configure the sequence
            master_corruption_seq[master_id] = axi4_master_user_signal_corruption_seq::type_id::create(
                                               $sformatf("master_corruption_seq_%0d", master_id));
            
            // Set configuration via config_db
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_corruption_seq[master_id].get_name()}, 
                                    "master_id", master_id);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_corruption_seq[master_id].get_name()}, 
                                    "slave_id", target_slave);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_corruption_seq[master_id].get_name()}, 
                                    "num_transactions", num_transactions_per_master);
            
            // Use write sequencers for corruption testing (write data is most critical)
            master_corruption_seq[master_id].start(p_sequencer.axi4_master_write_seqr_h_all[master_id]);
          end
        join_none
      end
      
      // Wait for all corruption sequences to complete
      wait fork;
    end
  join
  
  // Allow additional time for all corruption effects to be observed and recovery to occur
  #5000;
  
  `uvm_info(get_type_name(), "USER signal corruption test completed", UVM_MEDIUM)
  `uvm_info(get_type_name(), "Expected behavior: System should detect and recover from USER signal corruption", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Single bit errors should be correctable", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Multiple bit errors should be detectable", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Burst errors should trigger error handling", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Stuck bit faults should be identified", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Intermittent errors should be tracked", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Severe corruption should activate protection mechanisms", UVM_MEDIUM)
  
endtask : body

`endif