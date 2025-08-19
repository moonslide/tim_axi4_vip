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
  int use_bus_matrix_addressing = 0;  // 0=NONE/4x4, 1=4x4, 2=10x10
  
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
  bit [63:0] base_addr;
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting QoS arbitration sequence with QoS=%0h, use_bus_matrix_addressing=%0d", qos_value, use_bus_matrix_addressing), UVM_HIGH)
  
  for(int i = 0; i < num_transactions; i++) begin
    req = axi4_master_tx::type_id::create("req");
    
    // Select base address based on bus matrix mode
    if(use_bus_matrix_addressing == 2) begin
      // 10x10 enhanced matrix - use valid slave addresses
      base_addr = 64'h0000_0100_0000_0000; // DDR Memory
    end else if(use_bus_matrix_addressing == 1) begin
      // 4x4 base matrix - use valid slave addresses  
      base_addr = 64'h0000_0100_0000_0000; // DDR Memory
    end else begin
      // NONE mode - use simple addresses
      base_addr = 64'h0000_0000_0000_0000;
    end
    
    start_item(req);
    // Constrain AWID/ARID based on bus matrix mode
    if(use_bus_matrix_addressing == 2) begin
      // 10x10 mode: IDs can be 0-9
      if(!req.randomize() with {
        transfer_type inside {NON_BLOCKING_WRITE, NON_BLOCKING_READ};
        awaddr[63:16] == base_addr[63:16];
        araddr[63:16] == base_addr[63:16];
        awqos == qos_value;
        arqos == qos_value;
        awburst == WRITE_INCR;
        arburst == READ_INCR;
        awid inside {[0:9]};
        arid inside {[0:9]};
      }) begin
        `uvm_fatal(get_type_name(), "Randomization failed")
      end
    end else begin
      // 4x4 and NONE modes: IDs must be 0-3
      if(!req.randomize() with {
        transfer_type inside {NON_BLOCKING_WRITE, NON_BLOCKING_READ};
        awaddr[63:16] == base_addr[63:16];
        araddr[63:16] == base_addr[63:16];
        awqos == qos_value;
        arqos == qos_value;
        awburst == WRITE_INCR;
        arburst == READ_INCR;
        awid inside {[0:3]};
        arid inside {[0:3]};
      }) begin
        `uvm_fatal(get_type_name(), "Randomization failed")
      end
    end
    finish_item(req);
  end
  
  `uvm_info(get_type_name(), "Completed QoS arbitration sequence", UVM_HIGH)
  
endtask : body

`endif