`ifndef AXI4_MASTER_QOS_ARBITRATION_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_ARBITRATION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_arbitration_seq
// Tests QoS arbitration with different priority levels
//--------------------------------------------------------------------------------------------
class axi4_master_qos_arbitration_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_qos_arbitration_seq)

  rand bit [3:0] qos_value;
  rand int num_transactions = 50;
  
  constraint qos_c {
    qos_value inside {4'h0, 4'h3, 4'h7, 4'hF};  // Different QoS levels
  }

  extern function new(string name = "axi4_master_qos_arbitration_seq");
  extern task body();

endclass : axi4_master_qos_arbitration_seq

function axi4_master_qos_arbitration_seq::new(string name = "axi4_master_qos_arbitration_seq");
  super.new(name);
endfunction : new

task axi4_master_qos_arbitration_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting QoS arbitration sequence with QoS=%0h", qos_value), UVM_HIGH)
  
  for(int i = 0; i < num_transactions; i++) begin
    req = axi4_master_tx::type_id::create("req");
    
    start_item(req);
    if(!req.randomize() with {
      transfer_type inside {NON_BLOCKING_WRITE, NON_BLOCKING_READ};
      awqos == qos_value;
      arqos == qos_value;
      awburst == WRITE_INCR;
      arburst == READ_INCR;
    }) begin
      `uvm_fatal(get_type_name(), "Randomization failed")
    end
    finish_item(req);
  end
  
  `uvm_info(get_type_name(), "Completed QoS arbitration sequence", UVM_HIGH)
  
endtask : body

`endif