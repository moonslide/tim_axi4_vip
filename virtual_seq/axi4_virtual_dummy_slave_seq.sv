`ifndef AXI4_VIRTUAL_DUMMY_SLAVE_SEQ_INCLUDED_
`define AXI4_VIRTUAL_DUMMY_SLAVE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_dummy_slave_seq
// Virtual sequence that runs dummy slave sequences to prevent blocking
// Used when slaves are ACTIVE but no real transactions are needed
//--------------------------------------------------------------------------------------------
class axi4_virtual_dummy_slave_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_dummy_slave_seq)
  
  // Number of dummy sequences to run
  int num_dummy_sequences = 100;

  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_virtual_dummy_slave_seq");
    super.new(name);
  endfunction : new

  //--------------------------------------------------------------------------------------------
  // Task: body
  //--------------------------------------------------------------------------------------------
  task body();
    axi4_slave_dummy_write_seq slave_write_seq;
    axi4_slave_dummy_read_seq slave_read_seq;
    
    `uvm_info(get_type_name(), "Starting dummy slave sequences to prevent blocking", UVM_MEDIUM)
    
    // Run dummy sequences on all slave sequencers if they exist
    if(p_sequencer.axi4_slave_write_seqr_h != null) begin
      fork
        begin
          // Run dummy write sequences continuously
          for(int i = 0; i < num_dummy_sequences; i++) begin
            slave_write_seq = axi4_slave_dummy_write_seq::type_id::create($sformatf("dummy_write_%0d", i));
            slave_write_seq.start(p_sequencer.axi4_slave_write_seqr_h);
          end
        end
      join_none
    end
    
    if(p_sequencer.axi4_slave_read_seqr_h != null) begin
      fork
        begin
          // Run dummy read sequences continuously
          for(int i = 0; i < num_dummy_sequences; i++) begin
            slave_read_seq = axi4_slave_dummy_read_seq::type_id::create($sformatf("dummy_read_%0d", i));
            slave_read_seq.start(p_sequencer.axi4_slave_read_seqr_h);
          end
        end
      join_none
    end
    
    // Also run on all slave sequencers in the array
    foreach(p_sequencer.axi4_slave_write_seqr_h_all[i]) begin
      if(p_sequencer.axi4_slave_write_seqr_h_all[i] != null) begin
        fork
          automatic int idx = i;
          begin
            for(int j = 0; j < num_dummy_sequences; j++) begin
              slave_write_seq = axi4_slave_dummy_write_seq::type_id::create($sformatf("dummy_write_s%0d_%0d", idx, j));
              slave_write_seq.start(p_sequencer.axi4_slave_write_seqr_h_all[idx]);
            end
          end
        join_none
      end
    end
    
    foreach(p_sequencer.axi4_slave_read_seqr_h_all[i]) begin
      if(p_sequencer.axi4_slave_read_seqr_h_all[i] != null) begin
        fork
          automatic int idx = i;
          begin
            for(int j = 0; j < num_dummy_sequences; j++) begin
              slave_read_seq = axi4_slave_dummy_read_seq::type_id::create($sformatf("dummy_read_s%0d_%0d", idx, j));
              slave_read_seq.start(p_sequencer.axi4_slave_read_seqr_h_all[idx]);
            end
          end
        join_none
      end
    end
    
    `uvm_info(get_type_name(), "Dummy slave sequences started in background", UVM_MEDIUM)
    
  endtask : body

endclass : axi4_virtual_dummy_slave_seq

`endif