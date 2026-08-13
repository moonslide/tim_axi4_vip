`ifndef AXI4_MASTER_TRACKB_4K_CROSS_SEQ_INCLUDED_
`define AXI4_MASTER_TRACKB_4K_CROSS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_trackb_4k_cross_seq
//
// Drives a write burst that DELIBERATELY crosses a 4KB page boundary at the
// real commercial fabric IP DUT.
//
// Why this is a different sequence from axi4_master_4k_boundary_cross_seq:
// that one runs against the 1:1 direct wiring, where no RTL decodes the
// address at all, so it can only ever tell you what the VIP's own slave agent
// and the env-side axi4_bus_matrix_ref reference model think.  Only a real
// interconnect has arbiters and a decoder that must actually deal with a burst
// spanning two pages.
//
// The experiment is deliberately isolated: the start address is inside a
// MAPPED region and both pages the burst touches are inside that same region,
// so decode cannot be the variable.  The only thing under test is what the
// fabric does with the 4KB crossing itself -- if the run reports DECERR, a
// dropped beat or a timeout, that is the fabric's crossing behaviour and not
// an address-map artefact.
//
// axi4_master_trackb_base_seq's header states the rule this violates on
// purpose: "an AXI4 burst must not cross a 4KB boundary".  aw_4kb_boundary_c7
// exists to keep RANDOM traffic legal, so it is switched off for this one
// directed item rather than removed.
//--------------------------------------------------------------------------------------------
class axi4_master_trackb_4k_cross_seq extends axi4_master_trackb_base_seq;
  `uvm_object_utils(axi4_master_trackb_4k_cross_seq)

  // Address actually driven, so a paired read sequence can target the same place.
  bit [63:0] last_addr;

  // Page index inside the region to straddle.  Page 1 rather than page 0 so
  // the burst sits well away from the region's own base boundary.
  int unsigned page_index = 1;

  extern function new(string name = "axi4_master_trackb_4k_cross_seq");
  extern task body();
endclass : axi4_master_trackb_4k_cross_seq

function axi4_master_trackb_4k_cross_seq::new(string name = "axi4_master_trackb_4k_cross_seq");
  super.new(name);
endfunction : new

task axi4_master_trackb_4k_cross_seq::body();
  bit [63:0] base;
  bit [63:0] size;
  bit [63:0] cross_addr;

  super.body();
  base = region_base(target_slave);
  size = region_size(target_slave);

  // Last 4 bytes of page <page_index>: a 2-beat, 4-byte INCR burst starting
  // here occupies ...0FFC..0x1003 and therefore steps over the boundary.
  cross_addr = base + (page_index * 4096) + 4092;

  if ((cross_addr + 8) >= (base + size)) begin
    `uvm_fatal(get_type_name(),
               $sformatf("page_index %0d puts the crossing burst outside S%0d - the test would be measuring decode, not crossing",
                         page_index, target_slave))
  end

  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  req.aw_4kb_boundary_c7.constraint_mode(0);
  if (!req.randomize() with {
        req.tx_type       == WRITE;
        req.transfer_type == NON_BLOCKING_WRITE;
        req.awburst       == WRITE_INCR;
        req.awid          inside {[0:9]};
        req.awaddr        == cross_addr;
        req.awlen         == 1;              // 2 beats
        req.awsize        == WRITE_4_BYTES;  // 4 bytes/beat
      }) begin
    `uvm_fatal(get_type_name(), "Track-B 4KB-crossing write randomization failed")
  end
  req.aw_4kb_boundary_c7.constraint_mode(1);

  req.wdata.delete();
  req.wdata.push_back($urandom); req.wdata.push_back($urandom);
  req.wstrb.delete();
  req.wstrb.push_back('hf); req.wstrb.push_back('hf);
  req.wlast = 1'b1;

  last_addr = req.awaddr;
  `uvm_info(get_type_name(),
            $sformatf("Track-B 4KB-CROSSING WRITE S%0d addr=0x%016h awid=%0d awlen=%0d awsize=%0d (spans 0x%016h)",
                      target_slave, req.awaddr, req.awid, req.awlen, req.awsize, req.awaddr + 8),
            UVM_LOW)
  finish_item(req);

endtask : body

`endif
