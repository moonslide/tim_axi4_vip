`ifndef AXI4_MASTER_TX_INCLUDED_
`define AXI4_MASTER_TX_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tx
// This class holds the data items required to drive the stimulus to dut
// and also holds methods that manipulate those data items.
//--------------------------------------------------------------------------------------------
class axi4_master_tx extends uvm_sequence_item;
  
  `uvm_object_utils(axi4_master_tx)

  axi4_master_agent_config axi4_master_agent_cfg_h; 
  

  //Variable: sb_src_index
  //Index of the agent that OBSERVED this transaction (master port on the master
  //side, slave port on the slave side). Stamped by the monitor proxy purely so
  //the scoreboard can pair transactions by source instead of by arrival order.
  //Deliberately non-rand and deliberately excluded from do_compare/do_print --
  //it is scoreboard bookkeeping, not part of the transaction.
  int sb_src_index = -1;

  //-------------------------------------------------------
  // WRITE ADDRESS CHANNEL SIGNALS
  //-------------------------------------------------------
  //Variable : awid
  //Used to send the write address id
  rand awid_e awid;

  //Variable : awaddr
  //Used to send the write address
  rand bit [ADDRESS_WIDTH-1:0] awaddr;

  //Variable : awlen
  //Used to send the write address length
  rand bit [LENGTH-1:0] awlen;

  //Variable : awsize
  //Used to send the write address size
  rand awsize_e awsize;
  
  //Variable : awburst
  //Used to send the write address burst
  rand awburst_e awburst;

  //Variable : awlock
  //Used to send the write address lock
  rand awlock_e awlock;
  
  //Variable : awcache
  //Used to send the write address cache
  rand awcache_e awcache;

  //Variable : awprot
  //Used to send the write address prot
  rand awprot_e awprot;

  //Variable : awqos
  //Used to send the write address quality of service
  rand bit [3:0] awqos;

  //Variable : awregion
  //Used to send the write address region selected
  rand bit [3:0] awregion;

  //Variable : awuser
  //Used to send the write address user
  rand bit [`AXI_AWUSER_WIDTH-1:0] awuser;

  //-------------------------------------------------------
   // WRITE DATA CHANNEL SIGNALS
  //-------------------------------------------------------
  //Variable : wdata
  //Used to randomise write data
  //varaible[$] gives a unbounded queue
  //variable[$:value] gives a bounded queue to a value of given value 
  rand bit [DATA_WIDTH-1:0] wdata [$:2**LENGTH];

  //Variable : wstrb
  //Used to randomise write strobe
  //varaible[$] gives a unbounded queue
  //variable[$:value] gives a bounded queue to a value of given value 
  rand bit [(DATA_WIDTH/8)-1:0] wstrb [$:2**LENGTH];

  //Variable : wlast
  //Used to store the write last transfer
  bit wlast;

  //Variable : wuser
  //Used to send the user bit value
  rand bit [`AXI_WUSER_WIDTH-1:0] wuser;

  //-------------------------------------------------------
  // WRITE RESPONSE CHANNEL SIGNALS
  //-------------------------------------------------------
  //Variable : bid
  //Used to send the response id
  bid_e bid;

  //Variable : bresp
  //Used to capture the write response of the trasnaction
  bresp_e bresp;
  
  //Variable : buser
  //Used to capture the buser
  bit [`AXI_BUSER_WIDTH-1:0] buser;

  //-------------------------------------------------------
  // READ ADDRESS CHANNEL SIGNALS
  //-------------------------------------------------------
  //Variable : arid
  //Used to send the read address id
  rand arid_e arid;
 
  //Variable : araddr
  //Used to send the read address
  rand bit [ADDRESS_WIDTH-1:0] araddr;

  //Variable : arlen
  //Used to send the read address length
  rand bit [LENGTH-1:0] arlen;

  //Variable : arsize
  //Used to send the read address size
  rand arsize_e arsize;
  
  //Variable : arburst
  //Used to send the read address burst
  rand arburst_e arburst;

  //Variable : arlock
  //Used to send the read address lock
  rand arlock_e arlock;
  
  //Variable : arcache
  //Used to send the read address cache
  rand arcache_e arcache;

  //Variable : arprot
  //Used to send the read address prot
  rand arprot_e arprot;

  //Variable : arqos
  //Used to send the read address quality of service
  rand bit [3:0] arqos;

  //Variable : aruser
  //Used to send the read address user data
  rand bit [`AXI_ARUSER_WIDTH-1:0] aruser;

  //Variable : arregion
  //Used to send the read address region data
  //
  //Declared as a single bit while axi4_if, both monitor/driver BFM ports, the
  //axi4_read_transfer_char_s field and axi4_slave_tx all carry 4 bits. The
  //struct->class converter therefore truncated the sampled ARREGION to bit 0,
  //so the scoreboard compared a 1-bit master value against the subordinate's
  //full 4-bit one. It only became visible once the slave side stopped dropping
  //ARREGION entirely; before that both sides read zero and agreed by accident.
  rand bit [3:0] arregion;

  //-------------------------------------------------------
  // READ DATA CHANNEL SIGNALS 
  //-------------------------------------------------------
  //Variable : rid
  //Used to send the read address id
  rid_e rid;
  
  //Variable : rdata
  //Used to randomise read data
  //varaible[$] gives a unbounded queue
  //variable[$:value] gives a bounded queue to a value of given value 
  bit [DATA_WIDTH-1:0] rdata [$:2**LENGTH];

  //Variable : rresp
  //Used to capture the read response of the trasnaction
  rresp_e rresp;

  //Variable : rlast
  //Used to store the read last transfer
  bit rlast;

  //Variable : ruser
  //Used to read the read user value
  bit [`AXI_RUSER_WIDTH-1:0] ruser;
  
  //Variable : endian
  //Used to differentiate the type of memory storage
  rand endian_e endian;

  //Variable : tx_type
  //Used to determine the transaction type
  rand tx_type_e tx_type;

  //Variable: transfer_type
  //Used to the determine the type of the transfer
  rand transfer_type_e transfer_type;
  
  //Variable : aw_wait_states
  //Number of wait states before driving BREADY/RREADY or waiting on READY
  rand int aw_wait_states;
  rand int w_wait_states;
  rand int b_wait_states;
  rand int ar_wait_states;
  rand int r_wait_states;

  //Variable : r_stall_beat / r_stall_cycles (BENCH-065)
  //Programmable MID-BURST RREADY back-pressure: hold RREADY low for
  //r_stall_cycles clock cycles in front of interior beat r_stall_beat
  //(1 <= r_stall_beat <= arlen) of this read burst. One position per
  //transaction; -1 = no request (the default, so nothing in the regression
  //changes unless a sequence asks). Beat 0 is deliberately NOT reachable
  //through these fields -- the first-beat delay is r_wait_states, exactly as
  //before -- so the two knobs never describe the same beat. The countdown is
  //in CLOCK cycles from the handshake of beat r_stall_beat-1, whether or not
  //the subordinate presents the next beat immediately; with a subordinate that
  //streams RVALID gaplessly (this VIP's slave BFM) that is also the number of
  //RVALID-high cycles the monitor measures as r_stall_cycles_observed.
  //A request set by direct assignment instead of randomize() is validated in
  //the driver BFM at the AR handshake: beat 0, a beat beyond arlen, a negative
  //value, or a cycle count outside [0:R_BEAT_STALL_MAX] is reported with
  //uvm_error and applied as NO stall (never silently mis-applied).
  //The -1 initializer is load-bearing: a directed sequence that new()s a
  //transaction and sets fields directly (a documented usage pattern) must not
  //land on beat 0 by default.
  rand int r_stall_beat   = -1;
  rand int r_stall_cycles = 0;

  //Variable : r_stall_beat_observed / r_stall_cycles_observed
  //Pin-level witness, populated ONLY by axi4_master_monitor_bfm: the first
  //interior beat (index >= 1) at which RVALID was high while RREADY was low,
  //and for how many cycles. -1 / 0 when no interior beat was back-pressured.
  //Not a request field, not randomized, not compared.
  int r_stall_beat_observed   = -1;
  int r_stall_cycles_observed = 0;

  //-------------------------------------------------------
  // BENCH-066: transaction-attached X-injection descriptor (REQUEST side)
  //
  // x_inject_target names the manager-side signal to drive X on BEFORE this
  // item's own channel phases are dispatched (PRE_TRANSACTION mode - the only
  // mode this VIP advertises; an ACTIVE_PHASE mode overlapping the item's
  // own VALID/READY phase is deliberately NOT implemented, see the BENCH-066
  // handoff). The request rides on the item, so it is consumed by exactly the
  // proxy/BFM that owns the sequencer the item was started on: no wildcard
  // config_db key, no fixed-time sleep, nothing another master can steal.
  // Default X_INJ_NONE: every existing item is untouched.
  // x_inject_cycles is the hold in aclk cycles (1..X_INJECT_CYCLES_MAX).
  // x_inject_assert_policy: SUPPRESS_CHECKS (default) raises the
  // master_assertions gate for the drive window; KEEP_ARMED leaves the named
  // X-protocol assertions armed so a self-test can watch them fire.
  // DELIBERATELY NOT rand: the descriptor is set by assignment after
  // randomize() (the SVT exception-list shape - an attachment, not a
  // solved variable). Making these rand, even soft-defaulted, changed the
  // solver's random stream for EVERY master transaction in the regression
  // (measured: the baseline axi4_blocking_incr_burst_write_test produced
  // different AWADDR/WDATA/AWLEN values for the same seed - VCD line count
  // 500755 vs 500537), which is exactly the "zero drift when unused" the
  // BENCH-066 acceptance forbids. Validation is done where the request is
  // consumed: axi4_master_driver_bfm::x_inject_drive rejects a cycle count
  // outside [1:X_INJECT_CYCLES_MAX] as X_INJ_RESULT_INVALID (uvm_error) and
  // drives nothing.
  //-------------------------------------------------------
  x_inject_target_e        x_inject_target        = X_INJ_NONE;
  int                      x_inject_cycles        = 0;
  x_inject_assert_policy_e x_inject_assert_policy = X_INJ_SUPPRESS_CHECKS;

  //-------------------------------------------------------
  // BENCH-066: X-injection STATUS, written back by the driver (proxy + BFM),
  // never by the sequence. accepted = the request passed validation and was
  // handed to the BFM; started = the BFM took the channel and drove X;
  // completed = the hold finished (for any result). start/end are the aclk
  // edges on which X was first and last visible on the pins - the same edges
  // master_assertions' witness stamps - and cycles_driven counts them.
  // On a monitor-published packet these are stamped from the driver BFM's
  // per-transaction request log (pop by AWID/ARID at the address handshake,
  // BENCH-065 precedent), so coverage and the scoreboard's view carry the
  // request that actually preceded this transaction.
  // Not compared (see do_compare).
  //-------------------------------------------------------
  bit                x_inject_accepted      = 1'b0;
  bit                x_inject_started       = 1'b0;
  bit                x_inject_completed     = 1'b0;
  x_inject_result_e  x_inject_result        = X_INJ_RESULT_NOT_REQUESTED;
  time               x_inject_start_time    = 0;
  time               x_inject_end_time      = 0;
  int                x_inject_cycles_driven = 0;

  //Variable: wait_count_write_address_channel
  //Used to determine wait count for write address channel
  int wait_count_write_address_channel;

  //Variable: wait_count_write_data_channel
  //Used to determine wait count for write data channel
  int wait_count_write_data_channel;
  
  //Variable: wait_count_write_response_channel
  //Used to determine wait count for write response channel
  int wait_count_write_response_channel;

  //Variable: wait_count_read_address_channel
  //Used to determine wait count for write response channel
  int wait_count_read_address_channel;

  //Variable: wait_count_read_data_channel
  //Used to determine wait count for write response channel
  int wait_count_read_data_channel;
  
  //Variable: outstanding_write_tx
  //Used to determine the outstanding write tx count
  int outstanding_write_tx;
  
  //Variable: outstanding_write_tx
  //Used to determine the outstanding write tx count
  int outstanding_read_tx;
  
  //-------------------------------------------------------
  // WRITE ADDRESS Constraints
  //-------------------------------------------------------
  //Constraint : awaddr
  //Used to generate the alligned address with respect to size
  constraint awaddr_c0 {soft awaddr % (2**awsize) == 0;}

  //Constraint : awburst_c1
  //Restricting write burst to select only FIXED, INCR and WRAP types
  constraint awburst_c1 {awburst != WRITE_RESERVED;}

  //Constraint : awlength_c2
  //Adding constraint for restricting write trasnfers
  constraint awlength_c2 {if(awburst==WRITE_FIXED || awburst==WRITE_WRAP)
                              awlen inside {[0:15]};
                          else if(awburst == WRITE_INCR) 
                              awlen inside {[0:255]};}

  //Constraint : awlength_c3
  //Adding constraint for restricting to get multiples of 2 in wrap burst
  constraint awlength_c3 {if(awburst == WRITE_WRAP)
                          awlen + 1 inside {2,4,8,16};}
  
  //Constraint : awlock_c4
  //Adding constraint to select the lock transfer type
  constraint awlock_c4 {soft awlock == WRITE_NORMAL_ACCESS;}

  //Constraint : awburst_c5
  //Adding a soft constraint to detrmine the burst type
  constraint awburst_c5 {soft awburst == WRITE_INCR;}

  //Constraint : awsize_c6
  //Adding a soft constraint to detrmine the awsize
  constraint awsize_c6 {soft awsize inside {[0:2]};}

  // AXI4 A3.4.1: a burst must not cross a 4KB address boundary.  FIXED
  // bursts repeatedly access one address, so they cannot cross.  INCR bursts
  // advance from the start address; WRAP bursts stay inside their aligned
  // wrap region, which must itself fit in the containing 4KB page.
  // The WRAP arm only has to bound the wrap region's SIZE.  The region is
  // aligned to that size, so a power-of-two region of <=4096 bytes always sits
  // inside one page -- the old form recomputed that containment with a
  // variable-divisor division, `(floor(addr[11:0]/total)+1)*total <= 4096`,
  // which can never reject anything: awlength_c3 forces awlen+1 inside
  // {2,4,8,16} for WRAP, awsize is 3 bits so a beat is at most 128 bytes, so
  // total is a power of two of at most 2048, and floor(4095/total)*total+total
  // is exactly 4096.  Every master randomization in every test paid for that
  // division and a variable shift for a branch that never fired.  Keeping the
  // size bound (linear, and still meaningful if awlength_c3 is switched off by
  // a directed sequence) preserves the guard at a fraction of the solver cost.
  // The INCR arm measures the span from the ALIGNED start address, per AXI4
  // A3.4.1's address structure: an INCR burst may start unaligned, but the
  // first beat's byte lanes are truncated into the aligned block that contains
  // the start address, and every later beat is Aligned_Address + n*Number_Bytes.
  // So the last byte of the burst is Aligned_Address + (len+1)*bytes - 1, and
  // measuring from the raw address over-counts by the misalignment.  Using the
  // raw address rejected legal transfers: AWADDR=...0FFF with AWSIZE=2,
  // AWLEN=0 is a single beat covering the aligned block 0xFFC..0xFFF, entirely
  // inside the page, but 4095+4=4099 > 4096 refused it.  awaddr_c0 is SOFT, so
  // an unaligned sequence can legitimately reach this state and was then
  // blocked by this hard constraint.
  // Alignment is done by masking rather than `% (1<<awsize)` to keep a
  // variable-divisor modulo out of every master randomization.
  constraint aw_4kb_boundary_c7 {
    if (awburst == WRITE_INCR)
      (int'(awaddr[11:0]) & ~((1 << int'(awsize)) - 1))
        + ((int'(awlen) + 1) * (1 << int'(awsize))) <= 4096;
    else if (awburst == WRITE_WRAP)
      ((int'(awlen) + 1) * (1 << int'(awsize))) <= 4096;
  }

  //-------------------------------------------------------
  // WRITE DATA Constraints
  //-------------------------------------------------------
  //Constraint : wdata_c1
  //Adding constraint to restrict the write data based on awlength
  constraint wdata_c1 {wdata.size() == awlen + 1;} 

  //Constraint : wstrb_c2
  //Adding constraint to restrict the write strobe based on awlength
  constraint wstrb_c2 {wstrb.size() == awlen + 1;}

  //Constraint : wstrb_c3
  //wstrb shouldn't be zero
  constraint wstrb_c3 {foreach(wstrb[i]) wstrb[i]!=0; }

  //Constraint: wstrb_c4
  //based on size setting the strobe values
  constraint wstrb_c4 {foreach(wstrb[i]) $countones(wstrb[i]) == 2**awsize;}

  //Constraint : wait_states_c3
  //Adding constraint to restrict the number of wait states for all channels
  constraint wait_states_c3 {soft aw_wait_states inside {[0:6]};
                              soft w_wait_states  inside {[0:6]};
                              soft b_wait_states  inside {[0:6]};
                              soft ar_wait_states inside {[0:6]};
                              soft r_wait_states  inside {[0:6]};}

  //Constraint : r_mid_burst_stall_c (BENCH-065)
  //Default is "no stall requested" (soft), so every existing randomization is
  //unchanged. The hard part is an IMPLICATION on purpose: a plain
  //`r_stall_beat inside {[1:arlen]}` is unsatisfiable for arlen == 0 and
  //would silently delete every single-beat read from the regression's
  //solution space (`solve arlen before` only reweights, it does not add
  //solutions). A sequence that wants a stall constrains r_stall_beat to a
  //value >= 1, which then forces arlen >= r_stall_beat.
  //r_stall_cycles is bounded unconditionally: the driver's countdown is
  //`if(cnt > 0) cnt--; rready <= (cnt == 0)`, so a negative count would park
  //RREADY low forever. Directed sequences that bypass randomize() are caught
  //by the driver BFM's capture-time check instead.
  constraint r_mid_burst_stall_c {
    soft r_stall_beat   == -1;
    soft r_stall_cycles == 0;
    r_stall_cycles inside {[0:R_BEAT_STALL_MAX]};
    (r_stall_beat == -1) || (arlen > 0 && r_stall_beat inside {[1:arlen]});
  }

  //-------------------------------------------------------
  // READ ADDRESS Constraints
  //-------------------------------------------------------

  //Constraint : araddr
  //Used to generate the alligned address with respect to size
  constraint araddr_c0 {soft araddr % (2**arsize) == 0;}
  
  //Constraint : arburst_c1
  //Restricting read burst to select only FIXED, INCR and WRAP types
  constraint arburst_c1 { arburst != READ_RESERVED;}

  //Constraint : arlength_c2
  //Adding constraint for restricting read trasnfers
  constraint arlength_c2 { if(arburst==READ_FIXED || arburst==READ_WRAP)
                            arlen inside {[0:15]};
                           else if(arburst == READ_INCR) 
                            arlen inside {[0:255]};
                         }
  
  //Constraint : arlength_c3
  //Adding constraint for restricting to get multiples of 2 in wrap burst
  constraint arlength_c3 { if(arburst == READ_WRAP)
                            arlen + 1 inside {2,4,8,16};
                         }

  //Constraint : arlock_c9
  //Adding constraint to select the lock transfer type
  constraint arlock_c4 { soft arlock == READ_NORMAL_ACCESS;}

  //Constraint : arburst_c5
  //Adding a soft constraint to detrmine the burst type
  constraint arburst_c5 { soft arburst == READ_INCR;}

  //Constraint : arsize_c6
  //Adding a soft constraint to detrmine the arsize
  constraint arsize_c6 { soft arsize inside {[0:2]};}

  // AXI4 A3.4.1 read-side counterpart of aw_4kb_boundary_c7, including the
  // same WRAP simplification -- see the reasoning there.
  constraint ar_4kb_boundary_c7 {
    if (arburst == READ_INCR)
      (int'(araddr[11:0]) & ~((1 << int'(arsize)) - 1))
        + ((int'(arlen) + 1) * (1 << int'(arsize))) <= 4096;
    else if (arburst == READ_WRAP)
      ((int'(arlen) + 1) * (1 << int'(arsize))) <= 4096;
  }

  //-------------------------------------------------------
  // Memory Constraints
  //-------------------------------------------------------
  //Constraint : endian_c1
  //Adding constraint to select the endianess
  constraint endian_c1 { soft endian == LITTLE_ENDIAN;}

  //Constraint : wuser_c1
  //Adding constraint to set wuser to 0 by default for consistent master-slave comparison
  constraint wuser_c1 { soft wuser == 4'h0;}

  //Constraint : awuser_c1
  //Adding constraint to set awuser to 0 by default for consistent master-slave comparison
  constraint awuser_c1 { soft awuser == 1'b0;}

  //-------------------------------------------------------
  // ID Constraints based on bus matrix configuration
  //-------------------------------------------------------
  //Constraint : awid_c1
  //Limit AWID values to valid range based on the ID width
  // Default constraint allows all 16 values (AWID_0 to AWID_15)
  // Sequences should override this constraint for specific configurations
  constraint awid_c1 { 
    // By default, allow all valid AWID values
    // Specific tests/sequences should add constraints based on their configuration
    awid inside {[AWID_0:AWID_15]};
  }

  //Constraint : arid_c1
  //Limit ARID values to valid range based on the ID width
  // Default constraint allows all 16 values (ARID_0 to ARID_15)
  // Sequences should override this constraint for specific configurations
  constraint arid_c1 { 
    // By default, allow all valid ARID values
    // Specific tests/sequences should add constraints based on their configuration
    arid inside {[ARID_0:ARID_15]};
  }

  //Constraint : aruser_c1
  //Adding constraint to set aruser to 0 by default for consistent master-slave comparison
  constraint aruser_c1 { soft aruser == 1'b0;}
  
  //Constraint : awprot_c1
  //Removed default constraint - let tests control AWPROT based on master type
  //constraint awprot_c1 { soft awprot == WRITE_NORMAL_NONSECURE_DATA;}
  
  //Constraint : arprot_c1
  //Removed default constraint - let tests control ARPROT based on master type
  //constraint arprot_c1 { soft arprot == READ_NORMAL_NONSECURE_DATA;}

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new (string name = "axi4_master_tx");
  extern function void do_copy(uvm_object rhs);
  extern function void post_randomize();
  extern function bit do_compare(uvm_object rhs, uvm_comparer comparer);
  extern function void do_print(uvm_printer printer);
endclass : axi4_master_tx

//--------------------------------------------------------------------------------------------
// Construct: new
// initializes the class object
//
// Parameters:
// name - axi4_master_tx
//--------------------------------------------------------------------------------------------
function axi4_master_tx::new(string name = "axi4_master_tx");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function : post_randomize 
// Implements the narrow transfers and unalligned transfers
//--------------------------------------------------------------------------------------------
function void axi4_master_tx::post_randomize();
//-------------------------------------------------------
// Strobes for alligned with narrow transfers and
// Unalligned transfers
//-------------------------------------------------------
begin //{
  bit[STROBE_WIDTH-1:0]  remainder_check;
  // strobe_data provides you the strobe for starting addr
  bit [STROBE_WIDTH-1:0] strobe_data[int][1];

  // for awsize =0 which means 1B need to transfer 
  // for this case always addrs will be alligned
  // because remainder always be 0... in this case

  bit [STROBE_WIDTH-1:0] local_addr;
  bit [STROBE_WIDTH-1:0] min;
  bit [STROBE_WIDTH-1:0] shift_loc;

  remainder_check = (awaddr%(STROBE_WIDTH));
  min = (awsize == 1) ? {2{1'b1}} : ((awsize == 2) ? {4{1'b1}} : ((awsize == 3) ? {8{1'b1}} :
  ((awsize == 4) ? {16{1'b1}} : ((awsize == 5) ? {32{1'b1}} : ((awsize == 6) ? {64{1'b1}} : {128{1'b1}})))));

  for(int l=0;l<STROBE_WIDTH;l++) begin
    if((remainder_check+l)%2**awsize == 0) begin
      shift_loc = remainder_check+l;
      break;
    end
  end
  if(awsize == 0) begin
    strobe_data[STROBE_WIDTH][0][remainder_check] = 1'b1;
  end
  else begin
    if(awaddr % 2**awsize != 0) begin
        unique case(awsize)
          1: strobe_data[STROBE_WIDTH][0] = 1'b1 << remainder_check;
          2: strobe_data[STROBE_WIDTH][0] = ({STROBE_WIDTH{1'b1}} << remainder_check) & ~({STROBE_WIDTH{1'b1}} << (4*(awaddr/2**awsize)+4));
          3: strobe_data[STROBE_WIDTH][0] = ({STROBE_WIDTH{1'b1}} << remainder_check) & ~({STROBE_WIDTH{1'b1}} << (8*(awaddr/2**awsize)+8));
          4: strobe_data[STROBE_WIDTH][0] = ({STROBE_WIDTH{1'b1}} << remainder_check) & ~({STROBE_WIDTH{1'b1}} << (16*(awaddr/2**awsize)+16));
          5: strobe_data[STROBE_WIDTH][0] = ({STROBE_WIDTH{1'b1}} << remainder_check) & ~({STROBE_WIDTH{1'b1}} << (32*(awaddr/2**awsize)+32));
          6: strobe_data[STROBE_WIDTH][0] = ({STROBE_WIDTH{1'b1}} << remainder_check) & ~({STROBE_WIDTH{1'b1}} << (64*(awaddr/2**awsize)+64));
          7: strobe_data[STROBE_WIDTH][0] = ({STROBE_WIDTH{1'b1}} << remainder_check) & ~({STROBE_WIDTH{1'b1}} << (128*(awaddr/2**awsize)+128));
        endcase
    end
    else begin  //{ alligned address
        unique case(awsize)
          1: strobe_data[STROBE_WIDTH][0] = 2'b11 << remainder_check;
          2: strobe_data[STROBE_WIDTH][0] = 4'b1111 << remainder_check; 
          3: strobe_data[STROBE_WIDTH][0] = 8'b1111_1111 << remainder_check; 
          4: strobe_data[STROBE_WIDTH][0] = {16{1'b1}} << remainder_check; 
          5: strobe_data[STROBE_WIDTH][0] = {32{1'b1}} << remainder_check; 
          6: strobe_data[STROBE_WIDTH][0] = {64{1'b1}} << remainder_check; 
          7: strobe_data[STROBE_WIDTH][0] = {128{1'b1}} << remainder_check; 
        endcase
    end //}
  end
  if(awaddr%2**awsize != 0) begin
    for(int i=0;i<wstrb.size();i++) begin
      if(awsize == 0) begin
        if(i==0)  wstrb[0] = strobe_data[STROBE_WIDTH][0];
        else if(wstrb[i-1][STROBE_WIDTH-1]) wstrb[i] = local_addr|1'b1;
        else wstrb[i] = wstrb[i-1] << 1; 
      end
      if(awsize == 1) begin
        if(i==0)  wstrb[0] = strobe_data[STROBE_WIDTH][0];
        else if(i==1) wstrb[i] =  (wstrb[i-1][STROBE_WIDTH-1]) ? (local_addr|2'b11) : min << remainder_check+1 ;
        else if(wstrb[i-1][STROBE_WIDTH-1] && i>1) wstrb[i] = local_addr|2'b11;
        else wstrb[i] = wstrb[i-1] << 2; 
      end
      if(awsize == 2) begin
        if(i==0)  wstrb[0] = strobe_data[STROBE_WIDTH][0];
        else if(i==1) wstrb[i] =  (wstrb[i-1][STROBE_WIDTH-1]) ? (local_addr|4'b1111) : (min << shift_loc);
        else if(wstrb[i-1][STROBE_WIDTH-1] && i>0) wstrb[i] = local_addr|4'b1111; 
        else wstrb[i] = wstrb[i-1] << 4; 
      end
      if(awsize == 3) begin
        if(i==0)  wstrb[0] = strobe_data[STROBE_WIDTH][0];
        else if(i==1) wstrb[i] =  (wstrb[i-1][STROBE_WIDTH-1]) ? (local_addr|8'b1111_1111) : (min << shift_loc);
        else if(wstrb[i-1][STROBE_WIDTH-1] && i>1) wstrb[i] = local_addr|8'b1111_1111;
        else wstrb[i] = wstrb[i-1] << 8; 
      end
      if(awsize == 4) begin
        if(i==0)  wstrb[0] = strobe_data[STROBE_WIDTH][0];
        else if(i==1) wstrb[i] =  (wstrb[i-1][STROBE_WIDTH-1]) ? (local_addr|16'b1111_1111_1111_1111) : (min << shift_loc);
        else if(wstrb[i-1][STROBE_WIDTH-1] && i>1) wstrb[i] = local_addr|16'b1111_1111_1111_1111;
        else wstrb[i] = wstrb[i-1] << 16; 
      end
      if(awsize == 5) begin
        if(i==0)  wstrb[0] = strobe_data[STROBE_WIDTH][0];
        else if(i==1) wstrb[i] =  (wstrb[i-1][STROBE_WIDTH-1]) ? (local_addr|32'b1111_1111_1111_1111_1111_1111_1111_1111) : (min << shift_loc);
        else if(wstrb[i-1][STROBE_WIDTH-1] && i>1) wstrb[i] = local_addr|32'b1111_1111_1111_1111_1111_1111_1111_1111;
        else wstrb[i] = wstrb[i-1] << 32; 
      end
      if(awsize == 6) begin
        if(i==0)  wstrb[0] = strobe_data[STROBE_WIDTH][0];
        else if(i==1) wstrb[i] =  (wstrb[i-1][STROBE_WIDTH-1]) ? (local_addr|64'b1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111) : (min << shift_loc);
        else if(wstrb[i-1][STROBE_WIDTH-1] && i>1) wstrb[i] = local_addr|64'b1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111;
        else wstrb[i] = wstrb[i-1] << 64; 
      end
      if(awsize == 7) begin
        if(i==0)  wstrb[0] = strobe_data[STROBE_WIDTH][0];
        else  wstrb[i] = local_addr|128'b1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111;
      end
    end
  end
  else begin 
    for(int i=0;i<wstrb.size();i++) begin
      if(awsize == 0) begin
        if(i==0)  wstrb[0] = strobe_data[STROBE_WIDTH][0];
        else if(wstrb[i-1][STROBE_WIDTH-1]) wstrb[i] = local_addr|1'b1;
        else wstrb[i] = wstrb[i-1] << 1; 
      end
      if(awsize == 1) begin
        if(i==0)  wstrb[0] = strobe_data[STROBE_WIDTH][0];
        else if(wstrb[i-1][STROBE_WIDTH-1] && i>0) wstrb[i] = local_addr|2'b11;
        else wstrb[i] = wstrb[i-1] << 2; 
      end
      if(awsize == 2) begin
        if(i==0)  wstrb[0] = strobe_data[STROBE_WIDTH][0];
        else if(wstrb[i-1][STROBE_WIDTH-1] && i>0) wstrb[i] = local_addr|4'b1111;
        else wstrb[i] = wstrb[i-1] << 4; 
      end
      if(awsize == 3) begin
        if(i==0)  wstrb[0] = strobe_data[STROBE_WIDTH][0];
        else if(wstrb[i-1][STROBE_WIDTH-1] && i>0) wstrb[i] = local_addr|8'b1111_1111;
        else wstrb[i] = wstrb[i-1] << 8; 
      end
      if(awsize == 4) begin
        if(i==0)  wstrb[0] = strobe_data[STROBE_WIDTH][0];
        else if(wstrb[i-1][STROBE_WIDTH-1] && i>0) wstrb[i] = local_addr|16'b1111_1111_1111_1111;
        else wstrb[i] = wstrb[i-1] << 16; 
      end
      if(awsize == 5) begin
        if(i==0)  wstrb[0] = strobe_data[STROBE_WIDTH][0];
        else if(wstrb[i-1][STROBE_WIDTH-1] && i>0) wstrb[i] = local_addr|32'b1111_1111_1111_1111_1111_1111_1111_1111;
        else wstrb[i] = wstrb[i-1] << 32; 
      end
      if(awsize == 6) begin
        if(i==0)  wstrb[0] = strobe_data[STROBE_WIDTH][0];
        else if(wstrb[i-1][STROBE_WIDTH-1] && i>0) wstrb[i] = local_addr|64'b1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111;
        else wstrb[i] = wstrb[i-1] << 64; 
      end
      if(awsize == 7) begin
        if(i==0)  wstrb[0] = strobe_data[STROBE_WIDTH][0];
        else wstrb[i] = local_addr|128'b1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111;
      end
    end
  end
end //}
endfunction : post_randomize

//--------------------------------------------------------------------------------------------
// Function : do_copy
// Copies the axi4 slave_tx into the rhs object
//
// Parameters:
// rhs - uvm_object
//--------------------------------------------------------------------------------------------
function void axi4_master_tx::do_copy(uvm_object rhs);
  axi4_master_tx axi4_master_tx_copy_obj;

  if(!$cast(axi4_master_tx_copy_obj,rhs)) begin
    `uvm_fatal("do_copy","cast of the rhs object failed")
  end
  super.do_copy(rhs);
  
  //WRITE ADDRESS CHANNEL
  awid    = axi4_master_tx_copy_obj.awid;
  awaddr  = axi4_master_tx_copy_obj.awaddr;
  awlen   = axi4_master_tx_copy_obj.awlen;
  awsize  = axi4_master_tx_copy_obj.awsize;
  awburst = axi4_master_tx_copy_obj.awburst;
  awlock  = axi4_master_tx_copy_obj.awlock;
  awcache = axi4_master_tx_copy_obj.awcache;
  awprot  = axi4_master_tx_copy_obj.awprot;
  awqos   = axi4_master_tx_copy_obj.awqos;
  //WRITE DATA CHANNEL
  wdata = axi4_master_tx_copy_obj.wdata;
  wstrb = axi4_master_tx_copy_obj.wstrb;
  awuser = axi4_master_tx_copy_obj.awuser;
  wuser = axi4_master_tx_copy_obj.wuser;
  //WRITE RESPONSE CHANNEL
  bid   = axi4_master_tx_copy_obj.bid;
  bresp = axi4_master_tx_copy_obj.bresp;
  buser = axi4_master_tx_copy_obj.buser;
  //READ ADDRESS CHANNEL
  arid     = axi4_master_tx_copy_obj.arid;
  araddr   = axi4_master_tx_copy_obj.araddr;
  arlen    = axi4_master_tx_copy_obj.arlen;
  arsize   = axi4_master_tx_copy_obj.arsize;
  arburst  = axi4_master_tx_copy_obj.arburst;
  arlock   = axi4_master_tx_copy_obj.arlock;
  arcache  = axi4_master_tx_copy_obj.arcache;
  arprot   = axi4_master_tx_copy_obj.arprot;
  arqos    = axi4_master_tx_copy_obj.arqos;
  arregion = axi4_master_tx_copy_obj.arregion;
  aruser   = axi4_master_tx_copy_obj.aruser;
  //READ DATA CHANNEL
  rid   = axi4_master_tx_copy_obj.rid;
  rdata = axi4_master_tx_copy_obj.rdata;
  rresp = axi4_master_tx_copy_obj.rresp;
  // rlast was missing here.  axi4_master_monitor_proxy publishes a CLONE of
  // the combined read packet, so anything do_copy skips is silently reset to
  // its default on every analysis-port consumer -- which is what kept the
  // rlast-gated read error counting and read latency correlation in
  // axi4_performance_metrics dead even after the converter started setting it.
  rlast = axi4_master_tx_copy_obj.rlast;
  ruser = axi4_master_tx_copy_obj.ruser;
  //OTHERS
  tx_type       = axi4_master_tx_copy_obj.tx_type;
  transfer_type = axi4_master_tx_copy_obj.transfer_type;
  //WAIT STATES (timing metadata)
  // None of these five were copied. This class uses `uvm_object_utils (no
  // field automation), and axi4_master_monitor_proxy publishes a CLONE of every
  // packet, so anything skipped here reaches every analysis-port consumer as
  // its 2-state default. That is why the AW/W/B/AR/R_WAIT_STATES_CP coverpoints
  // in axi4_master_coverage only ever hit their zero bin (fail-then-pass
  // recorded 2026-09-17: R_WS_0=3 / R_WS_1..6=0 before, real distribution after).
  aw_wait_states = axi4_master_tx_copy_obj.aw_wait_states;
  w_wait_states  = axi4_master_tx_copy_obj.w_wait_states;
  b_wait_states  = axi4_master_tx_copy_obj.b_wait_states;
  ar_wait_states = axi4_master_tx_copy_obj.ar_wait_states;
  r_wait_states  = axi4_master_tx_copy_obj.r_wait_states;
  //MID-BURST RREADY STALL (BENCH-065): request and pin-level witness
  r_stall_beat            = axi4_master_tx_copy_obj.r_stall_beat;
  r_stall_cycles          = axi4_master_tx_copy_obj.r_stall_cycles;
  r_stall_beat_observed   = axi4_master_tx_copy_obj.r_stall_beat_observed;
  r_stall_cycles_observed = axi4_master_tx_copy_obj.r_stall_cycles_observed;
  //X INJECTION (BENCH-066): request and driver-stamped status. The monitor
  //proxy publishes CLONES, so anything skipped here reaches every subscriber
  //(coverage included) as its default.
  x_inject_target        = axi4_master_tx_copy_obj.x_inject_target;
  x_inject_cycles        = axi4_master_tx_copy_obj.x_inject_cycles;
  x_inject_assert_policy = axi4_master_tx_copy_obj.x_inject_assert_policy;
  x_inject_accepted      = axi4_master_tx_copy_obj.x_inject_accepted;
  x_inject_started       = axi4_master_tx_copy_obj.x_inject_started;
  x_inject_completed     = axi4_master_tx_copy_obj.x_inject_completed;
  x_inject_result        = axi4_master_tx_copy_obj.x_inject_result;
  x_inject_start_time    = axi4_master_tx_copy_obj.x_inject_start_time;
  x_inject_end_time      = axi4_master_tx_copy_obj.x_inject_end_time;
  x_inject_cycles_driven = axi4_master_tx_copy_obj.x_inject_cycles_driven;
endfunction : do_copy

//--------------------------------------------------------------------------------------------
// Function: do_compare
// Compare method is implemented using handle rhs
//
// Parameters:
// phase - uvm phase
//--------------------------------------------------------------------------------------------
function bit axi4_master_tx::do_compare (uvm_object rhs, uvm_comparer comparer);
  axi4_master_tx axi4_master_tx_compare_obj;

  if(!$cast(axi4_master_tx_compare_obj,rhs)) begin
    `uvm_fatal("FATAL_axi_MASTER_TX_DO_COMPARE_FAILED","cast of the rhs object failed")
    return 0;
  end
  
  return super.do_compare(axi4_master_tx_compare_obj, comparer) &&
  //WRITE ADDRESS CHANNEL
  awid    == axi4_master_tx_compare_obj.awid    &&
  awaddr  == axi4_master_tx_compare_obj.awaddr  &&
  awlen   == axi4_master_tx_compare_obj.awlen   &&
  awsize  == axi4_master_tx_compare_obj.awsize  &&
  awburst == axi4_master_tx_compare_obj.awburst &&
  awlock  == axi4_master_tx_compare_obj.awlock  &&
  awcache == axi4_master_tx_compare_obj.awcache &&
  awprot  == axi4_master_tx_compare_obj.awprot  &&
  awqos   == axi4_master_tx_compare_obj.awqos   &&
  //WRITE DATA CHANNEL
  wdata == axi4_master_tx_compare_obj.wdata &&
  wstrb == axi4_master_tx_compare_obj.wstrb &&
  //WRITE RESPONSE CHANNEL
  bid   == axi4_master_tx_compare_obj.bid   &&
  bresp == axi4_master_tx_compare_obj.bresp &&
  //READ ADDRESS CHANNEL
  arid    == axi4_master_tx_compare_obj.arid    &&
  araddr  == axi4_master_tx_compare_obj.araddr  &&
  arlen   == axi4_master_tx_compare_obj.arlen   &&
  arsize  == axi4_master_tx_compare_obj.arsize  &&
  arburst == axi4_master_tx_compare_obj.arburst &&
  arlock  == axi4_master_tx_compare_obj.arlock  &&
  arcache == axi4_master_tx_compare_obj.arcache &&
  arprot  == axi4_master_tx_compare_obj.arprot  &&
  arqos   == axi4_master_tx_compare_obj.arqos   &&
  //READ DATA CHANNEL
  rid   == axi4_master_tx_compare_obj.rid   &&
  rdata == axi4_master_tx_compare_obj.rdata &&
  rresp == axi4_master_tx_compare_obj.rresp;
  // The *_wait_states fields are DELIBERATELY not compared. On a driver-side
  // packet they are the requested delay; on a monitor-side packet they are the
  // measured one, and the two legitimately differ (a zero-delay response is
  // accepted one cycle late while another outstanding write/read asked for a
  // delay; an interleaved burst's first-beat delay is not applied -- see the
  // R collector in axi4_master_driver_bfm.sv). Timing metadata is not part of
  // transaction identity.
  // The x_inject_* request and status fields (BENCH-066) are DELIBERATELY not
  // compared either, and for a stronger reason than the wait states: the
  // scoreboard's only use of do_compare is master-monitor packet against
  // subordinate-monitor packet, and an X-injection request is a MANAGER-SIDE
  // stimulus attribute with no representation on the subordinate side at
  // all (the subordinate never learns that the X preceding this address was
  // requested). Comparing them would make every injected transaction a
  // guaranteed mismatch and every non-injected one a vacuous match. Whether
  // the request was honoured is checked where it is knowable: on the item
  // returned to the sequence, and against master_assertions' pin witness.
endfunction : do_compare

//--------------------------------------------------------------------------------------------
// Function: do_print method
// Print method can be added to display the data members values
//
// Parameters :
// printer  - uvm_printer
//--------------------------------------------------------------------------------------------
function void axi4_master_tx::do_print(uvm_printer printer);
  printer.print_string("tx_type",tx_type.name());
  if(tx_type == WRITE) begin
  //`uvm_info("------------------------------------------WRITE_ADDRESS_CHANNEL","-------------------------------------",UVM_LOW);
    printer.print_string("awid",awid.name());
    printer.print_field("awaddr",awaddr,$bits(awaddr),UVM_HEX);
    printer.print_field("awlen",awlen,$bits(awlen),UVM_DEC);
    printer.print_string("awsize",awsize.name());
    printer.print_string("awburst",awburst.name());
    printer.print_string("awlock",awlock.name());
    printer.print_string("awcache",awcache.name());
    printer.print_string("awprot",awprot.name());
    printer.print_field("awqos",awqos,$bits(awqos),UVM_HEX);
    printer.print_field("wait_count_write_address_channel",wait_count_write_address_channel,
                         $bits(wait_count_write_address_channel),UVM_HEX);
    //`uvm_info("------------------------------------------WRITE_DATA_CHANNEL","---------------------------------------",UVM_LOW);
    foreach(wdata[i])begin
      printer.print_field($sformatf("wdata[%0d]",i),wdata[i],$bits(wdata[i]),UVM_HEX);
    end
    foreach(wstrb[i])begin
      // MSHA: printer.print_field($sformatf("wstrb[%0d]",i),wstrb[i],$bits(wstrb[i]),UVM_HEX);
      printer.print_field($sformatf("wstrb[%0d]",i),wstrb[i],$bits(wstrb[i]),UVM_HEX);
    end
    printer.print_field("wait_count_write_data_channel",wait_count_write_data_channel,
                         $bits(wait_count_write_data_channel),UVM_HEX);
    //`uvm_info("-----------------------------------------WRITE_RESPONSE_CHANNEL","------------------------------------",UVM_LOW);
    printer.print_string("bid",bid.name());
    printer.print_string("bresp",bresp.name());
    printer.print_field("aw_wait_states",aw_wait_states,$bits(aw_wait_states),UVM_DEC);
    printer.print_field("w_wait_states",w_wait_states,$bits(w_wait_states),UVM_DEC);
    printer.print_field("b_wait_states",b_wait_states,$bits(b_wait_states),UVM_DEC);
    printer.print_field("wait_count_write_response_channel",wait_count_write_response_channel,
                         $bits(wait_count_write_response_channel),UVM_HEX);
  end
  
  if(tx_type == READ) begin
    //`uvm_info("------------------------------------------READ_ADDRESS_CHANNEL","-------------------------------------",UVM_LOW);
    printer.print_string("arid",arid.name());
    printer.print_field("araddr",araddr,$bits(araddr),UVM_HEX);
    printer.print_field("arlen",arlen,$bits(arlen),UVM_DEC);
    printer.print_string("arsize",arsize.name());
    printer.print_string("arburst",arburst.name());
    printer.print_string("arlock",arlock.name());
    printer.print_string("arcache",arcache.name());
    printer.print_string("arprot",arprot.name());
    printer.print_field("arqos",arqos,$bits(arqos),UVM_HEX);
    printer.print_field("wait_count_read_address_channel",wait_count_read_address_channel,
                         $bits(wait_count_read_address_channel),UVM_HEX);
    //`uvm_info("------------------------------------------READ_DATA_CHANNEL","----------------------------------------",UVM_LOW);
    printer.print_string("rid",rid.name());
    foreach(rdata[i])begin
      printer.print_field($sformatf("rdata[%0d]",i),rdata[i],$bits(rdata[i]),UVM_HEX);
    end
    printer.print_string("rresp",rresp.name());
    printer.print_field("ruser",ruser,$bits(ruser),UVM_HEX);
    printer.print_field("ar_wait_states",ar_wait_states,$bits(ar_wait_states),UVM_DEC);
    printer.print_field("r_wait_states",r_wait_states,$bits(r_wait_states),UVM_DEC);
    printer.print_field("r_stall_beat",r_stall_beat,$bits(r_stall_beat),UVM_DEC);
    printer.print_field("r_stall_cycles",r_stall_cycles,$bits(r_stall_cycles),UVM_DEC);
    printer.print_field("r_stall_beat_observed",r_stall_beat_observed,$bits(r_stall_beat_observed),UVM_DEC);
    printer.print_field("r_stall_cycles_observed",r_stall_cycles_observed,$bits(r_stall_cycles_observed),UVM_DEC);
    printer.print_field("wait_count_read_data_channel",wait_count_read_data_channel,$bits(wait_count_read_data_channel),UVM_HEX);
  end
  printer.print_string("transfer_type",transfer_type.name());
  //BENCH-066: the descriptor is printed on every packet (it is part of the
  //request), the status only when something was actually requested.
  printer.print_string("x_inject_target",x_inject_target.name());
  if(x_inject_target != X_INJ_NONE) begin
    printer.print_field("x_inject_cycles",x_inject_cycles,$bits(x_inject_cycles),UVM_DEC);
    printer.print_string("x_inject_assert_policy",x_inject_assert_policy.name());
    printer.print_field("x_inject_accepted",x_inject_accepted,1,UVM_DEC);
    printer.print_field("x_inject_started",x_inject_started,1,UVM_DEC);
    printer.print_field("x_inject_completed",x_inject_completed,1,UVM_DEC);
    printer.print_string("x_inject_result",x_inject_result.name());
    printer.print_time("x_inject_start_time",x_inject_start_time);
    printer.print_time("x_inject_end_time",x_inject_end_time);
    printer.print_field("x_inject_cycles_driven",x_inject_cycles_driven,$bits(x_inject_cycles_driven),UVM_DEC);
  end
endfunction : do_print

`endif
