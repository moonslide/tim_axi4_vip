#!/usr/bin/env python3
"""
Patch script to update axi4_regression.py to include seed in log filenames.
This solves the issue where multiple runs of the same test with different seeds
would overwrite each other's log files.
"""

import re
import sys
import shutil
from pathlib import Path

def patch_regression_script():
    """Apply patches to axi4_regression.py to include seed in log filenames"""
    
    script_path = Path("axi4_regression.py")
    backup_path = Path("axi4_regression.py.backup")
    
    # Create backup
    if not backup_path.exists():
        shutil.copy2(script_path, backup_path)
        print(f"✅ Created backup: {backup_path}")
    
    # Read the original file
    with open(script_path, 'r') as f:
        content = f.read()
    
    # Apply patches
    patches_applied = 0
    
    # 1. Update run_test_sequential method to store seed and use it in log filenames
    content = re.sub(
        r'(def run_test_sequential\(self, test_obj, folder_id\):.*?)(log_file = folder_path / f"{test_name}\.log")',
        r'\1# Store seed for log naming\n        self._current_test_seed = None\n        \2',
        content,
        flags=re.DOTALL
    )
    patches_applied += 1
    
    # 2. Store seed value when it's generated
    content = re.sub(
        r'(if custom_seed is not None:\s*seed_value = custom_seed)',
        r'\1\n                self._current_test_seed = seed_value',
        content
    )
    patches_applied += 1
    
    content = re.sub(
        r'(seed_value = random\.randint.*?\n.*?seed_value &= 0x7FFFFFFF)',
        r'\1\n                self._current_test_seed = seed_value',
        content,
        flags=re.DOTALL
    )
    patches_applied += 1
    
    # 3. Update log file path after seed is determined
    content = re.sub(
        r'(# Set the actual log file path\s*\n\s*log_file = folder_path / log_file_with_seed)',
        r'log_file = folder_path / f"{test_name}_{self._current_test_seed}.log"',
        content
    )
    patches_applied += 1
    
    # 4. Update VCS command to use seed in log filename
    content = re.sub(
        r'f\'-l {test_name}\.log\\\\n\'',
        r'f\'-l {test_name}_{self._current_test_seed}.log\\n\'',
        content
    )
    patches_applied += 1
    
    # 5. Update log copying to use seed in filename
    content = re.sub(
        r'shutil\.copy2\(log_file, target_folder / f"{test_name}\.log"\)',
        r'shutil.copy2(log_file, target_folder / f"{test_name}_{self._current_test_seed}.log")',
        content
    )
    patches_applied += 1
    
    content = re.sub(
        r'shutil\.copy2\(folder_path / f"{test_name}\.log", target_folder / f"{test_name}\.log"\)',
        r'shutil.copy2(folder_path / f"{test_name}_{self._current_test_seed}.log", target_folder / f"{test_name}_{self._current_test_seed}.log")',
        content
    )
    patches_applied += 1
    
    content = re.sub(
        r'shutil\.copy2\(log_file, self\.no_pass_logs_folder / f"{test_name}\.log"\)',
        r'shutil.copy2(log_file, self.no_pass_logs_folder / f"{test_name}_{self._current_test_seed}.log")',
        content
    )
    patches_applied += 1
    
    content = re.sub(
        r'shutil\.copy2\(folder_path / f"{test_name}\.log", self\.no_pass_logs_folder / f"{test_name}\.log"\)',
        r'shutil.copy2(folder_path / f"{test_name}_{self._current_test_seed}.log", self.no_pass_logs_folder / f"{test_name}_{self._current_test_seed}.log")',
        content
    )
    patches_applied += 1
    
    # 6. Update _ensure_log_copied method
    content = re.sub(
        r'target_log = target_folder / f"{test_result\.name}\.log"',
        r'target_log = target_folder / f"{test_result.name}_{test_result.seed}.log" if test_result.seed else target_folder / f"{test_result.name}.log"',
        content
    )
    patches_applied += 1
    
    # 7. Update possible log locations in _ensure_log_copied
    content = re.sub(
        r'self\.base_dir\.parent / f"run_folder_{test_result\.folder_id:02d}" / f"{test_result\.name}\.log"',
        r'self.base_dir.parent / f"run_folder_{test_result.folder_id:02d}" / (f"{test_result.name}_{test_result.seed}.log" if test_result.seed else f"{test_result.name}.log")',
        content
    )
    patches_applied += 1
    
    content = re.sub(
        r'self\.base_dir / f"{test_result\.name}\.log"',
        r'self.base_dir / (f"{test_result.name}_{test_result.seed}.log" if test_result.seed else f"{test_result.name}.log")',
        content
    )
    patches_applied += 1
    
    # 8. Update _copy_all_logs_to_logs_folder method
    content = re.sub(
        r'target_log = target_folder / f"{test_result\.name}\.log"',
        r'target_log = target_folder / f"{test_result.name}_{test_result.seed}.log" if test_result.seed else target_folder / f"{test_result.name}.log"',
        content
    )
    patches_applied += 1
    
    # 9. Update LSF job submission log file naming
    content = re.sub(
        r'(def submit_lsf_job\(self, test_obj, folder_id\):.*?)(log_file_rel = f\'{test_name}\.log\')',
        r'\1# Will be updated after seed generation\n        \2',
        content,
        flags=re.DOTALL
    )
    patches_applied += 1
    
    # 10. Update LSF log filename in job script
    content = re.sub(
        r'(\s+# Generate a more random seed.*?f\.write\(f\'# Generated random seed: {seed_value}\\\\n\'\))',
        r'\1\n            \n            # Update log file name with seed\n            log_file_rel = f\'{test_name}_{seed_value}.log\'',
        content,
        flags=re.DOTALL
    )
    patches_applied += 1
    
    # 11. Update references in summary reports
    content = re.sub(
        r'f"Log:\s+{self\._to_relative_path\(self\.no_pass_logs_folder / f\'{result\.name}\.log\'\)}"',
        r'f"Log:      {self._to_relative_path(self.no_pass_logs_folder / (f\'{result.name}_{result.seed}.log\' if result.seed else f\'{result.name}.log\'))}"',
        content
    )
    patches_applied += 1
    
    content = re.sub(
        r'f"Log:\s+{self\._to_relative_path\(self\.pass_logs_folder / f\'{result\.name}\.log\'\)}"',
        r'f"Log:      {self._to_relative_path(self.pass_logs_folder / (f\'{result.name}_{result.seed}.log\' if result.seed else f\'{result.name}.log\'))}"',
        content
    )
    patches_applied += 1
    
    # Write the patched content
    with open(script_path, 'w') as f:
        f.write(content)
    
    print(f"✅ Applied {patches_applied} patches to {script_path}")
    print("\nPatch Summary:")
    print("- Log files will now include seed in filename: test_name_seed.log")
    print("- Both pass_logs and no_pass_logs folders will have seed-named logs")
    print("- This prevents log overwrites when same test runs with different seeds")
    
    return True

if __name__ == "__main__":
    try:
        if patch_regression_script():
            print("\n✅ Patch completed successfully!")
        else:
            print("\n❌ Patch failed!")
            sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error applying patch: {e}")
        sys.exit(1)