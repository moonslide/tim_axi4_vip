#!/bin/bash
# Directed smoke test for the NIC-400 fabric + axi4_nic400_fabric_wrapper.
# Proves the Track-B wiring carries a transaction end to end:
#   CASE1 unmapped address -> DECERR from the fabric's default slave
#   CASE2 S0 base address  -> routed to egress 0, OKAY returned to ingress 0
# Run from sim/synopsys_sim/ :   bash ../run_fabric_smoke.sh
#
# codex_review.md Finding 7: the old last line here was one grep for
# "\[PASS\]|\[FAIL\]|FABRIC SMOKE", which matches success AND failure text
# alike -- grep exits 0 on ANY match, so a functional mismatch or the
# in-sim global timeout was reported as shell success. This script now
# gates its own exit status explicitly on log content (PASS banner present
# AND no FAIL/timeout text) and on the simulator's own exit status
# (tb_fabric_smoke.sv now $fatal's on the failure/timeout paths instead of
# a plain $finish, giving a non-zero sim_status as defense in depth -- but
# the content check below is the actual gate, not sim_status alone).
set -e
OUT=${1:-./fabric_smoke_work}
mkdir -p "$OUT"
vcs -full64 -sverilog +v2k -override_timescale=1ps/1ps +nospecify +no_timing_check \
    -f ../../sim/nic400_rtl.f \
    ../../top/axi4_nic400_fabric_wrapper.sv \
    ../../top/tb_fabric_smoke.sv \
    -top tb_fabric_smoke -Mdir="$OUT/csrc" -l "$OUT/vcs.log" -o "$OUT/simv"

set +e
"$OUT/simv" -l "$OUT/run.log"
sim_status=$?
set -e

# Keep the human-readable dump for anyone reading CI output.
grep -E "\[PASS\]|\[FAIL\]|FABRIC SMOKE" "$OUT/run.log" || true

if [ "$sim_status" -eq 0 ] \
   && grep -q "FABRIC SMOKE TEST PASSED (3/3)" "$OUT/run.log" \
   && ! grep -qE "\[FAIL\]|FABRIC SMOKE TEST FAILED|global timeout" "$OUT/run.log"; then
  echo "run_fabric_smoke: PASS"
  exit 0
fi

echo "run_fabric_smoke: FAIL (sim_status=$sim_status, see $OUT/run.log)"
exit 1
