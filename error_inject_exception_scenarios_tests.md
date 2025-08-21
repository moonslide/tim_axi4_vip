Of course. Here is the complete test plan translated into English.

-----

# AMBA AXI4 Robustness Verification Test Plan

## (X-Value Injection & Exception Scenarios)

**Target:** AXI4 Slave (Extendable to Interconnect/Bridge and other DUTs)

**Objective:** This test plan aims to systematically verify the robustness and predictable behavior of a Design Under Test (DUT) when faced with unknown logic values (`'X'`) and atypical protocol events. Using four-state simulation (0/1/X/Z), the goal is to ensure the DUT does not deadlock, suffer from state corruption, or generate unexpected errors.

-----

### 0\. Scope & Assumptions

  * **Protocol Version**: AMBA AXI4, including the full VALID/READY handshake protocol for all five channels (AW, AR, W, R, B).
  * **Hardware Parameters**:
      * Data Width (`DATA_WIDTH`): Default 32-bit, parameterizable to 64/128/256-bit.
      * Address Width (`ADDR_WIDTH`): 32-bit.
      * ID Width (`ID_WIDTH`): 4-bit.
  * **Timing Assumptions**: All operations occur in a single clock domain (`aclk`) with a synchronous, active-low reset (`aresetn`).
  * **Testbench Environment**:
      * Based on the UVM (Universal Verification Methodology) framework.
      * Includes a Master Agent capable of actively injecting `'X'` values.
      * Includes a Slave Monitor and Scoreboard for response verification.
  * **'X' Injection Method**:
      * The Testbench will drive `'X'` values (`1'bx`) onto the DUT's input ports, such as `AWVALID`, `AWADDR`, `WDATA`, `BREADY`, and `RREADY`.
      * All DUT interface signals should be declared as `logic` (four-state) to prevent `'X'` values from being masked by `bit` (two-state) types.
      * Injection control is recommended via a `virtual interface`. If necessary, `force/release` mechanisms can be used, but signals must be `release`d after the test to restore normal driving.
  * **Protocol Guideline Reminder**:
      * The official AXI specification does not define behavior for handling `'X'` values at the simulation level. This plan adheres to the engineering principle of robustness: **The DUT must not deadlock, must not enter an unrecoverable state, and must adopt a conservative response to indeterminate inputs** (e.g., holding `READY=0` or responding with an error).

-----

### 1\. Common Monitors & Checkers

#### 1.1 Signal Stability During 'X' Detection

The DUT's outputs should not become unstable as a result of its inputs being `'X'`.

```systemverilog
// SVA Example: The target signal 'sig' should remain stable while 'gate_ready' is 'X'.
property stable_during_x(sig, gate_ready);
  @(posedge aclk) disable iff(!aresetn)
    $isunknown(gate_ready) |-> $stable(sig);
endproperty

// Application Example: When the Master's BREADY is 'X', the Slave's BVALID/BRESP/BID must remain stable.
BCHAN_STABLE_DURING_X_BREADY:
  assert property (stable_during_x({BVALID, BRESP, BID}, BREADY));
```

#### 1.2 Handshake Safety

A handshake must not complete if either the `VALID` or `READY` signal on any channel is `'X'`.

```systemverilog
// SVA Example: A handshake (valid && ready) must not occur if either signal is 'X'.
property no_x_handshake(valid, ready);
  @(posedge aclk) disable iff(!aresetn)
    ($isunknown(valid) || $isunknown(ready)) |-> !(valid && ready);
endproperty

// Application Example: Apply assertions to all channels.
AW_NO_X_HANDSHAKE: assert property(no_x_handshake(AWVALID, AWREADY));
AR_NO_X_HANDSHAKE: assert property(no_x_handshake(ARVALID, ARREADY));
W_NO_X_HANDSHAKE:  assert property(no_x_handshake(WVALID,  WREADY));
R_NO_X_HANDSHAKE:  assert property(no_x_handshake(RVALID,  RREADY));
B_NO_X_HANDSHAKE:  assert property(no_x_handshake(BVALID,  BREADY));
```

#### 1.3 Timeout/Deadlock Detection

  * Implement a watchdog timer for each AXI channel. If a channel makes no progress within a specified period (e.g., 4096 cycles), a timeout error should be flagged.
  * Log the duration of all stall events for post-simulation analysis.

#### 1.4 Scoreboard Verification Rules (Summary)

  * Any transaction that might have been erroneously handshaken during an `'X'` injection period is considered invalid. The scoreboard must not update its memory model or internal state.
  * If the DUT accepts a request containing `'X'` (e.g., on the address or data bus):
      * **Acceptable Behavior 1 (Error Response)**: The DUT should respond with `SLVERR` or `DECERR` and **must not** write the `'X'`-corrupted data internally.
      * **Acceptable Behavior 2 (Request Refusal)**: The DUT should hold the corresponding `READY` signal low until the input signal becomes stable and valid.

-----

### 2\. Global Test Controls (Knobs)

The testbench should provide the following configurable parameters to facilitate randomization and scenario mixing:

  * `x_inject_cycles`: The number of consecutive cycles to inject `'X'` (Recommended range: 1-5).
  * `x_inject_phase`: The target AXI channel for `'X'` injection (AW/AR/W/B/R).
  * `x_target_signal`: The specific signal to inject `'X'` into (e.g., `AWVALID`, `AWADDR`, `WDATA`, `BREADY`, `RREADY`).
  * `timeout_cycles`: The watchdog timer threshold for channels.
  * `recover_to_value`: The value a signal should recover to after the `'X'` state ends (e.g., 0, 1, a legal address, legal data).

-----

### 3\. Test Overview (Matrix)

| Test Case ID | Injection Focus / Scenario | Objective |
| :--- | :--- | :--- |
| **4.1** | `AWVALID='X'` (during bus idle) | Verify X tolerance on the write address channel before a transaction starts. |
| **4.2** | `AWADDR='X'` (with `AWVALID=1`) | Verify the DUT's rejection or error handling strategy for an uncertain address. |
| **4.3** | `WDATA='X'` (with `WVALID=1`) | Verify the DUT's handling mechanism for corrupted write data payloads. |
| **4.4** | `ARVALID='X'` (during bus idle) | Verify X tolerance on the read address channel before a transaction starts. |
| **4.5** | `BREADY='X'` (from Master side) | Verify the Slave remains stable when the Master cannot accept a write response. |
| **4.6** | `RREADY='X'` (from Master side) | Verify the Slave remains stable when the Master cannot accept read data. |
| **4.7** | Master aborts `AWVALID` before handshake | Verify the Slave's handling of a prematurely aborted write request. |
| **4.8** | Master aborts `ARVALID` before handshake | Verify the Slave's handling of a prematurely aborted read request. |
| **4.9** | Slave channel stall near timeout threshold | Verify that a transaction can recover and complete successfully if a stall ends just before a timeout. |
| **4.10** | Accessing a protected or illegal address | Verify the DUT's custom address protection or permission logic. |
| **4.11** | Simulating an internal ECC/Parity error | Use a backdoor to inject an error and verify the DUT correctly reports `SLVERR`. |
| **4.12** | Consecutive reads to a special-function register | Verify behaviors like read-to-clear, counters, or status registers. |

-----

### 4\. Detailed Test Cases

Each test case below should include: **Pre-conditions, Stimulus Steps, Expected Behavior, Monitor Verification, Coverage Goals, and Notes**.

#### Test Case 4.1: Inject 'X' into `AWVALID`

  * **Pre-conditions**: The AXI bus is idle. Prepare a set of legal write address signals (e.g., `AWADDR=0x1000`, `AWID=0x1`, `AWLEN=0`).
  * **Stimulus Steps**: Drive `AWVALID` to `'X'` for 3 consecutive clock cycles while keeping other `AW*` signals stable.
  * **Expected Behavior (Slave)**:
      * While `AWVALID` is `'X'`, `AWREADY` must remain low, and no handshake should occur.
      * The DUT must not update any internal states or counters related to the address channel.
  * **Monitor Verification**:
      * The `no_x_handshake` assertion should pass.
      * After `AWVALID` recovers to `1`, the address channel handshake should complete normally.
  * **Coverage Goals**: `'X'` injection for 1, 2, and 3 consecutive cycles.

#### Test Case 4.2: Inject 'X' into `AWADDR` (with `AWVALID=1`)

  * **Pre-conditions**: `AWVALID=1`, `AWID=0x2`.
  * **Stimulus Steps**: On the first cycle `AWVALID` is high, drive `AWADDR` to `'X'`. Do not send any data on the W channel yet.
  * **Expected Behavior (Slave)**:
      * While `AWADDR` is `'X'`, `AWREADY` must be 0, rejecting the indeterminate request.
      * A handshake should only be allowed after `AWADDR` recovers to a legal value.
  * **Monitor Verification**: No AW handshake occurs while `AWADDR` is `'X'`, and no subsequent W or B channel activity is triggered.
  * **Notes**: This tests for the prevention of latching an unknown address, which could lead to a write to an unintended memory location.

#### Test Case 4.3: Inject 'X' into `WDATA` (with `WVALID=1`)

  * **Pre-conditions**: A successful AW handshake has already occurred (`AWID=0x3`, `AWADDR=0x1010`, `AWLEN=0`).
  * **Stimulus Steps**: Drive `WVALID=1`, `WID=0x3`, `WSTRB=0xF`, `WLAST=1`, but drive `WDATA` to `'X'`.
  * **Expected Behavior (Slave)**: (Must be confirmed with the design team; either is acceptable)
    1.  **Conservative Refusal (Stall)**: `WREADY` remains 0 until `WDATA` becomes stable. The write eventually completes normally with the stable data.
    2.  **Accept and Respond with Error**: If `WREADY=1` and the request is accepted, the DUT **must not** write the `'X'` data to memory and must return `BRESP=SLVERR` on the B channel.
  * **Monitor Verification**:
      * For strategy (1), verify `WDATA` is not `'X'` when the handshake occurs.
      * For strategy (2), verify the scoreboard shows no data change at the target address and that `BRESP` is `SLVERR`.
  * **Coverage Goals**: Different `WSTRB` masks; partial `'X'` on `WDATA` (e.g., only one byte).

#### Test Case 4.4: Inject 'X' into `ARVALID`

  * **Pre-conditions**: The AXI bus is idle. Prepare a set of legal read address signals (e.g., `ARADDR=0x1020`, `ARID=0x4`, `ARLEN=0`).
  * **Stimulus Steps**: Drive `ARVALID` to `'X'` for 3 consecutive clock cycles.
  * **Expected Behavior (Slave)**:
      * No AR handshake should occur; `ARREADY` should remain 0.
      * No R channel activity should be triggered.
  * **Monitor Verification**: `ARREADY` does not go high during the `'X'` period. A normal read can proceed after `ARVALID` recovers to `1`.
  * **Notes**: This case is the read-channel symmetric equivalent of Test Case 4.1.

#### Test Case 4.5: Inject 'X' into Master-side `BREADY`

  * **Pre-conditions**: A write transaction has completed, and the Slave has driven `BVALID=1`, `BRESP=OKAY`, `BID=0x5`.
  * **Stimulus Steps**: Drive `BREADY` to `'X'` for 2 cycles, then restore it to `1`.
  * **Expected Behavior (Slave)**:
      * The `BVALID`, `BRESP`, and `BID` outputs must remain stable. The DUT must not change its response or deadlock due to the downstream `'X'`.
  * **Monitor Verification**:
      * Use a `$stable()` assertion to check the stability of B channel outputs during the `'X'` period.
      * The handshake should complete on the same cycle or the cycle after `BREADY` recovers to `1`.

#### Test Case 4.6: Inject 'X' into Master-side `RREADY`

  * **Pre-conditions**: A read request has completed, and the Slave has driven `RVALID=1`, `RDATA=D`, `RRESP=OKAY`, `RLAST=1`, `RID=0x6`.
  * **Stimulus Steps**: Drive `RREADY` to `'X'` for 2 cycles, then restore it to `1`.
  * **Expected Behavior (Slave)**:
      * All R channel outputs (`RVALID`, `RDATA`, `RRESP`, etc.) must remain stable. The DUT must not change its output or deadlock.
  * **Monitor Verification**:
      * R channel outputs are `$stable` during the `'X'` period.
      * The handshake completes successfully after `RREADY` is restored.
  * **Notes**: Ensures read data does not drift due to downstream issues.

#### Test Case 4.7: Master Aborts `AWVALID` Before Handshake

  * **Stimulus Steps**:
      * t0: `AWVALID=1`, `AWADDR=0x1050`, while Slave `AWREADY=0`.
      * t0+2 clk: The Master de-asserts `AWVALID` to 0 before `AWREADY` ever goes high.
  * **Expected Behavior (Slave)**: The DUT should not register or latch this invalid request and should not generate any subsequent W or B activity for it.
  * **Monitor Verification**: The scoreboard contains no record of this transaction, and there are no write side-effects.

#### Test Case 4.8: Master Aborts `ARVALID` Before Handshake

  * **Stimulus Steps**:
      * t0: `ARVALID=1`, `ARADDR=0x1054`, while Slave `ARREADY=0`.
      * t0+2 clk: The Master de-asserts `ARVALID` to 0 prematurely.
  * **Expected Behavior (Slave)**: The DUT should not latch this request and should not generate any R activity for it.
  * **Monitor Verification**: The scoreboard contains no record of this transaction. A subsequent normal read request should succeed.

#### Test Case 4.9: Slave Channel Stall Near Timeout Threshold

  * **Stimulus Steps**: The Master initiates a write request (`AWVALID=1`). The Slave deliberately holds `AWREADY` low for a duration approaching its internal timeout threshold (e.g., hold low for 1023 cycles if the threshold is 1024), then asserts `AWREADY`.
  * **Expected Behavior (Slave)**:
      * The transaction recovers before the timeout and the subsequent W/B transaction completes successfully.
      * If the design includes a timeout-and-abort mechanism, it should be indicated via a clear status bit or error response.
  * **Monitor Verification**: Log the stall duration. Verify the transaction either completes successfully or fails cleanly, but never hangs.
  * **Coverage Goals**: The stall duration should cover the threshold `±1` and `±2` cycles. This scenario should be applied to all channels.

#### Test Case 4.10: Accessing a Protected/Illegal Address

  * **Pre-conditions**: The DUT defines a protected address region at `0x1A00` which requires writing a specific key `0xKEYVAL` to `0x1A04` to unlock.
  * **Stimulus Steps**: Attempt to write to `0x1A00` directly without first unlocking it.
  * **Expected Behavior (Slave)**: (Per DUT specification) Respond with `BRESP=SLVERR`, and the content at `0x1A00` must not be updated.
  * **Monitor Verification**:
      * Check that `BRESP` is `SLVERR`.
      * Confirm via backdoor access or a subsequent read that the value at `0x1A00` is unchanged.
      * Verify that a write after a proper unlock sequence succeeds.

#### Test Case 4.11: Simulating an Internal ECC/Parity Error

  * **Pre-conditions**: Use a backdoor mechanism or special command to create an ECC or Parity error in the DUT's internal memory at location `0x1B00`.
  * **Stimulus Steps**: Initiate a read request to address `0x1B00`.
  * **Expected Behavior (Slave)**:
      * Respond with `RRESP=SLVERR`.
      * `RDATA`, per the design spec, may return a fixed error-indicating value or the original corrupted data.
  * **Monitor Verification**: Check that `RRESP` is `SLVERR`. If an error log register exists, verify that it has been updated correctly.

#### Test Case 4.12: Consecutive Reads to a Special-Function Register

  * **Stimulus Steps**: Initiate multiple, consecutive single-beat reads to a special-function register address, `0x1C00`.
  * **Expected Behavior (Slave)**: (Per DUT specification, cover at least one of the following)
      * **Read-to-Clear**: The first read returns a status bit as 1 in `RDATA`; subsequent reads return that bit as 0.
      * **Counter**: The value of `RDATA` increments with each read.
      * **Constant**: The value of `RDATA` is the same for every read.
  * **Monitor Verification**: Compare the `RDATA` from each read to verify its behavior matches the design specification exactly.

-----

### 5\. Verification Aids: UVM Sequence & Injection Template

#### 5.1 Generic 'X' Injection Sequence (Skeleton)

```systemverilog
class axi_x_inject_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(axi_x_inject_seq)

  // --- Knobs ---
  rand string  phase;         // "AW", "AR", "W", "B", "R"
  rand string  signal;        // "VALID", "READY", "ADDR", "DATA"
  rand int     n_cycles;      // 1..5
  rand logic [31:0] addr, data;
  rand logic [3:0]  id;

  constraint c_n_cycles { n_cycles inside {[1:5]}; }

  virtual axi_if vif; // Should be connected via uvm_config_db

  `uvm_declare_p_sequencer(axi_sequencer)

  task body();
    // Get the virtual interface from the config_db
    if (!uvm_config_db#(virtual axi_if)::get(p_sequencer, "", "vif", vif))
      `uvm_fatal("VIF_FAIL", "Failed to get virtual interface")

    // Example: Inject 'X' into AWVALID
    if (phase == "AW" && signal == "VALID") begin
      // 1. Prepare stable background signals
      drive_aw_stable_fields(addr, id, /*len=*/0);

      // 2. Inject 'X'
      repeat (n_cycles) @(posedge vif.aclk) vif.awvalid <= 1'bx;

      // 3. Recover and complete the transaction
      @(posedge vif.aclk) vif.awvalid <= 1'b1;
      wait (vif.awready && vif.awvalid);
      @(posedge vif.aclk) vif.awvalid <= 1'b0;
    end
    // ... Logic for other signal injections can be implemented similarly ...
  endtask
endclass
```

-----

### 6\. Coverage Goals

  * **Functional Coverage**:
      * **X Injection**:
          * Cover all channels (`phase`) and key signals (`signal`).
          * Cover different `'X'` injection lengths (`n_cycles`).
          * Cover different `ID`s, `WSTRB` masks, and `BRESP`/`RRESP` types.
      * **Exception Scenarios**:
          * Cover branches for timeout thresholds `±1` and `±2` cycles.
          * Cover the full "fail -\> unlock -\> succeed" flow for protected resources.
          * Cover different error injection types (single-bit vs. multi-bit errors).
          * Cover all three behavioral models for special registers (Clear/Counter/Constant).
  * **Code Coverage**:
      * Target \> 90%, with special focus on condition/branch coverage for code paths that handle errors and exceptions.
  * **Assertion Coverage**:
      * Ensure that core assertions like `no_x_handshake` and stability checks are triggered and pass during tests.

-----

### 7\. Reporting & Observability

  * **Event Logging**: Log the start/end time, target signal, duration, and affected transaction ID for every `'X'` injection. Also log stall durations and any timeout triggers.
  * **Scoreboard Conclusions**: Clearly report whether writes landed, if read data was correct, and whether the DUT's behavior (Stall vs. SLVERR) matched the specification.
  * **Waveform Bookmarks**: Automatically add bookmarks to waveform files at critical moments (injection start, recovery, error response) for each test case. Format: `BOOKMARK:TestCase_4.1:Inject_Start:1234ns`, to accelerate debugging.

-----

### 8\. Risks & Notes

  * **'X' Propagation**: Be cautious with `'X'` handling within the Monitor and Scoreboard. Use the `$isunknown()` function during data comparisons to handle `'X'` states properly and avoid false negatives caused by `'X'` propagation within the testbench itself.
  * **`force/release` Mechanism**: Use `force` only when absolutely necessary. Always ensure that signals are `release`d to return control to the normal driver once the stimulus is complete.
  * **Design Specification Alignment**: For ambiguous scenarios like `'X'` on `WDATA`, the expected behavior (Stall vs. SLVERR) must be confirmed with the design team beforehand to prevent filing invalid bug reports.

-----

### 9\. Test Execution Checklist

  - [ ] Confirm the simulator is running in four-state simulation mode.
  - [ ] Confirm all DUT interface signals are declared as `logic` type.
  - [ ] Verify that injection sequence parameters (phase/signal/length) are functional.
  - [ ] Ensure that key assertions (`no_x_handshake`, stability checks, watchdogs) are enabled in the environment.
  - [ ] Check that final test reports include statistics on stalls/timeouts and `SLVERR` occurrences.
  - [ ] For each core test case, run regressions with at least 3 different random seeds or parameter variations (e.g., different IDs, addresses, burst lengths).
