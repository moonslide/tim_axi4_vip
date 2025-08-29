`ifndef AXI4_SLAVE_QOS_RESPONSE_SEQ_INCLUDED_
`define AXI4_SLAVE_QOS_RESPONSE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_qos_response_seq
// Slave sequence for QoS tests - provides immediate OKAY responses
//--------------------------------------------------------------------------------------------
class axi4_slave_qos_response_seq extends axi4_slave_nbk_base_seq;
  `uvm_object_utils(axi4_slave_qos_response_seq)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_slave_qos_response_seq");
  extern task body();
endclass : axi4_slave_qos_response_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//
// Parameters:
//  name - axi4_slave_qos_response_seq
//--------------------------------------------------------------------------------------------
function axi4_slave_qos_response_seq::new(string name = "axi4_slave_qos_response_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates slave response with OKAY for QoS testing
//--------------------------------------------------------------------------------------------
task axi4_slave_qos_response_seq::body();
  string seqr_name;
  bit is_read_seq;
  super.body();
  
  // Determine if this is read or write based on sequencer type
  seqr_name = m_sequencer.get_name();
  is_read_seq = seqr_name.match(".*read.*");
  
  if(is_read_seq) begin
    req.transfer_type = NON_BLOCKING_READ;
  end else begin
    req.transfer_type = NON_BLOCKING_WRITE;
  end
  
  start_item(req);
  
  // Optimized randomization for immediate, proper responses
  if(is_read_seq) begin
    // Read response configuration
    if(!req.randomize() with {
      req.transfer_type == NON_BLOCKING_READ;
      req.rresp == READ_OKAY;  // Always OKAY response
      req.rid == "RID_0";      // Default response ID
      req.ruser == 16'h0;      // Default user signals
      // Zero wait states for immediate response
      req.aw_wait_states == 0;
      req.w_wait_states == 0;
      req.b_wait_states == 0;
      req.ar_wait_states == 0;
      req.r_wait_states == 0;
      // Provide valid data
      foreach(req.rdata[i]) {
        req.rdata[i] == 'hDEADBEEF;  // Known pattern for debug
      }
    }) begin
      `uvm_fatal("axi4", "Read response randomization failed")
    end
    `uvm_info("SLAVE_QOS_RESPONSE_SEQ", "Generated READ OKAY response with zero wait states", UVM_HIGH)
  end else begin
    // Write response configuration  
    if(!req.randomize() with {
      req.transfer_type == NON_BLOCKING_WRITE;
      req.bresp == WRITE_OKAY;  // Always OKAY response
      req.bid == "BID_0";       // Default response ID
      req.buser == 16'h0;       // Default user signals
      // Zero wait states for immediate response
      req.aw_wait_states == 0;
      req.w_wait_states == 0;
      req.b_wait_states == 0;
      req.ar_wait_states == 0;
      req.r_wait_states == 0;
    }) begin
      `uvm_fatal("axi4", "Write response randomization failed")
    end
    `uvm_info("SLAVE_QOS_RESPONSE_SEQ", "Generated WRITE OKAY response with zero wait states", UVM_HIGH)
  end
  
  `uvm_info("SLAVE_QOS_RESPONSE_SEQ", $sformatf("QoS slave %s response ready", is_read_seq ? "READ" : "WRITE"), UVM_MEDIUM)
  
  finish_item(req);

endtask : body

`endif