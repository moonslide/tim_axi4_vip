`ifndef AXI4_MASTER_HOTSPOT_MANY_TO_ONE_SEQ_INCLUDED_
`define AXI4_MASTER_HOTSPOT_MANY_TO_ONE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_hotspot_many_to_one_seq
// Multiple masters targeting a single slave (hotspot)
//--------------------------------------------------------------------------------------------
class axi4_master_hotspot_many_to_one_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_hotspot_many_to_one_seq)

  rand int target_slave_id = 0;
  rand int num_transactions = 50;
  int use_bus_matrix_addressing = 0;  // 0=NONE, 1=4x4, 2=10x10
  bit write_only_mode = 0;  // Flag to force write-only transactions
  
  constraint slave_id_c {
    target_slave_id inside {[0:9]};
  }

  extern function new(string name = "axi4_master_hotspot_many_to_one_seq");
  extern task body();

endclass : axi4_master_hotspot_many_to_one_seq

function axi4_master_hotspot_many_to_one_seq::new(string name = "axi4_master_hotspot_many_to_one_seq");
  super.new(name);
endfunction : new

task axi4_master_hotspot_many_to_one_seq::body();
  bit [63:0] target_addr;
  
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting hotspot sequence targeting slave %0d, use_bus_matrix_addressing=%0d", target_slave_id, use_bus_matrix_addressing), UVM_HIGH)
  
  // Set target address based on addressing mode and slave_id
  if (use_bus_matrix_addressing == 1) begin
    // 4x4 BASE_BUS_MATRIX addresses
    case(target_slave_id)
      0: target_addr = 64'h0000_0100_0000_0000;  // S0: DDR Memory
      1: target_addr = 64'h0000_0000_0000_0000;  // S1: Boot ROM
      2: target_addr = 64'h0000_0010_0000_0000;  // S2: Peripheral Regs
      3: target_addr = 64'h0000_0020_0000_0000;  // S3: HW Fuse Box
      default: target_addr = 64'h0000_0100_0000_0000;  // Default to DDR
    endcase
    `uvm_info(get_type_name(), $sformatf("Using 4x4 bus matrix address: target_addr=0x%16h for slave %0d", target_addr, target_slave_id), UVM_MEDIUM)
  end else if (use_bus_matrix_addressing == 2) begin
    // 10x10 ENHANCED matrix addresses
    case(target_slave_id)
      0: target_addr = 64'h0000_0008_0000_0000;  // S0: DDR Secure
      1: target_addr = 64'h0000_0008_4000_0000;  // S1: DDR Non-Secure
      2: target_addr = 64'h0000_0008_8000_0000;  // S2: DDR Shared
      default: target_addr = 64'h0000_0008_0000_0000;  // Default to DDR Secure
    endcase
    `uvm_info(get_type_name(), $sformatf("Using 10x10 enhanced matrix address: target_addr=0x%16h for slave %0d", target_addr, target_slave_id), UVM_MEDIUM)
  end else begin
    // Use simple addresses for NONE mode (no bus matrix restrictions)
    case(target_slave_id)
      0: target_addr = 64'h0000_0000_0000_0000;  // S0
      1: target_addr = 64'h0000_0001_0000_0000;  // S1
      2: target_addr = 64'h0000_0002_0000_0000;  // S2
      3: target_addr = 64'h0000_0003_0000_0000;  // S3
      default: target_addr = 64'h0000_0000_0000_0000;  // Default to S0
    endcase
    `uvm_info(get_type_name(), $sformatf("Using NONE mode address: target_addr=0x%16h for slave %0d", target_addr, target_slave_id), UVM_MEDIUM)
  end
  
  for(int i = 0; i < num_transactions; i++) begin
    req = axi4_master_tx::type_id::create("req");
    
    start_item(req);
    if(write_only_mode) begin
      // Write-only mode for write sequencer
      if(!req.randomize() with {
        transfer_type == NON_BLOCKING_WRITE;
        awaddr[63:16] == target_addr[63:16];
        awburst == WRITE_INCR;
      }) begin
        `uvm_fatal(get_type_name(), "Randomization failed")
      end
    end else begin
      // Normal mode - both read and write
      if(!req.randomize() with {
        transfer_type inside {NON_BLOCKING_WRITE, NON_BLOCKING_READ};
        awaddr[63:16] == target_addr[63:16];
        araddr[63:16] == target_addr[63:16];
        awburst == WRITE_INCR;
        arburst == READ_INCR;
      }) begin
        `uvm_fatal(get_type_name(), "Randomization failed")
      end
    end
    finish_item(req);
  end
  
  `uvm_info(get_type_name(), "Completed hotspot sequence", UVM_HIGH)
  
endtask : body

`endif