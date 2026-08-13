#!/bin/bash
# AXI_ooo.md Phase 3 rework: F2 repro (checker at the NEW repo-wide default = ON)
# NOTE: this drives the DIRECTED fail-then-pass pair only (one test, two different
# simv binaries), which axi4_regression.py cannot express. Any MULTI-TEST sample goes
# through LSF: python3 axi4_regression.py --lsf --test-list p3r_sample.list -p 20 -t 1200
# and the fail-side "teeth" leg (identical checker, pre-Phase-2 slave driver).
cd "$(dirname "$0")"
mkdir -p p3r
T=axi4_same_id_nonadjacent_reorder_test
for s in 1 2 3 4 5; do
  ./simv_p3r +UVM_TESTNAME=$T +UVM_VERBOSITY=UVM_LOW +ntb_random_seed=$s -l p3r/f2_seed$s.log >/dev/null 2>&1 &
done
for s in 1 2 3 4 5; do
  ./simv_p3teeth +UVM_TESTNAME=$T +UVM_VERBOSITY=UVM_LOW +ntb_random_seed=$s -l p3r/teeth_seed$s.log >/dev/null 2>&1 &
done
./simv_p3r +UVM_TESTNAME=$T +UVM_VERBOSITY=UVM_LOW +ntb_random_seed=1 +SAMEID_INORDER_CONTROL -l p3r/f2_inorder_control_seed1.log >/dev/null 2>&1 &
./simv_p3r +UVM_TESTNAME=$T +UVM_VERBOSITY=UVM_LOW +ntb_random_seed=1 +SAMEID_NO_ORDER_CHECK -l p3r/f2_nocheck_seed1.log >/dev/null 2>&1 &
wait
echo ALL_DONE
