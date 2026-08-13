#!/usr/bin/env python3
"""Regression-tooling unit tests.

Covers three defects that were previously only ever checked by eye:

  1. axi4_regression.py applied the local worker cap (DEFAULT_MAX_PARALLEL=8)
     to LSF runs as well, throttling `--lsf` with no -p from one dispatch of
     the whole list down to batches of 8.
  2. p4_runall.sh used `shift 2 2>/dev/null`, which shifts NOTHING when fewer
     than two arguments were passed, so a 1-arg call leaked the simv path into
     EXTRA and passed it to simv as a bogus plusarg on every run.
  3. p2_lsf_launch.sh cd'd to a hard-coded /home/<user>/... path with no
     `set -e`, so on any other checkout it ran the runner from the caller's
     directory instead of failing.

Run:  python3 test_regression_tooling.py
      python3 test_regression_tooling.py <axi4_regression.py> <p4_runall.sh> <p2_lsf_launch.sh>

Each test runs against the REAL file in this directory, not a copy of the
logic. The optional path arguments exist so the same assertions can be pointed
at a pre-fix copy to produce the failing (red) leg.
"""

import importlib.util
import os
import shutil
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
FAILURES = []


def check(name, got, want):
    if got == want:
        print("  PASS  %-58s got %r" % (name, got))
    else:
        print("  FAIL  %-58s got %r, want %r" % (name, got, want))
        FAILURES.append(name)


def load_regression_module(path):
    """Import axi4_regression.py from an explicit path.

    Taking the path as an argument is what lets the red leg point this at a
    pre-fix copy of the file and run the SAME assertions against it.
    """
    spec = importlib.util.spec_from_file_location("axi4_regression_under_test", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_default_max_parallel(module_path):
    print("axi4_regression._default_max_parallel  [%s]" % os.path.basename(module_path))
    mod = load_regression_module(module_path)

    lsf = mod.RegressionRunner(max_parallel=None, use_lsf=True)
    local = mod.RegressionRunner(max_parallel=None, use_lsf=False)

    # The authoritative list expands to ~761 runs; the farm should take them all
    # up to the hard ceiling rather than the local thread cap.
    check("lsf, 761 tests -> MAX_PARALLEL", lsf._default_max_parallel(761), mod.MAX_PARALLEL)
    check("lsf, 301 tests -> MAX_PARALLEL", lsf._default_max_parallel(301), mod.MAX_PARALLEL)
    # Fewer tests than the ceiling: never spawn more workers than there is work.
    check("lsf, 3 tests -> 3", lsf._default_max_parallel(3), 3)
    # Local keeps the small cap: threads share one machine.
    check("local, 761 tests -> DEFAULT_MAX_PARALLEL",
          local._default_max_parallel(761), mod.DEFAULT_MAX_PARALLEL)
    check("local, 3 tests -> 3", local._default_max_parallel(3), 3)
    # The two modes must not be the same, or the LSF fix is not in effect.
    check("lsf ceiling > local ceiling",
          lsf._default_max_parallel(761) > local._default_max_parallel(761), True)


def test_p4_runall_shift(script_path):
    """Exercise the argument-consuming prologue of p4_runall.sh directly.

    The script itself launches simulations, so the prologue is extracted and
    run in isolation: everything up to and including the EXTRA assignment,
    with the `cd` and the run loop left out.
    """
    print("p4_runall.sh argument prologue  [%s]" % os.path.basename(script_path))
    with open(script_path) as fh:
        lines = fh.readlines()

    prologue = []
    for line in lines:
        prologue.append(line)
        if line.startswith("EXTRA="):
            break
    else:
        check("EXTRA= assignment found in script", False, True)
        return

    harness = "".join(prologue) + '\necho "[$EXTRA]"\n'

    cases = [
        ([], "[]"),
        (["./simv_p4"], "[]"),
        (["./simv_p4", "p4"], "[]"),
        (["./simv_p4", "p4", "+FOO"], "[+FOO]"),
        (["./simv_p4", "p4", "+FOO", "+BAR"], "[+FOO +BAR]"),
    ]
    for argv, want in cases:
        # stdout=PIPE rather than capture_output=: this host runs Python 3.6,
        # where capture_output= does not exist yet.
        proc = subprocess.run(["bash", "-c", harness, "p4_runall.sh"] + argv,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out = proc.stdout.decode().strip()
        check("%d arg(s) %s" % (len(argv), argv), out, want)


def test_lsf_launcher_is_relocatable(script_path):
    """p2_lsf_launch.sh must find its run directory from its OWN location.

    It used to `cd` to a hard-coded /home/<user>/... path, so on any other
    checkout the cd failed -- and with no `set -e` the script carried on and
    ran the regression runner from whatever directory the caller happened to
    be in. The test copies the script to a fresh directory (standing in for a
    different checkout) and checks the prologue lands there, run from an
    unrelated cwd.
    """
    print("p2_lsf_launch.sh relocatability  [%s]" % os.path.basename(script_path))
    with open(script_path) as fh:
        lines = fh.readlines()

    # Stop at whatever line launches the runner. Keyed on the runner's NAME
    # rather than on `exec`/`setsid`, so changing HOW it is launched (as the
    # detachment fix did) does not silently turn this test into a no-op.
    prologue = []
    for line in lines:
        if "axi4_regression.py" in line:
            break
        prologue.append(line)
    else:
        check("runner invocation found in script", False, True)
        return

    tmpdir = tempfile.mkdtemp(prefix="relocate_")
    try:
        copied = os.path.join(tmpdir, os.path.basename(script_path))
        with open(copied, "w") as fh:
            fh.write("".join(prologue) + "\npwd\n")
        os.chmod(copied, 0o755)
        # cwd="/" so a script that resolves nothing at all is visible as "/".
        proc = subprocess.run(["bash", copied], cwd="/",
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        landed = proc.stdout.decode().strip()
        check("relocated copy lands in its own dir",
              os.path.realpath(landed) if landed else "(no output)",
              os.path.realpath(tmpdir))
        check("does not silently land in the caller's cwd", landed != "/", True)
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)


def test_lsf_launcher_detaches(script_path):
    """The launcher must really leave the caller's session.

    Its header promises the run "survives the calling session". With a plain
    `exec python3 ...` that was untrue: the runner stayed in the caller's
    session and a dropped SSH connection could SIGHUP it after LSF jobs had
    been submitted but before their results were collected.

    Checked behaviourally, not by grepping for "setsid": the script is copied
    to a temp dir alongside a stub `axi4_regression.py` that prints its own
    session id, then run. A detached runner reports a DIFFERENT session id
    from this test process.
    """
    print("p2_lsf_launch.sh detachment  [%s]" % os.path.basename(script_path))

    tmpdir = tempfile.mkdtemp(prefix="detach_")
    try:
        shutil.copy(script_path, os.path.join(tmpdir, "p2_lsf_launch.sh"))
        os.chmod(os.path.join(tmpdir, "p2_lsf_launch.sh"), 0o755)
        # Stub standing in for the real runner: report the session we ended up in.
        with open(os.path.join(tmpdir, "axi4_regression.py"), "w") as fh:
            fh.write("import os\nprint('SID=%d' % os.getsid(0))\n")
        # The launcher's default --test-list path is outside the temp dir; the
        # stub ignores its arguments, so that does not matter.

        proc = subprocess.run(["bash", os.path.join(tmpdir, "p2_lsf_launch.sh")],
                              cwd="/", stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        check("launcher exits 0", proc.returncode, 0)

        # The runner is detached, so give it a moment to write its log.
        runner_sid = None
        for _ in range(50):
            logs = [f for f in os.listdir(tmpdir) if f.startswith("lsf_launch_")]
            if logs:
                body = open(os.path.join(tmpdir, logs[0])).read()
                if "SID=" in body:
                    runner_sid = int(body.split("SID=")[1].split()[0])
                    break
            time.sleep(0.1)

        my_sid = os.getsid(0)
        if runner_sid is None:
            check("runner wrote its log", False, True)
        else:
            check("runner runs in a different session", runner_sid != my_sid, True)
            print("        caller sid=%d, runner sid=%d" % (my_sid, runner_sid))
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)


if __name__ == "__main__":
    reg = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "axi4_regression.py")
    p4 = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, "p4_runall.sh")
    lsf = sys.argv[3] if len(sys.argv) > 3 else os.path.join(HERE, "p2_lsf_launch.sh")

    test_default_max_parallel(reg)
    print()
    test_p4_runall_shift(p4)
    print()
    test_lsf_launcher_is_relocatable(lsf)
    print()
    test_lsf_launcher_detaches(lsf)
    print()
    if FAILURES:
        print("%d check(s) FAILED: %s" % (len(FAILURES), ", ".join(FAILURES)))
        sys.exit(1)
    print("all checks passed")
