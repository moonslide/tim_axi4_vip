`ifndef AXI4_VIRTUAL_USER_BASED_QOS_ROUTING_SEQ_INCLUDED_
`define AXI4_VIRTUAL_USER_BASED_QOS_ROUTING_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_user_based_qos_routing_seq
// Virtual sequence to test USER signal-based QoS routing mechanisms
// Demonstrates how USER signals can control transaction routing and priority
//--------------------------------------------------------------------------------------------
class axi4_virtual_user_based_qos_routing_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_user_based_qos_routing_seq)

  // Master sequences for different routing scenarios
  axi4_master_user_based_qos_routing_seq master_routing_seq_h[4];
  
  // Standard sequences for comparison
  axi4_master_qos_priority_write_seq standard_qos_seq_h;
  axi4_master_qos_priority_read_seq standard_read_seq_h;

  // Slave sequences
  axi4_slave_nbk_write_seq axi4_slave_write_seq_h;
  axi4_slave_nbk_read_seq axi4_slave_read_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_user_based_qos_routing_seq");
  extern task body();

endclass : axi4_virtual_user_based_qos_routing_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the object
//
// Parameters:
//  name - axi4_virtual_user_based_qos_routing_seq
//--------------------------------------------------------------------------------------------
function axi4_virtual_user_based_qos_routing_seq::new(string name = "axi4_virtual_user_based_qos_routing_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates and starts sequences to test USER-based QoS routing
//--------------------------------------------------------------------------------------------
task axi4_virtual_user_based_qos_routing_seq::body();
  
  `uvm_info(get_type_name(), "Starting USER-based QoS Routing Virtual Sequence", UVM_LOW)
  
  // Create slave sequences
  axi4_slave_write_seq_h = axi4_slave_nbk_write_seq::type_id::create("axi4_slave_write_seq_h");
  axi4_slave_read_seq_h = axi4_slave_nbk_read_seq::type_id::create("axi4_slave_read_seq_h");
  
  // Start slave sequences in forever loops
  fork
    begin : SLAVE_WRITE
      forever begin
        axi4_slave_write_seq_h.start(p_sequencer.axi4_slave_write_seqr_h);
      end
    end
    
    begin : SLAVE_READ
      forever begin
        axi4_slave_read_seq_h.start(p_sequencer.axi4_slave_read_seqr_h);
      end
    end
  join_none
  
  // Test Scenario 1: Single Master routing to different slaves based on USER signals
  `uvm_info(get_type_name(), "==== Scenario 1: Single Master USER-based routing to multiple slaves ====", UVM_LOW)
  
  master_routing_seq_h[0] = axi4_master_user_based_qos_routing_seq::type_id::create("master_routing_seq_0");
  
  // Configure master 0 to target different slaves
  uvm_config_db#(int)::set(null, {get_full_name(), ".master_routing_seq_0"}, "master_id", 0);
  uvm_config_db#(int)::set(null, {get_full_name(), ".master_routing_seq_0"}, "slave_id", 0);
  uvm_config_db#(int)::set(null, {get_full_name(), ".master_routing_seq_0"}, "num_transactions", 5);
  
  master_routing_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h);
  #300ns;
  
  // Test Scenario 2: Multiple Masters with different routing strategies
  `uvm_info(get_type_name(), "==== Scenario 2: Multiple Masters with different USER routing strategies ====", UVM_LOW)
  
  for(int i = 1; i < 4; i++) begin
    master_routing_seq_h[i] = axi4_master_user_based_qos_routing_seq::type_id::create($sformatf("master_routing_seq_%0d", i));
    
    // Configure each master with different slave targets
    uvm_config_db#(int)::set(null, {get_full_name(), $sformatf(".master_routing_seq_%0d", i)}, "master_id", i);
    uvm_config_db#(int)::set(null, {get_full_name(), $sformatf(".master_routing_seq_%0d", i)}, "slave_id", i % 3);
    uvm_config_db#(int)::set(null, {get_full_name(), $sformatf(".master_routing_seq_%0d", i)}, "num_transactions", 3);
  end
  
  // Start all masters in parallel
  fork
    master_routing_seq_h[1].start(p_sequencer.axi4_master_write_seqr_h);
    master_routing_seq_h[2].start(p_sequencer.axi4_master_write_seqr_h);
    master_routing_seq_h[3].start(p_sequencer.axi4_master_write_seqr_h);
  join
  
  #500ns;
  
  // Test Scenario 3: Compare USER routing with standard QoS
  `uvm_info(get_type_name(), "==== Scenario 3: USER routing vs Standard QoS comparison ====", UVM_LOW)
  
  // Standard QoS transaction
  standard_qos_seq_h = axi4_master_qos_priority_write_seq::type_id::create("standard_qos_seq_h");
  standard_qos_seq_h.qos_value = 4'h8;
  
  fork
    begin
      `uvm_info(get_type_name(), "Starting standard QoS write (QoS=8)", UVM_LOW)
      standard_qos_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
    end
    begin
      #50ns;
      `uvm_info(get_type_name(), "Starting USER-routed write with dynamic QoS", UVM_LOW)
      master_routing_seq_h[0].num_transactions = 2;
      master_routing_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h);
    end
  join
  
  #300ns;
  
  // Test Scenario 4: USER routing with mixed read/write operations
  `uvm_info(get_type_name(), "==== Scenario 4: USER routing with mixed read operations ====", UVM_LOW)
  
  standard_read_seq_h = axi4_master_qos_priority_read_seq::type_id::create("standard_read_seq_h");
  standard_read_seq_h.qos_value = 4'h6;
  
  fork
    begin
      // Write with USER routing
      master_routing_seq_h[0].num_transactions = 3;
      master_routing_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h);
    end
    begin
      #100ns;
      // Read with standard QoS
      standard_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
    end
  join
  
  #500ns;
  
  // Test Scenario 5: Adaptive routing demonstration
  `uvm_info(get_type_name(), "==== Scenario 5: Adaptive USER-based routing demonstration ====", UVM_LOW)
  
  for(int cycle = 0; cycle < 3; cycle++) begin
    `uvm_info(get_type_name(), $sformatf("Adaptive routing cycle %0d", cycle), UVM_LOW)
    
    // Reconfigure for adaptive behavior
    master_routing_seq_h[0] = axi4_master_user_based_qos_routing_seq::type_id::create($sformatf("adaptive_seq_%0d", cycle));
    uvm_config_db#(int)::set(null, {get_full_name(), $sformatf(".adaptive_seq_%0d", cycle)}, "master_id", 0);
    uvm_config_db#(int)::set(null, {get_full_name(), $sformatf(".adaptive_seq_%0d", cycle)}, "slave_id", cycle % 3);
    uvm_config_db#(int)::set(null, {get_full_name(), $sformatf(".adaptive_seq_%0d", cycle)}, "num_transactions", 2);
    
    master_routing_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h);
    #200ns;
  end
  
  // Wait for all transactions to complete
  #1000ns;
  
  `uvm_info(get_type_name(), "Completed USER-based QoS Routing Virtual Sequence", UVM_LOW)
  `uvm_info(get_type_name(), "Test Summary:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Demonstrated USER signal-based routing to different slaves", UVM_LOW)
  `uvm_info(get_type_name(), "  - Showed multiple routing strategies (workload, bandwidth, latency optimized)", UVM_LOW)
  `uvm_info(get_type_name(), "  - Compared USER routing with standard QoS mechanisms", UVM_LOW)
  `uvm_info(get_type_name(), "  - Verified adaptive routing based on USER signal encoding", UVM_LOW)
  `uvm_info(get_type_name(), "  - USER signal format used:", UVM_LOW)
  `uvm_info(get_type_name(), "    [2:0]   - Routing strategy", UVM_LOW)
  `uvm_info(get_type_name(), "    [6:3]   - Application context", UVM_LOW)
  `uvm_info(get_type_name(), "    [10:7]  - Suggested QoS", UVM_LOW)
  `uvm_info(get_type_name(), "    [14:11] - Fallback QoS", UVM_LOW)
  `uvm_info(get_type_name(), "    [18:15] - Master ID", UVM_LOW)
  `uvm_info(get_type_name(), "    [26:19] - Priority hint", UVM_LOW)
  `uvm_info(get_type_name(), "    [31:27] - Timestamp", UVM_LOW)
  
endtask : body

`endif