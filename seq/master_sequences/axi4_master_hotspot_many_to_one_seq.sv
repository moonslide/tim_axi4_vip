`ifndef AXI4_MASTER_HOTSPOT_MANY_TO_ONE_SEQ_INCLUDED_
`define AXI4_MASTER_HOTSPOT_MANY_TO_ONE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_hotspot_many_to_one_seq
// Multiple masters targeting a single slave (hotspot)
//--------------------------------------------------------------------------------------------
class axi4_master_hotspot_many_to_one_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_hotspot_many_to_one_seq)

  rand int target_slave_id = 0;
  rand int num_transactions = 50;
  
  constraint slave_id_c {
    target_slave_id inside {[0:9]};
  }

  extern function new(string name = "axi4_master_hotspot_many_to_one_seq");
  extern task body();

endclass : axi4_master_hotspot_many_to_one_seq

function axi4_master_hotspot_many_to_one_seq::new(string name = "axi4_master_hotspot_many_to_one_seq");
  super.new(name);
endfunction : new

task axi4_master_hotspot_many_to_one_seq::body();
  bit [63:0] target_addr;
  
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting hotspot sequence targeting slave %0d", target_slave_id), UVM_HIGH)
  
  // Set target address based on slave_id
  case(target_slave_id)
    0: target_addr = 64'h0000_0008_0000_0000;  // S0
    1: target_addr = 64'h0000_0008_4000_0000;  // S1
    2: target_addr = 64'h0000_0008_8000_0000;  // S2
    3: target_addr = 64'h0000_0008_C000_0000;  // S3
    4: target_addr = 64'h0000_0009_0000_0000;  // S4
    5: target_addr = 64'h0000_000A_0000_0000;  // S5
    6: target_addr = 64'h0000_000A_0001_0000;  // S6
    7: target_addr = 64'h0000_000A_0002_0000;  // S7
    8: target_addr = 64'h0000_000A_0003_0000;  // S8
    9: target_addr = 64'h0000_000A_0004_0000;  // S9
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
  
  `uvm_info(get_type_name(), "Completed hotspot sequence", UVM_HIGH)
  
endtask : body

`endif