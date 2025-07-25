`ifndef AXI4_MASTER_LOWER_BOUNDARY_WRITE_SEQ_INCLUDED_
`define AXI4_MASTER_LOWER_BOUNDARY_WRITE_SEQ_INCLUDED_

class axi4_master_lower_boundary_write_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_lower_boundary_write_seq)
  `uvm_declare_p_sequencer(axi4_master_write_sequencer)
  int sid = 0;

  extern function new(string name="axi4_master_lower_boundary_write_seq");
  extern task body();
endclass

function axi4_master_lower_boundary_write_seq::new(string name="axi4_master_lower_boundary_write_seq");
  super.new(name);
endfunction

task axi4_master_lower_boundary_write_seq::body();
  bit [ADDRESS_WIDTH-1:0] valid_addr_list[2];
  bit [ADDRESS_WIDTH-1:0] invalid_addr_list[2];
  super.body();
  
  // Valid addresses - testing lower boundary of accessible ranges
  // Use DDR_Memory as it has proper access permissions
  valid_addr_list[0] = 64'h0000_0100_0000_0000; // Start of DDR_Memory
  valid_addr_list[1] = 64'h0000_0100_0000_0004; // Near start of DDR_Memory (aligned)
  
  // Invalid addresses - crossing lower boundaries into unmapped space
  invalid_addr_list[0] = 64'h0000_0000_0010_0000; // Unmapped space (boundary cross)
  invalid_addr_list[1] = 64'h0000_0000_0020_0000; // Another unmapped space (boundary cross)
  
  // Test valid addresses first - should succeed
  foreach(valid_addr_list[i]) begin
    start_item(req);
    if(!req.randomize() with {awaddr == valid_addr_list[i];
                              awlen  == 0;
                              awsize == WRITE_4_BYTES;
                              awburst == WRITE_INCR;
                              awprot == WRITE_NORMAL_NONSECURE_DATA;
                              tx_type == WRITE;
                              transfer_type == NON_BLOCKING_WRITE;})
      `uvm_fatal("axi4","Rand failed for valid address");
    req.wdata.delete();
    req.wdata.push_back($urandom);
    req.wstrb.delete();
    req.wstrb.push_back('hf);
    req.wlast = 1'b1;
    `uvm_info("LOWER_BOUNDARY_WRITE", $sformatf("Writing to valid address: 0x%016h", valid_addr_list[i]), UVM_MEDIUM);
    finish_item(req);
  end
  
  // Test invalid addresses - should get DECERR responses
  foreach(invalid_addr_list[i]) begin
    start_item(req);
    if(!req.randomize() with {awaddr == invalid_addr_list[i];
                              awlen  == 0;
                              awsize == WRITE_4_BYTES;
                              awburst == WRITE_INCR;
                              awprot == WRITE_NORMAL_NONSECURE_DATA;
                              tx_type == WRITE;
                              transfer_type == NON_BLOCKING_WRITE;})
      `uvm_fatal("axi4","Rand failed for invalid address");
    req.wdata.delete();
    req.wdata.push_back($urandom);
    req.wstrb.delete();
    req.wstrb.push_back('hf);
    req.wlast = 1'b1;
    `uvm_info("LOWER_BOUNDARY_WRITE", $sformatf("Writing to invalid address: 0x%016h (expect DECERR)", invalid_addr_list[i]), UVM_MEDIUM);
    finish_item(req);
  end
endtask

`endif
