`ifndef AXI4_MASTER_QOS_TAGGED_WRITE_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_TAGGED_WRITE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_tagged_write_seq
//  One single-beat NON_BLOCKING write with a caller-chosen AWQOS and AWID, whose
//  data carries a tag naming its own AWID: wdata[0][31:0] = TAG_BASE | awid.
//
//  Written for the write-QoS ordering test: AXI4 has no WID, so the only way to
//  tell on the wire which AW a W burst belongs to is its content. A test that
//  records the AW order (AWID) and the W order (tag) sees directly whether W
//  bursts follow AW order.
//
//  Address: awaddr = base_addr + 16*awid_value (slave 0 under
//  BUS_MATRIX_MODE=NONE with the default base_addr).
//--------------------------------------------------------------------------------------------
class axi4_master_qos_tagged_write_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_qos_tagged_write_seq)

  // Constant: TAG_BASE
  // Upper half of the data tag; the low half is the AWID.
  localparam bit [31:0] TAG_BASE = 32'h7A60_0000;

  bit [3:0]  qos_value  = 4'h0;
  int        awid_value = 0;
  bit [63:0] base_addr  = 64'h0000_0000_0000_2000;

  extern function new(string name = "axi4_master_qos_tagged_write_seq");
  extern task body();
endclass : axi4_master_qos_tagged_write_seq

function axi4_master_qos_tagged_write_seq::new(string name = "axi4_master_qos_tagged_write_seq");
  super.new(name);
endfunction : new

task axi4_master_qos_tagged_write_seq::body();
  bit [63:0] target_addr;
  bit [31:0] tag;
  super.body();
  target_addr = base_addr + (64'(awid_value) << 4);
  tag         = TAG_BASE | (awid_value & 32'hFFFF);
  start_item(req);
  if(!req.randomize() with {
    req.tx_type        == WRITE;
    req.transfer_type  == NON_BLOCKING_WRITE;
    req.awqos          == local::qos_value;
    req.awburst        == WRITE_INCR;
    req.awsize         == WRITE_4_BYTES;
    req.awlen          == 8'h00;
    req.awaddr         == local::target_addr;
    req.awprot         == 3'b010;
    req.wdata[0][31:0] == local::tag;
  }) begin
    `uvm_fatal("axi4", "Randomization failed for QoS tagged write sequence")
  end
  req.awid = awid_e'(awid_value % (`AXI_ID_LAST + 1));
  `uvm_info(get_type_name(), $sformatf("QoS tagged write: awid=0x%0h awqos=%0h awaddr=0x%016h tag=0x%08h",
            req.awid, req.awqos, req.awaddr, tag), UVM_MEDIUM)
  finish_item(req);
endtask : body

`endif
