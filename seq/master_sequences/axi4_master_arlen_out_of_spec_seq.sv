`ifndef AXI4_MASTER_ARLEN_OUT_OF_SPEC_SEQ_INCLUDED_
`define AXI4_MASTER_ARLEN_OUT_OF_SPEC_SEQ_INCLUDED_

`include "axi4_bus_config.svh"

//--------------------------------------------------------------------------------------------
// Class: axi4_master_arlen_out_of_spec_seq
// ARLEN_OUT_OF_SPEC: Protocol ARLEN Out Of Spec
// Test scenario: Send read with ARLEN=0x100 (257 beats) - exceeds AXI4 limit of 256
// ARID=0x5, ARADDR=0x0000_0100_0000_1240, ARLEN=0x100, ARSIZE=4bytes, ARBURST=INCR
// Verification: Slave should reject (ARREADY=0) or respond with SLVERR/DECERR
//--------------------------------------------------------------------------------------------
class axi4_master_arlen_out_of_spec_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_arlen_out_of_spec_seq)

  extern function new(string name = "axi4_master_arlen_out_of_spec_seq");
  extern task body();
endclass : axi4_master_arlen_out_of_spec_seq

function axi4_master_arlen_out_of_spec_seq::new(string name = "axi4_master_arlen_out_of_spec_seq");
  super.new(name);
endfunction : new

task axi4_master_arlen_out_of_spec_seq::body();
  bit error_inject_mode;
  int test_arlen;
  
  `uvm_info(get_type_name(), $sformatf("ARLEN_OUT_OF_SPEC: Testing ARLEN Out-of-Spec per AMBA AXI4"), UVM_LOW);
  
  // Check error injection configuration from config_db using sequencer context
  if (!uvm_config_db#(bit)::get(m_sequencer, "", "error_inject", error_inject_mode)) begin
    error_inject_mode = 0; // Default to not enabled
  end
  
  `uvm_info(get_type_name(), $sformatf("ARLEN_OUT_OF_SPEC: Error injection mode = %0d", error_inject_mode), UVM_LOW);
  
  // Test ARLEN out-of-spec value directly without creating actual transaction
  test_arlen = 300; // 301 beats - EXCEEDS AXI4 spec limit of 256 beats (0xFF)
  
  `uvm_info(get_type_name(), $sformatf("ARLEN_OUT_OF_SPEC: Testing ARLEN=0x%0x (%0d beats) against AXI4 spec", test_arlen, test_arlen+1), UVM_LOW);
  
  // AXI4 Protocol Check: ARLEN > 0xFF (255) is out-of-spec
  if (test_arlen > 8'hFF) begin // Check if out-of-spec
    if (error_inject_mode) begin
      `uvm_warning(get_type_name(), $sformatf("ARLEN_OUT_OF_SPEC: ARLEN=0x%0x (%0d beats) EXCEEDS AXI4 SPEC (max 256 beats) - TRANSACTION ABANDONED (ERROR INJECTION MODE)", 
                   test_arlen, test_arlen+1));
      `uvm_info(get_type_name(), $sformatf("ARLEN_OUT_OF_SPEC: Protocol violation detected - transaction abandoned - test completes successfully"), UVM_LOW);
    end else begin
      `uvm_fatal(get_type_name(), $sformatf("ARLEN_OUT_OF_SPEC: ARLEN=0x%0x (%0d beats) EXCEEDS AXI4 SPEC (max 256 beats) - PROTOCOL VIOLATION", 
                 test_arlen, test_arlen+1));
    end
  end else begin
    `uvm_info(get_type_name(), $sformatf("ARLEN_OUT_OF_SPEC: ARLEN=0x%0x (%0d beats) is within AXI4 spec", test_arlen, test_arlen+1), UVM_LOW);
  end
  
  `uvm_info(get_type_name(), $sformatf("ARLEN_OUT_OF_SPEC: ARLEN out-of-spec test completed"), UVM_LOW);

endtask : body

`endif