`ifndef AXI4_SLAVE_INJECT_RESPONSE_SEQ_INCLUDED_
`define AXI4_SLAVE_INJECT_RESPONSE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_inject_response_seq
// Continuous slave response sequence for X injection testing
//--------------------------------------------------------------------------------------------
class axi4_slave_inject_response_seq extends axi4_slave_base_seq;
  `uvm_object_utils(axi4_slave_inject_response_seq)

  // Number of responses to generate
  int num_responses = 10;
  
  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_slave_inject_response_seq");
    super.new(name);
  endfunction : new

  //--------------------------------------------------------------------------------------------
  // Task: body
  // Continuously responds to slave requests
  //--------------------------------------------------------------------------------------------
  task body();
    repeat(num_responses) begin
      req = axi4_slave_tx::type_id::create("req");
      
      start_item(req);
      
      // Simple OK response
      if (!req.randomize() with {
        bresp == axi4_globals_pkg::WRITE_OKAY;
      }) begin
        `uvm_error(get_type_name(), "Randomization failed")
      end
      
      finish_item(req);
      
      // Small delay between responses
      #1ns;
    end
  endtask : body

endclass : axi4_slave_inject_response_seq

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_inject_read_response_seq
// Continuous slave read response sequence
//--------------------------------------------------------------------------------------------
class axi4_slave_inject_read_response_seq extends axi4_slave_base_seq;
  `uvm_object_utils(axi4_slave_inject_read_response_seq)

  // Number of responses to generate
  int num_responses = 10;
  
  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_slave_inject_read_response_seq");
    super.new(name);
  endfunction : new

  //--------------------------------------------------------------------------------------------
  // Task: body
  //--------------------------------------------------------------------------------------------
  task body();
    repeat(num_responses) begin
      req = axi4_slave_tx::type_id::create("req");
      
      start_item(req);
      
      // Simple OK response with random data
      if (!req.randomize() with {
        rresp == axi4_globals_pkg::READ_OKAY;
      }) begin
        `uvm_error(get_type_name(), "Randomization failed")
      end
      
      finish_item(req);
      
      // Small delay between responses
      #1ns;
    end
  endtask : body

endclass : axi4_slave_inject_read_response_seq

`endif