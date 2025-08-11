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
  
  // Set target address
  case(target_slave)
    0: target_addr = 64'h0000_0008_0000_0000;
    1: target_addr = 64'h0000_0008_4000_0000;
    2: target_addr = 64'h0000_0008_8000_0000;
    3: target_addr = 64'h0000_0008_C000_0000;
    default: target_addr = 64'h0000_0008_0000_0000;
  endcase
  
  for(int i = 0; i < num_transactions; i++) begin
    req = axi4_master_tx::type_id::create("req");
    
    start_item(req);
    if(!req.randomize() with {
      transfer_type inside {NON_BLOCKING_WRITE, NON_BLOCKING_READ};
      awaddr[63:16] == target_addr[63:16];
      araddr[63:16] == target_addr[63:16];
      awburst == WRITE_INCR;
      arburst == READ_INCR;
    }) begin
      `uvm_fatal(get_type_name(), "Randomization failed")
    end
    finish_item(req);
  end
  
  `uvm_info(get_type_name(), "Completed read-write contention sequence", UVM_HIGH)
  
endtask : body

`endif