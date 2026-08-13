`ifndef AXI4_INDEPENDENT_RESET_TEST_INCLUDED_
`define AXI4_INDEPENDENT_RESET_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_independent_reset_test
// Exercises real per-interface reset requests and proves each one completed.
//--------------------------------------------------------------------------------------------
class axi4_independent_reset_test extends axi4_base_test;
  `uvm_component_utils(axi4_independent_reset_test)

  int expected_master_resets[10];
  int expected_slave_resets[10];
  int expected_global_resets;
  // Class scope, not a run_phase local: report_phase renders the verdict.
  int initial_error_count;

  extern function new(string name = "axi4_independent_reset_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern function void setup_axi4_env_cfg();
  extern task wait_for_master_reset(int index, int expected_count);
  extern task wait_for_slave_reset(int index, int expected_count);
  extern task wait_for_global_reset(int expected_count);
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);
endclass : axi4_independent_reset_test

function axi4_independent_reset_test::new(string name = "axi4_independent_reset_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_independent_reset_test::build_phase(uvm_phase phase);
  for(int i = 0; i < 10; i++) begin
    uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("*slave_agent_h[%0d]*", i), "is_active", UVM_PASSIVE);
    uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("*master_agent_h[%0d]*", i), "is_active", UVM_PASSIVE);
  end
  uvm_config_db#(bit)::set(null, "*", "x_inject_enable", 0);
  super.build_phase(phase);
  `uvm_info(get_type_name(), "Build phase completed - Independent Reset Test", UVM_LOW)
endfunction : build_phase

function void axi4_independent_reset_test::setup_axi4_env_cfg();
  super.setup_axi4_env_cfg();
  // This reset-only test has no protocol transactions to score.  Do not use
  // the scoreboard's global end-of-test waiver; the reset checker provides
  // the concrete completion gate for every request below.
  axi4_env_cfg_h.has_scoreboard = 0;
  axi4_env_cfg_h.has_reset_checker = 1;
endfunction : setup_axi4_env_cfg

task axi4_independent_reset_test::wait_for_master_reset(int index, int expected_count);
  time deadline = $time + 500ns;
  while(axi4_env_h.axi4_reset_checker_h.master_reset_count[index] < expected_count && $time < deadline) #1ns;
  if(axi4_env_h.axi4_reset_checker_h.master_reset_count[index] != expected_count)
    `uvm_error(get_type_name(), $sformatf("TIMEOUT: Master[%0d] reset completion %0d was not observed", index, expected_count))
endtask : wait_for_master_reset

task axi4_independent_reset_test::wait_for_slave_reset(int index, int expected_count);
  time deadline = $time + 500ns;
  while(axi4_env_h.axi4_reset_checker_h.slave_reset_count[index] < expected_count && $time < deadline) #1ns;
  if(axi4_env_h.axi4_reset_checker_h.slave_reset_count[index] != expected_count)
    `uvm_error(get_type_name(), $sformatf("TIMEOUT: Slave[%0d] reset completion %0d was not observed", index, expected_count))
endtask : wait_for_slave_reset

task axi4_independent_reset_test::wait_for_global_reset(int expected_count);
  time deadline = $time + 500ns;
  while(axi4_env_h.axi4_reset_checker_h.global_reset_count < expected_count && $time < deadline) #1ns;
  if(axi4_env_h.axi4_reset_checker_h.global_reset_count != expected_count)
    `uvm_error(get_type_name(), $sformatf("TIMEOUT: Global reset completion %0d was not observed", expected_count))
endtask : wait_for_global_reset

task axi4_independent_reset_test::run_phase(uvm_phase phase);
  uvm_report_server svr;

  phase.raise_objection(this);
  svr = uvm_report_server::get_server();
  initial_error_count = svr.get_severity_count(UVM_ERROR);

  if(axi4_env_h.axi4_reset_checker_h == null)
    `uvm_fatal(get_type_name(), "Reset checker was not constructed")

  for(int i = 0; i < 10; i++) begin
    expected_master_resets[i] = 0;
    expected_slave_resets[i] = 0;
  end
  expected_global_resets = 0;

  `uvm_info(get_type_name(), "Phase 1: Initial stabilization", UVM_LOW)
  #20ns;

  `uvm_info(get_type_name(), "Phase 2: Independent master resets", UVM_LOW)
  for(int i = 0; i < axi4_env_cfg_h.no_of_masters; i++) begin
    expected_master_resets[i]++;
    uvm_config_db#(int)::set(null, "*", $sformatf("reset_duration_master_%0d", i), 3);
    uvm_config_db#(bit)::set(null, "*", $sformatf("inject_reset_master_%0d", i), 1);
    wait_for_master_reset(i, expected_master_resets[i]);
  end

  `uvm_info(get_type_name(), "Phase 3: Independent slave resets", UVM_LOW)
  for(int i = 0; i < axi4_env_cfg_h.no_of_slaves; i++) begin
    expected_slave_resets[i]++;
    uvm_config_db#(int)::set(null, "*", $sformatf("reset_duration_slave_%0d", i), 3);
    uvm_config_db#(bit)::set(null, "*", $sformatf("inject_reset_slave_%0d", i), 1);
    wait_for_slave_reset(i, expected_slave_resets[i]);
  end

  `uvm_info(get_type_name(), "Phase 4: Global reset recovery", UVM_LOW)
  expected_global_resets++;
  uvm_config_db#(int)::set(null, "*", "reset_duration_cycles", 3);
  uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);
  wait_for_global_reset(expected_global_resets);

  // Expectation only -- env/axi4_reset_checker.sv:287 runs check_reset_behavior()
  // from its own report_phase.  See the same note in
  // test/axi4_reset_comprehensive_test.sv.
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
function void axi4_independent_reset_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  int final_errors;
  int final_fatals;

  super.report_phase(phase);

  svr          = uvm_report_server::get_server();
  final_errors = svr.get_severity_count(UVM_ERROR);
  final_fatals = svr.get_severity_count(UVM_FATAL);

  if(final_errors == initial_error_count && final_fatals == 0)
    `uvm_info(get_type_name(), "INDEPENDENT RESET TEST: PASSED", UVM_LOW)
  else
    `uvm_error(get_type_name(), $sformatf("INDEPENDENT RESET TEST: FAILED (UVM_ERROR %0d -> %0d, UVM_FATAL %0d)",
                                          initial_error_count, final_errors, final_fatals))
endfunction : report_phase

`endif
