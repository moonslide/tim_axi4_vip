`ifndef AXI4_MASTER_ONE_TO_MANY_FANOUT_SEQ_INCLUDED_
`define AXI4_MASTER_ONE_TO_MANY_FANOUT_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_one_to_many_fanout_seq
// Single master accessing multiple slaves
//--------------------------------------------------------------------------------------------
class axi4_master_one_to_many_fanout_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_one_to_many_fanout_seq)

  rand int num_slaves = 10;
  rand int transactions_per_slave = 10;
  
  extern function new(string name = "axi4_master_one_to_many_fanout_seq");
  extern task body();

endclass : axi4_master_one_to_many_fanout_seq

function axi4_master_one_to_many_fanout_seq::new(string name = "axi4_master_one_to_many_fanout_seq");
  super.new(name);
endfunction : new

task axi4_master_one_to_many_fanout_seq::body();
  bit [63:0] slave_addr[10];
  
  super.body();
  
  `uvm_info(get_type_name(), "Starting one-to-many fanout sequence", UVM_HIGH)
  
  // Initialize slave addresses
  slave_addr[0] = 64'h0000_0008_0000_0000;  // S0
  slave_addr[1] = 64'h0000_0008_4000_0000;  // S1
  slave_addr[2] = 64'h0000_0008_8000_0000;  // S2
  slave_addr[3] = 64'h0000_0008_C000_0000;  // S3
  slave_addr[4] = 64'h0000_0009_0000_0000;  // S4
  slave_addr[5] = 64'h0000_000A_0000_0000;  // S5
  slave_addr[6] = 64'h0000_000A_0001_0000;  // S6
  slave_addr[7] = 64'h0000_000A_0002_0000;  // S7
  slave_addr[8] = 64'h0000_000A_0003_0000;  // S8
  slave_addr[9] = 64'h0000_000A_0004_0000;  // S9
  
  for(int s = 0; s < num_slaves; s++) begin
    for(int i = 0; i < transactions_per_slave; i++) begin
      req = axi4_master_tx::type_id::create("req");
      
      start_item(req);
      if(!req.randomize() with {
        transfer_type inside {NON_BLOCKING_WRITE, NON_BLOCKING_READ};
        awaddr[63:16] == slave_addr[s][63:16];
        araddr[63:16] == slave_addr[s][63:16];
        awburst == WRITE_INCR;
        arburst == READ_INCR;
      }) begin
        `uvm_fatal(get_type_name(), "Randomization failed")
      end
      finish_item(req);
    end
  end
  
  `uvm_info(get_type_name(), "Completed one-to-many fanout sequence", UVM_HIGH)
  
endtask : body

`endif