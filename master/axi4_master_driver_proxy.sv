`ifndef AXI4_MASTER_DRIVER_PROXY_INCLUDED_
`define AXI4_MASTER_DRIVER_PROXY_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: master_driver_proxy
//  Driver is written by extending uvm_driver,uvm_driver is inherited from uvm_component, 
//  Methods and TLM port (seq_item_port) are defined for communication between sequencer and driver,
//  uvm_driver is a parameterized class and it is parameterized with the type of the request 
//  sequence_item and the type of the response sequence_item 
//--------------------------------------------------------------------------------------------
class axi4_master_driver_proxy extends uvm_driver#(axi4_master_tx);
  `uvm_component_utils(axi4_master_driver_proxy)

  //Port: axi_write_seq_item_port
  //This port is used to request write items from the sequencer, they are also used it to send responses back.
  uvm_seq_item_pull_port #(REQ,RSP) axi_write_seq_item_port;
  
  //Port: axi_read_seq_item_port
  //This port is used to request read items from the sequencer, they are also used it to send responses back.
  uvm_seq_item_pull_port #(REQ,RSP) axi_read_seq_item_port;

  //Port: axi_write_rsp_port
  //This port provides an alternate way of sending responses back to the originating sequencer. 
  //Which port to use depends on which export the sequencer provides for connection.
  uvm_analysis_port #(RSP) axi_write_rsp_port;
  
  //Port: axi_read_rsp_port
  //This port provides an alternate way of sending responses back to the originating sequencer. 
  //Which port to use depends on which export the sequencer provides for connection.
  uvm_analysis_port #(RSP) axi_read_rsp_port;

  //Variable: axi4_master_write_fifo_h
  //Declaring handle for uvm_tlm_analysis_fifo for write task
  uvm_tlm_analysis_fifo #(axi4_master_tx) axi4_master_write_fifo_h;

  //Variable: axi4_master_write_resp_fifo_h
  //Declaring handle for uvm_tlm_analysis_fifo for write task
  uvm_tlm_analysis_fifo #(axi4_master_tx) axi4_master_write_resp_fifo_h;
  
  //Variable: axi4_master_read_fifo_h
  //Declaring handle for uvm_tlm_analysis_fifo for read task
  uvm_tlm_analysis_fifo #(axi4_master_tx) axi4_master_read_fifo_h;

  //Variable: req_wr, req_rd
  //Declaration of REQ handles
  REQ req_wr, req_rd;
  
  //Variable: rsp_wr, rsp_rd
  //Declaration of RSP handles
  RSP rsp_wr, rsp_rd;
      
  //Variable: axi4_master_agent_cfg_h
  //Declaring handle for axi4_master agent config class 
  axi4_master_agent_config axi4_master_agent_cfg_h;

  //Variable: axi4_master_drv_bfm_h
  //Declaring handle for axi4 driver bfm
  virtual axi4_master_driver_bfm axi4_master_drv_bfm_h;

  // ---------------------------------------------------------------------------
  // Outstanding-depth credits (AXI_ooo.md F3/F4, Phase 4 / P4.1)
  //
  // These three semaphores are the manager's per-channel CREDIT COUNTERS: a
  // channel thread takes one credit before it may occupy its channel and returns
  // it when that transaction's phase is done, so the number of keys IS the
  // outstanding depth this manager will generate.
  //
  // They used to be hardcoded `new(1)` in the constructor, which pinned every
  // channel to exactly one transaction in flight no matter what
  // axi4_master_agent_config::outstanding_write_tx / outstanding_read_tx said -
  // those fields were packed into axi4_transfer_cfg_s and handed to the BFM but
  // never read by anything (AXI_ooo.md F3), so 9 tests configured a depth the VIP
  // could not produce (AXI_ooo.md F4). They are now created in run_phase() at the
  // configured depth by configure_outstanding_credits() below.
  //
  // Which credit actually bounds "outstanding" per AXI4's definition:
  //   write_response_channel_key - held from before the B wait until the response
  //     for this transaction has been claimed. This is the real bound on writes
  //     that have been issued but not yet responded to.
  //   read_channel_key           - held from before the R wait until RLAST has
  //     been claimed. Real bound on outstanding reads.
  //   write_data_channel_key     - held across the W burst. The BFM serialises the
  //     physical W channel on its own w_channel_key anyway, so raising this one
  //     lets later bursts queue up behind the one on the wire rather than making
  //     the proxy loop wait; it does not by itself interleave W data (AXI4 has no
  //     WID and forbids that).
  semaphore write_data_channel_key;
  semaphore write_response_channel_key;
  semaphore read_channel_key;

  //Variable : outstanding_write_credits / outstanding_read_credits
  //The depth the three semaphores above were actually created with. Resolved once,
  //in run_phase, by configure_outstanding_credits().
  int outstanding_write_credits = 1;
  int outstanding_read_credits  = 1;

  // ---- P4.1 instrumentation -------------------------------------------------
  // Live evidence that the credits do what they claim. All of it is plain int
  // bookkeeping around the existing get()/put() pairs; the per-event trace is
  // printed only under +AXI4_CREDIT_TRACE, the high-water marks always land in
  // report_phase.
  bit credit_trace_on;
  int wr_data_inflight,  wr_data_inflight_max;
  int wr_resp_inflight,  wr_resp_inflight_max;
  int rd_data_inflight,  rd_data_inflight_max;
  // Wire-level outstanding, read straight off the BFM's own protocol-bound
  // counters (AW handshakes issued minus B responses accepted at this port, and
  // the AR/R equivalent). Independent of the credit bookkeeping above, so the two
  // corroborate each other instead of one measuring itself.
  int wr_wire_outstanding_max;
  int rd_wire_outstanding_max;
  // High-water occupancy of the three analysis FIFOs. Replaces the unreachable
  // is_full() guards - see the note at the write/read FIFO pushes.
  int wr_fifo_used_max, wr_resp_fifo_used_max, rd_fifo_used_max;
  // W-burst ordering guard. AXI4 has no WID: write data bursts must appear on the
  // wire in the same order their addresses were issued. Ticket N is handed out in
  // AW order by the proxy loop; the data thread checks it is next before driving.
  // Only meaningful with QoS disabled (QoS deliberately re-orders which packet a
  // data thread drives) and only reachable at depth > 1.
  int wr_data_ticket_issue;
  int wr_data_ticket_next;

  bit wait_for_wr_addr;
  bit qos_wait_enable = 1'b1;
  bit qos_wait_enable_for_b2b = 1'b1;
  bit [ADDRESS_WIDTH-1:0] address;
  int length,size;
  int queue_index;
  int qualifer_for_initial_txn = -1;
  bit one_time_check = 1;
  bit disable_qos_check;
  int enable_qos_check_for_initial_txn = 1;
  int qos_write_counter;

  axi4_master_tx qos_queue[$];


  write_read_data_mode_e write_read_mode_h;

  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_driver_proxy", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual function void configure_outstanding_credits();
  extern virtual task run_phase(uvm_phase phase);
  extern virtual function void report_phase(uvm_phase phase);
  extern virtual task axi4_write_task();
  extern virtual task axi4_read_task();

endclass : axi4_master_driver_proxy

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_master_driver_proxy
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_master_driver_proxy::new(string name = "axi4_master_driver_proxy", uvm_component parent = null);
  super.new(name, parent);
  axi_write_seq_item_port    = new("axi_write_seq_item_port",this);
  axi_read_seq_item_port     = new("axi_read_seq_item_port",this);
  axi_write_rsp_port         = new("axi_write_rsp_port",this);
  axi_read_rsp_port          = new("axi_read_rsp_port",this);
  axi4_master_write_fifo_h   = new("axi4_master_write_fifo_h",this);
  axi4_master_write_resp_fifo_h   = new("axi4_master_write_resp_fifo_h",this);
  axi4_master_read_fifo_h    = new("axi4_master_read_fifo_h",this);
  // Depth-1 fallback only. The real depth is not knowable here (the agent config
  // is not bound yet), so run_phase re-creates all three at the configured depth
  // via configure_outstanding_credits(). Constructing them anyway keeps any
  // pre-run_phase get()/put() from dereferencing a null handle.
  read_channel_key           = new(1);
  write_data_channel_key     = new(1);
  write_response_channel_key = new(1);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_master_driver_proxy::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(!uvm_config_db #(virtual axi4_master_driver_bfm)::get(this,"","axi4_master_driver_bfm",axi4_master_drv_bfm_h)) begin
    `uvm_fatal("FATAL_MDP_CANNOT_GET_AXI4_MASTER_DRIVER_BFM","cannot get() axi4_master_drv_bfm_h");
  end
  
  // Get write_read_mode from config_db if available, default to WRITE_READ_DATA
  if(!uvm_config_db #(write_read_data_mode_e)::get(this,"","write_read_mode",write_read_mode_h)) begin
    write_read_mode_h = WRITE_READ_DATA; // Default to mixed mode
    `uvm_info(get_type_name(),"write_read_mode not found in config_db, defaulting to WRITE_READ_DATA", UVM_MEDIUM);
  end
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: end_of_elaboration_phase
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_master_driver_proxy::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  axi4_master_drv_bfm_h.axi4_master_drv_proxy_h = this;
endfunction : end_of_elaboration_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
//  Gets the sequence_item, converts them to struct compatible transactions
//  and sends them to the BFM to drive the data over the interface
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------
// Function: configure_outstanding_credits
//  Resolves the per-channel outstanding depth ONCE, before any traffic, and
//  (re)creates the three channel credit semaphores at that depth. This is what
//  makes axi4_master_agent_config::outstanding_write_tx / outstanding_read_tx a
//  live knob instead of the silent no-op AXI_ooo.md F3 describes.
//
//  The depth is read out of axi4_transfer_cfg_s - the same struct
//  axi4_master_cfg_converter::from_class() has always built and the write/read
//  tasks have always handed to the BFM, where nothing ever read it. Reading it
//  here keeps the converter the single path from config class to config struct.
//
//  D3 (AXI_ooo.md section 3) - default depth when the knob is not set:
//    outstanding_write_tx / outstanding_read_tx are `rand int` with NO
//    initialiser and the agent config is never randomised anywhere in this repo,
//    so an unset field reads 0, not 1. A literal reading would therefore give
//    "zero credits" (a deadlock) to every test that does not set it. Anything
//    <= 0 is treated as "not configured" and mapped to depth 1, which is exactly
//    the behaviour every such test has always run at. Only the 9 tests that
//    explicitly assign the field change behaviour.
//
//  Two clamps, both deliberate:
//    - OUTSTANDING_FIFO_DEPTH (pkg/axi4_globals_pkg.sv) is the VIP-wide sanity
//      bound; a larger request is clamped with a warning rather than silently
//      honoured. This is that parameter's first and only reader.
//    - QoS write arbitration in WRITE_DATA_CHANNEL below works on shared,
//      non-re-entrant state (qos_queue, queue_index, enable_qos_check_for_
//      initial_txn, disable_qos_check ...). Concurrent data threads would corrupt
//      it, so with write QoS enabled the WRITE depth is pinned to 1. Read depth
//      is untouched: the read path has no QoS arbitration.
//
//  +AXI4_OUTSTANDING_LEGACY forces both depths to 1, i.e. the exact pre-P4.1
//  behaviour, from the SAME binary - the single-variable control used for the
//  before/after evidence.
//--------------------------------------------------------------------------------------------
function void axi4_master_driver_proxy::configure_outstanding_credits();
  axi4_transfer_cfg_s struct_cfg;
  int                 cfg_wr;
  int                 cfg_rd;

  credit_trace_on = $test$plusargs("AXI4_CREDIT_TRACE");

  if(axi4_master_agent_cfg_h == null) begin
    `uvm_warning("AXI4_CREDIT","agent config is null - outstanding depth falls back to 1/1")
    cfg_wr = 0;
    cfg_rd = 0;
  end
  else begin
    axi4_master_cfg_converter::from_class(axi4_master_agent_cfg_h,struct_cfg);
    cfg_wr = struct_cfg.outstanding_write_tx;
    cfg_rd = struct_cfg.outstanding_read_tx;
  end

  outstanding_write_credits = (cfg_wr <= 0) ? 1 : cfg_wr;
  outstanding_read_credits  = (cfg_rd <= 0) ? 1 : cfg_rd;

  if(outstanding_write_credits > OUTSTANDING_FIFO_DEPTH) begin
    `uvm_warning("AXI4_CREDIT",$sformatf("outstanding_write_tx=%0d exceeds OUTSTANDING_FIFO_DEPTH=%0d - clamped",
                                          outstanding_write_credits,OUTSTANDING_FIFO_DEPTH))
    outstanding_write_credits = OUTSTANDING_FIFO_DEPTH;
  end
  if(outstanding_read_credits > OUTSTANDING_FIFO_DEPTH) begin
    `uvm_warning("AXI4_CREDIT",$sformatf("outstanding_read_tx=%0d exceeds OUTSTANDING_FIFO_DEPTH=%0d - clamped",
                                          outstanding_read_credits,OUTSTANDING_FIFO_DEPTH))
    outstanding_read_credits = OUTSTANDING_FIFO_DEPTH;
  end

  if(axi4_master_agent_cfg_h != null &&
     ((axi4_master_agent_cfg_h.qos_mode_type == ONLY_WRITE_QOS_MODE_ENABLE) ||
      (axi4_master_agent_cfg_h.qos_mode_type == WRITE_READ_QOS_MODE_ENABLE)) &&
     outstanding_write_credits > 1) begin
    `uvm_info("AXI4_CREDIT",$sformatf("write QoS arbitration is enabled (%s) and is not re-entrant - write outstanding depth pinned to 1 (requested %0d)",
                                       axi4_master_agent_cfg_h.qos_mode_type.name(),outstanding_write_credits),UVM_LOW)
    outstanding_write_credits = 1;
  end

  if($test$plusargs("AXI4_OUTSTANDING_LEGACY")) begin
    `uvm_info("AXI4_CREDIT","+AXI4_OUTSTANDING_LEGACY - forcing both depths to 1 (pre-P4.1 behaviour)",UVM_LOW)
    outstanding_write_credits = 1;
    outstanding_read_credits  = 1;
  end

  write_data_channel_key     = new(outstanding_write_credits);
  write_response_channel_key = new(outstanding_write_credits);
  read_channel_key           = new(outstanding_read_credits);

  `uvm_info("AXI4_CREDIT",$sformatf("outstanding depth LIVE: write=%0d read=%0d (cfg %0d/%0d, cap %0d)",
                                     outstanding_write_credits,outstanding_read_credits,
                                     cfg_wr,cfg_rd,OUTSTANDING_FIFO_DEPTH),UVM_LOW)
endfunction : configure_outstanding_credits

//--------------------------------------------------------------------------------------------
// Function: report_phase
//  Publishes the outstanding-depth high-water marks. These are the numbers that
//  say whether a configured depth was actually ACHIEVED, as opposed to merely
//  permitted - the distinction AXI_ooo.md F4 turns on.
//--------------------------------------------------------------------------------------------
function void axi4_master_driver_proxy::report_phase(uvm_phase phase);
  super.report_phase(phase);
  `uvm_info("AXI4_CREDIT",$sformatf("OUTSTANDING SUMMARY depth(w/r)=%0d/%0d max_inflight w_data=%0d w_resp=%0d r_data=%0d | max_wire_outstanding w=%0d r=%0d | max_fifo_used w=%0d wresp=%0d r=%0d",
                                     outstanding_write_credits,outstanding_read_credits,
                                     wr_data_inflight_max,wr_resp_inflight_max,rd_data_inflight_max,
                                     wr_wire_outstanding_max,rd_wire_outstanding_max,
                                     wr_fifo_used_max,wr_resp_fifo_used_max,rd_fifo_used_max),UVM_LOW)
endfunction : report_phase

task axi4_master_driver_proxy::run_phase(uvm_phase phase);

  //Size the per-channel outstanding credits from the agent config BEFORE any
  //traffic can take a key.
  configure_outstanding_credits();

  //waiting for system reset
  axi4_master_drv_bfm_h.wait_for_aresetn();

  fork 
    axi4_write_task();
    axi4_read_task();
  join

endtask : run_phase

//--------------------------------------------------------------------------------------------
// Task: axi4_write_task
//  Gets the sequence_item, converts them to struct compatible transactions
//  and sends them to the BFM to drive the data over the interface
//--------------------------------------------------------------------------------------------
task axi4_master_driver_proxy::axi4_write_task();

  forever begin
    axi4_master_tx             local_master_tx;
    axi4_transfer_cfg_s        struct_cfg;
    axi4_write_transfer_char_s struct_write_packet;
    bit x_inject_awvalid;
    int x_inject_cycles;

    axi_write_seq_item_port.get_next_item(req_wr);
    `uvm_info(get_type_name(),$sformatf("WRITE_TASK::Before Sending_req_write_packet = \n%s",req_wr.sprint()),UVM_HIGH); 

    // Check for X injection configuration
    if(!uvm_config_db#(bit)::get(null, "*", "x_inject_awvalid", x_inject_awvalid))
      x_inject_awvalid = 0;
    
    if(x_inject_awvalid) begin
      if(!uvm_config_db#(int)::get(null, "*", "x_inject_cycles", x_inject_cycles))
        x_inject_cycles = 3; // Default cycles
      
      `uvm_info(get_type_name(), $sformatf("Triggering AWVALID X injection for %0d cycles", x_inject_cycles), UVM_MEDIUM)
      
      // Call BFM's X injection task
      axi4_master_drv_bfm_h.inject_x_on_awvalid(x_inject_cycles);
      
      // Clear the injection flag after use
      uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid", 0);
    end
    
    // Check for AWADDR X injection
    begin
      bit x_inject_awaddr;
      if(!uvm_config_db#(bit)::get(null, "*", "x_inject_awaddr", x_inject_awaddr))
        x_inject_awaddr = 0;
      
      if(x_inject_awaddr) begin
        if(!uvm_config_db#(int)::get(null, "*", "x_inject_cycles", x_inject_cycles))
          x_inject_cycles = 3;
        
        `uvm_info(get_type_name(), $sformatf("Triggering AWADDR X injection for %0d cycles", x_inject_cycles), UVM_MEDIUM)
        axi4_master_drv_bfm_h.inject_x_on_awaddr(x_inject_cycles);
        uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr", 0);
      end
    end
    
    // Check for WDATA X injection
    begin
      bit x_inject_wdata;
      if(!uvm_config_db#(bit)::get(null, "*", "x_inject_wdata", x_inject_wdata))
        x_inject_wdata = 0;
      
      if(x_inject_wdata) begin
        if(!uvm_config_db#(int)::get(null, "*", "x_inject_cycles", x_inject_cycles))
          x_inject_cycles = 3;
        
        `uvm_info(get_type_name(), $sformatf("Triggering WDATA X injection for %0d cycles", x_inject_cycles), UVM_MEDIUM)
        axi4_master_drv_bfm_h.inject_x_on_wdata(x_inject_cycles);
        uvm_config_db#(bit)::set(null, "*", "x_inject_wdata", 0);
      end
    end
    
    // Check for BREADY X injection
    begin
      bit x_inject_bready;
      if(!uvm_config_db#(bit)::get(null, "*", "x_inject_bready", x_inject_bready))
        x_inject_bready = 0;
      
      if(x_inject_bready) begin
        if(!uvm_config_db#(int)::get(null, "*", "x_inject_cycles", x_inject_cycles))
          x_inject_cycles = 3;
        
        `uvm_info(get_type_name(), $sformatf("Triggering BREADY X injection for %0d cycles", x_inject_cycles), UVM_MEDIUM)
        axi4_master_drv_bfm_h.inject_x_on_bready(x_inject_cycles);
        uvm_config_db#(bit)::set(null, "*", "x_inject_bready", 0);
      end
    end

    if(axi4_master_agent_cfg_h.read_data_mode == SLAVE_MEM_MODE) begin 
      address = req_wr.awaddr;
      length = req_wr.awlen;
      size = req_wr.awsize;
    end

    //Converting configurations into struct config type
    axi4_master_cfg_converter::from_class(axi4_master_agent_cfg_h,struct_cfg);


    `uvm_info(get_type_name(),$sformatf("WRITE_TASK::Checking transfer type outside if = %s",req_wr.transfer_type),UVM_FULL); 
    
    //Checking if the tranfer type is blocking write 
    if(req_wr.transfer_type == BLOCKING_WRITE) begin
      
      axi4_master_tx local_master_write_tx; 
      axi4_master_seq_item_converter::from_write_class(req_wr,struct_write_packet);
      `uvm_info(get_type_name(),$sformatf("WRITE_TASK::Checking transfer type = %s",req_wr.transfer_type),UVM_MEDIUM); 
      
      //For blocking writes, run address and data channels in parallel per AXI protocol
      //Address and data channels are independent and can operate concurrently
      fork
        axi4_master_drv_bfm_h.axi4_write_address_channel_task(struct_write_packet,struct_cfg);
        axi4_master_drv_bfm_h.axi4_write_data_channel_task(struct_write_packet,struct_cfg);
      join
      //Response channel must wait for both address and data to complete
      axi4_master_drv_bfm_h.axi4_write_response_channel_task(struct_write_packet,struct_cfg);

      //Converts the struct packet to req packet
      axi4_master_seq_item_converter::to_write_class(struct_write_packet,local_master_write_tx);
      `uvm_info(get_type_name(),$sformatf("WRITE_TASK::Response Received_req_write_packet = \n %s",
                                           local_master_write_tx.sprint()),UVM_MEDIUM);
    end

    //Checking if the tranfer type is non blocking write 
    else if(req_wr.transfer_type == NON_BLOCKING_WRITE) begin

      //Variable : write_address_process
      //Used to control the fork_join process
      //Use Case is fork_join process should wait for write address to complete.
      process write_address_process;

      //Variable : write_data_process
      //Used to control the fork_join process
      process write_data_process;

      //Variable : write_response_process
      //Used to control the fork_join process
      process write_response_process;

      //Keeping the req packet into the write fifo
      //This fifo is used if the transfer_type is NON_BLOCKING_WRITE
      //
      //P4.2 (AXI_ooo.md F4, "three unreachable is_full() guards"): the
      //  if(!fifo.is_full()) ... else `uvm_error("FIFO IS FULL")
      //that used to wrap these two writes was dead code and stays dead after
      //P4.1. uvm_tlm_analysis_fifo forces its uvm_tlm_fifo base to size 0, and
      //uvm_tlm_fifo::is_full() is `(m_size != 0) && (used() == m_size)`, so it is
      //a compile-time constant 0 - the error could never fire. Making the credits
      //live does NOT change that: unboundedness is a property of the FIFO type,
      //not of the driver, and the occupancy is not bounded by the credit depth
      //either, because this loop pushes once per AW handshake while the consumer
      //threads are gated by credits, so the producer legitimately runs ahead.
      //There is therefore no correct threshold to test here, and a guard that
      //cannot fire is worse than none: it reads like protection that exists.
      //Replaced with the one thing that IS both true and useful - a high-water
      //mark, reported in report_phase, so real backlog growth is visible instead
      //of being nominally guarded and actually unobserved.
      axi4_master_write_fifo_h.write(req_wr);
      if(axi4_master_write_fifo_h.used() > wr_fifo_used_max)
        wr_fifo_used_max = axi4_master_write_fifo_h.used();

      axi4_master_write_resp_fifo_h.write(req_wr);
      if(axi4_master_write_resp_fifo_h.used() > wr_resp_fifo_used_max)
        wr_resp_fifo_used_max = axi4_master_write_resp_fifo_h.used();

      fork
        begin : WRITE_ADDRESS_CHANNEL 
          axi4_master_tx             local_master_addr_tx;
          axi4_write_transfer_char_s struct_write_addr_packet;

          //Added the write_address_process to keep track of this write address channel thread
          //self is a static method which creates the write_address_process of type process
          write_address_process = process::self();

          //Converting the req packet to struct packet
          axi4_master_seq_item_converter::from_write_class(req_wr,struct_write_addr_packet);
          `uvm_info(get_type_name(),$sformatf("WRITE_ADDRESS_THREAD::Checking write address struct packet = %p",
                                               struct_write_addr_packet),UVM_MEDIUM); 

          //Calling the bfm task which drives write address channel signals
          axi4_master_drv_bfm_h.axi4_write_address_channel_task(struct_write_addr_packet,struct_cfg);

          //Converting the write data struct packet to req packet
          axi4_master_seq_item_converter::to_write_class(struct_write_addr_packet,req_wr);
          `uvm_info(get_type_name(),$sformatf("WRITE_ADDRESS_THREAD::Received_req_write_packet = \n %s",
                                               req_wr.sprint()),UVM_MEDIUM);

          if((axi4_master_agent_cfg_h.qos_mode_type == ONLY_WRITE_QOS_MODE_ENABLE) || (axi4_master_agent_cfg_h.qos_mode_type == WRITE_READ_QOS_MODE_ENABLE)) begin
            qos_queue.push_front(req_wr);
            if(qos_queue.size>1) begin
              qualifer_for_initial_txn = 0;
            end
            qos_write_counter++;
          end
          

          //Returns the number of packets written to fifo
          `uvm_info(get_type_name(),$sformatf("WRITE_ADDRESS_THREAD::Checking fifo size used= %0d",
                                               axi4_master_write_fifo_h.used()),UVM_FULL);
        end
    
        begin : WRITE_DATA_CHANNEL
          axi4_master_tx             local_master_data_tx;
          axi4_write_transfer_char_s struct_write_data_packet;
          axi4_master_tx             qos_value_check_1;
          axi4_master_tx             temp_awid;
          int                        temp_queue_sz;
          int                        diff;
          bit                        modify_qos_index_bit;
          bit                        disable_b2b_check;
          int                        awid_queue_q[$];
          int                        wr_ticket;

          //Added the write_data_process to keep track of this write address channel thread
          //self is a static method which creates the write_data_process of type process
          write_data_process=process::self();

          //W-burst order ticket, taken here because this is the last point that is
          //still in strict per-iteration (i.e. AW issue) order: the parent blocks
          //at join_any, so this branch runs to its first blocking statement before
          //the next iteration exists. See wr_data_ticket_issue.
          wr_ticket = wr_data_ticket_issue++;

          //Taking a credit from the write-data channel. With depth 1 this is the
          //original "next transaction waits for the previous one" behaviour; with
          //depth N, N bursts may be queued behind the one the BFM currently has on
          //the wire.
          write_data_channel_key.get(1);
          wr_data_inflight++;
          if(wr_data_inflight > wr_data_inflight_max) wr_data_inflight_max = wr_data_inflight;
          if(credit_trace_on)
            `uvm_info("AXI4_CREDIT",$sformatf("WDATA acquire ticket=%0d inflight=%0d/%0d",
                                               wr_ticket,wr_data_inflight,outstanding_write_credits),UVM_LOW)

          //Returns the number of elements written into fifo
          `uvm_info(get_type_name(),$sformatf("WRITE_DATA_THREAD::Checking fifo size used in write_data= %0d",
                                               axi4_master_write_fifo_h.used()),UVM_FULL);

          //Return the fifo size that it is capable to hold
          //A return value of 0 indicates the FIFO capacity has no limit
          `uvm_info(get_type_name(),$sformatf("WRITE_DATA_THREAD::Checking fifo size = %0d",
                                               axi4_master_write_fifo_h.size()),UVM_FULL); 

          if((axi4_master_agent_cfg_h.qos_mode_type == ONLY_WRITE_QOS_MODE_ENABLE) ||
            (axi4_master_agent_cfg_h.qos_mode_type == WRITE_READ_QOS_MODE_ENABLE) &&
            one_time_check == 1) begin
            wait( qualifer_for_initial_txn == 0);
            one_time_check = 0;
          end
          if(((axi4_master_agent_cfg_h.qos_mode_type == ONLY_WRITE_QOS_MODE_ENABLE) ||
            (axi4_master_agent_cfg_h.qos_mode_type == WRITE_READ_QOS_MODE_ENABLE))) begin
            if(qos_wait_enable) begin
              wait(qos_queue.size>=2);
            end
            qos_wait_enable = 1'b0;
            qos_value_check_1 = qos_queue[$];
            if(!disable_qos_check) begin
              for(int i=0;i<qos_queue.size();i++) begin
                if(qos_queue[i].awqos >= qos_value_check_1.awqos) begin
                  qos_value_check_1 = qos_queue[i];
                  queue_index = i;
                end
              end
              if(qos_queue.size>1 && enable_qos_check_for_initial_txn == -1) begin
                for(int k=0;k<qos_queue.size();k++) begin
                  if(qos_queue[$].awid == qos_queue[k].awid) begin
                    if(k==qos_queue.size-1) disable_b2b_check = 1;
                  end
                  else begin
                    disable_b2b_check = 0;
                  end
                end
              end
              temp_awid = qos_queue[queue_index];
              if(disable_b2b_check == 0) begin
                for(int j=0;j<qos_queue.size();j++) begin
                  if(temp_awid.awid == qos_queue[j].awid) begin
                    queue_index = j;
                  end
                  else begin
                    break;
                  end
                end
              end
            end
            if(enable_qos_check_for_initial_txn == 0) begin
              // Check if queue has at least 2 elements before accessing $-1
              if(qos_queue.size() >= 2 && qos_queue[$].awid == qos_queue[$-1].awid && awid_queue_for_qos[$] == qos_queue[$-1].awid) begin
                awid_queue_q = qos_queue.find_last_index with (item.awid == qos_queue[$].awid);
                queue_index = awid_queue_q[$]; 
                enable_qos_check_for_initial_txn = -1;
              end
              else begin
                queue_index = queue_index;
                enable_qos_check_for_initial_txn = -1;
              end
            end
            if(enable_qos_check_for_initial_txn == 1) begin
              // Check if queue has at least 2 elements before accessing $-1
              if(qos_queue.size() >= 2 && qos_queue[$].awid == qos_queue[$-1].awid) begin
                local_master_data_tx = qos_queue.pop_back;
                awid_queue_for_qos.push_back(local_master_data_tx.awid);
              end
              else begin
                if(qos_write_counter>2) begin
                  local_master_data_tx = qos_queue.pop_back;
                  awid_queue_for_qos.push_back(local_master_data_tx.awid);
                  enable_qos_check_for_initial_txn = 0;
                end
                else begin
                  local_master_data_tx = qos_queue[queue_index];
                  awid_queue_for_qos.push_back(local_master_data_tx.awid);
                  enable_qos_check_for_initial_txn = 0;
                  qos_queue.delete(queue_index);
                end
              end
            end
            else begin
                // Check if queue_index is valid before accessing
                if(queue_index < qos_queue.size() && qos_queue[queue_index] != null) begin
                  local_master_data_tx = qos_queue[queue_index];
                  awid_queue_for_qos.push_back(local_master_data_tx.awid);
                  qos_queue.delete(queue_index);
                end
                else begin
                  // If index is invalid, skip QoS processing for this transaction
                  `uvm_info("axi4_master_driver_proxy", $sformatf("Invalid queue_index %0d, qos_queue size=%0d", queue_index, qos_queue.size()), UVM_LOW)
                end
            end
           temp_queue_sz = qos_queue.size();
            qos_wait_enable_for_b2b = 1'b0;
          end
          else begin
            //Peek method gets the packet from the fifo but the fifo doesn't discard the packet
            //It throws an error if peek is done into an empty fifo
            if(!axi4_master_write_fifo_h.is_empty()) begin
              axi4_master_write_fifo_h.get(local_master_data_tx);
            end
            else begin
              `uvm_error(get_type_name(),$sformatf("WRITE_DATA_THREAD::Cannot peek into FIFO as WRITE_FIFO IS EMPTY"));
            end
          end


          //AXI4 has no WID (A3.4.1): W bursts must reach the wire in the same
          //order their AWs were issued. At depth 1 that was structural; at
          //depth > 1 several data threads hold a credit at once and race for the
          //BFM's w_channel_key, so the invariant becomes checkable - and worth
          //checking, since a violation here is a manager-generated protocol error
          //that would surface far away as wrong write data. Everything between
          //here and the BFM call below is zero-time. Skipped under QoS, which
          //re-orders which packet a data thread drives on purpose.
          if((axi4_master_agent_cfg_h.qos_mode_type != ONLY_WRITE_QOS_MODE_ENABLE) &&
             (axi4_master_agent_cfg_h.qos_mode_type != WRITE_READ_QOS_MODE_ENABLE)) begin
            if(wr_ticket != wr_data_ticket_next) begin
              `uvm_error("AXI4_CREDIT",$sformatf("W burst out of AW order: this burst is ticket %0d but ticket %0d has not driven yet (AXI4 A3.4.1 - no WID, write data must follow address order)",
                                                  wr_ticket,wr_data_ticket_next))
            end
            wr_data_ticket_next++;
          end

          //Converts the received req_packet to struct packet
          if(local_master_data_tx != null) begin
            axi4_master_seq_item_converter::from_write_class(local_master_data_tx,struct_write_data_packet);
            `uvm_info(get_type_name(),$sformatf("WRITE_DATA_THREAD::Checking write data struct packet = %p",
                                                 struct_write_data_packet),UVM_MEDIUM);

            //Calling the write data channel in bfm to drive all the write data signals
            axi4_master_drv_bfm_h.axi4_write_data_channel_task(struct_write_data_packet,struct_cfg);
            
            //Converting the write data struct packet to req packet
            axi4_master_seq_item_converter::to_write_class(struct_write_data_packet,local_master_data_tx);
            `uvm_info(get_type_name(),$sformatf("WRITE_DATA_THREAD::Received_req_write_packet = \n %s",
                                                 local_master_data_tx.sprint()),UVM_MEDIUM);
          end
          else begin
            `uvm_info(get_type_name(), "WRITE_DATA_THREAD::local_master_data_tx is null, skipping this iteration", UVM_LOW)
            #1ns;  // Small delay before retrying
          end
          
                                               //Returns the number of packets written into fifo
          `uvm_info(get_type_name(),$sformatf("WRITE_DATA_THREAD::Checking fifo size used= %0d",
                                               axi4_master_write_fifo_h.used()),UVM_FULL);

          #1ns;
          if(enable_qos_check_for_initial_txn == -1) begin
            if(queue_index == 0 && modify_qos_index_bit == 0) begin
               if(temp_queue_sz == qos_queue.size) begin
                 queue_index = queue_index;
               end
               else begin
                 diff = qos_queue.size - temp_queue_sz;
                 if(local_master_data_tx != null && diff > 0 && qos_queue[diff-1] != null && 
                    local_master_data_tx.awid == qos_queue[diff-1].awid) begin
                   queue_index = diff-1;
                   disable_qos_check = 1;
                 end
                 else begin
                   disable_qos_check = 0;
                   queue_index = queue_index;
                 end
               end
            end
            else begin
              if(queue_index>=1) begin
                 diff = qos_queue.size - temp_queue_sz;
                 if(diff == 0) begin
                   if(local_master_data_tx.awid == qos_queue[queue_index-1].awid) begin
                     queue_index = queue_index-1;
                     disable_qos_check = 1;
                   end
                   else begin
                     disable_qos_check = 0;
                   end
                 end
                 else begin
                   if(local_master_data_tx.awid == qos_queue[diff].awid) begin
                     modify_qos_index_bit = 1;
                   end
                   else begin
                     modify_qos_index_bit = 0;
                   end
                   if(modify_qos_index_bit) begin
                     for(int i=diff;i<qos_queue.size();i++) begin
                       if(local_master_data_tx.awid == qos_queue[i].awid) begin
                        disable_qos_check = 1;
                        queue_index = i;
                       end
                     end
                   end
                   else begin
                     disable_qos_check = 0;
                   end
                 end
               end
            end
          end

          //Returning the write-data credit: this transaction's W burst is done.
          wr_data_inflight--;
          if(credit_trace_on)
            `uvm_info("AXI4_CREDIT",$sformatf("WDATA release ticket=%0d inflight=%0d/%0d",
                                               wr_ticket,wr_data_inflight,outstanding_write_credits),UVM_LOW)
          write_data_channel_key.put(1);
        end
     
        begin : WRITE_RESPONSE_CHANNEL

          axi4_master_tx             local_master_response_tx;
          axi4_write_transfer_char_s struct_write_response_packet;

          //Added the write_response_process to keep track of this write response channel thread
          //self is a static method which creates the write_response_process of type process
          write_response_process=process::self();

          //Taking a credit from the write-response channel. THIS is the credit that
          //defines outstanding writes: it is held from here until the B response
          //for this transaction has been claimed, so at most
          //outstanding_write_credits writes can be awaiting a response at once.
          write_response_channel_key.get(1);
          wr_resp_inflight++;
          if(wr_resp_inflight > wr_resp_inflight_max) wr_resp_inflight_max = wr_resp_inflight;
          //Independent, protocol-bound corroboration: AW handshakes issued at this
          //port minus B responses accepted at it, counted inside the BFM.
          if((axi4_master_drv_bfm_h.aw_issued_cnt - axi4_master_drv_bfm_h.b_event_cnt) > wr_wire_outstanding_max)
            wr_wire_outstanding_max = axi4_master_drv_bfm_h.aw_issued_cnt - axi4_master_drv_bfm_h.b_event_cnt;
          if(credit_trace_on)
            `uvm_info("AXI4_CREDIT",$sformatf("WRESP acquire inflight=%0d/%0d wire_outstanding=%0d",
                                               wr_resp_inflight,outstanding_write_credits,
                                               axi4_master_drv_bfm_h.aw_issued_cnt - axi4_master_drv_bfm_h.b_event_cnt),UVM_LOW)

          //write_address_process.await();

          `uvm_info(get_type_name(),$sformatf("WRITE_RESPONSE_THREAD::Checking fifo size used = %0d",
                                               axi4_master_write_resp_fifo_h.used()),UVM_FULL); 
         
            //Get method gets the packet and discards the packet from fifo
            //It throws an error if get is done into an empty fifo
            if(!axi4_master_write_resp_fifo_h.is_empty()) begin
              axi4_master_write_resp_fifo_h.get(local_master_response_tx);
            end
            else begin
              `uvm_error(get_type_name(),$sformatf("WRITE_RESPONSE_THREAD::Cannot peek into FIFO as WRITE_RESP_FIFO IS EMPTY"));
            end
          
          //Converts the received req_packet to struct packet
          axi4_master_seq_item_converter::from_write_class(local_master_response_tx,struct_write_response_packet);
          `uvm_info(get_type_name(),$sformatf("WRITE_RESPONSE_THREAD::Checking struct packet = %p",
                                               struct_write_response_packet),UVM_MEDIUM); 
          
          //Calls the write response channel on the bfm to sample the write response channel signals
          axi4_master_drv_bfm_h.axi4_write_response_channel_task(struct_write_response_packet,struct_cfg);
          `uvm_info(get_type_name(),$sformatf("WRITE_RESPONSE_THREAD::Received_struct_packet = %p",
                                               struct_write_response_packet),UVM_FULL);

          // Log error responses but complete the transaction normally
          if (struct_write_response_packet.bresp == 2 || struct_write_response_packet.bresp == 3) begin
            `uvm_info("MASTER_DRIVER_DEBUG", $sformatf("Received error response (bresp=%0d) for BID=0x%h - completing transaction normally", 
                     struct_write_response_packet.bresp, struct_write_response_packet.bid), UVM_LOW);
          end

          //Converting the write data struct packet to req packet
          axi4_master_seq_item_converter::to_write_class(struct_write_response_packet,local_master_response_tx);
          `uvm_info(get_type_name(),$sformatf("WRITE_RESPONSE_THREAD::Received_req_write_packet = \n %s",
                                               local_master_response_tx.sprint()),UVM_MEDIUM);

          `uvm_info(get_type_name(),$sformatf("WRITE_RESPONSE_THREAD::Checking fifo size used= %0d",
                                               axi4_master_write_resp_fifo_h.used()),UVM_FULL); 

          `uvm_info(get_type_name(), $sformatf("WRITE_RESPONSE_THREAD :: Out of response task"), UVM_FULL); 
          
          //Returning the write-response credit: this write is complete.
          wr_resp_inflight--;
          if(credit_trace_on)
            `uvm_info("AXI4_CREDIT",$sformatf("WRESP release inflight=%0d/%0d wire_outstanding=%0d",
                                               wr_resp_inflight,outstanding_write_credits,
                                               axi4_master_drv_bfm_h.aw_issued_cnt - axi4_master_drv_bfm_h.b_event_cnt),UVM_LOW)
          write_response_channel_key.put(1);

        end

      join_any

      //fine-grain control
      //status returns whether the process is FINISHED or WAITING or RUNNING.
      `uvm_info(get_type_name(), $sformatf("WRITE_TASK :: Out of fork_join : Before await write_address.status()=%s",
                                            write_address_process.status()), UVM_NONE); 
      //Waiting for write address channel to complete 
      //As we don't have control on fork-join_any or fork-join_none processes,
      //the await method makes sure that it waits for the write address to complete
      write_address_process.await();
      
      //status returns whether the process is FINISHED or WAITING or RUNNING.
      `uvm_info(get_type_name(), $sformatf("WRITE_TASK :: Out of fork_join : After await write_address.status()=%s",
                                            write_address_process.status()), UVM_NONE); 
    end

    wait_for_wr_addr = 1;

    axi_write_seq_item_port.item_done();
  end
endtask : axi4_write_task

//--------------------------------------------------------------------------------------------
// Task: axi4_read_task
//  Gets the sequence_item, converts them to struct compatible transactions
//  and sends them to the BFM to drive the data over the interface
//--------------------------------------------------------------------------------------------
task axi4_master_driver_proxy::axi4_read_task();
  forever begin
    
    //axi4_master_tx local_master_read_tx;
    axi4_read_transfer_char_s struct_read_packet;
    axi4_transfer_cfg_s       struct_cfg;

    axi_read_seq_item_port.get_next_item(req_rd);
    `uvm_info(get_type_name(),$sformatf("READ_TASK:: Before Sending_req_read_packet = \n %s",req_rd.sprint()),UVM_NONE); 

    // Check for ARVALID X injection
    begin
      bit x_inject_arvalid;
      int x_inject_cycles;
      if(!uvm_config_db#(bit)::get(null, "*", "x_inject_arvalid", x_inject_arvalid))
        x_inject_arvalid = 0;
      
      if(x_inject_arvalid) begin
        if(!uvm_config_db#(int)::get(null, "*", "x_inject_cycles", x_inject_cycles))
          x_inject_cycles = 3;
        
        `uvm_info(get_type_name(), $sformatf("Triggering ARVALID X injection for %0d cycles", x_inject_cycles), UVM_MEDIUM)
        axi4_master_drv_bfm_h.inject_x_on_arvalid(x_inject_cycles);
        uvm_config_db#(bit)::set(null, "*", "x_inject_arvalid", 0);
      end
    end
    
    // Check for RREADY X injection
    begin
      bit x_inject_rready;
      int x_inject_cycles;
      if(!uvm_config_db#(bit)::get(null, "*", "x_inject_rready", x_inject_rready))
        x_inject_rready = 0;
      
      if(x_inject_rready) begin
        if(!uvm_config_db#(int)::get(null, "*", "x_inject_cycles", x_inject_cycles))
          x_inject_cycles = 3;
        
        `uvm_info(get_type_name(), $sformatf("Triggering RREADY X injection for %0d cycles", x_inject_cycles), UVM_MEDIUM)
        axi4_master_drv_bfm_h.inject_x_on_rready(x_inject_cycles);
        uvm_config_db#(bit)::set(null, "*", "x_inject_rready", 0);
      end
    end

    // Skip SLAVE_MEM_MODE logic for independent read operations
    // This was causing reads to hang waiting for write addresses in mixed operation tests
    if(axi4_master_agent_cfg_h.read_data_mode == SLAVE_MEM_MODE && write_read_mode_h == ONLY_WRITE_DATA) begin 
      wait(wait_for_wr_addr);
      req_rd.araddr = address;
      req_rd.arlen  = length;
      req_rd.arsize = arsize_e'(size);
    end

    //Converting configurations into struct config type
    axi4_master_cfg_converter::from_class(axi4_master_agent_cfg_h,struct_cfg);


    //Return the fifo size that it is capable to hold
    //A return value of 0 indicates the FIFO capacity has no limit
    `uvm_info(get_type_name(),$sformatf("READ_TASK::Checking fifo_size = %0d",axi4_master_write_fifo_h.size()),UVM_FULL); 
    `uvm_info(get_type_name(),$sformatf("READ_TASK::Checking fifo_resp_size = %0d",axi4_master_write_resp_fifo_h.size()),UVM_FULL); 

    `uvm_info(get_type_name(),$sformatf("READ_TASK::Checking transfer type outside if= %s",req_rd.transfer_type),UVM_FULL); 
    `uvm_info(get_type_name(),$sformatf("READ_TASK::Checking transfer type outside if= %s",req_rd.transfer_type),UVM_FULL); 
    
    if(req_rd.transfer_type == BLOCKING_READ) begin
      
      //Converts the req read packet to struct read packet
      axi4_master_seq_item_converter::from_read_class(req_rd,struct_read_packet);
      `uvm_info(get_type_name(),$sformatf("READ_TASK::Checking transfer type in read task = %s",req_rd.transfer_type),UVM_MEDIUM); 

      //Calling read address channel and read data channel tasks declared in bfm to drive the
      //read address channel signals and to sample the read data channel siganls
      axi4_master_drv_bfm_h.axi4_read_address_channel_task(struct_read_packet,struct_cfg);
      axi4_master_drv_bfm_h.axi4_read_data_channel_task(struct_read_packet,struct_cfg,axi4_master_agent_cfg_h.error_inject);
      
      //Converting transactions into struct data type
      axi4_master_seq_item_converter::to_read_class(struct_read_packet,req_rd);

      `uvm_info(get_type_name(),$sformatf("READ_TASK::Response_received_req_read_packet = \n %s",req_rd.sprint()),UVM_MEDIUM);
    end

    else if(req_rd.transfer_type ==  NON_BLOCKING_READ) begin

      //Variable : read_addr_process
      //Used to control the fork_join process
      //Use Case is fork_join process should wait for read address to complete.
      process read_addr_process;

      //Variable : read_data_process
      //Used to control the fork_join process
      process read_data_process;

      //Keeping the req packet into the read fifo
      //This fifo is used if the transfer_type is NON_BLOCKING_READ
      //The is_full() guard that used to wrap this write was unreachable - see the
      //note at the write-side FIFO pushes in axi4_write_task for why, and why a
      //high-water mark replaces it rather than a different threshold.
      axi4_master_read_fifo_h.write(req_rd);
      if(axi4_master_read_fifo_h.used() > rd_fifo_used_max)
        rd_fifo_used_max = axi4_master_read_fifo_h.used();

      fork
        begin : READ_ADDRESS_CHANNEL
          axi4_read_transfer_char_s struct_read_address_packet;
          axi4_master_tx            req_rd_addr_dbg;

          //Added the read_addr_process to keep track of this read address channel thread
          //self is a static method which creates the read_addr_process of type process
          read_addr_process = process::self();

          `uvm_info(get_type_name(),$sformatf("READ_ADDRESS_THREAD::Checking transfer type inside fork = %s",
                                               req_rd.transfer_type),UVM_FULL); 

          `uvm_info(get_type_name(),$sformatf("READ_ADDRESS_THREAD::Checking req_rd = %s",req_rd.sprint()),UVM_FULL); 
          
          //Converts the read req packet to struct packet
          axi4_master_seq_item_converter::from_read_class(req_rd,struct_read_address_packet);
          `uvm_info(get_type_name(),$sformatf("READ_ADDRESS_THREAD::Checking struct packet = %p",
                                               struct_read_address_packet),UVM_MEDIUM); 
          
          //Calls the read address channel to drive the read address channel signals
          axi4_master_drv_bfm_h.axi4_read_address_channel_task(struct_read_address_packet,struct_cfg);

          // Debug-only read-back of what was just driven on the AR channel.
          //
          // Two defects in the previous form,
          //     to_read_class(struct_read_packet, req_rd);
          // whose only consumer is the `uvm_info` on the next line:
          //   1. Wrong source. `struct_read_packet` is the OUTER-scope variable
          //      (declared at the top of axi4_read_task), written only by the
          //      BLOCKING branch. In this NON_BLOCKING branch it still holds
          //      whatever the last blocking read left there, so the print
          //      describes an unrelated transaction rather than the AR just
          //      driven. `struct_read_address_packet` is the packet this thread
          //      actually handed to axi4_read_address_channel_task().
          //   2. Wrong destination. `req_rd` is a CLASS MEMBER (line 46,
          //      `REQ req_wr, req_rd;`), shared by every iteration of this
          //      forever loop and by the sibling READ_DATA_CHANNEL thread. Since
          //      to_read_class() declares its second argument `output`, it
          //      constructs a fresh object and rebinds the member - a debug
          //      print silently repointing driver-wide state.
          // A local handle keeps the print truthful and side-effect free.
          axi4_master_seq_item_converter::to_read_class(struct_read_address_packet,req_rd_addr_dbg);
          `uvm_info(get_type_name(),$sformatf("READ_ADDRESS_THREAD::Checking struct packet = %p",req_rd_addr_dbg.sprint()),UVM_MEDIUM);
        end

        begin : READ_DATA_CHANNEL
          axi4_master_tx local_master_read_data_tx;
          axi4_read_transfer_char_s struct_read_data_packet;
          
          //Added the read_data_process to keep track of this read data channel thread
          //self is a static method which creates the read_data_process of type process
          read_data_process = process::self();
          
          //Taking a credit from the read channel. This credit is held until this
          //burst's RLAST has been claimed, so it is what bounds outstanding reads.
          read_channel_key.get(1);
          rd_data_inflight++;
          if(rd_data_inflight > rd_data_inflight_max) rd_data_inflight_max = rd_data_inflight;
          //Independent, protocol-bound corroboration: AR handshakes issued at this
          //port minus complete read bursts collected at it.
          if((axi4_master_drv_bfm_h.ar_issued_cnt - axi4_master_drv_bfm_h.r_burst_cnt) > rd_wire_outstanding_max)
            rd_wire_outstanding_max = axi4_master_drv_bfm_h.ar_issued_cnt - axi4_master_drv_bfm_h.r_burst_cnt;
          if(credit_trace_on)
            `uvm_info("AXI4_CREDIT",$sformatf("RDATA acquire inflight=%0d/%0d wire_outstanding=%0d",
                                               rd_data_inflight,outstanding_read_credits,
                                               axi4_master_drv_bfm_h.ar_issued_cnt - axi4_master_drv_bfm_h.r_burst_cnt),UVM_LOW)

          //Get method gets the packet and discards the packet from fifo
          //It throws an error if get is done into an empty fifo
          if(!axi4_master_read_fifo_h.is_empty()) begin
            axi4_master_read_fifo_h.get(local_master_read_data_tx);
          end
          else begin
            `uvm_error(get_type_name(),$sformatf("READ_DATA_THREAD::Cannot read from read fifo, as it is empty"));
          end

          //Converts the req packet to struct packet
          axi4_master_seq_item_converter::from_read_class(local_master_read_data_tx,struct_read_data_packet);
          `uvm_info(get_type_name(),$sformatf("READ_DATA_THREAD::Checking struct packet = %p",
                                               struct_read_data_packet),UVM_MEDIUM); 
          
          //Calls the read data channel task in bfm to sample the read data signals
          axi4_master_drv_bfm_h.axi4_read_data_channel_task(struct_read_data_packet,struct_cfg,axi4_master_agent_cfg_h.error_inject);
          `uvm_info(get_type_name(),$sformatf("READ_DATA_THREAD::Checking response struct packet = %p",
                                               struct_read_data_packet),UVM_FULL); 
          
          // Log error responses but complete the transaction normally
          begin
            bit error_response_detected = 1'b0;
            // Check rresp elements for the actual transaction length (arlen + 1 beats)
            for (int i = 0; i < (local_master_read_data_tx.arlen + 1); i++) begin
              if (struct_read_data_packet.rresp[i] == 2 || struct_read_data_packet.rresp[i] == 3) begin
                error_response_detected = 1'b1;
                `uvm_info("MASTER_DRIVER_DEBUG", $sformatf("Error response detected: rresp[%0d]=%0d (SLVERR/DECERR)", 
                         i, struct_read_data_packet.rresp[i]), UVM_LOW);
              end
            end
            
            if (error_response_detected) begin
              `uvm_info("MASTER_DRIVER_DEBUG", $sformatf("Received error response (rresp contains DECERR/SLVERR) for RID=0x%h - completing transaction normally", 
                       struct_read_data_packet.rid), UVM_LOW);
            end
          end

          //Returning the read credit: this burst is complete.
          rd_data_inflight--;
          if(credit_trace_on)
            `uvm_info("AXI4_CREDIT",$sformatf("RDATA release inflight=%0d/%0d wire_outstanding=%0d",
                                               rd_data_inflight,outstanding_read_credits,
                                               axi4_master_drv_bfm_h.ar_issued_cnt - axi4_master_drv_bfm_h.r_burst_cnt),UVM_LOW)
          read_channel_key.put(1);

          //Converting transactions into struct data type
          axi4_master_seq_item_converter::to_read_class(struct_read_data_packet,req_rd);

          `uvm_info(get_type_name(),$sformatf("READ_DATA_THREAD::Response_received_req_read_packet = \n %s",
                                               req_rd.sprint()),UVM_MEDIUM);
        end
      join_any

      //fine-grain control
      //status returns whether the process is FINISHED or WAITING or RUNNING.
      `uvm_info(get_type_name(), $sformatf("READ_TASK :: Out of fork_join : Before await read_addr.status()=%s ",
                                            read_addr_process.status()), UVM_FULL); 

      //Waiting for read address channel to complete 
      //As we don't have control on fork-join_any or fork-join_none processes,
      //the await method makes sure that it waits for the read address to complete
      read_addr_process.await();

      //status returns whether the process is FINISHED or WAITING or RUNNING.
      `uvm_info(get_type_name(), $sformatf("READ_TASK :: Out of fork_join : After await read_addr.status()=%s ",
                                            read_addr_process.status()), UVM_FULL); 
    end

    axi_read_seq_item_port.item_done();
  end
endtask : axi4_read_task

`endif

