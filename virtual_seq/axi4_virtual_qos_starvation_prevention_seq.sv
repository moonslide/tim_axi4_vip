`ifndef AXI4_VIRTUAL_QOS_STARVATION_PREVENTION_SEQ_INCLUDED_
`define AXI4_VIRTUAL_QOS_STARVATION_PREVENTION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_qos_starvation_prevention_seq
// Virtual sequence to verify that low priority traffic doesn't get starved by high priority
// Tests fairness mechanisms in QoS arbitration
//--------------------------------------------------------------------------------------------
class axi4_virtual_qos_starvation_prevention_seq extends axi4_virtual_base_seq;
  
  `uvm_object_utils(axi4_virtual_qos_starvation_prevention_seq)
  
  // Sequence handles
  axi4_master_qos_starvation_prevention_seq master_starvation_seq[];
  
  // Test parameters - assign different priority roles to masters
  int target_slave = 2;
  int low_priority_masters[];  // Masters that generate low priority traffic
  int high_priority_masters[]; // Masters that generate high priority traffic
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_qos_starvation_prevention_seq");
  extern virtual task body();
  extern virtual task assign_master_priorities();
  
endclass : axi4_virtual_qos_starvation_prevention_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_virtual_qos_starvation_prevention_seq::new(string name = "axi4_virtual_qos_starvation_prevention_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Coordinates mixed priority traffic to test starvation prevention
//-----------------------------------------------------------------------------
task axi4_virtual_qos_starvation_prevention_seq::body();
  int active_masters;
  
  super.body();
  
  // Randomly select active masters between 2 and configured maximum for robust testing
  active_masters = (env_cfg_h.no_of_masters > 2) ? $urandom_range(2, env_cfg_h.no_of_masters) : env_cfg_h.no_of_masters;
  
  // Assign priority roles to masters
  assign_master_priorities();
  
  `uvm_info(get_type_name(), $sformatf("Starting QoS starvation prevention test with %0d masters", active_masters), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Low priority masters: %0d, High priority masters: %0d", 
                                        low_priority_masters.size(), high_priority_masters.size()), UVM_MEDIUM)
  
  // Create sequence array
  master_starvation_seq = new[active_masters];
  
  // Start starvation prevention sequences on all masters
  fork
    begin : all_master_starvation_sequences
      for (int i = 0; i < active_masters; i++) begin
        automatic int master_id = i;
        fork
          begin
            int distributed_slave;
            
            `uvm_info(get_type_name(), $sformatf("Starting starvation prevention sequence on Master %0d", master_id), UVM_HIGH)
            
            // Create and configure the sequence
            master_starvation_seq[master_id] = axi4_master_qos_starvation_prevention_seq::type_id::create(
                                              $sformatf("master_starvation_seq_%0d", master_id));
            
            // Distribute masters across slaves to reduce contention
            // Use more slaves as number of masters increases
            if (active_masters <= 2) begin
              distributed_slave = 2 + (master_id % 2);  // Use slaves 2 and 3
            end else if (active_masters <= 4) begin
              distributed_slave = 2 + (master_id % 3);  // Use slaves 2, 3, and 4
            end else begin
              distributed_slave = 2 + (master_id % 4);  // Use slaves 2, 3, 4, and 5
            end
            
            // Set configuration via config_db
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_starvation_seq[master_id].get_name()}, 
                                    "master_id", master_id);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_starvation_seq[master_id].get_name()}, 
                                    "slave_id", distributed_slave);
            
            // Always use write sequencer since the sequence generates both read and write transactions
            master_starvation_seq[master_id].start(p_sequencer.axi4_master_write_seqr_h_all[master_id]);
          end
        join_none
      end
      
      // Wait for all starvation prevention sequences to complete
      wait fork;
    end
  join
  
  // Allow additional time for all low priority transactions to complete
  #3000;
  
  `uvm_info(get_type_name(), "QoS starvation prevention test completed", UVM_MEDIUM)
  `uvm_info(get_type_name(), "Expected behavior: Low priority transactions should eventually complete despite high priority traffic", UVM_MEDIUM)
  
endtask : body

//-----------------------------------------------------------------------------
// Task: assign_master_priorities
// Assigns different priority roles to masters for testing
//-----------------------------------------------------------------------------
task axi4_virtual_qos_starvation_prevention_seq::assign_master_priorities();
  int active_masters;
  
  active_masters = (env_cfg_h.no_of_masters > 2) ? $urandom_range(2, env_cfg_h.no_of_masters) : env_cfg_h.no_of_masters;
  
  // Allocate arrays
  low_priority_masters = new[active_masters/2 + active_masters%2]; // Majority are low priority
  high_priority_masters = new[active_masters/2];
  
  // Assign masters to priority groups
  for (int i = 0; i < active_masters; i++) begin
    if (i < active_masters/2) begin
      high_priority_masters[i] = i;
    end
    else begin
      low_priority_masters[i - active_masters/2] = i;
    end
  end
  
  `uvm_info(get_type_name(), $sformatf("Priority assignment completed: Low=%0d masters, High=%0d masters", 
                                        low_priority_masters.size(), high_priority_masters.size()), UVM_HIGH)
  
endtask : assign_master_priorities

`endif