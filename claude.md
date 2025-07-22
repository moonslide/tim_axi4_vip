# AXI4 Bus Matrix Verification Plan (10x10)

## 1. Introduction

This document outlines the comprehensive verification strategy for the Enhanced AXI Bus Matrix. This design features 10 Masters and 10 Slaves, with access control based not only on address but also on a complex, multi-layered policy including:
- Security (AxPROT[1])
- Privilege level (AxPROT[0])
- Instruction/data type (AxPROT[2])
- Cacheability attributes (AxCACHE)

The system supports full 64-bit addressing (AWADDR[63:0] and ARADDR[63:0]) as per the AXI4 specification, enabling access to a large memory space suitable for modern SoC designs.

The goal of this plan is to achieve the highest verification coverage through comprehensive test cases utilizing concurrent, sequential, and exhaustive transaction sequences from multiple masters to ensure that the Interconnect and all Slaves correctly execute all defined access rules and error handling mechanisms.

## 2. AXI Master Profile Definitions

These 10 masters simulate various common IPs (Intellectual Properties) found within a real-world SoC (System on Chip), each with different permissions, cache policies, and security settings.

| Master ID | Master Name | Typical Use Case | AxPROT[2] (Instruction/Data) | AxPROT[1] (Secure/Non-secure) | AxPROT[0] (Privileged/Unprivileged) | AxCACHE[3:0] (Cacheability) | Notes |
|-----------|-------------|------------------|------------------------------|-------------------------------|-------------------------------------|----------------------------|--------|
| M0 | Secure CPU Core | Secure OS Kernel | Data (0) | Secure (0) | Privileged (0) | 0b1111 (WB-RA-WA) | Simulates the highest-privilege processor in the system, requiring access to all secure resources. |
| M1 | Non-Secure CPU Core | Non-secure Application Processor | Data (0) | Non-secure (1) | Unprivileged (1) | 0b1111 (WB-RA-WA) | Simulates a processor running general applications like Linux/Android. |
| M2 | Instruction Fetch Unit | CPU Instruction Fetch Unit | Instruction (1) | Secure (0) | Privileged (0) | 0b0110 (R-A) | Specialized for fetching instructions from memory to test Instruction-Only regions. |
| M3 | GPU (High-Performance) | Graphics Processing Unit | Data (0) | Non-secure (1) | Unprivileged (1) | 0b1111 (WB-RA-WA) | A high-performance, cacheable master used to test shared buffers. |
| M4 | AI Accelerator | AI Accelerator | Data (0) | Non-secure (1) | Privileged (0) | 0b0011 (Bufferable) | Another high-performance master, but with different cache attributes. |
| M5 | DMA (Secure) | Secure Direct Memory Access | Data (0) | Secure (0) | Privileged (0) | 0b0010 (Cacheable) | Used for transferring data between secure regions. |
| M6 | DMA (Non-Secure) | Non-secure Direct Memory Access | Data (0) | Non-secure (1) | Privileged (0) | 0b0010 (Cacheable) | Used for transferring data between non-secure regions and peripherals. |
| M7 | Malicious Master | Malicious/Misconfigured Master | Data (0) | Non-secure (1) | Unprivileged (1) | 0b0000 (Device Non-Bufferable) | Specifically designed to trigger various security and permission errors. |
| M8 | Read-Only Peripheral | Read-Only Peripheral (e.g., Sensor) | Data (0) | Non-secure (1) | Unprivileged (1) | 0b0001 (Device Bufferable) | Simulates a simple peripheral that only issues read requests. |
| M9 | Legacy Master | Legacy/Non-Cacheable Master | Data (0) | Non-secure (1) | Privileged (0) | 0b0000 (Device Non-Bufferable) | Used to test the slave's response to non-cacheable accesses. |

## 3. Master-Slave Access Test Matrix

This matrix defines the access test cases and expected outcomes for each master accessing each slave region.

### Slave Region Definitions and Address Mapping

| Slave ID | Slave Name | Start Address | End Address | Size | Access Type | Description |
|----------|------------|---------------|-------------|------|-------------|-------------|
| **S0** | DDR Secure Kernel | 0x0000_0008_0000_0000 | 0x0000_0008_3FFF_FFFF | 1GB | Secure R/W | Secure OS kernel space, protected memory region |
| **S1** | DDR Non-Secure User | 0x0000_0008_4000_0000 | 0x0000_0008_7FFF_FFFF | 1GB | Non-Secure R/W | Non-secure user application space |
| **S2** | DDR Shared Buffer | 0x0000_0008_8000_0000 | 0x0000_0008_BFFF_FFFF | 1GB | Shared R/W | Shared memory for inter-processor communication |
| **S3** | Illegal Address Hole | 0x0000_0008_C000_0000 | 0x0000_0008_FFFF_FFFF | 1GB | None | Address decode hole, all accesses return DECERR |
| **S4** | XOM Instruction-Only | 0x0000_0009_0000_0000 | 0x0000_0009_3FFF_FFFF | 1GB | Execute-Only | eXecute-Only Memory for secure code storage |
| **S5** | RO Peripheral | 0x0000_000A_0000_0000 | 0x0000_000A_0000_FFFF | 64KB | Read-Only | Read-only status registers and sensors |
| **S6** | Privileged-Only | 0x0000_000A_0001_0000 | 0x0000_000A_0001_FFFF | 64KB | Privileged R/W | System control registers, privileged access only |
| **S7** | Secure-Only | 0x0000_000A_0002_0000 | 0x0000_000A_0002_FFFF | 64KB | Secure R/W | Security controller registers |
| **S8** | Scratchpad | 0x0000_000A_0003_0000 | 0x0000_000A_0003_FFFF | 64KB | Shared R/W | Fast on-chip SRAM for temporary data |
| **S9** | Attribute Monitor | 0x0000_000A_0004_0000 | 0x0000_000A_0004_FFFF | 64KB | Write-Only | Transaction attribute monitoring registers |

### Address Region Notes
- All addresses are 64-bit aligned
- DDR regions (S0-S3) are mapped to external DRAM controller with 1GB per region
- Peripheral regions (S5-S9) are mapped to on-chip APB bridge at the 40-bit address space
- The XOM region (S4) supports only instruction fetches (AxPROT[2]=1)
- Address hole (S3) is intentionally unmapped for error testing
- 4KB page boundaries within each region should be tested for burst transactions
- The upper 32 bits are significant for system-level address routing

### Access Matrix

| Master | S0: DDR Secure Kernel | S1: DDR Non-Secure User | S2: DDR Shared Buffer | S3: Illegal Address Hole | S4: XOM Instruction-Only | S5: RO Peripheral | S6: Privileged-Only | S7: Secure-Only | S8: Scratchpad | S9: Attribute Monitor |
|--------|----------------------|------------------------|----------------------|------------------------|-------------------------|------------------|-------------------|----------------|---------------|---------------------|
| **M0 (Secure CPU)** | R/W: OKAY<br>PROT=000 | R/W: OKAY<br>PROT=000 | R/W: OKAY<br>PROT=000, CACHE=1111 | R/W: DECERR | R: OKAY PROT[2]=1<br>W: SLVERR | R: OKAY<br>W: SLVERR | R/W: OKAY<br>PROT=000 | R/W: OKAY<br>PROT=000 | R/W: OKAY | W: OKAY<br>R: SLVERR |
| **M1 (NS CPU)** | R/W: DECERR<br>PROT=111 | R/W: OKAY<br>PROT=111 | R/W: OKAY<br>PROT=111, CACHE=1111 | R/W: DECERR | R: DECERR (Secure mismatch) | R: OKAY<br>W: SLVERR | R/W: SLVERR<br>PROT[0]=1 | R/W: SLVERR<br>PROT[1]=1 | R/W: OKAY | W: OKAY<br>R: SLVERR |
| **M2 (I-Fetch)** | R: OKAY<br>PROT=000, PROT[2]=1 | R: OKAY<br>PROT=000, PROT[2]=1 | R: OKAY<br>PROT=000, PROT[2]=1 | R: DECERR | R: OKAY<br>PROT[2]=1<br>W: SLVERR | R: OKAY | R: OKAY | R: OKAY | R: OKAY | R: SLVERR |
| **M3 (GPU)** | R/W: DECERR<br>PROT=111 | R/W: OKAY<br>PROT=111 | R/W: OKAY<br>CACHE > 0<br>Test: CACHE=0 (Perf issue) | R/W: DECERR | R/W: SLVERR<br>PROT[2]=0 | R: OKAY<br>W: SLVERR | R/W: SLVERR<br>PROT[0]=1 | R/W: SLVERR<br>PROT[1]=1 | R/W: OKAY | W: OKAY<br>R: SLVERR |
| **M4 (AI Accel)** | R/W: DECERR<br>PROT=110 | R/W: OKAY<br>PROT=110 | R/W: OKAY<br>CACHE > 0 | R/W: DECERR | R/W: SLVERR<br>PROT[2]=0 | R: OKAY<br>W: SLVERR | R/W: OKAY<br>PROT[0]=0 | R/W: SLVERR<br>PROT[1]=1 | R/W: OKAY | W: OKAY<br>R: SLVERR |
| **M5 (DMA-S)** | R/W: OKAY<br>PROT=000 | R/W: OKAY<br>PROT=000 | R/W: OKAY<br>PROT=000 | R/W: DECERR | R/W: SLVERR<br>PROT[2]=0 | R: OKAY<br>W: SLVERR | R/W: OKAY<br>PROT=000 | R/W: OKAY<br>PROT=000 | R/W: OKAY | W: OKAY<br>R: SLVERR |
| **M6 (DMA-NS)** | R/W: DECERR<br>PROT=110 | R/W: OKAY<br>PROT=110 | R/W: OKAY<br>PROT=110 | R/W: DECERR | R/W: SLVERR<br>PROT[2]=0 | R: OKAY<br>W: SLVERR | R/W: OKAY<br>PROT[0]=0 | R/W: SLVERR<br>PROT[1]=1 | R/W: OKAY | W: OKAY<br>R: SLVERR |
| **M7 (Malicious)** | R/W: DECERR<br>PROT=111 | W: OKAY<br>R: OKAY | R/W: OKAY | R/W: DECERR | R: SLVERR PROT[2]=0<br>W: SLVERR | W: SLVERR | R/W: SLVERR<br>PROT[0]=1 | R/W: SLVERR<br>PROT[1]=1 | R/W: OKAY | W: OKAY<br>R: SLVERR |
| **M8 (RO Peri.)** | R: DECERR<br>PROT=111 | R: OKAY | R: OKAY | R: DECERR | R: SLVERR<br>PROT[2]=0 | R: OKAY<br>W: SLVERR | R: SLVERR<br>PROT[0]=1 | R: SLVERR<br>PROT[1]=1 | R: OKAY | R: SLVERR |
| **M9 (Legacy)** | R/W: DECERR<br>PROT=110 | R/W: OKAY<br>PROT=110 | R/W: OKAY<br>CACHE=0000 | R/W: DECERR | R/W: SLVERR<br>PROT[2]=0 | R: OKAY<br>W: SLVERR | R/W: OKAY<br>PROT[0]=0 | R/W: SLVERR<br>PROT[1]=1 | R/W: OKAY | W: OKAY<br>R: SLVERR |

### Legend:
- **R/W**: Represents Read and Write tests
- **OKAY**: The AXI transaction is expected to succeed, with BRESP or RRESP returning 2'b00
- **DECERR**: The AXI Interconnect or Slave is expected to return 2'b11, typically indicating an address decode error or a security permission violation
- **SLVERR**: The Slave is expected to return 2'b10, typically indicating an internal slave error (e.g., writing to a read-only region, unsupported access type)
- **PROT / CACHE**: The AxPROT and AxCACHE signal values to be used for the access

## 4. Verification Platform Architecture and Rules

### 4.1 Reference Model Support
To ensure verification flexibility and scalability, the verification platform must support the following three configurable reference bus architectures:

- **base bus matrix**: A basic, functionally simplified bus model for early-stage verification
- **bus enhanced matrix**: The complete 10x10 enhanced bus model, which is the primary target of this verification effort
- **none**: No reference model is used, allowing for direct driving and response analysis of the DUT (Design Under Test)

### 4.2 Error Handling and Scoreboarding Rules
To accurately simulate real-world error handling, the platform must adhere to the following core rule:

**Error and Abandon**: For any AXI transaction, if its response channel (BRESP or RRESP) receives a DECERR (Decode Error) or SLVERR (Slave Error), the Scoreboard must immediately treat the transaction as a completed failure. The platform must abandon any subsequent checks for that transaction (such as the read data channel), as the data is considered invalid after an error has occurred.

### 4.3 SystemVerilog Verification Configuration
To ensure that the AxPROT and AxCACHE attributes are correctly checked throughout the system, the following configuration flags must be enabled in all test cases:

- **axprot_chk_cfg**: Enabled. Activates monitors to verify that AxPROT signals are propagated and handled correctly
- **axcache_chk_cfg**: Enabled. Activates monitors to verify that AxCACHE signals are propagated and handled correctly
- **addr_width_cfg**: Set to 64. Configures all masters and slaves to use 64-bit addressing
- **data_width_cfg**: Set to 128/256/512 as per system requirements (typical: 128-bit for DDR, 32-bit for APB peripherals)

## 5. High-Coverage Comprehensive Test Cases

The following five test cases are designed to exhaustively test the 10x10 bus matrix by merging multiple legal and illegal scenarios.

### Test Case 1: Concurrent Read Operations (ARPROT & ARCACHE Focus)

**Objective**: To verify the correct handling of various ARPROT permissions and ARCACHE attributes during concurrent read operations.

**Concurrent Sequences**:

1. **M2 (I-Fetch) → S4 (XOM)**: Legal instruction read
   - ARPROT: 3'b100 (Privileged, Secure, Instruction)
   - Expected Response: OKAY

2. **M7 (Malicious) → S4 (XOM)**: Illegal data read
   - ARPROT: 3'b011 (Unprivileged, Non-secure, Data)
   - Expected Response: SLVERR (Slave rejects non-instruction read)

3. **M1 (NS CPU) → S0 (DDR Secure Kernel)**: Illegal non-secure read
   - ARPROT: 3'b111 (Unprivileged, Non-secure, Data)
   - Expected Response: DECERR (Interconnect rejects this transaction)

4. **M0 (Secure CPU) → S2 (DDR Shared Buffer)**: Legal cacheable read
   - ARCACHE: 4'b1111 (WB-RA-WA)
   - Expected Response: OKAY

5. **M8 (RO Peri.) → S6 (Privileged-Only)**: Illegal unprivileged read
   - ARPROT: 3'b111 (Unprivileged)
   - Expected Response: SLVERR (Slave rejects unprivileged access)

### Test Case 2: Concurrent Write Operations and Read-After-Write Verification (AWPROT & AWCACHE Focus)

**Objective**: To verify the handling of write permissions, illegal addresses, and cache attributes, and to confirm the state via read-after-write.

**Concurrent Sequences**:

1. **M0 (Secure CPU) → S0 (DDR Secure Kernel)**: Legal secure & privileged write
   - AWPROT: 3'b000
   - Expected Response: OKAY

2. **M3 (GPU) → S5 (RO Peripheral)**: Illegal write to read-only region
   - AWPROT: 3'b111
   - Expected Response: SLVERR

3. **M6 (DMA-NS) → S3 (Illegal Address Hole)**: Illegal write to address hole
   - AWPROT: 3'b110
   - Expected Response: DECERR

4. **M9 (Legacy) → S9 (Attribute Monitor)**: Legal write to monitor region
   - AWPROT: 3'b110
   - Expected Response: OKAY (Scoreboard should verify this transaction)

**Read After Write Verification**:

- **M0 → S0 (DDR Secure Kernel)**: After a successful write, M0 performs a legal read from the same address to verify data integrity
  - Expected Response: OKAY

- **M9 → S9 (Attribute Monitor)**: After a successful write, M9 performs an illegal read from the same address
  - Expected Response: SLVERR (Verifies the slave rejects all reads)

### Test Case 3: Sequential Mixed Read/Write Operations

**Objective**: To verify complex operational sequences involving multiple steps, particularly targeting shared resources and security policies.

**Sequential Operations**:

1. **Sequence 1**: M4 (AI Accel) → S8 (Scratchpad): Write to a shared register
   - Expected Response: OKAY

2. **Sequence 2**: M6 (DMA-NS) → S8 (Scratchpad): Read the data written by M4 to verify shared access
   - Expected Response: OKAY

3. **Sequence 3**: M7 (Malicious) → S7 (Secure-Only): Attempt to write to a secure-only region
   - AWPROT: 3'b111 (Non-secure)
   - Expected Response: SLVERR

4. **Sequence 4**: M2 (I-Fetch) → S0 (Secure Kernel): Perform an instruction read
   - ARPROT: 3'b100 (Instruction)
   - Expected Response: OKAY (Verifies that the secure region allows privileged instruction reads)

### Test Case 4: Concurrent Error Condition Stress Test and Read-After-Write Verification

**Objective**: To stress test the error handling capabilities of the Interconnect and all Slaves and to verify the persistence of error states.

**Concurrent Sequences**:

1. **M1 (NS CPU) → S7 (Secure-Only)**: Illegal non-secure write
   - AWPROT: 3'b111
   - Expected Response: SLVERR

2. **M3 (GPU) → S6 (Privileged-Only)**: Illegal unprivileged write
   - AWPROT: 3'b111
   - Expected Response: SLVERR

3. **M7 (Malicious) → S0 (Secure Kernel)**: Illegal security & privilege write
   - AWPROT: 3'b111
   - Expected Response: DECERR

4. **M8 (RO Peri.) → S9 (Attribute Monitor)**: Illegal read
   - Expected Response: SLVERR

**Read After Write Verification**:

- **M7 → S0 (Secure Kernel)**: After the failed write, M7 attempts another illegal read from the same address
  - Expected Response: DECERR (Verifies the Interconnect's protection remains active)

- **M1 → S7 (Secure-Only)**: After the failed write, M1 attempts another illegal read from the same address
  - Expected Response: SLVERR (Verifies the Slave's protection remains active)

### Test Case 5: Exhaustive Randomized Read & Boundary Verification

**Objective**: To exhaustively verify every read path in the 10x10 Master-Slave matrix and to check for 4K address boundary crossings.

**Execution Method**:

1. **Randomized Reads**: For each of the 100 Master-Slave pairings, the test sequence will generate at least 2000 random read transactions
   - Address Range: The address for each transaction will be randomized within the target slave's valid address space as defined in the Address Mapping table
   - For example:
     - When testing M0→S0, randomize addresses within 0x0000_0008_0000_0000 to 0x0000_0008_3FFF_FFFF
     - When testing M3→S2, randomize addresses within 0x0000_0008_8000_0000 to 0x0000_0008_BFFF_FFFF
     - When testing M2→S4, randomize addresses within 0x0000_0009_0000_0000 to 0x0000_0009_3FFF_FFFF
   - Attribute Settings: The ARPROT and ARCACHE for each transaction should use the typical settings for the initiating master

2. **Boundary Condition Verification**:
   - During transaction generation, the verification platform's sequence generator must monitor the start address and length of each transaction
   - If the address range of an AXI burst transaction crosses any 4KB boundary (i.e., `start_addr / 4096 != end_addr / 4096`), the platform must issue a UVM_WARNING
   - This warning is intended to alert designers to potential unexpected behavior, even though such operations are permitted by the AXI specification
   - Example boundary check code:
     ```systemverilog
     // Check for 4K boundary crossing
     bit [63:0] end_addr = trans.addr + (trans.len + 1) * (1 << trans.size) - 1;
     if ((trans.addr >> 12) != (end_addr >> 12)) begin
       `uvm_warning("BOUNDARY", $sformatf("Transaction crosses 4K boundary: start=0x%016x, end=0x%016x", 
                    trans.addr, end_addr))
     end
     ```

**Expected Results**:

The expected response (OKAY, DECERR, SLVERR) for each transaction must match the previously defined "Master-Slave Access Test Matrix". The scoreboard will verify that the responses for all 100×2000 transactions are correct based on this matrix. For example:

- M0 (Secure CPU) → S0 (Secure Kernel): All ~2000 random reads should receive an OKAY response
- M1 (NS CPU) → S0 (Secure Kernel): All ~2000 random reads should receive a DECERR response
- M2 (I-Fetch) → S4 (XOM): All ~2000 random reads should receive an OKAY response
- M7 (Malicious) → S4 (XOM): All ~2000 random reads should receive a SLVERR response
- The tests for the remaining 96 pairings will follow this pattern

## 6. Verification Strategy Recommendations

### 6.1 Sequential Testing
Enable each master one by one and execute all corresponding test cases from the matrix.

### 6.2 Concurrent Testing
Enable multiple masters simultaneously (e.g., M0, M1, M3) to access different slave regions to test the interconnect's arbitration and stress handling. Specifically, have multiple masters access S2 (Shared Buffer) and S8 (Scratchpad) at the same time.

### 6.3 Boundary Condition Testing
Test accesses at the address boundaries (start and end addresses) for each region.

### 6.4 Randomized Testing
Randomize AxPROT and AxCACHE within their legal ranges and have masters randomly access their permitted address spaces to discover unexpected bugs.

### 6.5 Performance Monitoring
When performing high-load tests on S2 (Shared Buffer), monitor its throughput and latency to ensure it meets design specifications.

## 7. Implementation Notes for Claude Code

When implementing this verification plan with Claude Code, consider the following:

1. **Testbench Architecture**:
   - Create a modular testbench with configurable master and slave agents
   - Implement a central scoreboard that tracks all transactions and verifies responses against the access matrix
   - Use SystemVerilog UVM methodology for maximum reusability and coverage
   - Implement proper address decoding logic based on the defined address regions

2. **Address Decoding Implementation**:
   - Create an address decoder module that maps transactions to the correct slave based on the address mapping table
   - Support full 64-bit address decoding with configurable address width (ADDR_WIDTH parameter)
   - Implement address boundary checking to ensure transactions don't cross slave boundaries
   - Generate DECERR responses for accesses to undefined address regions or S3 (Illegal Address Hole)
   - Consider implementing configurable address maps for different test scenarios
   - Example address decoder structure:
     ```systemverilog
     function automatic slave_id_t decode_address(bit [63:0] addr);
       case (addr[39:32])  // Check upper address bits
         8'h08: begin
           case (addr[31:30])
             2'b00: return S0_SECURE_KERNEL;
             2'b01: return S1_NONSECURE_USER;
             2'b10: return S2_SHARED_BUFFER;
             2'b11: return S3_ILLEGAL_HOLE;
           endcase
         end
         8'h09: return S4_XOM;
         8'h0A: begin
           case (addr[19:16])
             4'h0: return S5_RO_PERIPHERAL;
             4'h1: return S6_PRIVILEGED_ONLY;
             // ... etc
           endcase
         end
         default: return DECODE_ERROR;
       endcase
     endfunction
     ```

3. **Coverage Collection**:
   - Implement functional coverage for all master-slave combinations
   - Track coverage for different AxPROT and AxCACHE combinations
   - Monitor error response coverage (OKAY, DECERR, SLVERR)
   - Add address range coverage to ensure all regions are adequately tested

4. **Assertion Development**:
   - Create assertions for protocol compliance
   - Verify that error responses are properly propagated
   - Check for proper handling of concurrent transactions
   - Assert that addresses are correctly decoded to the appropriate slave

5. **Debug Features**:
   - Implement transaction-level logging with filtering capabilities
   - Create waveform markers for easy debug
   - Generate automated reports showing pass/fail status for each test case
   - Add address mapping visualization for debug purposes

6. **Example Test Sequence Code Structure**:
   ```systemverilog
   // Example: Testing M0 (Secure CPU) access to S0 (DDR Secure Kernel)
   class test_m0_to_s0_seq extends uvm_sequence;
     `uvm_object_utils(test_m0_to_s0_seq)
     
     // S0 address range constants (64-bit)
     localparam bit [63:0] S0_START_ADDR = 64'h0000_0008_0000_0000;
     localparam bit [63:0] S0_END_ADDR   = 64'h0000_0008_3FFF_FFFF;
     
     virtual task body();
       axi_transaction trans;
       
       // Generate 2000 random transactions
       repeat(2000) begin
         trans = axi_transaction::type_id::create("trans");
         
         // Randomize within S0 address range
         assert(trans.randomize() with {
           addr inside {[S0_START_ADDR:S0_END_ADDR]};
           prot == 3'b000;  // Secure, Privileged, Data
           cache == 4'b1111; // WB-RA-WA
         });
         
         start_item(trans);
         finish_item(trans);
         
         // Check expected response
         assert(trans.resp == OKAY) else
           `uvm_error("TEST", "Expected OKAY response for M0->S0 access")
       end
     endtask
   endclass
   ```

This complete matrix provides a clear blueprint to help your verification team systematically cover all functional points, significantly improving verification completeness and chip quality.
