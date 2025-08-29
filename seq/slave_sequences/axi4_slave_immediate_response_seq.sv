`ifndef AXI4_SLAVE_IMMEDIATE_RESPONSE_SEQ_INCLUDED_
`define AXI4_SLAVE_IMMEDIATE_RESPONSE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_immediate_response_seq
// Provides immediate OKAY responses for timing-critical tests
// Designed to minimize response latency and ensure proper master/slave coordination
//--------------------------------------------------------------------------------------------
class axi4_slave_immediate_response_seq extends axi4_slave_nbk_base_seq;
  `uvm_object_utils(axi4_slave_immediate_response_seq)

  // Configuration
  bit fixed_response_id = 1;  // Use fixed IDs for predictable responses
  bit immediate_mode = 1;     // Zero wait states for immediate response

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_slave_immediate_response_seq");
  extern task body();
  extern task generate_immediate_write_response();
  extern task generate_immediate_read_response();

endclass : axi4_slave_immediate_response_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//
// Parameters:
//  name - axi4_slave_immediate_response_seq
//--------------------------------------------------------------------------------------------
function axi4_slave_immediate_response_seq::new(string name = "axi4_slave_immediate_response_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates immediate slave response based on sequencer type
//--------------------------------------------------------------------------------------------
task axi4_slave_immediate_response_seq::body();
  string seqr_name;
  super.body();
  
  // Determine sequencer type for appropriate response
  seqr_name = m_sequencer.get_name();
  if(seqr_name.match(".*read.*")) begin
    generate_immediate_read_response();
  end else begin
    generate_immediate_write_response();
  end

endtask : body

//--------------------------------------------------------------------------------------------
// Task: generate_immediate_write_response
// Generate immediate write response with OKAY status
//--------------------------------------------------------------------------------------------
task axi4_slave_immediate_response_seq::generate_immediate_write_response();
  req.transfer_type = NON_BLOCKING_WRITE;
  
  start_item(req);
  
  // Manual assignment for fastest response (avoid randomization overhead)
  req.bresp = WRITE_OKAY;
  req.bid = fixed_response_id ? "BID_0" : $sformatf("BID_%0d", $urandom_range(0, 15));
  req.buser = 16'h0;
  
  if(immediate_mode) begin
    // Zero wait states for immediate response
    req.aw_wait_states = 0;
    req.w_wait_states = 0;
    req.b_wait_states = 0;
    req.ar_wait_states = 0;
    req.r_wait_states = 0;
  end else begin
    // Minimal wait states (1 cycle)
    req.aw_wait_states = 1;
    req.w_wait_states = 1; 
    req.b_wait_states = 1;
    req.ar_wait_states = 0;
    req.r_wait_states = 0;
  end
  
  `uvm_info("SLAVE_IMMEDIATE_RESP", "Generated immediate WRITE OKAY response", UVM_MEDIUM)
  
  finish_item(req);
endtask : generate_immediate_write_response

//--------------------------------------------------------------------------------------------
// Task: generate_immediate_read_response
// Generate immediate read response with OKAY status and valid data
//--------------------------------------------------------------------------------------------
task axi4_slave_immediate_response_seq::generate_immediate_read_response();
  req.transfer_type = NON_BLOCKING_READ;
  
  start_item(req);
  
  // Manual assignment for fastest response
  req.rresp = READ_OKAY;
  req.rid = fixed_response_id ? "RID_0" : $sformatf("RID_%0d", $urandom_range(0, 15));
  req.ruser = 16'h0;
  
  // Provide predictable data pattern
  for(int i = 0; i < req.rdata.size(); i++) begin
    req.rdata[i] = 32'hCAFEBABE + i;  // Incrementing pattern for debug
  end
  
  if(immediate_mode) begin
    // Zero wait states for immediate response
    req.aw_wait_states = 0;
    req.w_wait_states = 0;
    req.b_wait_states = 0;
    req.ar_wait_states = 0;
    req.r_wait_states = 0;
  end else begin
    // Minimal wait states (1 cycle)
    req.aw_wait_states = 0;
    req.w_wait_states = 0;
    req.b_wait_states = 0;
    req.ar_wait_states = 1;
    req.r_wait_states = 1;
  end
  
  `uvm_info("SLAVE_IMMEDIATE_RESP", "Generated immediate READ OKAY response with data pattern", UVM_MEDIUM)
  
  finish_item(req);
endtask : generate_immediate_read_response

`endif