`include "axi4_bus_config.svh"
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
`ifdef DUMP_FSDB
  // Re-enabled. Was commented out, and dumped only hvl_top -- the AXI pins live
  // in hdl_top, so a waveform taken with it could not answer any question about
  // WVALID/WREADY/WLAST timing. Dumping hdl_top is what makes signal-level debug
  // of the channel handshakes possible at all.
  initial begin
    string fsdb_filename;
    if (!$value$plusargs("fsdbfile=%s", fsdb_filename)) begin
      fsdb_filename = "default.fsdb";
    end
    $fsdbDumpfile(fsdb_filename);
    $fsdbDumpvars(0, hdl_top);
  end
`endif


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
  
  // AXI_ID_LAST is a hand-written literal because VCS will not take a computed
  // enum name range. Catch the two defines drifting apart here rather than
  // letting $cast silently drop out-of-range transaction IDs at run time.
  initial begin
    if (((1 << `AXI_ID_WIDTH) - 1) != `AXI_ID_LAST) begin
      $fatal(1, "AXI_ID_LAST is %0d but AXI_ID_WIDTH=%0d requires %0d -- set both (see include/axi4_bus_config.svh)",
             `AXI_ID_LAST, `AXI_ID_WIDTH, (1 << `AXI_ID_WIDTH) - 1);
    end
  end

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

`ifdef BUS_MATRIX_NIC400
    // The 1:1 direct wiring is stateless, so a single-edge reset is enough for
    // it. Real RTL is not: the NIC-400 fabric has arbiters, outstanding-
    // transaction FIFOs and clock-domain structures that need several cycles of
    // asserted reset to leave X. With the original single edge the fabric came
    // out of reset with X internal state, its egress AxVALID stayed X forever,
    // and reads were accepted at the ingress but never issued downstream.
    repeat (16) begin
      @(posedge aclk);
    end
`else
    repeat (1) begin
      @(posedge aclk);
    end
`endif

    aresetn = 1'b1;

`ifdef BUS_MATRIX_NIC400
    // Give the fabric a few idle cycles after release before traffic starts.
    repeat (8) @(posedge aclk);
`endif
    
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
  // Track-B DUT: ARM CoreLink NIC-400 arbitrated AXI4 fabric
  //
  // Compile with +define+BUS_MATRIX_NIC400 (plus +define+DATA_WIDTH=256 and
  // +define+AXI_ID_WIDTH=8 +define+AXI_ID_LAST=255) to route every master through a real crossbar
  // with arbitration, instead of the 1:1 direct wiring below. Only then are
  // cyclic-dependency deadlock, same-ID head-of-line blocking and hotspot
  // arbitration fairness physically reachable.
  //
  // Fabric: ext/nic400_vipv3b (10 ingress x 10 egress, QoS from_master).
  // GENERATED connection block -- see scratchpad/gen_hdltop_block.py
  //-------------------------------------------------------------------------
`ifdef BUS_MATRIX_NIC400

  // ---- ingress vectors: VIP master agents -> fabric AXI4_Slave<N> ----
  // NOTE: sized by `NIC400_PORTS (4 under NIC400_4X4, else 10), NOT by
  // NO_OF_MASTERS/NO_OF_SLAVES -- those are the VIP-wide agent count, gated
  // by the unrelated RUN_4X4_CONFIG knob, and stay 10 in a Track-B 4x4 build
  // (BUS_MATRIX_NIC400 + NIC400_4X4). Using NO_OF_MASTERS/NO_OF_SLAVES here
  // silently over-sized these vectors 10-wide against the wrapper's 4-wide
  // ports -> VCS Warning-[PCWM-W] port width mismatch on every signal.
  logic [`NIC400_PORTS-1:0][63:0] nic_m_araddr;
  logic [`NIC400_PORTS-1:0][1:0] nic_m_arburst;
  logic [`NIC400_PORTS-1:0][3:0] nic_m_arcache;
  logic [`NIC400_PORTS-1:0][3:0] nic_m_arid;
  logic [`NIC400_PORTS-1:0][7:0] nic_m_arlen;
  logic [`NIC400_PORTS-1:0]      nic_m_arlock;
  logic [`NIC400_PORTS-1:0][2:0] nic_m_arprot;
  logic [`NIC400_PORTS-1:0][3:0] nic_m_arqos;
  logic [`NIC400_PORTS-1:0]      nic_m_arready;
  logic [`NIC400_PORTS-1:0][3:0] nic_m_arregion;
  logic [`NIC400_PORTS-1:0][2:0] nic_m_arsize;
  logic [`NIC400_PORTS-1:0][31:0] nic_m_aruser;
  logic [`NIC400_PORTS-1:0]      nic_m_arvalid;
  logic [`NIC400_PORTS-1:0][63:0] nic_m_awaddr;
  logic [`NIC400_PORTS-1:0][1:0] nic_m_awburst;
  logic [`NIC400_PORTS-1:0][3:0] nic_m_awcache;
  logic [`NIC400_PORTS-1:0][3:0] nic_m_awid;
  logic [`NIC400_PORTS-1:0][7:0] nic_m_awlen;
  logic [`NIC400_PORTS-1:0]      nic_m_awlock;
  logic [`NIC400_PORTS-1:0][2:0] nic_m_awprot;
  logic [`NIC400_PORTS-1:0][3:0] nic_m_awqos;
  logic [`NIC400_PORTS-1:0]      nic_m_awready;
  logic [`NIC400_PORTS-1:0][3:0] nic_m_awregion;
  logic [`NIC400_PORTS-1:0][2:0] nic_m_awsize;
  logic [`NIC400_PORTS-1:0][31:0] nic_m_awuser;
  logic [`NIC400_PORTS-1:0]      nic_m_awvalid;
  logic [`NIC400_PORTS-1:0][3:0] nic_m_bid;
  logic [`NIC400_PORTS-1:0]      nic_m_bready;
  logic [`NIC400_PORTS-1:0][1:0] nic_m_bresp;
  logic [`NIC400_PORTS-1:0][15:0] nic_m_buser;
  logic [`NIC400_PORTS-1:0]      nic_m_bvalid;
  logic [`NIC400_PORTS-1:0][255:0] nic_m_rdata;
  logic [`NIC400_PORTS-1:0][3:0] nic_m_rid;
  logic [`NIC400_PORTS-1:0]      nic_m_rlast;
  logic [`NIC400_PORTS-1:0]      nic_m_rready;
  logic [`NIC400_PORTS-1:0][1:0] nic_m_rresp;
  logic [`NIC400_PORTS-1:0][15:0] nic_m_ruser;
  logic [`NIC400_PORTS-1:0]      nic_m_rvalid;
  logic [`NIC400_PORTS-1:0][255:0] nic_m_wdata;
  logic [`NIC400_PORTS-1:0]      nic_m_wlast;
  logic [`NIC400_PORTS-1:0]      nic_m_wready;
  logic [`NIC400_PORTS-1:0][31:0] nic_m_wstrb;
  logic [`NIC400_PORTS-1:0][31:0] nic_m_wuser;
  logic [`NIC400_PORTS-1:0]      nic_m_wvalid;

  // ---- egress vectors: fabric AXI4_Master<N> -> VIP slave agents ----
  logic [`NIC400_PORTS-1:0][63:0] nic_s_araddr;
  logic [`NIC400_PORTS-1:0][1:0] nic_s_arburst;
  logic [`NIC400_PORTS-1:0][3:0] nic_s_arcache;
  logic [`NIC400_PORTS-1:0][`NIC400_EGRESS_ID_WIDTH-1:0] nic_s_arid;
  logic [`NIC400_PORTS-1:0][7:0] nic_s_arlen;
  logic [`NIC400_PORTS-1:0]      nic_s_arlock;
  logic [`NIC400_PORTS-1:0][2:0] nic_s_arprot;
  logic [`NIC400_PORTS-1:0]      nic_s_arready;
  logic [`NIC400_PORTS-1:0][3:0] nic_s_arregion;
  logic [`NIC400_PORTS-1:0][2:0] nic_s_arsize;
  logic [`NIC400_PORTS-1:0][31:0] nic_s_aruser;
  logic [`NIC400_PORTS-1:0]      nic_s_arvalid;
  logic [`NIC400_PORTS-1:0][63:0] nic_s_awaddr;
  logic [`NIC400_PORTS-1:0][1:0] nic_s_awburst;
  logic [`NIC400_PORTS-1:0][3:0] nic_s_awcache;
  logic [`NIC400_PORTS-1:0][`NIC400_EGRESS_ID_WIDTH-1:0] nic_s_awid;
  logic [`NIC400_PORTS-1:0][7:0] nic_s_awlen;
  logic [`NIC400_PORTS-1:0]      nic_s_awlock;
  logic [`NIC400_PORTS-1:0][2:0] nic_s_awprot;
  logic [`NIC400_PORTS-1:0]      nic_s_awready;
  logic [`NIC400_PORTS-1:0][3:0] nic_s_awregion;
  logic [`NIC400_PORTS-1:0][2:0] nic_s_awsize;
  logic [`NIC400_PORTS-1:0][31:0] nic_s_awuser;
  logic [`NIC400_PORTS-1:0]      nic_s_awvalid;
  logic [`NIC400_PORTS-1:0][`NIC400_EGRESS_ID_WIDTH-1:0] nic_s_bid;
  logic [`NIC400_PORTS-1:0]      nic_s_bready;
  logic [`NIC400_PORTS-1:0][1:0] nic_s_bresp;
  logic [`NIC400_PORTS-1:0][15:0] nic_s_buser;
  logic [`NIC400_PORTS-1:0]      nic_s_bvalid;
  logic [`NIC400_PORTS-1:0][255:0] nic_s_rdata;
  logic [`NIC400_PORTS-1:0][`NIC400_EGRESS_ID_WIDTH-1:0] nic_s_rid;
  logic [`NIC400_PORTS-1:0]      nic_s_rlast;
  logic [`NIC400_PORTS-1:0]      nic_s_rready;
  logic [`NIC400_PORTS-1:0][1:0] nic_s_rresp;
  logic [`NIC400_PORTS-1:0][15:0] nic_s_ruser;
  logic [`NIC400_PORTS-1:0]      nic_s_rvalid;
  logic [`NIC400_PORTS-1:0][255:0] nic_s_wdata;
  logic [`NIC400_PORTS-1:0]      nic_s_wlast;
  logic [`NIC400_PORTS-1:0]      nic_s_wready;
  logic [`NIC400_PORTS-1:0][31:0] nic_s_wstrb;
  logic [`NIC400_PORTS-1:0][31:0] nic_s_wuser;
  logic [`NIC400_PORTS-1:0]      nic_s_wvalid;

  genvar jn;
  generate
    // Only the ports this fabric actually has are wired; the rest of the VIP's
    // agents stay on their idle defaults.
    for (jn = 0; jn < `NIC400_PORTS; jn++) begin : nic_ingress_connect
      // VIP master drives the fabric ingress
      assign nic_m_araddr[jn] = master_if_gen[jn].master_intf.araddr;
      assign nic_m_arburst[jn] = master_if_gen[jn].master_intf.arburst;
      assign nic_m_arcache[jn] = master_if_gen[jn].master_intf.arcache;
      assign nic_m_arid[jn] = master_if_gen[jn].master_intf.arid[3:0]; // fabric ingress AxID is 4b (VIDWidth)
      assign nic_m_arlen[jn] = master_if_gen[jn].master_intf.arlen;
      assign nic_m_arlock[jn] = master_if_gen[jn].master_intf.arlock[0];   // VIP awlock/arlock is AXI3-style [1:0]
      assign nic_m_arprot[jn] = master_if_gen[jn].master_intf.arprot;
      assign nic_m_arqos[jn] = master_if_gen[jn].master_intf.arqos;
      assign master_if_gen[jn].master_intf.arready = nic_m_arready[jn];
      assign nic_m_arregion[jn] = master_if_gen[jn].master_intf.arregion;
      assign nic_m_arsize[jn] = master_if_gen[jn].master_intf.arsize;
      assign nic_m_aruser[jn] = master_if_gen[jn].master_intf.aruser;
      // X-safe: an uninitialised VIP master interface drives X, and the VIP's own
      // slave BFM tolerates that (it waits with `=== 0`). Real RTL does not: X on a
      // VALID/READY input poisons the fabric arbiters and no egress request is ever
      // issued. Force X to 0 so the fabric only ever sees a clean handshake.
      assign nic_m_arvalid[jn] = (master_if_gen[jn].master_intf.arvalid === 1'b1);
      assign nic_m_awaddr[jn] = master_if_gen[jn].master_intf.awaddr;
      assign nic_m_awburst[jn] = master_if_gen[jn].master_intf.awburst;
      assign nic_m_awcache[jn] = master_if_gen[jn].master_intf.awcache;
      assign nic_m_awid[jn] = master_if_gen[jn].master_intf.awid[3:0]; // fabric ingress AxID is 4b (VIDWidth)
      assign nic_m_awlen[jn] = master_if_gen[jn].master_intf.awlen;
      assign nic_m_awlock[jn] = master_if_gen[jn].master_intf.awlock[0];   // VIP awlock/arlock is AXI3-style [1:0]
      assign nic_m_awprot[jn] = master_if_gen[jn].master_intf.awprot;
      assign nic_m_awqos[jn] = master_if_gen[jn].master_intf.awqos;
      assign master_if_gen[jn].master_intf.awready = nic_m_awready[jn];
      assign nic_m_awregion[jn] = master_if_gen[jn].master_intf.awregion;
      assign nic_m_awsize[jn] = master_if_gen[jn].master_intf.awsize;
      assign nic_m_awuser[jn] = master_if_gen[jn].master_intf.awuser;
      // X-safe: an uninitialised VIP master interface drives X, and the VIP's own
      // slave BFM tolerates that (it waits with `=== 0`). Real RTL does not: X on a
      // VALID/READY input poisons the fabric arbiters and no egress request is ever
      // issued. Force X to 0 so the fabric only ever sees a clean handshake.
      assign nic_m_awvalid[jn] = (master_if_gen[jn].master_intf.awvalid === 1'b1);
      assign master_if_gen[jn].master_intf.bid = {{(`AXI_ID_WIDTH-4){1'b0}}, nic_m_bid[jn]};
      // X-safe: an uninitialised VIP master interface drives X, and the VIP's own
      // slave BFM tolerates that (it waits with `=== 0`). Real RTL does not: X on a
      // VALID/READY input poisons the fabric arbiters and no egress request is ever
      // issued. Force X to 0 so the fabric only ever sees a clean handshake.
      assign nic_m_bready[jn] = (master_if_gen[jn].master_intf.bready === 1'b1);
      assign master_if_gen[jn].master_intf.bresp = nic_m_bresp[jn];
      assign master_if_gen[jn].master_intf.buser = nic_m_buser[jn];
      assign master_if_gen[jn].master_intf.bvalid = nic_m_bvalid[jn];
      assign master_if_gen[jn].master_intf.rdata = nic_m_rdata[jn];
      assign master_if_gen[jn].master_intf.rid = {{(`AXI_ID_WIDTH-4){1'b0}}, nic_m_rid[jn]};
      assign master_if_gen[jn].master_intf.rlast = nic_m_rlast[jn];
      // X-safe: an uninitialised VIP master interface drives X, and the VIP's own
      // slave BFM tolerates that (it waits with `=== 0`). Real RTL does not: X on a
      // VALID/READY input poisons the fabric arbiters and no egress request is ever
      // issued. Force X to 0 so the fabric only ever sees a clean handshake.
      assign nic_m_rready[jn] = (master_if_gen[jn].master_intf.rready === 1'b1);
      assign master_if_gen[jn].master_intf.rresp = nic_m_rresp[jn];
      assign master_if_gen[jn].master_intf.ruser = nic_m_ruser[jn];
      assign master_if_gen[jn].master_intf.rvalid = nic_m_rvalid[jn];
      assign nic_m_wdata[jn] = master_if_gen[jn].master_intf.wdata;
      // X-safe: an uninitialised VIP master interface drives X, and the VIP's own
      // slave BFM tolerates that (it waits with `=== 0`). Real RTL does not: X on a
      // VALID/READY input poisons the fabric arbiters and no egress request is ever
      // issued. Force X to 0 so the fabric only ever sees a clean handshake.
      assign nic_m_wlast[jn] = (master_if_gen[jn].master_intf.wlast === 1'b1);
      assign master_if_gen[jn].master_intf.wready = nic_m_wready[jn];
      assign nic_m_wstrb[jn] = master_if_gen[jn].master_intf.wstrb;
      assign nic_m_wuser[jn] = master_if_gen[jn].master_intf.wuser;
      // X-safe: an uninitialised VIP master interface drives X, and the VIP's own
      // slave BFM tolerates that (it waits with `=== 0`). Real RTL does not: X on a
      // VALID/READY input poisons the fabric arbiters and no egress request is ever
      // issued. Force X to 0 so the fabric only ever sees a clean handshake.
      assign nic_m_wvalid[jn] = (master_if_gen[jn].master_intf.wvalid === 1'b1);
    end

    for (jn = 0; jn < `NIC400_PORTS; jn++) begin : nic_egress_connect
      // fabric egress drives the VIP slave agent
      assign slave_if_gen[jn].slave_intf.araddr = nic_s_araddr[jn];
      assign slave_if_gen[jn].slave_intf.arburst = nic_s_arburst[jn];
      assign slave_if_gen[jn].slave_intf.arcache = nic_s_arcache[jn];
      assign slave_if_gen[jn].slave_intf.arid = nic_s_arid[jn];
      assign slave_if_gen[jn].slave_intf.arlen = nic_s_arlen[jn];
      assign slave_if_gen[jn].slave_intf.arlock = {1'b0, nic_s_arlock[jn]};
      assign slave_if_gen[jn].slave_intf.arprot = nic_s_arprot[jn];
      assign nic_s_arready[jn] = slave_if_gen[jn].slave_intf.arready;
      assign slave_if_gen[jn].slave_intf.arregion = nic_s_arregion[jn];
      assign slave_if_gen[jn].slave_intf.arsize = nic_s_arsize[jn];
      assign slave_if_gen[jn].slave_intf.aruser = nic_s_aruser[jn];
      assign slave_if_gen[jn].slave_intf.arvalid = nic_s_arvalid[jn];
      assign slave_if_gen[jn].slave_intf.awaddr = nic_s_awaddr[jn];
      assign slave_if_gen[jn].slave_intf.awburst = nic_s_awburst[jn];
      assign slave_if_gen[jn].slave_intf.awcache = nic_s_awcache[jn];
      assign slave_if_gen[jn].slave_intf.awid = nic_s_awid[jn];
      assign slave_if_gen[jn].slave_intf.awlen = nic_s_awlen[jn];
      assign slave_if_gen[jn].slave_intf.awlock = {1'b0, nic_s_awlock[jn]};
      assign slave_if_gen[jn].slave_intf.awprot = nic_s_awprot[jn];
      assign nic_s_awready[jn] = slave_if_gen[jn].slave_intf.awready;
      assign slave_if_gen[jn].slave_intf.awregion = nic_s_awregion[jn];
      assign slave_if_gen[jn].slave_intf.awsize = nic_s_awsize[jn];
      assign slave_if_gen[jn].slave_intf.awuser = nic_s_awuser[jn];
      assign slave_if_gen[jn].slave_intf.awvalid = nic_s_awvalid[jn];
      assign nic_s_bid[jn] = slave_if_gen[jn].slave_intf.bid;
      assign slave_if_gen[jn].slave_intf.bready = nic_s_bready[jn];
      assign nic_s_bresp[jn] = slave_if_gen[jn].slave_intf.bresp;
      assign nic_s_buser[jn] = slave_if_gen[jn].slave_intf.buser;
      assign nic_s_bvalid[jn] = slave_if_gen[jn].slave_intf.bvalid;
      assign nic_s_rdata[jn] = slave_if_gen[jn].slave_intf.rdata;
      assign nic_s_rid[jn] = slave_if_gen[jn].slave_intf.rid;
      assign nic_s_rlast[jn] = slave_if_gen[jn].slave_intf.rlast;
      assign slave_if_gen[jn].slave_intf.rready = nic_s_rready[jn];
      assign nic_s_rresp[jn] = slave_if_gen[jn].slave_intf.rresp;
      assign nic_s_ruser[jn] = slave_if_gen[jn].slave_intf.ruser;
      assign nic_s_rvalid[jn] = slave_if_gen[jn].slave_intf.rvalid;
      assign slave_if_gen[jn].slave_intf.wdata = nic_s_wdata[jn];
      assign slave_if_gen[jn].slave_intf.wlast = nic_s_wlast[jn];
      assign nic_s_wready[jn] = slave_if_gen[jn].slave_intf.wready;
      assign slave_if_gen[jn].slave_intf.wstrb = nic_s_wstrb[jn];
      assign slave_if_gen[jn].slave_intf.wuser = nic_s_wuser[jn];
      assign slave_if_gen[jn].slave_intf.wvalid = nic_s_wvalid[jn];
      // fabric does not forward QoS downstream; keep VIP slave inputs quiet
      assign slave_if_gen[jn].slave_intf.awqos = 4'b0;
      assign slave_if_gen[jn].slave_intf.arqos = 4'b0;
    end
  endgenerate

  // Fabric boundary probe. Compile with +define+NIC400_DEBUG_PROBE to trace what
  // the VIP actually presents to the fabric and what the fabric issues back.
  // This is how the read-path investigation established that reads are accepted
  // at ingress (arready=1) yet never issued on any egress port.
`ifdef NIC400_DEBUG_PROBE
  always @(posedge aclk) begin
    for (int pp = 0; pp < `NIC400_PORTS; pp++) begin
      if (nic_s_arvalid[pp] === 1'bx)
        $display("  [NICPROBE] t=%0t EGRESS[%0d] ARVALID is X", $time, pp);
      else if (nic_s_arvalid[pp])
        $display("  [NICPROBE] t=%0t EGRESS[%0d] ARVALID araddr=0x%016h", $time, pp, nic_s_araddr[pp]);
      if (nic_s_awvalid[pp])
        $display("  [NICPROBE] t=%0t EGRESS[%0d] AWVALID awaddr=0x%016h", $time, pp, nic_s_awaddr[pp]);
      if (nic_s_wvalid[pp] === 1'b1)
        $display("  [NICPROBE] t=%0t EGRESS[%0d] WVALID wlast=%0b wready=%0b", $time, pp, nic_s_wlast[pp], nic_s_wready[pp]);
      if (nic_s_bvalid[pp] === 1'bx)
        $display("  [NICPROBE] t=%0t EGRESS[%0d] BVALID is X (slave->fabric)", $time, pp);
      else if (nic_s_bvalid[pp])
        $display("  [NICPROBE] t=%0t EGRESS[%0d] BVALID bid=0x%02h bready=%0b", $time, pp, nic_s_bid[pp], nic_s_bready[pp]);
    end
    for (int pp = 0; pp < `NIC400_PORTS; pp++) begin
      if (nic_m_arvalid[pp] === 1'b1)
        $display("  [NICPROBE] t=%0t INGRESS[%0d] ARVALID araddr=0x%016h arready=%0b",
                 $time, pp, nic_m_araddr[pp], nic_m_arready[pp]);
      if (nic_m_awvalid[pp] === 1'b1)
        $display("  [NICPROBE] t=%0t INGRESS[%0d] AWVALID awaddr=0x%016h awready=%0b",
                 $time, pp, nic_m_awaddr[pp], nic_m_awready[pp]);
      if (nic_m_bvalid[pp] === 1'b1)
        $display("  [NICPROBE] t=%0t INGRESS[%0d] BVALID bid=0x%01h bready=%0b (fabric->master)",
                 $time, pp, nic_m_bid[pp], nic_m_bready[pp]);
    end
  end
`endif

  axi4_nic400_fabric_wrapper #(.NUM(`NIC400_PORTS)) u_nic400_fabric (
    .clk   (aclk),
    .resetn(aresetn),
    .m_araddr(nic_m_araddr),
    .m_arburst(nic_m_arburst),
    .m_arcache(nic_m_arcache),
    .m_arid(nic_m_arid),
    .m_arlen(nic_m_arlen),
    .m_arlock(nic_m_arlock),
    .m_arprot(nic_m_arprot),
    .m_arqos(nic_m_arqos),
    .m_arready(nic_m_arready),
    .m_arregion(nic_m_arregion),
    .m_arsize(nic_m_arsize),
    .m_aruser(nic_m_aruser),
    .m_arvalid(nic_m_arvalid),
    .m_awaddr(nic_m_awaddr),
    .m_awburst(nic_m_awburst),
    .m_awcache(nic_m_awcache),
    .m_awid(nic_m_awid),
    .m_awlen(nic_m_awlen),
    .m_awlock(nic_m_awlock),
    .m_awprot(nic_m_awprot),
    .m_awqos(nic_m_awqos),
    .m_awready(nic_m_awready),
    .m_awregion(nic_m_awregion),
    .m_awsize(nic_m_awsize),
    .m_awuser(nic_m_awuser),
    .m_awvalid(nic_m_awvalid),
    .m_bid(nic_m_bid),
    .m_bready(nic_m_bready),
    .m_bresp(nic_m_bresp),
    .m_buser(nic_m_buser),
    .m_bvalid(nic_m_bvalid),
    .m_rdata(nic_m_rdata),
    .m_rid(nic_m_rid),
    .m_rlast(nic_m_rlast),
    .m_rready(nic_m_rready),
    .m_rresp(nic_m_rresp),
    .m_ruser(nic_m_ruser),
    .m_rvalid(nic_m_rvalid),
    .m_wdata(nic_m_wdata),
    .m_wlast(nic_m_wlast),
    .m_wready(nic_m_wready),
    .m_wstrb(nic_m_wstrb),
    .m_wuser(nic_m_wuser),
    .m_wvalid(nic_m_wvalid),
    .s_araddr(nic_s_araddr),
    .s_arburst(nic_s_arburst),
    .s_arcache(nic_s_arcache),
    .s_arid(nic_s_arid),
    .s_arlen(nic_s_arlen),
    .s_arlock(nic_s_arlock),
    .s_arprot(nic_s_arprot),
    .s_arready(nic_s_arready),
    .s_arregion(nic_s_arregion),
    .s_arsize(nic_s_arsize),
    .s_aruser(nic_s_aruser),
    .s_arvalid(nic_s_arvalid),
    .s_awaddr(nic_s_awaddr),
    .s_awburst(nic_s_awburst),
    .s_awcache(nic_s_awcache),
    .s_awid(nic_s_awid),
    .s_awlen(nic_s_awlen),
    .s_awlock(nic_s_awlock),
    .s_awprot(nic_s_awprot),
    .s_awready(nic_s_awready),
    .s_awregion(nic_s_awregion),
    .s_awsize(nic_s_awsize),
    .s_awuser(nic_s_awuser),
    .s_awvalid(nic_s_awvalid),
    .s_bid(nic_s_bid),
    .s_bready(nic_s_bready),
    .s_bresp(nic_s_bresp),
    .s_buser(nic_s_buser),
    .s_bvalid(nic_s_bvalid),
    .s_rdata(nic_s_rdata),
    .s_rid(nic_s_rid),
    .s_rlast(nic_s_rlast),
    .s_rready(nic_s_rready),
    .s_rresp(nic_s_rresp),
    .s_ruser(nic_s_ruser),
    .s_rvalid(nic_s_rvalid),
    .s_wdata(nic_s_wdata),
    .s_wlast(nic_s_wlast),
    .s_wready(nic_s_wready),
    .s_wstrb(nic_s_wstrb),
    .s_wuser(nic_s_wuser),
    .s_wvalid(nic_s_wvalid)
  );

`else
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
`endif // BUS_MATRIX_NIC400
  //-------------------------------------------------------
  // Reset Signal Monitor Instance
  // Monitors and verifies all reset signal transitions
  //-------------------------------------------------------
  // Reset monitoring is now integrated into master and slave monitor BFMs
  
endmodule : hdl_top

`endif

