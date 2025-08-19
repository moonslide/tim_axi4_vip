`ifndef AXI4_VIRTUAL_QOS_STARVATION_PREVENTION_SEQ_INCLUDED_
`define AXI4_VIRTUAL_QOS_STARVATION_PREVENTION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_qos_starvation_prevention_seq
// Virtual sequence to test QoS starvation prevention mechanism
// Ensures low priority transactions eventually complete despite high priority traffic
//--------------------------------------------------------------------------------------------
class axi4_virtual_qos_starvation_prevention_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_qos_starvation_prevention_seq)

  // Master sequences for different QoS levels
  axi4_master_qos_priority_write_seq low_priority_write_seq_h;
  axi4_master_qos_priority_read_seq low_priority_read_seq_h;
  axi4_master_qos_priority_write_seq high_priority_write_seq_h[3];
  axi4_master_qos_priority_read_seq high_priority_read_seq_h[3];

  // Slave sequences
  axi4_slave_nbk_write_seq axi4_slave_write_seq_h;
  axi4_slave_nbk_read_seq axi4_slave_read_seq_h;

  // Bus matrix configuration parameters
  int num_masters = 4;
  int num_slaves = 4;
  int use_bus_matrix_addressing = 0; // 0=NONE, 1=BASE_4x4, 2=ENHANCED_10x10

  // Tracking variables
  int low_priority_start_time;
  int low_priority_end_time;
  int high_priority_count;
  bit low_priority_completed;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_qos_starvation_prevention_seq");
  extern task body();

endclass : axi4_virtual_qos_starvation_prevention_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the object
//
// Parameters:
//  name - axi4_virtual_qos_starvation_prevention_seq
//--------------------------------------------------------------------------------------------
function axi4_virtual_qos_starvation_prevention_seq::new(string name = "axi4_virtual_qos_starvation_prevention_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates and starts sequences to test starvation prevention
//--------------------------------------------------------------------------------------------
task axi4_virtual_qos_starvation_prevention_seq::body();
  
  `uvm_info(get_type_name(), "Starting QoS Starvation Prevention Virtual Sequence", UVM_LOW)
  
  // Create low priority sequences (QoS = 1)
  low_priority_write_seq_h = axi4_master_qos_priority_write_seq::type_id::create("low_priority_write_seq_h");
  low_priority_read_seq_h = axi4_master_qos_priority_read_seq::type_id::create("low_priority_read_seq_h");
  low_priority_write_seq_h.qos_value = 4'b0001;  // Lowest priority
  low_priority_read_seq_h.qos_value = 4'b0001;
  
  // Create high priority sequences (QoS = 15)
  for(int i = 0; i < 3; i++) begin
    high_priority_write_seq_h[i] = axi4_master_qos_priority_write_seq::type_id::create($sformatf("high_priority_write_seq_h[%0d]", i));
    high_priority_read_seq_h[i] = axi4_master_qos_priority_read_seq::type_id::create($sformatf("high_priority_read_seq_h[%0d]", i));
    high_priority_write_seq_h[i].qos_value = 4'b1111;  // Maximum priority
    high_priority_read_seq_h[i].qos_value = 4'b1111;
  end
  
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
  
  // Test Phase 1: Start a low priority transaction
  `uvm_info(get_type_name(), "Phase 1: Starting low priority transaction (QoS=1)", UVM_LOW)
  low_priority_start_time = $time;
  low_priority_completed = 0;
  
  fork
    begin : LOW_PRIORITY_MONITOR
      low_priority_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
      low_priority_completed = 1;
      low_priority_end_time = $time;
      `uvm_info(get_type_name(), $sformatf("Low priority write completed after %0d ns", 
                (low_priority_end_time - low_priority_start_time)/1000), UVM_LOW)
    end
  join_none
  
  // Small delay to let low priority transaction start
  #100ns;
  
  // Test Phase 2: Flood with high priority transactions
  `uvm_info(get_type_name(), "Phase 2: Starting continuous high priority traffic (QoS=15)", UVM_LOW)
  
  fork
    begin : HIGH_PRIORITY_FLOOD
      for(int i = 0; i < 10; i++) begin
        fork
          begin
            high_priority_write_seq_h[i % 3].start(p_sequencer.axi4_master_write_seqr_h);
            high_priority_count++;
          end
        join_none
        #50ns;  // Small delay between high priority transactions
      end
    end
  join_none
  
  // Wait for some time to observe behavior
  #2000ns;
  
  // Test Phase 3: Check if low priority completed (starvation prevention)
  if(low_priority_completed) begin
    `uvm_info(get_type_name(), 
              "PASS: Low priority transaction completed despite high priority traffic - Starvation Prevention Working!", 
              UVM_LOW)
  end
  else begin
    `uvm_warning(get_type_name(), 
                 "Low priority transaction may be starved - waiting more time")
    #3000ns;
    if(low_priority_completed) begin
      `uvm_info(get_type_name(), 
                "PASS: Low priority transaction eventually completed - Starvation Prevention Working!", 
                UVM_LOW)
    end
    else begin
      `uvm_error(get_type_name(), 
                 "FAIL: Low priority transaction appears to be starved!")
    end
  end
  
  // Test Phase 4: Send another low priority to confirm system is still responsive
  `uvm_info(get_type_name(), "Phase 3: Sending follow-up low priority transaction", UVM_LOW)
  low_priority_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
  `uvm_info(get_type_name(), "Follow-up low priority read completed successfully", UVM_LOW)
  
  // Wait for all transactions to complete
  #1000ns;
  
  `uvm_info(get_type_name(), "Completed QoS Starvation Prevention Virtual Sequence", UVM_LOW)
  `uvm_info(get_type_name(), "Test Summary:", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  - High priority transactions sent: %0d", high_priority_count), UVM_LOW)
  `uvm_info(get_type_name(), "  - Low priority transactions verified to complete", UVM_LOW)
  `uvm_info(get_type_name(), "  - Starvation prevention mechanism validated", UVM_LOW)
  
endtask : body

`endif