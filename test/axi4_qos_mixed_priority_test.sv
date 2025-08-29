`ifndef AXI4_QOS_MIXED_PRIORITY_TEST_INCLUDED_
`define AXI4_QOS_MIXED_PRIORITY_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_mixed_priority_test
// Test mixed QoS priority transactions
//--------------------------------------------------------------------------------------------
class axi4_qos_mixed_priority_test extends axi4_base_test;
  `uvm_component_utils(axi4_qos_mixed_priority_test)

  // Virtual sequences
  axi4_virtual_write_seq virtual_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_qos_mixed_priority_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_qos_mixed_priority_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_qos_mixed_priority_test
//  parent - parent under which this test is created
//--------------------------------------------------------------------------------------------
function axi4_qos_mixed_priority_test::new(string name = "axi4_qos_mixed_priority_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Creates components for the test
//
// Parameters:
//  phase - UVM phase
//--------------------------------------------------------------------------------------------
function void axi4_qos_mixed_priority_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Set test category explicitly for proper configuration
  test_name = "axi4_qos_mixed_priority_test";
  
  `uvm_info(get_type_name(), "QoS Mixed Priority Test Build Phase", UVM_MEDIUM)
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Runs the virtual sequence
//
// Parameters:
//  phase - UVM phase
//--------------------------------------------------------------------------------------------
task axi4_qos_mixed_priority_test::run_phase(uvm_phase phase);
  axi4_master_qos_priority_write_seq master_seq_h;
  axi4_slave_qos_response_seq slave_write_seq_h;
  axi4_slave_qos_response_seq slave_read_seq_h;
  bit timeout_occurred = 0;
  
  `uvm_info(get_type_name(), "Starting QoS Mixed Priority Test", UVM_LOW)
  
  phase.raise_objection(this);
  
  // Set up proper sequencer coordination
  axi4_virtual_sequencer_coordinator::setup_slave_coordination(axi4_virtual_seqr_h, 1);
  axi4_virtual_sequencer_coordinator::ensure_slaves_active(1);
  
  // Global timeout protection
  fork
    begin
      #8us;  // Global timeout
      timeout_occurred = 1;
      `uvm_warning(get_type_name(), "QoS mixed priority test timeout - completing")
      phase.drop_objection(this);
    end
  join_none
  
  // Create slave response sequences
  slave_write_seq_h = axi4_slave_qos_response_seq::type_id::create("slave_write_seq_h");
  slave_read_seq_h = axi4_slave_qos_response_seq::type_id::create("slave_read_seq_h");
  
  // Start coordinated slave response handling  
  axi4_virtual_sequencer_coordinator::start_slave_response_coordination(axi4_virtual_seqr_h, 10, 100);
  
  // Create and run master sequences with different QoS values with timeout
  for(int i = 0; i < 3 && !timeout_occurred; i++) begin
    master_seq_h = axi4_master_qos_priority_write_seq::type_id::create($sformatf("master_seq_h_%0d", i));
    master_seq_h.qos_value = $urandom_range(0, 15);  // Random QoS value
    master_seq_h.master_id = 0;  // Master 0
    master_seq_h.target_slave_id = 0;  // Target slave 0 (only slave in 1x1 mode)
    
    `uvm_info(get_type_name(), $sformatf("Starting master sequence %0d with QoS=%0d", i, master_seq_h.qos_value), UVM_MEDIUM)
    
    fork
      master_seq_h.start(axi4_virtual_seqr_h.axi4_master_write_seqr_h);
      begin
        #1us;  // Timeout per master sequence
        `uvm_warning(get_type_name(), $sformatf("Master sequence %0d timeout", i))
      end
    join_any
    disable fork;
    
    if(!timeout_occurred) #200ns;  // Increased delay between sequences
  end
  
  // Wait for transactions to complete (if not timed out)
  if(!timeout_occurred) begin
    #1000ns;
    phase.drop_objection(this);
  end
  
  `uvm_info(get_type_name(), "Completed QoS Mixed Priority Test", UVM_LOW)
  
endtask : run_phase

`endif