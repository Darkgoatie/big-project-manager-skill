#!/bin/sh
# Tests for scripts/bpm and scripts/smoke.sh. Builds a scratch repo and walks
# through a project: init, tasks, a clean task, a bad task, retries, checks.
# Usage: sh tests/run.sh

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
BPM="$ROOT/scripts/bpm"
T=$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/bpm-test-$$")
mkdir -p "$T/repo"
trap 'cd /; rm -rf "$T"' EXIT

pass=0; fail=0
ok() { if [ "$1" -eq 0 ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $2"; fi; }
yes() { d=$1; shift; "$@" >/dev/null 2>&1; ok $? "$d"; }
no() { d=$1; shift; "$@" >/dev/null 2>&1; [ $? -ne 0 ]; ok $? "$d"; }
has() { printf '%s' "$2" | grep -q -- "$3"; ok $? "$1 (wanted: $3)"; }
hasnt() { printf '%s' "$2" | grep -q -- "$3"; [ $? -ne 0 ]; ok $? "$1 (unwanted: $3)"; }
bpm() { ${BPM_SH:-sh} "$BPM" "$@"; }
acceptance() { # acceptance <id> <text>: fill in a task's acceptance check
  f=$(printf 'docs/spec/tasks/%03d.md' "$1")
  sed "s|^<one thing you can see.*|$2|" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}

cd "$T/repo" || exit 1
git init -q
git config user.email test@example.com
git config user.name test
git config commit.gpgsign false
git config core.safecrlf false

export BUILD_CMD=true
export TEST_CMD='echo "3 passed, 0 failed"'
export SCENARIO_CMD='echo ok; echo "METRIC p95_ms 40"'

# ---- init
out=$(bpm init)
has "init prints the next steps" "$out" "git bpm"
yes "init creates the task dir" test -d docs/spec/tasks
yes "init copies the child prompt" test -f docs/spec/templates/CHILD_PROMPT.md
yes "init copies bpm" test -f scripts/bpm
yes "init copies smoke.sh" test -f scripts/smoke.sh
yes "init installs pre-commit" grep -q 'bpm hook' "$(git rev-parse --git-path hooks)/pre-commit"
yes "init installs commit-msg" grep -q 'bpm hook' "$(git rev-parse --git-path hooks)/commit-msg"
yes "git alias works" git bpm help
BPM=scripts/bpm
yes "init is repeatable" bpm init

# ---- modules and tasks
cat > docs/spec/modules/store.md <<'EOF'
# Module: store

## Public interface
| Name | Signature | Errors |
|---|---|---|
| `put` | `put(key, value)` | none |

## Depends on

## Owned files
- src/store.py
- tests/test_store.py
- src/my file.py
EOF
cat > docs/spec/modules/api.md <<'EOF'
# Module: api

## Public interface
| Name | Signature | Errors |
|---|---|---|
| `handle` | `handle(request)` | none |

## Depends on
- store: put

## Owned files
- src/api.py
EOF

has "new creates task 1" "$(bpm new 'Store put' store)" "001.md"
bpm set 1 files 'src/store.py, tests/test_store.py, `src/my file.py`' >/dev/null
acceptance 1 "store round trip prints OK"
bpm new "API handler" api >/dev/null
bpm set 2 files "src/api.py" >/dev/null
bpm set 2 depends "1" >/dev/null
acceptance 2 "GET /x returns 200"
bpm new "Later work" api >/dev/null
bpm set 3 files "src/api.py" >/dev/null
bpm set 3 depends "2" >/dev/null
acceptance 3 "something visible"
bpm stop 3 >/dev/null
has "index lists the tasks" "$(cat docs/spec/TASKS.md)" "API handler"
has "index shows STOP" "$(cat docs/spec/TASKS.md)" "STOP"

mkdir -p src tests
printf 'def put(key, value):\n    return True\n' > src/store.py
printf 'from store import put\ndef handle(request):\n    return put(request, 1)\n' > src/api.py
printf 'def test_put():\n    assert True\n    assert 1\n' > tests/test_store.py
yes "check passes on a complete spec" bpm check

yes "smoke passes" sh scripts/smoke.sh
has "smoke counts passed tests" "$(cat .smoke/result.txt)" "tests_passed 3"
has "smoke records metrics" "$(cat .smoke/result.txt)" "p95_ms 40"
yes "baseline is recorded" bpm baseline
no "baseline is not overwritten silently" bpm baseline
sed 's/^p95_ms 40 info/p95_ms 40 max+10%/' docs/spec/baseline.txt > b.tmp && mv b.tmp docs/spec/baseline.txt
git add -A && git commit -qm "spec and skeleton"

# ---- task 1: a clean run
has "next offers task 1" "$(bpm next)" "next: task 1"
echo "my notes" > notes.txt
printf 'draft\n' >> docs/spec/tasks/002.md
no "start refuses an uncommitted task file" bpm start 2
git checkout -q docs/spec/tasks/002.md
no "start refuses a task with unmet dependencies" bpm start 2
yes "start 1" bpm start 1
bpm next >/dev/null 2>&1; ok "$([ $? -eq 4 ] && echo 0 || echo 1)" "next reports a task in progress (exit 4)"

printf 'def put(key, value):\n    return (key, value)\n' > src/store.py
printf 'x = 1\n' > "src/my file.py"
git add src/store.py "src/my file.py"
yes "commit of listed files is allowed (path with a space too)" git commit -qm "store: return the pair"
has "commit gets the Task trailer" "$(git log -1 --format=%B)" "Task: 1"

echo "# changed" >> src/api.py
git add src/api.py
no "commit outside the list is rejected" git commit -qm "sneaky"
git reset -q HEAD src/api.py; git checkout -q src/api.py

out=$(bpm review 1); rc=$?
ok $rc "review of a clean task passes"
has "review compares with the baseline" "$out" "p95_ms"
has "review says PASS" "$out" "review: PASS"
yes "done 1" bpm done 1
has "task 1 is done" "$(bpm status)" "done"
has "status counts commits from trailers" "$(bpm status | awk '$1 == 1')" " 1  Store put"
git add -A docs/spec && git commit -qm "spec: task 1 done"
hasnt "commits without a task carry no trailer" "$(git log -1 --format=%B)" "Task:"

# ---- task 2: a bad run
yes "start 2" bpm start 2
out=$(bpm prompt 2)
has "prompt has the task title" "$out" "API handler"
has "prompt has the acceptance check" "$out" "GET /x returns 200"
has "prompt lists the files" "$out" "^- src/api.py"
has "prompt includes the dependency's interface" "$out" "put(key, value)"
hasnt "prompt leaves no placeholder" "$out" "{{"

printf 'from store import put\ndef handle(request):\n    return put(request, 1)\ndef orphan_helper():\n    pass\n' > src/api.py
printf 'import pytest\n@pytest.mark.skip\ndef test_put():\n    return\n' > tests/test_store.py
echo "overwritten" > notes.txt
git add src/api.py tests/test_store.py
git commit -q --no-verify -m "api: stuff"
out=$(bpm review 2 --no-smoke); rc=$?
ok "$([ $rc -ne 0 ] && echo 0 || echo 1)" "review of a bad task fails"
has "review flags a file outside the list" "$out" "outside the task's list was changed: tests/test_store.py"
has "review flags the missing trailer" "$out" "no 'Task: 2' trailer"
has "review flags a skip marker" "$out" "skip markers"
has "review flags lost asserts" "$out" "lost asserts"
has "review flags an uncalled function" "$out" "orphan_helper"
has "review flags the user's changed file" "$out" "uncommitted before the task has changed: notes.txt"
no "done is refused without a passing review" bpm done 2
has "prompt --review lists the commits" "$(bpm prompt 2 --review)" "api: stuff"
no "fail needs a note on what changes" bpm fail 2
has "fail counts the attempt" "$(bpm fail 2 'narrower scope')" "attempt 1 failed"
has "fail records the note" "$(cat docs/spec/tasks/002.md)" "narrower scope"
has "revert undoes the commits" "$(bpm revert 2)" "reverted 1 commits"
hasnt "the reverted code is gone" "$(cat src/api.py)" "orphan_helper"
git add -A docs/spec && git commit -qm "spec: task 2 reverted"
has "next offers the retry" "$(bpm next)" "attempt 2"
yes "start 2 again" bpm start 2
has "second failure escalates" "$(bpm fail 2 'split it')" "ESCALATE"
git add -A docs/spec && git commit -qm "spec: task 2 failed twice"
bpm next >/dev/null 2>&1; ok "$([ $? -eq 6 ] && echo 0 || echo 1)" "next escalates after two failures (exit 6)"
no "start refuses a third attempt" bpm start 2

# ---- STOP
bpm set 2 status dropped >/dev/null
bpm next >/dev/null 2>&1; ok "$([ $? -eq 3 ] && echo 0 || echo 1)" "next halts at STOP (exit 3)"
bpm stop --clear 3 >/dev/null
bpm next >/dev/null 2>&1; ok "$([ $? -eq 5 ] && echo 0 || echo 1)" "next reports nothing runnable when a dependency was dropped (exit 5)"

# ---- regression against the baseline
printf 'tests_passed 2\ntests_failed 0\ntests_rc 0\nscenario_rc 0\nerror_lines 0\np95_ms 50\n' > r.txt
out=$(bpm compare r.txt docs/spec/baseline.txt); rc=$?
ok "$([ $rc -ne 0 ] && echo 0 || echo 1)" "compare fails on a regression"
has "compare flags fewer passing tests" "$out" "tests_passed.*REGRESSION"
has "compare flags a metric over its tolerance" "$out" "p95_ms.*REGRESSION"
printf 'tests_passed 3\ntests_failed 0\ntests_rc 0\nscenario_rc 0\nerror_lines 0\np95_ms 43\n' > r.txt
yes "compare accepts a metric inside its tolerance" bpm compare r.txt docs/spec/baseline.txt
rm -f r.txt

# ---- smoke failures
SCENARIO_CMD='echo "ERROR boom"' sh scripts/smoke.sh >/dev/null 2>&1; ok "$([ $? -eq 4 ] && echo 0 || echo 1)" "smoke fails on ERROR lines (exit 4)"
TEST_CMD='exit 7' sh scripts/smoke.sh >/dev/null 2>&1; ok "$([ $? -eq 2 ] && echo 0 || echo 1)" "smoke fails when tests fail (exit 2)"

# ---- check catches drift
sed 's/| `handle` |/| `handle_request` |/' docs/spec/modules/api.md > m.tmp && mv m.tmp docs/spec/modules/api.md
out=$(bpm check); rc=$?
ok "$([ $rc -ne 0 ] && echo 0 || echo 1)" "check fails when the spec names an interface the code lacks"
has "check names the interface" "$out" "handle_request"
git checkout -q docs/spec/modules/api.md
printf -- '- src/store.py\n' >> docs/spec/modules/api.md
has "check flags a file with two owners" "$(bpm check)" "more than one module"
git checkout -q docs/spec/modules/api.md

# ---- Claude Code hook for bpm-worker
bpm set 3 depends "-" >/dev/null
git add -A && git commit -qm "spec: task 3 unblocked" -q
yes "start 3" bpm start 3
root=$(git rev-parse --show-toplevel)
hook() { printf '%s' "$1" | BPM_EXTRA_READS=2 sh scripts/bpm hook claude-pretool >/dev/null 2>&1; echo $?; }
ok "$([ "$(hook "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$root/src/api.py\",\"old_string\":\"a\"}}")" -eq 0 ] && echo 0 || echo 1)" "hook allows an edit to a listed file"
ok "$([ "$(hook "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$root/src/store.py\"}}")" -eq 2 ] && echo 0 || echo 1)" "hook blocks an edit outside the list"
ok "$([ "$(hook '{"tool_name":"Write","tool_input":{"file_path":"docs/spec/tasks/003.md"}}')" -eq 2 ] && echo 0 || echo 1)" "hook blocks editing the task file"
ok "$([ "$(hook '{"tool_name":"Bash","tool_input":{"command":"grep -rn handle ."}}')" -eq 2 ] && echo 0 || echo 1)" "hook blocks a recursive grep"
ok "$([ "$(hook '{"tool_name":"Bash","tool_input":{"command":"cd src && find . -name x"}}')" -eq 2 ] && echo 0 || echo 1)" "hook blocks find after &&"
ok "$([ "$(hook '{"tool_name":"Bash","tool_input":{"command":"git commit --amend -m x"}}')" -eq 2 ] && echo 0 || echo 1)" "hook blocks amend"
ok "$([ "$(hook '{"tool_name":"Bash","tool_input":{"command":"sh scripts/smoke.sh && git commit -m \"find the bug\""}}')" -eq 0 ] && echo 0 || echo 1)" "hook allows smoke and commit"
ok "$([ "$(hook '{"tool_name":"Read","tool_input":{"file_path":"src/store.py"}}')" -eq 0 ] && echo 0 || echo 1)" "hook allows a first read outside the list"
ok "$([ "$(hook '{"tool_name":"Read","tool_input":{"file_path":"src/store.py"}}')" -eq 0 ] && echo 0 || echo 1)" "hook does not count a repeated read"
hook '{"tool_name":"Read","tool_input":{"file_path":"notes.txt"}}' >/dev/null
ok "$([ "$(hook '{"tool_name":"Read","tool_input":{"file_path":"README.md"}}')" -eq 2 ] && echo 0 || echo 1)" "hook blocks reads past the budget"
ok "$([ "$(hook '{"tool_name":"Read","tool_input":{"file_path":"src/api.py"}}')" -eq 0 ] && echo 0 || echo 1)" "hook always allows reading listed files"

# ---- interrupted run is visible
echo "# more" >> src/api.py; git add src/api.py; git commit -qm "api: partial"
rm -f "$(git rev-parse --git-dir)/bpm/current"
has "status flags an interrupted task" "$(bpm status)" "task 3 is pending but has 1 commits"

echo
echo "$pass passed, $fail failed"
[ $fail -eq 0 ]
