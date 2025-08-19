`ifndef AXI4_STRESS_RESET_VIRTUAL_SEQ_INCLUDED_
`define AXI4_STRESS_RESET_VIRTUAL_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_stress_reset_virtual_seq
// Simplified virtual sequence implementing stress test with reset injection
//--------------------------------------------------------------------------------------------
class axi4_stress_reset_virtual_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_stress_reset_virtual_seq)

  // Sequence handles
  axi4_master_reset_smoke_seq reset_smoke_seq;
  axi4_master_midburst_reset_read_seq midburst_reset_read_seq;
  axi4_master_midburst_reset_write_seq midburst_reset_write_seq;
  axi4_master_nbk_write_rand_seq write_rand_seq;
  axi4_master_nbk_read_rand_seq read_rand_seq;
  
  // Control parameters
  rand int num_transactions = 10;
  rand int reset_delay_cycles = 1000;
  int use_bus_matrix_addressing = 0; // 0=NONE, 1=BASE_4x4, 2=ENHANCED_10x10
  
  //--------------------------------------------------------------------------------------------
  // Externally defined Tasks and Functions
  //--------------------------------------------------------------------------------------------
  extern function new(string name = "axi4_stress_reset_virtual_seq");
  extern task body();

endclass : axi4_stress_reset_virtual_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the axi4_stress_reset_virtual_seq class object
//
// Parameters:
//  name - axi4_stress_reset_virtual_seq
//--------------------------------------------------------------------------------------------
function axi4_stress_reset_virtual_seq::new(string name = "axi4_stress_reset_virtual_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Main body task that orchestrates the stress reset test
//--------------------------------------------------------------------------------------------
task axi4_stress_reset_virtual_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), "Starting AXI4 Stress Reset Virtual Sequence", UVM_LOW)
  
  // Phase 1: Run some normal traffic on master 0 only to avoid timeout
  `uvm_info(get_type_name(), "Phase 1: Running normal traffic on master 0", UVM_MEDIUM)
  
  for(int i = 0; i < num_transactions; i++) begin
    // Run write transaction
    write_rand_seq = axi4_master_nbk_write_rand_seq::type_id::create($sformatf("write_rand_seq_%0d", i));
    write_rand_seq.use_bus_matrix_addressing = use_bus_matrix_addressing;
    write_rand_seq.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
    
    // Run read transaction  
    read_rand_seq = axi4_master_nbk_read_rand_seq::type_id::create($sformatf("read_rand_seq_%0d", i));
    read_rand_seq.use_bus_matrix_addressing = use_bus_matrix_addressing;
    read_rand_seq.start(p_sequencer.axi4_master_read_seqr_h_all[0]);
  end
  
  // Wait for some time (optimized for fast execution)
  #(reset_delay_cycles * 100ps);
  
  // Phase 2: Inject mid-burst reset sequence
  `uvm_info(get_type_name(), "Phase 2: Injecting mid-burst reset", UVM_MEDIUM)
  
  // Start a long burst transaction that will be interrupted
  fork
    begin
      midburst_reset_write_seq = axi4_master_midburst_reset_write_seq::type_id::create("midburst_reset_write_seq");
      midburst_reset_write_seq.master_id = 0;
      midburst_reset_write_seq.slave_id = 0;
      midburst_reset_write_seq.use_bus_matrix_addressing = use_bus_matrix_addressing;
      midburst_reset_write_seq.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
    end
    begin
      midburst_reset_read_seq = axi4_master_midburst_reset_read_seq::type_id::create("midburst_reset_read_seq");
      midburst_reset_read_seq.master_id = 1 % env_cfg_h.no_of_masters;
      midburst_reset_read_seq.slave_id = 0;
      midburst_reset_read_seq.use_bus_matrix_addressing = use_bus_matrix_addressing;
      if(env_cfg_h.no_of_masters > 1) begin
        midburst_reset_read_seq.start(p_sequencer.axi4_master_read_seqr_h_all[1]);
      end
    end
  join_none
  
  // Wait for transactions to be in progress (optimized)
  #50ns;
  
  // Signal for reset injection (to be handled by test)
  `uvm_info(get_type_name(), "Signaling for reset injection", UVM_LOW)
  uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);
  #10ns;
  uvm_config_db#(bit)::set(null, "*", "inject_reset", 0);
  
  // Wait for reset to complete (optimized)
  #100ns;
  
  // Phase 3: Recovery - run smoke test on master 0 only
  `uvm_info(get_type_name(), "Phase 3: Running recovery smoke test on master 0", UVM_MEDIUM)
  reset_smoke_seq = axi4_master_reset_smoke_seq::type_id::create("reset_smoke_seq");
  reset_smoke_seq.num_txns = 1;
  reset_smoke_seq.use_bus_matrix_addressing = use_bus_matrix_addressing;
  reset_smoke_seq.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
  
  `uvm_info(get_type_name(), "Completed AXI4 Stress Reset Virtual Sequence", UVM_LOW)
  
endtask : body

`endif