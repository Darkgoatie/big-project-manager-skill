# Module: store

## Responsibility
All database access: schema, migrations, and typed read/write functions for users, lists and items. Every query is scoped by user_id.

Does NOT: validate HTTP input, hash passwords, or know about sessions.

## Public interface
| Name | Signature | Errors |
|---|---|---|
| create_list | `(user_id: int, name: str) -> List` | `DuplicateName` |
| get_list | `(user_id: int, list_id: int) -> List` | `NotFound` |
| add_item | `(user_id: int, list_id: int, title: str, due: date \| None) -> Item` | `NotFound` |
| set_done | `(user_id: int, item_id: int, done: bool) -> Item` | `NotFound` |

## Invariants
- No query runs without a user_id in its WHERE clause; another user's row reads as NotFound, never as forbidden.
- Every schema change ships a numbered migration and a test that opens a database written by the previous version.
- One connection per request; no connection is shared across threads.

## Depends on
- none

## Owned files
- app/store/*.py
- migrations/*.sql
- tests/store/*.py

## Dependencies (third-party)
- none (stdlib sqlite3)

## Testing in isolation
`pytest -q tests/store`

## Deviations
- 2026-10-04 task 2: added `DuplicateName`; the app shows a specific message for it
