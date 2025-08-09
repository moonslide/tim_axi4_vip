`ifndef AXI4_MASTER_QOS_USER_BOOST_WRITE_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_USER_BOOST_WRITE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_user_boost_write_seq
// Master sequence for QoS write transactions with USER-based priority boosting
//--------------------------------------------------------------------------------------------
class axi4_master_qos_user_boost_write_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_qos_user_boost_write_seq)

  // QoS base priority value (1-15)
  rand bit [3:0] base_qos_value;
  
  // USER signal boost value (0-15)
  rand bit [3:0] user_boost_value;
  
  // Enable USER boost flag
  rand bit user_boost_enable;

  // Constraints
  constraint valid_qos_c {
    base_qos_value inside {1, 2, 4, 8};  // Use common QoS values
  }
  
  constraint valid_boost_c {
    user_boost_value inside {0, 2, 4, 8};  // Boost values
    user_boost_enable inside {0, 1};
  }

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_qos_user_boost_write_seq");
  extern task body();

endclass : axi4_master_qos_user_boost_write_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the sequence
//
// Parameters:
//  name - axi4_master_qos_user_boost_write_seq
//--------------------------------------------------------------------------------------------
function axi4_master_qos_user_boost_write_seq::new(string name = "axi4_master_qos_user_boost_write_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates and sends the write transaction with QoS and USER priority boost
//--------------------------------------------------------------------------------------------
task axi4_master_qos_user_boost_write_seq::body();
  bit [3:0] effective_qos;
  bit [31:0] user_signal;
  
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  
  // Calculate effective QoS (base + boost if enabled)
  if(user_boost_enable) begin
    effective_qos = base_qos_value + user_boost_value;
    if(effective_qos > 15) effective_qos = 15;  // Cap at maximum
  end
  else begin
    effective_qos = base_qos_value;
  end
  
  // Encode USER signal: [31:8]=reserved, [7:4]=boost_enable, [3:0]=boost_value
  user_signal = {24'h0, user_boost_enable, 3'b0, user_boost_value};
  
  if(!req.randomize() with {
    req.transfer_type == NON_BLOCKING_WRITE;
    req.awqos == base_qos_value;  // Use base QoS in protocol
    req.awuser == user_signal;     // USER carries boost info
    req.awburst == WRITE_INCR;
    req.awsize == WRITE_4_BYTES;
    req.awlen == 8'h00;  // Single beat burst
    req.awaddr inside {[64'h8_0000_0000:64'h8_3FFF_FFF0],  // Slave 0
                       [64'h8_4000_0000:64'h8_7FFF_FFF0],  // Slave 1
                       [64'h8_8000_0000:64'h8_BFFF_FFF0],  // Slave 2
                       [64'hA_0001_0000:64'hA_0001_FFF0],  // Slave 6
                       [64'hA_0002_0000:64'hA_0002_FFF0],  // Slave 7
                       [64'hA_0003_0000:64'hA_0003_FFF0]}; // Slave 8
  }) begin
    `uvm_fatal("axi4", "Randomization failed for QoS USER boost write sequence")
  end
  
  `uvm_info(get_type_name(), $sformatf("QoS+USER Write - Base QoS: %0h, USER Boost: %0s (value=%0h), Effective QoS: %0h, Address: %0h", 
            base_qos_value, user_boost_enable ? "ENABLED" : "DISABLED", user_boost_value, effective_qos, req.awaddr), UVM_MEDIUM)
  
  finish_item(req);
  
endtask : body

`endif