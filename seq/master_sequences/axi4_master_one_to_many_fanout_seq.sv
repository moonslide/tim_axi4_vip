`ifndef AXI4_MASTER_ONE_TO_MANY_FANOUT_SEQ_INCLUDED_
`define AXI4_MASTER_ONE_TO_MANY_FANOUT_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_one_to_many_fanout_seq
// Single master accessing multiple slaves
//--------------------------------------------------------------------------------------------
class axi4_master_one_to_many_fanout_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_one_to_many_fanout_seq)

  rand int num_slaves = 10;
  rand int transactions_per_slave = 10;
  int use_bus_matrix_addressing = 0;  // 0=NONE, 1=4x4, 2=10x10
  bit write_only_mode = 0;  // Flag to force write-only transactions
  
  extern function new(string name = "axi4_master_one_to_many_fanout_seq");
  extern task body();

endclass : axi4_master_one_to_many_fanout_seq

function axi4_master_one_to_many_fanout_seq::new(string name = "axi4_master_one_to_many_fanout_seq");
  super.new(name);
endfunction : new

task axi4_master_one_to_many_fanout_seq::body();
  bit [63:0] slave_addr[10];
  
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting one-to-many fanout sequence, use_bus_matrix_addressing=%0d", use_bus_matrix_addressing), UVM_HIGH)
  
  // Initialize slave addresses based on bus matrix mode
  if (use_bus_matrix_addressing == 1) begin
    // 4x4 base matrix addresses
    slave_addr[0] = 64'h0000_0100_0000_0000;  // S0: DDR Memory
    slave_addr[1] = 64'h0000_0000_0000_0000;  // S1: Boot_ROM
    slave_addr[2] = 64'h0000_0010_0000_0000;  // S2: Peripheral_Regs
    slave_addr[3] = 64'h0000_0020_0000_0000;  // S3: HW_Fuse_Box
    // Only 4 slaves in 4x4 mode - reuse addresses for indices 4-9
    for(int i = 4; i < 10; i++) begin
      slave_addr[i] = slave_addr[i % 4];
    end
    `uvm_info(get_type_name(), "Using 4x4 bus matrix addresses", UVM_MEDIUM)
  end else if (use_bus_matrix_addressing == 2) begin
    // 10x10 enhanced matrix addresses
    slave_addr[0] = 64'h0000_0008_0000_0000;  // S0: DDR Secure
    slave_addr[1] = 64'h0000_0008_4000_0000;  // S1: DDR Non-Secure
    slave_addr[2] = 64'h0000_0008_8000_0000;  // S2: DDR Shared
    slave_addr[3] = 64'h0000_0008_C000_0000;  // S3: Illegal Hole
    slave_addr[4] = 64'h0000_0009_0000_0000;  // S4: XOM
    slave_addr[5] = 64'h0000_000A_0000_0000;  // S5: RO Peripheral
    slave_addr[6] = 64'h0000_000A_0001_0000;  // S6: Privileged-Only
    slave_addr[7] = 64'h0000_000A_0002_0000;  // S7: Secure-Only
    slave_addr[8] = 64'h0000_000A_0003_0000;  // S8: Scratchpad
    slave_addr[9] = 64'h0000_000A_0004_0000;  // S9: Attribute Monitor
    `uvm_info(get_type_name(), "Using 10x10 enhanced matrix addresses", UVM_MEDIUM)
  end else begin
    // NONE mode - simple addresses
    slave_addr[0] = 64'h0000_0000_0000_0000;  // S0
    slave_addr[1] = 64'h0000_0001_0000_0000;  // S1
    slave_addr[2] = 64'h0000_0002_0000_0000;  // S2
    slave_addr[3] = 64'h0000_0003_0000_0000;  // S3
    // Only 4 slaves in NONE mode - reuse addresses for indices 4-9
    for(int i = 4; i < 10; i++) begin
      slave_addr[i] = slave_addr[i % 4];
    end
    `uvm_info(get_type_name(), "Using NONE mode simple addresses", UVM_MEDIUM)
  end
  
  for(int s = 0; s < num_slaves; s++) begin
    for(int i = 0; i < transactions_per_slave; i++) begin
      req = axi4_master_tx::type_id::create("req");
      
      start_item(req);
      if(write_only_mode) begin
        // Write-only mode for write sequencer
        if(!req.randomize() with {
          transfer_type == NON_BLOCKING_WRITE;
          awaddr[63:16] == slave_addr[s][63:16];
          awburst == WRITE_INCR;
        }) begin
          `uvm_fatal(get_type_name(), "Randomization failed")
        end
      end else begin
        // Normal mode - both read and write
        if(!req.randomize() with {
          transfer_type inside {NON_BLOCKING_WRITE, NON_BLOCKING_READ};
          awaddr[63:16] == slave_addr[s][63:16];
          araddr[63:16] == slave_addr[s][63:16];
          awburst == WRITE_INCR;
          arburst == READ_INCR;
        }) begin
          `uvm_fatal(get_type_name(), "Randomization failed")
        end
      end
      finish_item(req);
    end
  end
  
  `uvm_info(get_type_name(), "Completed one-to-many fanout sequence", UVM_HIGH)
  
endtask : body

`endif