#!/bin/bash
# Summarise a p4 run directory: per-log UVM verdict + the achieved outstanding
# depth (max over ALL master agents, not just agent 0) + any W-order violation.
cd "$(dirname "$0")"
DIR=${1:-p4}
for f in $(ls $DIR/qos/*.log $DIR/sample/*.log $DIR/ooo/*.log 2>/dev/null); do
  e=$(grep -m1 "^UVM_ERROR :"  $f | awk '{print $3}')
  ft=$(grep -m1 "^UVM_FATAL :" $f | awk '{print $3}')
  pass=$(grep -c "TEST RESULT: PASS" $f)
  ord=$(grep -c "out of AW order" $f)
  # max over all agents of w_resp / r_data in-flight
  wm=$(grep -o "w_resp=[0-9]*" $f | cut -d= -f2 | sort -n | tail -1)
  rm=$(grep -o "r_data=[0-9]*" $f | cut -d= -f2 | sort -n | tail -1)
  dep=$(grep -m1 -o "depth(w/r)=[0-9]*/[0-9]*" $f | cut -d= -f2)
  printf "%-62s err=%-4s fatal=%-4s pass=%-2s aworder=%-2s depth=%-6s achieved(w/r)=%s/%s\n" \
         "$(basename $f .log)" "${e:-NA}" "${ft:-NA}" "$pass" "$ord" "${dep:-NA}" "${wm:-NA}" "${rm:-NA}"
done
