`include "axi4_bus_config.svh"
`ifndef AXI4_MASTER_DRIVER_BFM_INCLUDED_
`define AXI4_MASTER_DRIVER_BFM_INCLUDED_

//-------------------------------------------------------
// Importing global package
//-------------------------------------------------------
import axi4_globals_pkg::*;
`include "axi4_bus_config.svh"

//--------------------------------------------------------------------------------------------
// Interface : axi4_master_driver_bfm
//  Used as the HDL driver for axi4
//  It connects with the HVL driver_proxy for driving the stimulus
//--------------------------------------------------------------------------------------------
interface axi4_master_driver_bfm(input bit                      aclk, 
                                 input bit                      aresetn,
                                 //Write Address Channel Signals
                                 output reg               [`AXI_ID_WIDTH-1:0] awid,
                                 output reg [ADDRESS_WIDTH-1:0] awaddr,
                                 output reg               [7:0] awlen,
                                 output reg               [2:0] awsize,
                                 output reg               [1:0] awburst,
                                 output reg               [1:0] awlock,
                                 output reg               [3:0] awcache,
                                 output reg               [2:0] awprot,
                                 output reg               [3:0] awqos,
                                 output reg               [3:0] awregion,
                                 output reg [`AXI_AWUSER_WIDTH-1:0] awuser,
                                 output reg                     awvalid,
                                 input    	                    awready,
                                 //Write Data Channel Signals
                                 output reg    [DATA_WIDTH-1: 0] wdata,
                                 output reg [(DATA_WIDTH/8)-1:0] wstrb,
                                 output reg                      wlast,
                                 output reg [`AXI_WUSER_WIDTH-1:0] wuser,
                                 output reg                      wvalid,
                                 input                           wready,
                                 //Write Response Channel Signals
                                 input      [`AXI_ID_WIDTH-1:0] bid,
                                 input      [1:0] bresp,
                                 input      [`AXI_BUSER_WIDTH-1:0] buser,
                                 input            bvalid,
                                 output	reg       bready,
                                 //Read Address Channel Signals
                                 output reg               [`AXI_ID_WIDTH-1:0] arid,
                                 output reg [ADDRESS_WIDTH-1:0] araddr,
                                 output reg               [7:0] arlen,
                                 output reg               [2:0] arsize,
                                 output reg               [1:0] arburst,
                                 output reg               [1:0] arlock,
                                 output reg               [3:0] arcache,
                                 output reg               [2:0] arprot,
                                 output reg               [3:0] arqos,
                                 output reg               [3:0] arregion,
                                 output reg [`AXI_ARUSER_WIDTH-1:0] aruser,
                                 output reg                     arvalid,
                                 input                          arready,
                                 //Read Data Channel Signals
                                 input                  [`AXI_ID_WIDTH-1:0] rid,
                                 input      [DATA_WIDTH-1: 0] rdata,
                                 input                  [1:0] rresp,
                                 input                        rlast,
                                 input      [`AXI_RUSER_WIDTH-1:0] ruser,
                                 input                        rvalid,
                                 output	reg                   rready  
                                );  
  
  //-------------------------------------------------------
  // Importing UVM Package 
  //-------------------------------------------------------
  import uvm_pkg::*;
  `include "uvm_macros.svh" 

  //-------------------------------------------------------
  // Importing Global Package
  //-------------------------------------------------------
  import axi4_master_pkg::axi4_master_driver_proxy;

  //Variable: name
  //Used to store the name of the interface
  string name = "AXI4_MASTER_DRIVER_BFM"; 

  //Variable: axi4_master_driver_proxy_h
  //Creating the handle for master driver proxy
  axi4_master_driver_proxy axi4_master_drv_proxy_h;

  // One address transfer may occupy the AW / AR channel at a time.
  //
  // The proxy serialises the write-data and write-response threads
  // (write_data_channel_key, write_response_channel_key) and the read-data
  // thread (read_channel_key), but nothing serialises the ADDRESS threads. With
  // several outstanding writes they all drive the same AWID/AWADDR/AWVALID wires
  // and all wait on the same AWREADY, so ONE AWREADY pulse retires EVERY waiting
  // thread: N threads each believe their address was accepted when only one
  // address was ever on the bus. Each of those threads then queues a write
  // response task, so the manager ends up waiting for more B responses than the
  // subordinate owes it -- the manager-side response bookkeeping gap recorded in
  // known-landmines #5.
  //
  // It was invisible before because the two defects hid each other: the
  // subordinate left AWREADY asserted permanently, and the manager's B wait gave
  // up after 1000 cycles and fabricated the missing response. Fixing either one
  // alone exposes this. The channel is a shared resource, so the mutex belongs
  // here at the pin level, not in one proxy's threading policy.
  semaphore aw_channel_key = new(1);
  semaphore ar_channel_key = new(1);

  // The W channel needs the same pin-level mutex, for a stronger reason.
  //
  // The proxy serialises the write-data threads of NON_BLOCKING writes with
  // write_data_channel_key, but a BLOCKING write never goes through that path:
  // axi4_master_driver_proxy::axi4_write_task forks the address and data channel
  // tasks directly (`fork ... join`) and takes no key at all. So on any manager
  // that mixes the two transfer types -- axi4_id_multiple_writes_different_awid_test
  // drives 17 blocking and 28 non-blocking writes -- a blocking burst and a
  // non-blocking burst drive WDATA/WSTRB/WLAST/WVALID in the same time steps.
  // The beats interleave into one unintelligible burst, both threads count the
  // same WREADY handshakes as their own, and WLAST is asserted by whichever
  // finishes first, truncating the other. Measured symptom: "WREADY still low
  // after 50000 cycles on beat 1" and a subordinate whose write data phase
  // completes tens of thousands of cycles after the manager thought it had sent
  // the burst.
  // Same resource, same fix as AW: one write-data burst occupies W at a time.
  semaphore w_channel_key  = new(1);

  //-------------------------------------------------------
  // Standing write-response (B) collector
  //
  // BREADY is owned by the background thread below, NOT by
  // axi4_write_response_channel_task, and that is the whole point.
  //
  // Before this, the ONLY thing that ever asserted BREADY was that task, which
  // the proxy runs once per transaction: for a BLOCKING write it runs after that
  // transaction's own address AND data phases have finished, and for a
  // NON_BLOCKING write it is one branch of a fork whose sibling data thread is
  // serialised behind write_data_channel_key. So the manager's ability to accept
  // a response was gated on which per-transaction task happened to be running.
  //
  // Measured consequence (axi4_id_multiple_writes_different_awid_test, default
  // build, /tmp/verify_out/base/.../run.log): master[0]'s last blocking write
  // enters at 3455 and never completes, while the subordinate sits in its write
  // response phase holding BVALID and warns at 97210 that BREADY has been low for
  // 3000 cycles. The subordinate's write fork is a `join`, so it cannot start the
  // next write DATA phase until that response retires -- and the manager cannot
  // retire it because it is still inside the data phase of the NEXT write, which
  // is waiting for the WREADY that the subordinate will never drive. Both sides
  // wait forever. This became visible only once the two fall-throughs that used
  // to paper over it were removed (the subordinate dropping BVALID on a timeout,
  // and the manager fabricating a response it never received) -- neither may come
  // back: see known-landmines #5 and #11.
  //
  // The rejected repair is recorded in known-landmines #5: asserting BREADY
  // EARLIER inside the existing task fixed one baseline case and broke the
  // Track-B read path. It is not a handshake-order problem. The fix is to stop
  // coupling response ACCEPTANCE to per-transaction task scheduling at all --
  // exactly what was done on the subordinate's AW channel
  // (agent/slave_agent_bfm/axi4_slave_driver_bfm.sv, aw_capture_q).
  //
  // So: BREADY stays asserted whenever there is room to accept, every
  // BVALID && BREADY handshake is captured at the handshake edge into
  // b_capture_q, and axi4_write_response_channel_task POPS from that queue
  // instead of driving BREADY itself.
  //
  // ROUTING (how a collected response reaches its issuing transaction):
  // the queue is popped BY BID, not by arrival order --
  // `find_first_index with (item.bid == data_write_packet.awid)`. AXI4 A3.2 makes
  // BID equal to the AWID of the write being answered, so a packet can only ever
  // be completed with the response that belongs to it. Several writes sharing one
  // AWID are still correct because AXI4 requires same-ID responses in order and
  // find_first_index returns the OLDEST matching entry. A response whose BID
  // matches nothing the manager issued is never attributed to anybody: the
  // waiting task times out, reports, and returns bvalid=0 (NOT response-verified)
  // exactly as the abandon path already did. Nothing is ever fabricated.
  //
  // The queue is bounded: when it is full BREADY drops, which is ordinary AXI
  // back-pressure rather than a silent drop.
  //-------------------------------------------------------
  localparam int B_ACCEPT_DEPTH = 64;

  typedef struct {
    bit [`AXI_ID_WIDTH-1:0]    bid;
    bit                  [1:0] bresp;
    bit [`AXI_BUSER_WIDTH-1:0] buser;
  } b_capture_s;

  b_capture_s b_capture_q[$];

  // PER-RESPONSE BREADY back-pressure.
  //
  // master/axi4_master_tx.sv defines b_wait_states as the wait states BEFORE
  // driving BREADY, and the master monitor BFM measures exactly that: it waits
  // for BVALID, then counts posedges until BREADY is high
  // (agent/master_agent_bfm/axi4_master_monitor_bfm.sv, b_ws). A standing
  // collector cannot honour that by loading a counter AFTER the handshake -- by
  // then the response the delay was specified for has already been accepted with
  // zero wait states, and what appears on the wire is a gap in FRONT OF THE NEXT
  // response instead. With several writes outstanding it was worse still: one
  // global request, written by whichever transaction ran its response task last,
  // so the value applied had no relation to the response it landed on.
  //
  // The delay therefore travels WITH the request: axi4_write_address_channel_task
  // queues it into aw_outstanding_q next to the AWID at the AWVALID && AWREADY
  // handshake, and the collector spends it while BVALID is up and BREADY is still
  // low -- in front of the response that asked for it.
  //
  // BREADY is registered, so a delay can only be applied if BREADY is ALREADY low
  // when BVALID first appears. That is why the idle state of BREADY is low
  // whenever any outstanding write at this port asked for a non-zero delay
  // (b_wait_pending()). Two consequences, both deliberate:
  //   * when every outstanding write asked for 0 -- the default/unspecified case
  //     -- b_wait_pending() is 0, BREADY stands high exactly as it did before
  //     this rework, so the baseline wire behaviour is unchanged.
  //   * when a zero-delay response and a non-zero-delay write are outstanding at
  //     the same time, that zero-delay response is accepted one cycle late. A
  //     single shared READY cannot selectively back-pressure one ID, so the
  //     choice is between under- and over-applying; over-applying is the safe
  //     way round because the point of the knob is to CREATE back-pressure.
  // b_wait_armed keeps the count from being reloaded on every cycle that BVALID
  // stays up; it is cleared whenever the B channel is not mid-wait.
  int b_wait_cnt   = 0;
  bit b_wait_armed = 1'b0;

  // Outstanding-write bookkeeping for THIS manager port.
  //
  // aw_outstanding_q holds one entry per AWVALID && AWREADY handshake this
  // manager has completed and not yet had answered. AXI4 A3.2 requires BID to
  // equal the AWID of an outstanding write, so it is the manager's own record of
  // which responses it is entitled to receive, and the only thing that lets the
  // collector tell a routable response from an unroutable one. It now also
  // carries that write's requested BREADY delay - see above.
  //
  // aw_issued_cnt / b_event_cnt are the totals. When b_event_cnt has caught up
  // with aw_issued_cnt the subordinate owes this port nothing more, so a task
  // still waiting for its BID knows its response is never coming and can abandon
  // without burning the full bound. That matters because a subordinate that
  // answers the right NUMBER of writes with the WRONG id (known-landmines #14)
  // would otherwise stall every such write for 50000 cycles each.
  typedef struct {
    bit [`AXI_ID_WIDTH-1:0] awid;
    int                     b_wait_states;
  } aw_outstanding_s;

  aw_outstanding_s aw_outstanding_q[$];
  int aw_issued_cnt = 0;
  int b_event_cnt   = 0;

  // True while any write this port still has outstanding asked for BREADY wait
  // states. Keeps BREADY low between responses so that the delay of whichever
  // response arrives next can actually be applied in front of it.
  function automatic bit b_wait_pending();
    foreach(aw_outstanding_q[i]) begin
      if(aw_outstanding_q[i].b_wait_states > 0) return 1'b1;
    end
    return 1'b0;
  endfunction : b_wait_pending

  // Delay requested by the OLDEST outstanding write carrying this id - the same
  // entry axi4_write_response_channel_task will claim the response with, so the
  // delay and the transaction it belongs to can never drift apart. A BID that
  // answers nothing outstanding gets 0: it is dropped anyway (AXI4 A3.2, below),
  // and stalling BREADY for a response nobody owns would only wedge the channel.
  function automatic int b_wait_for_id(input bit [`AXI_ID_WIDTH-1:0] id);
    int idx_q[$];
    idx_q = aw_outstanding_q.find_first_index with (item.awid == id);
    return (idx_q.size() > 0) ? aw_outstanding_q[idx_q[0]].b_wait_states : 0;
  endfunction : b_wait_for_id

  // Set while x_inject_drive (BENCH-066) owns BREADY, so the collector does not
  // fight the X injection (the X_INJECT_BREADY_COVER property depends on seeing it).
  bit bready_x_inject_active = 1'b0;

  initial begin
    b_capture_q.delete();
    forever begin
      @(posedge aclk);
      if(aresetn === 1'b0) begin
        bready     <= 1'b0;
        b_wait_cnt   = 0;
        b_wait_armed = 1'b0;
        b_capture_q.delete();
        aw_outstanding_q.delete();
        aw_issued_cnt = 0;
        b_event_cnt   = 0;
      end
      else if(bready_x_inject_active) begin
        // x_inject_drive owns BREADY for its duration.
      end
      else if(bvalid === 1'b1 && bready === 1'b1) begin
        // This edge IS the BVALID && BREADY handshake - capture it here, so a
        // response is recorded if and only if it was actually accepted.
        b_capture_s b_c;
        int         own_q[$];
        b_c.bid   = bid;
        b_c.bresp = bresp;
        b_c.buser = buser;
        b_event_cnt++;

        // AXI4 A3.2: BID must be the AWID of a write this manager still has
        // outstanding. A response that answers nothing can never be routed to a
        // transaction, so queueing it would only wedge the collector (and, once
        // the queue filled, drop BREADY and resurrect the deadlock). It is
        // reported and dropped -- reported, because the manager silently
        // swallowing whatever id was on the wire is precisely what let the
        // subordinate-side id defect (known-landmines #14) stay invisible.
        own_q = aw_outstanding_q.find_first_index with (item.awid == b_c.bid);
        if(own_q.size() > 0) begin
          aw_outstanding_q.delete(own_q[0]);
          b_capture_q.push_back(b_c);
        end
        else begin
          `uvm_warning(name,$sformatf("write response bid=0x%0h answers no write outstanding at this manager port - dropped (AXI4 A3.2)",b_c.bid))
        end

        // This response's wait states (if any) have already been spent in front
        // of it, in the branch below, and its aw_outstanding_q entry - which is
        // what carried them - has just been removed. The next response arms its
        // own delay from its own entry.
        b_wait_cnt   = 0;
        b_wait_armed = 1'b0;
        bready <= (b_capture_q.size() < B_ACCEPT_DEPTH) && !b_wait_pending();
      end
      else if(bvalid === 1'b1) begin
        // BVALID is up and this port has not accepted it yet: THIS is where the
        // b_wait_states of the write being answered are spent, so the requested
        // back-pressure lands on the response it was specified for and the
        // monitor measures the value the sequence asked for.
        if(!b_wait_armed) begin
          b_wait_cnt   = b_wait_for_id(bid);
          b_wait_armed = 1'b1;
        end
        if(b_wait_cnt > 0) b_wait_cnt--;
        // BREADY is registered, so this edge's decision is the value seen on the
        // NEXT edge: dropping to zero here makes the handshake happen exactly
        // b_wait_states edges after the first edge on which BVALID was high,
        // which is what axi4_master_monitor_bfm counts.
        bready <= (b_wait_cnt == 0) && (b_capture_q.size() < B_ACCEPT_DEPTH);
      end
      else begin
        b_wait_armed = 1'b0;
        b_wait_cnt   = 0;
        bready <= (b_capture_q.size() < B_ACCEPT_DEPTH) && !b_wait_pending();
      end
    end
  end

  //-------------------------------------------------------
  // Standing read-data (R) collector
  //
  // The same defect and the same fix as the B collector above: RREADY used to be
  // driven only from inside axi4_read_data_channel_task, which the proxy runs per
  // transaction and gates behind that transaction's own AR phase, so an
  // outstanding read burst could only be drained by whichever task happened to be
  // running. Measured after the B collector landed: the write side of
  // axi4_id_multiple_writes_different_awid_test retired completely by t=1510050
  // and the run still would not terminate, with one READ_DATA activity and 17
  // abandons out to t=5520230 -- the stall had simply moved to R.
  //
  // R differs from B in one way that drives the whole design: a response is a
  // BURST, not a single item. Beats are captured as they handshake, but a burst
  // only becomes claimable when its RLAST beat arrives, so a task can never be
  // handed a partial burst. AXI4 permits read data of DIFFERENT ARIDs to be
  // interleaved (only same-ID data must stay in order and contiguous), so beats
  // are accumulated PER RID and a burst is completed independently of any other
  // ID's traffic.
  //
  // ROUTING: axi4_read_data_channel_task pops the burst whose RID equals the
  // packet's ARID (`find_first_index with (item.rid == data_read_packet.arid)`).
  // AXI4 A3.2 makes RID the ARID of the read being answered, so a packet is only
  // ever completed with the data that belongs to it; several reads sharing one
  // ARID are still correct because AXI4 requires same-ID data in order and
  // find_first_index returns the OLDEST matching burst. Nothing is fabricated: a
  // task that never finds its burst abandons having sampled no beats, exactly as
  // the previous timeout path did.
  //
  // Bounded, like B: when the completed-burst queue is full RREADY drops, which
  // is ordinary AXI back-pressure and not a silent drop. RVALID is never dropped
  // by this side (the manager drives no VALID here) and RREADY is only ever
  // deasserted between handshakes, so landmines #5 and #11 both hold.
  //
  // Landmine #37 mitigation (2026-08-05): with outstanding_read_credits at its
  // default of 1, only ONE axi4_read_data_channel_task claim thread is ever
  // active, and it waits for one SPECIFIC RID while AR issuance itself is not
  // credit-gated (see axi4_master_driver_proxy.sv's READ_DATA_CHANNEL fork
  // branch). A legally-reordering subordinate can therefore complete enough
  // OTHER-RID bursts to fill this collector before the awaited RID arrives;
  // once full, RREADY deasserts and the awaited burst can never be
  // transmitted, guaranteeing the fixed 50000-cycle escape and a dropped
  // transaction (measured: axi4_same_id_nonadjacent_reorder_test,
  // seed 1413795560, `rid=0x0` abandoned at the collector, then dropped on
  // arrival as "answers no read outstanding"). Raised 8->64 per the 20-seed
  // A/B that measured this depth eliminates the timeout on every probed seed
  // (fail-then-pass: same seed, same test, UVM_ERROR:1 -> UVM_ERROR:0).
  // Structural fix (crediting AR issuance itself, not just claiming) remains
  // tracked as VIP_future.md FW-6 / landmine #37 - this is the proven,
  // low-risk mitigation, not a claim that reordering can no longer overflow
  // ANY finite depth.
  //-------------------------------------------------------
  localparam int R_ACCEPT_DEPTH = 64;

  typedef struct {
    bit [`AXI_ID_WIDTH-1:0]                 rid;
    bit [2**LENGTH:0][DATA_WIDTH-1:0]       rdata;
    bit [2**LENGTH:0][1:0]                  rresp;
    bit [2**LENGTH:0][`AXI_RUSER_WIDTH-1:0] ruser;
    int                                     beats;
  } r_capture_s;

  // Completed bursts, oldest first. Only RLAST puts a burst in here.
  r_capture_s r_capture_q[$];
  // Beats of bursts still in flight, one accumulator per RID.
  r_capture_s r_accum_q[bit [`AXI_ID_WIDTH-1:0]];

  // PER-BURST RREADY back-pressure - the R-side counterpart of b_wait_cnt; see
  // the long note above aw_outstanding_s for why a post-handshake counter cannot
  // implement "wait states BEFORE driving RREADY" and why the delay now travels
  // with the request (here: queued into ar_outstanding_q at the
  // ARVALID && ARREADY handshake).
  //
  // R adds one rule that B does not need: r_wait_states is a property of the
  // FIRST beat only. axi4_master_monitor_bfm records it from beat 0
  // (`if(i == 0) req.r_wait_states = r_ws`), and the counter this replaces
  // likewise only ever inserted its gap at RLAST, never inside a burst.
  // Mid-burst back-pressure is DIFFERENT, explicitly requested stimulus
  // (BENCH-065): r_stall_beat / r_stall_cycles on the transaction, carried in
  // ar_outstanding_q like r_wait_states and armed into this same counter pair
  // at the handshake of the beat before the requested one (see the R collector
  // below). With no such request RREADY is held asserted for as long as any
  // burst is mid-flight, exactly as before (see r_default_ready).
  int r_wait_cnt   = 0;
  bit r_wait_armed = 1'b0;
  // Total R beats accepted at this port. A task uses it to tell "the channel is
  // busy, my burst is still coming" from "the channel is idle" without having to
  // watch the raw wire.
  int r_event_cnt = 0;
  // See bready_x_inject_active.
  bit rready_x_inject_active = 1'b0;

  // Outstanding-read bookkeeping, the exact counterpart of aw_outstanding_q /
  // aw_issued_cnt: one entry per ARVALID && ARREADY handshake not yet answered,
  // so a waiting task can tell "my burst is still owed" from "the subordinate has
  // already answered everything I asked for, so it is never coming". It carries
  // that read's requested RREADY delay for the same reason the write side does.
  // r_stall_beat / r_stall_cycles (BENCH-065): the requested MID-BURST stall,
  // validated at the AR handshake (see axi4_read_address_channel_task) so that
  // an entry in this queue is always either "no request" (-1 / 0) or a legal
  // one (1 <= beat <= arlen, 0 < cycles <= R_BEAT_STALL_MAX).
  // NOTE: this struct is built with a NAMED aggregate literal at its only push
  // site. Keep it that way - a positional '{a, b} literal breaks at compile
  // time every time a field is added here.
  typedef struct {
    bit [`AXI_ID_WIDTH-1:0] arid;
    int                     r_wait_states;
    int                     r_stall_beat;
    int                     r_stall_cycles;
  } ar_outstanding_s;

  ar_outstanding_s ar_outstanding_q[$];
  int ar_issued_cnt  = 0;
  int r_burst_cnt    = 0;

  // Read-data claim escape (axi4_read_data_channel_task): after this many
  // cycles without its burst a claim task abandons. Named so the mid-burst
  // stall bound can be checked against it below.
  localparam int R_CLAIM_ESCAPE_CYCLES = 50000;

  //-------------------------------------------------------
  // BENCH-065: mid-burst RREADY stall request log for the MONITOR.
  //
  // The monitor BFM measures the stall on the pins, but it cannot know what
  // was REQUESTED - r_stall_beat/r_stall_cycles have no wire representation
  // (exactly like r_wait_states, which the monitor also only ever MEASURES).
  // The request-gated coverage witness needs both on one packet, so every
  // ARVALID && ARREADY handshake appends the (validated) request here, and
  // axi4_master_monitor_proxy pops the OLDEST entry carrying the RID of each
  // completed burst it publishes. That is the same same-ID in-order rule the
  // R collector itself relies on (AXI4 A5.3), so with a compliant subordinate
  // the popped entry is the burst's own request; entries are pushed for EVERY
  // AR (with -1 for "no request") precisely so the two sides stay in lockstep
  // even when only some reads ask for a stall.
  // Only the monitor pops. The driver's abandon/timeout path never touches
  // this log (it is not bookkeeping the driver acts on), so a burst that
  // arrives after its claim task gave up is still attributed correctly. The
  // only way an entry can go stale is a read the subordinate never answers at
  // all; that is reported by the claim task already, and the size warning
  // below makes a systematic leak visible.
  //-------------------------------------------------------
  typedef struct {
    bit [`AXI_ID_WIDTH-1:0] arid;
    int                     r_stall_beat;
    int                     r_stall_cycles;
  } r_stall_req_s;

  r_stall_req_s r_stall_req_log[$];
  localparam int R_STALL_REQ_LOG_WARN = 4096;

  function automatic bit pop_r_stall_request(input  bit [`AXI_ID_WIDTH-1:0] id,
                                             output int beat, output int cycles);
    int idx_q[$];
    idx_q = r_stall_req_log.find_first_index with (item.arid == id);
    if(idx_q.size() == 0) begin
      beat   = -1;
      cycles = 0;
      return 1'b0;
    end
    beat   = r_stall_req_log[idx_q[0]].r_stall_beat;
    cycles = r_stall_req_log[idx_q[0]].r_stall_cycles;
    r_stall_req_log.delete(idx_q[0]);
    return 1'b1;
  endfunction : pop_r_stall_request

  // Cycles to hold RREADY low in front of beat `beat` of the OLDEST
  // outstanding read carrying `id` - the entry the claim task will use, so the
  // stall and the transaction it belongs to can never drift apart (same rule
  // as r_wait_for_id). 0 unless that entry asked for exactly this beat.
  function automatic int r_stall_for_id(input bit [`AXI_ID_WIDTH-1:0] id, input int beat);
    int idx_q[$];
    idx_q = ar_outstanding_q.find_first_index with (item.arid == id);
    if(idx_q.size() == 0) return 0;
    if(ar_outstanding_q[idx_q[0]].r_stall_beat != beat) return 0;
    return ar_outstanding_q[idx_q[0]].r_stall_cycles;
  endfunction : r_stall_for_id

  // Cycles the R collector must hold RREADY low after the handshake it has just
  // completed (armed in that branch, see below). Interface-scope on purpose:
  // block-local declaration initializers in this static context run once,
  // not per iteration (see axi4_master_monitor_bfm.sv for the measured leak).
  int r_stall_next = 0;

  // The declared stall policy must stay clear of the claim escape: at most
  // OUTSTANDING_FIFO_DEPTH reads are truly in flight and each may stall once,
  // so this product is the worst case a waiting claim task can see ahead of
  // its own burst. Both constants have drifted independently before
  // (R_ACCEPT_DEPTH 8 -> 64 for landmine #37); this makes such a drift loud.
  initial begin
    if(R_BEAT_STALL_MAX * OUTSTANDING_FIFO_DEPTH >= R_CLAIM_ESCAPE_CYCLES) begin
      `uvm_fatal(name,$sformatf("R_BEAT_STALL_MAX (%0d) * OUTSTANDING_FIFO_DEPTH (%0d) = %0d reaches the read-data claim escape of %0d cycles - a legal stall could be reported as an abandoned burst (landmine #37)",
                                R_BEAT_STALL_MAX,OUTSTANDING_FIFO_DEPTH,R_BEAT_STALL_MAX*OUTSTANDING_FIFO_DEPTH,R_CLAIM_ESCAPE_CYCLES))
    end
  end

  // Counterpart of b_wait_pending().
  function automatic bit r_wait_pending();
    foreach(ar_outstanding_q[i]) begin
      if(ar_outstanding_q[i].r_wait_states > 0) return 1'b1;
    end
    return 1'b0;
  endfunction : r_wait_pending

  // Delay requested by the OLDEST outstanding read carrying this id - the entry
  // axi4_read_data_channel_task will claim the burst with. Counterpart of
  // b_wait_for_id(), including the "no matching outstanding read -> 0" rule.
  function automatic int r_wait_for_id(input bit [`AXI_ID_WIDTH-1:0] id);
    int idx_q[$];
    idx_q = ar_outstanding_q.find_first_index with (item.arid == id);
    return (idx_q.size() > 0) ? ar_outstanding_q[idx_q[0]].r_wait_states : 0;
  endfunction : r_wait_for_id

  // Idle/inter-beat value of RREADY.
  //   * queue full            -> back-pressure, as before (bounded collector).
  //   * a burst is mid-flight -> stay asserted. r_wait_states is a beat-0
  //     property, so a burst that has already had beats accepted must not be
  //     stalled; this is also what the previous code did (its gap counter was
  //     only ever loaded at RLAST).
  //   * otherwise             -> low if any outstanding read asked for a delay,
  //     so that the delay can be applied in front of the first beat. With every
  //     r_wait_states at 0 this is unconditionally 1, i.e. the pre-rework
  //     standing-RREADY behaviour.
  // Known limit: if a subordinate INTERLEAVES read data, the first beat of a new
  // burst can arrive while another burst is mid-flight and RREADY is therefore
  // held high, so that burst's r_wait_states are not applied. One shared RREADY
  // cannot back-pressure one RID and not another, and not stalling a burst that
  // is already being accepted is the more important of the two properties.
  // The same limit applies to a mid-burst stall (BENCH-065): it is armed after
  // a handshake of the requesting RID and holds the PORT's RREADY low for the
  // requested cycles, so if the subordinate interleaves and presents another
  // RID's beat next, that beat is the one that waits and the requesting RID's
  // own beat is then accepted without back-pressure. Protocol-legal either way
  // (a manager may deassert RREADY at any time); the monitor's witness is
  // gated on the REQUESTING transaction, so the interleaved case reads as
  // "not exercised", never as a false hit.
  function automatic bit r_default_ready();
    if(r_capture_q.size() >= R_ACCEPT_DEPTH) return 1'b0;
    if(r_accum_q.size() > 0)                 return 1'b1;
    return !r_wait_pending();
  endfunction : r_default_ready

  initial begin
    r_capture_q.delete();
    r_accum_q.delete();
    forever begin
      @(posedge aclk);
      if(aresetn === 1'b0) begin
        rready     <= 1'b0;
        r_wait_cnt   = 0;
        r_wait_armed = 1'b0;
        r_capture_q.delete();
        r_accum_q.delete();
        r_event_cnt   = 0;
        ar_outstanding_q.delete();
        ar_issued_cnt = 0;
        r_burst_cnt   = 0;
        r_stall_req_log.delete();
        r_stall_next  = 0;
      end
      else if(rready_x_inject_active) begin
        // x_inject_drive owns RREADY for its duration.
      end
      else if(rvalid === 1'b1 && rready === 1'b1) begin
        // This edge IS the RVALID && RREADY handshake - a beat is recorded if and
        // only if it was actually accepted.
        bit [`AXI_ID_WIDTH-1:0] r_id;
        r_capture_s             r_acc;
        r_id = rid;
        if(r_accum_q.exists(r_id)) begin
          r_acc = r_accum_q[r_id];
        end
        else begin
          r_acc       = '{default:0};
          r_acc.rid   = r_id;
          r_acc.beats = 0;
        end

        if(r_acc.beats <= 2**LENGTH) begin
          r_acc.rdata[r_acc.beats] = rdata;
          r_acc.rresp[r_acc.beats] = rresp;
          r_acc.ruser[r_acc.beats] = ruser;
          r_acc.beats++;
        end
        else begin
          `uvm_warning(name,$sformatf("read burst rid=0x%0h exceeded %0d beats without RLAST - further beats not recorded",r_id,2**LENGTH))
        end
        r_event_cnt++;

        if(rlast === 1'b1) begin
          // Only now is the burst complete and claimable.
          int r_own_q[$];
          r_burst_cnt++;
          r_own_q = ar_outstanding_q.find_first_index with (item.arid == r_id);
          if(r_own_q.size() > 0) begin
            ar_outstanding_q.delete(r_own_q[0]);
            r_capture_q.push_back(r_acc);
          end
          else begin
            // AXI4 A3.2: RID must be the ARID of a read this manager still has
            // outstanding. A burst that answers nothing can never be routed, so
            // queueing it would only wedge the collector and eventually drop
            // RREADY. Reported and dropped rather than silently absorbed.
            `uvm_warning(name,$sformatf("read burst rid=0x%0h answers no read outstanding at this manager port - dropped (AXI4 A3.2)",r_id))
          end
          r_accum_q.delete(r_id);
          r_stall_next = 0;
        end
        else begin
          r_accum_q[r_id] = r_acc;
          // BENCH-065: the beat just accepted was index r_acc.beats-1 of THIS
          // RID's burst, so its next beat is index r_acc.beats. If the oldest
          // outstanding read with this RID asked for a stall in front of
          // exactly that beat, arm it NOW, at the handshake, and drop RREADY
          // on this very edge. Arming here rather than by scanning inside
          // r_default_ready() is what makes the mechanism safe against
          // interleaving: while the countdown runs RREADY is low, so NO other
          // RID can complete a handshake and reach this branch to reset it,
          // and the `!r_wait_armed` guard in the branch below keeps another
          // RID's presented beat from re-arming it. r_default_ready() itself is
          // untouched, so with no request anywhere this branch is exactly what
          // it was before.
          r_stall_next = r_stall_for_id(r_id, r_acc.beats);
        end
        if(r_stall_next > 0) begin
          r_wait_cnt   = r_stall_next;
          r_wait_armed = 1'b1;
          rready <= 1'b0;
        end
        else begin
          // This beat's wait states (beat 0's, if any) were spent in front of
          // it in the branch below - there is no gap to load AFTER a handshake
          // any more. The next burst arms its own delay from its own
          // ar_outstanding_q entry.
          r_wait_cnt   = 0;
          r_wait_armed = 1'b0;
          rready <= r_default_ready();
        end
      end
      else if(rvalid === 1'b1) begin
        // RVALID is up and this port has not accepted the beat yet: THIS is where
        // the r_wait_states of the read being answered are spent, in front of the
        // burst they were specified for.
        if(!r_wait_armed) begin
          // Only the first beat of a burst carries the delay; a RID that already
          // has an accumulator is mid-burst and must not be stalled.
          r_wait_cnt   = r_accum_q.exists(rid) ? 0 : r_wait_for_id(rid);
          r_wait_armed = 1'b1;
        end
        if(r_wait_cnt > 0) r_wait_cnt--;
        // Registered, exactly like BREADY: reaching zero here makes the handshake
        // land r_wait_states edges after the first edge on which RVALID was high,
        // which is the number axi4_master_monitor_bfm records for beat 0.
        rready <= (r_wait_cnt == 0) && (r_capture_q.size() < R_ACCEPT_DEPTH);
      end
      else if(r_wait_armed && r_wait_cnt > 0) begin
        // No beat presented on this edge while a countdown is running. This
        // can only be a MID-BURST stall (armed at a handshake above): a beat-0
        // delay is armed only once RVALID is up, and RVALID may not drop before
        // its handshake (AXI4 A3.2.1). BENCH-065 asks for RREADY low for N
        // CLOCK cycles, so the countdown keeps ticking through a subordinate's
        // RVALID gap instead of being wiped by the idle branch; if it expires
        // before the next beat appears, RREADY simply returns to its idle
        // value and that beat is accepted without back-pressure (the monitor
        // then measures fewer stall cycles than requested and the
        // request-gated witness does not fire - honest "not exercised", never
        // a false hit).
        r_wait_cnt--;
        if(r_wait_cnt == 0) begin
          r_wait_armed = 1'b0;
          rready <= r_default_ready();
        end
        else begin
          rready <= 1'b0;
        end
      end
      else begin
        r_wait_armed = 1'b0;
        r_wait_cnt   = 0;
        rready <= r_default_ready();
      end
    end
  end

  //-------------------------------------------------------
  // BENCH-066: X-injection ownership, status and request log
  //
  // Ownership. bready_x_inject_active / rready_x_inject_active (above) already
  // make the standing B/R collectors yield their wire while an injection owns
  // it. The AW, W and AR channels get the same per-channel bit here, and are
  // in addition serialised by the pin-level channel mutexes every normal
  // address/data task already takes (aw_channel_key / w_channel_key /
  // ar_channel_key): an injection takes the SAME key, so it can never drive
  // AWVALID/AWADDR, WDATA or ARVALID in the same time step as a transaction
  // thread, whichever of the two arrived first. That single rule is what
  // makes the idle-injection path (no item, serviced by a proxy thread that
  // runs alongside the item loops) safe: a write item that starts while an
  // idle injection is in progress simply waits for the key, and an idle
  // request that arrives while an address task holds AWVALID waits - bounded
  // by X_INJECT_ACQUIRE_TIMEOUT - for that handshake.
  //
  // x_inject_drive_active is the OR of the five bits and is what
  // master_assertions' x_inject_mode gate is derived from (through
  // axi4_master_agent_bfm), replacing the config_db poller: the checks are
  // suppressed for exactly the cycles this BFM owns a wire, not for a
  // sequence's flag window. x_inject_keep_armed carries the request's
  // assertion policy and keeps the gate LOW for a KEEP_ARMED request.
  //-------------------------------------------------------
  bit aw_x_inject_active = 1'b0;
  bit w_x_inject_active  = 1'b0;
  bit ar_x_inject_active = 1'b0;
  wire x_inject_drive_active = aw_x_inject_active | w_x_inject_active | ar_x_inject_active |
                               bready_x_inject_active | rready_x_inject_active;
  bit  x_inject_keep_armed = 1'b0;

  // Reset-restore of an injection in flight is done INSIDE x_inject_drive
  // (it polls ARESETn on every held edge and restores the signal it owns on
  // the edge it sees reset), mirroring how the channel tasks abandon on
  // reset. Nothing else may touch an owned wire during reset: the collectors
  // above reset their own state but stay out of a wire whose ownership bit
  // is set, and the bit is cleared by the owner on its way out.

  // Request log for the MONITOR (BENCH-065 precedent, r_stall_req_log). An
  // injection request has no wire representation, so the proxy records the
  // completed request here, keyed by the requesting item's AWID/ARID, right
  // before that item is dispatched; axi4_master_monitor_proxy pops the
  // OLDEST entry with the id of each address handshake it publishes, so the
  // packet every subscriber (coverage, scoreboard) sees carries the request
  // that actually preceded it. Only item-attached requests are logged: an
  // idle request has no transaction to attribute to and reports through its
  // own request object.
  // The entry type x_inject_req_s lives in axi4_globals_pkg so the proxy and
  // the monitor proxy can name it through their virtual-interface handles.
  x_inject_req_s x_inject_req_log[$];
  localparam int X_INJECT_REQ_LOG_WARN = 1024;

  function automatic void log_x_inject_request(input x_inject_req_s r);
    x_inject_req_log.push_back(r);
    if(x_inject_req_log.size() == X_INJECT_REQ_LOG_WARN) begin
      `uvm_warning(name,$sformatf("x_inject_req_log holds %0d entries the monitor never consumed - injected items whose address never handshook?",X_INJECT_REQ_LOG_WARN))
    end
  endfunction : log_x_inject_request

  function automatic bit pop_x_inject_request(input bit is_write, input bit [`AXI_ID_WIDTH-1:0] id,
                                              output x_inject_req_s r);
    int idx_q[$];
    idx_q = x_inject_req_log.find_first_index with (item.is_write == is_write && item.id == id);
    if(idx_q.size() == 0) return 1'b0;
    r = x_inject_req_log[idx_q[0]];
    x_inject_req_log.delete(idx_q[0]);
    return 1'b1;
  endfunction : pop_x_inject_request

  initial begin
    `uvm_info(name,$sformatf(name),UVM_LOW)
    // Initialize all AXI signals to 0 at time 0 to avoid X propagation
    awvalid = 1'b0;
    wvalid  = 1'b0;
    bready  = 1'b0;
    arvalid = 1'b0;
    rready  = 1'b0;
  end

  //-------------------------------------------------------
  // Task: wait_for_aresetn
  // Waiting for the system reset to be active low
  //-------------------------------------------------------
  task wait_for_aresetn();
    @(negedge aresetn);
    `uvm_info(name,$sformatf("SYSTEM RESET DETECTED"),UVM_HIGH)
    awvalid <= 1'b0;
    wvalid  <= 1'b0;
    bready  <= 1'b0;
    arvalid <= 1'b0;
    rready  <= 1'b0;
    @(posedge aresetn);
    `uvm_info(name,$sformatf("SYSTEM RESET DEACTIVATED"),UVM_HIGH)
  endtask : wait_for_aresetn

  //--------------------------------------------------------------------------------------------
  // Tasks written for all 5 channels in BFM are given below
  //--------------------------------------------------------------------------------------------

  //-------------------------------------------------------
  // Task: axi4_write_address_channel_task
  // This task will drive the write address signals
  //-------------------------------------------------------
// `automatic` for the same reason as the W/B/R channel tasks below: a task in an
// interface defaults to STATIC storage, so its locals and formal arguments are shared
// by every concurrent call. This one has two call sites -
// axi4_master_driver_proxy.sv:283 (the blocking path) and :343 (inside the
// non-blocking fork) - which is exactly the pattern that was measured corrupting the
// W and R tasks: a re-entrant call overwrote the in-flight packet of a caller that was
// still waiting. Static storage here has no proven failure yet, but the exposure is
// identical, so the same one-word fix applies.
task automatic axi4_write_address_channel_task (inout axi4_write_transfer_char_s data_write_packet, axi4_transfer_cfg_s cfg_packet);
    int aw_cycles;
    // Take the AW channel before driving it - see aw_channel_key above.
    aw_channel_key.get(1);
    @(posedge aclk);
    aw_cycles = 0;

    `uvm_info(name,$sformatf("data_write_packet=\n%p",data_write_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("cfg_packet=\n%p",cfg_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("DRIVING_WRITE_ADDRESS_CHANNEL"),UVM_HIGH)
    
    awid     <= data_write_packet.awid;
    awaddr   <= data_write_packet.awaddr;
    awlen    <= data_write_packet.awlen;
    awsize   <= data_write_packet.awsize;
    awburst  <= data_write_packet.awburst;
    awlock   <= data_write_packet.awlock;
    awcache  <= data_write_packet.awcache;
    awprot   <= data_write_packet.awprot;
    awqos    <= data_write_packet.awqos;
    awregion <= data_write_packet.awregion;
    awuser   <= data_write_packet.awuser;
    awvalid  <= 1'b1;
    
    `uvm_info(name,$sformatf("detect_awready = %0d",awready),UVM_HIGH)
    // AXI4 A3.2.1: once AWVALID is asserted it must remain asserted until the
    // AWVALID && AWREADY handshake. The old form gave up after 1000 cycles and
    // deasserted AWVALID with no handshake -- an illegal VALID drop, and a
    // silently lost write: the driver went straight on to the data and response
    // phases for an address the subordinate never accepted.
    // Reset is the only other legal exit (A3.1.2 requires all VALIDs low while
    // ARESETn is low). The 1000-cycle mark is now a report, not an exit; a peer
    // that never asserts AWREADY stops the run at the base test's
    // timeout_watchdog with this warning as the last thing in the log.
    do begin
      @(posedge aclk);
      if(aresetn === 1'b0) break;
      if(aw_cycles == 1000) begin
        `uvm_warning(name,"AWREADY still low after 1000 cycles - holding AWVALID until the handshake (AXI4 A3.2.1)")
      end
      aw_cycles++;
      data_write_packet.wait_count_write_address_channel++;
    end while(awready !== 1'b1);

    if(aresetn === 1'b0) begin
      `uvm_info(name,"ARESETn asserted during the write address phase - dropping AWVALID (the only legal abandon)",UVM_LOW)
    end
    else begin
      // The AWVALID && AWREADY handshake really happened, so from here on the
      // subordinate owes this port exactly one response carrying this AWID.
      // This is what makes the B collector able to tell a routable response from
      // one that answers nothing - see aw_outstanding_q.
      //
      // The requested BREADY back-pressure is queued WITH the id, here, because
      // this is the earliest instant at which the response is owed and the last
      // instant at which the request is unambiguously this transaction's. Doing
      // it in axi4_write_response_channel_task instead was too late - the
      // collector may already have accepted the response by then - and a single
      // global request could not survive more than one outstanding write.
      aw_outstanding_q.push_back('{data_write_packet.awid,
                                   data_write_packet.b_wait_states});
      aw_issued_cnt++;
    end

    `uvm_info(name,$sformatf("After_loop_of_Detecting_awready = %0d, awvalid = %0d",awready,awvalid),UVM_HIGH)
    awvalid <= 1'b0;
    aw_channel_key.put(1);

  endtask : axi4_write_address_channel_task

  //-------------------------------------------------------
  // Task: axi4_write_data_channel_task
  // This task will drive the write data signals
  //-------------------------------------------------------
task automatic axi4_write_data_channel_task (inout axi4_write_transfer_char_s data_write_packet, input axi4_transfer_cfg_s cfg_packet);
    int wr_cycles;
    bit reset_abort = 1'b0;

    `uvm_info(name,$sformatf("data_write_packet=\n%p",data_write_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("cfg_packet=\n%p",cfg_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("DRIVE TO WRITE DATA CHANNEL"),UVM_HIGH)

    // Take the W channel before driving it - see w_channel_key above.
    w_channel_key.get(1);
    @(posedge aclk);

    for(int i=0; i<data_write_packet.awlen + 1; i++) begin
      wdata  <= data_write_packet.wdata[i];
      wstrb  <= data_write_packet.wstrb[i];
      wuser  <= data_write_packet.wuser;
      wlast  <= 1'b0;
      wvalid <= 1'b1;
      `uvm_info(name,$sformatf("DETECT_WRITE_DATA_WAIT_STATE"),UVM_HIGH)
        
      if(data_write_packet.awlen == i)begin  
        wlast  <= 1'b1;
      end

      // AXI4 A3.2.1: WVALID must stay asserted until WVALID && WREADY. The old
      // form gave up after 50000 cycles and simply advanced to the next beat --
      // it changed WDATA/WSTRB/WLAST underneath an asserted WVALID (a stability
      // violation) and dropped a beat from the burst, or ended the burst with no
      // WLAST handshake at all.
      // `wready===0` was also X-tolerant in the wrong direction: an X on WREADY
      // made the condition false and the beat was treated as accepted
      // (known-landmines #6, the manager-side instance).
      wr_cycles = 0;
      do begin
        @(posedge aclk);
        if(aresetn === 1'b0) begin
          reset_abort = 1'b1;
          break;
        end
        if(wr_cycles == 50000) begin
          `uvm_warning(name,$sformatf("WREADY still low after 50000 cycles on beat %0d - holding WVALID until the handshake (AXI4 A3.2.1)",i))
        end
        wr_cycles++;
      end while(wready !== 1'b1);
      `uvm_info(name,$sformatf("DEBUG_NA:WDATA[%0d]=%0h",i,data_write_packet.wdata[i]),UVM_HIGH)
      if(reset_abort) begin
        `uvm_info(name,"ARESETn asserted during the write data phase - dropping WVALID/WLAST (the only legal abandon)",UVM_LOW)
        break;
      end
    end

    wlast <= 1'b0;
    wvalid<= 1'b0;
    w_channel_key.put(1);
    `uvm_info(name,$sformatf("WRITE_DATA_COMP data_write_packet=\n%p",data_write_packet),UVM_HIGH)
  endtask : axi4_write_data_channel_task

  //-------------------------------------------------------
  // Task: axi4_write_response_channel_task
  // This task will drive the write response signals
  //-------------------------------------------------------
task automatic axi4_write_response_channel_task (inout axi4_write_transfer_char_s data_write_packet, input axi4_transfer_cfg_s cfg_packet);
    int         bv_cycles;
    int         b_idx_q[$];
    int         own_idx_q[$];
    b_capture_s b_c;

    `uvm_info(name,$sformatf("WRITE_RESP data_write_packet=\n%p",data_write_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("cfg_packet=\n%p",cfg_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("DRIVE TO WRITE RESPONSE CHANNEL"),UVM_HIGH)

    // THIS TASK NO LONGER DRIVES BREADY. The standing B collector above owns the
    // wire and captures every accepted response into b_capture_q; all this task
    // does is claim the entry that belongs to THIS transaction. See the collector
    // header for why acceptance had to be decoupled from per-transaction task
    // scheduling, and for the two repairs that must never come back (landmines
    // #5 and #11): a timeout may not fabricate a response, and BVALID may not be
    // dropped without a handshake.
    //
    // Routing: the pop is keyed on BID == this packet's AWID (AXI4 A3.2), so a
    // packet can only ever be completed by the response that answers it. With
    // several writes sharing one AWID, find_first_index returns the oldest
    // matching entry, which is the order AXI4 guarantees for same-ID responses.
    //
    // The abandon path is unchanged in kind: report, record bvalid=0, sample
    // NOTHING, so the write is visibly not response-verified and the
    // scoreboard's completeness checks account for it. It now has two triggers.
    // The 50000-cycle bound is still there as a backstop, but the useful one is
    // exact: once the subordinate has produced as many B beats at this port as
    // the manager has issued AW handshakes, it owes nothing more, so a response
    // that has not arrived is never going to. That fires immediately instead of
    // stalling 1 ms per occurrence when the subordinate answers the right NUMBER
    // of writes with the WRONG id (known-landmines #14 - now finally visible
    // rather than silently absorbed by the manager).
    //
    // This task does NOT publish data_write_packet.b_wait_states any more. By the
    // time it runs the collector may already have accepted the response, so a
    // request written here could only ever land on somebody else's response (or
    // on the gap after this one). It is queued at the AWVALID && AWREADY
    // handshake instead - see aw_outstanding_q.
    bv_cycles = 0;
    forever begin
      @(posedge aclk);
      if(aresetn === 1'b0) begin
        `uvm_info(name,"ARESETn asserted while waiting for BVALID - write response phase abandoned, nothing sampled",UVM_LOW)
        data_write_packet.bvalid = 1'b0;
        return;
      end
      b_idx_q = b_capture_q.find_first_index with (item.bid == data_write_packet.awid);
      if(b_idx_q.size() > 0) break;

      // Only meaningful once THIS write's AWVALID && AWREADY has happened;
      // before that the counters legitimately say "nothing owed".
      own_idx_q = aw_outstanding_q.find_first_index with (item.awid == data_write_packet.awid);
      if(own_idx_q.size() > 0 && b_event_cnt >= aw_issued_cnt) begin
        `uvm_warning(name,$sformatf("the subordinate has answered every write issued at this port but none carried bid=0x%0h - write response abandoned, nothing sampled (this write is NOT response-verified)",data_write_packet.awid))
        aw_outstanding_q.delete(own_idx_q[0]);
        data_write_packet.bvalid = 1'b0;
        return;
      end

      if(bv_cycles++ > 50000) begin
        `uvm_warning(name,$sformatf("timeout waiting for a write response with bid=0x%0h - write response abandoned, nothing sampled (this write is NOT response-verified)",data_write_packet.awid))
        if(own_idx_q.size() > 0) aw_outstanding_q.delete(own_idx_q[0]);
        data_write_packet.bvalid = 1'b0;
        return;
      end
    end

    b_c = b_capture_q[b_idx_q[0]];
    b_capture_q.delete(b_idx_q[0]);

    data_write_packet.bvalid = 1'b1;
    data_write_packet.bid    = b_c.bid;
    data_write_packet.bresp  = b_c.bresp;
    data_write_packet.buser  = b_c.buser;

    `uvm_info(name,$sformatf("CHECKING WRITE RESPONSE :: %p",data_write_packet),UVM_HIGH);

  endtask : axi4_write_response_channel_task

  //-------------------------------------------------------
  // Task: axi4_read_address_channel_task
  // This task will drive the read address signals
  //-------------------------------------------------------
// `automatic` - see axi4_write_address_channel_task. Two call sites,
// axi4_master_driver_proxy.sv:734 (blocking) and :783 (non-blocking fork), so the same
// re-entrancy that was measured corrupting axi4_read_data_channel_task applies here.
task automatic axi4_read_address_channel_task (inout axi4_read_transfer_char_s data_read_packet, input axi4_transfer_cfg_s cfg_packet);
    int ar_cycles;
    // Take the AR channel before driving it - same reason as the AW channel.
    ar_channel_key.get(1);
    @(posedge aclk);
    ar_cycles = 0;
    
    `uvm_info(name,$sformatf("data_read_packet=\n%p",data_read_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("cfg_packet=\n%p",cfg_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("DRIVE TO READ ADDRESS CHANNEL"),UVM_HIGH)

    arid     <= data_read_packet.arid;
    araddr   <= data_read_packet.araddr;
    arlen    <= data_read_packet.arlen;
    arsize   <= data_read_packet.arsize;
    arburst  <= data_read_packet.arburst;
    arlock   <= data_read_packet.arlock;
    arcache  <= data_read_packet.arcache;
    arprot   <= data_read_packet.arprot;
    arqos    <= data_read_packet.arqos;
    aruser   <= data_read_packet.aruser;
    arregion <= data_read_packet.arregion;
    arvalid  <= 1'b1;

    `uvm_info(name,$sformatf("detect_awready = %0d",arready),UVM_HIGH)
    // AXI4 A3.2.1: ARVALID must stay asserted until ARVALID && ARREADY. The old
    // form reported and then deasserted ARVALID with no handshake, which both
    // violates the protocol and drops the read -- the driver then went on to the
    // read data phase for a request the subordinate never accepted, so the
    // "timeout waiting for rvalid" that followed was self-inflicted.
    // The error severity is kept (this site was already an enabled uvm_error);
    // it is now a report that does not end the wait. Reset is the only other
    // legal exit (A3.1.2).
    do begin
      @(posedge aclk);
      if(aresetn === 1'b0) break;
      if(ar_cycles == 1000) begin
        `uvm_error(name,"timeout waiting for arready - holding ARVALID until the handshake (AXI4 A3.2.1)")
      end
      ar_cycles++;
      data_read_packet.wait_count_read_address_channel++;
    end while(arready !== 1'b1);

    if(aresetn === 1'b0) begin
      `uvm_info(name,"ARESETn asserted during the read address phase - dropping ARVALID (the only legal abandon)",UVM_LOW)
    end
    else begin
      // The ARVALID && ARREADY handshake really happened, so the subordinate now
      // owes this port exactly one read burst carrying this ARID. Symmetric with
      // aw_outstanding_q - see the R collector header - including carrying this
      // read's requested RREADY back-pressure, which has to be queued here and
      // not in axi4_read_data_channel_task for the reason given on the AW side.
      //
      // BENCH-065 mid-burst stall request: validated HERE, where the live
      // ARLEN is in scope, because a directed sequence may set the fields by
      // direct assignment and never run the constraint. An invalid request is
      // reported and applied as NO stall - never silently ignored (beat 0) and
      // never mis-applied (a negative count would park RREADY low for good).
      begin
        int    stall_beat;
        int    stall_cycles;
        string why;
        stall_beat   = data_read_packet.r_stall_beat;
        stall_cycles = data_read_packet.r_stall_cycles;
        why          = "";
        if(stall_beat == -1) begin
          stall_cycles = 0;
        end
        else if(stall_beat == 0) begin
          why = "beat 0 is the first-beat delay r_wait_states, not a mid-burst position (legal: 1..arlen)";
        end
        else if(stall_beat < 0) begin
          why = "negative position (only -1 = no request is legal)";
        end
        else if(stall_beat > int'(data_read_packet.arlen)) begin
          why = $sformatf("beyond the last beat of this burst (arlen=%0d, legal: 1..%0d)",
                          data_read_packet.arlen,data_read_packet.arlen);
        end
        else if(stall_cycles < 0) begin
          why = "negative r_stall_cycles";
        end
        else if(stall_cycles > R_BEAT_STALL_MAX) begin
          why = $sformatf("r_stall_cycles above R_BEAT_STALL_MAX=%0d",R_BEAT_STALL_MAX);
        end
        else if(stall_cycles == 0) begin
          `uvm_info(name,$sformatf("mid-burst stall request for arid=0x%0h beat %0d carries r_stall_cycles=0 - treated as no request",
                                   data_read_packet.arid,stall_beat),UVM_MEDIUM)
          stall_beat = -1;
        end
        if(why != "") begin
          `uvm_error(name,$sformatf("invalid mid-burst RREADY stall request on arid=0x%0h: r_stall_beat=%0d r_stall_cycles=%0d - %s. Applying NO stall to this read.",
                                    data_read_packet.arid,stall_beat,stall_cycles,why))
          stall_beat   = -1;
          stall_cycles = 0;
        end
        // Named fields, not positional - see ar_outstanding_s.
        ar_outstanding_q.push_back('{arid:           data_read_packet.arid,
                                     r_wait_states:  data_read_packet.r_wait_states,
                                     r_stall_beat:   stall_beat,
                                     r_stall_cycles: stall_cycles});
        r_stall_req_log.push_back('{arid:           data_read_packet.arid,
                                    r_stall_beat:   stall_beat,
                                    r_stall_cycles: stall_cycles});
        if(r_stall_req_log.size() == R_STALL_REQ_LOG_WARN) begin
          `uvm_warning(name,$sformatf("r_stall_req_log holds %0d entries the monitor never consumed - reads issued at this port that were never answered?",R_STALL_REQ_LOG_WARN))
        end
      end
      ar_issued_cnt++;
    end

    `uvm_info(name,$sformatf("After_loop_of_Detecting_awready = %0d, awvalid = %0d",awready,awvalid),UVM_HIGH)
    arvalid <= 1'b0;
    ar_channel_key.put(1);
  endtask : axi4_read_address_channel_task

  //-------------------------------------------------------
  // Task: axi4_read_data_channel_task
  // This task will drive the read data signals
  //-------------------------------------------------------
task automatic axi4_read_data_channel_task (inout axi4_read_transfer_char_s data_read_packet, input axi4_transfer_cfg_s cfg_packet, input bit error_inject = 0);

    int         rv_cycles;
    int         r_idx_q[$];
    int         own_idx_q[$];
    r_capture_s r_c;

    `uvm_info(name,$sformatf("data_read_packet in read data Channel=\n%p",data_read_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("cfg_packet=\n%p",cfg_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("DRIVE TO READ DATA CHANNEL"),UVM_HIGH)

    // THIS TASK NO LONGER DRIVES RREADY. The standing R collector above owns the
    // wire, captures every accepted beat and publishes a burst only once its
    // RLAST beat has handshaken; all this task does is claim the burst that
    // belongs to THIS transaction. See the collector header for why acceptance
    // had to be decoupled from per-transaction task scheduling.
    //
    // Both of the previous defects stay fixed and neither repair may come back
    // (landmines #5 and #11): a beat is recorded only at a real
    // RVALID && RREADY handshake, and a timeout samples NOTHING rather than
    // reconstructing a read off an idle bus. The old code's two X-tolerant polls
    // are gone with the polls themselves - the collector compares `=== 1'b1`, so
    // an X on RVALID is not "data available" (landmine #6).
    //
    // Routing: the pop is keyed on RID == this packet's ARID (AXI4 A3.2), so a
    // packet is only ever completed with the burst that answers it; with several
    // reads sharing one ARID, find_first_index returns the oldest, which is the
    // order AXI4 guarantees for same-ID read data.
    //
    // Abandon has the same two triggers as the write response path: the exact one
    // (the subordinate has completed as many bursts at this port as the manager
    // has issued AR handshakes, so a burst that has not arrived never will) and
    // the 50000-cycle bound as a backstop. Severity is unchanged - uvm_error, or
    // uvm_warning when the test is injecting errors on purpose.
    //
    // Like the write response task, this one no longer publishes
    // data_read_packet.r_wait_states: the collector may already have accepted the
    // burst by the time this runs. It is queued at the ARVALID && ARREADY
    // handshake instead - see ar_outstanding_q.
    rv_cycles = 0;
    forever begin
      @(posedge aclk);
      if(aresetn === 1'b0) begin
        `uvm_info(name,"ARESETn asserted while waiting for RVALID - read data phase abandoned, nothing sampled",UVM_LOW)
        return;
      end
      r_idx_q = r_capture_q.find_first_index with (item.rid == data_read_packet.arid);
      if(r_idx_q.size() > 0) break;

      // Only meaningful once THIS read's ARVALID && ARREADY has happened.
      own_idx_q = ar_outstanding_q.find_first_index with (item.arid == data_read_packet.arid);
      if(own_idx_q.size() > 0 && r_burst_cnt >= ar_issued_cnt) begin
        if(error_inject) begin
          `uvm_warning(name,$sformatf("the subordinate has completed every read issued at this port but none carried rid=0x%0h - read data phase abandoned, no beats sampled",data_read_packet.arid))
        end
        else begin
          `uvm_error(name,$sformatf("the subordinate has completed every read issued at this port but none carried rid=0x%0h - read data phase abandoned, no beats sampled",data_read_packet.arid))
        end
        ar_outstanding_q.delete(own_idx_q[0]);
        return;
      end

      if(rv_cycles++ > R_CLAIM_ESCAPE_CYCLES) begin
        if(error_inject) begin
          `uvm_warning(name,$sformatf("timeout waiting for a read burst with rid=0x%0h - read data phase abandoned, no beats sampled",data_read_packet.arid))
        end
        else begin
          `uvm_error(name,$sformatf("timeout waiting for a read burst with rid=0x%0h - read data phase abandoned, no beats sampled",data_read_packet.arid))
        end
        if(own_idx_q.size() > 0) ar_outstanding_q.delete(own_idx_q[0]);
        return;
      end
    end

    r_c = r_capture_q[r_idx_q[0]];
    r_capture_q.delete(r_idx_q[0]);

    // Replay the captured burst into the packet beat by beat. rid/ruser/rresp are
    // assigned exactly as the pin-level loop assigned them (whole-field, so the
    // last beat wins) so that this rework changes WHICH beats a packet gets, not
    // how the struct is filled - the per-beat rresp/ruser truncation in
    // axi4_read_transfer_char_s is a separate, pre-existing issue and is
    // deliberately not changed here.
    data_read_packet.rvalid = 1'b1;
    for(int b = 0; b < r_c.beats; b++) begin
      data_read_packet.rid      = r_c.rid;
      data_read_packet.rdata[b] = r_c.rdata[b];
      data_read_packet.ruser    = r_c.ruser[b];
      data_read_packet.rresp    = r_c.rresp[b];
      `uvm_info(name,$sformatf("DEBUG_NA:RDATA[%0d]=%0h",b,data_read_packet.rdata[b]),UVM_HIGH)
    end
    data_read_packet.rlast = 1'b1;

  endtask : axi4_read_data_channel_task

  //-------------------------------------------------------
  // Task: x_inject_drive (BENCH-066)
  //
  // Drives X on ONE manager-side signal for `cycles` aclk edges and reports
  // what happened. This is the single X-drive entry point; the six
  // per-signal inject_x_on_* tasks it replaces kept their drive semantics
  // (AWVALID/ARVALID/BREADY/RREADY: the signal itself goes X; AWADDR: AWVALID
  // is asserted with AWADDR X; WDATA: WVALID is asserted with WDATA/WSTRB X)
  // but had no ownership, no status and no reset path.
  //
  // Contract:
  //   accepted   - request validated (target != NONE, 1 <= cycles <= MAX)
  //   started    - the channel was taken and X was driven
  //   completed  - the task is done, for ANY result
  //   result     - OK / TIMEOUT (channel never freed, nothing driven) /
  //                ABORTED_BY_RESET (signal restored on the reset edge) /
  //                INVALID (rejected, nothing driven, uvm_error)
  //   start_time / end_time - the first and last aclk edges on which X is
  //                visible on the pin (exactly the edges master_assertions'
  //                witness counts), cycles_driven = number of such edges.
  // Timing: the drive is issued on a posedge (as every channel task does),
  // is visible from the next posedge, and is restored on the last held
  // posedge; ownership is released one edge after the restore so the
  // collectors and the assertion gate never overlap the restore edge.
  //-------------------------------------------------------
  task automatic x_inject_drive(input  x_inject_target_e        target,
                                input  int                      cycles,
                                input  x_inject_assert_policy_e policy,
                                output bit                      accepted,
                                output bit                      started,
                                output bit                      completed,
                                output x_inject_result_e        result,
                                output time                     start_time,
                                output time                     end_time,
                                output int                      cycles_driven);
    semaphore key;
    int       waited;
    bit       aborted;

    accepted      = 1'b0;
    started       = 1'b0;
    completed     = 1'b0;
    result        = X_INJ_RESULT_NOT_REQUESTED;
    start_time    = 0;
    end_time      = 0;
    cycles_driven = 0;
    aborted       = 1'b0;

    if(target == X_INJ_NONE) return;

    if(cycles < 1 || cycles > X_INJECT_CYCLES_MAX) begin
      `uvm_error(name,$sformatf("invalid X-injection request on %s: cycles=%0d is outside [1:%0d] - rejected, nothing driven",
                                target.name(),cycles,X_INJECT_CYCLES_MAX))
      result    = X_INJ_RESULT_INVALID;
      completed = 1'b1;
      return;
    end
    accepted = 1'b1;

    // Channel ownership: the same pin-level mutex the address/data tasks
    // take. B and R have no task-side driver to exclude - the standing
    // collectors yield on the ownership bit alone.
    case(target)
      X_INJ_AWVALID, X_INJ_AWADDR: key = aw_channel_key;
      X_INJ_WDATA               : key = w_channel_key;
      X_INJ_ARVALID             : key = ar_channel_key;
      default                   : key = null;
    endcase
    if(key != null) begin
      waited = 0;
      while(!key.try_get(1)) begin
        @(posedge aclk);
        if(aresetn === 1'b0) begin
          `uvm_info(name,$sformatf("ARESETn asserted while waiting for the %s channel - X injection abandoned before it started",target.name()),UVM_LOW)
          result    = X_INJ_RESULT_ABORTED_BY_RESET;
          completed = 1'b1;
          return;
        end
        waited++;
        if(waited >= X_INJECT_ACQUIRE_TIMEOUT) begin
          `uvm_warning(name,$sformatf("X injection on %s: channel not released within %0d cycles - request timed out, nothing driven",
                                      target.name(),X_INJECT_ACQUIRE_TIMEOUT))
          result    = X_INJ_RESULT_TIMEOUT;
          completed = 1'b1;
          return;
        end
      end
    end

    // Take ownership BEFORE the edge on which X is driven, so a collector that
    // runs on that same edge already sees the bit and does not schedule its
    // own NBA on the wire (same ordering rule the B/R injections used).
    x_inject_keep_armed = (policy == X_INJ_KEEP_ARMED);
    case(target)
      X_INJ_AWVALID, X_INJ_AWADDR: aw_x_inject_active     = 1'b1;
      X_INJ_WDATA               : w_x_inject_active      = 1'b1;
      X_INJ_ARVALID             : ar_x_inject_active     = 1'b1;
      X_INJ_BREADY              : bready_x_inject_active = 1'b1;
      X_INJ_RREADY              : rready_x_inject_active = 1'b1;
    endcase

    @(posedge aclk);
    `uvm_info(name,$sformatf("Injecting X on %s for %0d cycles (policy %s)",target.name(),cycles,policy.name()),UVM_MEDIUM)
    case(target)
      X_INJ_AWVALID: begin awvalid <= 1'bx; end
      X_INJ_AWADDR : begin awvalid <= 1'b1; awaddr <= 'x; end
      X_INJ_WDATA  : begin wvalid  <= 1'b1; wdata  <= 'x; wstrb <= 'x; end
      X_INJ_ARVALID: begin arvalid <= 1'bx; end
      X_INJ_BREADY : begin bready  <= 1'bx; end
      X_INJ_RREADY : begin rready  <= 1'bx; end
    endcase
    started = 1'b1;

    // Hold: one iteration per aclk edge on which X is visible. ARESETn is
    // polled on every edge; reset restores the wire on that very edge.
    for(int c = 0; c < cycles; c++) begin
      @(posedge aclk);
      if(aresetn === 1'b0) begin
        aborted = 1'b1;
        break;
      end
      if(c == 0) start_time = $time;
      end_time = $time;
      cycles_driven++;
    end

    // Restore to the idle value the channel tasks / collectors leave behind.
    case(target)
      X_INJ_AWVALID: begin awvalid <= 1'b0; end
      X_INJ_AWADDR : begin awvalid <= 1'b0; awaddr <= '0; end
      X_INJ_WDATA  : begin wvalid  <= 1'b0; wdata  <= '0; wstrb <= '0; end
      X_INJ_ARVALID: begin arvalid <= 1'b0; end
      X_INJ_BREADY : begin bready  <= 1'b0; end
      X_INJ_RREADY : begin rready  <= 1'b0; end
    endcase

    if(aborted) begin
      `uvm_info(name,$sformatf("ARESETn asserted during X injection on %s after %0d of %0d cycles - signal restored to idle (the only legal abandon)",
                               target.name(),cycles_driven,cycles),UVM_LOW)
      result = X_INJ_RESULT_ABORTED_BY_RESET;
    end
    else begin
      // One more edge with ownership held, so the restore NBA and a
      // collector's first own drive never land in the same time step.
      @(posedge aclk);
      result = X_INJ_RESULT_OK;
    end

    case(target)
      X_INJ_AWVALID, X_INJ_AWADDR: aw_x_inject_active     = 1'b0;
      X_INJ_WDATA               : w_x_inject_active      = 1'b0;
      X_INJ_ARVALID             : ar_x_inject_active     = 1'b0;
      X_INJ_BREADY              : bready_x_inject_active = 1'b0;
      X_INJ_RREADY              : rready_x_inject_active = 1'b0;
    endcase
    x_inject_keep_armed = 1'b0;
    if(key != null) key.put(1);
    completed = 1'b1;

    `uvm_info(name,$sformatf("X injection on %s %s: %0d cycle(s) driven, %0t .. %0t",
                             target.name(),result.name(),cycles_driven,start_time,end_time),UVM_MEDIUM)
  endtask : x_inject_drive

endinterface : axi4_master_driver_bfm

`endif
