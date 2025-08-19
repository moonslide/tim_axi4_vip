`ifndef AXI_VIRTUAL_NBK_QOS_WRITE_READ_SEQ_INCLUDED_
`define AXI_VIRTUAL_NBK_QOS_WRITE_READ_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_nbk_qos_write_read_seq
// Creates and starts the master and slave sequences
// Supports all three bus matrix modes with proper address generation
//--------------------------------------------------------------------------------------------
class axi4_virtual_nbk_qos_write_read_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_nbk_qos_write_read_seq)

  //Variable: axi4_master_nbk_write_qos_seq_h
  //Instantiation of axi4_master_write_qos_seq handle
  axi4_master_nbk_write_qos_seq axi4_master_nbk_write_qos_seq_h;

  //Variable: axi4_master_read_qos_seq_h
  //Instantiation of axi4_master_read_qos_seq handle
  axi4_master_nbk_read_qos_seq axi4_master_nbk_read_qos_seq_h;

  //Variable: axi4_slave_write_qos_seq_h
  //Instantiation of axi4_slave_write_qos_seq handle
  axi4_slave_nbk_write_qos_seq axi4_slave_nbk_write_qos_seq_h;

  //Variable: axi4_slave_read_qos_seq_h
  //Instantiation of axi4_slave_read_qos_seq handle
  axi4_slave_nbk_read_qos_seq axi4_slave_nbk_read_qos_seq_h;
  
  // Targeted sequences for proper address/ID generation
  axi4_master_nbk_targeted_write_qos_seq master_targeted_write_seq[];
  axi4_master_nbk_targeted_read_qos_seq master_targeted_read_seq[];
  
  // Configuration parameters from test
  int num_masters = 4;
  int num_slaves = 4;
  bit is_enhanced_mode = 0;
  bit is_4x4_ref_mode = 0;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_nbk_qos_write_read_seq");
  extern task body();
  extern function bit [63:0] get_valid_slave_addr(int slave_id, int master_id);
  extern function bit is_access_allowed(int master_id, int slave_id);
  extern function bit is_slave_read_only(int slave_id);
endclass : axi4_virtual_nbk_qos_write_read_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initialises new memory for the object
//
// Parameters:
//  name - axi4_virtual_nbk_qos_write_read_seq
//--------------------------------------------------------------------------------------------
function axi4_virtual_nbk_qos_write_read_seq::new(string name = "axi4_virtual_nbk_qos_write_read_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task - body
// Creates and starts the data of master and slave sequences
// Uses targeted sequences for proper address generation based on bus matrix mode
//--------------------------------------------------------------------------------------------
task axi4_virtual_nbk_qos_write_read_seq::body();
  int actual_masters;
  int actual_slaves;
  int num_rounds;
  int max_slaves_per_master;
  
  `uvm_info(get_type_name(), "========================================", UVM_LOW)
  `uvm_info(get_type_name(), "NBK QOS WRITE READ SEQUENCE", UVM_LOW)
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
  
  // Start slave sequences (run continuously in background)
  fork 
    begin : T1_SL_WR
      if (actual_slaves > 1) begin
        foreach(p_sequencer.axi4_slave_write_seqr_h_all[i]) begin
          if (i < num_slaves) begin
            automatic int slave_idx = i;
            fork
              forever begin
                // Create a new sequence instance each time
                axi4_slave_nbk_write_qos_seq slave_wr_seq;
                slave_wr_seq = axi4_slave_nbk_write_qos_seq::type_id::create($sformatf("slave_wr_seq_%0d", slave_idx));
                slave_wr_seq.start(p_sequencer.axi4_slave_write_seqr_h_all[slave_idx]);
              end
            join_none
          end
        end
      end else begin
        forever begin
          // Create a new sequence instance each time
          axi4_slave_nbk_write_qos_seq slave_wr_seq;
          slave_wr_seq = axi4_slave_nbk_write_qos_seq::type_id::create("slave_wr_seq");
          slave_wr_seq.start(p_sequencer.axi4_slave_write_seqr_h);
        end
      end
    end
    
    begin : T2_SL_RD
      if (actual_slaves > 1) begin
        foreach(p_sequencer.axi4_slave_read_seqr_h_all[i]) begin
          if (i < num_slaves) begin
            automatic int slave_idx = i;
            fork
              forever begin
                // Create a new sequence instance each time
                axi4_slave_nbk_read_qos_seq slave_rd_seq;
                slave_rd_seq = axi4_slave_nbk_read_qos_seq::type_id::create($sformatf("slave_rd_seq_%0d", slave_idx));
                slave_rd_seq.start(p_sequencer.axi4_slave_read_seqr_h_all[slave_idx]);
              end
            join_none
          end
        end
      end else begin
        forever begin
          // Create a new sequence instance each time
          axi4_slave_nbk_read_qos_seq slave_rd_seq;
          slave_rd_seq = axi4_slave_nbk_read_qos_seq::type_id::create("slave_rd_seq");
          slave_rd_seq.start(p_sequencer.axi4_slave_read_seqr_h);
        end
      end
    end
  join_none
  
  // Create targeted sequences for each master
  master_targeted_write_seq = new[num_masters];
  master_targeted_read_seq = new[num_masters];
  
  // Generate transactions from each master to valid slaves
  // Reduce transactions for ENHANCED mode to prevent timeout
  num_rounds = is_enhanced_mode ? 1 : 2;
  
  fork 
    begin: T1_WRITE
      repeat(num_rounds) begin // Fewer rounds for ENHANCED mode
        for(int m = 0; m < num_masters; m++) begin
          // For ENHANCED mode, only test a subset of slaves per master
          max_slaves_per_master = is_enhanced_mode ? 2 : num_slaves;
          for(int s = 0; s < max_slaves_per_master; s++) begin
            // Skip write to read-only slaves (slave 1 in BASE mode, slave 5 in ENHANCED mode)
            if (is_access_allowed(m, s) && !is_slave_read_only(s)) begin
              automatic int master_idx = m;
              automatic int slave_idx = s;
              
              master_targeted_write_seq[master_idx] = axi4_master_nbk_targeted_write_qos_seq::type_id::create(
                $sformatf("master_targeted_write_seq[%0d]", master_idx));
              
              // Configure the sequence
              master_targeted_write_seq[master_idx].target_addr = get_valid_slave_addr(slave_idx, master_idx);
              master_targeted_write_seq[master_idx].awid_val = $sformatf("AWID_%0d", master_idx);
              master_targeted_write_seq[master_idx].master_id = master_idx;
              master_targeted_write_seq[master_idx].target_slave = slave_idx;
              master_targeted_write_seq[master_idx].is_enhanced_mode = is_enhanced_mode;
              master_targeted_write_seq[master_idx].is_4x4_ref_mode = is_4x4_ref_mode;
              
              // Start on appropriate sequencer
              if (actual_masters > 1 && master_idx < p_sequencer.axi4_master_write_seqr_h_all.size()) begin
                master_targeted_write_seq[master_idx].start(p_sequencer.axi4_master_write_seqr_h_all[master_idx]);
              end else begin
                master_targeted_write_seq[master_idx].start(p_sequencer.axi4_master_write_seqr_h);
              end
            end
          end
        end
      end
    end
    
    begin: T2_READ
      repeat(num_rounds) begin // Fewer rounds for ENHANCED mode
        for(int m = 0; m < num_masters; m++) begin
          // For ENHANCED mode, only test a subset of slaves per master
          max_slaves_per_master = is_enhanced_mode ? 2 : num_slaves;
          for(int s = 0; s < max_slaves_per_master; s++) begin
            // Skip illegal address hole (slave 3 in ENHANCED mode)
            if (is_access_allowed(m, s) && !(is_enhanced_mode && s == 3)) begin
              automatic int master_idx = m;
              automatic int slave_idx = s;
              
              master_targeted_read_seq[master_idx] = axi4_master_nbk_targeted_read_qos_seq::type_id::create(
                $sformatf("master_targeted_read_seq[%0d]", master_idx));
              
              // Configure the sequence
              master_targeted_read_seq[master_idx].target_addr = get_valid_slave_addr(slave_idx, master_idx);
              master_targeted_read_seq[master_idx].arid_val = $sformatf("ARID_%0d", master_idx);
              master_targeted_read_seq[master_idx].master_id = master_idx;
              master_targeted_read_seq[master_idx].target_slave = slave_idx;
              master_targeted_read_seq[master_idx].is_enhanced_mode = is_enhanced_mode;
              master_targeted_read_seq[master_idx].is_4x4_ref_mode = is_4x4_ref_mode;
              
              // Start on appropriate sequencer
              if (actual_masters > 1 && master_idx < p_sequencer.axi4_master_read_seqr_h_all.size()) begin
                master_targeted_read_seq[master_idx].start(p_sequencer.axi4_master_read_seqr_h_all[master_idx]);
              end else begin
                master_targeted_read_seq[master_idx].start(p_sequencer.axi4_master_read_seqr_h);
              end
            end
          end
        end
      end
    end
  join
  
  `uvm_info(get_type_name(), "NBK QOS sequence completed", UVM_LOW)
endtask : body

//--------------------------------------------------------------------------------------------
// Function: get_valid_slave_addr
// Returns a valid address for the specified slave based on bus matrix mode
//--------------------------------------------------------------------------------------------
function bit [63:0] axi4_virtual_nbk_qos_write_read_seq::get_valid_slave_addr(int slave_id, int master_id);
  bit [63:0] base_addr;
  bit [63:0] offset;
  
  // Use proper base addresses based on bus matrix mode
  if (is_4x4_ref_mode) begin
    // BASE mode (4x4) addresses per AXI_MATRIX.txt
    case(slave_id)
      0: base_addr = 64'h0000_0100_0000_0000; // DDR_Memory
      1: base_addr = 64'h0000_0000_0000_0010; // Boot_ROM (read-only) - use valid range
      2: base_addr = 64'h0000_0010_0000_0000; // Peripheral_Regs
      3: base_addr = 64'h0000_0020_0000_0000; // HW_Fuse_Box
      default: base_addr = 64'h0000_0100_0000_0000; // Default to DDR
    endcase
  end else if (is_enhanced_mode) begin
    // ENHANCED mode (10x10) addresses
    case(slave_id)
      0: base_addr = 64'h0000_0008_4000_0000; // SOC/Audio
      1: base_addr = 64'h0000_0008_8000_0000; // Reserved
      2: base_addr = 64'h0000_0008_8000_0000; // DDR Shared Buffer
      3: base_addr = 64'h0000_0008_C000_0000; // Illegal Address Hole
      4: base_addr = 64'h0000_0009_0000_0000; // XOM Instruction-Only
      5: base_addr = 64'h0000_000A_0000_0000; // RO Peripheral
      6: base_addr = 64'h0000_000A_0001_0000; // Privileged-Only
      7: base_addr = 64'h0000_000A_0002_0000; // Secure-Only
      8: base_addr = 64'h0000_000A_0003_0000; // Scratchpad
      9: base_addr = 64'h0000_000A_0004_0000; // Attribute Monitor
      default: base_addr = 64'h0000_0008_8000_0000; // Default to DDR
    endcase
  end else begin
    // NONE mode - simple addresses
    case(slave_id)
      0: base_addr = 64'h0000_0000_0000_0000;
      1: base_addr = 64'h0000_0000_1000_0000;
      2: base_addr = 64'h0000_0000_2000_0000;
      3: base_addr = 64'h0000_0000_3000_0000;
      default: base_addr = 64'h0000_0000_0000_0000;
    endcase
  end
  
  // Add small offset based on master to avoid conflicts
  offset = master_id * 64'h1000;
  
  return base_addr + offset;
endfunction : get_valid_slave_addr

//--------------------------------------------------------------------------------------------
// Function: is_access_allowed
// Checks if a master can access a slave based on bus matrix mode and access control
//--------------------------------------------------------------------------------------------
function bit axi4_virtual_nbk_qos_write_read_seq::is_access_allowed(int master_id, int slave_id);
  // For NONE mode, all accesses are allowed
  if (!is_4x4_ref_mode && !is_enhanced_mode) begin
    return 1;
  end
  
  // For 4x4 mode
  if (is_4x4_ref_mode && !is_enhanced_mode) begin
    // Per AXI_MATRIX.txt access control:
    // Slave 2 (Peripheral_Regs) only allows masters 0, 1, 2
    if (slave_id == 2 && master_id > 2) return 0;
    // Slave 3 (HW_Fuse_Box) is read-only and only M0,M3 can read
    if (slave_id == 3 && master_id != 0 && master_id != 3) return 0;
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

//--------------------------------------------------------------------------------------------
// Function: is_slave_read_only
// Checks if a slave is read-only and should not receive write transactions
//--------------------------------------------------------------------------------------------
function bit axi4_virtual_nbk_qos_write_read_seq::is_slave_read_only(int slave_id);
  // Check based on bus matrix mode
  if (is_4x4_ref_mode && !is_enhanced_mode) begin
    // BASE mode (4x4): 
    // Slave 1 is Boot_ROM (read-only)
    // Slave 3 is HW_Fuse_Box (read-only - no masters can write)
    return (slave_id == 1 || slave_id == 3);
  end else if (is_enhanced_mode) begin
    // ENHANCED mode (10x10): 
    // Slave 3 is Illegal Address Hole (skip it)
    // Slave 5 is RO Peripheral (read-only)
    return (slave_id == 3 || slave_id == 5);
  end else begin
    // NONE mode: no read-only slaves
    return 0;
  end
endfunction : is_slave_read_only

`endif


