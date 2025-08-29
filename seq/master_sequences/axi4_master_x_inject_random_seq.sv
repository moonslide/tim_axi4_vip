`ifndef AXI4_MASTER_X_INJECT_RANDOM_SEQ_INCLUDED_
`define AXI4_MASTER_X_INJECT_RANDOM_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_x_inject_random_seq
// Sequence for randomly injecting X values during long-running tests
//--------------------------------------------------------------------------------------------
class axi4_master_x_inject_random_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_x_inject_random_seq)

  // Test duration and injection parameters
  rand int unsigned test_duration_ns;      // Total test duration
  rand int unsigned min_inject_interval;   // Min time between injections
  rand int unsigned max_inject_interval;   // Max time between injections
  rand int unsigned x_inject_cycles;       // Duration of each injection
  rand int unsigned num_injections;        // Total number of injections
  
  // Track injection count
  int injection_count = 0;
  
  // Injection targets (randomly selected each time)
  typedef enum {
    INJECT_AWVALID,
    INJECT_AWADDR,
    INJECT_WDATA,
    INJECT_ARVALID,
    INJECT_BREADY,
    INJECT_RREADY
  } inject_target_e;

  // Constraints
  constraint c_timing {
    test_duration_ns inside {[10000:50000]};  // 10-50 us test
    min_inject_interval inside {[100:500]};   // 100-500 ns minimum
    max_inject_interval inside {[1000:5000]}; // 1-5 us maximum
    min_inject_interval < max_inject_interval;
    x_inject_cycles inside {[5:20]};  // 5-20 cycles of X injection for better coverage
    num_injections inside {[5:20]};
  }

  // Transaction queue for background traffic
  axi4_master_tx txn_queue[$];
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_x_inject_random_seq");
  extern task body();
  extern task generate_background_traffic();
  extern task inject_x_randomly();
  extern task perform_single_injection();

endclass : axi4_master_x_inject_random_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_master_x_inject_random_seq::new(string name = "axi4_master_x_inject_random_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_random_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), "Starting RANDOM X injection sequence", UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("  Test duration: %0d ns", test_duration_ns), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("  Number of injections: %0d", num_injections), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("  Injection interval: %0d-%0d ns", min_inject_interval, max_inject_interval), UVM_MEDIUM)
  
  // Run background traffic and random injections in parallel
  fork
    begin : traffic_thread
      generate_background_traffic();
    end
    
    begin : injection_thread
      inject_x_randomly();
    end
  join_any
  
  // Disable the other thread
  disable fork;
  
  // Final recovery period
  #100ns;
  
  `uvm_info(get_type_name(), $sformatf("Random X injection completed. Total injections: %0d", injection_count), UVM_MEDIUM)
  
endtask : body

//--------------------------------------------------------------------------------------------
// Task: generate_background_traffic
// Continuously generate normal AXI transactions
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_random_seq::generate_background_traffic();
  int txn_count = 0;
  time end_time = $time + test_duration_ns * 1ns;
  
  `uvm_info(get_type_name(), "Starting background traffic generation", UVM_HIGH)
  
  while($time < end_time) begin
    req = axi4_master_tx::type_id::create($sformatf("bg_req_%0d", txn_count));
    start_item(req);
    
    assert(req.randomize() with {
      tx_type dist { WRITE := 50, READ := 50 };
      // Use valid slave address ranges
      awaddr inside {[64'h0000_0008_0000_0000:64'h0000_0008_BFFF_FFFF],
                     [64'h0000_000A_0000_0000:64'h0000_000A_0004_FFFF]};
      araddr inside {[64'h0000_0008_0000_0000:64'h0000_0008_BFFF_FFFF],
                     [64'h0000_000A_0000_0000:64'h0000_000A_0004_FFFF]};
      awlen inside {[0:7]};  // Variable burst lengths
      arlen inside {[0:7]};
      awsize dist { WRITE_1_BYTE := 10, 
                     WRITE_2_BYTES := 20, 
                     WRITE_4_BYTES := 40,
                     WRITE_8_BYTES := 30 };
      arsize dist { READ_1_BYTE := 10,
                     READ_2_BYTES := 20,
                     READ_4_BYTES := 40,
                     READ_8_BYTES := 30 };
      awburst dist { WRITE_FIXED := 10, WRITE_INCR := 80, WRITE_WRAP := 10 };
      arburst dist { READ_FIXED := 10, READ_INCR := 80, READ_WRAP := 10 };
      transfer_type == BLOCKING_WRITE;
    }) else `uvm_fatal(get_type_name(), "Randomization failed")
    
    finish_item(req);
    txn_count++;
    
    // Random delay between transactions
    #($urandom_range(10, 100) * 1ns);
  end
  
  `uvm_info(get_type_name(), $sformatf("Background traffic completed. Total transactions: %0d", txn_count), UVM_HIGH)
  
endtask : generate_background_traffic

//--------------------------------------------------------------------------------------------
// Task: inject_x_randomly
// Randomly inject X at various points during the test
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_random_seq::inject_x_randomly();
  time next_injection_time;
  time end_time = $time + test_duration_ns * 1ns;
  
  `uvm_info(get_type_name(), "Starting random X injection controller", UVM_HIGH)
  
  while(($time < end_time) && (injection_count < num_injections)) begin
    // Calculate random wait time
    next_injection_time = $urandom_range(min_inject_interval, max_inject_interval);
    
    // Wait for next injection time
    #(next_injection_time * 1ns);
    
    // Perform injection
    perform_single_injection();
    injection_count++;
    
    `uvm_info(get_type_name(), $sformatf("Injection #%0d completed at time %0t", injection_count, $time), UVM_MEDIUM)
  end
  
endtask : inject_x_randomly

//--------------------------------------------------------------------------------------------
// Task: perform_single_injection
// Perform a single X injection on a randomly selected signal
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_random_seq::perform_single_injection();
  inject_target_e target;
  string target_name;
  
  // Randomly select injection target
  target = inject_target_e'($urandom_range(0, 5));
  
  case(target)
    INJECT_AWVALID: begin
      target_name = "AWVALID";
      uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid_active", 1);
    end
    INJECT_AWADDR: begin
      target_name = "AWADDR";
      uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr_active", 1);
    end
    INJECT_WDATA: begin
      target_name = "WDATA";
      uvm_config_db#(bit)::set(null, "*", "x_inject_wdata_active", 1);
    end
    INJECT_ARVALID: begin
      target_name = "ARVALID";
      uvm_config_db#(bit)::set(null, "*", "x_inject_arvalid_active", 1);
    end
    INJECT_BREADY: begin
      target_name = "BREADY";
      uvm_config_db#(bit)::set(null, "*", "x_inject_bready_active", 1);
    end
    INJECT_RREADY: begin
      target_name = "RREADY";
      uvm_config_db#(bit)::set(null, "*", "x_inject_rready_active", 1);
    end
  endcase
  
  // Set injection duration
  uvm_config_db#(int)::set(null, "*", "x_inject_cycles", x_inject_cycles);
  
  `uvm_info(get_type_name(), $sformatf("Injecting X on %s for %0d cycles", target_name, x_inject_cycles), UVM_MEDIUM)
  
  // Wait for injection duration
  #(x_inject_cycles * 10ns);
  
  // Clear all injection flags
  uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid_active", 0);
  uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr_active", 0);
  uvm_config_db#(bit)::set(null, "*", "x_inject_wdata_active", 0);
  uvm_config_db#(bit)::set(null, "*", "x_inject_arvalid_active", 0);
  uvm_config_db#(bit)::set(null, "*", "x_inject_bready_active", 0);
  uvm_config_db#(bit)::set(null, "*", "x_inject_rready_active", 0);
  
endtask : perform_single_injection

`endif