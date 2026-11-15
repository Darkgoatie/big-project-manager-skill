You are implementing task {{ID}}: {{TITLE}}. Work only on this task.

## Task
{{TASK}}

## Acceptance check
{{ACCEPTANCE}}

Context budget: {{BUDGET}}. If you are about to exceed it, stop and report.

## Module spec
{{MODULE_SPEC}}

## Interfaces you may call
{{INTERFACES}}

## Context
{{CONTEXT}}

## Files
You may edit only these files:
{{FILES}}

Read only these files and what they directly import. Do not explore the repo, search it, or open other files. If you need anything else, stop and report what you need and why.

## Verify
Run before every commit:
```
sh scripts/smoke.sh
```

## Rules
- Do not edit files outside the list. A pre-commit hook rejects them, and the review checks every file your commits touched.
- If the interface in the module spec is wrong or missing something, do not change it: stop and report the change you need.
- Commit each piece separately with a clear message. Never reset, rebase, amend, stash, push, or use `--no-verify`.
- Do not skip, weaken, or delete tests to make them pass. If a test is wrong, report it.
- Secrets come from the environment. Never print or write their values.
- Append one line per step to `{{SPEC_DIR}}/progress/{{ID}}.log`: step started, command run, result.

## Report
When done or stopped, reply with only:
- Commits: <hashes and messages>
- Acceptance check: <what you ran and what it showed>
- Smoke: <its summary line>
- Tokens used: <the number your host reports, or "unknown">
- Open issues or needed interface changes: <list or "none">
