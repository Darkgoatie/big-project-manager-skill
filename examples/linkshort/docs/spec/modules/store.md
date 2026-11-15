# Module: store

## Responsibility
Owns the SQLite file. Creates codes, stores and looks up links.

Does NOT: speak HTTP, validate URLs, or know about rate limits.

## Public interface
| Name | Signature | Errors |
|---|---|---|
| `create_link` | `create_link(url: str, ttl: int \| None) -> str` | `StoreFull` after 5 code collisions in a row |
| `get_link` | `get_link(code: str) -> Link \| None` | none |

## Invariants
- A code is never reused, including for expired links.
- `create_link` is atomic: a crash leaves either the full row or nothing.
- No connection is shared between threads.

## Depends on

Must never depend on: api.

## Owned files
- src/linkshort/store.py
- tests/test_store.py

## Dependencies (third-party)
- none (sqlite3 is in the standard library)

## Testing in isolation
`pytest tests/test_store.py`

## Deviations
- 2026-11-05 task 2: collisions are retried inside one transaction instead of with a unique-index retry loop; the loop allowed a duplicate under concurrent writers.
