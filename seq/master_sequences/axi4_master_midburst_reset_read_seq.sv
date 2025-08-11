`ifndef AXI4_MASTER_MIDBURST_RESET_READ_SEQ_INCLUDED_
`define AXI4_MASTER_MIDBURST_RESET_READ_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_midburst_reset_read_seq
// Sequence to test reset injection during a long read burst
// Triggers reset in the middle of a LEN=255 read transaction
//--------------------------------------------------------------------------------------------
class axi4_master_midburst_reset_read_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_midburst_reset_read_seq)

  // Configuration parameters
  rand int reset_after_beats = 128;  // Reset after this many beats
  rand int master_id = 0;
  rand int slave_id = 0;
  
  constraint reset_point_c {
    reset_after_beats inside {[50:200]};
  }

  //--------------------------------------------------------------------------------------------
  // Externally defined Tasks and Functions
  //--------------------------------------------------------------------------------------------
  extern function new(string name = "axi4_master_midburst_reset_read_seq");
  extern task body();

endclass : axi4_master_midburst_reset_read_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the axi4_master_midburst_reset_read_seq class object
//
// Parameters:
//  name - axi4_master_midburst_reset_read_seq
//--------------------------------------------------------------------------------------------
function axi4_master_midburst_reset_read_seq::new(string name = "axi4_master_midburst_reset_read_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates a long read burst and triggers reset in the middle
//--------------------------------------------------------------------------------------------
task axi4_master_midburst_reset_read_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting mid-burst reset read sequence, reset after %0d beats", reset_after_beats), UVM_HIGH)
  
  // Create long read burst transaction
  req = axi4_master_tx::type_id::create("req");
  
  start_item(req);
  if(!req.randomize() with {
    arburst == READ_INCR;
    transfer_type == BLOCKING_READ;
    arsize == READ_4_BYTES;
    arlen == 255;  // Maximum burst length
    arid == master_id;
  }) begin
    `uvm_fatal(get_type_name(), "Randomization failed")
  end
  
  // Set address based on slave_id (using enhanced bus matrix ranges)
  case(slave_id)
    0: req.araddr = 64'h0000_0008_0000_1000;  // S0: DDR Secure Kernel
    1: req.araddr = 64'h0000_0008_4000_1000;  // S1: DDR Non-Secure User
    2: req.araddr = 64'h0000_0008_8000_1000;  // S2: DDR Shared Buffer
    default: req.araddr = 64'h0000_0008_0000_1000;
  endcase
  
  finish_item(req);
  
  // Note: Reset will be injected by the test environment at the specified beat count
  // The sequence doesn't directly control reset but provides the long transaction
  
  // Try to get response (may fail due to reset)
  fork
    begin
      get_response(rsp);
      `uvm_info(get_type_name(), "Read transaction completed", UVM_HIGH)
    end
    begin
      #500us;  // Timeout in case reset prevents completion
      `uvm_info(get_type_name(), "Read transaction timeout (expected during reset)", UVM_HIGH)
    end
  join_any
  disable fork;
  
endtask : body

`endif