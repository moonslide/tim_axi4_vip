`ifndef AXI4_TC_004_CONCURRENT_ERROR_STRESS_VIRTUAL_SEQ_INCLUDED_
`define AXI4_TC_004_CONCURRENT_ERROR_STRESS_VIRTUAL_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_tc_004_concurrent_error_stress_virtual_seq
// Test Case 4: Concurrent Error Condition Stress Test and Read-After-Write
//--------------------------------------------------------------------------------------------
class axi4_tc_004_concurrent_error_stress_virtual_seq extends axi4_virtual_base_seq;
  
  `uvm_object_utils(axi4_tc_004_concurrent_error_stress_virtual_seq)

  // Error stress sequences
  axi4_master_bk_write_seq m1_write_seq_h; // M1 → S7 (non-secure to secure)
  axi4_master_bk_write_seq m3_write_seq_h; // M3 → S6 (unprivileged to privileged) 
  axi4_master_bk_write_seq m7_write_seq_h; // M7 → S0 (double violation)
  axi4_master_bk_read_seq  m8_read_seq_h;  // M8 → S9 (read write-only)
  
  // RAW verification sequences
  axi4_master_bk_read_seq  m7_raw_read_seq_h; // M7 → S0 after failed write
  axi4_master_bk_read_seq  m1_raw_read_seq_h; // M1 → S7 after failed write
  
  // Slave sequences
  axi4_slave_bk_write_seq axi4_slave_write_seq_h[10];
  axi4_slave_bk_read_seq  axi4_slave_read_seq_h[10];

  extern function new(string name = "axi4_tc_004_concurrent_error_stress_virtual_seq");
  extern task body();
  extern task setup_slave_sequences();
  extern task execute_concurrent_error_stress();
  extern task execute_raw_verification();

endclass : axi4_tc_004_concurrent_error_stress_virtual_seq

function axi4_tc_004_concurrent_error_stress_virtual_seq::new(string name = "axi4_tc_004_concurrent_error_stress_virtual_seq");
  super.new(name);
endfunction : new

task axi4_tc_004_concurrent_error_stress_virtual_seq::body();
  
  `uvm_info("TC004_VSEQ", "Starting TC004 Concurrent Error Stress Test", UVM_NONE);
  
  super.body();
  
  // Create sequence handles
  m1_write_seq_h    = axi4_master_bk_write_seq::type_id::create("m1_write_seq_h");
  m3_write_seq_h    = axi4_master_bk_write_seq::type_id::create("m3_write_seq_h");
  m7_write_seq_h    = axi4_master_bk_write_seq::type_id::create("m7_write_seq_h");
  m8_read_seq_h     = axi4_master_bk_read_seq::type_id::create("m8_read_seq_h");
  m7_raw_read_seq_h = axi4_master_bk_read_seq::type_id::create("m7_raw_read_seq_h");
  m1_raw_read_seq_h = axi4_master_bk_read_seq::type_id::create("m1_raw_read_seq_h");
  
  setup_slave_sequences();
  execute_concurrent_error_stress();
  execute_raw_verification();
  
  `uvm_info("TC004_VSEQ", "TC004 Concurrent Error Stress Test COMPLETE", UVM_NONE);
  
endtask : body

task axi4_tc_004_concurrent_error_stress_virtual_seq::setup_slave_sequences();
  
  foreach(axi4_slave_write_seq_h[i]) begin
    axi4_slave_write_seq_h[i] = axi4_slave_bk_write_seq::type_id::create($sformatf("axi4_slave_write_seq_h[%0d]", i));
    axi4_slave_read_seq_h[i] = axi4_slave_bk_read_seq::type_id::create($sformatf("axi4_slave_read_seq_h[%0d]", i));
  end
  
  // Start continuous slave sequences for relevant slaves
  fork
    begin
      fork
        forever axi4_slave_write_seq_h[0].start(p_sequencer.axi4_slave_write_seqr_h[0]); // S0
        forever axi4_slave_read_seq_h[0].start(p_sequencer.axi4_slave_read_seqr_h[0]); // S0
        forever axi4_slave_write_seq_h[6].start(p_sequencer.axi4_slave_write_seqr_h[6]); // S6
        forever axi4_slave_read_seq_h[6].start(p_sequencer.axi4_slave_read_seqr_h[6]); // S6
        forever axi4_slave_write_seq_h[7].start(p_sequencer.axi4_slave_write_seqr_h[7]); // S7
        forever axi4_slave_read_seq_h[7].start(p_sequencer.axi4_slave_read_seqr_h[7]); // S7
        forever axi4_slave_write_seq_h[9].start(p_sequencer.axi4_slave_write_seqr_h[9]); // S9
        forever axi4_slave_read_seq_h[9].start(p_sequencer.axi4_slave_read_seqr_h[9]); // S9
      join
    end
  join_none
  
endtask : setup_slave_sequences

task axi4_tc_004_concurrent_error_stress_virtual_seq::execute_concurrent_error_stress();
  
  `uvm_info("TC004_VSEQ", "Executing concurrent error stress operations", UVM_MEDIUM);
  
  // Execute concurrent error operations as per claude.md
  fork
    begin : M1_NS_CPU_ERROR_WRITE
      `uvm_info("TC004_VSEQ", "M1 → S7: Non-secure to secure (Expect: SLVERR)", UVM_MEDIUM);
      m1_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h[1]);
    end
    
    begin : M3_GPU_ERROR_WRITE
      `uvm_info("TC004_VSEQ", "M3 → S6: Unprivileged to privileged (Expect: SLVERR)", UVM_MEDIUM);
      m3_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h[3]);
    end
    
    begin : M7_MALICIOUS_ERROR_WRITE
      `uvm_info("TC004_VSEQ", "M7 → S0: Security & privilege violation (Expect: DECERR)", UVM_MEDIUM);
      m7_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h[7]);
    end
    
    begin : M8_RO_PERIPHERAL_ERROR_READ
      `uvm_info("TC004_VSEQ", "M8 → S9: Read from write-only (Expect: SLVERR)", UVM_MEDIUM);
      m8_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h[8]);
    end
  join
  
  `uvm_info("TC004_VSEQ", "Concurrent error stress operations completed", UVM_MEDIUM);
  #500; // Wait for completion
  
endtask : execute_concurrent_error_stress

task axi4_tc_004_concurrent_error_stress_virtual_seq::execute_raw_verification();
  
  `uvm_info("TC004_VSEQ", "Executing Read-After-Write error verification", UVM_MEDIUM);
  
  // RAW verification after failed operations
  fork
    begin : M7_RAW_VERIFICATION
      `uvm_info("TC004_VSEQ", "M7 → S0: RAW after failed write (Expect: DECERR)", UVM_MEDIUM);
      m7_raw_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h[7]);
    end
    
    begin : M1_RAW_VERIFICATION
      `uvm_info("TC004_VSEQ", "M1 → S7: RAW after failed write (Expect: SLVERR)", UVM_MEDIUM);
      m1_raw_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h[1]);
    end
  join
  
  `uvm_info("TC004_VSEQ", "RAW verification completed", UVM_MEDIUM);
  #1000; // Final completion delay
  
endtask : execute_raw_verification

`endif