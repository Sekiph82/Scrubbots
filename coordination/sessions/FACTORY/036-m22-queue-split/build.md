STATUS: READY

# Build: M22 queue split (TASKS.md bookkeeping)

## Summary
TASKS.md only: ticked SB-M22-025 with 2026-10-22 note; queue READY row replaced by DONE SB-M22-025 row and OWNER SB-M22-023 row (after last READY row); one question added under Questions for Sekip. SB-M22-023 left unticked. CRLF preserved.

## Acceptance criteria
1. [x] SB-M22-025 ticked with note: git diff shows change.
2. [x] SB-M22-023 unticked: untouched.
3. [x] Queue rows replaced/placed: git diff.
4. [x] Question line added.
5. [x] git diff --check clean; only TASKS.md changed.

## Validation
git diff --check: clean. git status clean after commit.

## Log
### Round 2
Review finding: OWNER SB-M22-023 row sat mid-READY block; moved to directly after OWNER SB-UI-008..013 (after last READY row).

### Round 1
Done as above.
