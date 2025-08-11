`ifndef AXI4_CONCURRENT_WRITES_RAW_VIRTUAL_SEQ_INCLUDED_
`define AXI4_CONCURRENT_WRITES_RAW_VIRTUAL_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_concurrent_writes_raw_virtual_seq
// Virtual sequence for Test Case 2: Concurrent Write Operations and Read-After-Write
// Coordinates concurrent writes followed by read-after-write verification
//--------------------------------------------------------------------------------------------
class axi4_concurrent_writes_raw_virtual_seq extends axi4_virtual_base_seq;
  
  `uvm_object_utils(axi4_concurrent_writes_raw_virtual_seq)

  // Write sequence handles
  axi4_concurrent_writes_raw_m0_legal_secure_write_seq      m0_write_seq_h;
  axi4_concurrent_writes_raw_m3_illegal_ro_write_seq        m3_write_seq_h;
  axi4_concurrent_writes_raw_m6_illegal_hole_write_seq      m6_write_seq_h;
  axi4_concurrent_writes_raw_m9_legal_monitor_write_seq     m9_write_seq_h;
  
  // Read-after-write sequence handles
  axi4_concurrent_writes_raw_m0_raw_read_seq                m0_raw_seq_h;
  axi4_concurrent_writes_raw_m9_raw_illegal_read_seq        m9_raw_seq_h;
  
  // Slave sequence handles for continuous response
  axi4_slave_bk_write_seq axi4_slave_write_seq_h[10];
  axi4_slave_bk_read_seq  axi4_slave_read_seq_h[10];

  extern function new(string name = "axi4_concurrent_writes_raw_virtual_seq");
  extern task body();
  extern task setup_slave_sequences();
  extern task execute_concurrent_writes();
  extern task execute_read_after_write_verification();

endclass : axi4_concurrent_writes_raw_virtual_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_concurrent_writes_raw_virtual_seq::new(string name = "axi4_concurrent_writes_raw_virtual_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Main execution task for the virtual sequence
//--------------------------------------------------------------------------------------------
task axi4_concurrent_writes_raw_virtual_seq::body();
  
  `uvm_info("TC002_VSEQ", "========================================", UVM_NONE);
  `uvm_info("TC002_VSEQ", "Starting TC002 Concurrent Writes + RAW Virtual Sequence", UVM_NONE);
  `uvm_info("TC002_VSEQ", "Testing AWPROT & AWCACHE attribute handling", UVM_NONE);
  `uvm_info("TC002_VSEQ", "========================================", UVM_NONE);
  
  // Get environment configuration and cast sequencer
  super.body();
  
  // Create write sequence handles
  m0_write_seq_h = axi4_concurrent_writes_raw_m0_legal_secure_write_seq::type_id::create("m0_write_seq_h");
  m3_write_seq_h = axi4_concurrent_writes_raw_m3_illegal_ro_write_seq::type_id::create("m3_write_seq_h");
  m6_write_seq_h = axi4_concurrent_writes_raw_m6_illegal_hole_write_seq::type_id::create("m6_write_seq_h");
  m9_write_seq_h = axi4_concurrent_writes_raw_m9_legal_monitor_write_seq::type_id::create("m9_write_seq_h");
  
  // Create read-after-write sequence handles
  m0_raw_seq_h = axi4_concurrent_writes_raw_m0_raw_read_seq::type_id::create("m0_raw_seq_h");
  m9_raw_seq_h = axi4_concurrent_writes_raw_m9_raw_illegal_read_seq::type_id::create("m9_raw_seq_h");
  
  // Setup slave sequences for continuous response
  setup_slave_sequences();
  
  // Execute the concurrent write test
  execute_concurrent_writes();
  
  // Execute read-after-write verification
  execute_read_after_write_verification();
  
  `uvm_info("TC002_VSEQ", "========================================", UVM_NONE);
  `uvm_info("TC002_VSEQ", "TC002 Concurrent Writes + RAW Virtual Sequence COMPLETE", UVM_NONE);
  `uvm_info("TC002_VSEQ", "Expected Results Summary:", UVM_NONE);
  `uvm_info("TC002_VSEQ", "Concurrent Writes:", UVM_NONE);
  `uvm_info("TC002_VSEQ", "- M0→S0: OKAY (Secure CPU to secure region)", UVM_NONE);
  `uvm_info("TC002_VSEQ", "- M3→S5: SLVERR (Write to read-only region)", UVM_NONE);
  `uvm_info("TC002_VSEQ", "- M6→S3: DECERR (Write to illegal address hole)", UVM_NONE);
  `uvm_info("TC002_VSEQ", "- M9→S9: OKAY (Write to monitor region)", UVM_NONE);
  `uvm_info("TC002_VSEQ", "Read-After-Write Verification:", UVM_NONE);
  `uvm_info("TC002_VSEQ", "- M0→S0: OKAY (Legal read from secure region)", UVM_NONE);
  `uvm_info("TC002_VSEQ", "- M9→S9: SLVERR (Read from write-only region)", UVM_NONE);
  `uvm_info("TC002_VSEQ", "========================================", UVM_NONE);
  
endtask : body

//--------------------------------------------------------------------------------------------
// Task: setup_slave_sequences
// Setup slave sequences to run continuously and respond to write/read requests
//--------------------------------------------------------------------------------------------
task axi4_concurrent_writes_raw_virtual_seq::setup_slave_sequences();
  
  `uvm_info("TC002_VSEQ", "Setting up slave sequences for continuous operation", UVM_MEDIUM);
  
  // Create slave write and read sequences for all slaves
  foreach(axi4_slave_write_seq_h[i]) begin
    axi4_slave_write_seq_h[i] = axi4_slave_bk_write_seq::type_id::create($sformatf("axi4_slave_write_seq_h[%0d]", i));
    axi4_slave_read_seq_h[i] = axi4_slave_bk_read_seq::type_id::create($sformatf("axi4_slave_read_seq_h[%0d]", i));
  end
  
  // Start slave sequences in parallel to handle incoming write/read requests
  fork
    // Write sequences for all 10 slaves
    begin : SLAVE_WRITE_SEQUENCES
      fork
        begin : S0_WRITE_SEQ
          forever begin
            axi4_slave_bk_write_seq temp_write_seq_s0 = axi4_slave_bk_write_seq::type_id::create("temp_write_seq_s0");
            temp_write_seq_s0.start(p_sequencer.axi4_slave_write_seqr_h[0]);
          end
        end
        begin : S1_WRITE_SEQ
          forever begin
            axi4_slave_bk_write_seq temp_write_seq_s1 = axi4_slave_bk_write_seq::type_id::create("temp_write_seq_s1");
            temp_write_seq_s1.start(p_sequencer.axi4_slave_write_seqr_h[1]);
          end
        end
        begin : S2_WRITE_SEQ
          forever begin
            axi4_slave_bk_write_seq temp_write_seq_s2 = axi4_slave_bk_write_seq::type_id::create("temp_write_seq_s2");
            temp_write_seq_s2.start(p_sequencer.axi4_slave_write_seqr_h[2]);
          end
        end
        begin : S3_WRITE_SEQ
          forever begin
            axi4_slave_bk_write_seq temp_write_seq_s3 = axi4_slave_bk_write_seq::type_id::create("temp_write_seq_s3");
            temp_write_seq_s3.start(p_sequencer.axi4_slave_write_seqr_h[3]);
          end
        end
        begin : S4_WRITE_SEQ
          forever begin
            axi4_slave_bk_write_seq temp_write_seq_s4 = axi4_slave_bk_write_seq::type_id::create("temp_write_seq_s4");
            temp_write_seq_s4.start(p_sequencer.axi4_slave_write_seqr_h[4]);
          end
        end
        begin : S5_WRITE_SEQ
          forever begin
            axi4_slave_bk_write_seq temp_write_seq_s5 = axi4_slave_bk_write_seq::type_id::create("temp_write_seq_s5");
            temp_write_seq_s5.start(p_sequencer.axi4_slave_write_seqr_h[5]);
          end
        end
        begin : S6_WRITE_SEQ
          forever begin
            axi4_slave_bk_write_seq temp_write_seq_s6 = axi4_slave_bk_write_seq::type_id::create("temp_write_seq_s6");
            temp_write_seq_s6.start(p_sequencer.axi4_slave_write_seqr_h[6]);
          end
        end
        begin : S7_WRITE_SEQ
          forever begin
            axi4_slave_bk_write_seq temp_write_seq_s7 = axi4_slave_bk_write_seq::type_id::create("temp_write_seq_s7");
            temp_write_seq_s7.start(p_sequencer.axi4_slave_write_seqr_h[7]);
          end
        end
        begin : S8_WRITE_SEQ
          forever begin
            axi4_slave_bk_write_seq temp_write_seq_s8 = axi4_slave_bk_write_seq::type_id::create("temp_write_seq_s8");
            temp_write_seq_s8.start(p_sequencer.axi4_slave_write_seqr_h[8]);
          end
        end
        begin : S9_WRITE_SEQ
          forever begin
            axi4_slave_bk_write_seq temp_write_seq_s9 = axi4_slave_bk_write_seq::type_id::create("temp_write_seq_s9");
            temp_write_seq_s9.start(p_sequencer.axi4_slave_write_seqr_h[9]);
          end
        end
      join
    end
    
    // Read sequences for all 10 slaves
    begin : SLAVE_READ_SEQUENCES
      fork
        begin : S0_READ_SEQ
          forever begin
            axi4_slave_read_seq_h[0].start(p_sequencer.axi4_slave_read_seqr_h[0]);
          end
        end
        begin : S1_READ_SEQ
          forever begin
            axi4_slave_read_seq_h[1].start(p_sequencer.axi4_slave_read_seqr_h[1]);
          end
        end
        begin : S2_READ_SEQ
          forever begin
            axi4_slave_read_seq_h[2].start(p_sequencer.axi4_slave_read_seqr_h[2]);
          end
        end
        begin : S3_READ_SEQ
          forever begin
            axi4_slave_read_seq_h[3].start(p_sequencer.axi4_slave_read_seqr_h[3]);
          end
        end
        begin : S4_READ_SEQ
          forever begin
            axi4_slave_read_seq_h[4].start(p_sequencer.axi4_slave_read_seqr_h[4]);
          end
        end
        begin : S5_READ_SEQ
          forever begin
            axi4_slave_read_seq_h[5].start(p_sequencer.axi4_slave_read_seqr_h[5]);
          end
        end
        begin : S6_READ_SEQ
          forever begin
            axi4_slave_read_seq_h[6].start(p_sequencer.axi4_slave_read_seqr_h[6]);
          end
        end
        begin : S7_READ_SEQ
          forever begin
            axi4_slave_read_seq_h[7].start(p_sequencer.axi4_slave_read_seqr_h[7]);
          end
        end
        begin : S8_READ_SEQ
          forever begin
            axi4_slave_read_seq_h[8].start(p_sequencer.axi4_slave_read_seqr_h[8]);
          end
        end
        begin : S9_READ_SEQ
          forever begin
            axi4_slave_read_seq_h[9].start(p_sequencer.axi4_slave_read_seqr_h[9]);
          end
        end
      join
    end
  join_none
  
  `uvm_info("TC002_VSEQ", "All slave write and read sequences started continuously", UVM_MEDIUM);
  
endtask : setup_slave_sequences

//--------------------------------------------------------------------------------------------
// Task: execute_concurrent_writes
// Execute all 4 concurrent write operations from different masters
//--------------------------------------------------------------------------------------------
task axi4_concurrent_writes_raw_virtual_seq::execute_concurrent_writes();
  
  `uvm_info("TC002_VSEQ", "Executing 4 concurrent write operations", UVM_MEDIUM);
  
  // Execute all master write sequences concurrently
  fork
    begin : M0_SECURE_CPU_WRITE
      `uvm_info("TC002_VSEQ", "Starting M0 (Secure CPU) → S0 (Secure Kernel)", UVM_MEDIUM);
      m0_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h[0]);
      `uvm_info("TC002_VSEQ", "Completed M0 → S0 write operation", UVM_MEDIUM);
    end
    
    begin : M3_GPU_WRITE
      `uvm_info("TC002_VSEQ", "Starting M3 (GPU) → S5 (RO Peripheral)", UVM_MEDIUM);
      m3_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h[3]);
      `uvm_info("TC002_VSEQ", "Completed M3 → S5 write operation", UVM_MEDIUM);
    end
    
    begin : M6_DMA_NS_WRITE
      `uvm_info("TC002_VSEQ", "Starting M6 (DMA-NS) → S3 (Address Hole)", UVM_MEDIUM);
      m6_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h[6]);
      `uvm_info("TC002_VSEQ", "Completed M6 → S3 write operation", UVM_MEDIUM);
    end
    
    begin : M9_LEGACY_WRITE
      `uvm_info("TC002_VSEQ", "Starting M9 (Legacy) → S9 (Attribute Monitor)", UVM_MEDIUM);
      m9_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h[9]);
      `uvm_info("TC002_VSEQ", "Completed M9 → S9 write operation", UVM_MEDIUM);
    end
  join
  
  `uvm_info("TC002_VSEQ", "All 4 concurrent write operations completed", UVM_MEDIUM);
  
  // Add delay for write completion and response propagation
  #500;
  
endtask : execute_concurrent_writes

//--------------------------------------------------------------------------------------------
// Task: execute_read_after_write_verification
// Execute read-after-write verification for successful write operations
//--------------------------------------------------------------------------------------------
task axi4_concurrent_writes_raw_virtual_seq::execute_read_after_write_verification();
  
  `uvm_info("TC002_VSEQ", "Starting Read-After-Write verification phase", UVM_MEDIUM);
  
  // Set target addresses for read-after-write sequences
  m0_raw_seq_h.target_address = m0_write_seq_h.write_address;
  m9_raw_seq_h.target_address = m9_write_seq_h.write_address;
  
  // Execute read-after-write sequences concurrently
  fork
    begin : M0_RAW_VERIFICATION
      `uvm_info("TC002_VSEQ", "Starting M0 Read-After-Write verification", UVM_MEDIUM);
      m0_raw_seq_h.start(p_sequencer.axi4_master_read_seqr_h[0]);
      `uvm_info("TC002_VSEQ", "Completed M0 RAW verification", UVM_MEDIUM);
    end
    
    begin : M9_RAW_VERIFICATION
      `uvm_info("TC002_VSEQ", "Starting M9 Read-After-Write verification (should fail)", UVM_MEDIUM);
      m9_raw_seq_h.start(p_sequencer.axi4_master_read_seqr_h[9]);
      `uvm_info("TC002_VSEQ", "Completed M9 RAW verification", UVM_MEDIUM);
    end
  join
  
  `uvm_info("TC002_VSEQ", "Read-After-Write verification phase completed", UVM_MEDIUM);
  
  // Add delay for transaction completion and response propagation
  #1000;
  
endtask : execute_read_after_write_verification

`endif