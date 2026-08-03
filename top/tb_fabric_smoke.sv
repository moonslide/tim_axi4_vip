//----------------------------------------------------------------------------
// tb_fabric_smoke -- directed smoke test for the commercial fabric IP + the
// generated axi4_fabric_ip_wrapper.
//
// Purpose: prove the wrapper wiring actually carries a transaction end to end,
// with fail-then-pass evidence from the fabric's own address decoder:
//
//   CASE 1 (expect DECERR): write to 0x0000_0000_0000_0000, which is OUTSIDE
//           the fabric memory map -> decoded to the default slave.
//   CASE 2 (expect OKAY)  : write to 0x0000_0008_0000_0000, the base of S0
//           in the VIP memory map -> must reach egress port 0, where a trivial
//           always-ready slave responder answers OKAY.
//
// If the wiring were wrong (e.g. ingress/egress swapped, ID/valid mis-mapped)
// neither case could produce the expected distinct responses.
//----------------------------------------------------------------------------
`timescale 1ps/1ps

module tb_fabric_smoke;

  localparam int NUM = 10;

  logic clk = 0, resetn = 0;
  always #500 clk = ~clk;              // 1ns period

  // ---- ingress (we drive, as if we were VIP master 0) ----------------------
  logic [NUM-1:0][3:0]   m_awid, m_arid, m_awregion, m_arregion, m_awcache, m_arcache, m_awqos, m_arqos;
  logic [NUM-1:0][63:0]  m_awaddr, m_araddr;
  logic [NUM-1:0][7:0]   m_awlen, m_arlen;
  logic [NUM-1:0][2:0]   m_awsize, m_arsize, m_awprot, m_arprot;
  logic [NUM-1:0][1:0]   m_awburst, m_arburst;
  logic [NUM-1:0]        m_awlock, m_arlock, m_awvalid, m_arvalid, m_wlast, m_wvalid, m_bready, m_rready;
  logic [NUM-1:0][255:0] m_wdata;
  logic [NUM-1:0][31:0]  m_wstrb, m_awuser, m_aruser, m_wuser;
  logic [NUM-1:0]        m_awready, m_wready, m_bvalid, m_arready, m_rvalid, m_rlast;
  logic [NUM-1:0][3:0]   m_bid, m_rid;
  logic [NUM-1:0][1:0]   m_bresp, m_rresp;
  logic [NUM-1:0][255:0] m_rdata;
  logic [NUM-1:0][15:0]  m_buser, m_ruser;

  // ---- egress (fabric drives; we act as the 10 VIP slaves) -----------------
  logic [NUM-1:0][7:0]   s_awid, s_arid;
  logic [NUM-1:0][63:0]  s_awaddr, s_araddr;
  logic [NUM-1:0][7:0]   s_awlen, s_arlen;
  logic [NUM-1:0][2:0]   s_awsize, s_arsize, s_awprot, s_arprot;
  logic [NUM-1:0][1:0]   s_awburst, s_arburst;
  logic [NUM-1:0][3:0]   s_awcache, s_arcache, s_awregion, s_arregion;
  logic [NUM-1:0]        s_awlock, s_arlock, s_awvalid, s_arvalid, s_wlast, s_wvalid, s_bready, s_rready;
  logic [NUM-1:0][255:0] s_wdata;
  logic [NUM-1:0][31:0]  s_wstrb, s_awuser, s_aruser, s_wuser;
  logic [NUM-1:0]        s_awready, s_wready, s_bvalid, s_arready, s_rvalid, s_rlast;
  logic [NUM-1:0][7:0]   s_bid, s_rid;
  logic [NUM-1:0][1:0]   s_bresp, s_rresp;
  logic [NUM-1:0][255:0] s_rdata;
  logic [NUM-1:0][15:0]  s_buser, s_ruser;

  axi4_fabric_ip_wrapper #(.NUM(NUM)) dut (
    .clk(clk), .resetn(resetn),
    .m_awid(m_awid), .m_awaddr(m_awaddr), .m_awlen(m_awlen), .m_awsize(m_awsize),
    .m_awburst(m_awburst), .m_awlock(m_awlock), .m_awcache(m_awcache), .m_awprot(m_awprot),
    .m_awvalid(m_awvalid), .m_awregion(m_awregion), .m_awready(m_awready),
    .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast), .m_wvalid(m_wvalid), .m_wready(m_wready),
    .m_bid(m_bid), .m_bresp(m_bresp), .m_bvalid(m_bvalid), .m_bready(m_bready),
    .m_arid(m_arid), .m_araddr(m_araddr), .m_arlen(m_arlen), .m_arsize(m_arsize),
    .m_arburst(m_arburst), .m_arlock(m_arlock), .m_arcache(m_arcache), .m_arprot(m_arprot),
    .m_arvalid(m_arvalid), .m_arregion(m_arregion), .m_arready(m_arready),
    .m_rid(m_rid), .m_rdata(m_rdata), .m_rresp(m_rresp), .m_rlast(m_rlast),
    .m_rvalid(m_rvalid), .m_rready(m_rready),
    .m_awuser(m_awuser), .m_wuser(m_wuser), .m_buser(m_buser), .m_aruser(m_aruser), .m_ruser(m_ruser),
    .m_awqos(m_awqos), .m_arqos(m_arqos),
    .s_awid(s_awid), .s_awaddr(s_awaddr), .s_awlen(s_awlen), .s_awsize(s_awsize),
    .s_awburst(s_awburst), .s_awlock(s_awlock), .s_awcache(s_awcache), .s_awprot(s_awprot),
    .s_awvalid(s_awvalid), .s_awregion(s_awregion), .s_awready(s_awready),
    .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wlast(s_wlast), .s_wvalid(s_wvalid), .s_wready(s_wready),
    .s_bid(s_bid), .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
    .s_arid(s_arid), .s_araddr(s_araddr), .s_arlen(s_arlen), .s_arsize(s_arsize),
    .s_arburst(s_arburst), .s_arlock(s_arlock), .s_arcache(s_arcache), .s_arprot(s_arprot),
    .s_arvalid(s_arvalid), .s_arregion(s_arregion), .s_arready(s_arready),
    .s_rid(s_rid), .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rlast(s_rlast),
    .s_rvalid(s_rvalid), .s_rready(s_rready),
    .s_awuser(s_awuser), .s_wuser(s_wuser), .s_buser(s_buser), .s_aruser(s_aruser), .s_ruser(s_ruser)
  );

  // ---- trivial always-ready OKAY slave on every egress port ----------------
  genvar g;
  generate
    for (g = 0; g < NUM; g++) begin : slv
      assign s_awready[g] = 1'b1;
      assign s_wready[g]  = 1'b1;
      assign s_arready[g] = 1'b1;
      assign s_buser[g]   = '0;
      assign s_ruser[g]   = '0;
      assign s_rdata[g]   = 256'hCAFE;
      assign s_rresp[g]   = 2'b00;
      assign s_rlast[g]   = 1'b1;

      // Latch AWID at the AW handshake -- it is NOT still valid at WLAST time,
      // and the fabric needs the exact ID back to route B to the right ASIB.
      logic [7:0] awid_q;
      always_ff @(posedge clk or negedge resetn) begin
        if (!resetn)                              awid_q <= '0;
        else if (s_awvalid[g] && s_awready[g])    awid_q <= s_awid[g];
      end

      // B response one cycle after WLAST accepted, held until BREADY
      always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
          s_bvalid[g] <= 1'b0; s_bid[g] <= '0; s_bresp[g] <= 2'b00;
        end else if (s_bvalid[g]) begin
          if (s_bready[g]) s_bvalid[g] <= 1'b0;
        end else if (s_wvalid[g] && s_wready[g] && s_wlast[g]) begin
          s_bvalid[g] <= 1'b1; s_bid[g] <= awid_q; s_bresp[g] <= 2'b00;
        end
      end
      // Same rule as the write side: capture ARID at the AR handshake and hold
      // RVALID until RREADY, otherwise the fabric cannot route R back.
      always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
          s_rvalid[g] <= 1'b0; s_rid[g] <= '0;
        end else if (s_rvalid[g]) begin
          if (s_rready[g]) s_rvalid[g] <= 1'b0;
        end else if (s_arvalid[g] && s_arready[g]) begin
          s_rvalid[g] <= 1'b1; s_rid[g] <= s_arid[g];
        end
      end
    end
  endgenerate


  // ---- probes: did the transaction reach an egress port? ----
  always @(posedge clk) begin
    for (int p = 0; p < NUM; p++) begin
      if (s_awvalid[p]) $display("  [probe] t=%0t egress[%0d] AWVALID addr=0x%016h awid=0x%02h", $time, p, s_awaddr[p], s_awid[p]);
      if (s_wvalid[p])  $display("  [probe] t=%0t egress[%0d] WVALID wlast=%0b", $time, p, s_wlast[p]);
      if (s_bvalid[p] && s_bready[p]) $display("  [probe] t=%0t egress[%0d] B accepted", $time, p);
    end
  end

  int errors = 0;

  task automatic do_write(input logic [63:0] addr, input string label,
                          input logic [1:0] exp_resp);
    int unsigned timeout;
    begin
      @(posedge clk);
      m_awid[0]<=4'h5; m_awaddr[0]<=addr; m_awlen[0]<='0; m_awsize[0]<=3'd5;
      m_awburst[0]<=2'b01; m_awlock[0]<=1'b0; m_awcache[0]<=4'h0; m_awprot[0]<=3'b000;
      m_awregion[0]<=4'h0; m_awqos[0]<=4'h0; m_awuser[0]<='0; m_awvalid[0]<=1'b1;
      @(posedge clk);
      while (!m_awready[0]) @(posedge clk);
      m_awvalid[0]<=1'b0;

      m_wdata[0]<=256'hA5A5; m_wstrb[0]<='1; m_wlast[0]<=1'b1; m_wuser[0]<='0; m_wvalid[0]<=1'b1;
      @(posedge clk);
      while (!m_wready[0]) @(posedge clk);
      m_wvalid[0]<=1'b0; m_wlast[0]<=1'b0;

      m_bready[0]<=1'b1;
      timeout = 0;
      while (!m_bvalid[0] && timeout < 2000) begin @(posedge clk); timeout++; end
      if (!m_bvalid[0]) begin
        $display("[FAIL] %s: no BVALID within 2000 cycles (addr=0x%016h)", label, addr);
        errors++;
      end else if (m_bresp[0] !== exp_resp) begin
        $display("[FAIL] %s: BRESP=0b%02b expected 0b%02b (addr=0x%016h)",
                 label, m_bresp[0], exp_resp, addr);
        errors++;
      end else begin
        $display("[PASS] %s: BRESP=0b%02b BID=0x%01h (addr=0x%016h)",
                 label, m_bresp[0], m_bid[0], addr);
      end
      @(posedge clk); m_bready[0]<=1'b0;
    end
  endtask

  task automatic do_read(input logic [63:0] addr, input string label,
                         input logic [1:0] exp_resp);
    int unsigned timeout;
    begin
      @(posedge clk);
      m_arid[0]<=4'h7; m_araddr[0]<=addr; m_arlen[0]<='0; m_arsize[0]<=3'd5;
      m_arburst[0]<=2'b01; m_arlock[0]<=1'b0; m_arcache[0]<=4'h0; m_arprot[0]<=3'b000;
      m_arregion[0]<=4'h0; m_arqos[0]<=4'h0; m_aruser[0]<='0; m_arvalid[0]<=1'b1;
      @(posedge clk);
      while (!m_arready[0]) @(posedge clk);
      m_arvalid[0]<=1'b0;

      m_rready[0]<=1'b1;
      timeout = 0;
      while (!m_rvalid[0] && timeout < 2000) begin @(posedge clk); timeout++; end
      if (!m_rvalid[0]) begin
        $display("[FAIL] %s: no RVALID within 2000 cycles (addr=0x%016h)", label, addr);
        errors++;
      end else if (m_rresp[0] !== exp_resp) begin
        $display("[FAIL] %s: RRESP=0b%02b expected 0b%02b", label, m_rresp[0], exp_resp);
        errors++;
      end else begin
        $display("[PASS] %s: RRESP=0b%02b RID=0x%01h RLAST=%0b (addr=0x%016h)",
                 label, m_rresp[0], m_rid[0], m_rlast[0], addr);
      end
      @(posedge clk); m_rready[0]<=1'b0;
    end
  endtask

  initial begin
    m_awvalid='0; m_wvalid='0; m_arvalid='0; m_bready='0; m_rready='0; m_wlast='0;
    m_awid='0; m_arid='0; m_awaddr='0; m_araddr='0; m_awlen='0; m_arlen='0;
    m_awsize='0; m_arsize='0; m_awburst='0; m_arburst='0; m_awlock='0; m_arlock='0;
    m_awcache='0; m_arcache='0; m_awprot='0; m_arprot='0; m_awregion='0; m_arregion='0;
    m_awqos='0; m_arqos='0; m_awuser='0; m_aruser='0; m_wuser='0; m_wdata='0; m_wstrb='0;

    repeat (20) @(posedge clk);
    resetn = 1'b1;
    repeat (20) @(posedge clk);

    // CASE 1 -- unmapped address must be rejected by the fabric decoder
    do_write(64'h0000_0000_0000_0000, "CASE1 unmapped->DECERR", 2'b11);

    repeat (20) @(posedge clk);

    // CASE 2 -- S0 base address must reach egress 0 and return OKAY
    do_write(64'h0000_0008_0000_0000, "CASE2 S0 base ->OKAY  ", 2'b00);

    repeat (20) @(posedge clk);

    // CASE 3 -- read back through the fabric from the same mapped region
    do_read(64'h0000_0008_0000_0000, "CASE3 S0 base read->OKAY", 2'b00);

    repeat (20) @(posedge clk);
    if (errors == 0) begin
      $display("\n=== FABRIC SMOKE TEST PASSED (3/3) ===\n");
      $finish;
    end else begin
      $display("\n=== FABRIC SMOKE TEST FAILED (%0d error(s)) ===\n", errors);
      // codex_review.md Finding 7 fix: a functional mismatch must not leave
      // the simulator process with the same clean exit as a pass. $fatal
      // gives VCS a non-zero process exit status (defense in depth on top
      // of the explicit log-content gate added in run_fabric_smoke.sh,
      // which does not depend on this exit code alone).
      $fatal(1, "fabric smoke: %0d error(s) detected", errors);
    end
  end

  initial begin
    #50_000_000;
    $display("[FAIL] global timeout");
    // Finding 7 fix: same non-zero-exit treatment as the mismatch path
    // above -- a timeout must not look like a clean run either.
    $fatal(1, "fabric smoke: global timeout waiting for transaction completion");
  end

endmodule
