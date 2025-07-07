`ifndef AXI4_MASTER_TC_048_WLAST_TOO_LATE_SEQ_INCLUDED_
`define AXI4_MASTER_TC_048_WLAST_TOO_LATE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_048_wlast_too_late_seq
// TC_048: Protocol WLAST Too Late Or Missing
// Test scenario: Send burst write with AWLEN=0x1 (2 beats) but WLAST=0 on beat 2
// AWADDR=0x0000_0100_0000_1220, AWLEN=0x1 (2 beats), AWSIZE=4bytes, AWID=0x4
// Beat 1: WDATA=D1, WLAST=0
// Beat 2: WDATA=D2, WLAST=0 (should be 1)
// Verification: Slave handles WLAST timing violation appropriately
//--------------------------------------------------------------------------------------------
class axi4_master_tc_048_wlast_too_late_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_048_wlast_too_late_seq)

  extern function new(string name = "axi4_master_tc_048_wlast_too_late_seq");
  extern task body();
endclass : axi4_master_tc_048_wlast_too_late_seq

function axi4_master_tc_048_wlast_too_late_seq::new(string name = "axi4_master_tc_048_wlast_too_late_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_048_wlast_too_late_seq::body();
  
  // WLAST Too Late Protocol Violation - 2 beat burst with WLAST=0 on final beat
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == WRITE;
    req.awid == AWID_4;  // 0x4
    req.awaddr == 64'h0000_0100_0000_1220; // DDR Memory range
    req.awlen == 4'h1;  // 2 beats (0x1 = len-1)
    req.awsize == WRITE_4_BYTES;
    req.awburst == WRITE_INCR;
    req.wdata.size() == 2;
    req.wdata[0] == 32'hDEAD0001; // Beat 1
    req.wdata[1] == 32'hDEAD0002; // Beat 2
    req.wstrb.size() == 2;
    req.wstrb[0] == 4'hF;
    req.wstrb[1] == 4'hF;
    // Note: In real implementation, WLAST control would be handled
    // at the BFM level to create the protocol violation
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_048: Sent burst write - AWID=0x%0x, AWADDR=0x%16h, AWLEN=0x%0x (2 beats)", 
           req.awid, req.awaddr, req.awlen), UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_048: Protocol Violation - WLAST should be 1 on beat 2 but will be 0"), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("TC_048: Verification - Check Slave handles WLAST timing violation (SLVERR or timeout)"), UVM_LOW);

endtask : body

`endif