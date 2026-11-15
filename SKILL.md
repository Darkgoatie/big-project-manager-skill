---
name: big-project-manager
description: Run projects too big for one context window through a living spec, small verified tasks, and narrowly scoped sub-agents. Use when asked to build something large, finish or take over the rest of a repo, resume half-done multi-session work, or coordinate several sub-agents; not for single-file fixes or one-sitting features.
version: 0.3.0
author: Darkgoatie
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [project-management, planning, delegation, spec, sub-agents, verification]
    related_skills: [graphify]
---

# Big Project Manager

For work too big to hold in one context, including taking over an existing repo's remaining work. Runs on a living spec: every step reads it, every change updates it. The bookkeeping is done by a script, `bpm`, so the rules below are enforced rather than remembered. `examples/linkshort/` shows a spec part-way through a project.

## When to Use
Use for multi-session projects or finishing a repo: living spec, modules, verified sub-agents.

- A project or feature set too large for one context window.
- "Finish the rest of this repo" or taking over half-done work.
- Work that will span several sessions or several sub-agents.

Don't use for: single-file fixes, one-sitting features, or exploratory spikes on their own (run the spike, then come back here if it grows).

## The runner: `git bpm`
Set up once per project, from the project root (`<skill-dir>` is the folder holding this file, written with forward slashes):

```
git -c "alias.bpm=!sh '<skill-dir>/scripts/bpm'" bpm init
```

This creates `docs/spec/`, copies `scripts/bpm` and a smoke script into the project, installs two git hooks, and adds a `git bpm` alias that works from any shell on any platform. In a Claude Code project it also adds the `bpm-worker` and `bpm-reviewer` agents (`--claude` forces this). Commit `scripts/` and `docs/spec/` before the first task.

| Command | What it does |
|---|---|
| `git bpm new "<title>" <module>` | Creates `docs/spec/tasks/NNN.md`. Numbers are never reused. |
| `git bpm next` | Names the next runnable task. Halts at a STOP, and after two failed attempts. |
| `git bpm start <id>` | Records the base commit and turns the commit guard on for that task's files. |
| `git bpm prompt <id>` | Prints the child's prompt. `--review` prints the reviewer's. |
| `git bpm review <id>` | The mechanical review, including the smoke run against the baseline. |
| `git bpm done <id> --cost "<n>"` | Marks it done. Refuses without a passing review of the current commit. |
| `git bpm fail <id> "<what changes>"` | Counts the attempt and records what the next one changes. |
| `git bpm revert <id>` | `git revert`s the task's commits and marks it reverted. |
| `git bpm status` | Tasks, attempts, commits per task, and anything inconsistent. Start here when resuming. |
| `git bpm check` | The spec still matches the code: interfaces exist, no file has two owners, tasks are complete. |

`git bpm help` lists the rest. bpm needs git. In a project without a repo, keep the same files under `plans/<project>/` and follow the steps by hand.

## Optional: code graph (graphify)
If the graphify skill or CLI is available, the manager uses its knowledge graph to learn the repo without reading it. Steps below marked **[graph]** use it; without graphify, skip those lines and the rest works unchanged.
- The graph is for the manager. Children never get the graph, the HTML, or query access; at most one budgeted query result in their task's Context section.
- The graph is a hint, not the spec. Only EXTRACTED edges count as evidence in a review; INFERRED and AMBIGUOUS edges are leads to check by reading the code.
- Keep `graphify-out/` out of task file lists and out of children's commits.

## 0. Inventory what exists
Before writing anything, list the repo's existing design docs (ARCHITECTURE.md, blueprints/, API maps, TODO.md, progress logs). Link to them from the spec; write only what is missing. Duplicating an existing doc creates two sources that drift.

**[graph]** Build or refresh the graph (`/graphify .`, or `/graphify . --update` if `graphify-out/` exists) and read `graphify-out/GRAPH_REPORT.md` instead of browsing source. Link it from SPEC.md under Existing docs.

If `docs/spec/` already exists, you are resuming: read HANDOFF.md and run `git bpm status`. It derives each task's commits from git and flags what does not add up, such as a pending task that already has commits. Review or revert that work before starting anything new. Do not resume from memory or from an old transcript.

## 1. Write the spec
In `docs/spec/`:
- `SPEC.md`: goal, non-goals, constraints (platform, stack, performance), glossary, links to existing docs.
- `ARCHITECTURE.md` only if the repo has none: components, data flow, storage, key decisions with a one-line reason each.
- Open questions. Ask the user about anything that changes the architecture; decide low-stakes items yourself and note them.
- State the core model in one sentence and get the user to confirm it before anything else (e.g. "each tenant gets an isolated database behind one shared API"). A wrong core model silently shapes every later step.
- Risky unknowns (an untested library, a platform quirk, a performance ceiling): list them and plan a throwaway spike for each. Record the yes/no result and numbers in SPEC.md; delete the spike code.
Do not start implementing until the user has seen the spec.

## 2. Decompose into modules
For each module, `docs/spec/modules/<name>.md` (skeleton in `docs/spec/templates/module.md`) with:
- Responsibility (one paragraph) and what it does NOT do.
- Public interface: functions/types/messages with signatures, inputs, outputs, errors.
- Invariants the implementation must hold, not just signatures. Examples: "non-blocking socket reads and writes buffer partial frames"; "no side vectors kept aligned by index with another list"; "an idle queue consumes no CPU".
- Dependencies: only other modules' interfaces, never their internals, and which modules it must never depend on.
- Files it owns, and how to test it in isolation.
If two modules need each other's internals, the boundary is wrong. Fix the spec, not the code.

**[graph]** In an existing repo, use the report's communities as a first draft of modules, its god nodes as candidate public interfaces, and its surprising cross-community connections as boundary problems to resolve in the spec.

## 3. Baseline and smoke test
Before the first task:
- Fill in the build, test and scenario commands in `scripts/smoke.sh`: it builds, runs the tests, runs one short real scenario, and counts ERROR lines. The scenario can report its own numbers by printing `METRIC <name> <value>`. Every task must pass it, so "verified" means the same thing for every agent.
- Run it, then `git bpm baseline`. That writes `docs/spec/baseline.txt` with a rule per metric: test counts may not drop, failures and ERROR lines may not rise. Give each performance metric a tolerance by hand (`p95_ms 12 max+25%`). Every review compares against this file, and it changes only with the user's agreement.

## 4. Write the tasks
- One file per task, created with `git bpm new`: small (one sitting, a few commits), with module, files, dependencies, and an observable acceptance check. "Tests pass" is not enough: name something you can see or measure ("a 60 s run of the standard scenario has 0 ERROR lines", "a client that stops reading for 2 s stays connected").
- `files` is a comma-separated list of paths or globs (`src/net/socket.rs, tests/net_*.rs`). The commit guard and the review both enforce it.
- **[graph]** Fill a task's file list and dependencies from `graphify query "<task>" --budget 1500` and `graphify explain "<symbol>"`, then confirm against the module spec, instead of grepping the repo.
- Ideas raised mid-run become new task files and do not interrupt the current task. `docs/spec/TASKS.md` is a generated index; do not edit it.
- Order: first a thin end-to-end slice (the real entry point exercising the core model with minimal features), then widen. It exposes a wrong architecture while it is cheap to change.
- Size by cost too: long runs re-send a growing context every call, so cache reads dominate spend. Give each task a context `budget` and an `effort` (lower effort is several times cheaper for routine coding). Treat budgets as defaults; tune them to the model and pricing in use.
- The user halts the run before any task with `git bpm stop <id>`. Only the user clears a STOP.
- Review the list before executing: merge trivial steps, split vague ones, reorder by dependency, drop anything outside the spec (`git bpm set <id> status dropped`). Show it to the user and adjust. Then run `git bpm check` and commit.

## 5. Delegate with focused context
For each task: `git bpm next`, `git bpm start <id>`, then give a sub-agent the output of `git bpm prompt <id>` as its whole prompt. This applies to any sub-agent mechanism (built-in subagents, spawned CLI agents, a second session). Without one, do the task yourself under the same rules.
- The prompt holds only the task, its acceptance check, its module spec, the interfaces of the modules it calls, and the files it may touch. Do not add SPEC.md, other modules' specs, unrelated source, or anything from your own context.
- **[graph]** You may put one budgeted query result (a few thousand tokens at most) in the task's Context section. Never more, and never tool access to the graph.
- In Claude Code, launch the `bpm-worker` agent. It has no search tools; its edits outside the task's files are blocked, searching the repo from the shell is blocked, and reads outside its list are capped. Elsewhere those limits exist only as rules in the prompt, so check harder in review.
- While a task is started, the pre-commit hook rejects staged files outside its list, and every commit gets a `Task: <id>` trailer. This is what protects the user's uncommitted work; do not turn it off to get a commit through.
- Never put secrets, tokens, or `.env` contents in a prompt or a task file; name the variable and let the environment supply the value.
- Parallel only when file sets are disjoint and each child has its own git worktree, with `git bpm start <id>` run inside that worktree. Default to sequential.
- A one-shot child reads its prompt at start. Change a task file before `git bpm start`, never after; `start` refuses a task file with uncommitted changes.

## 6. Review every task (the child's report is not proof)
Hand the review to a fresh sub-agent with the output of `git bpm prompt <id> --review` (`bpm-reviewer` in Claude Code). It did not write the code, it changes nothing, and it returns a verdict with evidence. You read the verdict, not the diff.

`git bpm review <id>` is the first step of every review. It fails the task if:
- a commit touched a file outside the task's list, or carries no `Task: <id>` trailer (a bypassed hook);
- tests gained skip markers, lost asserts, or gained bare early returns;
- a new function has no callers;
- history was rewritten (reset, rebase, amend, stash), or a file that was uncommitted before the task has changed;
- the smoke script fails on a clean checkout of the commit, or any baseline rule is broken.

The reviewer then does what a script cannot:
- Runs the acceptance check, and the real feature end to end (the actual binaries, the actual user action), including the reverse path (pause then unpause, disconnect then reconnect).
- Counts ERROR lines in every runtime log, not just panics.
- Checks the module spec's invariants against the diff.
- **[graph]** Runs `graphify . --update`, then `graphify path "<module>" "<forbidden module>"` for each forbidden dependency in the module spec. A new EXTRACTED edge means the boundary broke.
- Changed data formats, schemas, save files or config: requires a migration and a test that loads data written by the previous version.
- New dependencies: checks license and size, and that the module spec records a one-line reason.

Findings that do not fail the task become new task files, done before dependent work.

## 7. Stop, escalate, roll back
- Review failed: `git bpm fail <id> "<what the next attempt changes>"`, then `git bpm revert <id>` (never reset). The next attempt must differ: a narrower task, a different approach, a stronger model or higher effort. An identical retry fails the same way.
- Two failed attempts: bpm stops offering the task. Split it into smaller tasks or ask the user.
- A child reports it needs an interface change: `git bpm fail` the task, update the module spec, get approval for anything architectural, then continue.
- A done task turns out to be wrong later: `git bpm revert <id>`, and revisit the done tasks it names as depending on it.

## 8. Update the spec after every change
After `git bpm done <id>`: update the module file (interface, invariants, files), ARCHITECTURE.md if a decision changed, and HANDOFF.md (current state against the baseline, what is blocked, next task). Record deviations in one line. Run `git bpm check`, then commit the spec with the code or right after. Never leave code and spec disagreeing.

Record the task's cost as the token count your host reports for the child and the reviewer (`--cost "48k + 12k tokens"`). If the host reports nothing, write `unknown`. Never estimate it.

**[graph]** Keep the graph current (`--update` after each task, or graphify's post-commit hook) so a resumed session starts from an accurate map.

## 9. Keep your own context small
On a long run the manager's context is re-sent on every call, so it is the largest cost you control.
- Do not read children's transcripts, full diffs, or source files you are not specifying. Read reports and verdicts.
- Start a fresh manager session every 5 or so tasks, or sooner if your context is past half full: update HANDOFF.md, commit, and tell the user to continue in a new session from HANDOFF.md and `git bpm status`. Everything needed to resume is in the repo by design.
- After each task, report in a few lines: commits, what was verified against the baseline, cost, what is still open. Don't replay the process.

## 10. Definition of done
The project is done when: every task is done or explicitly dropped by the user, `git bpm check` passes, the smoke script and a full end-to-end run pass with no regression against the baseline, HANDOFF.md reflects the final state, and a final report lists total cost and known limitations.

## Pitfalls
- Skipping the spec for "quick" pieces: that's where boundaries rot.
- Giant tasks ("implement backend"): split until each has one acceptance check.
- Adding to the generated child prompt "to be helpful", or letting a child browse: it wanders, edits unrelated files, and costs tokens.
- Giving a sub-agent the graph or query access: it is exploring by another name.
- Treating INFERRED graph edges as facts, or a stale graph as current.
- Using `--force`, `--no-verify`, or deleting `.git/bpm/current` to get past a refusal: the refusal is the process working. Ask the user.
- Reviewing in your own context: your context grows and you are reviewing a plan you wrote.
- Updating the spec in batches at the end: it goes stale mid-project.
- Trusting "no panics": a run with zero crashes can still log thousands of handled errors.
- Loosening the baseline to make a review pass.

## Verification
- [ ] SPEC.md states a core model the user confirmed, and `docs/spec/baseline.txt` exists.
- [ ] Every module listed in SPEC.md has a file under `modules/` with interface, invariants and owned files.
- [ ] `git bpm check` passes.
- [ ] `git bpm status` shows no warnings: every done task has commits, no pending task has any.
- [ ] Every done task has a reviewer's verdict with evidence, not only its child's report.
- [ ] If graphify is used: the graph was updated after the last task and no forbidden module path exists.
- [ ] HANDOFF.md matches the current `git log`.
