`ifndef AXI4_VIRTUAL_USER_SECURITY_TAGGING_SEQ_INCLUDED_
`define AXI4_VIRTUAL_USER_SECURITY_TAGGING_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_user_security_tagging_seq
// Virtual sequence to test USER signal security tagging across multiple masters
// Verifies that security levels, trust zones, and access permissions work correctly
//--------------------------------------------------------------------------------------------
class axi4_virtual_user_security_tagging_seq extends axi4_virtual_base_seq;
  
  `uvm_object_utils(axi4_virtual_user_security_tagging_seq)
  
  // Sequence handles
  axi4_master_user_security_tagging_seq master_security_seq[];
  
  // Test parameters
  int num_transactions_per_master = 10;
  int target_slave = 2; // Target slave for security tagging testing
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_user_security_tagging_seq");
  extern virtual task body();
  
endclass : axi4_virtual_user_security_tagging_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_virtual_user_security_tagging_seq::new(string name = "axi4_virtual_user_security_tagging_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Coordinates USER signal security tagging testing across multiple masters
//-----------------------------------------------------------------------------
task axi4_virtual_user_security_tagging_seq::body();
  int active_masters;
  
  super.body();
  
  // Use all available masters for security testing (different security contexts)
  active_masters = (env_cfg_h.no_of_masters > 4) ? 4 : env_cfg_h.no_of_masters;
  
  `uvm_info(get_type_name(), $sformatf("Starting USER signal security tagging test with %0d masters", active_masters), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Each master will test %0d security scenarios targeting slave S%0d", 
                                        num_transactions_per_master, target_slave), UVM_MEDIUM)
  `uvm_info(get_type_name(), "Testing security levels, trust zones, and access permissions", UVM_MEDIUM)
  
  // Create sequence array
  master_security_seq = new[active_masters];
  
  // Start security tagging sequences on all masters with different timing
  // Use staggered start to simulate different security contexts
  fork
    begin : all_master_security_sequences
      for (int i = 0; i < active_masters; i++) begin
        automatic int master_id = i;
        fork
          begin
            // Stagger starts to simulate different security contexts
            #(master_id * 100);
            
            `uvm_info(get_type_name(), $sformatf("Starting USER security tagging sequence on Master %0d", master_id), UVM_HIGH)
            
            // Create and configure the sequence
            master_security_seq[master_id] = axi4_master_user_security_tagging_seq::type_id::create(
                                             $sformatf("master_security_seq_%0d", master_id));
            
            // Set configuration via config_db
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_security_seq[master_id].get_name()}, 
                                    "master_id", master_id);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_security_seq[master_id].get_name()}, 
                                    "slave_id", target_slave);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_security_seq[master_id].get_name()}, 
                                    "num_transactions", num_transactions_per_master);
            
            // Alternate between write and read sequencers for security testing
            if (master_id & 1) begin
              master_security_seq[master_id].start(p_sequencer.axi4_master_write_seqr_h_all[master_id]);
            end
            else begin
              master_security_seq[master_id].start(p_sequencer.axi4_master_read_seqr_h_all[master_id]);
            end
          end
        join_none
      end
      
      // Wait for all security tagging sequences to complete
      wait fork;
    end
  join
  
  // Allow additional time for all transactions to complete and security to be verified
  #3000;
  
  `uvm_info(get_type_name(), "USER signal security tagging test completed", UVM_MEDIUM)
  `uvm_info(get_type_name(), "Expected behavior: All security tagging schemes should work correctly", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Security levels should be properly encoded and preserved", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Trust zones should be correctly identified", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Access permissions should be properly enforced", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Security hashes should provide integrity protection", UVM_MEDIUM)
  
endtask : body

`endif