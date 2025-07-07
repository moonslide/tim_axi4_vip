`ifndef AXI4_MASTER_UPPER_BOUNDARY_WRITE_SEQ_INCLUDED_
`define AXI4_MASTER_UPPER_BOUNDARY_WRITE_SEQ_INCLUDED_

class axi4_master_upper_boundary_write_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_upper_boundary_write_seq)
  `uvm_declare_p_sequencer(axi4_master_write_sequencer)
  int sid = 0;

  extern function new(string name="axi4_master_upper_boundary_write_seq");
  extern task body();
endclass

function axi4_master_upper_boundary_write_seq::new(string name="axi4_master_upper_boundary_write_seq");
  super.new(name);
endfunction

task axi4_master_upper_boundary_write_seq::body();
  bit [ADDRESS_WIDTH-1:0] valid_addr_list[2];
  bit [ADDRESS_WIDTH-1:0] invalid_addr_list[2];
  super.body();
  
  // Valid addresses - testing upper boundary of DDR_Memory range
  // These should succeed as they're within valid range
  valid_addr_list[0] = 64'h0000_0107_FFFF_FFFC; // Near end of DDR_Memory (testing boundary)
  valid_addr_list[1] = 64'h0000_0107_FFFF_FFF8; // Also near end of DDR_Memory
  
  // Invalid addresses - crossing upper boundary, should get DECERR per AMBA AXI4 spec
  invalid_addr_list[0] = 64'h0000_0108_0000_0000; // Just after DDR_Memory ends (boundary cross)
  invalid_addr_list[1] = 64'h0000_FFFF_FFFF_FFFC; // Way out of range
  
  // Test valid addresses first - should succeed
  foreach(valid_addr_list[i]) begin
    start_item(req);
    if(!req.randomize() with {awaddr == valid_addr_list[i];
                              awlen  == 0;
                              awsize == WRITE_4_BYTES;
                              awburst == WRITE_INCR;
                              tx_type == WRITE;
                              transfer_type == NON_BLOCKING_WRITE;})
      `uvm_fatal("axi4","Rand failed for valid address");
    req.wdata.delete();
    req.wdata.push_back($urandom);
    req.wstrb.delete();
    req.wstrb.push_back('hf);
    req.wlast = 1'b1;
    `uvm_info("UPPER_BOUNDARY_WRITE", $sformatf("Writing to valid address: 0x%016h", valid_addr_list[i]), UVM_MEDIUM);
    finish_item(req);
  end
  
  // Test invalid addresses - should get DECERR responses
  foreach(invalid_addr_list[i]) begin
    start_item(req);
    if(!req.randomize() with {awaddr == invalid_addr_list[i];
                              awlen  == 0;
                              awsize == WRITE_4_BYTES;
                              awburst == WRITE_INCR;
                              tx_type == WRITE;
                              transfer_type == NON_BLOCKING_WRITE;})
      `uvm_fatal("axi4","Rand failed for invalid address");
    req.wdata.delete();
    req.wdata.push_back($urandom);
    req.wstrb.delete();
    req.wstrb.push_back('hf);
    req.wlast = 1'b1;
    `uvm_info("UPPER_BOUNDARY_WRITE", $sformatf("Writing to invalid address: 0x%016h (expect DECERR)", invalid_addr_list[i]), UVM_MEDIUM);
    finish_item(req);
  end
endtask

`endif
