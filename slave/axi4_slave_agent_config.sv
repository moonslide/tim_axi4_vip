`ifndef AXI4_SLAVE_AGENT_CONFIG_INCLUDED_
`define AXI4_SLAVE_AGENT_CONFIG_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_agent_config
// Used as the configuration class for axi4_slave agent and it's components
//--------------------------------------------------------------------------------------------
class axi4_slave_agent_config extends uvm_object;
  `uvm_object_utils(axi4_slave_agent_config)

  //Variable: is_active
  //Used for creating the agent in either passive or active mode
  uvm_active_passive_enum is_active = UVM_ACTIVE;  
  
  //Variable: has_coverage
  //Used for enabling the master agent coverage
  bit has_coverage;

  //Variable: addr_width
  //Address width for this slave
  int addr_width = ADDRESS_WIDTH;

  //Variable: data_width
  //Data width for this slave
  int data_width = DATA_WIDTH;

  //Variable: slave_id
  //Gives the slave id
  int slave_id;
  
  //Variable : max_address
  //Used to store the maximum address value of this slave
  bit [ADDRESS_WIDTH-1:0] max_address;

  //Variable : min_address
  //Used to store the minimum address value of this slave
  bit [ADDRESS_WIDTH-1:0] min_address;
  
  //Variable : wait_count_write_response_channel;
  //Used to determine the number of wait states inserted for write response channel
  int wait_count_write_response_channel;
  
  //Variable : wait_count_read_data_channel;
  //Used to determine the number of wait states inserted for read data channel
  int wait_count_read_data_channel;

  //Variable: slave_response_mode
  //Used to enable the out_of_order for writres and reads
  rand response_mode_e slave_response_mode;

  //Variable: minimum_transactions
  //Used to set the minimum txns for out_of_order
  protected bit[1:0] minimum_transactions = 2;

  //Variable: maximum_transactions
  //Used to set the maximumm txns for out_of_order
  bit[3:0] maximum_transactions;

  //Variable: read_data_mode
  //Used to set type of data to read
  read_data_type_mode_e read_data_mode;

  //Used to set the qos mode
  qos_mode_e qos_mode_type;

  //-------------------------------------------------------
  // Read-QoS arbiter knobs (used only when qos_mode_type enables read QoS).
  // Every default reproduces the arbiter as it was before these knobs existed:
  // hold the FIRST response until two reads are queued, wait for that without
  // limit, then always serve the highest ARQOS (oldest first among equals).
  //-------------------------------------------------------

  //Variable: rd_qos_hold_min
  //Pool size the arbiter waits for before choosing. 1 = never hold.
  int rd_qos_hold_min = 2;

  //Variable: rd_qos_hold_scope
  //QOS_HOLD_FIRST: hold only before the first response (legacy).
  //QOS_HOLD_EACH : hold before every response.
  //KNOWN LIMITATION (not changed this round): the read-QoS
  //arbitration ignores ARID. Two queued reads with the SAME ARID can therefore
  //be returned out of issue order, which AXI4 forbids (A5.3: same-ID read
  //responses in order). Measured with the defaults: axi4_qos_basic_priority_test
  //(every read ARID 0) reports reordered=4 on slave 0. QOS_HOLD_EACH makes it
  //more likely (a bigger pool before every choice). Keep reads that may be
  //reordered on distinct ARIDs. qos_rd_arb_chk re-derives the SAME rule, so it
  //is not an independent oracle for this.
  qos_hold_scope_e rd_qos_hold_scope = QOS_HOLD_FIRST;

  //Variable: rd_qos_hold_tmo_clk
  //0 = hold without limit (legacy). N > 0 = once at least one read is queued,
  //wait at most N aclk cycles for the pool to reach rd_qos_hold_min, then
  //choose from whatever is queued. A topology that only ever delivers one read
  //at a time to this subordinate needs this, or the first read waits forever.
  //The plusarg +AXI4_QOS_HOLD_TMO=<N> applies N to every subordinate left at 0.
  int rd_qos_hold_tmo_clk = 0;

  //Variable: rd_qos_max_bypass
  //0 = no bound (legacy). N > 0 = a queued read that has been overtaken by N
  //younger reads is served next, whatever its ARQOS (starvation bound).
  int rd_qos_max_bypass = 0;

  //Variable: qos_rd_arb_chk
  //1 = re-derive every read-QoS choice with a separately written reference of
  //the same rule and report a mismatch as UVM_ERROR (self-check of the
  //arbiter's implementation, not of the rule: it does not catch the same-ARID
  //reordering described at rd_qos_hold_scope).
  bit qos_rd_arb_chk = 0;

  //Variable: qos_rd_expect_reorder_min
  //-1 = no expectation. N >= 0 = report_phase requires at least N read-QoS
  //choices that served a read other than the oldest queued one.
  int qos_rd_expect_reorder_min = -1;

  //Variable: qos_rd_expect_bypass_max
  //-1 = no expectation. N >= 0 = report_phase requires that no queued read was
  //overtaken more than N times.
  int qos_rd_expect_bypass_max = -1;

  //Variable: reset_test_mode
  //When set, slave driver doesn't wait for sequences (for reset testing)
  bit reset_test_mode = 0;

  //Variable: user_rdata
  //Used to set default read data
  bit[DATA_WIDTH-1:0] user_rdata;

  //constraint: maximum_txns
  //Make sure to have minimum txns to perform out_of_order
  constraint maximum_txns_c{maximum_transactions >= minimum_transactions;}

  // Variable: error_inject
  // Enable error injection mode - converts UVM_ERROR to UVM_WARNING for expected errors
  bit error_inject = 0;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_slave_agent_config");
  extern function void do_print(uvm_printer printer);
  extern function int get_minimum_transactions();
  extern function void set_minimum_transactions(int value);
endclass : axi4_slave_agent_config

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_slave_agent_config
//--------------------------------------------------------------------------------------------
function axi4_slave_agent_config::new(string name = "axi4_slave_agent_config");
  super.new(name); 
endfunction : new

function int axi4_slave_agent_config::get_minimum_transactions();
  return (this.minimum_transactions);
endfunction

function void axi4_slave_agent_config::set_minimum_transactions(int value);
  this.minimum_transactions = value;
endfunction

//--------------------------------------------------------------------------------------------
// Function: do_print method
// Print method can be added to display the data members values
//
// Parameters:
//  printer - uvm_printer
//--------------------------------------------------------------------------------------------
function void axi4_slave_agent_config::do_print(uvm_printer printer);
  super.do_print(printer);

  printer.print_string ("is_active",   is_active.name());
  printer.print_field ("slave_id",     slave_id,     $bits(slave_id),     UVM_DEC);
  printer.print_field ("has_coverage", has_coverage, $bits(has_coverage), UVM_DEC);
  printer.print_field ("addr_width", addr_width, $bits(addr_width), UVM_DEC);
  printer.print_field ("data_width", data_width, $bits(data_width), UVM_DEC);
  printer.print_field ("min_address",  min_address,  $bits(max_address),  UVM_HEX);
  printer.print_field ("max_address",  max_address,  $bits(max_address),  UVM_HEX);
  printer.print_string ("slave_response_type",   slave_response_mode.name());
  printer.print_string ("QoS mode",   qos_mode_type.name());
  // Read-QoS arbiter knobs: printed only when not at the default, so a config
  // dump of an existing test is unchanged.
  if(rd_qos_hold_min != 2 || rd_qos_hold_scope != QOS_HOLD_FIRST || rd_qos_hold_tmo_clk != 0 || rd_qos_max_bypass != 0)
    printer.print_string("rd_qos_hold",$sformatf("min=%0d scope=%s tmo_clk=%0d max_bypass=%0d",
                                                 rd_qos_hold_min,rd_qos_hold_scope.name(),rd_qos_hold_tmo_clk,rd_qos_max_bypass));
  if(qos_rd_arb_chk || qos_rd_expect_reorder_min >= 0 || qos_rd_expect_bypass_max >= 0)
    printer.print_string("qos_rd_checks",$sformatf("arb_chk=%0d expect_reorder_min=%0d expect_bypass_max=%0d",
                                                   qos_rd_arb_chk,qos_rd_expect_reorder_min,qos_rd_expect_bypass_max));
  printer.print_field ("minimum_transactions",  minimum_transactions,  $bits(minimum_transactions),  UVM_HEX);
  printer.print_field ("maximum_transactions",  maximum_transactions,  $bits(maximum_transactions),  UVM_HEX);
  printer.print_string ("read_data_mode", read_data_mode.name());  
  printer.print_field ("wait_count_write_response_channel",wait_count_write_response_channel,$bits(wait_count_write_response_channel),UVM_DEC);
  printer.print_field ("wait_count_read_data_channel",wait_count_read_data_channel,$bits(wait_count_read_data_channel),UVM_DEC);
         
endfunction : do_print

`endif

