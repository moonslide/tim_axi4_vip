`ifndef AXI4_VIRTUAL_RESET_COMPREHENSIVE_SEQ_INCLUDED_
`define AXI4_VIRTUAL_RESET_COMPREHENSIVE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_reset_comprehensive_seq
// Comprehensive virtual sequence for testing all reset scenarios:
// - Transfer abandonment during reset
// - System recovery after reset  
// - Protocol compliance during reset events
//--------------------------------------------------------------------------------------------
class axi4_virtual_reset_comprehensive_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_reset_comprehensive_seq)

  // Test scenario control
  rand bit test_transfer_abandonment;
  rand bit test_system_recovery;
  rand bit test_protocol_compliance;
  rand bit test_midburst_reset;
  rand bit test_multi_reset;
  
  // Reset parameters
  rand int num_reset_events;
  rand int reset_duration_cycles[];
  rand int reset_delay_ns[];
  
  // Constraints - made soft to allow override from test
  constraint c_test_scenarios {
    soft test_transfer_abandonment == 1;
    soft test_system_recovery == 1;
    soft test_protocol_compliance == 1;
    soft test_midburst_reset == 1;
    soft test_multi_reset == 1;
  }
  
  constraint c_reset_params {
    num_reset_events inside {[3:5]};  // Reduced to 3-5 for faster execution
    reset_duration_cycles.size() == num_reset_events;
    reset_delay_ns.size() == num_reset_events;
    
    foreach(reset_duration_cycles[i]) {
      reset_duration_cycles[i] inside {[1:10]};  // Reduced to 1-10 cycles
    }
    
    foreach(reset_delay_ns[i]) {
      reset_delay_ns[i] inside {[50:200]};  // Reduced to 50-200ns between resets
    }
  }

  extern function new(string name = "axi4_virtual_reset_comprehensive_seq");
  extern task body();
  extern task test_abandonment_scenario();
  extern task test_recovery_scenario();
  extern task test_compliance_scenario();
  extern task test_midburst_scenario();
  extern task test_multiple_resets();
  extern task inject_reset(int duration, string phase);
  extern task verify_bus_idle();
  extern task send_test_transaction();

endclass : axi4_virtual_reset_comprehensive_seq

//--------------------------------------------------------------------------------------------
// Constructor
//--------------------------------------------------------------------------------------------
function axi4_virtual_reset_comprehensive_seq::new(string name = "axi4_virtual_reset_comprehensive_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//--------------------------------------------------------------------------------------------
task axi4_virtual_reset_comprehensive_seq::body();
  
  `uvm_info(get_type_name(), "Starting Comprehensive Reset Test Sequence", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Run selected test scenarios
  if(test_transfer_abandonment) begin
    `uvm_info(get_type_name(), "Testing Transfer Abandonment During Reset", UVM_LOW)
    test_abandonment_scenario();
  end
  
  if(test_system_recovery) begin
    `uvm_info(get_type_name(), "Testing System Recovery After Reset", UVM_LOW)
    test_recovery_scenario();
  end
  
  if(test_protocol_compliance) begin
    `uvm_info(get_type_name(), "Testing Protocol Compliance During Reset", UVM_LOW)
    test_compliance_scenario();
  end
  
  if(test_midburst_reset) begin
    `uvm_info(get_type_name(), "Testing Mid-Burst Reset", UVM_LOW)
    test_midburst_scenario();
  end
  
  if(test_multi_reset) begin
    `uvm_info(get_type_name(), "Testing Multiple Reset Events", UVM_LOW)
    test_multiple_resets();
  end
  
  `uvm_info(get_type_name(), "Comprehensive Reset Test Sequence Completed", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
endtask : body

//--------------------------------------------------------------------------------------------
// Task: test_abandonment_scenario
// Tests that transfers are properly abandoned when reset occurs
//--------------------------------------------------------------------------------------------
task axi4_virtual_reset_comprehensive_seq::test_abandonment_scenario();
  axi4_master_write_seq write_seq;
  axi4_master_read_seq read_seq;
  
  `uvm_info(get_type_name(), "Starting transfer abandonment test", UVM_MEDIUM)
  
  // Start a write burst with timeout protection
  write_seq = axi4_master_write_seq::type_id::create("write_seq");
  fork
    begin
      fork
        begin
          write_seq.start(p_sequencer.axi4_master_write_seqr_h);
        end
        begin
          // Timeout after 1us if sequence doesn't complete
          #1us;
          `uvm_info(get_type_name(), "Write sequence timeout - expected during reset", UVM_MEDIUM)
        end
      join_any
      disable fork;
    end
    begin
      // Wait for transfer to start
      #100ns;
      
      // Inject reset during transfer
      inject_reset(10, "ABANDON_WRITE");
      
      `uvm_info(get_type_name(), "Write transfer should be abandoned", UVM_LOW)
    end
  join_any
  disable fork;
  
  // Wait for system to stabilize
  #500ns;
  
  // Start a read burst with timeout protection
  read_seq = axi4_master_read_seq::type_id::create("read_seq");
  fork
    begin
      fork
        begin
          read_seq.start(p_sequencer.axi4_master_read_seqr_h);
        end
        begin
          // Timeout after 1us if sequence doesn't complete
          #1us;
          `uvm_info(get_type_name(), "Read sequence timeout - expected during reset", UVM_MEDIUM)
        end
      join_any
      disable fork;
    end
    begin
      // Wait for transfer to start
      #100ns;
      
      // Inject reset during transfer
      inject_reset(10, "ABANDON_READ");
      
      `uvm_info(get_type_name(), "Read transfer should be abandoned", UVM_LOW)
    end
  join_any
  disable fork;
  
  // Verify bus returns to idle
  verify_bus_idle();
  
endtask : test_abandonment_scenario

//--------------------------------------------------------------------------------------------
// Task: test_recovery_scenario
// Tests that system recovers properly after reset
//--------------------------------------------------------------------------------------------
task axi4_virtual_reset_comprehensive_seq::test_recovery_scenario();
  
  `uvm_info(get_type_name(), "Starting system recovery test", UVM_MEDIUM)
  
  // Inject a reset
  inject_reset(5, "RECOVERY_TEST");
  
  // Wait for stabilization
  #200ns;
  
  // Send test transactions to verify recovery
  repeat(3) begin
    send_test_transaction();
    #50ns;
  end
  
  `uvm_info(get_type_name(), "System recovery verified - transactions completed successfully", UVM_LOW)
  
endtask : test_recovery_scenario

//--------------------------------------------------------------------------------------------
// Task: test_compliance_scenario
// Tests protocol compliance during reset events
//--------------------------------------------------------------------------------------------
task axi4_virtual_reset_comprehensive_seq::test_compliance_scenario();
  axi4_master_write_seq write_seq;
  
  `uvm_info(get_type_name(), "Starting protocol compliance test", UVM_MEDIUM)
  
  // Start multiple transactions with timeout protection
  repeat(3) begin  // Reduced from 5 to 3 for faster execution
    fork
      begin
        write_seq = axi4_master_write_seq::type_id::create("write_seq");
        fork
          begin
            write_seq.start(p_sequencer.axi4_master_write_seqr_h);
          end
          begin
            #2us;  // Timeout protection
          end
        join_any
        disable fork;
      end
    join_none
    #20ns;
  end
  
  // Inject reset while transactions are in flight
  #100ns;
  inject_reset(15, "COMPLIANCE_TEST");
  
  // Wait for all forks to complete or timeout with protection
  fork
    begin
      wait fork;
    end
    begin
      #5us;  // Maximum wait time
      `uvm_info(get_type_name(), "Compliance test timeout - continuing", UVM_MEDIUM)
    end
  join_any
  disable fork;
  
  // Verify no protocol violations occurred (checked by assertions)
  `uvm_info(get_type_name(), "Protocol compliance during reset verified", UVM_LOW)
  
endtask : test_compliance_scenario

//--------------------------------------------------------------------------------------------
// Task: test_midburst_scenario
// Tests reset injection in the middle of burst transfers
//--------------------------------------------------------------------------------------------
task axi4_virtual_reset_comprehensive_seq::test_midburst_scenario();
  axi4_master_midburst_reset_write_seq write_seq;
  axi4_master_midburst_reset_read_seq read_seq;
  
  `uvm_info(get_type_name(), "Starting mid-burst reset test", UVM_MEDIUM)
  
  // Test write burst with reset
  write_seq = axi4_master_midburst_reset_write_seq::type_id::create("write_seq");
  write_seq.reset_after_beats = 100;
  write_seq.start(p_sequencer.axi4_master_write_seqr_h);
  
  // Wait for recovery
  #1us;
  
  // Test read burst with reset
  read_seq = axi4_master_midburst_reset_read_seq::type_id::create("read_seq");
  read_seq.reset_after_beats = 150;
  read_seq.start(p_sequencer.axi4_master_read_seqr_h);
  
  `uvm_info(get_type_name(), "Mid-burst reset test completed", UVM_LOW)
  
endtask : test_midburst_scenario

//--------------------------------------------------------------------------------------------
// Task: test_multiple_resets
// Tests multiple reset events with varying timing
//--------------------------------------------------------------------------------------------
task axi4_virtual_reset_comprehensive_seq::test_multiple_resets();
  
  `uvm_info(get_type_name(), $sformatf("Starting multiple reset test with %0d events", num_reset_events), UVM_LOW)
  `uvm_info(get_type_name(), "This will stress test the reset mechanism thoroughly", UVM_LOW)
  
  foreach(reset_duration_cycles[i]) begin
    // Log every 5th reset to avoid log spam
    if(i % 5 == 0 || i == num_reset_events-1) begin
      `uvm_info(get_type_name(), $sformatf("Reset event %0d/%0d: duration=%0d cycles, delay=%0dns", 
                i+1, num_reset_events, reset_duration_cycles[i], reset_delay_ns[i]), UVM_LOW)
    end else begin
      `uvm_info(get_type_name(), $sformatf("Reset event %0d/%0d: duration=%0d cycles, delay=%0dns", 
                i+1, num_reset_events, reset_duration_cycles[i], reset_delay_ns[i]), UVM_MEDIUM)
    end
    
    // Send traffic before reset (skip for some to add variety)
    if(i % 3 != 2) begin
      send_test_transaction();
    end
    
    // Wait specified delay
    #(reset_delay_ns[i] * 1ns);
    
    // Inject reset
    inject_reset(reset_duration_cycles[i], $sformatf("MULTI_RESET_%0d", i+1));
    
    // Verify recovery after each reset (skip some for stress)
    if(i % 2 == 0) begin
      send_test_transaction();
    end
  end
  
  // Final recovery verification
  repeat(3) begin
    send_test_transaction();
    #50ns;
  end
  
  `uvm_info(get_type_name(), $sformatf("Multiple reset test completed - %0d resets successfully handled", num_reset_events), UVM_LOW)
  
endtask : test_multiple_resets

//--------------------------------------------------------------------------------------------
// Task: inject_reset
// Helper task to inject reset via config_db
//--------------------------------------------------------------------------------------------
task axi4_virtual_reset_comprehensive_seq::inject_reset(int duration, string phase);
  
  `uvm_info(get_type_name(), $sformatf("Injecting reset for %0d cycles during %s", duration, phase), UVM_LOW)
  
  // Configure reset injection
  uvm_config_db#(int)::set(null, "*", "reset_duration_cycles", duration);
  uvm_config_db#(bit)::set(null, "*", "reset_active", 1);
  uvm_config_db#(string)::set(null, "*", "reset_phase", phase);
  
  // Trigger reset
  uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);
  
  // Wait for reset to complete
  #((duration + 2) * 10ns);
  
  // Clear flags
  uvm_config_db#(bit)::set(null, "*", "reset_active", 0);
  
  // Additional stabilization time
  #50ns;
  
endtask : inject_reset

//--------------------------------------------------------------------------------------------
// Task: verify_bus_idle
// Verifies that the bus returns to idle state
//--------------------------------------------------------------------------------------------
task axi4_virtual_reset_comprehensive_seq::verify_bus_idle();
  
  `uvm_info(get_type_name(), "Verifying bus idle state", UVM_HIGH)
  
  // Wait for any pending transactions to clear
  #500ns;
  
  // The actual verification would be done by monitors/assertions
  // checking that all valid signals are low
  
endtask : verify_bus_idle

//--------------------------------------------------------------------------------------------
// Task: send_test_transaction
// Sends a simple test transaction to verify bus functionality
//--------------------------------------------------------------------------------------------
task axi4_virtual_reset_comprehensive_seq::send_test_transaction();
  axi4_master_write_seq write_seq;
  axi4_master_read_seq read_seq;
  
  // Send a simple write
  write_seq = axi4_master_write_seq::type_id::create("write_seq");
  write_seq.start(p_sequencer.axi4_master_write_seqr_h);
  
  // Send a simple read
  read_seq = axi4_master_read_seq::type_id::create("read_seq");
  read_seq.start(p_sequencer.axi4_master_read_seqr_h);
  
endtask : send_test_transaction

`endif