#!/bin/bash
echo "=== FINAL ULTRATHINK VERIFICATION ==="
echo ""
echo "Testing all modes after scoreboard fix..."
echo ""

modes=("NONE" "4x4" "ENHANCED")
all_pass=true

for mode in "${modes[@]}"; do
  echo "Testing $mode mode..."
  ./simv +UVM_TESTNAME=axi4_throughput_ordering_longtail_throttled_write_test +BUS_MATRIX_MODE=$mode > test_${mode}_final.log 2>&1
  
  error_count=$(grep "UVM_ERROR " test_${mode}_final.log | grep -v "UVM_ERROR Count:" | grep -v "UVM_ERROR :" | grep -v "Number of" | wc -l)
  mode_info=$(grep "Final Mode:" test_${mode}_final.log | head -1 | cut -d: -f3-)
  
  echo "  Mode:$mode_info"
  echo "  UVM_ERROR count: $error_count"
  
  if [ $error_count -eq 0 ]; then
    echo "  ✅ PASS"
  else
    echo "  ❌ FAIL"
    all_pass=false
    echo "  Errors:"
    grep "UVM_ERROR " test_${mode}_final.log | grep -v "UVM_ERROR Count:" | grep -v "UVM_ERROR :" | grep -v "Number of" | head -3
  fi
  echo ""
done

echo "=== FINAL RESULT ==="
if $all_pass; then
  echo "🎉 ALL MODES PASS - ULTRATHINK FIX COMPLETE! 🎉"
  echo ""
  echo "Root Cause Identified: Scoreboard wdata/wstrb comparison logic"
  echo "was missing 'no transactions processed' check for NONE mode"
  echo ""
  echo "Fix Applied: Added proper conditional logic to handle cases"
  echo "where no reference model comparisons should occur"
else
  echo "❌ Some modes still failing - investigation needed"
fi