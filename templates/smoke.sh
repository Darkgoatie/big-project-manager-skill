#!/usr/bin/env sh
# Smoke check every task must pass. Copy to scripts/smoke.sh in your project
# and fill in the three commands. Exits non-zero on any failure or on more
# ERROR lines than the baseline allows.
set -eu

BUILD_CMD="${BUILD_CMD:-echo 'BUILD_CMD not set'; exit 1}"        # e.g. cargo build --release
TEST_CMD="${TEST_CMD:-echo 'TEST_CMD not set'; exit 1}"           # e.g. cargo test
SCENARIO_CMD="${SCENARIO_CMD:-echo 'SCENARIO_CMD not set'; exit 1}" # a short real run, e.g. ./bin/server --run-for 60s
MAX_ERRORS="${MAX_ERRORS:-0}"                         # baseline from SPEC.md

log_dir="${SMOKE_LOG_DIR:-.smoke}"
mkdir -p "$log_dir"

step() {
  name="$1"; shift
  printf '== %s\n' "$name"
  if ! sh -c "$*" >"$log_dir/$name.log" 2>&1; then
    printf 'FAIL: %s (see %s/%s.log)\n' "$name" "$log_dir" "$name"
    tail -n 20 "$log_dir/$name.log"
    exit 1
  fi
}

step build "$BUILD_CMD"
step test "$TEST_CMD"
step scenario "$SCENARIO_CMD"

errors=$(cat "$log_dir"/*.log | grep -c 'ERROR' || true)
printf 'ERROR lines: %s (max %s)\n' "$errors" "$MAX_ERRORS"
if [ "$errors" -gt "$MAX_ERRORS" ]; then
  echo "FAIL: ERROR lines above baseline"
  exit 1
fi
echo "smoke OK"
