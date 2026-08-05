#!/bin/bash
# Regenerate sim/synopsys_sim/prephase2/axi4_slave_driver_proxy.sv -- the
# pre-Phase-2 (F2-buggy) subordinate used to build the same-ID order checker's
# "teeth" binary. See prephase2/README.md and AXI_ooo.md Phase 3.
#
# a9017e8 is the last commit BEFORE AXI_ooo.md Phase 2's per-ID read-response
# FIFO fix. Pinned by SHA on purpose: Phase 2 is (at the time of writing) an
# uncommitted working-tree change, so HEAD happens to be equivalent today and
# will stop being equivalent the moment Phase 2 is committed.
set -euo pipefail

PREPHASE2_SHA=a9017e8
cd "$(dirname "$0")"
REPO_ROOT=$(git rev-parse --show-toplevel)
OUT=prephase2/axi4_slave_driver_proxy.sv

mkdir -p prephase2
git -C "$REPO_ROOT" show "${PREPHASE2_SHA}:slave/axi4_slave_driver_proxy.sv" > "$OUT"

# Self-check: the staged file must be byte-identical to the pinned blob.
if git -C "$REPO_ROOT" show "${PREPHASE2_SHA}:slave/axi4_slave_driver_proxy.sv" | cmp -s - "$OUT"; then
  echo "OK: $OUT regenerated from ${PREPHASE2_SHA} ($(wc -l < "$OUT") lines)"
else
  echo "ERROR: $OUT does not match ${PREPHASE2_SHA}" >&2
  exit 1
fi
