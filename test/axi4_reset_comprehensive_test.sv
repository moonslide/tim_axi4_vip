`ifndef AXI4_RESET_COMPREHENSIVE_TEST_INCLUDED_
`define AXI4_RESET_COMPREHENSIVE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_reset_comprehensive_test
// Verifies reset assertions around real idle and repeated reset pulses.
//--------------------------------------------------------------------------------------------
class axi4_reset_comprehensive_test extends axi4_base_test;
  `uvm_component_utils(axi4_reset_comprehensive_test)

  int expected_master_resets[10];
  int expected_slave_resets[10];
  int expected_global_resets;
  int pre_test_errors;

  extern function new(string name = "axi4_reset_comprehensive_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern function void setup_axi4_env_cfg();
  extern task wait_for_master_reset(int index, int expected_count);
  extern task wait_for_global_reset(int expected_count);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);
endclass : axi4_reset_comprehensive_test

function axi4_reset_comprehensive_test::new(string name = "axi4_reset_comprehensive_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_reset_comprehensive_test::build_phase(uvm_phase phase);
  for(int i = 0; i < 10; i++) begin
    uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("*master_agent_h[%0d]*", i), "is_active", (i == 0) ? UVM_ACTIVE : UVM_PASSIVE);
    uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("*slave_agent_h[%0d]*", i), "is_active", UVM_PASSIVE);
  end
  uvm_config_db#(bit)::set(null, "*", "x_inject_enable", 0);
  uvm_config_db#(bit)::set(null, "*", "enable_assertion_checks", 1);
  uvm_config_db#(bit)::set(null, "*", "disable_timeout_checks", 0);
  super.build_phase(phase);
  `uvm_info(get_type_name(), "Build phase completed - Comprehensive Reset Test", UVM_LOW)
endfunction : build_phase

function void axi4_reset_comprehensive_test::setup_axi4_env_cfg();
  super.setup_axi4_env_cfg();
  axi4_env_cfg_h.write_read_mode_h = ONLY_WRITE_DATA;
  // No slave responder is started in this reset-focused test, so do not
  // instantiate a transaction scoreboard.  Reset completion remains checked.
  axi4_env_cfg_h.has_scoreboard = 0;
  axi4_env_cfg_h.has_reset_checker = 1;
endfunction : setup_axi4_env_cfg

task axi4_reset_comprehensive_test::wait_for_master_reset(int index, int expected_count);
  time deadline = $time + 500ns;
  while(axi4_env_h.axi4_reset_checker_h.master_reset_count[index] < expected_count && $time < deadline) #1ns;
  if(axi4_env_h.axi4_reset_checker_h.master_reset_count[index] != expected_count)
    `uvm_error(get_type_name(), $sformatf("TIMEOUT: Master[%0d] reset completion %0d was not observed", index, expected_count))
endtask : wait_for_master_reset

task axi4_reset_comprehensive_test::wait_for_global_reset(int expected_count);
  time deadline = $time + 500ns;
  while(axi4_env_h.axi4_reset_checker_h.global_reset_count < expected_count && $time < deadline) #1ns;
  if(axi4_env_h.axi4_reset_checker_h.global_reset_count != expected_count)
    `uvm_error(get_type_name(), $sformatf("TIMEOUT: Global reset completion %0d was not observed", expected_count))
endtask : wait_for_global_reset

task axi4_reset_comprehensive_test::run_phase(uvm_phase phase);
  uvm_report_server svr;
  axi4_master_write_seq write_seq;

  phase.raise_objection(this);
  svr = uvm_report_server::get_server();
  pre_test_errors = svr.get_severity_count(UVM_ERROR);
  if(axi4_env_h.axi4_reset_checker_h == null)
    `uvm_fatal(get_type_name(), "Reset checker was not constructed")

  for(int i = 0; i < 10; i++) begin
    expected_master_resets[i] = 0;
    expected_slave_resets[i] = 0;
  end
  expected_global_resets = 0;

  `uvm_info(get_type_name(), "Scenario 1: Normal transaction before reset", UVM_LOW)
  if(axi4_env_cfg_h.bus_matrix_mode == axi4_bus_matrix_ref::NONE &&
     axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h != null) begin
    write_seq = axi4_master_write_seq::type_id::create("pre_reset_write_seq");
    write_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
  end

  `uvm_info(get_type_name(), "Scenario 2: Reset during idle", UVM_LOW)
  expected_master_resets[0]++;
  uvm_config_db#(int)::set(null, "*", "reset_duration_master_0", 3);
  uvm_config_db#(bit)::set(null, "*", "inject_reset_master_0", 1);
  wait_for_master_reset(0, expected_master_resets[0]);

  `uvm_info(get_type_name(), "Scenario 3: Three completed global reset cycles", UVM_LOW)
  repeat(3) begin
    expected_global_resets++;
    uvm_config_db#(int)::set(null, "*", "reset_duration_cycles", 2);
    uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);
    wait_for_global_reset(expected_global_resets);
  end

  `uvm_info(get_type_name(), "Scenario 4: Post-reset transaction", UVM_LOW)
  if(axi4_env_cfg_h.bus_matrix_mode == axi4_bus_matrix_ref::NONE &&
     axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h != null) begin
    write_seq = axi4_master_write_seq::type_id::create("post_reset_write_seq");
    write_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
  end

  // Publish the expectation only.  Do NOT call check_reset_behavior() here:
  // env/axi4_reset_checker.sv:287 already calls it unconditionally from its own
  // report_phase, so a second call made one miscount print twice and raise two
  // UVM_ERRORs, leaving a log whose error tally is double the number of real
  // defects.  The checker owns the verdict on reset counts; this test owns the
  // expectation.
  axi4_env_h.axi4_reset_checker_h.set_expected_resets(expected_master_resets,
                                                        expected_slave_resets,
                                                        expected_global_resets);

  phase.drop_objection(this);
endtask : run_phase

//--------------------------------------------------------------------------------------------
// Function: report_phase
// The verdict MUST live here, not at the end of run_phase.  Components that
// check in a later phase raise their errors after run_phase has ended --
// axi4_reset_checker::report_phase re-runs check_reset_behavior() and
// axi4_performance_metrics::report_phase can raise "TEST RESULT: FAIL".  A
// run_phase verdict cannot see any of them, and cannot see UVM_FATAL at all,
// so it prints PASSED into a log whose UVM summary reports errors.
//--------------------------------------------------------------------------------------------
function void axi4_reset_comprehensive_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  int final_errors;
  int final_fatals;

  super.report_phase(phase);

  svr          = uvm_report_server::get_server();
  final_errors = svr.get_severity_count(UVM_ERROR);
  final_fatals = svr.get_severity_count(UVM_FATAL);

  if(final_errors == pre_test_errors && final_fatals == 0)
    `uvm_info(get_type_name(), "COMPREHENSIVE RESET TEST PASSED", UVM_LOW)
  else
    `uvm_error(get_type_name(), $sformatf("COMPREHENSIVE RESET TEST FAILED (UVM_ERROR %0d -> %0d, UVM_FATAL %0d)",
                                          pre_test_errors, final_errors, final_fatals))
endfunction : report_phase

`endif
