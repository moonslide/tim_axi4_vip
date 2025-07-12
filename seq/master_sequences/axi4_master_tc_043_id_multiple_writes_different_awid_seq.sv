`ifndef AXI4_MASTER_TC_043_ID_MULTIPLE_WRITES_DIFFERENT_AWID_SEQ_INCLUDED_
`define AXI4_MASTER_TC_043_ID_MULTIPLE_WRITES_DIFFERENT_AWID_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_043_id_multiple_writes_different_awid_seq  
// TC_043: ID Multiple Writes Different AWID
// Test scenario: Send two write transactions with different AWID
// T1: AWID=0xC, AWADDR=0x0000_0100_0000_10C0, AWLEN=0, WDATA=D1
// T2: AWID=0xD, AWADDR=0x0000_0100_0000_10D0, AWLEN=0, WDATA=D2
// WDATA can be interleaved, BRESP can be out-of-order relative to AW
// Verification: Slave handles different AWID properly and does not deadlock
//--------------------------------------------------------------------------------------------
class axi4_master_tc_043_id_multiple_writes_different_awid_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_043_id_multiple_writes_different_awid_seq)

  extern function new(string name = "axi4_master_tc_043_id_multiple_writes_different_awid_seq");
  extern task body();
endclass : axi4_master_tc_043_id_multiple_writes_different_awid_seq

function axi4_master_tc_043_id_multiple_writes_different_awid_seq::new(string name = "axi4_master_tc_043_id_multiple_writes_different_awid_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_043_id_multiple_writes_different_awid_seq::body();
  
  // Transaction T1: First write with AWID=0xC
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  // Direct assignment to avoid constraint conflicts (following TC_044 pattern)
  req.tx_type = WRITE;
  req.awid = AWID_12;
  req.awaddr = 64'h0000_0100_0000_10C0; // DDR Memory range
  req.awlen = 4'h0;  // 1 beat
  req.awsize = WRITE_4_BYTES;
  req.awburst = WRITE_INCR;
  req.wdata.delete();
  req.wdata.push_back(32'hDEAD0001); // D1
  req.wstrb.delete();
  req.wstrb.push_back(4'hF);
  req.wuser = 4'h0;
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_043: Sent T1 - AWID=0x%0x, AWADDR=0x%16h, WDATA=0x%8h", 
           req.awid, req.awaddr, req.wdata[0]), UVM_LOW);
  
  // Small delay to avoid race condition but allow concurrent outstanding transactions
  #5;
  
  // Transaction T2: Second write with different AWID=0xD (overlapping with T1)
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  // Direct assignment to avoid constraint conflicts (following TC_044 pattern)
  req.tx_type = WRITE;
  req.awid = AWID_13;
  req.awaddr = 64'h0000_0100_0000_10D0; // DDR Memory range
  req.awlen = 4'h0;  // 1 beat
  req.awsize = WRITE_4_BYTES;
  req.awburst = WRITE_INCR;
  req.wdata.delete();
  req.wdata.push_back(32'hBEEF0002); // D2
  req.wstrb.delete();
  req.wstrb.push_back(4'hF);
  req.wuser = 4'h0;
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_043: Sent T2 - AWID=0x%0x, AWADDR=0x%16h, WDATA=0x%8h", 
           req.awid, req.awaddr, req.wdata[0]), UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_043: Verification - Check that Slave handles different AWID, allows WDATA interleaving and BRESP out-of-order"), UVM_LOW);

endtask : body

`endif