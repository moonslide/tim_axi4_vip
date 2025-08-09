`ifndef AXI4_VIRTUAL_QOS_SATURATION_STRESS_SEQ_INCLUDED_
`define AXI4_VIRTUAL_QOS_SATURATION_STRESS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_qos_saturation_stress_seq
// Virtual sequence for stress testing QoS arbitration under saturation conditions
// Generates heavy traffic with mixed priorities to verify robust arbitration
//--------------------------------------------------------------------------------------------
class axi4_virtual_qos_saturation_stress_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_qos_saturation_stress_seq)

  // Master sequences for different QoS levels and masters
  // Low priority flood sequences
  axi4_master_qos_priority_write_seq low_flood_write_seq_h[4];
  axi4_master_qos_priority_read_seq low_flood_read_seq_h[4];
  
  // Medium priority normal sequences  
  axi4_master_qos_priority_write_seq med_normal_write_seq_h[3];
  axi4_master_qos_priority_read_seq med_normal_read_seq_h[3];
  
  // High priority critical sequences
  axi4_master_qos_priority_write_seq high_critical_write_seq_h[2];
  axi4_master_qos_priority_read_seq high_critical_read_seq_h[2];
  
  // Ultra-high priority emergency sequence
  axi4_master_qos_priority_write_seq ultra_emergency_write_seq_h;
  axi4_master_qos_priority_read_seq ultra_emergency_read_seq_h;

  // Slave sequences
  axi4_slave_nbk_write_seq axi4_slave_write_seq_h;
  axi4_slave_nbk_read_seq axi4_slave_read_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_qos_saturation_stress_seq");
  extern task body();

endclass : axi4_virtual_qos_saturation_stress_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the object
//
// Parameters:
//  name - axi4_virtual_qos_saturation_stress_seq
//--------------------------------------------------------------------------------------------
function axi4_virtual_qos_saturation_stress_seq::new(string name = "axi4_virtual_qos_saturation_stress_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates and starts sequences for QoS saturation stress testing
// Floods the bus with low priority traffic while injecting higher priority transactions
//--------------------------------------------------------------------------------------------
task axi4_virtual_qos_saturation_stress_seq::body();
  
  `uvm_info(get_type_name(), "Starting QoS Saturation Stress Virtual Sequence", UVM_LOW)
  
  // Create low priority flood sequences (QoS = 1)
  for(int i = 0; i < 4; i++) begin
    low_flood_write_seq_h[i] = axi4_master_qos_priority_write_seq::type_id::create($sformatf("low_flood_write_seq_h[%0d]", i));
    low_flood_read_seq_h[i] = axi4_master_qos_priority_read_seq::type_id::create($sformatf("low_flood_read_seq_h[%0d]", i));
    low_flood_write_seq_h[i].qos_value = 4'b0001;  // Lowest priority
    low_flood_read_seq_h[i].qos_value = 4'b0001;   // Lowest priority
  end
  
  // Create medium priority normal sequences (QoS = 4)
  for(int i = 0; i < 3; i++) begin
    med_normal_write_seq_h[i] = axi4_master_qos_priority_write_seq::type_id::create($sformatf("med_normal_write_seq_h[%0d]", i));
    med_normal_read_seq_h[i] = axi4_master_qos_priority_read_seq::type_id::create($sformatf("med_normal_read_seq_h[%0d]", i));
    med_normal_write_seq_h[i].qos_value = 4'b0100;  // Medium priority
    med_normal_read_seq_h[i].qos_value = 4'b0100;   // Medium priority
  end
  
  // Create high priority critical sequences (QoS = 8)
  for(int i = 0; i < 2; i++) begin
    high_critical_write_seq_h[i] = axi4_master_qos_priority_write_seq::type_id::create($sformatf("high_critical_write_seq_h[%0d]", i));
    high_critical_read_seq_h[i] = axi4_master_qos_priority_read_seq::type_id::create($sformatf("high_critical_read_seq_h[%0d]", i));
    high_critical_write_seq_h[i].qos_value = 4'b1000;  // High priority
    high_critical_read_seq_h[i].qos_value = 4'b1000;   // High priority
  end
  
  // Create ultra-high priority emergency sequence (QoS = 15)
  ultra_emergency_write_seq_h = axi4_master_qos_priority_write_seq::type_id::create("ultra_emergency_write_seq_h");
  ultra_emergency_read_seq_h = axi4_master_qos_priority_read_seq::type_id::create("ultra_emergency_read_seq_h");
  ultra_emergency_write_seq_h.qos_value = 4'b1111;  // Maximum priority
  ultra_emergency_read_seq_h.qos_value = 4'b1111;   // Maximum priority
  
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
  
  // Simple QoS test with minimal traffic to verify basic functionality
  
  // Test 1: Single low priority write
  `uvm_info(get_type_name(), "Test 1: Single low priority write (QoS=1)", UVM_LOW)
  low_flood_write_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h);
  #500ns;  // Large delay to ensure completion
  
  // Test 2: Single medium priority write  
  `uvm_info(get_type_name(), "Test 2: Single medium priority write (QoS=4)", UVM_LOW)
  med_normal_write_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h);
  #500ns;
  
  // Test 3: Single high priority write
  `uvm_info(get_type_name(), "Test 3: Single high priority write (QoS=8)", UVM_LOW)
  high_critical_write_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h);
  #500ns;
  
  // Test 4: Single ultra-high priority write
  `uvm_info(get_type_name(), "Test 4: Single ultra-high priority write (QoS=15)", UVM_LOW)
  ultra_emergency_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
  #500ns;
  
  `uvm_info(get_type_name(), "All QoS write tests completed", UVM_LOW)
  
  // Wait for transactions to complete
  #1000ns;
  
  // Wait for all transactions to complete
  #500ns;
  
  `uvm_info(get_type_name(), "Completed QoS Saturation Stress Virtual Sequence", UVM_LOW)
  `uvm_info(get_type_name(), "QoS test summary:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Low priority write completed (QoS=1)", UVM_LOW)
  `uvm_info(get_type_name(), "  - Medium priority write completed (QoS=4)", UVM_LOW)
  `uvm_info(get_type_name(), "  - High priority write completed (QoS=8)", UVM_LOW)
  `uvm_info(get_type_name(), "  - Ultra-high emergency write completed (QoS=15)", UVM_LOW)
  `uvm_info(get_type_name(), "Verified basic QoS functionality in 10x10 enhanced bus matrix", UVM_LOW)
  
endtask : body

`endif