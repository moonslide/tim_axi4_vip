`ifndef AXI4_MASTER_AGENT_BFM_INCLUDED_
`define AXI4_MASTER_AGENT_BFM_INCLUDED_

//--------------------------------------------------------------------------------------------
// Module:AXI4 Master Agent BFM
// This module is used as the configuration class for master agent bfm and its components
//--------------------------------------------------------------------------------------------
module axi4_master_agent_bfm #(parameter int MASTER_ID = 0)(axi4_if intf);

  //-------------------------------------------------------
  // Package : Importing Uvm Pakckage and Test Package
  //-------------------------------------------------------
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  master_assertions M_A(
    .aclk(intf.aclk),
    .aresetn(intf.aresetn),
    .awid(intf.awid),
    .awaddr(intf.awaddr),
    .awlen(intf.awlen),
    .awsize(intf.awsize),
    .awburst(intf.awburst),
    .awlock(intf.awlock),
    .awcache(intf.awcache),
    .awprot(intf.awprot),
    .awqos(intf.awqos),
    .awregion(intf.awregion),
    .awuser(intf.awuser),
    .awvalid(intf.awvalid),
    .awready(intf.awready),
    .wdata(intf.wdata),
    .wstrb(intf.wstrb),
    .wlast(intf.wlast),
    .wuser(intf.wuser),
    .wvalid(intf.wvalid),
    .wready(intf.wready),
    .bid(intf.bid),
    .bresp(intf.bresp),
    .buser(intf.buser),
    .bvalid(intf.bvalid),
    .bready(intf.bready),
    .arid(intf.arid),
    .araddr(intf.araddr),
    .arlen(intf.arlen),
    .arsize(intf.arsize),
    .arburst(intf.arburst),
    .arlock(intf.arlock),
    .arcache(intf.arcache),
    .arprot(intf.arprot),
    .arqos(intf.arqos),
    .arregion(intf.arregion),
    .aruser(intf.aruser),
    .arvalid(intf.arvalid),
    .arready(intf.arready),
    .rid(intf.rid),
    .rdata(intf.rdata),
    .rresp(intf.rresp),
    .rlast(intf.rlast),
    .ruser(intf.ruser),
    .rvalid(intf.rvalid),
    .rready(intf.rready)
  ); 
  //-------------------------------------------------------
  // AXI4 Master Driver bfm instantiation
  //-------------------------------------------------------
  axi4_master_driver_bfm axi4_master_drv_bfm_h (.aclk(intf.aclk), 
                                                .aresetn(intf.aresetn),
                                                .awid(intf.awid),
                                                .awaddr(intf.awaddr),
                                                .awlen(intf.awlen),
                                                .awsize(intf.awsize),
                                                .awburst(intf.awburst),
                                                .awlock(intf.awlock),
                                                .awcache(intf.awcache),
                                                .awprot(intf.awprot),
                                                .awqos(intf.awqos),
                                                .awregion(intf.awregion),
                                                .awuser(intf.awuser),
                                                .awvalid(intf.awvalid),
                                                .awready(intf.awready),
                                                .wdata(intf.wdata),
                                                .wstrb(intf.wstrb),
                                                .wlast(intf.wlast),
                                                .wuser(intf.wuser),
                                                .wvalid(intf.wvalid),
                                                .wready(intf.wready),
                                                .bid(intf.bid),
                                                .bresp(intf.bresp),
                                                .buser(intf.buser),
                                                .bvalid(intf.bvalid),
                                                .bready(intf.bready),
                                                .arid(intf.arid),
                                                .araddr(intf.araddr),
                                                .arlen(intf.arlen),
                                                .arsize(intf.arsize),
                                                .arburst(intf.arburst),
                                                .arlock(intf.arlock),
                                                .arcache(intf.arcache),
                                                .arprot(intf.arprot),
                                                .arqos(intf.arqos),
                                                .arregion(intf.arregion),
                                                .aruser(intf.aruser),
                                                .arvalid(intf.arvalid),
                                                .arready(intf.arready),
                                                .rid(intf.rid),
                                                .rdata(intf.rdata),
                                                .rresp(intf.rresp),
                                                .rlast(intf.rlast),
                                                .ruser(intf.ruser),      
                                                .rvalid(intf.rvalid),
                                                .rready(intf.rready)
                                                );

  //-------------------------------------------------------
  // AXI4 Master monitor  bfm instantiation
  //-------------------------------------------------------
  axi4_master_monitor_bfm axi4_master_mon_bfm_h (.aclk(intf.aclk),
                                                 .aresetn(intf.aresetn),
                                                 .awid(intf.awid),
                                                 .awaddr(intf.awaddr),
                                                 .awlen(intf.awlen),
                                                 .awsize(intf.awsize),
                                                 .awburst(intf.awburst),
                                                 .awlock(intf.awlock),
                                                 .awcache(intf.awcache),
                                                 .awprot(intf.awprot),
                                                 .awqos(intf.awqos),
                                                 .awregion(intf.awregion),
                                                 .awuser(intf.awuser),
                                                 .awvalid(intf.awvalid),
                                                 .awready(intf.awready),
                                                 .wdata(intf.wdata),
                                                 .wstrb(intf.wstrb),
                                                 .wlast(intf.wlast),
                                                 .wuser(intf.wuser),
                                                 .wvalid(intf.wvalid),
                                                 .wready(intf.wready),
                                                 .bid(intf.bid),
                                                 .bresp(intf.bresp),
                                                 .buser(intf.buser),
                                                 .bvalid(intf.bvalid),
                                                 .bready(intf.bready),
                                                 .arid(intf.arid),
                                                 .araddr(intf.araddr),
                                                 .arlen(intf.arlen),
                                                 .arsize(intf.arsize),
                                                 .arburst(intf.arburst),
                                                 .arlock(intf.arlock),
                                                 .arcache(intf.arcache),
                                                 .arprot(intf.arprot),
                                                 .arqos(intf.arqos),
                                                 .arregion(intf.arregion),
                                                 .aruser(intf.aruser),
                                                 .arvalid(intf.arvalid),
                                                 .arready(intf.arready),
                                                 .rid(intf.rid),
                                                 .rdata(intf.rdata),
                                                 .rresp(intf.rresp),
                                                 .rlast(intf.rlast),
                                                 .ruser(intf.ruser),      
                                                 .rvalid(intf.rvalid),
                                                 .rready(intf.rready)
                                                 );

  //-------------------------------------------------------
  // Setting the virtual handle of BMFs into config_db
  //-------------------------------------------------------
  initial begin
    string path;
    bit disable_timeout;
    
    path = $sformatf("*axi4_master_agent_h[%0d]*", MASTER_ID);
    uvm_config_db#(virtual axi4_master_driver_bfm)::set(null, path,
                                                       "axi4_master_driver_bfm",
                                                       axi4_master_drv_bfm_h);
    uvm_config_db#(virtual axi4_master_monitor_bfm)::set(null, path,
                                                        "axi4_master_monitor_bfm",
                                                        axi4_master_mon_bfm_h);
    // Export the bound assertion interface via config_db so that the UVM
    // environment can configure assertion parameters such as ready_delay_cycles
    // after build time. Direct hierarchical access to the interface instance is
    // not practical once the BFM is instantiated, hence the config_db handle.
    uvm_config_db#(virtual master_assertions)::set(null, path,
                                                  "master_assertions",
                                                  M_A);
    
    // Check for timeout disable configuration after UVM build phase
    #1;  // Wait for UVM configuration to be set
    if(uvm_config_db#(bit)::get(null, "*", "disable_timeout_checks", disable_timeout)) begin
      if(disable_timeout) begin
        M_A.disable_timeout_checks = 1'b1;
        `uvm_info("axi4_master_agent_bfm", "Timeout checks disabled for assertions", UVM_MEDIUM);
      end
    end
  end



  //Printing axi4 master agent bfm
  initial begin
    `uvm_info("axi4 master agent bfm",$sformatf("AXI4 MASTER AGENT BFM"),UVM_LOW);
  end
   
endmodule : axi4_master_agent_bfm
`endif
