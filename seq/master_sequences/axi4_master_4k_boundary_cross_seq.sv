`ifndef AXI4_MASTER_4K_BOUNDARY_CROSS_SEQ_INCLUDED_
`define AXI4_MASTER_4K_BOUNDARY_CROSS_SEQ_INCLUDED_

class axi4_master_4k_boundary_cross_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_4k_boundary_cross_seq)
  `uvm_declare_p_sequencer(axi4_master_write_sequencer)
  int sid = 0;

  extern function new(string name="axi4_master_4k_boundary_cross_seq");
  extern task body();
endclass

function axi4_master_4k_boundary_cross_seq::new(string name="axi4_master_4k_boundary_cross_seq");
  super.new(name);
endfunction

task axi4_master_4k_boundary_cross_seq::body();
  bit [ADDRESS_WIDTH-1:0] valid_cross_addr;
  bit [ADDRESS_WIDTH-1:0] invalid_cross_addr;
  super.body();
  
  // Test 1: Valid 4K boundary crossing within DDR_Memory (should succeed per AMBA AXI4 spec)
  // Note: AXI4 spec generally prohibits 4K boundary crossing, but we test interconnect response
  valid_cross_addr = 64'h0000_0100_0000_FFC; // Within DDR_Memory, crosses 4K boundary
  
  `uvm_info("4K_BOUNDARY_CROSS", $sformatf("Testing valid 4K boundary cross at: 0x%016h", valid_cross_addr), UVM_MEDIUM);
  
  // Write crossing 4K boundary within valid space
  start_item(req);
  if(!req.randomize() with {awaddr == valid_cross_addr;
                            awlen  == 1;
                            awsize == WRITE_4_BYTES;
                            awburst == WRITE_INCR;
                            tx_type == WRITE;
                            transfer_type == NON_BLOCKING_WRITE;})
    `uvm_fatal("axi4","Rand failed for valid 4K cross write");
  req.wdata.delete();
  req.wdata.push_back($urandom); req.wdata.push_back($urandom);
  req.wstrb.delete();
  req.wstrb.push_back('hf); req.wstrb.push_back('hf);
  req.wlast = 1'b1;
  finish_item(req);

  // Read after Write - same address crossing 4K boundary within valid space
  start_item(req);
  if(!req.randomize() with {araddr == valid_cross_addr;
                            arlen  == 1;
                            arsize == READ_4_BYTES;
                            arburst == READ_INCR;
                            tx_type == READ;
                            transfer_type == NON_BLOCKING_READ;})
    `uvm_fatal("axi4","Rand failed for valid 4K cross read");
  finish_item(req);
  
  // Test 2: Invalid 4K boundary crossing into unmapped space (should cause DECERR per AMBA AXI4 spec)
  invalid_cross_addr = 64'h0000_0000_0050_0FFC; // Crosses from unmapped into unmapped space
  
  `uvm_info("4K_BOUNDARY_CROSS", $sformatf("Testing invalid 4K boundary cross at: 0x%016h (expect DECERR)", invalid_cross_addr), UVM_MEDIUM);
  
  // Write crossing into unmapped space (should cause DECERR)
  start_item(req);
  if(!req.randomize() with {awaddr == invalid_cross_addr;
                            awlen  == 1;
                            awsize == WRITE_4_BYTES;
                            awburst == WRITE_INCR;
                            tx_type == WRITE;
                            transfer_type == NON_BLOCKING_WRITE;})
    `uvm_fatal("axi4","Rand failed for invalid 4K cross write");
  req.wdata.delete();
  req.wdata.push_back($urandom); req.wdata.push_back($urandom);
  req.wstrb.delete();
  req.wstrb.push_back('hf); req.wstrb.push_back('hf);
  req.wlast = 1'b1;
  finish_item(req);

  // Read after Write - crossing into unmapped space (should cause DECERR)
  start_item(req);
  if(!req.randomize() with {araddr == invalid_cross_addr;
                            arlen  == 1;
                            arsize == READ_4_BYTES;
                            arburst == READ_INCR;
                            tx_type == READ;
                            transfer_type == NON_BLOCKING_READ;})
    `uvm_fatal("axi4","Rand failed for invalid 4K cross read");
  finish_item(req);
endtask

`endif
