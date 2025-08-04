`ifndef AXI4_VIRTUAL_USER_BASED_QOS_ROUTING_SEQ_INCLUDED_
`define AXI4_VIRTUAL_USER_BASED_QOS_ROUTING_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_user_based_qos_routing_seq
// Virtual sequence to test USER-based QoS routing across multiple masters
// Verifies that QoS routing decisions are made intelligently based on USER signal context
//--------------------------------------------------------------------------------------------
class axi4_virtual_user_based_qos_routing_seq extends axi4_virtual_base_seq;
  
  `uvm_object_utils(axi4_virtual_user_based_qos_routing_seq)
  
  // Sequence handles
  axi4_master_user_based_qos_routing_seq master_routing_seq[];
  
  // Test parameters
  int num_transactions_per_master = 9;
  int target_slave = 2; // Target slave for QoS routing testing
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_user_based_qos_routing_seq");
  extern virtual task body();
  
endclass : axi4_virtual_user_based_qos_routing_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_virtual_user_based_qos_routing_seq::new(string name = "axi4_virtual_user_based_qos_routing_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Coordinates USER-based QoS routing testing across multiple masters
//-----------------------------------------------------------------------------
task axi4_virtual_user_based_qos_routing_seq::body();
  int active_masters;
  
  super.body();
  
  // Use all available masters for QoS routing testing (different app contexts per master)
  active_masters = (env_cfg_h.no_of_masters > 4) ? 4 : env_cfg_h.no_of_masters;
  
  `uvm_info(get_type_name(), $sformatf("Starting USER-based QoS routing test with %0d masters", active_masters), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Each master will test %0d routing strategies targeting slave S%0d", 
                                        num_transactions_per_master, target_slave), UVM_MEDIUM)
  `uvm_info(get_type_name(), "Testing routing strategies: Workload-aware, Bandwidth/Latency optimized, Energy/Thermal aware", UVM_MEDIUM)
  
  // Create sequence array
  master_routing_seq = new[active_masters];
  
  // Start USER-based QoS routing sequences on all masters with coordinated timing
  // Each master represents different application contexts requiring different routing
  fork
    begin : all_master_routing_sequences
      for (int i = 0; i < active_masters; i++) begin
        automatic int master_id = i;
        fork
          begin
            // Stagger starts to simulate different application launch times
            #(master_id * 100);
            
            `uvm_info(get_type_name(), $sformatf("Starting USER-based QoS routing sequence on Master %0d", master_id), UVM_HIGH)
            
            // Create and configure the sequence
            master_routing_seq[master_id] = axi4_master_user_based_qos_routing_seq::type_id::create(
                                           $sformatf("master_routing_seq_%0d", master_id));
            
            // Set configuration via config_db
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_routing_seq[master_id].get_name()}, 
                                    "master_id", master_id);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_routing_seq[master_id].get_name()}, 
                                    "slave_id", target_slave);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_routing_seq[master_id].get_name()}, 
                                    "num_transactions", num_transactions_per_master);
            
            // Alternate between write and read sequencers for different routing scenarios
            if (master_id & 1) begin
              master_routing_seq[master_id].start(p_sequencer.axi4_master_write_seqr_h_all[master_id]);
            end
            else begin
              master_routing_seq[master_id].start(p_sequencer.axi4_master_read_seqr_h_all[master_id]);
            end
          end
        join_none
      end
      
      // Wait for all USER-based QoS routing sequences to complete
      wait fork;
    end
  join
  
  // Allow additional time for all routing decisions to take effect
  #4000;
  
  `uvm_info(get_type_name(), "USER-based QoS routing test completed", UVM_MEDIUM)
  `uvm_info(get_type_name(), "Expected behavior: QoS routing should adapt to USER signal context", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Workload-aware routing should optimize for application characteristics", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Bandwidth optimization should maximize throughput for bulk transfers", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Latency optimization should minimize delays for interactive apps", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Energy-aware routing should reduce power for background tasks", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Thermal-aware routing should manage heat generation", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Load balancing should distribute traffic efficiently", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Adaptive routing should respond to dynamic conditions", UVM_MEDIUM)
  
endtask : body

`endif