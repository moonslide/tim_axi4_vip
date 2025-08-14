`ifndef AXI4_MASTER_READ_REORDER_SEQ_INCLUDED_
`define AXI4_MASTER_READ_REORDER_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_read_reorder_seq
// Tests read reordering with multiple IDs and slaves
//--------------------------------------------------------------------------------------------
class axi4_master_read_reorder_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_read_reorder_seq)

  rand int num_transactions = 50;
  rand int num_ids = 8;
  int use_bus_matrix_addressing = 0;  // 0=NONE, 1=4x4, 2=10x10
  
  extern function new(string name = "axi4_master_read_reorder_seq");
  extern task body();

endclass : axi4_master_read_reorder_seq

function axi4_master_read_reorder_seq::new(string name = "axi4_master_read_reorder_seq");
  super.new(name);
endfunction : new

task axi4_master_read_reorder_seq::body();
  bit [63:0] target_addr;
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting read reorder sequence, use_bus_matrix_addressing=%0d", use_bus_matrix_addressing), UVM_HIGH)
  
  for(int i = 0; i < num_transactions; i++) begin
    req = axi4_master_tx::type_id::create("req");
    
    // Select target address based on bus matrix mode
    if (use_bus_matrix_addressing == 1) begin
      // 4x4 base matrix - use DDR memory address for reads
      target_addr = 64'h0000_0100_0000_0000;  // DDR Memory
    end else if (use_bus_matrix_addressing == 2) begin
      // 10x10 enhanced matrix - use DDR Secure address for reads
      target_addr = 64'h0000_0008_0000_0000;  // DDR Secure
    end else begin
      // NONE mode - use simple address
      target_addr = 64'h0000_0000_0000_0000;
    end
    
    start_item(req);
    if(!req.randomize() with {
      transfer_type == NON_BLOCKING_READ;
      tx_type == READ;
      araddr[63:16] == target_addr[63:16];
      arburst == READ_INCR;
      arid inside {[0:num_ids-1]};
      arlen inside {[0:15]};
    }) begin
      `uvm_fatal(get_type_name(), "Randomization failed")
    end
    finish_item(req);
  end
  
  `uvm_info(get_type_name(), "Completed read reorder sequence", UVM_HIGH)
  
endtask : body

`endif