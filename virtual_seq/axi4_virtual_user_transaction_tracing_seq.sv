`ifndef AXI4_VIRTUAL_USER_TRANSACTION_TRACING_SEQ_INCLUDED_
`define AXI4_VIRTUAL_USER_TRANSACTION_TRACING_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_user_transaction_tracing_seq
// Virtual sequence to test USER signal transaction tracing across multiple masters
// Verifies that trace IDs, debug markers, and performance monitoring work correctly
//--------------------------------------------------------------------------------------------
class axi4_virtual_user_transaction_tracing_seq extends axi4_virtual_base_seq;
  
  `uvm_object_utils(axi4_virtual_user_transaction_tracing_seq)
  
  // Sequence handles
  axi4_master_user_transaction_tracing_seq master_trace_seq[];
  
  // Test parameters
  int num_transactions_per_master = 9;
  int target_slave = 2; // Target slave for transaction tracing testing
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_user_transaction_tracing_seq");
  extern virtual task body();
  
endclass : axi4_virtual_user_transaction_tracing_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_virtual_user_transaction_tracing_seq::new(string name = "axi4_virtual_user_transaction_tracing_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Coordinates USER signal transaction tracing testing across multiple masters
//-----------------------------------------------------------------------------
task axi4_virtual_user_transaction_tracing_seq::body();
  int active_masters;
  
  super.body();
  
  // Use all available masters for tracing (each master represents different trace source)
  active_masters = (env_cfg_h.no_of_masters > 4) ? 4 : env_cfg_h.no_of_masters;
  
  `uvm_info(get_type_name(), $sformatf("Starting USER signal transaction tracing test with %0d masters", active_masters), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Each master will test %0d trace scenarios targeting slave S%0d", 
                                        num_transactions_per_master, target_slave), UVM_MEDIUM)
  `uvm_info(get_type_name(), "Testing trace types: Debug, Performance, Error, Security, Power, Thermal, QoS, Custom", UVM_MEDIUM)
  
  // Create sequence array
  master_trace_seq = new[active_masters];
  
  // Start transaction tracing sequences on all masters with coordinated timing
  // Each master represents a different trace source with unique characteristics
  fork
    begin : all_master_trace_sequences
      for (int i = 0; i < active_masters; i++) begin
        automatic int master_id = i;
        fork
          begin
            // Stagger starts to create realistic trace timing patterns
            #(master_id * 50);
            
            `uvm_info(get_type_name(), $sformatf("Starting USER transaction tracing sequence on Master %0d", master_id), UVM_HIGH)
            
            // Create and configure the sequence
            master_trace_seq[master_id] = axi4_master_user_transaction_tracing_seq::type_id::create(
                                         $sformatf("master_trace_seq_%0d", master_id));
            
            // Set configuration via config_db
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_trace_seq[master_id].get_name()}, 
                                    "master_id", master_id);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_trace_seq[master_id].get_name()}, 
                                    "slave_id", target_slave);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_trace_seq[master_id].get_name()}, 
                                    "num_transactions", num_transactions_per_master);
            
            // Use write sequencers for tracing (most trace events are for write operations)
            master_trace_seq[master_id].start(p_sequencer.axi4_master_write_seqr_h_all[master_id]);
          end
        join_none
      end
      
      // Wait for all transaction tracing sequences to complete
      wait fork;
    end
  join
  
  // Allow additional time for all trace transactions to complete
  #4000;
  
  `uvm_info(get_type_name(), "USER signal transaction tracing test completed", UVM_MEDIUM)
  `uvm_info(get_type_name(), "Expected behavior: All transaction tracing should work correctly", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Trace types should be properly encoded and preserved", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Debug markers should provide accurate debugging information", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Trace priorities should be correctly handled", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Timestamps should provide temporal correlation", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Sequence numbers should enable trace ordering", UVM_MEDIUM)
  
endtask : body

`endif