#!/bin/bash
# AXI_ooo.md Phase 4 / P4.1-P4.3 verification driver.
#   P4.3  - the 9 tests that set outstanding_write_tx / outstanding_read_tx, in
#           all three bus-matrix modes: their depth changes from the silent 1 they
#           have always run at to what they asked for.
#   sample- the same 28-test baseline regression sample p1/p2/p2b/p3d used, so the
#           "tests that do NOT set the knob are unaffected" claim is measured, not
#           asserted.
# Usage: bash p4_runall.sh <simv> <outdir> [extra plusargs...]
SIMV=${1:-./simv_p4}
OUT=${2:-p4}
# `shift 2` FAILS and shifts NOTHING when fewer than two arguments were given,
# so with a 1-arg call (legal here: both SIMV and OUT have defaults) EXTRA
# became the simv path itself and was then passed to simv as a bogus plusarg on
# every run. Verified: `set -- ./simv_p4; shift 2 2>/dev/null; echo "[$*]"`
# prints `[./simv_p4]`.
[ $# -ge 2 ] && shift 2 || shift $#
EXTRA="$@"
cd "$(dirname "$0")"
mkdir -p $OUT $OUT/sample $OUT/qos
run() { # name testname extra_args...
  local nm=$1; shift
  local tn=$1; shift
  $SIMV +UVM_TESTNAME=$tn +UVM_VERBOSITY=UVM_LOW $EXTRA "$@" -l $nm.log > /dev/null 2>&1
  echo "rc=$? $nm" >> $OUT/_rc.txt
}
: > $OUT/_rc.txt

# --- P4.3: the outstanding-knob family, all three modes -----------------------
KNOB="axi4_qos_saturation_stress_test
axi4_qos_starvation_prevention_test
axi4_qos_with_user_priority_boost_test
axi4_user_based_qos_routing_test
axi4_user_parity_protection_test
axi4_user_signal_passthrough_test
axi4_user_security_tagging_test
axi4_user_signal_protocol_violation_test
axi4_user_signal_width_mismatch_test"
n=0
for t in $KNOB; do
  for m in NONE 4x4 ENHANCED; do
    run "$OUT/qos/${t}_${m}" $t +BUS_MATRIX_MODE=$m &
    n=$((n+1)); if [ $((n%6)) -eq 0 ]; then wait; fi
  done
done
wait

# --- 28-test baseline regression sample (identical list to p1/p2/p2b/p3d) -----
S=$OUT/sample
run $S/axi4_arlen_out_of_spec_test               axi4_arlen_out_of_spec_test &
run $S/axi4_basic_reset_test                     axi4_basic_reset_test &
run $S/axi4_blocking_cross_write_read_test       axi4_blocking_cross_write_read_test &
run $S/axi4_blocking_outstanding_transfer_write_read_test axi4_blocking_outstanding_transfer_write_read_test &
run $S/axi4_blocking_slave_error_write_read_test axi4_blocking_slave_error_write_read_test &
wait
run $S/axi4_blocking_unaligned_addr_write_read_test axi4_blocking_unaligned_addr_write_read_test &
run $S/axi4_blocking_write_read_test             axi4_blocking_write_read_test &
run $S/axi4_error_inject_arvalid_x_test          axi4_error_inject_arvalid_x_test &
run $S/axi4_error_inject_awvalid_x_test          axi4_error_inject_awvalid_x_test &
run $S/axi4_error_inject_x_drive_test            axi4_error_inject_x_drive_test &
wait
run $S/axi4_id_multiple_writes_different_awid_test axi4_id_multiple_writes_different_awid_test &
run $S/axi4_independent_reset_test               axi4_independent_reset_test &
run $S/axi4_non_blocking_slave_error_write_read_test axi4_non_blocking_slave_error_write_read_test &
run $S/axi4_non_blocking_write_read_test         axi4_non_blocking_write_read_test &
run $S/axi4_non_blocking_write_read_response_out_of_order_test axi4_non_blocking_write_read_response_out_of_order_test &
wait
run $S/axi4_non_blocking_qos_write_read_test_ENHANCED axi4_non_blocking_qos_write_read_test +BUS_MATRIX_MODE=ENHANCED &
run $S/axi4_qos_basic_priority_test_4x4          axi4_qos_basic_priority_test +BUS_MATRIX_MODE=4x4 &
run $S/axi4_qos_basic_priority_test_ENHANCED     axi4_qos_basic_priority_test +BUS_MATRIX_MODE=ENHANCED &
run $S/axi4_qos_equal_priority_fairness_test_ENHANCED axi4_qos_equal_priority_fairness_test +BUS_MATRIX_MODE=ENHANCED &
run $S/axi4_qos_saturation_stress_test_ENHANCED  axi4_qos_saturation_stress_test +BUS_MATRIX_MODE=ENHANCED &
wait
run $S/axi4_qos_starvation_prevention_test_ENHANCED axi4_qos_starvation_prevention_test +BUS_MATRIX_MODE=ENHANCED &
run $S/axi4_qos_with_user_priority_boost_test_ENHANCED axi4_qos_with_user_priority_boost_test +BUS_MATRIX_MODE=ENHANCED &
run $S/axi4_saturation_midburst_reset_qos_boundary_test axi4_saturation_midburst_reset_qos_boundary_test &
run $S/axi4_slave_inject_rvalid_x_test           axi4_slave_inject_rvalid_x_test &
run $S/axi4_stress_reset_test_NONE               axi4_stress_reset_test +BUS_MATRIX_MODE=NONE &
wait
run $S/axi4_stress_reset_test_4x4                axi4_stress_reset_test +BUS_MATRIX_MODE=4x4 &
run $S/axi4_stress_reset_test_ENHANCED           axi4_stress_reset_test +BUS_MATRIX_MODE=ENHANCED &
run $S/axi4_write_heavy_midburst_reset_rw_contention_test axi4_write_heavy_midburst_reset_rw_contention_test &
wait

# --- the OOO/reorder/outstanding family (unchanged expectation) ---------------
mkdir -p $OUT/ooo
OOO="axi4_cross_id_read_reorder_test
axi4_cross_id_write_reorder_test
axi4_non_blocking_only_read_response_out_of_order_test
axi4_non_blocking_only_write_response_out_of_order_test
axi4_non_blocking_write_read_response_out_of_order_test
axi4_blocking_outstanding_transfer_write_read_test
axi4_non_blocking_outstanding_transfer_write_read_test
axi4_id_multiple_reads_different_arid_test
axi4_id_multiple_writes_different_awid_test
axi4_write_resp_ooo_empty_queue_test
axi4_same_id_nonadjacent_reorder_test"
n=0
for t in $OOO; do
  run "$OUT/ooo/$t" $t &
  n=$((n+1)); if [ $((n%6)) -eq 0 ]; then wait; fi
done
wait

echo ALL_DONE >> $OUT/_rc.txt
