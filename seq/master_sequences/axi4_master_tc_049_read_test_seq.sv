`ifndef AXI4_MASTER_TC_049_READ_TEST_SEQ_INCLUDED_
`define AXI4_MASTER_TC_049_READ_TEST_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_049_read_test_seq
// TC_049: Read Test Phase - Multiple reads with different ARID
//--------------------------------------------------------------------------------------------
class axi4_master_tc_049_read_test_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_049_read_test_seq)

  extern function new(string name = "axi4_master_tc_049_read_test_seq");
  extern task body();
endclass : axi4_master_tc_049_read_test_seq

function axi4_master_tc_049_read_test_seq::new(string name = "axi4_master_tc_049_read_test_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_049_read_test_seq::body();
  
  // TEST PHASE: Read T1 with ARID=0xA from first address  
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  req.tx_type = READ;
  req.arid = ARID_10;  // 0xA
  req.araddr = 64'h0000_0100_0000_2000; // DDR Memory range - same as first write address
  req.arlen = 4'h0;  // 1 beat
  req.arsize = READ_4_BYTES;
  req.arburst = READ_INCR;
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_049: Sent T1 Read - ARID=0x%0x, ARADDR=0x%16h", 
           req.arid, req.araddr), UVM_LOW);
  
  // Small delay before second read
  #20;
  
  // TEST PHASE: Read T2 with different ARID=0xB from second address
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  req.tx_type = READ;
  req.arid = ARID_11;  // 0xB
  req.araddr = 64'h0000_0100_0000_2004; // DDR Memory range - same as second write address
  req.arlen = 4'h0;  // 1 beat
  req.arsize = READ_4_BYTES;
  req.arburst = READ_INCR;
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_049: Sent T2 Read - ARID=0x%0x, ARADDR=0x%16h", 
           req.arid, req.araddr), UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_049: Verification - Check that RDATA can be out-of-order (T2:D2 before T1:D1 allowed)"), UVM_LOW);

endtask : body

`endif