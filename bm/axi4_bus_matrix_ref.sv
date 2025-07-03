`ifndef AXI4_BUS_MATRIX_REF_INCLUDED_
`define AXI4_BUS_MATRIX_REF_INCLUDED_

class axi4_bus_matrix_ref extends uvm_component;
  `uvm_component_utils(axi4_bus_matrix_ref)

  // simple memory for each slave indexed by address
  bit [DATA_WIDTH-1:0] slave_mem[NO_OF_SLAVES][bit [ADDRESS_WIDTH-1:0]];

  typedef struct {
    bit [ADDRESS_WIDTH-1:0] start_addr;
    bit [ADDRESS_WIDTH-1:0] end_addr;
    bit                      read_only;
    bit [NO_OF_MASTERS-1:0]  read_masters;
    bit [NO_OF_MASTERS-1:0]  write_masters;
  } slave_cfg_s;

  slave_cfg_s slave_cfg[NO_OF_SLAVES];

  extern function new(string name = "axi4_bus_matrix_ref", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function int decode(bit [ADDRESS_WIDTH-1:0] addr);
  extern virtual function bresp_e get_write_resp(int master, bit [ADDRESS_WIDTH-1:0] addr);
  extern virtual function rresp_e get_read_resp(int master, bit [ADDRESS_WIDTH-1:0] addr);
  extern virtual function void store_write(bit [ADDRESS_WIDTH-1:0] addr,
                                           bit [DATA_WIDTH-1:0] data);
  extern virtual function void load_read(bit [ADDRESS_WIDTH-1:0] addr,
                                         output bit [DATA_WIDTH-1:0] data);
endclass : axi4_bus_matrix_ref

function axi4_bus_matrix_ref::new(string name = "axi4_bus_matrix_ref", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_bus_matrix_ref::build_phase(uvm_phase phase);
  super.build_phase(phase);

  slave_cfg[0] = '{64'h0000_0100_0000_0000,
                    64'h0000_0107_FFFF_FFFF,
                    1'b0,
                    4'b1111,
                    4'b1111};
  slave_cfg[1] = '{64'h0000_0000_0000_0000,
                    64'h0000_0000_0001_FFFF,
                    1'b1,
                    4'b0000,
                    4'b0000};
  slave_cfg[2] = '{64'h0000_0010_0000_0000,
                    64'h0000_0010_000F_FFFF,
                    1'b0,
                    4'b0111,
                    4'b0111};
  slave_cfg[3] = '{64'h0000_0020_0000_0000,
                    64'h0000_0020_0000_0FFF,
                    1'b1,
                    4'b1001,
                    4'b0000};
endfunction : build_phase

function int axi4_bus_matrix_ref::decode(bit [ADDRESS_WIDTH-1:0] addr);
  foreach(slave_cfg[i]) begin
    if(addr >= slave_cfg[i].start_addr && addr <= slave_cfg[i].end_addr)
      return i;
  end
  return -1;
endfunction : decode

function bresp_e axi4_bus_matrix_ref::get_write_resp(int master, bit [ADDRESS_WIDTH-1:0] addr);
  int sid = decode(addr);
  if(sid < 0)
    return WRITE_DECERR;
  if(!slave_cfg[sid].write_masters[master])
    return WRITE_DECERR;
  if(slave_cfg[sid].read_only)
    return WRITE_SLVERR;
  return WRITE_OKAY;
endfunction : get_write_resp

function rresp_e axi4_bus_matrix_ref::get_read_resp(int master, bit [ADDRESS_WIDTH-1:0] addr);
  int sid = decode(addr);
  if(sid < 0)
    return READ_DECERR;
  if(!slave_cfg[sid].read_masters[master])
    return READ_DECERR;
  return READ_OKAY;
endfunction : get_read_resp

function void axi4_bus_matrix_ref::store_write(bit [ADDRESS_WIDTH-1:0] addr,
                                               bit [DATA_WIDTH-1:0] data);
  int sid = decode(addr);
  if(sid >= 0)
    slave_mem[sid][addr] = data;
endfunction : store_write

function void axi4_bus_matrix_ref::load_read(bit [ADDRESS_WIDTH-1:0] addr,
                                             output bit [DATA_WIDTH-1:0] data);
  int sid = decode(addr);
  if(sid >= 0 && slave_mem[sid].exists(addr))
    data = slave_mem[sid][addr];
  else
    data = '0;
endfunction : load_read

`endif
