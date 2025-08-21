`ifndef AXI4_MASTER_NEAR_TIMEOUT_SEQ_INCLUDED_
`define AXI4_MASTER_NEAR_TIMEOUT_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_near_timeout_seq
// Master sequence for near timeout testing - stalls transaction near timeout threshold
//--------------------------------------------------------------------------------------------
class axi4_master_near_timeout_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_near_timeout_seq)

  // Timeout control parameters
  int timeout_threshold = 1024;  // Timeout threshold cycles  
  int stall_cycles = 1023;       // Stall for 1023 cycles (1 less than threshold)

  function new(string name = "axi4_master_near_timeout_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting near timeout test sequence", UVM_MEDIUM)
    
    // Get timeout configuration from test
    if (!uvm_config_db#(int)::get(m_sequencer, "", "timeout_threshold", timeout_threshold)) begin
      `uvm_warning(get_type_name(), "timeout_threshold not found in config, using default 1024")
    end
    
    if (!uvm_config_db#(int)::get(m_sequencer, "", "stall_cycles", stall_cycles)) begin
      `uvm_warning(get_type_name(), "stall_cycles not found in config, using default 1023")
    end
    
    `uvm_info(get_type_name(), $sformatf("Timeout test: stall_cycles=%0d, timeout_threshold=%0d", 
              stall_cycles, timeout_threshold), UVM_MEDIUM)
    
    `uvm_info(get_type_name(), "Sending write transaction for timeout testing", UVM_MEDIUM)
    `uvm_info(get_type_name(), "Expected: Slave will stall AWREADY for 1023 cycles, then complete", UVM_MEDIUM)
    
    // Create and send write transaction using standard pattern
    start_item(req);
    if(!req.randomize() with {
      req.tx_type == WRITE;
      req.transfer_type == BLOCKING_WRITE;
      req.awaddr == 64'h0000_0000_DEAD_BEEF;  // Special address to trigger timeout test in slave
    }) begin
      `uvm_fatal("axi4_master_near_timeout_seq", "Randomization failed");
    end
    
    `uvm_info(get_type_name(), $sformatf("Sending timeout test transaction:\n%s", req.sprint()), UVM_MEDIUM)
    finish_item(req);
    
    `uvm_info(get_type_name(), "Near timeout test sequence completed", UVM_MEDIUM)
    
  endtask

endclass : axi4_master_near_timeout_seq

`endif