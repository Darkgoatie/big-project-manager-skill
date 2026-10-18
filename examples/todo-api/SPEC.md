# todo-api spec

Core model: one SQLite file per deployment, every row scoped by user_id, one stateless HTTP process in front (confirmed by the user on 2026-10-02)

## Goal
JSON API for todo lists: users, lists, items, due dates. Used by an existing mobile app.

## Non-goals
Sharing lists between users. Real-time sync. Admin UI.

## Constraints
Python 3.12, FastAPI, SQLite. p95 latency under 50 ms for list reads with 1,000 items.

## Glossary
- list: a named group of items owned by one user
- item: one todo with title, done flag, optional due date

## Existing docs
- docs/mobile-api-contract.md: endpoints the app already calls

## Decisions
- SQLite over Postgres: single small deployment, no ops budget
- Session tokens over JWT: easy revocation, one table

## Open questions
- [x] Soft delete or hard delete items? (owner: user) Hard delete, decided 2026-10-03
- [ ] Rate limit per user or per IP? (owner: agent)

## Spikes
| Unknown | Result | Numbers | Date |
|---|---|---|---|
| SQLite under concurrent writes in WAL mode | yes | 400 writes/s, 0 busy errors over 60 s | 2026-10-02 |

## Baseline
| Metric | Value | Command |
|---|---|---|
| Tests passing | 0 / 0 (new repo) | `pytest -q` |
| Build time | n/a | |
| ERROR lines, standard run | 0 | `scripts/smoke.sh` |
| p95 list read, 1,000 items | 31 ms | `python bench/read_list.py` |
