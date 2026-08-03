`ifndef AXI4_SLAVE_MONITOR_PROXY_INCLUDED_
`define AXI4_SLAVE_MONITOR_PROXY_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_monitor_proxy
// This is the HVL axi4_slave monitor proxy
// It gets the sampled data from the HDL axi4_slave monitor and 
// converts them into transaction items
//--------------------------------------------------------------------------------------------
class axi4_slave_monitor_proxy extends uvm_monitor;
  `uvm_component_utils(axi4_slave_monitor_proxy)

  // Variable: axi4_slave_agent_cfg_h;
  // Handle for axi4 slave agent configuration
  axi4_slave_agent_config axi4_slave_agent_cfg_h;

  // Declaring Virtual Monitor BFM Handle
  virtual axi4_slave_monitor_bfm axi4_slave_mon_bfm_h;

  axi4_slave_tx req_rd;
  axi4_slave_tx req_wr;

  // Variable: axi4_slave_analysis_port
  // Declaring analysis port for the monitor port
  uvm_analysis_port#(axi4_slave_tx) axi4_slave_write_address_analysis_port;
  uvm_analysis_port#(axi4_slave_tx) axi4_slave_write_data_analysis_port;
  uvm_analysis_port#(axi4_slave_tx) axi4_slave_write_response_analysis_port;
  uvm_analysis_port#(axi4_slave_tx) axi4_slave_read_address_analysis_port;
  uvm_analysis_port#(axi4_slave_tx) axi4_slave_read_data_analysis_port;

  //Variable: axi4_slave_write_address_fifo_h
  //Declaring handle for uvm_tlm_analysis_fifo for write task
  uvm_tlm_analysis_fifo #(axi4_slave_tx) axi4_slave_write_address_fifo_h;
  
  //-------------------------------------------------------
  // Response-join pools, KEYED BY ID
  //
  // These two used to be plain in-order uvm_tlm_analysis_fifos whose HEAD was
  // popped whenever a B or a completed R burst was seen. That is only correct
  // if responses complete in issue order, which AXI4 does not require: write
  // responses of DIFFERENT BIDs and read bursts of DIFFERENT RIDs may complete
  // out of order (ordering is guaranteed only WITHIN one ID). On legal
  // reordered traffic the head-pop grafted another transaction's address,
  // length and payload onto the response, and the scoreboard reported that as
  // a data mismatch; when the two swapped responses happened to carry equal
  // values it hid a real routing error instead. This matters more on the slave
  // side than on the master side, because the slave agent is exactly what an
  // out-of-order response-mode test (response_mode_e != RESP_IN_ORDER) drives.
  //
  // A per-ID queue popped from the front is correct for both cases and is
  // bit-identical to the old behaviour for single-ID / in-order traffic, which
  // is what the existing regression drives.
  //
  // The AW -> W pairing below deliberately stays an in-order FIFO: AXI4 has no
  // WID and forbids write-data interleaving, so write data on one port is
  // always in address-issue order.
  //-------------------------------------------------------

  //Variable: axi4_slave_write_data_pool
  //Combined write address+data packets awaiting their B response, keyed by AWID
  axi4_slave_tx axi4_slave_write_data_pool[int][$];
  uvm_event     axi4_slave_write_data_pool_ev;

  //Variable: axi4_slave_read_addr_pool
  //Read address packets awaiting their R burst, keyed by ARID
  axi4_slave_tx axi4_slave_read_addr_pool[int][$];
  uvm_event     axi4_slave_read_addr_pool_ev;

  // How many further same-channel completions we tolerate while waiting for an
  // outstanding request with the response's ID before saying so out loud. A
  // response whose ID was never issued -- or an AxID truncated by the
  // interconnect -- is indistinguishable from "not published yet" at the
  // instant it arrives, but not after this many other completions.
  static const int unmatched_id_wait_limit = 256;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_slave_monitor_proxy", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task axi4_slave_write_address();
  extern virtual task axi4_slave_write_data();
  extern virtual task axi4_slave_write_response();
  extern virtual task axi4_slave_read_address();
  extern virtual task axi4_slave_read_data();
  extern virtual task get_write_data_packet_by_id(input int id, output axi4_slave_tx tx_h);
  extern virtual task get_read_addr_packet_by_id(input int id, output axi4_slave_tx tx_h);

endclass : axi4_slave_monitor_proxy

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_slave_monitor_proxy
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_slave_monitor_proxy::new(string name = "axi4_slave_monitor_proxy",
                                 uvm_component parent = null);
  super.new(name, parent);
  axi4_slave_read_address_analysis_port = new("axi4_slave_read_address_analysis_port",this);
  axi4_slave_read_data_analysis_port = new("axi4_slave_read_data_analysis_port",this);
  axi4_slave_write_address_analysis_port = new("axi4_slave_write_address_analysis_port",this);
  axi4_slave_write_data_analysis_port = new("axi4_slave_write_data_analysis_port",this);
  axi4_slave_write_response_analysis_port = new("axi4_slave_write_response_analysis_port",this);
  axi4_slave_write_address_fifo_h= new("axi4_slave_write_address_fifo_h",this);
  axi4_slave_write_data_pool_ev  = new("axi4_slave_write_data_pool_ev");
  axi4_slave_read_addr_pool_ev   = new("axi4_slave_read_addr_pool_ev");
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_slave_monitor_proxy::build_phase(uvm_phase phase);
  super.build_phase(phase);
   if(!uvm_config_db#(virtual axi4_slave_monitor_bfm)::get(this,"","axi4_slave_monitor_bfm",axi4_slave_mon_bfm_h)) begin
     `uvm_fatal("FATAL_SMP_MON_BFM",$sformatf("Couldn't get S_MON_BFM in axi4_slave_monitor_proxy"));  
  end 
endfunction : build_phase

//-------------------------------------------------------------------------------------------
// Function: end_of_elaboration_phase
//Description: connects monitor_proxy and monitor_bfm
//
// Parameters:
//  phase - stores the current phase
//------------------------------------------------------------------------------------------
function void axi4_slave_monitor_proxy::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  axi4_slave_mon_bfm_h.axi4_slave_mon_proxy_h = this;
endfunction : end_of_elaboration_phase


//--------------------------------------------------------------------------------------------
// Task: run_phase
//--------------------------------------------------------------------------------------------
task axi4_slave_monitor_proxy::run_phase(uvm_phase phase);

  axi4_slave_mon_bfm_h.wait_for_aresetn();

  fork 
    axi4_slave_write_address();
    axi4_slave_write_data();
    axi4_slave_write_response();
    axi4_slave_read_address();
    axi4_slave_read_data();
  join

endtask : run_phase 

//--------------------------------------------------------------------------------------------
// Task : axi4_slave_write_address
// Description: converting,sampling and again converting 
//--------------------------------------------------------------------------------------------
task axi4_slave_monitor_proxy::axi4_slave_write_address();
  forever begin
    axi4_write_transfer_char_s struct_write_packet;
    axi4_transfer_cfg_s        struct_cfg;
    axi4_slave_tx              req_wr_clone_packet;


    axi4_slave_cfg_converter::from_class(axi4_slave_agent_cfg_h, struct_cfg);
    axi4_slave_mon_bfm_h.axi4_slave_write_address_sampling(struct_write_packet,struct_cfg);
    axi4_slave_seq_item_converter::to_write_class(struct_write_packet,req_wr);
    
    axi4_slave_write_address_fifo_h.write(req_wr);

    $cast(req_wr_clone_packet,req_wr.clone());    
    `uvm_info(get_type_name(),$sformatf("Packet received from axi4_slave_write_address_sampling is %s",req_wr_clone_packet.sprint()),UVM_HIGH)
    req_wr_clone_packet.sb_src_index = axi4_slave_agent_cfg_h.slave_id;
    axi4_slave_write_address_analysis_port.write(req_wr_clone_packet);

  end
endtask
//--------------------------------------------------------------------------------------------
// Task: axi4_slave_write_data
//  Gets the struct packet samples the data, convert it to req and drives to analysis port
//--------------------------------------------------------------------------------------------

task axi4_slave_monitor_proxy::axi4_slave_write_data();
  forever begin
    axi4_write_transfer_char_s struct_write_packet;

    axi4_transfer_cfg_s        struct_cfg;
    axi4_slave_tx             req_wr_clone_packet;
    axi4_slave_tx             local_write_addr_packet;
    
    axi4_slave_cfg_converter::from_class(axi4_slave_agent_cfg_h, struct_cfg);
    axi4_slave_mon_bfm_h.axi4_slave_write_data_sampling(struct_write_packet,struct_cfg);
    axi4_slave_seq_item_converter::to_write_class(struct_write_packet,req_wr);
    
    //Getting the write address packet
    axi4_slave_write_address_fifo_h.get(local_write_addr_packet);
    `uvm_info(get_type_name(),$sformatf("ADDR_Packet received from fifo is \n %s",local_write_addr_packet.sprint()),UVM_HIGH)   
    
    //Combining write address and write data packets
    axi4_slave_seq_item_converter::to_write_addr_data_class(local_write_addr_packet,struct_write_packet,req_wr);

    // Park the completed address+data packet under ITS OWN AWID so the B
    // channel can find it by BID instead of by arrival order.
    axi4_slave_write_data_pool[int'(req_wr.awid)].push_back(req_wr);
    axi4_slave_write_data_pool_ev.trigger();

    //clone and publish the clone to the analysis port
    //The clone was already being made here but the ORIGINAL was published, so
    //the object handed to the scoreboard was the same handle that is also
    //sitting in axi4_slave_write_data_pool. Every other path in this monitor
    //publishes the clone; the scoreboard now HOLDS slave items in keyed
    //matching pools for much longer, so publishing a handle that another
    //component also owns is one edit away from a real aliasing bug.
    $cast(req_wr_clone_packet,req_wr.clone());
    `uvm_info(get_type_name(),$sformatf("Packet received from axi4_slave_write_data is \n %s",req_wr_clone_packet.sprint()),UVM_HIGH)

    req_wr_clone_packet.sb_src_index = axi4_slave_agent_cfg_h.slave_id;
    axi4_slave_write_data_analysis_port.write(req_wr_clone_packet);
  end

endtask
//--------------------------------------------------------------------------------------------
// Task: axi4_slave_write_response
//  Gets the struct packet samples the data, convert it to req and drives to analysis port
//--------------------------------------------------------------------------------------------

task axi4_slave_monitor_proxy::axi4_slave_write_response();

  forever begin
    axi4_write_transfer_char_s struct_write_packet;
    axi4_transfer_cfg_s        struct_cfg;
    axi4_slave_tx             axi4_slave_tx_clone_packet;
    axi4_slave_tx             local_write_addr_data_packet;

    axi4_slave_cfg_converter::from_class(axi4_slave_agent_cfg_h, struct_cfg);
    axi4_slave_mon_bfm_h.axi4_write_response_sampling(struct_write_packet,struct_cfg);
    axi4_slave_seq_item_converter::to_write_class(struct_write_packet,req_wr);
    
    //Getting the write address+data packet that this B response actually
    //belongs to, matched on BID rather than on issue order.
    get_write_data_packet_by_id(int'(struct_write_packet.bid),local_write_addr_data_packet);

    //Combining write address and write data packets
    axi4_slave_seq_item_converter::to_write_addr_data_resp_class(local_write_addr_data_packet,struct_write_packet,req_wr);

    //clone and publish the clone to the analysis port 
    $cast(axi4_slave_tx_clone_packet,req_wr.clone());
    `uvm_info(get_type_name(),$sformatf("Packet received from axi4_slave_write_response is \n %s",axi4_slave_tx_clone_packet.sprint()),UVM_HIGH);
    
    axi4_slave_tx_clone_packet.sb_src_index = axi4_slave_agent_cfg_h.slave_id;
    axi4_slave_write_response_analysis_port.write(axi4_slave_tx_clone_packet);
  end
endtask

//--------------------------------------------------------------------------------------------
// Task: axi4_slave_read_address
//  Gets the struct packet samples the data, convert it to req and drives to analysis port
//--------------------------------------------------------------------------------------------

task axi4_slave_monitor_proxy::axi4_slave_read_address();
  forever begin
    axi4_read_transfer_char_s struct_read_packet;
    axi4_transfer_cfg_s        struct_cfg;
    axi4_slave_tx             req_rd_clone_packet;

    axi4_slave_cfg_converter::from_class(axi4_slave_agent_cfg_h, struct_cfg);
    axi4_slave_mon_bfm_h.axi4_read_address_sampling(struct_read_packet,struct_cfg);
    axi4_slave_seq_item_converter::to_read_class(struct_read_packet,req_rd);

    // Park the read request under ITS OWN ARID so the R channel can find it by
    // RID instead of by arrival order.
    axi4_slave_read_addr_pool[int'(req_rd.arid)].push_back(req_rd);
    axi4_slave_read_addr_pool_ev.trigger();

    $cast(req_rd_clone_packet,req_rd.clone());
    `uvm_info(get_type_name(),$sformatf("Packet received from axi4_slave_read_address is \n %s",req_rd_clone_packet.sprint()),UVM_HIGH)

    req_rd_clone_packet.sb_src_index = axi4_slave_agent_cfg_h.slave_id;
    axi4_slave_read_address_analysis_port.write(req_rd_clone_packet); 
  end

endtask

//--------------------------------------------------------------------------------------------
// Task: axi4_slave_read_data
//  Gets the struct packet samples the data, convert it to req and drives to analysis port
//--------------------------------------------------------------------------------------------

task axi4_slave_monitor_proxy::axi4_slave_read_data();
  forever begin
    axi4_read_transfer_char_s struct_read_packet;
    axi4_transfer_cfg_s       struct_cfg;
    axi4_slave_tx             req_rd_clone_packet; 
    axi4_slave_tx             local_read_addr_packet; 

    axi4_slave_cfg_converter::from_class(axi4_slave_agent_cfg_h, struct_cfg);
    axi4_slave_mon_bfm_h.axi4_read_data_sampling(struct_read_packet,struct_cfg);
    axi4_slave_seq_item_converter::to_read_class(struct_read_packet,req_rd);

    // The BFM hands up one COMPLETED burst at a time, already demuxed per RID,
    // so match it to the read request carrying the same ID.
    get_read_addr_packet_by_id(int'(struct_read_packet.rid),local_read_addr_packet);
    `uvm_info(get_type_name(),$sformatf("READ_ADDR_Packet joined by RID is \n %s",local_read_addr_packet.sprint()),UVM_HIGH)

    axi4_slave_seq_item_converter::to_read_addr_data_class(local_read_addr_packet,struct_read_packet,req_rd);
    //clone and publish the clone to the analysis port 
    $cast(req_rd_clone_packet,req_rd.clone());
    `uvm_info(get_type_name(),$sformatf("Packet received from axi4_slave_read_data is \n %s",req_rd_clone_packet.sprint()),UVM_HIGH)

    req_rd_clone_packet.sb_src_index = axi4_slave_agent_cfg_h.slave_id;
    axi4_slave_read_data_analysis_port.write(req_rd_clone_packet);
  end
endtask

//--------------------------------------------------------------------------------------------
// Task: get_write_data_packet_by_id
//  Pops the oldest outstanding write whose AWID equals the observed BID.
//
//  Blocking is deliberate and matches what the uvm_tlm_analysis_fifo get() it
//  replaced already did: a B handshake can be observed in the same time step as
//  its own WLAST, i.e. before the write-data process above has published the
//  combined packet, so "not there yet" is a legal transient. Nothing in this
//  monitor raises an objection, so a wait that never completes cannot hang the
//  simulation -- the item is simply never published, and the scoreboard's
//  completeness accounting is what reports it.
//--------------------------------------------------------------------------------------------
task axi4_slave_monitor_proxy::get_write_data_packet_by_id(input int id, output axi4_slave_tx tx_h);
  int waits = 0;
  while(!(axi4_slave_write_data_pool.exists(id) && axi4_slave_write_data_pool[id].size() > 0)) begin
    waits++;
    if(waits == unmatched_id_wait_limit) begin
      `uvm_warning("SLAVE_MON_BID_UNMATCHED",$sformatf("B response with BID=%0d has waited through %0d other write completions with no outstanding write of that ID. A BID that was never issued, or an AxID truncated by the interconnect, looks exactly like this.",id,waits))
    end
    axi4_slave_write_data_pool_ev.wait_trigger();
  end
  tx_h = axi4_slave_write_data_pool[id].pop_front();
  if(axi4_slave_write_data_pool[id].size() == 0) begin
    axi4_slave_write_data_pool.delete(id);
  end
  `uvm_info(get_type_name(),$sformatf("Joined B (BID=%0d) to its outstanding write \n %s",id,tx_h.sprint()),UVM_HIGH)
endtask

//--------------------------------------------------------------------------------------------
// Task: get_read_addr_packet_by_id
//  Pops the oldest outstanding read whose ARID equals the observed RID.
//  Same blocking rationale as get_write_data_packet_by_id above.
//--------------------------------------------------------------------------------------------
task axi4_slave_monitor_proxy::get_read_addr_packet_by_id(input int id, output axi4_slave_tx tx_h);
  int waits = 0;
  while(!(axi4_slave_read_addr_pool.exists(id) && axi4_slave_read_addr_pool[id].size() > 0)) begin
    waits++;
    if(waits == unmatched_id_wait_limit) begin
      `uvm_warning("SLAVE_MON_RID_UNMATCHED",$sformatf("R burst with RID=%0d has waited through %0d other read requests with no outstanding read of that ID. An RID that was never issued, or an AxID truncated by the interconnect, looks exactly like this.",id,waits))
    end
    axi4_slave_read_addr_pool_ev.wait_trigger();
  end
  tx_h = axi4_slave_read_addr_pool[id].pop_front();
  if(axi4_slave_read_addr_pool[id].size() == 0) begin
    axi4_slave_read_addr_pool.delete(id);
  end
  `uvm_info(get_type_name(),$sformatf("Joined R burst (RID=%0d) to its outstanding read \n %s",id,tx_h.sprint()),UVM_HIGH)
endtask

`endif
