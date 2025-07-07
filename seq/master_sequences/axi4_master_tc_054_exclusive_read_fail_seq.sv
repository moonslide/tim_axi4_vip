`ifndef AXI4_MASTER_TC_054_EXCLUSIVE_READ_FAIL_SEQ_INCLUDED_
`define AXI4_MASTER_TC_054_EXCLUSIVE_READ_FAIL_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_054_exclusive_read_fail_seq
// TC_054: Optional Exclusive Read Fail
// Test scenario: Send exclusive read with ARLOCK=1 to unprivileged address
// ARLOCK=1, ARADDR=0x0000_0000_0000_1000 (slave 1 - not accessible by master 0)
// ARLEN=0, ARSIZE=4bytes, ARID=0xF
// Verification: Expect RRESP=SLVERR/DECERR due to access privilege violation
//--------------------------------------------------------------------------------------------
class axi4_master_tc_054_exclusive_read_fail_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_054_exclusive_read_fail_seq)

  extern function new(string name = "axi4_master_tc_054_exclusive_read_fail_seq");
  extern task body();
endclass : axi4_master_tc_054_exclusive_read_fail_seq

function axi4_master_tc_054_exclusive_read_fail_seq::new(string name = "axi4_master_tc_054_exclusive_read_fail_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_054_exclusive_read_fail_seq::body();
  
  // TEST PHASE: Exclusive Read Transaction to unprivileged address
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == READ;
    req.arid == ARID_15;  // 0xF
    req.araddr == 64'h0000_0000_0000_1000; // Slave 1 range - not accessible by master 0
    req.arlen == 4'h0;  // 1 beat
    req.arsize == READ_4_BYTES;
    req.arburst == READ_INCR;
    req.arlock == READ_EXCLUSIVE_ACCESS; // ARLOCK=1 for exclusive access
  });
  
  `uvm_info(get_type_name(), $sformatf("TC_054: Sending Exclusive Read to unprivileged address - ARID=0x%0x, ARADDR=0x%16h, ARLOCK=%0d", 
           req.arid, req.araddr, req.arlock), UVM_LOW);
  
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_054: Verification - Expect RRESP=SLVERR/DECERR due to access privilege violation"), UVM_LOW);

endtask : body

`endif