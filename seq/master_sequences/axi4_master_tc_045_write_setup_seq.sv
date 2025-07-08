`ifndef AXI4_MASTER_TC_045_WRITE_SETUP_SEQ_INCLUDED_
`define AXI4_MASTER_TC_045_WRITE_SETUP_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_045_write_setup_seq
// TC_045: Write Setup Phase - Prepare test data for different ARID read test
//--------------------------------------------------------------------------------------------
class axi4_master_tc_045_write_setup_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_045_write_setup_seq)

  extern function new(string name = "axi4_master_tc_045_write_setup_seq");
  extern task body();
endclass : axi4_master_tc_045_write_setup_seq

function axi4_master_tc_045_write_setup_seq::new(string name = "axi4_master_tc_045_write_setup_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_045_write_setup_seq::body();
  
  // SETUP PHASE: Write test data D1 to first address
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  req.tx_type = WRITE;
  req.awid = AWID_0;
  req.awaddr = 64'h0000_0100_0000_2000; // DDR Memory range - simplified aligned address
  req.awlen = 4'h0;  // 1 beat
  req.awsize = WRITE_4_BYTES;
  req.awburst = WRITE_INCR;
  req.wdata.delete();
  req.wdata.push_back(32'hDAEF0001); // D1
  req.wstrb.delete();
  req.wstrb.push_back(4'hF);
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_045: Setup - Wrote D1=0x%8h to 0x%16h", 
           req.wdata[0], req.awaddr), UVM_LOW);
  
  // SETUP PHASE: Write test data D2 to second address  
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  req.tx_type = WRITE;
  req.awid = AWID_0;
  req.awaddr = 64'h0000_0100_0000_2004; // DDR Memory range - next aligned address
  req.awlen = 4'h0;  // 1 beat
  req.awsize = WRITE_4_BYTES;
  req.awburst = WRITE_INCR;
  req.wdata.delete();
  req.wdata.push_back(32'hDAEF0002); // D2
  req.wstrb.delete();
  req.wstrb.push_back(4'hF);
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_045: Setup - Wrote D2=0x%8h to 0x%16h", 
           req.wdata[0], req.awaddr), UVM_LOW);

endtask : body

`endif