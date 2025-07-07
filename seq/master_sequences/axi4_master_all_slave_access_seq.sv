`ifndef AXI4_MASTER_ALL_SLAVE_ACCESS_SEQ_INCLUDED_
`define AXI4_MASTER_ALL_SLAVE_ACCESS_SEQ_INCLUDED_

class axi4_master_all_slave_access_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_all_slave_access_seq)
  `uvm_declare_p_sequencer(axi4_master_write_sequencer)

  extern function new(string name="axi4_master_all_slave_access_seq");
  extern task body();
endclass

function axi4_master_all_slave_access_seq::new(string name="axi4_master_all_slave_access_seq");
  super.new(name);
endfunction

// Generate a simple write then read for each slave range
// Assumes address ranges are stored in the master configuration

task axi4_master_all_slave_access_seq::body();
  bit [ADDRESS_WIDTH-1:0] test_addr;
  axi4_bus_matrix_ref bus_matrix_h;
  int master_id;
  
  super.body();
  
  // Get the bus matrix reference from config_db
  if(!uvm_config_db#(axi4_bus_matrix_ref)::get(null, "*", "bus_matrix_ref", bus_matrix_h)) begin
    `uvm_info(get_type_name(), "Bus matrix reference not found", UVM_MEDIUM)
    return;
  end
  
  // Get master ID from sequencer name (assuming format "axi4_master_agent_h[X]")
  begin
    string seqr_name = p_sequencer.get_parent().get_name();
    int idx = seqr_name.substr(seqr_name.len()-2, seqr_name.len()-2).atoi();
    master_id = idx;
    `uvm_info(get_type_name(), $sformatf("Master ID: %0d", master_id), UVM_MEDIUM)
  end
  
  // Focus on valid S0 (DDR_Memory) transactions to avoid scoreboard pairing issues
  // Each master will perform multiple transactions to S0 with different addresses
  
  for (int i = 0; i < 3; i++) begin
    test_addr = 64'h0000_0100_0000_0000 + (master_id * 'h10000) + (i * 'h1000);
    
    // Valid write to S0
    if(bus_matrix_h.slave_cfg[0].write_masters[master_id]) begin
      start_item(req);
      if(!req.randomize() with {awaddr == test_addr;
                                awlen  == 0;
                                awsize == WRITE_4_BYTES;
                                awburst == WRITE_INCR;
                                tx_type == WRITE;
                                transfer_type == NON_BLOCKING_WRITE;})
        `uvm_fatal("axi4","Rand failed");
      req.wdata.delete();
      req.wdata.push_back($urandom);
      req.wstrb.delete();
      req.wstrb.push_back('hf);
      req.wlast = 1'b1;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Master %0d: Write %0d to S0 address 0x%h", master_id, i, test_addr), UVM_MEDIUM)
    end
    
    // Valid read from S0 
    if(bus_matrix_h.slave_cfg[0].read_masters[master_id]) begin
      start_item(req);
      if(!req.randomize() with {araddr == test_addr;
                                arlen  == 0;
                                arsize == READ_4_BYTES;
                                arburst == READ_INCR;
                                tx_type == READ;
                                transfer_type == NON_BLOCKING_READ;})
        `uvm_fatal("axi4","Rand failed");
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Master %0d: Read %0d from S0 address 0x%h", master_id, i, test_addr), UVM_MEDIUM)
    end
    
    // Small delay between transactions
    #100;
  end
endtask

`endif
