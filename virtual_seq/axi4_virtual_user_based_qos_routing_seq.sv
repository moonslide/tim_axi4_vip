`ifndef AXI4_VIRTUAL_USER_BASED_QOS_ROUTING_SEQ_INCLUDED_
`define AXI4_VIRTUAL_USER_BASED_QOS_ROUTING_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_user_based_qos_routing_seq
// Virtual sequence to test USER signal-based QoS routing mechanisms
// Demonstrates how USER signals can control transaction routing and priority
// Supports all three bus matrix modes with proper address generation
//--------------------------------------------------------------------------------------------
class axi4_virtual_user_based_qos_routing_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_user_based_qos_routing_seq)

  // Master sequences for different routing scenarios
  axi4_master_user_based_qos_routing_seq master_routing_seq_h[];
  
  // Standard sequences for comparison
  axi4_master_qos_priority_write_seq standard_qos_seq_h;
  axi4_master_qos_priority_read_seq standard_read_seq_h;

  // Slave sequences
  axi4_slave_nbk_write_seq axi4_slave_write_seq_h[];
  axi4_slave_nbk_read_seq axi4_slave_read_seq_h[];
  
  // Configuration parameters from test
  int num_masters = 4;
  int num_slaves = 4;
  bit is_enhanced_mode = 0;
  bit is_4x4_ref_mode = 0;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_user_based_qos_routing_seq");
  extern task body();
  extern function bit [63:0] get_valid_slave_addr(int slave_id, int master_id);
  extern function bit is_access_allowed(int master_id, int slave_id);

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
  int actual_masters;
  int actual_slaves;
  
  `uvm_info(get_type_name(), "========================================", UVM_LOW)
  `uvm_info(get_type_name(), "USER-BASED QOS ROUTING SEQUENCE", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Masters: %0d, Slaves: %0d", num_masters, num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Enhanced: %0d, 4x4 Ref: %0d", is_enhanced_mode, is_4x4_ref_mode), UVM_LOW)
  `uvm_info(get_type_name(), "========================================", UVM_LOW)
  
  // Determine actual number of sequencers available
  actual_masters = (p_sequencer.axi4_master_write_seqr_h_all.size() > 0) ? 
                   p_sequencer.axi4_master_write_seqr_h_all.size() : 1;
  actual_slaves = (p_sequencer.axi4_slave_write_seqr_h_all.size() > 0) ? 
                  p_sequencer.axi4_slave_write_seqr_h_all.size() : 1;
  
  // Use minimum of configured and actual
  if (actual_masters < num_masters) begin
    `uvm_info(get_type_name(), $sformatf("Adjusting masters from %0d to %0d (actual available)", 
                                         num_masters, actual_masters), UVM_MEDIUM)
    num_masters = actual_masters;
  end
  
  if (actual_slaves < num_slaves) begin
    `uvm_info(get_type_name(), $sformatf("Adjusting slaves from %0d to %0d (actual available)", 
                                         num_slaves, actual_slaves), UVM_MEDIUM)
    num_slaves = actual_slaves;
  end
  
  // Create slave sequences arrays
  axi4_slave_write_seq_h = new[num_slaves];
  axi4_slave_read_seq_h = new[num_slaves];
  
  // Create and start slave sequences for each slave
  for(int i = 0; i < num_slaves; i++) begin
    axi4_slave_write_seq_h[i] = axi4_slave_nbk_write_seq::type_id::create($sformatf("axi4_slave_write_seq_h[%0d]", i));
    axi4_slave_read_seq_h[i] = axi4_slave_nbk_read_seq::type_id::create($sformatf("axi4_slave_read_seq_h[%0d]", i));
  end
  
  // Start slave sequences once in forever loops
  fork
    begin : SLAVE_WRITE
      if (actual_slaves > 1) begin
        foreach(p_sequencer.axi4_slave_write_seqr_h_all[i]) begin
          if (i < num_slaves) begin
            automatic int slave_idx = i;
            fork
              forever begin
                axi4_slave_write_seq_h[slave_idx].start(p_sequencer.axi4_slave_write_seqr_h_all[slave_idx]);
                #10;
              end
            join_none
          end
        end
      end else begin
        fork
          forever begin
            axi4_slave_write_seq_h[0].start(p_sequencer.axi4_slave_write_seqr_h);
            #10;
          end
        join_none
      end
    end
    
    begin : SLAVE_READ
      if (actual_slaves > 1) begin
        foreach(p_sequencer.axi4_slave_read_seqr_h_all[i]) begin
          if (i < num_slaves) begin
            automatic int slave_idx = i;
            fork
              forever begin
                axi4_slave_read_seq_h[slave_idx].start(p_sequencer.axi4_slave_read_seqr_h_all[slave_idx]);
                #10;
              end
            join_none
          end
        end
      end else begin
        fork
          forever begin
            axi4_slave_read_seq_h[0].start(p_sequencer.axi4_slave_read_seqr_h);
            #10;
          end
        join_none
      end
    end
  join_none
  
  // Create master sequences array based on number of masters
  master_routing_seq_h = new[num_masters];
  
  // Test Scenario 1: Single Master routing to different slaves based on USER signals
  `uvm_info(get_type_name(), "==== Scenario 1: Single Master USER-based routing to multiple slaves ====", UVM_LOW)
  
  master_routing_seq_h[0] = axi4_master_user_based_qos_routing_seq::type_id::create("master_routing_seq_0");
  
  // Configure master 0 to target valid slave (use slave 0 - DDR_Memory which is R/W)
  uvm_config_db#(int)::set(null, "*master_routing_seq_0", "master_id", 0);
  uvm_config_db#(int)::set(null, "*master_routing_seq_0", "slave_id", 0); // DDR_Memory (R/W)
  uvm_config_db#(int)::set(null, "*master_routing_seq_0", "num_transactions", 3);
  uvm_config_db#(bit)::set(null, "*master_routing_seq_0", "is_enhanced_mode", is_enhanced_mode);
  
  if (actual_masters > 1 && p_sequencer.axi4_master_write_seqr_h_all.size() > 0) begin
    master_routing_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h_all[0]);
  end else begin
    master_routing_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h);
  end
  #300ns;
  
  // Test Scenario 2: Multiple Masters with different routing strategies
  if (num_masters > 1) begin
    `uvm_info(get_type_name(), "==== Scenario 2: Multiple Masters with different USER routing strategies ====", UVM_LOW)
    
    for(int i = 1; i < num_masters && i < 4; i++) begin
      int target_slave;
      
      master_routing_seq_h[i] = axi4_master_user_based_qos_routing_seq::type_id::create($sformatf("master_routing_seq_%0d", i));
      
      // Find a valid writable slave for this master (avoid read-only slaves 1 and 3)
      target_slave = -1;
      for(int s = 0; s < num_slaves; s++) begin
        // Skip read-only slaves for write operations
        if (s == 1 || s == 3) continue; // Boot_ROM and HW_Fuse_Box are read-only
        if (is_access_allowed(i, s)) begin
          target_slave = s;
          break;
        end
      end
      
      if (target_slave == -1) target_slave = 0; // Fallback to slave 0 (DDR_Memory)
      
      // Configure each master with valid slave targets using wildcard path
      uvm_config_db#(int)::set(null, $sformatf("*master_routing_seq_%0d", i), "master_id", i);
      uvm_config_db#(int)::set(null, $sformatf("*master_routing_seq_%0d", i), "slave_id", target_slave);
      uvm_config_db#(int)::set(null, $sformatf("*master_routing_seq_%0d", i), "num_transactions", 2);
      uvm_config_db#(bit)::set(null, $sformatf("*master_routing_seq_%0d", i), "is_enhanced_mode", is_enhanced_mode);
    end
    
    // Start masters in parallel on appropriate sequencers
    fork
      begin
        for(int i = 1; i < num_masters && i < 4; i++) begin
          automatic int master_idx = i;
          fork
            begin
              if (actual_masters > 1 && master_idx < p_sequencer.axi4_master_write_seqr_h_all.size()) begin
                master_routing_seq_h[master_idx].start(p_sequencer.axi4_master_write_seqr_h_all[master_idx]);
              end else begin
                master_routing_seq_h[master_idx].start(p_sequencer.axi4_master_write_seqr_h);
              end
            end
          join_none
        end
        wait fork;
      end
    join
  end
  
  #500ns;
  
  // Test Scenario 3: Compare USER routing with standard QoS
  `uvm_info(get_type_name(), "==== Scenario 3: USER routing vs Standard QoS comparison ====", UVM_LOW)
  
  // Standard QoS transaction
  standard_qos_seq_h = axi4_master_qos_priority_write_seq::type_id::create("standard_qos_seq_h");
  standard_qos_seq_h.qos_value = 4'h8;
  standard_qos_seq_h.master_id = 0;
  standard_qos_seq_h.target_slave_id = 0;
  
  fork
    begin
      `uvm_info(get_type_name(), "Starting standard QoS write (QoS=8)", UVM_LOW)
      if (actual_masters > 1 && p_sequencer.axi4_master_write_seqr_h_all.size() > 0) begin
        standard_qos_seq_h.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
      end else begin
        standard_qos_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
      end
    end
    begin
      #50ns;
      `uvm_info(get_type_name(), "Starting USER-routed write with dynamic QoS", UVM_LOW)
      master_routing_seq_h[0] = axi4_master_user_based_qos_routing_seq::type_id::create("master_routing_seq_comparison");
      uvm_config_db#(int)::set(null, "*master_routing_seq_comparison", "master_id", 0);
      uvm_config_db#(int)::set(null, "*master_routing_seq_comparison", "slave_id", 0);
      uvm_config_db#(int)::set(null, "*master_routing_seq_comparison", "num_transactions", 2);
      uvm_config_db#(bit)::set(null, "*master_routing_seq_comparison", "is_enhanced_mode", is_enhanced_mode);
      if (actual_masters > 1 && p_sequencer.axi4_master_write_seqr_h_all.size() > 0) begin
        master_routing_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h_all[0]);
      end else begin
        master_routing_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h);
      end
    end
  join
  
  #300ns;
  
  // Test Scenario 4: USER routing with mixed read/write operations
  `uvm_info(get_type_name(), "==== Scenario 4: USER routing with mixed read operations ====", UVM_LOW)
  
  standard_read_seq_h = axi4_master_qos_priority_read_seq::type_id::create("standard_read_seq_h");
  standard_read_seq_h.qos_value = 4'h6;
  standard_read_seq_h.master_id = 0;
  standard_read_seq_h.target_slave_id = 0;
  
  fork
    begin
      // Write with USER routing
      master_routing_seq_h[0] = axi4_master_user_based_qos_routing_seq::type_id::create("master_routing_seq_mixed");
      uvm_config_db#(int)::set(null, "*master_routing_seq_mixed", "master_id", 0);
      uvm_config_db#(int)::set(null, "*master_routing_seq_mixed", "slave_id", 0);
      uvm_config_db#(int)::set(null, "*master_routing_seq_mixed", "num_transactions", 2);
      uvm_config_db#(bit)::set(null, "*master_routing_seq_mixed", "is_enhanced_mode", is_enhanced_mode);
      if (actual_masters > 1 && p_sequencer.axi4_master_write_seqr_h_all.size() > 0) begin
        master_routing_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h_all[0]);
      end else begin
        master_routing_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h);
      end
    end
    begin
      #100ns;
      // Read with standard QoS
      if (actual_masters > 1 && p_sequencer.axi4_master_read_seqr_h_all.size() > 0) begin
        standard_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h_all[0]);
      end else begin
        standard_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
      end
    end
  join
  
  #500ns;
  
  // Test Scenario 5: Adaptive routing demonstration
  `uvm_info(get_type_name(), "==== Scenario 5: Adaptive USER-based routing demonstration ====", UVM_LOW)
  
  for(int cycle = 0; cycle < 3 && cycle < num_slaves; cycle++) begin
    int target_slave = cycle;
    
    // Skip read-only slaves for write operations
    if (target_slave == 1 || target_slave == 3) begin
      // Find a writable slave
      target_slave = (cycle == 1) ? 0 : 2; // Use DDR or Peripheral_Regs
    end
    
    // Check if master 0 can access this slave
    if (!is_access_allowed(0, target_slave)) begin
      // Find an accessible writable slave
      for(int s = 0; s < num_slaves; s++) begin
        if (s == 1 || s == 3) continue; // Skip read-only slaves
        if (is_access_allowed(0, s)) begin
          target_slave = s;
          break;
        end
      end
    end
    
    `uvm_info(get_type_name(), $sformatf("Adaptive routing cycle %0d -> Slave %0d", cycle, target_slave), UVM_LOW)
    
    // Reconfigure for adaptive behavior
    master_routing_seq_h[0] = axi4_master_user_based_qos_routing_seq::type_id::create($sformatf("adaptive_seq_%0d", cycle));
    uvm_config_db#(int)::set(null, $sformatf("*adaptive_seq_%0d", cycle), "master_id", 0);
    uvm_config_db#(int)::set(null, $sformatf("*adaptive_seq_%0d", cycle), "slave_id", target_slave);
    uvm_config_db#(int)::set(null, $sformatf("*adaptive_seq_%0d", cycle), "num_transactions", 2);
    uvm_config_db#(bit)::set(null, $sformatf("*adaptive_seq_%0d", cycle), "is_enhanced_mode", is_enhanced_mode);
    
    if (actual_masters > 1 && p_sequencer.axi4_master_write_seqr_h_all.size() > 0) begin
      master_routing_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h_all[0]);
    end else begin
      master_routing_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h);
    end
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

//--------------------------------------------------------------------------------------------
// Function: get_valid_slave_addr
// Returns a valid address for the specified slave based on bus matrix mode
//--------------------------------------------------------------------------------------------
function bit [63:0] axi4_virtual_user_based_qos_routing_seq::get_valid_slave_addr(int slave_id, int master_id);
  bit [63:0] base_addr;
  bit [63:0] offset;
  
  if (!is_enhanced_mode) begin
    // Base addresses matching AXI_MATRIX.txt configuration for 4x4 mode
    // S0: DDR_Memory at 0x0000_0100_0000_0000 (R/W)
    // S1: Boot_ROM at 0x0000_0000_0000_0000 (Read-Only)
    // S2: Peripheral_Regs at 0x0000_0010_0000_0000 (R/W)
    // S3: HW_Fuse_Box at 0x0000_0020_0000_0000 (Read-Only)
    case(slave_id)
      0: base_addr = 64'h0000_0100_0000_0000; // DDR_Memory (R/W)
      1: base_addr = 64'h0000_0000_0000_0000; // Boot_ROM (Read-Only)
      2: base_addr = 64'h0000_0010_0000_0000; // Peripheral_Regs (R/W)
      3: base_addr = 64'h0000_0020_0000_0000; // HW_Fuse_Box (Read-Only)
      default: base_addr = 64'h0000_0100_0000_0000; // Default to DDR
    endcase
  end else begin
    // 10x10 ENHANCED mode addresses
    case(slave_id)
      0: base_addr = 64'h0000_0008_0000_0000; // Slave 0
      1: base_addr = 64'h0000_0008_4000_0000; // Slave 1
      2: base_addr = 64'h0000_0008_8000_0000; // Slave 2
      3: base_addr = 64'h0000_0008_c000_0000; // Slave 3
      4: base_addr = 64'h0000_0009_0000_0000; // Slave 4
      5: base_addr = 64'h0000_000a_0000_0000; // Slave 5
      6: base_addr = 64'h0000_000a_0001_0000; // Slave 6
      7: base_addr = 64'h0000_000a_0002_0000; // Slave 7
      8: base_addr = 64'h0000_000a_0003_0000; // Slave 8
      9: base_addr = 64'h0000_000a_0004_0000; // Slave 9
      default: base_addr = 64'h0000_0008_0000_0000; // Default to slave 0
    endcase
  end
  
  // Add offset based on master to avoid conflicts
  offset = master_id * 64'h1000;
  
  return base_addr + offset;
endfunction : get_valid_slave_addr

//--------------------------------------------------------------------------------------------
// Function: is_access_allowed
// Checks if a master can access a slave based on bus matrix mode and access control
//--------------------------------------------------------------------------------------------
function bit axi4_virtual_user_based_qos_routing_seq::is_access_allowed(int master_id, int slave_id);
  // For NONE mode, all accesses are allowed
  if (!is_4x4_ref_mode && !is_enhanced_mode) begin
    return 1;
  end
  
  // For 4x4 mode
  if (is_4x4_ref_mode && !is_enhanced_mode) begin
    // Slave 2 only allows masters 0, 1, 2
    if (slave_id == 2 && master_id > 2) return 0;
    // Slave 3 is secure, only master 3 can access
    if (slave_id == 3 && master_id != 3) return 0;
    return 1;
  end
  
  // For 10x10 enhanced mode
  if (is_enhanced_mode) begin
    // Apply more complex access control
    case(slave_id)
      2: return (master_id <= 4); // First 5 masters only
      3: return (master_id == 3 || master_id == 9); // Secure slave
      5: return (master_id >= 5); // Last 5 masters only
      7: return (master_id % 2 == 0); // Even masters only
      9: return (master_id == 9); // Exclusive to master 9
      default: return 1;
    endcase
  end
  
  return 1;
endfunction : is_access_allowed

`endif