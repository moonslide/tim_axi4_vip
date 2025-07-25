`ifndef AXI4_MASTER_TC_057_EXCLUSIVE_READ_SUCCESS_SEQ_INCLUDED_
`define AXI4_MASTER_TC_057_EXCLUSIVE_READ_SUCCESS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_057_exclusive_read_success_seq
// TC_057: Optional Exclusive Read Success
// Test scenario: Send exclusive read with ARLOCK=1 to establish exclusive monitor
// Precondition: Write data 0xDATA1260 to address 0x0000_0100_0000_1260
// ARLOCK=1, ARADDR=0x0000_0100_0000_1260, ARLEN=0, ARSIZE=4bytes, ARID=0x2
// Verification: If slave supports exclusive access, expect RRESP=EXOKAY and setup monitor
//               If not supported, expect RRESP=OKAY (normal read)
//--------------------------------------------------------------------------------------------
class axi4_master_tc_057_exclusive_read_success_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_057_exclusive_read_success_seq)

  extern function new(string name = "axi4_master_tc_057_exclusive_read_success_seq");
  extern task body();
endclass : axi4_master_tc_057_exclusive_read_success_seq

function axi4_master_tc_057_exclusive_read_success_seq::new(string name = "axi4_master_tc_057_exclusive_read_success_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_057_exclusive_read_success_seq::body();
  
  // SETUP PHASE: Write test data to the address for exclusive read
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == WRITE;
    req.awid == AWID_0;
    req.awaddr == 64'h0000_0100_0000_1260; // DDR Memory range
    req.awlen == 4'h0;  // 1 beat
    req.awsize == WRITE_4_BYTES;
    req.awburst == WRITE_INCR;
    req.awlock == WRITE_NORMAL_ACCESS;
    req.wdata.size() == 1;
    req.wdata[0] == 32'hDEAD1260; // Precondition data
    req.wstrb.size() == 1;
    req.wstrb[0] == 4'hF;
    req.wuser == 4'h0;
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_057: Setup - Wrote 0x%8h to 0x%16h", 
           req.wdata[0], req.awaddr), UVM_LOW);
  
  #20; // Wait for write to complete
  
  // TEST PHASE: Exclusive Read Transaction
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == READ;
    req.arid == ARID_2;  // Valid range 0-3 for 4x4 bus matrix configuration
    req.araddr == 64'h0000_0100_0000_1260; // DDR Memory range
    req.arlen == 4'h0;  // 1 beat
    req.arsize == READ_4_BYTES;
    req.arburst == READ_INCR;
    req.arlock == READ_EXCLUSIVE_ACCESS; // ARLOCK=1 for exclusive access
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_057: Sent Exclusive Read - ARID=0x%0x, ARADDR=0x%16h, ARLOCK=%0d", 
           req.arid, req.araddr, req.arlock), UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_057: Verification - Check RDATA=0xDEAD1260, RRESP: EXOKAY if exclusive supported, OKAY if not"), UVM_LOW);

endtask : body

`endif