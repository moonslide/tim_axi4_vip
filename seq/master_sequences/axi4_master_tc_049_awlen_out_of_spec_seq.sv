`ifndef AXI4_MASTER_TC_049_AWLEN_OUT_OF_SPEC_SEQ_INCLUDED_
`define AXI4_MASTER_TC_049_AWLEN_OUT_OF_SPEC_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_049_awlen_out_of_spec_seq
// TC_049: Protocol AWLEN Out Of Spec
// Test scenario: Send write with AWLEN=0x100 (257 beats) - exceeds AXI4 limit of 256
// AWID=0x4, AWADDR=0x0000_0100_0000_1230, AWLEN=0x100, AWSIZE=4bytes, AWBURST=INCR
// Verification: Slave should reject (AWREADY=0) or respond with SLVERR/DECERR
//--------------------------------------------------------------------------------------------
class axi4_master_tc_049_awlen_out_of_spec_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_049_awlen_out_of_spec_seq)

  extern function new(string name = "axi4_master_tc_049_awlen_out_of_spec_seq");
  extern task body();
endclass : axi4_master_tc_049_awlen_out_of_spec_seq

function axi4_master_tc_049_awlen_out_of_spec_seq::new(string name = "axi4_master_tc_049_awlen_out_of_spec_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_049_awlen_out_of_spec_seq::body();
  
  // Out-of-Spec AWLEN Protocol Violation - 257 beats exceeds AXI4 limit
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == WRITE;
    req.awid == AWID_4;  // 0x4
    req.awaddr == 64'h0000_0100_0000_1230; // DDR Memory range
    req.awlen == 8'hFF; // 256 beats (0xFF + 1 = 256) - Maximum allowed by AXI4
    req.awsize == WRITE_4_BYTES;
    req.awburst == WRITE_INCR;
    // Only provide minimal wdata - slave should reject before processing
    req.wdata.size() == 1;
    req.wdata[0] == 32'hBAD12340; 
    req.wstrb.size() == 1;
    req.wstrb[0] == 4'hF;
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_049: Sent out-of-spec write - AWID=0x%0x, AWADDR=0x%16h, AWLEN=0x%0x (257 beats)", 
           req.awid, req.awaddr, req.awlen), UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_049: Protocol Violation - AWLEN=0x100 exceeds AXI4 limit of 256 beats"), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("TC_049: Verification - Check Slave rejects (AWREADY=0) or responds with error"), UVM_LOW);

endtask : body

`endif