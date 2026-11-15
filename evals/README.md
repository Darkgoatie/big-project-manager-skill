# Evals

Not yet run. These define what to measure; the results belong in `benchmarks/` once there are some.

- `trigger-evals.json`: does the skill's description load it for the right requests? Each entry is a query and whether the skill should trigger. Run it against the `description` in SKILL.md and change the description until both halves pass.
- `evals.json`: does the agent follow the process once the skill is loaded? Each eval is a prompt plus expectations a grader can check against the transcript and the resulting files. Run each one with and without the skill.

Evals 2 to 5 name a fixture repo under `fixtures/`. Those fixtures do not exist yet. Each is a small git repo in a known state:

| Fixture | State |
|---|---|
| `resume-interrupted/` | `docs/spec/` present, task 3 pending, two commits with `Task: 3` trailers |
| `weakened-test/` | task 3 started, its commits add `@pytest.mark.skip` to a test |
| `two-failures/` | task 5 with `attempts: 2`, `status: needs-fix` |
| `ready-task/` | task 2 pending, dependencies done, hooks installed, a `.env` file with a fake secret |

`tests/run.sh` builds very similar states to test the scripts, so it is the place to start when writing them.

## The benchmark that is still missing

The token numbers in `benchmarks/` come from a model, not from runs. To replace them: take one real project of 10 to 15 tasks, run it once with the skill and once without, on the same model, and record per task the tokens the host reports, whether the acceptance check passed, and how many review findings there were. Add a third run with graphify to see what the graph changes.
