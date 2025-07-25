`ifndef AXI4_MASTER_LOWER_BOUNDARY_READ_SEQ_INCLUDED_
`define AXI4_MASTER_LOWER_BOUNDARY_READ_SEQ_INCLUDED_

class axi4_master_lower_boundary_read_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_lower_boundary_read_seq)
  `uvm_declare_p_sequencer(axi4_master_read_sequencer)
  int sid = 0;

  extern function new(string name="axi4_master_lower_boundary_read_seq");
  extern task body();
endclass

function axi4_master_lower_boundary_read_seq::new(string name="axi4_master_lower_boundary_read_seq");
  super.new(name);
endfunction

task axi4_master_lower_boundary_read_seq::body();
  bit [ADDRESS_WIDTH-1:0] valid_addr_list[2];
  bit [ADDRESS_WIDTH-1:0] invalid_addr_list[2];
  super.body();
  
  // Valid addresses - testing lower boundary using accessible ranges
  // Use HW_Fuse_Box which is readable for M0,M3 or DDR_Memory for broader access
  valid_addr_list[0] = 64'h0000_0100_0000_0000; // Start of DDR_Memory (lowest accessible range)
  valid_addr_list[1] = 64'h0000_0100_0000_0004; // Near start of DDR_Memory
  
  // Invalid addresses - crossing lower boundaries into unmapped/inaccessible space
  invalid_addr_list[0] = 64'h0000_0000_0002_0000; // Just after Boot_ROM ends (boundary cross)
  invalid_addr_list[1] = 64'h0000_0000_0003_0000; // In unmapped space (boundary cross)
  
  // Test valid addresses first - should succeed
  foreach(valid_addr_list[i]) begin
    start_item(req);
    if(!req.randomize() with {araddr == valid_addr_list[i];
                              arlen  == 0;
                              arsize == READ_4_BYTES;
                              arburst == READ_INCR;
                              tx_type == READ;
                              transfer_type == NON_BLOCKING_READ;
                              // Constrain ARID to valid range for 4x4 configuration
                              arid inside {ARID_0, ARID_1, ARID_2, ARID_3};})
      `uvm_fatal("axi4","Rand failed for valid address");
    `uvm_info("LOWER_BOUNDARY_READ", $sformatf("Reading from valid address: 0x%016h with ARID=%s", valid_addr_list[i], req.arid.name()), UVM_MEDIUM);
    finish_item(req);
  end
  
  // Test invalid addresses - should get DECERR responses
  foreach(invalid_addr_list[i]) begin
    start_item(req);
    if(!req.randomize() with {araddr == invalid_addr_list[i];
                              arlen  == 0;
                              arsize == READ_4_BYTES;
                              arburst == READ_INCR;
                              tx_type == READ;
                              transfer_type == NON_BLOCKING_READ;
                              // Constrain ARID to valid range for 4x4 configuration
                              arid inside {ARID_0, ARID_1, ARID_2, ARID_3};})
      `uvm_fatal("axi4","Rand failed for invalid address");
    `uvm_info("LOWER_BOUNDARY_READ", $sformatf("Reading from invalid address: 0x%016h (expect DECERR) with ARID=%s", invalid_addr_list[i], req.arid.name()), UVM_MEDIUM);
    finish_item(req);
  end
endtask

`endif
