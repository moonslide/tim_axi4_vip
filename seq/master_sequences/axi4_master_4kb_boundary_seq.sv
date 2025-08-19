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
  bit write_only_mode = 0;  // Flag to force write-only transactions
  int use_bus_matrix_addressing = 0;  // 0=NONE, 1=4x4, 2=10x10
  
  extern function new(string name = "axi4_master_4kb_boundary_seq");
  extern task body();

endclass : axi4_master_4kb_boundary_seq

function axi4_master_4kb_boundary_seq::new(string name = "axi4_master_4kb_boundary_seq");
  super.new(name);
endfunction : new

task axi4_master_4kb_boundary_seq::body();
  bit [63:0] base_addr;
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting 4KB boundary sequence, use_bus_matrix_addressing=%0d", use_bus_matrix_addressing), UVM_HIGH)
  
  for(int i = 0; i < num_transactions; i++) begin
    req = axi4_master_tx::type_id::create("req");
    
    // Select base address based on bus matrix mode
    if(use_bus_matrix_addressing == 2) begin
      // 10x10 enhanced matrix - use valid slave addresses
      base_addr = 64'h0000_0100_0000_0000; // DDR Memory
    end else if(use_bus_matrix_addressing == 1) begin
      // 4x4 base matrix - use valid slave addresses  
      base_addr = 64'h0000_0100_0000_0000; // DDR Memory
    end else begin
      // NONE mode - use simple addresses
      base_addr = 64'h0000_0000_0000_0000;
    end
    
    start_item(req);
    if(test_illegal && (i % 2 == 0)) begin
      // Create illegal 4KB crossing transaction with proper AWID constraints
      if(use_bus_matrix_addressing == 2) begin
        // 10x10 mode
        if(!req.randomize() with {
          transfer_type == BLOCKING_WRITE;
          awburst == WRITE_INCR;
          awaddr[63:12] == base_addr[63:12];
          awaddr[11:0] == 12'hF00;  // Start near 4KB boundary
          awlen == 63;  // Will cross boundary
          awsize == WRITE_4_BYTES;
          awid inside {[0:9]};
        }) begin
          `uvm_fatal(get_type_name(), "Randomization failed")
        end
      end else begin
        // 4x4 and NONE modes
        if(!req.randomize() with {
          transfer_type == BLOCKING_WRITE;
          awburst == WRITE_INCR;
          awaddr[63:12] == base_addr[63:12];
          awaddr[11:0] == 12'hF00;  // Start near 4KB boundary
          awlen == 63;  // Will cross boundary
          awsize == WRITE_4_BYTES;
          awid inside {[0:3]};
        }) begin
          `uvm_fatal(get_type_name(), "Randomization failed")
        end
      end
    end else begin
      // Create legal transaction near boundary
      if(write_only_mode) begin
        // Write-only mode for write sequencer with proper AWID constraints
        if(use_bus_matrix_addressing == 2) begin
          // 10x10 mode
          if(!req.randomize() with {
            transfer_type == BLOCKING_WRITE;
            awburst == WRITE_INCR;
            awaddr[63:12] == base_addr[63:12];
            awaddr[11:0] inside {[12'h000:12'hF00]};
            awlen inside {[0:15]};
            awid inside {[0:9]};
          }) begin
            `uvm_fatal(get_type_name(), "Randomization failed")
          end
        end else begin
          // 4x4 and NONE modes
          if(!req.randomize() with {
            transfer_type == BLOCKING_WRITE;
            awburst == WRITE_INCR;
            awaddr[63:12] == base_addr[63:12];
            awaddr[11:0] inside {[12'h000:12'hF00]};
            awlen inside {[0:15]};
            awid inside {[0:3]};
          }) begin
            `uvm_fatal(get_type_name(), "Randomization failed")
          end
        end
      end else begin
        // Normal mode - both read and write with proper ID constraints
        if(use_bus_matrix_addressing == 2) begin
          // 10x10 mode
          if(!req.randomize() with {
            transfer_type inside {BLOCKING_WRITE, BLOCKING_READ};
            awburst == WRITE_INCR;
            arburst == READ_INCR;
            awaddr[63:12] == base_addr[63:12];
            araddr[63:12] == base_addr[63:12];
            awaddr[11:0] inside {[12'h000:12'hF00]};
            araddr[11:0] inside {[12'h000:12'hF00]};
            awlen inside {[0:15]};
            arlen inside {[0:15]};
            awid inside {[0:9]};
            arid inside {[0:9]};
          }) begin
            `uvm_fatal(get_type_name(), "Randomization failed")
          end
        end else begin
          // 4x4 and NONE modes
          if(!req.randomize() with {
            transfer_type inside {BLOCKING_WRITE, BLOCKING_READ};
            awburst == WRITE_INCR;
            arburst == READ_INCR;
            awaddr[63:12] == base_addr[63:12];
            araddr[63:12] == base_addr[63:12];
            awaddr[11:0] inside {[12'h000:12'hF00]};
            araddr[11:0] inside {[12'h000:12'hF00]};
            awlen inside {[0:15]};
            arlen inside {[0:15]};
            awid inside {[0:3]};
            arid inside {[0:3]};
          }) begin
            `uvm_fatal(get_type_name(), "Randomization failed")
          end
        end
      end
    end
    finish_item(req);
    
    get_response(rsp);
  end
  
  `uvm_info(get_type_name(), "Completed 4KB boundary sequence", UVM_HIGH)
  
endtask : body

`endif