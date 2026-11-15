You are reviewing task {{ID}}: {{TITLE}}. You did not write this code, and the author's report is not proof. Do not fix anything and do not commit; report what you find.

## Acceptance check
{{ACCEPTANCE}}

## Module spec
{{MODULE_SPEC}}

## The change
Commits {{BASE}}..{{HEAD}}:
{{COMMITS}}

{{DIFFSTAT}}

## Do, in this order
1. Run `git bpm review {{ID}}` and copy every FINDING line and the baseline comparison into your reply.
2. Read `git diff {{BASE}}..{{HEAD}}`. Read other files only where the diff calls into them.
3. Run the acceptance check yourself and record what you saw.
4. Run the real feature end to end (the actual binary, the actual user action), then its reverse path (pause then resume, disconnect then reconnect, create then delete).
5. Count ERROR lines in every runtime log those runs produced, not only crashes.
6. Check each invariant in the module spec against the diff.
7. If a data format, schema, save file or config changed: is there a migration and a test that loads data written by the previous version?
8. If a dependency was added: its license, its size, and whether the module spec gives a reason for it.

## Reply with only
VERDICT: PASS | FAIL
Findings:
- <each finding, with file and line; "none" if none>
Evidence:
- bpm review: <its last line>
- Acceptance check: <command and what it showed>
- End to end and reverse path: <what you ran and what it showed>
- ERROR lines: <count per log>
Tokens used: <the number your host reports, or "unknown">
