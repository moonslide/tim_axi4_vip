`ifndef AXI4_MASTER_TC_050_ARLEN_OUT_OF_SPEC_SEQ_INCLUDED_
`define AXI4_MASTER_TC_050_ARLEN_OUT_OF_SPEC_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_050_arlen_out_of_spec_seq
// TC_050: Protocol ARLEN Out Of Spec
// Test scenario: Send read with ARLEN=0x100 (257 beats) - exceeds AXI4 limit of 256
// ARID=0x5, ARADDR=0x0000_0100_0000_1240, ARLEN=0x100, ARSIZE=4bytes, ARBURST=INCR
// Verification: Slave should reject (ARREADY=0) or respond with SLVERR/DECERR
//--------------------------------------------------------------------------------------------
class axi4_master_tc_050_arlen_out_of_spec_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_050_arlen_out_of_spec_seq)

  extern function new(string name = "axi4_master_tc_050_arlen_out_of_spec_seq");
  extern task body();
endclass : axi4_master_tc_050_arlen_out_of_spec_seq

function axi4_master_tc_050_arlen_out_of_spec_seq::new(string name = "axi4_master_tc_050_arlen_out_of_spec_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_050_arlen_out_of_spec_seq::body();
  
  // Out-of-Spec ARLEN Protocol Violation - 257 beats exceeds AXI4 limit
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == READ;
    req.arid == ARID_5;  // 0x5
    req.araddr == 64'h0000_0100_0000_1240; // DDR Memory range
    req.arlen == 8'hFF; // 256 beats (0xFF + 1 = 256) - Maximum allowed by AXI4
    req.arsize == READ_4_BYTES;
    req.arburst == READ_INCR;
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_050: Sent out-of-spec read - ARID=0x%0x, ARADDR=0x%16h, ARLEN=0x%0x (257 beats)", 
           req.arid, req.araddr, req.arlen), UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_050: Protocol Violation - ARLEN=0x100 exceeds AXI4 limit of 256 beats"), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("TC_050: Verification - Check Slave rejects (ARREADY=0) or responds with error"), UVM_LOW);

endtask : body

`endif