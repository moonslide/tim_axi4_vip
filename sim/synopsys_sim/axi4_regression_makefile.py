#!/usr/bin/env python
"""
AXI4 Regression Test Runner - Makefile Version
==============================================

This script runs AXI4 testcases sequentially using Makefile targets.
It provides the same functionality as axi4_regression.py but delegates
VCS execution to make targets instead of generating commands directly.

Features:
- Sequential execution using make targets
- Each test runs in isolated run_folder_XX directory
- Progress tracking and real-time status
- Comprehensive logging and error analysis
- Creates timestamped results folder with all logs
- Generates no_pass_list for failed tests
- Timeout handling for stuck tests
- Summary report with failure details
- Configurable log file wait timeout for large designs

Configuration Notes:
- Default log wait timeout: 30 seconds (suitable for most designs)
- Default cleanup delay: 15 seconds (enhanced for VCS database corruption prevention)
- For large designs with slow compilation: use --log-wait-timeout 60 or higher
- Log wait timeout can be configured from 5 seconds to unlimited
- Data preservation: Last test data is kept in each folder until a new test starts (for debugging)

Usage:
    python3 axi4_regression_makefile.py [--timeout SECONDS] [--verbose] [--log-wait-timeout SECONDS]
"""

import os
import sys
import subprocess
import threading
import time
import re
import argparse
import shutil
import random
import fcntl
import tempfile
from pathlib import Path
from datetime import datetime, timedelta
import signal
import json


class TestResult:
    """Container for test execution results"""
    def __init__(self, name, status, duration, log_file, error_msg=None, folder_id=0, uvm_errors=0, uvm_fatals=0, seed=None, command_add=None):
        self.name = name
        self.status = status  # 'PASS', 'FAIL', 'TIMEOUT', 'ERROR'
        self.duration = duration
        self.log_file = log_file
        self.error_msg = error_msg
        self.folder_id = folder_id
        self.uvm_errors = uvm_errors
        self.uvm_fatals = uvm_fatals
        self.seed = seed
        self.command_add = command_add


class RegressionRunner:
    """Main regression test runner class using Makefile"""
    
    def __init__(self, max_parallel=None, timeout=900, verbose=False, use_lsf=False, fsdb_dump=False, coverage=False, log_wait_timeout=300, cleanup_delay=15):
        self.max_parallel = max_parallel  # Will be set to number of tests if None
        self.timeout = timeout
        self.verbose = verbose
        self.use_lsf = use_lsf
        self.fsdb_dump = fsdb_dump
        self.coverage = coverage
        self.log_wait_timeout = log_wait_timeout  # Configurable log file wait timeout
        self.cleanup_delay = cleanup_delay  # Configurable delay after cleanup
        self.base_dir = Path.cwd()
        self.results = []
        self.stop_all = threading.Event()
        
        # LSF job tracking
        self.lsf_jobs = {}  # job_id -> test_info
        self.pending_jobs = 0
        self.running_jobs = 0
        
        # VCS startup serialization lock to prevent database corruption in parallel mode
        self.vcs_startup_lock = threading.Lock()
        
        # Results folder with timestamp
        self.timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        self.results_folder = self.base_dir / f"regression_result_{self.timestamp}"
        self.logs_folder = self.results_folder / "logs"
        self.pass_logs_folder = self.logs_folder / "pass_logs"
        self.no_pass_logs_folder = self.logs_folder / "no_pass_logs"
        
        # Coverage collection folder
        if self.coverage:
            self.coverage_folder = self.results_folder / "coverage_collect"
        else:
            self.coverage_folder = None
        
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
        
        # Check Makefile exists
        self._check_makefile()
    
    def _check_makefile(self):
        """Check if Makefile exists in current directory"""
        makefile_path = self.base_dir / "Makefile"
        if not makefile_path.exists():
            print(f"❌ Error: Makefile not found at {makefile_path}")
            print("💡 This script requires a Makefile with 'sim' target")
            sys.exit(1)
        else:
            print(f"✅ Found Makefile at {makefile_path}")
    
    def _to_relative_path(self, path):
        """Convert absolute path to relative path for display"""
        try:
            # Convert to Path object if needed
            if not isinstance(path, Path):
                path = Path(path)
            
            # Try to make path relative to current working directory
            return path.relative_to(Path.cwd())
        except (ValueError, TypeError, OSError, FileNotFoundError):
            # If can't make relative or cwd fails, return the path name only
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
        
        # Note: Removed _cleanup_all_folders() call to preserve run_folder data
        print("💡 Keeping all execution folders (run_folder_*) for debugging")
        sys.exit(1)
    
    def _load_test_list(self, test_list_file):
        """Load test names from regression list file
        
        Supports format:
        - testname                                 (run once)
        - testname run_cnt=N                       (run N times with numbered logs)
        - testname seed=123                        (run once with custom seed)
        - testname command_add=+define+XXX         (run once with custom VCS command)
        - testname run_cnt=N seed=123 command_add=+define+XXX  (combine parameters)
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
            
            # Parse and expand tests with parameters
            for test_entry in tests:
                parts = test_entry.split()
                if not parts:
                    print(f"⚠️  Warning: Empty test entry, skipping")
                    continue
                    
                test_name = parts[0]
                
                # Parse parameters
                repeat_count = 1
                custom_seed = None
                command_add = None
                
                for part in parts[1:]:
                    if part.startswith('run_cnt='):
                        try:
                            repeat_count = int(part.split('=')[1])
                            if repeat_count < 1:
                                raise ValueError(f"run_cnt must be >= 1, got {repeat_count}")
                        except (ValueError, IndexError) as e:
                            print(f"⚠️  Warning: Invalid run_cnt format in '{test_entry}': {e}")
                            print(f"    Expected format: 'testname run_cnt=N'")
                            repeat_count = 1
                    elif part.startswith('seed='):
                        try:
                            custom_seed = int(part.split('=')[1])
                            if custom_seed < 0 or custom_seed > 2**31-1:
                                raise ValueError(f"seed must be 0 <= seed <= 2^31-1, got {custom_seed}")
                        except (ValueError, IndexError) as e:
                            print(f"⚠️  Warning: Invalid seed format in '{test_entry}': {e}")
                            print(f"    Expected format: 'testname seed=123'")
                            custom_seed = None
                    elif part.startswith('command_add='):
                        try:
                            command_add = part.split('=', 1)[1]  # Use split with maxsplit=1 to handle complex commands
                            if not command_add:
                                raise ValueError("command_add cannot be empty")
                        except (ValueError, IndexError) as e:
                            print(f"⚠️  Warning: Invalid command_add format in '{test_entry}': {e}")
                            print(f"    Expected format: 'testname command_add=+define+XXX'")
                            command_add = None
                
                # Create test objects with parameters
                if repeat_count > 1:
                    # Add numbered test entries
                    for i in range(1, repeat_count + 1):
                        test_obj = {
                            'name': f"{test_name}_{i}",
                            'base_name': test_name,
                            'run_number': i,
                            'seed': custom_seed,
                            'command_add': command_add
                        }
                        expanded_tests.append(test_obj)
                    
                    params_str = []
                    if custom_seed is not None:
                        params_str.append(f"seed={custom_seed}")
                    if command_add is not None:
                        params_str.append(f"command_add={command_add}")
                    params_info = f" with {', '.join(params_str)}" if params_str else ""
                    print(f"📋 Expanded {test_name} into {repeat_count} runs: {test_name}_1 to {test_name}_{repeat_count}{params_info}")
                else:
                    # Single test
                    test_obj = {
                        'name': test_name,
                        'base_name': test_name,
                        'run_number': 1,
                        'seed': custom_seed,
                        'command_add': command_add
                    }
                    expanded_tests.append(test_obj)
                    
                    if custom_seed is not None or command_add is not None:
                        params_str = []
                        if custom_seed is not None:
                            params_str.append(f"seed={custom_seed}")
                        if command_add is not None:
                            params_str.append(f"command_add={command_add}")
                        print(f"📋 Loaded {test_name} with {', '.join(params_str)}")
                
            self.total_tests = len(expanded_tests)
            print(f"📋 Loaded {len(tests)} test entries from {test_list_file}")
            print(f"📋 Expanded to {self.total_tests} total test runs")
            return expanded_tests
            
        except FileNotFoundError:
            raise FileNotFoundError(f"Test list file not found: {test_list_file}")
        except Exception as e:
            raise Exception(f"Error reading test list file: {e}")
    
    def _remove_suffix_for_lists(self, test_name):
        """Remove _xx suffix from test names for list files (requirement 2)
        
        Examples:
        - 'axi4_wstrb_test_1' -> 'axi4_wstrb_test'
        - 'axi4_wstrb_test_10' -> 'axi4_wstrb_test'
        - 'axi4_wstrb_test' -> 'axi4_wstrb_test' (unchanged)
        """
        import re
        match = re.match(r'^(.+)_(\d+)$', test_name)
        if match:
            return match.group(1)  # Return base name without _N suffix
        else:
            return test_name  # Return as-is if no _N suffix found
    
    def _generate_running_list(self, results):
        """Generate a running_list file with actual test execution parameters"""
        running_list_file = self.results_folder / "running_list"
        
        try:
            with open(running_list_file, 'w') as f:
                f.write(f"# Running list generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"# Test execution parameters actually used in this regression run\n")
                f.write(f"# Format: test_name [seed=XXX] [command_add=XXX]\n")
                f.write(f"# Total tests: {len(results)}\n")
                f.write("#\n")
                
                for result in results:
                    # Remove _N suffix from test name for cleaner display
                    base_name = self._remove_suffix_for_lists(result.name)
                    actual_seed = result.seed
                    command_add = result.command_add
                    
                    # Build the parameter line with actual execution parameters
                    params = []
                    if actual_seed is not None:
                        params.append(f"seed={actual_seed}")
                    if command_add is not None:
                        params.append(f"command_add={command_add}")
                    
                    if params:
                        f.write(f"{base_name} {' '.join(params)}\n")
                    else:
                        f.write(f"{base_name}\n")
            
            print(f"📋 Generated running list: {self._to_relative_path(running_list_file)}")
            
        except Exception as e:
            print(f"⚠️  Warning: Could not generate running list: {e}")
    
    def _generate_pass_list(self, results):
        """Generate a pass_list file with passed test execution parameters"""
        pass_list_file = self.results_folder / "pass_list"
        
        try:
            passed_results = [r for r in results if r.status == 'PASS']
            
            with open(pass_list_file, 'w') as f:
                f.write(f"# Pass list generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"# Test execution parameters for passed tests (individual runs with actual seeds)\n")
                f.write(f"# Format: test_name [seed=XXX] [command_add=XXX]\n")
                f.write(f"# Total passed runs: {len(passed_results)}\n")
                f.write("#\n")
                
                for result in sorted(passed_results, key=lambda r: r.name):
                    # Remove _N suffix from test name for cleaner display
                    base_name = self._remove_suffix_for_lists(result.name)
                    actual_seed = result.seed
                    command_add = result.command_add
                    
                    # Build the parameter line with actual execution parameters
                    params = []
                    if actual_seed is not None:
                        params.append(f"seed={actual_seed}")
                    if command_add is not None:
                        params.append(f"command_add={command_add}")
                    
                    if params:
                        f.write(f"{base_name} {' '.join(params)}\n")
                    else:
                        f.write(f"{base_name}\n")
            
            print(f"📋 Generated pass list: {self._to_relative_path(pass_list_file)}")
            
        except Exception as e:
            print(f"⚠️  Warning: Could not generate pass list: {e}")
    
    def _generate_no_pass_list(self, results):
        """Generate a no_pass_list file with failed test execution parameters"""
        no_pass_list_file = self.results_folder / "no_pass_list"
        
        try:
            failed_results = [r for r in results if r.status != 'PASS']
            
            with open(no_pass_list_file, 'w') as f:
                f.write(f"# No pass list generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"# Test execution parameters for failed tests (individual runs with actual seeds)\n")
                f.write(f"# Format: test_name [seed=XXX] [command_add=XXX]\n")
                f.write(f"# Total failed runs: {len(failed_results)}\n")
                f.write("#\n")
                
                for result in sorted(failed_results, key=lambda r: r.name):
                    # Remove _N suffix from test name for cleaner display
                    base_name = self._remove_suffix_for_lists(result.name)
                    actual_seed = result.seed
                    command_add = result.command_add
                    
                    # Build the parameter line with actual execution parameters
                    params = []
                    if actual_seed is not None:
                        params.append(f"seed={actual_seed}")
                    if command_add is not None:
                        params.append(f"command_add={command_add}")
                    
                    if params:
                        f.write(f"{base_name} {' '.join(params)}\n")
                    else:
                        f.write(f"{base_name}\n")
                    
                    # Add status info as comment for debugging
                    f.write(f"#   Status: {result.status}, Duration: {result.duration:.1f}s\n")
            
            print(f"📋 Generated no pass list: {self._to_relative_path(no_pass_list_file)}")
            
        except Exception as e:
            print(f"⚠️  Warning: Could not generate no pass list: {e}")
    
    def _cleanup_existing_folders(self):
        """Clean up any existing run_folder_xx directories and all artifacts before starting"""
        print("🧹 Performing initial cleanup of all run folders and simulation artifacts...")
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
        
        # Also clean current directory of any leftover artifacts
        try:
            cleanup_patterns = [
                'simv*', 'csrc*', '*.daidir*', '*.vdb*', '*.fsdb*',
                'vc_hdrs.h', 'ucli.key', 'work.lib++*', 'work/', 
                'transcript*', 'waveform.wlf*', 'verdi*', 'tr_db.log*',
                '*.log', '*.vpd', '*.shm', '*.trn', '*.dsn', 
                'DVEfiles/', 'inter.vpd', 'vcdplus.vpd', 'novas.*',
                'urgReport/', 'AN.DB/', 'novas_dump.log', 'nWaveLog/'
            ]
            
            for pattern in cleanup_patterns:
                for artifact in self.base_dir.glob(pattern):
                    try:
                        if artifact.is_dir():
                            shutil.rmtree(artifact, ignore_errors=True)
                        else:
                            artifact.unlink()
                    except (FileNotFoundError, PermissionError):
                        pass
        except Exception as e:
            print(f"⚠️  Warning: Could not clean current directory: {e}")
        
        if folders_cleaned > 0:
            print(f"✅ Cleaned up {folders_cleaned} existing run folders and all simulation artifacts")
        else:
            print("✅ Cleaned up all simulation artifacts (no existing run folders found)")

    def _setup_test_folders(self) :
        """Create and setup test execution folders"""
        folders = []
        
        # Keep existing run folders to preserve last run data for debugging
        # Only clean up artifacts when folder is reused during this regression
        
        # Create results folder and logs subfolders
        self.results_folder.mkdir(exist_ok=True)
        self.logs_folder.mkdir(exist_ok=True)
        self.pass_logs_folder.mkdir(exist_ok=True)
        self.no_pass_logs_folder.mkdir(exist_ok=True)
        
        # Create coverage folder if coverage collection is enabled
        if self.coverage:
            self.coverage_folder.mkdir(exist_ok=True)
        
        print(f"📁 Created results folder: {self._to_relative_path(self.results_folder)}")
        
        # Verify the folder was actually created
        if not self.results_folder.exists():
            raise RuntimeError(f"Failed to create results folder: {self.results_folder}")
        
        print(f"   └─ logs folder: {self._to_relative_path(self.logs_folder)}")
        print(f"       ├─ pass_logs folder: {self._to_relative_path(self.pass_logs_folder)}")
        print(f"       └─ no_pass_logs folder: {self._to_relative_path(self.no_pass_logs_folder)}")
        
        if self.coverage:
            print(f"       └─ coverage_collect folder: {self._to_relative_path(self.coverage_folder)}")
        
        # LSF mode: Create one folder per test for complete isolation
        if self.use_lsf:
            num_folders = self.total_tests
            print(f"🔧 Setting up {num_folders} execution folders for LSF mode (one per test)...")
            
            for i in range(num_folders):
                folder_name = f"run_folder_{i:02d}"
                folder_path = self.base_dir.parent / folder_name
                
                # Create folder if it doesn't exist, preserve existing content
                folder_path.mkdir(exist_ok=True)
                
                # Copy Makefile to each run folder for proper isolation
                makefile_src = self.base_dir / "Makefile"
                makefile_dst = folder_path / "Makefile"
                
                try:
                    shutil.copy2(makefile_src, makefile_dst)
                    if self.verbose:
                        print(f"📋 [Folder {i:02d}] Copied Makefile for isolated execution")
                except Exception as e:
                    print(f"⚠️  Warning: Could not copy Makefile to {folder_path}: {e}")
                
                # Create compile file with adjusted paths for this run folder
                try:
                    self._create_compile_file_for_folder(folder_path, i)
                    if self.verbose:
                        print(f"📋 [Folder {i:02d}] Created compile file for isolated execution")
                except Exception as e:
                    print(f"⚠️  Warning: Could not create compile file for {folder_path}: {e}")
                
                folders.append(folder_path)
                
            print(f"✅ Set up {len(folders)} execution folders for LSF mode (complete isolation)")
        
        else:
            # Local mode: Set up parallel folders based on number of tests and max_parallel
            num_folders = min(self.max_parallel, self.total_tests)
            print(f"🔧 Setting up {num_folders} parallel execution folders (max_parallel={self.max_parallel}, total_tests={self.total_tests})...")
            
            for i in range(num_folders):
                folder_name = f"run_folder_{i:02d}"
                folder_path = self.base_dir.parent / folder_name
                
                # Create folder if it doesn't exist, preserve existing content
                folder_path.mkdir(exist_ok=True)
                
                # Copy Makefile to each run folder for proper isolation
                makefile_src = self.base_dir / "Makefile"
                makefile_dst = folder_path / "Makefile"
                
                try:
                    shutil.copy2(makefile_src, makefile_dst)
                    if self.verbose:
                        print(f"📋 [Folder {i:02d}] Copied Makefile for isolated execution")
                except Exception as e:
                    print(f"⚠️  Warning: Could not copy Makefile to {folder_path}: {e}")
                
                # Create compile file with adjusted paths for this run folder
                try:
                    self._create_compile_file_for_folder(folder_path, i)
                    if self.verbose:
                        print(f"📋 [Folder {i:02d}] Created compile file for isolated execution")
                except Exception as e:
                    print(f"⚠️  Warning: Could not create compile file for {folder_path}: {e}")
                
                folders.append(folder_path)
                
            print(f"✅ Set up {len(folders)} execution folders (existing data preserved)")
            
        return folders
    
    
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
    
    def _submit_lsf_job(self, test_obj, folder_path, folder_id):
        """Submit a test job to LSF using make and return job ID"""
        # Extract test information from test object
        test_name = test_obj['name']
        custom_seed = test_obj.get('seed')
        command_add = test_obj.get('command_add')
        
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
            
            # Use custom seed if provided, otherwise generate random seed
            if custom_seed is not None:
                seed_value = custom_seed
                f.write(f'# Using custom seed: {seed_value}\n')
            else:
                # Generate a more random seed using multiple entropy sources
                seed_value = random.randint(1, 2**31-1)
                seed_value ^= int(time.time() * 1000000) & 0x7FFFFFFF  # Mix with microsecond timestamp
                seed_value ^= hash(test_name) & 0x7FFFFFFF  # Mix with test name hash
                seed_value &= 0x7FFFFFFF  # Ensure positive 32-bit value
                f.write(f'# Generated random seed: {seed_value}\n')
            
            # Build make command with appropriate variables
            f.write('# Run test using make\n')
            f.write(f'cd {folder_path} && ')
            f.write(f'make -f ../synopsys_sim/Makefile sim test={base_test_name} ')  # Reference Makefile in synopsys_sim
            f.write(f'LOG_FILE={test_name}.log ')  # Pass the expected log file name to Makefile
            f.write(f'SEED={seed_value} ')
            
            if self.fsdb_dump:
                f.write(f'FSDB_DUMP=1 ')
            
            if self.coverage:
                f.write(f'COVERAGE=1 ')
                f.write(f'COV_DIR={test_name}.vdb ')
                f.write(f'COVERAGE_FLAGS=1 ')
            
            if command_add:
                f.write(f'COMMAND_ADD="{command_add}" ')
            
            f.write('\n')
        
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
                    'status': 'PEND',  # LSF job status
                    'seed': seed_value,
                    'command_add': command_add
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
        """Keep all test execution folders (DISABLED cleanup to preserve data permanently)"""
        print("📁 Preserving all execution folders permanently...")
        existing_folders = []
        
        # LSF mode: Check for all test folders, local mode: Check for parallel folders
        num_folders_to_check = self.total_tests if self.use_lsf else self.max_parallel
        
        for i in range(num_folders_to_check):
            folder_name = f"run_folder_{i:02d}"
            folder_path = self.base_dir.parent / folder_name
            if folder_path.exists():
                existing_folders.append((i, folder_path))
        
        # Report existing folders but do not remove any
        for folder_id, folder_path in existing_folders:
            print(f"📁 Keeping execution folder: {folder_path.name} (data preserved)")
        
        if existing_folders:
            print(f"💡 All {len(existing_folders)} execution folders preserved for analysis")
        else:
            print("💡 No execution folders found to preserve")
    
    def _copy_coverage_files(self, test_name, folder_path, folder_id):
        """Copy coverage files from test execution folder to central coverage collection folder"""
        if not self.coverage:
            return
        
        try:
            # For numbered tests like test_name_1, the VDB is created with base name (test_name without _N)
            base_test_name = self._extract_base_test_name(test_name)
            coverage_dir = folder_path / f"{base_test_name}.vdb"
            
            # Check if coverage database was generated
            if not coverage_dir.exists():
                if self.verbose:
                    print(f"⚠️  [Folder {folder_id:02d}] No coverage data found for {test_name}")
                return
            
            # Create unique coverage directory name in collection folder
            dest_coverage_dir = self.coverage_folder / f"{test_name}_cov_{folder_id:02d}.vdb"
            
            # Copy coverage database to collection folder
            # Handle compatibility with older Python versions
            if dest_coverage_dir.exists():
                shutil.rmtree(dest_coverage_dir)
            shutil.copytree(coverage_dir, dest_coverage_dir)
            
            if self.verbose:
                print(f"📊 [Folder {folder_id:02d}] Copied coverage data: {coverage_dir.name} -> {dest_coverage_dir.name}")
            
            # Also copy any additional coverage files (like .cm files if they exist)
            for pattern in ['*.cm', '*.ucm', '*.ccf']:
                for coverage_file in folder_path.glob(pattern):
                    dest_file = self.coverage_folder / f"{test_name}_{coverage_file.name}"
                    shutil.copy2(coverage_file, dest_file)
                    if self.verbose:
                        print(f"📊 [Folder {folder_id:02d}] Copied coverage file: {coverage_file.name}")
                        
        except Exception as e:
            print(f"⚠️  Warning: Could not copy coverage files for {test_name}: {e}")
    
    def _merge_coverage_data(self):
        """Merge all collected coverage data using VCS urg tool"""
        if not self.coverage or not self.coverage_folder:
            return
        
        try:
            # Find all coverage directories in coverage collection folder
            coverage_dirs = list(self.coverage_folder.glob("*_cov_*"))
            
            if not coverage_dirs:
                print(f"⚠️  No coverage data found in {self.coverage_folder}")
                return
            
            print(f"\n📊 Merging coverage data from {len(coverage_dirs)} test runs...")
            
            # Create temporary coverage folder at sim level (same as reference script)
            temp_coverage_folder = self.base_dir.parent / "coverage_temp"
            temp_coverage_folder.mkdir(exist_ok=True)
            
            # Copy all coverage databases to temp folder
            temp_coverage_dirs = []
            for i, cov_dir in enumerate(coverage_dirs):
                temp_cov_dir = temp_coverage_folder / cov_dir.name
                if temp_cov_dir.exists():
                    shutil.rmtree(temp_cov_dir)
                shutil.copytree(cov_dir, temp_cov_dir)
                temp_coverage_dirs.append(temp_cov_dir)
            
            # Build urg command to merge coverage databases (use relative paths in temp folder)
            urg_cmd = [
                'urg',
                '-dir', temp_coverage_dirs[0].name  # Start with first database (relative name)
            ]
            
            # Add additional coverage databases
            for temp_cov_dir in temp_coverage_dirs[1:]:
                urg_cmd.extend(['-dir', temp_cov_dir.name])
            
            # Set output directory and format with additional options
            urg_cmd.extend([
                '-dbname', 'merged_coverage.vdb',
                '-format', 'both',  # Generate both text and HTML reports
                '-report', 'coverage_report',
                '-metric', 'line+cond+fsm+tgl+branch+assert',  # Match reference script
                '-show', 'tests'  # Show test information
            ])
            
            if self.verbose:
                print(f"Running coverage merge command: {' '.join(urg_cmd)}")
            
            # Execute coverage merge in temp folder
            result = subprocess.run(
                urg_cmd,
                cwd=str(temp_coverage_folder),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=600  # 10 minute timeout for coverage merge
            )
            
            if result.returncode == 0:
                print(f"✅ Coverage merge completed successfully")
                
                # Move merged results to regression results folder
                temp_merged_vdb = temp_coverage_folder / "merged_coverage.vdb"
                temp_coverage_report = temp_coverage_folder / "coverage_report"
                
                final_merged_vdb = self.coverage_folder / "merged_coverage.vdb"
                final_coverage_report = self.coverage_folder / "coverage_report"
                
                # Move merged VDB
                if temp_merged_vdb.exists():
                    if final_merged_vdb.exists():
                        shutil.rmtree(final_merged_vdb)
                    shutil.move(str(temp_merged_vdb), str(final_merged_vdb))
                
                # Move coverage report
                if temp_coverage_report.exists():
                    if final_coverage_report.exists():
                        shutil.rmtree(final_coverage_report)
                    shutil.move(str(temp_coverage_report), str(final_coverage_report))
                
                print(f"   Merged database: {final_merged_vdb}")
                print(f"   Coverage report: {final_coverage_report}")
                
                # Display coverage summary if available
                summary_file = final_coverage_report / "summary.txt"
                if summary_file.exists():
                    print(f"\n📊 Coverage Summary:")
                    with open(summary_file, 'r') as f:
                        # Read first few lines of summary
                        for i, line in enumerate(f):
                            if i < 10:  # Show first 10 lines
                                print(f"   {line.rstrip()}")
                            else:
                                break
                
                # Clean up temporary coverage folder
                try:
                    shutil.rmtree(temp_coverage_folder)
                    if self.verbose:
                        print(f"🗑️  Cleaned up temporary coverage folder: {temp_coverage_folder}")
                except Exception as e:
                    print(f"⚠️  Warning: Could not clean up temp folder {temp_coverage_folder}: {e}")
            else:
                print(f"⚠️  Coverage merge failed with return code {result.returncode}")
                if result.stderr:
                    stderr_text = result.stderr.decode('utf-8', errors='replace')
                    print(f"   stderr: {stderr_text}")
                
        except subprocess.TimeoutExpired:
            print(f"⚠️  Coverage merge timed out after 10 minutes")
        except FileNotFoundError:
            print(f"⚠️  Coverage merge tool 'urg' not found. Make sure VCS tools are in PATH")
        except Exception as e:
            print(f"⚠️  Error during coverage merge: {e}")
    
    def _monitor_test_completion(self, folder_path, folder_id, test_name, process):
        """Monitor test completion and ensure proper log completion before unlocking"""
        try:
            # Wait for process to complete
            stdout, _ = process.communicate(timeout=self.timeout)
            
            # Additional wait to ensure all file operations are complete
            time.sleep(2.0)
            
            # Wait for complete log file with proper completion markers
            log_file = folder_path / f"{test_name}.log"
            if self._wait_for_complete_log(log_file, folder_id, test_name):
                if self.verbose:
                    print(f"✅ [Folder {folder_id:02d}] Test {test_name} completed with verified log")
            else:
                if self.verbose:
                    print(f"⚠️  [Folder {folder_id:02d}] Test {test_name} completed but log verification failed")
                
            return stdout
            
        except subprocess.TimeoutExpired:
            # Kill the process and cleanup
            try:
                os.killpg(os.getpgid(process.pid), signal.SIGKILL)
                process.communicate()
            except:
                pass
            
            if self.verbose:
                print(f"⏰ [Folder {folder_id:02d}] Test {test_name} timed out")
            
            raise

    def _wait_for_complete_log(self, log_file, folder_id, test_name):
        """Wait for log file to be created and contain completion markers"""
        max_wait = self.log_wait_timeout  # Use configurable timeout
        waited = 0
        
        # Phase 1: Wait for log file to be created
        while waited < max_wait and not log_file.exists():
            time.sleep(1.0)
            waited += 1
            
        if not log_file.exists():
            if self.verbose:
                print(f"⚠️  [Folder {folder_id:02d}] Log file {log_file.name} was not created after {max_wait}s")
            return False
        
        # Phase 2: Wait for log file to contain completion markers
        completion_waited = 0
        max_completion_wait = min(30, max_wait)  # Maximum 30 seconds for completion check
        
        while completion_waited < max_completion_wait:
            if self._verify_log_completion(log_file, folder_id, test_name):
                if self.verbose:
                    print(f"📋 [Folder {folder_id:02d}] Log completion verified after {waited + completion_waited}s total wait")
                return True
                
            time.sleep(2.0)  # Check every 2 seconds for completion
            completion_waited += 2
            
        if self.verbose:
            print(f"⚠️  [Folder {folder_id:02d}] Log file exists but completion markers not found after {max_completion_wait}s")
        return False

    def _verify_log_completion(self, log_file, folder_id, test_name):
        """Verify that log file contains proper completion markers"""
        try:
            if not log_file.exists() or log_file.stat().st_size == 0:
                return False
                
            # Read the last portion of the log file to check for completion
            with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
                # Read last 2KB to check for completion markers
                f.seek(0, 2)  # Go to end
                file_size = f.tell()
                
                # Read last 2KB or entire file if smaller
                read_size = min(2048, file_size)
                f.seek(max(0, file_size - read_size))
                last_content = f.read()
                
            # Look for various completion indicators
            completion_patterns = [
                r'TEST_DONE.*run.*phase.*ready',  # Standard UVM completion
                r'TestCase.*PASSED!!!',  # Success completion
                r'TEST PASSED',  # Simple test pass
                r'\$finish called',  # VCS finish call
                r'Simulation complete',  # Simulation end
                r'UVM_INFO.*TEST.*PASSED',  # UVM test passed
                r'TESTDONE',  # Generic test done marker (case-insensitive)
                r'Test completed',  # Generic completion
                r'## Simulation End',  # Formatted end marker
                r'Exit code.*[0-9]+',  # Exit with code
                r'.*run completed',  # Run completion
            ]
            
            # Look for error/fatal patterns that also indicate completion
            error_completion_patterns = [
                r'UVM_FATAL.*Stopping further execution',
                r'FATAL.*Terminating',
                r'Error.*VCS.*terminating',
                r'\$finish called.*error',
                r'Simulation terminated',
            ]
            
            # Check for completion patterns (case-insensitive)
            last_content_lower = last_content.lower()
            
            for pattern in completion_patterns:
                if re.search(pattern, last_content, re.IGNORECASE | re.MULTILINE):
                    if self.verbose:
                        print(f"📝 [Folder {folder_id:02d}] Found completion marker: {pattern}")
                    return True
                    
            for pattern in error_completion_patterns:
                if re.search(pattern, last_content, re.IGNORECASE | re.MULTILINE):
                    if self.verbose:
                        print(f"📝 [Folder {folder_id:02d}] Found error completion marker: {pattern}")
                    return True
            
            # Additional check: Look for VCS session end patterns
            if ('vcs' in last_content_lower and 
                any(end_word in last_content_lower for end_word in 
                    ['completed', 'finished', 'terminated', 'done', 'exit'])):
                if self.verbose:
                    print(f"📝 [Folder {folder_id:02d}] Found VCS session end indication")
                return True
                
            return False
            
        except Exception as e:
            if self.verbose:
                print(f"⚠️  [Folder {folder_id:02d}] Error verifying log completion: {e}")
            return False

    def _copy_verified_log(self, log_file, target_folder, test_name, folder_id):
        """Copy log file only after verifying it's complete with retry mechanism"""
        max_retries = 3
        retry_delay = 2.0
        
        for attempt in range(max_retries):
            try:
                # Check if log file exists and is complete
                if not log_file.exists():
                    if self.verbose:
                        print(f"⚠️  [Folder {folder_id:02d}] Attempt {attempt+1}: Log file {log_file.name} does not exist")
                    if attempt < max_retries - 1:
                        time.sleep(retry_delay)
                        continue
                    else:
                        return False
                
                # Verify log file is complete before copying
                if not self._verify_log_completion(log_file, folder_id, test_name):
                    if self.verbose:
                        print(f"⚠️  [Folder {folder_id:02d}] Attempt {attempt+1}: Log file incomplete, waiting...")
                    if attempt < max_retries - 1:
                        time.sleep(retry_delay)
                        continue
                    else:
                        # Copy anyway even if completion verification failed
                        if self.verbose:
                            print(f"⚠️  [Folder {folder_id:02d}] Copying incomplete log file as final attempt")
                
                # Ensure log file is not empty and not being written to
                file_size = log_file.stat().st_size
                if file_size == 0:
                    if self.verbose:
                        print(f"⚠️  [Folder {folder_id:02d}] Attempt {attempt+1}: Log file is empty")
                    if attempt < max_retries - 1:
                        time.sleep(retry_delay)
                        continue
                    else:
                        return False
                
                # Wait a bit then check if file size is stable (not being written to)
                time.sleep(1.0)
                new_file_size = log_file.stat().st_size
                if new_file_size != file_size:
                    if self.verbose:
                        print(f"⚠️  [Folder {folder_id:02d}] Attempt {attempt+1}: Log file still being written ({file_size} -> {new_file_size} bytes)")
                    if attempt < max_retries - 1:
                        time.sleep(retry_delay)
                        continue
                
                # Create target directory if it doesn't exist
                target_folder.mkdir(parents=True, exist_ok=True)
                
                # Copy the log file
                target_file = target_folder / f"{test_name}.log"
                shutil.copy2(log_file, target_file)
                
                # Verify the copy was successful
                if target_file.exists() and target_file.stat().st_size == log_file.stat().st_size:
                    if self.verbose:
                        print(f"✅ [Folder {folder_id:02d}] Successfully copied log file ({log_file.stat().st_size} bytes)")
                    return True
                else:
                    if self.verbose:
                        print(f"⚠️  [Folder {folder_id:02d}] Attempt {attempt+1}: Copy verification failed")
                    if attempt < max_retries - 1:
                        time.sleep(retry_delay)
                        continue
                    else:
                        return False
                        
            except Exception as e:
                if self.verbose:
                    print(f"⚠️  [Folder {folder_id:02d}] Attempt {attempt+1}: Error copying log file: {e}")
                if attempt < max_retries - 1:
                    time.sleep(retry_delay)
                    continue
                else:
                    return False
        
        return False
    
    def _comprehensive_cleanup_folder(self, folder_path, folder_id):
        """Remove and recreate folder ensuring previous test completion"""
        if self.verbose:
            print(f"🗂️  [Folder {folder_id:02d}] Preparing folder for new test...")
        
        try:
            # STEP 1: Check if previous test is complete (if folder exists)
            if folder_path.exists():
                if not self._verify_previous_test_completion(folder_path, folder_id):
                    if self.verbose:
                        print(f"⚠️  [Folder {folder_id:02d}] Previous test may still be running, waiting...")
                    # Wait for previous test to complete
                    self._wait_for_test_completion_in_folder(folder_path, folder_id)
            
            # STEP 2: Terminate any VCS processes that might be using this folder
            self._terminate_vcs_processes_for_folder(folder_path, folder_id)
            
            # STEP 3: Archive previous test data if folder exists
            if folder_path.exists():
                archive_path = self._archive_previous_test_data(folder_path, folder_id)
                if self.verbose and archive_path:
                    print(f"📦 [Folder {folder_id:02d}] Previous test data archived to {archive_path.name}")
            
            # STEP 4: Remove existing folder completely
            if folder_path.exists():
                try:
                    shutil.rmtree(folder_path, ignore_errors=False)
                    if self.verbose:
                        print(f"🗑️  [Folder {folder_id:02d}] Removed existing folder")
                except Exception as e:
                    if self.verbose:
                        print(f"⚠️  [Folder {folder_id:02d}] Warning during folder removal: {e}")
                    # Force removal with system command if needed
                    try:
                        subprocess.run(['rm', '-rf', str(folder_path)], check=True)
                    except:
                        pass
            
            # STEP 5: Recreate fresh folder
            folder_path.mkdir(parents=True, exist_ok=True)
            
            # STEP 6: Makefile is now referenced from synopsys_sim directory (no copying needed)
            
            # STEP 7: Create compile file for folder (matching original axi4_regression.py approach)
            self._create_compile_file_for_folder(folder_path, folder_id)
            
            # STEP 8: Brief pause for filesystem stability
            time.sleep(1.0)
            
            if self.verbose:
                print(f"✅ [Folder {folder_id:02d}] Fresh folder created and ready for new test")
                
        except Exception as e:
            if self.verbose:
                print(f"⚠️  [Folder {folder_id:02d}] Folder preparation warning: {e}")
            # Ensure folder exists even if there were issues
            folder_path.mkdir(parents=True, exist_ok=True)

    def _verify_previous_test_completion(self, folder_path, folder_id):
        """Check if previous test in this folder has completed"""
        try:
            # Look for signs that a test is still running
            # 1. Check for VCS processes using this folder
            result = subprocess.run(['pgrep', '-f', str(folder_path)], 
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
            if result.returncode == 0:
                if self.verbose:
                    print(f"⚠️  [Folder {folder_id:02d}] Found active VCS processes")
                return False
            
            # 2. Check for VCS lock files
            vcs_lock_patterns = ['*.lck', '.vcs.lck', 'simv.daidir/.*.lck', '*.vdb/.*.lck']
            for pattern in vcs_lock_patterns:
                if list(folder_path.glob(pattern)):
                    if self.verbose:
                        print(f"⚠️  [Folder {folder_id:02d}] Found VCS lock files")
                    return False
            
            # 3. Check if log file exists and has completion markers
            log_files = list(folder_path.glob("*.log"))
            if log_files:
                latest_log = max(log_files, key=lambda x: x.stat().st_mtime)
                if self._verify_log_completion(latest_log, folder_id, "previous_test"):
                    if self.verbose:
                        print(f"✅ [Folder {folder_id:02d}] Previous test completed successfully")
                    return True
                else:
                    if self.verbose:
                        print(f"⚠️  [Folder {folder_id:02d}] Previous test log incomplete")
                    return False
            
            # If no log files found, assume no previous test or it's very old
            return True
            
        except Exception as e:
            if self.verbose:
                print(f"⚠️  [Folder {folder_id:02d}] Error checking previous test completion: {e}")
            return True  # Assume it's safe to proceed

    def _wait_for_test_completion_in_folder(self, folder_path, folder_id):
        """Wait for previous test in folder to complete"""
        max_wait = 300  # 5 minutes maximum wait
        waited = 0
        
        while waited < max_wait:
            if self._verify_previous_test_completion(folder_path, folder_id):
                if self.verbose:
                    print(f"✅ [Folder {folder_id:02d}] Previous test completed after {waited}s wait")
                return
            
            time.sleep(5.0)  # Check every 5 seconds
            waited += 5
            
            if waited % 30 == 0:  # Print status every 30 seconds
                if self.verbose:
                    print(f"⏳ [Folder {folder_id:02d}] Still waiting for previous test completion ({waited}s)...")
        
        if self.verbose:
            print(f"⚠️  [Folder {folder_id:02d}] Previous test completion wait timed out after {max_wait}s")

    def _archive_previous_test_data(self, folder_path, folder_id):
        """Archive previous test data before removing folder"""
        try:
            # Create archive directory if it doesn't exist
            archive_base = self.base_dir / "test_archives"
            archive_base.mkdir(exist_ok=True)
            
            # Generate archive name with timestamp
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            archive_name = f"run_folder_{folder_id:02d}_{timestamp}"
            archive_path = archive_base / archive_name
            
            # Copy the entire folder to archive
            try:
                shutil.copytree(folder_path, archive_path)
            except OSError:
                # If destination exists, try to remove it first
                if archive_path.exists():
                    shutil.rmtree(archive_path)
                shutil.copytree(folder_path, archive_path)
            
            if self.verbose:
                print(f"📦 [Folder {folder_id:02d}] Test data archived to {archive_path}")
            
            return archive_path
            
        except Exception as e:
            if self.verbose:
                print(f"⚠️  [Folder {folder_id:02d}] Failed to archive previous test data: {e}")
            return None

    def _create_compile_file_for_folder(self, folder_path, folder_id):
        """Create a compile file with paths adjusted for running from the folder (matches original axi4_regression.py)"""
        try:
            # Read the original compile file from parent directory
            orig_compile_file = self.base_dir.parent / 'axi4_compile.f'
            new_compile_file = folder_path / 'axi4_compile.f'
            
            if not orig_compile_file.exists():
                if self.verbose:
                    print(f"⚠️  [Folder {folder_id:02d}] Original compile file not found at {orig_compile_file}")
                return
            
            with open(orig_compile_file, 'r') as f:
                content = f.read()
            
            # No path adjustment needed since run_folder_XX is at same level as synopsys_sim
            # Both are at sim/ level, so ../../pkg/ works from both locations
            adjusted_content = content
            
            with open(new_compile_file, 'w') as f:
                f.write(adjusted_content)
            
            if self.verbose:
                print(f"📋 [Folder {folder_id:02d}] Created local axi4_compile.f file")
                
        except Exception as e:
            if self.verbose:
                print(f"⚠️  [Folder {folder_id:02d}] Failed to create compile file: {e}")

    def _terminate_vcs_processes_for_folder(self, folder_path, folder_id):
        """Terminate any VCS processes that might be using this folder"""
        try:
            # Check for VCS processes with this folder path
            result = subprocess.run(['pgrep', '-f', str(folder_path)], 
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
            if result.returncode == 0:
                pids = result.stdout.strip().split('\n')
                for pid in pids:
                    if pid.isdigit():
                        try:
                            # Send SIGTERM first, then SIGKILL if needed
                            os.kill(int(pid), signal.SIGTERM)
                            time.sleep(0.5)
                            try:
                                os.kill(int(pid), 0)  # Check if still alive
                                os.kill(int(pid), signal.SIGKILL)  # Force kill
                            except ProcessLookupError:
                                pass  # Process already terminated
                        except (ProcessLookupError, PermissionError):
                            pass
                if self.verbose:
                    print(f"🔪 [Folder {folder_id:02d}] Terminated {len(pids)} VCS processes")
        except Exception:
            pass  # Don't fail cleanup due to process termination issues

    def _wait_for_vcs_locks_release(self, folder_path, folder_id):
        """Wait for VCS-specific lock files to be released"""
        vcs_lock_patterns = ['*.lck', '.vcs.lck', 'simv.daidir/.*.lck', '*.vdb/.*.lck']
        max_wait = 10  # Maximum 10 seconds wait for locks
        waited = 0
        
        while waited < max_wait:
            locks_found = False
            for pattern in vcs_lock_patterns:
                if list(folder_path.glob(pattern)):
                    locks_found = True
                    break
            
            if not locks_found:
                break
                
            time.sleep(0.5)
            waited += 0.5
            
        if self.verbose and waited > 0:
            print(f"🔒 [Folder {folder_id:02d}] Waited {waited:.1f}s for VCS locks to release")

    def _force_filesystem_sync(self):
        """Force filesystem sync to ensure all changes are committed"""
        try:
            os.sync()  # Force filesystem sync
        except:
            pass  # Sync might not be available on all systems

    def _verify_critical_artifacts_removed(self, folder_path, folder_id):
        """Verify that critical VCS artifacts that could cause corruption are removed"""
        critical_patterns = ['simv', 'simv.daidir', '*.vdb', '*.sdb']
        remaining_artifacts = []
        
        for pattern in critical_patterns:
            artifacts = list(folder_path.glob(pattern))
            remaining_artifacts.extend(artifacts)
        
        if remaining_artifacts and self.verbose:
            artifact_names = [str(a.name) for a in remaining_artifacts[:3]]  # Show first 3
            print(f"⚠️  [Folder {folder_id:02d}] Some critical artifacts remain: {artifact_names}")
            
        # Try one more aggressive cleanup pass if critical artifacts remain
        if remaining_artifacts:
            time.sleep(1.0)
            for artifact in remaining_artifacts:
                try:
                    if artifact.is_dir():
                        shutil.rmtree(artifact, ignore_errors=True)
                    else:
                        artifact.unlink()
                except:
                    pass

    def _run_single_test_with_lock(self, test_obj, folder_path, folder_id):
        """Execute a single test using make in the specified folder with proper locking"""
        start_time = time.time()
        
        # Extract test information from test object
        test_name = test_obj['name']
        custom_seed = test_obj.get('seed')
        command_add = test_obj.get('command_add')
        
        # Simple approach: just run the test without complex locking
        
        try:
            # PREPARE FOLDER FOR NEW TEST (removes and recreates folder after ensuring previous test completion)
            # This approach archives previous test data and creates a fresh folder for the new test
            if self.verbose:
                print(f"🗂️  [Folder {folder_id:02d}] Preparing folder for {test_name}")
            self._comprehensive_cleanup_folder(folder_path, folder_id)
            
            log_file = folder_path / f"{test_name}.log"
            
            # Extract base test name for UVM_TESTNAME (remove _N suffix if present)
            base_test_name = self._extract_base_test_name(test_name)
            
            if self.verbose:
                print(f"🔄 [Folder {folder_id:02d}] Starting {test_name}")
                if test_name != base_test_name:
                    print(f"    Base test: {base_test_name}")
                print(f"    Working directory: {self._to_relative_path(folder_path)}")
                print(f"    Expected log file: {self._to_relative_path(log_file)}")
                print(f"    Makefile location: ../synopsys_sim/Makefile")
            
            # Build make command using Makefile in synopsys_sim directory
            make_cmd = ['make', '-f', '../synopsys_sim/Makefile', 'sim']
            
            # Add make variables
            make_vars = {
                'test': base_test_name,
                'LOG_FILE': f"{test_name}.log",  # Pass the expected log file name to Makefile
                'CLEANUP_DELAY': str(self.cleanup_delay)  # Pass cleanup delay to Makefile
            }
            
            # Use custom seed if provided, otherwise generate random seed
            if custom_seed is not None:
                seed_value = custom_seed
                if self.verbose:
                    print(f"    Using custom seed: {seed_value}")
            else:
                # Generate a more random seed using multiple entropy sources
                seed_value = random.randint(1, 2**31-1)
                seed_value ^= int(time.time() * 1000000) & 0x7FFFFFFF  # Mix with microsecond timestamp
                seed_value ^= hash(test_name) & 0x7FFFFFFF  # Mix with test name hash
                seed_value &= 0x7FFFFFFF  # Ensure positive 32-bit value
                if self.verbose:
                    print(f"    Generated random seed: {seed_value}")
            
            make_vars['SEED'] = str(seed_value)
            
            # Add optional parameters
            if self.fsdb_dump:
                make_vars['FSDB_DUMP'] = '1'
                if self.verbose:
                    print(f"    FSDB dumping enabled")
            
            if self.coverage:
                make_vars['COVERAGE'] = '1'
                make_vars['COV_DIR'] = f"{test_name}.vdb"
                if self.verbose:
                    print(f"    Coverage collection enabled: {test_name}.vdb")
            
            if command_add:
                make_vars['COMMAND_ADD'] = command_add
                if self.verbose:
                    print(f"    Adding custom command: {command_add}")
            
            # Add variables to make command
            for var, value in make_vars.items():
                make_cmd.append(f'{var}={value}')

            if self.verbose:
                print(f"    Make command: {' '.join(make_cmd)} (using synopsys_sim/Makefile)")

            # Change to the run folder before executing
            original_dir = os.getcwd()
            os.chdir(str(folder_path))
            
            # SERIALIZE VCS STARTUP in parallel mode to prevent database corruption
            if self.max_parallel > 1:
                with self.vcs_startup_lock:
                    if self.verbose:
                        print(f"🔐 [Folder {folder_id:02d}] Acquired VCS startup lock for database protection")
                    
                    # Run make command with timeout
                    process = subprocess.Popen(
                        make_cmd,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        universal_newlines=True,
                        preexec_fn=os.setsid  # Create new process group
                    )
                    
                    # Wait for VCS compilation/elaboration to complete before releasing lock
                    # This prevents database corruption during the critical startup phase
                    startup_timeout = 15  # 15 seconds for compilation/elaboration in parallel mode
                    try:
                        # Poll process to check if compilation phase is done
                        waited = 0
                        while waited < startup_timeout and process.poll() is None:
                            time.sleep(1.0)
                            waited += 1
                            
                            # After reasonable time, assume compilation is likely done
                            if waited >= 8:  # After 8 seconds in parallel mode
                                break
                        
                        if self.verbose:
                            print(f"🔓 [Folder {folder_id:02d}] Released VCS startup lock after {waited}s")
                            
                    except Exception:
                        if self.verbose:
                            print(f"🔓 [Folder {folder_id:02d}] Released VCS startup lock (exception)")
            else:
                # Sequential mode - no startup serialization needed
                process = subprocess.Popen(
                    make_cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    universal_newlines=True,
                    preexec_fn=os.setsid  # Create new process group
                )
            
            # Monitor test completion with proper synchronization
            try:
                stdout = self._monitor_test_completion(folder_path, folder_id, test_name, process)
                duration = time.time() - start_time
                
                # Check if test passed or failed  
                status, error_msg, uvm_errors, uvm_fatals = self._analyze_test_result(log_file, stdout)
                
                # Enhanced log copying with completion verification
                target_folder = self.pass_logs_folder if status == 'PASS' else self.no_pass_logs_folder
                
                # Copy log with verification and retry mechanism
                if self._copy_verified_log(log_file, target_folder, test_name, folder_id):
                    if self.verbose:
                        print(f"📋 Copied verified log to {target_folder.name}: {test_name}.log")
                else:
                    print(f"⚠️  Warning: Could not copy verified log file for {test_name}")
                
                # Copy coverage files if coverage collection is enabled
                if self.coverage:
                    self._copy_coverage_files(test_name, folder_path, folder_id)
                
                return TestResult(
                    name=test_name,
                    status=status,
                    duration=duration,
                    log_file=str(log_file),
                    error_msg=error_msg,
                    folder_id=folder_id,
                    uvm_errors=uvm_errors,
                    uvm_fatals=uvm_fatals,
                    seed=seed_value,
                    command_add=command_add
                )
                    
            except subprocess.TimeoutExpired:
                duration = time.time() - start_time
                timeout_msg = f"Test timed out after {self.timeout} seconds"
                
                # Copy log to no_pass_logs folder for timeout cases using enhanced mechanism
                if not self._copy_verified_log(log_file, self.no_pass_logs_folder, test_name, folder_id):
                    if self.verbose:
                        print(f"⚠️  Warning: Could not copy verified log file for timeout case {test_name}")
                
                return TestResult(
                    name=test_name,
                    status='TIMEOUT',
                    duration=duration,
                    log_file=str(log_file),
                    error_msg=timeout_msg,
                    folder_id=folder_id,
                    seed=seed_value,
                    command_add=command_add
                )
                
        except Exception as e:
            duration = time.time() - start_time
            return TestResult(
                name=test_name,
                status='ERROR',
                duration=duration,
                log_file=str(log_file) if 'log_file' in locals() else '',
                error_msg=f"Execution error: {str(e)}",
                folder_id=folder_id,
                seed=seed_value if 'seed_value' in locals() else None,
                command_add=command_add
            )
        finally:
            # Always change back to original directory
            os.chdir(original_dir)

    def _run_single_test(self, test_obj, folder_path, folder_id):
        """Simplified test execution without complex locking"""
        return self._run_single_test_with_lock(test_obj, folder_path, folder_id)
    
    def _analyze_test_result(self, log_file, stdout):
        """Analyze test output to determine pass/fail status and extract error message
        Returns: (status, error_msg, uvm_errors, uvm_fatals)
        """
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
                r'timeout.*enhanced',
                r'TIME_OUT.*enhanced',
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
                r'test completed successfully',
                r'Test execution completed'
            ]
            
            # Check for timeout/hang patterns first - these indicate stuck simulations
            for pattern in timeout_patterns:
                matches = re.findall(pattern, full_output, re.IGNORECASE | re.MULTILINE)
                if matches:
                    return 'TIMEOUT', f"Simulation hung or stuck - pattern: {pattern}", 0, 0
            
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
                        return 'TIMEOUT', f"Excessive repetition detected - simulation likely stuck", 0, 0
            
            # Look for success indicators 
            for pattern in success_patterns:
                matches = re.findall(pattern, full_output, re.IGNORECASE | re.MULTILINE)
                if matches:
                    return 'PASS', None, 0, 0
            
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
                    return 'PASS', None, uvm_errors, uvm_fatals
                elif uvm_errors > 0 or uvm_fatals > 0:
                    # Found UVM errors or fatals
                    error_msg = f"UVM_ERROR Count: {uvm_errors}, UVM_FATAL Count: {uvm_fatals}"
                    return 'FAIL', error_msg, uvm_errors, uvm_fatals
            
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
                    
                    # If we have UVM summary info, include it in the error message
                    if uvm_summary_found and (uvm_errors > 0 or uvm_fatals > 0):
                        error_msg = f"{error_msg} (UVM_ERROR Count: {uvm_errors}, UVM_FATAL Count: {uvm_fatals})"
                    return 'FAIL', error_msg, uvm_errors, uvm_fatals
            
            # If no explicit pass/fail found, check simulation completion
            if 'CPU TIME' in full_output or 'Total simulation time' in full_output:
                # Simulation completed, assume pass if no errors found
                return 'PASS', None, 0, 0
            elif log_content == "" and not log_file.exists():
                # No log file was created - make likely failed to run
                return 'ERROR', f"Make failed to create log file: {self._to_relative_path(log_file)}", 0, 0
            else:
                # If we have UVM summary info, include it in the error message
                if uvm_summary_found and (uvm_errors > 0 or uvm_fatals > 0):
                    return 'FAIL', f"Simulation did not complete properly (UVM_ERROR Count: {uvm_errors}, UVM_FATAL Count: {uvm_fatals})", uvm_errors, uvm_fatals
                else:
                    return 'FAIL', "Simulation did not complete properly", 0, 0
                
        except Exception as e:
            return 'ERROR', f"Could not analyze results: {str(e)}", 0, 0
    
    def _update_progress(self, test_result):
        """Update progress statistics and display"""
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
        # Merge coverage data if coverage collection was enabled
        if self.coverage:
            self._merge_coverage_data()
        
        # Generate running list with actual execution parameters
        self._generate_running_list(self.results)
        
        # Generate pass and no pass lists with actual execution parameters
        self._generate_pass_list(self.results)
        self._generate_no_pass_list(self.results)
        
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
                print(f"            └─ Log: {self._to_relative_path(self.no_pass_logs_folder / f'{result.name}.log')}")
            
            print(f"\n📝 Failed test list saved to: {self._to_relative_path(self.results_folder / 'no_pass_list')}")
        
        # Save detailed results to results folder
        results_file = self.results_folder / f"regression_results_{self.timestamp}.txt"
        self._save_detailed_results(results_file)
        
        # Create regression summary with all test records and detailed error info
        regression_log = self.results_folder / "regression_summary.txt"
        self._save_regression_summary(regression_log)
        
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
            f.write(f"AXI4 Regression Results (Makefile Version)\n")
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
    
    def _save_regression_summary(self, summary_file: Path):
        """Save comprehensive summary with all test records and detailed error information"""
        with open(summary_file, 'w') as f:
            f.write(f"AXI4 Regression Summary Report (Makefile Version)\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"="*80 + "\n\n")
            
            # Overall statistics
            f.write(f"Overall Statistics:\n")
            f.write(f"  Total Tests:     {self.total_tests}\n")
            f.write(f"  Passed:          {self.passed_tests} ({(self.passed_tests/self.total_tests)*100:.1f}%)\n")
            f.write(f"  Failed:          {self.failed_tests} ({(self.failed_tests/self.total_tests)*100:.1f}%)\n")
            elapsed = time.time() - self.start_time
            f.write(f"  Total Time:      {str(timedelta(seconds=int(elapsed)))}\n")
            f.write(f"  Average per Test: {elapsed/self.total_tests:.1f}s\n\n")
            
            # Detailed results for ALL tests (not just failed)
            f.write(f"Detailed Test Results:\n")
            f.write(f"="*80 + "\n\n")
            
            # Sort results: TIMEOUT first, FAIL/ERROR second, PASS last
            timeout_results = [r for r in self.results if r.status == 'TIMEOUT']
            fail_results = [r for r in self.results if r.status in ['FAIL', 'ERROR']]
            pass_results = [r for r in self.results if r.status == 'PASS']
            
            test_num = 1
            
            # Show TIMEOUT tests
            for result in timeout_results:
                f.write(f"[{test_num:3d}] Test: {result.name}\n")
                f.write(f"      Status:     {result.status}\n")
                f.write(f"      Duration:   {result.duration:.1f}s\n")
                f.write(f"      Folder:     run_folder_{result.folder_id:02d}\n")
                f.write(f"      Log:        {self._to_relative_path(self.no_pass_logs_folder / f'{result.name}.log')}\n")
                if result.error_msg:
                    f.write(f"      Error:      {result.error_msg}\n")
                f.write(f"\n")
                test_num += 1
            
            # Show FAIL/ERROR tests
            for result in fail_results:
                f.write(f"[{test_num:3d}] Test: {result.name}\n")
                f.write(f"      Status:     {result.status}\n")
                f.write(f"      Duration:   {result.duration:.1f}s\n")
                f.write(f"      Folder:     run_folder_{result.folder_id:02d}\n")
                f.write(f"      Log:        {self._to_relative_path(self.no_pass_logs_folder / f'{result.name}.log')}\n")
                if result.error_msg:
                    f.write(f"      Error:      {result.error_msg}\n")
                if result.uvm_errors > 0 or result.uvm_fatals > 0:
                    f.write(f"      UVM Counts: UVM_ERROR: {result.uvm_errors}, UVM_FATAL: {result.uvm_fatals}\n")
                f.write(f"\n")
                test_num += 1
            
            # Show PASS tests
            for result in pass_results:
                f.write(f"[{test_num:3d}] Test: {result.name}\n")
                f.write(f"      Status:     {result.status}\n")
                f.write(f"      Duration:   {result.duration:.1f}s\n")
                f.write(f"      Folder:     run_folder_{result.folder_id:02d}\n")
                f.write(f"      Log:        {self._to_relative_path(self.pass_logs_folder / f'{result.name}.log')}\n")
                f.write(f"\n")
                test_num += 1
            
            # Summary of failed tests
            if fail_results or timeout_results:
                f.write(f"\n" + "="*80 + "\n")
                f.write(f"Failed Test Summary:\n")
                f.write(f"-"*80 + "\n")
                for result in timeout_results + fail_results:
                    f.write(f"{result.status:8s} {result.name:50s} ({result.duration:6.1f}s)\n")
                    if result.error_msg:
                        f.write(f"         └─ {result.error_msg}\n")
                    if result.uvm_errors > 0 or result.uvm_fatals > 0:
                        f.write(f"         └─ UVM_ERROR Count: {result.uvm_errors}, UVM_FATAL Count: {result.uvm_fatals}\n")
    
    def run_regression(self, test_list_file) :
        """Main method to run the regression"""
        try:
            print("🚀 Starting AXI4 Regression Runner (Makefile Version)")
            
            # Load test list
            tests = self._load_test_list(test_list_file)
            
            # Set max_parallel to number of tests if not specified
            if self.max_parallel is None:
                self.max_parallel = len(tests)
            
            execution_mode = "LSF" if self.use_lsf else "Local"
            if self.use_lsf:
                print(f"⚙️  Configuration: {execution_mode} mode, {self.max_parallel} parallel workers, {self.timeout}s timeout")
            else:
                if self.max_parallel == 1:
                    print(f"⚙️  Configuration: {execution_mode} mode (sequential execution), {self.timeout}s timeout")
                else:
                    print(f"⚙️  Configuration: {execution_mode} mode ({self.max_parallel} parallel workers), {self.timeout}s timeout")
            
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
            # Always keep all execution folders for reference
            print("\n⚠️  Keeping all execution folders from this run (run_folder_*)")
            print("💡 These folders contain the actual test execution data and logs")
            print("💡 The last test data is preserved for debugging purposes")
            print("💡 To manually remove them: rm -rf run_folder_*")
            
            # Always report the regression result folder location
            if hasattr(self, 'results_folder') and self.results_folder.exists():
                print(f"\n📊 Regression results saved in: {self._to_relative_path(self.results_folder)}")
                print(f"   View summary: cat {self._to_relative_path(self.results_folder / 'regression_summary.txt')}")
                print(f"   View detailed results: cat {self._to_relative_path(self.results_folder / f'regression_results_{self.timestamp}.txt')}")
    
    def _run_lsf_regression(self, tests, folders):
        """Run regression using LSF job submission"""
        # Submit all jobs - LSF mode uses one folder per test for complete isolation
        for i, test_obj in enumerate(tests):
            if self.stop_all.is_set():
                break
                
            test_name = test_obj['name']
            folder_id = i  # LSF mode: one folder per test
            folder_path = folders[folder_id]
            
            try:
                self._submit_lsf_job(test_obj, folder_path, folder_id)
            except Exception as e:
                error_result = TestResult(
                    name=test_name,
                    status='ERROR',
                    duration=0.0,
                    log_file='',
                    error_msg=f"LSF submission error: {str(e)}",
                    folder_id=folder_id,
                    seed=test_obj.get('seed'),
                    command_add=test_obj.get('command_add')
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
                    uvm_errors = 0
                    uvm_fatals = 0
                elif job_info['status'] == 'EXIT':
                    status = 'FAIL'
                    error_msg = "LSF job exited with error"
                    uvm_errors = 0
                    uvm_fatals = 0
                else:
                    # Analyze log file for actual test result
                    if log_file.exists():
                        with open(log_file, 'r') as f:
                            log_content = f.read()
                        status, error_msg, uvm_errors, uvm_fatals = self._analyze_test_result(log_file, log_content)
                    else:
                        status = 'ERROR'
                        error_msg = "Log file not found"
                        uvm_errors = 0
                        uvm_fatals = 0
                
                result = TestResult(
                    name=test_name,
                    status=status,
                    duration=duration,
                    log_file=str(log_file),
                    error_msg=error_msg,
                    folder_id=folder_id,
                    uvm_errors=uvm_errors,
                    uvm_fatals=uvm_fatals,
                    seed=job_info.get('seed'),
                    command_add=job_info.get('command_add')
                )
                
                # Copy coverage files if coverage collection is enabled
                if self.coverage:
                    self._copy_coverage_files(test_name, folder_path, folder_id)
                
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
        """Run regression with parallel execution and proper race condition prevention"""
        # Smart parallel approach: multiple tests can run simultaneously 
        # but each has exclusive folder access until log completion
        
        if self.max_parallel == 1:
            print(f"🔄 Running {len(tests)} tests sequentially...")
            # Sequential execution for max_parallel=1
            total_folders = len(folders)
            
            for i, test_obj in enumerate(tests):
                if self.stop_all.is_set():
                    break
                
                folder_id = i % total_folders
                folder_path = folders[folder_id]
                test_name = test_obj['name']
                
                if self.verbose:
                    print(f"🔄 [Folder {folder_id:02d}] Running {test_name} (test {i+1}/{len(tests)})")
                
                try:
                    result = self._run_single_test(test_obj, folder_path, folder_id)
                    self._update_progress(result)
                    
                    if self.verbose:
                        print(f"✅ [Folder {folder_id:02d}] Test {test_name} completed")
                        
                except Exception as e:
                    error_result = TestResult(
                        name=test_name,
                        status='ERROR',
                        duration=0.0,
                        log_file='',
                        error_msg=f"Test execution error: {str(e)}",
                        folder_id=folder_id,
                        seed=test_obj.get('seed'),
                        command_add=test_obj.get('command_add')
                    )
                    self._update_progress(error_result)
                
                time.sleep(1.0)
        else:
            # Parallel execution with race condition prevention
            print(f"🚀 Running {len(tests)} tests in parallel with {self.max_parallel} workers...")
            print(f"📁 Using {len(folders)} execution folders with proper isolation...")
            
            from concurrent.futures import ThreadPoolExecutor, as_completed
            import threading
            
            # Track folder availability - a folder is only available when:
            # 1. No test is running in it
            # 2. Previous test's log has been completely copied
            folder_status = {i: 'available' for i in range(len(folders))}
            folder_lock = threading.Lock()
            
            def get_available_folder():
                """Get an available folder atomically"""
                with folder_lock:
                    for folder_id, status in folder_status.items():
                        if status == 'available':
                            folder_status[folder_id] = 'in_use'
                            return folder_id, folders[folder_id]
                return None, None
            
            def release_folder(folder_id):
                """Mark folder as available after ensuring log completion"""
                with folder_lock:
                    folder_status[folder_id] = 'available'
                    if self.verbose:
                        print(f"📁 [Folder {folder_id:02d}] Released and available for next test")
            
            def run_test_with_exclusive_folder(test_obj):
                """Run a test with exclusive folder access until log completion"""
                # Wait for an available folder
                folder_id = None
                folder_path = None
                
                while folder_id is None:
                    folder_id, folder_path = get_available_folder()
                    if folder_id is None:
                        time.sleep(0.1)  # Short wait and retry
                        if self.stop_all.is_set():
                            return None
                
                test_name = test_obj['name']
                
                try:
                    if self.verbose:
                        print(f"🔄 [Folder {folder_id:02d}] Starting {test_name}")
                    
                    # Run test (this includes log completion waiting and copying)
                    result = self._run_single_test(test_obj, folder_path, folder_id)
                    
                    # The test is complete and log has been copied
                    # Now safe to release the folder
                    release_folder(folder_id)
                    
                    return result
                    
                except Exception as e:
                    release_folder(folder_id)
                    return TestResult(
                        name=test_name,
                        status='ERROR',
                        duration=0.0,
                        log_file='',
                        error_msg=f"Test execution error: {str(e)}",
                        folder_id=folder_id,
                        seed=test_obj.get('seed'),
                        command_add=test_obj.get('command_add')
                    )
            
            # Run tests in parallel
            with ThreadPoolExecutor(max_workers=self.max_parallel) as executor:
                # Submit all tests
                future_to_test = {}
                for test_obj in tests:
                    if self.stop_all.is_set():
                        break
                    future = executor.submit(run_test_with_exclusive_folder, test_obj)
                    future_to_test[future] = test_obj
                
                # Process completed tests
                for future in as_completed(future_to_test):
                    if self.stop_all.is_set():
                        break
                        
                    result = future.result()
                    if result:
                        self._update_progress(result)
        
        # Copy all logs to logs folder and print summary
        self._copy_all_logs_to_logs_folder()
        exit_code = self._print_summary()
        if exit_code == 0:
            self._regression_success = True
        return exit_code


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="AXI4 Regression Test Runner - Makefile Version",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 axi4_regression_makefile.py                      # Sequential execution (default)
  python3 axi4_regression_makefile.py -p 4                 # Parallel execution with 4 workers
  python3 axi4_regression_makefile.py -p 8 --verbose       # 8 parallel workers with verbose output
  python3 axi4_regression_makefile.py --timeout 900        # 15min timeout per test
  python3 axi4_regression_makefile.py --fsdb-dump          # Enable FSDB waveform dumping
  python3 axi4_regression_makefile.py --cov                # Enable coverage collection
  python3 axi4_regression_makefile.py --lsf                # Use LSF job submission
  python3 axi4_regression_makefile.py --lsf --cov          # LSF mode with coverage
  python3 axi4_regression_makefile.py --log-wait-timeout 60 # Wait up to 60s for log files (large designs)
  python3 axi4_regression_makefile.py --cleanup-delay 10   # Wait 10s after cleanup (fix database conflicts)
        """
    )
    
    parser.add_argument(
        '--max-parallel', '-p',
        type=int,
        default=1,
        help='Maximum number of parallel workers (default: 1 for sequential execution, use -p 4 for parallel)'
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
    
    parser.add_argument(
        '--fsdb-dump',
        action='store_true',
        help='Enable FSDB waveform dumping by passing FSDB_DUMP=1 to make (default: disabled)'
    )
    
    parser.add_argument(
        '--cov',
        action='store_true',
        help='Enable coverage collection by passing COVERAGE=1 to make'
    )
    
    parser.add_argument(
        '--log-wait-timeout',
        type=int,
        default=30,
        help='Maximum time to wait for log file creation in seconds (default: 30, increase for large designs)'
    )
    
    parser.add_argument(
        '--cleanup-delay',
        type=int,
        default=10,
        help='Delay in seconds after cleanup before starting VCS (default: 10, increase if database conflicts occur)'
    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if args.max_parallel is not None and (args.max_parallel < 1 or args.max_parallel > 50):
        print("❌ Error: max-parallel must be between 1 and 50")
        return 1
    
    if args.timeout < 60:
        print("❌ Error: timeout must be at least 60 seconds")
        return 1
    
    if args.log_wait_timeout < 5:
        print("❌ Error: log-wait-timeout must be at least 5 seconds")
        return 1
    
    if args.cleanup_delay < 0:
        print("❌ Error: cleanup-delay must be non-negative")
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
        use_lsf=args.lsf,
        fsdb_dump=args.fsdb_dump,
        coverage=args.cov,
        log_wait_timeout=args.log_wait_timeout,
        cleanup_delay=args.cleanup_delay
    )
    
    try:
        return runner.run_regression(args.test_list)
    except KeyboardInterrupt:
        print("\n⚠️  Regression interrupted by user")
        return 1


if __name__ == "__main__":
    sys.exit(main())
