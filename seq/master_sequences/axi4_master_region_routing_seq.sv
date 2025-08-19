`ifndef AXI4_MASTER_REGION_ROUTING_SEQ_INCLUDED_
`define AXI4_MASTER_REGION_ROUTING_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_region_routing_seq
// Tests REGION-based routing to different slaves
//--------------------------------------------------------------------------------------------
class axi4_master_region_routing_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_region_routing_seq)

  rand int num_transactions = 40;
  int use_bus_matrix_addressing = 0;  // 0=NONE/4x4, 1=4x4, 2=10x10
  
  extern function new(string name = "axi4_master_region_routing_seq");
  extern task body();

endclass : axi4_master_region_routing_seq

function axi4_master_region_routing_seq::new(string name = "axi4_master_region_routing_seq");
  super.new(name);
endfunction : new

task axi4_master_region_routing_seq::body();
  bit [63:0] base_addr;
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting REGION routing sequence, use_bus_matrix_addressing=%0d", use_bus_matrix_addressing), UVM_HIGH)
  
  for(int i = 0; i < num_transactions; i++) begin
    req = axi4_master_tx::type_id::create("req");
    
    // Select base address based on bus matrix mode
    if(use_bus_matrix_addressing == 2) begin
      // 10x10 enhanced matrix - use valid slave addresses
      case(i % 3)
        0: base_addr = 64'h0000_0008_4000_0000; // DDR Non-Secure User
        1: base_addr = 64'h0000_0008_8000_0000; // DDR Shared Buffer
        2: base_addr = 64'h0000_000B_0000_0000; // RW Peripheral
      endcase
    end else if(use_bus_matrix_addressing == 1) begin
      // 4x4 base matrix - use valid slave addresses  
      base_addr = (i % 2) ? 64'h0000_0100_0000_0000 : 64'h0000_0010_0000_0000; // DDR Memory or APB
    end else begin
      // NONE mode - use simple addresses
      base_addr = 64'h0000_0000_0000_0000;
    end
    
    start_item(req);
    // Constrain AWID/ARID based on bus matrix mode
    if(use_bus_matrix_addressing == 2) begin
      // 10x10 mode: IDs can be 0-9
      if(!req.randomize() with {
        transfer_type inside {BLOCKING_WRITE, BLOCKING_READ};
        awaddr[63:16] == base_addr[63:16];
        araddr[63:16] == base_addr[63:16];
        awregion inside {[0:15]};  // Test different regions
        arregion inside {[0:15]};
        awburst == WRITE_INCR;
        arburst == READ_INCR;
        awid inside {[0:9]};
        arid inside {[0:9]};
      }) begin
        `uvm_fatal(get_type_name(), "Randomization failed")
      end
    end else begin
      // 4x4 and NONE modes: IDs must be 0-3
      if(!req.randomize() with {
        transfer_type inside {BLOCKING_WRITE, BLOCKING_READ};
        awaddr[63:16] == base_addr[63:16];
        araddr[63:16] == base_addr[63:16];
        awregion inside {[0:15]};  // Test different regions
        arregion inside {[0:15]};
        awburst == WRITE_INCR;
        arburst == READ_INCR;
        awid inside {[0:3]};
        arid inside {[0:3]};
      }) begin
        `uvm_fatal(get_type_name(), "Randomization failed")
      end
    end
    finish_item(req);
    
    get_response(rsp);
  end
  
  `uvm_info(get_type_name(), "Completed REGION routing sequence", UVM_HIGH)
  
endtask : body

`endif