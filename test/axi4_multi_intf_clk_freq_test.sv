`ifndef AXI4_MULTI_INTF_CLK_FREQ_TEST_INCLUDED_
`define AXI4_MULTI_INTF_CLK_FREQ_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_multi_intf_clk_freq_test
// Tests independent clock frequency changes on multiple interfaces
//--------------------------------------------------------------------------------------------
class axi4_multi_intf_clk_freq_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_multi_intf_clk_freq_test)
  
  // Test configuration
  rand int num_freq_changes;
  rand int active_masters;
  rand int active_slaves;
  
  // Constraints
  constraint c_freq_changes {
    num_freq_changes inside {[5:10]};
  }
  
  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_multi_intf_clk_freq_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
  //--------------------------------------------------------------------------------------------
  // Function: setup_axi4_env_cfg
  //--------------------------------------------------------------------------------------------
  virtual function void setup_axi4_env_cfg();
    super.setup_axi4_env_cfg();
    
    // Enable frequency checker for this test
    axi4_env_cfg_h.has_freq_checker = 1;
    
    // Configure based on bus matrix mode
    case(axi4_env_cfg_h.bus_matrix_mode)
      axi4_bus_matrix_ref::NONE: begin
        active_masters = 1;
        active_slaves = 1;
      end
      axi4_bus_matrix_ref::BASE_BUS_MATRIX: begin
        active_masters = 4;
        active_slaves = 4;
      end
      axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: begin
        active_masters = 10;
        active_slaves = 10;
      end
    endcase
    
    `uvm_info(get_type_name(), $sformatf("Multi-interface clock freq test: %0d masters, %0d slaves", 
              active_masters, active_slaves), UVM_MEDIUM)
  endfunction : setup_axi4_env_cfg
  
  //--------------------------------------------------------------------------------------------
  // Function: build_phase
  //--------------------------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Configure test for clock frequency exceptions
    uvm_config_db#(bit)::set(this, "*", "enable_exceptions", 1);
    uvm_config_db#(bit)::set(this, "*", "clk_freq_exception", 1);
    uvm_config_db#(bit)::set(this, "*", "multi_interface_mode", 1);
    
    `uvm_info(get_type_name(), "Build phase completed for Multi-Interface Clock Frequency Test", UVM_LOW)
  endfunction : build_phase
  
  //--------------------------------------------------------------------------------------------
  // Task: run_phase
  //--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    axi4_master_exception_clk_freq_seq clk_freq_seq[];
    real freq_scales[4] = '{0.5, 1.0, 2.0, 1.5};
    int freq_idx;
    int intf_idx;
    int total_freq_events = 0;
    
    phase.raise_objection(this);
    
    // Randomize test parameters
    if(!this.randomize()) begin
      `uvm_error(get_type_name(), "Randomization failed")
    end
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "  MULTI-INTERFACE CLOCK FREQUENCY TEST", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Active Masters: %0d", active_masters), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Active Slaves: %0d", active_slaves), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Frequency Changes: %0d", num_freq_changes), UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Configure expected frequency changes for the checker
    if(axi4_env_h.axi4_freq_checker_h != null) begin
      int expected_events[string];
      expected_events["0.5x"] = 0;
      expected_events["1.0x"] = 0;
      expected_events["1.5x"] = 0;
      expected_events["2.0x"] = 0;
      
      // Estimate expected events based on randomization
      foreach(freq_scales[i]) begin
        if(freq_scales[i] == 0.5) expected_events["0.5x"] = num_freq_changes/4;
        else if(freq_scales[i] == 1.0) expected_events["1.0x"] = num_freq_changes/4;
        else if(freq_scales[i] == 1.5) expected_events["1.5x"] = num_freq_changes/4;
        else if(freq_scales[i] == 2.0) expected_events["2.0x"] = num_freq_changes/4;
      end
      
      axi4_env_h.axi4_freq_checker_h.set_expected_events(num_freq_changes, expected_events);
    end
    
    // Create sequences for each active master
    clk_freq_seq = new[active_masters];
    foreach(clk_freq_seq[i]) begin
      clk_freq_seq[i] = axi4_master_exception_clk_freq_seq::type_id::create($sformatf("clk_freq_seq_%0d", i));
    end
    
    fork
      // Thread 1: Run transfers on all active masters
      begin
        for(int m = 0; m < active_masters; m++) begin
          automatic int master_id = m;
          fork
            begin
              axi4_master_write_seq write_seq;
              repeat(10) begin
                write_seq = axi4_master_write_seq::type_id::create($sformatf("write_seq_m%0d", master_id));
                if(!write_seq.randomize()) begin
                  `uvm_error(get_type_name(), $sformatf("Write sequence randomization failed for master %0d", master_id))
                end
                
                if(test_config.num_masters > master_id) begin
                  write_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h_all[master_id]);
                end
                #50ns;
              end
            end
          join_none
        end
      end
      
      // Thread 2: Inject clock frequency changes on different interfaces
      begin
        repeat(num_freq_changes) begin
          // Random delay between changes
          #($urandom_range(100, 500) * 1ns);
          
          // Select random interface and frequency
          intf_idx = $urandom_range(0, active_masters-1);
          freq_idx = $urandom_range(0, 3);
          
          `uvm_info(get_type_name(), $sformatf("Changing frequency for interface %0d to %.1fx", 
                    intf_idx, freq_scales[freq_idx]), UVM_LOW)
          
          // Set frequency change for specific interface
          uvm_config_db#(int)::set(null, "*", "clk_freq_intf_id", intf_idx);
          uvm_config_db#(real)::set(null, "*", $sformatf("clk_freq_scale_intf_%0d", intf_idx), freq_scales[freq_idx]);
          uvm_config_db#(bit)::set(null, "*", $sformatf("clk_freq_change_active_intf_%0d", intf_idx), 1);
          
          // Also set global for freq_checker monitoring
          uvm_config_db#(real)::set(null, "*", "clk_freq_scale", freq_scales[freq_idx]);
          uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
          
          total_freq_events++;
          
          // Hold for some cycles
          #($urandom_range(50, 200) * 1ns);
          
          // Clear the active flag
          uvm_config_db#(bit)::set(null, "*", $sformatf("clk_freq_change_active_intf_%0d", intf_idx), 0);
          uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 0);
        end
      end
      
      // Thread 3: Monitor slave interfaces (if different clock domains)
      begin
        for(int s = 0; s < active_slaves; s++) begin
          automatic int slave_id = s;
          fork
            begin
              // Monitor slave ready signals
              repeat(20) begin
                #($urandom_range(50, 150) * 1ns);
                `uvm_info(get_type_name(), $sformatf("Slave %0d operational", slave_id), UVM_HIGH)
              end
            end
          join_none
        end
      end
    join_any
    
    // Allow time for all transactions to complete
    #2000ns;
    
    // Disable all threads
    disable fork;
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "  MULTI-INTERFACE CLOCK FREQUENCY TEST DONE", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total frequency events: %0d", total_freq_events), UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    phase.drop_objection(this);
    
  endtask : run_phase
  
endclass : axi4_multi_intf_clk_freq_test

`endif