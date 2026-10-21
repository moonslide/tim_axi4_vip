`ifndef AXI4_MASTER_QOS_TAGGED_READ_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_TAGGED_READ_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_tagged_read_seq
//  One single-beat NON_BLOCKING read with a caller-chosen ARQOS AND ARID.
//
//  Written for the read-QoS arbitration tests: the subordinate's QoS arbiter may
//  return reads out of issue order, which AXI4 only permits between DIFFERENT
//  ARIDs, so each read of such a test carries its own ARID (arid_value). The
//  ARID doubles as the tag a test uses to recognise which read an R burst
//  answers.
//
//  Address: araddr = base_addr + 16*arid_value, inside the low 64 KB that every
//  bus-matrix mode maps to slave 0 when base_addr is left at its default for
//  BUS_MATRIX_MODE=NONE (1x1). A test on another mode sets base_addr.
//--------------------------------------------------------------------------------------------
class axi4_master_qos_tagged_read_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_qos_tagged_read_seq)

  // Variable: qos_value
  // ARQOS of the read.
  bit [3:0]  qos_value = 4'h0;

  // Variable: arid_value
  // ARID of the read. Keep it distinct from every other read that may be
  // outstanding at the same time if the read is allowed to be reordered.
  int        arid_value = 0;

  // Variable: base_addr
  // Base of the address window the read targets.
  bit [63:0] base_addr = 64'h0000_0000_0000_1000;

  extern function new(string name = "axi4_master_qos_tagged_read_seq");
  extern task body();
endclass : axi4_master_qos_tagged_read_seq

function axi4_master_qos_tagged_read_seq::new(string name = "axi4_master_qos_tagged_read_seq");
  super.new(name);
endfunction : new

task axi4_master_qos_tagged_read_seq::body();
  bit [63:0] target_addr;
  super.body();
  target_addr = base_addr + (64'(arid_value) << 4);
  start_item(req);
  if(!req.randomize() with {
    req.tx_type       == READ;
    req.transfer_type == NON_BLOCKING_READ;
    req.arqos         == local::qos_value;
    req.arburst       == READ_INCR;
    req.arsize        == READ_4_BYTES;
    req.arlen         == 8'h00;
    req.araddr        == local::target_addr;
    req.arprot        == 3'b010;
  }) begin
    `uvm_fatal("axi4", "Randomization failed for QoS tagged read sequence")
  end
  req.arid = arid_e'(arid_value % (`AXI_ID_LAST + 1));
  `uvm_info(get_type_name(), $sformatf("QoS tagged read: arid=0x%0h arqos=%0h araddr=0x%016h",
            req.arid, req.arqos, req.araddr), UVM_MEDIUM)
  finish_item(req);
endtask : body

`endif
