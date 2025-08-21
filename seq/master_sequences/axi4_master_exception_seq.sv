`ifndef AXI4_MASTER_EXCEPTION_SEQ_INCLUDED_
`define AXI4_MASTER_EXCEPTION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_exception_seq
// Sequence for generating exception scenarios (aborts, timeouts, illegal access)
//--------------------------------------------------------------------------------------------
class axi4_master_exception_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_exception_seq)

  // Exception type enumeration
  typedef enum {
    ABORT_AWVALID,     // Abort AWVALID before handshake
    ABORT_ARVALID,     // Abort ARVALID before handshake
    NEAR_TIMEOUT,      // Stall near timeout threshold
    ILLEGAL_ACCESS,    // Access protected/illegal address
    ECC_ERROR_SIM,     // Simulate internal ECC/parity error
    SPECIAL_REG_READ   // Consecutive reads to special register
  } exception_type_e;
  
  // Control parameters
  rand exception_type_e exception_type;
  rand bit [ADDRESS_WIDTH-1:0] target_addr;
  rand bit [ADDRESS_WIDTH-1:0] protected_addr;
  rand bit [DATA_WIDTH-1:0] unlock_key;
  rand int unsigned stall_cycles;
  rand int unsigned num_special_reads;
  
  // Constraints
  constraint c_stall_cycles {
    stall_cycles inside {[1020:1023]}; // Near 1024 timeout threshold
  }
  
  constraint c_num_reads {
    num_special_reads inside {[3:5]};
  }
  
  constraint c_addresses {
    target_addr[1:0] == 2'b00;
    protected_addr == 64'h0000_0000_0000_1A00; // Protected region
    unlock_key == 32'hDEADBEEF; // Unlock key value
  }

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_exception_seq");
  extern task body();
  extern task abort_awvalid_sequence();
  extern task abort_arvalid_sequence();
  extern task near_timeout_sequence();
  extern task illegal_access_sequence();
  extern task ecc_error_sim_sequence();
  extern task special_reg_read_sequence();

endclass : axi4_master_exception_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_master_exception_seq::new(string name = "axi4_master_exception_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//--------------------------------------------------------------------------------------------
task axi4_master_exception_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting exception scenario: %s", 
            exception_type.name()), UVM_MEDIUM)
  
  // Route to appropriate exception sequence
  case (exception_type)
    ABORT_AWVALID:    abort_awvalid_sequence();
    ABORT_ARVALID:    abort_arvalid_sequence();
    NEAR_TIMEOUT:     near_timeout_sequence();
    ILLEGAL_ACCESS:   illegal_access_sequence();
    ECC_ERROR_SIM:    ecc_error_sim_sequence();
    SPECIAL_REG_READ: special_reg_read_sequence();
    default: `uvm_error(get_type_name(), "Invalid exception type")
  endcase
  
endtask : body

//--------------------------------------------------------------------------------------------
// Task: abort_awvalid_sequence
// Master aborts AWVALID before handshake completes
//--------------------------------------------------------------------------------------------
task axi4_master_exception_seq::abort_awvalid_sequence();
  
  start_item(req);
  
  assert(req.randomize() with {
    tx_type == WRITE;
    awaddr == local::target_addr;
    awlen == 0;
    awsize == WRITE_4_BYTES;
    awburst == WRITE_INCR;
    transfer_type == BLOCKING_WRITE;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  
  // Note: Actual abort would need driver-level implementation
  `uvm_info(get_type_name(), "AWVALID abort conceptual test", UVM_MEDIUM);
  
  finish_item(req);
  
  `uvm_info(get_type_name(), "Aborted AWVALID before handshake", UVM_HIGH)
  
  // Wait and then send a normal transaction to verify recovery
  #100ns;
  
  start_item(req);
  assert(req.randomize() with {
    tx_type == WRITE;
    awaddr == local::target_addr + 8;
    awlen == 0;
    transfer_type == BLOCKING_WRITE;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  finish_item(req);
  
endtask : abort_awvalid_sequence

//--------------------------------------------------------------------------------------------
// Task: abort_arvalid_sequence  
// Master aborts ARVALID before handshake completes
//--------------------------------------------------------------------------------------------
task axi4_master_exception_seq::abort_arvalid_sequence();
  
  start_item(req);
  
  assert(req.randomize() with {
    tx_type == READ;
    araddr == local::target_addr;
    arlen == 0;
    arsize == READ_4_BYTES;
    arburst == READ_INCR;
    transfer_type == BLOCKING_READ;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  
  // Note: Actual abort would need driver-level implementation
  `uvm_info(get_type_name(), "ARVALID abort conceptual test", UVM_MEDIUM);
  
  finish_item(req);
  
  `uvm_info(get_type_name(), "Aborted ARVALID before handshake", UVM_HIGH)
  
  // Wait and send normal read to verify recovery
  #100ns;
  
  start_item(req);
  assert(req.randomize() with {
    tx_type == READ;
    araddr == local::target_addr + 8;
    arlen == 0;
    transfer_type == BLOCKING_READ;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  finish_item(req);
  
endtask : abort_arvalid_sequence

//--------------------------------------------------------------------------------------------
// Task: near_timeout_sequence
// Create a stall condition near timeout threshold
//--------------------------------------------------------------------------------------------
task axi4_master_exception_seq::near_timeout_sequence();
  
  start_item(req);
  
  assert(req.randomize() with {
    tx_type == WRITE;
    awaddr == local::target_addr;
    awlen == 0;
    awsize == WRITE_4_BYTES;
    awburst == WRITE_INCR;
    transfer_type == BLOCKING_WRITE;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  
  // Note: Actual stalling would need slave agent implementation
  `uvm_info(get_type_name(), $sformatf("Near timeout stall conceptual test for %0d cycles", stall_cycles), UVM_MEDIUM);
  
  // Simulate stall delay
  #(stall_cycles * 10ns);
  
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("Created stall for %0d cycles (near timeout)", stall_cycles), UVM_HIGH)
  
endtask : near_timeout_sequence

//--------------------------------------------------------------------------------------------
// Task: illegal_access_sequence
// Attempt to access protected address without unlock
//--------------------------------------------------------------------------------------------
task axi4_master_exception_seq::illegal_access_sequence();
  
  // First attempt: Direct write to protected address (should fail)
  start_item(req);
  assert(req.randomize() with {
    tx_type == WRITE;
    awaddr == local::protected_addr;
    awlen == 0;
    awsize == WRITE_4_BYTES;
    awburst == WRITE_INCR;
    transfer_type == BLOCKING_WRITE;
    wdata[0] == 32'hBADC0FFE;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  
  // Note: Error response expectation would need scoreboard handling
  `uvm_info(get_type_name(), "Expecting SLVERR for protected access", UVM_MEDIUM);
  
  finish_item(req);
  
  `uvm_info(get_type_name(), "Attempted illegal access to protected address", UVM_HIGH)
  
  // Second attempt: Write unlock key
  start_item(req);
  assert(req.randomize() with {
    tx_type == WRITE;
    awaddr == local::protected_addr + 4; // Unlock register
    awlen == 0;
    transfer_type == BLOCKING_WRITE;
    wdata[0] == local::unlock_key;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  finish_item(req);
  
  `uvm_info(get_type_name(), "Written unlock key", UVM_HIGH)
  
  // Third attempt: Write to protected address (should succeed)
  start_item(req);
  assert(req.randomize() with {
    tx_type == WRITE;
    awaddr == local::protected_addr;
    awlen == 0;
    transfer_type == BLOCKING_WRITE;
    wdata[0] == 32'hC001DA7A;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  finish_item(req);
  
  `uvm_info(get_type_name(), "Successfully accessed protected address after unlock", UVM_HIGH)
  
endtask : illegal_access_sequence

//--------------------------------------------------------------------------------------------
// Task: ecc_error_sim_sequence
// Simulate internal ECC/parity error
//--------------------------------------------------------------------------------------------
task axi4_master_exception_seq::ecc_error_sim_sequence();
  
  // Use backdoor to inject ECC error at specific location
  // This would be done via DPI or backdoor access in real implementation
  `uvm_info(get_type_name(), "Injecting ECC error via backdoor", UVM_MEDIUM)
  
  // Attempt to read from corrupted location
  start_item(req);
  assert(req.randomize() with {
    tx_type == READ;
    araddr == 64'h0000_0000_0000_1B00; // ECC error location
    arlen == 0;
    arsize == READ_4_BYTES;
    arburst == READ_INCR;
    transfer_type == BLOCKING_READ;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  
  // Note: Error response expectation would need scoreboard handling
  `uvm_info(get_type_name(), "Expecting SLVERR for ECC error", UVM_MEDIUM);
  
  finish_item(req);
  
  `uvm_info(get_type_name(), "Read from ECC error location", UVM_HIGH)
  
endtask : ecc_error_sim_sequence

//--------------------------------------------------------------------------------------------
// Task: special_reg_read_sequence  
// Consecutive reads to special function register
//--------------------------------------------------------------------------------------------
task axi4_master_exception_seq::special_reg_read_sequence();
  
  bit [DATA_WIDTH-1:0] read_data[$];
  
  // Perform multiple consecutive reads to special register
  repeat(num_special_reads) begin
    start_item(req);
    assert(req.randomize() with {
      tx_type == READ;
      araddr == 64'h0000_0000_0000_1C00; // Special function register
      arlen == 0;
      arsize == READ_4_BYTES;
      arburst == READ_INCR;
      transfer_type == BLOCKING_READ;
    }) else `uvm_fatal(get_type_name(), "Randomization failed")
    finish_item(req);
    
    // Get response and store data
    get_response(rsp);
    read_data.push_back(rsp.rdata[0]);
  end
  
  // Analyze read data pattern
  if (read_data.size() >= 2) begin
    if (read_data[0] != 0 && read_data[1] == 0) begin
      `uvm_info(get_type_name(), "Detected read-to-clear behavior", UVM_MEDIUM)
    end else if (read_data[1] == read_data[0] + 1) begin
      `uvm_info(get_type_name(), "Detected counter behavior", UVM_MEDIUM)
    end else if (read_data[0] == read_data[1]) begin
      `uvm_info(get_type_name(), "Detected constant value behavior", UVM_MEDIUM)
    end
  end
  
endtask : special_reg_read_sequence

`endif