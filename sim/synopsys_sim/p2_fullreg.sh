#!/bin/bash
# Runs every entry of sim/axi4_transfers_regression.list that does NOT carry a
# compile-time `command_add=+define+...` (those need their own VCS build and are
# reported separately), directly against a prebuilt simv. run_cnt is collapsed to
# 1 run per test; the point is coverage of the whole list, not seed volume.
# Usage: bash p2_fullreg.sh <simv> <outdir> [parallel]
SIMV=${1:-./simv_p2}
OUT=${2:-p2/fullreg}
PAR=${3:-12}
cd "$(dirname "$0")"
mkdir -p $OUT
: > $OUT/_rc.txt
: > $OUT/_skipped.txt

LIST=../../sim/axi4_transfers_regression.list
i=0
while read -r line; do
  case "$line" in \#*|"") continue;; esac
  tname=$(echo "$line" | awk '{print $1}')
  cadd=$(echo "$line" | sed -n 's/.*command_add=//p')
  case "$cadd" in
    *+define+*) echo "$tname :: $cadd" >> $OUT/_skipped.txt; continue;;
  esac
  ( $SIMV +UVM_TESTNAME=$tname +UVM_VERBOSITY=UVM_LOW $cadd -l $OUT/$tname.log > /dev/null 2>&1
    rc=$?
    err=$(grep -m1 "UVM_ERROR :" $OUT/$tname.log | tr -dc '0-9')
    fat=$(grep -m1 "UVM_FATAL :" $OUT/$tname.log | tr -dc '0-9')
    res=$(grep -m1 "TEST RESULT" $OUT/$tname.log | grep -o "PASS\|FAIL")
    echo "rc=$rc err=${err:-NA} fatal=${fat:-NA} result=${res:-NA} $tname" >> $OUT/_rc.txt ) &
  i=$((i+1))
  if [ $((i % PAR)) -eq 0 ]; then wait; fi
done < $LIST
wait
echo FULLREG_DONE >> $OUT/_rc.txt
