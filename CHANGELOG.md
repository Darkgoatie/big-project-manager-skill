# Changelog

## 0.2.0 - 2026-10-18

- Added `templates/smoke.sh`, `templates/smoke.ps1` and `templates/hooks/pre-commit`, which SKILL.md already told agents to create.
- Added a worked example under `examples/todo-api/`.
- README: framed around token use, project history and task tracking; benchmark numbers are now labelled as a simulation, not measured savings; Files section lists every folder.
- Added CI that checks SKILL.md frontmatter, links between files, and the shell scripts.
- Added issue templates and this changelog.
- Scope requests: a sub-agent that needs a file outside its list files a request in TASKS.md and the run pauses for the user, like a `STOP` line; the decision is recorded in the same row. Repeated requests for one file flag a wrong module boundary. (Suggested on Reddit.)
- HANDOFF.md records the commit it describes; a resumed session refuses to continue until it has reconciled any commits made since. (Suggested on Reddit.)
- Per-task cost is now also read as a scoping signal: a task costing about 3x its neighbours gets split.

## 0.1.0

- Initial release: SKILL.md, spec templates, modelled token-savings benchmarks.
