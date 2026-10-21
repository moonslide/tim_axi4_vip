`ifndef AXI4_MASTER_AGENT_CONFIG_INCLUDED_
`define AXI4_MASTER_AGENT_CONFIG_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_agent_config
// Used as the configuration class for axi4_master agent, for configuring number of slaves and number
// of active passive agents to be created
//--------------------------------------------------------------------------------------------
class axi4_master_agent_config extends uvm_object;
  `uvm_object_utils(axi4_master_agent_config)

  //Variable: is_active
  //Used for creating the agent in either passive or active mode
  uvm_active_passive_enum is_active=UVM_ACTIVE;  
  
  //Variable: has_coverage
  //Used for enabling the master agent coverage
  bit has_coverage;

  //Variable: master_id
  //Index of this master agent, mirroring axi4_slave_agent_config::slave_id.
  //The scoreboard needs the SOURCE PORT of a transaction; it used to substitute
  //AWID/ARID for it, which is only the same number by coincidence.
  int master_id;

  //Variable: addr_width
  //Address width for this master
  int addr_width = ADDRESS_WIDTH;

  //Variable: data_width
  //Data width for this master
  int data_width = DATA_WIDTH;

  //Variable : master_memory
  //Used to store all the data from the slaves
  //Each location of the master memory stores 32 bit data
  bit [MEMORY_WIDTH-1:0]master_memory[(SLAVE_MEMORY_SIZE+SLAVE_MEMORY_GAP)*NO_OF_SLAVES:0];

  //Variable : master_min_array
  //An associative array used to store the min address ranges of every slave
  //Index - type    - int
  //        stores  - slave number
  //Value - stores the minimum address range of that slave.
  bit [ADDRESS_WIDTH-1:0]master_min_addr_range_array[int];

  //Variable : master_max_array
  //An associative array used to store the max address ranges of every slave
  //Index - type    - int
  //        stores  - slave number
  //Value - stores the maximum address range of that slave.
  bit [ADDRESS_WIDTH-1:0]master_max_addr_range_array[int];
  
  //Variable : wait_count_write_address_channel;
  //Used to determine the number of wait states inserted for write address channel
  int wait_count_write_address_channel;
  
  //Variable : wait_count_write_data_channel;
  //Used to determine the number of wait states inserted for write data channel
  int wait_count_write_data_channel;
  
  //Variable : wait_count_read_address_channel;
  //Used to determine the number of wait states inserted for read address channel
  int wait_count_read_address_channel;

  //Variable : outstanding_write_tx
  //Used to send the outstanding transactions
  rand int outstanding_write_tx;
  
  //Variable : outstanding_read_tx
  //Used to send the outstanding transactions
  rand int outstanding_read_tx;

  //Used to store the read data type
  read_data_type_mode_e read_data_mode;

  //Used to set the qos mode
  qos_mode_e qos_mode_type;

  //Variables : awqos_src / arqos_src and their parameters
  //Agent-level AxQOS value policy, per channel (see axqos_src_e). Independent
  //of qos_mode_type, which selects the manager's write-QoS arbitration.
  //  AXQOS_SRC_SEQ   (default) - the sequence item's own value, untouched
  //  AXQOS_SRC_CONST - <ch>qos_const on every request
  //  AXQOS_SRC_SPAN  - uniform in [<ch>qos_span_lo : <ch>qos_span_hi] (both
  //                    ends included), drawn from a generator private to the
  //                    driver proxy so no other random stream moves
  //  AXQOS_SRC_ZERO  - 0 on every request (a manager with no QoS signal)
  //Not rand: the agent config is never randomised, and a rand field would
  //still change what the solver consumes for any test that does.
  axqos_src_e awqos_src     = AXQOS_SRC_SEQ;
  bit [3:0]   awqos_const   = 4'h0;
  bit [3:0]   awqos_span_lo = 4'h0;
  bit [3:0]   awqos_span_hi = 4'hF;
  axqos_src_e arqos_src     = AXQOS_SRC_SEQ;
  bit [3:0]   arqos_const   = 4'h0;
  bit [3:0]   arqos_span_lo = 4'h0;
  bit [3:0]   arqos_span_hi = 4'hF;

  //Variables : wr_qos_arb_point / wr_qos_aw_pool_min / wr_qos_aw_window_clk
  //Where write-QoS arbitration happens (see wr_qos_arb_point_e); used only when
  //qos_mode_type enables write QoS. With WR_QOS_ARB_AT_AW the driver proxy takes
  //pending writes off the sequencer into a pool (each one is item_done()'d when
  //it enters the pool, i.e. before its AW is issued) and issues the highest
  //AWQOS first, oldest first among equals. Before choosing it waits up to
  //wr_qos_aw_window_clk aclk cycles for the pool to reach wr_qos_aw_pool_min.
  //+AXI4_WR_QOS_ARB=AW selects WR_QOS_ARB_AT_AW for ALL managers from the
  //command line (evaluation aid; the default stays WR_QOS_ARB_AT_WDATA).
  //
  //WR_QOS_ARB_AT_AW is EXPERIMENTAL until it has broader regression coverage
  //(one directed test: axi4_qos_wr_aw_order_test). Consequences a sequence can
  //see:
  //  * finish_item() returns when the write enters the pool, i.e. BEFORE its AW
  //    is issued - a BLOCKING_WRITE is no longer blocking for the sequence, and
  //    response fields (BRESP...) are not written back into the sequence's item
  //    (the pool drives a copy).
  //  * a write still pooled when the run ends is a QOS_WR_AW UVM_ERROR
  //    (check_phase), never a silent loss.
  wr_qos_arb_point_e wr_qos_arb_point     = WR_QOS_ARB_AT_WDATA;
  int                wr_qos_aw_pool_min   = 2;
  int                wr_qos_aw_window_clk = 16;
  //wr_qos_aw_pool_max bounds the pool: the proxy stops taking writes off the
  //sequencer once this many are waiting, so a sequence that supplies writes
  //back to back in zero time cannot keep the proxy collecting forever (no AW
  //would ever be issued and simulation time would not advance).
  int                wr_qos_aw_pool_max   = 16;

  // Variable: error_inject
  // Enable error injection mode - converts UVM_ERROR to UVM_WARNING for expected errors
  bit error_inject = 0;

  // Variable: x_inject_idle_mbx (BENCH-066, Option C)
  // Per-agent delivery path for X-injection requests that are not attached to
  // any transaction (idle injection, e.g. AWVALID while the bus is idle). A
  // sequence puts an axi4_master_x_inject_idle_req here and waits on it; the
  // agent's axi4_master_driver_proxy services it in a thread of its own that
  // does not wait on get_next_item(). One config object per agent means one
  // mailbox per agent: no wildcard key, no other master can consume it.
  mailbox #(axi4_master_x_inject_idle_req) x_inject_idle_mbx;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_agent_config");
  extern function void do_print(uvm_printer printer);
  extern function void master_min_addr_range(int slave_number, bit [ADDRESS_WIDTH-1:0]slave_min_address_range);
  extern function void master_max_addr_range(int slave_number, bit [ADDRESS_WIDTH-1:0]slave_max_address_range);
endclass : axi4_master_agent_config

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_master_agent_config
//--------------------------------------------------------------------------------------------
function axi4_master_agent_config::new(string name = "axi4_master_agent_config");
  super.new(name);
  x_inject_idle_mbx = new();
endfunction : new

//--------------------------------------------------------------------------------------------
// Function : master_max_addr_range_array
// Used to store the maximum address ranges of the slaves in the array
// Parameters :
//  slave_number            - int
//  slave_max_address_range - bit [63:0]
//--------------------------------------------------------------------------------------------
function void axi4_master_agent_config::master_max_addr_range(int slave_number, bit[ADDRESS_WIDTH-1:0]slave_max_address_range);
  master_max_addr_range_array[slave_number] = slave_max_address_range;
endfunction : master_max_addr_range

//--------------------------------------------------------------------------------------------
// Function : master_min_addr_range_array
// Used to store the minimum address ranges of the slaves in the array
// Parameters :
//  slave_number            - int
//  slave_min_address_range - bit [63:0]
//--------------------------------------------------------------------------------------------
function void axi4_master_agent_config::master_min_addr_range(int slave_number, bit[ADDRESS_WIDTH-1:0]slave_min_address_range);
  master_min_addr_range_array[slave_number] = slave_min_address_range;
endfunction : master_min_addr_range

//--------------------------------------------------------------------------------------------
// Function: do_print method
// Print method can be added to display the data members values
//
// Parameters :
// printer  - uvm_printer
//--------------------------------------------------------------------------------------------
function void axi4_master_agent_config::do_print(uvm_printer printer);
  super.do_print(printer);
  
  printer.print_string ("is_active",is_active.name());
  printer.print_field ("has_coverage",  has_coverage, $bits(has_coverage),  UVM_DEC);
  printer.print_field ("addr_width", addr_width, $bits(addr_width), UVM_DEC);
  printer.print_field ("data_width", data_width, $bits(data_width), UVM_DEC);
  
  //Memory Mapping Minimum and Maximum Address Range 
  foreach(master_max_addr_range_array[i]) begin
    printer.print_field($sformatf("master_min_addr_range_array[%0d]",i),master_min_addr_range_array[i],
                                   $bits(master_min_addr_range_array[i]),UVM_HEX);
    printer.print_field($sformatf("master_max_addr_range_array[%0d]",i),master_max_addr_range_array[i],
                                   $bits(master_max_addr_range_array[i]),UVM_HEX);
  end
  printer.print_string ("QoS_mode",qos_mode_type.name());
  // Printed only when not at the default, so a config dump of an existing test
  // is unchanged.
  if(awqos_src != AXQOS_SRC_SEQ)
    printer.print_string("awqos_src",$sformatf("%s const=%0h span=[%0h:%0h]",awqos_src.name(),awqos_const,awqos_span_lo,awqos_span_hi));
  if(wr_qos_arb_point != WR_QOS_ARB_AT_WDATA)
    printer.print_string("wr_qos_arb_point",$sformatf("%s pool_min=%0d window_clk=%0d pool_max=%0d",wr_qos_arb_point.name(),wr_qos_aw_pool_min,wr_qos_aw_window_clk,wr_qos_aw_pool_max));
  if(arqos_src != AXQOS_SRC_SEQ)
    printer.print_string("arqos_src",$sformatf("%s const=%0h span=[%0h:%0h]",arqos_src.name(),arqos_const,arqos_span_lo,arqos_span_hi));

  printer.print_field("wait_count_write_address_channel",wait_count_write_address_channel,
                       $bits(wait_count_write_address_channel),UVM_DEC);
  printer.print_field("wait_count_write_data_channel",wait_count_write_data_channel,
                       $bits(wait_count_write_data_channel),UVM_DEC);
  printer.print_field("wait_count_read_address_channel",wait_count_read_address_channel,
                       $bits(wait_count_read_address_channel),UVM_DEC);
  printer.print_field("outstanding_write_tx",outstanding_write_tx,$bits(outstanding_write_tx),UVM_DEC);
  printer.print_field("outstanding_read_tx",outstanding_read_tx,$bits(outstanding_read_tx),UVM_DEC);
  
endfunction : do_print

`endif

