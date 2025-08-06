`ifndef AXI4_VIRTUAL_QOS_BASIC_PRIORITY_SEQ_INCLUDED_
`define AXI4_VIRTUAL_QOS_BASIC_PRIORITY_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_qos_basic_priority_seq
// Description:
// Virtual sequence for testing QoS basic priority ordering
//--------------------------------------------------------------------------------------------
class axi4_virtual_qos_basic_priority_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_qos_basic_priority_seq)

  // Master sequences
  axi4_master_qos_basic_priority_order_seq master_qos_priority_seq_h[];

  //--------------------------------------------------------------------------------------------
  // Externally defined tasks and functions
  //--------------------------------------------------------------------------------------------
  extern function new(string name = "axi4_virtual_qos_basic_priority_seq");
  extern task body();

endclass : axi4_virtual_qos_basic_priority_seq

//--------------------------------------------------------------------------------------------
// Constructor: new
//
// Parameters:
//  name - Instance name of the virtual_sequence
//--------------------------------------------------------------------------------------------
function axi4_virtual_qos_basic_priority_seq::new(string name = "axi4_virtual_qos_basic_priority_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Executes the QoS basic priority test scenario
//--------------------------------------------------------------------------------------------
task axi4_virtual_qos_basic_priority_seq::body();
  super.body();
  
  master_qos_priority_seq_h = new[env_cfg_h.no_of_masters];
  
  `uvm_info(get_type_name(), $sformatf("Starting QoS basic priority test with %0d masters and %0d slaves", 
                                       env_cfg_h.no_of_masters, env_cfg_h.no_of_slaves), UVM_LOW);
  `uvm_info(get_type_name(), "Slaves are in SLAVE_MEM_MODE - they will respond automatically to master requests", UVM_LOW);
  
  // Create master sequences
  foreach(master_qos_priority_seq_h[i]) begin
    master_qos_priority_seq_h[i] = axi4_master_qos_basic_priority_order_seq::type_id::create($sformatf("master_qos_priority_seq_h[%0d]", i));
  end
  
  // Start master sequences - slaves will respond automatically in SLAVE_MEM_MODE
  foreach(master_qos_priority_seq_h[i]) begin
    automatic int idx = i;
    fork
      begin
        `uvm_info(get_type_name(), $sformatf("Starting QoS priority sequence on master[%0d]", idx), UVM_MEDIUM);
        // Configure master_id for the sequence
        uvm_config_db#(int)::set(null, {get_full_name(), ".", master_qos_priority_seq_h[idx].get_name()}, 
                                "master_id", idx);
        master_qos_priority_seq_h[idx].start(p_sequencer.axi4_master_read_seqr_h_all[idx]);
      end
    join_none
  end
  
  // Wait for all master sequences to complete
  wait fork;
  
  `uvm_info(get_type_name(), "Completed QoS basic priority test", UVM_LOW);
  
endtask : body

`endif