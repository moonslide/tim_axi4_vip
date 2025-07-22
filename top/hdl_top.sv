`ifndef HDL_TOP_INCLUDED_
`define HDL_TOP_INCLUDED_

//--------------------------------------------------------------------------------------------
// Module      : HDL Top
// Description : Has a interface master and slave agent bfm.
//--------------------------------------------------------------------------------------------

module hdl_top;

  import uvm_pkg::*;
  import axi4_globals_pkg::*;
  `include "uvm_macros.svh"

  //-------------------------------------------------------
  // Clock Reset Initialization
  //-------------------------------------------------------
  bit aclk;
  bit aresetn;

  //-------------------------------------------------------
  // Display statement for HDL_TOP
  //-------------------------------------------------------
  initial begin
    $display("HDL_TOP");
  end

  //-------------------------------------------------------
  // System Clock Generation
  //-------------------------------------------------------
  initial begin
    aclk = 1'b0;
    forever #10 aclk = ~aclk;
  end
//`ifdef DUMP_FSDB
//        initial begin
//            string fsdb_filename;
//        
//            // ? +fsdbfile=my_dump.fsdb
//            if (!$value$plusargs("fsdbfile=%s", fsdb_filename)) begin
//                fsdb_filename = "default.fsdb"; // if no used for default.fsdb
//            end
//        
//            $fsdbDumpfile(fsdb_filename);  // 
//            $fsdbDumpvars(0, hvl_top);   //
////            $fsdbDumpvars(" uvm_test_top.axi4_env_h.axi4_master_agent_h[0]", "+class","+object_level=5");   //
//
//        end
//`endif


  //-------------------------------------------------------
  // System Reset Generation
  // Active low reset
  //-------------------------------------------------------
  initial begin
    aresetn = 1'b1;
    #10 aresetn = 1'b0;

    repeat (1) begin
      @(posedge aclk);
    end
    aresetn = 1'b1;
  end

  // Variables : master_intf and slave_intf
  // HDL always creates maximum interfaces (10x10) for flexibility
  // HVL dynamically uses only required interfaces based on test configuration:
  // - Enhanced matrix tests (TC01-TC05): Use all 10 masters/10 slaves
  // - Boundary tests (TC046-TC058): Use only 4 masters/4 slaves
  // - Default tests: Use only 4 masters/4 slaves
  // This approach avoids recompilation between different test configurations
  axi4_if master_intf[NO_OF_MASTERS] (.aclk(aclk),
                                     .aresetn(aresetn));
  axi4_if slave_intf[NO_OF_SLAVES]   (.aclk(aclk),
                                     .aresetn(aresetn));

  //-------------------------------------------------------
  // AXI4  No of Master and Slaves Agent Instantiation
  //-------------------------------------------------------
  genvar i;
  generate
    for (i=0; i<NO_OF_MASTERS; i++) begin : axi4_master_agent_bfm
      axi4_master_agent_bfm #(.MASTER_ID(i))
        axi4_master_agent_bfm_h(master_intf[i]);
      defparam axi4_master_agent_bfm[i].axi4_master_agent_bfm_h.MASTER_ID = i;
    end
    for (i=0; i<NO_OF_SLAVES; i++) begin : axi4_slave_agent_bfm
      axi4_slave_agent_bfm #(.SLAVE_ID(i))
        axi4_slave_agent_bfm_h(slave_intf[i]);
      defparam axi4_slave_agent_bfm[i].axi4_slave_agent_bfm_h.SLAVE_ID = i;
    end
  endgenerate
  //-------------------------------------------------------------------------
  // Simple direct connection between each master and slave interface instance
  //-------------------------------------------------------------------------
  genvar j;
  generate
    for (j = 0; j < NO_OF_MASTERS && j < NO_OF_SLAVES; j++) begin : axi4_connect
      // Write Address Channel
      assign slave_intf[j].awid     = master_intf[j].awid;
      assign slave_intf[j].awaddr   = master_intf[j].awaddr;
      assign slave_intf[j].awlen    = master_intf[j].awlen;
      assign slave_intf[j].awsize   = master_intf[j].awsize;
      assign slave_intf[j].awburst  = master_intf[j].awburst;
      assign slave_intf[j].awlock   = master_intf[j].awlock;
      assign slave_intf[j].awcache  = master_intf[j].awcache;
      assign slave_intf[j].awprot   = master_intf[j].awprot;
      assign slave_intf[j].awqos    = master_intf[j].awqos;
      assign slave_intf[j].awregion = master_intf[j].awregion;
      assign slave_intf[j].awuser   = master_intf[j].awuser;
      assign slave_intf[j].awvalid  = master_intf[j].awvalid;
      assign master_intf[j].awready = slave_intf[j].awready;

      // Write Data Channel
      assign slave_intf[j].wdata    = master_intf[j].wdata;
      assign slave_intf[j].wstrb    = master_intf[j].wstrb;
      assign slave_intf[j].wlast    = master_intf[j].wlast;
      assign slave_intf[j].wuser    = master_intf[j].wuser;
      assign slave_intf[j].wvalid   = master_intf[j].wvalid;
      assign master_intf[j].wready  = slave_intf[j].wready;

      // Write Response Channel
      assign master_intf[j].bid     = slave_intf[j].bid;
      assign master_intf[j].bresp   = slave_intf[j].bresp;
      assign master_intf[j].buser   = slave_intf[j].buser;
      assign master_intf[j].bvalid  = slave_intf[j].bvalid;
      assign slave_intf[j].bready   = master_intf[j].bready;

      // Read Address Channel
      assign slave_intf[j].arid     = master_intf[j].arid;
      assign slave_intf[j].araddr   = master_intf[j].araddr;
      assign slave_intf[j].arlen    = master_intf[j].arlen;
      assign slave_intf[j].arsize   = master_intf[j].arsize;
      assign slave_intf[j].arburst  = master_intf[j].arburst;
      assign slave_intf[j].arlock   = master_intf[j].arlock;
      assign slave_intf[j].arcache  = master_intf[j].arcache;
      assign slave_intf[j].arprot   = master_intf[j].arprot;
      assign slave_intf[j].arqos    = master_intf[j].arqos;
      assign slave_intf[j].arregion = master_intf[j].arregion;
      assign slave_intf[j].aruser   = master_intf[j].aruser;
      assign slave_intf[j].arvalid  = master_intf[j].arvalid;
      assign master_intf[j].arready = slave_intf[j].arready;

      // Read Data Channel
      assign master_intf[j].rid     = slave_intf[j].rid;
      assign master_intf[j].rdata   = slave_intf[j].rdata;
      assign master_intf[j].rresp   = slave_intf[j].rresp;
      assign master_intf[j].rlast   = slave_intf[j].rlast;
      assign master_intf[j].ruser   = slave_intf[j].ruser;
      assign master_intf[j].rvalid  = slave_intf[j].rvalid;
      assign slave_intf[j].rready   = master_intf[j].rready;
    end
  endgenerate 
endmodule : hdl_top

`endif

