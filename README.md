# big-project-manager

A skill for coding agents (Hermes Agent, Claude Code, Codex, or anything else that reads `SKILL.md`) for projects that don't fit in one context window.

I wrote it after watching agents fall apart on long jobs. They'd lose the plan after a restart, sub-agents would read half the repo to change one file, and "done" often meant a test got skipped. This skill makes the agent write the plan down, split the work into small checked tasks, and verify each one itself instead of trusting the sub-agent's report.

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

## Why bother

Everything important lives in files in your repo, not in the chat. If the session dies, or you switch to a different agent, it reads `HANDOFF.md` and `TASKS.md`, checks them against `git log`, and carries on.

It costs fewer tokens. On long runs most of the spend is sub-agents reading code they don't need, and a narrow context with no exploring fixes most of that. Each task also records its cost, so oversized tasks show up in the numbers.

You can check that "done" really means done, because each task has a check you can see and every review compares against the baseline. A regression gets caught at the task that caused it, not three tasks later.

Your working tree is safe. Sub-agents aren't allowed to reset, rebase, amend or stash, and a pre-commit hook rejects edits outside a task's file list.

You stay in charge. You approve the core model and the task list before anything runs, and a `STOP` line in `TASKS.md` pauses the run wherever you put it.

It isn't worth it for small things. For a one-file fix or something you'd finish in an afternoon, skip it. The overhead pays off once work spans several sessions or agents.

## Install

Clone it into your agent's skills folder as `big-project-manager`:

```
git clone https://github.com/darkgoatie/big-project-manager-skill big-project-manager
```

- Hermes Agent: `~/.hermes/skills/software-development/`
- Claude Code: `~/.claude/skills/`, or `.claude/skills/` inside a project
- Codex: `~/.codex/skills/`

Then give it something big ("take over this repo and finish the remaining work"), or ask for the skill by name.

## Files

```
SKILL.md            the process
templates/
  SPEC.md           goal, constraints, decisions, spikes, baseline
  module.md         interface, invariants, owned files
  TASKS.md          task table with status, attempts, cost
  HANDOFF.md        where things stand, what's next
```

In your project these go under `docs/spec/`, or under `plans/<project>/` if there's no repo.

## License

MIT
