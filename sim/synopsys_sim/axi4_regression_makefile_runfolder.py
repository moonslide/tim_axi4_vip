#!/usr/bin/env python3

"""
AXI4 VIP Regression Test Runner - Run Folder Version
Copies Makefile to each run_folder for proper test isolation
"""

import os
import sys
import subprocess
import time
import re
import shutil
import signal
import threading
import queue
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict, Tuple, Optional
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed
import gzip

class TestResult:
    def __init__(self, name, status, duration, log_file, error_msg=None, folder_id=0, 
                 uvm_errors=0, uvm_fatals=0, seed=None, command_add=None):
        self.name = name
        self.status = status
        self.duration = duration
        self.log_file = log_file
        self.error_msg = error_msg
        self.folder_id = folder_id
        self.uvm_errors = uvm_errors
        self.uvm_fatals = uvm_fatals
        self.seed = seed
        self.command_add = command_add

class OptimizedRegressionRunner:
    def __init__(self, max_parallel=None, timeout=900, verbose=False, use_lsf=False, 
                 fsdb_dump=False, coverage=False, log_wait_timeout=300, cleanup_delay=15,
                 compress_logs=True):
        # Parameters
        self.max_parallel = max_parallel or min(8, os.cpu_count() or 4)
        self.timeout = timeout
        self.verbose = verbose
        self.use_lsf = use_lsf
        self.fsdb_dump = fsdb_dump
        self.coverage = coverage
        self.log_wait_timeout = log_wait_timeout
        self.cleanup_delay = cleanup_delay
        self.compress_logs = compress_logs
        
        # Paths
        self.base_dir = Path.cwd()
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.results_folder = self.base_dir / f"regression_result_{self.timestamp}"
        self.logs_folder = self.results_folder / "logs"
        self.pass_logs_folder = self.logs_folder / "pass_logs"
        self.no_pass_logs_folder = self.logs_folder / "no_pass_logs"
        
        # Statistics
        self.results = []
        self.total_tests = 0
        self.completed_tests = 0
        self.passed_tests = 0
        self.failed_tests = 0
        self.start_time = None
        
        # LSF tracking
        self.lsf_jobs = {}
        
        # Thread safety
        self.lock = threading.Lock()
        
    def setup_folders(self):
        """Create result folders"""
        self.results_folder.mkdir(parents=True, exist_ok=True)
        self.logs_folder.mkdir(exist_ok=True)
        self.pass_logs_folder.mkdir(exist_ok=True)
        self.no_pass_logs_folder.mkdir(exist_ok=True)
        
        # Create coverage folder if needed
        if self.coverage:
            coverage_folder = self.results_folder / "coverage_collect"
            coverage_folder.mkdir(exist_ok=True)
            
    def run_regression(self, test_list_file='test.list'):
        """Main regression runner"""
        self.start_time = time.time()
        
        # Setup folders
        self.setup_folders()
        
        # Load tests
        tests = self._load_test_list(test_list_file)
        if not tests:
            print("❌ No tests found in test list")
            return
            
        self.total_tests = len(tests)
        
        # Print header
        print("=" * 80)
        print("🚀 STARTING AXI4 REGRESSION (Run Folder Optimized)")
        print("=" * 80)
        print(f"📊 Configuration:")
        print(f"   Tests to run: {self.total_tests}")
        print(f"   Max parallel: {self.max_parallel if not self.use_lsf else 'LSF'}")
        print(f"   Timeout: {self.timeout}s")
        print(f"   Execution mode: {'LSF' if self.use_lsf else 'Local'}")
        print(f"   Coverage: {'Enabled' if self.coverage else 'Disabled'}")
        print(f"   Log compression: {'Enabled' if self.compress_logs else 'Disabled'}")
        
        # Run tests
        if self.use_lsf:
            self._run_tests_lsf(tests)
        else:
            self._run_tests_local(tests)
            
        # Generate reports
        self._generate_reports()
        
        # Cleanup old folders
        if self.cleanup_delay > 0:
            self._cleanup_old_folders()
            
        # Print summary
        self._print_summary()
        
    def _run_tests_local(self, tests):
        """Run tests locally with parallel execution"""
        with ThreadPoolExecutor(max_workers=self.max_parallel) as executor:
            futures = []
            
            for test in tests:
                future = executor.submit(self._run_single_test, test)
                futures.append(future)
                
            for future in as_completed(futures):
                try:
                    result = future.result()
                    self._process_result(result)
                except Exception as e:
                    print(f"❌ Test execution error: {e}")
                    result = TestResult(
                        name="unknown",
                        status='ERROR',
                        duration=0,
                        log_file=None,
                        error_msg=str(e),
                        folder_id=test.get('folder_id', 0),
                        seed=test.get('seed'),
                        command_add=test.get('command_add')
                    )
                    self._process_result(result)
                    
    def _run_single_test(self, test):
        """Run a single test locally in its own run_folder"""
        test_name = test['name']
        base_name = test.get('base_name', test_name)
        folder_id = test.get('folder_id', 0)
        start_time = time.time()
        
        # Prepare folder with numbered naming convention in parent directory
        folder_path = self.base_dir.parent / f"run_folder_{folder_id:02d}"
        self._prepare_test_folder(folder_path, folder_id)
        
        # Copy Makefile to run folder
        makefile_src = self.base_dir / "Makefile"
        if not makefile_src.exists():
            makefile_src = self.base_dir.parent / "synopsys_sim" / "Makefile"
        
        if makefile_src.exists():
            shutil.copy2(makefile_src, folder_path / "Makefile")
        
        # Build command - now using local Makefile
        cmd = ['make', '-f', 'Makefile', 'sim']
        cmd.append(f"test={base_name}")
        if test.get('seed'):
            cmd.append(f"seed={test['seed']}")
        if test.get('command_add'):
            # Pass command_add with proper quoting
            cmd.append(f"command_add={test['command_add']}")
        if self.fsdb_dump:
            cmd.append("FSDB_DUMP=1")
        if self.coverage:
            cmd.append("COVERAGE=1")
            
        if self.verbose:
            print(f"📝 Running in {folder_path.name}: {' '.join(cmd)}")
            
        # Run test
        try:
            process = subprocess.Popen(
                cmd,
                cwd=str(folder_path),
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True
            )
            
            stdout, _ = process.communicate(timeout=self.timeout)
            
            # Wait for log to be written
            time.sleep(2)
            
            # Look for log file - it should be in the run folder now
            log_file = folder_path / f"{base_name}.log"
            
            # Check if log exists, if not wait a bit more
            if not log_file.exists():
                time.sleep(3)
                
            status, error_msg, uvm_errors, uvm_fatals = self._analyze_test_result(log_file, stdout)
            
            duration = time.time() - start_time
            
            # Copy log to results folder
            self._copy_log_to_results(log_file, test_name, status)
            
            return TestResult(
                name=test_name,
                status=status,
                duration=duration,
                log_file=str(log_file),
                error_msg=error_msg,
                folder_id=folder_id,
                uvm_errors=uvm_errors,
                uvm_fatals=uvm_fatals,
                seed=test.get('seed'),
                command_add=test.get('command_add')
            )
            
        except subprocess.TimeoutExpired:
            process.kill()
            duration = time.time() - start_time
            return TestResult(
                name=test_name,
                status='TIMEOUT',
                duration=duration,
                log_file=None,
                error_msg=f"Timeout after {self.timeout}s",
                folder_id=folder_id,
                seed=test.get('seed'),
                command_add=test.get('command_add')
            )
        except Exception as e:
            duration = time.time() - start_time
            return TestResult(
                name=test_name,
                status='ERROR',
                duration=duration,
                log_file=None,
                error_msg=str(e),
                folder_id=folder_id,
                seed=test.get('seed'),
                command_add=test.get('command_add')
            )
            
    def _run_tests_lsf(self, tests):
        """Run tests on LSF"""
        # Submit all jobs with small delay to avoid conflicts
        for i, test in enumerate(tests):
            folder_id = test.get('folder_id', 0)
            folder_path = self.base_dir.parent / f"run_folder_{folder_id:02d}"
            self._prepare_test_folder(folder_path, folder_id)
            
            # Copy Makefile to run folder
            makefile_src = self.base_dir / "Makefile"
            if not makefile_src.exists():
                makefile_src = self.base_dir.parent / "synopsys_sim" / "Makefile"
            
            if makefile_src.exists():
                shutil.copy2(makefile_src, folder_path / "Makefile")
            
            self._submit_lsf_job(test, folder_path, folder_id)
            
            # Small delay between submissions to avoid conflicts
            if i < len(tests) - 1:
                time.sleep(0.2)
            
        # Wait for completion
        print(f"\n⏳ Waiting for {len(self.lsf_jobs)} LSF jobs to complete...")
        
        while self.completed_tests < self.total_tests:
            completed_job_ids = self._monitor_lsf_jobs()
            
            for job_id in completed_job_ids:
                self._process_lsf_job_completion(job_id)
                
            if self.completed_tests < self.total_tests:
                time.sleep(5)
                
    def _submit_lsf_job(self, test, folder_path, folder_id):
        """Submit test to LSF from run folder"""
        test_name = test['name']
        base_name = test.get('base_name', test_name)
        
        # Create job script
        job_script = folder_path / f"lsf_job.sh"
        with open(job_script, 'w') as f:
            f.write("#!/bin/bash\n")
            f.write(f"#BSUB -J {test_name}\n")
            f.write(f"#BSUB -o {folder_path.absolute()}/{test_name}_lsf.out\n")
            f.write(f"#BSUB -e {folder_path.absolute()}/{test_name}_lsf.err\n")
            f.write(f"#BSUB -cwd {folder_path.absolute()}\n")
            f.write(f"#BSUB -W {int(self.timeout/60)}:00\n")
            f.write(f"\ncd {folder_path.absolute()}\n")
            f.write("# Clean using Makefile to ensure proper cleanup\n")
            f.write("make -f Makefile clean 2>/dev/null || true\n")
            f.write("# Additional cleanup of VCS files\n")
            f.write("rm -rf simv* *.daidir csrc* *.vdb* work* DVEfiles/ ucli.key 2>/dev/null\n")
            f.write("# Add small random delay to avoid simultaneous compilation\n")
            f.write("sleep $((RANDOM % 3))\n")
            
            # Use local Makefile in run folder
            cmd = f"make -f Makefile sim test={base_name}"
            if test.get('seed'):
                cmd += f" seed={test['seed']}"
            if test.get('command_add'):
                # Quote command_add to handle special characters
                cmd += f" command_add=\"{test['command_add']}\""
            if self.fsdb_dump:
                cmd += " FSDB_DUMP=1"
            if self.coverage:
                cmd += " COVERAGE=1"
                
            f.write(f"{cmd}\n")
            
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
            
            match = re.search(r'Job <(\d+)>', result.stdout)
            if match:
                job_id = match.group(1)
                self.lsf_jobs[job_id] = {
                    'test_name': test_name,
                    'base_name': base_name,
                    'folder_path': folder_path,
                    'folder_id': folder_id,
                    'submit_time': time.time(),
                    'status': 'PEND',
                    'seed': test.get('seed'),
                    'command_add': test.get('command_add')
                }
                print(f"📤 Submitted {test_name} as job {job_id} in {folder_path.name}")
                return job_id
                
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to submit {test_name}: {e.stderr}")
            return None
            
    def _monitor_lsf_jobs(self):
        """Monitor LSF jobs"""
        completed_jobs = []
        
        if not self.lsf_jobs:
            return completed_jobs
            
        try:
            # Query specific jobs
            job_ids = list(self.lsf_jobs.keys())
            result = subprocess.run(
                ['bjobs'] + job_ids,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True
            )
            
            # Parse output
            lines = result.stdout.strip().split('\n')
            if len(lines) > 1:
                for line in lines[1:]:
                    parts = line.split()
                    if len(parts) >= 3:
                        job_id = parts[0]
                        status = parts[2]
                        
                        if job_id in self.lsf_jobs:
                            old_status = self.lsf_jobs[job_id]['status']
                            self.lsf_jobs[job_id]['status'] = status
                            
                            if status in ['DONE', 'EXIT'] and old_status not in ['DONE', 'EXIT']:
                                self.lsf_jobs[job_id]['end_time'] = time.time()
                                completed_jobs.append(job_id)
                                
            # Check for jobs that disappeared (completed)
            for job_id in self.lsf_jobs:
                if job_id not in result.stdout and self.lsf_jobs[job_id]['status'] not in ['DONE', 'EXIT']:
                    # Job disappeared from bjobs - check if it actually ran
                    folder_path = self.lsf_jobs[job_id]['folder_path']
                    base_name = self.lsf_jobs[job_id]['base_name']
                    log_file = folder_path / f"{base_name}.log"
                    
                    # If log exists or LSF output exists, mark as DONE, otherwise EXIT
                    lsf_out = folder_path / f"{self.lsf_jobs[job_id]['test_name']}_lsf.out"
                    if log_file.exists() or lsf_out.exists():
                        self.lsf_jobs[job_id]['status'] = 'DONE'
                    else:
                        self.lsf_jobs[job_id]['status'] = 'EXIT'
                    
                    self.lsf_jobs[job_id]['end_time'] = time.time()
                    completed_jobs.append(job_id)
                    
        except subprocess.CalledProcessError:
            # bjobs failed - assume all jobs are done
            for job_id in self.lsf_jobs:
                if self.lsf_jobs[job_id]['status'] not in ['DONE', 'EXIT']:
                    self.lsf_jobs[job_id]['status'] = 'DONE'
                    self.lsf_jobs[job_id]['end_time'] = time.time()
                    completed_jobs.append(job_id)
                    
        return completed_jobs
        
    def _process_lsf_job_completion(self, job_id):
        """Process completed LSF job"""
        if job_id not in self.lsf_jobs:
            return
            
        job_info = self.lsf_jobs[job_id]
        test_name = job_info['test_name']
        base_name = job_info['base_name']
        folder_path = job_info['folder_path']
        
        # Analyze results - log should be in run folder
        log_file = folder_path / f"{base_name}.log"
        
        # Check LSF output files for additional info
        lsf_out = folder_path / f"{test_name}_lsf.out"
        lsf_err = folder_path / f"{test_name}_lsf.err"
        
        # Read LSF stdout to check for actual completion
        lsf_stdout_content = ""
        if lsf_out.exists():
            try:
                with open(lsf_out, 'r') as f:
                    lsf_stdout_content = f.read()
            except:
                pass
        
        lsf_error_msg = None
        if lsf_err.exists() and lsf_err.stat().st_size > 0:
            try:
                with open(lsf_err, 'r') as f:
                    lsf_error_msg = f.read()[:200]  # First 200 chars of error
            except:
                pass
        
        # Check if job actually completed by looking for log file or LSF output
        if job_info['status'] == 'EXIT' and not log_file.exists():
            # Only treat as LSF error if log doesn't exist
            status = 'FAIL'
            error_msg = f"LSF job exited with error{': ' + lsf_error_msg if lsf_error_msg else ''}"
            uvm_errors = 0
            uvm_fatals = 0
        else:
            # Analyze test result from log and LSF output
            status, error_msg, uvm_errors, uvm_fatals = self._analyze_test_result(log_file, lsf_stdout_content)
            
        duration = job_info.get('end_time', time.time()) - job_info['submit_time']
        
        # Copy log to results
        self._copy_log_to_results(log_file, test_name, status)
        
        result = TestResult(
            name=test_name,
            status=status,
            duration=duration,
            log_file=str(log_file),
            error_msg=error_msg,
            folder_id=job_info['folder_id'],
            uvm_errors=uvm_errors,
            uvm_fatals=uvm_fatals,
            seed=job_info.get('seed'),
            command_add=job_info.get('command_add')
        )
        
        self._process_result(result)
        
    def _analyze_test_result(self, log_file, stdout):
        """Analyze test result from log file and stdout"""
        try:
            # Read log file if it exists
            log_content = ""
            if log_file.exists():
                try:
                    with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
                        log_content = f.read()
                except Exception:
                    pass
                    
            # Combine for analysis
            full_output = stdout + "\n" + log_content
            
            # Check for pass patterns - comprehensive list
            pass_patterns = [
                r'TEST PASSED',
                r'TestCase.*PASSED',
                r'TEST RESULT:\s*PASS',
                r'test.*passed',
                r'PASS.*test.*passed',
                r'TEST.*DONE.*PASS',
                r'All tests passed',
                r'Near Timeout Exception Test PASSED',  # Specific for this test
                r'Exception.*Test.*PASSED',  # More general exception test pattern
                r'UVM_INFO.*Test.*PASSED'  # UVM info with test passed
            ]
            
            for pattern in pass_patterns:
                if re.search(pattern, full_output, re.IGNORECASE):
                    return 'PASS', None, 0, 0
                    
            # Extract UVM errors/fatals
            uvm_errors = 0
            uvm_fatals = 0
            uvm_match = re.search(r'UVM_ERROR\s*:\s*(\d+)', full_output)
            if uvm_match:
                uvm_errors = int(uvm_match.group(1))
            uvm_match = re.search(r'UVM_FATAL\s*:\s*(\d+)', full_output)
            if uvm_match:
                uvm_fatals = int(uvm_match.group(1))
                
            # Check for failures
            if uvm_errors > 0 or uvm_fatals > 0:
                return 'FAIL', f"UVM_ERROR: {uvm_errors}, UVM_FATAL: {uvm_fatals}", uvm_errors, uvm_fatals
                
            fail_patterns = [
                r'TEST FAILED',
                r'UVM_FATAL',
                r'UVM_ERROR.*[1-9]',
                r'Error-\[',
                r'Fatal:',
                r'Simulation.*failed'
            ]
            
            for pattern in fail_patterns:
                if re.search(pattern, full_output, re.IGNORECASE):
                    return 'FAIL', "Test failed based on log pattern", 0, 0
                    
            # No clear pass/fail - check if simulation completed
            if not log_file.exists():
                return 'FAIL', "Log file not found", 0, 0
                
            if len(log_content) < 100:
                return 'FAIL', "Log file too short - simulation may have crashed", 0, 0
                
            # Default to fail if no clear pass
            return 'FAIL', "No pass pattern found in log", 0, 0
            
        except Exception as e:
            return 'ERROR', f"Analysis error: {str(e)}", 0, 0
            
    def _copy_log_to_results(self, log_file, test_name, status):
        """Copy log to results folder"""
        if not log_file or not Path(log_file).exists():
            return
            
        target_folder = self.pass_logs_folder if status == 'PASS' else self.no_pass_logs_folder
        target_log = target_folder / f"{test_name}.log"
        
        try:
            if self.compress_logs:
                with open(log_file, 'rb') as f_in:
                    with gzip.open(f"{target_log}.gz", 'wb') as f_out:
                        shutil.copyfileobj(f_in, f_out)
            else:
                shutil.copy2(log_file, target_log)
        except Exception as e:
            if self.verbose:
                print(f"⚠️  Failed to copy log: {e}")
                
    def _process_result(self, result):
        """Process test result"""
        self.results.append(result)
        self.completed_tests += 1
        
        if result.status == 'PASS':
            self.passed_tests += 1
        else:
            self.failed_tests += 1
            
        # Display progress
        progress = (self.completed_tests / self.total_tests) * 100
        elapsed = time.time() - self.start_time
        
        status_icon = {
            'PASS': '✅',
            'FAIL': '❌',
            'TIMEOUT': '⏰',
            'ERROR': '💥'
        }.get(result.status, '❓')
        
        if self.completed_tests > 0:
            avg_time = elapsed / self.completed_tests
            remaining = self.total_tests - self.completed_tests
            eta_seconds = remaining * avg_time / max(1, self.max_parallel)
            eta = str(timedelta(seconds=int(eta_seconds)))
        else:
            eta = "Unknown"
            
        print(f"{status_icon} [{self.completed_tests:3d}/{self.total_tests}] "
              f"{result.name:50s} ({result.duration:6.1f}s) "
              f"Progress: {progress:5.1f}% ETA: {eta}")
              
        if result.status != 'PASS' and result.error_msg:
            print(f"    └─ {result.error_msg[:100]}")
            
    def _prepare_test_folder(self, folder_path, folder_id):
        """Prepare test folder"""
        if folder_path.exists():
            # Clean up any existing VCS database files
            try:
                # Remove VCS specific files that might cause conflicts
                for pattern in ['simv*', '*.daidir', 'csrc*', '*.vdb*', 'work*']:
                    for file in folder_path.glob(pattern):
                        if file.is_file():
                            file.unlink()
                        elif file.is_dir():
                            shutil.rmtree(file, ignore_errors=True)
            except:
                pass
            shutil.rmtree(folder_path, ignore_errors=True)
        folder_path.mkdir(parents=True, exist_ok=True)
        
        # Copy and fix compile file paths
        orig_compile = self.base_dir.parent / 'axi4_compile.f'
        if orig_compile.exists():
            # Copy compile file and adjust paths
            target_compile = folder_path / 'axi4_compile.f'
            with open(orig_compile, 'r') as f_in:
                content = f_in.read()
            
            # We're in /sim/run_folder_XX, compile file expects /sim/synopsys_sim
            # So paths starting with ../../ should remain the same (they go to project root)
            # No adjustment needed since we're at the same level as synopsys_sim
            
            with open(target_compile, 'w') as f_out:
                f_out.write(content)
            
    def _load_test_list(self, test_list_file):
        """Load and expand test list"""
        test_file = self.base_dir / test_list_file
        if not test_file.exists():
            return []
            
        tests = []
        expanded_tests = []
        
        with open(test_file, 'r') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                    
                parts = line.split()
                if not parts:
                    continue
                    
                test_name = parts[0]
                run_cnt = 1
                seed = None
                command_add = None
                
                for part in parts[1:]:
                    if part.startswith('run_cnt='):
                        run_cnt = int(part.split('=')[1])
                    elif part.startswith('seed='):
                        seed = part.split('=')[1]
                    elif part.startswith('command_add='):
                        command_add = part.split('=', 1)[1]
                        
                tests.append({
                    'name': test_name,
                    'run_cnt': run_cnt,
                    'seed': seed,
                    'command_add': command_add
                })
                
        # Expand tests with run_cnt
        folder_id = 0
        for test in tests:
            if test['run_cnt'] > 1:
                print(f"📋 Expanded {test['name']} into {test['run_cnt']} runs")
                
            for i in range(test['run_cnt']):
                expanded_name = f"{test['name']}_{i+1}" if test['run_cnt'] > 1 else test['name']
                expanded_tests.append({
                    'name': expanded_name,
                    'base_name': test['name'],
                    'seed': test['seed'],
                    'command_add': test['command_add'],
                    'folder_id': folder_id
                })
                folder_id += 1
                
        return expanded_tests
        
    def _generate_reports(self):
        """Generate regression reports"""
        timestamp_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # Generate pass list
        pass_file = self.results_folder / "pass_list"
        with open(pass_file, 'w') as f:
            f.write(f"# Pass list generated on {timestamp_str}\n")
            f.write("# Test execution parameters for passed tests\n")
            f.write("# Format: test_name [seed=XXX] [command_add=XXX]\n")
            
            passed = [r for r in self.results if r.status == 'PASS']
            f.write(f"# Total passed runs: {len(passed)}\n")
            f.write("#\n")
            
            for result in passed:
                line = result.name
                if result.seed:
                    line += f" seed={result.seed}"
                if result.command_add:
                    line += f" command_add={result.command_add}"
                f.write(f"{line}\n")
                
        # Generate no-pass list
        no_pass_file = self.results_folder / "no_pass_list"
        with open(no_pass_file, 'w') as f:
            f.write(f"# No pass list generated on {timestamp_str}\n")
            f.write("# Test execution parameters for failed tests\n")
            f.write("# Format: test_name [seed=XXX] [command_add=XXX]\n")
            
            failed = [r for r in self.results if r.status != 'PASS']
            f.write(f"# Total failed runs: {len(failed)}\n")
            f.write("#\n")
            
            for result in failed:
                line = result.name
                if result.seed:
                    line += f" seed={result.seed}"
                if result.command_add:
                    line += f" command_add={result.command_add}"
                f.write(f"{line}\n")
                
        # Generate running list
        running_file = self.results_folder / "running_list"
        with open(running_file, 'w') as f:
            f.write(f"# Running list generated on {timestamp_str}\n")
            f.write("# All tests executed in this regression\n")
            f.write(f"# Total runs: {len(self.results)}\n")
            f.write("#\n")
            
            for result in self.results:
                status_str = "PASS" if result.status == 'PASS' else "FAIL"
                line = f"{result.name} [{status_str}]"
                if result.seed:
                    line += f" seed={result.seed}"
                if result.command_add:
                    line += f" command_add={result.command_add}"
                f.write(f"{line}\n")
                
        # Generate detailed summary
        summary_file = self.results_folder / "regression_summary.txt"
        with open(summary_file, 'w') as f:
            f.write("AXI4 Regression Summary\n")
            f.write(f"Generated: {timestamp_str}\n")
            f.write("=" * 80 + "\n\n")
            
            f.write("Statistics:\n")
            f.write(f"  Total Tests: {self.total_tests}\n")
            f.write(f"  Passed: {self.passed_tests}\n")
            f.write(f"  Failed: {self.failed_tests}\n")
            
            pass_rate = (self.passed_tests / self.total_tests * 100) if self.total_tests > 0 else 0
            f.write(f"  Pass Rate: {pass_rate:.1f}%\n")
            
            total_time = time.time() - self.start_time
            f.write(f"  Total Time: {str(timedelta(seconds=int(total_time)))}\n")
            
            # List failed tests
            failed = [r for r in self.results if r.status != 'PASS']
            if failed:
                f.write("\nFailed Tests:\n")
                f.write("-" * 80 + "\n")
                for result in failed:
                    f.write(f"{result.status:8s} {result.name:50s} ({result.duration:.1f}s)\n")
                    if result.error_msg:
                        f.write(f"         Error: {result.error_msg}\n")
                        
        # Also save with timestamp in filename
        results_file = self.results_folder / f"regression_results_{self.timestamp}.txt"
        shutil.copy2(summary_file, results_file)
        
    def _cleanup_old_folders(self):
        """Clean up old test folders after delay"""
        if self.verbose:
            print(f"\n🧹 Cleaning up test folders after {self.cleanup_delay}s delay...")
            
        time.sleep(self.cleanup_delay)
        
        # Clean up run folders using folder_id in parent directory
        for result in self.results:
            folder_path = self.base_dir.parent / f"run_folder_{result.folder_id:02d}"
            if folder_path.exists():
                try:
                    shutil.rmtree(folder_path, ignore_errors=True)
                except Exception:
                    pass
                    
    def _print_summary(self):
        """Print final summary"""
        print("\n" + "=" * 80)
        print("🏁 REGRESSION SUMMARY")
        print("=" * 80)
        
        print(f"📊 Statistics:")
        print(f"   Total Tests:     {self.total_tests}")
        print(f"   Passed:          {self.passed_tests} ({self.passed_tests/self.total_tests*100:.1f}%)")
        print(f"   Failed:          {self.failed_tests} ({self.failed_tests/self.total_tests*100:.1f}%)")
        
        total_time = time.time() - self.start_time
        print(f"   Total Time:      {str(timedelta(seconds=int(total_time)))}")
        print(f"   Results folder:  {self.results_folder}")
        
        # Show failed tests
        failed = [r for r in self.results if r.status != 'PASS']
        if failed:
            print("\n❌ Failed Tests:")
            for result in failed[:10]:  # Show first 10
                print(f"   - {result.name}: {result.error_msg or result.status}")
            if len(failed) > 10:
                print(f"   ... and {len(failed) - 10} more")
                
        print("\n" + "=" * 80)


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='AXI4 VIP Regression Runner - Run Folder Optimized')
    parser.add_argument('--test-list', default='test.list', help='Test list file')
    parser.add_argument('--max-parallel', type=int, help='Max parallel tests')
    parser.add_argument('--timeout', type=int, default=900, help='Test timeout (seconds)')
    parser.add_argument('--lsf', action='store_true', help='Use LSF for execution')
    parser.add_argument('--fsdb', action='store_true', help='Enable FSDB dump')
    parser.add_argument('--cov', action='store_true', help='Enable coverage')
    parser.add_argument('--no-compress', action='store_true', help='Disable log compression')
    parser.add_argument('--verbose', action='store_true', help='Verbose output')
    parser.add_argument('--cleanup-delay', type=int, default=15, help='Delay before cleanup (seconds, 0 to keep folders)')
    
    args = parser.parse_args()
    
    # Create runner
    runner = OptimizedRegressionRunner(
        max_parallel=args.max_parallel,
        timeout=args.timeout,
        verbose=args.verbose,
        use_lsf=args.lsf,
        fsdb_dump=args.fsdb,
        coverage=args.cov,
        compress_logs=not args.no_compress,
        cleanup_delay=args.cleanup_delay
    )
    
    # Run regression
    try:
        runner.run_regression(args.test_list)
    except KeyboardInterrupt:
        print("\n\n⚠️  Regression interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Regression failed: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()