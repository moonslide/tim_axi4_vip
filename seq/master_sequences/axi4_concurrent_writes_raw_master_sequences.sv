`ifndef AXI4_CONCURRENT_WRITES_RAW_MASTER_SEQUENCES_INCLUDED_
`define AXI4_CONCURRENT_WRITES_RAW_MASTER_SEQUENCES_INCLUDED_

`include "axi4_bus_config.svh"

//--------------------------------------------------------------------------------------------
// Class: axi4_concurrent_writes_raw_m0_legal_secure_write_seq
// M0 (Secure CPU) → S0 (DDR Secure Kernel): Legal secure & privileged write
// AWPROT: 3'b000 (Privileged, Secure, Data), Expected: OKAY
//--------------------------------------------------------------------------------------------
class axi4_concurrent_writes_raw_m0_legal_secure_write_seq extends axi4_master_bk_base_seq;
  
  `uvm_object_utils(axi4_concurrent_writes_raw_m0_legal_secure_write_seq)
  
  bit [63:0] write_address; // Store for read-after-write
  bit [31:0] write_data;    // Store write data for verification

  extern function new(string name = "axi4_concurrent_writes_raw_m0_legal_secure_write_seq");
  extern task body();

endclass : axi4_concurrent_writes_raw_m0_legal_secure_write_seq

function axi4_concurrent_writes_raw_m0_legal_secure_write_seq::new(string name = "axi4_concurrent_writes_raw_m0_legal_secure_write_seq");
  super.new(name);
endfunction : new

task axi4_concurrent_writes_raw_m0_legal_secure_write_seq::body();
  super.body();
  
  `uvm_info("TC002_M0_WRITE", "Starting M0 Legal Secure Write to S0 (DDR Secure Kernel)", UVM_MEDIUM);
  
  start_item(req);
  if(!req.randomize() with {
    req.tx_type == WRITE;
    req.transfer_type == BLOCKING_WRITE;
    req.awaddr >= 64'h0000_0008_0000_0000 && req.awaddr <= 64'h0000_0008_3FFF_FFFF; // S0: DDR Secure Kernel per claude.md
    req.awprot == 3'b000; // Privileged, Secure, Data (legal for secure CPU)
    req.awcache inside {4'b0000, 4'b0001, 4'b0010, 4'b0011}; // WB-RA-WA (high performance cacheable)
    req.awsize == WRITE_4_BYTES;
    req.awlen == 4'h0; // Single beat
    req.awburst == WRITE_INCR;
    req.awid == `GET_AWID_ENUM(`GET_EFFECTIVE_AWID(0)); // Master 0 ID (scalable)
    req.wdata.size() == 1;
    req.wstrb.size() == 1;
    foreach(req.wstrb[i]) req.wstrb[i] == 4'hF; // All bytes valid
  }) begin
    `uvm_fatal("TC002_M0_WRITE", "Randomization failed for M0 legal secure write");
  end
  
  write_address = req.awaddr; // Store for potential read-after-write
  write_data = req.wdata[0]; // Store write data for verification
  
  `uvm_info("TC002_M0_WRITE", 
    $sformatf("M0→S0: AWPROT=3'b%3b, AWCACHE=4'b%4b, AWADDR=0x%16h, WDATA=0x%08h (Expect: OKAY)", 
    req.awprot, req.awcache, req.awaddr, req.wdata[0]), UVM_MEDIUM);
  
  finish_item(req);
  
  `uvm_info("TC002_M0_WRITE", "Completed M0 Legal Secure Write", UVM_MEDIUM);
endtask : body

//--------------------------------------------------------------------------------------------
// Class: axi4_concurrent_writes_raw_m0_raw_read_seq
// M0 Read-After-Write verification: Read from same address after successful write
// Expected: OKAY (legal secure read)
//--------------------------------------------------------------------------------------------
class axi4_concurrent_writes_raw_m0_raw_read_seq extends axi4_master_bk_base_seq;
  
  `uvm_object_utils(axi4_concurrent_writes_raw_m0_raw_read_seq)
  
  bit [63:0] target_address; // Address to read from

  extern function new(string name = "axi4_concurrent_writes_raw_m0_raw_read_seq");
  extern task body();

endclass : axi4_concurrent_writes_raw_m0_raw_read_seq

function axi4_concurrent_writes_raw_m0_raw_read_seq::new(string name = "axi4_concurrent_writes_raw_m0_raw_read_seq");
  super.new(name);
endfunction : new

task axi4_concurrent_writes_raw_m0_raw_read_seq::body();
  super.body();
  
  `uvm_info("TC002_M0_RAW", $sformatf("Starting M0 Read-After-Write verification from address 0x%16h", target_address), UVM_MEDIUM);
  
  start_item(req);
  if(!req.randomize() with {
    req.tx_type == READ;
    req.transfer_type == BLOCKING_READ;
    req.araddr == target_address; // Read from same address as write
    req.arprot == 3'b000; // Privileged, Secure, Data (legal for secure CPU)
    req.arcache inside {4'b0000, 4'b0001, 4'b0010, 4'b0011}; // WB-RA-WA (match write cache attributes)
    req.arsize == READ_4_BYTES;
    req.arlen == 4'h0; // Single beat
    req.arburst == READ_INCR;
    req.arid == `GET_ARID_ENUM(`GET_EFFECTIVE_ARID(0)); // Master 0 ID (scalable)
  }) begin
    `uvm_fatal("TC002_M0_RAW", "Randomization failed for M0 read-after-write");
  end
  
  `uvm_info("TC002_M0_RAW", 
    $sformatf("M0→S0 RAW: ARPROT=3'b%3b, ARADDR=0x%16h (Expect: OKAY)", 
    req.arprot, req.araddr), UVM_MEDIUM);
  
  finish_item(req);
  
  `uvm_info("TC002_M0_RAW", "Completed M0 Read-After-Write verification", UVM_MEDIUM);
endtask : body

//--------------------------------------------------------------------------------------------
// Class: axi4_concurrent_writes_raw_m3_illegal_ro_write_seq
// M3 (GPU) → S5 (RO Peripheral): Illegal write to read-only region
// AWPROT: 3'b111 (Unprivileged, Non-secure, Data), Expected: SLVERR
//--------------------------------------------------------------------------------------------
class axi4_concurrent_writes_raw_m3_illegal_ro_write_seq extends axi4_master_bk_base_seq;
  
  `uvm_object_utils(axi4_concurrent_writes_raw_m3_illegal_ro_write_seq)

  extern function new(string name = "axi4_concurrent_writes_raw_m3_illegal_ro_write_seq");
  extern task body();

endclass : axi4_concurrent_writes_raw_m3_illegal_ro_write_seq

function axi4_concurrent_writes_raw_m3_illegal_ro_write_seq::new(string name = "axi4_concurrent_writes_raw_m3_illegal_ro_write_seq");
  super.new(name);
endfunction : new

task axi4_concurrent_writes_raw_m3_illegal_ro_write_seq::body();
  super.body();
  
  `uvm_info("TC002_M3_WRITE", "Starting M3 Illegal Write to S5 (RO Peripheral)", UVM_MEDIUM);
  
  start_item(req);
  if(!req.randomize() with {
    req.tx_type == WRITE;
    req.transfer_type == BLOCKING_WRITE;
    req.awaddr >= 64'h0000_000A_0000_0000 && req.awaddr <= 64'h0000_000A_0000_FFFF; // S5: RO Peripheral per claude.md
    req.awprot == 3'b111; // Unprivileged, Non-secure, Data (standard GPU access)
    req.awcache inside {4'b0000, 4'b0001, 4'b0010, 4'b0011}; // WB-RA-WA (high performance but irrelevant due to error)
    req.awsize == WRITE_4_BYTES;
    req.awlen == 4'h0; // Single beat
    req.awburst == WRITE_INCR;
    req.awid == `GET_AWID_ENUM(`GET_EFFECTIVE_AWID(3)); // Master 3 ID (scalable)
    req.wdata.size() == 1;
    req.wstrb.size() == 1;
    foreach(req.wstrb[i]) req.wstrb[i] == 4'hF; // All bytes valid
  }) begin
    `uvm_fatal("TC002_M3_WRITE", "Randomization failed for M3 illegal RO write");
  end
  
  `uvm_info("TC002_M3_WRITE", 
    $sformatf("M3→S5: AWPROT=3'b%3b, AWCACHE=4'b%4b, AWADDR=0x%16h (Expect: SLVERR)", 
    req.awprot, req.awcache, req.awaddr), UVM_MEDIUM);
  
  finish_item(req);
  
  `uvm_info("TC002_M3_WRITE", "Completed M3 Illegal RO Write", UVM_MEDIUM);
endtask : body

//--------------------------------------------------------------------------------------------
// Class: axi4_concurrent_writes_raw_m6_illegal_hole_write_seq
// M6 (DMA-NS) → S3 (Illegal Address Hole): Illegal write to address hole
// AWPROT: 3'b110 (Privileged, Non-secure, Data), Expected: DECERR
//--------------------------------------------------------------------------------------------
class axi4_concurrent_writes_raw_m6_illegal_hole_write_seq extends axi4_master_bk_base_seq;
  
  `uvm_object_utils(axi4_concurrent_writes_raw_m6_illegal_hole_write_seq)

  extern function new(string name = "axi4_concurrent_writes_raw_m6_illegal_hole_write_seq");
  extern task body();

endclass : axi4_concurrent_writes_raw_m6_illegal_hole_write_seq

function axi4_concurrent_writes_raw_m6_illegal_hole_write_seq::new(string name = "axi4_concurrent_writes_raw_m6_illegal_hole_write_seq");
  super.new(name);
endfunction : new

task axi4_concurrent_writes_raw_m6_illegal_hole_write_seq::body();
  super.body();
  
  `uvm_info("TC002_M6_WRITE", "Starting M6 Illegal Write to S3 (Illegal Address Hole)", UVM_MEDIUM);
  
  start_item(req);
  if(!req.randomize() with {
    req.tx_type == WRITE;
    req.transfer_type == BLOCKING_WRITE;
    req.awaddr >= 64'h0000_0008_C000_0000 && req.awaddr <= 64'h0000_0008_FFFF_FFFF; // S3: Illegal Address Hole per claude.md
    req.awprot == 3'b110; // Privileged, Non-secure, Data (DMA-NS profile)
    req.awcache inside {4'b0000, 4'b0001, 4'b0010, 4'b0011}; // Cacheable (DMA appropriate)
    req.awsize == WRITE_4_BYTES;
    req.awlen == 4'h0; // Single beat
    req.awburst == WRITE_INCR;
    req.awid == `GET_AWID_ENUM(`GET_EFFECTIVE_AWID(6)); // Master 6 ID (scalable)
    req.wdata.size() == 1;
    req.wstrb.size() == 1;
    foreach(req.wstrb[i]) req.wstrb[i] == 4'hF; // All bytes valid
  }) begin
    `uvm_fatal("TC002_M6_WRITE", "Randomization failed for M6 illegal hole write");
  end
  
  `uvm_info("TC002_M6_WRITE", 
    $sformatf("M6→S3: AWPROT=3'b%3b, AWCACHE=4'b%4b, AWADDR=0x%16h (Expect: DECERR)", 
    req.awprot, req.awcache, req.awaddr), UVM_MEDIUM);
  
  finish_item(req);
  
  `uvm_info("TC002_M6_WRITE", "Completed M6 Illegal Address Hole Write", UVM_MEDIUM);
endtask : body

//--------------------------------------------------------------------------------------------
// Class: axi4_concurrent_writes_raw_m9_legal_monitor_write_seq
// M9 (Legacy) → S9 (Attribute Monitor): Legal write to monitor region
// AWPROT: 3'b110 (Privileged, Non-secure, Data), Expected: OKAY
//--------------------------------------------------------------------------------------------
class axi4_concurrent_writes_raw_m9_legal_monitor_write_seq extends axi4_master_bk_base_seq;
  
  `uvm_object_utils(axi4_concurrent_writes_raw_m9_legal_monitor_write_seq)
  
  bit [63:0] write_address; // Store for read-after-write
  bit [31:0] write_data; // Store write data for backdoor verification

  extern function new(string name = "axi4_concurrent_writes_raw_m9_legal_monitor_write_seq");
  extern task body();

endclass : axi4_concurrent_writes_raw_m9_legal_monitor_write_seq

function axi4_concurrent_writes_raw_m9_legal_monitor_write_seq::new(string name = "axi4_concurrent_writes_raw_m9_legal_monitor_write_seq");
  super.new(name);
endfunction : new

task axi4_concurrent_writes_raw_m9_legal_monitor_write_seq::body();
  super.body();
  
  `uvm_info("TC002_M9_WRITE", "Starting M9 Legal Write to S9 (Attribute Monitor)", UVM_MEDIUM);
  
  start_item(req);
  if(!req.randomize() with {
    req.tx_type == WRITE;
    req.transfer_type == BLOCKING_WRITE;
    req.awaddr >= 64'h0000_000A_0004_0000 && req.awaddr <= 64'h0000_000A_0004_FFFF; // S9: Attribute Monitor per claude.md
    req.awprot == 3'b110; // Privileged, Non-secure, Data (legacy master profile)
    req.awcache inside {4'b0000, 4'b0001, 4'b0010, 4'b0011}; // Device non-bufferable (legacy/non-cacheable)
    req.awsize == WRITE_4_BYTES;
    req.awlen == 4'h0; // Single beat
    req.awburst == WRITE_INCR;
    req.awid == `GET_AWID_ENUM(`GET_EFFECTIVE_AWID(9)); // Master 9 ID (scalable)
    req.wdata.size() == 1;
    req.wstrb.size() == 1;
    // For 32-bit write, only set 4 strobe bits at byte offset 0 within the beat
    foreach(req.wstrb[i]) req.wstrb[i] == ((i == 0) ? 128'hF : 128'h0);
  }) begin
    `uvm_fatal("TC002_M9_WRITE", "Randomization failed for M9 legal monitor write");
  end
  
  write_address = req.awaddr; // Store for potential read-after-write
  
  // For narrow transfer on wide bus, data should be at correct byte lanes
  // Calculate byte offset and extract the 32-bit data from correct position
  begin
    int byte_offset = req.awaddr[6:0]; // Byte offset within 128-byte data
    write_data = req.wdata[0][(byte_offset*8) +: 32]; // Extract 32 bits from correct offset
  end
  
  `uvm_info("TC002_M9_WRITE", 
    $sformatf("M9→S9: AWPROT=3'b%3b, AWCACHE=4'b%4b, AWADDR=0x%16h, WDATA=0x%08h (Expect: OKAY)", 
    req.awprot, req.awcache, req.awaddr, write_data), UVM_MEDIUM);
  
  finish_item(req);
  
  `uvm_info("TC002_M9_WRITE", "Completed M9 Legal Monitor Write", UVM_MEDIUM);
endtask : body

//--------------------------------------------------------------------------------------------
// Class: axi4_concurrent_writes_raw_m9_raw_illegal_read_seq
// M9 Read-After-Write: Read from S9 (Attribute Monitor) after successful write
// Expected: SLVERR (S9 is write-only, reads should fail)
//--------------------------------------------------------------------------------------------
class axi4_concurrent_writes_raw_m9_raw_illegal_read_seq extends axi4_master_bk_base_seq;
  
  `uvm_object_utils(axi4_concurrent_writes_raw_m9_raw_illegal_read_seq)
  
  bit [63:0] target_address; // Address to read from

  extern function new(string name = "axi4_concurrent_writes_raw_m9_raw_illegal_read_seq");
  extern task body();

endclass : axi4_concurrent_writes_raw_m9_raw_illegal_read_seq

function axi4_concurrent_writes_raw_m9_raw_illegal_read_seq::new(string name = "axi4_concurrent_writes_raw_m9_raw_illegal_read_seq");
  super.new(name);
endfunction : new

task axi4_concurrent_writes_raw_m9_raw_illegal_read_seq::body();
  super.body();
  
  `uvm_info("TC002_M9_RAW", "Starting M9 Read-After-Write (Should Fail)", UVM_MEDIUM);
  
  start_item(req);
  if(!req.randomize() with {
    req.tx_type == READ;
    req.transfer_type == BLOCKING_READ;
    req.araddr == target_address; // Read from same address as write
    req.arprot == 3'b110; // Privileged, Non-secure, Data (same as write)
    req.arcache inside {4'b0000, 4'b0001, 4'b0010, 4'b0011}; // Device non-bufferable (legacy profile)
    req.arsize == READ_4_BYTES;
    req.arlen == 4'h0; // Single beat
    req.arburst == READ_INCR;
    req.arid == `GET_ARID_ENUM(`GET_EFFECTIVE_ARID(9)); // Master 9 ID (scalable)
  }) begin
    `uvm_fatal("TC002_M9_RAW", "Randomization failed for M9 read-after-write");
  end
  
  `uvm_info("TC002_M9_RAW", 
    $sformatf("M9→S9 RAW: ARPROT=3'b%3b, ARADDR=0x%16h (Expect: SLVERR - Write-only region)", 
    req.arprot, req.araddr), UVM_MEDIUM);
  
  finish_item(req);
  
  `uvm_info("TC002_M9_RAW", "Completed M9 Read-After-Write (Should have failed)", UVM_MEDIUM);
endtask : body

`endif