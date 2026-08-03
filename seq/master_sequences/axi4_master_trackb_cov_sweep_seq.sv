`include "axi4_bus_config.svh"
`ifndef AXI4_MASTER_TRACKB_COV_SWEEP_SEQ_INCLUDED_
`define AXI4_MASTER_TRACKB_COV_SWEEP_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_trackb_cov_sweep_seq
//
// Coverage-directed sweep for the Track-B (NIC-400 fabric) builds.
//
// The two existing Track-B sequences drive ONE write and ONE read per master with
// mostly-random attributes, which leaves nearly every attribute bin unhit: measured
// GROUP coverage 28.76% on the 10x10 fabric and 24.53% on the 4x4.
//
// This walks the AXI attribute space deliberately instead. Every value below is a
// bin the model actually declares -- see axi4_master_coverage.sv:
//   AWSIZE_CP   {0..7}   but the fabric bus is 256b, so only 0..5 are legal here
//   AWBURST_CP  {0,1,2}  FIXED / INCR / WRAP  (3 is illegal_bins)
//   AWLEN_CP    {0,1,3,7,15,31,63,127,255}
//   AWCACHE_CP  {0,1,2,3}
//   AWPROT_CP   [0:$]    all 8 encodings
//   AWLOCK_CP   {0,1}    normal / exclusive
// plus the crosses AWBURST x AWLEN x AWSIZE and ARBURST x ARLEN x ARSIZE.
//
// Constraints the fabric imposes, all enforced below:
//   * a burst must not cross a 4KB boundary          (AXI4 A3.4.1)
//   * WRAP length must be 2, 4, 8 or 16 beats        (AXI4 A3.4.1)
//   * a beat must not be wider than the data bus     (awsize <= max_size_log2)
//   * the address must be inside a region the fabric decodes, otherwise the
//     transaction is answered DECERR by the default slave and never reaches a
//     VIP slave agent at all (see axi4_master_trackb_base_seq's header).
//--------------------------------------------------------------------------------------------
class axi4_master_trackb_cov_sweep_seq extends axi4_master_trackb_base_seq;
  `uvm_object_utils(axi4_master_trackb_cov_sweep_seq)

  // One sweep step. The test walks these so each transaction is a deliberate
  // point in the attribute space rather than a random draw.
  rand int unsigned step;

  // Highest slave index this fabric decodes: 3 for the 4x4, 9 for the 10x10.
  int unsigned max_slave = 9;

  // Which master port this sweep is running on. Needed because the access matrix
  // is per (master, slave): the first version ignored it and swept every master
  // across every region, which drove writes at S4 (XOM instruction-only), S5
  // (read-only peripheral), S7 (secure-only) and S3 (the deliberate illegal
  // hole). The fabric and the bus matrix correctly answered SLVERR/DECERR --
  // measured DECERR=96, SLVERR=192, "Protocol Issues : 210" -> TEST RESULT: FAIL.
  // That was the stimulus violating the access matrix, not a DUT or VIP defect.
  int unsigned master_id = 0;

  // 0 = drive a write this step, 1 = drive a read. The first version only wrote,
  // so every AR*/R* coverpoint and the ARBURST x ARLEN x ARSIZE cross stayed at
  // zero ("Total Reads : 0").
  bit do_read = 0;

  axi4_bus_matrix_ref axi4_bus_matrix_h;

  bit [63:0] last_addr;

  extern function new(string name = "axi4_master_trackb_cov_sweep_seq");
  extern task body();
  extern function int unsigned wrap_len(int unsigned sel);
  extern function int  pick_slave(int unsigned want, bit for_write, bit [2:0] axprot);
endclass : axi4_master_trackb_cov_sweep_seq

function axi4_master_trackb_cov_sweep_seq::new(string name = "axi4_master_trackb_cov_sweep_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: wrap_len
// AXI4 permits WRAP bursts of 2, 4, 8 or 16 beats only, so a WRAP step cannot use
// the same AWLEN list as FIXED/INCR.
//--------------------------------------------------------------------------------------------
function int unsigned axi4_master_trackb_cov_sweep_seq::wrap_len(int unsigned sel);
  case (sel % 4)
    0: return 1;   // 2 beats
    1: return 3;   // 4 beats
    2: return 7;   // 8 beats
    default: return 15;  // 16 beats
  endcase
endfunction : wrap_len

//--------------------------------------------------------------------------------------------
// Function: pick_slave
// Returns the first region at or after `want` that THIS master may access in the
// requested direction, or -1 if it may access none. Walking forward from `want`
// keeps the sweep spread across regions instead of collapsing onto one.
//--------------------------------------------------------------------------------------------
function int axi4_master_trackb_cov_sweep_seq::pick_slave(int unsigned want, bit for_write, bit [2:0] axprot);
  int unsigned n = max_slave + 1;
  if (axi4_bus_matrix_h == null) return int'(want % n);
  // Ask the SAME oracle the checkers use, with the SAME (master, address, AxPROT)
  // triple, instead of re-deriving the rules here. An earlier version only looked
  // at the read_masters/write_masters masks plus read_only/instruction_only and
  // ignored AxPROT entirely; the sweep drives all 8 AxPROT encodings, so a
  // non-secure access to S0 (DDR Secure Kernel) or S7 (Secure-Only) was still
  // generated and correctly refused -- 127 "Protocol Issues", with the VIP's two
  // sides in perfect agreement. Permission is a function of three things, and the
  // stimulus has to respect all three.
  for (int k = 0; k < n; k++) begin
    int unsigned idx = (want + k) % n;
    bit [63:0]   probe_addr = region_base(idx);
    if (for_write) begin
      if (axi4_bus_matrix_h.get_write_resp(master_id, probe_addr, axprot) == WRITE_OKAY)
        return int'(idx);
    end
    else begin
      if (axi4_bus_matrix_h.get_read_resp(master_id, probe_addr, axprot) == READ_OKAY)
        return int'(idx);
    end
  end
  return -1;
endfunction : pick_slave

task axi4_master_trackb_cov_sweep_seq::body();
  bit [63:0] base;
  bit [63:0] size;
  int unsigned slv;
  int unsigned slv_want;
  int          slv_pick;
  int unsigned burst_sel;
  int unsigned size_sel;
  int unsigned len_sel;
  int unsigned cache_sel;
  int unsigned prot_sel;
  int unsigned lock_sel;
  int unsigned qos_sel;
  int unsigned len_val;
  int unsigned len_choices[9] = '{0, 1, 3, 7, 15, 31, 63, 127, 255};
  bit [63:0]   addr;
  int unsigned bytes_per_beat;
  int unsigned burst_bytes;

  super.body();

  // Decompose the step into independent attribute selectors. Co-prime-ish strides
  // mean consecutive steps move several dimensions at once, so the CROSS bins fill
  // far faster than a nested loop over one dimension at a time would manage.
  if (axi4_bus_matrix_h == null) begin
    if (!uvm_config_db #(axi4_bus_matrix_ref)::get(m_sequencer, "*", "axi4_bus_matrix_gm", axi4_bus_matrix_h))
      axi4_bus_matrix_h = null;
  end

  prot_sel  = step % 8;   // needed before pick_slave: permission depends on AxPROT
  slv_want  = step % (max_slave + 1);
  slv_pick  = pick_slave(slv_want, ~do_read, prot_sel[2:0]);
  if (slv_pick < 0) begin
    // This master may not touch any region in this direction. Nothing legal to
    // drive; skipping is correct, inventing an illegal access is not.
    `uvm_info(get_type_name(),
              $sformatf("SWEEP step=%0d master=%0d %s: no permitted region, skipped",
                        step, master_id, do_read ? "READ" : "WRITE"), UVM_HIGH)
    return;
  end
  slv = slv_pick;
  burst_sel = (step / 3) % 3;
  size_sel  = step % (max_size_log2 + 1);
  len_sel   = (step / 2) % 9;
  cache_sel = step % 4;
  lock_sel  = (step / 5) % 2;
  qos_sel   = step % 16;

  base = region_base(slv);
  size = region_size(slv);

  // AXI4 A3.4.1, enforced by axi4_master_tx::awlength_c2/c3: only INCR may exceed
  // 16 beats, and WRAP must be exactly 2/4/8/16. Picking a length without honouring
  // that made the very first FIXED step unsolvable (measured: burst=0 size=4 len=31
  // -> "Track-B sweep write randomize failed").
  case (burst_sel)
    0:       len_val = len_choices[len_sel] > 15 ? 15 : len_choices[len_sel]; // FIXED
    2:       len_val = wrap_len(len_sel);                                     // WRAP
    default: len_val = len_choices[len_sel];                                  // INCR
  endcase
  bytes_per_beat = 1 << size_sel;
  burst_bytes    = (burst_sel == 0) ? bytes_per_beat            // FIXED: one location
                                    : (len_val + 1) * bytes_per_beat;

  // Keep the burst inside 4KB and inside the region. Starting every burst on a 4KB
  // boundary makes the no-4KB-crossing rule hold for any legal len/size pair, and a
  // WRAP burst additionally needs its address aligned to the total burst size.
  if (burst_bytes > 4096) begin
    // The step asked for more than 4KB in one burst; shorten it rather than
    // emitting an illegal transaction.
    len_val     = (4096 / bytes_per_beat) - 1;
    burst_bytes = 4096;
  end
  addr = base + ((step * 64'h1000) % (size > 4096 ? size - 4096 : 4096));
  addr = addr - (addr % 4096);

  req = axi4_master_tx::type_id::create("req");
  start_item(req);

  if (do_read) begin
    if (!req.randomize() with {
          req.tx_type       == READ;
          req.transfer_type == NON_BLOCKING_READ;
          req.araddr        == addr;
          req.arlen         == len_val;
          req.arsize        == size_sel;
          req.arburst       == arburst_e'(burst_sel);
          req.arcache       == arcache_e'(cache_sel);
          req.arprot        == arprot_e'(prot_sel);
          req.arlock        == arlock_e'(lock_sel);
          req.arqos         == qos_sel;
          req.arid          inside {[0:15]};
          // Explicit manager identity for the subordinate behind the fabric.
          req.aruser        == {`AXI4_MID_TAG, master_id[3:0]};
        }) begin
      `uvm_fatal(get_type_name(),
                 $sformatf("Track-B sweep read randomize failed: slv=%0d burst=%0d size=%0d len=%0d addr=0x%0h",
                           slv, burst_sel, size_sel, len_val, addr))
    end
    last_addr = req.araddr;
    `uvm_info(get_type_name(),
              $sformatf("SWEEP step=%0d m%0d READ S%0d addr=0x%016h burst=%0d size=%0d len=%0d",
                        step, master_id, slv, req.araddr, burst_sel, size_sel, len_val), UVM_HIGH)
    finish_item(req);
    return;
  end

  if (!req.randomize() with {
        req.tx_type       == WRITE;
        req.transfer_type == NON_BLOCKING_WRITE;
        req.awaddr        == addr;
        req.awlen         == len_val;
        req.awsize        == size_sel;
        req.awburst       == awburst_e'(burst_sel);
        req.awcache       == awcache_e'(cache_sel);
        req.awprot        == awprot_e'(prot_sel);
        req.awlock        == awlock_e'(lock_sel);
        req.awqos         == qos_sel;
        req.awid          inside {[0:15]};
        req.awuser        == {`AXI4_MID_TAG, master_id[3:0]};
      }) begin
    `uvm_fatal(get_type_name(),
               $sformatf("Track-B sweep write randomize failed: slv=%0d burst=%0d size=%0d len=%0d addr=0x%0h",
                         slv, burst_sel, size_sel, len_val, addr))
  end
  last_addr = req.awaddr;
  `uvm_info(get_type_name(),
            $sformatf("SWEEP step=%0d S%0d addr=0x%016h burst=%0d size=%0d len=%0d cache=%0d prot=%0d lock=%0d qos=%0d",
                      step, slv, req.awaddr, burst_sel, size_sel, len_val, cache_sel, prot_sel, lock_sel, qos_sel),
            UVM_HIGH)
  finish_item(req);

endtask : body

`endif
