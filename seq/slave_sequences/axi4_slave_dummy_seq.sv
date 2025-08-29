`ifndef AXI4_SLAVE_DUMMY_SEQ_INCLUDED_
`define AXI4_SLAVE_DUMMY_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_dummy_seq
// Dummy slave sequence that immediately returns without blocking
// Used when slaves need to be ACTIVE but no real transactions are needed
//--------------------------------------------------------------------------------------------
class axi4_slave_dummy_write_seq extends axi4_slave_base_seq;
  `uvm_object_utils(axi4_slave_dummy_write_seq)

  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_slave_dummy_write_seq");
    super.new(name);
  endfunction : new

  //--------------------------------------------------------------------------------------------
  // Task: body
  //--------------------------------------------------------------------------------------------
  task body();
    // Create a dummy response that will never be used
    req = axi4_slave_tx::type_id::create("req");
    
    // Start the item but immediately finish it
    start_item(req);
    
    // Set minimal valid configuration with IMMEDIATE AWREADY/WREADY response
    if (!req.randomize() with {
      bresp == axi4_globals_pkg::WRITE_OKAY;
      aw_wait_states == 0;  // CRITICAL: No wait states for AWREADY
      w_wait_states == 0;   // No wait states for WREADY
      b_wait_states == 0;   // No wait states for BVALID
    }) begin
      `uvm_error("axi4_slave_dummy_write_seq", "Randomization failed")
    end
    
    finish_item(req);
    
    // No delay - this is just to satisfy the driver's get_next_item call
  endtask : body

endclass : axi4_slave_dummy_write_seq

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_dummy_read_seq
//--------------------------------------------------------------------------------------------
class axi4_slave_dummy_read_seq extends axi4_slave_base_seq;
  `uvm_object_utils(axi4_slave_dummy_read_seq)

  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_slave_dummy_read_seq");
    super.new(name);
  endfunction : new

  //--------------------------------------------------------------------------------------------
  // Task: body
  //--------------------------------------------------------------------------------------------
  task body();
    // Create a dummy response
    req = axi4_slave_tx::type_id::create("req");
    
    start_item(req);
    
    // Set minimal valid configuration with IMMEDIATE ARREADY response
    if (!req.randomize() with {
      rresp == axi4_globals_pkg::READ_OKAY;
      ar_wait_states == 0;  // CRITICAL: No wait states for ARREADY
      r_wait_states == 0;   // No wait states for RVALID  
      rdata.size() == 1;    // Single data element for dummy response
    }) begin
      `uvm_error("axi4_slave_dummy_read_seq", "Randomization failed")
    end
    
    // Set predictable data pattern after randomization
    req.rdata[0] = 64'hDEADBEEF;
    
    finish_item(req);
  endtask : body

endclass : axi4_slave_dummy_read_seq

`endif