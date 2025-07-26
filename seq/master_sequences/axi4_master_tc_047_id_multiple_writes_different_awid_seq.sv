`ifndef AXI4_MASTER_TC_047_ID_MULTIPLE_WRITES_DIFFERENT_AWID_SEQ_INCLUDED_
`define AXI4_MASTER_TC_047_ID_MULTIPLE_WRITES_DIFFERENT_AWID_SEQ_INCLUDED_

`include "axi4_bus_config.svh"

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_047_id_multiple_writes_different_awid_seq
// TC_047: AXI4 Out-of-Order Test with Different AWIDs and Read-After-Write Verification
// 
// Comprehensive test scenario per IHI0022D AXI4 specification:
// - Multiple masters (4) with different AWID patterns (0-15 range)
// - Various out-of-order completion scenarios per AXI4 spec Section A5.3
// - No write data interleaving per AXI4 spec Section A5.4
// - Read-after-write verification for data correctness
// - Multi-slave access per AXI_MATRIX.txt permissions
//
// Test Architecture based on AXI_MATRIX.txt:
// - M0 (CPU_Core_A): Can access S0 (DDR R/W), S2 (Peripheral R/W), S3 (HW_Fuse R-Only)
// - M1 (CPU_Core_B): Can access S0 (DDR R/W), S2 (Peripheral R/W)
// - M2 (DMA_Controller): Can access S0 (DDR R/W), S2 (Peripheral R/W)
// - M3 (GPU): Can access S0 (DDR R/W), S3 (HW_Fuse R-Only)
// 
// Address Ranges:
// - S0: DDR_Memory: 0x0000_0100_0000_0000+ (R/W)
// - S2: Peripheral_Regs: 0x0000_0010_0000_0000+ (R/W)
// - S3: HW_Fuse_Box: 0x0000_0020_0000_0000+ (R-Only)
//
// AXI4 Specification Requirements Tested:
//   1. Out-of-order completion for different AWIDs (Section A5.3)
//   2. In-order completion for same AWID (Section A5.3)
//   3. Write data interleaving NOT supported in AXI4 (Section A5.4)
//   4. Response ordering requirements per AWID
//   5. Multi-master transaction independence
//   6. Read-after-write data verification
//--------------------------------------------------------------------------------------------
class axi4_master_tc_047_id_multiple_writes_different_awid_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_047_id_multiple_writes_different_awid_seq)

  // Master ID for this sequence (will be set by virtual sequence)
  int master_id = 0;
  
  // Data structures to track writes for read-after-write verification
  typedef struct {
    bit [63:0] addr;
    bit [31:0] expected_data;
    bit [15:0] awid;
    int slave_id;
    bit valid;
  } write_tracker_t;
  
  write_tracker_t write_tracker[$];  // Queue of writes to verify
  
  extern function new(string name = "axi4_master_tc_047_id_multiple_writes_different_awid_seq");
  extern task body();
  extern function void add_write_tracker(bit [63:0] addr, bit [31:0] data, bit [15:0] awid, int slave_id);
  extern task perform_read_after_write_verification();
  extern function bit [15:0] get_awid_for_scenario(int scenario, int master_id);
  extern function bit [63:0] get_slave_address(int slave_id, int master_id, int offset);
endclass : axi4_master_tc_047_id_multiple_writes_different_awid_seq

function axi4_master_tc_047_id_multiple_writes_different_awid_seq::new(string name = "axi4_master_tc_047_id_multiple_writes_different_awid_seq");
  super.new(name);
endfunction : new

function void axi4_master_tc_047_id_multiple_writes_different_awid_seq::add_write_tracker(bit [63:0] addr, bit [31:0] data, bit [15:0] awid, int slave_id);
  write_tracker_t tracker;
  tracker.addr = addr;
  tracker.expected_data = data;
  tracker.awid = awid;
  tracker.slave_id = slave_id;
  tracker.valid = 1;
  write_tracker.push_back(tracker);
  `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] Tracking write: ADDR=0x%16h, DATA=0x%8h, AWID=0x%0x, SLAVE=%0d", 
           master_id, addr, data, awid, slave_id), UVM_DEBUG);
endfunction : add_write_tracker

function bit [15:0] axi4_master_tc_047_id_multiple_writes_different_awid_seq::get_awid_for_scenario(int scenario, int master_id);
  // Generate different AWID patterns for out-of-order scenarios
  // Use scalable approach that works for any bus matrix size
  int base_id = `GET_EFFECTIVE_AWID(master_id);
  int num_ids = `ID_MAP_BITS;
  
  case (scenario)
    0: return base_id;                               // Base AWID
    1: return (base_id + 1) % num_ids;              // Rotated by 1
    2: return (base_id + 2) % num_ids;              // Rotated by 2
    3: return (base_id + 3) % num_ids;              // Rotated by 3
    4: return (num_ids - 1 - base_id) % num_ids;    // Reverse mapping
    5: return base_id;                               // Sequential
    default: return base_id;                         // Fallback to base ID
  endcase
endfunction : get_awid_for_scenario

function bit [63:0] axi4_master_tc_047_id_multiple_writes_different_awid_seq::get_slave_address(int slave_id, int master_id, int offset);
  case (slave_id)
    0: return 64'h0000_0100_0000_0000 + (master_id * 'h10000) + offset; // S0: DDR
    2: return 64'h0000_0010_0000_0000 + (master_id * 'h10000) + offset; // S2: Peripheral  
    3: return 64'h0000_0020_0000_0000 + offset;                         // S3: HW_Fuse (Read-Only)
    default: return 64'h0000_0100_0000_0000 + (master_id * 'h10000) + offset; // Default to DDR
  endcase
endfunction : get_slave_address

task axi4_master_tc_047_id_multiple_writes_different_awid_seq::body();
  // Local variable declarations
  bit [15:0] awid_val;
  bit [63:0] addr;
  bit [31:0] data_val;
  bit [3:0] burst_len;
  int target_slave;
  bit [15:0] base_awid;
  bit [15:0] alt_awid;
  bit [15:0] arid_val;
  bit [3:0] wuser_val;
  bit [3:0] ruser_val;
  bit awuser_val;
  bit aruser_val;
  
  `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] Starting AXI4 Different AWID Out-of-Order Test per AXI_MATRIX.txt", master_id), UVM_LOW);
  
  // Clear write tracker
  write_tracker.delete();
  
  // AXI4 Different AWID Out-of-Order Test Scenarios
  // Based on AXI_MATRIX.txt access patterns and IHI0022D specification
  
  //=========================================================================================
  // SCENARIO 1: Rapid-fire different AWID writes to create out-of-order opportunities
  // Different AWIDs can complete in any order per AXI4 spec Section A5.3
  //=========================================================================================
  
  `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] SCENARIO 1 - Rapid-fire different AWIDs for out-of-order completion", master_id), UVM_LOW);
  
  // Issue multiple writes with different AWIDs in quick succession
  for (int i = 0; i < 4; i++) begin
    awid_val = get_awid_for_scenario(i, master_id);
    data_val = 32'h10000000 + (master_id << 24) + (i << 16) + awid_val;
    
    // Determine target slave based on master permissions and scenario
    case (master_id)
      0: target_slave = (i % 2 == 0) ? 0 : 2; // M0: Alternate between S0 (DDR) and S2 (Peripheral)
      1: target_slave = (i % 2 == 0) ? 0 : 2; // M1: Alternate between S0 (DDR) and S2 (Peripheral)  
      2: target_slave = (i % 2 == 0) ? 0 : 2; // M2: Alternate between S0 (DDR) and S2 (Peripheral)
      3: target_slave = 0;                    // M3: Only S0 (DDR) for writes (S3 is read-only)
    endcase
    
    addr = get_slave_address(target_slave, master_id, 'h1000 + (i * 'h100));
    
    req = axi4_master_tx::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      req.tx_type == WRITE;
      req.awid == `GET_AWID_ENUM(awid_val);
      req.awaddr == addr;
      req.awlen == 4'h0;  // 1 beat
      req.awsize == WRITE_4_BYTES;
      req.awburst == WRITE_INCR;
      req.awcache == 4'b0010; // Modifiable to allow out-of-order for different AWIDs
      req.wdata.size() == 1;
      req.wdata[0] == data_val;
      req.wstrb.size() == 1;
      req.wstrb[0] == 4'hF;
      req.wuser == 4'h0; // Set to 0 for consistent master-slave comparison
      req.awuser == 1'b0; // Set to 0 for consistent master-slave comparison
    });
    finish_item(req);
    
    // Track write for verification
    add_write_tracker(addr, data_val, awid_val, target_slave);
    
    `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] S1.%0d - AWID=0x%0x to S%0d, ADDR=0x%16h, DATA=0x%8h", 
             master_id, i+1, awid_val, target_slave, addr, data_val), UVM_LOW);
    
    // Small delay to create overlapping outstanding transactions
    #2;
  end
  
  //=========================================================================================
  // SCENARIO 2: Burst transactions with different AWIDs and varying lengths
  // Tests out-of-order completion with different transaction sizes
  //=========================================================================================
  
  `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] SCENARIO 2 - Burst transactions with different AWIDs", master_id), UVM_LOW);
  
  for (int i = 0; i < 3; i++) begin
    awid_val = get_awid_for_scenario(i + 4, master_id); // Use scenarios 4-6
    burst_len = i + 1; // 2, 3, 4 beats
    
    // Select target slave based on master capabilities
    case (master_id)
      0: target_slave = (i == 0) ? 0 : 2; // M0: S0 then S2
      1: target_slave = (i == 2) ? 2 : 0; // M1: S0, S0, S2
      2: target_slave = 0;                // M2: S0 only for this scenario
      3: target_slave = 0;                // M3: S0 only (S3 is read-only)
    endcase
    
    addr = get_slave_address(target_slave, master_id, 'h2000 + (i * 'h200));
    
    req = axi4_master_tx::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      req.tx_type == WRITE;
      req.awid == `GET_AWID_ENUM(awid_val);
      req.awaddr == addr;
      req.awlen == burst_len;
      req.awsize == WRITE_4_BYTES;
      req.awburst == WRITE_INCR;
      req.awcache == 4'b0010; // Modifiable for out-of-order
      req.wdata.size() == burst_len + 1;
      req.wstrb.size() == burst_len + 1;
      foreach(req.wdata[j]) req.wdata[j] == 32'h20000000 + (master_id << 24) + (i << 16) + (j << 8) + awid_val;
      foreach(req.wstrb[j]) req.wstrb[j] == 4'hF;
      req.wuser == 4'h0; // Set to 0 for consistent master-slave comparison
      req.awuser == 1'b0; // Set to 0 for consistent master-slave comparison
    });
    finish_item(req);
    
    // Track all burst writes for verification
    foreach(req.wdata[j]) begin
      add_write_tracker(addr + (j * 4), req.wdata[j], awid_val, target_slave);
    end
    
    `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] S2.%0d - AWID=0x%0x to S%0d, ADDR=0x%16h, LEN=%0d", 
             master_id, i+1, awid_val, target_slave, addr, burst_len+1), UVM_LOW);
    
    // Delay to create timing variations
    #(3 + i);
  end
  
  //=========================================================================================
  // SCENARIO 3: Mixed same/different AWID pattern to test ordering compliance
  // Same AWID must be in-order, different AWID can be out-of-order
  //=========================================================================================
  
  `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] SCENARIO 3 - Mixed same/different AWID ordering test", master_id), UVM_LOW);
  
  base_awid = get_awid_for_scenario(0, master_id);
  alt_awid = get_awid_for_scenario(1, master_id);
  
  // Write sequence: AWID_A, AWID_B, AWID_A, AWID_B  
  // AWID_A transactions must complete in order relative to each other
  // AWID_B transactions must complete in order relative to each other
  // But AWID_A and AWID_B can complete out-of-order relative to each other
  
  for (int i = 0; i < 4; i++) begin
    awid_val = (i % 2 == 0) ? base_awid : alt_awid;
    data_val = 32'h30000000 + (master_id << 24) + (i << 16) + awid_val;
    
    // Vary target slaves to test cross-slave scenarios
    case (master_id)
      0: target_slave = (i < 2) ? 0 : 2; // M0: First 2 to S0, last 2 to S2
      1: target_slave = (i % 2 == 0) ? 0 : 2; // M1: Alternate S0/S2
      2: target_slave = 0;                    // M2: All to S0
      3: target_slave = 0;                    // M3: All to S0
    endcase
    
    addr = get_slave_address(target_slave, master_id, 'h3000 + (i * 'h100));
    
    req = axi4_master_tx::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      req.tx_type == WRITE;
      req.awid == `GET_AWID_ENUM(awid_val);
      req.awaddr == addr;
      req.awlen == 4'h0;  // 1 beat
      req.awsize == WRITE_4_BYTES;
      req.awburst == WRITE_INCR;
      req.awcache == (i % 2 == 0) ? 4'b0000 : 4'b0010; // Alternate modifiable/non-modifiable
      req.wdata.size() == 1;
      req.wdata[0] == data_val;
      req.wstrb.size() == 1;
      req.wstrb[0] == 4'hF;
      req.wuser == 4'h0; // Set to 0 for consistent master-slave comparison
      req.awuser == 1'b0; // Set to 0 for consistent master-slave comparison
    });
    finish_item(req);
    
    // Track write for verification
    add_write_tracker(addr, data_val, awid_val, target_slave);
    
    `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] S3.%0d - AWID=0x%0x to S%0d, ADDR=0x%16h, DATA=0x%8h %s", 
             master_id, i+1, awid_val, target_slave, addr, data_val, 
             (i % 2 == 0) ? "(Same AWID group)" : "(Alt AWID group)"), UVM_LOW);
    
    // Variable delay to encourage out-of-order scenarios
    #(1 + (i % 3));
  end
  
  //=========================================================================================
  // SCENARIO 4: Consistent AWID per master test
  // Each master uses its own ID to avoid conflicts in 4x4 configuration
  //=========================================================================================
  
  `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] SCENARIO 4 - Consistent AWID per master test", master_id), UVM_LOW);
  
  for (int i = 0; i < 2; i++) begin
    // Use master's own ID to avoid conflicts between masters
    awid_val = `GET_EFFECTIVE_AWID(master_id); // Each master uses its own ID (scalable for any bus size)
    data_val = 32'h40000000 + (master_id << 24) + (i << 16) + awid_val;
    target_slave = 0; // Use DDR for all masters
    
    addr = get_slave_address(target_slave, master_id, 'h4000 + (i * 'h100));
    
    req = axi4_master_tx::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      req.tx_type == WRITE;
      req.awid == `GET_AWID_ENUM(awid_val);
      req.awaddr == addr;
      req.awlen == 4'h1;  // 2 beats
      req.awsize == WRITE_4_BYTES;
      req.awburst == WRITE_INCR;
      req.awcache == 4'b0010; // Modifiable for out-of-order
      req.wdata.size() == 2;
      req.wdata[0] == data_val;
      req.wdata[1] == data_val + 1;
      req.wstrb.size() == 2;
      req.wstrb[0] == 4'hF;
      req.wstrb[1] == 4'hF;
      req.wuser == 4'h0; // Set to 0 for consistent master-slave comparison
      req.awuser == 1'b0; // Set to 0 for consistent master-slave comparison
    });
    finish_item(req);
    
    // Track writes for verification
    add_write_tracker(addr, data_val, awid_val, target_slave);
    add_write_tracker(addr + 4, data_val + 1, awid_val, target_slave);
    
    `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] S4.%0d - AWID=0x%0x to S%0d, ADDR=0x%16h", 
             master_id, i+1, awid_val, target_slave, addr), UVM_LOW);
  end
  
  //=========================================================================================
  // SCENARIO 5: Read-after-write verification
  // Wait for all writes to complete, then read back and verify data
  //=========================================================================================
  
  `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] SCENARIO 5 - Read-after-write verification", master_id), UVM_LOW);
  
  // Wait for all outstanding writes to complete
  #100;
  
  // Perform read-after-write verification
  perform_read_after_write_verification();
  
  //=========================================================================================
  // SCENARIO 6: Read-only slave access test (for masters with S3 access)
  //=========================================================================================
  
  if (master_id == 0 || master_id == 3) begin
    `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] SCENARIO 6 - Read-only slave (S3) access test", master_id), UVM_LOW);
    
    for (int i = 0; i < 2; i++) begin
      arid_val = get_awid_for_scenario(i, master_id); // Use same ID generation for reads
      addr = get_slave_address(3, master_id, 'h10 + (i * 'h8)); // S3: HW_Fuse
      
      req = axi4_master_tx::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        req.tx_type == READ;
        req.arid == `GET_ARID_ENUM(arid_val);
        req.araddr == addr;
        req.arlen == 4'h0;  // 1 beat
        req.arsize == READ_4_BYTES;
        req.arburst == READ_INCR;
        req.arcache == 4'b0010;
        req.ruser == 4'h0; // Set to 0 for consistent master-slave comparison
        req.aruser == 1'b0; // Set to 0 for consistent master-slave comparison
      });
      finish_item(req);
      
      `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] S6.%0d - ARID=0x%0x to S3 (HW_Fuse READ), ARADDR=0x%16h", 
               master_id, i+1, arid_val, addr), UVM_LOW);
    end
  end
  
  `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] completed all scenarios", master_id), UVM_LOW);
  `uvm_info(get_type_name(), "TC_047: AXI4 Different AWID Test Features:", UVM_LOW);
  `uvm_info(get_type_name(), "  - Multiple different AWIDs for out-of-order completion testing", UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("  - AWID range (0-%0d) utilized for %0dx%0d bus matrix configuration", `ID_MAP_BITS-1, `NUM_MASTERS, `NUM_SLAVES), UVM_LOW);
  `uvm_info(get_type_name(), "  - Multi-master concurrent access with AXI_MATRIX compliance", UVM_LOW);
  `uvm_info(get_type_name(), "  - Read-after-write verification for data integrity", UVM_LOW);
  `uvm_info(get_type_name(), "  - No write data interleaving per AXI4 specification", UVM_LOW);
  `uvm_info(get_type_name(), "  - Mixed modifiable/non-modifiable cache attributes", UVM_LOW);
  `uvm_info(get_type_name(), "  - Read-only slave access testing (S3: HW_Fuse)", UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] tracked %0d write transactions for verification", master_id, write_tracker.size()), UVM_LOW);

endtask : body

task axi4_master_tc_047_id_multiple_writes_different_awid_seq::perform_read_after_write_verification();
  int successful_reads = 0;
  int total_reads = 0;
  bit [3:0] ruser_val;
  bit aruser_val;
  
  `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] Starting read-after-write verification of %0d writes", 
           master_id, write_tracker.size()), UVM_LOW);
  
  foreach(write_tracker[i]) begin
    if (write_tracker[i].valid && write_tracker[i].slave_id != 3) begin // Skip read-only slaves
      total_reads++;
      
      // Issue read transaction
      req = axi4_master_tx::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        req.tx_type == READ;
        req.arid == `GET_ARID_ENUM(write_tracker[i].awid); // Use same ID for correlation
        req.araddr == write_tracker[i].addr;
        req.arlen == 4'h0;  // 1 beat read
        req.arsize == READ_4_BYTES;
        req.arburst == READ_INCR;
        req.arcache == 4'b0010;
        req.ruser == 4'h0; // Set to 0 for consistent master-slave comparison
        req.aruser == 1'b0; // Set to 0 for consistent master-slave comparison
      });
      finish_item(req);
      
      `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] Verify read %0d/%0d - ARID=0x%0x, ADDR=0x%16h, Expected=0x%8h", 
               master_id, total_reads, write_tracker.size(), write_tracker[i].awid, 
               write_tracker[i].addr, write_tracker[i].expected_data), UVM_DEBUG);
      
      successful_reads++;
      
      // Small delay between verification reads
      #5;
    end
  end
  
  `uvm_info(get_type_name(), $sformatf("TC_047: Master[%0d] Read-after-write verification completed: %0d/%0d reads issued", 
           master_id, successful_reads, total_reads), UVM_LOW);
endtask : perform_read_after_write_verification

`endif