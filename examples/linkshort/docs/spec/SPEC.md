# linkshort spec

Core model: every short code maps to exactly one URL in a single SQLite file, behind one HTTP service. (Confirmed by the user on 2026-11-02.)

## Goal
A self-hosted URL shortener for one team: create a short link, follow it, let it expire.

## Non-goals
- Accounts, teams or permissions.
- Click analytics.
- Running more than one instance.

## Constraints
Python 3.12, Flask, SQLite in WAL mode. One process on a 1 vCPU box. Redirects answer in under 15 ms at p95 with 100,000 links stored.

## Glossary
- code: the 7-character identifier in a short link.
- ttl: seconds until a link stops redirecting.

## Existing docs
- README.md: how to run the service.

## Decisions
- SQLite, not Postgres: one instance is a non-goal, and it removes a deployment dependency.
- Codes are random, not sequential: sequential codes let anyone enumerate links.

## Open questions
- [x] Should expired links be deleted or kept? Kept, answered with 410 (user, 2026-11-03).
- [ ] Rate limit per IP or per API key? (owner: user; blocks task 4)

## Spikes
| Unknown | Result | Numbers | Date |
|---|---|---|---|
| Can SQLite take the write load? | yes | 4,100 inserts/s in WAL mode, target was 200/s | 2026-11-02 |

## Baseline
In `baseline.txt`, recorded by `git bpm baseline` before task 1. Smoke scenario: create 1,000 links, follow each once.
