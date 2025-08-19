`ifndef AXI4_MASTER_MIDBURST_RESET_WRITE_SEQ_INCLUDED_
`define AXI4_MASTER_MIDBURST_RESET_WRITE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_midburst_reset_write_seq
// Sequence to test reset injection during a long write burst
// Triggers reset in the middle of a LEN=255 write transaction
//--------------------------------------------------------------------------------------------
class axi4_master_midburst_reset_write_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_midburst_reset_write_seq)

  // Configuration parameters
  rand int reset_after_beats = 100;  // Reset after this many beats
  rand int master_id = 0;
  rand int slave_id = 0;
  int use_bus_matrix_addressing = 0; // 0=NONE, 1=BASE_4x4, 2=ENHANCED_10x10
  
  constraint reset_point_c {
    reset_after_beats inside {[50:200]};
  }

  //--------------------------------------------------------------------------------------------
  // Externally defined Tasks and Functions
  //--------------------------------------------------------------------------------------------
  extern function new(string name = "axi4_master_midburst_reset_write_seq");
  extern task body();

endclass : axi4_master_midburst_reset_write_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the axi4_master_midburst_reset_write_seq class object
//
// Parameters:
//  name - axi4_master_midburst_reset_write_seq
//--------------------------------------------------------------------------------------------
function axi4_master_midburst_reset_write_seq::new(string name = "axi4_master_midburst_reset_write_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates a long write burst and triggers reset in the middle
//--------------------------------------------------------------------------------------------
task axi4_master_midburst_reset_write_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting mid-burst reset write sequence, reset after %0d beats", reset_after_beats), UVM_HIGH)
  
  // Create long write burst transaction
  req = axi4_master_tx::type_id::create("req");
  
  start_item(req);
  
  // Randomize with proper constraints based on bus matrix mode
  if(use_bus_matrix_addressing == 2) begin
    // ENHANCED mode (10x10)
    if(!req.randomize() with {
      awburst == WRITE_INCR;
      transfer_type == BLOCKING_WRITE;
      awsize == WRITE_4_BYTES;
      awlen == 255;  // Maximum burst length
      awid inside {[0:9]};  // Valid master IDs for 10x10
    }) begin
      `uvm_fatal(get_type_name(), "Randomization failed")
    end
    // Set address for ENHANCED mode
    req.awaddr = 64'h0000_0100_0000_2000;  // DDR Memory region
  end else begin
    // NONE or BASE mode (4x4)
    if(!req.randomize() with {
      awburst == WRITE_INCR;
      transfer_type == BLOCKING_WRITE;
      awsize == WRITE_4_BYTES;
      awlen == 255;  // Maximum burst length
      awid inside {[0:3]};  // Valid master IDs for 4x4
    }) begin
      `uvm_fatal(get_type_name(), "Randomization failed")
    end
    // Set address for 4x4 or NONE mode
    if(use_bus_matrix_addressing == 1) begin
      req.awaddr = 64'h0000_0100_0000_2000;  // DDR Memory region for BASE mode
    end else begin
      req.awaddr = 64'h0000_0000_0000_2000;  // Simple address for NONE mode
    end
  end
  
  finish_item(req);
  
  // Note: Reset will be injected by the test environment at the specified beat count
  // The sequence doesn't directly control reset but provides the long transaction
  
  // Try to get response (may fail due to reset)
  fork
    begin
      get_response(rsp);
      `uvm_info(get_type_name(), "Write transaction completed", UVM_HIGH)
    end
    begin
      #5us;  // Timeout in case reset prevents completion (optimized)
      `uvm_info(get_type_name(), "Write transaction timeout (expected during reset)", UVM_HIGH)
    end
  join_any
  disable fork;
  
endtask : body

`endif