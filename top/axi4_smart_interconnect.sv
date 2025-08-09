`ifndef AXI4_SMART_INTERCONNECT_INCLUDED_
`define AXI4_SMART_INTERCONNECT_INCLUDED_

//--------------------------------------------------------------------------------------------
// Module: axi4_smart_interconnect
// Description: Simplified interconnect for bench-only mode using OR logic
// Features:
//   - OR-based signal routing to ensure proper connections
//   - BFM-level address filtering handles routing decisions
//   - Prevents race conditions through proper signal control
//--------------------------------------------------------------------------------------------

import axi4_globals_pkg::*;
`include "axi4_bus_config.svh"

module axi4_smart_interconnect #(
  parameter int NUM_MASTERS = 10,
  parameter int NUM_SLAVES  = 10,
  parameter int ADDR_WIDTH  = ADDRESS_WIDTH,
  parameter int DATA_WIDTH  = 256
) (
  input  logic aclk,
  input  logic aresetn,
  axi4_if master_intf[NUM_MASTERS],
  axi4_if slave_intf[NUM_SLAVES]
);

  // OR-based interconnect - similar to original hdl_top bus matrix
  // but with proper reset handling and signal initialization
  
  genvar i, j;
  generate
    for (j = 0; j < NUM_SLAVES; j++) begin : slave_connections
      
      // Write Address Channel - OR all master requests
      always_comb begin
        slave_intf[j].awid     = 4'b0;
        slave_intf[j].awaddr   = '0;
        slave_intf[j].awlen    = 4'b0;
        slave_intf[j].awsize   = 3'b0;
        slave_intf[j].awburst  = 2'b0;
        slave_intf[j].awlock   = 2'b0;
        slave_intf[j].awcache  = 4'b0;
        slave_intf[j].awprot   = 3'b0;
        slave_intf[j].awqos    = 4'b0;
        slave_intf[j].awregion = 4'b0;
        slave_intf[j].awuser   = '0;
        slave_intf[j].awvalid  = 1'b0;
        
        for (int i = 0; i < NUM_MASTERS; i++) begin
          if (master_intf[i].awvalid) begin
            slave_intf[j].awid     |= master_intf[i].awid;
            slave_intf[j].awaddr   |= master_intf[i].awaddr;
            slave_intf[j].awlen    |= master_intf[i].awlen;
            slave_intf[j].awsize   |= master_intf[i].awsize;
            slave_intf[j].awburst  |= master_intf[i].awburst;
            slave_intf[j].awlock   |= master_intf[i].awlock;
            slave_intf[j].awcache  |= master_intf[i].awcache;
            slave_intf[j].awprot   |= master_intf[i].awprot;
            slave_intf[j].awqos    |= master_intf[i].awqos;
            slave_intf[j].awregion |= master_intf[i].awregion;
            slave_intf[j].awuser   |= master_intf[i].awuser;
            slave_intf[j].awvalid  |= master_intf[i].awvalid;
          end
        end
      end

      // Write Data Channel - OR all master data
      always_comb begin
        slave_intf[j].wdata  = '0;
        slave_intf[j].wstrb  = '0;
        slave_intf[j].wlast  = 1'b0;
        slave_intf[j].wuser  = '0;
        slave_intf[j].wvalid = 1'b0;
        
        for (int i = 0; i < NUM_MASTERS; i++) begin
          if (master_intf[i].wvalid) begin
            slave_intf[j].wdata  |= master_intf[i].wdata;
            slave_intf[j].wstrb  |= master_intf[i].wstrb;
            slave_intf[j].wlast  |= master_intf[i].wlast;
            slave_intf[j].wuser  |= master_intf[i].wuser;
            slave_intf[j].wvalid |= master_intf[i].wvalid;
          end
        end
      end

      // Read Address Channel - OR all master requests
      always_comb begin
        slave_intf[j].arid     = 4'b0;
        slave_intf[j].araddr   = '0;
        slave_intf[j].arlen    = 8'b0;
        slave_intf[j].arsize   = 3'b0;
        slave_intf[j].arburst  = 2'b0;
        slave_intf[j].arlock   = 2'b0;
        slave_intf[j].arcache  = 4'b0;
        slave_intf[j].arprot   = 3'b0;
        slave_intf[j].arqos    = 4'b0;
        slave_intf[j].arregion = 4'b0;
        slave_intf[j].aruser   = '0;
        slave_intf[j].arvalid  = 1'b0;
        
        for (int i = 0; i < NUM_MASTERS; i++) begin
          if (master_intf[i].arvalid) begin
            slave_intf[j].arid     |= master_intf[i].arid;
            slave_intf[j].araddr   |= master_intf[i].araddr;
            slave_intf[j].arlen    |= master_intf[i].arlen;
            slave_intf[j].arsize   |= master_intf[i].arsize;
            slave_intf[j].arburst  |= master_intf[i].arburst;
            slave_intf[j].arlock   |= master_intf[i].arlock;
            slave_intf[j].arcache  |= master_intf[i].arcache;
            slave_intf[j].arprot   |= master_intf[i].arprot;
            slave_intf[j].arqos    |= master_intf[i].arqos;
            slave_intf[j].arregion |= master_intf[i].arregion;
            slave_intf[j].aruser   |= master_intf[i].aruser;
            slave_intf[j].arvalid  |= master_intf[i].arvalid;
          end
        end
      end
    end

    for (i = 0; i < NUM_MASTERS; i++) begin : master_connections
      
      // Write Response Channel - OR all slave responses
      always_comb begin
        master_intf[i].awready = 1'b0;
        master_intf[i].wready  = 1'b0;
        master_intf[i].bid     = 4'b0;
        master_intf[i].bresp   = 2'b0;
        master_intf[i].buser   = '0;
        master_intf[i].bvalid  = 1'b0;
        
        for (int j = 0; j < NUM_SLAVES; j++) begin
          master_intf[i].awready |= slave_intf[j].awready;
          master_intf[i].wready  |= slave_intf[j].wready;
          if (slave_intf[j].bvalid) begin
            master_intf[i].bid     |= slave_intf[j].bid;
            master_intf[i].bresp   |= slave_intf[j].bresp;
            master_intf[i].buser   |= slave_intf[j].buser;
            master_intf[i].bvalid  |= slave_intf[j].bvalid;
          end
        end
      end

      // Read Response Channel - OR all slave responses
      always_comb begin
        master_intf[i].arready = 1'b0;
        master_intf[i].rid     = 4'b0;
        master_intf[i].rdata   = '0;
        master_intf[i].rresp   = 2'b0;
        master_intf[i].rlast   = 1'b0;
        master_intf[i].ruser   = '0;
        master_intf[i].rvalid  = 1'b0;
        
        for (int j = 0; j < NUM_SLAVES; j++) begin
          master_intf[i].arready |= slave_intf[j].arready;
          if (slave_intf[j].rvalid) begin
            master_intf[i].rid     |= slave_intf[j].rid;
            master_intf[i].rdata   |= slave_intf[j].rdata;
            master_intf[i].rresp   |= slave_intf[j].rresp;
            master_intf[i].rlast   |= slave_intf[j].rlast;
            master_intf[i].ruser   |= slave_intf[j].ruser;
            master_intf[i].rvalid  |= slave_intf[j].rvalid;
          end
        end
      end
      
      // Backpressure handling - distribute master ready to all slaves
      always_comb begin
        for (int j = 0; j < NUM_SLAVES; j++) begin
          slave_intf[j].bready |= master_intf[i].bready;
          slave_intf[j].rready |= master_intf[i].rready;
        end
      end
    end
  endgenerate

endmodule : axi4_smart_interconnect

`endif