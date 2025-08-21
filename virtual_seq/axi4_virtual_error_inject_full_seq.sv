`ifndef AXI4_VIRTUAL_ERROR_INJECT_FULL_SEQ_INCLUDED_
`define AXI4_VIRTUAL_ERROR_INJECT_FULL_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_full_seq
// Full virtual sequence for error injection testing - uses all available masters/slaves
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_full_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_full_seq)

  // Dynamic arrays for master sequences
  axi4_master_bk_write_seq axi4_master_bk_write_seq_h[];
  axi4_master_bk_read_seq axi4_master_bk_read_seq_h[];
  
  // Number of masters/slaves to use
  int num_masters_to_use;
  int num_slaves_to_use;

  function new(string name = "axi4_virtual_error_inject_full_seq");
    super.new(name);
  endfunction

  task body();
    axi4_bus_matrix_ref::bus_matrix_mode_e bus_mode;
    super.body();
    
    // Get bus matrix mode from config
    if (!uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::get(m_sequencer, "", "bus_matrix_mode", bus_mode)) begin
      `uvm_warning(get_type_name(), "bus_matrix_mode not found in config, using all masters")
      bus_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
    end
    
    // Determine number of masters/slaves to use based on bus matrix mode
    case (bus_mode)
      axi4_bus_matrix_ref::NONE: begin
        num_masters_to_use = 1;  // Only use 1 master in NONE mode
        num_slaves_to_use = 1;   // Only use 1 slave in NONE mode
        `uvm_info(get_type_name(), "NONE mode: Using 1 master and 1 slave", UVM_MEDIUM)
      end
      axi4_bus_matrix_ref::BASE_BUS_MATRIX: begin
        num_masters_to_use = 4;  // Use 4 masters in BASE mode
        num_slaves_to_use = 4;   // Use 4 slaves in BASE mode
        `uvm_info(get_type_name(), "BASE mode: Using 4 masters and 4 slaves", UVM_MEDIUM)
      end
      axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: begin
        num_masters_to_use = env_cfg_h.no_of_masters;  // Use all masters in ENHANCED mode
        num_slaves_to_use = env_cfg_h.no_of_slaves;    // Use all slaves in ENHANCED mode
        `uvm_info(get_type_name(), $sformatf("ENHANCED mode: Using all %0d masters and %0d slaves", 
                  num_masters_to_use, num_slaves_to_use), UVM_MEDIUM)
      end
      default: begin
        num_masters_to_use = env_cfg_h.no_of_masters;
        num_slaves_to_use = env_cfg_h.no_of_slaves;
        `uvm_warning(get_type_name(), $sformatf("Unknown bus mode, using all %0d masters", num_masters_to_use))
      end
    endcase
    
    // Ensure we don't exceed available masters/slaves
    if (num_masters_to_use > env_cfg_h.no_of_masters) begin
      num_masters_to_use = env_cfg_h.no_of_masters;
      `uvm_warning(get_type_name(), $sformatf("Limiting to available %0d masters", num_masters_to_use))
    end
    if (num_slaves_to_use > env_cfg_h.no_of_slaves) begin
      num_slaves_to_use = env_cfg_h.no_of_slaves;
      `uvm_warning(get_type_name(), $sformatf("Limiting to available %0d slaves", num_slaves_to_use))
    end
    
    `uvm_info(get_type_name(), $sformatf("Starting error injection test with %0d active masters and %0d active slaves", 
              num_masters_to_use, num_slaves_to_use), UVM_MEDIUM)
    
    // Create sequence arrays
    axi4_master_bk_write_seq_h = new[num_masters_to_use];
    axi4_master_bk_read_seq_h = new[num_masters_to_use];
    
    // Create sequences for each master
    foreach(axi4_master_bk_write_seq_h[i]) begin
      axi4_master_bk_write_seq_h[i] = axi4_master_bk_write_seq::type_id::create($sformatf("axi4_master_bk_write_seq_h[%0d]", i));
      axi4_master_bk_read_seq_h[i] = axi4_master_bk_read_seq::type_id::create($sformatf("axi4_master_bk_read_seq_h[%0d]", i));
    end
    
    // Run write transactions from all masters in parallel
    `uvm_info(get_type_name(), $sformatf("Running write transactions from %0d masters in parallel", num_masters_to_use), UVM_MEDIUM)
    fork
      begin
        for(int i = 0; i < num_masters_to_use; i++) begin
          automatic int master_idx = i;
          fork
            begin
              `uvm_info(get_type_name(), $sformatf("Master[%0d]: Starting write transaction", master_idx), UVM_HIGH)
              if(p_sequencer.axi4_master_write_seqr_h_all.size() > master_idx) begin
                axi4_master_bk_write_seq_h[master_idx].start(p_sequencer.axi4_master_write_seqr_h_all[master_idx]);
              end else begin
                `uvm_warning(get_type_name(), $sformatf("Master write sequencer[%0d] not available", master_idx))
              end
            end
          join_none
        end
        wait fork;
      end
    join
    
    // Add delay to simulate error injection/recovery
    #100ns;
    
    // Run read transactions from all masters in parallel
    `uvm_info(get_type_name(), $sformatf("Running read transactions from %0d masters in parallel", num_masters_to_use), UVM_MEDIUM)
    fork
      begin
        for(int i = 0; i < num_masters_to_use; i++) begin
          automatic int master_idx = i;
          fork
            begin
              `uvm_info(get_type_name(), $sformatf("Master[%0d]: Starting read transaction", master_idx), UVM_HIGH)
              if(p_sequencer.axi4_master_read_seqr_h_all.size() > master_idx) begin
                axi4_master_bk_read_seq_h[master_idx].start(p_sequencer.axi4_master_read_seqr_h_all[master_idx]);
              end else begin
                `uvm_warning(get_type_name(), $sformatf("Master read sequencer[%0d] not available", master_idx))
              end
            end
          join_none
        end
        wait fork;
      end
    join
    
    `uvm_info(get_type_name(), $sformatf("Full error injection test completed with %0d masters", num_masters_to_use), UVM_MEDIUM)
    
  endtask
endclass

`endif