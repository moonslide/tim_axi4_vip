`ifndef AXI4_MASTER_4KB_BOUNDARY_SEQ_INCLUDED_
`define AXI4_MASTER_4KB_BOUNDARY_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_4kb_boundary_seq
// Tests 4KB boundary crossing (legal and illegal)
//--------------------------------------------------------------------------------------------
class axi4_master_4kb_boundary_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_4kb_boundary_seq)

  rand int num_transactions = 20;
  rand bit test_illegal = 0;
  
  extern function new(string name = "axi4_master_4kb_boundary_seq");
  extern task body();

endclass : axi4_master_4kb_boundary_seq

function axi4_master_4kb_boundary_seq::new(string name = "axi4_master_4kb_boundary_seq");
  super.new(name);
endfunction : new

task axi4_master_4kb_boundary_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), "Starting 4KB boundary sequence", UVM_HIGH)
  
  for(int i = 0; i < num_transactions; i++) begin
    req = axi4_master_tx::type_id::create("req");
    
    start_item(req);
    if(test_illegal && (i % 2 == 0)) begin
      // Create illegal 4KB crossing transaction
      if(!req.randomize() with {
        transfer_type == BLOCKING_WRITE;
        awburst == WRITE_INCR;
        awaddr[11:0] == 12'hF00;  // Start near 4KB boundary
        awlen == 63;  // Will cross boundary
        awsize == WRITE_4_BYTES;
      }) begin
        `uvm_fatal(get_type_name(), "Randomization failed")
      end
    end else begin
      // Create legal transaction near boundary
      if(!req.randomize() with {
        transfer_type inside {BLOCKING_WRITE, BLOCKING_READ};
        awburst == WRITE_INCR;
        arburst == READ_INCR;
        awaddr[11:0] inside {[12'h000:12'hF00]};
        araddr[11:0] inside {[12'h000:12'hF00]};
        awlen inside {[0:15]};
        arlen inside {[0:15]};
      }) begin
        `uvm_fatal(get_type_name(), "Randomization failed")
      end
    end
    finish_item(req);
    
    get_response(rsp);
  end
  
  `uvm_info(get_type_name(), "Completed 4KB boundary sequence", UVM_HIGH)
  
endtask : body

`endif