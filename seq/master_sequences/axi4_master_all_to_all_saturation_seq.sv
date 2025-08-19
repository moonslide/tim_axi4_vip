`ifndef AXI4_MASTER_ALL_TO_ALL_SATURATION_SEQ_INCLUDED_
`define AXI4_MASTER_ALL_TO_ALL_SATURATION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_all_to_all_saturation_seq
// All masters accessing all slaves with saturated traffic
//--------------------------------------------------------------------------------------------
class axi4_master_all_to_all_saturation_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_all_to_all_saturation_seq)

  rand int num_transactions = 100;
  rand int max_outstanding = 16;
  int use_bus_matrix_addressing = 0;  // 0=NONE/4x4, 1=4x4, 2=10x10
  
  constraint num_trans_c {
    num_transactions inside {[50:200]};
  }

  extern function new(string name = "axi4_master_all_to_all_saturation_seq");
  extern task body();

endclass : axi4_master_all_to_all_saturation_seq

function axi4_master_all_to_all_saturation_seq::new(string name = "axi4_master_all_to_all_saturation_seq");
  super.new(name);
endfunction : new

task axi4_master_all_to_all_saturation_seq::body();
  bit [63:0] base_addr;
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting all-to-all saturation sequence, use_bus_matrix_addressing=%0d", use_bus_matrix_addressing), UVM_HIGH)
  
  for(int i = 0; i < num_transactions; i++) begin
    req = axi4_master_tx::type_id::create("req");
    
    // Select base address based on bus matrix mode - rotate through slaves
    if(use_bus_matrix_addressing == 2) begin
      // 10x10 enhanced matrix - cycle through valid slave addresses
      case(i % 3)
        0: base_addr = 64'h0000_0008_4000_0000; // DDR Non-Secure User
        1: base_addr = 64'h0000_0008_8000_0000; // DDR Shared Buffer
        2: base_addr = 64'h0000_000B_0000_0000; // RW Peripheral
      endcase
    end else if(use_bus_matrix_addressing == 1) begin
      // 4x4 base matrix - cycle through valid slave addresses
      case(i % 2)
        0: base_addr = 64'h0000_0100_0000_0000; // DDR Memory
        1: base_addr = 64'h0000_0010_0000_0000; // APB
      endcase
    end else begin
      // NONE mode - use simple addresses
      base_addr = 64'h0000_0000_0000_0000;
    end
    
    start_item(req);
    // Constrain AWID based on bus matrix mode
    if(use_bus_matrix_addressing == 2) begin
      // 10x10 mode: IDs can be 0-9
      if(!req.randomize() with {
        transfer_type == NON_BLOCKING_WRITE;
        awaddr[63:16] == base_addr[63:16];
        awburst == WRITE_INCR;
        awlen inside {[0:255]};
        awsize inside {[0:3]};
        awid inside {[0:9]};
      }) begin
        `uvm_fatal(get_type_name(), "Randomization failed")
      end
    end else begin
      // 4x4 and NONE modes: IDs must be 0-3
      if(!req.randomize() with {
        transfer_type == NON_BLOCKING_WRITE;
        awaddr[63:16] == base_addr[63:16];
        awburst == WRITE_INCR;
        awlen inside {[0:255]};
        awsize inside {[0:3]};
        awid inside {[0:3]};
      }) begin
        `uvm_fatal(get_type_name(), "Randomization failed")
      end
    end
    finish_item(req);
  end
  
  `uvm_info(get_type_name(), "Completed all-to-all saturation sequence", UVM_HIGH)
  
endtask : body

`endif