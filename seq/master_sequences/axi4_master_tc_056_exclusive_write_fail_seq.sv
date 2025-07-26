`ifndef AXI4_MASTER_TC_056_EXCLUSIVE_WRITE_FAIL_SEQ_INCLUDED_
`define AXI4_MASTER_TC_056_EXCLUSIVE_WRITE_FAIL_SEQ_INCLUDED_

`include "axi4_bus_config.svh"

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_056_exclusive_write_fail_seq
// TC_056: Optional Exclusive Write Fail
// Test scenario: Send exclusive write when exclusive monitor has been invalidated
// AWLOCK=1, AWADDR=0x0000_0100_0000_1250, AWLEN=0, AWSIZE=4bytes, AWID=0xD, WDATA=0xFAIL0001
// Precondition: Exclusive monitor for 0x1250 has been cleared/invalidated
// Verification: If slave supports exclusive access, expect BRESP=OKAY (not EXOKAY)
//               Indicating exclusive access failed due to monitor invalidation
//--------------------------------------------------------------------------------------------
class axi4_master_tc_056_exclusive_write_fail_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_056_exclusive_write_fail_seq)

  extern function new(string name = "axi4_master_tc_056_exclusive_write_fail_seq");
  extern task body();
endclass : axi4_master_tc_056_exclusive_write_fail_seq

function axi4_master_tc_056_exclusive_write_fail_seq::new(string name = "axi4_master_tc_056_exclusive_write_fail_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_056_exclusive_write_fail_seq::body();
  
  // First perform a normal write to the same address to invalidate any existing exclusive monitor
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == WRITE;
    req.awid == `GET_AWID_ENUM(0);  // Using scalable ID mapping
    req.awaddr == 64'h0000_0100_0000_1250; // Same address as exclusive write
    req.awlen == 4'h0;  // 1 beat
    req.awsize == WRITE_4_BYTES;
    req.awburst == WRITE_INCR;
    req.awlock == WRITE_NORMAL_ACCESS; // Normal write to invalidate monitor
    req.wdata.size() == 1;
    req.wdata[0] == 32'hC1EA5001; // Clear exclusive monitor
    req.wstrb.size() == 1;
    req.wstrb[0] == 4'hF;
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_056: Sent invalidating write to clear exclusive monitor at 0x%16h", 
           req.awaddr), UVM_LOW);
  
  #20; // Wait for monitor invalidation
  
  // Now attempt exclusive write - should fail due to invalidated monitor
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == WRITE;
    req.awid == `GET_AWID_ENUM(1);  // Use ID 1 for 4x4 configuration compatibility, scalable mapping
    req.awaddr == 64'h0000_0100_0000_1250; // DDR Memory range
    req.awlen == 4'h0;  // 1 beat
    req.awsize == WRITE_4_BYTES;
    req.awburst == WRITE_INCR;
    req.awlock == WRITE_EXCLUSIVE_ACCESS; // AWLOCK=1 for exclusive access
    req.wdata.size() == 1;
    req.wdata[0] == 32'hFA110001; // Exclusive write data (should fail)
    req.wstrb.size() == 1;
    req.wstrb[0] == 4'hF;
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_056: Sent Exclusive Write (should fail) - AWID=0x%0x, AWADDR=0x%16h, AWLOCK=%0d, WDATA=0x%8h", 
           req.awid, req.awaddr, req.awlock, req.wdata[0]), UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_056: Verification - Check BRESP: OKAY (exclusive failed), not EXOKAY"), UVM_LOW);

endtask : body

`endif