`ifndef AXI4_ENV_INCLUDED_
`define AXI4_ENV_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4 env
// Description:
// Environment contains slave_agent_top,master_agent_top and axi4_virtual_sequencer
//--------------------------------------------------------------------------------------------
class axi4_env extends uvm_env;
  `uvm_component_utils(axi4_env)
  
  //Variable : axi4_env_cfg_h
  //Declaring handle for axi4_env_config_object
  axi4_env_config axi4_env_cfg_h;

  //Variable : axi4_master_agent_h
  //Declaring axi4 master agent handle 
  axi4_master_agent axi4_master_agent_h[];
 
  //Variable : axi4_slave_agent_h
  //Declaring axi4 slave agent handle
  axi4_slave_agent axi4_slave_agent_h[];

  //Variable : axi4_virtual_seqr_h
  //Declaring axi4_virtual seqr handle
  axi4_virtual_sequencer axi4_virtual_seqr_h;

  //Variable : axi4__scoreboard_h
  //Declaring axi4 scoreboard handle
  axi4_scoreboard axi4_scoreboard_h;

  //Variable : axi4_bus_matrix_h
  //Handle for golden bus matrix reference model
  axi4_bus_matrix_ref axi4_bus_matrix_h;

  //Variable : axi4_protocol_coverage_h
  //Handle for protocol compliance coverage
  axi4_protocol_coverage axi4_protocol_coverage_h;

  
  // Variable: axi4_master_agent_cfg_h;
  // Handle for axi4_master agent configuration
  axi4_master_agent_config axi4_master_agent_cfg_h[];

  // Variable: axi4_slave_agent_cfg_h;
  // Handle for axi4_slave agent configuration
  axi4_slave_agent_config axi4_slave_agent_cfg_h[];

 
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_env", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual function void start_of_simulation_phase(uvm_phase phase);

endclass : axi4_env

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
// name - axi4_env
// parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_env::new(string name = "axi4_env",uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Description:
// Create required components
//
// Parameters:
// phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_env::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  if(!uvm_config_db #(axi4_env_config)::get(this,"","axi4_env_config",axi4_env_cfg_h)) begin
    `uvm_fatal("FATAL_ENV_AGENT_CONFIG", $sformatf("Couldn't get the env_agent_config from config_db"))
  end
  
  axi4_master_agent_cfg_h = new[axi4_env_cfg_h.no_of_masters];
  foreach(axi4_master_agent_cfg_h[i]) begin
    if(!uvm_config_db#(axi4_master_agent_config)::get(this,"",
                                  $sformatf("axi4_master_agent_config_%0d",i),
                                  axi4_master_agent_cfg_h[i])) begin
      `uvm_fatal("FATAL_MA_AGENT_CONFIG", $sformatf("Couldn't get the axi4_master_agent_config_%0d from config_db",i))
    end
  end

  axi4_slave_agent_cfg_h = new[axi4_env_cfg_h.no_of_slaves];
  foreach(axi4_slave_agent_cfg_h[i]) begin
    if(!uvm_config_db #(axi4_slave_agent_config)::get(this,"",
                                $sformatf("axi4_slave_agent_config_%0d",i),
                                axi4_slave_agent_cfg_h[i])) begin
      `uvm_fatal("FATAL_SA_AGENT_CONFIG", $sformatf("Couldn't get the axi4_slave_agent_config_%0d from config_db",i))
    end
  end

  // Propagate error_inject flag from environment config to all agent configs
  foreach(axi4_master_agent_cfg_h[i]) begin
    axi4_master_agent_cfg_h[i].error_inject = axi4_env_cfg_h.error_inject;
  end
  foreach(axi4_slave_agent_cfg_h[i]) begin
    axi4_slave_agent_cfg_h[i].error_inject = axi4_env_cfg_h.error_inject;
  end

  axi4_master_agent_h = new[axi4_env_cfg_h.no_of_masters];
  foreach(axi4_master_agent_h[i]) begin
    axi4_master_agent_h[i]=axi4_master_agent::type_id::create($sformatf("axi4_master_agent_h[%0d]",i),this);
  end

  axi4_slave_agent_h = new[axi4_env_cfg_h.no_of_slaves];
  foreach(axi4_slave_agent_h[i]) begin
    axi4_slave_agent_h[i]=axi4_slave_agent::type_id::create($sformatf("axi4_slave_agent_h[%0d]",i),this);
  end
  
  if(axi4_env_cfg_h.has_virtual_seqr) begin
    axi4_virtual_seqr_h = axi4_virtual_sequencer::type_id::create("axi4_virtual_seqr_h",this);
  end

  if(axi4_env_cfg_h.has_scoreboard) begin
    axi4_scoreboard_h=axi4_scoreboard::type_id::create("axi4_scoreboard_h",this);
  end

  // Create protocol coverage component
  axi4_protocol_coverage_h = axi4_protocol_coverage::type_id::create("axi4_protocol_coverage_h", this);

  axi4_bus_matrix_h = axi4_bus_matrix_ref::type_id::create("axi4_bus_matrix_h", this);
  
  // Pass bus matrix mode from environment config to bus matrix reference model
  uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::set(this, "axi4_bus_matrix_h", "bus_matrix_mode", axi4_env_cfg_h.bus_matrix_mode);
  
  // Set bus matrix reference globally for access by sequences
  uvm_config_db#(axi4_bus_matrix_ref)::set(null, "*", "bus_matrix_ref", axi4_bus_matrix_h);
  
  // Set scoreboard handle globally for backdoor verification access by sequences
  if(axi4_env_cfg_h.has_scoreboard) begin
    uvm_config_db#(axi4_scoreboard)::set(null, "*", "axi4_scoreboard_h", axi4_scoreboard_h);
  end

  
  foreach(axi4_master_agent_h[i]) begin
    axi4_master_agent_h[i].axi4_master_agent_cfg_h = axi4_master_agent_cfg_h[i];
    // Pass write_read_mode to master driver proxies
    uvm_config_db#(write_read_data_mode_e)::set(this, 
                        $sformatf("axi4_master_agent_h[%0d].axi4_master_drv_proxy_h*", i),
                        "write_read_mode", axi4_env_cfg_h.write_read_mode_h);
  end
  
  foreach(axi4_slave_agent_h[i]) begin
    axi4_slave_agent_h[i].axi4_slave_agent_cfg_h = axi4_slave_agent_cfg_h[i];
    uvm_config_db#(axi4_bus_matrix_ref)::set(this,
                        $sformatf("*axi4_slave_agent_h[%0d]*", i),
                        "axi4_bus_matrix_gm", axi4_bus_matrix_h);
  end
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: connect_phase
// Description:
// To connect driver and sequencer
//
// Parameters:
// phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_env::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  if(axi4_env_cfg_h.has_virtual_seqr) begin
    axi4_virtual_seqr_h.axi4_master_write_seqr_h_all = new[axi4_env_cfg_h.no_of_masters];
    axi4_virtual_seqr_h.axi4_master_read_seqr_h_all  = new[axi4_env_cfg_h.no_of_masters];
    axi4_virtual_seqr_h.axi4_slave_write_seqr_h_all  = new[axi4_env_cfg_h.no_of_slaves];
    axi4_virtual_seqr_h.axi4_slave_read_seqr_h_all   = new[axi4_env_cfg_h.no_of_slaves];
    foreach(axi4_master_agent_h[i]) begin
      axi4_virtual_seqr_h.axi4_master_write_seqr_h_all[i] = axi4_master_agent_h[i].axi4_master_write_seqr_h;
      axi4_virtual_seqr_h.axi4_master_read_seqr_h_all[i]  = axi4_master_agent_h[i].axi4_master_read_seqr_h;
    end
    foreach(axi4_slave_agent_h[i]) begin
      // Only connect sequencers if agent is active
      if(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].is_active == UVM_ACTIVE) begin
        axi4_virtual_seqr_h.axi4_slave_write_seqr_h_all[i] = axi4_slave_agent_h[i].axi4_slave_write_seqr_h;
        axi4_virtual_seqr_h.axi4_slave_read_seqr_h_all[i]  = axi4_slave_agent_h[i].axi4_slave_read_seqr_h;
      end else begin
        axi4_virtual_seqr_h.axi4_slave_write_seqr_h_all[i] = null;
        axi4_virtual_seqr_h.axi4_slave_read_seqr_h_all[i]  = null;
      end
    end
    if(axi4_env_cfg_h.no_of_masters > 0) begin
      axi4_virtual_seqr_h.axi4_master_write_seqr_h = axi4_virtual_seqr_h.axi4_master_write_seqr_h_all[0];
      axi4_virtual_seqr_h.axi4_master_read_seqr_h  = axi4_virtual_seqr_h.axi4_master_read_seqr_h_all[0];
    end
    if(axi4_env_cfg_h.no_of_slaves > 0) begin
      // Find first active slave for default sequencer assignment
      foreach(axi4_virtual_seqr_h.axi4_slave_write_seqr_h_all[i]) begin
        if(axi4_virtual_seqr_h.axi4_slave_write_seqr_h_all[i] != null) begin
          axi4_virtual_seqr_h.axi4_slave_write_seqr_h = axi4_virtual_seqr_h.axi4_slave_write_seqr_h_all[i];
          axi4_virtual_seqr_h.axi4_slave_read_seqr_h  = axi4_virtual_seqr_h.axi4_slave_read_seqr_h_all[i];
          break;
        end
      end
      // If all slaves are passive, set to null
      if(axi4_virtual_seqr_h.axi4_slave_write_seqr_h == null) begin
        `uvm_info(get_type_name(), "All slaves are PASSIVE - no slave sequencers available", UVM_MEDIUM)
      end
    end
  end
  
  foreach(axi4_master_agent_h[i]) begin
    // Connect master agent analysis ports to scoreboard only if scoreboard is enabled
    if(axi4_env_cfg_h.has_scoreboard) begin
      axi4_master_agent_h[i].axi4_master_mon_proxy_h.axi4_master_read_address_analysis_port.connect(axi4_scoreboard_h.axi4_master_read_address_analysis_fifo.analysis_export);
      axi4_master_agent_h[i].axi4_master_mon_proxy_h.axi4_master_read_data_analysis_port.connect(axi4_scoreboard_h.axi4_master_read_data_analysis_fifo.analysis_export);
      axi4_master_agent_h[i].axi4_master_mon_proxy_h.axi4_master_write_address_analysis_port.connect(axi4_scoreboard_h.axi4_master_write_address_analysis_fifo.analysis_export);
      axi4_master_agent_h[i].axi4_master_mon_proxy_h.axi4_master_write_data_analysis_port.connect(axi4_scoreboard_h.axi4_master_write_data_analysis_fifo.analysis_export);
      axi4_master_agent_h[i].axi4_master_mon_proxy_h.axi4_master_write_response_analysis_port.connect(axi4_scoreboard_h.axi4_master_write_response_analysis_fifo.analysis_export);
    end
    
    // Connect protocol coverage to master agent transaction analysis ports
    axi4_master_agent_h[i].axi4_master_mon_proxy_h.axi4_master_write_address_analysis_port.connect(axi4_protocol_coverage_h.analysis_export);
    axi4_master_agent_h[i].axi4_master_mon_proxy_h.axi4_master_read_address_analysis_port.connect(axi4_protocol_coverage_h.analysis_export);
    
    axi4_master_agent_h[i].axi4_master_drv_proxy_h.write_read_mode_h = axi4_env_cfg_h.write_read_mode_h;
  end

  foreach(axi4_slave_agent_h[i]) begin
    // Connect slave agent analysis ports to scoreboard only if scoreboard is enabled
    if(axi4_env_cfg_h.has_scoreboard) begin
      axi4_slave_agent_h[i].axi4_slave_mon_proxy_h.axi4_slave_write_address_analysis_port.connect(axi4_scoreboard_h.axi4_slave_write_address_analysis_fifo.analysis_export);
      axi4_slave_agent_h[i].axi4_slave_mon_proxy_h.axi4_slave_write_data_analysis_port.connect(axi4_scoreboard_h.axi4_slave_write_data_analysis_fifo.analysis_export);
      axi4_slave_agent_h[i].axi4_slave_mon_proxy_h.axi4_slave_write_response_analysis_port.connect(axi4_scoreboard_h.axi4_slave_write_response_analysis_fifo.analysis_export);
      axi4_slave_agent_h[i].axi4_slave_mon_proxy_h.axi4_slave_read_address_analysis_port.connect(axi4_scoreboard_h.axi4_slave_read_address_analysis_fifo.analysis_export);
      axi4_slave_agent_h[i].axi4_slave_mon_proxy_h.axi4_slave_read_data_analysis_port.connect(axi4_scoreboard_h.axi4_slave_read_data_analysis_fifo.analysis_export);
    end
    // Only set driver proxy configuration if agent is active
    if(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].is_active == UVM_ACTIVE) begin
      axi4_slave_agent_h[i].axi4_slave_drv_proxy_h.write_read_mode_h = axi4_env_cfg_h.write_read_mode_h;
    end
  end
  
  // Set scoreboard configuration only if scoreboard is enabled
  if(axi4_env_cfg_h.has_scoreboard) begin
    axi4_scoreboard_h.axi4_env_cfg_h = axi4_env_cfg_h;
  end


  // Configure assertion ready delay cycles
//  foreach(axi4_master_agent_h[i]) begin
//    virtual master_assertions ma_if;
//    if(uvm_config_db#(virtual master_assertions)::get(null, $sformatf("*axi4_master_agent_h[%0d]*", i), "master_assertions", ma_if)) begin
//      ma_if.ready_delay_cycles = axi4_env_cfg_h.ready_delay_cycles;
//    end
//  end
//  foreach(axi4_slave_agent_h[i]) begin
//    virtual slave_assertions sa_if;
//    if(uvm_config_db#(virtual slave_assertions)::get(null, $sformatf("*axi4_slave_agent_h[%0d]*", i), "slave_assertions", sa_if)) begin
//      sa_if.ready_delay_cycles = axi4_env_cfg_h.ready_delay_cycles;
//    end
//  end
endfunction : connect_phase

//--------------------------------------------------------------------------------------------
// Function: start_of_simulation_phase
// Set up slave memory handles for backdoor verification after memories are created
//
// Parameters:
// phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_env::start_of_simulation_phase(uvm_phase phase);
  super.start_of_simulation_phase(phase);
  
  // Pass slave memory handles to scoreboard for backdoor verification
  // This is done in start_of_simulation_phase to ensure slave memories are created
  if(axi4_env_cfg_h.has_scoreboard) begin
    axi4_slave_memory slave_mem_handles[];
    slave_mem_handles = new[axi4_env_cfg_h.no_of_slaves];
    foreach(axi4_slave_agent_h[i]) begin
      if (axi4_slave_agent_cfg_h[i].is_active == UVM_ACTIVE) begin
        slave_mem_handles[i] = axi4_slave_agent_h[i].axi4_slave_drv_proxy_h.axi4_slave_mem_h;
        `uvm_info(get_type_name(), $sformatf("Setting slave memory handle[%0d] = %p", i, slave_mem_handles[i]), UVM_HIGH);
      end
    end
    axi4_scoreboard_h.set_slave_memory_handles(slave_mem_handles);
  end
endfunction : start_of_simulation_phase

`endif

