`ifndef AXI4_MASTER_SEQ_PKG_INCLUDED_
`define AXI4_MASTER_SEQ_PKG_INCLUDED_

//-----------------------------------------------------------------------------------------
// Package: axi4_master_seq_pkg
// Description:
// Includes all the files written to run the simulation
//-------------------------------------------------------------------------------------------
package axi4_master_seq_pkg;

  //-------------------------------------------------------
  // Import uvm package
  //-------------------------------------------------------
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import axi4_master_pkg::*;
  import axi4_globals_pkg::*;
  import axi4_bus_matrix_pkg::*;

  //-------------------------------------------------------
  // Importing the required packages
  //-------------------------------------------------------
  `include "axi4_master_base_seq.sv"
  `include "axi4_master_bk_base_seq.sv"
  `include "axi4_master_nbk_base_seq.sv"
  `include "axi4_master_write_seq.sv"
  `include "axi4_master_read_seq.sv"
  `include "axi4_master_bk_write_seq.sv"
  `include "axi4_master_bk_write_constrained_seq.sv"
  `include "axi4_master_bk_read_seq.sv"
  `include "axi4_master_bk_read_constrained_seq.sv"
  `include "axi4_master_targeted_write_seq.sv"
  `include "axi4_master_targeted_read_seq.sv"
  `include "axi4_master_nbk_write_seq.sv"
  `include "axi4_master_nbk_read_seq.sv"
  `include "axi4_master_bk_write_8b_transfer_seq.sv"
  `include "axi4_master_bk_write_16b_transfer_seq.sv"
  `include "axi4_master_bk_write_32b_transfer_seq.sv"
  `include "axi4_master_bk_write_64b_transfer_seq.sv"
  `include "axi4_master_bk_write_incr_burst_seq.sv"
  `include "axi4_master_bk_write_wrap_burst_seq.sv"
  `include "axi4_master_bk_write_okay_resp_seq.sv"
  `include "axi4_master_bk_write_exokay_resp_seq.sv"
  `include "axi4_master_bk_write_rand_seq.sv"
  `include "axi4_master_bk_write_slave_error_seq.sv"
  `include "axi4_master_bk_write_unaligned_addr_seq.sv"
  `include "axi4_master_bk_write_fixed_burst_seq.sv"
  `include "axi4_master_bk_write_outstanding_transfer_seq.sv"
  `include "axi4_master_bk_write_cross_seq.sv"

  `include "axi4_master_nbk_write_8b_transfer_seq.sv"
  `include "axi4_master_nbk_write_16b_transfer_seq.sv"
  `include "axi4_master_nbk_write_32b_transfer_seq.sv"
  `include "axi4_master_nbk_write_64b_transfer_seq.sv"
  `include "axi4_master_nbk_write_incr_burst_seq.sv"
  `include "axi4_master_nbk_write_wrap_burst_seq.sv"
  `include "axi4_master_nbk_write_fixed_burst_seq.sv"
  `include "axi4_master_nbk_write_okay_resp_seq.sv"
  `include "axi4_master_nbk_write_exokay_resp_seq.sv"
  `include "axi4_master_nbk_write_outstanding_transfer_seq.sv"
  `include "axi4_master_nbk_write_unaligned_addr_seq.sv"
  `include "axi4_master_nbk_write_cross_seq.sv"
  `include "axi4_master_nbk_write_slave_error_seq.sv"
  `include "axi4_master_nbk_write_rand_seq.sv"
  `include "axi4_master_nbk_rand_write_incr_burst_seq.sv"
  `include "axi4_master_aw_ready_delay_seq.sv"
  `include "axi4_master_w_ready_delay_seq.sv"
  `include "axi4_master_b_ready_delay_seq.sv"
  `include "axi4_master_wstrb_baseline_seq.sv"
  `include "axi4_master_wstrb_seq.sv"
  `include "axi4_master_illegal_wstrb_seq.sv"
  `include "axi4_master_wstrb_read_seq.sv"
  `include "axi4_master_ar_ready_delay_seq.sv"
  `include "axi4_master_r_ready_delay_seq.sv"
  `include "axi4_master_aw_w_channel_separation_seq.sv"
  `include "axi4_master_bk_read_incr_burst_seq.sv"
  `include "axi4_master_bk_read_wrap_burst_seq.sv"
  `include "axi4_master_bk_read_8b_transfer_seq.sv"
  `include "axi4_master_bk_read_16b_transfer_seq.sv"
  `include "axi4_master_bk_read_32b_transfer_seq.sv"
  `include "axi4_master_bk_read_64b_transfer_seq.sv"
  `include "axi4_master_bk_read_okay_resp_seq.sv"
  `include "axi4_master_bk_read_ex_okay_resp_seq.sv"
  `include "axi4_master_bk_read_rand_seq.sv"
  `include "axi4_master_bk_read_slave_error_seq.sv"
  `include "axi4_master_bk_read_unaligned_addr_seq.sv"
  `include "axi4_master_bk_read_fixed_burst_seq.sv"
  `include "axi4_master_bk_read_outstanding_transfer_seq.sv"
  `include "axi4_master_bk_read_cross_seq.sv"

  `include "axi4_master_nbk_read_incr_burst_seq.sv"
  `include "axi4_master_nbk_read_wrap_burst_seq.sv"
  `include "axi4_master_nbk_read_fixed_burst_seq.sv"
  `include "axi4_master_nbk_read_8b_transfer_seq.sv"
  `include "axi4_master_nbk_read_16b_transfer_seq.sv"
  `include "axi4_master_nbk_read_32b_transfer_seq.sv"
  `include "axi4_master_nbk_read_64b_transfer_seq.sv"
  `include "axi4_master_nbk_read_okay_resp_seq.sv"
  `include "axi4_master_nbk_read_ex_okay_resp_seq.sv"
  `include "axi4_master_nbk_read_outstanding_transfer_seq.sv"
  `include "axi4_master_nbk_read_unaligned_addr_seq.sv"
  `include "axi4_master_nbk_read_cross_seq.sv"
  `include "axi4_master_nbk_read_slave_error_seq.sv"
  `include "axi4_master_nbk_read_rand_seq.sv"

  `include "axi4_master_nbk_slave_mem_mode_write_fixed_burst_seq.sv"
  `include "axi4_master_nbk_slave_mem_mode_write_incr_burst_seq.sv"
  `include "axi4_master_nbk_slave_mem_mode_write_wrap_burst_seq.sv"
  `include "axi4_master_nbk_slave_mem_mode_read_fixed_burst_seq.sv"
  `include "axi4_master_nbk_slave_mem_mode_read_incr_burst_seq.sv"
  `include "axi4_master_nbk_slave_mem_mode_read_wrap_burst_seq.sv"
 


  `include "axi4_master_write_nbk_write_read_response_out_of_order_seq.sv"
  `include "axi4_master_read_nbk_write_read_response_out_of_order_seq.sv"

  `include "axi4_master_write_nbk_only_write_response_out_of_order_seq.sv"
  `include "axi4_master_write_nbk_only_read_response_out_of_order_seq.sv"
  `include "axi4_master_read_nbk_only_write_response_out_of_order_seq.sv"
  `include "axi4_master_read_nbk_only_read_response_out_of_order_seq.sv"
  
  `include "axi4_master_nbk_write_qos_seq.sv"
  `include "axi4_master_nbk_read_qos_seq.sv"
  `include "axi4_master_nbk_targeted_write_qos_seq.sv"
  `include "axi4_master_nbk_targeted_read_qos_seq.sv"
  `include "axi4_master_all_slave_access_seq.sv"
  `include "axi4_master_upper_boundary_write_seq.sv"
  `include "axi4_master_lower_boundary_write_seq.sv"
  `include "axi4_master_upper_boundary_read_seq.sv"
  `include "axi4_master_lower_boundary_read_seq.sv"
  `include "axi4_master_4k_boundary_cross_seq.sv"
  
  // ID_MULTIPLE_WRITES_SAME_AWID~TC_058: AXI4 ID Management and Protocol Violation Test Sequences
  `include "axi4_master_id_multiple_writes_same_awid_seq.sv"
  `include "axi4_master_id_multiple_writes_different_awid_seq.sv"
  `include "axi4_master_id_multiple_reads_same_arid_seq.sv"
  `include "axi4_master_id_multiple_reads_same_arid_write_setup_seq.sv"
  `include "axi4_master_id_multiple_reads_same_arid_read_test_seq.sv"
  `include "axi4_master_id_multiple_reads_different_arid_seq.sv"
  `include "axi4_master_id_multiple_reads_different_arid_write_setup_seq.sv"
  `include "axi4_master_id_multiple_reads_different_arid_read_test_seq.sv"
  `include "axi4_master_wid_awid_mismatch_seq.sv"
  `include "axi4_master_wlast_too_early_seq.sv"
  `include "axi4_master_wlast_too_late_seq.sv"
  `include "axi4_master_awlen_out_of_spec_seq.sv"
  `include "axi4_master_arlen_out_of_spec_seq.sv"
  `include "axi4_master_exclusive_write_success_seq.sv"
  `include "axi4_master_exclusive_write_fail_seq.sv"
  `include "axi4_master_exclusive_read_success_seq.sv"
  `include "axi4_master_exclusive_read_fail_seq.sv"
  
  // Claude.md Test Case Sequences
  `include "axi4_concurrent_reads_master_sequences.sv"
  `include "axi4_concurrent_writes_raw_master_sequences.sv"
  
  // QoS and USER Signal Test Sequences
  // Existing QoS/USER sequences
  `include "axi4_master_qos_read_only_seq.sv"
  `include "axi4_master_qos_write_only_seq.sv"
  `include "axi4_master_user_based_qos_routing_seq.sv"
  
  // QoS Priority Test Sequences
  `include "axi4_master_qos_priority_write_seq.sv"
  `include "axi4_master_qos_priority_read_seq.sv"
  
  // TODO: Future QoS/USER sequences to be implemented
  // `include "axi4_master_qos_basic_priority_order_seq.sv"
  // `include "axi4_master_qos_equal_priority_fairness_seq.sv"
  // `include "axi4_master_qos_saturation_stress_seq.sv"
  // `include "axi4_master_qos_starvation_prevention_seq.sv"
  `include "axi4_master_user_signal_passthrough_seq.sv"
  `include "axi4_master_user_width_mismatch_seq.sv"
  `include "axi4_master_user_parity_seq.sv"
  `include "axi4_master_user_security_tagging_seq.sv"
  `include "axi4_master_user_transaction_tracing_seq.sv"
  `include "axi4_master_user_protocol_violation_seq.sv"
  `include "axi4_master_user_signal_corruption_seq.sv"
  `include "axi4_master_qos_user_boost_write_seq.sv"
  
  // Reset sequences
  `include "axi4_master_reset_smoke_seq.sv"
  `include "axi4_master_midburst_reset_read_seq.sv"
  `include "axi4_master_midburst_reset_write_seq.sv"
  `include "axi4_master_reset_injection_base.sv"
  
  // Stress test sequences from markdown
  `include "axi4_master_all_to_all_saturation_seq.sv"
  `include "axi4_master_hotspot_many_to_one_seq.sv"
  `include "axi4_master_one_to_many_fanout_seq.sv"
  `include "axi4_master_mixed_burst_lengths_seq.sv"
  `include "axi4_master_4kb_boundary_seq.sv"
  `include "axi4_master_max_outstanding_seq.sv"
  `include "axi4_master_qos_arbitration_seq.sv"
  `include "axi4_master_region_routing_seq.sv"
  `include "axi4_master_read_reorder_seq.sv"
  `include "axi4_master_read_write_contention_seq.sv"

  // Error injection and exception handling sequences  
  `include "axi4_master_x_inject_seq.sv"
  `include "axi4_master_x_inject_active_seq.sv"
  
  // Slave injection test sequences
  `include "axi4_master_slave_inject_write_seq.sv"
  `include "axi4_master_slave_inject_read_seq.sv"
  `include "axi4_master_x_inject_random_seq.sv"
  `include "axi4_master_exception_seq.sv"
  `include "axi4_master_exception_random_seq.sv"
  `include "axi4_master_exception_multi_abort_seq.sv"
  `include "axi4_master_near_timeout_seq.sv"
  
  // Clock and reset exception sequences
  `include "axi4_master_exception_clk_freq_seq.sv"
  `include "axi4_master_exception_reset_terminate_seq.sv"

endpackage : axi4_master_seq_pkg

`endif

