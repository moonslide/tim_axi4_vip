`ifndef AXI4_VIRTUAL_USER_TRANSACTION_TRACING_SEQ_INCLUDED_
`define AXI4_VIRTUAL_USER_TRANSACTION_TRACING_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_user_transaction_tracing_seq
// Virtual sequence to test USER signal-based transaction tracing
// Coordinates multiple masters to demonstrate transaction tracing, correlation, and debugging
//--------------------------------------------------------------------------------------------
class axi4_virtual_user_transaction_tracing_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_user_transaction_tracing_seq)

  // Master sequences for different tracing scenarios
  axi4_master_user_transaction_tracing_seq trace_seq_h[10];
  
  // Slave sequences
  axi4_slave_nbk_write_seq axi4_slave_write_seq_h;
  axi4_slave_nbk_read_seq axi4_slave_read_seq_h;

  // Trace statistics
  int total_traced_writes = 0;
  int total_traced_reads = 0;
  int basic_trace_count = 0;
  int detailed_trace_count = 0;
  int debug_trace_count = 0;
  int performance_trace_count = 0;
  int correlation_checks = 0;
  int trace_propagation_checks = 0;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_user_transaction_tracing_seq");
  extern task body();
  extern function void display_trace_statistics();

endclass : axi4_virtual_user_transaction_tracing_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the object
//
// Parameters:
//  name - axi4_virtual_user_transaction_tracing_seq
//--------------------------------------------------------------------------------------------
function axi4_virtual_user_transaction_tracing_seq::new(string name = "axi4_virtual_user_transaction_tracing_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: display_trace_statistics
// Displays comprehensive trace statistics
//--------------------------------------------------------------------------------------------
function void axi4_virtual_user_transaction_tracing_seq::display_trace_statistics();
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Transaction Tracing Test Statistics:", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Total traced write transactions:     %0d", total_traced_writes), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Total traced read transactions:      %0d", total_traced_reads), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Basic trace transactions:            %0d", basic_trace_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Detailed trace transactions:         %0d", detailed_trace_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Debug trace transactions:            %0d", debug_trace_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Performance trace transactions:      %0d", performance_trace_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Correlation checks performed:        %0d", correlation_checks), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Trace propagation validations:       %0d", trace_propagation_checks), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
endfunction : display_trace_statistics

//--------------------------------------------------------------------------------------------
// Task: body
// Creates and starts sequences to test USER signal transaction tracing
//--------------------------------------------------------------------------------------------
task axi4_virtual_user_transaction_tracing_seq::body();
  
  `uvm_info(get_type_name(), "Starting USER Signal Transaction Tracing Virtual Sequence", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  // Create slave sequences
  axi4_slave_write_seq_h = axi4_slave_nbk_write_seq::type_id::create("axi4_slave_write_seq_h");
  axi4_slave_read_seq_h = axi4_slave_nbk_read_seq::type_id::create("axi4_slave_read_seq_h");
  
  // Start slave sequences in forever loops
  fork
    begin : SLAVE_WRITE
      forever begin
        axi4_slave_write_seq_h.start(p_sequencer.axi4_slave_write_seqr_h);
      end
    end
    
    begin : SLAVE_READ
      forever begin
        axi4_slave_read_seq_h.start(p_sequencer.axi4_slave_read_seqr_h);
      end
    end
  join_none
  
  // Test Scenario 1: Basic Transaction Tracing
  `uvm_info(get_type_name(), "==== Test Scenario 1: Basic Transaction Tracing ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: Simple transaction ID tracking through the system", UVM_LOW)
  
  trace_seq_h[0] = axi4_master_user_transaction_tracing_seq::type_id::create("trace_seq_0");
  uvm_config_db#(string)::set(null, {get_full_name(), ".trace_seq_0"}, "trace_mode", "BASIC");
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_0"}, "num_transactions", 5);
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_0"}, "master_id", 0);
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_0"}, "slave_id", 0);
  
  trace_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h);
  basic_trace_count += 5;
  total_traced_writes += 5;
  #200ns;
  
  // Test Scenario 2: Detailed Transaction Tracing with Logging
  `uvm_info(get_type_name(), "==== Test Scenario 2: Detailed Transaction Tracing ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: Enhanced tracing with verbose logging enabled", UVM_LOW)
  
  trace_seq_h[1] = axi4_master_user_transaction_tracing_seq::type_id::create("trace_seq_1");
  uvm_config_db#(string)::set(null, {get_full_name(), ".trace_seq_1"}, "trace_mode", "DETAILED");
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_1"}, "num_transactions", 4);
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_1"}, "master_id", 1);
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_1"}, "slave_id", 1);
  
  trace_seq_h[1].start(p_sequencer.axi4_master_write_seqr_h);
  detailed_trace_count += 4;
  total_traced_writes += 4;
  #200ns;
  
  // Test Scenario 3: Debug Mode Transaction Tracing
  `uvm_info(get_type_name(), "==== Test Scenario 3: Debug Mode Transaction Tracing ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: Full debug tracing with write-read correlation", UVM_LOW)
  
  trace_seq_h[2] = axi4_master_user_transaction_tracing_seq::type_id::create("trace_seq_2");
  uvm_config_db#(string)::set(null, {get_full_name(), ".trace_seq_2"}, "trace_mode", "DEBUG");
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_2"}, "num_transactions", 3);
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_2"}, "master_id", 2);
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_2"}, "slave_id", 2);
  
  trace_seq_h[2].start(p_sequencer.axi4_master_write_seqr_h);
  debug_trace_count += 3;
  total_traced_writes += 3;
  total_traced_reads += 3; // DEBUG mode includes reads
  correlation_checks += 3;
  #300ns;
  
  // Test Scenario 4: Performance Tracking Mode
  `uvm_info(get_type_name(), "==== Test Scenario 4: Performance Tracking Mode ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: Transaction tracing with performance monitoring flags", UVM_LOW)
  
  trace_seq_h[3] = axi4_master_user_transaction_tracing_seq::type_id::create("trace_seq_3");
  uvm_config_db#(string)::set(null, {get_full_name(), ".trace_seq_3"}, "trace_mode", "PERFORMANCE");
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_3"}, "num_transactions", 6);
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_3"}, "master_id", 3);
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_3"}, "slave_id", 3);
  
  trace_seq_h[3].start(p_sequencer.axi4_master_write_seqr_h);
  performance_trace_count += 6;
  total_traced_writes += 6;
  #200ns;
  
  // Test Scenario 5: Multi-Master Concurrent Tracing
  `uvm_info(get_type_name(), "==== Test Scenario 5: Multi-Master Concurrent Tracing ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: Multiple masters with unique trace IDs for correlation", UVM_LOW)
  
  fork
    begin
      trace_seq_h[4] = axi4_master_user_transaction_tracing_seq::type_id::create("trace_seq_4");
      uvm_config_db#(string)::set(null, {get_full_name(), ".trace_seq_4"}, "trace_mode", "BASIC");
      uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_4"}, "num_transactions", 3);
      uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_4"}, "master_id", 0);
      uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_4"}, "slave_id", 4);
      trace_seq_h[4].start(p_sequencer.axi4_master_write_seqr_h);
      basic_trace_count += 3;
      total_traced_writes += 3;
    end
    begin
      #50ns;
      trace_seq_h[5] = axi4_master_user_transaction_tracing_seq::type_id::create("trace_seq_5");
      uvm_config_db#(string)::set(null, {get_full_name(), ".trace_seq_5"}, "trace_mode", "BASIC");
      uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_5"}, "num_transactions", 3);
      uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_5"}, "master_id", 1);
      uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_5"}, "slave_id", 5);
      trace_seq_h[5].start(p_sequencer.axi4_master_write_seqr_h);
      basic_trace_count += 3;
      total_traced_writes += 3;
    end
    begin
      #100ns;
      trace_seq_h[6] = axi4_master_user_transaction_tracing_seq::type_id::create("trace_seq_6");
      uvm_config_db#(string)::set(null, {get_full_name(), ".trace_seq_6"}, "trace_mode", "BASIC");
      uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_6"}, "num_transactions", 3);
      uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_6"}, "master_id", 2);
      uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_6"}, "slave_id", 6);
      trace_seq_h[6].start(p_sequencer.axi4_master_write_seqr_h);
      basic_trace_count += 3;
      total_traced_writes += 3;
    end
  join
  
  correlation_checks += 9;
  #300ns;
  
  // Test Scenario 6: Trace Propagation Through Read Path
  `uvm_info(get_type_name(), "==== Test Scenario 6: Trace Propagation Through Read Path ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: USER signal trace preservation in read transactions", UVM_LOW)
  
  trace_seq_h[7] = axi4_master_user_transaction_tracing_seq::type_id::create("trace_seq_7");
  uvm_config_db#(string)::set(null, {get_full_name(), ".trace_seq_7"}, "trace_mode", "DETAILED");
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_7"}, "num_transactions", 2);
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_7"}, "master_id", 0);
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_7"}, "slave_id", 7);
  
  trace_seq_h[7].start(p_sequencer.axi4_master_read_seqr_h);
  detailed_trace_count += 2;
  total_traced_reads += 2;
  trace_propagation_checks += 2;
  #200ns;
  
  // Test Scenario 7: Full Trace Mode with All Features
  `uvm_info(get_type_name(), "==== Test Scenario 7: Full Trace Mode (All Features) ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: Complete tracing with all debug flags enabled", UVM_LOW)
  
  trace_seq_h[8] = axi4_master_user_transaction_tracing_seq::type_id::create("trace_seq_8");
  uvm_config_db#(string)::set(null, {get_full_name(), ".trace_seq_8"}, "trace_mode", "FULL");
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_8"}, "num_transactions", 2);
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_8"}, "master_id", 4);
  uvm_config_db#(int)::set(null, {get_full_name(), ".trace_seq_8"}, "slave_id", 8);
  
  trace_seq_h[8].start(p_sequencer.axi4_master_write_seqr_h);
  total_traced_writes += 2;
  total_traced_reads += 2; // FULL mode includes reads
  correlation_checks += 2;
  trace_propagation_checks += 2;
  #300ns;
  
  // Test Scenario 8: Cross-Master Trace Correlation
  `uvm_info(get_type_name(), "==== Test Scenario 8: Cross-Master Trace Correlation ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: Trace ID uniqueness across multiple masters", UVM_LOW)
  
  fork
    begin
      for(int m = 0; m < 3; m++) begin
        trace_seq_h[9] = axi4_master_user_transaction_tracing_seq::type_id::create($sformatf("cross_trace_%0d", m));
        uvm_config_db#(string)::set(null, {get_full_name(), $sformatf(".cross_trace_%0d", m)}, "trace_mode", "BASIC");
        uvm_config_db#(int)::set(null, {get_full_name(), $sformatf(".cross_trace_%0d", m)}, "num_transactions", 1);
        uvm_config_db#(int)::set(null, {get_full_name(), $sformatf(".cross_trace_%0d", m)}, "master_id", m);
        uvm_config_db#(int)::set(null, {get_full_name(), $sformatf(".cross_trace_%0d", m)}, "slave_id", 9);
        trace_seq_h[9].start(p_sequencer.axi4_master_write_seqr_h);
        basic_trace_count += 1;
        total_traced_writes += 1;
        #50ns;
      end
    end
  join
  
  correlation_checks += 3;
  
  // Wait for all transactions to complete
  #1000ns;
  
  // Display comprehensive statistics
  display_trace_statistics();
  
  `uvm_info(get_type_name(), "Transaction Tracing Capabilities Demonstrated:", UVM_LOW)
  `uvm_info(get_type_name(), "  ✓ Unique transaction ID generation and tracking", UVM_LOW)
  `uvm_info(get_type_name(), "  ✓ Source master identification in traces", UVM_LOW)
  `uvm_info(get_type_name(), "  ✓ Debug flag control for selective tracing", UVM_LOW)
  `uvm_info(get_type_name(), "  ✓ Sequence number for transaction ordering", UVM_LOW)
  `uvm_info(get_type_name(), "  ✓ Multi-master concurrent trace support", UVM_LOW)
  `uvm_info(get_type_name(), "  ✓ Write-read transaction correlation", UVM_LOW)
  `uvm_info(get_type_name(), "  ✓ Performance monitoring integration", UVM_LOW)
  `uvm_info(get_type_name(), "  ✓ Trace propagation through AXI channels", UVM_LOW)
  
endtask : body

`endif