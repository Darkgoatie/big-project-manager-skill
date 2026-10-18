# big-project-manager

[![lint](https://github.com/darkgoatie/big-project-manager-skill/actions/workflows/lint.yml/badge.svg)](https://github.com/darkgoatie/big-project-manager-skill/actions/workflows/lint.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A skill for coding agents (Hermes Agent, Claude Code, Codex, or anything else that reads `SKILL.md`) for projects that don't fit in one context window. It does three things:

- **Spends fewer tokens.** Sub-agents get only the task, its module spec and the files they own. Nobody rereads the repo, the cached prefix stays small, and each task logs its cost so oversized ones show up.
- **Keeps the project's history in your repo.** The spec, decisions, task log and handoff notes are plain files under `docs/spec/`. A new session, or a different agent, reads them, checks them against `git log`, and picks up where the last one stopped.
- **Tracks goals and tasks.** The goal and core model are written down and confirmed by you. Work is a numbered task list where each task has one acceptance check you can observe, a status, its commits and its cost.

I wrote it after watching agents fall apart on long jobs. They'd lose the plan after a restart, sub-agents would read half the repo to change one file, and "done" often meant a test got skipped.

## What it does

When you hand the agent something big, like "build this" or "finish the rest of this repo", it:

1. Looks for the design docs you already have and links to them instead of rewriting them.
2. Writes `SPEC.md`: goal, non-goals, constraints, open questions, and the core model in one sentence. You confirm that sentence before any code gets written, because if it's wrong everything after it is wrong too. Risky unknowns get a throwaway spike first.
3. Splits the project into modules. Each one gets a file listing its interface, invariants and the files it owns. Modules only talk through those interfaces.
4. Records a baseline (test counts, error lines in a normal run, perf numbers) and commits a smoke script that every task has to pass.
5. Writes a numbered `TASKS.md`. Tasks are small, and each has one acceptance check you can actually observe, like "60 s run, 0 ERROR lines" rather than "tests pass". The first task is a thin end-to-end slice.
6. Hands each task to a sub-agent with only what it needs: the task, its module spec, the interfaces it calls, and the files it may touch. It isn't allowed to explore the repo. If it needs something else it has to ask.
7. Reviews the result itself. It reruns the smoke script, counts errors in the logs, checks the test diff for skips and removed asserts, looks for new functions nothing calls, and runs the real feature.
8. Stops after two failed attempts on the same task and either splits it or asks you. Bad work is undone with `git revert`, never a reset.
9. Updates the spec, the task list and `HANDOFF.md` after every task, so the docs never fall behind the code.

See [`examples/todo-api/`](examples/todo-api/) for what the files look like partway through a small project.

## Why bother

**Tokens.** On long runs most of the spend is sub-agents reading code they don't need and re-sending a growing context on every call. A narrow context with no exploring cuts most of that. Each task records its cost, so you can see where the money went.

**History.** Everything important lives in files in your repo, not in the chat. If the session dies, or you switch agents, nothing is lost: `HANDOFF.md` says where things stand and `TASKS.md` lists every task with its commits.

**Tracking.** You can check that "done" really means done, because each task has a check you can see and every review compares against the baseline. A regression gets caught at the task that caused it, not three tasks later.

**Your working tree is safe.** Sub-agents aren't allowed to reset, rebase, amend or stash, and a pre-commit hook ([`templates/hooks/pre-commit`](templates/hooks/pre-commit)) rejects edits outside a task's file list.

**You stay in charge.** You approve the core model and the task list before anything runs, and a `STOP` line in `TASKS.md` pauses the run wherever you put it.

It isn't worth it for small things. For a one-file fix or something you'd finish in an afternoon, skip it. The overhead pays off once work spans several sessions or agents.

## How much does it save?

Honest answer: it hasn't been measured on real agent runs yet. What exists is a **simulation** of input tokens with and without the skill's context rules, 30 seeded runs per repo, using real repo sizes:

| Repos | Size range | Modelled input-token saving (median) |
|---|---|---|
| 7 open-source repos (chalk, requests, flask, express, react, django, vscode) | 32 to 18,599 files | 57% to 68% |
| 5 of the author's own projects | 12 to 232 files | 51% to 67% |

Per-repo numbers with p5 to p95 ranges are in [`benchmarks/`](benchmarks/). Treat them as an estimate of where the savings come from, not a promise. If you run the skill on a real project and log task costs, I'd love to see the numbers in an issue.

## Install

Clone it into your agent's skills folder as `big-project-manager`:

```
git clone https://github.com/darkgoatie/big-project-manager-skill big-project-manager
```

- Hermes Agent: `~/.hermes/skills/software-development/`
- Claude Code: `~/.claude/skills/`, or `.claude/skills/` inside a project
- Codex: `~/.codex/skills/`

Then give it something big ("take over this repo and finish the remaining work"), or ask for the skill by name.

To update, `git pull` inside that folder. Changes are listed in [CHANGELOG.md](CHANGELOG.md).

## Files

```
SKILL.md              the process the agent follows
templates/
  SPEC.md             goal, constraints, decisions, spikes, baseline
  module.md           interface, invariants, owned files
  TASKS.md            task table with status, attempts, cost
  HANDOFF.md          where things stand, what's next
  smoke.sh            build + test + short real run, with ERROR counting
  hooks/pre-commit    rejects commits outside the current task's files
examples/todo-api/    a filled-in spec partway through a small project
benchmarks/           modelled token savings (HTML tables + JSON rows)
```

In your project the spec files go under `docs/spec/`, or under `plans/<project>/` if there's no repo.

## Contributing

Bug reports, real-world cost numbers and process tweaks are welcome. Open an issue first for anything larger than a wording fix. Keep `SKILL.md` short: every line is context the agent pays for on every load.

## License

MIT
