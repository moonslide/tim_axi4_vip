`ifndef AXI4_MASTER_TC_055_EXCLUSIVE_WRITE_SUCCESS_SEQ_INCLUDED_
`define AXI4_MASTER_TC_055_EXCLUSIVE_WRITE_SUCCESS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_055_exclusive_write_success_seq
// TC_055: Optional Exclusive Write Success  
// Test scenario: Send exclusive write with AWLOCK=1
// AWLOCK=1, AWADDR=0x0000_0100_0000_1250, AWLEN=0, AWSIZE=4bytes, AWID=0xD, WDATA=0xEXCL0001
// Verification: If slave supports exclusive access, expect BRESP=EXOKAY
//               If not supported, expect BRESP=OKAY (normal write)
//--------------------------------------------------------------------------------------------
class axi4_master_tc_055_exclusive_write_success_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_055_exclusive_write_success_seq)

  extern function new(string name = "axi4_master_tc_055_exclusive_write_success_seq");
  extern task body();
endclass : axi4_master_tc_055_exclusive_write_success_seq

function axi4_master_tc_055_exclusive_write_success_seq::new(string name = "axi4_master_tc_055_exclusive_write_success_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_055_exclusive_write_success_seq::body();
  
  // SETUP PHASE: Write initial data to the address (following TC_044 direct assignment pattern)
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  // Direct assignment to avoid constraint conflicts (following TC_044 pattern)
  req.tx_type = WRITE;
  req.awid = AWID_0;
  req.awaddr = 64'h0000_0100_0000_1250; // DDR Memory range
  req.awlen = 4'h0;  // 1 beat
  req.awsize = WRITE_4_BYTES;
  req.awburst = WRITE_INCR;
  req.awlock = WRITE_NORMAL_ACCESS;
  req.wdata.delete();
  req.wdata.push_back(32'hDEAD1250); // Setup data
  req.wstrb.delete();
  req.wstrb.push_back(4'hF);
  req.wuser = 4'h0;
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_055: Setup - Wrote 0x%8h to 0x%16h", 
           req.wdata[0], req.awaddr), UVM_LOW);
  
  #20; // Wait for write to complete
  
  // Step 1: Exclusive Read Transaction (required to set up exclusive monitor)
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  // Direct assignment to avoid constraint conflicts (following TC_044 pattern)
  req.tx_type = READ;
  req.arid = ARID_13;  // 0xD - same master ID
  req.araddr = 64'h0000_0100_0000_1250; // DDR Memory range - same address
  req.arlen = 4'h0;  // 1 beat
  req.arsize = READ_4_BYTES;
  req.arburst = READ_INCR;
  req.arlock = READ_EXCLUSIVE_ACCESS; // ARLOCK=1 for exclusive access
  req.aruser = 4'h0;
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_055: Sent Exclusive Read - ARID=0x%0x, ARADDR=0x%16h, ARLOCK=%0d", 
           req.arid, req.araddr, req.arlock), UVM_LOW);
  
  // Wait for exclusive read to complete and establish exclusive monitor
  #20;
  
  // Step 2: Exclusive Write Transaction (should succeed with EXOKAY)
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  // Direct assignment to avoid constraint conflicts (following TC_044 pattern)
  req.tx_type = WRITE;
  req.awid = AWID_13;  // 0xD - same master ID as exclusive read
  req.awaddr = 64'h0000_0100_0000_1250; // DDR Memory range - same address as exclusive read
  req.awlen = 4'h0;  // 1 beat
  req.awsize = WRITE_4_BYTES;
  req.awburst = WRITE_INCR;
  req.awlock = WRITE_EXCLUSIVE_ACCESS; // AWLOCK=1 for exclusive access
  req.wdata.delete();
  req.wdata.push_back(32'hECC10001); // Exclusive write data
  req.wstrb.delete();
  req.wstrb.push_back(4'hF);
  req.wuser = 4'h0;
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_055: Sent Exclusive Write - AWID=0x%0x, AWADDR=0x%16h, AWLOCK=%0d, WDATA=0x%8h", 
           req.awid, req.awaddr, req.awlock, req.wdata[0]), UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_055: Verification - Expect BRESP=EXOKAY for successful exclusive write after exclusive read"), UVM_LOW);

endtask : body

`endif