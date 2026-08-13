#!/bin/bash
# Detached launcher for the full LSF regression, so the run survives the calling
# session. Results land in sim/synopsys_sim/regression_result_<ts>/.
#
# "Survives the calling session" is a real guarantee here, not a comment:
# `setsid` puts the runner in a NEW session with no controlling terminal, so a
# dropped SSH connection cannot SIGHUP it. The previous `exec python3 ...` left
# the runner in the caller's session, where a hangup could kill it part-way --
# after LSF jobs had been submitted but before their results were collected,
# which is the worst possible moment (farm work continues, nobody harvests it).
#
# Because the runner is detached, its stdout cannot go to the caller's terminal;
# it goes to a timestamped log whose path is printed before this script returns.
#
# Resolve the run directory from THIS script's location, never from a hard-coded
# checkout. The path used to be /home/<user>/... verbatim, so on any other
# checkout the cd failed; and without `set -e` the script carried on and ran
# python3 in whatever directory the caller happened to be in.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

TEST_LIST=${TEST_LIST:-../../testlists/axi4_transfers_regression.list}
PARALLEL=${PARALLEL:-12}
TIMEOUT=${TIMEOUT:-1800}
LOG="lsf_launch_$(date +%Y%m%d_%H%M%S).log"

# </dev/null so the runner never blocks on terminal input it will never get.
setsid python3 axi4_regression.py --lsf \
       --test-list "$TEST_LIST" \
       -p "$PARALLEL" -t "$TIMEOUT" \
       </dev/null >"$LOG" 2>&1 &

echo "regression detached (new session); log: $(pwd)/$LOG"
