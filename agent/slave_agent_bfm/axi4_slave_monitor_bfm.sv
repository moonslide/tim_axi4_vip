`ifndef AXI4_SLAVE_MONITOR_BFM_INCLUDED_
`define AXI4_SLAVE_MONITOR_BFM_INCLUDED_

`include "axi4_bus_config.svh"

//--------------------------------------------------------------------------------------------
//Interface : axi4_slave_monitor_bfm
//Used as the HDL monitor for axi4
//It connects with the HVL monitor_proxy for driving the stimulus
//--------------------------------------------------------------------------------------------
import axi4_globals_pkg::*;
// NOTE on the ID ports below: they MUST follow `AXI_ID_WIDTH, exactly like
// axi4_if does. They were hard-coded [3:0] while the interface was already
// `AXI_ID_WIDTH wide, so on the Track-B/NIC-400 build (AXI_ID_WIDTH=8) VCS
// silently connected 8-bit expressions to 4-bit ports (16 PCWM-W warnings):
// the fabric's egress source tag lives in exactly those dropped upper bits, so
// the monitor aliased every ingress port onto the same 4-bit ID and no checker
// could see corruption or X confined to them.
interface axi4_slave_monitor_bfm(input aclk, input aresetn,
                                //Write_address_channel
                                input [`AXI_ID_WIDTH-1:0]awid    ,
                                input [ADDRESS_WIDTH-1:0]awaddr  ,
                                input [7: 0]awlen   ,
                                input [2: 0]awsize  ,
                                input [1: 0]awburst ,
                                input [1: 0]awlock  ,
                                input [3: 0]awcache ,
                                input [2: 0]awprot  ,
                                input [3: 0]awqos   ,
                                input [3: 0]awregion,
                                input [`AXI_AWUSER_WIDTH-1: 0]awuser  ,
                                input awvalid ,
                                input awready ,

                                
                                //write_data_channel
                                input [DATA_WIDTH-1: 0]wdata  ,
                                input [(DATA_WIDTH/8)-1: 0]wstrb  ,
                                input wlast  ,
                                input [`AXI_WUSER_WIDTH-1: 0]wuser  ,
                                input wvalid ,
                                input wready ,

                                //Write Response Channel
                                input  [`AXI_ID_WIDTH-1:0]bid    ,
                                input  [1:0]bresp  ,
                                input  [`AXI_BUSER_WIDTH-1:0]buser  ,
                                input bvalid ,
                                input bready ,

                                //Read Address Channel
                                input [`AXI_ID_WIDTH-1:0] arid    ,
                                input [ADDRESS_WIDTH-1: 0]araddr  ,
                                input [7:0]arlen   ,
                                input [2:0]arsize  ,
                                input [1:0]arburst ,
                                input [1:0]arlock  ,
                                input [3:0]arcache ,
                                input [2:0]arprot  ,
                                input [3:0]arqos   ,
                                input [3:0]arregion,
                                input [`AXI_ARUSER_WIDTH-1:0]aruser  ,
                                input arvalid ,
                                input arready ,

                                //Read Data Channel
                                input  [`AXI_ID_WIDTH-1:0]rid    ,
                                input  [DATA_WIDTH-1: 0]rdata  ,
                                input  [1:0]rresp  ,
                                input  rlast  ,
                                input  [`AXI_RUSER_WIDTH-1:0]ruser  ,
                                input  rvalid ,
                                input  rready   
  
                               ); 
  //-------------------------------------------------------
  // Importing UVM Package 
  //-------------------------------------------------------
  import uvm_pkg::*;
  `include "uvm_macros.svh" 
  //-------------------------------------------------------
  // Importing axi4 Global Package slave package
  //-------------------------------------------------------
  import axi4_slave_pkg::axi4_slave_monitor_proxy;

  // Write-data beat index. This was `reg[3:0]`, i.e. it wrapped at 16, so any
  // burst longer than 16 beats overwrote req.wdata[0..15] again and again and
  // the slave-side payload was garbage past beat 15. AXI4 allows AWLEN up to
  // 255 (256 beats). Measured with AWLEN=141: master reconstructed 142 beats,
  // slave 142 beats of which only 16 distinct values were real.
  int i = 0;

  //Variable : axi4_slave_monitor_proxy_h
  //Creating the handle for proxy monitor
  axi4_slave_monitor_proxy axi4_slave_mon_proxy_h;

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


  //Printing axi4 slave monitor bfm
  initial begin
    `uvm_info("axi4 slave monitor bfm",$sformatf("AXI4 SLAVE MONITOR BFM"),UVM_LOW);
  end

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
  // aresetn is deliberately NOT in here: wait_for_aresetn() and the
  // r_acc/r_beat flush are asynchronous to ACLK by design.
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

  //-------------------------------------------------------
  // Task: wait_for_aresetn
  // Waiting for the system reset to be active low
  //-------------------------------------------------------

  task wait_for_aresetn();
    @(negedge aresetn);
    `uvm_info("FROM SLAVE MON BFM",$sformatf("SYSTEM RESET DETECTED"),UVM_HIGH)
   
    @(posedge aresetn);
    `uvm_info("FROM SLAVE MON BFM",$sformatf("SYSTEM RESET DEACTIVATED"),UVM_HIGH)
  endtask : wait_for_aresetn
  
  //-------------------------------------------------------
  // Task: axi4_slave_write_address_sampling
  // Used for sample the write address channel signals
  //-------------------------------------------------------
  task axi4_slave_write_address_sampling(output axi4_write_transfer_char_s req ,input axi4_transfer_cfg_s cfg);

    // See agent/master_agent_bfm/axi4_master_monitor_bfm.sv:209-220 and
    // known-landmines.md #46: this task has STATIC lifetime, so a declaration
    // initializer (`int aw_ws = 0;`) runs exactly once before time 0, not on
    // each call. Reset with an explicit statement instead.
    int aw_ws;
    aw_ws = 0;

    @(mon_cb);
    `uvm_info("FROM SLAVE MON BFM",$sformatf("from axi4_slave_write_address_sampling "),UVM_HIGH)

    while(mon_cb.awvalid !== 1) begin
      @(mon_cb);
    end

    while(mon_cb.awready !== 1) begin
      @(mon_cb);
      aw_ws++;
      `uvm_info("FROM SLAVE MON BFM",$sformatf("Inside while loop from axi4_slave_write_address_sampling"),UVM_HIGH)
    end

    `uvm_info("FROM SLAVE MON BFM",$sformatf("after while loop from axi4_slave_write_address_sampling "),UVM_HIGH)

    req.aw_wait_states = aw_ws;
    req.awid = mon_cb.awid;
    req.awaddr = mon_cb.awaddr;
    req.awlen = mon_cb.awlen;
    req.awsize = mon_cb.awsize;
    req.awburst = mon_cb.awburst;
    req.awlock = mon_cb.awlock;
    req.awcache = mon_cb.awcache;
    req.awprot = mon_cb.awprot;
    // AWUSER was never sampled here at all, while the read-address task right
    // below has always sampled ARUSER. The slave side therefore handed the
    // scoreboard a hard-coded zero AWUSER, and env/axi4_scoreboard.sv's
    // axuser_passthrough_chk_cfg comparison was vacuous: it compared the
    // master's AWUSER against that zero and could only ever "pass" while the
    // master also drove zero.
    req.awuser = mon_cb.awuser;
    `uvm_info("FROM SLAVE MON BFM",$sformatf("after while loop from axi4_slave_write_address_sampling req=%p ",req),UVM_HIGH)
  endtask

  //-------------------------------------------------------
  // Task: axi4_slave_write_data_sampling
  // Used for sample the write data channel signals
  //-------------------------------------------------------
  task axi4_slave_write_data_sampling(output axi4_write_transfer_char_s req ,input axi4_transfer_cfg_s cfg);
  
  forever begin
   // Static task lifetime -- see landmine #46 -- so reset by statement, not
   // by declaration initializer.
   int w_ws;
   w_ws = 0;
   // wait for valid
   do begin
     @(mon_cb);
   end while(mon_cb.wvalid !== 1);

   // wait for ready
   while(mon_cb.wready !== 1) begin
     @(mon_cb);
     w_ws++;
   end

   `uvm_info("FROM SLAVE MON BFM",$sformatf("Inside while loop......"),UVM_HIGH)
   req.wdata[i] = mon_cb.wdata;
   req.wstrb[i] = mon_cb.wstrb;
   req.wlast = mon_cb.wlast;
   req.wuser[i] = mon_cb.wuser;

   if(i == 0) req.w_wait_states = w_ws;

   `uvm_info("FROM SLAVE MON BFM write data",$sformatf("write datapacket wdata[%0d] = 'h%0x",i,req.wdata[i]),UVM_HIGH)
   `uvm_info("FROM SLAVE MON BFM write data",$sformatf("write datapacket wstrb[%0d] = 'h%0x",i,req.wstrb[i]),UVM_HIGH)
   `uvm_info("FROM SLAVE MON BFM write data",$sformatf("write datapacket wuser[%0d] = 'h%0x",i,req.wuser[i]),UVM_HIGH)
   if(req.wlast == 1)begin
     `uvm_info("FROM SLAVE MON BFM write data",$sformatf("Inside wlast write datapacket: %p",req),UVM_HIGH)
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
     // Static task lifetime -- see landmine #46 -- so reset by statement, not
     // by declaration initializer.
     int b_ws;
     b_ws = 0;

      @(mon_cb);
    while(mon_cb.bvalid !== 1) begin
      @(mon_cb);
    end
    while(mon_cb.bready !== 1) begin
      `uvm_info("FROM SLAVE MON BFM",$sformatf("values :: bvalid=%d & bready=%d",mon_cb.bvalid,mon_cb.bready),UVM_HIGH)
      @(mon_cb);
      b_ws++;
      `uvm_info("FROM SLAVE MON BFM",$sformatf("Inside while loop of write response sample"),UVM_HIGH)
    end
    `uvm_info("FROM SLAVE MON BFM",$sformatf("after while loop of write response "),UVM_HIGH)

    // Sample at the BVALID && BREADY handshake.  Advancing one more clock
    // here consumes the next response's payload when legal B responses are
    // back-to-back.
    req.bid      = mon_cb.bid;
    req.bresp    = mon_cb.bresp;
    // BUSER is a per-transaction field on B, like BID/BRESP -- sampled with
    // them and at the same instant, so it inherits whatever timing bid/bresp
    // already rely on rather than introducing a second, different one.
    // It was dropped entirely, so the slave-side BUSER handed to the
    // scoreboard was a hard-coded zero.
    req.buser    = mon_cb.buser;
    req.b_wait_states = b_ws;
    `uvm_info("FROM SLAVE MON BFM WRITE RESPONSE",$sformatf("write response packet: \n %p",req),UVM_HIGH)
  endtask

  //-------------------------------------------------------
  // Task: axi4_read_address_sampling
  // Used for sample the read address channel signals
  //-------------------------------------------------------  
  task axi4_read_address_sampling(output axi4_read_transfer_char_s req ,input axi4_transfer_cfg_s cfg);

    // Static task lifetime -- see landmine #46 -- so reset by statement, not
    // by declaration initializer.
    int ar_ws;
    ar_ws = 0;
    @(mon_cb);
    while(mon_cb.arvalid !== 1) begin
      @(mon_cb);
    end
    while(mon_cb.arready !== 1) begin
      @(mon_cb);
      ar_ws++;
      `uvm_info("FROM SLAVE MON BFM READ ADDR",$sformatf("INSIDE WHILE LOOP OF READ ADDRESS"),UVM_HIGH)
    end
    `uvm_info("FROM SLAVE MON BFM READ ADDR",$sformatf("AFTER WHILE LOOP OF READ ADDRESS"),UVM_HIGH)
    
    req.arid     = mon_cb.arid;
    req.araddr   = mon_cb.araddr;
    req.arlen    = mon_cb.arlen;
    req.arsize   = mon_cb.arsize;
    req.arburst  = mon_cb.arburst;
    req.arlock   = mon_cb.arlock;
    req.arcache  = mon_cb.arcache;
    req.arprot   = mon_cb.arprot;
    req.arqos    = mon_cb.arqos;
    req.arregion = mon_cb.arregion;
    req.aruser   = mon_cb.aruser;
    req.ar_wait_states = ar_ws;

    `uvm_info("FROM SLAVE MON BFM READ ADDR",$sformatf("datapacket =%p",req),UVM_HIGH)
  endtask

  //-------------------------------------------------------
  // Task: axi4_read_data_sampling
  // Used for sample the read data channel signals
  //-------------------------------------------------------
  task axi4_read_data_sampling(output axi4_read_transfer_char_s req ,input axi4_transfer_cfg_s cfg);
    int rid_key;
    int beat;

    forever begin

      // Static task lifetime -- see landmine #46 -- so reset by statement,
      // not by declaration initializer.
      int r_ws;
      r_ws = 0;
      // Wait for valid
      do begin
        @(mon_cb);
      end while(mon_cb.rvalid !== 1);

      // Wait for ready
      while(mon_cb.rready !== 1) begin
        @(mon_cb);
        r_ws++;
      end

      `uvm_info("FROM SLAVE MON BFM",$sformatf("after do_while loop of read data sample"),UVM_HIGH)

      // Route this beat to its own RID's accumulator, creating one on first sight.
      rid_key = int'(mon_cb.rid);
      if(!r_acc.exists(rid_key)) begin
        r_acc[rid_key]  = r_blank;
        r_beat[rid_key] = 0;
      end
      beat = r_beat[rid_key];

      r_acc[rid_key].rid         = mon_cb.rid;
      r_acc[rid_key].rdata[beat] = mon_cb.rdata;
      // Per beat, like rdata. This was an assignment to the WHOLE ruser array,
      // which packed the R-channel USER of one beat across the low beats'
      // slots instead of recording it against its own beat.
      r_acc[rid_key].ruser[beat] = mon_cb.ruser;
      // Per beat, like rdata/ruser.  axi4_read_transfer_char_s.rresp is a
      // per-beat packed array, but this used to assign the 2-bit value to the
      // WHOLE array, which lands it in element [0] and leaves every other beat
      // at READ_OKAY.  A burst whose error was on a non-final beat therefore
      // reported OKAY once the packet was collapsed downstream.
      r_acc[rid_key].rresp[beat] = mon_cb.rresp;
      r_acc[rid_key].rlast       = mon_cb.rlast;
      if(beat == 0) r_acc[rid_key].r_wait_states = r_ws;
      r_beat[rid_key] = beat + 1;

      `uvm_info("FROM SLAVE MON BFM READ DATA",$sformatf("DEBUG:SLAVE MON RID=%0d RDATA[%0d]=%0h",rid_key,beat,mon_cb.rdata),UVM_HIGH)

      if(mon_cb.rlast === 1) begin
       // Only THIS RID's burst is complete; any other RID still accumulating
       // keeps its own partial packet for a later call.
       req = r_acc[rid_key];
       r_acc.delete(rid_key);
       r_beat.delete(rid_key);
       `uvm_info("FROM SLAVE MON BFM read data",$sformatf("Inside RLAST Read Data Packet rid=%0d beats=%0d =%p",rid_key,beat+1,req),UVM_HIGH)
       break;
      end
      `uvm_info("FROM SLAVE MON BFM READ DATA",$sformatf("Read data beat rid=%0d beat=%0d rdata=%0h",rid_key,beat,mon_cb.rdata),UVM_HIGH)
   end
  endtask

endinterface : axi4_slave_monitor_bfm
`endif
