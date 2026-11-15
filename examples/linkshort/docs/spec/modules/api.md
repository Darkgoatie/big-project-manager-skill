# Module: api

## Responsibility
The HTTP surface: create a link, follow a link. Validates input and maps store results to status codes.

Does NOT: touch SQLite directly or generate codes.

## Public interface
| Name | Signature | Errors |
|---|---|---|
| `create_app` | `create_app(db_path: str) -> Flask` | none |
| `POST /links` | body `{url, ttl?}` -> `201 {code}` | `400` invalid URL, `503` on `StoreFull` |
| `GET /<code>` | -> `302` to the URL | `404` unknown code, `410` expired |

## Invariants
- A redirect never follows a URL the service did not store itself.
- Every 5xx response logs exactly one ERROR line.

## Depends on
- store: create_link, get_link

## Owned files
- src/linkshort/app.py
- tests/test_slice.py
- tests/test_api.py

## Dependencies (third-party)
- flask: BSD-3-Clause, the HTTP layer

## Testing in isolation
`pytest tests/test_api.py` (uses an in-memory store)

## Deviations
