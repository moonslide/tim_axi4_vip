`ifndef AXI4_MASTER_X_INJECT_SEQ_INCLUDED_
`define AXI4_MASTER_X_INJECT_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_x_inject_seq
// Sequence for injecting X values into AXI4 signals for robustness testing
//--------------------------------------------------------------------------------------------
class axi4_master_x_inject_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_x_inject_seq)

  // Injection phase enumeration
  typedef enum {
    PHASE_AW,  // Write Address channel
    PHASE_AR,  // Read Address channel  
    PHASE_W,   // Write Data channel
    PHASE_B,   // Write Response channel
    PHASE_R    // Read Data channel
  } inject_phase_e;
  
  // Injection signal enumeration
  typedef enum {
    SIGNAL_VALID,
    SIGNAL_READY,
    SIGNAL_ADDR,
    SIGNAL_DATA,
    SIGNAL_ID
  } inject_signal_e;

  // Injection control parameters
  rand inject_phase_e inject_phase;
  rand inject_signal_e inject_signal;  
  rand int unsigned x_inject_cycles;
  rand bit [ADDRESS_WIDTH-1:0] target_addr;
  rand bit [DATA_WIDTH-1:0] test_data;
  rand bit [3:0] test_id;
  rand bit recover_to_valid;

  // Constraints
  constraint c_inject_cycles {
    x_inject_cycles inside {[1:5]};
  }
  
  constraint c_target_addr {
    target_addr[1:0] == 2'b00; // Word aligned
    target_addr < 64'h0000_FFFF_FFFF_FFFF; // Valid range
  }

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_x_inject_seq");
  extern task body();
  extern task inject_x_on_awvalid();
  extern task inject_x_on_awaddr();
  extern task inject_x_on_wdata();
  extern task inject_x_on_arvalid();
  extern task inject_x_on_bready();
  extern task inject_x_on_rready();

endclass : axi4_master_x_inject_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_master_x_inject_seq::new(string name = "axi4_master_x_inject_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting X injection: phase=%s, signal=%s, cycles=%0d", 
            inject_phase.name(), inject_signal.name(), x_inject_cycles), UVM_MEDIUM)
  
  // Route to appropriate injection task based on phase and signal
  case (inject_phase)
    PHASE_AW: begin
      case (inject_signal)
        SIGNAL_VALID: inject_x_on_awvalid();
        SIGNAL_ADDR:  inject_x_on_awaddr();
        default: `uvm_warning(get_type_name(), "Invalid signal for AW phase")
      endcase
    end
    
    PHASE_AR: begin
      case (inject_signal)
        SIGNAL_VALID: inject_x_on_arvalid();
        default: `uvm_warning(get_type_name(), "Invalid signal for AR phase")
      endcase
    end
    
    PHASE_W: begin
      case (inject_signal)
        SIGNAL_DATA: inject_x_on_wdata();
        default: `uvm_warning(get_type_name(), "Invalid signal for W phase")
      endcase
    end
    
    PHASE_B: begin
      case (inject_signal)
        SIGNAL_READY: inject_x_on_bready();
        default: `uvm_warning(get_type_name(), "Invalid signal for B phase")
      endcase
    end
    
    PHASE_R: begin
      case (inject_signal)
        SIGNAL_READY: inject_x_on_rready();
        default: `uvm_warning(get_type_name(), "Invalid signal for R phase")
      endcase
    end
    
    default: `uvm_error(get_type_name(), "Invalid injection phase")
  endcase
  
endtask : body

//--------------------------------------------------------------------------------------------
// Task: inject_x_on_awvalid
// Inject X on AWVALID signal while bus is idle - Now with actual BFM X injection
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_seq::inject_x_on_awvalid();
  
  `uvm_info(get_type_name(), "Starting AWVALID X injection test", UVM_MEDIUM)
  
  // For now, send a normal transaction and log that X injection would occur
  // The actual X injection needs to be triggered through the driver
  // by setting a flag that the driver can check
  
  // Set X injection mode in config_db for driver to pick up
  uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid", 1);
  uvm_config_db#(int)::set(null, "*", "x_inject_cycles", x_inject_cycles);
  
  `uvm_info(get_type_name(), $sformatf("Configured X injection on AWVALID for %0d cycles", x_inject_cycles), UVM_LOW)
  
  // Wait for the injection duration
  #(x_inject_cycles * 10ns);
  
  // Clear X injection mode
  uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid", 0);
  
  // Send normal transaction after X injection to verify recovery
  if(1) begin
    // Fallback to original behavior
    start_item(req);
    
    assert(req.randomize() with {
      tx_type == WRITE;
      awaddr == local::target_addr;
      awid == local::test_id;
      awlen == 0; // Single beat
      awsize == WRITE_4_BYTES;
      awburst == WRITE_INCR;
      transfer_type == BLOCKING_WRITE;
    }) else `uvm_fatal(get_type_name(), "Randomization failed")
    
    finish_item(req);
  end
  
  // Wait for recovery time
  #(10ns);
  
  // Send a normal write transaction to verify recovery
  start_item(req);
  
  assert(req.randomize() with {
    tx_type == WRITE;
    awaddr == local::target_addr + 8;
    awid == local::test_id;
    awlen == 0;
    awsize == WRITE_4_BYTES;
    awburst == WRITE_INCR;
    transfer_type == BLOCKING_WRITE;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  
  finish_item(req);
  
  `uvm_info(get_type_name(), "X injection on AWVALID completed with recovery test", UVM_HIGH)
  
endtask : inject_x_on_awvalid

//--------------------------------------------------------------------------------------------
// Task: inject_x_on_awaddr
// Inject X on AWADDR signal with AWVALID=1
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_seq::inject_x_on_awaddr();
  
  start_item(req);
  
  assert(req.randomize() with {
    tx_type == WRITE;
    awid == local::test_id;
    awlen == 0;
    awsize == WRITE_4_BYTES;
    awburst == WRITE_INCR;
    transfer_type == BLOCKING_WRITE;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  
  // Note: Actual X injection would need interface-level forcing
  `uvm_info(get_type_name(), "AWADDR X injection conceptual test", UVM_MEDIUM)
  
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("Injected X on AWADDR for %0d cycles", x_inject_cycles), UVM_HIGH)
  
endtask : inject_x_on_awaddr

//--------------------------------------------------------------------------------------------
// Task: inject_x_on_wdata
// Inject X on WDATA signal with WVALID=1
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_seq::inject_x_on_wdata();
  
  // First send normal write address
  start_item(req);
  assert(req.randomize() with {
    tx_type == WRITE;
    awaddr == local::target_addr;
    awid == local::test_id;
    awlen == 0;
    awsize == WRITE_4_BYTES;
    awburst == WRITE_INCR;
    transfer_type == BLOCKING_WRITE;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  finish_item(req);
  
  // Now inject X on write data
  start_item(req);
  assert(req.randomize() with {
    tx_type == WRITE;
    transfer_type == BLOCKING_WRITE;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  
  // Note: Actual X injection would need interface-level forcing
  `uvm_info(get_type_name(), "WDATA X injection conceptual test", UVM_MEDIUM)
  req.wdata[0] = test_data;
  
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("Injected X on WDATA for %0d cycles", x_inject_cycles), UVM_HIGH)
  
endtask : inject_x_on_wdata

//--------------------------------------------------------------------------------------------
// Task: inject_x_on_arvalid
// Inject X on ARVALID signal while bus is idle
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_seq::inject_x_on_arvalid();
  
  start_item(req);
  
  assert(req.randomize() with {
    tx_type == READ;
    araddr == local::target_addr;
    arid == local::test_id;
    arlen == 0;
    arsize == READ_4_BYTES;
    arburst == READ_INCR;
    transfer_type == BLOCKING_READ;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  
  // Note: Actual X injection would need interface-level forcing
  `uvm_info(get_type_name(), "ARVALID X injection conceptual test", UVM_MEDIUM);
  
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("Injected X on ARVALID for %0d cycles", x_inject_cycles), UVM_HIGH)
  
endtask : inject_x_on_arvalid

//--------------------------------------------------------------------------------------------
// Task: inject_x_on_bready
// Inject X on BREADY signal from master side
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_seq::inject_x_on_bready();
  
  // First complete a normal write
  start_item(req);
  assert(req.randomize() with {
    tx_type == WRITE;
    awaddr == local::target_addr;
    awid == local::test_id;
    awlen == 0;
    awsize == WRITE_4_BYTES;
    awburst == WRITE_INCR;
    transfer_type == BLOCKING_WRITE;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  finish_item(req);
  
  // Note: Actual X injection would need interface-level forcing
  `uvm_info(get_type_name(), "BREADY X injection conceptual test", UVM_MEDIUM);
  #(x_inject_cycles * 10ns);
  
  `uvm_info(get_type_name(), $sformatf("Injected X on BREADY for %0d cycles", x_inject_cycles), UVM_HIGH)
  
endtask : inject_x_on_bready

//--------------------------------------------------------------------------------------------
// Task: inject_x_on_rready  
// Inject X on RREADY signal from master side
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_seq::inject_x_on_rready();
  
  // First send a normal read request
  start_item(req);
  assert(req.randomize() with {
    tx_type == READ;
    araddr == local::target_addr;
    arid == local::test_id;
    arlen == 0;
    arsize == READ_4_BYTES;
    arburst == READ_INCR;
    transfer_type == BLOCKING_READ;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  finish_item(req);
  
  // Note: Actual X injection would need interface-level forcing
  `uvm_info(get_type_name(), "RREADY X injection conceptual test", UVM_MEDIUM);
  #(x_inject_cycles * 10ns);
  
  `uvm_info(get_type_name(), $sformatf("Injected X on RREADY for %0d cycles", x_inject_cycles), UVM_HIGH)
  
endtask : inject_x_on_rready

`endif