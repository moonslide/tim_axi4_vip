`ifndef AXI4_MASTER_TC_048_READ_TEST_SEQ_INCLUDED_
`define AXI4_MASTER_TC_048_READ_TEST_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_048_read_test_seq
// TC_048: Read Test Phase - Multiple reads with same ARID=0x2
//--------------------------------------------------------------------------------------------
class axi4_master_tc_048_read_test_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_048_read_test_seq)

  extern function new(string name = "axi4_master_tc_048_read_test_seq");
  extern task body();
endclass : axi4_master_tc_048_read_test_seq

function axi4_master_tc_048_read_test_seq::new(string name = "axi4_master_tc_048_read_test_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_048_read_test_seq::body();
  
  // TEST PHASE: Read T1 with ARID=0xE from first address  
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  req.tx_type = READ;
  req.arid = ARID_2;  // Valid range 0-3 for 4x4 bus matrix configuration
  req.araddr = 64'h0000_0100_0000_1000; // DDR Memory range - same as write address
  req.arlen = 4'h0;  // 1 beat
  req.arsize = READ_4_BYTES;
  req.arburst = READ_INCR;
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_048: Sent T1 Read - ARID=0x%0x, ARADDR=0x%16h", 
           req.arid, req.araddr), UVM_LOW);
  
  // Small delay before second read
  #20;
  
  // TEST PHASE: Read T2 with same ARID=0xE from second address
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  req.tx_type = READ;
  req.arid = ARID_2;  // Valid range 0-3 for 4x4 bus matrix configuration
  req.araddr = 64'h0000_0100_0000_1004; // DDR Memory range - same as second write address
  req.arlen = 4'h0;  // 1 beat
  req.arsize = READ_4_BYTES;
  req.arburst = READ_INCR;
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_048: Sent T2 Read - ARID=0x%0x, ARADDR=0x%16h", 
           req.arid, req.araddr), UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_048: Verification - Check that RDATA comes in order of AR (T1:D1 then T2:D2)"), UVM_LOW);

endtask : body

`endif