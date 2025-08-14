`ifndef AXI4_MASTER_MIXED_BURST_LENGTHS_SEQ_INCLUDED_
`define AXI4_MASTER_MIXED_BURST_LENGTHS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_mixed_burst_lengths_seq
// Transactions with various burst lengths (1 to 256)
//--------------------------------------------------------------------------------------------
class axi4_master_mixed_burst_lengths_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_mixed_burst_lengths_seq)

  rand int num_transactions = 50;
  int use_bus_matrix_addressing = 0;  // 0=NONE, 1=4x4, 2=10x10
  bit write_only_mode = 0;  // Flag to force write-only transactions
  
  extern function new(string name = "axi4_master_mixed_burst_lengths_seq");
  extern task body();

endclass : axi4_master_mixed_burst_lengths_seq

function axi4_master_mixed_burst_lengths_seq::new(string name = "axi4_master_mixed_burst_lengths_seq");
  super.new(name);
endfunction : new

task axi4_master_mixed_burst_lengths_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting mixed burst lengths sequence, use_bus_matrix_addressing=%0d", use_bus_matrix_addressing), UVM_HIGH)
  
  for(int i = 0; i < num_transactions; i++) begin
    req = axi4_master_tx::type_id::create("req");
    
    start_item(req);
    if(write_only_mode) begin
      // Write-only mode for write sequencer
      if(use_bus_matrix_addressing == 1) begin
        // For 4x4 base matrix mode, use DDR memory address range
        if(!req.randomize() with {
          transfer_type == BLOCKING_WRITE;
          awaddr inside {[64'h0000_0100_0000_0000:64'h0000_0100_00FF_FFFF]};  // 4x4 DDR range
          awburst == WRITE_INCR;
          awlen inside {0, 1, 3, 7, 15, 31, 63, 127, 255};  // Various burst lengths
        }) begin
          `uvm_fatal(get_type_name(), "Randomization failed")
        end
      end else if(use_bus_matrix_addressing == 2) begin
        // For 10x10 enhanced matrix mode, use DDR addresses
        if(!req.randomize() with {
          transfer_type == BLOCKING_WRITE;
          awaddr inside {[64'h0000_0008_0000_0000:64'h0000_0008_00FF_FFFF]};  // 10x10 DDR range
          awburst == WRITE_INCR;
          awlen inside {0, 1, 3, 7, 15, 31, 63, 127, 255};  // Various burst lengths
        }) begin
          `uvm_fatal(get_type_name(), "Randomization failed")
        end
      end else begin
        // For NONE mode, use default random addresses
        if(!req.randomize() with {
          transfer_type == BLOCKING_WRITE;
          awburst == WRITE_INCR;
          awlen inside {0, 1, 3, 7, 15, 31, 63, 127, 255};  // Various burst lengths
        }) begin
          `uvm_fatal(get_type_name(), "Randomization failed")
        end
      end
    end else begin
      // Normal mode - both read and write
      if(use_bus_matrix_addressing) begin
        // For bus matrix modes, use DDR memory address range
        if(!req.randomize() with {
          transfer_type inside {BLOCKING_WRITE, BLOCKING_READ};
          awaddr inside {[64'h0000_0100_0000_0000:64'h0000_0100_00FF_FFFF]};  // DDR range
          araddr inside {[64'h0000_0100_0000_0000:64'h0000_0100_00FF_FFFF]};
          awburst == WRITE_INCR;
          arburst == READ_INCR;
          awlen inside {0, 1, 3, 7, 15, 31, 63, 127, 255};  // Various burst lengths
          arlen inside {0, 1, 3, 7, 15, 31, 63, 127, 255};
        }) begin
          `uvm_fatal(get_type_name(), "Randomization failed")
        end
      end else begin
        // For NONE mode, use default random addresses
        if(!req.randomize() with {
          transfer_type inside {BLOCKING_WRITE, BLOCKING_READ};
          awburst == WRITE_INCR;
          arburst == READ_INCR;
          awlen inside {0, 1, 3, 7, 15, 31, 63, 127, 255};  // Various burst lengths
          arlen inside {0, 1, 3, 7, 15, 31, 63, 127, 255};
        }) begin
          `uvm_fatal(get_type_name(), "Randomization failed")
        end
      end
    end
    finish_item(req);
    
    get_response(rsp);
  end
  
  `uvm_info(get_type_name(), "Completed mixed burst lengths sequence", UVM_HIGH)
  
endtask : body

`endif