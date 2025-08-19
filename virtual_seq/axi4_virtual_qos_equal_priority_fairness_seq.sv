`ifndef AXI4_VIRTUAL_QOS_EQUAL_PRIORITY_FAIRNESS_SEQ_INCLUDED_
`define AXI4_VIRTUAL_QOS_EQUAL_PRIORITY_FAIRNESS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_qos_equal_priority_fairness_seq
// Virtual sequence for testing fairness when transactions have equal QoS priority
// Generates multiple transactions with the same QoS value and verifies fair arbitration
//--------------------------------------------------------------------------------------------
class axi4_virtual_qos_equal_priority_fairness_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_qos_equal_priority_fairness_seq)

  // Configuration parameters from test
  int num_masters = 4;
  int num_slaves = 4;
  bit is_enhanced_mode = 0;
  bit is_4x4_ref_mode = 0;

  // Master sequences for equal QoS testing
  axi4_master_qos_priority_write_seq master0_write_seq_h;
  axi4_master_qos_priority_write_seq master1_write_seq_h;
  axi4_master_qos_priority_write_seq master2_write_seq_h;
  axi4_master_qos_priority_write_seq master3_write_seq_h;
  
  axi4_master_qos_priority_read_seq master0_read_seq_h;
  axi4_master_qos_priority_read_seq master1_read_seq_h;
  axi4_master_qos_priority_read_seq master2_read_seq_h;
  axi4_master_qos_priority_read_seq master3_read_seq_h;

  // Slave sequences
  axi4_slave_nbk_write_seq axi4_slave_write_seq_h;
  axi4_slave_nbk_read_seq axi4_slave_read_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_qos_equal_priority_fairness_seq");
  extern task body();

endclass : axi4_virtual_qos_equal_priority_fairness_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the object
//
// Parameters:
//  name - axi4_virtual_qos_equal_priority_fairness_seq
//--------------------------------------------------------------------------------------------
function axi4_virtual_qos_equal_priority_fairness_seq::new(string name = "axi4_virtual_qos_equal_priority_fairness_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates and starts sequences for equal priority fairness testing
// All masters generate transactions with the same QoS value to test fairness
//--------------------------------------------------------------------------------------------
task axi4_virtual_qos_equal_priority_fairness_seq::body();
  
  `uvm_info(get_type_name(), "Starting QoS Equal Priority Fairness Virtual Sequence", UVM_LOW)
  
  // Create sequences for multiple masters with equal priority
  master0_write_seq_h = axi4_master_qos_priority_write_seq::type_id::create("master0_write_seq_h");
  master1_write_seq_h = axi4_master_qos_priority_write_seq::type_id::create("master1_write_seq_h");
  master2_write_seq_h = axi4_master_qos_priority_write_seq::type_id::create("master2_write_seq_h");
  master3_write_seq_h = axi4_master_qos_priority_write_seq::type_id::create("master3_write_seq_h");
  
  master0_read_seq_h = axi4_master_qos_priority_read_seq::type_id::create("master0_read_seq_h");
  master1_read_seq_h = axi4_master_qos_priority_read_seq::type_id::create("master1_read_seq_h");
  master2_read_seq_h = axi4_master_qos_priority_read_seq::type_id::create("master2_read_seq_h");
  master3_read_seq_h = axi4_master_qos_priority_read_seq::type_id::create("master3_read_seq_h");
  
  // Create slave sequences
  axi4_slave_write_seq_h = axi4_slave_nbk_write_seq::type_id::create("axi4_slave_write_seq_h");
  axi4_slave_read_seq_h = axi4_slave_nbk_read_seq::type_id::create("axi4_slave_read_seq_h");
  
  // Set all masters to use the SAME QoS value (medium priority)
  // This tests fairness when all transactions have equal priority
  master0_write_seq_h.qos_value = 4'b0100;  // Same priority
  master1_write_seq_h.qos_value = 4'b0100;  // Same priority
  master2_write_seq_h.qos_value = 4'b0100;  // Same priority
  master3_write_seq_h.qos_value = 4'b0100;  // Same priority
  
  master0_read_seq_h.qos_value = 4'b0100;   // Same priority
  master1_read_seq_h.qos_value = 4'b0100;   // Same priority
  master2_read_seq_h.qos_value = 4'b0100;   // Same priority
  master3_read_seq_h.qos_value = 4'b0100;   // Same priority
  
  // Set master IDs for proper AWID/ARID generation
  master0_write_seq_h.master_id = 0;
  master1_write_seq_h.master_id = 1;
  master2_write_seq_h.master_id = 2;
  master3_write_seq_h.master_id = 3;
  
  master0_read_seq_h.master_id = 0;
  master1_read_seq_h.master_id = 1;
  master2_read_seq_h.master_id = 2;
  master3_read_seq_h.master_id = 3;
  
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
  
  // Generate equal priority transactions from multiple masters concurrently
  // The expectation is that all masters should get fair access (no starvation)
  // Use up to 4 masters, each on their own sequencer
  fork
    begin : MASTER0_WRITES
      if (p_sequencer.axi4_master_write_seqr_h_all.size() > 0) begin
        `uvm_info(get_type_name(), "Master 0 starting equal priority writes", UVM_MEDIUM)
        repeat(5) begin
          master0_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
        end
        `uvm_info(get_type_name(), "Master 0 completed equal priority writes", UVM_MEDIUM)
      end
    end
    
    begin : MASTER1_WRITES
      if (p_sequencer.axi4_master_write_seqr_h_all.size() > 1) begin
        `uvm_info(get_type_name(), "Master 1 starting equal priority writes", UVM_MEDIUM)
        repeat(5) begin
          master1_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h_all[1]);
        end
        `uvm_info(get_type_name(), "Master 1 completed equal priority writes", UVM_MEDIUM)
      end
    end
    
    begin : MASTER2_WRITES
      if (p_sequencer.axi4_master_write_seqr_h_all.size() > 2) begin
        `uvm_info(get_type_name(), "Master 2 starting equal priority writes", UVM_MEDIUM)
        repeat(5) begin
          master2_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h_all[2]);
        end
        `uvm_info(get_type_name(), "Master 2 completed equal priority writes", UVM_MEDIUM)
      end
    end
    
    begin : MASTER3_WRITES
      if (p_sequencer.axi4_master_write_seqr_h_all.size() > 3) begin
        `uvm_info(get_type_name(), "Master 3 starting equal priority writes", UVM_MEDIUM)
        repeat(5) begin
          master3_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h_all[3]);
        end
        `uvm_info(get_type_name(), "Master 3 completed equal priority writes", UVM_MEDIUM)
      end
    end
    
    begin : MASTER0_READS
      if (p_sequencer.axi4_master_read_seqr_h_all.size() > 0) begin
        `uvm_info(get_type_name(), "Master 0 starting equal priority reads", UVM_MEDIUM)
        repeat(3) begin
          master0_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h_all[0]);
        end
        `uvm_info(get_type_name(), "Master 0 completed equal priority reads", UVM_MEDIUM)
      end
    end
    
    begin : MASTER1_READS
      if (p_sequencer.axi4_master_read_seqr_h_all.size() > 1) begin
        `uvm_info(get_type_name(), "Master 1 starting equal priority reads", UVM_MEDIUM)
        repeat(3) begin
          master1_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h_all[1]);
        end
        `uvm_info(get_type_name(), "Master 1 completed equal priority reads", UVM_MEDIUM)
      end
    end
    
    begin : MASTER2_READS
      if (p_sequencer.axi4_master_read_seqr_h_all.size() > 2) begin
        `uvm_info(get_type_name(), "Master 2 starting equal priority reads", UVM_MEDIUM)
        repeat(3) begin
          master2_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h_all[2]);
        end
        `uvm_info(get_type_name(), "Master 2 completed equal priority reads", UVM_MEDIUM)
      end
    end
    
    begin : MASTER3_READS
      if (p_sequencer.axi4_master_read_seqr_h_all.size() > 3) begin
        `uvm_info(get_type_name(), "Master 3 starting equal priority reads", UVM_MEDIUM)
        repeat(3) begin
          master3_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h_all[3]);
        end
        `uvm_info(get_type_name(), "Master 3 completed equal priority reads", UVM_MEDIUM)
      end
    end
  join
  
  // Wait for all transactions to complete
  #200ns;
  
  `uvm_info(get_type_name(), "Completed QoS Equal Priority Fairness Virtual Sequence", UVM_LOW)
  `uvm_info(get_type_name(), "All masters with equal QoS priority should have received fair access", UVM_LOW)
  
endtask : body

`endif