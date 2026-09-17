`ifndef AXI4_MASTER_X_INJECT_IDLE_REQ_INCLUDED_
`define AXI4_MASTER_X_INJECT_IDLE_REQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_x_inject_idle_req
//
// BENCH-066 "Option C": an X-injection request that is NOT attached to a
// transaction. It is the same descriptor / status shape as the fields on
// axi4_master_tx, delivered through the owning agent's config object
// (axi4_master_agent_config::x_inject_idle_mbx) to a dedicated
// axi4_master_driver_proxy thread that runs alongside the write/read item
// loops and never waits on get_next_item(). Per agent by construction: a
// sequence reaches the mailbox through the sequencer it runs on, so the
// request can only ever be serviced by that agent's driver.
//
// Usage from a sequence:
//   req = axi4_master_x_inject_idle_req::type_id::create("req");
//   req.target = X_INJ_AWVALID; req.cycles = 4;
//   cfg.x_inject_idle_mbx.put(req);
//   req.wait_done(timeout, timed_out);   // sequence-owned bound
//   ... inspect req.result / req.start_time / req.end_time ...
//--------------------------------------------------------------------------------------------
class axi4_master_x_inject_idle_req extends uvm_object;
  `uvm_object_utils(axi4_master_x_inject_idle_req)

  // Request
  x_inject_target_e        target        = X_INJ_NONE;
  int                      cycles        = 0;
  x_inject_assert_policy_e assert_policy = X_INJ_SUPPRESS_CHECKS;

  // Status, written by the driver proxy from the BFM's return values
  bit                x_inject_accepted      = 1'b0;
  bit                x_inject_started       = 1'b0;
  bit                x_inject_completed     = 1'b0;
  x_inject_result_e  x_inject_result        = X_INJ_RESULT_NOT_REQUESTED;
  time               x_inject_start_time    = 0;
  time               x_inject_end_time      = 0;
  int                x_inject_cycles_driven = 0;

  // Raised by the proxy once the status above is final.
  event done;

  extern function new(string name = "axi4_master_x_inject_idle_req");
  extern task wait_done(input time timeout, output bit timed_out);
  extern function string status_str();
endclass : axi4_master_x_inject_idle_req

function axi4_master_x_inject_idle_req::new(string name = "axi4_master_x_inject_idle_req");
  super.new(name);
endfunction : new

// Bounded wait for completion. `timeout` is the requester's own bound
// (repair-contract item 3); 0 means wait forever. timed_out is set when the
// bound expired first - the request is then still owned by the driver and
// will be serviced whenever the channel frees, so a requester that gives up
// must expect a late injection unless it is at the end of its test.
task axi4_master_x_inject_idle_req::wait_done(input time timeout, output bit timed_out);
  timed_out = 1'b0;
  if(x_inject_completed) return;
  if(timeout == 0) begin
    @(done);
    return;
  end
  fork
    begin : WAIT_DONE
      fork
        @(done);
        begin
          #(timeout);
          timed_out = 1'b1;
        end
      join_any
      disable fork;
    end
  join
endtask : wait_done

function string axi4_master_x_inject_idle_req::status_str();
  return $sformatf("target=%s cycles=%0d policy=%s accepted=%0d started=%0d completed=%0d result=%s driven=%0d %0t..%0t",
                   target.name(), cycles, assert_policy.name(),
                   x_inject_accepted, x_inject_started, x_inject_completed, x_inject_result.name(),
                   x_inject_cycles_driven, x_inject_start_time, x_inject_end_time);
endfunction : status_str

`endif
