`ifndef AXI4_VIRTUAL_SEQ_PKG_INCLUDED_
`define AXI4_VIRTUAL_SEQ_PKG_INCLUDED_

//-----------------------------------------------------------------------------------------
// Package: axi4_virtual_seq_pkg
// Description:
// Includes all the files written to run the simulation
//-------------------------------------------------------------------------------------------
package axi4_virtual_seq_pkg;

  //-------------------------------------------------------
  // Import uvm package
  //-------------------------------------------------------
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import axi4_master_pkg::*;
  import axi4_slave_pkg::*; 
  import axi4_master_seq_pkg::*; 
  import axi4_slave_seq_pkg::*; 
  import axi4_env_pkg::*; 
  import axi4_globals_pkg::*;
  import axi4_bus_matrix_pkg::*;
  //-------------------------------------------------------
  // Importing the required packages
  //-------------------------------------------------------
  `include "axi4_virtual_base_seq.sv"
  `include "axi4_virtual_write_seq.sv"
  `include "axi4_virtual_read_seq.sv"
  `include "axi4_virtual_write_read_seq.sv"
  `include "axi4_virtual_bk_8b_write_data_seq.sv"
  `include "axi4_virtual_bk_16b_write_data_seq.sv"
  `include "axi4_virtual_bk_32b_write_data_seq.sv"
  `include "axi4_virtual_bk_64b_write_data_seq.sv"
  `include "axi4_virtual_bk_exokay_response_write_seq.sv"
  `include "axi4_virtual_bk_okay_response_write_seq.sv"
  `include "axi4_virtual_bk_incr_burst_write_seq.sv"
  `include "axi4_virtual_bk_wrap_burst_write_seq.sv"
  `include "axi4_virtual_nbk_8b_write_data_seq.sv"
  `include "axi4_virtual_nbk_16b_write_data_seq.sv"
  `include "axi4_virtual_nbk_32b_write_data_seq.sv"
  `include "axi4_virtual_nbk_64b_write_data_seq.sv"
  `include "axi4_virtual_nbk_exokay_response_write_seq.sv"
  `include "axi4_virtual_nbk_okay_response_write_seq.sv"
  `include "axi4_virtual_nbk_incr_burst_write_seq.sv"
  `include "axi4_virtual_nbk_wrap_burst_write_seq.sv"
  `include "axi4_virtual_bk_write_read_seq.sv"
  `include "axi4_virtual_nbk_write_read_seq.sv"
  `include "axi4_virtual_bk_incr_burst_read_seq.sv"
  `include "axi4_virtual_bk_wrap_burst_read_seq.sv"
  `include "axi4_virtual_bk_okay_response_read_seq.sv"
  `include "axi4_virtual_bk_exokay_response_read_seq.sv"
  `include "axi4_virtual_bk_8b_data_read_seq.sv"
  `include "axi4_virtual_bk_16b_data_read_seq.sv"
  `include "axi4_virtual_bk_32b_data_read_seq.sv"
  `include "axi4_virtual_bk_64b_data_read_seq.sv"
  `include "axi4_virtual_nbk_incr_burst_read_seq.sv"
  `include "axi4_virtual_nbk_wrap_burst_read_seq.sv"
  `include "axi4_virtual_nbk_8b_data_read_seq.sv"
  `include "axi4_virtual_nbk_16b_data_read_seq.sv"
  `include "axi4_virtual_nbk_32b_data_read_seq.sv"
  `include "axi4_virtual_nbk_64b_data_read_seq.sv"
  `include "axi4_virtual_nbk_okay_response_read_seq.sv"
  `include "axi4_virtual_nbk_exokay_response_read_seq.sv"
  
  `include "axi4_virtual_bk_8b_write_read_seq.sv"
  `include "axi4_virtual_bk_16b_write_read_seq.sv"
  `include "axi4_virtual_bk_32b_write_read_seq.sv"
  `include "axi4_virtual_bk_64b_write_read_seq.sv"
  `include "axi4_virtual_bk_okay_response_write_read_seq.sv"
  `include "axi4_virtual_bk_write_read_rand_seq.sv"
  `include "axi4_virtual_bk_slave_error_write_read_seq.sv"
  `include "axi4_virtual_bk_unaligned_addr_write_read_seq.sv"
  `include "axi4_virtual_bk_fixed_burst_write_read_seq.sv"
  `include "axi4_virtual_bk_outstanding_transfer_write_read_seq.sv"
  `include "axi4_virtual_bk_cross_write_read_seq.sv"
  
  `include "axi4_virtual_nbk_8b_write_read_seq.sv"
  `include "axi4_virtual_nbk_16b_write_read_seq.sv"
  `include "axi4_virtual_nbk_32b_write_read_seq.sv"
  `include "axi4_virtual_nbk_64b_write_read_seq.sv"
  `include "axi4_virtual_bk_incr_burst_write_read_seq.sv"
  `include "axi4_virtual_nbk_incr_burst_write_read_seq.sv"
  `include "axi4_virtual_bk_wrap_burst_write_read_seq.sv"
  `include "axi4_virtual_nbk_wrap_burst_write_read_seq.sv"
  `include "axi4_virtual_nbk_fixed_burst_write_read_seq.sv"
  `include "axi4_virtual_nbk_outstanding_transfer_write_read_seq.sv"
  `include "axi4_virtual_nbk_unaligned_addr_write_read_seq.sv"
  `include "axi4_virtual_nbk_cross_write_read_seq.sv"
  `include "axi4_virtual_nbk_slave_error_write_read_seq.sv"
  
  `include "axi4_virtual_nbk_okay_response_write_read_seq.sv"

  `include "axi4_virtual_nbk_write_read_rand_seq.sv"

  `include "axi4_virtual_nbk_slave_mem_mode_wrap_burst_write_read_seq.sv"
  `include "axi4_virtual_nbk_slave_mem_mode_fixed_burst_write_read_seq.sv"
  `include "axi4_virtual_nbk_slave_mem_mode_incr_burst_write_read_seq.sv"



  `include "axi4_virtual_nbk_only_write_response_out_of_order_seq.sv"
  `include "axi4_virtual_nbk_only_read_response_out_of_order_seq.sv"
  `include "axi4_virtual_nbk_write_read_response_out_of_order_seq.sv"

  `include "axi4_virtual_nbk_qos_write_read_seq.sv"
  `include "axi4_virtual_nbk_rand_incr_burst_write_seq.sv"
  `include "axi4_virtual_aw_ready_delay_seq.sv"
  `include "axi4_virtual_w_ready_delay_seq.sv"
  `include "axi4_virtual_b_ready_delay_seq.sv"
  `include "axi4_virtual_ar_ready_delay_seq.sv"
  `include "axi4_virtual_r_ready_delay_seq.sv"
  `include "axi4_virtual_wstrb_seq.sv"
  `include "axi4_virtual_illegal_wstrb_seq.sv"
  `include "axi4_virtual_aw_w_channel_separation_seq.sv"
  `include "axi4_virtual_all_master_slave_access_seq.sv"
  `include "axi4_virtual_upper_boundary_write_seq.sv"
  `include "axi4_virtual_lower_boundary_write_seq.sv"
  `include "axi4_virtual_upper_boundary_read_seq.sv"
  `include "axi4_virtual_lower_boundary_read_seq.sv"
  `include "axi4_virtual_4k_boundary_cross_seq.sv"
  
  // TC_046~TC_058: AXI4 ID Management and Protocol Violation Virtual Sequences
  `include "axi4_virtual_tc_046_id_multiple_writes_same_awid_seq.sv"
  `include "axi4_virtual_tc_047_id_multiple_writes_different_awid_seq.sv"
  `include "axi4_virtual_tc_048_id_multiple_reads_same_arid_seq.sv"
  `include "axi4_virtual_tc_049_id_multiple_reads_different_arid_seq.sv"
  `include "axi4_virtual_tc_050_wid_awid_mismatch_seq.sv"
  `include "axi4_virtual_tc_051_wlast_too_early_seq.sv"
  `include "axi4_virtual_tc_052_wlast_too_late_seq.sv"
  `include "axi4_virtual_tc_053_awlen_out_of_spec_seq.sv"
  `include "axi4_virtual_tc_054_arlen_out_of_spec_seq.sv"
  `include "axi4_virtual_tc_055_exclusive_write_success_seq.sv"
  `include "axi4_virtual_tc_056_exclusive_write_fail_seq.sv"
  `include "axi4_virtual_tc_057_exclusive_read_success_seq.sv"
  `include "axi4_virtual_tc_058_exclusive_read_fail_seq.sv"

  // Claude.md Test Case Virtual Sequences
  `include "axi4_tc_001_concurrent_reads_virtual_seq.sv"
  `include "axi4_tc_002_concurrent_writes_raw_virtual_seq.sv"
  `include "axi4_tc_003_sequential_mixed_ops_virtual_seq.sv"
  `include "axi4_tc_004_concurrent_error_stress_virtual_seq.sv"
  `include "axi4_tc_005_exhaustive_random_reads_virtual_seq.sv"
  `include "axi4_enhanced_bus_matrix_virtual_seq.sv"
  
  // QoS and USER Signal Virtual Sequences
  `include "axi4_virtual_qos_basic_priority_test_seq.sv"
  `include "axi4_virtual_qos_equal_priority_fairness_seq.sv"
  `include "axi4_virtual_qos_saturation_stress_seq.sv"
  `include "axi4_virtual_qos_starvation_prevention_seq.sv"
  `include "axi4_virtual_user_signal_passthrough_seq.sv"
  `include "axi4_virtual_user_signal_width_mismatch_seq.sv"
  `include "axi4_virtual_user_parity_protection_seq.sv"
  `include "axi4_virtual_user_security_tagging_seq.sv"
  `include "axi4_virtual_user_transaction_tracing_seq.sv"
  `include "axi4_virtual_user_signal_protocol_violation_seq.sv"
  `include "axi4_virtual_user_signal_corruption_seq.sv"
  `include "axi4_virtual_qos_with_user_priority_boost_seq.sv"
  `include "axi4_virtual_user_based_qos_routing_seq.sv"

endpackage : axi4_virtual_seq_pkg

`endif

