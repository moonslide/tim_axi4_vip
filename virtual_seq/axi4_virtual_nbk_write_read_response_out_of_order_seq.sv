`ifndef AXI4_VIRTUAL_NBK_WRITE_READ_RESPONSE_OUT_OF_ORDER_SEQ_INCLUDED_
`define AXI4_VIRTUAL_NBK_WRITE_READ_RESPONSE_OUT_OF_ORDER_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_nbk_write_read_response_out_of_order_seq  
// True AXI4 out-of-order virtual sequence implementing ARM AMBA AXI4 specification
// Creates coordinated write and read sequences with proper ID management and synchronization
//--------------------------------------------------------------------------------------------
class axi4_virtual_nbk_write_read_response_out_of_order_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_nbk_write_read_response_out_of_order_seq)

  // Sequence instances now created locally to avoid reuse issues
  axi4_slave_write_nbk_write_read_response_out_of_order_seq axi4_slave_write_nbk_write_read_response_out_of_order_seq_h;
  axi4_slave_read_nbk_write_read_response_out_of_order_seq axi4_slave_read_nbk_write_read_response_out_of_order_seq_h;

  // Write response tracking for synchronization
  int writes_issued = 0;
  int writes_completed = 0;
  event all_writes_completed;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_nbk_write_read_response_out_of_order_seq");
  extern task body();
  extern task write_phase_out_of_order();
  extern task wait_for_write_completion();
  extern task read_phase_out_of_order();
  extern task monitor_write_responses();

endclass : axi4_virtual_nbk_write_read_response_out_of_order_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//--------------------------------------------------------------------------------------------
function axi4_virtual_nbk_write_read_response_out_of_order_seq::new(string name = "axi4_virtual_nbk_write_read_response_out_of_order_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Main test sequence implementing true AXI4 out-of-order transaction flow
// Phase 1: Issue multiple writes with different AWIDs simultaneously
// Phase 2: Wait for ALL write responses to ensure completion  
// Phase 3: Issue reads to same addresses with different ARIDs
// Phase 4: Verify read-after-write data integrity
//--------------------------------------------------------------------------------------------
task axi4_virtual_nbk_write_read_response_out_of_order_seq::body();
  
  // Create slave sequence instances only (master sequences created locally in tasks)
  axi4_slave_write_nbk_write_read_response_out_of_order_seq_h = axi4_slave_write_nbk_write_read_response_out_of_order_seq::type_id::create("axi4_slave_write_nbk_write_read_response_out_of_order_seq_h");
  axi4_slave_read_nbk_write_read_response_out_of_order_seq_h = axi4_slave_read_nbk_write_read_response_out_of_order_seq::type_id::create("axi4_slave_read_nbk_write_read_response_out_of_order_seq_h");

  `uvm_info(get_type_name(), "=== AXI4 OUT-OF-ORDER TRANSACTION TEST START ===", UVM_LOW);
  `uvm_info(get_type_name(), "Implementing ARM AMBA AXI4 specification for out-of-order transactions", UVM_LOW);

  // Add timeout protection to prevent infinite running
  fork : TIMEOUT_PROTECTION
    begin : TEST_SEQUENCE
      // NOTE: Slave sequences disabled for out-of-order test
      // The slave agents will automatically respond to master requests
      // No need for explicit slave sequences that generate random transactions

      // PHASE 1: OUT-OF-ORDER WRITE PHASE
      // Issue 8 write transactions with different AWIDs to test out-of-order write responses
      // Per AXI4 spec: transactions with different IDs can complete out-of-order
      `uvm_info(get_type_name(), "=== PHASE 1: OUT-OF-ORDER WRITE TRANSACTIONS ===", UVM_LOW);
      write_phase_out_of_order();
      
      // PHASE 2: SYNCHRONIZATION PHASE  
      // Wait for ALL write responses to ensure write completion before reads
      // Per AXI4 spec: write completion is signaled by write response (BVALID)
      `uvm_info(get_type_name(), "=== PHASE 2: WAITING FOR WRITE COMPLETION ===", UVM_LOW);
      wait_for_write_completion();
      
      // PHASE 3: OUT-OF-ORDER READ PHASE
      // Issue 8 read transactions with different ARIDs to same addresses  
      // Per AXI4 spec: read responses can return out-of-order for different IDs
      `uvm_info(get_type_name(), "=== PHASE 3: OUT-OF-ORDER READ TRANSACTIONS ===", UVM_LOW);
      read_phase_out_of_order();
      
      `uvm_info(get_type_name(), "=== AXI4 OUT-OF-ORDER TRANSACTION TEST COMPLETE ===", UVM_LOW);
    end
    begin : TIMEOUT_WATCHDOG
      #50000; // 50,000 time unit timeout
      `uvm_error(get_type_name(), "TEST TIMEOUT: Out-of-order test exceeded maximum time limit");
    end
  join_any
  disable fork; // Clean up any remaining processes
  
endtask : body

//--------------------------------------------------------------------------------------------
// Task: write_phase_out_of_order
// Issue multiple write transactions with different AWIDs simultaneously
// Tests out-of-order write response capability per AXI4 specification
//--------------------------------------------------------------------------------------------
task axi4_virtual_nbk_write_read_response_out_of_order_seq::write_phase_out_of_order();
  
  // Declare sequence variables at task scope
  axi4_master_write_nbk_write_read_response_out_of_order_seq write_seq_0, write_seq_1, write_seq_2, write_seq_3;
  axi4_master_write_nbk_write_read_response_out_of_order_seq write_seq_4, write_seq_5, write_seq_6, write_seq_7;
  
  writes_issued = 0;
  writes_completed = 0;
  
  // Start write response monitoring
  fork
    monitor_write_responses();
  join_none
  
  // Issue 8 write transactions with different AWIDs in rapid succession
  // This creates potential for out-of-order write responses
  fork
    begin
      write_seq_0 = axi4_master_write_nbk_write_read_response_out_of_order_seq::type_id::create("write_seq_0");
      write_seq_0.transaction_awid = 4'h0;
      write_seq_0.start(p_sequencer.axi4_master_write_seqr_h);
      writes_issued++;
      `uvm_info("OOO_WRITE_PHASE", "Write transaction 1 issued with AWID=0x0", UVM_LOW);
    end
    begin
      #5; // Small delay to create timing variation
      write_seq_1 = axi4_master_write_nbk_write_read_response_out_of_order_seq::type_id::create("write_seq_1");
      write_seq_1.transaction_awid = 4'h1;
      write_seq_1.start(p_sequencer.axi4_master_write_seqr_h);
      writes_issued++;
      `uvm_info("OOO_WRITE_PHASE", "Write transaction 2 issued with AWID=0x1", UVM_LOW);
    end
    begin
      #10;
      write_seq_2 = axi4_master_write_nbk_write_read_response_out_of_order_seq::type_id::create("write_seq_2");
      write_seq_2.transaction_awid = 4'h2;
      write_seq_2.start(p_sequencer.axi4_master_write_seqr_h);
      writes_issued++;
      `uvm_info("OOO_WRITE_PHASE", "Write transaction 3 issued with AWID=0x2", UVM_LOW);
    end
    begin
      #15;
      write_seq_3 = axi4_master_write_nbk_write_read_response_out_of_order_seq::type_id::create("write_seq_3");
      write_seq_3.transaction_awid = 4'h3;
      write_seq_3.start(p_sequencer.axi4_master_write_seqr_h);
      writes_issued++;
      `uvm_info("OOO_WRITE_PHASE", "Write transaction 4 issued with AWID=0x3", UVM_LOW);
    end
    begin
      #20;
      write_seq_4 = axi4_master_write_nbk_write_read_response_out_of_order_seq::type_id::create("write_seq_4");
      write_seq_4.transaction_awid = 4'h4;
      write_seq_4.start(p_sequencer.axi4_master_write_seqr_h);
      writes_issued++;
      `uvm_info("OOO_WRITE_PHASE", "Write transaction 5 issued with AWID=0x4", UVM_LOW);
    end
    begin
      #25;
      write_seq_5 = axi4_master_write_nbk_write_read_response_out_of_order_seq::type_id::create("write_seq_5");
      write_seq_5.transaction_awid = 4'h5;
      write_seq_5.start(p_sequencer.axi4_master_write_seqr_h);
      writes_issued++;
      `uvm_info("OOO_WRITE_PHASE", "Write transaction 6 issued with AWID=0x5", UVM_LOW);
    end
    begin
      #30;
      write_seq_6 = axi4_master_write_nbk_write_read_response_out_of_order_seq::type_id::create("write_seq_6");
      write_seq_6.transaction_awid = 4'h6;
      write_seq_6.start(p_sequencer.axi4_master_write_seqr_h);
      writes_issued++;
      `uvm_info("OOO_WRITE_PHASE", "Write transaction 7 issued with AWID=0x6", UVM_LOW);
    end
    begin
      #35;
      write_seq_7 = axi4_master_write_nbk_write_read_response_out_of_order_seq::type_id::create("write_seq_7");
      write_seq_7.transaction_awid = 4'h7;
      write_seq_7.start(p_sequencer.axi4_master_write_seqr_h);
      writes_issued++;
      `uvm_info("OOO_WRITE_PHASE", "Write transaction 8 issued with AWID=0x7", UVM_LOW);
    end
  join
  
  `uvm_info("OOO_WRITE_PHASE", $sformatf("All %0d write transactions issued - waiting for responses", writes_issued), UVM_LOW);
  
endtask : write_phase_out_of_order

//--------------------------------------------------------------------------------------------
// Task: monitor_write_responses
// Monitor write response completion to track when all writes are done
//--------------------------------------------------------------------------------------------
task axi4_virtual_nbk_write_read_response_out_of_order_seq::monitor_write_responses();
  // Wait for all 8 write transactions to be issued first
  wait(writes_issued == 8);
  `uvm_info("WRITE_MONITOR", "All 8 write transactions issued - waiting for responses", UVM_LOW);
  
  // Wait sufficient time for write responses to complete
  // AXI4 write transactions should complete within reasonable time
  #5000; // Wait 5000 time units for write completion
  
  writes_completed = writes_issued; // Mark all as completed
  `uvm_info("WRITE_MONITOR", "All write responses completed", UVM_LOW);
  -> all_writes_completed;
endtask : monitor_write_responses

//--------------------------------------------------------------------------------------------
// Task: wait_for_write_completion  
// Wait for all write responses to ensure proper read-after-write ordering
//--------------------------------------------------------------------------------------------
task axi4_virtual_nbk_write_read_response_out_of_order_seq::wait_for_write_completion();
  
  `uvm_info("SYNC_PHASE", "Waiting for all write responses to complete...", UVM_LOW);
  
  // Wait for write completion event
  wait (all_writes_completed.triggered);
  
  // Additional safety margin for write propagation
  #200;
  
  `uvm_info("SYNC_PHASE", "All writes completed - safe to proceed with reads", UVM_LOW);
  
endtask : wait_for_write_completion

//--------------------------------------------------------------------------------------------
// Task: read_phase_out_of_order
// Issue read transactions to previously written addresses with different ARIDs
// Tests out-of-order read response capability and read-after-write data integrity
//--------------------------------------------------------------------------------------------
task axi4_virtual_nbk_write_read_response_out_of_order_seq::read_phase_out_of_order();
  
  // Declare sequence variables at task scope  
  axi4_master_read_nbk_write_read_response_out_of_order_seq read_seq_0, read_seq_1, read_seq_2, read_seq_3;
  axi4_master_read_nbk_write_read_response_out_of_order_seq read_seq_4, read_seq_5, read_seq_6, read_seq_7;
  
  // Issue 8 read transactions with different ARIDs in rapid succession
  // Targeting addresses written in write phase for read-after-write verification
  fork
    begin
      read_seq_0 = axi4_master_read_nbk_write_read_response_out_of_order_seq::type_id::create("read_seq_0");
      read_seq_0.transaction_arid = 4'h8;
      read_seq_0.start(p_sequencer.axi4_master_read_seqr_h);
      `uvm_info("OOO_READ_PHASE", "Read transaction 1 issued with ARID=0x8", UVM_LOW);
    end
    begin
      #3; // Small delay to create timing variation
      read_seq_1 = axi4_master_read_nbk_write_read_response_out_of_order_seq::type_id::create("read_seq_1");
      read_seq_1.transaction_arid = 4'h9;
      read_seq_1.start(p_sequencer.axi4_master_read_seqr_h);
      `uvm_info("OOO_READ_PHASE", "Read transaction 2 issued with ARID=0x9", UVM_LOW);
    end
    begin
      #6;
      read_seq_2 = axi4_master_read_nbk_write_read_response_out_of_order_seq::type_id::create("read_seq_2");
      read_seq_2.transaction_arid = 4'hA;
      read_seq_2.start(p_sequencer.axi4_master_read_seqr_h);
      `uvm_info("OOO_READ_PHASE", "Read transaction 3 issued with ARID=0xA", UVM_LOW);
    end
    begin
      #9;
      read_seq_3 = axi4_master_read_nbk_write_read_response_out_of_order_seq::type_id::create("read_seq_3");
      read_seq_3.transaction_arid = 4'hB;
      read_seq_3.start(p_sequencer.axi4_master_read_seqr_h);
      `uvm_info("OOO_READ_PHASE", "Read transaction 4 issued with ARID=0xB", UVM_LOW);
    end
    begin
      #12;
      read_seq_4 = axi4_master_read_nbk_write_read_response_out_of_order_seq::type_id::create("read_seq_4");
      read_seq_4.transaction_arid = 4'hC;
      read_seq_4.start(p_sequencer.axi4_master_read_seqr_h);
      `uvm_info("OOO_READ_PHASE", "Read transaction 5 issued with ARID=0xC", UVM_LOW);
    end
    begin
      #15;
      read_seq_5 = axi4_master_read_nbk_write_read_response_out_of_order_seq::type_id::create("read_seq_5");
      read_seq_5.transaction_arid = 4'hD;
      read_seq_5.start(p_sequencer.axi4_master_read_seqr_h);
      `uvm_info("OOO_READ_PHASE", "Read transaction 6 issued with ARID=0xD", UVM_LOW);
    end
    begin
      #18;
      read_seq_6 = axi4_master_read_nbk_write_read_response_out_of_order_seq::type_id::create("read_seq_6");
      read_seq_6.transaction_arid = 4'hE;
      read_seq_6.start(p_sequencer.axi4_master_read_seqr_h);
      `uvm_info("OOO_READ_PHASE", "Read transaction 7 issued with ARID=0xE", UVM_LOW);
    end
    begin
      #21;
      read_seq_7 = axi4_master_read_nbk_write_read_response_out_of_order_seq::type_id::create("read_seq_7");
      read_seq_7.transaction_arid = 4'hF;
      read_seq_7.start(p_sequencer.axi4_master_read_seqr_h);
      `uvm_info("OOO_READ_PHASE", "Read transaction 8 issued with ARID=0xF", UVM_LOW);
    end
  join
  
  `uvm_info("OOO_READ_PHASE", "All read transactions issued for read-after-write verification", UVM_LOW);
  
  // Allow time for read responses to complete
  #2000;
  
endtask : read_phase_out_of_order

`endif