# Tasks

Status: pending | in progress | blocked | done | needs-fix | reverted

| # | Task | Module | Files | Depends | Acceptance check | Budget | Effort | Status | Attempts | Commits | Cost |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Thin slice: POST /lists then GET /lists/{id} end to end | api, store | app/main.py, app/store/lists.py, tests/test_slice.py | - | curl create then read returns the same name; smoke 0 ERROR | 40k | low | done | 1 | a1c3e09, 5f2d8b1 | $0.21 |
| 2 | Items: add, mark done | store | app/store/items.py, tests/store/test_items.py | 1 | another user's item_id returns 404, tested | 40k | low | done | 2 | 9e07c4a | $0.38 |
| 3 | Session login and logout | auth | app/auth/*.py, tests/auth/*.py | 1 | logout then reuse token returns 401 | 60k | medium | done | 1 | 3b61f0e, c8a92d7 | $0.44 |
| 4 | Due dates and overdue filter | store, api | app/store/items.py, app/api/items.py, migrations/002_due.sql | 2 | GET ?overdue=1 returns only past-due open items; v1 db opens after migration | 50k | low | blocked | 1 | | |
| 5 | Rate limiting | api | app/api/limits.py | 3 | 101st request in a minute returns 429 | 40k | low | pending | 0 | | |

STOP

| # | Task | Module | Files | Depends | Acceptance check | Budget | Effort | Status | Attempts | Commits | Cost |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 6 | Deploy to the VPS | ops | deploy/* | 1-5 | /health returns 200 from the public URL | 30k | low | pending | 0 | | |

## Scope requests

| Task | File | Reason | Decision | Date |
|---|---|---|---|---|
| 3 | app/main.py | register the auth router at startup | approved by user | 2026-10-05 |
| 4 | app/api/schemas.py | add `due` to the item response model | pending | |
