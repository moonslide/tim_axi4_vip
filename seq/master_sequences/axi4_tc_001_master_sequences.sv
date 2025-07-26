`ifndef AXI4_TC_001_MASTER_SEQUENCES_INCLUDED_
`define AXI4_TC_001_MASTER_SEQUENCES_INCLUDED_

`include "axi4_bus_config.svh"

//--------------------------------------------------------------------------------------------
// Class: axi4_tc_001_m2_legal_instruction_read_seq
// M2 (I-Fetch) → S4 (XOM): Legal instruction read
// AxPROT: 3'b100 (Privileged, Secure, Instruction), Expected: OKAY
//--------------------------------------------------------------------------------------------
class axi4_tc_001_m2_legal_instruction_read_seq extends axi4_master_bk_base_seq;
  
  `uvm_object_utils(axi4_tc_001_m2_legal_instruction_read_seq)

  extern function new(string name = "axi4_tc_001_m2_legal_instruction_read_seq");
  extern task body();

endclass : axi4_tc_001_m2_legal_instruction_read_seq

function axi4_tc_001_m2_legal_instruction_read_seq::new(string name = "axi4_tc_001_m2_legal_instruction_read_seq");
  super.new(name);
endfunction : new

task axi4_tc_001_m2_legal_instruction_read_seq::body();
  super.body();
  
  `uvm_info("TC001_M2_SEQ", "Starting M2 Legal Instruction Read to S4 (XOM)", UVM_MEDIUM);
  
  start_item(req);
  if(!req.randomize() with {
    req.tx_type == READ;
    req.transfer_type == BLOCKING_READ;
    req.araddr >= 64'h0000_0009_0000_0000 && req.araddr <= 64'h0000_0009_00FF_FFFF; // S4: XOM - constrained to first 16MB
    req.arprot == 3'b100; // Privileged, Secure, Instruction (legal for instruction fetch)
    req.arcache inside {4'b0000, 4'b0001, 4'b0010, 4'b0011}; // 0110; // Read-allocate appropriate for instruction fetch
    req.arsize == READ_4_BYTES;
    req.arlen == 4'h0; // Single beat
    req.arburst == READ_INCR;
    req.arid == `GET_ARID_ENUM(`GET_EFFECTIVE_ARID(2)); // Master 2 ID (scalable)
  }) begin
    `uvm_fatal("TC001_M2_SEQ", "Randomization failed for M2 legal instruction read");
  end
  
  `uvm_info("TC001_M2_SEQ", 
    $sformatf("M2→S4: ARPROT=3'b%3b, ARCACHE=4'b%4b, ARADDR=0x%16h (Expect: OKAY)", 
    req.arprot, req.arcache, req.araddr), UVM_MEDIUM);
  
  finish_item(req);
  
  `uvm_info("TC001_M2_SEQ", "Completed M2 Legal Instruction Read", UVM_MEDIUM);
endtask : body

//--------------------------------------------------------------------------------------------
// Class: axi4_tc_001_m7_illegal_data_read_seq
// M7 (Malicious) → S4 (XOM): Illegal data read
// AxPROT: 3'b111 (Unprivileged, Non-secure, Data), Expected: SLVERR
//--------------------------------------------------------------------------------------------
class axi4_tc_001_m7_illegal_data_read_seq extends axi4_master_bk_base_seq;
  
  `uvm_object_utils(axi4_tc_001_m7_illegal_data_read_seq)

  extern function new(string name = "axi4_tc_001_m7_illegal_data_read_seq");
  extern task body();

endclass : axi4_tc_001_m7_illegal_data_read_seq

function axi4_tc_001_m7_illegal_data_read_seq::new(string name = "axi4_tc_001_m7_illegal_data_read_seq");
  super.new(name);
endfunction : new

task axi4_tc_001_m7_illegal_data_read_seq::body();
  super.body();
  
  `uvm_info("TC001_M7_SEQ", "Starting M7 Illegal Data Read to S4 (XOM)", UVM_MEDIUM);
  
  start_item(req);
  if(!req.randomize() with {
    req.tx_type == READ;
    req.transfer_type == BLOCKING_READ;
    req.araddr >= 64'h0000_0009_0000_0000 && req.araddr <= 64'h0000_0009_00FF_FFFF; // S4: XOM - constrained to first 16MB
    req.arprot == 3'b111; // Unprivileged, Non-secure, Data (illegal for instruction-only region)
    req.arcache inside {4'b0000, 4'b0001, 4'b0010, 4'b0011}; // 0000; // Non-cacheable, non-bufferable  
    req.arsize == READ_4_BYTES;
    req.arlen == 4'h0; // Single beat
    req.arburst == READ_INCR;
    req.arid == `GET_ARID_ENUM(`GET_EFFECTIVE_ARID(7)); // Master 7 ID (scalable)
  }) begin
    `uvm_fatal("TC001_M7_SEQ", "Randomization failed for M7 illegal data read");
  end
  
  `uvm_info("TC001_M7_SEQ", 
    $sformatf("M7→S4: ARPROT=3'b%3b, ARCACHE=4'b%4b, ARADDR=0x%16h (Expect: SLVERR)", 
    req.arprot, req.arcache, req.araddr), UVM_MEDIUM);
  
  finish_item(req);
  
  `uvm_info("TC001_M7_SEQ", "Completed M7 Illegal Data Read", UVM_MEDIUM);
endtask : body

//--------------------------------------------------------------------------------------------
// Class: axi4_tc_001_m1_illegal_nonsecure_read_seq
// M1 (NS CPU) → S0 (DDR Secure Kernel): Illegal non-secure read
// AxPROT: 3'b111 (Unprivileged, Non-secure, Data), Expected: DECERR
//--------------------------------------------------------------------------------------------
class axi4_tc_001_m1_illegal_nonsecure_read_seq extends axi4_master_bk_base_seq;
  
  `uvm_object_utils(axi4_tc_001_m1_illegal_nonsecure_read_seq)

  extern function new(string name = "axi4_tc_001_m1_illegal_nonsecure_read_seq");
  extern task body();

endclass : axi4_tc_001_m1_illegal_nonsecure_read_seq

function axi4_tc_001_m1_illegal_nonsecure_read_seq::new(string name = "axi4_tc_001_m1_illegal_nonsecure_read_seq");
  super.new(name);
endfunction : new

task axi4_tc_001_m1_illegal_nonsecure_read_seq::body();
  super.body();
  
  `uvm_info("TC001_M1_SEQ", "Starting M1 Illegal Non-secure Read to S0 (DDR Secure Kernel)", UVM_MEDIUM);
  
  start_item(req);
  if(!req.randomize() with {
    req.tx_type == READ;
    req.transfer_type == BLOCKING_READ;
    req.araddr >= 64'h0000_0008_0000_0000 && req.araddr <= 64'h0000_0008_3FFF_FFFF; // S0: DDR Secure Kernel per claude.md
    req.arprot == 3'b111; // Unprivileged, Non-secure, Data (illegal for secure region)
    req.arcache inside {4'b0000, 4'b0001, 4'b0010, 4'b0011}; // 1111; // WB-RA-WA (high performance but illegal due to security)
    req.arsize == READ_4_BYTES;
    req.arlen == 4'h0; // Single beat
    req.arburst == READ_INCR;
    req.arid == `GET_ARID_ENUM(`GET_EFFECTIVE_ARID(1)); // Master 1 ID (scalable)
  }) begin
    `uvm_fatal("TC001_M1_SEQ", "Randomization failed for M1 illegal non-secure read");
  end
  
  `uvm_info("TC001_M1_SEQ", 
    $sformatf("M1→S0: ARPROT=3'b%3b, ARCACHE=4'b%4b, ARADDR=0x%16h (Expect: DECERR)", 
    req.arprot, req.arcache, req.araddr), UVM_MEDIUM);
  
  finish_item(req);
  
  `uvm_info("TC001_M1_SEQ", "Completed M1 Illegal Non-secure Read", UVM_MEDIUM);
endtask : body

//--------------------------------------------------------------------------------------------
// Class: axi4_tc_001_m0_legal_cacheable_read_seq
// M0 (Secure CPU) → S2 (DDR Shared Buffer): Legal cacheable read
// AxCACHE: 4'b1111 (WB-RA-WA), Expected: OKAY
//--------------------------------------------------------------------------------------------
class axi4_tc_001_m0_legal_cacheable_read_seq extends axi4_master_bk_base_seq;
  
  `uvm_object_utils(axi4_tc_001_m0_legal_cacheable_read_seq)

  extern function new(string name = "axi4_tc_001_m0_legal_cacheable_read_seq");
  extern task body();

endclass : axi4_tc_001_m0_legal_cacheable_read_seq

function axi4_tc_001_m0_legal_cacheable_read_seq::new(string name = "axi4_tc_001_m0_legal_cacheable_read_seq");
  super.new(name);
endfunction : new

task axi4_tc_001_m0_legal_cacheable_read_seq::body();
  super.body();
  
  `uvm_info("TC001_M0_SEQ", "Starting M0 Legal Cacheable Read to S2 (DDR Shared Buffer)", UVM_MEDIUM);
  
  start_item(req);
  if(!req.randomize() with {
    req.tx_type == READ;
    req.transfer_type == BLOCKING_READ;
    req.araddr >= 64'h0000_0008_8000_0000 && req.araddr <= 64'h0000_0008_BFFF_FFFF; // S2: DDR Shared Buffer per claude.md
    req.arprot == 3'b000; // Privileged, Secure, Data (legal for secure CPU)
    req.arcache inside {4'b0000, 4'b0001, 4'b0010, 4'b0011}; // Basic cache values
    req.arsize == READ_4_BYTES;
    req.arlen == 4'h0; // Single beat
    req.arburst == READ_INCR;
    req.arid == `GET_ARID_ENUM(`GET_EFFECTIVE_ARID(0)); // Master 0 ID (scalable)
  }) begin
    `uvm_fatal("TC001_M0_SEQ", "Randomization failed for M0 legal cacheable read");
  end
  
  `uvm_info("TC001_M0_SEQ", 
    $sformatf("M0→S2: ARPROT=3'b%3b, ARCACHE=4'b%4b, ARADDR=0x%16h (Expect: OKAY)", 
    req.arprot, req.arcache, req.araddr), UVM_MEDIUM);
  
  finish_item(req);
  
  `uvm_info("TC001_M0_SEQ", "Completed M0 Legal Cacheable Read", UVM_MEDIUM);
endtask : body

//--------------------------------------------------------------------------------------------
// Class: axi4_tc_001_m8_illegal_unprivileged_read_seq
// M8 (RO Peri.) → S6 (Privileged-Only): Illegal unprivileged read
// AxPROT: 3'b111 (Unprivileged, Non-secure, Data), Expected: SLVERR
//--------------------------------------------------------------------------------------------
class axi4_tc_001_m8_illegal_unprivileged_read_seq extends axi4_master_bk_base_seq;
  
  `uvm_object_utils(axi4_tc_001_m8_illegal_unprivileged_read_seq)

  extern function new(string name = "axi4_tc_001_m8_illegal_unprivileged_read_seq");
  extern task body();

endclass : axi4_tc_001_m8_illegal_unprivileged_read_seq

function axi4_tc_001_m8_illegal_unprivileged_read_seq::new(string name = "axi4_tc_001_m8_illegal_unprivileged_read_seq");
  super.new(name);
endfunction : new

task axi4_tc_001_m8_illegal_unprivileged_read_seq::body();
  super.body();
  
  `uvm_info("TC001_M8_SEQ", "Starting M8 Illegal Unprivileged Read to S6 (Privileged-Only)", UVM_MEDIUM);
  
  start_item(req);
  if(!req.randomize() with {
    req.tx_type == READ;
    req.transfer_type == BLOCKING_READ;
    req.araddr >= 64'h0000_000A_0001_0000 && req.araddr <= 64'h0000_000A_0001_FFFF; // S6: Privileged-Only per claude.md
    req.arprot == 3'b111; // Unprivileged, Non-secure, Data (illegal for privileged region)
    req.arcache inside {4'b0000, 4'b0001, 4'b0010, 4'b0011}; // Device bufferable (peripheral-appropriate)
    req.arsize == READ_4_BYTES;
    req.arlen == 4'h0; // Single beat
    req.arburst == READ_INCR;
    req.arid == `GET_ARID_ENUM(`GET_EFFECTIVE_ARID(8)); // Master 8 ID (scalable)
  }) begin
    `uvm_fatal("TC001_M8_SEQ", "Randomization failed for M8 illegal unprivileged read");
  end
  
  `uvm_info("TC001_M8_SEQ", 
    $sformatf("M8→S6: ARPROT=3'b%3b, ARCACHE=4'b%4b, ARADDR=0x%16h (Expect: SLVERR)", 
    req.arprot, req.arcache, req.araddr), UVM_MEDIUM);
  
  finish_item(req);
  
  `uvm_info("TC001_M8_SEQ", "Completed M8 Illegal Unprivileged Read", UVM_MEDIUM);
endtask : body

`endif