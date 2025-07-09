#!/usr/bin/env python3
"""
Test the regression runner with a small subset of tests
"""

import tempfile
import os
from pathlib import Path

# Create a small test list for verification
test_content = """# Small test list for verification
axi4_write_read_test
axi4_blocking_8b_write_read_test
axi4_tc_054_exclusive_read_fail_test
"""

# Create temporary test list
with tempfile.NamedTemporaryFile(mode='w', suffix='.list', delete=False) as f:
    f.write(test_content)
    temp_test_list = f.name

try:
    print("🧪 Running regression test with 3 sample tests...")
    print(f"📋 Using temporary test list: {temp_test_list}")
    
    # Import and run regression
    from axi4_regression import RegressionRunner
    
    runner = RegressionRunner(max_parallel=3, timeout=300, verbose=True)
    exit_code = runner.run_regression(temp_test_list)
    
    print(f"\n✅ Test completed with exit code: {exit_code}")
    
finally:
    # Clean up temporary file
    if os.path.exists(temp_test_list):
        os.unlink(temp_test_list)