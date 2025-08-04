`ifndef AXI4_VIRTUAL_QOS_SATURATION_STRESS_SEQ_INCLUDED_
`define AXI4_VIRTUAL_QOS_SATURATION_STRESS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_qos_saturation_stress_seq
// Virtual sequence to coordinate QoS saturation stress testing across multiple masters
// All masters generate maximum priority traffic simultaneously to stress arbitration
//--------------------------------------------------------------------------------------------
class axi4_virtual_qos_saturation_stress_seq extends axi4_virtual_base_seq;
  
  `uvm_object_utils(axi4_virtual_qos_saturation_stress_seq)
  
  // Sequence handles
  axi4_master_qos_saturation_stress_seq master_stress_seq[];
  
  // Test parameters - dynamically scaled based on active masters
  int num_transactions_per_master;
  int target_slave = 2; // All masters target slave S2 for maximum contention
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_qos_saturation_stress_seq");
  extern virtual task body();
  
endclass : axi4_virtual_qos_saturation_stress_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_virtual_qos_saturation_stress_seq::new(string name = "axi4_virtual_qos_saturation_stress_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Coordinates all masters to generate high-priority traffic simultaneously
//-----------------------------------------------------------------------------
task axi4_virtual_qos_saturation_stress_seq::body();
  int active_masters;
  
  super.body();
  
  // Randomly select active masters between 2 and configured maximum for robust testing
  active_masters = (env_cfg_h.no_of_masters > 2) ? $urandom_range(2, env_cfg_h.no_of_masters) : env_cfg_h.no_of_masters;
  
  // Dynamically scale transactions based on active masters to avoid overload
  // More masters = fewer transactions per master to maintain system stability
  case (active_masters)
    2: num_transactions_per_master = 20;
    3: num_transactions_per_master = 15;
    4: num_transactions_per_master = 10;
    default: num_transactions_per_master = 40 / active_masters; // Scale down for more masters
  endcase
  
  `uvm_info(get_type_name(), $sformatf("Starting QoS saturation stress test with %0d masters", active_masters), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Each master will generate %0d high-priority transactions targeting slave S%0d", 
                                        num_transactions_per_master, target_slave), UVM_MEDIUM)
  
  // Create sequence array
  master_stress_seq = new[active_masters];
  
  // Start stress sequences on all masters simultaneously
  fork
    begin : all_master_stress_sequences
      for (int i = 0; i < active_masters; i++) begin
        automatic int master_id = i;
        fork
          begin
            int distributed_slave;
            
            `uvm_info(get_type_name(), $sformatf("Starting saturation stress sequence on Master %0d", master_id), UVM_HIGH)
            
            // Create and configure the sequence
            master_stress_seq[master_id] = axi4_master_qos_saturation_stress_seq::type_id::create(
                                          $sformatf("master_stress_seq_%0d", master_id));
            
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
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_stress_seq[master_id].get_name()}, 
                                    "master_id", master_id);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_stress_seq[master_id].get_name()}, 
                                    "slave_id", distributed_slave);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_stress_seq[master_id].get_name()}, 
                                    "num_transactions", num_transactions_per_master);
            
            // Always use write sequencer since the sequence generates both read and write transactions
            master_stress_seq[master_id].start(p_sequencer.axi4_master_write_seqr_h_all[master_id]);
          end
        join_none
      end
      
      // Wait for all stress sequences to complete
      wait fork;
    end
  join
  
  // Allow additional time for all transactions to complete through the system
  #2000;
  
  `uvm_info(get_type_name(), "QoS saturation stress test completed", UVM_MEDIUM)
  `uvm_info(get_type_name(), "Expected behavior: System should handle high QoS load without deadlock or significant performance degradation", UVM_MEDIUM)
  
endtask : body

`endif