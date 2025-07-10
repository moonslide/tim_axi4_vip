#!/usr/bin/env python
"""
AXI4 Regression Test Runner
==========================

This script runs AXI4 testcases in parallel using separate run folders for each test.
It provides detailed reporting including pass/fail statistics and failure analysis.

Features:
- Parallel execution (default: one folder per test case)
- Each test runs in isolated run_folder_XX directory
- Progress tracking and real-time status
- Comprehensive logging and error analysis
- Creates timestamped results folder with all logs
- Generates no_pass_list for failed tests
- Timeout handling for stuck tests
- Summary report with failure details

Usage:
    python3 axi4_regression.py [-p NUM_WORKERS] [--timeout SECONDS] [--verbose]
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
import random
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from datetime import datetime, timedelta
import signal
import json


class TestResult:
    """Container for test execution results"""
    def __init__(self, name, status, duration, log_file, error_msg=None, folder_id=0):
        self.name = name
        self.status = status  # 'PASS', 'FAIL', 'TIMEOUT', 'ERROR'
        self.duration = duration
        self.log_file = log_file
        self.error_msg = error_msg
        self.folder_id = folder_id


class RegressionRunner:
    """Main regression test runner class"""
    
    def __init__(self, max_parallel=None, timeout=600, verbose=False, use_lsf=False):
        self.max_parallel = max_parallel  # Will be set to number of tests if None
        self.timeout = timeout
        self.verbose = verbose
        self.use_lsf = use_lsf
        self.base_dir = Path.cwd()
        self.results = []
        self.running_tests = {}
        self.test_queue = queue.Queue()
        self.results_lock = threading.Lock()
        self.stop_all = threading.Event()
        
        # LSF job tracking
        self.lsf_jobs = {}  # job_id -> test_info
        self.pending_jobs = 0
        self.running_jobs = 0
        
        # Results folder with timestamp
        self.timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        self.results_folder = self.base_dir / f"regression_result_{self.timestamp}"
        self.logs_folder = self.results_folder / "logs"
        self.pass_logs_folder = self.logs_folder / "pass_logs"
        self.no_pass_logs_folder = self.logs_folder / "no_pass_logs"
        
        # Statistics
        self.total_tests = 0
        self.completed_tests = 0
        self.passed_tests = 0
        self.failed_tests = 0
        self.start_time = None
        
        # Set up signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
        
        # Check LSF availability if requested
        if self.use_lsf:
            self._check_lsf_availability()
    
    def _to_relative_path(self, path):
        """Convert absolute path to relative path for display"""
        try:
            # Convert to Path object if needed
            if not isinstance(path, Path):
                path = Path(path)
            
            # Try to make path relative to current working directory
            return path.relative_to(Path.cwd())
        except (ValueError, TypeError):
            # If can't make relative, return the path name only
            return path.name if hasattr(path, 'name') else str(path)
    
    def _extract_base_test_name(self, test_name):
        """Extract base test name from numbered test name
        
        Examples:
        - 'axi4_wstrb_test' -> 'axi4_wstrb_test'
        - 'axi4_wstrb_test_1' -> 'axi4_wstrb_test'
        - 'axi4_wstrb_test_10' -> 'axi4_wstrb_test'
        """
        # Check if test name ends with _N where N is a number
        import re
        match = re.match(r'^(.+)_(\d+)$', test_name)
        if match:
            return match.group(1)  # Return base name without _N suffix
        else:
            return test_name  # Return as-is if no _N suffix found
    
    def _check_lsf_availability(self):
        """Check if LSF commands are available"""
        try:
            subprocess.run(['which', 'bsub'], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            subprocess.run(['which', 'bjobs'], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            subprocess.run(['which', 'bkill'], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            print("✅ LSF commands available (bsub, bjobs, bkill)")
        except subprocess.CalledProcessError:
            print("❌ LSF commands not available on this system")
            print("💡 Available alternatives:")
            print("   - Install LSF package")
            print("   - Use local execution mode (without --lsf)")
            print("   - Set up LSF environment variables")
            sys.exit(1)
    
    def _signal_handler(self, signum, frame):
        """Handle interrupt signals gracefully"""
        print(f"\n⚠️  Received signal {signum}. Initiating graceful shutdown...")
        self.stop_all.set()
        
        # Kill any running LSF jobs
        if self.use_lsf:
            self._kill_all_lsf_jobs()
        
        self._cleanup_all_folders()
        sys.exit(1)
    
    def _load_test_list(self, test_list_file):
        """Load test names from regression list file
        
        Supports format:
        - testname          (run once)
        - testname N        (run N times with numbered logs: testname_1.log, testname_2.log, etc.)
        """
        tests = []
        expanded_tests = []
        try:
            with open(test_list_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    # Skip comments and empty lines
                    if line and not line.startswith('#'):
                        tests.append(line)
            
            if not tests:
                raise ValueError(f"No tests found in {test_list_file}")
            
            # Parse and expand tests that have repetition count
            for test_entry in tests:
                parts = test_entry.split()
                if len(parts) == 1:
                    # Single test, no repetition
                    expanded_tests.append(parts[0])
                elif len(parts) == 2:
                    # Test with repetition count
                    test_name = parts[0]
                    try:
                        repeat_count = int(parts[1])
                        if repeat_count < 1:
                            raise ValueError(f"Repeat count must be >= 1, got {repeat_count}")
                        
                        # Add numbered test entries
                        for i in range(1, repeat_count + 1):
                            numbered_test = f"{test_name}_{i}"
                            expanded_tests.append(numbered_test)
                        
                        print(f"📋 Expanded {test_name} into {repeat_count} runs: {test_name}_1 to {test_name}_{repeat_count}")
                    except ValueError as e:
                        print(f"⚠️  Warning: Invalid repeat count in '{test_entry}': {e}")
                        print(f"    Treating as single test: {test_name}")
                        expanded_tests.append(test_name)
                else:
                    print(f"⚠️  Warning: Invalid test entry format '{test_entry}' - expected 'testname' or 'testname N'")
                    print(f"    Treating as single test: {parts[0]}")
                    expanded_tests.append(parts[0])
                
            self.total_tests = len(expanded_tests)
            print(f"📋 Loaded {len(tests)} test entries from {test_list_file}")
            print(f"📋 Expanded to {self.total_tests} total test runs")
            return expanded_tests
            
        except FileNotFoundError:
            raise FileNotFoundError(f"Test list file not found: {test_list_file}")
        except Exception as e:
            raise Exception(f"Error reading test list file: {e}")
    
    def _cleanup_existing_folders(self):
        """Clean up any existing run_folder_xx directories before starting"""
        print("🧹 Cleaning up existing run_folder_xx directories...")
        folders_cleaned = 0
        
        # Look for all run_folder_xx patterns in parent directory
        parent_dir = self.base_dir.parent
        for folder_path in parent_dir.glob("run_folder_*"):
            if folder_path.is_dir():
                try:
                    shutil.rmtree(folder_path)
                    folders_cleaned += 1
                except Exception as e:
                    print(f"⚠️  Warning: Could not remove {folder_path}: {e}")
        
        if folders_cleaned > 0:
            print(f"✅ Cleaned up {folders_cleaned} existing run folders")
        else:
            print("✅ No existing run folders to clean")

    def _setup_test_folders(self) :
        """Create and setup test execution folders"""
        folders = []
        
        # Clean up existing run folders first
        self._cleanup_existing_folders()
        
        # Create results folder and logs subfolders
        self.results_folder.mkdir(exist_ok=True)
        self.logs_folder.mkdir(exist_ok=True)
        self.pass_logs_folder.mkdir(exist_ok=True)
        self.no_pass_logs_folder.mkdir(exist_ok=True)
        print(f"📁 Created results folder: {self._to_relative_path(self.results_folder)}")
        print(f"📁 Created logs folder: {self._to_relative_path(self.logs_folder)}")
        print(f"📁 Created pass_logs folder: {self._to_relative_path(self.pass_logs_folder)}")
        print(f"📁 Created no_pass_logs folder: {self._to_relative_path(self.no_pass_logs_folder)}")
        
        # Always set up parallel folders based on number of tests
        num_folders = min(self.max_parallel, self.total_tests)
        print(f"🔧 Setting up {num_folders} parallel execution folders...")
        
        for i in range(num_folders):
            folder_name = f"run_folder_{i:02d}"
            folder_path = self.base_dir.parent / folder_name
            
            # Clean existing folder (additional safety check)
            if folder_path.exists():
                shutil.rmtree(folder_path)
            
            # Create new folder
            folder_path.mkdir(exist_ok=True)
            
            # Create modified compile file with adjusted paths for this run folder
            self._create_compile_file_for_folder(folder_path)
            
            folders.append(folder_path)
            
        print(f"✅ Created {len(folders)} execution folders")
            
        return folders
    
    def _create_compile_file_for_folder(self, folder_path):
        """Create a compile file with paths adjusted for running from the folder"""
        # Read the original compile file
        orig_compile_file = self.base_dir.parent / 'axi4_compile.f'
        new_compile_file = folder_path / 'axi4_compile.f'
        
        with open(orig_compile_file, 'r') as f:
            content = f.read()
        
        # No path adjustment needed since run_folder_XX is at same level as synopsys_sim
        # Both are at sim/ level, so ../../pkg/ works from both locations
        adjusted_content = content
        
        with open(new_compile_file, 'w') as f:
            f.write(adjusted_content)
    
    def _kill_all_lsf_jobs(self):
        """Kill all LSF jobs associated with this regression"""
        if not self.lsf_jobs:
            return
            
        print("🔪 Killing LSF jobs...")
        for job_id, job_info in self.lsf_jobs.items():
            try:
                subprocess.run(['bkill', str(job_id)], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                print(f"🔪 Killed job {job_id} ({job_info['test_name']})")
            except subprocess.CalledProcessError as e:
                print(f"⚠️  Warning: Could not kill job {job_id}: {e}")
    
    def _submit_lsf_job(self, test_name, folder_path, folder_id):
        """Submit a test job to LSF and return job ID"""
        # Create job script
        job_script = folder_path / f'lsf_job_{test_name}.sh'
        log_file_rel = f'{test_name}.log'
        
        # Extract base test name for UVM_TESTNAME (remove _N suffix if present)
        base_test_name = self._extract_base_test_name(test_name)
        
        with open(job_script, 'w') as f:
            f.write('#!/bin/bash\n')
            f.write('#BSUB -J {}\n'.format(test_name))
            f.write('#BSUB -o {}.lsf.out\n'.format(test_name))
            f.write('#BSUB -e {}.lsf.err\n'.format(test_name))
            f.write('#BSUB -q normal\n')  # Adjust queue as needed
            f.write('#BSUB -n 1\n')
            f.write('#BSUB -R "rusage[mem=4000]"\n')  # 4GB memory
            f.write('\n')
            f.write('# Change to execution directory\n')
            f.write(f'cd {folder_path}\n')
            f.write('\n')
            f.write('# Clean up VCS artifacts before running test\n')
            f.write('rm -rf simv* csrc vc_hdrs.h ucli.key *.fsdb *.daidir work.lib++ *.log\n')
            f.write('\n')
            # Generate a more random seed using multiple entropy sources
            random_seed = random.randint(1, 2**31-1)
            random_seed ^= int(time.time() * 1000000) & 0x7FFFFFFF  # Mix with microsecond timestamp
            random_seed ^= hash(test_name) & 0x7FFFFFFF  # Mix with test name hash
            random_seed &= 0x7FFFFFFF  # Ensure positive 32-bit value
            
            f.write('# Run VCS\n')
            f.write(f'vcs -full64 -lca -kdb -sverilog +v2k ')
            f.write(f'-debug_access+all -ntb_opts uvm-1.2 ')
            f.write(f'+ntb_random_seed={random_seed} -override_timescale=1ps/1ps ')
            f.write(f'+nospecify +no_timing_check +define+DUMP_FSDB ')
            f.write(f'+define+UVM_VERDI_COMPWAVE -f axi4_compile.f ')
            f.write(f'-debug_access+all -R +UVM_TESTNAME={base_test_name} ')
            f.write(f'+UVM_VERBOSITY=MEDIUM +plusarg_ignore ')
            f.write(f'-l {log_file_rel}\n')
        
        # Make script executable
        os.chmod(job_script, 0o755)
        
        # Submit job
        try:
            result = subprocess.run(
                ['bsub', str(job_script)],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True,
                check=True
            )
            
            # Extract job ID from bsub output: "Job <12345> is submitted to queue <normal>."
            job_id_match = re.search(r'Job <(\d+)>', result.stdout)
            if job_id_match:
                job_id = int(job_id_match.group(1))
                
                # Store job info
                self.lsf_jobs[job_id] = {
                    'test_name': test_name,
                    'folder_path': folder_path,
                    'folder_id': folder_id,
                    'submit_time': time.time(),
                    'status': 'PEND'  # LSF job status
                }
                
                self.pending_jobs += 1
                if self.verbose:
                    print(f"📤 [LSF] Submitted {test_name} as job {job_id}")
                
                return job_id
            else:
                raise Exception(f"Could not extract job ID from bsub output: {result.stdout}")
                
        except subprocess.CalledProcessError as e:
            raise Exception(f"Failed to submit LSF job: {e.stderr}")
    
    def _check_lsf_job_status(self, job_id):
        """Check the status of an LSF job"""
        try:
            result = subprocess.run(
                ['bjobs', '-o', 'jobid stat exit_reason', '-json', str(job_id)],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True,
                check=True
            )
            
            # Parse JSON output
            data = json.loads(result.stdout)
            if 'RECORDS' in data and len(data['RECORDS']) > 0:
                record = data['RECORDS'][0]
                status = record.get('STAT', 'UNKNOWN')
                exit_reason = record.get('EXIT_REASON', '')
                return status, exit_reason
            else:
                # Job not found, assume completed
                return 'DONE', ''
                
        except (subprocess.CalledProcessError, json.JSONDecodeError):
            # Fallback to simple bjobs
            try:
                result = subprocess.run(
                    ['bjobs', str(job_id)],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    universal_newlines=True,
                    check=True
                )
                
                lines = result.stdout.strip().split('\n')
                if len(lines) >= 2:
                    # Parse bjobs output: JOBID USER STAT QUEUE FROM_HOST EXEC_HOST JOB_NAME SUBMIT_TIME
                    parts = lines[1].split()
                    if len(parts) >= 3:
                        return parts[2], ''  # Return status
                        
            except subprocess.CalledProcessError:
                pass
                
            return 'UNKNOWN', ''
    
    def _monitor_lsf_jobs(self):
        """Monitor LSF jobs and update status"""
        completed_jobs = []
        
        for job_id, job_info in self.lsf_jobs.items():
            if job_info.get('completed', False):
                continue
                
            status, exit_reason = self._check_lsf_job_status(job_id)
            current_time = time.time()
            
            # Update job status
            if job_info['status'] != status:
                if status == 'RUN' and job_info['status'] == 'PEND':
                    self.pending_jobs -= 1
                    self.running_jobs += 1
                    job_info['start_time'] = current_time
                    
                job_info['status'] = status
            
            # Check for completion
            if status in ['DONE', 'EXIT']:
                job_info['completed'] = True
                job_info['end_time'] = current_time
                
                if status == 'RUN':
                    self.running_jobs -= 1
                elif status == 'PEND':
                    self.pending_jobs -= 1
                
                completed_jobs.append(job_id)
                
            # Check for timeout
            elif status == 'RUN' and 'start_time' in job_info:
                elapsed = current_time - job_info['start_time']
                if elapsed > self.timeout:
                    print(f"⏰ [LSF] Job {job_id} ({job_info['test_name']}) timed out after {elapsed:.1f}s")
                    try:
                        subprocess.run(['bkill', str(job_id)], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                        job_info['completed'] = True
                        job_info['status'] = 'TIMEOUT'
                        job_info['end_time'] = current_time
                        self.running_jobs -= 1
                        completed_jobs.append(job_id)
                    except subprocess.CalledProcessError as e:
                        print(f"⚠️  Warning: Could not kill timed out job {job_id}: {e}")
        
        return completed_jobs
    
    def _display_lsf_status(self):
        """Display current LSF job status summary"""
        remaining_tests = self.total_tests - self.completed_tests
        elapsed = time.time() - self.start_time
        
        # Calculate average completion time for ETA
        if self.completed_tests > 0:
            avg_time = elapsed / self.completed_tests
            eta_seconds = remaining_tests * avg_time
            eta = str(timedelta(seconds=int(eta_seconds)))
        else:
            eta = "Unknown"
        
        # Progress percentage
        progress = (self.completed_tests / self.total_tests) * 100
        
        print(f"📊 [LSF Status] "
              f"Done: {self.completed_tests}/{self.total_tests} ({progress:.1f}%) | "
              f"Remaining: {remaining_tests} | "
              f"Pending: {self.pending_jobs} | "
              f"Running: {self.running_jobs} | "
              f"ETA: {eta}")
        
        # Show pass/fail breakdown if any tests completed
        if self.completed_tests > 0:
            print(f"           Results: {self.passed_tests} PASS, {self.failed_tests} FAIL")
    
    def _cleanup_all_folders(self):
        """Clean up all test execution folders"""
        print("🧹 Cleaning up execution folders...")
        for i in range(self.max_parallel):
            folder_name = f"run_folder_{i:02d}"
            folder_path = self.base_dir.parent / folder_name
            if folder_path.exists():
                try:
                    shutil.rmtree(folder_path)
                except Exception as e:
                    print(f"⚠️  Warning: Could not remove {folder_path}: {e}")
    
    def _cleanup_vcs_artifacts(self, folder_path):
        """Clean up VCS compilation artifacts before running a test"""
        artifacts_to_clean = [
            'simv*',           # VCS executable and related files
            'csrc',            # VCS compilation directory
            'vc_hdrs.h',       # VCS header file
            'ucli.key',        # VCS license key file
            '*.fsdb',          # FSDB waveform files
            '*.daidir',        # VCS debug directory
            'work.lib++',      # Work library
            # Note: We don't clean *.log files here since they might be needed for analysis
        ]
        
        for pattern in artifacts_to_clean:
            try:
                # Use shell globbing to handle wildcards
                result = subprocess.run(
                    f'cd {folder_path} && rm -rf {pattern}',
                    shell=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )
                if self.verbose and result.returncode == 0:
                    # Only show if files were actually removed
                    check_result = subprocess.run(
                        f'cd {folder_path} && ls {pattern} 2>/dev/null',
                        shell=True,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE
                    )
                    if check_result.returncode != 0:  # Files were removed
                        print(f"🧹 [Folder {folder_path.name[-2:]}] Cleaned {pattern}")
            except Exception as e:
                if self.verbose:
                    print(f"⚠️  Warning: Could not clean {pattern} in {folder_path}: {e}")
    
    def _cleanup_old_logs(self, folder_path, current_test_name):
        """Clean up old log files from previous tests, but preserve current test's log"""
        try:
            # Only clean log files that are not the current test's log
            result = subprocess.run(
                f'cd {folder_path} && find . -name "*.log" ! -name "{current_test_name}.log" -delete',
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            if self.verbose and result.returncode == 0:
                print(f"🧹 [Folder {folder_path.name[-2:]}] Cleaned old log files")
        except Exception as e:
            if self.verbose:
                print(f"⚠️  Warning: Could not clean old logs in {folder_path}: {e}")
    
    def _run_single_test(self, test_name, folder_path, folder_id):
        """Execute a single test in the specified folder"""
        start_time = time.time()
        log_file = folder_path / f"{test_name}.log"
        
        # Extract base test name for UVM_TESTNAME (remove _N suffix if present)
        base_test_name = self._extract_base_test_name(test_name)
        
        # Clean up VCS artifacts before running the test
        self._cleanup_vcs_artifacts(folder_path)
        
        # Clean up old log files but preserve any that might be from the current test
        self._cleanup_old_logs(folder_path, test_name)
        
        if self.verbose:
            print(f"🔄 [Folder {folder_id:02d}] Starting {test_name}")
            if test_name != base_test_name:
                print(f"    Base test: {base_test_name}")
            print(f"    Working directory: {self._to_relative_path(folder_path)}")
            print(f"    Expected log file: {self._to_relative_path(log_file)}")
        
        # Always use parallel VCS execution now
        # VCS command - use script wrapper to handle directory changes
        run_script = folder_path / 'run_test.sh'
        log_file_rel = f'{test_name}.log'
        
        # Create run script that runs VCS directly from within this folder
        with open(run_script, 'w') as f:
            f.write('#!/bin/bash\n')
            # Generate a more random seed using multiple entropy sources
            random_seed = random.randint(1, 2**31-1)
            random_seed ^= int(time.time() * 1000000) & 0x7FFFFFFF  # Mix with microsecond timestamp
            random_seed ^= hash(test_name) & 0x7FFFFFFF  # Mix with test name hash
            random_seed &= 0x7FFFFFFF  # Ensure positive 32-bit value
            
            f.write('# Clean up VCS artifacts (already done in Python, but ensure completeness)\n')
            f.write('# This is a backup cleanup in case Python cleanup missed anything\n')
            f.write('# Run VCS directly from this folder with adjusted compile file\n')
            f.write(f'vcs -full64 -lca -kdb -sverilog +v2k ')
            f.write(f'-debug_access+all -ntb_opts uvm-1.2 ')
            f.write(f'+ntb_random_seed={random_seed} -override_timescale=1ps/1ps ')
            f.write(f'+nospecify +no_timing_check +define+DUMP_FSDB ')
            f.write(f'+define+UVM_VERDI_COMPWAVE -f axi4_compile.f ')
            f.write(f'-debug_access+all -R +UVM_TESTNAME={base_test_name} ')
            f.write(f'+UVM_VERBOSITY=MEDIUM +plusarg_ignore ')
            f.write(f'-l {log_file_rel}\n')
        
        # Make script executable
        os.chmod(run_script, 0o755)

        try:
            # Change to the test folder and stay there for VCS execution
            original_cwd = os.getcwd()
            os.chdir(folder_path)
            
            # Run the test with timeout and early hang detection
            process = subprocess.Popen(
                ['./run_test.sh'],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                preexec_fn=os.setsid  # Create new process group
            )
            
            # Wait for completion with timeout and early hang detection
            try:
                stdout, _ = process.communicate(timeout=self.timeout)
                duration = time.time() - start_time
                
                # Wait a moment for log file to be written
                time.sleep(0.5)
                
                # Check multiple possible log file locations
                log_locations = [
                    log_file,  # Expected location
                    Path.cwd() / f"{test_name}.log",  # Current directory
                    self.base_dir / f"{test_name}.log",  # synopsys_sim directory
                ]
                
                actual_log_file = None
                for loc in log_locations:
                    if loc.exists():
                        actual_log_file = loc
                        break
                
                # If log file found in unexpected location, move it to expected location
                if actual_log_file and actual_log_file != log_file:
                    shutil.move(str(actual_log_file), str(log_file))
                    if self.verbose:
                        print(f"📋 Moved log from {self._to_relative_path(actual_log_file)} to {self._to_relative_path(log_file)}")
                elif not actual_log_file:
                    # No log file found anywhere
                    if self.verbose:
                        print(f"⚠️  No log file found for {test_name}")
                        print(f"    Checked locations: {[str(self._to_relative_path(loc)) for loc in log_locations]}")
                        if stdout:
                            print(f"    VCS stdout (first 500 chars): {stdout[:500]}")
                
                # Check if test passed or failed  
                status, error_msg = self._analyze_test_result(log_file, stdout)
                
                # Special handling for TIMEOUT status from analysis
                if status == 'TIMEOUT':
                    # Kill the process if it's still running
                    if process.poll() is None:
                        os.killpg(os.getpgid(process.pid), signal.SIGKILL)
                        process.communicate()
                
                # Copy log to appropriate logs subfolder based on test status
                log_copied = False
                target_folder = self.pass_logs_folder if status == 'PASS' else self.no_pass_logs_folder
                
                if log_file.exists():
                    shutil.copy2(log_file, target_folder / f"{test_name}.log")
                    log_copied = True
                elif (folder_path / f"{test_name}.log").exists():
                    # Try alternative log location
                    shutil.copy2(folder_path / f"{test_name}.log", target_folder / f"{test_name}.log")
                    log_copied = True
                
                if not log_copied:
                    print(f"⚠️  Warning: Could not find log file for {test_name} after test completion")
                
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
                
                # Check if this was an ultrasim timeout or general timeout
                timeout_msg = f"Test timed out after {self.timeout} seconds"
                if log_file.exists():
                    try:
                        # Check log file for ultrasim/ultrathink-specific timeout patterns
                        with open(log_file, 'r') as f:
                            log_tail = f.read()[-10000:]  # Read last 10KB
                            if 'ultrasim' in log_tail.lower() or 'ultrathink' in log_tail.lower():
                                timeout_msg = f"Ultrasim/Ultrathink timeout detected after {self.timeout} seconds"
                            elif 'excessive repetition' in log_tail or 'simulation stuck' in log_tail:
                                timeout_msg = f"Simulation hung - excessive repetition detected"
                    except Exception:
                        pass  # Use default timeout message
                
                # Copy log to no_pass_logs folder for timeout cases
                log_copied = False
                if log_file.exists():
                    shutil.copy2(log_file, self.no_pass_logs_folder / f"{test_name}.log")
                    log_copied = True
                elif (folder_path / f"{test_name}.log").exists():
                    # Try alternative log location
                    shutil.copy2(folder_path / f"{test_name}.log", self.no_pass_logs_folder / f"{test_name}.log")
                    log_copied = True
                
                if not log_copied:
                    print(f"⚠️  Warning: Could not find log file for {test_name} after timeout")
                
                return TestResult(
                    name=test_name,
                    status='TIMEOUT',
                    duration=duration,
                    log_file=str(log_file),
                    error_msg=timeout_msg,
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
    
    def _analyze_test_result(self, log_file, stdout):
        """Analyze test output to determine pass/fail status and extract error message"""
        error_msg = None
        
        try:
            # Read the log file if it exists
            log_content = ""
            if log_file.exists():
                with open(log_file, 'r') as f:
                    log_content = f.read()
            else:
                # If log file doesn't exist, try to determine status from stdout only
                if self.verbose:
                    print(f"⚠️  Log file not found at {self._to_relative_path(log_file)}, analyzing stdout only")
                log_content = ""  # Use empty log content
            
            # Combine stdout and log content for analysis
            full_output = stdout + "\n" + log_content
            
            # Check for timeout/hang patterns first - these indicate stuck simulations
            timeout_patterns = [
                r'simulation time.*exceeded',
                r'infinite loop detected',
                r'simulation appears to be hung',
                r'excessive repetition detected',
                r'timeout.*ultrasim',
                r'TIME_OUT.*ultrasim',
                r'timeout.*ultrathink',
                r'TIME_OUT.*ultrathink',
                r'simulation stuck at time'
            ]
            
            # Check for common failure patterns
            failure_patterns = [
                r'UVM_FATAL(?!\s*:\s*\d+)',  # UVM_FATAL but not summary count like "UVM_FATAL : 0"
                r'UVM_ERROR(?!\s*:\s*\d+)(?!\s+@\s+0:)',  # UVM_ERROR but not summary count or at time 0
                r'Error-\[',
                r'\*E,',
                r'FAILED',
                r'simulation aborted',
                r'Segmentation fault',
                r'core dumped'
            ]
            
            # Check for success patterns
            success_patterns = [
                r'TestCase PASSED!!!',
                r'UVM_INFO.*TEST PASSED',
                r'UVM_INFO.*PASSED',
                r'\*\* TEST PASSED \*\*',
                r'Simulation completed successfully',
                r'test completed successfully',  # TC_050 specific
                r'Test execution completed'      # TC_050 specific
            ]
            
            # Check for timeout/hang patterns first - these indicate stuck simulations
            for pattern in timeout_patterns:
                matches = re.findall(pattern, full_output, re.IGNORECASE | re.MULTILINE)
                if matches:
                    return 'TIMEOUT', f"Simulation hung or stuck - pattern: {pattern}"
            
            # Detect potential infinite loops by checking for excessive repetition
            # Look for the same UVM_INFO message repeated many times
            lines = full_output.split('\n')
            if len(lines) > 1000:  # Only check large logs
                # Check last 100 lines for repetitive patterns
                recent_lines = lines[-100:]
                line_counts = {}
                for line in recent_lines:
                    if 'UVM_INFO' in line:
                        # Extract the message part after timestamp
                        msg_part = re.sub(r'@\s*\d+:', '@TIME:', line)
                        line_counts[msg_part] = line_counts.get(msg_part, 0) + 1
                
                # If any line appears more than 20 times in recent output, it's likely stuck
                for line, count in line_counts.items():
                    if count > 20:
                        return 'TIMEOUT', f"Excessive repetition detected - simulation likely stuck"
            
            # Look for success indicators 
            for pattern in success_patterns:
                matches = re.findall(pattern, full_output, re.IGNORECASE | re.MULTILINE)
                if matches:
                    return 'PASS', None
            
            # Double-check feature: Analyze UVM report summary for more accurate pass/fail detection
            uvm_summary_found = False
            uvm_errors = 0
            uvm_fatals = 0
            
            if 'UVM Report Summary' in full_output or 'Report counts by severity' in full_output:
                uvm_summary_found = True
                # Look for UVM error/fatal counts in summary
                error_match = re.search(r'UVM_ERROR\s*:\s*(\d+)', full_output)
                fatal_match = re.search(r'UVM_FATAL\s*:\s*(\d+)', full_output)
                
                if error_match:
                    uvm_errors = int(error_match.group(1))
                if fatal_match:
                    uvm_fatals = int(fatal_match.group(1))
                
                # Also check for successful completion patterns
                simulation_completed = bool(re.search(r'\$finish called', full_output))
                test_done = bool(re.search(r'TEST_DONE.*run.*phase.*ready', full_output))
                
                # If UVM summary exists and shows 0 errors/fatals, and simulation completed, it's a pass
                if uvm_errors == 0 and uvm_fatals == 0 and (simulation_completed or test_done):
                    return 'PASS', None
            
            # Look for failure indicators
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
            
            # Success patterns already checked above
            
            # If no explicit pass/fail found, check simulation completion
            if 'CPU TIME' in full_output or 'Total simulation time' in full_output:
                # Simulation completed, assume pass if no errors found
                return 'PASS', None
            elif log_content == "" and not log_file.exists():
                # No log file was created - VCS likely failed to run
                return 'ERROR', f"VCS failed to create log file: {self._to_relative_path(log_file)}"
            else:
                return 'FAIL', "Simulation did not complete properly"
                
        except Exception as e:
            return 'ERROR', f"Could not analyze results: {str(e)}"
    
    def _update_progress(self, test_result):
        """Update progress statistics and display"""
        with self.results_lock:
            self.results.append(test_result)
            self.completed_tests += 1
            
            # Ensure log is copied to results folder
            self._ensure_log_copied(test_result)
            
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
                if self.use_lsf:
                    eta_seconds = remaining_tests * avg_time_per_test  # LSF manages parallelism
                else:
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
            
            # LSF job status display
            lsf_status = ""
            if self.use_lsf:
                remaining = self.total_tests - self.completed_tests
                lsf_status = f" [Remaining:{remaining} P:{self.pending_jobs} R:{self.running_jobs}]"
            
            print(f"{status_icon} [{self.completed_tests:3d}/{self.total_tests}] "
                  f"{test_result.name:50s} "
                  f"({test_result.duration:6.1f}s) "
                  f"Progress: {progress:5.1f}% ETA: {eta}{lsf_status}")
            
            if test_result.status != 'PASS' and test_result.error_msg:
                print(f"    └─ Error: {test_result.error_msg}")
    
    def _ensure_log_copied(self, test_result):
        """Ensure test log is copied to appropriate logs subfolder based on test status"""
        try:
            # Determine target folder based on test status
            target_folder = self.pass_logs_folder if test_result.status == 'PASS' else self.no_pass_logs_folder
            target_log = target_folder / f"{test_result.name}.log"
            
            if target_log.exists():
                return  # Already copied
            
            # Try to find the log file in various locations
            possible_locations = [
                # Original log path from test result
                Path(test_result.log_file) if test_result.log_file else None,
                # In the run folder
                self.base_dir.parent / f"run_folder_{test_result.folder_id:02d}" / f"{test_result.name}.log",
                # In synopsys_sim directory  
                self.base_dir / f"{test_result.name}.log"
            ]
            
            for log_path in possible_locations:
                if log_path and log_path.exists():
                    shutil.copy2(log_path, target_log)
                    status_folder = "pass_logs" if test_result.status == 'PASS' else "no_pass_logs"
                    if self.verbose:
                        print(f"📋 Copied log to {status_folder}: {test_result.name}.log")
                    return
            
            print(f"⚠️  Warning: Could not find log file for {test_result.name}")
        except Exception as e:
            print(f"⚠️  Warning: Error copying log for {test_result.name}: {e}")
    
    def _copy_all_logs_to_logs_folder(self):
        """Ensure all test logs are in appropriate pass_logs or no_pass_logs folders"""
        print(f"\n📋 Verifying log organization...")
        verified_count = 0
        missing_count = 0
        
        for test_result in self.results:
            # Determine target folder based on test status
            target_folder = self.pass_logs_folder if test_result.status == 'PASS' else self.no_pass_logs_folder
            target_log = target_folder / f"{test_result.name}.log"
            
            # Check if already properly organized
            if target_log.exists():
                verified_count += 1
                continue
            
            # If not found, this indicates an issue with earlier copying
            missing_count += 1
            print(f"⚠️  Warning: Log not found in expected location for {test_result.name}")
        
        status_msg = f"✅ Verified {verified_count}/{len(self.results)} logs are properly organized"
        if missing_count > 0:
            status_msg += f" (⚠️  {missing_count} logs missing)"
        print(status_msg)
    
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
            
            # Create no_pass_list file
            no_pass_list_file = self.results_folder / "no_pass_list"
            with open(no_pass_list_file, 'w') as f:
                for result in failed_results:
                    f.write(f"{result.name}\n")
            
            for result in failed_results:
                print(f"   {result.status:8s} {result.name:50s} ({result.duration:6.1f}s)")
                if result.error_msg:
                    # Truncate long error messages
                    error_short = result.error_msg[:100] + "..." if len(result.error_msg) > 100 else result.error_msg
                    print(f"            └─ {error_short}")
                print(f"            └─ Log: {self._to_relative_path(self.no_pass_logs_folder / f'{result.name}.log')}")
            
            print(f"\n📝 Failed test list saved to: {self._to_relative_path(no_pass_list_file)}")
        
        # Save detailed results to results folder
        results_file = self.results_folder / f"regression_results_{self.timestamp}.txt"
        self._save_detailed_results(results_file)
        
        # Copy regression log to results folder
        regression_log = self.results_folder / "regression_summary.txt"
        shutil.copy2(results_file, regression_log)
        
        print(f"\n📄 Detailed results saved to: {self._to_relative_path(results_file)}")
        print(f"📁 All results in folder: {self._to_relative_path(self.results_folder)}")
        print(f"📋 Test logs organized in:")
        print(f"   ✅ Pass logs: {self._to_relative_path(self.pass_logs_folder)}")
        print(f"   ❌ Fail logs: {self._to_relative_path(self.no_pass_logs_folder)}")
        
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
            
            # Group results by status: TIMEOUT first, FAIL second, PASS third
            timeout_results = [r for r in self.results if r.status == 'TIMEOUT']
            fail_results = [r for r in self.results if r.status in ['FAIL', 'ERROR']]
            pass_results = [r for r in self.results if r.status == 'PASS']
            
            # Write TIMEOUT results first
            if timeout_results:
                f.write(f"TIMEOUT Tests ({len(timeout_results)}):\n")
                f.write(f"-" * 80 + "\n")
                for result in timeout_results:
                    f.write(f"Test:     {result.name}\n")
                    f.write(f"Status:   {result.status}\n")
                    f.write(f"Duration: {result.duration:.1f}s\n")
                    f.write(f"Folder:   {result.folder_id}\n")
                    f.write(f"Log:      {self._to_relative_path(self.no_pass_logs_folder / f'{result.name}.log')}\n")
                    if result.error_msg:
                        f.write(f"Error:    {result.error_msg}\n")
                    f.write(f"\n")
                f.write(f"\n")
            
            # Write FAIL results second
            if fail_results:
                f.write(f"FAILED Tests ({len(fail_results)}):\n")
                f.write(f"-" * 80 + "\n")
                for result in fail_results:
                    f.write(f"Test:     {result.name}\n")
                    f.write(f"Status:   {result.status}\n")
                    f.write(f"Duration: {result.duration:.1f}s\n")
                    f.write(f"Folder:   {result.folder_id}\n")
                    f.write(f"Log:      {self._to_relative_path(self.no_pass_logs_folder / f'{result.name}.log')}\n")
                    if result.error_msg:
                        f.write(f"Error:    {result.error_msg}\n")
                    f.write(f"\n")
                f.write(f"\n")
            
            # Write PASS results third
            if pass_results:
                f.write(f"PASSED Tests ({len(pass_results)}):\n")
                f.write(f"-" * 80 + "\n")
                for result in pass_results:
                    f.write(f"Test:     {result.name}\n")
                    f.write(f"Status:   {result.status}\n")
                    f.write(f"Duration: {result.duration:.1f}s\n")
                    f.write(f"Folder:   {result.folder_id}\n")
                    f.write(f"Log:      {self._to_relative_path(self.pass_logs_folder / f'{result.name}.log')}\n")
                    f.write(f"\n")
    
    def run_regression(self, test_list_file) :
        """Main method to run the regression"""
        try:
            print("🚀 Starting AXI4 Regression Runner")
            
            # Load test list
            tests = self._load_test_list(test_list_file)
            
            # Set max_parallel to number of tests if not specified
            if self.max_parallel is None:
                self.max_parallel = len(tests)
            
            execution_mode = "LSF" if self.use_lsf else "Local"
            print(f"⚙️  Configuration: {execution_mode} mode, {self.max_parallel} parallel workers, {self.timeout}s timeout")
            
            # Setup test folders
            folders = self._setup_test_folders()
            
            # Start timer
            self.start_time = time.time()
            
            print(f"\n🏃 Starting regression with {len(tests)} tests...")
            print("-" * 80)
            
            if self.use_lsf:
                return self._run_lsf_regression(tests, folders)
            else:
                return self._run_local_regression(tests, folders)
            
        except Exception as e:
            print(f"\n💥 Fatal error during regression: {e}")
            return 1
        finally:
            # Only clean up if successful
            if hasattr(self, '_regression_success') and self._regression_success:
                self._cleanup_all_folders()
                print("🧹 Cleaned up execution folders")
            else:
                print("⚠️  Keeping execution folders for debugging (run_folder_*)")
                print("💡 Manually remove with: rm -rf run_folder_*")
    
    def _run_lsf_regression(self, tests, folders):
        """Run regression using LSF job submission"""
        # Submit all jobs
        for i, test_name in enumerate(tests):
            if self.stop_all.is_set():
                break
                
            folder_id = i % len(folders)
            folder_path = folders[folder_id]
            
            try:
                self._submit_lsf_job(test_name, folder_path, folder_id)
            except Exception as e:
                error_result = TestResult(
                    name=test_name,
                    status='ERROR',
                    duration=0.0,
                    log_file='',
                    error_msg=f"LSF submission error: {str(e)}",
                    folder_id=folder_id
                )
                self._update_progress(error_result)
        
        print(f"📤 [LSF] Submitted {len(self.lsf_jobs)} jobs, monitoring for completion...")
        
        # Display initial LSF status
        self._display_lsf_status()
        
        # Monitor jobs until completion
        last_status_update = time.time()
        while self.completed_tests < self.total_tests and not self.stop_all.is_set():
            completed_job_ids = self._monitor_lsf_jobs()
            
            # Update LSF status every 10 seconds
            if time.time() - last_status_update >= 10:
                self._display_lsf_status()
                last_status_update = time.time()
            
            # Process completed jobs
            for job_id in completed_job_ids:
                job_info = self.lsf_jobs[job_id]
                test_name = job_info['test_name']
                folder_path = job_info['folder_path']
                folder_id = job_info['folder_id']
                
                # Calculate duration
                duration = job_info.get('end_time', time.time()) - job_info['submit_time']
                
                # Analyze results
                log_file = folder_path / f"{test_name}.log"
                if job_info['status'] == 'TIMEOUT':
                    status = 'TIMEOUT'
                    error_msg = f"LSF job timed out after {self.timeout}s"
                elif job_info['status'] == 'EXIT':
                    status = 'FAIL'
                    error_msg = "LSF job exited with error"
                else:
                    # Analyze log file for actual test result
                    if log_file.exists():
                        with open(log_file, 'r') as f:
                            log_content = f.read()
                        status, error_msg = self._analyze_test_result(log_file, log_content)
                    else:
                        status = 'ERROR'
                        error_msg = "Log file not found"
                
                result = TestResult(
                    name=test_name,
                    status=status,
                    duration=duration,
                    log_file=str(log_file),
                    error_msg=error_msg,
                    folder_id=folder_id
                )
                
                self._update_progress(result)
            
            # Sleep briefly before next monitoring cycle
            if self.completed_tests < self.total_tests:
                time.sleep(2)
        
        # Copy all logs to logs folder and print summary
        self._copy_all_logs_to_logs_folder()
        exit_code = self._print_summary()
        if exit_code == 0:
            self._regression_success = True
        return exit_code
    
    def _run_local_regression(self, tests, folders):
        """Run regression using local parallel execution with proper folder management"""
        # For now, let's use a simpler sequential approach to verify the fix works
        # We can re-enable parallelism once we confirm isolation is working
        
        if self.max_parallel == 1:
            # Sequential execution - use only first folder
            folder_id = 0
            folder_path = folders[0]
            
            for test_name in tests:
                if self.stop_all.is_set():
                    break
                
                # Ensure thorough cleanup before starting new test
                self._cleanup_vcs_artifacts(folder_path)
                self._cleanup_old_logs(folder_path, test_name)
                
                if self.verbose:
                    print(f"🔄 [Folder {folder_id:02d}] Running {test_name}")
                
                try:
                    result = self._run_single_test(test_name, folder_path, folder_id)
                    self._update_progress(result)
                except Exception as e:
                    error_result = TestResult(
                        name=test_name,
                        status='ERROR',
                        duration=0.0,
                        log_file='',
                        error_msg=f"Test execution error: {str(e)}",
                        folder_id=folder_id
                    )
                    self._update_progress(error_result)
        else:
            # Parallel execution with proper folder management
            from queue import Queue
            import threading
            
            # Create a queue of available folders
            available_folders = Queue()
            for i, folder_path in enumerate(folders):
                available_folders.put((i, folder_path))
            
            # Track active futures
            active_futures = {}
            pending_tests = list(tests)
            lock = threading.Lock()
            
            with ThreadPoolExecutor(max_workers=self.max_parallel) as executor:
                
                def submit_test_when_folder_available():
                    """Submit next test when a folder becomes available"""
                    while True:
                        with lock:
                            if not pending_tests:
                                return None
                            test_name = pending_tests.pop(0)
                        
                        # Wait for available folder
                        folder_id, folder_path = available_folders.get()
                        
                        # Cleanup before use
                        self._cleanup_vcs_artifacts(folder_path)
                        self._cleanup_old_logs(folder_path, test_name)
                        
                        if self.verbose:
                            print(f"🔄 [Folder {folder_id:02d}] Starting {test_name}")
                        
                        # Submit test
                        future = executor.submit(self._run_single_test, test_name, folder_path, folder_id)
                        
                        with lock:
                            active_futures[future] = {
                                'test_name': test_name,
                                'folder_id': folder_id,
                                'folder_path': folder_path
                            }
                        
                        return future
                
                # Submit initial tests
                while len(active_futures) < self.max_parallel and pending_tests:
                    submit_test_when_folder_available()
                
                # Process completions
                while active_futures:
                    if self.stop_all.is_set():
                        break
                    
                    for future in as_completed(active_futures):
                        with lock:
                            if future not in active_futures:
                                continue
                            future_info = active_futures.pop(future)
                        
                        folder_id = future_info['folder_id']
                        folder_path = future_info['folder_path']
                        
                        try:
                            result = future.result()
                            self._update_progress(result)
                        except Exception as e:
                            test_name = future_info['test_name']
                            error_result = TestResult(
                                name=test_name,
                                status='ERROR',
                                duration=0.0,
                                log_file='',
                                error_msg=f"Thread execution error: {str(e)}",
                                folder_id=folder_id
                            )
                            self._update_progress(error_result)
                        
                        # Return folder to queue
                        available_folders.put((folder_id, folder_path))
                        
                        # Submit next test
                        submit_test_when_folder_available()
                        break
        
        # Copy all logs to logs folder and print summary
        self._copy_all_logs_to_logs_folder()
        exit_code = self._print_summary()
        if exit_code == 0:
            self._regression_success = True
        return exit_code


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="AXI4 Regression Test Runner",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 axi4_regression.py                      # Auto parallel (# of tests), local mode
  python3 axi4_regression.py -p 5                 # Limit to 5 parallel workers
  python3 axi4_regression.py --timeout 900        # 15min timeout per test
  python3 axi4_regression.py --verbose            # Verbose execution output
  python3 axi4_regression.py --lsf                # Use LSF job submission
  python3 axi4_regression.py --lsf -p 10          # LSF mode with 10 parallel jobs
        """
    )
    
    parser.add_argument(
        '--max-parallel', '-p',
        type=int,
        default=None,
        help='Maximum number of parallel test executions (default: number of test cases)'
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
        '--lsf',
        action='store_true',
        help='Use LSF (Load Sharing Facility) for job submission and management'
    )
    
    parser.add_argument(
        '--test-list',
        default='axi4_transfers_regression.list',
        help='Path to test list file (default: axi4_transfers_regression.list)'
    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if args.max_parallel is not None and (args.max_parallel < 1 or args.max_parallel > 50):
        print("❌ Error: max-parallel must be between 1 and 50")
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
        verbose=args.verbose,
        use_lsf=args.lsf
    )
    
    try:
        return runner.run_regression(args.test_list)
    except KeyboardInterrupt:
        print("\n⚠️  Regression interrupted by user")
        return 1


if __name__ == "__main__":
    sys.exit(main())