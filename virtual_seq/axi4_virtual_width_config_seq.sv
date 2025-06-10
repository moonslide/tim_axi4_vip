`ifndef AXI4_VIRTUAL_WIDTH_CONFIG_SEQ_INCLUDED_
`define AXI4_VIRTUAL_WIDTH_CONFIG_SEQ_INCLUDED_

class axi4_virtual_width_config_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_width_config_seq)

  axi4_master_set_width_seq master_seq;
  axi4_slave_set_width_seq  slave_seq;
  axi4_virtual_write_read_seq write_read_seq;

  extern function new(string name = "axi4_virtual_width_config_seq");
  extern task body();
endclass : axi4_virtual_width_config_seq

function axi4_virtual_width_config_seq::new(string name = "axi4_virtual_width_config_seq");
  super.new(name);
endfunction : new

task axi4_virtual_width_config_seq::body();
  super.body();

  master_seq = axi4_master_set_width_seq::type_id::create("master_seq");
  slave_seq  = axi4_slave_set_width_seq::type_id::create("slave_seq");

  master_seq.address_width = 64;
  master_seq.data_width    = 128;
  slave_seq.address_width  = 32;
  slave_seq.data_width     = 256;

  fork
    master_seq.start(p_sequencer.axi4_master_write_seqr_h);
    slave_seq.start(p_sequencer.axi4_slave_write_seqr_h);
  join

  write_read_seq = axi4_virtual_write_read_seq::type_id::create("write_read_seq");
  write_read_seq.start(p_sequencer);
endtask : body

`endif
