`ifndef AXI4_VIRTUAL_QOS_BASIC_PRIORITY_SEQ_INCLUDED_
`define AXI4_VIRTUAL_QOS_BASIC_PRIORITY_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_qos_basic_priority_seq
// Virtual sequence for testing basic QoS priority ordering
// Generates transactions with different QoS values and verifies priority-based arbitration
//--------------------------------------------------------------------------------------------
class axi4_virtual_qos_basic_priority_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_qos_basic_priority_seq)

  // Master sequences for different QoS levels
  axi4_master_qos_priority_write_seq low_qos_write_seq_h;
  axi4_master_qos_priority_write_seq med_qos_write_seq_h;
  axi4_master_qos_priority_write_seq high_qos_write_seq_h;
  
  axi4_master_qos_priority_read_seq low_qos_read_seq_h;
  axi4_master_qos_priority_read_seq med_qos_read_seq_h;
  axi4_master_qos_priority_read_seq high_qos_read_seq_h;

  // Slave sequences
  axi4_slave_nbk_write_seq axi4_slave_write_seq_h;
  axi4_slave_nbk_read_seq axi4_slave_read_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_qos_basic_priority_seq");
  extern task body();

endclass : axi4_virtual_qos_basic_priority_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the object
//
// Parameters:
//  name - axi4_virtual_qos_basic_priority_seq
//--------------------------------------------------------------------------------------------
function axi4_virtual_qos_basic_priority_seq::new(string name = "axi4_virtual_qos_basic_priority_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates and starts the sequences for QoS priority testing
//--------------------------------------------------------------------------------------------
task axi4_virtual_qos_basic_priority_seq::body();
  
  `uvm_info(get_type_name(), "Starting QoS Basic Priority Virtual Sequence", UVM_LOW)
  
  // Create sequences for different QoS levels
  low_qos_write_seq_h = axi4_master_qos_priority_write_seq::type_id::create("low_qos_write_seq_h");
  med_qos_write_seq_h = axi4_master_qos_priority_write_seq::type_id::create("med_qos_write_seq_h");
  high_qos_write_seq_h = axi4_master_qos_priority_write_seq::type_id::create("high_qos_write_seq_h");
  
  low_qos_read_seq_h = axi4_master_qos_priority_read_seq::type_id::create("low_qos_read_seq_h");
  med_qos_read_seq_h = axi4_master_qos_priority_read_seq::type_id::create("med_qos_read_seq_h");
  high_qos_read_seq_h = axi4_master_qos_priority_read_seq::type_id::create("high_qos_read_seq_h");
  
  // Create slave sequences
  axi4_slave_write_seq_h = axi4_slave_nbk_write_seq::type_id::create("axi4_slave_write_seq_h");
  axi4_slave_read_seq_h = axi4_slave_nbk_read_seq::type_id::create("axi4_slave_read_seq_h");
  
  // Configure QoS values for each sequence
  low_qos_write_seq_h.qos_value = 4'b0001;  // Low priority
  med_qos_write_seq_h.qos_value = 4'b0100;  // Medium priority  
  high_qos_write_seq_h.qos_value = 4'b1000; // High priority
  
  low_qos_read_seq_h.qos_value = 4'b0001;   // Low priority
  med_qos_read_seq_h.qos_value = 4'b0100;   // Medium priority
  high_qos_read_seq_h.qos_value = 4'b1000;  // High priority
  
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
  
  // Generate transactions with different priorities
  // The expectation is that high priority transactions should complete first
  fork
    begin : LOW_PRIORITY_WRITES
      repeat(3) begin
        low_qos_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
      end
    end
    
    begin : MEDIUM_PRIORITY_WRITES
      repeat(3) begin
        med_qos_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
      end
    end
    
    begin : HIGH_PRIORITY_WRITES
      repeat(3) begin
        high_qos_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
      end
    end
    
    begin : LOW_PRIORITY_READS
      repeat(2) begin
        low_qos_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
      end
    end
    
    begin : MEDIUM_PRIORITY_READS
      repeat(2) begin
        med_qos_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
      end
    end
    
    begin : HIGH_PRIORITY_READS
      repeat(2) begin
        high_qos_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
      end
    end
  join
  
  // Wait for all transactions to complete
  #100ns;
  
  `uvm_info(get_type_name(), "Completed QoS Basic Priority Virtual Sequence", UVM_LOW)
  
endtask : body

`endif