`ifndef AXI4_VIRTUAL_ERROR_INJECT_SEQ_INCLUDED_
`define AXI4_VIRTUAL_ERROR_INJECT_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_awvalid_x_seq
// Virtual sequence for injecting X on AWVALID
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_awvalid_x_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_awvalid_x_seq)

  axi4_master_x_inject_seq master_x_seq;
  axi4_master_bk_write_seq axi4_master_bk_write_seq_h;

  function new(string name = "axi4_virtual_error_inject_awvalid_x_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting AWVALID X injection test", UVM_MEDIUM)
    
    // For error injection tests, just inject X and wait
    // Don't try to send recovery transactions as they will timeout
    
    // Set X injection directly via config_db (bypass sequence)
    uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid", 1);
    uvm_config_db#(int)::set(null, "*", "x_inject_cycles", 8);
    
    `uvm_info(get_type_name(), "X injection configured for AWVALID", UVM_MEDIUM)
    
    // Wait for injection to complete
    #100ns;
    
    // Clear injection flag
    uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid", 0);
    
    // Just wait for observation, don't send recovery transaction
    #200ns;
    
    `uvm_info(get_type_name(), "AWVALID X injection test completed", UVM_MEDIUM)
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_awaddr_x_seq
// Virtual sequence for injecting X on AWADDR
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_awaddr_x_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_awaddr_x_seq)

  axi4_master_x_inject_seq master_x_seq;

  function new(string name = "axi4_virtual_error_inject_awaddr_x_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting AWADDR X injection test", UVM_MEDIUM)
    
    // Set X injection directly via config_db
    uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr", 1);
    uvm_config_db#(int)::set(null, "*", "x_inject_cycles", 6);
    
    `uvm_info(get_type_name(), "X injection configured for AWADDR", UVM_MEDIUM)
    
    // Wait for injection to complete
    #100ns;
    
    // Clear injection flag
    uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr", 0);
    
    // Just wait for observation
    #100ns;
    
    `uvm_info(get_type_name(), "AWADDR X injection test completed", UVM_MEDIUM)
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_wdata_x_seq
// Virtual sequence for injecting X on WDATA
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_wdata_x_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_wdata_x_seq)

  axi4_master_x_inject_seq master_x_seq;

  function new(string name = "axi4_virtual_error_inject_wdata_x_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting WDATA X injection test", UVM_MEDIUM)
    
    // Set X injection directly via config_db
    uvm_config_db#(bit)::set(null, "*", "x_inject_wdata", 1);
    uvm_config_db#(int)::set(null, "*", "x_inject_cycles", 6);
    
    `uvm_info(get_type_name(), "X injection configured for WDATA", UVM_MEDIUM)
    
    // Wait for injection to complete
    #100ns;
    
    // Clear injection flag
    uvm_config_db#(bit)::set(null, "*", "x_inject_wdata", 0);
    
    // Just wait for observation
    #100ns;
    
    `uvm_info(get_type_name(), "WDATA X injection test completed", UVM_MEDIUM)
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_arvalid_x_seq
// Virtual sequence for injecting X on ARVALID
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_arvalid_x_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_arvalid_x_seq)

  axi4_master_x_inject_seq master_x_seq;
  axi4_master_bk_read_seq axi4_master_bk_read_seq_h;

  function new(string name = "axi4_virtual_error_inject_arvalid_x_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting ARVALID X injection test", UVM_MEDIUM)
    
    // Set X injection directly via config_db
    uvm_config_db#(bit)::set(null, "*", "x_inject_arvalid", 1);
    uvm_config_db#(int)::set(null, "*", "x_inject_cycles", 8);
    
    `uvm_info(get_type_name(), "X injection configured for ARVALID", UVM_MEDIUM)
    
    // Wait for injection to complete
    #100ns;
    
    // Clear injection flag
    uvm_config_db#(bit)::set(null, "*", "x_inject_arvalid", 0);
    
    // Just wait for observation, don't send recovery transaction
    #200ns;
    
    `uvm_info(get_type_name(), "ARVALID X injection test completed", UVM_MEDIUM)
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_bready_x_seq
// Virtual sequence for injecting X on BREADY
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_bready_x_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_bready_x_seq)

  axi4_master_x_inject_seq master_x_seq;

  function new(string name = "axi4_virtual_error_inject_bready_x_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting BREADY X injection test", UVM_MEDIUM)
    
    // Create sequence
    master_x_seq = axi4_master_x_inject_seq::type_id::create("master_x_seq");
    
    // Configure X injection sequence
    master_x_seq.inject_phase = axi4_master_x_inject_seq::PHASE_B;
    master_x_seq.inject_signal = axi4_master_x_inject_seq::SIGNAL_READY;
    master_x_seq.x_inject_cycles = 6;  // Increased for better coverage
    master_x_seq.target_addr = 64'h0000_0008_0000_1040;  // Valid DDR address
    master_x_seq.test_id = 4'h5;
    
    // Start X injection sequence
    master_x_seq.start(p_sequencer.axi4_master_write_seqr_h);
    
    #100ns;
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_rready_x_seq
// Virtual sequence for injecting X on RREADY
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_rready_x_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_rready_x_seq)

  axi4_master_x_inject_seq master_x_seq;

  function new(string name = "axi4_virtual_error_inject_rready_x_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting RREADY X injection test", UVM_MEDIUM)
    
    // Create sequence
    master_x_seq = axi4_master_x_inject_seq::type_id::create("master_x_seq");
    
    // Configure X injection sequence
    master_x_seq.inject_phase = axi4_master_x_inject_seq::PHASE_R;
    master_x_seq.inject_signal = axi4_master_x_inject_seq::SIGNAL_READY;
    master_x_seq.x_inject_cycles = 6;  // Increased for better coverage
    master_x_seq.target_addr = 64'h0000_0008_0000_1050;  // Valid DDR address
    master_x_seq.test_id = 4'h6;
    
    // Start X injection sequence - Use read sequencer for read channel
    master_x_seq.start(p_sequencer.axi4_master_read_seqr_h);
    
    #100ns;
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_exception_abort_awvalid_seq
// Virtual sequence for aborting AWVALID before handshake
//--------------------------------------------------------------------------------------------
class axi4_virtual_exception_abort_awvalid_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_exception_abort_awvalid_seq)

  axi4_master_exception_seq master_exc_seq;

  function new(string name = "axi4_virtual_exception_abort_awvalid_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting AWVALID abort test", UVM_MEDIUM)
    
    // Create sequence
    master_exc_seq = axi4_master_exception_seq::type_id::create("master_exc_seq");
    
    // Configure abort sequence
    master_exc_seq.exception_type = axi4_master_exception_seq::ABORT_AWVALID;
    master_exc_seq.target_addr = 64'h0000_0008_0000_1060;  // Valid DDR address
    
    // Start sequence
    master_exc_seq.start(p_sequencer.axi4_master_write_seqr_h);
    
    #200ns;
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_exception_abort_arvalid_seq
// Virtual sequence for aborting ARVALID before handshake
//--------------------------------------------------------------------------------------------
class axi4_virtual_exception_abort_arvalid_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_exception_abort_arvalid_seq)

  axi4_master_exception_seq master_exc_seq;

  function new(string name = "axi4_virtual_exception_abort_arvalid_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting ARVALID abort test", UVM_MEDIUM)
    
    // Create sequence
    master_exc_seq = axi4_master_exception_seq::type_id::create("master_exc_seq");
    
    // Configure abort sequence
    master_exc_seq.exception_type = axi4_master_exception_seq::ABORT_ARVALID;
    master_exc_seq.target_addr = 64'h0000_0008_0000_1070;  // Valid DDR address
    
    // Start sequence - Use read sequencer for read channel
    master_exc_seq.start(p_sequencer.axi4_master_read_seqr_h);
    
    #200ns;
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_exception_near_timeout_seq
// Virtual sequence for stall near timeout threshold
//--------------------------------------------------------------------------------------------
class axi4_virtual_exception_near_timeout_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_exception_near_timeout_seq)

  axi4_master_exception_seq master_exc_seq;

  function new(string name = "axi4_virtual_exception_near_timeout_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting near timeout test", UVM_MEDIUM)
    
    // Create sequence
    master_exc_seq = axi4_master_exception_seq::type_id::create("master_exc_seq");
    
    // Configure near timeout sequence
    master_exc_seq.exception_type = axi4_master_exception_seq::NEAR_TIMEOUT;
    master_exc_seq.target_addr = 64'h0000_0008_0000_1080;  // Valid DDR address
    master_exc_seq.stall_cycles = 1023;
    
    // Start sequence
    master_exc_seq.start(p_sequencer.axi4_master_write_seqr_h);
    
    #500ns;
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_exception_illegal_access_seq
// Virtual sequence for illegal/protected address access
//--------------------------------------------------------------------------------------------
class axi4_virtual_exception_illegal_access_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_exception_illegal_access_seq)

  axi4_master_exception_seq master_exc_seq;

  function new(string name = "axi4_virtual_exception_illegal_access_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting illegal access test", UVM_MEDIUM)
    
    // Create sequence
    master_exc_seq = axi4_master_exception_seq::type_id::create("master_exc_seq");
    
    // Configure illegal access sequence
    master_exc_seq.exception_type = axi4_master_exception_seq::ILLEGAL_ACCESS;
    master_exc_seq.protected_addr = 64'h0000_0000_0000_1A00;
    master_exc_seq.unlock_key = 32'hDEADBEEF;
    
    // Start sequence
    master_exc_seq.start(p_sequencer.axi4_master_write_seqr_h);
    
    #300ns;
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_exception_ecc_error_seq
// Virtual sequence for simulating ECC/parity errors
//--------------------------------------------------------------------------------------------
class axi4_virtual_exception_ecc_error_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_exception_ecc_error_seq)

  axi4_master_exception_seq master_exc_seq;

  function new(string name = "axi4_virtual_exception_ecc_error_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting ECC error simulation test", UVM_MEDIUM)
    
    // Create sequence
    master_exc_seq = axi4_master_exception_seq::type_id::create("master_exc_seq");
    
    // Configure ECC error sequence
    master_exc_seq.exception_type = axi4_master_exception_seq::ECC_ERROR_SIM;
    
    // Start sequence
    master_exc_seq.start(p_sequencer.axi4_master_write_seqr_h);
    
    #200ns;
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_exception_special_reg_seq
// Virtual sequence for special function register access
//--------------------------------------------------------------------------------------------
class axi4_virtual_exception_special_reg_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_exception_special_reg_seq)

  axi4_master_exception_seq master_exc_seq;

  function new(string name = "axi4_virtual_exception_special_reg_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting special register read test", UVM_MEDIUM)
    
    // Create sequence
    master_exc_seq = axi4_master_exception_seq::type_id::create("master_exc_seq");
    
    // Configure special register sequence
    master_exc_seq.exception_type = axi4_master_exception_seq::SPECIAL_REG_READ;
    master_exc_seq.num_special_reads = 4;
    
    // Start sequence - Use read sequencer for read operations
    master_exc_seq.start(p_sequencer.axi4_master_read_seqr_h);
    
    #300ns;
    
  endtask
endclass

`endif