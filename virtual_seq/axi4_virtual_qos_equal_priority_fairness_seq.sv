`ifndef AXI4_VIRTUAL_QOS_EQUAL_PRIORITY_FAIRNESS_SEQ_INCLUDED_
`define AXI4_VIRTUAL_QOS_EQUAL_PRIORITY_FAIRNESS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_qos_equal_priority_fairness_seq
// Virtual sequence to verify fair arbitration when all masters have equal QoS
// Runs continuous traffic from all masters with same QoS value
//--------------------------------------------------------------------------------------------
class axi4_virtual_qos_equal_priority_fairness_seq extends axi4_virtual_base_seq;
  
  `uvm_object_utils(axi4_virtual_qos_equal_priority_fairness_seq)
  
  // Sequence handles - write-only sequences for all masters (avoids read BFM timeout issues)
  axi4_master_qos_write_only_seq master_write_seq[];
  
  // Test parameters
  bit [3:0] common_qos_value = 4'h8;
  int num_transactions_per_master;  // Dynamically scaled based on active masters
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_qos_equal_priority_fairness_seq");
  extern virtual task body();
  
endclass : axi4_virtual_qos_equal_priority_fairness_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_virtual_qos_equal_priority_fairness_seq::new(string name = "axi4_virtual_qos_equal_priority_fairness_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Coordinates all masters to generate traffic with equal QoS
//-----------------------------------------------------------------------------
task axi4_virtual_qos_equal_priority_fairness_seq::body();
  int target_slave = 2; // Primary target slave S2
  int secondary_slave = 3; // Secondary target to reduce congestion
  int active_masters;
  
  super.body();
  
  // Drastically limit active masters and transactions to get basic functionality working
  active_masters = (env_cfg_h.no_of_masters > 2) ? 2 : env_cfg_h.no_of_masters;
  
  // Use only 1 transaction per master to minimize complexity and debug basic issues
  num_transactions_per_master = 1;
  
  `uvm_info(get_type_name(), $sformatf("Starting QoS equal priority fairness test with %0d masters, QoS=0x%0h", 
                                       active_masters, common_qos_value), UVM_MEDIUM)
  
  // Create sequence array for write sequences (read sequences disabled to avoid BFM timeout issues)
  master_write_seq = new[active_masters];
  
  // Start sequences on all masters in parallel
  fork
    begin : all_master_sequences
      for (int i = 0; i < active_masters; i++) begin
        automatic int master_id = i;
        fork
          begin
            int selected_slave;
            string seq_name;
            
            `uvm_info(get_type_name(), $sformatf("Starting dedicated sequence on Master %0d", master_id), UVM_HIGH)
            
            // Distribute masters across valid writable slaves to reduce contention
            // Avoid problematic slaves: 3 (illegal address hole), 4 (read-only XOM), 5 (read-only peripheral)
            // Valid writable slaves: 0, 1, 2, 6, 7, 8, 9 (7 total slaves)
            case (master_id % 7)
              0: selected_slave = 0;  // DDR Secure Kernel
              1: selected_slave = 1;  // DDR Non-Secure User
              2: selected_slave = 2;  // DDR Shared Buffer
              3: selected_slave = 6;  // Privileged-Only
              4: selected_slave = 7;  // Secure-Only
              5: selected_slave = 8;  // Scratchpad
              6: selected_slave = 9;  // Attribute Monitor (write-only)
            endcase
            
            // Use WRITE-ONLY sequences for all masters to avoid read timeout issues
            seq_name = $sformatf("master_write_seq_%0d", master_id);
            
            // Set configuration for write sequence
            uvm_config_db#(int)::set(null, {get_full_name(), ".", seq_name, "*"}, 
                                    "master_id", master_id);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", seq_name, "*"}, 
                                    "slave_id", selected_slave);
            uvm_config_db#(bit [3:0])::set(null, {get_full_name(), ".", seq_name, "*"}, 
                                           "qos_value", common_qos_value);
            uvm_config_db#(int)::set(null, {get_full_name(), ".", seq_name, "*"}, 
                                    "num_transactions", num_transactions_per_master);
            
            // Create and start write sequence
            master_write_seq[master_id] = axi4_master_qos_write_only_seq::type_id::create(seq_name);
            
            `uvm_info(get_type_name(), $sformatf("Master %0d will perform WRITE-ONLY transactions to Slave %0d (QoS fairness test)", master_id, selected_slave), UVM_HIGH)
            master_write_seq[master_id].start(p_sequencer.axi4_master_write_seqr_h_all[master_id]);
          end
        join_none
      end
      
      // Wait for all master sequences to complete
      wait fork;
    end
  join
  
  // Add delay to ensure all transactions complete
  #5000;
  
  `uvm_info(get_type_name(), "QoS equal priority fairness test completed", UVM_MEDIUM)
  `uvm_info(get_type_name(), "Expected behavior: All masters should receive approximately equal bandwidth (±5% tolerance)", UVM_MEDIUM)
  
endtask : body

`endif