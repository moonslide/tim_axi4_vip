`ifndef HDL_TOP_INCLUDED_
`define HDL_TOP_INCLUDED_

//--------------------------------------------------------------------------------------------
// Module      : HDL Top
// Description : Has a interface master and slave agent bfm with advanced control features:
//               - Independent reset control per master/slave interface
//               - Dynamic clock frequency scaling
//               - Clock gating support
//               - Backward compatibility with legacy tests
//
// USAGE GUIDE:
//
// 1. INDEPENDENT RESET CONTROL:
//    Each master and slave interface can be reset independently while others continue operating.
//    
//    To reset a specific master (e.g., Master 0):
//      uvm_config_db#(int)::set(null, "*", "reset_duration_master_0", 5);  // 5 clock cycles
//      uvm_config_db#(bit)::set(null, "*", "inject_reset_master_0", 1);
//    
//    To reset a specific slave (e.g., Slave 2):
//      uvm_config_db#(int)::set(null, "*", "reset_duration_slave_2", 3);   // 3 clock cycles
//      uvm_config_db#(bit)::set(null, "*", "inject_reset_slave_2", 1);
//    
//    Multiple interfaces can be reset simultaneously - they operate independently.
//
// 2. GLOBAL RESET (affects all interfaces):
//      uvm_config_db#(int)::set(null, "*", "global_reset_duration_cycles", 5);
//      uvm_config_db#(bit)::set(null, "*", "inject_global_reset", 1);
//
// 3. LEGACY RESET (backward compatibility - resets global signal):
//      uvm_config_db#(int)::set(null, "*", "reset_duration_cycles", 5);
//      uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);
//
// 4. DYNAMIC CLOCK FREQUENCY CONTROL:
//    Change clock frequency during simulation (0.5x to 3x of base 100MHz):
//      uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 2.0);      // 200MHz (2x)
//      uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
//    
//    Examples:
//      clk_freq_scale = 0.5  -> 50MHz  (20ns period)
//      clk_freq_scale = 1.0  -> 100MHz (10ns period) [default]
//      clk_freq_scale = 2.0  -> 200MHz (5ns period)
//      clk_freq_scale = 3.0  -> 300MHz (3.33ns period)
//
// 5. CLOCK GATING:
//    Stop/start clock without losing state:
//      uvm_config_db#(bit)::set(null, "*", "clk_enable", 0);  // Stop clock
//      uvm_config_db#(bit)::set(null, "*", "clk_enable", 1);  // Start clock
//
// IMPLEMENTATION NOTES:
// - Independent resets use a wire-based mux design to avoid procedural conflicts
// - When not independently controlled, interfaces follow global aresetn signal
// - After independent reset completes, control returns to global reset
// - All features are backward compatible - existing tests work without modification
//
// EXAMPLE TEST CODE:
//
// class my_test extends axi4_base_test;
//   task run_phase(uvm_phase phase);
//     phase.raise_objection(this);
//     
//     // Example 1: Reset only Master 0 while others continue
//     uvm_config_db#(int)::set(null, "*", "reset_duration_master_0", 5);
//     uvm_config_db#(bit)::set(null, "*", "inject_reset_master_0", 1);
//     #100ns;
//     
//     // Example 2: Change clock frequency to 200MHz
//     uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 2.0);
//     uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
//     #100ns;
//     
//     // Example 3: Reset multiple interfaces simultaneously
//     fork
//       begin
//         uvm_config_db#(int)::set(null, "*", "reset_duration_master_1", 3);
//         uvm_config_db#(bit)::set(null, "*", "inject_reset_master_1", 1);
//       end
//       begin
//         uvm_config_db#(int)::set(null, "*", "reset_duration_slave_0", 4);
//         uvm_config_db#(bit)::set(null, "*", "inject_reset_slave_0", 1);
//       end
//     join
//     #100ns;
//     
//     // Example 4: Clock gating
//     uvm_config_db#(bit)::set(null, "*", "clk_enable", 0);  // Stop clock
//     #50ns;
//     uvm_config_db#(bit)::set(null, "*", "clk_enable", 1);  // Restart clock
//     
//     phase.drop_objection(this);
//   endtask
// endclass
//--------------------------------------------------------------------------------------------

module hdl_top;

  import uvm_pkg::*;
  import axi4_globals_pkg::*;
  `include "uvm_macros.svh"

  //-------------------------------------------------------
  // Clock Reset Initialization
  //-------------------------------------------------------
  bit aclk;
  bit aresetn;

  //-------------------------------------------------------
  // Display statement for HDL_TOP
  //-------------------------------------------------------
  initial begin
    $display("HDL_TOP");
  end

  //-------------------------------------------------------
  // Clock Control Variables for Dynamic Frequency Changes
  // Usage: Set clk_freq_scale via config_db to change frequency
  //        Set clk_enable to 0 to gate (stop) the clock
  //-------------------------------------------------------
  real clk_period = 10.0;  // Default 10ns (100MHz)
  real clk_freq_scale = 1.0;  // Frequency scaling factor (0.5 to 3.0)
  real prev_clk_freq_scale = 1.0;  // Previous scale to detect changes
  bit clk_freq_change_active = 0;  // Set to 1 to trigger frequency change
  bit clk_enable = 1;  // Clock gating control (0=stopped, 1=running)
  int clk_change_count = 0;  // Count frequency changes for debug
  
  //-------------------------------------------------------
  // System Clock Generation with Dynamic Frequency Control
  //-------------------------------------------------------
  initial begin
    aclk = 1'b0;
    
    forever begin
      // Check for frequency change requests
      if(!uvm_config_db#(bit)::get(null, "*", "clk_freq_change_active", clk_freq_change_active))
        clk_freq_change_active = 0;
        
      if(clk_freq_change_active) begin
        // Get the new frequency scale factor
        if(!uvm_config_db#(real)::get(null, "*", "clk_freq_scale", clk_freq_scale))
          clk_freq_scale = 1.0;
          
        // Only update and print if frequency actually changed
        if(clk_freq_scale != prev_clk_freq_scale) begin
          // Calculate new clock period
          clk_period = 10.0 / clk_freq_scale;  // Base is 10ns (100MHz)
          clk_change_count++;
          
          `uvm_info("HDL_TOP", $sformatf("Clock frequency change #%0d: scale=%.2fx, new_period=%.2fns (%.2fMHz)", 
                    clk_change_count, clk_freq_scale, clk_period, 1000.0/(clk_period*2)), UVM_LOW)
          
          prev_clk_freq_scale = clk_freq_scale;
        end
      end
      
      // Check for clock gating
      if(!uvm_config_db#(bit)::get(null, "*", "clk_enable", clk_enable))
        clk_enable = 1;
      
      // Generate clock with current period
      if(clk_enable) begin
        #(clk_period) aclk = ~aclk;
      end else begin
        // Clock gated - hold current value
        #(clk_period);
      end
    end
  end
  
  //-------------------------------------------------------
  // Clock Period Monitor for Verification
  //-------------------------------------------------------
  initial begin
    time prev_edge = 0;
    time curr_edge = 0;
    real actual_period;
    int edge_count = 0;
    
    // Wait for first few edges to stabilize
    repeat(5) @(posedge aclk);
    
    forever begin
      @(posedge aclk);
      curr_edge = $time;
      
      if(prev_edge != 0) begin
        actual_period = real'(curr_edge - prev_edge);
        edge_count++;
        
        // Print every 1000th edge or when frequency changes
        if(edge_count % 1000 == 1 || clk_freq_change_active) begin
          `uvm_info("CLK_VERIFY", $sformatf("Actual clock period measured on aclk: %.2f ns (%.2f MHz) at time %0t", 
                    actual_period, 1000.0/actual_period, $time), UVM_HIGH)
        end
      end
      
      prev_edge = curr_edge;
    end
  end
//`ifdef DUMP_FSDB
//        initial begin
//            string fsdb_filename;
//        
//            // ? +fsdbfile=my_dump.fsdb
//            if (!$value$plusargs("fsdbfile=%s", fsdb_filename)) begin
//                fsdb_filename = "default.fsdb"; // if no used for default.fsdb
//            end
//        
//            $fsdbDumpfile(fsdb_filename);  // 
//            $fsdbDumpvars(0, hvl_top);   //
////            $fsdbDumpvars(" uvm_test_top.axi4_env_h.axi4_master_agent_h[0]", "+class","+object_level=5");   //
//
//        end
//`endif


  //-------------------------------------------------------
  // System Reset Generation
  // Active low reset with injection support
  // Supports both global and independent per-interface resets
  //-------------------------------------------------------
  bit inject_reset = 0;                          // Legacy reset trigger (backward compatible)
  bit inject_global_reset = 0;                   // Global reset trigger (all interfaces)
  int reset_duration_cycles = 1;                 // Duration for legacy reset
  int global_reset_duration_cycles = 1;          // Duration for global reset
  int reset_count = 0;                           // Track number of resets for debug
  
  // Independent reset control for each master and slave
  // These allow individual interfaces to be reset while others continue operating
  bit aresetn_master_override[NO_OF_MASTERS];    // Override value when using independent reset
  bit aresetn_slave_override[NO_OF_SLAVES];      // Override value when using independent reset
  bit inject_reset_master[NO_OF_MASTERS];        // Trigger for individual master reset
  bit inject_reset_slave[NO_OF_SLAVES];          // Trigger for individual slave reset
  int reset_duration_master[NO_OF_MASTERS];      // Duration for each master reset
  int reset_duration_slave[NO_OF_SLAVES];        // Duration for each slave reset
  
  // Arrays to track which interfaces need reset (used to avoid automatic variable issue)
  bit masters_to_reset[NO_OF_MASTERS];
  int master_durations[NO_OF_MASTERS];
  bit slaves_to_reset[NO_OF_SLAVES];
  int slave_durations[NO_OF_SLAVES];
  
  // Flags to track if independent reset is being used
  // When 0, interface follows global aresetn; when 1, uses override value
  bit independent_reset_active_master[NO_OF_MASTERS];
  bit independent_reset_active_slave[NO_OF_SLAVES];
  
  // Actual reset signals for interfaces - use override when independent, otherwise global
  // These are wires that automatically select between global and independent reset
  wire aresetn_master[NO_OF_MASTERS];
  wire aresetn_slave[NO_OF_SLAVES];
  
  // Conditional assignment for backward compatibility
  // This MUX design ensures no procedural conflicts and automatic fallback to global reset
  genvar rst_idx;
  generate
    for (rst_idx = 0; rst_idx < NO_OF_MASTERS; rst_idx++) begin : master_reset_mux
      assign aresetn_master[rst_idx] = independent_reset_active_master[rst_idx] ? 
                                        aresetn_master_override[rst_idx] : aresetn;
    end
    for (rst_idx = 0; rst_idx < NO_OF_SLAVES; rst_idx++) begin : slave_reset_mux
      assign aresetn_slave[rst_idx] = independent_reset_active_slave[rst_idx] ? 
                                       aresetn_slave_override[rst_idx] : aresetn;
    end
  endgenerate
  
  // Initialize independent resets
  initial begin
    // Initialize flags - no interface is using independent reset initially
    for(int i = 0; i < NO_OF_MASTERS; i++) begin
      independent_reset_active_master[i] = 1'b0;
    end
    for(int i = 0; i < NO_OF_SLAVES; i++) begin
      independent_reset_active_slave[i] = 1'b0;
    end
    
    // Initial global reset - individual resets will follow via always_comb
    aresetn = 1'b1;
    #10 aresetn = 1'b0;

    repeat (1) begin
      @(posedge aclk);
    end
    
    aresetn = 1'b1;
    
    `uvm_info("HDL_TOP", "Initial reset completed, monitoring for injection requests", UVM_LOW)
    
    // Monitor for reset injection requests
    forever begin
      @(posedge aclk);
      
      // Check for global reset injection
      if(!uvm_config_db#(bit)::get(null, "*", "inject_global_reset", inject_global_reset))
        inject_global_reset = 0;
        
      if(inject_global_reset) begin
        reset_count++;
        
        // Get global reset duration
        if(!uvm_config_db#(int)::get(null, "*", "global_reset_duration_cycles", global_reset_duration_cycles))
          global_reset_duration_cycles = 1;
          
        `uvm_info("HDL_TOP", $sformatf("Global Reset #%0d: Injecting reset for %0d cycles", reset_count, global_reset_duration_cycles), UVM_LOW)
        
        // Assert global reset (active low) - individual resets will follow via always_comb
        aresetn = 1'b0;
        
        // Hold for specified duration
        repeat(global_reset_duration_cycles) @(posedge aclk);
        
        // Deassert global reset
        aresetn = 1'b1;
        
        // Clear injection flag
        uvm_config_db#(bit)::set(null, "*", "inject_global_reset", 0);
        
        `uvm_info("HDL_TOP", $sformatf("Global Reset #%0d completed", reset_count), UVM_LOW)
        
        // Small delay to prevent immediate re-triggering
        repeat(2) @(posedge aclk);
      end
      
      // Check for legacy reset injection (backward compatibility - resets global signal)
      if(!uvm_config_db#(bit)::get(null, "*", "inject_reset", inject_reset))
        inject_reset = 0;
        
      if(inject_reset) begin
        reset_count++;
        
        // Get reset duration
        if(!uvm_config_db#(int)::get(null, "*", "reset_duration_cycles", reset_duration_cycles))
          reset_duration_cycles = 1;
          
        `uvm_info("HDL_TOP", $sformatf("Legacy Reset #%0d: Injecting reset for %0d cycles", reset_count, reset_duration_cycles), UVM_LOW)
        
        // Assert global reset (active low) - individual resets will follow via always_comb
        aresetn = 1'b0;
        
        // Hold for specified duration
        repeat(reset_duration_cycles) @(posedge aclk);
        
        // Deassert global reset
        aresetn = 1'b1;
        
        // Clear injection flag
        uvm_config_db#(bit)::set(null, "*", "inject_reset", 0);
        
        // Set completion flag for reset checker
        uvm_config_db#(bit)::set(null, "*", "reset_complete_global", 1);
        
        `uvm_info("HDL_TOP", $sformatf("Legacy Reset #%0d completed", reset_count), UVM_LOW)
        
        // Small delay to prevent immediate re-triggering
        repeat(2) @(posedge aclk);
      end
      
      // Check for individual master reset injections
      // First pass: collect which masters need reset
      for(int i = 0; i < NO_OF_MASTERS; i++) begin
        if(!uvm_config_db#(bit)::get(null, "*", $sformatf("inject_reset_master_%0d", i), inject_reset_master[i]))
          inject_reset_master[i] = 0;
          
        if(inject_reset_master[i]) begin
          masters_to_reset[i] = 1;
          
          // Clear the injection flag immediately to prevent re-triggering
          inject_reset_master[i] = 0;
          uvm_config_db#(bit)::set(null, "*", $sformatf("inject_reset_master_%0d", i), 0);
          
          // Get reset duration for this master
          if(!uvm_config_db#(int)::get(null, "*", $sformatf("reset_duration_master_%0d", i), reset_duration_master[i]))
            reset_duration_master[i] = 1;
          master_durations[i] = reset_duration_master[i];
            
          `uvm_info("HDL_TOP", $sformatf("Master[%0d] Reset: Injecting reset for %0d cycles", i, reset_duration_master[i]), UVM_LOW)
          
          // Mark this master as using independent reset
          independent_reset_active_master[i] = 1'b1;
          
          // Assert reset for this master (active low)
          aresetn_master_override[i] = 1'b0;
        end else begin
          masters_to_reset[i] = 0;
        end
      end
      
      // Second pass: fork reset handlers with correct indices
      for(int j = 0; j < NO_OF_MASTERS; j++) begin
        if(masters_to_reset[j]) begin
          // Fork to handle this reset independently
          // Use automatic variable to capture the correct index
          automatic int master_idx = j;
          automatic int duration = master_durations[j];
          
          fork
            begin
              // Hold for specified duration
              repeat(duration) @(posedge aclk);
              
              // Deassert reset
              aresetn_master_override[master_idx] = 1'b1;
              
              // Return control to global reset
              independent_reset_active_master[master_idx] = 1'b0;
              
              // Set completion flag for reset checker
              uvm_config_db#(bit)::set(null, "*", $sformatf("reset_complete_master_%0d", master_idx), 1);
              
              `uvm_info("HDL_TOP", $sformatf("Master[%0d] Reset completed", master_idx), UVM_LOW)
            end
          join_none
        end
      end
      
      // Check for individual slave reset injections
      // First pass: collect which slaves need reset
      for(int i = 0; i < NO_OF_SLAVES; i++) begin
        if(!uvm_config_db#(bit)::get(null, "*", $sformatf("inject_reset_slave_%0d", i), inject_reset_slave[i]))
          inject_reset_slave[i] = 0;
          
        if(inject_reset_slave[i]) begin
          slaves_to_reset[i] = 1;
          
          // Clear the injection flag immediately to prevent re-triggering
          inject_reset_slave[i] = 0;
          uvm_config_db#(bit)::set(null, "*", $sformatf("inject_reset_slave_%0d", i), 0);
          
          // Get reset duration for this slave
          if(!uvm_config_db#(int)::get(null, "*", $sformatf("reset_duration_slave_%0d", i), reset_duration_slave[i]))
            reset_duration_slave[i] = 1;
          slave_durations[i] = reset_duration_slave[i];
            
          `uvm_info("HDL_TOP", $sformatf("Slave[%0d] Reset: Injecting reset for %0d cycles", i, reset_duration_slave[i]), UVM_LOW)
          
          // Mark this slave as using independent reset
          independent_reset_active_slave[i] = 1'b1;
          
          // Assert reset for this slave (active low)
          aresetn_slave_override[i] = 1'b0;
        end else begin
          slaves_to_reset[i] = 0;
        end
      end
      
      // Second pass: fork reset handlers with correct indices
      for(int j = 0; j < NO_OF_SLAVES; j++) begin
        if(slaves_to_reset[j]) begin
          // Fork to handle this reset independently
          // Use automatic variable to capture the correct index
          automatic int slave_idx = j;
          automatic int duration = slave_durations[j];
          
          fork
            begin
              // Hold for specified duration
              repeat(duration) @(posedge aclk);
              
              // Deassert reset
              aresetn_slave_override[slave_idx] = 1'b1;
              
              // Return control to global reset
              independent_reset_active_slave[slave_idx] = 1'b0;
              
              // Set completion flag for reset checker
              uvm_config_db#(bit)::set(null, "*", $sformatf("reset_complete_slave_%0d", slave_idx), 1);
              
              `uvm_info("HDL_TOP", $sformatf("Slave[%0d] Reset completed", slave_idx), UVM_LOW)
            end
          join_none
        end
      end
    end
  end

  //-------------------------------------------------------
  // AXI4 Interface Instantiation with Independent Reset Control
  // 
  // ARCHITECTURE:
  // - Each master interface has its own reset signal (aresetn_master[i])
  // - Each slave interface has its own reset signal (aresetn_slave[i])
  // - Resets can be controlled independently or follow global aresetn
  //
  // CONFIGURATION:
  // HDL always creates maximum interfaces (10x10) for flexibility
  // HVL dynamically uses only required interfaces based on test configuration:
  // - Enhanced matrix tests (TC01-TC05): Use all 10 masters/10 slaves
  // - Boundary tests (TC046-TC058): Use only 4 masters/4 slaves
  // - Default tests: Use only 4 masters/4 slaves
  // This approach avoids recompilation between different test configurations
  //-------------------------------------------------------
  genvar rst_i;
  generate
    for (rst_i = 0; rst_i < NO_OF_MASTERS; rst_i++) begin : master_if_gen
      axi4_if master_intf (.aclk(aclk),
                          .aresetn(aresetn_master[rst_i]));
    end
    for (rst_i = 0; rst_i < NO_OF_SLAVES; rst_i++) begin : slave_if_gen
      axi4_if slave_intf (.aclk(aclk),
                         .aresetn(aresetn_slave[rst_i]));
    end
  endgenerate

  //-------------------------------------------------------
  // AXI4  No of Master and Slaves Agent Instantiation
  //-------------------------------------------------------
  genvar i;
  generate
    for (i=0; i<NO_OF_MASTERS; i++) begin : axi4_master_agent_bfm
      axi4_master_agent_bfm #(.MASTER_ID(i))
        axi4_master_agent_bfm_h(master_if_gen[i].master_intf);
      defparam axi4_master_agent_bfm[i].axi4_master_agent_bfm_h.MASTER_ID = i;
    end
    for (i=0; i<NO_OF_SLAVES; i++) begin : axi4_slave_agent_bfm
      axi4_slave_agent_bfm #(.SLAVE_ID(i))
        axi4_slave_agent_bfm_h(slave_if_gen[i].slave_intf);
      defparam axi4_slave_agent_bfm[i].axi4_slave_agent_bfm_h.SLAVE_ID = i;
    end
  endgenerate
  //-------------------------------------------------------------------------
  // Simple direct connection between each master and slave interface instance
  //-------------------------------------------------------------------------
  genvar j;
  generate
    for (j = 0; j < NO_OF_MASTERS && j < NO_OF_SLAVES; j++) begin : axi4_connect
      // Write Address Channel
      assign slave_if_gen[j].slave_intf.awid     = master_if_gen[j].master_intf.awid;
      assign slave_if_gen[j].slave_intf.awaddr   = master_if_gen[j].master_intf.awaddr;
      assign slave_if_gen[j].slave_intf.awlen    = master_if_gen[j].master_intf.awlen;
      assign slave_if_gen[j].slave_intf.awsize   = master_if_gen[j].master_intf.awsize;
      assign slave_if_gen[j].slave_intf.awburst  = master_if_gen[j].master_intf.awburst;
      assign slave_if_gen[j].slave_intf.awlock   = master_if_gen[j].master_intf.awlock;
      assign slave_if_gen[j].slave_intf.awcache  = master_if_gen[j].master_intf.awcache;
      assign slave_if_gen[j].slave_intf.awprot   = master_if_gen[j].master_intf.awprot;
      assign slave_if_gen[j].slave_intf.awqos    = master_if_gen[j].master_intf.awqos;
      assign slave_if_gen[j].slave_intf.awregion = master_if_gen[j].master_intf.awregion;
      assign slave_if_gen[j].slave_intf.awuser   = master_if_gen[j].master_intf.awuser;
      assign slave_if_gen[j].slave_intf.awvalid  = master_if_gen[j].master_intf.awvalid;
      assign master_if_gen[j].master_intf.awready = slave_if_gen[j].slave_intf.awready;

      // Write Data Channel
      assign slave_if_gen[j].slave_intf.wdata    = master_if_gen[j].master_intf.wdata;
      assign slave_if_gen[j].slave_intf.wstrb    = master_if_gen[j].master_intf.wstrb;
      assign slave_if_gen[j].slave_intf.wlast    = master_if_gen[j].master_intf.wlast;
      assign slave_if_gen[j].slave_intf.wuser    = master_if_gen[j].master_intf.wuser;
      assign slave_if_gen[j].slave_intf.wvalid   = master_if_gen[j].master_intf.wvalid;
      assign master_if_gen[j].master_intf.wready  = slave_if_gen[j].slave_intf.wready;

      // Write Response Channel
      assign master_if_gen[j].master_intf.bid     = slave_if_gen[j].slave_intf.bid;
      assign master_if_gen[j].master_intf.bresp   = slave_if_gen[j].slave_intf.bresp;
      assign master_if_gen[j].master_intf.buser   = slave_if_gen[j].slave_intf.buser;
      assign master_if_gen[j].master_intf.bvalid  = slave_if_gen[j].slave_intf.bvalid;
      assign slave_if_gen[j].slave_intf.bready   = master_if_gen[j].master_intf.bready;

      // Read Address Channel
      assign slave_if_gen[j].slave_intf.arid     = master_if_gen[j].master_intf.arid;
      assign slave_if_gen[j].slave_intf.araddr   = master_if_gen[j].master_intf.araddr;
      assign slave_if_gen[j].slave_intf.arlen    = master_if_gen[j].master_intf.arlen;
      assign slave_if_gen[j].slave_intf.arsize   = master_if_gen[j].master_intf.arsize;
      assign slave_if_gen[j].slave_intf.arburst  = master_if_gen[j].master_intf.arburst;
      assign slave_if_gen[j].slave_intf.arlock   = master_if_gen[j].master_intf.arlock;
      assign slave_if_gen[j].slave_intf.arcache  = master_if_gen[j].master_intf.arcache;
      assign slave_if_gen[j].slave_intf.arprot   = master_if_gen[j].master_intf.arprot;
      assign slave_if_gen[j].slave_intf.arqos    = master_if_gen[j].master_intf.arqos;
      assign slave_if_gen[j].slave_intf.arregion = master_if_gen[j].master_intf.arregion;
      assign slave_if_gen[j].slave_intf.aruser   = master_if_gen[j].master_intf.aruser;
      assign slave_if_gen[j].slave_intf.arvalid  = master_if_gen[j].master_intf.arvalid;
      assign master_if_gen[j].master_intf.arready = slave_if_gen[j].slave_intf.arready;

      // Read Data Channel
      assign master_if_gen[j].master_intf.rid     = slave_if_gen[j].slave_intf.rid;
      assign master_if_gen[j].master_intf.rdata   = slave_if_gen[j].slave_intf.rdata;
      assign master_if_gen[j].master_intf.rresp   = slave_if_gen[j].slave_intf.rresp;
      assign master_if_gen[j].master_intf.rlast   = slave_if_gen[j].slave_intf.rlast;
      assign master_if_gen[j].master_intf.ruser   = slave_if_gen[j].slave_intf.ruser;
      assign master_if_gen[j].master_intf.rvalid  = slave_if_gen[j].slave_intf.rvalid;
      assign slave_if_gen[j].slave_intf.rready   = master_if_gen[j].master_intf.rready;
    end
  endgenerate 
  //-------------------------------------------------------
  // Reset Signal Monitor Instance
  // Monitors and verifies all reset signal transitions
  //-------------------------------------------------------
  // Reset monitoring is now integrated into master and slave monitor BFMs
  
endmodule : hdl_top

`endif

