`ifndef AXI4_MASTER_AGENT_INCLUDED_
`define AXI4_MASTER_AGENT_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_agent
// This agent is a configurable with respect to configuration which can create active and passive components
// It contains testbench components like sequencer,driver_proxy and monitor_proxy for AXI4
//--------------------------------------------------------------------------------------------
class axi4_master_agent extends uvm_agent;
  `uvm_component_utils(axi4_master_agent)

  // Variable: axi4_master_agent_cfg_h
  // Declaring handle for master agent configuration class 
  axi4_master_agent_config axi4_master_agent_cfg_h;

  // Varible: axi4_master_write_seqr_h 
  // Handle for master write sequencer
  axi4_master_write_sequencer axi4_master_write_seqr_h;
  
  // Varible: axi4_master_read_seqr_h 
  // Handle for master read sequencer
  axi4_master_read_sequencer axi4_master_read_seqr_h;
  
  // Variable: axi4_master_drv_proxy_h
  // Creating a Handle for axi4_master driver proxy 
  axi4_master_driver_proxy axi4_master_drv_proxy_h;

  // Variable: axi4_master_mon_proxy_h
  // Declaring a handle for axi4_master monitor proxy 
  axi4_master_monitor_proxy axi4_master_mon_proxy_h;
  
  // Variable: axi4_master_coverage
  // Decalring a handle for axi4_master_coverage
  axi4_master_coverage axi4_master_cov_h;

  // Variable: axi4_master_qos_user_cov_h
  // The QoS/USER covergroups (axi4_qos_cg, axi4_user_cg,
  // axi4_qos_user_combination_cg) were compiled into axi4_master_pkg but never
  // created anywhere, so the whole axi4_qos_* test family ran without a single
  // QoS coverpoint being sampled.
  axi4_master_qos_user_coverage axi4_master_qos_user_cov_h;


  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_agent", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);

endclass : axi4_master_agent

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_master_agent
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_master_agent::new(string name = "axi4_master_agent", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
//  Function: build_phase
//  Creates the required ports, gets the required configuration from config_db
//
//  Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_master_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  if(axi4_master_agent_cfg_h.is_active == UVM_ACTIVE) begin
    axi4_master_drv_proxy_h=axi4_master_driver_proxy::type_id::create("axi4_master_drv_proxy_h",this);
    axi4_master_write_seqr_h=axi4_master_write_sequencer::type_id::create("axi4_master_write_seqr_h",this);
    axi4_master_read_seqr_h=axi4_master_read_sequencer::type_id::create("axi4_master_read_seqr_h",this);
  end
  
  axi4_master_mon_proxy_h=axi4_master_monitor_proxy::type_id::create("axi4_master_mon_proxy_h",this);
  
  if(axi4_master_agent_cfg_h.has_coverage) begin
   axi4_master_cov_h = axi4_master_coverage ::type_id::create("axi4_master_cov_h",this);
   axi4_master_qos_user_cov_h = axi4_master_qos_user_coverage::type_id::create("axi4_master_qos_user_cov_h",this);
  end

  if(!uvm_config_db#(read_data_type_mode_e)::get(this,"","read_data_mode",axi4_master_agent_cfg_h.read_data_mode)) begin
    `uvm_fatal("FATAL_MA_AGENT_CONFIG", $sformatf("Couldn't get the read_data_mode from config_db"))
  end
endfunction : build_phase

//--------------------------------------------------------------------------------------------
//  Function: connect_phase 
//  Connecting axi4 master driver, master monitor and master sequencer for configuration
//
//  Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_master_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if(axi4_master_agent_cfg_h.is_active == UVM_ACTIVE) begin
    axi4_master_drv_proxy_h.axi4_master_agent_cfg_h = axi4_master_agent_cfg_h;
    axi4_master_write_seqr_h.axi4_master_agent_cfg_h = axi4_master_agent_cfg_h;
    axi4_master_read_seqr_h.axi4_master_agent_cfg_h = axi4_master_agent_cfg_h;
    // Fixed: Only assign coverage config if coverage is enabled and created
    if(axi4_master_agent_cfg_h.has_coverage && axi4_master_cov_h != null) begin
      axi4_master_cov_h.axi4_master_agent_cfg_h = axi4_master_agent_cfg_h;
    end
  
    //Connecting the ports
    axi4_master_drv_proxy_h.axi_write_seq_item_port.connect(axi4_master_write_seqr_h.seq_item_export);
    axi4_master_drv_proxy_h.axi_read_seq_item_port.connect(axi4_master_read_seqr_h.seq_item_export);
  end

  if(axi4_master_agent_cfg_h.has_coverage) begin
    axi4_master_cov_h.axi4_master_agent_cfg_h = axi4_master_agent_cfg_h;

    // Connecting monitor_proxy ports to the PER-CHANNEL coverage exports.
    //
    // All five channel ports used to land on the single uvm_subscriber
    // analysis_export of axi4_master_cov_h, which then sampled one monolithic
    // covergroup on every packet. Because every published packet is a freshly
    // new()'d 2-state axi4_master_tx, the fields that channel did not observe
    // were legal zeros (BRESP/RRESP=OKAY, AxBURST=FIXED, AxSIZE=1 byte,
    // AxID=0), so write-only traffic scored first-time hits on read-side bins
    // and vice versa. axi4_master_coverage now exposes one imp per channel and
    // samples only the covergroup whose fields that packet actually carries.
    axi4_master_mon_proxy_h.axi4_master_write_address_analysis_port.connect(axi4_master_cov_h.write_addr_export);
    axi4_master_mon_proxy_h.axi4_master_write_data_analysis_port.connect(axi4_master_cov_h.write_data_export);
    axi4_master_mon_proxy_h.axi4_master_write_response_analysis_port.connect(axi4_master_cov_h.write_resp_export);
    axi4_master_mon_proxy_h.axi4_master_read_address_analysis_port.connect(axi4_master_cov_h.read_addr_export);
    axi4_master_mon_proxy_h.axi4_master_read_data_analysis_port.connect(axi4_master_cov_h.read_data_export);

    // QoS/USER coverage is a separate subscriber and keeps its own wiring.
    axi4_master_mon_proxy_h.axi4_master_read_address_analysis_port.connect(axi4_master_qos_user_cov_h.analysis_export);
    axi4_master_mon_proxy_h.axi4_master_write_address_analysis_port.connect(axi4_master_qos_user_cov_h.analysis_export);
  end
  
  axi4_master_mon_proxy_h.axi4_master_agent_cfg_h = axi4_master_agent_cfg_h;

endfunction : connect_phase

`endif

