#!/bin/bash

echo "=== Final Verification Results ==="
echo ""
echo "Test: axi4_throughput_ordering_longtail_throttled_write_test"
echo ""

for mode in NONE 4x4 ENHANCED; do
  echo "Testing $mode mode..."
  ./simv +UVM_TESTNAME=axi4_throughput_ordering_longtail_throttled_write_test +BUS_MATRIX_MODE=$mode > test_${mode}_final.log 2>&1
  mode_used=$(grep "Final Mode:" test_${mode}_final.log | head -1 | cut -d: -f3-)
  error_count=$(grep "UVM_ERROR " test_${mode}_final.log | grep -v "UVM_ERROR Count:" | grep -v "UVM_ERROR :" | grep -v "Number of" | wc -l)
  echo "  Mode:$mode_used"
  echo "  UVM_ERROR count: $error_count"
  echo ""
done