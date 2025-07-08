`ifndef AXI4_MASTER_TC_044_ID_MULTIPLE_READS_SAME_ARID_SEQ_INCLUDED_
`define AXI4_MASTER_TC_044_ID_MULTIPLE_READS_SAME_ARID_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_044_id_multiple_reads_same_arid_seq
// TC_044: ID Multiple Reads Same ARID
// Test scenario: Setup data then send two read transactions with same ARID=0xE  
// Precondition: 0x0000_0100_0000_10E0=D1, 0x0000_0100_0000_10E4=D2
// T1: ARID=0xE, ARADDR=0x0000_0100_0000_10E0, ARLEN=0
// T2: ARID=0xE, ARADDR=0x0000_0100_0000_10E4, ARLEN=0
// Verification: Slave must respond with RDATA in the order of AR Channel
//--------------------------------------------------------------------------------------------
class axi4_master_tc_044_id_multiple_reads_same_arid_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_044_id_multiple_reads_same_arid_seq)

  extern function new(string name = "axi4_master_tc_044_id_multiple_reads_same_arid_seq");
  extern task body();
endclass : axi4_master_tc_044_id_multiple_reads_same_arid_seq

function axi4_master_tc_044_id_multiple_reads_same_arid_seq::new(string name = "axi4_master_tc_044_id_multiple_reads_same_arid_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_044_id_multiple_reads_same_arid_seq::body();
  
  // SETUP PHASE: Write test data D1 to first address
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  // Direct assignment to avoid constraint conflicts
  req.tx_type = WRITE;
  req.awid = AWID_0;
  req.awaddr = 64'h0000_0100_0000_1000; // DDR Memory range - simplified aligned address
  req.awlen = 4'h0;  // 1 beat
  req.awsize = WRITE_4_BYTES;
  req.awburst = WRITE_INCR;
  req.wdata.delete();
  req.wdata.push_back(32'hDEAD0001); // D1
  req.wstrb.delete();
  req.wstrb.push_back(4'hF);
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_044: Setup - Wrote D1=0x%8h to 0x%16h", 
           req.wdata[0], req.awaddr), UVM_LOW);
  
  // SETUP PHASE: Write test data D2 to second address  
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  // Direct assignment to avoid constraint conflicts
  req.tx_type = WRITE;
  req.awid = AWID_0;
  req.awaddr = 64'h0000_0100_0000_1004; // DDR Memory range - next aligned address
  req.awlen = 4'h0;  // 1 beat
  req.awsize = WRITE_4_BYTES;
  req.awburst = WRITE_INCR;
  req.wdata.delete();
  req.wdata.push_back(32'hDEAD0002); // D2
  req.wstrb.delete();
  req.wstrb.push_back(4'hF);
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_044: Setup - Wrote D2=0x%8h to 0x%16h", 
           req.wdata[0], req.awaddr), UVM_LOW);
  
  #50; // Wait for writes to complete
  
  // TEST PHASE: Read T1 with ARID=0xE from first address  
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  // Direct assignment to avoid constraint conflicts
  req.tx_type = READ;
  req.arid = ARID_14;
  req.araddr = 64'h0000_0100_0000_1000; // DDR Memory range - same as write address
  req.arlen = 4'h0;  // 1 beat
  req.arsize = READ_4_BYTES;
  req.arburst = READ_INCR;
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_044: Sent T1 Read - ARID=0x%0x, ARADDR=0x%16h", 
           req.arid, req.araddr), UVM_LOW);
  
  // Small delay before second read
  #20;
  
  // TEST PHASE: Read T2 with same ARID=0xE from second address
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  // Direct assignment to avoid constraint conflicts
  req.tx_type = READ;
  req.arid = ARID_14;
  req.araddr = 64'h0000_0100_0000_1004; // DDR Memory range - same as second write address
  req.arlen = 4'h0;  // 1 beat
  req.arsize = READ_4_BYTES;
  req.arburst = READ_INCR;
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_044: Sent T2 Read - ARID=0x%0x, ARADDR=0x%16h", 
           req.arid, req.araddr), UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_044: Verification - Check that RDATA comes in order of AR (T1:D1 then T2:D2)"), UVM_LOW);

endtask : body

`endif