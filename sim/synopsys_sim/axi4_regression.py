#!/usr/bin/env python3
"""
AXI4 Regression Test Runner
==========================

This script runs AXI4 testcases in parallel using multiple simulation folders.
It provides detailed reporting including pass/fail statistics and first failure analysis.

Features:
- Parallel execution (10 simultaneous tests)
- Progress tracking and real-time status
- Comprehensive logging and error analysis
- Automatic cleanup and folder management
- Timeout handling for stuck tests
- Summary report with failure details

Usage:
    python3 axi4_regression.py [--max-parallel N] [--timeout SECONDS] [--verbose]
"""

import os
import sys
import subprocess
import threading
import time
import re
import argparse
import queue
import shutil
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from datetime import datetime, timedelta
from dataclasses import dataclass
from typing import List, Dict, Optional, Tuple
import signal


@dataclass
class TestResult:
    """Container for test execution results"""
    name: str
    status: str  # 'PASS', 'FAIL', 'TIMEOUT', 'ERROR'
    duration: float
    log_file: str
    error_msg: Optional[str] = None
    folder_id: int = 0


class RegressionRunner:
    """Main regression test runner class"""
    
    def __init__(self, max_parallel: int = 10, timeout: int = 600, verbose: bool = False):
        self.max_parallel = max_parallel
        self.timeout = timeout
        self.verbose = verbose
        self.base_dir = Path.cwd()
        self.results: List[TestResult] = []
        self.running_tests: Dict[str, threading.Thread] = {}
        self.test_queue = queue.Queue()
        self.results_lock = threading.Lock()
        self.stop_all = threading.Event()
        
        # Statistics
        self.total_tests = 0
        self.completed_tests = 0
        self.passed_tests = 0
        self.failed_tests = 0
        self.start_time = None
        
        # Set up signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        """Handle interrupt signals gracefully"""
        print(f"\n⚠️  Received signal {signum}. Initiating graceful shutdown...")
        self.stop_all.set()
        self._cleanup_all_folders()
        sys.exit(1)
    
    def _load_test_list(self, test_list_file: str) -> List[str]:
        """Load test names from regression list file"""
        tests = []
        try:
            with open(test_list_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    # Skip comments and empty lines
                    if line and not line.startswith('#'):
                        tests.append(line)
            
            if not tests:
                raise ValueError(f"No tests found in {test_list_file}")
                
            self.total_tests = len(tests)
            print(f"📋 Loaded {self.total_tests} tests from {test_list_file}")
            return tests
            
        except FileNotFoundError:
            raise FileNotFoundError(f"Test list file not found: {test_list_file}")
        except Exception as e:
            raise Exception(f"Error reading test list file: {e}")
    
    def _setup_test_folders(self) -> List[Path]:
        """Create and setup parallel test execution folders"""
        folders = []
        
        print(f"🔧 Setting up {self.max_parallel} parallel execution folders...")
        
        for i in range(self.max_parallel):
            folder_name = f"run_folder_{i:02d}"
            folder_path = self.base_dir / folder_name
            
            # Clean existing folder
            if folder_path.exists():
                shutil.rmtree(folder_path)
            
            # Create new folder
            folder_path.mkdir(exist_ok=True)
            
            # Copy necessary files (if any configuration files exist)
            config_files = ['../axi4_compile.f', 'Makefile']
            for config_file in config_files:
                src_path = self.base_dir / config_file
                if src_path.exists():
                    shutil.copy2(src_path, folder_path)
            
            folders.append(folder_path)
            
        print(f"✅ Created {len(folders)} execution folders")
        return folders
    
    def _cleanup_all_folders(self):
        """Clean up all test execution folders"""
        print("🧹 Cleaning up execution folders...")
        for i in range(self.max_parallel):
            folder_name = f"run_folder_{i:02d}"
            folder_path = self.base_dir / folder_name
            if folder_path.exists():
                try:
                    shutil.rmtree(folder_path)
                except Exception as e:
                    print(f"⚠️  Warning: Could not remove {folder_path}: {e}")
    
    def _run_single_test(self, test_name: str, folder_path: Path, folder_id: int) -> TestResult:
        """Execute a single test in the specified folder"""
        start_time = time.time()
        log_file = folder_path / f"{test_name}.log"
        
        if self.verbose:
            print(f"🔄 [Folder {folder_id:02d}] Starting {test_name}")
        
        # VCS command
        vcs_cmd = [
            'vcs', '-full64', '-lca', '-kdb', '-sverilog', '+v2k',
            '-debug_access+all', '-ntb_opts', 'uvm-1.2', 
            '+ntb_random_seed_automatic', '-override_timescale=1ps/1ps',
            '+nospecify', '+no_timing_check', '+define+DUMP_FSDB',
            '+define+UVM_VERDI_COMPWAVE', '-f', '../axi4_compile.f',
            '-debug_access+all', '-R', f'+UVM_TESTNAME={test_name}',
            '+UVM_VERBOSITY=MEDIUM', '+plusarg_ignore', '-l', str(log_file)
        ]
        
        try:
            # Change to the test folder
            original_cwd = os.getcwd()
            os.chdir(folder_path)
            
            # Run the test with timeout
            process = subprocess.Popen(
                vcs_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                preexec_fn=os.setsid  # Create new process group
            )
            
            # Wait for completion with timeout
            try:
                stdout, _ = process.communicate(timeout=self.timeout)
                duration = time.time() - start_time
                
                # Check if test passed or failed
                status, error_msg = self._analyze_test_result(log_file, stdout)
                
                return TestResult(
                    name=test_name,
                    status=status,
                    duration=duration,
                    log_file=str(log_file),
                    error_msg=error_msg,
                    folder_id=folder_id
                )
                
            except subprocess.TimeoutExpired:
                # Kill the entire process group
                os.killpg(os.getpgid(process.pid), signal.SIGKILL)
                process.communicate()  # Clean up
                
                duration = time.time() - start_time
                return TestResult(
                    name=test_name,
                    status='TIMEOUT',
                    duration=duration,
                    log_file=str(log_file),
                    error_msg=f"Test timed out after {self.timeout} seconds",
                    folder_id=folder_id
                )
                
        except Exception as e:
            duration = time.time() - start_time
            return TestResult(
                name=test_name,
                status='ERROR',
                duration=duration,
                log_file=str(log_file) if log_file else '',
                error_msg=f"Execution error: {str(e)}",
                folder_id=folder_id
            )
        finally:
            # Restore original directory
            os.chdir(original_cwd)
    
    def _analyze_test_result(self, log_file: Path, stdout: str) -> Tuple[str, Optional[str]]:
        """Analyze test output to determine pass/fail status and extract error message"""
        error_msg = None
        
        try:
            # Read the log file if it exists
            log_content = ""
            if log_file.exists():
                with open(log_file, 'r') as f:
                    log_content = f.read()
            
            # Combine stdout and log content for analysis
            full_output = stdout + "\n" + log_content
            
            # Check for common failure patterns
            failure_patterns = [
                r'UVM_FATAL',
                r'UVM_ERROR(?!\s+@\s+0:)',  # UVM_ERROR but not at time 0 (which might be expected)
                r'Error-\[',
                r'\*E,',
                r'FAILED',
                r'simulation aborted',
                r'Segmentation fault',
                r'core dumped'
            ]
            
            # Check for success patterns
            success_patterns = [
                r'UVM_INFO.*TEST PASSED',
                r'UVM_INFO.*PASSED',
                r'\*\* TEST PASSED \*\*',
                r'Simulation completed successfully'
            ]
            
            # Look for failure indicators first
            for pattern in failure_patterns:
                matches = re.findall(pattern, full_output, re.IGNORECASE | re.MULTILINE)
                if matches:
                    # Extract the first error message context
                    error_lines = []
                    for line in full_output.split('\n'):
                        if re.search(pattern, line, re.IGNORECASE):
                            error_lines.append(line.strip())
                            break
                    
                    if error_lines:
                        error_msg = error_lines[0][:200]  # Limit error message length
                    else:
                        error_msg = f"Failed with pattern: {pattern}"
                    
                    return 'FAIL', error_msg
            
            # Check for success patterns
            for pattern in success_patterns:
                if re.search(pattern, full_output, re.IGNORECASE):
                    return 'PASS', None
            
            # If no explicit pass/fail found, check simulation completion
            if 'CPU TIME' in full_output or 'Total simulation time' in full_output:
                # Simulation completed, assume pass if no errors found
                return 'PASS', None
            else:
                return 'FAIL', "Simulation did not complete properly"
                
        except Exception as e:
            return 'ERROR', f"Could not analyze results: {str(e)}"
    
    def _update_progress(self, test_result: TestResult):
        """Update progress statistics and display"""
        with self.results_lock:
            self.results.append(test_result)
            self.completed_tests += 1
            
            if test_result.status == 'PASS':
                self.passed_tests += 1
            else:
                self.failed_tests += 1
            
            # Calculate progress
            progress = (self.completed_tests / self.total_tests) * 100
            elapsed = time.time() - self.start_time
            
            # Estimate remaining time
            if self.completed_tests > 0:
                avg_time_per_test = elapsed / self.completed_tests
                remaining_tests = self.total_tests - self.completed_tests
                eta_seconds = remaining_tests * avg_time_per_test / self.max_parallel
                eta = str(timedelta(seconds=int(eta_seconds)))
            else:
                eta = "Unknown"
            
            # Status icon
            if test_result.status == 'PASS':
                status_icon = "✅"
            elif test_result.status == 'FAIL':
                status_icon = "❌"
            elif test_result.status == 'TIMEOUT':
                status_icon = "⏰"
            else:
                status_icon = "💥"
            
            print(f"{status_icon} [{self.completed_tests:3d}/{self.total_tests}] "
                  f"{test_result.name:50s} "
                  f"({test_result.duration:6.1f}s) "
                  f"Progress: {progress:5.1f}% ETA: {eta}")
            
            if test_result.status != 'PASS' and test_result.error_msg:
                print(f"    └─ Error: {test_result.error_msg}")
    
    def _print_summary(self):
        """Print final test summary report"""
        total_time = time.time() - self.start_time
        
        print("\n" + "="*80)
        print("🏁 REGRESSION SUMMARY")
        print("="*80)
        
        print(f"📊 Statistics:")
        print(f"   Total Tests:     {self.total_tests}")
        print(f"   Passed:          {self.passed_tests} ({(self.passed_tests/self.total_tests)*100:.1f}%)")
        print(f"   Failed:          {self.failed_tests} ({(self.failed_tests/self.total_tests)*100:.1f}%)")
        print(f"   Total Time:      {str(timedelta(seconds=int(total_time)))}")
        print(f"   Average per Test: {total_time/self.total_tests:.1f}s")
        
        # Group results by status
        failed_results = [r for r in self.results if r.status != 'PASS']
        
        if failed_results:
            print(f"\n❌ FAILED TESTS ({len(failed_results)}):")
            print("-" * 80)
            
            for result in failed_results:
                print(f"   {result.status:8s} {result.name:50s} ({result.duration:6.1f}s)")
                if result.error_msg:
                    # Truncate long error messages
                    error_short = result.error_msg[:100] + "..." if len(result.error_msg) > 100 else result.error_msg
                    print(f"            └─ {error_short}")
                print(f"            └─ Log: {result.log_file}")
        
        # Save detailed results to file
        results_file = self.base_dir / f"regression_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        self._save_detailed_results(results_file)
        print(f"\n📄 Detailed results saved to: {results_file}")
        
        # Exit code
        if self.failed_tests > 0:
            print(f"\n💥 REGRESSION FAILED: {self.failed_tests} tests failed")
            return 1
        else:
            print(f"\n🎉 REGRESSION PASSED: All {self.passed_tests} tests passed!")
            return 0
    
    def _save_detailed_results(self, results_file: Path):
        """Save detailed test results to file"""
        with open(results_file, 'w') as f:
            f.write(f"AXI4 Regression Results\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"="*80 + "\n\n")
            
            f.write(f"Summary:\n")
            f.write(f"  Total Tests: {self.total_tests}\n")
            f.write(f"  Passed:      {self.passed_tests}\n")
            f.write(f"  Failed:      {self.failed_tests}\n")
            f.write(f"  Pass Rate:   {(self.passed_tests/self.total_tests)*100:.1f}%\n\n")
            
            f.write(f"Detailed Results:\n")
            f.write(f"-" * 80 + "\n")
            
            for result in self.results:
                f.write(f"Test:     {result.name}\n")
                f.write(f"Status:   {result.status}\n")
                f.write(f"Duration: {result.duration:.1f}s\n")
                f.write(f"Folder:   {result.folder_id}\n")
                f.write(f"Log:      {result.log_file}\n")
                
                if result.error_msg:
                    f.write(f"Error:    {result.error_msg}\n")
                
                f.write(f"\n")
    
    def run_regression(self, test_list_file: str) -> int:
        """Main method to run the regression"""
        try:
            print("🚀 Starting AXI4 Regression Runner")
            print(f"⚙️  Configuration: {self.max_parallel} parallel, {self.timeout}s timeout")
            
            # Load test list
            tests = self._load_test_list(test_list_file)
            
            # Setup test folders
            folders = self._setup_test_folders()
            
            # Start timer
            self.start_time = time.time()
            
            print(f"\n🏃 Starting regression with {len(tests)} tests...")
            print("-" * 80)
            
            # Run tests in parallel using ThreadPoolExecutor
            with ThreadPoolExecutor(max_workers=self.max_parallel) as executor:
                # Submit all tests
                future_to_test = {}
                folder_assignment = {}
                
                for i, test_name in enumerate(tests):
                    if self.stop_all.is_set():
                        break
                        
                    folder_id = i % self.max_parallel
                    folder_path = folders[folder_id]
                    
                    future = executor.submit(self._run_single_test, test_name, folder_path, folder_id)
                    future_to_test[future] = test_name
                    folder_assignment[test_name] = folder_id
                
                # Process completed tests
                for future in as_completed(future_to_test):
                    if self.stop_all.is_set():
                        break
                        
                    try:
                        result = future.result()
                        self._update_progress(result)
                    except Exception as e:
                        test_name = future_to_test[future]
                        error_result = TestResult(
                            name=test_name,
                            status='ERROR',
                            duration=0.0,
                            log_file='',
                            error_msg=f"Thread execution error: {str(e)}",
                            folder_id=folder_assignment.get(test_name, 0)
                        )
                        self._update_progress(error_result)
            
            # Print summary and return exit code
            return self._print_summary()
            
        except Exception as e:
            print(f"\n💥 Fatal error during regression: {e}")
            return 1
        finally:
            # Always clean up
            self._cleanup_all_folders()


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="AXI4 Regression Test Runner",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 axi4_regression.py
  python3 axi4_regression.py --max-parallel 5 --timeout 900
  python3 axi4_regression.py --verbose
        """
    )
    
    parser.add_argument(
        '--max-parallel', '-p',
        type=int,
        default=10,
        help='Maximum number of parallel test executions (default: 10)'
    )
    
    parser.add_argument(
        '--timeout', '-t',
        type=int,
        default=600,
        help='Timeout for each test in seconds (default: 600)'
    )
    
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Enable verbose output'
    )
    
    parser.add_argument(
        '--test-list',
        default='../../testlists/axi4_transfers_regression.list',
        help='Path to test list file (default: ../../testlists/axi4_transfers_regression.list)'
    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if args.max_parallel < 1 or args.max_parallel > 20:
        print("❌ Error: max-parallel must be between 1 and 20")
        return 1
    
    if args.timeout < 60:
        print("❌ Error: timeout must be at least 60 seconds")
        return 1
    
    # Check if test list file exists
    test_list_path = Path(args.test_list)
    if not test_list_path.exists():
        print(f"❌ Error: Test list file not found: {test_list_path}")
        return 1
    
    # Create and run regression
    runner = RegressionRunner(
        max_parallel=args.max_parallel,
        timeout=args.timeout,
        verbose=args.verbose
    )
    
    try:
        return runner.run_regression(args.test_list)
    except KeyboardInterrupt:
        print("\n⚠️  Regression interrupted by user")
        return 1


if __name__ == "__main__":
    sys.exit(main())