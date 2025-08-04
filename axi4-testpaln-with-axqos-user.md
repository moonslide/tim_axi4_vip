# EXTENDED AXI4 BUS MATRIX VERIFICATION PLAN (QoS, AXUSER)

## 1. INTRODUCTION

This document extends the "AXI4 Bus Matrix Verification Plan (10x10)" to provide comprehensive verification strategies for Quality of Service (QoS) and user-defined signals (AxUSER/BUSER/RUSER). The verification approach ensures robust handling of priority-based arbitration and sideband signal integrity in compliance with the AMBA AXI4 protocol specification in the doc/IHI0022D_amba_axi_protocol_spec.pdf by pypdf2 .
The reference bus matrix is same as 10x10 enhanced bus matrix you need write sequnce and the testcase should use virtual sequences to running case 
### 1.1 Scope
- Quality of Service (QoS) arbitration mechanisms
- User-defined sideband signals (AWUSER, ARUSER, WUSER, BUSER, RUSER)
- Integration with existing AXI4 ordering rules
- Performance impact of QoS implementation

### 1.2 References
- AMBA AXI4 Protocol Specification (ARM IHI 0022E)
- AXI4 Bus Matrix Verification Plan (10x10) - Base Document

### 1.3 Configuration Parameters
```systemverilog
// Define configurable parameters for the verification environment
`define AXI_QOS_WIDTH     4    // Standard AXI4 QoS width
`define AXI_AWUSER_WIDTH  32   // Configurable AWUSER width
`define AXI_ARUSER_WIDTH  32   // Configurable ARUSER width  
`define AXI_WUSER_WIDTH   32   // Configurable WUSER width
`define AXI_BUSER_WIDTH   16   // Configurable BUSER width
`define AXI_RUSER_WIDTH   16   // Configurable RUSER width

// Alternative: Use configuration class
class axi_config;
  parameter int QOS_WIDTH     = 4;
  parameter int AWUSER_WIDTH  = 32;
  parameter int ARUSER_WIDTH  = 32;
  parameter int WUSER_WIDTH   = 32;
  parameter int BUSER_WIDTH   = 16;
  parameter int RUSER_WIDTH   = 16;
endclass
```

---

## 2. VERIFICATION PLATFORM: BUS REFERENCE MODEL REQUIREMENTS

The bus reference model (golden model) must implement the following features to accurately verify QoS and AxUSER/BUSER/RUSER behavior.

### 2.1 QoS Modeling Requirements

#### 2.1.1 Priority Arbitration Engine
- **Multi-Level Priority Support**: Implement 2^`AXI_QOS_WIDTH` priority levels (default: 16 levels for 4-bit QoS)
- **Configurable QoS Width**: Support parameterized QoS width via `AXI_QOS_WIDTH` define
- **QoS Value Range**: {`AXI_QOS_WIDTH`{1'b0}} = lowest priority, {`AXI_QOS_WIDTH`{1'b1}} = highest priority
- **Configurable Arbitration Policy**: Support multiple arbitration schemes:
  - Fixed Priority: Higher QoS always wins
  - Weighted Round Robin: QoS determines weight in round-robin scheduling
  - Hybrid: Combination of fixed priority and fair sharing within priority levels

#### 2.1.2 QoS Integration with AXI Ordering
- **ID-Based Ordering Precedence**: Transactions with same AxID from same master must maintain order regardless of QoS
- **QoS Arbitration Points**:
  - Apply QoS arbitration only at slave port contention
  - Maintain separate arbitration for read and write channels
  - Independent QoS evaluation for each burst transaction

#### 2.1.3 QoS Tie-Breaking Rules
When multiple transactions have identical QoS values:
1. First-come-first-served (FCFS) as primary tie-breaker
2. Master ID as secondary tie-breaker (configurable priority order)
3. Transaction type (read vs write) as tertiary tie-breaker

### 2.2 AxUSER and BUSER/RUSER Modeling

#### 2.2.1 Signal Propagation Requirements
- **Bit-Width Configurability**: Support parameterized widths for all USER signals
- **End-to-End Integrity**: Track USER signals from master through interconnect to slave
- **Synchronization Validation**: Verify USER signals are stable when corresponding VALID is asserted

#### 2.2.2 Functional Modeling Capabilities
The reference model must support configurable USER signal interpretations:

| USER Signal | Bit Width | Example Functional Uses | Model Requirements |
|-------------|-----------|------------------------|-------------------|
| AWUSER | `AXI_AWUSER_WIDTH` | Parity bits, Security tags, Transaction ID extension | Configurable checker/generator |
| ARUSER | `AXI_ARUSER_WIDTH` | Cache hints, Prefetch indicators, QoS extensions | Parameterized decoder |
| WUSER | `AXI_WUSER_WIDTH` | Data integrity checks, Byte-enable extensions | Per-beat validation |
| BUSER | `AXI_BUSER_WIDTH` | Error codes, Write completion status | Slave-specific generation |
| RUSER | `AXI_RUSER_WIDTH` | Read data attributes, ECC syndrome | Per-beat attributes |

#### 2.2.3 Error Injection and Validation
- Support corruption of USER signals for negative testing
- Implement USER signal protocol checkers (stable during VALID)
- Model slave responses based on USER signal values

---

## 3. COMPREHENSIVE TEST SUITE

### 3.1 QoS Functional Test Cases

#### 3.1.1 Basic QoS Priority Tests

**Test: qos_basic_priority_order**
- **Objective**: Verify basic QoS priority ordering
- **Scenario**:
  1. Queue 4 simultaneous read requests to same slave:
     - M0→S2: ARQOS=0x0002
     - M1→S2: ARQOS=0x0008
     - M3→S2: ARQOS=0x0004
     - M4→S2: ARQOS=0x000C
  2. All requests arrive at interconnect in same clock cycle
- **Expected**: Service order: M4 (QoS=12), M1 (QoS=8), M3 (QoS=4), M0 (QoS=2)

**Test: qos_equal_priority_fairness**
- **Objective**: Verify fair arbitration for equal QoS values
- **Scenario**:
  1. Configure all masters with same QoS value (0x0008)
  2. Generate continuous traffic from all masters to single slave
  3. Measure bandwidth allocation over 10,000 cycles
- **Expected**: Each master receives equal bandwidth (±5% tolerance)

#### 3.1.2 QoS vs AXI Ordering Tests

**Test: qos_id_ordering_precedence**
- **Objective**: Verify AxID ordering overrides QoS
- **Scenario**:
  1. M5 issues 3 writes to S8 with same AWID=0x5:
     - Txn1: AWQOS=0x0002, AWADDR=0x0000_000A_0003_1000
     - Txn2: AWQOS=0x000F, AWADDR=0x0000_000A_0003_2000  
     - Txn3: AWQOS=0x0008, AWADDR=0x0000_000A_0003_3000
- **Expected**: Transactions complete in order: Txn1, Txn2, Txn3

**Test: qos_multi_id_arbitration**
- **Objective**: Verify QoS applies correctly across different IDs
- **Scenario**:
  1. M5 issues writes with alternating IDs and QoS:
     - AWID=0x1, AWQOS=0x0004
     - AWID=0x2, AWQOS=0x000C
     - AWID=0x1, AWQOS=0x0004
     - AWID=0x2, AWQOS=0x000C
- **Expected**: ID=0x2 transactions get priority, but maintain order within each ID

#### 3.1.3 QoS Stress Tests

**Test: qos_saturation_stress**
- **Objective**: Verify QoS under heavy load conditions
- **Scenario**:
  1. All masters generate maximum traffic to single slave
  2. Vary QoS values dynamically during test
  3. Monitor latency and throughput per QoS level
- **Expected**: Higher QoS consistently achieves lower latency

**Test: qos_starvation_prevention**
- **Objective**: Ensure low-priority transactions aren't starved
- **Scenario**:
  1. High-priority master (QoS=0x000F) generates continuous traffic
  2. Low-priority master (QoS=0x0001) issues periodic requests
  3. Run for 100,000 cycles
- **Expected**: Low-priority requests complete within bounded time

### 3.2 USER Signal Test Cases

#### 3.2.1 Signal Integrity Tests

**Test: user_signal_passthrough_all_channels**
- **Objective**: Verify USER signal integrity across all channels
- **Test Matrix**:
  ```
  For each master M[0-9]:
    For each accessible slave S[0-9]:
      - Drive unique patterns on AWUSER/ARUSER/WUSER
      - Verify exact match at slave interface
      - Check BUSER/RUSER returned to correct master
  ```

**Test: user_signal_width_mismatch**
- **Objective**: Verify handling of USER width mismatches
- **Scenario**:
  1. Configure masters with different USER widths
  2. Configure interconnect adaptation policy
  3. Verify correct truncation/padding behavior

#### 3.2.2 Functional USER Signal Tests

**Test: user_parity_protection**
- **Objective**: Implement and verify parity protection via USER signals
- **Implementation**:
  ```systemverilog
  // Using configuration parameters
  logic [`AXI_AWUSER_WIDTH-1:0] awuser;
  logic [`AXI_WUSER_WIDTH-1:0]  wuser;
  logic [`AXI_BUSER_WIDTH-1:0]  buser;
  
  // Example implementation (adjust based on actual widths)
  awuser[0] = ^awaddr;  // Parity of address
  wuser[0]  = ^wdata;   // Parity of data  
  buser[1:0] = {addr_parity_error, data_parity_error};
  ```
- **Test Sequence**:
  1. Send transactions with correct parity
  2. Inject parity errors randomly
  3. Verify slave detection and BUSER response

**Test: user_security_tagging**
- **Objective**: Implement security classification via USER
- **Implementation**:
  ```systemverilog
  // Security level encoding (using lower 4 bits of USER signals)
  logic [3:0] security_level;
  
  // Assign to USER signals (width-aware)
  awuser[3:0] = (`AXI_AWUSER_WIDTH >= 4) ? security_level : 4'b0;
  aruser[3:0] = (`AXI_ARUSER_WIDTH >= 4) ? security_level : 4'b0;
  
  // Slave enforces access based on security level
  if (awuser[3:0] < slave_min_security_level) begin
    bresp = SLVERR;
  end
  ```

**Test: user_transaction_tracing**
- **Objective**: Use USER for transaction debug/trace
- **Implementation**:
  ```systemverilog
  // Define trace fields based on available width
  typedef struct packed {
    logic [15:0] timestamp;
    logic [7:0]  source_id;
    logic [7:0]  sequence;
  } trace_info_t;
  
  // Only use if USER width is sufficient
  if (`AXI_AWUSER_WIDTH >= $bits(trace_info_t)) begin
    trace_info_t trace;
    awuser = trace;
  end
  
  if (`AXI_BUSER_WIDTH >= 32) begin
    buser[31:0] = {completion_time[15:0], slave_id[7:0], status[7:0]};
  end
  ```

#### 3.2.3 Error Injection Tests

**Test: user_signal_protocol_violation**
- **Objective**: Verify detection of USER signal protocol violations
- **Scenarios**:
  1. Change USER during VALID assertion
  2. Drive USER when VALID deasserted
  3. Floating USER signals
- **Expected**: Reference model flags protocol violations

**Test: user_signal_corruption**
- **Objective**: Test system resilience to USER corruption
- **Method**: Randomly corrupt USER bits in interconnect
- **Verification**: Check error detection/correction mechanisms

### 3.3 Combined QoS and USER Tests

**Test: qos_with_user_priority_boost**
- **Objective**: Implement dynamic QoS adjustment via USER
- **Implementation**:
  ```systemverilog
  // Dynamic QoS boost using lower bits of AWUSER
  logic [`AXI_QOS_WIDTH-1:0] base_qos;
  logic [`AXI_QOS_WIDTH-1:0] qos_boost;
  logic [`AXI_QOS_WIDTH:0]   effective_qos; // Extra bit for overflow
  
  // Extract boost value from USER signal (if width permits)
  qos_boost = (`AXI_AWUSER_WIDTH >= `AXI_QOS_WIDTH) ? 
              awuser[`AXI_QOS_WIDTH-1:0] : {`AXI_QOS_WIDTH{1'b0}};
  
  // Calculate effective QoS with saturation
  effective_qos = base_qos + qos_boost;
  if (effective_qos > {`AXI_QOS_WIDTH{1'b1}})
    effective_qos = {`AXI_QOS_WIDTH{1'b1}}; // Saturate at max
    
  // Example: AWQOS=0x0004 + AWUSER[3:0]=0x0003 = Effective_QoS=0x0007
  ```

**Test: user_based_qos_routing**
- **Objective**: Route based on USER-encoded attributes
- **Scenario**: USER signals encode traffic class, affecting routing decisions

---

## 4. COVERAGE METRICS AND GOALS

### 4.1 Functional Coverage Points

#### QoS Coverage
```systemverilog
covergroup qos_coverage;
  qos_values: coverpoint axi_qos[`AXI_QOS_WIDTH-1:0] {
    bins all_values[] = {[0:(1<<`AXI_QOS_WIDTH)-1]};
  }
  
  qos_transitions: coverpoint axi_qos[`AXI_QOS_WIDTH-1:0] {
    bins low_to_high = ({`AXI_QOS_WIDTH{1'b0}} => {`AXI_QOS_WIDTH{1'b1}});
    bins high_to_low = ({`AXI_QOS_WIDTH{1'b1}} => {`AXI_QOS_WIDTH{1'b0}});
    wildcard bins incremental = ({`AXI_QOS_WIDTH{1'b?}} => {`AXI_QOS_WIDTH{1'b?}}+1);
  }
  
  qos_contention: cross master_id, slave_id, axi_qos[`AXI_QOS_WIDTH-1:0] {
    bins high_contention = binsof(slave_id) intersect {[0:9]} &&
                          binsof(master_id) intersect {[0:9]};
  }
endgroup
```

#### USER Signal Coverage
```systemverilog
covergroup user_coverage;
  awuser_patterns: coverpoint awuser[`AXI_AWUSER_WIDTH-1:0] {
    bins zero = {0};
    bins ones = {{`AXI_AWUSER_WIDTH{1'b1}}};
    bins alternating[] = {32'hAAAAAAAA, 32'h55555555}; // If width >= 32
  }
  
  buser_values: coverpoint buser[`AXI_BUSER_WIDTH-1:0] {
    bins zero = {0};
    bins error_codes[] = {[1:(1<<`AXI_BUSER_WIDTH)-1]};
  }
  
  user_correlation: cross awuser[`AXI_AWUSER_WIDTH-1:0], buser[`AXI_BUSER_WIDTH-1:0] {
    bins error_response = binsof(buser) intersect {[1:$]};
  }
endgroup
```

### 4.2 Coverage Goals
- **QoS Coverage**: ≥ 95% with all QoS values and transitions covered
- **USER Coverage**: ≥ 90% with all defined functional modes tested
- **Cross Coverage**: ≥ 85% for QoS/USER interaction scenarios
- **Error Coverage**: 100% of defined error conditions

### 4.3 Performance Metrics
- **QoS Latency Impact**: < 5% increase vs non-QoS implementation
- **USER Signal Overhead**: < 2% area increase for USER support
- **Simulation Performance**: < 20% slowdown with full QoS/USER checking

---

## 5. DEBUG AND DIAGNOSTICS

### 5.1 QoS Debug Features
- Transaction trace with QoS values and arbitration decisions
- QoS violation detection and reporting
- Bandwidth allocation per QoS level reporting
- Starvation detection alerts

### 5.2 USER Signal Debug
- USER signal change detection and logging
- Protocol violation reporting with timestamps
- USER-based transaction filtering in waveforms
- Correlation analysis between USER values and system behavior

---

## 6. REGRESSION STRATEGY

### 6.1 Test Execution Phases
1. **Sanity**: Basic QoS and USER connectivity (5 min)
2. **Functional**: All individual test cases (2 hours)
3. **Stress**: Long-running stress scenarios (8 hours)
4. **Random**: Constrained random with coverage (12 hours)

### 6.2 Coverage-Driven Closure
- Daily coverage reports with gap analysis
- Directed tests for coverage holes
- Automatic test generation for uncovered scenarios

---

## APPENDIX A: AXI BUS MATRIX (10X10) SYSTEM DEFINITION

### A.1 Master Profiles

| Master ID | Name | Use Case | AxPROT[2:0] | AxCACHE[3:0] | Notes |
|-----------|------|----------|-------------|--------------|-------|
| M0 | Secure CPU Core | Secure OS Kernel | 0b000 | 0b1111 | Full access |
| M1 | Non-Secure CPU Core | Applications | 0b011 | 0b1111 | NS restricted |
| M2 | Instruction Fetch | CPU I-Fetch | 0b100 | 0b0110 | Read-only |
| M3 | GPU | Graphics | 0b011 | 0b1111 | High bandwidth |
| M4 | AI Accelerator | AI/ML | 0b010 | 0b0011 | Bufferable only |
| M5 | DMA Secure | Secure DMA | 0b000 | 0b0010 | Trusted |
| M6 | DMA Non-Secure | NS DMA | 0b010 | 0b0010 | Untrusted |
| M7 | Malicious Master | Attack simulation | 0b011 | 0b0000 | Test only |
| M8 | Read-Only Peripheral | Sensors | 0b011 | 0b0001 | Read only |
| M9 | Legacy Master | Compatibility | 0b010 | 0b0000 | Non-cacheable |

### A.2 Slave Regions

| Slave ID | Name | Address Range | Size | Access Policy |
|----------|------|---------------|------|---------------|
| S0 | DDR Secure Kernel | 0x0000_0008_0000_0000 - 0x0000_0008_3FFF_FFFF | 1GB | Secure R/W |
| S1 | DDR Non-Secure User | 0x0000_0008_4000_0000 - 0x0000_0008_7FFF_FFFF | 1GB | Non-Secure R/W |
| S2 | DDR Shared Buffer | 0x0000_0008_8000_0000 - 0x0000_0008_BFFF_FFFF | 1GB | Shared R/W |
| S3 | Illegal Address Hole | 0x0000_0008_C000_0000 - 0x0000_0008_FFFF_FFFF | 1GB | Always DECERR |
| S4 | XOM Instruction-Only | 0x0000_0009_0000_0000 - 0x0000_0009_3FFF_FFFF | 1GB | Execute-Only |
| S5 | RO Peripheral | 0x0000_000A_0000_0000 - 0x0000_000A_0000_FFFF | 64KB | Read-Only |
| S6 | Privileged-Only | 0x0000_000A_0001_0000 - 0x0000_000A_0001_FFFF | 64KB | Privileged R/W |
| S7 | Secure-Only | 0x0000_000A_0002_0000 - 0x0000_000A_0002_FFFF | 64KB | Secure R/W |
| S8 | Scratchpad | 0x0000_000A_0003_0000 - 0x0000_000A_0003_FFFF | 64KB | Shared R/W |
| S9 | Attribute Monitor | 0x0000_000A_0004_0000 - 0x0000_000A_0004_FFFF | 64KB | Write-Only |

### A.3 Access Control Matrix

[THIS IS TABLE: A 10x10 matrix showing access permissions between masters M0-M9 and slaves S0-S9, with responses like OKAY, DECERR, SLVERR for different R/W operations]

---

## APPENDIX B: USER SIGNAL WIDTH CONFIGURATION

| Signal | Parameter/Define | Default Width | Configurable Range | Typical Uses |
|--------|-----------------|---------------|-------------------|--------------|
| AWUSER | `AXI_AWUSER_WIDTH` | 32 bits | 1-128 bits | Address attributes, security tags |
| WUSER | `AXI_WUSER_WIDTH` | 32 bits | 1-128 bits | Data attributes, ECC |
| BUSER | `AXI_BUSER_WIDTH` | 16 bits | 1-64 bits | Write response status |
| ARUSER | `AXI_ARUSER_WIDTH` | 32 bits | 1-128 bits | Read attributes, prefetch hints |
| RUSER | `AXI_RUSER_WIDTH` | 16 bits | 1-64 bits | Read data attributes |

### Configuration Guidelines
```systemverilog
// Method 1: Using defines (compile-time configuration)
`ifndef AXI_AWUSER_WIDTH
  `define AXI_AWUSER_WIDTH 32
`endif

// Method 2: Using parameters (runtime configuration)
module axi_interconnect #(
  parameter int AWUSER_WIDTH = 32,
  parameter int ARUSER_WIDTH = 32,
  parameter int WUSER_WIDTH  = 32,
  parameter int BUSER_WIDTH  = 16,
  parameter int RUSER_WIDTH  = 16,
  parameter int QOS_WIDTH    = 4
) (
  // Port declarations
);

// Method 3: Using configuration object
class axi_cfg extends uvm_object;
  rand int awuser_width;
  rand int aruser_width;
  rand int wuser_width;
  rand int buser_width;
  rand int ruser_width;
  rand int qos_width;
  
  constraint valid_widths_c {
    awuser_width inside {[1:128]};
    aruser_width inside {[1:128]};
    wuser_width  inside {[1:128]};
    buser_width  inside {[1:64]};
    ruser_width  inside {[1:64]};
    qos_width    == 4; // AXI4 standard
  }
endclass
```
