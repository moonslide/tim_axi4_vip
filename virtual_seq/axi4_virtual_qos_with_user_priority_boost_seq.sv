`ifndef AXI4_VIRTUAL_QOS_WITH_USER_PRIORITY_BOOST_SEQ_INCLUDED_
`define AXI4_VIRTUAL_QOS_WITH_USER_PRIORITY_BOOST_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_qos_with_user_priority_boost_seq
// Virtual sequence to test QoS priority boosting based on USER signals across multiple masters
// Verifies that USER signal context enhances QoS priority decisions appropriately
//--------------------------------------------------------------------------------------------
class axi4_virtual_qos_with_user_priority_boost_seq extends axi4_virtual_base_seq;
  
  `uvm_object_utils(axi4_virtual_qos_with_user_priority_boost_seq)
  
  // Sequence handles
  axi4_master_qos_with_user_priority_boost_seq master_boost_seq[];
  
  // Test parameters
  int num_transactions_per_master = 8;
  int target_slave = 2; // Target slave for QoS priority boost testing
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_qos_with_user_priority_boost_seq");
  extern virtual task body();
  
endclass : axi4_virtual_qos_with_user_priority_boost_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_virtual_qos_with_user_priority_boost_seq::new(string name = "axi4_virtual_qos_with_user_priority_boost_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Coordinates QoS priority boosting with USER signals across multiple masters
//-----------------------------------------------------------------------------
task axi4_virtual_qos_with_user_priority_boost_seq::body();
  int active_masters;
  
  super.body();
  
  // Use all available masters for combined QoS+USER testing
  active_masters = (env_cfg_h.no_of_masters > 4) ? 4 : env_cfg_h.no_of_masters;
  
  `uvm_info(get_type_name(), $sformatf("Starting QoS with USER priority boost test with %0d masters", active_masters), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Each master will test %0d priority boost scenarios targeting slave S%0d", 
                                        num_transactions_per_master, target_slave), UVM_MEDIUM)
  `uvm_info(get_type_name(), "Testing combined QoS+USER: Security, Real-time, Emergency, Performance boosts", UVM_MEDIUM)
  
  // Create sequence array
  master_boost_seq = new[active_masters];
  
  // Start QoS priority boost sequences on all masters with overlapping execution
  // This tests how the system handles multiple concurrent priority boosts
  fork
    begin : all_master_boost_sequences
      for (int i = 0; i < active_masters; i++) begin
        automatic int master_id = i;
        fork
          begin
            // Small stagger to create realistic boost timing patterns
            #(master_id * 75);
            
            `uvm_info(get_type_name(), $sformatf("Starting QoS priority boost sequence on Master %0d", master_id), UVM_HIGH)
            
            // Create and configure the sequence
            master_boost_seq[master_id] = axi4_master_qos_with_user_priority_boost_seq::type_id::create(
                                         $sformatf("master_boost_seq_%0d", master_id));
            
            // Set configuration via config_db
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_boost_seq[master_id].get_name()}, 
                                    "master_id", master_id);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_boost_seq[master_id].get_name()}, 
                                    "slave_id", target_slave);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_boost_seq[master_id].get_name()}, 
                                    "num_transactions", num_transactions_per_master);
            
            // Use write sequencers for priority boost testing (write operations are typically boosted)
            master_boost_seq[master_id].start(p_sequencer.axi4_master_write_seqr_h_all[master_id]);
          end
        join_none
      end
      
      // Wait for all QoS priority boost sequences to complete
      wait fork;
    end
  join
  
  // Allow additional time for all priority boost effects to be observed
  #3500;
  
  `uvm_info(get_type_name(), "QoS with USER priority boost test completed", UVM_MEDIUM)
  `uvm_info(get_type_name(), "Expected behavior: USER signals should enhance QoS priority decisions", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Security-critical transactions should get maximum priority", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Real-time deadlines should trigger appropriate priority boosts", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Emergency contexts should override normal QoS arbitration", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Performance-critical paths should receive priority elevation", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Power-saving contexts should reduce unnecessary priority", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Priority boosts should not interfere between masters", UVM_MEDIUM)
  
endtask : body

`endif