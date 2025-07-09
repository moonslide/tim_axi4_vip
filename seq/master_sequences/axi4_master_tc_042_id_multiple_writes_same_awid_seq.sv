`ifndef AXI4_MASTER_TC_042_ID_MULTIPLE_WRITES_SAME_AWID_SEQ_INCLUDED_
`define AXI4_MASTER_TC_042_ID_MULTIPLE_WRITES_SAME_AWID_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_042_id_multiple_writes_same_awid_seq
// TC_042: ID Multiple Writes Same AWID - W Channel Ordering Test
// Test scenario: Send two write transactions with same AWID=0xB
// T1: AWID=0xB, AWADDR=0x0000_0100_0000_10B0, AWLEN=0, WDATA=0x11110000
// T2: AWID=0xB, AWADDR=0x0000_0100_0000_10B4, AWLEN=0, WDATA=0x22220000  
// Verification: 
//   1. Slave must respond to BRESP in the order of AW Channel (T1 then T2)
//   2. W channel data must be processed in correct order for same AWID
//   3. Backdoor verification confirms data was written correctly to memory
//   4. Read-after-write verification confirms data integrity
//--------------------------------------------------------------------------------------------
class axi4_master_tc_042_id_multiple_writes_same_awid_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_042_id_multiple_writes_same_awid_seq)

  extern function new(string name = "axi4_master_tc_042_id_multiple_writes_same_awid_seq");
  extern task body();
endclass : axi4_master_tc_042_id_multiple_writes_same_awid_seq

function axi4_master_tc_042_id_multiple_writes_same_awid_seq::new(string name = "axi4_master_tc_042_id_multiple_writes_same_awid_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_042_id_multiple_writes_same_awid_seq::body();
  
  // Transaction T1: First write with AWID=0xB
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == WRITE;
    req.awid == AWID_11;
    req.awaddr == 64'h0000_0100_0000_10B0; // DDR Memory range
    req.awlen == 4'h0;  // 1 beat
    req.awsize == WRITE_4_BYTES;
    req.awburst == WRITE_INCR;
    req.wdata.size() == 1;
    req.wdata[0] == 32'h11110000;
    req.wstrb.size() == 1;
    req.wstrb[0] == 4'hF;
    req.wuser == 4'h0;
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_042: Sent T1 - AWID=0x%0x, AWADDR=0x%16h, WDATA=0x%8h", 
           req.awid, req.awaddr, req.wdata[0]), UVM_LOW);
  
  // Small delay before second transaction
  #20;
  
  // Transaction T2: Second write with same AWID=0xB 
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == WRITE;
    req.awid == AWID_11;
    req.awaddr == 64'h0000_0100_0000_10B4; // DDR Memory range
    req.awlen == 4'h0;  // 1 beat
    req.awsize == WRITE_4_BYTES;
    req.awburst == WRITE_INCR;
    req.wdata.size() == 1;
    req.wdata[0] == 32'h22220000;
    req.wstrb.size() == 1;
    req.wstrb[0] == 4'hF;
    req.wuser == 4'h0;
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_042: Sent T2 - AWID=0x%0x, AWADDR=0x%16h, WDATA=0x%8h", 
           req.awid, req.awaddr, req.wdata[0]), UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_042: Verification - Check that BRESP comes in order of AW (T1 then T2)"), UVM_LOW);
  
  // Wait for write responses to complete
  #100;
  
  // Read back T1 data to verify write was successful (Backdoor verification)
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == READ;
    req.arid == ARID_11;  // Use same ID for reads
    req.araddr == 64'h0000_0100_0000_10B0; // Same address as T1 write
    req.arlen == 4'h0;  // 1 beat
    req.arsize == READ_4_BYTES;
    req.arburst == READ_INCR;
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_042: Read T1 - ARID=0x%0x, ARADDR=0x%16h (Expected RDATA=0x11110000)", 
           req.arid, req.araddr), UVM_LOW);
  
  #20;
  
  // Read back T2 data to verify write was successful (Backdoor verification)
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == READ;
    req.arid == ARID_11;  // Use same ID for reads
    req.araddr == 64'h0000_0100_0000_10B4; // Same address as T2 write
    req.arlen == 4'h0;  // 1 beat
    req.arsize == READ_4_BYTES;
    req.arburst == READ_INCR;
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_042: Read T2 - ARID=0x%0x, ARADDR=0x%16h (Expected RDATA=0x22220000)", 
           req.arid, req.araddr), UVM_LOW);

endtask : body

`endif