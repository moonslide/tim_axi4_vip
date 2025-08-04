`ifndef AXI4_VIRTUAL_QOS_BASIC_PRIORITY_TEST_SEQ_INCLUDED_
`define AXI4_VIRTUAL_QOS_BASIC_PRIORITY_TEST_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_qos_basic_priority_test_seq
// Virtual sequence to coordinate multiple masters for QoS basic priority testing
// Runs QoS priority order sequences on multiple masters simultaneously
//--------------------------------------------------------------------------------------------
class axi4_virtual_qos_basic_priority_test_seq extends axi4_virtual_base_seq;
  
  `uvm_object_utils(axi4_virtual_qos_basic_priority_test_seq)
  
  // Sequence handles
  axi4_master_qos_basic_priority_order_seq master_qos_seq[];
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_qos_basic_priority_test_seq");
  extern virtual task body();
  
endclass : axi4_virtual_qos_basic_priority_test_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_virtual_qos_basic_priority_test_seq::new(string name = "axi4_virtual_qos_basic_priority_test_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Coordinates multiple masters to test QoS priority ordering
//-----------------------------------------------------------------------------
task axi4_virtual_qos_basic_priority_test_seq::body();
  int no_of_masters_to_test;
  int master_ids[];
  int target_slave = 2; // Base slave, will be distributed
  
  super.body();
  
  // Randomly select number of masters between 2 and configured maximum
  no_of_masters_to_test = (env_cfg_h.no_of_masters > 2) ? $urandom_range(2, env_cfg_h.no_of_masters) : env_cfg_h.no_of_masters;
  
  // Dynamically create master_ids array
  master_ids = new[no_of_masters_to_test];
  for (int i = 0; i < no_of_masters_to_test; i++) begin
    master_ids[i] = i;
  end
  
  `uvm_info(get_type_name(), $sformatf("Starting QoS basic priority virtual sequence with %0d masters", no_of_masters_to_test), UVM_MEDIUM)
  
  // Create sequence array
  master_qos_seq = new[no_of_masters_to_test];
  
  // Start sequences on multiple masters in parallel
  fork
    begin : master_sequences
      for (int i = 0; i < no_of_masters_to_test; i++) begin
        automatic int idx = i;
        fork
          begin
            int distributed_slave;
            
            `uvm_info(get_type_name(), $sformatf("Starting QoS sequence on Master %0d", master_ids[idx]), UVM_HIGH)
            
            // Create and configure the sequence
            master_qos_seq[idx] = axi4_master_qos_basic_priority_order_seq::type_id::create($sformatf("master_qos_seq_%0d", idx));
            
            // Distribute masters across slaves to reduce contention
            // Use more slaves as number of masters increases
            if (no_of_masters_to_test <= 2) begin
              distributed_slave = 2 + (master_ids[idx] % 2);  // Use slaves 2 and 3
            end else if (no_of_masters_to_test <= 4) begin
              distributed_slave = 2 + (master_ids[idx] % 3);  // Use slaves 2, 3, and 4
            end else begin
              distributed_slave = 2 + (master_ids[idx] % 4);  // Use slaves 2, 3, 4, and 5
            end
            
            // Set master and slave IDs via config_db
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_qos_seq[idx].get_name()}, "master_id", master_ids[idx]);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", master_qos_seq[idx].get_name()}, "slave_id", distributed_slave);
            
            // Start the sequence on the appropriate sequencer
            if (master_ids[idx] < env_cfg_h.no_of_masters) begin
              master_qos_seq[idx].start(p_sequencer.axi4_master_write_seqr_h_all[master_ids[idx]]);
            end
            else begin
              `uvm_error(get_type_name(), $sformatf("Master ID %0d exceeds configured number of masters", master_ids[idx]))
            end
          end
        join_none
      end
      
      // Wait for all master sequences to complete
      wait fork;
    end
  join
  
  // Add some delay to allow all transactions to complete
  #1000;
  
  `uvm_info(get_type_name(), "QoS basic priority virtual sequence completed", UVM_MEDIUM)
  `uvm_info(get_type_name(), "Expected behavior: Transactions should be arbitrated based on QoS values when contending for the same slave", UVM_MEDIUM)
  
endtask : body

`endif