#!/bin/bash
# Clean up VCS artifacts (already done in Python, but ensure completeness)
# This is a backup cleanup in case Python cleanup missed anything
# Run VCS directly from this folder with adjusted compile file
vcs -full64 -lca -kdb -sverilog +v2k -debug_access+all -ntb_opts uvm-1.2 +ntb_random_seed_automatic -override_timescale=1ps/1ps +nospecify +no_timing_check +define+DUMP_FSDB +define+UVM_VERDI_COMPWAVE -f axi4_compile.f -debug_access+all -R +UVM_TESTNAME=axi4_tc_047_wlast_too_early_test +UVM_VERBOSITY=MEDIUM +plusarg_ignore -l axi4_tc_047_wlast_too_early_test.log
