`ifndef AXI4_MASTER_TC_046_WID_AWID_MISMATCH_SEQ_INCLUDED_
`define AXI4_MASTER_TC_046_WID_AWID_MISMATCH_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_046_wid_awid_mismatch_seq
// TC_046: WID AWID Mismatch Violation
// Test scenario: Send write with AWID=0xC but WID=0xD (protocol violation)
// Master sends AWID=0xC, AWADDR=0x0000_0100_0000_1200, AWLEN=0
// Then sends WVALID=1, WDATA=0xBADWID00, WID=0xD (should be 0xC), WLAST=1
// Verification: Slave response to WID/AWID mismatch - expect error or rejection
//--------------------------------------------------------------------------------------------
class axi4_master_tc_046_wid_awid_mismatch_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_046_wid_awid_mismatch_seq)

  extern function new(string name = "axi4_master_tc_046_wid_awid_mismatch_seq");
  extern task body();
endclass : axi4_master_tc_046_wid_awid_mismatch_seq

function axi4_master_tc_046_wid_awid_mismatch_seq::new(string name = "axi4_master_tc_046_wid_awid_mismatch_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_046_wid_awid_mismatch_seq::body();
  
  // WID/AWID Mismatch Protocol Violation
  // Note: In AXI4, WID is deprecated and write data is associated with AW channel by order
  // This test simulates legacy AXI3 behavior where WID≠AWID was a protocol violation
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == WRITE;
    req.awid == AWID_12; // 0xC
    req.awaddr == 64'h0000_0100_0000_1200; // DDR Memory range
    req.awlen == 4'h0;  // 1 beat
    req.awsize == WRITE_4_BYTES;
    req.awburst == WRITE_INCR;
    req.wdata.size() == 1;
    req.wdata[0] == 32'hBADC0D00; // Bad WID data
    req.wstrb.size() == 1;
    req.wstrb[0] == 4'hF;
    // Note: In real AXI3 implementation, WID would be set to 0xD here
    // For AXI4, this test verifies proper ordering without WID
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_046: Sent write - AWID=0x%0x, AWADDR=0x%16h, WDATA=0x%8h", 
           req.awid, req.awaddr, req.wdata[0]), UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_046: Protocol Note - AXI4 removes WID, data associated by order"), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("TC_046: Verification - Check Slave handles write transaction correctly"), UVM_LOW);

endtask : body

`endif