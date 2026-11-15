#!/bin/sh
# smoke: build, test, run one short real scenario, count ERROR lines.
# `git bpm init` copies this to scripts/smoke.sh; fill in the three commands.
# Every task must pass it. It writes .smoke/result.txt ("name value" lines),
# which `git bpm baseline` records and `git bpm review` compares.
#
# Exit codes: 0 pass, 1 build failed, 2 tests failed, 3 scenario failed,
#             4 ERROR lines above the allowed count.

BUILD_CMD="${BUILD_CMD:-echo 'TODO: build command'}"
TEST_CMD="${TEST_CMD:-echo 'TODO: test command'}"
SCENARIO_CMD="${SCENARIO_CMD:-echo 'TODO: short real scenario'}"
MAX_ERRORS="${MAX_ERRORS:-0}"
ERROR_PATTERN="${ERROR_PATTERN:-ERROR}"
# Extra runtime logs the scenario writes (space-separated), also counted.
EXTRA_LOGS="${EXTRA_LOGS:-}"
# How to find test counts in the test output. The counts are for comparing
# runs with each other, so they only need to be consistent, not exact.
PASS_REGEX="${PASS_REGEX:-[0-9]+ (passed|passing)}"
FAIL_REGEX="${FAIL_REGEX:-[0-9]+ (failed|failing)}"
# The scenario can report numbers of its own by printing lines like
#   METRIC p95_ms 41
# Each becomes a line in result.txt; give it a rule in docs/spec/baseline.txt.

OUT="${SMOKE_OUT:-.smoke}"
mkdir -p "$OUT"
RES="$OUT/result.txt"; : > "$RES"
count() { grep -oE "$1" "$OUT/test.log" 2>/dev/null | awk '{ s += $1 } END { print s + 0 }'; }

start=$(date +%s)
sh -c "$BUILD_CMD" > "$OUT/build.log" 2>&1 || { echo "smoke: build FAILED (see $OUT/build.log)"; exit 1; }
build_s=$(( $(date +%s) - start ))

sh -c "$TEST_CMD" > "$OUT/test.log" 2>&1
test_rc=$?
passed=$(count "$PASS_REGEX")
failed=$(count "$FAIL_REGEX")

sh -c "$SCENARIO_CMD" > "$OUT/scenario.log" 2>&1
scen_rc=$?

# shellcheck disable=SC2086
errors=$(cat "$OUT/scenario.log" $EXTRA_LOGS 2>/dev/null | grep -c "$ERROR_PATTERN")

{
  echo "build_s $build_s"
  echo "tests_rc $test_rc"
  echo "tests_passed $passed"
  echo "tests_failed $failed"
  echo "scenario_rc $scen_rc"
  echo "error_lines $errors"
  sed -nE 's/^METRIC[[:space:]]+([A-Za-z0-9_.-]+)[[:space:]]+(-?[0-9.]+).*/\1 \2/p' "$OUT/scenario.log"
} > "$RES"

echo "smoke: build=${build_s}s tests=${passed} passed ${failed} failed (rc $test_rc) scenario_rc=$scen_rc error_lines=$errors (max $MAX_ERRORS)"

[ $test_rc -eq 0 ] || { echo "smoke: tests FAILED (see $OUT/test.log)"; exit 2; }
[ $scen_rc -eq 0 ] || { echo "smoke: scenario FAILED (see $OUT/scenario.log)"; exit 3; }
[ "$errors" -le "$MAX_ERRORS" ] || { echo "smoke: too many ERROR lines"; exit 4; }
echo "smoke: PASS"
