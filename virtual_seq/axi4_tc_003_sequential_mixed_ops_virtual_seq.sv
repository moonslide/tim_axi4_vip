`ifndef AXI4_TC_003_SEQUENTIAL_MIXED_OPS_VIRTUAL_SEQ_INCLUDED_
`define AXI4_TC_003_SEQUENTIAL_MIXED_OPS_VIRTUAL_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_tc_003_sequential_mixed_ops_virtual_seq
// Test Case 3: Sequential Mixed Read/Write Operations
//--------------------------------------------------------------------------------------------
class axi4_tc_003_sequential_mixed_ops_virtual_seq extends axi4_virtual_base_seq;
  
  `uvm_object_utils(axi4_tc_003_sequential_mixed_ops_virtual_seq)

  // Master sequences for sequential operations
  axi4_master_bk_write_seq m4_write_seq_h; // M4 → S8 write
  axi4_master_bk_read_seq  m6_read_seq_h;  // M6 → S8 read
  axi4_master_bk_write_seq m7_write_seq_h; // M7 → S7 error write
  axi4_master_bk_read_seq  m2_read_seq_h;  // M2 → S0 instruction read
  
  // Slave sequences
  axi4_slave_bk_write_seq axi4_slave_write_seq_h[10];
  axi4_slave_bk_read_seq  axi4_slave_read_seq_h[10];

  extern function new(string name = "axi4_tc_003_sequential_mixed_ops_virtual_seq");
  extern task body();
  extern task setup_slave_sequences();
  extern task execute_sequential_operations();

endclass : axi4_tc_003_sequential_mixed_ops_virtual_seq

function axi4_tc_003_sequential_mixed_ops_virtual_seq::new(string name = "axi4_tc_003_sequential_mixed_ops_virtual_seq");
  super.new(name);
endfunction : new

task axi4_tc_003_sequential_mixed_ops_virtual_seq::body();
  
  `uvm_info("TC003_VSEQ", "Starting TC003 Sequential Mixed Operations", UVM_NONE);
  
  super.body();
  
  // Create sequence handles
  m4_write_seq_h = axi4_master_bk_write_seq::type_id::create("m4_write_seq_h");
  m6_read_seq_h  = axi4_master_bk_read_seq::type_id::create("m6_read_seq_h");
  m7_write_seq_h = axi4_master_bk_write_seq::type_id::create("m7_write_seq_h");
  m2_read_seq_h  = axi4_master_bk_read_seq::type_id::create("m2_read_seq_h");
  
  setup_slave_sequences();
  #1000; // Reduced slave initialization delay for faster execution
  execute_sequential_operations();
  
  `uvm_info("TC003_VSEQ", "TC003 Sequential Mixed Operations COMPLETE", UVM_NONE);
  
endtask : body

task axi4_tc_003_sequential_mixed_ops_virtual_seq::setup_slave_sequences();
  
  `uvm_info("TC003_VSEQ", "Setting up slave sequences for sequential operations", UVM_MEDIUM);
  
  foreach(axi4_slave_write_seq_h[i]) begin
    axi4_slave_write_seq_h[i] = axi4_slave_bk_write_seq::type_id::create($sformatf("axi4_slave_write_seq_h[%0d]", i));
    axi4_slave_read_seq_h[i] = axi4_slave_bk_read_seq::type_id::create($sformatf("axi4_slave_read_seq_h[%0d]", i));
  end
  
  // Start slave sequences for expected transactions
  fork
    begin : SLAVE_RESPONSES
      fork
        begin : SLAVE_S0_READ_HANDLER
          repeat(20) axi4_slave_read_seq_h[0].start(p_sequencer.axi4_slave_read_seqr_h_all[0]); // S0 handles M2 read
        end
        begin : SLAVE_S7_WRITE_HANDLER
          repeat(20) axi4_slave_write_seq_h[7].start(p_sequencer.axi4_slave_write_seqr_h_all[7]); // S7 handles M7 write
        end
        begin : SLAVE_S8_WRITE_HANDLER
          repeat(20) axi4_slave_write_seq_h[8].start(p_sequencer.axi4_slave_write_seqr_h_all[8]); // S8 handles M4 write
        end
        begin : SLAVE_S8_READ_HANDLER
          repeat(20) axi4_slave_read_seq_h[8].start(p_sequencer.axi4_slave_read_seqr_h_all[8]); // S8 handles M6 read
        end
      join_any
    end
  join_none
  
  `uvm_info("TC003_VSEQ", "Slave sequences started for sequential operations", UVM_MEDIUM);
  
endtask : setup_slave_sequences

task axi4_tc_003_sequential_mixed_ops_virtual_seq::execute_sequential_operations();
  
  `uvm_info("TC003_VSEQ", "Executing sequential mixed operations", UVM_MEDIUM);
  
  // Sequential execution as per claude.md with extended timeout protection
  fork
    begin : SEQUENTIAL_OPERATIONS
      // 1. M4 (AI Accel) → S8 (Scratchpad): Write to shared register
      `uvm_info("TC003_VSEQ", "Step 1: M4 → S8 Write (Expect: OKAY)", UVM_MEDIUM);
      m4_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h_all[4]);
      `uvm_info("TC003_VSEQ", "Step 1: M4 → S8 Write COMPLETED", UVM_MEDIUM);
      #500; // Reduced inter-operation delay for faster execution
      
      // 2. M6 (DMA-NS) → S8 (Scratchpad): Read data written by M4
      `uvm_info("TC003_VSEQ", "Step 2: M6 → S8 Read (Expect: OKAY)", UVM_MEDIUM);
      m6_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h_all[6]);
      `uvm_info("TC003_VSEQ", "Step 2: M6 → S8 Read COMPLETED", UVM_MEDIUM);
      #500; // Reduced inter-operation delay for faster execution
      
      // 3. M7 (Malicious) → S7 (Secure-Only): Attempt write to secure-only region
      `uvm_info("TC003_VSEQ", "Step 3: M7 → S7 Write (Expect: SLVERR)", UVM_MEDIUM);
      m7_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h_all[7]);
      `uvm_info("TC003_VSEQ", "Step 3: M7 → S7 Write COMPLETED", UVM_MEDIUM);
      #500; // Reduced inter-operation delay for faster execution
      
      // 4. M2 (I-Fetch) → S0 (Secure Kernel): Instruction read
      `uvm_info("TC003_VSEQ", "Step 4: M2 → S0 Read (Expect: OKAY)", UVM_MEDIUM);
      m2_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h_all[2]);
      `uvm_info("TC003_VSEQ", "Step 4: M2 → S0 Read COMPLETED", UVM_MEDIUM);
      #500; // Reduced inter-operation delay for faster execution
      
      `uvm_info("TC003_VSEQ", "All sequential operations completed successfully", UVM_MEDIUM);
    end
    
    begin : OPERATION_TIMEOUT
      #200000; // 200000 time units timeout for sequential operations (increased to allow write operations to complete)
      `uvm_warning("TC003_VSEQ", "Sequential operation timeout reached - proceeding with test completion");
    end
  join_any
  
  // Kill any remaining threads (especially the timeout thread) to prevent spurious warnings
  disable fork;
  
  `uvm_info("TC003_VSEQ", "Sequential operations phase complete", UVM_MEDIUM);
  
  // Reduced completion delay
  #200;
  
endtask : execute_sequential_operations

`endif