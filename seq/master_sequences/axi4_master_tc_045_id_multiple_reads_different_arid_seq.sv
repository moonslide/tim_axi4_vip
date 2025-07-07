`ifndef AXI4_MASTER_TC_045_ID_MULTIPLE_READS_DIFFERENT_ARID_SEQ_INCLUDED_
`define AXI4_MASTER_TC_045_ID_MULTIPLE_READS_DIFFERENT_ARID_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_045_id_multiple_reads_different_arid_seq
// TC_045: ID Multiple Reads Different ARID
// Test scenario: Setup data then send two read transactions with different ARID  
// Precondition: 0x0000_0100_0000_10F0=D1, 0x0000_0100_0000_10F4=D2
// T1: ARID=0xA, ARADDR=0x0000_0100_0000_10F0, ARLEN=0
// T2: ARID=0xB, ARADDR=0x0000_0100_0000_10F4, ARLEN=0
// Verification: Slave can handle different ARID with out-of-order RDATA responses
//--------------------------------------------------------------------------------------------
class axi4_master_tc_045_id_multiple_reads_different_arid_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_045_id_multiple_reads_different_arid_seq)

  extern function new(string name = "axi4_master_tc_045_id_multiple_reads_different_arid_seq");
  extern task body();
endclass : axi4_master_tc_045_id_multiple_reads_different_arid_seq

function axi4_master_tc_045_id_multiple_reads_different_arid_seq::new(string name = "axi4_master_tc_045_id_multiple_reads_different_arid_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_045_id_multiple_reads_different_arid_seq::body();
  
  // SETUP PHASE: Write test data D1 to first address
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == WRITE;
    req.awid == AWID_0;
    req.awaddr == 64'h0000_0100_0000_10F0; // DDR Memory range
    req.awlen == 4'h0;  // 1 beat
    req.awsize == WRITE_4_BYTES;
    req.awburst == WRITE_INCR;
    req.wdata.size() == 1;
    req.wdata[0] == 32'hDAEF0001; // D1
    req.wstrb.size() == 1;
    req.wstrb[0] == 4'hF;
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_045: Setup - Wrote D1=0x%8h to 0x%16h", 
           req.wdata[0], req.awaddr), UVM_LOW);
  
  // SETUP PHASE: Write test data D2 to second address  
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == WRITE;
    req.awid == AWID_0;
    req.awaddr == 64'h0000_0100_0000_10F4; // DDR Memory range
    req.awlen == 4'h0;  // 1 beat
    req.awsize == WRITE_4_BYTES;
    req.awburst == WRITE_INCR;
    req.wdata.size() == 1;
    req.wdata[0] == 32'hDAEF0002; // D2
    req.wstrb.size() == 1;
    req.wstrb[0] == 4'hF;
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_045: Setup - Wrote D2=0x%8h to 0x%16h", 
           req.wdata[0], req.awaddr), UVM_LOW);
  
  #50; // Wait for writes to complete
  
  // TEST PHASE: Read T1 with ARID=0xA from first address  
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == READ;
    req.arid == ARID_10;  // 0xA
    req.araddr == 64'h0000_0100_0000_10F0; // DDR Memory range
    req.arlen == 4'h0;  // 1 beat
    req.arsize == READ_4_BYTES;
    req.arburst == READ_INCR;
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_045: Sent T1 Read - ARID=0x%0x, ARADDR=0x%16h", 
           req.arid, req.araddr), UVM_LOW);
  
  // Small delay before second read
  #20;
  
  // TEST PHASE: Read T2 with different ARID=0xB from second address
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == READ;
    req.arid == ARID_11;  // 0xB
    req.araddr == 64'h0000_0100_0000_10F4; // DDR Memory range
    req.arlen == 4'h0;  // 1 beat
    req.arsize == READ_4_BYTES;
    req.arburst == READ_INCR;
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_045: Sent T2 Read - ARID=0x%0x, ARADDR=0x%16h", 
           req.arid, req.araddr), UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_045: Verification - Check that RDATA can be out-of-order (T2:D2 before T1:D1 allowed)"), UVM_LOW);

endtask : body

`endif