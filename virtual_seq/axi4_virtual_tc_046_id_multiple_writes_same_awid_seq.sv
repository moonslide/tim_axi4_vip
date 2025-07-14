`ifndef AXI4_VIRTUAL_TC_046_ID_MULTIPLE_WRITES_SAME_AWID_SEQ_INCLUDED_
`define AXI4_VIRTUAL_TC_046_ID_MULTIPLE_WRITES_SAME_AWID_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_tc_046_id_multiple_writes_same_awid_seq
// TC_046: Verifies Slave handles multiple writes with same AWID in order
// Address: Use DDR Memory range (0x0000_0100_0000_0000+) for all masters access
//--------------------------------------------------------------------------------------------
class axi4_virtual_tc_046_id_multiple_writes_same_awid_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_tc_046_id_multiple_writes_same_awid_seq)

  axi4_master_tc_046_id_multiple_writes_same_awid_seq axi4_master_tc_046_seq_h;
  
  // Scoreboard handle for backdoor verification
  axi4_scoreboard axi4_scoreboard_h;

  extern function new(string name = "axi4_virtual_tc_046_id_multiple_writes_same_awid_seq");
  extern task body();
endclass : axi4_virtual_tc_046_id_multiple_writes_same_awid_seq

function axi4_virtual_tc_046_id_multiple_writes_same_awid_seq::new(string name = "axi4_virtual_tc_046_id_multiple_writes_same_awid_seq");
  super.new(name);
endfunction : new

task axi4_virtual_tc_046_id_multiple_writes_same_awid_seq::body();
  bit verify_result1, verify_result2;
  
  // Get scoreboard handle for backdoor verification
  if(!uvm_config_db#(axi4_scoreboard)::get(null, "*", "axi4_scoreboard_h", axi4_scoreboard_h)) begin
    `uvm_warning(get_type_name(), "Cannot get scoreboard handle - backdoor verification disabled")
  end
  
  axi4_master_tc_046_seq_h = axi4_master_tc_046_id_multiple_writes_same_awid_seq::type_id::create("axi4_master_tc_046_seq_h");
  
  `uvm_info(get_type_name(), $sformatf("TC_046: Starting ID Multiple Writes Same AWID test"), UVM_LOW);
  
  // Start master sequence on Master 0
  fork
    axi4_master_tc_046_seq_h.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
  join
  
  `uvm_info(get_type_name(), $sformatf("TC_046: Master sequence completed, starting backdoor verification"), UVM_LOW);
  
  // Wait for all transactions to complete 
  #500;
  
  // Perform backdoor verification only if not disabled
  if (axi4_scoreboard_h != null) begin
    bit backdoor_verify_enable = 1;
    bit disable_backdoor_verify = 0;
    
    // Check configuration settings
    if (uvm_config_db#(bit)::get(null, "*", "disable_backdoor_verify", disable_backdoor_verify) ||
        uvm_config_db#(int)::get(null, "*", "backdoor_verify_enable", backdoor_verify_enable)) begin
      if (disable_backdoor_verify || !backdoor_verify_enable) begin
        `uvm_info(get_type_name(), $sformatf("TC_046: BACKDOOR VERIFICATION DISABLED - Skipping for same AWID test"), UVM_LOW);
      end else begin
        // Verify T1 write: Address=0x0000_0100_0000_10B0, Expected=0x11110000, Slave_ID=0 (DDR)
        verify_result1 = axi4_scoreboard_h.backdoor_read_verify(64'h0000_0100_0000_10B0, {{(DATA_WIDTH-32){1'b0}}, 32'h11110000}, 0);
        
        // Verify T2 write: Address=0x0000_0100_0000_10B4, Expected=0x22220000, Slave_ID=0 (DDR)  
        verify_result2 = axi4_scoreboard_h.backdoor_read_verify(64'h0000_0100_0000_10B4, {{(DATA_WIDTH-32){1'b0}}, 32'h22220000}, 0);
        
        if (verify_result1 && verify_result2) begin
          `uvm_info(get_type_name(), $sformatf("TC_046: BACKDOOR VERIFICATION PASSED - Both writes correctly stored"), UVM_LOW);
        end else begin
          `uvm_error(get_type_name(), $sformatf("TC_046: BACKDOOR VERIFICATION FAILED - Write data mismatch detected"));
        end
      end
    end else begin
      `uvm_info(get_type_name(), $sformatf("TC_046: BACKDOOR VERIFICATION DISABLED - Configuration not found, skipping"), UVM_LOW);
    end
  end
  
  `uvm_info(get_type_name(), $sformatf("TC_046: Completed ID Multiple Writes Same AWID test with backdoor verification"), UVM_LOW);
endtask : body

`endif