`ifndef AXI4_MASTER_TC_048_ID_MULTIPLE_READS_SAME_ARID_SEQ_INCLUDED_
`define AXI4_MASTER_TC_048_ID_MULTIPLE_READS_SAME_ARID_SEQ_INCLUDED_

`include "axi4_bus_config.svh"

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_048_id_multiple_reads_same_arid_seq
// TC_048: ID Multiple Reads Same ARID
// Test scenario: Setup data then send two read transactions with same ARID (scalable)  
// Precondition: 0x0000_0100_0000_10E0=D1, 0x0000_0100_0000_10E4=D2
// T1: ARID=scalable, ARADDR=0x0000_0100_0000_1000, ARLEN=0
// T2: ARID=scalable, ARADDR=0x0000_0100_0000_1004, ARLEN=0
// Verification: Slave must respond with RDATA in the order of AR Channel
//--------------------------------------------------------------------------------------------
class axi4_master_tc_048_id_multiple_reads_same_arid_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_048_id_multiple_reads_same_arid_seq)

  extern function new(string name = "axi4_master_tc_048_id_multiple_reads_same_arid_seq");
  extern task body();
endclass : axi4_master_tc_048_id_multiple_reads_same_arid_seq

function axi4_master_tc_048_id_multiple_reads_same_arid_seq::new(string name = "axi4_master_tc_048_id_multiple_reads_same_arid_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_048_id_multiple_reads_same_arid_seq::body();
  
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
  
  `uvm_info(get_type_name(), $sformatf("TC_048: Setup - Wrote D1=0x%8h to 0x%16h", 
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
  
  `uvm_info(get_type_name(), $sformatf("TC_048: Setup - Wrote D2=0x%8h to 0x%16h", 
           req.wdata[0], req.awaddr), UVM_LOW);
  
  #50; // Wait for writes to complete
  
  // TEST PHASE: Read T1 with ARID=0x2 from first address  
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  // Direct assignment to avoid constraint conflicts
  req.tx_type = READ;
  req.arid = `GET_ARID_ENUM(`GET_EFFECTIVE_ARID(2));  // Scalable ID assignment
  req.araddr = 64'h0000_0100_0000_1000; // DDR Memory range - same as write address
  req.arlen = 4'h0;  // 1 beat
  req.arsize = READ_4_BYTES;
  req.arburst = READ_INCR;
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_048: Sent T1 Read - ARID=0x%0x, ARADDR=0x%16h", 
           req.arid, req.araddr), UVM_LOW);
  
  // Small delay before second read
  #20;
  
  // TEST PHASE: Read T2 with same ARID=0x2 from second address
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  // Direct assignment to avoid constraint conflicts
  req.tx_type = READ;
  req.arid = `GET_ARID_ENUM(`GET_EFFECTIVE_ARID(2));  // Scalable ID assignment
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