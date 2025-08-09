`ifndef AXI4_VIRTUAL_USER_PARITY_PROTECTION_SEQ_INCLUDED_
`define AXI4_VIRTUAL_USER_PARITY_PROTECTION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_user_parity_protection_seq
// Virtual sequence to test USER signal parity protection mechanisms
// Demonstrates error detection capabilities using parity bits
//--------------------------------------------------------------------------------------------
class axi4_virtual_user_parity_protection_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_user_parity_protection_seq)

  // Master sequences for parity testing
  axi4_master_user_parity_seq parity_seq_good_h;
  axi4_master_user_parity_seq parity_seq_error_h;
  axi4_master_user_parity_seq parity_seq_mixed_h[4];
  
  // Standard sequences for comparison
  axi4_master_qos_priority_write_seq standard_write_seq_h;

  // Slave sequences
  axi4_slave_nbk_write_seq axi4_slave_write_seq_h;
  axi4_slave_nbk_read_seq axi4_slave_read_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_user_parity_protection_seq");
  extern task body();

endclass : axi4_virtual_user_parity_protection_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the object
//
// Parameters:
//  name - axi4_virtual_user_parity_protection_seq
//--------------------------------------------------------------------------------------------
function axi4_virtual_user_parity_protection_seq::new(string name = "axi4_virtual_user_parity_protection_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates and starts sequences to test USER parity protection
//--------------------------------------------------------------------------------------------
task axi4_virtual_user_parity_protection_seq::body();
  
  `uvm_info(get_type_name(), "Starting USER Parity Protection Virtual Sequence", UVM_LOW)
  
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
  
  // Test Scenario 1: Good parity - No errors
  `uvm_info(get_type_name(), "==== Scenario 1: Good Parity - All transactions with valid parity ====", UVM_LOW)
  
  for(int i = 0; i < 5; i++) begin
    parity_seq_good_h = axi4_master_user_parity_seq::type_id::create($sformatf("parity_seq_good_%0d", i));
    parity_seq_good_h.parity_enable = 1;
    parity_seq_good_h.inject_error = 0;
    parity_seq_good_h.user_data_payload = $urandom();
    
    `uvm_info(get_type_name(), $sformatf("  Transaction %0d: Data=0x%06h with valid parity", 
              i, parity_seq_good_h.user_data_payload), UVM_LOW)
    
    parity_seq_good_h.start(p_sequencer.axi4_master_write_seqr_h);
    #100ns;
  end
  
  #200ns;
  
  // Test Scenario 2: Single bit errors
  `uvm_info(get_type_name(), "==== Scenario 2: Single Bit Errors - Testing error detection ====", UVM_LOW)
  
  for(int i = 0; i < 4; i++) begin
    parity_seq_error_h = axi4_master_user_parity_seq::type_id::create($sformatf("parity_seq_single_error_%0d", i));
    parity_seq_error_h.parity_enable = 1;
    parity_seq_error_h.inject_error = 1;
    parity_seq_error_h.error_type = 1; // Single bit error
    parity_seq_error_h.error_bit_position = $urandom_range(0, 23);
    parity_seq_error_h.user_data_payload = $urandom();
    
    `uvm_info(get_type_name(), $sformatf("  Transaction %0d: Data=0x%06h with single bit error at position %0d", 
              i, parity_seq_error_h.user_data_payload, parity_seq_error_h.error_bit_position), UVM_LOW)
    
    parity_seq_error_h.start(p_sequencer.axi4_master_write_seqr_h);
    #100ns;
  end
  
  #200ns;
  
  // Test Scenario 3: Double bit errors
  `uvm_info(get_type_name(), "==== Scenario 3: Double Bit Errors - Testing multi-bit error detection ====", UVM_LOW)
  
  for(int i = 0; i < 3; i++) begin
    parity_seq_error_h = axi4_master_user_parity_seq::type_id::create($sformatf("parity_seq_double_error_%0d", i));
    parity_seq_error_h.parity_enable = 1;
    parity_seq_error_h.inject_error = 1;
    parity_seq_error_h.error_type = 2; // Double bit error
    parity_seq_error_h.error_bit_position = $urandom_range(0, 16);
    parity_seq_error_h.user_data_payload = $urandom();
    
    `uvm_info(get_type_name(), $sformatf("  Transaction %0d: Data=0x%06h with double bit error starting at position %0d", 
              i, parity_seq_error_h.user_data_payload, parity_seq_error_h.error_bit_position), UVM_LOW)
    
    parity_seq_error_h.start(p_sequencer.axi4_master_write_seqr_h);
    #100ns;
  end
  
  #200ns;
  
  // Test Scenario 4: Burst errors
  `uvm_info(get_type_name(), "==== Scenario 4: Burst Errors - Testing burst error detection ====", UVM_LOW)
  
  for(int i = 0; i < 2; i++) begin
    parity_seq_error_h = axi4_master_user_parity_seq::type_id::create($sformatf("parity_seq_burst_error_%0d", i));
    parity_seq_error_h.parity_enable = 1;
    parity_seq_error_h.inject_error = 1;
    parity_seq_error_h.error_type = 3; // Burst error
    parity_seq_error_h.error_bit_position = $urandom_range(0, 20);
    parity_seq_error_h.user_data_payload = $urandom();
    
    `uvm_info(get_type_name(), $sformatf("  Transaction %0d: Data=0x%06h with burst error starting at position %0d", 
              i, parity_seq_error_h.user_data_payload, parity_seq_error_h.error_bit_position), UVM_LOW)
    
    parity_seq_error_h.start(p_sequencer.axi4_master_write_seqr_h);
    #100ns;
  end
  
  #200ns;
  
  // Test Scenario 5: Mixed traffic with and without parity
  `uvm_info(get_type_name(), "==== Scenario 5: Mixed Traffic - Parity enabled and disabled ====", UVM_LOW)
  
  fork
    begin
      for(int i = 0; i < 4; i++) begin
        parity_seq_mixed_h[i] = axi4_master_user_parity_seq::type_id::create($sformatf("parity_seq_mixed_%0d", i));
        parity_seq_mixed_h[i].parity_enable = (i % 2); // Alternate enable/disable
        parity_seq_mixed_h[i].inject_error = 0;
        parity_seq_mixed_h[i].user_data_payload = $urandom();
        
        `uvm_info(get_type_name(), $sformatf("  Transaction %0d: Data=0x%06h, Parity %s", 
                  i, parity_seq_mixed_h[i].user_data_payload, 
                  parity_seq_mixed_h[i].parity_enable ? "ENABLED" : "DISABLED"), UVM_LOW)
        
        parity_seq_mixed_h[i].start(p_sequencer.axi4_master_write_seqr_h);
        #50ns;
      end
    end
  join
  
  #300ns;
  
  // Test Scenario 6: Standard transaction for comparison
  `uvm_info(get_type_name(), "==== Scenario 6: Standard Transaction - No USER parity ====", UVM_LOW)
  
  standard_write_seq_h = axi4_master_qos_priority_write_seq::type_id::create("standard_write_seq_h");
  standard_write_seq_h.qos_value = 4'h4;
  standard_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
  
  #200ns;
  
  // Test Scenario 7: Stress test with rapid transactions
  `uvm_info(get_type_name(), "==== Scenario 7: Stress Test - Rapid parity-protected transactions ====", UVM_LOW)
  
  fork
    begin
      for(int i = 0; i < 10; i++) begin
        parity_seq_good_h = axi4_master_user_parity_seq::type_id::create($sformatf("stress_seq_%0d", i));
        parity_seq_good_h.parity_enable = 1;
        parity_seq_good_h.inject_error = ($urandom_range(0, 100) < 20); // 20% error rate
        parity_seq_good_h.error_type = $urandom_range(0, 3);
        parity_seq_good_h.user_data_payload = $urandom();
        parity_seq_good_h.start(p_sequencer.axi4_master_write_seqr_h);
        #20ns;
      end
    end
  join
  
  // Wait for all transactions to complete
  #1000ns;
  
  `uvm_info(get_type_name(), "Completed USER Parity Protection Virtual Sequence", UVM_LOW)
  `uvm_info(get_type_name(), "Test Summary:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Demonstrated parity generation and checking", UVM_LOW)
  `uvm_info(get_type_name(), "  - Tested single-bit error detection", UVM_LOW)
  `uvm_info(get_type_name(), "  - Tested double-bit error detection", UVM_LOW)
  `uvm_info(get_type_name(), "  - Tested burst error detection", UVM_LOW)
  `uvm_info(get_type_name(), "  - Verified mixed parity-enabled/disabled traffic", UVM_LOW)
  `uvm_info(get_type_name(), "  - Parity protection levels: Nibble, Byte, and Overall", UVM_LOW)
  
endtask : body

`endif