#!/bin/bash

# AXI4 Regression Test Runner Script
# Usage: ./run_regression.sh [options]

# Default values
PARALLEL=10
TIMEOUT=600
VERBOSE=""
TEST_LIST="../../testlists/axi4_transfers_regression.list"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--parallel)
            PARALLEL="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE="--verbose"
            shift
            ;;
        -l|--test-list)
            TEST_LIST="$2"
            shift 2
            ;;
        -h|--help)
            echo "AXI4 Regression Test Runner"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -p, --parallel N     Number of parallel tests (default: 10)"
            echo "  -t, --timeout N      Timeout per test in seconds (default: 600)"
            echo "  -v, --verbose        Enable verbose output"
            echo "  -l, --test-list FILE Test list file (default: ../../testlists/axi4_transfers_regression.list)"
            echo "  -h, --help           Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                           # Run with defaults"
            echo "  $0 -p 5 -t 900              # 5 parallel tests, 15min timeout"
            echo "  $0 -v                        # Verbose mode"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if python3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: python3 is required but not installed"
    exit 1
fi

# Check if test list file exists
if [[ ! -f "$TEST_LIST" ]]; then
    echo "❌ Error: Test list file not found: $TEST_LIST"
    exit 1
fi

# Create timestamp for this run
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
echo "🚀 Starting AXI4 Regression - $TIMESTAMP"
echo "📋 Test List: $TEST_LIST"
echo "⚙️  Configuration: $PARALLEL parallel, ${TIMEOUT}s timeout"

# Run the regression
python3 axi4_regression.py \
    --max-parallel "$PARALLEL" \
    --timeout "$TIMEOUT" \
    --test-list "$TEST_LIST" \
    $VERBOSE

# Capture exit code
EXIT_CODE=$?

# Show completion message
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "🎉 Regression completed successfully!"
else
    echo "💥 Regression failed with exit code: $EXIT_CODE"
fi

exit $EXIT_CODE