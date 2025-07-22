`ifndef AXI4_TC_001_CONCURRENT_READS_VIRTUAL_SEQ_INCLUDED_
`define AXI4_TC_001_CONCURRENT_READS_VIRTUAL_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_tc_001_concurrent_reads_virtual_seq
// Virtual sequence for Test Case 1: Concurrent Read Operations (AxPROT & AxCACHE Focus)
// Coordinates 5 concurrent read operations from different masters
//--------------------------------------------------------------------------------------------
class axi4_tc_001_concurrent_reads_virtual_seq extends axi4_virtual_base_seq;
  
  `uvm_object_utils(axi4_tc_001_concurrent_reads_virtual_seq)

  // Master sequence handles
  axi4_tc_001_m0_legal_cacheable_read_seq      m0_seq_h;
  axi4_tc_001_m1_illegal_nonsecure_read_seq    m1_seq_h; 
  axi4_tc_001_m2_legal_instruction_read_seq    m2_seq_h;
  axi4_tc_001_m7_illegal_data_read_seq         m7_seq_h;
  axi4_tc_001_m8_illegal_unprivileged_read_seq m8_seq_h;
  
  // Slave sequence handles for continuous response
  axi4_slave_bk_read_seq axi4_slave_read_seq_h[10];

  extern function new(string name = "axi4_tc_001_concurrent_reads_virtual_seq");
  extern task body();
  extern task setup_slave_sequences();
  extern task execute_concurrent_reads();

endclass : axi4_tc_001_concurrent_reads_virtual_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_tc_001_concurrent_reads_virtual_seq::new(string name = "axi4_tc_001_concurrent_reads_virtual_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Main execution task for the virtual sequence
//--------------------------------------------------------------------------------------------
task axi4_tc_001_concurrent_reads_virtual_seq::body();
  
  `uvm_info("TC001_VSEQ", "========================================", UVM_NONE);
  `uvm_info("TC001_VSEQ", "Starting TC001 Concurrent Reads Virtual Sequence", UVM_NONE);
  `uvm_info("TC001_VSEQ", "Testing AxPROT & AxCACHE attribute handling", UVM_NONE);
  `uvm_info("TC001_VSEQ", "========================================", UVM_NONE);
  
  // Get environment configuration and cast sequencer
  super.body();
  
  // Create master sequence handles
  m0_seq_h = axi4_tc_001_m0_legal_cacheable_read_seq::type_id::create("m0_seq_h");
  m1_seq_h = axi4_tc_001_m1_illegal_nonsecure_read_seq::type_id::create("m1_seq_h");
  m2_seq_h = axi4_tc_001_m2_legal_instruction_read_seq::type_id::create("m2_seq_h");
  m7_seq_h = axi4_tc_001_m7_illegal_data_read_seq::type_id::create("m7_seq_h");
  m8_seq_h = axi4_tc_001_m8_illegal_unprivileged_read_seq::type_id::create("m8_seq_h");
  
  // Setup slave sequences for continuous response
  setup_slave_sequences();
  
  // Execute the concurrent read test
  execute_concurrent_reads();
  
  `uvm_info("TC001_VSEQ", "========================================", UVM_NONE);
  `uvm_info("TC001_VSEQ", "TC001 Concurrent Reads Virtual Sequence COMPLETE", UVM_NONE);
  `uvm_info("TC001_VSEQ", "Expected Results Summary:", UVM_NONE);
  `uvm_info("TC001_VSEQ", "- M0→S2: OKAY (Secure CPU, cacheable access)", UVM_NONE);
  `uvm_info("TC001_VSEQ", "- M1→S0: DECERR (Non-secure access to secure region)", UVM_NONE);
  `uvm_info("TC001_VSEQ", "- M2→S4: OKAY (Legal instruction fetch)", UVM_NONE);
  `uvm_info("TC001_VSEQ", "- M7→S4: SLVERR (Data access to instruction-only region)", UVM_NONE);
  `uvm_info("TC001_VSEQ", "- M8→S6: SLVERR (Unprivileged access to privileged region)", UVM_NONE);
  `uvm_info("TC001_VSEQ", "========================================", UVM_NONE);
  
endtask : body

//--------------------------------------------------------------------------------------------
// Task: setup_slave_sequences
// Setup slave sequences to run continuously and respond to read requests
//--------------------------------------------------------------------------------------------
task axi4_tc_001_concurrent_reads_virtual_seq::setup_slave_sequences();
  
  `uvm_info("TC001_VSEQ", "Setting up slave sequences for continuous operation", UVM_MEDIUM);
  
  // Create slave read sequences for all slaves
  foreach(axi4_slave_read_seq_h[i]) begin
    axi4_slave_read_seq_h[i] = axi4_slave_bk_read_seq::type_id::create($sformatf("axi4_slave_read_seq_h[%0d]", i));
  end
  
  // Start slave sequences in parallel to handle incoming read requests
  fork
    // Start continuous slave read sequences for all 10 slaves
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
  
  `uvm_info("TC001_VSEQ", "All slave read sequences started continuously", UVM_MEDIUM);
  
endtask : setup_slave_sequences

//--------------------------------------------------------------------------------------------
// Task: execute_concurrent_reads
// Execute all 5 concurrent read operations from different masters
//--------------------------------------------------------------------------------------------
task axi4_tc_001_concurrent_reads_virtual_seq::execute_concurrent_reads();
  
  `uvm_info("TC001_VSEQ", "Executing 5 concurrent read operations", UVM_MEDIUM);
  
  // Execute all master read sequences concurrently
  fork
    begin : M0_SECURE_CPU_READ
      `uvm_info("TC001_VSEQ", "Starting M0 (Secure CPU) → S2 (Shared Buffer)", UVM_MEDIUM);
      m0_seq_h.start(p_sequencer.axi4_master_read_seqr_h[0]);
      `uvm_info("TC001_VSEQ", "Completed M0 → S2 operation", UVM_MEDIUM);
    end
    
    begin : M1_NONSECURE_CPU_READ
      `uvm_info("TC001_VSEQ", "Starting M1 (NS CPU) → S0 (Secure Kernel)", UVM_MEDIUM);
      m1_seq_h.start(p_sequencer.axi4_master_read_seqr_h[1]);
      `uvm_info("TC001_VSEQ", "Completed M1 → S0 operation", UVM_MEDIUM);
    end
    
    begin : M2_INSTRUCTION_FETCH_READ
      `uvm_info("TC001_VSEQ", "Starting M2 (I-Fetch) → S4 (XOM)", UVM_MEDIUM);
      m2_seq_h.start(p_sequencer.axi4_master_read_seqr_h[2]);
      `uvm_info("TC001_VSEQ", "Completed M2 → S4 operation", UVM_MEDIUM);
    end
    
    begin : M7_MALICIOUS_READ
      `uvm_info("TC001_VSEQ", "Starting M7 (Malicious) → S4 (XOM)", UVM_MEDIUM);
      m7_seq_h.start(p_sequencer.axi4_master_read_seqr_h[7]);
      `uvm_info("TC001_VSEQ", "Completed M7 → S4 operation", UVM_MEDIUM);
    end
    
    begin : M8_RO_PERIPHERAL_READ
      `uvm_info("TC001_VSEQ", "Starting M8 (RO Peripheral) → S6 (Privileged-Only)", UVM_MEDIUM);
      m8_seq_h.start(p_sequencer.axi4_master_read_seqr_h[8]);
      `uvm_info("TC001_VSEQ", "Completed M8 → S6 operation", UVM_MEDIUM);
    end
  join
  
  `uvm_info("TC001_VSEQ", "All 5 concurrent read operations completed", UVM_MEDIUM);
  
  // Add small delay for transaction completion and response propagation
  #1000;
  
endtask : execute_concurrent_reads

`endif