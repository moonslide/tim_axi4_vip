`ifndef AXI4_QOS_CTRL_OBSERVER_INCLUDED_
`define AXI4_QOS_CTRL_OBSERVER_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_ctrl_observer
//  Test-side record of what ONE manager port actually put on / got back from
//  the wire, as published by that master agent's monitor:
//    aw_qos / ar_qos : AWQOS / ARQOS of every address handshake, in wire order
//    aw_id           : AWID of every AW handshake, in wire order
//    w_tag           : wdata[0][31:0] of every W burst, in wire order (the
//                      tagged write sequence puts its AWID there)
//    r_id   / r_qos  : RID and the paired ARQOS of every completed read burst,
//                      in completion order
//  It checks nothing by itself; the QoS-control tests that create it decide
//  what the record must look like. Only those tests instantiate it.
//--------------------------------------------------------------------------------------------
`uvm_analysis_imp_decl(_qco_aw)
`uvm_analysis_imp_decl(_qco_ar)
`uvm_analysis_imp_decl(_qco_r)
`uvm_analysis_imp_decl(_qco_w)

class axi4_qos_ctrl_observer extends uvm_component;
  `uvm_component_utils(axi4_qos_ctrl_observer)

  uvm_analysis_imp_qco_aw #(axi4_master_tx, axi4_qos_ctrl_observer) aw_imp;
  uvm_analysis_imp_qco_ar #(axi4_master_tx, axi4_qos_ctrl_observer) ar_imp;
  uvm_analysis_imp_qco_r  #(axi4_master_tx, axi4_qos_ctrl_observer) r_imp;
  uvm_analysis_imp_qco_w  #(axi4_master_tx, axi4_qos_ctrl_observer) w_imp;

  bit [3:0] aw_qos[$];
  bit [3:0] ar_qos[$];
  int       r_id[$];
  bit [3:0] r_qos[$];
  int       aw_id[$];
  bit [31:0] w_tag[$];

  function new(string name = "axi4_qos_ctrl_observer", uvm_component parent = null);
    super.new(name, parent);
    aw_imp = new("aw_imp", this);
    ar_imp = new("ar_imp", this);
    r_imp  = new("r_imp",  this);
    w_imp  = new("w_imp",  this);
  endfunction : new

  virtual function void write_qco_aw(axi4_master_tx t);
    aw_qos.push_back(t.awqos);
    aw_id.push_back(int'(t.awid));
  endfunction : write_qco_aw

  virtual function void write_qco_ar(axi4_master_tx t);
    ar_qos.push_back(t.arqos);
  endfunction : write_qco_ar

  virtual function void write_qco_r(axi4_master_tx t);
    r_id.push_back(int'(t.rid));
    r_qos.push_back(t.arqos);
  endfunction : write_qco_r

  virtual function void write_qco_w(axi4_master_tx t);
    w_tag.push_back((t.wdata.size() > 0) ? t.wdata[0][31:0] : 32'hFFFF_FFFF);
  endfunction : write_qco_w

  // Function: connect_to
  // Subscribes this observer to master agent `mon`'s address and read-data ports.
  function void connect_to(axi4_master_monitor_proxy mon);
    mon.axi4_master_write_address_analysis_port.connect(aw_imp);
    mon.axi4_master_read_address_analysis_port.connect(ar_imp);
    mon.axi4_master_read_data_analysis_port.connect(r_imp);
    mon.axi4_master_write_data_analysis_port.connect(w_imp);
  endfunction : connect_to

  // Function: distinct
  // Number of different values in q.
  static function int distinct(bit [3:0] q[$]);
    bit seen[16];
    int n;
    foreach(q[i]) if(!seen[q[i]]) begin seen[q[i]] = 1; n++; end
    return n;
  endfunction : distinct
endclass : axi4_qos_ctrl_observer

`endif
