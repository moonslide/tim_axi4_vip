`ifndef AXI4_MASTER_MAX_OUTSTANDING_SEQ_INCLUDED_
`define AXI4_MASTER_MAX_OUTSTANDING_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_max_outstanding_seq
// Tests maximum outstanding transactions
//--------------------------------------------------------------------------------------------
class axi4_master_max_outstanding_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_max_outstanding_seq)

  rand int max_outstanding = 16;
  rand int num_transactions = 100;
  int use_bus_matrix_addressing = 0;  // 0=NONE, 1=4x4, 2=10x10
  
  constraint outstanding_c {
    max_outstanding inside {[8:32]};
  }

  extern function new(string name = "axi4_master_max_outstanding_seq");
  extern task body();

endclass : axi4_master_max_outstanding_seq

function axi4_master_max_outstanding_seq::new(string name = "axi4_master_max_outstanding_seq");
  super.new(name);
endfunction : new

task axi4_master_max_outstanding_seq::body();
  bit [63:0] target_addr;
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting max outstanding sequence with %0d outstanding, use_bus_matrix_addressing=%0d", max_outstanding, use_bus_matrix_addressing), UVM_HIGH)
  
  for(int i = 0; i < num_transactions; i++) begin
    req = axi4_master_tx::type_id::create("req");
    
    // Select target address based on bus matrix mode
    if (use_bus_matrix_addressing == 1) begin
      // 4x4 base matrix - use DDR memory address
      target_addr = 64'h0000_0100_0000_0000;  // DDR Memory
    end else if (use_bus_matrix_addressing == 2) begin
      // 10x10 enhanced matrix - use DDR Secure address
      target_addr = 64'h0000_0008_0000_0000;  // DDR Secure
    end else begin
      // NONE mode - use simple address
      target_addr = 64'h0000_0000_0000_0000;
    end
    
    start_item(req);
    if(!req.randomize() with {
      transfer_type == NON_BLOCKING_WRITE;
      awaddr[63:16] == target_addr[63:16];
      awburst == WRITE_INCR;
      awid inside {[0:max_outstanding-1]};
      awlen inside {[0:15]};
    }) begin
      `uvm_fatal(get_type_name(), "Randomization failed")
    end
    finish_item(req);
    
    // Allow some transactions to complete
    if(i % max_outstanding == 0) begin
      #100ns;
    end
  end
  
  `uvm_info(get_type_name(), "Completed max outstanding sequence", UVM_HIGH)
  
endtask : body

`endif