#!/bin/bash
echo "Testing axi4_throughput_ordering_longtail_throttled_write_test"
echo "Testing mode: $1"

# Run the test
timeout 45 make sim test=axi4_throughput_ordering_longtail_throttled_write_test \
  COMMAND_ADD="+BUS_MATRIX_MODE=$1" \
  LOG_FILE=throughput_${1}_test.log 2>&1

# Check results
if [ -f throughput_${1}_test.log ]; then
  echo "Log file created, checking for errors..."
  ERRORS=$(tail -100 throughput_${1}_test.log | grep -c "UVM_ERROR :" || echo "0")
  FATALS=$(tail -100 throughput_${1}_test.log | grep -c "UVM_FATAL :" || echo "0")
  
  echo "Results for $1 mode:"
  echo "  UVM_ERROR count: $ERRORS"
  echo "  UVM_FATAL count: $FATALS"
  
  # Show any errors
  if [ "$ERRORS" != "0" ] || [ "$FATALS" != "0" ]; then
    echo "  First few errors:"
    grep -m 5 "UVM_ERROR\|UVM_FATAL" throughput_${1}_test.log
  fi
else
  echo "Test did not create log file"
fi
