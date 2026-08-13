`ifndef AXI4_MASTER_TRACKB_4K_CROSS_READ_SEQ_INCLUDED_
`define AXI4_MASTER_TRACKB_4K_CROSS_READ_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_trackb_4k_cross_read_seq
//
// Read-side counterpart of axi4_master_trackb_4k_cross_seq.  It is a separate
// sequence because a read item must be started on the READ sequencer: a read
// pushed onto the write sequencer is handed to the write driver and never
// appears on the AR channel.
//
// The read leg matters more than the write leg here.  A crossing WRITE can
// only report back through BRESP, but a crossing READ has to return data
// beats, so it is the leg that exposes a fabric which accepts the request and
// then fails to return R beats -- exactly the failure mode observed against
// the 1:1 wiring ("timeout waiting for a read burst with rid=...").
//--------------------------------------------------------------------------------------------
class axi4_master_trackb_4k_cross_read_seq extends axi4_master_trackb_base_seq;
  `uvm_object_utils(axi4_master_trackb_4k_cross_read_seq)

  // Address to read.  Set by the test to the write leg's last_addr so the two
  // legs straddle the same boundary.
  bit [63:0] read_addr;
  int unsigned page_index = 1;

  extern function new(string name = "axi4_master_trackb_4k_cross_read_seq");
  extern task body();
endclass : axi4_master_trackb_4k_cross_read_seq

function axi4_master_trackb_4k_cross_read_seq::new(string name = "axi4_master_trackb_4k_cross_read_seq");
  super.new(name);
endfunction : new

task axi4_master_trackb_4k_cross_read_seq::body();
  bit [63:0] base;
  bit [63:0] cross_addr;

  super.body();
  base = region_base(target_slave);

  // Default to the same page-straddling address the write leg computes, so the
  // sequence is usable standalone as well as paired.
  cross_addr = (read_addr != 0) ? read_addr : (base + (page_index * 4096) + 4092);

  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  req.ar_4kb_boundary_c7.constraint_mode(0);
  if (!req.randomize() with {
        req.tx_type       == READ;
        req.transfer_type == NON_BLOCKING_READ;
        req.arburst       == READ_INCR;
        req.arid          inside {[0:9]};
        req.araddr        == cross_addr;
        req.arlen         == 1;             // 2 beats
        req.arsize        == READ_4_BYTES;  // 4 bytes/beat
      }) begin
    `uvm_fatal(get_type_name(), "Track-B 4KB-crossing read randomization failed")
  end
  req.ar_4kb_boundary_c7.constraint_mode(1);

  `uvm_info(get_type_name(),
            $sformatf("Track-B 4KB-CROSSING READ S%0d addr=0x%016h arid=%0d arlen=%0d arsize=%0d (spans 0x%016h)",
                      target_slave, req.araddr, req.arid, req.arlen, req.arsize, req.araddr + 8),
            UVM_LOW)
  finish_item(req);

endtask : body

`endif
