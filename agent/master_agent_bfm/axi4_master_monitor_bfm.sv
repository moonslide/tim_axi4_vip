`ifndef AXI4_MASTER_MONITOR_BFM_INCLUDED_
`define AXI4_MASTER_MONITOR_BFM_INCLUDED_

//--------------------------------------------------------------------------------------------
//Interface : axi4_master_monitor_bfm
//Used as the HDL monitor for axi4
//It connects with the HVL monitor_proxy for driving the stimulus
//--------------------------------------------------------------------------------------------
import axi4_globals_pkg::*;
`include "axi4_bus_config.svh"

// NOTE on the ID ports below: they MUST follow `AXI_ID_WIDTH, exactly like
// axi4_if does. They were hard-coded [3:0] while the interface was already
// `AXI_ID_WIDTH wide, so on the Track-B/NIC-400 build (AXI_ID_WIDTH=8) VCS
// silently connected 8-bit expressions to 4-bit ports (16 PCWM-W warnings):
// the fabric's egress source tag lives in exactly those dropped upper bits, so
// the monitor aliased every ingress port onto the same 4-bit ID and no checker
// could see corruption or X confined to them.
interface axi4_master_monitor_bfm(input bit aclk, input bit aresetn,
                                 //Write Address Channel Signals
                                 input  [`AXI_ID_WIDTH-1:0]awid,
                                 input  [ADDRESS_WIDTH-1:0]awaddr,
                                 input  [7:0]awlen,
                                 input  [2:0]awsize,
                                 input  [1:0]awburst,
                                 input  [1:0]awlock,
                                 input  [3:0]awcache,
                                 input  [2:0]awprot,
                                 input  [3:0]awqos,
                                 input  [3:0]awregion,
                                 input  [`AXI_AWUSER_WIDTH-1:0]awuser,
                                 input  awvalid,
                                 input  awready,

                                 //Write Data Channel Signals
                                 input  [DATA_WIDTH-1: 0]wdata,
                                 input  [(DATA_WIDTH/8)-1:0]wstrb,
                                 input  wlast,
                                 input  [`AXI_WUSER_WIDTH-1:0]wuser,
                                 input  wvalid,
                                 input  wready,

                                 //Write Response Channel Signals
                                 input  [`AXI_ID_WIDTH-1:0]bid,
                                 input  [1:0]bresp,
                                 input  [`AXI_BUSER_WIDTH-1:0]buser,
                                 input  bvalid,
                                 input  bready,

                                 //Read Address Channel Signals
                                 input  [`AXI_ID_WIDTH-1:0]arid,
                                 input  [ADDRESS_WIDTH-1: 0]araddr,
                                 input  [7:0]arlen,
                                 input  [2:0]arsize,
                                 input  [1:0]arburst,
                                 input  [1:0]arlock,
                                 input  [3:0]arcache,
                                 input  [2:0]arprot,
                                 input  [3:0]arqos,
                                 input  [3:0]arregion,
                                 input  [`AXI_ARUSER_WIDTH-1:0]aruser,
                                 input  arvalid,
                                 input  arready,
                                 //Read Data Channel Signals
                                 input  [`AXI_ID_WIDTH-1:0]rid,
                                 input  [DATA_WIDTH-1: 0]rdata,
                                 input  [1:0]rresp,
                                 input  rlast,
                                 input  [`AXI_RUSER_WIDTH-1:0]ruser,
                                 input  rvalid,
                                 input  rready  
                                );  

  //-------------------------------------------------------
  // Importing UVM Package 
  //-------------------------------------------------------
  import uvm_pkg::*;
  `include "uvm_macros.svh" 
  
  //-------------------------------------------------------
  // Importing axi4 Global Package master package
  //-------------------------------------------------------
  import axi4_master_pkg::axi4_master_monitor_proxy;
 
  //Variable : axi4_master_monitor_proxy_h
  //Creating the handle for proxy monitor
 
  axi4_master_monitor_proxy axi4_master_mon_proxy_h;

  // Which master port this interface belongs to, stamped by the monitor proxy
  // in its connect_phase. Deliberately a VARIABLE and not a parameter: making
  // the interface parameterised changes its TYPE, and every
  // `virtual axi4_master_monitor_bfm` in the config_db then fails to match
  // (Error-[ICVITFC], "type of the actual is ...#(9), type of the formal is
  // ...#(0)"). -1 means "not stamped yet".
  int master_index = -1;

  //-------------------------------------------------------
  // Per-RID read-data accumulators
  //
  // AXI4 permits read data of DIFFERENT RIDs to INTERLEAVE on the R channel;
  // only the beats of one ID are guaranteed to stay in order. This task used
  // to keep ONE packet and ONE static beat index, so with two bursts in
  // flight the beats of both were written into the same rdata[] slots and the
  // FIRST RLAST ended and published the merged result -- one transaction with
  // another's data, and the second burst's remaining beats then opening a
  // third bogus packet. Demux per RID instead and publish a burst only when
  // its OWN RLAST beat is seen.
  //
  // r_blank is the all-zero initial value handed to a newly seen RID: every
  // member of axi4_read_transfer_char_s is 2-state (bit/int), so an untouched
  // declaration is exactly the zero-initialised packet the old `output` formal
  // gave each call.
  //-------------------------------------------------------
  axi4_read_transfer_char_s r_acc[int];
  int                       r_beat[int];
  axi4_read_transfer_char_s r_blank;

  // AXI4 discards outstanding transactions across reset, so a partially
  // accumulated burst is stale the moment ARESETn drops; leaving it in place
  // would splice pre-reset beats onto the next burst that reuses the same RID.
  // (The single static beat index this replaced leaked across reset the same
  // way -- it just did it for every RID at once.)
  always @(negedge aresetn) begin
    r_acc.delete();
    r_beat.delete();
  end


  //-------------------------------------------------------
  // Task: wait_for_aresetn
  // Waiting for the system reset to be active low
  //-------------------------------------------------------
  //-------------------------------------------------------
  // Clocking block: mon_cb
  //
  // AXI4 A3.2.1 defines a transfer as occurring at the rising ACLK edge where
  // VALID and READY are both HIGH -- meaning the payload that met SETUP before
  // that edge.  Reading an interface signal directly inside a task woken by
  // `@(posedge aclk)` samples in the Active region instead, which races the
  // drivers: today it happens to give the right answer only because the
  // drivers assign with non-blocking assignments, so their updates land in the
  // NBA region after the monitor's read.  That is correct by accident, not by
  // construction -- any driver (or a real DUT hooked to these pins) that
  // updates differently would be sampled one cycle early.
  //
  // `default input #1step` samples in the PREPONED region, i.e. the value
  // immediately before the edge, which is exactly what the spec means by the
  // value that met setup.  Every sampling task below therefore waits on
  // @(mon_cb) and reads mon_cb.<signal>.
  //
  // aresetn is deliberately NOT in here: wait_for_aresetn(), the reset
  // broadcast and the r_acc/r_beat flush are asynchronous to ACLK by design.
  //-------------------------------------------------------
  clocking mon_cb @(posedge aclk);
    default input #1step;
    input awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot,
          awqos, awregion, awuser, awvalid, awready;
    input wdata, wstrb, wlast, wuser, wvalid, wready;
    input bid, bresp, buser, bvalid, bready;
    input arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot,
          arqos, arregion, aruser, arvalid, arready;
    input rid, rdata, rresp, rlast, ruser, rvalid, rready;
  endclocking

  task wait_for_aresetn();
    @(negedge aresetn);
    `uvm_info("FROM MASTER MON BFM",$sformatf("SYSTEM RESET DETECTED"),UVM_HIGH)
    @(posedge aresetn);
    `uvm_info("FROM MASTER MON BFM",$sformatf("SYSTEM RESET DEACTIVATED"),UVM_HIGH)
  endtask : wait_for_aresetn

  //-------------------------------------------------------
  // Reset broadcast
  //
  // wait_for_aresetn() above is called exactly once, at the top of the monitor
  // proxy's run_phase, so nothing in the environment observed a reset that
  // happened mid-test. The scoreboard needs that event: AXI4 discards
  // outstanding transactions across reset, so every expectation it is holding
  // becomes stale and must not be reported as a lost transaction.
  //
  // Deassertion (not assertion) is the trigger, so subscribers resynchronise
  // once the bus is usable again. Every master interface drives the same global
  // event; clearing twice is harmless, missing one is not.
  //-------------------------------------------------------
  always @(posedge aresetn) begin
    if ($time > 0) begin
      // The GLOBAL event stays: axi4_scoreboard restarts its channel tasks on
      // it and does not care which port reset.
      uvm_event_pool::get_global("axi4_sb_reset_e").trigger();
      // ...but this interface's aresetn is PER MASTER (top/hdl_top.sv:523 wires
      // aresetn_master[i]), and an independent reset of one master must not be
      // read as a reset of the others. A consumer that keeps per-source state --
      // axi4_performance_metrics holds per-(port, ID) latency FIFOs -- needs to
      // know WHICH port went down, so also announce it by index. Deleting every
      // port's state on one port's reset would zero the outstanding count of
      // masters that are still mid-transaction, which is how a busy bus gets
      // mistaken for an idle one.
      if (master_index >= 0)
        uvm_event_pool::get_global($sformatf("axi4_sb_reset_e_%0d", master_index)).trigger();
    end
  end

  //-------------------------------------------------------
  // Task: axi4_write_address_sampling
  // Used for sample the write address channel signals
  //-------------------------------------------------------
  task axi4_write_address_sampling(output axi4_write_transfer_char_s req ,input axi4_transfer_cfg_s cfg);

    int aw_ws = 0;
    @(mon_cb);
    while(mon_cb.awvalid !== 1) begin
      @(mon_cb);
    end
    while(mon_cb.awready !== 1) begin
      @(mon_cb);
      aw_ws++;
      `uvm_info("FROM MASTER MON BFM",$sformatf("Inside while loop......"),UVM_HIGH)
    end
    `uvm_info("FROM MASTER MON BFM",$sformatf("after while loop ......."),UVM_HIGH)
      
    req.awid    = mon_cb.awid ;
    req.awaddr  = mon_cb.awaddr;
    req.awlen   = mon_cb.awlen;
    req.awsize  = mon_cb.awsize;
    req.awburst = mon_cb.awburst;
    req.awlock  = mon_cb.awlock;
    req.awcache = mon_cb.awcache;
    req.awprot  = mon_cb.awprot;
    req.awqos   = mon_cb.awqos;
    req.awregion = mon_cb.awregion;
    req.awuser  = mon_cb.awuser;
    req.aw_wait_states = aw_ws;
    `uvm_info("FROM MASTER MON BFM",$sformatf("datapacket =%p",req),UVM_HIGH)
  endtask
  
  //-------------------------------------------------------
  // Task: axi4_write_data_sampling
  // Used for sample the write data channel signals
  //-------------------------------------------------------
  task axi4_write_data_sampling(output axi4_write_transfer_char_s req ,input axi4_transfer_cfg_s cfg);

    static int i = 0;

    forever begin
      int w_ws = 0;
      // Wait for valid
      do begin
        @(mon_cb);
      end while(mon_cb.wvalid !== 1);

      // Wait for ready
      while(mon_cb.wready !== 1) begin
        @(mon_cb);
        w_ws++;
      end
      `uvm_info("FROM MASTER MON BFM",$sformatf("After while loop write data......"),UVM_HIGH)
  
      req.wdata[i] = mon_cb.wdata;
      req.wstrb[i] = mon_cb.wstrb;
      req.wuser[i] = mon_cb.wuser;
      req.wlast    = mon_cb.wlast;
      if(i == 0) req.w_wait_states = w_ws;
  
      `uvm_info("FROM MASTER MON BFM write data",$sformatf("write datapacket wdata[%0d] = 'h%0x",i,req.wdata[i]),UVM_HIGH)
      `uvm_info("FROM MASTER MON BFM write data",$sformatf("write datapacket wstrb[%0d] = 'h%0x",i,req.wstrb[i]),UVM_HIGH)
      if(req.wlast == 1) begin
        `uvm_info("FROM MASTER MON BFM write data",$sformatf("Inside wlast write datapacket  =%p",req),UVM_HIGH)
        i = 0;
        break;
      end
     i++;
    end
  endtask 

  //-------------------------------------------------------
  // Task: axi4_write_response_sampling
  // Used for sample the write response channel signals
  //-------------------------------------------------------
  task axi4_write_response_sampling(output axi4_write_transfer_char_s req ,input axi4_transfer_cfg_s cfg);
    int b_ws = 0;
    `uvm_info("FROM MASTER MON BFM",$sformatf("AFTER WHILE LOOP OF WRITE RESPONSE"),UVM_HIGH)


    do begin
      @(mon_cb);
    end while(mon_cb.bvalid !== 1);

    while(mon_cb.bready !== 1) begin
      @(mon_cb);
      b_ws++;
    end

    req.bid      = mon_cb.bid;
    req.bresp    = mon_cb.bresp;
    // BUSER is a per-transaction B-channel field, exactly like BID/BRESP, and
    // is sampled at the same instant so it inherits their timing rather than
    // introducing a second one. It was never written here at all: the pin was
    // connected but dropped on the floor, so because axi4_write_transfer_char_s
    // .buser is 2-state the scoreboard saw master BUSER == 0 unconditionally.
    // env/axi4_scoreboard.sv really does compare BUSER, so correct non-zero
    // pass-through read as a MISMATCH and manager-side corruption of the pin
    // read as a PASS. The slave monitor BFM has always sampled it (see
    // agent/slave_agent_bfm/axi4_slave_monitor_bfm.sv, axi4_write_response_sampling).
    req.buser    = mon_cb.buser;
    req.b_wait_states = b_ws;
    `uvm_info("FROM MASTER MON BFM::WRITE RESPONSE",$sformatf("WRITE RESPONSE PACKET: \n %p",req),UVM_HIGH)
  endtask
  
  //-------------------------------------------------------
  // Task: axi4_read_address_sampling
  // Used for sample the read address channel signals
  //-------------------------------------------------------
  task axi4_read_address_sampling(output axi4_read_transfer_char_s req ,input axi4_transfer_cfg_s cfg);

    int ar_ws = 0;
    do begin
      @(mon_cb);
    end while(mon_cb.arvalid !== 1);

    while(mon_cb.arready !== 1) begin
      @(mon_cb);
      ar_ws++;
    end

    req.arid    = mon_cb.arid;
    req.araddr  = mon_cb.araddr;
    req.arlen   = mon_cb.arlen;
    req.arsize  = mon_cb.arsize;
    req.arburst = mon_cb.arburst;
    req.arlock  = mon_cb.arlock;
    req.arcache = mon_cb.arcache;
    req.arprot  = mon_cb.arprot;
    req.arqos   = mon_cb.arqos;
    req.arregion = mon_cb.arregion;
    req.aruser     = mon_cb.aruser;
    req.ar_wait_states = ar_ws;
    `uvm_info("FROM MASTER MON BFM",$sformatf("datapacket =%p",req),UVM_HIGH)
  endtask
  
  //-------------------------------------------------------
  // Task: axi4_read_data_sampling
  // Used for sample the read data channel signals
  //-------------------------------------------------------
  task axi4_read_data_sampling(output axi4_read_transfer_char_s req ,input axi4_transfer_cfg_s cfg);
    int rid_key;
    int beat;
    forever begin
      int r_ws = 0;
      // Wait for valid
      do begin
        @(mon_cb);
      end while(mon_cb.rvalid !== 1);

      // Wait for ready
      while(mon_cb.rready !== 1) begin
        @(mon_cb);
        r_ws++;
      end

      // Route this beat to its own RID's accumulator, creating one on first sight.
      rid_key = int'(mon_cb.rid);
      if(!r_acc.exists(rid_key)) begin
        r_acc[rid_key]  = r_blank;
        r_beat[rid_key] = 0;
      end
      beat = r_beat[rid_key];

      r_acc[rid_key].rid        = mon_cb.rid;
      r_acc[rid_key].rdata[beat] = mon_cb.rdata;
      // Per beat, like rdata. This was an assignment to the WHOLE ruser array,
      // which packed the R-channel USER of one beat across the low beats'
      // slots instead of recording it against its own beat.
      r_acc[rid_key].ruser[beat] = mon_cb.ruser;
      // Per beat, like rdata/ruser -- see the slave monitor for why the
      // whole-array assignment this replaces lost non-final-beat errors.
      r_acc[rid_key].rresp[beat] = mon_cb.rresp;
      r_acc[rid_key].rlast      = mon_cb.rlast;
      if(beat == 0) r_acc[rid_key].r_wait_states = r_ws;
      r_beat[rid_key] = beat + 1;

      if(mon_cb.rlast === 1) begin
        // Only THIS RID's burst is complete; any other RID still accumulating
        // keeps its own partial packet for a later call.
        req = r_acc[rid_key];
        r_acc.delete(rid_key);
        r_beat.delete(rid_key);
        `uvm_info("FROM MASTER MON BFM READ DATA",$sformatf("Inside RLAST Read Data Packet rid=%0d beats=%0d =%p",rid_key,beat+1,req),UVM_HIGH)
        break;
      end
      `uvm_info("FROM MASTER MON BFM READ DATA",$sformatf("Read data beat rid=%0d beat=%0d rdata=%0h",rid_key,beat,mon_cb.rdata),UVM_HIGH)
    end
  endtask
endinterface : axi4_master_monitor_bfm

`endif
