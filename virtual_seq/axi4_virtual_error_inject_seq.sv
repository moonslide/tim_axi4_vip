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
    
    // Create sequences
    master_x_seq = axi4_master_x_inject_seq::type_id::create("master_x_seq");
    axi4_master_bk_write_seq_h = axi4_master_bk_write_seq::type_id::create("axi4_master_bk_write_seq_h");
    
    // Configure and run X injection on AWVALID
    `uvm_do_on_with(master_x_seq, p_sequencer.axi4_master_write_seqr_h, {
      inject_phase == axi4_master_x_inject_seq::PHASE_AW;
      inject_signal == axi4_master_x_inject_seq::SIGNAL_VALID;
      x_inject_cycles == 3;
      target_addr == 64'h0000_0000_0000_1000;
      test_id == 4'h1;
    })
    
    #100ns;
    
    // Send normal transaction to verify recovery
    `uvm_do_on_with(axi4_master_bk_write_seq_h, p_sequencer.axi4_master_write_seqr_h, {
      awaddr == 64'h0000_0000_0000_1008;
      awlen == 0;
    })
    
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
    
    // Configure and run X injection on AWADDR
    `uvm_do_on_with(master_x_seq, p_sequencer.axi4_master_write_seqr_h, {
      inject_phase == axi4_master_x_inject_seq::PHASE_AW;
      inject_signal == axi4_master_x_inject_seq::SIGNAL_ADDR;
      x_inject_cycles == 2;
      target_addr == 64'h0000_0000_0000_1010;
      test_id == 4'h2;
    })
    
    #100ns;
    
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
    
    // Configure and run X injection on WDATA
    `uvm_do_on_with(master_x_seq, p_sequencer.axi4_master_write_seqr_h, {
      inject_phase == axi4_master_x_inject_seq::PHASE_W;
      inject_signal == axi4_master_x_inject_seq::SIGNAL_DATA;
      x_inject_cycles == 2;
      target_addr == 64'h0000_0000_0000_1020;
      test_data == 32'hDEADBEEF;
      test_id == 4'h3;
    })
    
    #100ns;
    
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
    
    // Create sequences
    master_x_seq = axi4_master_x_inject_seq::type_id::create("master_x_seq");
    axi4_master_bk_read_seq_h = axi4_master_bk_read_seq::type_id::create("axi4_master_bk_read_seq_h");
    
    // Configure and run X injection on ARVALID
    `uvm_do_on_with(master_x_seq, p_sequencer.axi4_master_write_seqr_h, {
      inject_phase == axi4_master_x_inject_seq::PHASE_AR;
      inject_signal == axi4_master_x_inject_seq::SIGNAL_VALID;
      x_inject_cycles == 3;
      target_addr == 64'h0000_0000_0000_1030;
      test_id == 4'h4;
    })
    
    #100ns;
    
    // Send normal read to verify recovery
    `uvm_do_on_with(axi4_master_bk_read_seq_h, p_sequencer.axi4_master_read_seqr_h, {
      araddr == 64'h0000_0000_0000_1038;
      arlen == 0;
    })
    
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
    
    // Configure and run X injection on BREADY
    `uvm_do_on_with(master_x_seq, p_sequencer.axi4_master_write_seqr_h, {
      inject_phase == axi4_master_x_inject_seq::PHASE_B;
      inject_signal == axi4_master_x_inject_seq::SIGNAL_READY;
      x_inject_cycles == 2;
      target_addr == 64'h0000_0000_0000_1040;
      test_id == 4'h5;
    })
    
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
    
    // Configure and run X injection on RREADY
    `uvm_do_on_with(master_x_seq, p_sequencer.axi4_master_write_seqr_h, {
      inject_phase == axi4_master_x_inject_seq::PHASE_R;
      inject_signal == axi4_master_x_inject_seq::SIGNAL_READY;
      x_inject_cycles == 2;
      target_addr == 64'h0000_0000_0000_1050;
      test_id == 4'h6;
    })
    
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
    
    // Configure and run abort sequence
    `uvm_do_on_with(master_exc_seq, p_sequencer.axi4_master_write_seqr_h, {
      exception_type == axi4_master_exception_seq::ABORT_AWVALID;
      target_addr == 64'h0000_0000_0000_1060;
    })
    
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
    
    // Configure and run abort sequence
    `uvm_do_on_with(master_exc_seq, p_sequencer.axi4_master_write_seqr_h, {
      exception_type == axi4_master_exception_seq::ABORT_ARVALID;
      target_addr == 64'h0000_0000_0000_1070;
    })
    
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
    
    // Configure and run near timeout sequence
    `uvm_do_on_with(master_exc_seq, p_sequencer.axi4_master_write_seqr_h, {
      exception_type == axi4_master_exception_seq::NEAR_TIMEOUT;
      target_addr == 64'h0000_0000_0000_1080;
      stall_cycles inside {[1022:1023]};
    })
    
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
    
    // Configure and run illegal access sequence
    `uvm_do_on_with(master_exc_seq, p_sequencer.axi4_master_write_seqr_h, {
      exception_type == axi4_master_exception_seq::ILLEGAL_ACCESS;
      protected_addr == 64'h0000_0000_0000_1A00;
      unlock_key == 32'hDEADBEEF;
    })
    
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
    
    // Configure and run ECC error sequence
    `uvm_do_on_with(master_exc_seq, p_sequencer.axi4_master_write_seqr_h, {
      exception_type == axi4_master_exception_seq::ECC_ERROR_SIM;
    })
    
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
    
    // Configure and run special register sequence
    `uvm_do_on_with(master_exc_seq, p_sequencer.axi4_master_write_seqr_h, {
      exception_type == axi4_master_exception_seq::SPECIAL_REG_READ;
      num_special_reads == 4;
    })
    
    #300ns;
    
  endtask
endclass

`endif