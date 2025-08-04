`ifndef AXI4_VIRTUAL_USER_SIGNAL_PASSTHROUGH_SEQ_INCLUDED_
`define AXI4_VIRTUAL_USER_SIGNAL_PASSTHROUGH_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_user_signal_passthrough_seq
// Virtual sequence to test USER signal passthrough across multiple masters
// Verifies that USER signals propagate correctly from master to slave on all channels
//--------------------------------------------------------------------------------------------
class axi4_virtual_user_signal_passthrough_seq extends axi4_virtual_base_seq;
  
  `uvm_object_utils(axi4_virtual_user_signal_passthrough_seq)
  
  // Sequence handles
  axi4_master_user_signal_passthrough_seq master_user_seq[];
  
  // Test parameters
  int num_transactions_per_master = 20;
  int target_slave = 2; // Target slave for USER signal passthrough testing
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_user_signal_passthrough_seq");
  extern virtual task body();
  
endclass : axi4_virtual_user_signal_passthrough_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_virtual_user_signal_passthrough_seq::new(string name = "axi4_virtual_user_signal_passthrough_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Coordinates USER signal passthrough testing across multiple masters
//-----------------------------------------------------------------------------
task axi4_virtual_user_signal_passthrough_seq::body();
  int active_masters;
  
  super.body();
  
  // Determine number of active masters
  active_masters = (env_cfg_h.no_of_masters > 4) ? 4 : env_cfg_h.no_of_masters;
  
  `uvm_info(get_type_name(), $sformatf("Starting USER signal passthrough test with %0d masters", active_masters), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Each master will generate %0d transactions targeting slave S%0d", 
                                        num_transactions_per_master, target_slave), UVM_MEDIUM)
  `uvm_info(get_type_name(), "Testing AWUSER, ARUSER, WUSER passthrough and BUSER, RUSER response correlation", UVM_MEDIUM)
  
  // Create sequence array
  master_user_seq = new[active_masters];
  
  // Start USER passthrough sequences on all masters in parallel
  fork
    begin : all_master_user_sequences
      for (int i = 0; i < active_masters; i++) begin
        automatic int master_id = i;
        fork
          begin
            `uvm_info(get_type_name(), $sformatf("Starting USER passthrough sequence on Master %0d", master_id), UVM_HIGH)
            
            // Create and configure the sequence
            master_user_seq[master_id] = axi4_master_user_signal_passthrough_seq::type_id::create(
                                         $sformatf("master_user_seq_%0d", master_id));
            
            // Set configuration via config_db
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_user_seq[master_id].get_name()}, 
                                    "master_id", master_id);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_user_seq[master_id].get_name()}, 
                                    "slave_id", target_slave);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_user_seq[master_id].get_name()}, 
                                    "num_transactions", num_transactions_per_master);
            
            // Start on both write and read sequencers (alternate)
            if (master_id & 1) begin
              master_user_seq[master_id].start(p_sequencer.axi4_master_write_seqr_h_all[master_id]);
            end
            else begin
              master_user_seq[master_id].start(p_sequencer.axi4_master_read_seqr_h_all[master_id]);
            end
          end
        join_none
      end
      
      // Wait for all USER passthrough sequences to complete
      wait fork;
    end
  join
  
  // Allow additional time for all responses to be received and checked
  #2000;
  
  `uvm_info(get_type_name(), "USER signal passthrough test completed", UVM_MEDIUM)
  `uvm_info(get_type_name(), "Expected behavior: All USER signals should passthrough correctly", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- AWUSER → slave and BUSER ← slave correlation", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- ARUSER → slave and RUSER ← slave correlation", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- WUSER → slave passthrough integrity", UVM_MEDIUM)
  
endtask : body

`endif