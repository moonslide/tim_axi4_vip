`ifndef AXI4_MASTER_TC_058_EXCLUSIVE_READ_FAIL_SEQ_INCLUDED_
`define AXI4_MASTER_TC_058_EXCLUSIVE_READ_FAIL_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_058_exclusive_read_fail_seq
// TC_058: Optional Exclusive Read Fail
// Test scenario: Write then exclusive read to unprivileged address
// Setup: Write 0xDEAD1000 to address 0x0000_0000_0000_1000 (expect BRESP=SLVERR)
// Test: ARLOCK=1, ARADDR=0x0000_0000_0000_1000 (slave 1 - not accessible by master 0)
// ARLEN=0, ARSIZE=4bytes, ARID=0xF
// Verification: Expect BRESP=SLVERR for write and RRESP=SLVERR for read due to access privilege violation
//--------------------------------------------------------------------------------------------
class axi4_master_tc_058_exclusive_read_fail_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_058_exclusive_read_fail_seq)

  extern function new(string name = "axi4_master_tc_058_exclusive_read_fail_seq");
  extern task body();
endclass : axi4_master_tc_058_exclusive_read_fail_seq

function axi4_master_tc_058_exclusive_read_fail_seq::new(string name = "axi4_master_tc_058_exclusive_read_fail_seq");
  super.new(name);
endfunction : new

task axi4_master_tc_058_exclusive_read_fail_seq::body();
  
  // SETUP PHASE: Write test data to unprivileged address (should fail with SLVERR)
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == WRITE;
    req.awid == AWID_0;
    req.awaddr == 64'h0000_0000_0000_1000; // Slave 1 range - not accessible by master 0
    req.awlen == 4'h0;  // 1 beat
    req.awsize == WRITE_4_BYTES;
    req.awburst == WRITE_INCR;
    req.awlock == WRITE_NORMAL_ACCESS;
    req.wdata.size() == 1;
    req.wdata[0] == 32'hDEAD1000; // Test data for unprivileged address
    req.wstrb.size() == 1;
    req.wstrb[0] == 4'hF;
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_058: Setup - Attempted write 0x%8h to unprivileged address 0x%16h (expect BРЕSP=SLVERR)", 
           req.wdata[0], req.awaddr), UVM_LOW);
  
  #20; // Wait for write to complete
  
  // TEST PHASE: Exclusive Read Transaction to unprivileged address (should also fail with SLVERR)
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == READ;
    req.arid == ARID_3;  // Valid range 0-3 for 4x4 bus matrix configuration
    req.araddr == 64'h0000_0000_0000_1000; // Slave 1 range - not accessible by master 0
    req.arlen == 4'h0;  // 1 beat
    req.arsize == READ_4_BYTES;
    req.arburst == READ_INCR;
    req.arlock == READ_EXCLUSIVE_ACCESS; // ARLOCK=1 for exclusive access
  });
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("TC_058: Sent Exclusive Read to unprivileged address - ARID=0x%0x, ARADDR=0x%16h, ARLOCK=%0d", 
           req.arid, req.araddr, req.arlock), UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_058: Verification - Expect BРЕSP=SLVERR for write and RRESP=SLVERR for read due to access privilege violation"), UVM_LOW);

endtask : body

`endif