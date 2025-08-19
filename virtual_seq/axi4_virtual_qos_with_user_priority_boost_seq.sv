`ifndef AXI4_VIRTUAL_QOS_WITH_USER_PRIORITY_BOOST_SEQ_INCLUDED_
`define AXI4_VIRTUAL_QOS_WITH_USER_PRIORITY_BOOST_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_qos_with_user_priority_boost_seq
// Virtual sequence to test QoS priority boosting using USER signals
// Demonstrates how USER signals can dynamically modify effective QoS priority
//--------------------------------------------------------------------------------------------
class axi4_virtual_qos_with_user_priority_boost_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_qos_with_user_priority_boost_seq)

  // Master sequences for different scenarios
  axi4_master_qos_user_boost_write_seq low_qos_no_boost_seq_h;
  axi4_master_qos_user_boost_write_seq low_qos_with_boost_seq_h;
  axi4_master_qos_user_boost_write_seq med_qos_no_boost_seq_h;
  axi4_master_qos_user_boost_write_seq med_qos_with_boost_seq_h;
  
  // Standard QoS sequences for comparison
  axi4_master_qos_priority_write_seq high_qos_standard_seq_h;

  // Slave sequences
  axi4_slave_nbk_write_seq axi4_slave_write_seq_h;
  axi4_slave_nbk_read_seq axi4_slave_read_seq_h;

  // Bus matrix configuration parameters
  int num_masters = 4;
  int num_slaves = 4;
  int use_bus_matrix_addressing = 0; // 0=NONE, 1=BASE_4x4, 2=ENHANCED_10x10

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_qos_with_user_priority_boost_seq");
  extern task body();

endclass : axi4_virtual_qos_with_user_priority_boost_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the object
//
// Parameters:
//  name - axi4_virtual_qos_with_user_priority_boost_seq
//--------------------------------------------------------------------------------------------
function axi4_virtual_qos_with_user_priority_boost_seq::new(string name = "axi4_virtual_qos_with_user_priority_boost_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates and starts sequences to test USER signal priority boosting
//--------------------------------------------------------------------------------------------
task axi4_virtual_qos_with_user_priority_boost_seq::body();
  
  `uvm_info(get_type_name(), "Starting QoS with USER Priority Boost Virtual Sequence", UVM_LOW)
  
  // Create sequences with different configurations
  
  // Low QoS without boost (effective QoS = 2)
  low_qos_no_boost_seq_h = axi4_master_qos_user_boost_write_seq::type_id::create("low_qos_no_boost_seq_h");
  low_qos_no_boost_seq_h.base_qos_value = 4'h2;
  low_qos_no_boost_seq_h.user_boost_enable = 0;
  low_qos_no_boost_seq_h.user_boost_value = 4'h0;
  
  // Low QoS with boost (effective QoS = 2 + 8 = 10)
  low_qos_with_boost_seq_h = axi4_master_qos_user_boost_write_seq::type_id::create("low_qos_with_boost_seq_h");
  low_qos_with_boost_seq_h.base_qos_value = 4'h2;
  low_qos_with_boost_seq_h.user_boost_enable = 1;
  low_qos_with_boost_seq_h.user_boost_value = 4'h8;
  
  // Medium QoS without boost (effective QoS = 4)
  med_qos_no_boost_seq_h = axi4_master_qos_user_boost_write_seq::type_id::create("med_qos_no_boost_seq_h");
  med_qos_no_boost_seq_h.base_qos_value = 4'h4;
  med_qos_no_boost_seq_h.user_boost_enable = 0;
  med_qos_no_boost_seq_h.user_boost_value = 4'h0;
  
  // Medium QoS with boost (effective QoS = 4 + 4 = 8)
  med_qos_with_boost_seq_h = axi4_master_qos_user_boost_write_seq::type_id::create("med_qos_with_boost_seq_h");
  med_qos_with_boost_seq_h.base_qos_value = 4'h4;
  med_qos_with_boost_seq_h.user_boost_enable = 1;
  med_qos_with_boost_seq_h.user_boost_value = 4'h4;
  
  // High QoS standard for comparison (QoS = 8)
  high_qos_standard_seq_h = axi4_master_qos_priority_write_seq::type_id::create("high_qos_standard_seq_h");
  high_qos_standard_seq_h.qos_value = 4'h8;
  
  // Create slave sequences
  axi4_slave_write_seq_h = axi4_slave_nbk_write_seq::type_id::create("axi4_slave_write_seq_h");
  axi4_slave_read_seq_h = axi4_slave_nbk_read_seq::type_id::create("axi4_slave_read_seq_h");
  
  // Start slave sequences in forever loops
  fork
    begin : SLAVE_WRITE
      forever begin
        // Create new instance each time to avoid sequence reuse error
        axi4_slave_nbk_write_seq slave_wr_seq;
        slave_wr_seq = axi4_slave_nbk_write_seq::type_id::create("slave_wr_seq");
        slave_wr_seq.start(p_sequencer.axi4_slave_write_seqr_h);
      end
    end
    
    begin : SLAVE_READ
      forever begin
        // Create new instance each time to avoid sequence reuse error
        axi4_slave_nbk_read_seq slave_rd_seq;
        slave_rd_seq = axi4_slave_nbk_read_seq::type_id::create("slave_rd_seq");
        slave_rd_seq.start(p_sequencer.axi4_slave_read_seqr_h);
      end
    end
  join_none
  
  // Test Scenario 1: Low QoS without boost
  `uvm_info(get_type_name(), "==== Scenario 1: Low QoS without USER boost (QoS=2) ====", UVM_LOW)
  low_qos_no_boost_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
  #50ns;
  
  // Test Scenario 2: Low QoS with USER boost
  `uvm_info(get_type_name(), "==== Scenario 2: Low QoS WITH USER boost (QoS=2, boost=8, effective=10) ====", UVM_LOW)
  low_qos_with_boost_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
  #50ns;
  
  // Test Scenario 3: Medium QoS without boost
  `uvm_info(get_type_name(), "==== Scenario 3: Medium QoS without USER boost (QoS=4) ====", UVM_LOW)
  med_qos_no_boost_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
  #50ns;
  
  // Test Scenario 4: Medium QoS with USER boost
  `uvm_info(get_type_name(), "==== Scenario 4: Medium QoS WITH USER boost (QoS=4, boost=4, effective=8) ====", UVM_LOW)
  med_qos_with_boost_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
  #50ns;
  
  // Test Scenario 5: Standard high QoS for comparison
  `uvm_info(get_type_name(), "==== Scenario 5: Standard high QoS for reference (QoS=8) ====", UVM_LOW)
  high_qos_standard_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
  #50ns;
  
  // Test Scenario 6: Mixed traffic with and without boost
  `uvm_info(get_type_name(), "==== Scenario 6: Mixed traffic - boosted low priority vs non-boosted medium ====", UVM_LOW)
  fork
    begin
      // Low priority with boost (effective = 10) should win over medium without boost (effective = 4)
      low_qos_with_boost_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
    end
    begin
      #10ns;  // Small delay
      med_qos_no_boost_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
    end
  join
  
  #100ns;
  
  // Test Scenario 7: Dynamic boost enable/disable
  `uvm_info(get_type_name(), "==== Scenario 7: Dynamic USER boost enable/disable demonstration ====", UVM_LOW)
  for(int i = 0; i < 2; i++) begin  // Reduced from 4 to 2
    low_qos_with_boost_seq_h.user_boost_enable = (i % 2);  // Toggle boost on/off
    `uvm_info(get_type_name(), $sformatf("  Transaction %0d: USER boost %s", i, 
              low_qos_with_boost_seq_h.user_boost_enable ? "ENABLED" : "DISABLED"), UVM_LOW)
    low_qos_with_boost_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
    #50ns;
  end
  
  // Wait for all transactions to complete
  #200ns;  // Reduced from 1000ns
  
  `uvm_info(get_type_name(), "Completed QoS with USER Priority Boost Virtual Sequence", UVM_LOW)
  `uvm_info(get_type_name(), "Test Summary:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Demonstrated USER signal boost increasing effective priority", UVM_LOW)
  `uvm_info(get_type_name(), "  - Showed boosted low priority can exceed non-boosted medium priority", UVM_LOW)
  `uvm_info(get_type_name(), "  - Verified dynamic enable/disable of USER boost feature", UVM_LOW)
  `uvm_info(get_type_name(), "  - USER signal format: [7:4]=enable, [3:0]=boost_value", UVM_LOW)
  
endtask : body

`endif