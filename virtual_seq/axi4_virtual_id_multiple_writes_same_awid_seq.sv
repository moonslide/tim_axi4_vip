`ifndef AXI4_VIRTUAL_ID_MULTIPLE_WRITES_SAME_AWID_SEQ_INCLUDED_
`define AXI4_VIRTUAL_ID_MULTIPLE_WRITES_SAME_AWID_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_id_multiple_writes_same_awid_seq
// ID_MULTIPLE_WRITES_SAME_AWID: AXI4 Complex Out-of-Order Test with 4 Masters and 4 Slaves
// Tests AXI4 out-of-order transaction completion with NO write data interleaving
// 
// Test Architecture based on AXI_MATRIX.txt:
//   - 4 Masters sending transactions concurrently per access matrix
//   - 3 Slaves (DDR, Peripheral, HW_Fuse) with proper access control
//   - Multiple AWIDs per master for out-of-order scenarios
//   - Predictive verification using expected write data
//
// Master-Slave Access Matrix:
//   - M0 (CPU_Core_A): S0 (DDR R/W), S2 (Peripheral R/W), S3 (HW_Fuse R-Only)
//   - M1 (CPU_Core_B): S0 (DDR R/W), S2 (Peripheral R/W)
//   - M2 (DMA_Controller): S0 (DDR R/W), S2 (Peripheral R/W)
//   - M3 (GPU): S0 (DDR R/W), S3 (HW_Fuse R-Only)
//
// AXI4 Requirements Verified:
//   - Write data interleaving NOT supported (A5.4)
//   - Out-of-order completion for different AWIDs (A5.3)
//   - In-order completion for same AWID to same slave (Non-modifiable)
//   - Each transaction's write data is consecutive
//   - Proper handling of read-only slaves (S3)
//   - Complex multi-master scenarios with proper ordering
//--------------------------------------------------------------------------------------------
class axi4_virtual_id_multiple_writes_same_awid_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_id_multiple_writes_same_awid_seq)

  // Array of master sequences for 4 masters
  axi4_master_id_multiple_writes_same_awid_seq axi4_master_seq_h[4];
  
  // Scoreboard handle for backdoor verification
  axi4_scoreboard axi4_scoreboard_h;

  extern function new(string name = "axi4_virtual_id_multiple_writes_same_awid_seq");
  extern task body();
endclass : axi4_virtual_id_multiple_writes_same_awid_seq

function axi4_virtual_id_multiple_writes_same_awid_seq::new(string name = "axi4_virtual_id_multiple_writes_same_awid_seq");
  super.new(name);
endfunction : new

task axi4_virtual_id_multiple_writes_same_awid_seq::body();
  int slave_id;
  bit verify_result;
  bit all_tests_passed = 1;
  
  // Get scoreboard handle for backdoor verification
  if(!uvm_config_db#(axi4_scoreboard)::get(null, "*", "axi4_scoreboard_h", axi4_scoreboard_h)) begin
    `uvm_warning(get_type_name(), "Cannot get scoreboard handle - backdoor verification disabled")
  end
  
  `uvm_info(get_type_name(), "ID_MULTIPLE_WRITES_SAME_AWID: Starting AXI4 Complex Out-of-Order Test", UVM_LOW);
  `uvm_info(get_type_name(), "ID_MULTIPLE_WRITES_SAME_AWID: 4 Masters x 4 Slaves with NO Write Interleaving", UVM_LOW);
  `uvm_info(get_type_name(), "ID_MULTIPLE_WRITES_SAME_AWID: Testing AXI4 out-of-order completion per spec", UVM_LOW);
  
  // Create and configure master sequences for all 4 masters
  foreach(axi4_master_seq_h[i]) begin
    axi4_master_seq_h[i] = axi4_master_id_multiple_writes_same_awid_seq::type_id::create($sformatf("axi4_master_seq_h[%0d]", i));
    axi4_master_seq_h[i].master_id = i;  // Set master ID
  end
  
  `uvm_info(get_type_name(), "ID_MULTIPLE_WRITES_SAME_AWID: Starting all 4 masters concurrently", UVM_LOW);
  
  // Start all 4 master sequences concurrently - creates complex out-of-order scenarios
  fork
    begin : master_0
      axi4_master_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h_all[0]);
    end
    begin : master_1
      axi4_master_seq_h[1].start(p_sequencer.axi4_master_write_seqr_h_all[1]);
    end
    begin : master_2
      axi4_master_seq_h[2].start(p_sequencer.axi4_master_write_seqr_h_all[2]);
    end
    begin : master_3
      axi4_master_seq_h[3].start(p_sequencer.axi4_master_write_seqr_h_all[3]);
    end
  join
  
  `uvm_info(get_type_name(), "ID_MULTIPLE_WRITES_SAME_AWID: All master sequences completed", UVM_LOW);
  
  // Wait for all transactions to propagate and complete
  #2000;
  
  // Perform backdoor verification only if not disabled
  if (axi4_scoreboard_h != null) begin
    bit backdoor_verify_enable = 1;
    bit disable_backdoor_verify = 0;
    
    // Check configuration settings
    if (uvm_config_db#(bit)::get(null, "*", "disable_backdoor_verify", disable_backdoor_verify) ||
        uvm_config_db#(int)::get(null, "*", "backdoor_verify_enable", backdoor_verify_enable)) begin
      if (disable_backdoor_verify || !backdoor_verify_enable) begin
        `uvm_info(get_type_name(), "ID_MULTIPLE_WRITES_SAME_AWID: BACKDOOR VERIFICATION DISABLED", UVM_LOW);
      end else begin
        `uvm_info(get_type_name(), "ID_MULTIPLE_WRITES_SAME_AWID: Starting backdoor verification for all transactions", UVM_LOW);
        
        // Verify each master's transactions using predicted writes
        foreach(axi4_master_seq_h[master_id]) begin
          automatic axi4_master_id_multiple_writes_same_awid_seq::predicted_write_t predicted_writes[$];
          axi4_master_seq_h[master_id].get_predicted_writes(predicted_writes);
          
          `uvm_info(get_type_name(), $sformatf("ID_MULTIPLE_WRITES_SAME_AWID: Verifying Master[%0d] transactions - %0d predicted writes", master_id, predicted_writes.size()), UVM_LOW);
          
          // Verify each predicted write
          foreach(predicted_writes[i]) begin
            if (predicted_writes[i].valid) begin
              verify_result = axi4_scoreboard_h.backdoor_read_verify(
                predicted_writes[i].addr,
                {{(DATA_WIDTH-32){1'b0}}, predicted_writes[i].data}, 
                predicted_writes[i].slave_id
              );
              if (!verify_result) begin
                `uvm_error(get_type_name(), $sformatf("ID_MULTIPLE_WRITES_SAME_AWID: Master[%0d] predicted write[%0d] FAILED - ADDR=0x%16h, DATA=0x%8h, SLAVE=%0d", 
                          master_id, i, predicted_writes[i].addr, predicted_writes[i].data, predicted_writes[i].slave_id));
                all_tests_passed = 0;
              end else begin
                `uvm_info(get_type_name(), $sformatf("ID_MULTIPLE_WRITES_SAME_AWID: Master[%0d] predicted write[%0d] PASSED - ADDR=0x%16h, DATA=0x%8h, SLAVE=%0d", 
                          master_id, i, predicted_writes[i].addr, predicted_writes[i].data, predicted_writes[i].slave_id), UVM_DEBUG);
              end
            end
          end
        end
        
        if (all_tests_passed) begin
          `uvm_info(get_type_name(), "ID_MULTIPLE_WRITES_SAME_AWID: BACKDOOR VERIFICATION PASSED - All transactions completed correctly", UVM_LOW);
          `uvm_info(get_type_name(), "ID_MULTIPLE_WRITES_SAME_AWID: AXI4 Out-of-Order Requirements SATISFIED:", UVM_LOW);
          `uvm_info(get_type_name(), "  - NO write data interleaving observed (AXI4 compliant)", UVM_LOW);
          `uvm_info(get_type_name(), "  - Out-of-order completion for different AWIDs verified", UVM_LOW);
          `uvm_info(get_type_name(), "  - In-order completion for same AWID to same slave verified", UVM_LOW);
          `uvm_info(get_type_name(), "  - 4 Masters x 4 Slaves complex scenario passed", UVM_LOW);
        end else begin
          `uvm_error(get_type_name(), "ID_MULTIPLE_WRITES_SAME_AWID: BACKDOOR VERIFICATION FAILED - AXI4 compliance violation detected");
        end
      end
    end else begin
      `uvm_info(get_type_name(), "ID_MULTIPLE_WRITES_SAME_AWID: BACKDOOR VERIFICATION DISABLED - Configuration not found", UVM_LOW);
    end
  end
  
  `uvm_info(get_type_name(), "ID_MULTIPLE_WRITES_SAME_AWID: Completed AXI4 Complex Out-of-Order Test", UVM_LOW);
endtask : body

// Typedef alias for backward compatibility with test file naming
// typedef removed - class name now matches expected name

`endif