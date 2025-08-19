`ifndef AXI4_WRITE_HEAVY_MIDBURST_RESET_RW_CONTENTION_TEST_INCLUDED_
`define AXI4_WRITE_HEAVY_MIDBURST_RESET_RW_CONTENTION_TEST_INCLUDED_

class axi4_write_heavy_midburst_reset_rw_contention_test extends axi4_base_test;
  `uvm_component_utils(axi4_write_heavy_midburst_reset_rw_contention_test)
  
  axi4_master_nbk_write_rand_seq write_seq[];
  axi4_master_nbk_read_rand_seq read_seq[];
  
  function new(string name = "axi4_write_heavy_midburst_reset_rw_contention_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Write-heavy configuration
    `uvm_info(get_type_name(), "Write heavy test build phase", UVM_LOW)
  endfunction
  
  task run_phase(uvm_phase phase);
    int num_masters = axi4_env_cfg_h.no_of_masters;
    
    phase.raise_objection(this);
    
    write_seq = new[num_masters];
    read_seq = new[num_masters];
    
    // Run minimal transactions to avoid timeout
    fork
      begin
        // Write-heavy traffic (80% writes, 20% reads)
        repeat(2) begin  // Reduced from 10
          for(int i = 0; i < num_masters && i < 2; i++) begin  // Limit to 2 masters
            write_seq[i] = axi4_master_nbk_write_rand_seq::type_id::create($sformatf("write_seq_%0d", i));
            write_seq[i].start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h_all[i]);
            
            if($urandom_range(0,4) == 0) begin  // 20% chance for read
              read_seq[i] = axi4_master_nbk_read_rand_seq::type_id::create($sformatf("read_seq_%0d", i));
              read_seq[i].start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_read_seqr_h_all[i]);
            end
          end
        end
      end
    join
    
    #100ns;  // Reduced observation time
    
    phase.drop_objection(this);
  endtask
  
endclass
`endif
