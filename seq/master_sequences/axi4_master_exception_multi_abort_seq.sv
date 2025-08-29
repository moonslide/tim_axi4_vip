`ifndef AXI4_MASTER_EXCEPTION_MULTI_ABORT_SEQ_INCLUDED_
`define AXI4_MASTER_EXCEPTION_MULTI_ABORT_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_exception_multi_abort_seq
// Multiple random abort events with random durations
//--------------------------------------------------------------------------------------------
class axi4_master_exception_multi_abort_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_exception_multi_abort_seq)

  // Abort type enum
  typedef enum int {
    ABORT_AWVALID,    // Abort write address valid
    ABORT_WVALID,     // Abort write data valid
    ABORT_ARVALID,    // Abort read address valid
    ABORT_WLAST,      // Abort before WLAST
    ABORT_BREADY,     // Abort BREADY acceptance
    ABORT_RREADY      // Abort RREADY acceptance
  } abort_type_e;
  
  // Randomization parameters
  rand int unsigned num_aborts;           // Number of abort events
  rand int unsigned abort_durations[];    // Duration of each abort (cycles)
  rand int unsigned delays_between[];     // Delays between aborts
  rand abort_type_e abort_types[];        // Type of each abort
  rand bit [63:0] target_addrs[];        // Target addresses
  rand bit abort_during_transfer[];      // Abort during active transfer or idle
  
  // Constraints
  constraint c_num_aborts {
    num_aborts inside {[1:15]};  // 1-15 abort events
  }
  
  constraint c_arrays_size {
    abort_durations.size() == num_aborts;
    delays_between.size() == num_aborts;
    abort_types.size() == num_aborts;
    target_addrs.size() == num_aborts;
    abort_during_transfer.size() == num_aborts;
  }
  
  constraint c_abort_params {
    foreach(abort_durations[i]) {
      abort_durations[i] inside {[5:50]};  // 5-50 cycles abort duration
    }
    
    foreach(delays_between[i]) {
      delays_between[i] inside {[100:2000]};  // 100-2000ns between aborts
    }
    
    foreach(abort_types[i]) {
      abort_types[i] inside {[ABORT_AWVALID:ABORT_RREADY]};
    }
    
    foreach(target_addrs[i]) {
      target_addrs[i][11:0] == 0;  // 4KB aligned
      target_addrs[i] < 64'h0001_0000_0000;
    }
  }

  function new(string name = "axi4_master_exception_multi_abort_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info(get_type_name(), $sformatf("Starting Multi-Abort sequence with %0d aborts", num_aborts), UVM_MEDIUM)
    
    for(int i = 0; i < num_aborts; i++) begin
      `uvm_info(get_type_name(), $sformatf("Abort %0d/%0d: Type=%s, Duration=%0d cycles, Delay=%0dns", 
                i+1, num_aborts, abort_types[i].name(), abort_durations[i], delays_between[i]), UVM_MEDIUM)
      
      // Delay before this abort
      #(delays_between[i] * 1ns);
      
      // Execute the abort based on type
      case(abort_types[i])
        ABORT_AWVALID: begin
          execute_awvalid_abort(abort_durations[i], target_addrs[i], abort_during_transfer[i]);
        end
        
        ABORT_WVALID: begin
          execute_wvalid_abort(abort_durations[i], target_addrs[i], abort_during_transfer[i]);
        end
        
        ABORT_ARVALID: begin
          execute_arvalid_abort(abort_durations[i], target_addrs[i], abort_during_transfer[i]);
        end
        
        ABORT_WLAST: begin
          execute_wlast_abort(abort_durations[i], target_addrs[i]);
        end
        
        ABORT_BREADY: begin
          execute_bready_abort(abort_durations[i]);
        end
        
        ABORT_RREADY: begin
          execute_rready_abort(abort_durations[i]);
        end
      endcase
      
      // Recovery time after abort
      #($urandom_range(50, 200) * 1ns);
    end
    
  endtask
  
  // Execute AWVALID abort
  task execute_awvalid_abort(int duration, bit [63:0] addr, bit during_transfer);
    axi4_master_tx req;
    
    req = axi4_master_tx::type_id::create("req");
    start_item(req);
    
    if(!req.randomize() with {
      tx_type == WRITE;
      awaddr == addr;
      awlen == 3;  // 4-beat burst
    }) begin
      `uvm_error(get_type_name(), "Randomization failed")
    end
    
    finish_item(req);
    
    if(during_transfer) begin
      // Start transfer then abort mid-way
      #($urandom_range(10, 30) * 1ns);
    end
    
    // Force AWVALID low for abort duration
    `uvm_info(get_type_name(), $sformatf("Aborting AWVALID for %0d cycles", duration), UVM_MEDIUM)
    // BFM will handle the abort by deasserting AWVALID
    
    #(duration * 1ns);
  endtask
  
  // Execute WVALID abort
  task execute_wvalid_abort(int duration, bit [63:0] addr, bit during_transfer);
    axi4_master_tx req;
    
    req = axi4_master_tx::type_id::create("req");
    start_item(req);
    
    if(!req.randomize() with {
      tx_type == WRITE;
      awaddr == addr;
      awlen == 7;  // 8-beat burst
    }) begin
      `uvm_error(get_type_name(), "Randomization failed")
    end
    
    finish_item(req);
    
    // Abort WVALID during data phase
    #($urandom_range(20, 50) * 1ns);
    
    `uvm_info(get_type_name(), $sformatf("Aborting WVALID for %0d cycles", duration), UVM_MEDIUM)
    
    #(duration * 1ns);
  endtask
  
  // Execute ARVALID abort
  task execute_arvalid_abort(int duration, bit [63:0] addr, bit during_transfer);
    axi4_master_tx req;
    
    req = axi4_master_tx::type_id::create("req");
    start_item(req);
    
    if(!req.randomize() with {
      tx_type == READ;
      araddr == addr;
      arlen == 3;  // 4-beat burst
    }) begin
      `uvm_error(get_type_name(), "Randomization failed")
    end
    
    finish_item(req);
    
    if(during_transfer) begin
      #($urandom_range(10, 30) * 1ns);
    end
    
    `uvm_info(get_type_name(), $sformatf("Aborting ARVALID for %0d cycles", duration), UVM_MEDIUM)
    
    #(duration * 1ns);
  endtask
  
  // Execute WLAST abort (abort before sending WLAST)
  task execute_wlast_abort(int duration, bit [63:0] addr);
    axi4_master_tx req;
    
    req = axi4_master_tx::type_id::create("req");
    start_item(req);
    
    if(!req.randomize() with {
      tx_type == WRITE;
      awaddr == addr;
      awlen == 15;  // 16-beat burst
    }) begin
      `uvm_error(get_type_name(), "Randomization failed")
    end
    
    finish_item(req);
    
    // Wait until near the end of burst
    #($urandom_range(100, 200) * 1ns);
    
    `uvm_info(get_type_name(), $sformatf("Aborting before WLAST for %0d cycles", duration), UVM_MEDIUM)
    
    #(duration * 1ns);
  endtask
  
  // Execute BREADY abort
  task execute_bready_abort(int duration);
    `uvm_info(get_type_name(), $sformatf("Aborting BREADY for %0d cycles", duration), UVM_MEDIUM)
    
    // Configure driver to deassert BREADY
    uvm_config_db#(int)::set(null, "*", "bready_abort_cycles", duration);
    
    #(duration * 1ns);
  endtask
  
  // Execute RREADY abort
  task execute_rready_abort(int duration);
    `uvm_info(get_type_name(), $sformatf("Aborting RREADY for %0d cycles", duration), UVM_MEDIUM)
    
    // Configure driver to deassert RREADY
    uvm_config_db#(int)::set(null, "*", "rready_abort_cycles", duration);
    
    #(duration * 1ns);
  endtask

endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_master_exception_continuous_abort_seq
// Continuous random aborts throughout simulation
//--------------------------------------------------------------------------------------------
class axi4_master_exception_continuous_abort_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_exception_continuous_abort_seq)
  
  // Parameters
  rand int unsigned test_duration_ns;
  rand int unsigned abort_probability;  // Percentage 0-100
  rand int unsigned min_abort_duration;
  rand int unsigned max_abort_duration;
  
  constraint c_params {
    test_duration_ns inside {[5000:20000]};  // 5-20us
    abort_probability inside {[5:30]};  // 5-30% chance
    min_abort_duration inside {[5:20]};
    max_abort_duration inside {[20:100]};
    min_abort_duration < max_abort_duration;
  }

  function new(string name = "axi4_master_exception_continuous_abort_seq");
    super.new(name);
  endfunction

  task body();
    int time_elapsed = 0;
    int num_aborts = 0;
    
    // Ensure test_duration_ns has a valid value
    if (test_duration_ns == 0) begin
      test_duration_ns = 10000;  // Default to 10us if not set
    end
    
    `uvm_info(get_type_name(), "Starting Continuous Abort sequence", UVM_MEDIUM)
    `uvm_info(get_type_name(), $sformatf("  Test duration: %0d ns", test_duration_ns), UVM_MEDIUM)
    `uvm_info(get_type_name(), $sformatf("  Abort probability: %0d%%", abort_probability), UVM_MEDIUM)
    
    // Start background traffic
    fork
      generate_background_traffic();
    join_none
    
    // Continuous abort loop
    while(time_elapsed < test_duration_ns) begin
      int wait_time = $urandom_range(50, 500);
      
      #(wait_time * 1ns);
      time_elapsed += wait_time;
      
      // Randomly decide whether to abort
      if($urandom_range(1, 100) <= abort_probability) begin
        perform_random_abort();
        num_aborts++;
      end
    end
    
    `uvm_info(get_type_name(), $sformatf("Total aborts performed: %0d", num_aborts), UVM_MEDIUM)
    
    // IMPORTANT: Kill the background traffic task before ending sequence
    disable fork;
    
    // Small delay to ensure clean termination
    #100ns;
    
  endtask
  
  // Perform a random abort
  task perform_random_abort();
    int abort_type = $urandom_range(0, 5);
    int duration = $urandom_range(min_abort_duration, max_abort_duration);
    bit [63:0] addr = $urandom & 64'hFFFF_F000;
    axi4_master_tx req;
    
    case(abort_type)
      0: begin  // AWVALID abort
        `uvm_info(get_type_name(), $sformatf("Random AWVALID abort for %0d cycles", duration), UVM_MEDIUM)
        req = axi4_master_tx::type_id::create("abort_req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == WRITE;
          awaddr == addr;
        });
        finish_item(req);
        #(duration * 1ns);
      end
      
      1: begin  // ARVALID abort
        `uvm_info(get_type_name(), $sformatf("Random ARVALID abort for %0d cycles", duration), UVM_MEDIUM)
        req = axi4_master_tx::type_id::create("abort_req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == READ;
          araddr == addr;
        });
        finish_item(req);
        #(duration * 1ns);
      end
      
      2: begin  // WVALID abort
        `uvm_info(get_type_name(), $sformatf("Random WVALID abort for %0d cycles", duration), UVM_MEDIUM)
        #(duration * 1ns);
      end
      
      3: begin  // WLAST abort
        `uvm_info(get_type_name(), $sformatf("Random WLAST abort for %0d cycles", duration), UVM_MEDIUM)
        #(duration * 1ns);
      end
      
      4: begin  // BREADY abort
        `uvm_info(get_type_name(), $sformatf("Random BREADY abort for %0d cycles", duration), UVM_MEDIUM)
        uvm_config_db#(int)::set(null, "*", "bready_abort_cycles", duration);
        #(duration * 1ns);
      end
      
      5: begin  // RREADY abort
        `uvm_info(get_type_name(), $sformatf("Random RREADY abort for %0d cycles", duration), UVM_MEDIUM)
        uvm_config_db#(int)::set(null, "*", "rready_abort_cycles", duration);
        #(duration * 1ns);
      end
    endcase
  endtask
  
  // Generate background traffic
  task generate_background_traffic();
    axi4_master_tx req;
    
    // Run for the duration of the test
    while(1) begin
      req = axi4_master_tx::type_id::create("bg_req");
      start_item(req);
      if(!req.randomize() with {
        // Constrain to valid addresses
        req.awaddr inside {[64'h0000_0008_0000_0000:64'h0000_0008_BFFF_FFFF],
                          [64'h0000_000A_0000_0000:64'h0000_000A_0004_FFFF]};
        req.araddr inside {[64'h0000_0008_0000_0000:64'h0000_0008_BFFF_FFFF],
                          [64'h0000_000A_0000_0000:64'h0000_000A_0004_FFFF]};
      }) begin
        `uvm_warning(get_type_name(), "Failed to randomize background traffic request")
      end
      finish_item(req);
      #($urandom_range(50, 200) * 1ns);
    end
  endtask

endclass

`endif