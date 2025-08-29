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
  int use_bus_matrix_addressing = 0;  // 0=NONE/4x4, 1=4x4, 2=10x10
  
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
  bit [63:0] base_addr;
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting mid-burst reset read sequence, reset after %0d beats, use_bus_matrix_addressing=%0d", reset_after_beats, use_bus_matrix_addressing), UVM_HIGH)
  
  // Select base address based on bus matrix mode
  if(use_bus_matrix_addressing == 2) begin
    // 10x10 enhanced matrix - use DDR Memory for read
    base_addr = 64'h0000_0100_0000_0000;
  end else if(use_bus_matrix_addressing == 1) begin
    // 4x4 base matrix - use DDR Memory for read
    base_addr = 64'h0000_0100_0000_0000;
  end else begin
    // NONE mode - use simple address
    base_addr = 64'h0000_0000_0000_0000;
  end
  
  // Create long read burst transaction
  req = axi4_master_tx::type_id::create("req");
  
  start_item(req);
  // Constrain ARID based on bus matrix mode
  if(use_bus_matrix_addressing == 2) begin
    // 10x10 mode: master_id can be 0-9
    if(!req.randomize() with {
      arburst == READ_INCR;
      transfer_type == BLOCKING_READ;
      araddr[63:16] == base_addr[63:16];
      arsize == READ_4_BYTES;
      arlen == 255;  // Maximum burst length
      arid inside {[0:9]};
    }) begin
      `uvm_fatal(get_type_name(), "Randomization failed")
    end
  end else begin
    // 4x4 and NONE modes: master_id must be 0-3
    if(!req.randomize() with {
      arburst == READ_INCR;
      transfer_type == BLOCKING_READ;
      araddr[63:16] == base_addr[63:16];
      arsize == READ_4_BYTES;
      arlen == 255;  // Maximum burst length
      arid inside {[0:3]};
    }) begin
      `uvm_fatal(get_type_name(), "Randomization failed")
    end
  end
  
  // Set address based on slave_id (using enhanced bus matrix ranges)
  case(slave_id)
    0: req.araddr = 64'h0000_0008_0000_1000;  // S0: DDR Secure Kernel
    1: req.araddr = 64'h0000_0008_4000_1000;  // S1: DDR Non-Secure User
    2: req.araddr = 64'h0000_0008_8000_1000;  // S2: DDR Shared Buffer
    default: req.araddr = 64'h0000_0008_0000_1000;
  endcase
  
  finish_item(req);
  
  // Fork to inject reset mid-burst
  fork
    begin
      // Wait for specified number of beats (approximate timing)
      #(reset_after_beats * 10ns); // Assuming ~10ns per beat at 100MHz
      
      `uvm_info(get_type_name(), $sformatf("Injecting reset after ~%0d beats", reset_after_beats), UVM_MEDIUM)
      
      // Inject reset for 5-10 cycles
      uvm_config_db#(int)::set(null, "*", "reset_duration_cycles", 8);
      uvm_config_db#(bit)::set(null, "*", "reset_active", 1);
      uvm_config_db#(string)::set(null, "*", "reset_phase", "MID_READ_BURST");
      uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);
      
      // Wait for reset to complete
      #(100ns);
      
      // Clear reset flags
      uvm_config_db#(bit)::set(null, "*", "reset_active", 0);
    end
    begin
      // Try to get response (may fail due to reset)
      get_response(rsp);
      `uvm_info(get_type_name(), "Read transaction completed", UVM_HIGH)
    end
    begin
      #5us;  // Timeout in case reset prevents completion
      `uvm_info(get_type_name(), "Read transaction timeout (expected during reset)", UVM_HIGH)
    end
  join_any
  disable fork;
  
endtask : body

`endif