`ifndef AXI4_MASTER_X_INJECT_SEQ_INCLUDED_
`define AXI4_MASTER_X_INJECT_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_x_inject_seq
// Sequence for injecting X values into AXI4 signals for robustness testing.
//
// BENCH-066 rewrite. Each basic task used to set a wildcard config_db flag,
// sleep #(cycles*10ns), clear the flag, re-arm assertions and only THEN send
// an item - while the driver read the flag only after get_next_item()
// returned, so with an idle driver the injection was skipped and the sleep
// stood in for a completion the BFM never signalled. Now:
//   * AWADDR / WDATA / ARVALID / BREADY / RREADY: the request rides on an
//     INJECTION ITEM (x_inject_target / x_inject_cycles on axi4_master_tx);
//     the proxy runs it before that item's own phases and stamps the status
//     back, so finish_item() returning IS the acknowledgement. A SEPARATE
//     recovery item (descriptor NONE) follows, and the returned status is
//     checked (uvm_error on anything but X_INJ_RESULT_OK).
//   * AWVALID keeps its "while the bus is idle" meaning through the
//     agent-scoped idle request path (axi4_master_x_inject_idle_req via the
//     agent config's mailbox, serviced by a dedicated proxy thread), with a
//     sequence-owned bounded wait, then the same recovery item.
//   * No fixed-time sleeps stand in for injection completion, no
//     $assertoff/$asserton: the assertion gate follows the BFM's own drive
//     state, and a test that wants the checks armed asks for it through
//     assert_policy == X_INJ_KEEP_ARMED.
// The last injection item / idle request are kept (last_inject_item,
// last_idle_req) so a test can compare the driver-stamped status against the
// pin-level witness in master_assertions.
//--------------------------------------------------------------------------------------------
class axi4_master_x_inject_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_x_inject_seq)

  // Injection phase enumeration
  typedef enum {
    PHASE_AW,  // Write Address channel
    PHASE_AR,  // Read Address channel
    PHASE_W,   // Write Data channel
    PHASE_B,   // Write Response channel
    PHASE_R    // Read Data channel
  } inject_phase_e;

  // Injection signal enumeration
  typedef enum {
    SIGNAL_VALID,
    SIGNAL_READY,
    SIGNAL_ADDR,
    SIGNAL_DATA,
    SIGNAL_ID
  } inject_signal_e;

  // Injection control parameters
  rand inject_phase_e inject_phase;
  rand inject_signal_e inject_signal;
  rand int unsigned x_inject_cycles;
  rand bit [ADDRESS_WIDTH-1:0] target_addr;
  rand bit [DATA_WIDTH-1:0] test_data;
  rand bit [3:0] test_id;
  rand bit recover_to_valid;

  // BENCH-066: explicit assertion policy carried by the request (see
  // x_inject_assert_policy_e). Default keeps today's suppression.
  x_inject_assert_policy_e assert_policy = X_INJ_SUPPRESS_CHECKS;

  // BENCH-066: sequence-owned bound on the idle (AWVALID) request, in
  // simulation time. 0 = wait forever. The default covers the BFM's own
  // acquire timeout plus the longest legal hold at the base 10ns clock.
  time idle_req_timeout = (X_INJECT_ACQUIRE_TIMEOUT + X_INJECT_CYCLES_MAX + 16) * 10ns;

  // BENCH-066: control mode - no injection at all, just ONE directed
  // single-beat write (or read, control_is_read) at target_addr through the
  // same send_*_item() path the injection tasks use. This is the
  // injection-disabled control of the witness tests and the directed
  // background traffic of the concurrent-traffic scenario.
  bit control_only    = 1'b0;
  bit control_is_read = 1'b0;
  // Optional fixed AxPROT for the control/background item (the access
  // matrix in claude.md makes some master/slave pairs' response depend on
  // PROT; the concurrent-traffic scenario needs a pair that answers OKAY).
  bit       control_prot_fixed = 1'b0;
  bit [2:0] control_prot       = 3'b000;

  // BENCH-066: the result this sequence expects back. OK by default; a
  // directed reset-during-injection test sets X_INJ_RESULT_ABORTED_BY_RESET
  // (and then only the result itself is checked, not the driven count).
  x_inject_result_e expected_result = X_INJ_RESULT_OK;

  // BENCH-066: what the driver reported for the last request this sequence
  // made (item path / idle path), for the test's witness comparison.
  axi4_master_tx                 last_inject_item;
  axi4_master_tx                 last_recovery_item;
  axi4_master_x_inject_idle_req  last_idle_req;

  // Constraints
  constraint c_inject_cycles {
    x_inject_cycles inside {[1:20]};  // Allow wider range for randomization (1-20 cycles)
  }

  constraint c_target_addr {
    target_addr[1:0] == 2'b00; // Word aligned
    // Constrain to valid slave address ranges for enhanced bus matrix
    // Either in DDR region (S0-S2) or Peripheral region (S5-S9)
    (target_addr >= 64'h0000_0008_0000_0000 && target_addr <= 64'h0000_0008_BFFF_FFFF) ||
    (target_addr >= 64'h0000_000A_0000_0000 && target_addr <= 64'h0000_000A_0004_FFFF);
  }

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_x_inject_seq");
  extern task body();
  extern task inject_x_on_awvalid();
  extern task inject_x_on_awaddr();
  extern task inject_x_on_wdata();
  extern task inject_x_on_arvalid();
  extern task inject_x_on_bready();
  extern task inject_x_on_rready();
  extern task send_write_item(input x_inject_target_e target, input bit [ADDRESS_WIDTH-1:0] addr, output axi4_master_tx item);
  extern task send_read_item (input x_inject_target_e target, input bit [ADDRESS_WIDTH-1:0] addr, output axi4_master_tx item);
  extern function void check_inject_status(input string what, input x_inject_target_e target, input x_inject_result_e result,
                                           input bit accepted, input bit started, input bit completed, input int driven,
                                           input time t0, input time t1);
  extern function axi4_master_agent_config get_agent_cfg();

endclass : axi4_master_x_inject_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_master_x_inject_seq::new(string name = "axi4_master_x_inject_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_seq::body();
  super.body();

  if(control_only) begin
    if(control_is_read) send_read_item (X_INJ_NONE, target_addr, last_recovery_item);
    else                send_write_item(X_INJ_NONE, target_addr, last_recovery_item);
    return;
  end

  `uvm_info(get_type_name(), $sformatf("Starting X injection: phase=%s, signal=%s, cycles=%0d, policy=%s",
            inject_phase.name(), inject_signal.name(), x_inject_cycles, assert_policy.name()), UVM_MEDIUM)

  // Route to appropriate injection task based on phase and signal
  case (inject_phase)
    PHASE_AW: begin
      case (inject_signal)
        SIGNAL_VALID: inject_x_on_awvalid();
        SIGNAL_ADDR:  inject_x_on_awaddr();
        default: `uvm_warning(get_type_name(), "Invalid signal for AW phase")
      endcase
    end

    PHASE_AR: begin
      case (inject_signal)
        SIGNAL_VALID: inject_x_on_arvalid();
        default: `uvm_warning(get_type_name(), "Invalid signal for AR phase")
      endcase
    end

    PHASE_W: begin
      case (inject_signal)
        SIGNAL_DATA: inject_x_on_wdata();
        default: `uvm_warning(get_type_name(), "Invalid signal for W phase")
      endcase
    end

    PHASE_B: begin
      case (inject_signal)
        SIGNAL_READY: inject_x_on_bready();
        default: `uvm_warning(get_type_name(), "Invalid signal for B phase")
      endcase
    end

    PHASE_R: begin
      case (inject_signal)
        SIGNAL_READY: inject_x_on_rready();
        default: `uvm_warning(get_type_name(), "Invalid signal for R phase")
      endcase
    end

    default: `uvm_error(get_type_name(), "Invalid injection phase")
  endcase

endtask : body

//--------------------------------------------------------------------------------------------
// Function: get_agent_cfg
// The config object of the agent whose sequencer this sequence runs on -
// the per-agent delivery path for idle requests.
//--------------------------------------------------------------------------------------------
function axi4_master_agent_config axi4_master_x_inject_seq::get_agent_cfg();
  axi4_master_write_sequencer wseqr;
  axi4_master_read_sequencer  rseqr;
  if($cast(wseqr, m_sequencer) && wseqr != null) return wseqr.axi4_master_agent_cfg_h;
  if($cast(rseqr, m_sequencer) && rseqr != null) return rseqr.axi4_master_agent_cfg_h;
  return null;
endfunction : get_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: check_inject_status
// The acknowledgement contract (repair-contract item 3): a request that did
// not come back accepted+started+completed with result OK and exactly the
// requested number of driven cycles is a uvm_error here, in the sequence
// that asked for it.
//--------------------------------------------------------------------------------------------
function void axi4_master_x_inject_seq::check_inject_status(input string what, input x_inject_target_e target, input x_inject_result_e result,
                                                            input bit accepted, input bit started, input bit completed, input int driven,
                                                            input time t0, input time t1);
  if(!accepted || !completed || result != expected_result ||
     (expected_result == X_INJ_RESULT_OK && (!started || driven != int'(x_inject_cycles)))) begin
    `uvm_error(get_type_name(), $sformatf("%s X injection on %s did not complete as requested (expected %s): accepted=%0d started=%0d completed=%0d result=%s driven=%0d/%0d",
                                          what, target.name(), expected_result.name(), accepted, started, completed, result.name(), driven, x_inject_cycles))
  end
  else begin
    `uvm_info(get_type_name(), $sformatf("%s X injection on %s acknowledged: %0d aclk cycle(s) driven, %0t .. %0t",
                                         what, target.name(), driven, t0, t1), UVM_LOW)
  end
endfunction : check_inject_status

//--------------------------------------------------------------------------------------------
// Task: send_write_item
// One directed single-beat BLOCKING write at `addr`, carrying `target` as its
// X-injection descriptor (X_INJ_NONE = the recovery item). BLOCKING so that
// finish_item() returns only after the write response has been claimed - the
// injection item is fully retired before the recovery item is even built.
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_seq::send_write_item(input x_inject_target_e target, input bit [ADDRESS_WIDTH-1:0] addr, output axi4_master_tx item);
  item = axi4_master_tx::type_id::create("req");
  start_item(item);
  if(!item.randomize() with {
    tx_type                == WRITE;
    awaddr                 == local::addr;
    awid                   == local::test_id;
    awlen                  == 0;
    awsize                 == WRITE_4_BYTES;
    awburst                == WRITE_INCR;
    transfer_type          == BLOCKING_WRITE;
    if(local::control_prot_fixed) awprot == awprot_e'(local::control_prot);
  }) `uvm_fatal(get_type_name(), "Randomization failed")
  // The descriptor is an attachment, set after randomize() (see the field
  // note in axi4_master_tx); the BFM validates it at accept time.
  item.x_inject_target        = target;
  item.x_inject_cycles        = (target == X_INJ_NONE) ? 0 : int'(x_inject_cycles);
  item.x_inject_assert_policy = assert_policy;
  finish_item(item);
endtask : send_write_item

//--------------------------------------------------------------------------------------------
// Task: send_read_item
// Read-side counterpart of send_write_item.
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_seq::send_read_item(input x_inject_target_e target, input bit [ADDRESS_WIDTH-1:0] addr, output axi4_master_tx item);
  item = axi4_master_tx::type_id::create("req");
  start_item(item);
  if(!item.randomize() with {
    tx_type                == READ;
    araddr                 == local::addr;
    arid                   == local::test_id;
    arlen                  == 0;
    arsize                 == READ_4_BYTES;
    arburst                == READ_INCR;
    transfer_type          == BLOCKING_READ;
    if(local::control_prot_fixed) arprot == arprot_e'(local::control_prot);
  }) `uvm_fatal(get_type_name(), "Randomization failed")
  item.x_inject_target        = target;
  item.x_inject_cycles        = (target == X_INJ_NONE) ? 0 : int'(x_inject_cycles);
  item.x_inject_assert_policy = assert_policy;
  finish_item(item);
endtask : send_read_item

//--------------------------------------------------------------------------------------------
// Task: inject_x_on_awvalid
// Inject X on AWVALID while the bus is idle (Option C: no item is involved in
// the injection itself), then send a recovery write.
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_seq::inject_x_on_awvalid();
  axi4_master_agent_config cfg;
  bit timed_out;

  `uvm_info(get_type_name(), "Starting AWVALID X injection test (idle path)", UVM_MEDIUM)

  cfg = get_agent_cfg();
  if(cfg == null) begin
    `uvm_error(get_type_name(), "cannot reach the agent config through m_sequencer - idle AWVALID injection has no delivery path")
    return;
  end

  last_idle_req = axi4_master_x_inject_idle_req::type_id::create("awvalid_idle_req");
  last_idle_req.target        = X_INJ_AWVALID;
  last_idle_req.cycles        = x_inject_cycles;
  last_idle_req.assert_policy = assert_policy;
  cfg.x_inject_idle_mbx.put(last_idle_req);
  `uvm_info(get_type_name(), $sformatf("Requested idle X injection on AWVALID for %0d cycles (bound %0t)", x_inject_cycles, idle_req_timeout), UVM_LOW)

  last_idle_req.wait_done(idle_req_timeout, timed_out);
  if(timed_out) begin
    `uvm_error(get_type_name(), $sformatf("idle AWVALID X injection did not complete within the sequence's bound of %0t (%s)", idle_req_timeout, last_idle_req.status_str()))
  end
  else begin
    check_inject_status("idle", X_INJ_AWVALID, last_idle_req.x_inject_result,
                        last_idle_req.x_inject_accepted, last_idle_req.x_inject_started, last_idle_req.x_inject_completed,
                        last_idle_req.x_inject_cycles_driven, last_idle_req.x_inject_start_time, last_idle_req.x_inject_end_time);
  end

  // Recovery: an ordinary write must complete after the idle injection.
  send_write_item(X_INJ_NONE, target_addr + 16, last_recovery_item);

  `uvm_info(get_type_name(), "X injection on AWVALID completed with recovery test", UVM_HIGH)
endtask : inject_x_on_awvalid

//--------------------------------------------------------------------------------------------
// Task: inject_x_on_awaddr
// Inject X on AWADDR signal with AWVALID=1, in front of the injection item.
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_seq::inject_x_on_awaddr();
  `uvm_info(get_type_name(), "Starting AWADDR X injection test", UVM_MEDIUM)
  send_write_item(X_INJ_AWADDR, target_addr + 16, last_inject_item);
  check_inject_status("item", X_INJ_AWADDR, last_inject_item.x_inject_result,
                      last_inject_item.x_inject_accepted, last_inject_item.x_inject_started, last_inject_item.x_inject_completed,
                      last_inject_item.x_inject_cycles_driven, last_inject_item.x_inject_start_time, last_inject_item.x_inject_end_time);
  send_write_item(X_INJ_NONE, target_addr + 32, last_recovery_item);
  `uvm_info(get_type_name(), "X injection on AWADDR completed with recovery test", UVM_HIGH)
endtask : inject_x_on_awaddr

//--------------------------------------------------------------------------------------------
// Task: inject_x_on_wdata
// Inject X on WDATA signal with WVALID=1, in front of the injection item.
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_seq::inject_x_on_wdata();
  `uvm_info(get_type_name(), "Starting WDATA X injection test", UVM_MEDIUM)
  send_write_item(X_INJ_WDATA, target_addr, last_inject_item);
  check_inject_status("item", X_INJ_WDATA, last_inject_item.x_inject_result,
                      last_inject_item.x_inject_accepted, last_inject_item.x_inject_started, last_inject_item.x_inject_completed,
                      last_inject_item.x_inject_cycles_driven, last_inject_item.x_inject_start_time, last_inject_item.x_inject_end_time);
  send_write_item(X_INJ_NONE, target_addr + 32, last_recovery_item);
  `uvm_info(get_type_name(), "X injection on WDATA completed with recovery test", UVM_HIGH)
endtask : inject_x_on_wdata

//--------------------------------------------------------------------------------------------
// Task: inject_x_on_arvalid
// Inject X on ARVALID signal in front of the injection (read) item.
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_seq::inject_x_on_arvalid();
  `uvm_info(get_type_name(), "Starting ARVALID X injection test", UVM_MEDIUM)
  send_read_item(X_INJ_ARVALID, target_addr, last_inject_item);
  check_inject_status("item", X_INJ_ARVALID, last_inject_item.x_inject_result,
                      last_inject_item.x_inject_accepted, last_inject_item.x_inject_started, last_inject_item.x_inject_completed,
                      last_inject_item.x_inject_cycles_driven, last_inject_item.x_inject_start_time, last_inject_item.x_inject_end_time);
  send_read_item(X_INJ_NONE, target_addr + 32, last_recovery_item);
  `uvm_info(get_type_name(), "X injection on ARVALID completed with recovery test", UVM_HIGH)
endtask : inject_x_on_arvalid

//--------------------------------------------------------------------------------------------
// Task: inject_x_on_bready
// Inject X on BREADY signal from master side, in front of the injection item.
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_seq::inject_x_on_bready();
  `uvm_info(get_type_name(), "Starting BREADY X injection test", UVM_MEDIUM)
  send_write_item(X_INJ_BREADY, target_addr + 24, last_inject_item);
  check_inject_status("item", X_INJ_BREADY, last_inject_item.x_inject_result,
                      last_inject_item.x_inject_accepted, last_inject_item.x_inject_started, last_inject_item.x_inject_completed,
                      last_inject_item.x_inject_cycles_driven, last_inject_item.x_inject_start_time, last_inject_item.x_inject_end_time);
  send_write_item(X_INJ_NONE, target_addr + 40, last_recovery_item);
  `uvm_info(get_type_name(), "X injection on BREADY completed with recovery test", UVM_HIGH)
endtask : inject_x_on_bready

//--------------------------------------------------------------------------------------------
// Task: inject_x_on_rready
// Inject X on RREADY signal from master side, in front of the injection item.
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_seq::inject_x_on_rready();
  `uvm_info(get_type_name(), "Starting RREADY X injection test", UVM_MEDIUM)
  send_read_item(X_INJ_RREADY, target_addr + 32, last_inject_item);
  check_inject_status("item", X_INJ_RREADY, last_inject_item.x_inject_result,
                      last_inject_item.x_inject_accepted, last_inject_item.x_inject_started, last_inject_item.x_inject_completed,
                      last_inject_item.x_inject_cycles_driven, last_inject_item.x_inject_start_time, last_inject_item.x_inject_end_time);
  send_read_item(X_INJ_NONE, target_addr + 48, last_recovery_item);
  `uvm_info(get_type_name(), "X injection on RREADY completed with recovery test", UVM_HIGH)
endtask : inject_x_on_rready

`endif
