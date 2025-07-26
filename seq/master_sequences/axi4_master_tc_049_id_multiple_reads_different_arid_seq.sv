`ifndef AXI4_MASTER_TC_049_ID_MULTIPLE_READS_DIFFERENT_ARID_SEQ_INCLUDED_
`define AXI4_MASTER_TC_049_ID_MULTIPLE_READS_DIFFERENT_ARID_SEQ_INCLUDED_

`include "axi4_bus_config.svh"

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_049_id_multiple_reads_different_arid_seq
// TC_049: ID Multiple Reads Different ARID (Scalable)
// Test scenario: Setup data then send two read transactions with different ARID  
// Precondition: Write test data D1 and D2 to memory
// T1: ARID=scalable_id_1, ARADDR=first_addr, ARLEN=0
// T2: ARID=scalable_id_2, ARADDR=second_addr, ARLEN=0
// Verification: Slave can handle different ARID with out-of-order RDATA responses
// Scalable: Works with 4x4 to 64x64+ bus configurations
//--------------------------------------------------------------------------------------------
class axi4_master_tc_049_id_multiple_reads_different_arid_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_049_id_multiple_reads_different_arid_seq)

  extern function new(string name = "axi4_master_tc_049_id_multiple_reads_different_arid_seq");
  extern task body();
endclass : axi4_master_tc_049_id_multiple_reads_different_arid_seq

function axi4_master_tc_049_id_multiple_reads_different_arid_seq::new(string name = "axi4_master_tc_049_id_multiple_reads_different_arid_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_049_id_multiple_reads_different_arid_seq::body();
  
  // SETUP PHASE: Write test data D1 to first address
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  // Direct assignment to avoid constraint conflicts
  req.tx_type = WRITE;
  req.awid = `GET_AWID_ENUM(0); // Use scalable ID 0 for writes
  req.awaddr = 64'h0000_0100_0000_2000; // DDR Memory range - simplified aligned address
  req.awlen = 4'h0;  // 1 beat
  req.awsize = WRITE_4_BYTES;
  req.awburst = WRITE_INCR;
  req.wdata.delete();
  req.wdata.push_back(32'hDAEF0001); // D1
  req.wstrb.delete();
  req.wstrb.push_back(4'hF);
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_049: Setup - Wrote D1=0x%8h to 0x%16h", 
           req.wdata[0], req.awaddr), UVM_LOW);
  
  // SETUP PHASE: Write test data D2 to second address  
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  // Direct assignment to avoid constraint conflicts
  req.tx_type = WRITE;
  req.awid = `GET_AWID_ENUM(0); // Use scalable ID 0 for writes
  req.awaddr = 64'h0000_0100_0000_2004; // DDR Memory range - next aligned address
  req.awlen = 4'h0;  // 1 beat
  req.awsize = WRITE_4_BYTES;
  req.awburst = WRITE_INCR;
  req.wdata.delete();
  req.wdata.push_back(32'hDAEF0002); // D2
  req.wstrb.delete();
  req.wstrb.push_back(4'hF);
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_049: Setup - Wrote D2=0x%8h to 0x%16h", 
           req.wdata[0], req.awaddr), UVM_LOW);
  
  #50; // Wait for writes to complete
  
  // TEST PHASE: Read T1 with ARID=0xA from first address  
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  // Direct assignment to avoid constraint conflicts
  req.tx_type = READ;
  req.arid = `GET_ARID_ENUM(10 % `ID_MAP_BITS); // Scalable ARID (0xA for 4x4)
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
  // Direct assignment to avoid constraint conflicts
  req.tx_type = READ;
  req.arid = `GET_ARID_ENUM(11 % `ID_MAP_BITS); // Scalable ARID (0xB for 4x4)
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