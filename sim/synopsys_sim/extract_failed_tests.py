#!/usr/bin/env python3
import re

# Read the regression results file
with open('regression_result_20250709_144850/regression_results_20250709_144850.txt', 'r') as f:
    content = f.read()

# Find all failed test names
failed_tests = []
lines = content.split('\n')
in_failed_section = False

for line in lines:
    if 'FAILED Tests' in line:
        in_failed_section = True
        continue
    if 'PASSED Tests' in line:
        in_failed_section = False
        break
    
    if in_failed_section and line.startswith('Test:'):
        test_name = line.split()[1]
        failed_tests.append(test_name)

# Write to test list file
with open('test_all_previously_failed.list', 'w') as f:
    for test in failed_tests:
        f.write(f"{test}\n")

print(f"Extracted {len(failed_tests)} failed tests:")
for test in failed_tests:
    print(f"  {test}")