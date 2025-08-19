`ifndef AXI4_MASTER_READ_WRITE_CONTENTION_SEQ_INCLUDED_
`define AXI4_MASTER_READ_WRITE_CONTENTION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_read_write_contention_seq
// Tests read/write contention on same slave
//--------------------------------------------------------------------------------------------
class axi4_master_read_write_contention_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_read_write_contention_seq)

  rand int target_slave = 3;
  rand int num_transactions = 50;
  bit write_only_mode = 0;  // Flag to force write-only transactions
  int use_bus_matrix_addressing = 0; // 0=NONE, 1=BASE_4x4, 2=ENHANCED_10x10
  
  extern function new(string name = "axi4_master_read_write_contention_seq");
  extern task body();

endclass : axi4_master_read_write_contention_seq

function axi4_master_read_write_contention_seq::new(string name = "axi4_master_read_write_contention_seq");
  super.new(name);
endfunction : new

task axi4_master_read_write_contention_seq::body();
  bit [63:0] target_addr;
  
  super.body();
  
  `uvm_info(get_type_name(), "Starting read-write contention sequence", UVM_HIGH)
  
  // Set target address based on bus matrix mode
  if(use_bus_matrix_addressing == 2) begin
    // ENHANCED mode - use DDR Memory region
    target_addr = 64'h0000_0100_0000_0000;
  end else if(use_bus_matrix_addressing == 1) begin
    // BASE mode - use DDR Memory region
    target_addr = 64'h0000_0100_0000_0000;
  end else begin
    // NONE mode - use simple address
    target_addr = 64'h0000_0000_0000_0000;
  end
  
  for(int i = 0; i < num_transactions; i++) begin
    req = axi4_master_tx::type_id::create("req");
    
    start_item(req);
    
    // Apply proper ID constraints based on bus matrix mode
    if(use_bus_matrix_addressing == 2) begin
      // ENHANCED mode (10x10)
      if(write_only_mode) begin
        if(!req.randomize() with {
          transfer_type == NON_BLOCKING_WRITE;
          awaddr[63:16] == target_addr[63:16];
          awburst == WRITE_INCR;
          awid inside {[0:9]};
        }) begin
          `uvm_fatal(get_type_name(), "Randomization failed")
        end
      end else begin
        if(!req.randomize() with {
          transfer_type inside {NON_BLOCKING_WRITE, NON_BLOCKING_READ};
          awaddr[63:16] == target_addr[63:16];
          araddr[63:16] == target_addr[63:16];
          awburst == WRITE_INCR;
          arburst == READ_INCR;
          awid inside {[0:9]};
          arid inside {[0:9]};
        }) begin
          `uvm_fatal(get_type_name(), "Randomization failed")
        end
      end
    end else begin
      // NONE or BASE mode (4x4)
      if(write_only_mode) begin
        if(!req.randomize() with {
          transfer_type == NON_BLOCKING_WRITE;
          awaddr[63:16] == target_addr[63:16];
          awburst == WRITE_INCR;
          awid inside {[0:3]};
        }) begin
          `uvm_fatal(get_type_name(), "Randomization failed")
        end
      end else begin
        if(!req.randomize() with {
          transfer_type inside {NON_BLOCKING_WRITE, NON_BLOCKING_READ};
          awaddr[63:16] == target_addr[63:16];
          araddr[63:16] == target_addr[63:16];
          awburst == WRITE_INCR;
          arburst == READ_INCR;
          awid inside {[0:3]};
          arid inside {[0:3]};
        }) begin
          `uvm_fatal(get_type_name(), "Randomization failed")
        end
      end
    end
    finish_item(req);
  end
  
  `uvm_info(get_type_name(), "Completed read-write contention sequence", UVM_HIGH)
  
endtask : body

`endif