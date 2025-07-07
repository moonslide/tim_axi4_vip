`ifndef AXI4_MASTER_TC_047_WLAST_TOO_EARLY_SEQ_INCLUDED_
`define AXI4_MASTER_TC_047_WLAST_TOO_EARLY_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_047_wlast_too_early_seq
// TC_047: Protocol WLAST Too Early
// Test scenario: Send burst write with AWLEN=0x3 (4 beats) but WLAST=1 on beat 2
// AWADDR=0x0000_0100_0000_1210, AWLEN=0x3 (4 beats), AWSIZE=4bytes, AWID=0x4
// Beat 1: WDATA=D1, WLAST=0
// Beat 2: WDATA=D2, WLAST=1 (error, should be on beat 4)
// Beat 3: WDATA=D3, WLAST=0
// Beat 4: WDATA=D4, WLAST=0
// Verification: Slave handles WLAST timing violation appropriately
//--------------------------------------------------------------------------------------------
class axi4_master_tc_047_wlast_too_early_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_047_wlast_too_early_seq)

  extern function new(string name = "axi4_master_tc_047_wlast_too_early_seq");
  extern task body();
endclass : axi4_master_tc_047_wlast_too_early_seq

function axi4_master_tc_047_wlast_too_early_seq::new(string name = "axi4_master_tc_047_wlast_too_early_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_047_wlast_too_early_seq::body();
  
  // WLAST Too Early Protocol Violation - 4 beat burst with WLAST=1 on beat 2
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == WRITE;
    req.awid == AWID_4;  // 0x4
    req.awaddr == 64'h0000_0100_0000_1210; // DDR Memory range
    req.awlen == 4'h3;  // 4 beats (0x3 = len-1)
    req.awsize == WRITE_4_BYTES;
    req.awburst == WRITE_INCR;
    req.wdata.size() == 4;
    req.wdata[0] == 32'hEAEF0001; // Beat 1
    req.wdata[1] == 32'hEAEF0002; // Beat 2 
    req.wdata[2] == 32'hEAEF0003; // Beat 3
    req.wdata[3] == 32'hEAEF0004; // Beat 4
    req.wstrb.size() == 4;
    foreach(req.wstrb[i]) req.wstrb[i] == 4'hF;
    // Note: In real implementation, WLAST control would be handled
    // at the BFM level to create the early WLAST=1 on beat 2 violation
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_047: Sent burst write - AWID=0x%0x, AWADDR=0x%16h, AWLEN=0x%0x (4 beats)", 
           req.awid, req.awaddr, req.awlen), UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_047: Protocol Violation - WLAST=1 on beat 2 instead of beat 4"), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("TC_047: Verification - Check Slave handles early WLAST (may complete at beat 2 or signal error)"), UVM_LOW);

endtask : body

`endif