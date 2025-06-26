`ifndef AXI4_TEST_PKG_INCLUDED_
`define AXI4_TEST_PKG_INCLUDED_

//-----------------------------------------------------------------------------------------
// Package: Test
// Description:
// Includes all the files written to run the simulation
//--------------------------------------------------------------------------------------------
package axi4_test_pkg;

  //-------------------------------------------------------
  // Import uvm package
  //-------------------------------------------------------
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import axi4_globals_pkg::*;
  import axi4_master_pkg::*;
  import axi4_slave_pkg::*;
  import axi4_env_pkg::*;
  import axi4_master_seq_pkg::*;
  import axi4_slave_seq_pkg::*;
  import axi4_virtual_seq_pkg::*;

  //including base_test for testing
  `include "axi4_base_test.sv"
  `include "assertion_base_test.sv"
  `include "axi4_write_test.sv"
  `include "axi4_read_test.sv"
  `include "axi4_write_read_test.sv"
  `include "axi4_blocking_8b_write_data_test.sv"
  `include "axi4_blocking_16b_write_data_test.sv"
  `include "axi4_blocking_32b_write_data_test.sv"
  `include "axi4_blocking_64b_write_data_test.sv"
  `include "axi4_blocking_exokay_response_write_test.sv"
  `include "axi4_blocking_okay_response_write_test.sv"
  `include "axi4_blocking_incr_burst_write_test.sv"
  `include "axi4_blocking_wrap_burst_write_test.sv"
  
  `include "axi4_non_blocking_8b_write_data_test.sv"
  `include "axi4_non_blocking_16b_write_data_test.sv"
  `include "axi4_non_blocking_32b_write_data_test.sv"
  `include "axi4_non_blocking_64b_write_data_test.sv"
  `include "axi4_non_blocking_exokay_write_response_test.sv"
  `include "axi4_non_blocking_okay_write_response_test.sv"
  `include "axi4_non_blocking_incr_burst_write_test.sv"
  `include "axi4_non_blocking_wrap_burst_write_test.sv"
  `include "axi4_blocking_write_read_test.sv"
  `include "axi4_non_blocking_write_read_test.sv"
  `include "axi4_blocking_incr_burst_read_test.sv"
  `include "axi4_blocking_wrap_burst_read_test.sv"
  `include "axi4_blocking_8b_data_read_test.sv"
  `include "axi4_blocking_16b_data_read_test.sv"
  `include "axi4_blocking_32b_data_read_test.sv"
  `include "axi4_blocking_64b_data_read_test.sv"
  `include "axi4_blocking_64b_data_read_test.sv"
  `include "axi4_blocking_okay_response_read_test.sv"
  `include "axi4_blocking_exokay_response_read_test.sv"
  `include "axi4_non_blocking_incr_burst_read_test.sv"
  `include "axi4_non_blocking_wrap_burst_read_test.sv"
  `include "axi4_non_blocking_8b_data_read_test.sv"
  `include "axi4_non_blocking_16b_data_read_test.sv"
  `include "axi4_non_blocking_32b_data_read_test.sv"
  `include "axi4_non_blocking_64b_data_read_test.sv"
  `include "axi4_non_blocking_okay_response_read_test.sv"
  `include "axi4_non_blocking_exokay_response_read_test.sv"
  
  `include "axi4_blocking_8b_write_read_test.sv"
  `include "axi4_blocking_16b_write_read_test.sv"
  `include "axi4_blocking_32b_write_read_test.sv"
  `include "axi4_blocking_64b_write_read_test.sv"
  `include "axi4_blocking_okay_response_write_read_test.sv"
  `include "axi4_blocking_slave_error_write_read_test.sv"
  `include "axi4_blocking_unaligned_addr_write_read_test.sv"
  `include "axi4_blocking_fixed_burst_write_read_test.sv"
  `include "axi4_blocking_outstanding_transfer_write_read_test.sv"
  `include "axi4_blocking_cross_write_read_test.sv"
  
  `include "axi4_non_blocking_8b_write_read_test.sv"
  `include "axi4_non_blocking_16b_write_read_test.sv"
  `include "axi4_non_blocking_32b_write_read_test.sv"
  `include "axi4_non_blocking_64b_write_read_test.sv"
  `include "axi4_blocking_incr_burst_write_read_test.sv"
  `include "axi4_non_blocking_incr_burst_write_read_test.sv"
  `include "axi4_blocking_wrap_burst_write_read_test.sv"
  `include "axi4_non_blocking_wrap_burst_write_read_test.sv"
  `include "axi4_non_blocking_okay_response_write_read_test.sv"
  `include "axi4_non_blocking_fixed_burst_write_read_test.sv"
  `include "axi4_non_blocking_outstanding_transfer_write_read_test.sv"
  `include "axi4_non_blocking_unaligned_addr_write_read_test.sv"
  `include "axi4_non_blocking_cross_write_read_test.sv"
  `include "axi4_non_blocking_slave_error_write_read_test.sv"

  `include "axi4_non_blocking_write_read_rand_test.sv"
  `include "axi4_blocking_write_read_rand_test.sv"

  `include "axi4_non_blocking_slave_mem_mode_wrap_burst_write_read_test.sv"
  `include "axi4_non_blocking_slave_mem_mode_fixed_burst_write_read_test.sv"
  `include "axi4_non_blocking_slave_mem_mode_incr_burst_write_read_test.sv"
  

  `include "axi4_non_blocking_write_read_response_out_of_order_test.sv"
  `include "axi4_non_blocking_only_read_response_out_of_order_test.sv"
  `include "axi4_non_blocking_only_write_response_out_of_order_test.sv"
  `include "axi4_non_blocking_rand_incr_burst_write_test.sv"
  `include "axi4_non_blocking_qos_write_read_test.sv"
  `include "axi4_width_config_test.sv"
  `include "axi4_width_check_test.sv"
  `include "axi4_aw_ready_delay_test.sv"
  `include "axi4_w_ready_delay_test.sv"
  `include "axi4_b_ready_delay_test.sv"
  `include "axi4_ar_ready_delay_test.sv"
  `include "axi4_r_ready_delay_test.sv"
  `include "axi4_aw_w_channel_separation_test.sv"
  `include "axi4_wstrb_all_zero_test.sv"
  `include "axi4_wstrb_all_ones_test.sv"
  `include "axi4_wstrb_upper_half_test.sv"
  `include "axi4_wstrb_lower_half_test.sv"
  `include "axi4_wstrb_alternating_test.sv"
  `include "axi4_wstrb_single_bit_test.sv"
  `include "axi4_wstrb_random_burst_test.sv"
  `include "axi4_wstrb_illegal_test.sv"
endpackage : axi4_test_pkg

`endif
