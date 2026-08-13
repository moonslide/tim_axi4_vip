#!/bin/bash
# AXI_ooo.md Phase 2 follow-up (write-side arbiter removal + Gate-1 ref fix)
# verification driver. Same test set as p2_runall.sh plus F2 seeds 1-2.
# Usage: bash p2b_runall.sh <simv> <outdir>
SIMV=${1:-./simv_p2b}
OUT=${2:-p2b}
cd "$(dirname "$0")"
mkdir -p $OUT $OUT/sample $OUT/ooo
run() { # name testname extra_args...
  local nm=$1; shift
  local tn=$1; shift
  $SIMV +UVM_TESTNAME=$tn +UVM_VERBOSITY=UVM_LOW "$@" -l $nm.log > /dev/null 2>&1
  echo "rc=$? $nm" >> $OUT/_rc.txt
}
: > $OUT/_rc.txt

# --- F2 repro, all 5 seeds ----------------------------------------------------
for s in 1 2 3 4 5; do
  run "$OUT/f2_seed$s" axi4_same_id_nonadjacent_reorder_test +ntb_random_seed=$s &
done
run "$OUT/f2_inorder_control_seed1" axi4_same_id_nonadjacent_reorder_test +ntb_random_seed=1 +SAMEID_INORDER_CONTROL &
wait

# --- the OOO/reorder/outstanding tests (AXI_ooo.md F6) ------------------------
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
axi4_qos_bid_queue_race_test"
n=0
for t in $OOO; do
  if [ "$t" = "axi4_qos_bid_queue_race_test" ]; then
    run "$OUT/ooo/$t" $t +BUS_MATRIX_MODE=ENHANCED &
  else
    run "$OUT/ooo/$t" $t &
  fi
  n=$((n+1)); if [ $((n%5)) -eq 0 ]; then wait; fi
done
wait

# --- 28-test baseline regression sample (same list as p1/post_sample, p2/sample)
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

echo ALL_DONE >> $OUT/_rc.txt
