#!/bin/bash
echo "Testing all modes with fix..."
echo ""

echo "Testing NONE mode..."
./simv +UVM_TESTNAME=axi4_throughput_ordering_longtail_throttled_write_test +BUS_MATRIX_MODE=NONE > test_NONE_final_fix.log 2>&1
error_count=$(grep "UVM_ERROR " test_NONE_final_fix.log | grep -v "UVM_ERROR Count:" | grep -v "UVM_ERROR :" | grep -v "Number of" | wc -l)
mode_info=$(grep "Final Mode:" test_NONE_final_fix.log | head -1 | cut -d: -f3-)
echo "  Mode:$mode_info"
echo "  UVM_ERROR count: $error_count"
if [ $error_count -eq 0 ]; then
  echo "  ✅ PASS"
else
  echo "  ❌ FAIL"
fi
echo ""

echo "Testing 4x4 mode..."
./simv +UVM_TESTNAME=axi4_throughput_ordering_longtail_throttled_write_test +BUS_MATRIX_MODE=4x4 > test_4x4_final_fix.log 2>&1
error_count=$(grep "UVM_ERROR " test_4x4_final_fix.log | grep -v "UVM_ERROR Count:" | grep -v "UVM_ERROR :" | grep -v "Number of" | wc -l)
mode_info=$(grep "Final Mode:" test_4x4_final_fix.log | head -1 | cut -d: -f3-)
echo "  Mode:$mode_info"
echo "  UVM_ERROR count: $error_count"
if [ $error_count -eq 0 ]; then
  echo "  ✅ PASS"
else
  echo "  ❌ FAIL"
fi
echo ""

echo "Testing ENHANCED mode..."
./simv +UVM_TESTNAME=axi4_throughput_ordering_longtail_throttled_write_test +BUS_MATRIX_MODE=ENHANCED > test_ENHANCED_final_fix.log 2>&1
error_count=$(grep "UVM_ERROR " test_ENHANCED_final_fix.log | grep -v "UVM_ERROR Count:" | grep -v "UVM_ERROR :" | grep -v "Number of" | wc -l)
mode_info=$(grep "Final Mode:" test_ENHANCED_final_fix.log | head -1 | cut -d: -f3-)
echo "  Mode:$mode_info"
echo "  UVM_ERROR count: $error_count"
if [ $error_count -eq 0 ]; then
  echo "  ✅ PASS"
else
  echo "  ❌ FAIL"
fi
echo ""