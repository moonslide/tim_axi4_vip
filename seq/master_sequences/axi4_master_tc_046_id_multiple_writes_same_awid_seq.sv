`ifndef AXI4_MASTER_TC_046_ID_OUT_OF_ORDER_NO_INTERLEAVING_SEQ_INCLUDED_
`define AXI4_MASTER_TC_046_ID_OUT_OF_ORDER_NO_INTERLEAVING_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tc_046_id_out_of_order_no_interleaving_seq
// TC_046: AXI4 Out-of-Order Transaction Test with No Write Interleaving
// Complex test scenario using multiple AWIDs to demonstrate out-of-order completion
// while ensuring NO write data interleaving per AXI4 specification
//
// Test Architecture based on AXI_MATRIX.txt:
// - M0 (CPU_Core_A): Can access S0 (DDR R/W), S2 (Peripheral R/W), S3 (HW_Fuse R-Only)
// - M1 (CPU_Core_B): Can access S0 (DDR R/W), S2 (Peripheral R/W)
// - M2 (DMA_Controller): Can access S0 (DDR R/W), S2 (Peripheral R/W)
// - M3 (GPU): Can access S0 (DDR R/W), S3 (HW_Fuse R-Only)
// 
// Address Ranges:
// - S0: DDR_Memory: 0x0000_0100_0000_0000+ (R/W)
// - S2: Peripheral_Regs: 0x0000_0010_0000_0000+ (R/W)
// - S3: HW_Fuse_Box: 0x0000_0020_0000_0000+ (R-Only)
// 
// AXI4 Specification Requirements Tested:
//   1. Write data interleaving is NOT supported in AXI4 (Section A5.4)
//   2. Out-of-order completion allowed for different AWIDs (Section A5.3)
//   3. Each transaction's write data must be consecutive
//   4. Responses can return in any order for different AWIDs
//   5. Same AWID to same slave must maintain order (Non-modifiable)
//   6. Proper handling of read-only slaves (S3)
//--------------------------------------------------------------------------------------------
class axi4_master_tc_046_id_out_of_order_no_interleaving_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_tc_046_id_out_of_order_no_interleaving_seq)

  // Master ID for this sequence (will be set by virtual sequence)
  int master_id = 0;
  
  // Predictive data structures to track expected writes
  typedef struct {
    bit [63:0] addr;
    bit [31:0] data;
    int slave_id;
    bit valid;
  } predicted_write_t;
  
  predicted_write_t predicted_writes[$];  // Queue of expected writes
  
  extern function new(string name = "axi4_master_tc_046_id_out_of_order_no_interleaving_seq");
  extern task body();
  extern function void add_predicted_write(bit [63:0] addr, bit [31:0] data, int slave_id);
  extern function void get_predicted_writes(ref predicted_write_t result[$]);
endclass : axi4_master_tc_046_id_out_of_order_no_interleaving_seq

function axi4_master_tc_046_id_out_of_order_no_interleaving_seq::new(string name = "axi4_master_tc_046_id_out_of_order_no_interleaving_seq");
  super.new(name);
endfunction : new

function void axi4_master_tc_046_id_out_of_order_no_interleaving_seq::add_predicted_write(bit [63:0] addr, bit [31:0] data, int slave_id);
  predicted_write_t pred_write;
  pred_write.addr = addr;
  pred_write.data = data;
  pred_write.slave_id = slave_id;
  pred_write.valid = 1;
  predicted_writes.push_back(pred_write);
  `uvm_info(get_type_name(), $sformatf("TC_046: Master[%0d] Predicted write: ADDR=0x%16h, DATA=0x%8h, SLAVE=%0d", 
           master_id, addr, data, slave_id), UVM_DEBUG);
endfunction : add_predicted_write

function void axi4_master_tc_046_id_out_of_order_no_interleaving_seq::get_predicted_writes(ref predicted_write_t result[$]);
  result = predicted_writes;
endfunction : get_predicted_writes

task axi4_master_tc_046_id_out_of_order_no_interleaving_seq::body();
  
  `uvm_info(get_type_name(), $sformatf("TC_046: Master[%0d] Starting AXI4 Out-of-Order Test per AXI_MATRIX.txt", master_id), UVM_LOW);
  
  // Clear predicted writes queue
  predicted_writes.delete();
  
  // Based on AXI_MATRIX.txt access patterns:
  // M0 (CPU_Core_A): Can access S0 (DDR R/W), S2 (Peripheral R/W), S3 (HW_Fuse R-Only)
  // M1 (CPU_Core_B): Can access S0 (DDR R/W), S2 (Peripheral R/W)
  // M2 (DMA_Controller): Can access S0 (DDR R/W), S2 (Peripheral R/W)
  // M3 (GPU): Can access S0 (DDR R/W), S3 (HW_Fuse R-Only)
  
  // Transaction T1: All masters write to DDR (S0) - 4-beat burst
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == WRITE;
    req.awid == (master_id * 4);  // Master 0: AWID=0, Master 1: AWID=4, etc.
    req.awaddr == 64'h0000_0100_0000_0000 + (master_id * 'h1000) + 'h100; // DDR with master offset
    req.awlen == 4'h3;  // 4 beats
    req.awsize == WRITE_4_BYTES;
    req.awburst == WRITE_INCR;
    req.awcache == 4'b0010; // Modifiable to allow out-of-order
    req.wdata.size() == 4;
    foreach(req.wdata[i]) req.wdata[i] == 32'h1000_0000 + (master_id << 16) + i;
    req.wstrb.size() == 4;
    foreach(req.wstrb[i]) req.wstrb[i] == 4'hF;
    req.wuser == 4'h0;
  });
  finish_item(req);
  
  // Add predicted writes for T1
  foreach(req.wdata[i]) begin
    add_predicted_write(req.awaddr + (i * 4), req.wdata[i], 0); // S0 = DDR
  end
  
  `uvm_info(get_type_name(), $sformatf("TC_046: Master[%0d] T1 - AWID=0x%0x to S0 (DDR), AWADDR=0x%16h, AWLEN=%0d", 
           master_id, req.awid, req.awaddr, req.awlen), UVM_LOW);
  
  // Transaction T2: Master-specific secondary access
  if (master_id == 0 || master_id == 1 || master_id == 2) begin
    // M0, M1, M2 can write to Peripheral (S2)
    req = axi4_master_tx::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      req.tx_type == WRITE;
      req.awid == (master_id * 4) + 1;  // Different AWID for out-of-order
      req.awaddr == 64'h0000_0010_0000_0000 + (master_id * 'h1000) + 'h200; // Peripheral with master offset
      req.awlen == 4'h0;  // 1 beat
      req.awsize == WRITE_4_BYTES;
      req.awburst == WRITE_INCR;
      req.awcache == 4'b0010; // Modifiable
      req.wdata.size() == 1;
      req.wdata[0] == 32'h2000_0000 + (master_id << 16);
      req.wstrb.size() == 1;
      req.wstrb[0] == 4'hF;
      req.wuser == 4'h0;
    });
    finish_item(req);
    
    add_predicted_write(req.awaddr, req.wdata[0], 2); // S2 = Peripheral
    
    `uvm_info(get_type_name(), $sformatf("TC_046: Master[%0d] T2 - AWID=0x%0x to S2 (Peripheral), AWADDR=0x%16h", 
             master_id, req.awid, req.awaddr), UVM_LOW);
  end else if (master_id == 3) begin
    // M3 (GPU) can only read from HW_Fuse (S3) - no write, just read
    req = axi4_master_tx::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      req.tx_type == READ;
      req.arid == (master_id * 4) + 1;  // Different ARID for out-of-order
      req.araddr == 64'h0000_0020_0000_0000 + 'h10; // HW_Fuse_Box
      req.arlen == 4'h0;  // 1 beat
      req.arsize == READ_4_BYTES;
      req.arburst == READ_INCR;
    });
    finish_item(req);
    
    `uvm_info(get_type_name(), $sformatf("TC_046: Master[%0d] T2 - ARID=0x%0x to S3 (HW_Fuse) READ, ARADDR=0x%16h", 
             master_id, req.arid, req.araddr), UVM_LOW);
  end
  
  // Transaction T3: Same AWID as T1 to DDR - Must maintain order
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {
    req.tx_type == WRITE;
    req.awid == (master_id * 4);  // Same AWID as T1
    req.awaddr == 64'h0000_0100_0000_0000 + (master_id * 'h1000) + 'h300; // DDR with different offset
    req.awlen == 4'h1;  // 2 beats
    req.awsize == WRITE_4_BYTES;
    req.awburst == WRITE_INCR;
    req.awcache == 4'b0000; // Non-modifiable - Must maintain order with T1
    req.wdata.size() == 2;
    req.wdata[0] == 32'h3000_0000 + (master_id << 16);
    req.wdata[1] == 32'h3000_0001 + (master_id << 16);
    req.wstrb.size() == 2;
    req.wstrb[0] == 4'hF;
    req.wstrb[1] == 4'hF;
    req.wuser == 4'h0;
  });
  finish_item(req);
  
  // Add predicted writes for T3
  foreach(req.wdata[i]) begin
    add_predicted_write(req.awaddr + (i * 4), req.wdata[i], 0); // S0 = DDR
  end
  
  `uvm_info(get_type_name(), $sformatf("TC_046: Master[%0d] T3 - AWID=0x%0x to S0 (DDR), AWADDR=0x%16h (2-beat, Non-mod)", 
           master_id, req.awid, req.awaddr), UVM_LOW);
  
  // Transaction T4: Additional access based on master capability
  if (master_id == 0) begin
    // M0 can read from HW_Fuse (S3) - read only
    req = axi4_master_tx::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      req.tx_type == READ;
      req.arid == (master_id * 4) + 2;  // Different ARID for out-of-order
      req.araddr == 64'h0000_0020_0000_0000 + 'h20; // HW_Fuse_Box
      req.arlen == 4'h0;  // 1 beat
      req.arsize == READ_4_BYTES;
      req.arburst == READ_INCR;
    });
    finish_item(req);
    
    `uvm_info(get_type_name(), $sformatf("TC_046: Master[%0d] T4 - ARID=0x%0x to S3 (HW_Fuse) READ, ARADDR=0x%16h", 
             master_id, req.arid, req.araddr), UVM_LOW);
  end else if (master_id == 1 || master_id == 2) begin
    // M1, M2 can write to Peripheral (S2) with different AWID
    req = axi4_master_tx::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      req.tx_type == WRITE;
      req.awid == (master_id * 4) + 2;  // Different AWID for out-of-order
      req.awaddr == 64'h0000_0010_0000_0000 + (master_id * 'h1000) + 'h400; // Peripheral with different offset
      req.awlen == 4'h0;  // 1 beat
      req.awsize == WRITE_4_BYTES;
      req.awburst == WRITE_INCR;
      req.awcache == 4'b0010; // Modifiable
      req.wdata.size() == 1;
      req.wdata[0] == 32'h4000_0000 + (master_id << 16);
      req.wstrb.size() == 1;
      req.wstrb[0] == 4'hF;
      req.wuser == 4'h0;
    });
    finish_item(req);
    
    add_predicted_write(req.awaddr, req.wdata[0], 2); // S2 = Peripheral
    
    `uvm_info(get_type_name(), $sformatf("TC_046: Master[%0d] T4 - AWID=0x%0x to S2 (Peripheral), AWADDR=0x%16h", 
             master_id, req.awid, req.awaddr), UVM_LOW);
  end else if (master_id == 3) begin
    // M3 can write to DDR (S0) with different AWID
    req = axi4_master_tx::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      req.tx_type == WRITE;
      req.awid == (master_id * 4) + 2;  // Different AWID for out-of-order
      req.awaddr == 64'h0000_0100_0000_0000 + (master_id * 'h1000) + 'h400; // DDR with different offset
      req.awlen == 4'h1;  // 2 beats
      req.awsize == WRITE_4_BYTES;
      req.awburst == WRITE_INCR;
      req.awcache == 4'b0010; // Modifiable
      req.wdata.size() == 2;
      req.wdata[0] == 32'h4000_0000 + (master_id << 16);
      req.wdata[1] == 32'h4000_0001 + (master_id << 16);
      req.wstrb.size() == 2;
      req.wstrb[0] == 4'hF;
      req.wstrb[1] == 4'hF;
      req.wuser == 4'h0;
    });
    finish_item(req);
    
    // Add predicted writes for T4
    foreach(req.wdata[i]) begin
      add_predicted_write(req.awaddr + (i * 4), req.wdata[i], 0); // S0 = DDR
    end
    
    `uvm_info(get_type_name(), $sformatf("TC_046: Master[%0d] T4 - AWID=0x%0x to S0 (DDR), AWADDR=0x%16h (2-beat)", 
             master_id, req.awid, req.awaddr), UVM_LOW);
  end
  
  `uvm_info(get_type_name(), $sformatf("TC_046: Master[%0d] completed sending all transactions", master_id), UVM_LOW);
  `uvm_info(get_type_name(), "TC_046: Expected behavior per AXI4 spec:", UVM_LOW);
  `uvm_info(get_type_name(), "  - T1 and T3 (same AWID, Non-mod) must complete in order", UVM_LOW);
  `uvm_info(get_type_name(), "  - T2 and T4 (different AWIDs) can complete out-of-order", UVM_LOW);
  `uvm_info(get_type_name(), "  - NO write data interleaving between transactions", UVM_LOW);
  `uvm_info(get_type_name(), "  - Each transaction's write data is consecutive", UVM_LOW);
  `uvm_info(get_type_name(), "  - S3 (HW_Fuse) is read-only - no write attempts", UVM_LOW);
  
  `uvm_info(get_type_name(), $sformatf("TC_046: Master[%0d] predicted %0d write transactions", master_id, predicted_writes.size()), UVM_LOW);

endtask : body

`endif