`ifndef AXI4_MASTER_TC_050_WID_AWID_MISMATCH_SEQ_INCLUDED_
`define AXI4_MASTER_TC_050_WID_AWID_MISMATCH_SEQ_INCLUDED_

`include "axi4_bus_config.svh"

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_050_wid_awid_mismatch_seq
// TC_050: WID AWID Mismatch Violation (Scalable)
// Test scenario: Send write with AWID=scalable_id_12 (0xC for 4x4)
// Note: AXI4 removes WID, this tests legacy AXI3 behavior simulation
// Master sends AWID=scalable_id, AWADDR=0x0000_0100_0000_1200, AWLEN=0
// Verification: Check proper AXI4 write handling (WID removed in AXI4)
// Scalable: Works with 4x4 to 64x64+ bus configurations
//--------------------------------------------------------------------------------------------
class axi4_master_tc_050_wid_awid_mismatch_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_050_wid_awid_mismatch_seq)

  extern function new(string name = "axi4_master_tc_050_wid_awid_mismatch_seq");
  extern task body();
endclass : axi4_master_tc_050_wid_awid_mismatch_seq

function axi4_master_tc_050_wid_awid_mismatch_seq::new(string name = "axi4_master_tc_050_wid_awid_mismatch_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_050_wid_awid_mismatch_seq::body();
  
  // WID/AWID Mismatch Protocol Violation
  // Note: In AXI4, WID is deprecated and write data is associated with AW channel by order
  // This test simulates legacy AXI3 behavior where WID≠AWID was a protocol violation
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == WRITE;
    req.awid == `GET_AWID_ENUM(12 % `ID_MAP_BITS); // Scalable AWID (0xC for 4x4)
    req.awaddr == 64'h0000_0100_0000_1200; // DDR Memory range
    req.awlen == 4'h0;  // 1 beat
    req.awsize == WRITE_4_BYTES;
    req.awburst == WRITE_INCR;
    req.awprot == WRITE_NORMAL_NONSECURE_DATA; // Explicitly set for DDR access
    req.wdata.size() == 1;
    req.wdata[0] == 32'hBADC0D00; // Bad WID data
    req.wstrb.size() == 1;
    req.wstrb[0] == 4'hF;
    req.wuser == 4'h0; // Add wuser constraint
    // Note: In real AXI3 implementation, WID would be set to 0xD here
    // For AXI4, this test verifies proper ordering without WID
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_050: Sent write - AWID=0x%0x, AWADDR=0x%16h, WDATA=0x%8h", 
           req.awid, req.awaddr, req.wdata[0]), UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_050: Protocol Note - AXI4 removes WID, data associated by order"), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("TC_050: Verification - Check Slave handles write transaction correctly"), UVM_LOW);

endtask : body

`endif