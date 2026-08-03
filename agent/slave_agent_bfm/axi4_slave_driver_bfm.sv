`include "axi4_bus_config.svh"
`ifndef AXI4_SLAVE_DRIVER_BFM_INCLUDED_
`define AXI4_SLAVE_DRIVER_BFM_INCLUDED_

`include "axi4_bus_config.svh"

//--------------------------------------------------------------------------------------------
//Interface : axi4_slave_driver_bfm
//Used as the HDL driver for axi4
//It connects with the HVL driver_proxy for driving the stimulus
//--------------------------------------------------------------------------------------------
import axi4_globals_pkg::*;
interface axi4_slave_driver_bfm(input                     aclk    , 
                                input                     aresetn ,
                                //Write_address_channel
                                input [`AXI_ID_WIDTH-1:0]               awid    ,
                                input [ADDRESS_WIDTH-1:0] awaddr  ,
                                input [7: 0]              awlen   ,
                                input [2: 0]              awsize  ,
                                input [1: 0]              awburst ,
                                input [1: 0]              awlock  ,
                                input [3: 0]              awcache ,
                                input [2: 0]              awprot  ,
                                input [3: 0]              awqos   ,  
                                input [3: 0]              awregion,
                                input [`AXI_AWUSER_WIDTH-1: 0] awuser  ,
                                input                     awvalid ,
                                output reg	              awready ,

                                //Write_data_channel
                                input [DATA_WIDTH-1: 0]     wdata  ,
                                input [(DATA_WIDTH/8)-1: 0] wstrb  ,
                                input                       wlast  ,
                                input [`AXI_WUSER_WIDTH-1: 0]                wuser  ,
                                input                       wvalid ,
                                output reg	                wready ,

                                //Write Response Channel
                                output reg [`AXI_ID_WIDTH-1:0]            bid    ,
                                output reg [1:0]            bresp  ,
                                output reg [`AXI_BUSER_WIDTH-1:0]            buser  ,
                                output reg                  bvalid ,
                                input		                    bready ,

                                //Read Address Channel
                                input [`AXI_ID_WIDTH-1:0]                arid    ,
                                input [ADDRESS_WIDTH-1: 0]  araddr  ,
                                input [7:0]                 arlen   ,
                                input [2:0]                 arsize  ,
                                input [1:0]                 arburst ,
                                input [1:0]                 arlock  ,
                                input [3:0]                 arcache ,
                                input [2:0]                 arprot  ,
                                input [3:0]                 arqos   ,
                                input [3:0]                 arregion,
                                input [`AXI_ARUSER_WIDTH-1:0]                 aruser  ,
                                input                       arvalid ,
                                output reg                  arready ,

                                //Read Data Channel
                                output reg [`AXI_ID_WIDTH-1:0]                rid    ,
                                output reg [DATA_WIDTH-1: 0]    rdata  ,
                                output reg [1:0]                rresp  ,
                                output reg                      rlast  ,
                                output reg [`AXI_RUSER_WIDTH-1:0]                ruser  ,
                                output reg                      rvalid ,
                                input		                        rready  
                              ); 
                              
  //-------------------------------------------------------
  // Importing UVM Package 
  //-------------------------------------------------------
  import uvm_pkg::*;
  `include "uvm_macros.svh" 

  //-------------------------------------------------------
  // Importing axi4 slave driver proxy
  //-------------------------------------------------------
  import axi4_slave_pkg::axi4_slave_driver_proxy;

  //Variable : axi4_slave_driver_proxy_h
  //Creating the handle for proxy driver
  axi4_slave_driver_proxy axi4_slave_drv_proxy_h;
  
  reg [7: 0] i = 0;
  reg [7: 0] j = 0;
  reg [7: 0] a = 0;

  initial begin
    `uvm_info("axi4 slave driver bfm",$sformatf("AXI4 SLAVE DRIVER BFM"),UVM_LOW);
    // Initialize all AXI slave response signals to 0 at time 0 to avoid X propagation
    awready = 1'b0;
    wready  = 1'b0;
    bvalid  = 1'b0;
    bid     = '0;
    bresp   = '0;
    buser   = '0;
    arready = 1'b0;
    rvalid  = 1'b0;
    rid     = '0;
    rdata   = '0;
    rresp   = '0;
    rlast   = 1'b0;
    ruser   = '0;
  end

  string name = "AXI4_SLAVE_DRIVER_BFM";

  // Creating Memories for each signal to store each transaction attributes

  reg [`AXI_ID_WIDTH-1:0]     mem_awid   [2**LENGTH];
  reg [	ADDRESS_WIDTH-1: 0]	mem_waddr	  [2**LENGTH];
  reg [	7 : 0]	            mem_wlen	  [2**LENGTH];
  reg [	2 : 0]	            mem_wsize	  [2**LENGTH];
  reg [ 1	: 0]	            mem_wburst  [2**LENGTH];
  reg [ 3	: 0]	            mem_wqos    [2**LENGTH];
  bit                       mem_wlast   [2**LENGTH];
  reg [ 2	: 0]	            mem_wprot   [2**LENGTH];  // Added for AWPROT
  
  reg [`AXI_ID_WIDTH-1:0]     mem_arid   [2**LENGTH];
  reg [	ADDRESS_WIDTH-1: 0]	mem_raddr	  [2**LENGTH];
  reg [	7	: 0]	            mem_rlen	  [2**LENGTH];
  reg [	2	: 0]	            mem_rsize	  [2**LENGTH];
  reg [ 1	: 0]	            mem_rburst  [2**LENGTH];
  reg [ 3	: 0]	            mem_rqos    [2**LENGTH];
  reg [ 2	: 0]	            mem_rprot   [2**LENGTH];  // Added for ARPROT
  // AxUSER was never sampled here. The read/write ADDRESS phases captured
  // arid/araddr/arlen/arsize/arburst/arqos/arprot and stopped, so the manager
  // identity the Track-B sequences put in AxUSER (AXI4_MID_TAG) arrived at the
  // subordinate as zero on all 960 reads even though the fabric forwarded it
  // correctly on the wire.
  reg [`AXI_ARUSER_WIDTH-1:0] mem_ruser [2**LENGTH];
  reg [`AXI_AWUSER_WIDTH-1:0] mem_wuser_addr [2**LENGTH];

  // Per-transaction read-response bookkeeping (known-landmines #14), the read
  // twin of aw_resp_id_q / w_done_q.
  //
  // One entry is pushed by axi4_read_address_phase at the ARVALID && ARREADY
  // handshake edge, and axi4_read_data_phase pops one per read data burst. The
  // Nth read data phase therefore answers the Nth accepted read address, which
  // is the same transaction: AXI4 A5.3 requires read data for a given ID to be
  // returned in the order its addresses were issued, and this subordinate
  // returns them in acceptance order.
  //
  // What it replaces: the in-order branch of axi4_read_data_phase read
  // mem_arid[j1] / mem_rlen[j1] / mem_rsize[j1] with its OWN task-static `j1`,
  // while axi4_read_address_phase fills those arrays using the interface-scope
  // `reg [7:0] j`. Two independent free-running counters for one transaction --
  // the exact pattern landmine 1's Trap warns about. They only stay aligned
  // while AR and R run in strict lockstep; once a read is accepted while an
  // earlier read is still streaming data (which is what a real interconnect
  // produces), the burst is driven with another read's RID, beat count and
  // beat size. The types made it worse: `j` wraps at 256 while `j1` is a
  // 32-bit int wrapped by hand.
  typedef struct {
    bit [`AXI_ID_WIDTH-1:0] arid;
    bit [7:0]               arlen;
    bit [2:0]               arsize;
  } ar_capture_s;

  ar_capture_s ar_resp_q[$];

  // A3.1.2: nothing survives a reset into the next transaction. Same rule the
  // AW acceptance thread applies to aw_capture_q / aw_resp_id_q / w_done_q.
  always @(negedge aresetn) begin
    ar_resp_q.delete();
  end

  //-------------------------------------------------------
  // Task: wait_for_system_reset
  // Waiting for the system reset to be active low
  //-------------------------------------------------------

  task wait_for_system_reset();
    @(negedge aresetn);
    `uvm_info(name,$sformatf("SYSTEM RESET ACTIVATED"),UVM_NONE)
    awready <= 0;
    wready  <= 0;
    rvalid  <= 0;
    rlast   <= 0;
    bvalid  <= 0;
    arready <= 0;
    bid     <= 'bx;
    bresp   <= 'b0;
    buser   <= 'b0;
    rid     <= 'bx;
    rdata   <= 'b0;
    rresp   <= 'b0;
    ruser   <= 'b0;
    @(posedge aresetn);
    `uvm_info(name,$sformatf("SYSTEM RESET DE-ACTIVATED"),UVM_NONE)
  endtask 
  
  //-------------------------------------------------------
  // Task: axi_write_address_phase
  // Sampling the signals that are associated with write_address_channel
  //-------------------------------------------------------

//-------------------------------------------------------
// Write address acceptance
//
// AWREADY is owned by the background thread below, NOT by
// axi4_write_address_phase, and that is the whole point.
//
// The task used to assert AWREADY and RETURN, leaving it high until the next
// call. Since the proxy's write fork is a `join`, the next call only happens
// after the W and B phases have finished, so for the entire duration of a write
// the bus advertised "address accepted here" with nothing running to record an
// address: a second AWVALID completed a perfectly legal AWVALID && AWREADY
// handshake that no sampler saw. The subordinate then owed a response for a
// transaction it had never captured -- a silently dropped write, and
// multiple-outstanding writes unusable.
//
// The obvious repair (drop AWREADY after each handshake) is protocol-correct but
// throttles acceptance to one address per write turnaround, which starves any
// test whose stimulus depends on addresses being accepted while an earlier write
// is still in flight -- measured: axi4_qos_basic_priority_test stopped making
// progress entirely, 0 write data phases completed.
//
// So the other half of the invariant is implemented instead: AWREADY stays
// asserted whenever there is room to accept, and a sampler is ALWAYS armed. Every
// AWVALID && AWREADY handshake is captured at the handshake edge into
// aw_capture_q (and into the mem_* arrays exactly as before), and the task simply
// pops one. Nothing accepted is ever lost, AWREADY is never asserted without a
// sampler, and the acceptance rate is not tied to the write turnaround. It also
// keeps AW acceptance independent of the response phase, which is what stops a
// compliant manager (holds AWVALID until AWREADY) and a compliant subordinate
// (holds BVALID until BREADY) from deadlocking each other.
//
// The queue is bounded: when it is full AWREADY drops, which is ordinary AXI
// back-pressure rather than a silent drop.
//-------------------------------------------------------
  localparam int AW_ACCEPT_DEPTH = 16;

  typedef struct {
    bit [`AXI_ID_WIDTH-1:0]  awid;
    bit [ADDRESS_WIDTH-1:0]  awaddr;
    bit [7:0]                awlen;
    bit [2:0]                awsize;
    bit [1:0]                awburst;
    bit [3:0]                awqos;
    bit [2:0]                awprot;
    // AxUSER was never captured here, so the manager identity the Track-B
    // sequences carry in AWUSER (AXI4_MID_TAG) reached the subordinate as zero.
    bit [`AXI_AWUSER_WIDTH-1:0] awuser;
    // AWLOCK/AWCACHE/AWREGION were never captured either, and the consequence is
    // worse than a missing debug field: in SLAVE_MEM_MODE the proxy randomizes a
    // dummy axi4_slave_tx and the BFM then overwrites only the fields it
    // sampled, so every field NOT sampled here reached the response logic as the
    // dummy's value rather than as the value on the pins. AWLOCK is read at
    // slave/axi4_slave_driver_proxy.sv (exclusive-write branch), so an exclusive
    // write arrived as WRITE_NORMAL_ACCESS and was answered OKAY instead of
    // EXOKAY, and the exclusive monitor was never consulted. Captured at the
    // handshake edge with the rest of the address payload.
    //
    // AWLOCK is [1:0] on the pins (AXI3 legacy width). AXI4 (A7.2) defines bit 0
    // only, and both axi4_write_transfer_char_s.awlock and awlock_e are 1 bit,
    // so bit 0 IS the field - taking it explicitly rather than letting a width
    // mismatch decide.
    bit                      awlock;
    bit [3:0]                awcache;
    bit [3:0]                awregion;
  } aw_capture_s;

  aw_capture_s aw_capture_q[$];

  // Per-transaction write-response bookkeeping (known-landmines #14).
  //
  // aw_resp_id_q is a SECOND, independent record of the same AWVALID && AWREADY
  // handshakes, pushed at the same edge as aw_capture_q. aw_capture_q is consumed
  // by axi4_write_address_phase at the START of a proxy write iteration;
  // axi4_write_response_phase runs at the END of that iteration in a different
  // thread and needs the same record, so it cannot share the queue.
  //
  // w_done_q gets one entry (the beat count) each time a write data burst
  // terminates on WLAST, pushed by axi4_write_data_phase.
  //
  // The response phase pops one entry from each. That pairs the Nth completed
  // write data burst with the Nth accepted write address, which is the SAME
  // transaction: AXI4 (A3.4.1, write data interleaving removed) requires a
  // manager to send write data in the order it issued the addresses. Popping
  // w_done_q is also the AXI4 A3.3 rule that a write response must follow the
  // last write data transfer -- previously spelled `while(mem_wlast[j]!=1)`
  // against a free-running static counter.
  //
  // What this replaces, and why it had to go: the response phase used to read
  // `mem_awid[j]` / `mem_wlast[j]` with its OWN task-static `j`, while the
  // address phase filled those arrays with the interface-scope `i` and the data
  // phase marked wlast with the interface-scope `a`. Three independent counters
  // for one transaction; they only stay aligned while AW, W and B happen to run
  // in lockstep. Measured on axi4_id_multiple_writes_different_awid_test: `j`
  // sat one ahead of the data-phase index, so the B for write N was gated on
  // write N+1's WLAST and was emitted only after N+1's data (@502830 vs the
  // manager collecting bid=0xa at @502850, one full transaction late). A
  // blocking manager cannot feed the next write, so the chain broke on a
  // timeout and the last writes of a stream -- having no "next write" to unblock
  // them -- were never answered at all: 5 writes with no BID.
  //
  // Both queues are cleared by the reset branch of the acceptance thread below,
  // together with aw_capture_q, so nothing survives a reset into the wrong
  // transaction.
  bit [`AXI_ID_WIDTH-1:0] aw_resp_id_q[$];
  int                     w_done_q[$];

  // Wait states requested by the proxy for the NEXT acceptance. Applied as a gap
  // between accepted transfers (AWREADY low for N cycles after a handshake),
  // which is what the per-transaction `repeat(aw_wait_states)` produced on the
  // wire before.
  int aw_wait_states_req = 0;
  int aw_wait_cnt        = 0;

  initial begin
    aw_capture_q.delete();
    aw_resp_id_q.delete();
    w_done_q.delete();
    forever begin
      @(posedge aclk);
      if(aresetn === 1'b0) begin
        awready     <= 1'b0;
        aw_wait_cnt  = 0;
        aw_capture_q.delete();
        aw_resp_id_q.delete();
        w_done_q.delete();
      end
      else if(awvalid === 1'b1 && awready === 1'b1) begin
        // This edge IS the AWVALID && AWREADY handshake - capture it here, so an
        // address is turned into a transaction if and only if it was accepted.
        aw_capture_s aw_c;
        aw_c.awid   = awid;
        aw_c.awaddr = awaddr;
        aw_c.awlen  = awlen;
        aw_c.awsize = awsize;
        aw_c.awburst= awburst;
        aw_c.awqos  = awqos;
        aw_c.awprot = awprot;
        aw_c.awuser = awuser;
        aw_c.awlock = awlock[0];   // see the awlock note on aw_capture_s
        aw_c.awcache= awcache;
        aw_c.awregion=awregion;
        aw_capture_q.push_back(aw_c);
        // Same edge, second record: the response phase's copy of this accepted
        // address. See the aw_resp_id_q declaration.
        aw_resp_id_q.push_back(awid);

        mem_awid  [i] = awid   ;
        mem_waddr [i] = awaddr ;
        mem_wlen  [i] = awlen  ;
        mem_wsize [i] = awsize ;
        mem_wburst[i] = awburst;
        mem_wqos  [i] = awqos  ;
        mem_wprot [i] = awprot ;
        i = i+1;

        aw_wait_cnt = aw_wait_states_req;
        awready    <= (aw_wait_cnt == 0) && (aw_capture_q.size() < AW_ACCEPT_DEPTH);
      end
      else if(aw_wait_cnt > 0) begin
        aw_wait_cnt--;
        awready <= 1'b0;
      end
      else begin
        awready <= (aw_capture_q.size() < AW_ACCEPT_DEPTH);
      end
    end
  end

task axi4_write_address_phase(inout axi4_write_transfer_char_s data_write_packet);
    aw_capture_s aw_c;
    `uvm_info(name,"INSIDE WRITE_ADDRESS_PHASE",UVM_LOW)

    // Publish this transaction's wait-state request for the acceptance thread.
    aw_wait_states_req = data_write_packet.aw_wait_states;
    `uvm_info(name,$sformatf("Before DRIVING WRITE ADDRS WAIT STATES :: %0d",data_write_packet.aw_wait_states),UVM_HIGH);

    if(axi4_slave_drv_proxy_h.axi4_slave_write_addr_fifo_h.is_full()) begin
    //  `uvm_error("UVM_TLM_FIFO","FIFO is now FULL!")
    end

    // A reactive subordinate has no legitimate timeout on "am I being
    // addressed?" (landmine 11). Hang protection is the base test's
    // timeout_watchdog, not a fall-through that samples an idle bus.
    wait(aw_capture_q.size() > 0);
    aw_c = aw_capture_q.pop_front();

    `uvm_info("SLAVE_DRIVER_WADDR_PHASE", $sformatf("outside of awvalid"), UVM_MEDIUM);

   data_write_packet.awid    = aw_c.awid   ;
   data_write_packet.awaddr  = aw_c.awaddr ;
   data_write_packet.awlen   = aw_c.awlen  ;
   data_write_packet.awsize  = aw_c.awsize ;
   data_write_packet.awburst = aw_c.awburst;
   data_write_packet.awqos   = aw_c.awqos  ;
   data_write_packet.awprot  = aw_c.awprot ; // Assign AWPROT
   data_write_packet.awuser  = aw_c.awuser ; // Assign AWUSER
   // Observed request semantics must come from the pins, never from the proxy's
   // randomized dummy transaction - see the note on aw_capture_s.
   data_write_packet.awlock  = aw_c.awlock ; // Assign AWLOCK   (exclusive access)
   data_write_packet.awcache = aw_c.awcache; // Assign AWCACHE
   data_write_packet.awregion= aw_c.awregion;// Assign AWREGION

   `uvm_info("struct_pkt_debug",$sformatf("struct_pkt_wr_addr_phase = \n %0p",data_write_packet),UVM_HIGH)

  endtask: axi4_write_address_phase

  //-------------------------------------------------------
  // Task: axi4_write_data_phase
  // This task will sample the write data signals
  //-------------------------------------------------------
task axi4_write_data_phase (inout axi4_write_transfer_char_s data_write_packet, input axi4_transfer_cfg_s cfg_packet);
    static reg [7:0]i = 0;
    @(posedge aclk);
    `uvm_info(name,$sformatf("data_write_packet=\n%p",data_write_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("cfg_packet=\n%p",cfg_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("INSIDE WRITE DATA CHANNEL"),UVM_NONE)
    
    wready <= 0;

   // Same rule as the address phases (landmine 11): a reactive subordinate has
   // no legitimate timeout on "is the manager sending me write data?". The old
   // bounded wait `break`ed out and the code below then drove WREADY and
   // sampled beats off an idle bus, i.e. it manufactured write data for a burst
   // that had not started. Hang protection is the base test's timeout_watchdog.
   do begin
     @(posedge aclk);
   end while(wvalid !== 1'b1);

   // based on the wait_cycles we can choose to drive the wready
    `uvm_info("SLAVE_BFM_WDATA_PHASE",$sformatf("Before DRIVING WRITE DATA WAIT STATES :: %0d",data_write_packet.w_wait_states),UVM_HIGH);
    repeat(data_write_packet.w_wait_states)begin
      `uvm_info(name,$sformatf("DRIVING_WRITE_DATA_WAIT_STATES :: %0d",data_write_packet.w_wait_states),UVM_HIGH);
      @(posedge aclk);
      wready<=0;
    end

    wready <= 1 ;
    
    if(cfg_packet.qos_mode_type == ONLY_WRITE_QOS_MODE_ENABLE || cfg_packet.qos_mode_type == WRITE_READ_QOS_MODE_ENABLE) begin 
      forever begin
        // Unbounded on purpose: the beat below is only valid if a WVALID &&
        // WREADY handshake actually happened at this edge. Both sides of the
        // handshake are tested, so a beat is recorded if and only if it was
        // accepted (`!== 1'b1` also keeps an X out of the accept decision).
        do begin
          @(posedge aclk);
        end while(!(wvalid === 1'b1 && wready === 1'b1));

        data_write_packet.wdata[i] = wdata;
        data_write_packet.wstrb[i] = wstrb;
        i++;
        if(wlast === 1'b1)begin
          // This burst is complete. Hand one completion to the response phase so
          // it can bind a B to THIS transaction (see aw_resp_id_q / w_done_q).
          w_done_q.push_back(i);
          i=0;
          break;
        end
      end
    end
    else begin
      // Terminate the burst on WLAST, not on a remembered AWLEN.
      //
      // This loop used to run `mem_wlen[a]+1` times, where `a` is this task's
      // own free-running static counter while the address phase fills
      // mem_wlen[]/mem_awid[] using a DIFFERENT static counter. The two indices
      // only stay aligned while AW and W arrive in strict lockstep, which is
      // what 1:1 direct wiring happens to give. Behind any real DUT the AW/W
      // interleaving differs, the indices desynchronise, the loop reads a stale
      // beat count and waits forever: measured 5 write-data phases entered but
      // only 2 completed, so BVALID was never driven for the rest.
      //
      // AXI defines the end of a write burst as WLAST, so use that -- the same
      // shape the QoS branch above already uses correctly.
      for(int s = 0; ; s = s+1) begin
        // Unbounded on purpose. An idle reactive slave legitimately waits here
        // forever; the old `break` fell through into the sampling code below
        // and recorded a beat that never handshook, which then also satisfied
        // the WLAST test at random and terminated the burst early.
        // Both sides of the handshake, same rule as the QoS branch above.
        do begin
          @(posedge aclk);
        end while(!(wvalid === 1'b1 && wready === 1'b1));
         data_write_packet.wdata[s]=wdata;
         `uvm_info("slave_wdata",$sformatf("sampled_slave_wdata[%0d] = %0h",s,data_write_packet.wdata[s]),UVM_HIGH);
         data_write_packet.wstrb[s]=wstrb;
         `uvm_info("slave_wstrb",$sformatf("sampled_slave_wstrb[%0d] = %0d",s,data_write_packet.wstrb[s]),UVM_HIGH);

         if(wlast === 1'b1) begin
           // mem_wlast[a] is kept only for the debug message below; the response
           // phase no longer reads it (that indexed a free-running counter, not
           // this transaction -- known-landmines #14). The authoritative "this
           // burst finished" signal is the w_done_q entry pushed here.
           mem_wlast[a]            = 1'b1;
           data_write_packet.wlast = 1'b1;
           w_done_q.push_back(s+1);
           `uvm_info("slave_wlast",$sformatf("sampled_slave_wlast at beat %0d ,a=%0d",s,a),UVM_HIGH);
           break;
         end
       end
      `uvm_info(name,$sformatf("OUTSIDE WRITE DATA CHANNEL"),UVM_NONE)
      a++;
    end

   // WREADY MUST fall on the WLAST edge, not one edge later.
   //
   // This used to be `@(posedge aclk); wready <= 0;`. Control reaches here in
   // the active region of the very edge at which the WLAST beat handshook, so
   // that extra `@(posedge aclk)` left WREADY ASSERTED for one more clock with
   // no sampler behind it. If the manager already had the next burst's first
   // beat on the wire (back-to-back writes do), that edge was a perfectly legal
   // WVALID && WREADY handshake: the manager considered the beat delivered and
   // moved on, while this task had already broken out of its sampling loop.
   // The beat was consumed and never recorded.
   //
   // With the single-beat bursts this test issues, that swallows a WHOLE burst,
   // and the next call to this task then waits for a beat the manager has
   // already sent and will never repeat. Measured on
   // axi4_id_multiple_writes_different_awid_test: a data phase entered at 42510
   // and did not leave until 502790, i.e. it was completed by the NEXT write's
   // data; the subordinate ran one transaction behind from then on, its B for
   // AWID 0xa arrived at 502850 -- 1 ms after the manager gave up at 501450 --
   // and the last writes of each stream, having no successor to unblock them,
   // were never answered at all (5 x SB_INCOMPLETE_OUTSTANDING_AWID, plus the
   // 59-AW/55-W pipeline imbalance that is the same lost bursts counted on the
   // other side).
   //
   // Scheduling the deassert here (NBA at the WLAST edge) keeps the WLAST beat
   // accepted -- WREADY was high AT that edge -- and guarantees WREADY is low
   // at the following edge, so nothing can be accepted that no one samples.
   wready <= 1'b0;
   `uvm_info("WDBG",$sformatf("WDATA_PHASE_EXIT beats_done"),UVM_NONE)

  endtask : axi4_write_data_phase

// Track-B: transaction ID width must follow AXI_ID_WIDTH. Hard-coding [3:0]
// silently truncates the wider IDs a real interconnect emits (the NIC-400
// fabric appends source-port bits), so the slave echoes a BID/RID the fabric
// cannot match to any outstanding transaction and the transfer never retires.
  //-------------------------------------------------------
  // Task: axi4_write_response_phase
  // This task will drive the write response signals
  //-------------------------------------------------------
  
task axi4_write_response_phase(inout axi4_write_transfer_char_s data_write_packet,
    axi4_transfer_cfg_s struct_cfg,bit[`AXI_ID_WIDTH-1:0] bid_local);

    int b_cycles;
    bit b_timeout_reported;
    bit [`AXI_ID_WIDTH-1:0] this_awid;
    int                     this_beats;
    `uvm_info("WDBG",$sformatf("WRESP_PHASE_ENTER bid_local=0x%0h",bid_local),UVM_NONE)
    @(posedge aclk);

    // ---------------------------------------------------------------------
    // Bind this response to ITS OWN transaction (known-landmines #14).
    //
    // One entry is claimed from each bookkeeping queue: the oldest unanswered
    // accepted write address (aw_resp_id_q) and the oldest completed write data
    // burst (w_done_q). Both are filled at protocol events -- the AWVALID &&
    // AWREADY handshake edge and WLAST -- never by a counter, so the pairing
    // cannot drift the way `mem_awid[j]` / `mem_wlast[j]` did.
    //
    // Waiting for w_done_q here IS the old `while(mem_wlast[j]!=1)` gate, stated
    // against this transaction instead of index j: AXI4 A3.3 requires the write
    // response to follow the last write data transfer. It is not a fall-through
    // (landmine 11): nothing below is reached, and BVALID is never driven, until
    // a real WLAST and a real accepted address exist. Reset is the only other
    // exit and it abandons the phase without driving anything, which is the one
    // legal way out (A3.1.2).
    //
    // In practice the wait costs zero cycles: the proxy's WRITE_RESPONSE_CHANNEL
    // thread already does data_tx.await() before calling this task, so the WLAST
    // of this iteration's data phase has already happened. It is kept as an
    // explicit protocol precondition rather than an assumption about the proxy's
    // thread structure -- that assumption is exactly what the static counters
    // encoded.
    // ---------------------------------------------------------------------
    while(!(aw_resp_id_q.size() > 0 && w_done_q.size() > 0)) begin
      if(aresetn === 1'b0) begin
        `uvm_info(name,"ARESETn asserted while binding the write response to its transaction - phase abandoned, BVALID not driven",UVM_LOW)
        bvalid <= 1'b0;
        return;
      end
      @(posedge aclk);
    end
    this_awid  = aw_resp_id_q.pop_front();
    this_beats = w_done_q.pop_front();
    `uvm_info("WDBG",$sformatf("WRESP_PHASE_BOUND awid=0x%0h beats=%0d (aw_resp_id_q=%0d w_done_q=%0d remaining)",this_awid,this_beats,aw_resp_id_q.size(),w_done_q.size()),UVM_HIGH)

    if((struct_cfg.qos_mode_type == ONLY_WRITE_QOS_MODE_ENABLE) || (struct_cfg.qos_mode_type == WRITE_READ_QOS_MODE_ENABLE)) begin
      bid <= data_write_packet.bid; 
      bresp <= data_write_packet.bresp;
      buser <= data_write_packet.buser;
      bvalid <= 1;
    end
    else if((struct_cfg.slave_response_mode == ONLY_WRITE_RESP_OUT_OF_ORDER) || (struct_cfg.slave_response_mode == WRITE_READ_RESP_OUT_OF_ORDER)) begin 
      bid <= bid_local; 
      data_write_packet.bid <= bid_local; 
      bresp <= data_write_packet.bresp;
      buser <= data_write_packet.buser;
      bvalid <= 1;
    end
    else begin
     // AXI4 A3.2: BID is the AWID of the write being answered. That is
     // this_awid -- the address whose data burst just completed -- and NOT
     // mem_awid[j], which was whatever the response phase's own call counter
     // happened to point at.
     data_write_packet.bid = this_awid;
     `uvm_info("DEBUG_BRESP",$sformatf("BID = %0d",data_write_packet.bid),UVM_HIGH)
     `uvm_info(name,"INSIDE WRITE_RESPONSE_PHASE",UVM_LOW)

     bid  <= this_awid;
     bresp <= data_write_packet.bresp;
     buser<=data_write_packet.buser;
     bvalid <= 1;
     `uvm_info("DEBUG_BRESP",$sformatf("BID = %0d",this_awid),UVM_HIGH)
   end
    
    // AXI B-channel handshake.
    //
    // The previous form was `while(bready !== 1'b1) @(posedge aclk); ... bvalid <= 0;`.
    // When the manager already has BREADY asserted (a real interconnect asserts it
    // early) the loop ran zero iterations and consumed no clock edge, so the
    // `bvalid <= 1` above and the `bvalid <= 1'b0` below landed in the SAME time
    // step and the deassert won: BVALID was never observable on the bus and the
    // write never retired. `=== 0` also treated an X on BREADY as "ready".
    // Always consume at least one edge, then hold BVALID until BREADY is actually
    // sampled high.
    // AXI4 A3.2.1: BVALID, once asserted, must remain asserted until BVALID &&
    // BREADY. The wait is ended ONLY by the handshake or by reset, which is the
    // one legal way to abandon an asserted VALID (A3.1.2 requires all VALIDs low
    // while ARESETn is low).
    //
    // The 3000-cycle mark is a REPORT, not an exit, and it is reported ONCE.
    //
    // History, because this was a deliberate protocol violation for a while and
    // must not come back: this loop used to `break` at 3000 cycles straight into
    // `bvalid <= 1'b0`, i.e. the VIP itself deasserted VALID with no handshake.
    // The justification was that the manager only asserted BREADY from inside a
    // per-transaction task and had no outstanding-response collector, so a
    // response could sit on the bus with nothing able to accept it and both
    // sides waited forever (reproduced on
    // axi4_id_multiple_writes_different_awid_test). That justification is now
    // OBSOLETE: agent/master_agent_bfm/axi4_master_driver_bfm.sv carries a
    // STANDING B collector that drives BREADY from a free-running thread
    // whenever this port has room, independent of any per-transaction task.
    //
    // So the subordinate holds. A response that is still unaccepted after 3000
    // cycles now means either the manager's completed-response queue is full
    // (B_ACCEPT_DEPTH, ordinary back-pressure - it will drain) or a genuine
    // manager-side bookkeeping gap, and in the second case the run ends at the
    // base test's timeout_watchdog `uvm_fatal` with this warning as the last
    // evidence in the log. That is the correct division of labour: the watchdog
    // terminates deadlocks, the BFM never withdraws VALID.
    //
    // WARNING and not ERROR, deliberately: a stuck B is not a subordinate fault.
    // Attributing it to this agent would fail the test at the wrong end of the
    // bus, and known-landmines #5 (manager-side B-channel bookkeeping) is still
    // OPEN, so an error here would convert a known, tracked manager-side gap
    // into a red regression that points at the wrong file. The failure is not
    // silent either way - a real deadlock is fatal at the watchdog.
    b_cycles           = 0;
    b_timeout_reported = 1'b0;
    do begin
      @(posedge aclk);
      data_write_packet.wait_count_write_response_channel++;
      `uvm_info(name,$sformatf("inside_detect_bready = %0d",bready),UVM_HIGH)
      if(aresetn === 1'b0) begin
        `uvm_info(name,"ARESETn asserted during the write response phase - dropping BVALID (the only legal abandon)",UVM_LOW)
        break;
      end
      if(b_cycles++ > 3000 && !b_timeout_reported) begin
        `uvm_warning(name,$sformatf("BREADY still low %0d cycles after BVALID was asserted for bid=0x%0h - HOLDING BVALID (AXI4 A3.2.1); the manager-side B collector should be draining this, see known-landmines #5",b_cycles,this_awid))
        b_timeout_reported = 1'b1;
      end
    end while(bready !== 1'b1);
    `uvm_info(name,$sformatf("After_loop_of_Detecting_bready = %0d",bready),UVM_HIGH)
    bvalid <= 1'b0;

  endtask : axi4_write_response_phase

  //-------------------------------------------------------
  // Task: axi4_read_address_phase
  // This task will sample the read address signals
  //-------------------------------------------------------
// `automatic`: a task in an interface defaults to STATIC storage, so its locals and
// formal arguments are shared by every concurrent call. The subordinate READ path can
// re-enter this task across transactions - axi4_slave_driver_proxy::axi4_read_task()
// is `forever begin ... fork ... join_any` (proxy:715/777/1469) and after join_any it
// awaits only the address thread (`rd_addr.await()`, proxy:1474) before calling
// item_done(), so iteration N's read threads outlive iteration N's item.
//
// That is the same structure that was MEASURED corrupting the manager side: there,
// a re-entrant call overwrote the in-flight packet of a caller still waiting, which
// surfaced as "timeout waiting for a read burst with rid=0x6" while the proxy had
// just passed arid=0x7. No subordinate-side failure has been observed yet - this is
// the same one-word fix applied on structural grounds, not on a reproduced bug.
//
// The subordinate WRITE path does not need it: that fork closes with plain `join`
// (proxy:247/690), so transactions cannot overlap there.
task automatic axi4_read_address_phase (inout axi4_read_transfer_char_s data_read_packet, input axi4_transfer_cfg_s cfg_packet);
    @(posedge aclk);
    `uvm_info(name,$sformatf("data_read_packet=\n%p",data_read_packet),UVM_HIGH);
    `uvm_info(name,$sformatf("cfg_packet=\n%p",cfg_packet),UVM_HIGH);
    `uvm_info(name,$sformatf("INSIDE READ ADDRESS CHANNEL"),UVM_HIGH);

    // Ready can be HIGH even before we start to check
    // based on wait_cycles variable
    // Can make arready to zero
     arready <= 0;
    // Same defect as the write address phase, and this one was observable on the
    // bus. In SLAVE_MEM_MODE the proxy calls this task from a forever loop even
    // when the bus is idle. After 50000 idle cycles the old break fell through,
    // sampled araddr=0/arlen=0, and the proxy then drove a full read data phase:
    // a phantom RVALID no manager had requested. When the RREADY wait later timed
    // out, RVALID/RLAST were dropped mid-handshake and
    // slave_assertions.sv AXI_RD_STABLE_SIGNALS_CHECK fired -- eight times per
    // Track-B run, at exact 50000-cycle multiples.
    // Kept as a pre-test `while` (not do-while) so that an ARVALID already high on
    // entry is still accepted without burning an extra cycle, exactly as before.
    while(arvalid !== 1'b1) begin
      @(posedge aclk);
    end
   
    repeat(data_read_packet.ar_wait_states)begin
      `uvm_info(name,$sformatf("DRIVING_READ_ADDRS_WAIT_STATES :: %0d",data_read_packet.ar_wait_states),UVM_HIGH);
      @(posedge aclk);
      arready<=0;
    end

    `uvm_info("SLAVE_DRIVER_RADDR_PHASE", $sformatf("outside of arvalid"), UVM_NONE); 
    
    // Sample the values
    mem_arid 	[j]	  = arid  	;	
	  mem_raddr	[j] 	= araddr	;
	  mem_rlen 	[j]	  = arlen	  ;	
	  mem_rsize	[j] 	= arsize	;	
	  mem_rburst[j] 	= arburst ;	
	  mem_rqos[j] 	  = arqos   ;	
	  mem_rprot[j]    = arprot  ;   // Sample ARPROT
	  mem_ruser[j]    = aruser  ;   // Sample ARUSER (carries the manager identity)
    arready         <= 1      ;

    data_read_packet.arid    = mem_arid[j]     ;
    data_read_packet.araddr  = mem_raddr[j]    ;
    data_read_packet.arlen   = mem_rlen[j]     ;
    data_read_packet.arsize  = mem_rsize[j]    ;
    data_read_packet.arburst = mem_rburst[j]   ;
    data_read_packet.arqos   = mem_rqos[j]     ;
    data_read_packet.arprot  = mem_rprot[j]    ; // Assign ARPROT
    data_read_packet.aruser  = mem_ruser[j]    ; // Assign ARUSER

    // ARLOCK/ARCACHE/ARREGION were never sampled, and on the read side that is
    // the most damaging half of the missing-Ax-metadata defect. In
    // SLAVE_MEM_MODE the proxy randomizes a dummy axi4_slave_tx and this task
    // overwrites only the fields it samples, so every unsampled field reached
    // the response logic as the DUMMY's value - and axi4_slave_tx declares
    // `rand arlock_e arlock` / `rand arcache_e arcache`, so those two were
    // genuinely random. slave/axi4_slave_driver_proxy.sv reads arlock twice (it
    // arms an exclusive monitor on the read address path and upgrades RRESP to
    // READ_EXOKAY on the data path), so roughly half of all ordinary reads were
    // treated as READ_EXCLUSIVE_ACCESS: an exclusive monitor was armed for a
    // manager that never asked for one, and the manager was answered EXOKAY for
    // a normal read.
    //
    // Sampled directly rather than through a new mem_* array on purpose: those
    // arrays are indexed by the interface-scope free-running `j`, which is the
    // exact pattern known-landmines #14 exists to stop spreading. The values are
    // the ones in the block above - AxVALID payload must be stable until the
    // handshake (A3.2.1), so sampling here and accepting below reads the same
    // address phase.
    //
    // ARLOCK is [1:0] on the pins (AXI3 legacy width); AXI4 A7.2 defines bit 0
    // only and both axi4_read_transfer_char_s.arlock and arlock_e are 1 bit.
    data_read_packet.arlock  = arlock[0]       ; // Assign ARLOCK  (exclusive access)
    data_read_packet.arcache = arcache         ; // Assign ARCACHE
    data_read_packet.arregion= arregion        ; // Assign ARREGION
	  j = j+1                                    ;

    `uvm_info("mem_arid",$sformatf("mem_arid[%0d]=%0d",j,mem_arid[j]),UVM_HIGH)
    `uvm_info("mem_arid",$sformatf("arid=%0d",arid),UVM_HIGH)
    `uvm_info(name,$sformatf("struct_pkt_rd_addr_phase = \n %0p",data_read_packet),UVM_HIGH)

    // This edge IS the ARVALID && ARREADY handshake: ARREADY was scheduled high
    // above and the manager must hold ARVALID until it is sampled (A3.2.1), so
    // the address is accepted here. Record it for the read data phase at the
    // protocol event rather than letting that phase index an array with a
    // counter of its own. The payload recorded is the payload sampled above --
    // AxVALID payload must be stable until the handshake, so they are the same
    // values.
    @(posedge aclk);
    ar_resp_q.push_back('{arid   : data_read_packet.arid,
                          arlen  : data_read_packet.arlen,
                          arsize : data_read_packet.arsize});
    `uvm_info("RDBG",$sformatf("RADDR_PHASE_ACCEPTED arid=0x%0h arlen=%0d arsize=%0d (ar_resp_q=%0d)",data_read_packet.arid,data_read_packet.arlen,data_read_packet.arsize,ar_resp_q.size()),UVM_HIGH)
    arready <= 0;

  endtask: axi4_read_address_phase
    
  //-------------------------------------------------------
  // Task: axi4_read_data_channel_task
  // This task will drive the read data signals
  //-------------------------------------------------------
// `automatic` - see axi4_read_address_phase above. This one is the more exposed of the
// two: it has eight call sites (axi4_slave_driver_proxy.sv:923, 1049, 1185, 1281, 1350,
// 1362, 1440, 1447), every one of them inside the join_any fork.
task automatic axi4_read_data_phase (inout axi4_read_transfer_char_s data_read_packet, input axi4_transfer_cfg_s cfg_packet,response_mode_e out_of_order_enable);
    ar_capture_s this_ar;
    int rr_cycles;
    int rr_cycles2;
    bit rr_reported;
    bit rr_reported2;
    @(posedge aclk);

    // ---------------------------------------------------------------------
    // Claim the read address this burst is answering (known-landmines #14).
    //
    // One entry per accepted AR was pushed at the ARVALID && ARREADY handshake
    // edge, and exactly one read data phase runs per accepted address, so the
    // oldest unanswered entry IS this transaction's address. The pop happens in
    // BOTH branches so the queue cannot drift: the out-of-order / QoS branch
    // deliberately answers a DIFFERENT outstanding read (chosen by the proxy,
    // which is where that policy belongs) and takes its ARID/ARLEN/ARSIZE from
    // data_read_packet, but it still consumes one accepted address.
    //
    // Not a fall-through (landmine 11): nothing is sampled or driven off this
    // wait, because there is no wait. If the queue is empty -- which means a
    // read data phase ran without an accepted address, i.e. a proxy-side
    // structural break, not a bus event -- the packet's own fields are used and
    // the burst still completes with a legal handshake rather than driving X.
    // ---------------------------------------------------------------------
    if(ar_resp_q.size() > 0) begin
      this_ar = ar_resp_q.pop_front();
    end
    else begin
      this_ar.arid   = data_read_packet.arid;
      this_ar.arlen  = data_read_packet.arlen;
      this_ar.arsize = data_read_packet.arsize;
      `uvm_info(name,$sformatf("read data phase with no accepted read address outstanding - falling back to the packet's own arid=0x%0h arlen=%0d",this_ar.arid,this_ar.arlen),UVM_LOW)
    end
    `uvm_info("RDBG",$sformatf("RDATA_PHASE_BOUND arid=0x%0h arlen=%0d arsize=%0d (ar_resp_q=%0d remaining)",this_ar.arid,this_ar.arlen,this_ar.arsize,ar_resp_q.size()),UVM_HIGH)

    if((out_of_order_enable == RESP_IN_ORDER || out_of_order_enable ==
      ONLY_WRITE_RESP_OUT_OF_ORDER) && (cfg_packet.qos_mode_type == ONLY_WRITE_QOS_MODE_ENABLE ||
      cfg_packet.qos_mode_type == QOS_MODE_DISABLE)) begin
      // AXI4 A5.1: RID is the ARID of the read being answered -- that is
      // this_ar, the address claimed above, and NOT mem_arid[j1], which was
      // whatever this task's own call counter happened to point at.
      // Blocking, not `<=`. Two reasons, and the first one is a correctness fix
      // independent of the second:
      //   1. data_read_packet is an inout FORMAL - it is copied back to the caller
      //      when this task returns. A non-blocking write lands in the NBA region,
      //      so whether the caller saw this rid at all depended on the task not
      //      returning first. It is written exactly once and never read again inside
      //      this task (sole occurrence in the file), so a blocking write is what
      //      the copy-out actually needs.
      //   2. `task automatic` (see the header) forbids it outright - VCS rejects
      //      Error-[DTNBA-STRUCT] "Dynamic type ... cannot be used on the left-hand
      //      side of non blocking assignments".
      // The `<=` on rid/rdata/rresp/ruser/rvalid/rlast below are INTERFACE PINS and
      // stay non-blocking - that is the correct way to drive them.
      data_read_packet.rid = this_ar.arid;

      for(int i1=0, k1=0; i1<this_ar.arlen + 1; i1++) begin
        if(k1 == DATA_WIDTH/8) k1 = 0;
        rid  <= this_ar.arid;
        //Sending the rdata based on each byte lane
        //RHS: Is used to send Byte by Byte
        //LHS: Is used to shift the location for each Byte
        for(int l1=0; l1<(2**this_ar.arsize); l1++) begin
          rdata[8*k1+7 -: 8]<=data_read_packet.rdata[i1][8*l1+7 -: 8];
          k1++;
        end
        rresp<=data_read_packet.rresp[i1];

        ruser<=data_read_packet.ruser;
        rvalid<=1'b1;

        if((this_ar.arlen) == i1)begin
          rlast <= 1'b1;
        end

        // AXI4 A3.2.1: RVALID must stay asserted until RVALID && RREADY. Only
        // the handshake or reset ends this wait; the 50000 mark reports ONCE per
        // beat and keeps waiting.
        //
        // Same history as the B channel above, and the same obsolete
        // justification: this used to `break` into `rvalid <= 0; rlast <= 0`,
        // which is the violation slave_assertions.sv AXI_RD_STABLE_SIGNALS_CHECK
        // catches AND a beat the manager never received but the subordinate
        // counted as delivered. It was bounded because the manager drove RREADY
        // only from inside a per-transaction task that could abandon a read on
        // its own timeout. agent/master_agent_bfm/axi4_master_driver_bfm.sv now
        // carries a STANDING R collector that accepts beats per RID from a
        // free-running thread, so the subordinate holds and the base test's
        // timeout_watchdog owns real deadlocks. WARNING not ERROR for the same
        // reason as B: a stuck R is not a subordinate fault.
        rr_cycles   = 0;
        rr_reported = 1'b0;
        do begin
          @(posedge aclk);
          if(aresetn === 1'b0) break;
          if(rr_cycles++ > 50000 && !rr_reported) begin
            `uvm_warning(name,$sformatf("RREADY still low %0d cycles into beat %0d of the burst for rid=0x%0h - HOLDING RVALID/RLAST (AXI4 A3.2.1); the manager-side R collector should be draining this",rr_cycles,i1,this_ar.arid))
            rr_reported = 1'b1;
          end
        end while(rready !== 1'b1);
        rlast <= 1'b0;
        rvalid <= 1'b0;
        if(aresetn === 1'b0) begin
          `uvm_info(name,"ARESETn asserted during the read data phase - dropping RVALID/RLAST (the only legal abandon)",UVM_LOW)
          break;
        end
      end
     end
     else begin
      for(int i1=0, k1=0; i1<data_read_packet.arlen + 1; i1++) begin
        if(k1 == DATA_WIDTH/8) k1 = 0;
        rid  <= data_read_packet.arid;
        //Sending the rdata based on each byte lane
        //RHS: Is used to send Byte by Byte
        //LHS: Is used to shift the location for each Byte
        for(int l1=0; l1<(2**data_read_packet.arsize); l1++) begin
          rdata[8*k1+7 -: 8]<=data_read_packet.rdata[i1][8*l1+7 -: 8];
          k1++;
        end
        rresp<=data_read_packet.rresp[i1];
       
        ruser<=data_read_packet.ruser;
        rvalid<=1'b1;
        
        if((data_read_packet.arlen) == i1)begin
          rlast <= 1'b1;
        end
        
        // Identical rule to the in-order branch above: RVALID is held until the
        // RVALID && RREADY handshake, or until reset. The 50000 mark reports
        // once per beat and keeps waiting - it is NOT an exit.
        rr_cycles2   = 0;
        rr_reported2 = 1'b0;
        do begin
          @(posedge aclk);
          if(aresetn === 1'b0) break;
          // See the in-order branch above.
          if(rr_cycles2++ > 50000 && !rr_reported2) begin
            `uvm_warning(name,$sformatf("RREADY still low %0d cycles into beat %0d of the burst for rid=0x%0h - HOLDING RVALID/RLAST (AXI4 A3.2.1); the manager-side R collector should be draining this",rr_cycles2,i1,data_read_packet.arid))
            rr_reported2 = 1'b1;
          end
        end while(rready !== 1'b1);
        rlast <= 1'b0;
        rvalid <= 1'b0;
        if(aresetn === 1'b0) begin
          `uvm_info(name,"ARESETn asserted during the read data phase - dropping RVALID/RLAST (the only legal abandon)",UVM_LOW)
          break;
        end
      end
     end

  endtask : axi4_read_data_phase

endinterface : axi4_slave_driver_bfm

`endif
