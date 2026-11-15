# big-project-manager

**Saves tokens across the board: less context, fewer cache reads, and lower input and output token counts.** Sub-agents get only the task, its module spec and the files they own, so nobody rereads the repo, the cached prefix stays small, and replies stay short.

A skill for coding agents (Hermes Agent, Claude Code, Codex, or anything else that reads `SKILL.md`) for projects that don't fit in one context window.

I wrote it after watching agents fall apart on long jobs. They'd lose the plan after a restart, sub-agents would read half the repo to change one file, and "done" often meant a test got skipped. This skill makes the agent write the plan down, split the work into small checked tasks, and verify each one itself instead of trusting the sub-agent's report.

## What it does

When you hand the agent something big, like "build this" or "finish the rest of this repo", it:

1. Looks for the design docs you already have and links to them instead of rewriting them.
2. Writes `SPEC.md`: goal, non-goals, constraints, open questions, and the core model in one sentence. You confirm that sentence before any code gets written, because if it's wrong everything after it is wrong too. Risky unknowns get a throwaway spike first.
3. Splits the project into modules. Each one gets a file listing its interface, invariants and the files it owns. Modules only talk through those interfaces.
4. Records a baseline (test counts, error lines in a normal run, perf numbers) and commits a smoke script that every task has to pass.
5. Writes one numbered file per task. Tasks are small, and each has one acceptance check you can actually observe, like "60 s run, 0 ERROR lines" rather than "tests pass". The first task is a thin end-to-end slice.
6. Hands each task to a sub-agent with only what it needs: the task, its module spec, the interfaces it calls, and the files it may touch. It isn't allowed to explore the repo. If it needs something else it has to ask.
7. Has a second, fresh sub-agent review the result. The review reruns the smoke script on a clean checkout, compares it with the baseline, checks every file the commits touched, looks for skipped tests, removed asserts and functions nothing calls, and runs the real feature.
8. Stops after two failed attempts on the same task and either splits it or asks you. A retry has to change something. Bad work is undone with `git revert`, never a reset.
9. Updates the spec and `HANDOFF.md` after every task, so the docs never fall behind the code.

## The runner

The bookkeeping is done by a script, not by the agent's memory. `git bpm` (one POSIX shell file, needs only git) picks the next task, builds the sub-agent's prompt, runs the mechanical review, and refuses to mark a task done without a passing review of the current commit:

```
git bpm next            # which task is next; halts at STOP and after two failures
git bpm start 14        # commits may now touch only task 14's files
git bpm prompt 14       # the child's whole prompt
git bpm review 14       # files touched, weakened tests, smoke run vs the baseline
git bpm done 14         # or: git bpm fail 14 "what the next attempt changes"
git bpm status          # tasks and their commits, read from git; start here when resuming
```

While a task is started, a pre-commit hook rejects files outside its list and every commit gets a `Task: 14` trailer, so the task list can always be checked against `git log`.

In Claude Code, sub-agents run as a `bpm-worker` agent with no search tools. Its edits outside the task's files are blocked, searching the repo from the shell is blocked, and reads outside its list are capped. Other agents get the same limits as rules in the prompt, and the review catches what slips through.

## Why bother

Everything important lives in files in your repo, not in the chat. If the session dies, or you switch to a different agent, it reads `HANDOFF.md`, runs `git bpm status`, and carries on. The manager is told to restart on purpose every few tasks, because its own growing context is the largest cost on a long run.

It costs fewer tokens. On long runs most of the spend is sub-agents reading code they don't need, and a narrow context with no exploring fixes most of that. Each task also records the tokens the host reported, so oversized tasks show up in the numbers.

You can check that "done" really means done, because each task has a check you can see and every review compares against the baseline. A regression gets caught at the task that caused it, not three tasks later.

Your working tree is safe. Sub-agents aren't allowed to reset, rebase, amend or stash, the hook rejects commits outside a task's file list, and the review fails if a file you had uncommitted has changed.

You stay in charge. You approve the core model and the task list before anything runs, and `git bpm stop 20` pauses the run before task 20 until you clear it.

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
SKILL.md              the process
scripts/
  bpm                 the runner, the git hooks and the review checks
  smoke.sh, smoke.ps1 build + test + short scenario + ERROR count
templates/
  SPEC.md             goal, constraints, decisions, spikes
  module.md           interface, invariants, owned files
  task.md             one task: files, dependencies, acceptance check
  HANDOFF.md          where things stand, what's next
  CHILD_PROMPT.md     the prompt each sub-agent gets
  REVIEW_PROMPT.md    the prompt each reviewer gets
claude-agents/        bpm-worker and bpm-reviewer for Claude Code
examples/linkshort/   a spec part-way through a small project
evals/                trigger and behaviour evals (defined, not yet run)
tests/run.sh          tests for the scripts; CI runs them on Linux, macOS, Windows
```

`git bpm init` copies what a project needs into its `docs/spec/` and `scripts/`, installs the hooks, and adds the `git bpm` alias. It also adds two lines to `.gitattributes` and one to `.gitignore`. To run the tests: `sh tests/run.sh`.

## Works with graphify (optional)

If [graphify](https://pypi.org/project/graphifyy/) is installed, the manager uses its knowledge graph instead of reading the repo: the graph report for the inventory, communities as a first draft of modules, budgeted queries to fill in task file lists, and `graphify path` in reviews to catch broken module boundaries. Sub-agents never get the graph. They still see only their task. Without graphify, everything works the same.

## License

MIT
